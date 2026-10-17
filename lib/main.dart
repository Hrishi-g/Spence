import 'package:flutter/material.dart';
import 'state/expense_state.dart';
import 'theme/app_theme.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final expenseState = ExpenseState();
  await expenseState.initialize();
  runApp(ExpenseTrackerApp(expenseState: expenseState));
}

class ExpenseTrackerApp extends StatefulWidget {
  final ExpenseState? expenseState;
  const ExpenseTrackerApp({super.key, this.expenseState});

  @override
  State<ExpenseTrackerApp> createState() => _ExpenseTrackerAppState();
}

class _ExpenseTrackerAppState extends State<ExpenseTrackerApp> {
  late final ExpenseState _expenseState;

  @override
  void initState() {
    super.initState();
    _expenseState = widget.expenseState ?? ExpenseState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: MainNavigationScreen(expenseState: _expenseState),
    );
  }
}
