import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dart:async';

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

class EnhancedLocationSearch extends StatefulWidget {
  final Function(String address, double latitude, double longitude) onLocationSelected;
  final String initialValue;

  const EnhancedLocationSearch({
    super.key,
    required this.onLocationSelected,
    this.initialValue = '',
  });

  @override
  State<EnhancedLocationSearch> createState() => _EnhancedLocationSearchState();
}

class _EnhancedLocationSearchState extends State<EnhancedLocationSearch> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showSuggestions = false;
  List<LocationSuggestion> _suggestions = [];
  Timer? _debounceTimer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialValue;
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    // Debounce the search to avoid too many API calls
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchLocationSuggestions(_controller.text);
    });
  }

  Future<void> _searchLocationSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _showSuggestions = false;
        _suggestions = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<Location> locations = await locationFromAddress(query);
      List<LocationSuggestion> suggestions = [];
      
      for (Location location in locations.take(5)) { // Limit to 5 suggestions
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );
          if (placemarks.isNotEmpty) {
            final placemark = placemarks.first;
            final formattedAddress = _formatAddress(placemark);
            suggestions.add(LocationSuggestion(
              address: formattedAddress,
              latitude: location.latitude,
              longitude: location.longitude,
              placemark: placemark,
            ));
          }
        } catch (e) {
          // If reverse geocoding fails, still add the location
          suggestions.add(LocationSuggestion(
            address: query,
            latitude: location.latitude,
            longitude: location.longitude,
            placemark: null,
          ));
        }
      }

      setState(() {
        _suggestions = suggestions;
        _showSuggestions = suggestions.isNotEmpty;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _showSuggestions = false;
        _suggestions = [];
        _isLoading = false;
      });
    }
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

  void _selectSuggestion(LocationSuggestion suggestion) {
    setState(() {
      _controller.text = suggestion.address;
      _showSuggestions = false;
      _suggestions = [];
    });
    
    widget.onLocationSelected(
      suggestion.address,
      suggestion.latitude,
      suggestion.longitude,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: "Search address or place (e.g., Lahore, Karachi)",
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
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
            suffixIcon: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C7BE)),
                      ),
                    ),
                  )
                : null,
          ),
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        // Location suggestions dropdown
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return ListTile(
                  leading: Icon(
                    Icons.location_on,
                    color: const Color(0xFF00C7BE),
                    size: 20,
                  ),
                  title: Text(
                    suggestion.address,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: suggestion.placemark?.locality != null
                      ? Text(
                          '${suggestion.placemark!.locality}, ${suggestion.placemark!.country}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        )
                      : null,
                  onTap: () => _selectSuggestion(suggestion),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
} 