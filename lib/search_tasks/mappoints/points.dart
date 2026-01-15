import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:connect/config/app_config.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class TaskMapScreen extends StatefulWidget {
  final String? taskId;
  final Map<String, dynamic>? taskData;
  final bool showPostedTasks;

  const TaskMapScreen({
    super.key, 
    this.taskId, 
    this.taskData, 
    this.showPostedTasks = false,
  });

  @override
  _TaskMapScreenState createState() => _TaskMapScreenState();
}

class _TaskMapScreenState extends State<TaskMapScreen> {
  late GoogleMapController mapController;
  final TextEditingController _searchController = TextEditingController();
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  LatLng? _initialPosition;
  bool _isLoading = true;
  BitmapDescriptor? _customMarkerIcon;
  BitmapDescriptor? _nearMarkerIcon;
  BitmapDescriptor? _farMarkerIcon;
  
  // Get near distance threshold from configuration (in meters)
  double get _nearDistanceThreshold => AppConfig.nearDistanceThreshold;
  
  // Route-related variables
  bool _isRouteLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeCustomMarker();
    _initializeMap();
  }

  Future<void> _initializeCustomMarker() async {
    try {
      // Use the teal pin icon for markers - increased size from 90 to 120
      final Uint8List tealPinIcon = await getBytesFromAsset('assets/images/logos/teal_pin.png', 120);
      
      setState(() {
        _customMarkerIcon = BitmapDescriptor.fromBytes(tealPinIcon);
        _nearMarkerIcon = BitmapDescriptor.fromBytes(tealPinIcon);
        _farMarkerIcon = BitmapDescriptor.fromBytes(tealPinIcon);
      });
      
      print('✅ Teal pin markers loaded successfully (120px size)');
    } catch (e) {
      print('Error loading teal pin marker: $e');
      // Fallback to teal colored marker if custom icon loading fails
      setState(() {
        _customMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
        _nearMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
        _farMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
      });
    }
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    final frame = await codec.getNextFrame();
    final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  BitmapDescriptor _getMarkerIconForDistance(double distance) {
    if (distance <= _nearDistanceThreshold) {
      print('📍 Using teal pin marker for distance: ${(distance / 1000).toStringAsFixed(1)}km');
      return _nearMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
    } else {
      print('📍 Using teal pin marker for distance: ${(distance / 1000).toStringAsFixed(1)}km');
      return _farMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
    }
  }

  // Function to get route from current location to marker
  Future<void> _getRouteToMarker(LatLng destination) async {
    if (_initialPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current location not available')),
      );
      return;
    }

    setState(() {
      _isRouteLoading = true;
    });

    try {
      // Clear existing polylines
      _polylines.clear();

      final response = await http.get(Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${_initialPosition!.latitude},${_initialPosition!.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=driving'
        '&key=${AppConfig.googleMapsApiKey}'
      ));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final polylinePoints = route['overview_polyline']['points'];
          
          // Decode polyline points
          final List<LatLng> polylineCoordinates = _decodePolyline(polylinePoints);
          
          // Create polyline
          final polyline = Polyline(
            polylineId: const PolylineId('route'),
            color: const Color(0xFF00C7BE),
            width: 5,
            points: polylineCoordinates,
          );

          setState(() {
            _polylines.add(polyline);
            _isRouteLoading = false;
          });

          // Fit camera to show entire route
          _fitPolyline(polylineCoordinates);
        } else {
          setState(() {
            _isRouteLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No route found')),
          );
        }
      } else {
        setState(() {
          _isRouteLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get route')),
        );
      }
    } catch (e) {
      setState(() {
        _isRouteLoading = false;
      });
      print('Error getting route: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error calculating route')),
      );
    }
  }

  // Decode polyline string to list of LatLng
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      final p = LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble());
      poly.add(p);
    }
    return poly;
  }

  // Fit camera to show entire polyline
  void _fitPolyline(List<LatLng> polylineCoordinates) {
    if (polylineCoordinates.isEmpty) return;

    double minLat = polylineCoordinates[0].latitude;
    double maxLat = polylineCoordinates[0].latitude;
    double minLng = polylineCoordinates[0].longitude;
    double maxLng = polylineCoordinates[0].longitude;

    for (final point in polylineCoordinates) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  // Clear route
  void _clearRoute() {
    setState(() {
      _polylines.clear();
    });
  }

  Future<void> _initializeMap() async {
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _initialPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      // Load tasks
      if (widget.taskId != null || widget.taskData != null) {
        await _showSpecificTask();
      } else {
        await _fetchTasksFromFirestore();
      }
    } catch (e) {
      print('Error initializing map: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to initialize map')),
      );
    }
  }

  Future<void> _searchAndNavigate(String query) async {
    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final newPosition = LatLng(location.latitude, location.longitude);

        setState(() {
          _markers.add(
            Marker(
              markerId: const MarkerId('search_result'),
              position: newPosition,
              icon: _customMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
            ),
          );
        });

        mapController.animateCamera(
          CameraUpdate.newLatLngZoom(newPosition, 12),
        );
      }
    } catch (e) {
      print('Error searching location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to find location')),
      );
    }
  }

  void _showTaskDetails(Map<String, dynamic>? taskData) {
    if (taskData == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with title and budget
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            taskData['title'] ?? 'No Title',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        if (taskData['budget'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00C7BE), Color(0xFF00A8A0)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00C7BE).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'Rs ${taskData['budget']}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Location and date info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Location
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00C7BE).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  size: 20,
                                  color: Color(0xFF00C7BE),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Location',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      taskData['location'] ?? 'No location',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Date
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.calendar_today,
                                  size: 20,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Posted',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      taskData['createdAt'] != null 
                                          ? DateFormat('MMM d, yyyy').format((taskData['createdAt'] as Timestamp).toDate())
                                          : 'No date',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Description
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      taskData['description'] ?? 'No Description',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              // Add to favorites or bookmark logic
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Color(0xFF00C7BE)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Save',
                              style: TextStyle(
                                color: Color(0xFF00C7BE),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              // Implement task acceptance logic here
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00C7BE),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Accept Task',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showSpecificTask() async {
    try {
      Map<String, dynamic> taskData;

      if (widget.taskData != null) {
        taskData = widget.taskData!;
      } else {
        final doc = await FirebaseFirestore.instance
            .collection('tasks')
            .doc(widget.taskId)
            .get();
        final data = doc.data();
        if (data == null) {
          throw Exception('Task not found');
        }
        taskData = data;
      }

      if (taskData.containsKey('latitude') && taskData.containsKey('longitude')) {
        final double latitude = (taskData['latitude'] as num).toDouble();
        final double longitude = (taskData['longitude'] as num).toDouble();
        final LatLng taskPosition = LatLng(latitude, longitude);

        // Calculate distance from user's current position
        double distance = double.infinity;
        if (_initialPosition != null) {
          distance = Geolocator.distanceBetween(
            _initialPosition!.latitude,
            _initialPosition!.longitude,
            latitude,
            longitude,
          );
        }

        // Get appropriate marker icon based on distance
        final markerIcon = _getMarkerIconForDistance(distance);

        setState(() {
          _markers.add(
            Marker(
              markerId: MarkerId(widget.taskId ?? 'specific_task'),
              position: taskPosition,
              infoWindow: InfoWindow(
                title: taskData['title'] ?? 'No Title',
                snippet: 'Rs ${taskData['budget'] ?? '0'} - ${distance < double.infinity ? '${(distance / 1000).toStringAsFixed(1)}km away' : 'Distance unknown'}',
              ),
              icon: markerIcon,
              onTap: () {
                _showTaskDetails(taskData);
                _getRouteToMarker(taskPosition);
              },
            ),
          );
        });

        mapController.animateCamera(
          CameraUpdate.newLatLngZoom(taskPosition, 12),
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showTaskDetails(taskData);
        });
      }
    } catch (e) {
      print("Error showing specific task: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load task details')),
      );
    }
  }

  Future<void> _fetchTasksFromFirestore() async {
    try {
      Query query = FirebaseFirestore.instance.collection('tasks');
      
      // Filter by current user if showPostedTasks is true
      if (widget.showPostedTasks) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          query = query.where('userId', isEqualTo: currentUser.uid);
        }
      }
      
      final snapshot = await query.get();
      final newMarkers = <Marker>{};
      Map<String, dynamic>? nearestTaskData;
      double nearestDistance = double.infinity;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('latitude') && data.containsKey('longitude')) {
          final double latitude = (data['latitude'] as num).toDouble();
          final double longitude = (data['longitude'] as num).toDouble();
          final LatLng position = LatLng(latitude, longitude);

          // Debug: Log budget information
          debugPrint('📍 Task: ${data['title']} - Budget: ${data['budget']} - Location: ${data['location']}');

          // Calculate distance from user's current position
          double distance = double.infinity;
          if (_initialPosition != null) {
            distance = Geolocator.distanceBetween(
              _initialPosition!.latitude,
              _initialPosition!.longitude,
              latitude,
              longitude,
            );
          }

          // Get appropriate marker icon based on distance
          final markerIcon = _getMarkerIconForDistance(distance);

          newMarkers.add(
            Marker(
              markerId: MarkerId(doc.id),
              position: position,
              infoWindow: InfoWindow(
                title: data['title'] ?? 'No Title',
                snippet: 'Rs ${data['budget'] ?? '0'} - ${distance < double.infinity ? '${(distance / 1000).toStringAsFixed(1)}km away' : 'Distance unknown'}',
              ),
              icon: markerIcon,
              onTap: () {
                _showTaskDetails(data);
                _getRouteToMarker(position);
              },
            ),
          );

          if (_initialPosition != null) {
            if (distance < nearestDistance) {
              nearestDistance = distance;
              nearestTaskData = data;
            }
          }
        }
      }

      setState(() {
        _markers.addAll(newMarkers);
      });

      if (nearestTaskData != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showTaskDetails(nearestTaskData);
        });
      }
    } catch (e) {
      print("Error fetching tasks: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load tasks')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.showPostedTasks ? 'My Posted Tasks' : 'Task Map',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: (controller) {
                    mapController = controller;
                    if (_initialPosition != null) {
                      controller.animateCamera(
                        CameraUpdate.newLatLngZoom(_initialPosition!, 14),
                      );
                    }
                  },
                  initialCameraPosition: CameraPosition(
                    target: _initialPosition ?? const LatLng(0, 0),
                    zoom: 14,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),
                Positioned(
                  top: 50,
                  left: 15,
                  right: 15,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _searchAndNavigate,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search for tasks or locations...',
                        hintStyle: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w400,
                        ),
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C7BE).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.search,
                            color: Color(0xFF00C7BE),
                            size: 20,
                          ),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: Colors.grey.shade600,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: const BorderSide(
                            color: Color(0xFF00C7BE),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                ),
                // Clear route button
                if (_polylines.isNotEmpty)
                  Positioned(
                    top: 120,
                    right: 15,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: _clearRoute,
                        icon: const Icon(
                          Icons.clear,
                          color: Color(0xFF00C7BE),
                          size: 24,
                        ),
                        tooltip: 'Clear Route',
                      ),
                    ),
                  ),
                // Route loading indicator
                if (_isRouteLoading)
                  Positioned(
                    top: 120,
                    left: 15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C7BE)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Calculating route...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Show message when no tasks found for posted tasks
                if (widget.showPostedTasks && _markers.length <= 1)
                  Positioned(
                    top: 120,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_off,
                            size: 48,
                            color: Color(0xFF00C7BE),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No Posted Tasks Found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'You haven\'t posted any tasks with location data yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}