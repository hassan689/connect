// import 'package:flutter/material.dart';

// class AddBankAccountScreen extends StatefulWidget {
//   const AddBankAccountScreen({super.key});

//   @override
//   State<AddBankAccountScreen> createState() => _AddBankAccountScreenState();
// }

// class _AddBankAccountScreenState extends State<AddBankAccountScreen> {
//   final TextEditingController _accountNameController = TextEditingController();
//   final TextEditingController _bsbController = TextEditingController();
//   final TextEditingController _accountNumberController = TextEditingController();

//   void _handleAdd() {
//     final name = _accountNameController.text;
//     final bsb = _bsbController.text;
//     final accountNumber = _accountNumberController.text;

//     if (name.isEmpty || bsb.isEmpty || accountNumber.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please fill all fields')),
//       );
//       return;
//     }

//     // Save the account info (e.g., to Firebase or local state)
//     print("Account Name: $name, BSB: $bsb, Account Number: $accountNumber");

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Bank account added successfully')),
//     );

//     Navigator.pop(context); // Optionally go back
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Add bank account"),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text("Account name", style: TextStyle(fontWeight: FontWeight.bold)),
//             const SizedBox(height: 8),
//             TextField(
//               controller: _accountNameController,
//               decoration: const InputDecoration(
//                 filled: true,
//                 fillColor: Color(0xFFF0F0F0),
//                 border: OutlineInputBorder(borderSide: BorderSide.none),
//               ),
//             ),
//             const SizedBox(height: 20),
//             Row(
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text("BSB", style: TextStyle(fontWeight: FontWeight.bold)),
//                       const SizedBox(height: 8),
//                       TextField(
//                         controller: _bsbController,
//                         decoration: const InputDecoration(
//                           filled: true,
//                           fillColor: Color(0xFFF0F0F0),
//                           border: OutlineInputBorder(borderSide: BorderSide.none),
//                         ),
//                         keyboardType: TextInputType.number,
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text("Account number", style: TextStyle(fontWeight: FontWeight.bold)),
//                       const SizedBox(height: 8),
//                       TextField(
//                         controller: _accountNumberController,
//                         decoration: const InputDecoration(
//                           filled: true,
//                           fillColor: Color(0xFFF0F0F0),
//                           border: OutlineInputBorder(borderSide: BorderSide.none),
//                         ),
//                         keyboardType: TextInputType.number,
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//       bottomNavigationBar: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: ElevatedButton(
//           onPressed: _handleAdd,
//           style: ElevatedButton.styleFrom(
//             minimumSize: const Size.fromHeight(50),
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
//             backgroundColor: Colors.blue,
//           ),
//           child: const Text("Add", style: TextStyle(fontSize: 16)),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';

class AddBankAccountScreen extends StatefulWidget {
  const AddBankAccountScreen({super.key});

  @override
  State<AddBankAccountScreen> createState() => _AddBankAccountScreenState();
}

class _AddBankAccountScreenState extends State<AddBankAccountScreen> {
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _bsbController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();

  void _handleAdd() {
    final name = _accountNameController.text.trim();
    final bsb = _bsbController.text.trim();
    final accountNumber = _accountNumberController.text.trim();

    if (name.isEmpty || bsb.isEmpty || accountNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final accountInfo = '''
Account Name: $name
BSB: $bsb
Account Number: $accountNumber
'''.trim();

    Navigator.pop(context, accountInfo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add bank account"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Account name", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _accountNameController,
              decoration: const InputDecoration(
                filled: true,
                fillColor: Color(0xFFF0F0F0),
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("BSB", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _bsbController,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Color(0xFFF0F0F0),
                          border: OutlineInputBorder(borderSide: BorderSide.none),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Account number", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _accountNumberController,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Color(0xFFF0F0F0),
                          border: OutlineInputBorder(borderSide: BorderSide.none),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _handleAdd,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            backgroundColor: Colors.blue,
          ),
          child: const Text("Add", style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}
