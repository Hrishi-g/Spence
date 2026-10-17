import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../state/expense_state.dart';
import '../theme/app_theme.dart';
import 'category_details_screen.dart';

class InsightsScreen extends StatefulWidget {
  final ExpenseState expenseState;

  const InsightsScreen({super.key, required this.expenseState});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  int _selectedTabIndex = 0; // 0: Total Spent (Accounts), 1: Total Expense (Categories)

  @override
  void initState() {
    super.initState();
    widget.expenseState.addListener(_onStateChanged);
  }

  @override
  void didUpdateWidget(covariant InsightsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expenseState != widget.expenseState) {
      oldWidget.expenseState.removeListener(_onStateChanged);
      widget.expenseState.addListener(_onStateChanged);
    }
  }

  @override
  void dispose() {
    widget.expenseState.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.expenseState;
    final double lifetimeTotal = state.totalExpenses;

    // Accounts sorted by lifetime spend descending
    final sortedAccounts = List<AccountItem>.from(state.allAccounts)
      ..sort((a, b) {
        final spentA = state.getAccountTotalExpense(a.id);
        final spentB = state.getAccountTotalExpense(b.id);
        final comp = spentB.compareTo(spentA);
        if (comp != 0) return comp;
        return a.displayName.compareTo(b.displayName);
      });

    // Categories sorted by lifetime spend descending
    final sortedCategories = List<CategoryItem>.from(state.allCategories)
      ..sort((a, b) {
        final spentA = state.getCategoryTotalExpense(a.id);
        final spentB = state.getCategoryTotalExpense(b.id);
        final comp = spentB.compareTo(spentA);
        if (comp != 0) return comp;
        return a.displayName.compareTo(b.displayName);
      });

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        title: const Text(
          'Insights',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // TOP SWITCHER: Total Spent vs Total Expense
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSegmentButton(
                      title: 'Total Spent',
                      icon: Icons.account_balance_wallet_outlined,
                      index: 0,
                    ),
                  ),
                  Expanded(
                    child: _buildSegmentButton(
                      title: 'Total Expense',
                      icon: Icons.pie_chart_outline_rounded,
                      index: 1,
                    ),
                  ),
                ],
              ),
            ),

            // SUMMARY BANNER (Matching Total Amount)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedTabIndex == 0
                              ? 'TOTAL SPENT TILL DATE'
                              : 'TOTAL EXPENSE TILL DATE',
                          style: const TextStyle(
                            color: AppTheme.secondaryText,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '₹${lifetimeTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedTabIndex == 0
                              ? 'All-time spending across all accounts'
                              : 'All-time expenses across all categories',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _selectedTabIndex == 0
                          ? Icons.account_balance_wallet_outlined
                          : Icons.pie_chart_outline_rounded,
                      color: AppTheme.accentGold,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),

            // SECTION HEADER
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedTabIndex == 0
                        ? 'All Accounts'
                        : 'All Categories',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _selectedTabIndex == 0
                        ? '${sortedAccounts.length} accounts'
                        : '${sortedCategories.length} categories',
                    style: const TextStyle(
                      color: AppTheme.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // LIST OF ACCOUNTS (Total Spent View)
            if (_selectedTabIndex == 0)
              ...sortedAccounts.map((acc) {
                final accountSpent = state.getAccountTotalExpense(acc.id);
                final accountTransactions = state.getAccountTransactions(acc.id);
                final percentage = lifetimeTotal > 0
                    ? (accountSpent / lifetimeTotal * 100)
                    : 0.0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoryDetailsScreen(
                              title: acc.displayName,
                              icon: acc.icon,
                              color: acc.color,
                              periodTitle: 'All Time',
                              totalSpent: accountSpent,
                              totalOverallSpent: lifetimeTotal,
                              transactions: accountTransactions,
                              isAccount: true,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: acc.color.withOpacity(0.18),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(acc.icon, color: acc.color, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        acc.displayName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${accountTransactions.length} expenses till date',
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${accountSpent.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: accountSpent > 0
                                            ? Colors.white
                                            : Colors.white38,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${percentage.toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        color: AppTheme.secondaryText,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (lifetimeTotal > 0 && accountSpent > 0) ...[
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (accountSpent / lifetimeTotal).clamp(0.0, 1.0),
                                  backgroundColor: AppTheme.surfaceLight,
                                  valueColor: AlwaysStoppedAnimation<Color>(acc.color),
                                  minHeight: 4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),

            // LIST OF CATEGORIES (Total Expense View)
            if (_selectedTabIndex == 1)
              ...sortedCategories.map((cat) {
                final categorySpent = state.getCategoryTotalExpense(cat.id);
                final categoryTransactions = state.getCategoryTransactions(cat.id);
                final percentage = lifetimeTotal > 0
                    ? (categorySpent / lifetimeTotal * 100)
                    : 0.0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoryDetailsScreen(
                              title: cat.displayName,
                              icon: cat.icon,
                              color: cat.color,
                              periodTitle: 'All Time',
                              totalSpent: categorySpent,
                              totalOverallSpent: lifetimeTotal,
                              transactions: categoryTransactions,
                              isAccount: false,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: cat.color.withOpacity(0.18),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(cat.icon, color: cat.color, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cat.displayName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${categoryTransactions.length} expenses till date',
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${categorySpent.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: categorySpent > 0
                                            ? Colors.white
                                            : Colors.white38,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${percentage.toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        color: AppTheme.secondaryText,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (lifetimeTotal > 0 && categorySpent > 0) ...[
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (categorySpent / lifetimeTotal).clamp(0.0, 1.0),
                                  backgroundColor: AppTheme.surfaceLight,
                                  valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                                  minHeight: 4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton({
    required String title,
    required IconData icon,
    required int index,
  }) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentGold : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.black : AppTheme.secondaryText,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.black : AppTheme.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
