import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connect/search_tasks/mappoints/points.dart';
import 'package:connect/search_tasks/taskdetails.dart';
import 'package:connect/ai_services/huggingface_service.dart';
import 'package:connect/widgets/shimmer_loading.dart';
import 'package:connect/core/utils/responsive.dart';


class BrowseTasksScreen extends StatefulWidget {
  const BrowseTasksScreen({super.key});

  @override
  State<BrowseTasksScreen> createState() => _BrowseTasksScreenState();
}

class _BrowseTasksScreenState extends State<BrowseTasksScreen> {
  // Filter variables
  String? _selectedStatus;
  String? _selectedBudgetRange;
  String? _selectedLocation;
  String? _selectedDateRange;
  bool _hasImages = false;
  bool _isFilterActive = false;
  
  // AI-powered filtering
  String? _selectedAICategory;
  String _searchQuery = '';
  String _suggestedCategory = '';
  bool _isAnalyzingSearch = false;
  bool _showAISuggestions = false;
  


  // Budget ranges
  final List<String> _budgetRanges = [
    'Any Budget',
    'Under Rs 50',
    'Rs 50 - Rs 100',
    'Rs 100 - Rs 200',
    'Rs 200 - Rs 500',
    'Over Rs 500',
  ];

  // Date ranges
  final List<String> _dateRanges = [
    'Any Time',
    'Today',
    'This Week',
    'This Month',
    'Last 7 Days',
    'Last 30 Days',
  ];

  // Status options
  final List<String> _statusOptions = [
    'All Status',
    'Open',
    'In Progress',
    'Completed',
    'Cancelled',
  ];

  // AI Categories (based on our classification model)
  final List<String> _aiCategories = [
    'All Categories',
    'Cleaning',
    'Moving',
    'Gardening',
    'Pet Care',
    'Tutoring',
    'Delivery',
    'Handyman',
    'Technology',
    'Event Planning',
    'Other',
  ];



