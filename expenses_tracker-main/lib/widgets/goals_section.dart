import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expenses_tracker/models/goal.dart';
import 'package:expenses_tracker/widgets/goals_header.dart';
import 'package:expenses_tracker/widgets/goal_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expenses_tracker/l10n/language_provider.dart';
import 'package:provider/provider.dart';

class GoalsSection extends StatefulWidget {
  GoalsSection({super.key});

  @override
  _GoalsSectionState createState() => _GoalsSectionState();
}

class _GoalsSectionState extends State<GoalsSection> {
  List<Goal> goals = [];
  Timer? timer;
  DateTime lastIncreaseDate = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(Duration(days: 30), (timer) {
      checkAndIncreaseGoals();
    });
    loadGoals();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String getUserId() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid ?? 'anonymous';
  }

  void addGoal(String title, int targetAmount, int monthlySavings,
      int? currentAmount) async {
    final newGoal = Goal(
      title: title,
      currentAmount: 0,
      targetAmount: targetAmount,
      monthlySavings: monthlySavings,
    );
    setState(() {
      goals.add(newGoal);
    });
    await FirebaseFirestore.instance.collection('goals').add({
      'userId': getUserId(),
      'title': title,
      'currentAmount': currentAmount,
      'targetAmount': targetAmount,
      'monthlySavings': monthlySavings,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  void increaseGoals() {
    setState(() {
      for (var goal in goals) {
        if (goal.currentAmount < goal.targetAmount) {
          goal.currentAmount += goal.monthlySavings;
          if (goal.currentAmount > goal.targetAmount) {
            goal.currentAmount = goal.targetAmount;
          }
        }
      }
      lastIncreaseDate = DateTime.now();
    });
  }

  void checkAndIncreaseGoals() {
    if (DateTime.now().difference(lastIncreaseDate).inDays >= 30) {
      increaseGoals();
    }
  }

  void loadGoals() async {
    setState(() => _isLoading = true);

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('goals')
          .where('userId', isEqualTo: getUserId())
          .get();

      final loadedGoals = querySnapshot.docs
          .map((doc) => Goal(
                id: doc.id,
                title: doc['title'],
                currentAmount: doc['currentAmount'],
                targetAmount: doc['targetAmount'],
                monthlySavings: doc['monthlySavings'],
              ))
          .toList();

      setState(() {
        goals = loadedGoals;
        _isLoading = false;
      });
    } catch (error) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      // Delete from Firestore
      await FirebaseFirestore.instance.collection('goals').doc(goalId).delete();

      // Delete from local state
      setState(() {
        goals.removeWhere((goal) => goal.id == goalId);
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Provider.of<LanguageProvider>(context, listen: false)
                        .locale
                        .languageCode ==
                    'ar'
                ? 'حدث خطأ أثناء حذف الهدف'
                : 'Error deleting goal',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isRTL = languageProvider.locale.languageCode == 'ar';

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              spreadRadius: 1,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(18),
        margin: EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isRTL ? 'أهدافك' : 'Your Goals',
                  style: GoogleFonts.poppins(
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                GoalsHeader(onAddGoal: () => showAddGoalDialog(context)),
              ],
            ),
            SizedBox(height: 20),
            if (_isLoading)
              Center(
                child: CircularProgressIndicator(
                  color: Colors.blue.shade400,
                ),
              )
            else if (goals.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: 8),
                    Text(
                      isRTL ? 'لا توجد أهداف بعد' : 'No goals yet',
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      isRTL
                          ? 'أضف هدفًا لبدء التتبع'
                          : 'Add a goal to start tracking',
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...goals.map((goal) {
                return Dismissible(
                  key: Key(goal.id),
                  background: Container(
                    color: Colors.red,
                    alignment:
                        isRTL ? Alignment.centerLeft : Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  secondaryBackground: Container(
                    color: Colors.red,
                    alignment:
                        isRTL ? Alignment.centerRight : Alignment.centerLeft,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(
                            isRTL ? 'تأكيد الحذف' : 'Confirm Deletion',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          content: Text(
                            isRTL
                                ? 'هل أنت متأكد من رغبتك في حذف هذا الهدف؟'
                                : 'Are you sure you want to delete this goal?',
                            style: GoogleFonts.poppins(),
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(
                                isRTL ? 'إلغاء' : 'Cancel',
                                style: GoogleFonts.poppins(),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(
                                isRTL ? 'حذف' : 'Delete',
                                style: GoogleFonts.poppins(
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  onDismissed: (direction) {
                    deleteGoal(goal.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isRTL ? 'تم حذف الهدف' : 'Goal deleted',
                          style: GoogleFonts.poppins(),
                        ),
                        backgroundColor: Colors.blue.shade400,
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  child: GoalCard(
                    title: goal.title,
                    currentAmount: goal.currentAmount,
                    targetAmount: goal.targetAmount,
                    monthlySavings: goal.monthlySavings,
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  void showAddGoalDialog(BuildContext context) {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final isRTL = languageProvider.locale.languageCode == 'ar';

    String title = '';
    int targetAmount = 0;
    int monthlySavings = 0;
    int currentAmount = 0;

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            title: Text(
              isRTL ? 'إضافة هدف' : 'Add Goal',
              style: GoogleFonts.poppins(
                color: Colors.blue.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Container(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    onChanged: (value) => title = value,
                    decoration: InputDecoration(
                      labelText: isRTL ? 'عنوان الهدف' : 'Goal Title',
                      labelStyle: GoogleFonts.poppins(
                        color: Colors.blue.shade700,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade400),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    onChanged: (value) =>
                        targetAmount = int.tryParse(value) ?? 0,
                    decoration: InputDecoration(
                      labelText: isRTL ? 'المبلغ المستهدف' : 'Target Amount',
                      labelStyle: GoogleFonts.poppins(
                        color: Colors.blue.shade700,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade400),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    onChanged: (value) =>
                        monthlySavings = int.tryParse(value) ?? 0,
                    decoration: InputDecoration(
                      labelText: isRTL ? 'المدخرات الشهرية' : 'Monthly Savings',
                      labelStyle: GoogleFonts.poppins(
                        color: Colors.blue.shade700,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade400),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    onChanged: (value) =>
                        currentAmount = int.tryParse(value) ?? 0,
                    decoration: InputDecoration(
                      labelText: isRTL ? 'المبلغ الحالي' : 'Current Amount',
                      labelStyle: GoogleFonts.poppins(
                        color: Colors.blue.shade700,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade400),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  isRTL ? 'إلغاء' : 'Cancel',
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (title.trim().isEmpty ||
                      targetAmount <= 0 ||
                      monthlySavings <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isRTL
                              ? 'العنوان والمبلغ المستهدف والمدخرات الشهرية مطلوبة.'
                              : 'Title, Target Amount and Monthly Savings are required.',
                          style: GoogleFonts.poppins(),
                        ),
                        backgroundColor: Colors.red.shade400,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                    return;
                  }
                  addGoal(title, targetAmount, monthlySavings, currentAmount);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(
                  isRTL ? 'إضافة' : 'Add',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
