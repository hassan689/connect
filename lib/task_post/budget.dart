import 'dart:io';
import 'package:flutter/material.dart';
import 'package:linkster/task_post/finalscree.dart';
import 'package:linkster/l10n/app_localizations.dart';
import 'title.dart'; // Your custom app bar

class DecideBudgetScreen extends StatefulWidget {
  final String taskTitle;
  final DateTime? selectedDate;
  final String location;
  final String description;
  final double latitude ;
  final double longitude;
  final String dateOption;
  final List<File>? imageFiles;
  final String taskType;
  final String? suggestedCategory;
  
  const DecideBudgetScreen({
    super.key,
    required this.taskType,
    required this.dateOption,
    required this.longitude,
    required this.latitude,
    required this.taskTitle,
    required this.selectedDate,
    required this.location,
    required this.description,
    this.imageFiles,
    this.suggestedCategory,
  });

  @override
  State<DecideBudgetScreen> createState() => _DecideBudgetScreenState();
}

class _DecideBudgetScreenState extends State<DecideBudgetScreen> {
  final TextEditingController _budgetController = TextEditingController();
  bool _isBudgetNotEmpty = false;

  @override
  void initState() {
    super.initState();
    _budgetController.addListener(() {
      if (mounted) {
        setState(() {
          _isBudgetNotEmpty = _budgetController.text.isNotEmpty;
        });
      }
    });
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white ,
      appBar: CustomAppBar(step: 6),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)?.getString('what_is_your_budget') ?? 'What is your budget?',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Display selected images (if any)
            if (widget.imageFiles != null && widget.imageFiles!.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.imageFiles?.length ?? 0,
                  itemBuilder: (context, index) {
                    final imageFiles = widget.imageFiles;
                    if (imageFiles == null || index >= imageFiles.length) return const SizedBox.shrink();
                    
                    final imageFile = imageFiles[index];
                    if (imageFile == null) return const SizedBox.shrink();
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          imageFile,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),

            // Budget Input Field
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)?.getString('enter_budget') ?? 'Enter budget',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.monetization_on),
              ),
            ),

            const Spacer(),

            // Updated Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isBudgetNotEmpty
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FinalSummaryScreen(
                                taskType: widget.taskType,
                                taskTitle: widget.taskTitle,
                                longitude: widget.longitude,
                                latitude: widget.latitude,
                                selectedDate: widget.selectedDate,
                                location: widget.location,
                                description: widget.description,
                                imageFiles: widget.imageFiles,
                                budget: _budgetController.text.isNotEmpty ? _budgetController.text : '0',
                                dateOption:widget.dateOption,
                                suggestedCategory: widget.suggestedCategory,
                              ),
                            ),
                          );

                          // Optional Alert (you can remove if not needed)
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(AppLocalizations.of(context)?.getString('budget_selected') ?? 'Budget Selected'),
                              content: Text(
                                  "${AppLocalizations.of(context)?.getString('you_entered') ?? 'You entered'} ${_budgetController.text}"),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(AppLocalizations.of(context)?.getString('ok') ?? 'OK'),
                                ),
                              ],
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isBudgetNotEmpty
                        ? const Color(0xFF00C7BE)
                        : Colors.grey, // Disabled color
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)?.getString('next') ?? 'Next',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
