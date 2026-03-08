import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expenses_tracker/screens/home/add_balance.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expenses_tracker/l10n/language_provider.dart';
import 'package:provider/provider.dart';

class Balance extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _BalanceState();
}

class _BalanceState extends State<Balance> {
  double amount = 0.0;
  double lastExpenseAmount = 0.0;
  late Stream<DocumentSnapshot> _balanceStream;
  Stream<QuerySnapshot>? _expensesStream;

  @override
  void initState() {
    super.initState();
    _initBalanceStream();
    _initLastExpenseStream();
  }

  void _initBalanceStream() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _balanceStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots();

      // Listen to changes in the balance
      _balanceStream.listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>?;
          if (data != null && data['balance'] != null) {
            setState(() {
              amount = (data['balance'] as num).toDouble();
            });
          }
        }
      });
    } else {
      // If not logged in, initialize with 0
      setState(() {
        amount = 0.0;
      });
    }
  }

  void _initLastExpenseStream() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _expensesStream = FirebaseFirestore.instance
          .collection('expenses')
          .where('userId', isEqualTo: user.uid)
          .orderBy('date', descending: true)
          .limit(1)
          .snapshots();

      // Listen to changes in the expenses collection
      _expensesStream?.listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final data = snapshot.docs.first.data() as Map<String, dynamic>?;
          if (data != null && data['amount'] != null) {
            setState(() {
              lastExpenseAmount = (data['amount'] as num).toDouble();
            });
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isRTL = languageProvider.locale.languageCode == 'ar';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromRGBO(224, 255, 213, 1),
            const Color.fromRGBO(179, 229, 164, 1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      margin: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    isRTL ? "الرصيد الحالي" : "Current Balance",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!isRTL)
                    Image.asset(
                      "assets/Saudi_Riyal_Symbol-1.png",
                      width: 24,
                      height: 24,
                    ),
                  if (!isRTL) SizedBox(width: 5),
                  Text(
                    "${amount.floor()}",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w900,
                      fontSize: 38,
                      color: Colors.black87,
                    ),
                  ),
                  if (isRTL) SizedBox(width: 5),
                  if (isRTL)
                    Image.asset(
                      "assets/Saudi_Riyal_Symbol-1.png",
                      width: 24,
                      height: 24,
                    ),
                ],
              ),
              if (lastExpenseAmount > 0)
                Container(
                  margin: EdgeInsets.only(top: 8),
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_downward,
                        size: 14,
                        color: Colors.red,
                      ),
                      SizedBox(width: 4),
                      Text(
                        isRTL
                            ? "${lastExpenseAmount.toStringAsFixed(2)}"
                            : "${lastExpenseAmount.toStringAsFixed(2)}",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.red,
                        ),
                      ),
                      if (!isRTL) SizedBox(width: 4),
                      ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          Colors.red,
                          BlendMode.srcIn,
                        ),
                        child: Image.asset(
                          "assets/Saudi_Riyal_Symbol-1.png",
                          width: 14,
                          height: 14,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () async {
                final expense = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddBalance()),
                );
                if (expense != null) {
                  // No need to update local state here since we're already listening to Firestore
                  // Updates from the AddBalance screen will be automatically reflected

                  // Update the balance in Firestore
                  final User? user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    // Get current balance to avoid race conditions
                    final doc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .get();

                    final data = doc.data();
                    double currentBalance = 0.0;
                    if (data != null && data['balance'] != null) {
                      currentBalance = (data['balance'] as num).toDouble();
                    }

                    // Update with the new total balance
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({'balance': currentBalance + expense});
                  }
                }
              },
              icon: Icon(
                Icons.add,
                size: 30,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
