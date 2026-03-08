class Goal {
  String id;
  String title;
  int currentAmount;
  int targetAmount;
  int monthlySavings;

  Goal({
    this.id = '',
    required this.title,
    required this.currentAmount,
    required this.targetAmount,
    required this.monthlySavings,
  });
}
