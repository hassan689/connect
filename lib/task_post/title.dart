import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:linkster/task_post/description.dart';
import 'package:linkster/task_post/location_search.dart';
import 'dart:async'; // Added for Timer
import 'dart:typed_data'; // Added for Uint8List

class TaskTitleScreen extends StatefulWidget {
  const TaskTitleScreen({super.key});

  @override
  State<TaskTitleScreen> createState() => _TaskTitleScreenState();
}

class _TaskTitleScreenState extends State<TaskTitleScreen> {
  final TextEditingController _titleController = TextEditingController();
  String _taskMode = 'Online'; // Default selection

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(step: 1),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Start with the title",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Title input field
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: "Enter task title",
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                prefixIcon: Icon(Icons.edit_note, color: Colors.grey.shade600),
              ),
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 30),

            Text(
              "Do you want to be online or offline?",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),

            const SizedBox(height: 20),
            const Text(
              "Where will this task be done?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Row(
              children:
                  ['Online', 'on site'].map((mode) {
                    final isSelected = _taskMode == mode;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: ChoiceChip(
                        label: Text(mode),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _taskMode = mode;
                          });
                        },
                        selectedColor: const Color(0xFF00C7BE),
                        backgroundColor: Colors.grey.shade200,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
            ),

            const Spacer(),

            // Post Task Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => SelectDateScreen(
                            taskTitle: _titleController.text,
                            taskMode: _taskMode, // pass the mode here
                          ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C7BE),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 3,
                ),
                child: Text(
                  "Next",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class SelectDateScreen extends StatefulWidget {
  final String taskTitle;
  final String taskMode;
  const SelectDateScreen({
    super.key,
    required this.taskTitle,
    required this.taskMode,
  });

  @override
  State<SelectDateScreen> createState() => _SelectDateScreenState();
}

class _SelectDateScreenState extends State<SelectDateScreen> {
  DateTime? _selectedDate;
  bool _needSpecificTime = false;
  String? _selectedTimeSlot;
  String _dateOption = 'flexible'; // 'specific', 'before', or 'flexible'

  void _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateOption = 'specific';
      });
    }
  }

  void _pickBeforeDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateOption = 'before';
      });
    }
  }

  void _selectTimeSlot(String timeSlot) {
    setState(() {
      _selectedTimeSlot = timeSlot;
    });
  }

  void _selectDateOption(String option) {
    setState(() {
      _dateOption = option;
      if (option != 'specific' && option != 'before') {
        _selectedDate = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(step: 2),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Decide on when",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "When do you need this done?",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 20),

            // Date Selection
            Column(
              children: [
                _dateOptionButton(
                  label:
                      _dateOption == 'specific' && _selectedDate != null
                          ? "On ${_formatDate(_selectedDate!)}"
                          : "Select a date",
                  isSelected: _dateOption == 'specific',
                  onTap: _pickDate,
                ),
                const SizedBox(height: 10),
                _dateOptionButton(
                  label:
                      _dateOption == 'before' && _selectedDate != null
                          ? "Before ${_formatDate(_selectedDate!)}"
                          : "Before date",
                  isSelected: _dateOption == 'before',
                  onTap: _pickBeforeDate,
                ),
                const SizedBox(height: 10),
                _dateOptionButton(
                  label: "I'm flexible",
                  isSelected: _dateOption == 'flexible',
                  onTap: () => _selectDateOption('flexible'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Time of day checkbox
            Row(
              children: [
                Checkbox(
                  value: _needSpecificTime,
                  onChanged: (value) {
                    setState(() {
                      _needSpecificTime = value!;
                      if (!_needSpecificTime) {
                        _selectedTimeSlot = null;
                      }
                    });
                  },
                ),
                const Text("I need a certain time of the day"),
              ],
            ),

            const SizedBox(height: 10),

            // Time Slots
            if (_needSpecificTime)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _timeSlotButton("Morning\nBefore 10am"),
                  _timeSlotButton("Midday\n10am - 2pm"),
                  _timeSlotButton("Afternoon\n2pm - 6pm"),
                  _timeSlotButton("Evening\nAfter 6pm"),
                ],
              ),

            const Spacer(),

            // Continue Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => SelectLocationScreen(
                            taskType: widget.taskMode,
                            taskTitle: widget.taskTitle,
                            selectedDate: _selectedDate,
                            selectedTimeSlot: _selectedTimeSlot,
                            dateOption: _dateOption,
                            
                          ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C7BE),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  "Continue",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day} ${_monthName(date.month)} ${date.year}";
  }

  String _monthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[month - 1];
  }

  Widget _dateOptionButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00C7BE) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _timeSlotButton(String label) {
    final bool isSelected = _selectedTimeSlot == label;
    return GestureDetector(
      onTap: () => _selectTimeSlot(label),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.4,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? const Color(0xFF00C7BE).withOpacity(0.2)
                  : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF00C7BE) : Colors.grey.shade300,
          ),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isSelected ? const Color(0xFF00C7BE) : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

class SelectLocationScreen extends StatefulWidget {
  final String taskTitle;
  final DateTime? selectedDate;
  final String? selectedTimeSlot;
  final String dateOption;
  final String taskType;

  const SelectLocationScreen({
    super.key,
    required this.taskType,
    required this.taskTitle,
    required this.selectedDate,
    this.selectedTimeSlot,
    required this.dateOption,
  });

  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  final TextEditingController _locationController = TextEditingController();
  GoogleMapController? _mapController;
  LatLng? _selectedPosition;
  final Set<Marker> _markers = {};
  bool _isLoading = true;

  // Function to create a larger custom marker
  Future<BitmapDescriptor> _createLargeMarker() async {
    try {
      // Create a larger rose-colored marker (120px instead of default ~40px)
      final Uint8List markerBytes = await _getBytesFromAsset('assets/images/logos/teal_pin.png', 120);
      return BitmapDescriptor.fromBytes(markerBytes);
    } catch (e) {
      print('Error creating large marker: $e');
      // Fallback to default marker if custom marker fails
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
    }
  }

  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    final frame = await codec.getNextFrame();
    final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    setState(() => _isLoading = true);

    try {
      print('📍 Starting location detection...');
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Location services are disabled');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enable location services in your device settings'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        print('🔐 Requesting location permission...');
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          print('❌ Location permission denied');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location permission is required to use this feature'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Location permission permanently denied');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location permission is permanently denied. Please enable it in app settings.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }

      print('✅ Getting current position...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      LatLng currentLatLng = LatLng(position.latitude, position.longitude);
      print('📍 Position obtained: ${position.latitude}, ${position.longitude}');

      // Update location with reverse geocoding to get the address
      await _updateLocation(currentLatLng, useReverseGeocoding: true);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Location set to: ${_locationController.text}'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateLocation(
    LatLng position, {
    bool useReverseGeocoding = false,
    String? address,
  }) async {
    // Create the larger marker
    final largeMarker = await _createLargeMarker();
    
    setState(() {
      _selectedPosition = position;
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId("selected"),
          position: position,
          infoWindow: const InfoWindow(title: "Selected Location"),
          icon: largeMarker,
        ),
      );
    });

    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, 14));

    // Update the location controller text
    if (address != null) {
      setState(() => _locationController.text = address);
    } else if (useReverseGeocoding) {
      try {
        print('🔄 Getting address for coordinates: ${position.latitude}, ${position.longitude}');
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          final formattedAddress = _formatAddress(placemark);
          print('📍 Address found: $formattedAddress');
          setState(() => _locationController.text = formattedAddress);
        } else {
          print('⚠️ No placemarks found for coordinates');
          // Fallback to coordinates if no address found
          setState(() => _locationController.text = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}');
        }
      } catch (e) {
        print('❌ Reverse geocoding error: $e');
        // Fallback to coordinates if reverse geocoding fails
        setState(() => _locationController.text = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}');
      }
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(step: 3),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Where do you need it done?",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Search or tap on the map to select a location",
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                EnhancedLocationSearch(
                  onLocationSelected: (address, latitude, longitude) {
                    _updateLocation(
                      LatLng(latitude, longitude),
                      useReverseGeocoding: false,
                      address: address,
                    );
                  },
                  initialValue: _locationController.text,
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _determinePosition,
                    icon: _isLoading 
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(Icons.my_location, color: Colors.white),
                    label: Text(
                      _isLoading ? 'Getting Location...' : 'Use My Current Location',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C7BE),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child:
                      _isLoading
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF00C7BE),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Loading map...',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          )
                          : GoogleMap(
                            onMapCreated: (controller) {
                              _mapController = controller;
                              setState(() => _isLoading = false);
                            },
                            initialCameraPosition: CameraPosition(
                              target: _selectedPosition ?? const LatLng(0, 0),
                              zoom: 14,
                            ),
                            markers: _markers,
                            myLocationEnabled: true,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            mapToolbarEnabled: false,
                            onTap: (LatLng position) {
                              _updateLocation(
                                position,
                                useReverseGeocoding: true,
                              );
                            },
                          ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              24,
              20,
              24,
              24,
            ), // your desired padding
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedPosition != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => TaskDescriptionScreen(
                              tasktype: widget.taskType,
                              location: _locationController.text,
                              taskTitle: widget.taskTitle,
                              selectedDate: widget.selectedDate,
                              selectedTimeSlot: widget.selectedTimeSlot,
                              dateOption: widget.dateOption,
                              latitude: _selectedPosition!.latitude,
                              longitude: _selectedPosition!.longitude,
                            ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select a location first'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C7BE),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 3,
                ),
                child: Text(
                  "Continue",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAddress(Placemark placemark) {
    List<String> parts = [];
    
    if (placemark.name?.isNotEmpty == true) {
      parts.add(placemark.name!);
    }
    if (placemark.street?.isNotEmpty == true) {
      parts.add(placemark.street!);
    }
    if (placemark.locality?.isNotEmpty == true) {
      parts.add(placemark.locality!);
    }
    if (placemark.administrativeArea?.isNotEmpty == true) {
      parts.add(placemark.administrativeArea!);
    }
    if (placemark.country?.isNotEmpty == true) {
      parts.add(placemark.country!);
    }
    
    return parts.join(', ');
  }
}

// Helper class for location suggestions
class LocationSuggestion {
  final String address;
  final double latitude;
  final double longitude;
  final Placemark? placemark;

  LocationSuggestion({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.placemark,
  });
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int step;

  const CustomAppBar({super.key, required this.step});

  @override
  Size get preferredSize => const Size.fromHeight(100);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 100,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 12, // <-- THICKNESS of the bar
                child: LinearProgressIndicator(
                  value: step / 7,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF00C7BE),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 5),
            child: Text(
              "Step $step of 7",
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