  void _resetFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedBudgetRange = null;
      _selectedLocation = null;
      _selectedDateRange = null;
      _hasImages = false;
      _selectedAICategory = null;
      _searchQuery = '';
      _suggestedCategory = '';
      _showAISuggestions = false;
      _isFilterActive = false;
    });
  }

  void _applyFilters() {
    setState(() {
      _isFilterActive = _selectedStatus != null ||
          _selectedBudgetRange != null ||
          _selectedLocation != null ||
          _selectedDateRange != null ||
          _hasImages ||
          _selectedAICategory != null ||
          _searchQuery.isNotEmpty;
    });
    Navigator.pop(context);
  }

  // AI-powered search analysis
  Future<void> _analyzeSearchQuery() async {
    if (_searchQuery.trim().isEmpty) return;

    setState(() {
      _isAnalyzingSearch = true;
    });

    try {
      final category = await HuggingFaceService.classifyTask(_searchQuery);
      setState(() {
        _suggestedCategory = category;
        _showAISuggestions = true;
      });
    } catch (e) {
      print('AI search analysis failed: $e');
    } finally {
      setState(() {
        _isAnalyzingSearch = false;
      });
    }
  }

  void _applyAISuggestion() {
    setState(() {
      _selectedAICategory = _suggestedCategory;
      _showAISuggestions = false;
    });
  }

  Query<Map<String, dynamic>> _buildFilteredQuery() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('tasks')
        .orderBy('createdAt', descending: true);

    // Apply status filter
    if (_selectedStatus != null && _selectedStatus != 'All Status') {
      query = query.where('status', isEqualTo: _selectedStatus!.toLowerCase());
    }

    // Apply has images filter
    if (_hasImages) {
      query = query.where('hasImages', isEqualTo: true);
    }

    return query;
  }

  List<QueryDocumentSnapshot> _filterTasks(List<QueryDocumentSnapshot> tasks) {
    return tasks.where((doc) {
      final taskData = doc.data() as Map<String, dynamic>;
      
      // AI Category filter
      if (_selectedAICategory != null && _selectedAICategory != 'All Categories') {
        final aiCategory = taskData['aiCategory']?.toString() ?? '';
        if (aiCategory.toLowerCase() != _selectedAICategory!.toLowerCase()) {
          return false;
        }
      }

      // Search query filter (text search in title and description)
      if (_searchQuery.isNotEmpty) {
        final title = taskData['title']?.toString().toLowerCase() ?? '';
        final description = taskData['description']?.toString().toLowerCase() ?? '';
        final searchLower = _searchQuery.toLowerCase();
        
        if (!title.contains(searchLower) && !description.contains(searchLower)) {
          return false;
        }
      }
      
      // Budget filter
      if (_selectedBudgetRange != null && _selectedBudgetRange != 'Any Budget') {
        final budget = double.tryParse(taskData['budget']?.toString() ?? '0') ?? 0;
        switch (_selectedBudgetRange) {
          case 'Under Rs 50':
            if (budget >= 50) return false;
            break;
          case 'Rs 50 - Rs 100':
            if (budget < 50 || budget > 100) return false;
            break;
          case 'Rs 100 - Rs 200':
            if (budget < 100 || budget > 200) return false;
            break;
          case 'Rs 200 - Rs 500':
            if (budget < 200 || budget > 500) return false;
            break;
          case 'Over Rs 500':
            if (budget <= 500) return false;
            break;
        }
      }

      // Location filter
      if (_selectedLocation != null && _selectedLocation!.isNotEmpty) {
        final location = taskData['location']?.toString().toLowerCase() ?? '';
        if (!location.contains(_selectedLocation!.toLowerCase())) {
          return false;
        }
      }

      // Date filter
      if (_selectedDateRange != null && _selectedDateRange != 'Any Time') {
        final createdAt = taskData['createdAt'] as Timestamp?;
        if (createdAt == null) return false;
        
        final taskDate = createdAt.toDate();
        final now = DateTime.now();
        
        switch (_selectedDateRange) {
          case 'Today':
            if (!_isSameDay(taskDate, now)) return false;
            break;
          case 'This Week':
            final weekStart = now.subtract(Duration(days: now.weekday - 1));
            if (taskDate.isBefore(weekStart)) return false;
            break;
          case 'This Month':
            if (taskDate.month != now.month || taskDate.year != now.year) return false;
            break;
          case 'Last 7 Days':
            final weekAgo = now.subtract(const Duration(days: 7));
            if (taskDate.isBefore(weekAgo)) return false;
            break;
          case 'Last 30 Days':
            final monthAgo = now.subtract(const Duration(days: 30));
            if (taskDate.isBefore(monthAgo)) return false;
            break;
        }
      }

      return true;
    }).toList();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterModal(),
    );
  }

  Widget _buildFilterModal() {
    final responsive = context.responsive;
    return Container(
      height: responsive.value(mobile: MediaQuery.of(context).size.height * 0.8, tablet: 600, desktop: 700),
      padding: responsive.padding,
      constraints: BoxConstraints(maxWidth: responsive.value(mobile: double.infinity, tablet: 600, desktop: 800)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Tasks',
                style: TextStyle(
                  fontSize: responsive.value(mobile: 20.0, tablet: 24.0, desktop: 28.0),
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Filter Options
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AI-Powered Search
                  _buildAISearchFilter(),

                  const SizedBox(height: 20),

                  // AI Category Filter
                  _buildFilterSection(
                    'AI Categories',
                    _aiCategories,
                    _selectedAICategory,
                    (value) => setState(() => _selectedAICategory = value),
                  ),

                  const SizedBox(height: 20),

                  // Status Filter
                  _buildFilterSection(
                    'Status',
                    _statusOptions,
                    _selectedStatus,
                    (value) => setState(() => _selectedStatus = value),
                  ),

                  const SizedBox(height: 20),

                  // Budget Filter
                  _buildFilterSection(
                    'Budget Range',
                    _budgetRanges,
                    _selectedBudgetRange,
                    (value) => setState(() => _selectedBudgetRange = value),
                  ),

                  const SizedBox(height: 20),

                  // Date Filter
                  _buildFilterSection(
                    'Date Range',
                    _dateRanges,
                    _selectedDateRange,
                    (value) => setState(() => _selectedDateRange = value),
                  ),

                  const SizedBox(height: 20),

                  // Location Filter
                  _buildLocationFilter(),

                  const SizedBox(height: 20),

                  // Has Images Filter
                  _buildHasImagesFilter(),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetFilters,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFF00C7BE)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      color: Color(0xFF00C7BE),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C7BE),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(
    String title,
    List<String> options,
    String? selectedValue,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedValue == option;
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                onChanged(selected ? option : null);
              },
              selectedColor: const Color(0xFF00C7BE).withOpacity(0.2),
              checkmarkColor: const Color(0xFF00C7BE),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF00C7BE) : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF00C7BE) : Colors.grey[300]!,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLocationFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: InputDecoration(
            hintText: 'Enter location (e.g., Lahore, Karachi)',
            prefixIcon: const Icon(Icons.location_on),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[100],
          ),
          onChanged: (value) => setState(() => _selectedLocation = value),
        ),
      ],
    );
  }

  Widget _buildAISearchFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFF00C7BE)),
            const SizedBox(width: 8),
            const Text(
              'AI-Powered Search',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: InputDecoration(
            hintText: 'Search tasks naturally (e.g., "cleaning jobs", "help with moving")',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _isAnalyzingSearch
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF00C7BE),
                      ),
                    ),
                  )
                : _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _showAISuggestions = false;
                          });
                        },
                      )
                    : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[100],
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
              _showAISuggestions = false;
            });
            // Debounce the AI analysis
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_searchQuery == value && value.trim().isNotEmpty) {
                _analyzeSearchQuery();
              }
            });
          },
        ),
        
        // AI Suggestions
        if (_showAISuggestions && _suggestedCategory.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00C7BE).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF00C7BE).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb, color: Color(0xFF00C7BE), size: 16),
                const SizedBox(width: 8),
                                 Expanded(
                   child: Text(
                     'AI suggests: $_suggestedCategory',
                     style: GoogleFonts.poppins(
                       fontSize: 14,
                       fontWeight: FontWeight.w500,
                     ),
                   ),
                 ),
                TextButton(
                  onPressed: _applyAISuggestion,
                  child: const Text(
                    'Apply',
                    style: TextStyle(
                      color: Color(0xFF00C7BE),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHasImagesFilter() {
    return Row(
      children: [
        Switch(
          value: _hasImages,
          onChanged: (value) => setState(() => _hasImages = value),
          activeColor: const Color(0xFF00C7BE),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Tasks with Images Only',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Browse Tasks", 
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: responsive.value(mobile: 18.0, tablet: 20.0, desktop: 22.0),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          // Filter Button
          IconButton(
            onPressed: _showFilterModal,
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (_isFilterActive)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFF00C7BE),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 8,
                        minHeight: 8,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Filter Tasks',
          ),
          // Button to view posted tasks
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TaskMapScreen(showPostedTasks: true),
                ),
              );
            },
            icon: const Icon(Icons.my_location),
            tooltip: 'View My Posted Tasks',
          ),
          // Button to view all tasks on map
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TaskMapScreen()),
              );
            },
            icon: const Icon(Icons.map),
            tooltip: 'View All Tasks on Map',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: responsive.maxContentWidth),
          child: Column(
            children: [
              // Search Bar
              Container(
                padding: responsive.padding,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search tasks... (AI-powered)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isAnalyzingSearch
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF00C7BE),
                          ),
                        ),
                      )
                    : _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _showAISuggestions = false;
                              });
                            },
                          )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _showAISuggestions = false;
                });
                // Debounce the AI analysis
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchQuery == value && value.trim().isNotEmpty) {
                    _analyzeSearchQuery();
                  }
                });
              },
            ),
          ),

          // AI Suggestions
          if (_showAISuggestions && _suggestedCategory.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00C7BE).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF00C7BE).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFF00C7BE), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI suggests category: $_suggestedCategory',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _applyAISuggestion,
                    child: const Text(
                      'Apply',
                      style: TextStyle(
                        color: Color(0xFF00C7BE),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Filter Summary
          if (_isFilterActive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF00C7BE).withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(
                    Icons.filter_list,
                    size: 16,
                    color: Color(0xFF00C7BE),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filters applied',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF00C7BE),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _resetFilters,
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        color: Color(0xFF00C7BE),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Tasks List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildFilteredQuery().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      "Error loading tasks",
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: 5,
                    itemBuilder: (context, index) => ShimmerLoading.taskCard(),
                  );
                }

                final tasks = snapshot.data?.docs ?? [];
                final filteredTasks = _filterTasks(tasks);

                if (filteredTasks.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.filter_list_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isFilterActive ? 'No tasks match your filters' : 'No tasks available',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isFilterActive 
                                ? 'Try adjusting your filter criteria'
                                : 'There are currently no tasks posted in your area. Check back later!',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                          if (_isFilterActive) ...[
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _resetFilters,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00C7BE),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text(
                                'Clear Filters',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final taskData = filteredTasks[index].data() as Map<String, dynamic>;
                    final taskId = filteredTasks[index].id;
                    final userId = taskData['userId'];
                    final status = taskData['status'] ?? 'open';
                    final createdAt = (taskData['createdAt'] as Timestamp?)?.toDate();
                    final formattedDate = createdAt != null 
                        ? DateFormat('MMM d, yyyy').format(createdAt) 
                        : 'No date';

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TaskDetailsScreen(taskId: taskId),
                          ),
                        );
                      },
                      child: Card(
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status Badge
                              Row(
                                children: [
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: status == 'open' 
                                            ? const Color(0xFF00C7BE).withOpacity(0.2)
                                            : Colors.grey.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: status == 'open' 
                                              ? const Color(0xFF00C7BE)
                                              : Colors.grey,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Title & Budget with Avatar
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      taskData['title'] ?? 'No title',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: true,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      // Avatar above price
                                      StreamBuilder<DocumentSnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(userId)
                                            .snapshots(),
                                        builder: (context, userSnapshot) {
                                          if (!userSnapshot.hasData) {
                                            return const CircleAvatar(
                                              radius: 25,
                                              backgroundColor: Colors.grey,
                                              child: Icon(Icons.person, size: 25, color: Colors.white),
                                            );
                                          }
                                          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                                          final photoUrl = userData?['profileImageUrl'];
                                          
                                          return Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: const Color(0xFF00C7BE).withOpacity(0.3),
                                                width: 2,
                                              ),
                                            ),
                                            child: CircleAvatar(
                                              radius: 25,
                                              backgroundColor: Colors.grey[200],
                                              backgroundImage: photoUrl != null
                                                  ? CachedNetworkImageProvider(photoUrl)
                                                  : null,
                                              child: photoUrl == null
                                                  ? const Icon(Icons.person, size: 25, color: Colors.grey)
                                                  : null,
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 10),
                                      // Price below avatar
                                      Text(
                                        "Rs ${taskData['budget'] ?? '0'}",
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF00C7BE),
                                        ),
                                        textAlign: TextAlign.end,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Location
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      taskData['location'] ?? 'No location',
                                      style: const TextStyle(fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),

                              // Date & Time
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      formattedDate,
                                      style: const TextStyle(fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (taskData['time'] != null) ...[
                                    const Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        taskData['time']!,
                                        style: const TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
      ),
    );
  }
}
