import 'package:flutter/material.dart';
import '../state/expense_state.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'reports_screen.dart';
import 'accounts_screen.dart';
import 'insights_screen.dart';
import 'add_expense_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final ExpenseState expenseState;

  const MainNavigationScreen({super.key, required this.expenseState});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  int _pageVersion = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.expenseState.resetToCurrentDate();
      setState(() {
        _pageVersion++;
      });
    }
  }

  void _onNavTap(int index) {
    widget.expenseState.resetToCurrentDate();
    setState(() {
      if (_currentIndex != index) {
        _currentIndex = index;
      }
      _pageVersion++;
    });
  }

  void _openAddExpensePage([DateTime? date]) {
    final targetDate = date ?? widget.expenseState.selectedCalendarDate;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (routeCtx) => AddExpenseScreen(
          expenseState: widget.expenseState,
          initialDate: targetDate,
          onExpenseAdded: () {
            widget.expenseState.resetToCurrentDate();
            Navigator.of(context).popUntil((route) => route.isFirst);
            setState(() {
              _currentIndex = 0;
              _pageVersion++;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeScreen(
        key: ValueKey('home_$_pageVersion'),
        expenseState: widget.expenseState,
        onAddExpenseTap: _openAddExpensePage,
      ),
      ReportsScreen(
        key: ValueKey('reports_$_pageVersion'),
        expenseState: widget.expenseState,
      ),
      const SizedBox.shrink(), // Index 2 is center '+' button
      AccountsScreen(
        key: ValueKey('accounts_$_pageVersion'),
        expenseState: widget.expenseState,
      ),
      InsightsScreen(
        key: ValueKey('insights_$_pageVersion'),
        expenseState: widget.expenseState,
      ),
    ];

    return Scaffold(
      body: AnimatedBuilder(
        animation: widget.expenseState,
        builder: (context, _) {
          return IndexedStack(
            index: _currentIndex == 2 ? 0 : _currentIndex,
            children: pages,
          );
        },
      ),

      // FIXED BOTTOM NAVIGATION BAR MATCHING SCREENSHOTS
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
        ),
        child: SafeArea(
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(icon: Icons.home_filled, label: 'Home', index: 0),
                _buildNavItem(icon: Icons.insert_chart_outlined, label: 'Reports', index: 1),

                // CENTER HIGHLIGHTED GOLDEN '+' FAB
                GestureDetector(
                  onTap: _openAddExpensePage,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentGold.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.black,
                      size: 28,
                    ),
                  ),
                ),

                _buildNavItem(icon: Icons.account_balance_wallet_outlined, label: 'Accounts', index: 3),
                _buildNavItem(icon: Icons.pie_chart_outline_rounded, label: 'Insights', index: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => _onNavTap(index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.accentGold : AppTheme.secondaryText,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.accentGold : AppTheme.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
