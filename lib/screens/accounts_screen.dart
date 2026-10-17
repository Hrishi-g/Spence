import 'package:flutter/material.dart';
import '../state/expense_state.dart';
import '../theme/app_theme.dart';
import 'all_accounts_modal.dart';
import 'month_year_picker_modal.dart';
import 'category_details_screen.dart';

class AccountsScreen extends StatefulWidget {
  final ExpenseState expenseState;

  const AccountsScreen({super.key, required this.expenseState});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  @override
  void initState() {
    super.initState();
    widget.expenseState.addListener(_onStateChanged);
  }

  @override
  void didUpdateWidget(covariant AccountsScreen oldWidget) {
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

  void _openMonthYearPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MonthYearPickerModal(
        initialDate: widget.expenseState.selectedMonth,
        onSelected: (date) {
          setState(() {
            widget.expenseState.selectedMonth = date;
          });
        },
      ),
    );
  }

  String _formatMonthYear(DateTime dt) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  String _formatMonthName(DateTime dt) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[dt.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.expenseState;
    final accounts = state.allAccounts;
    final monthTransactions = state.selectedMonthTransactions;
    final totalMonthExpense = state.monthlyExpensesTotal;
    final monthName = _formatMonthName(state.selectedMonth);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        title: GestureDetector(
          onTap: () => _openMonthYearPicker(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Accounts • ${_formatMonthYear(state.selectedMonth)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_drop_down,
                color: AppTheme.accentGold,
                size: 22,
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: AppTheme.accentGold,
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => AllAccountsModal(
                  selectedAccount: accounts.first,
                  expenseState: state,
                  onSelectAccount: (acc) {},
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Top Month Account Summary Banner
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL MONTH SPENT • ${monthName.toUpperCase()}',
                        style: const TextStyle(
                          color: AppTheme.secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₹${totalMonthExpense.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'All-time account totals available in Reports',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppTheme.accentGold,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),

            // Accounts List with Monthly Spending
            ...accounts.map((acc) {
              final accountSpent = state.getAccountMonthlyExpense(acc.id);
              final accountTransactions = monthTransactions
                  .where((tx) => tx.account.id == acc.id)
                  .toList();

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
                            periodTitle: _formatMonthYear(state.selectedMonth),
                            totalSpent: accountSpent,
                            totalOverallSpent: totalMonthExpense,
                            transactions: accountTransactions,
                            isAccount: true,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
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
                                  '${accountTransactions.length} expenses in $monthName',
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
                                '$monthName spent',
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
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
}
