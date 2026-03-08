import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AddBalance extends StatefulWidget {
  const AddBalance({super.key});

  @override
  State<AddBalance> createState() => _AddBalanceState();
}

class _AddBalanceState extends State<AddBalance> {
  DateTime? _selectedDate;
  final TextEditingController _balanceController = TextEditingController();
  final TextEditingController _merchantController = TextEditingController();

  // Define theme colors
  final Color primaryColor = const Color(0xFF27AE60);
  final Color accentColor = const Color(0xFFE8F5E9);
  final Color textColor = const Color(0xFF424242);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: textColor,
        title: Text(
          'Add Balance',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, accentColor.withOpacity(0.3)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter your current balance',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This will help us track your expenses better',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),

                // Amount Field
                _buildInputField(
                  controller: _balanceController,
                  label: 'Amount',
                  prefixIcon: Icons.monetization_on_outlined,
                  hint: '0.00',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),

                const SizedBox(height: 40),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _submitExpense,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Add Balance',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(
          fontSize: 16,
          color: textColor,
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            color: Colors.grey[400],
          ),
          labelText: label,
          labelStyle: GoogleFonts.inter(
            color: Colors.grey[600],
            fontSize: 14,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: primaryColor,
            size: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 1.5),
          ),
        ),
      ),
    );
  }

  void _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: textColor,
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _submitExpense() {
    // Parse the balance value and validate input
    final parsedAmount = double.tryParse(_balanceController.text);
    if (parsedAmount != null) {
      // Skip creating expenses document and directly return to previous screen
      // with the amount to be added to balance

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Amount added to balance'),
          backgroundColor: primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Return to previous screen with the amount
      Navigator.pop(context, parsedAmount);
    } else {
      // Handle invalid input
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}
