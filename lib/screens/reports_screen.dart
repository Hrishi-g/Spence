import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../state/expense_state.dart';
import '../theme/app_theme.dart';
import 'month_year_picker_modal.dart';
import 'category_details_screen.dart';

class ReportsScreen extends StatefulWidget {
  final ExpenseState expenseState;

  const ReportsScreen({super.key, required this.expenseState});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _selectedPeriod = 0; // 0: Month, 1: Year
  int _viewMode = 0; // 0: By Category, 1: By Account

  @override
  void initState() {
    super.initState();
    widget.expenseState.addListener(_onStateChanged);
  }

  @override
  void didUpdateWidget(covariant ReportsScreen oldWidget) {
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

  final List<Color> _segmentColors = const [
    Color(0xFFF59E0B), // Amber / Gold
    Color(0xFF7059E2), // Violet / Purple
    Color(0xFF2F80ED), // Blue
    Color(0xFF27AE60), // Green
    Color(0xFFEB5757), // Coral / Red
    Color(0xFFEC4899), // Pink
    Color(0xFF00B4D8), // Cyan
    Color(0xFF8B5CF6), // Purple
  ];

  void _openMonthYearPicker() {
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

  void _openItemDetails({
    required String title,
    required IconData icon,
    required Color color,
    required double spent,
    required double totalSpent,
    required List<ExpenseTransaction> transactions,
    required bool isAccount,
  }) {
    final state = widget.expenseState;
    final periodTitle = _selectedPeriod == 0
        ? '${_formatMonthName(state.selectedMonth)} ${state.selectedMonth.year}'
        : '${state.selectedMonth.year}';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryDetailsScreen(
          title: title,
          icon: icon,
          color: color,
          periodTitle: periodTitle,
          totalSpent: spent,
          totalOverallSpent: totalSpent,
          transactions: transactions,
          isAccount: isAccount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.expenseState;

    final bool isYearMode = _selectedPeriod == 1;
    final List<ExpenseTransaction> activeTransactions = isYearMode
        ? state.selectedYearTransactions
        : state.selectedMonthTransactions;

    final double totalExpense = isYearMode
        ? state.yearlyExpensesTotal
        : state.monthlyExpensesTotal;

    // Group expenses either by Category or by Account
    final List<_DisplayItem> items = [];

    if (_viewMode == 0) {
      // GROUP BY CATEGORY
      final Map<CategoryItem, double> categorySums = {};
      for (var tx in activeTransactions) {
        categorySums[tx.category] = (categorySums[tx.category] ?? 0) + tx.amount;
      }
      // Sort Max to Min spend
      final sortedCategories = categorySums.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      for (int i = 0; i < sortedCategories.length; i++) {
        final entry = sortedCategories[i];
        final pct = totalExpense > 0 ? (entry.value / totalExpense) * 100 : 0.0;
        final color = _segmentColors[i % _segmentColors.length];
        items.add(_DisplayItem(
          id: entry.key.id,
          title: entry.key.displayName,
          icon: entry.key.icon,
          color: color,
          amount: entry.value,
          percentage: pct,
          isAccount: false,
        ));
      }
    } else {
      // GROUP BY ACCOUNT
      final Map<AccountItem, double> accountSums = {};
      for (var tx in activeTransactions) {
        accountSums[tx.account] = (accountSums[tx.account] ?? 0) + tx.amount;
      }
      // Sort Max to Min spend
      final sortedAccounts = accountSums.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      for (int i = 0; i < sortedAccounts.length; i++) {
        final entry = sortedAccounts[i];
        final pct = totalExpense > 0 ? (entry.value / totalExpense) * 100 : 0.0;
        final color = _segmentColors[i % _segmentColors.length];
        items.add(_DisplayItem(
          id: entry.key.id,
          title: entry.key.displayName,
          icon: entry.key.icon,
          color: color,
          amount: entry.value,
          percentage: pct,
          isAccount: true,
        ));
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // TOP SWITCHER: By Category vs By Account
              Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildViewModeTab('Categories', 0),
                      _buildViewModeTab('Accounts', 1),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // TOP HALF: DONUT RING CHART WITH PERCENTAGES & CENTER TEXT
              Center(
                child: SizedBox(
                  width: 290,
                  height: 290,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Donut Ring Canvas
                      CustomPaint(
                        size: const Size(290, 290),
                        painter: _SegmentedDonutPainter(items: items),
                      ),

                      // Floating Percentage Badges in Dark Theme
                      ..._buildFloatingBadges(items),

                      // Center Month/Year Dropdown & Total Expense Text
                      GestureDetector(
                        onTap: _openMonthYearPicker,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isYearMode
                                      ? 'Spent in ${state.selectedMonth.year}'
                                      : 'Spent this ${_formatMonthAbbrev(state.selectedMonth)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.secondaryText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_drop_down,
                                  size: 18,
                                  color: AppTheme.secondaryText,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '₹${totalExpense.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // TIME PERIOD SELECTOR (Month, Year)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPeriodTab('Month', 0),
                  const SizedBox(width: 32),
                  _buildPeriodTab('Year', 1),
                ],
              ),

              const SizedBox(height: 24),

              // BOTTOM HALF: SPENDING CARDS (SORTED MAX TO MIN)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle indicator pill
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _viewMode == 0 ? 'Spending Categories' : 'Spending by Accounts',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Max to Min',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.accentGold.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.pie_chart_outline,
                                size: 48,
                                color: Colors.white24,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                isYearMode
                                    ? 'No expenses recorded in ${state.selectedMonth.year}'
                                    : 'No expenses in ${_formatMonthYear(state.selectedMonth)}',
                                style: const TextStyle(
                                  color: AppTheme.secondaryText,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.25,
                        ),
                        itemBuilder: (context, index) {
                          final item = items[index];

                          return GestureDetector(
                            onTap: () {
                              final matchingTx = item.isAccount
                                  ? activeTransactions.where((tx) => tx.account.id == item.id).toList()
                                  : activeTransactions.where((tx) => tx.category.id == item.id).toList();

                              _openItemDetails(
                                title: item.title,
                                icon: item.icon,
                                color: item.color,
                                spent: item.amount,
                                totalSpent: totalExpense,
                                transactions: matchingTx,
                                isAccount: item.isAccount,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppTheme.border,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          '₹${item.amount.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${item.percentage.toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.secondaryText,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.secondaryText,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: item.color.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      item.icon,
                                      color: item.color,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewModeTab(String title, int index) {
    final isSelected = _viewMode == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _viewMode = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentGold : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : AppTheme.secondaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodTab(String title, int index) {
    final isSelected = _selectedPeriod == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = index;
        });
      },
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : AppTheme.secondaryText,
            ),
          ),
          const SizedBox(height: 4),
          if (isSelected)
            Container(
              width: 24,
              height: 2.5,
              decoration: BoxDecoration(
                color: AppTheme.accentGold,
                borderRadius: BorderRadius.circular(2),
              ),
            )
          else
            const SizedBox(height: 2.5),
        ],
      ),
    );
  }

  List<Widget> _buildFloatingBadges(List<_DisplayItem> items) {
    if (items.isEmpty) return [];

    final List<Widget> badges = [];
    const double centerX = 145;
    const double centerY = 145;
    const double badgeRadius = 112;

    double currentAngle = -math.pi / 2;
    final double gapAngle = items.length > 1 ? 0.08 : 0.0;
    final double totalAvailableAngle = 2 * math.pi - (items.length * gapAngle);

    for (var item in items) {
      final double sweepAngle = (item.percentage / 100) * totalAvailableAngle;
      final double midAngle = currentAngle + (sweepAngle / 2);

      if (item.percentage >= 3) {
        final double x = centerX + badgeRadius * math.cos(midAngle);
        final double y = centerY + badgeRadius * math.sin(midAngle);

        badges.add(
          Positioned(
            left: x - 18,
            top: y - 11,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border, width: 0.8),
              ),
              child: Text(
                '${item.percentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      }

      currentAngle += sweepAngle + gapAngle;
    }

    return badges;
  }

  String _formatMonthAbbrev(DateTime dt) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[dt.month - 1];
  }

  String _formatMonthName(DateTime dt) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[dt.month - 1];
  }

  String _formatMonthYear(DateTime dt) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }
}

class _DisplayItem {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final double amount;
  final double percentage;
  final bool isAccount;

  _DisplayItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.amount,
    required this.percentage,
    required this.isAccount,
  });
}

// CUSTOM PAINTER FOR SEGMENTED DONUT RING
class _SegmentedDonutPainter extends CustomPainter {
  final List<_DisplayItem> items;

  _SegmentedDonutPainter({required this.items});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const double radius = 88.0;
    const double strokeWidth = 16.0;

    if (items.isEmpty) {
      final emptyPaint = Paint()
        ..color = AppTheme.surfaceLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, radius, emptyPaint);
      return;
    }

    double currentAngle = -math.pi / 2;
    final double gapAngle = items.length > 1 ? 0.08 : 0.0;
    final double totalAvailableAngle = 2 * math.pi - (items.length * gapAngle);

    for (var item in items) {
      final double sweepAngle = (item.percentage / 100) * totalAvailableAngle;

      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        sweepAngle,
        false,
        paint,
      );

      currentAngle += sweepAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentedDonutPainter oldDelegate) {
    return oldDelegate.items != items;
  }
}
