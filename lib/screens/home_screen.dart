import 'dart:async';
import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../state/expense_state.dart';
import '../theme/app_theme.dart';
import 'calendar_screen.dart';
import 'search_transactions_screen.dart';
import 'month_year_picker_modal.dart';
import 'add_expense_screen.dart';

class HomeScreen extends StatefulWidget {
  final ExpenseState expenseState;
  final VoidCallback onAddExpenseTap;

  const HomeScreen({
    super.key,
    required this.expenseState,
    required this.onAddExpenseTap,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _touchedGraphIndex;
  Timer? _touchResetTimer;

  @override
  void initState() {
    super.initState();
    widget.expenseState.addListener(_onStateChanged);
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expenseState != widget.expenseState) {
      oldWidget.expenseState.removeListener(_onStateChanged);
      widget.expenseState.addListener(_onStateChanged);
    }
  }

  @override
  void dispose() {
    _touchResetTimer?.cancel();
    widget.expenseState.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onGraphTouch(Offset localPos, double width, List<DateTime> sortedDates) {
    final pointCount = sortedDates.length;
    if (pointCount <= 0) return;
    const marginX = 14.0;
    final usableW = width - (2 * marginX);
    final count = pointCount == 1 ? 2 : pointCount;
    final stepX = usableW / (count - 1 > 0 ? count - 1 : 1);

    int closest = 0;
    double minD = double.infinity;
    for (int i = 0; i < count; i++) {
      final px = marginX + (i * stepX);
      final dist = (px - localPos.dx).abs();
      if (dist < minD) {
        minD = dist;
        closest = i;
      }
    }

    final resolvedIndex = pointCount == 1 ? 0 : closest.clamp(0, pointCount - 1);

    _touchResetTimer?.cancel();
    setState(() {
      _touchedGraphIndex = resolvedIndex;
      widget.expenseState.selectedCalendarDate = sortedDates[resolvedIndex];
    });
  }

  void _onGraphTouchEnd() {
    _touchResetTimer?.cancel();
    _touchResetTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _touchedGraphIndex = null;
        });
      }
    });
  }

  void _openCalendar(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CalendarScreen(expenseState: widget.expenseState),
      ),
    );
  }

  void _openSearch(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchTransactionsScreen(expenseState: widget.expenseState),
      ),
    );
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
            _touchedGraphIndex = null;
            widget.expenseState.selectedMonth = date;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.expenseState;
    final totalExpense = state.monthlyExpensesTotal;
    final monthTransactions = state.selectedMonthTransactions;
    final groupedTransactions = state.selectedMonthGroupedByDate;
    final dates = groupedTransactions.keys.toList()..sort((a, b) => b.compareTo(a));
    final sortedDates = groupedTransactions.keys.toList()..sort((a, b) => a.compareTo(b));
    final dailyTotals = state.selectedMonthDailyTotals;

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
                _formatMonthYear(state.selectedMonth),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, color: AppTheme.accentGold, size: 22),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white, size: 24),
            onPressed: () => _openSearch(context),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined, color: Colors.white, size: 24),
            onPressed: () => _openCalendar(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          children: [
            // TOP HALF: TOTAL EXPENSES DYNAMIC GRAPH CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL EXPENSES • ${_formatMonthName(state.selectedMonth).toUpperCase()}',
                    style: const TextStyle(
                      color: AppTheme.secondaryText,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: FittedBox(
                          alignment: Alignment.centerLeft,
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '₹${totalExpense.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withOpacity(0.4)),
                        ),
                        child: Text(
                          '${monthTransactions.length} entries',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // DYNAMIC REAL DATA WAVE GRAPH CANVAS WITH TOUCH INTERACTION
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) => _onGraphTouch(
                          details.localPosition,
                          constraints.maxWidth,
                          sortedDates,
                        ),
                        onHorizontalDragStart: (details) => _onGraphTouch(
                          details.localPosition,
                          constraints.maxWidth,
                          sortedDates,
                        ),
                        onHorizontalDragUpdate: (details) => _onGraphTouch(
                          details.localPosition,
                          constraints.maxWidth,
                          sortedDates,
                        ),
                        onHorizontalDragEnd: (_) => _onGraphTouchEnd(),
                        onTapUp: (_) => _onGraphTouchEnd(),
                        child: SizedBox(
                          height: 120,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: _SpendingWaveGraphPainter(
                              spendingPoints: dailyTotals,
                              dates: sortedDates,
                              touchedIndex: _touchedGraphIndex,
                              lineColor: AppTheme.accentGold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // IF SELECTED MONTH HAS NO TRANSACTIONS -> SHOW CLEAN EMPTY STATE
            if (monthTransactions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 56,
                      color: Colors.white24,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No expenses recorded for ${_formatMonthYear(state.selectedMonth)}',
                      style: const TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: widget.onAddExpenseTap,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Expense'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentGold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              if (state.selectedCalendarDate != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.accentGold.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_available, color: AppTheme.accentGold, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selected: ${_formatDateHeaderTitle(state.selectedCalendarDate!)}',
                              style: const TextStyle(
                                color: AppTheme.accentGold,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const Text(
                              'Click + to add expense for this date',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.accentGold, size: 18),
                        tooltip: 'Clear selected date',
                        onPressed: () {
                          setState(() {
                            widget.expenseState.selectedCalendarDate = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),

              // Date Grouped Transactions List for Selected Month
              ...dates.map((date) {
                final txList = groupedTransactions[date]!;
                final dailyTotal = txList.fold(0.0, (sum, item) => sum + item.amount);
                final isDateSelected = state.selectedCalendarDate != null &&
                    state.selectedCalendarDate!.year == date.year &&
                    state.selectedCalendarDate!.month == date.month &&
                    state.selectedCalendarDate!.day == date.day;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setState(() {
                          if (isDateSelected) {
                            state.selectedCalendarDate = null;
                          } else {
                            state.selectedCalendarDate = date;
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDateSelected ? AppTheme.accentGold.withOpacity(0.18) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: isDateSelected
                              ? Border.all(color: AppTheme.accentGold, width: 1.2)
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                if (isDateSelected) ...[
                                  const Icon(Icons.check_circle, color: AppTheme.accentGold, size: 16),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  _formatDateHeaderTitle(date),
                                  style: TextStyle(
                                    color: isDateSelected ? AppTheme.accentGold : Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.arrow_upward, color: Colors.redAccent, size: 14),
                                Text(
                                  '₹${dailyTotal.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                if (isDateSelected) ...[
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      state.selectedCalendarDate = date;
                                      widget.onAddExpenseTap();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.accentGold,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.add, color: Colors.black, size: 14),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    ...txList.map((tx) => _buildTransactionCard(tx)),

                    const SizedBox(height: 16),
                  ],
                );
              }),
            ],

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  void _showTransactionOptions(BuildContext context, ExpenseTransaction tx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Material(
          color: const Color(0xFF1E1E1E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: tx.category.color.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(tx.category.icon, color: tx.category.color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.category.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${tx.description} • ₹${tx.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_outlined, color: AppTheme.accentGold, size: 20),
                  ),
                  title: const Text('Edit Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Prefill and update expense details', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openEditExpense(context, tx);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  ),
                  title: const Text('Delete Expense', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Permanently remove this transaction', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDelete(context, tx);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openEditExpense(BuildContext context, ExpenseTransaction tx) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(
          expenseState: widget.expenseState,
          initialTransaction: tx,
          onExpenseAdded: () {
            widget.expenseState.resetToCurrentDate();
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ExpenseTransaction tx) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.white12),
          ),
          title: const Text('Delete Expense?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(
            'Are you sure you want to delete this expense of ₹${tx.amount.toStringAsFixed(2)} for "${tx.category.displayName}"?\nThis action cannot be undone.',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                widget.expenseState.deleteTransaction(tx.id);
                Navigator.pop(ctx);
                if (mounted) {
                  setState(() {});
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted ₹${tx.amount.toStringAsFixed(2)} expense'),
                    backgroundColor: Colors.redAccent,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransactionCard(ExpenseTransaction tx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showTransactionOptions(context, tx),
          onLongPress: () => _showTransactionOptions(context, tx),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: tx.category.color.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(tx.category.icon, color: tx.category.color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.category.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tx.description,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '-₹${tx.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTime(tx.timestamp),
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
  }

  String _formatMonthYear(DateTime dt) {
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  String _formatMonthName(DateTime dt) {
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return months[dt.month - 1];
  }

  String _formatDateHeaderTitle(DateTime dt) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final prefix = isToday ? 'Today ' : '';
    return '$prefix${months[dt.month - 1]} ${dt.day} ${days[dt.weekday - 1]}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minuteStr = dt.minute < 10 ? '0${dt.minute}' : '${dt.minute}';
    return '$hour:$minuteStr $period';
  }
}

// REAL DYNAMIC SPENDING WAVE GRAPH PAINTER WITH 20K BASELINE & TOUCH SCRUBBING
class _SpendingWaveGraphPainter extends CustomPainter {
  final List<double> spendingPoints;
  final List<DateTime> dates;
  final int? touchedIndex;
  final Color lineColor;

  _SpendingWaveGraphPainter({
    required this.spendingPoints,
    required this.dates,
    this.touchedIndex,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    if (spendingPoints.isEmpty || dates.isEmpty) return;

    // If only 1 data point in the month, interpolate from a lower baseline
    final List<double> renderPoints = spendingPoints.length == 1
        ? [spendingPoints.first * 0.25, spendingPoints.first]
        : spendingPoints;

    // BASELINE MAX PEAK 2000:
    // If entered more than 2000, make that the new peak and scale other expenses relative to it!
    final actualMax = renderPoints.reduce((a, b) => a > b ? a : b);
    const double baselinePeak = 2000.0;
    final double maxPeak = actualMax > baselinePeak ? actualMax : baselinePeak;

    const marginX = 14.0;
    const topPadding = 26.0;   // space for top price badge
    const bottomPadding = 22.0; // space for bottom date badge
    final usableW = w - (2 * marginX);
    final usableH = h - topPadding - bottomPadding;
    final count = renderPoints.length;
    final stepX = usableW / (count - 1 > 0 ? count - 1 : 1);

    List<Offset> points = [];
    for (int i = 0; i < count; i++) {
      final x = marginX + (i * stepX);
      final val = renderPoints[i];
      // Ratio relative to maxPeak (minimum 20k, or higher if an expense exceeds 20k)
      final ratio = maxPeak > 0 ? (val / maxPeak).clamp(0.0, 1.0) : 0.0;
      // Scaled ratio so small amounts remain visible as gentle waves
      final scaledRatio = val > 0 ? (0.04 + ratio * 0.96) : 0.0;
      final y = (topPadding + usableH) - (scaledRatio * usableH);
      points.add(Offset(x, y));
    }

    final path = Path();
    final fillPath = Path();

    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i];
        final p2 = points[i + 1];
        final controlX = (p1.dx + p2.dx) / 2;
        path.cubicTo(controlX, p1.dy, controlX, p2.dy, p2.dx, p2.dy);
      }
    }

    fillPath.addPath(path, Offset.zero);
    fillPath.lineTo(points.last.dx, topPadding + usableH);
    fillPath.lineTo(points.first.dx, topPadding + usableH);
    fillPath.close();

    final fillGradient = LinearGradient(
      colors: [
        lineColor.withOpacity(0.35),
        lineColor.withOpacity(0.0),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(Rect.fromLTWH(0, topPadding, w, usableH))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);

    if (points.isNotEmpty) {
      final bool isTouching = touchedIndex != null &&
          touchedIndex! >= 0 &&
          touchedIndex! < dates.length &&
          touchedIndex! < spendingPoints.length;

      final int activePointIndex = isTouching
          ? (spendingPoints.length == 1 ? 1 : touchedIndex!)
          : (points.length - 1);

      final Offset activePoint = points[activePointIndex];

      final double activeAmount = isTouching
          ? spendingPoints[touchedIndex!]
          : spendingPoints.last;

      final DateTime activeDate = isTouching
          ? dates[touchedIndex!]
          : dates.last;

      // 1. Sleek vertical indicator line through active point
      final vLinePaint = Paint()
        ..color = isTouching
            ? AppTheme.accentGold.withOpacity(0.7)
            : lineColor.withOpacity(0.25)
        ..strokeWidth = isTouching ? 1.5 : 1.0;

      canvas.drawLine(
        Offset(activePoint.dx, 2),
        Offset(activePoint.dx, h - 2),
        vLinePaint,
      );

      // 2. Glowing indicator dot on the curve
      final glowPaint = Paint()
        ..color = lineColor.withOpacity(isTouching ? 0.45 : 0.3);
      final dotRingPaint = Paint()..color = lineColor;
      final dotPaint = Paint()..color = Colors.white;

      canvas.drawCircle(activePoint, isTouching ? 9 : 7, glowPaint);
      canvas.drawCircle(activePoint, isTouching ? 5.5 : 4.5, dotRingPaint);
      canvas.drawCircle(activePoint, isTouching ? 3.5 : 2.5, dotPaint);

      // 3. TOP PRICE BADGE ("on top show price")
      final priceText = '₹${_formatAmount(activeAmount)}';
      final priceSpan = TextSpan(
        style: const TextStyle(
          color: AppTheme.accentGold,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
        text: priceText,
      );

      final pricePainter = TextPainter(
        text: priceSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      const padH = 8.0;
      const padV = 3.5;
      final badgeW = pricePainter.width + (padH * 2);
      final badgeH = pricePainter.height + (padV * 2);

      double badgeX = activePoint.dx - (badgeW / 2);
      badgeX = badgeX.clamp(4.0, w - badgeW - 4);
      const badgeY = 2.0;

      final badgeRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(badgeX, badgeY, badgeW, badgeH),
        const Radius.circular(8),
      );

      final badgeBg = Paint()..color = const Color(0xFF1E1E1E);
      final badgeBorder = Paint()
        ..color = isTouching ? AppTheme.accentGold : lineColor.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawRRect(badgeRRect, badgeBg);
      canvas.drawRRect(badgeRRect, badgeBorder);
      pricePainter.paint(canvas, Offset(badgeX + padH, badgeY + padV));

      // 4. BOTTOM DATE BADGE ("and botton show date")
      final dateText = _formatBadgeDate(activeDate);
      final dateSpan = TextSpan(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        text: dateText,
      );

      final datePainter = TextPainter(
        text: dateSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      const dPadH = 7.0;
      const dPadV = 2.5;
      final dBadgeW = datePainter.width + (dPadH * 2);
      final dBadgeH = datePainter.height + (dPadV * 2);

      double dBadgeX = activePoint.dx - (dBadgeW / 2);
      dBadgeX = dBadgeX.clamp(4.0, w - dBadgeW - 4);
      final dBadgeY = h - dBadgeH - 2.0;

      final dRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(dBadgeX, dBadgeY, dBadgeW, dBadgeH),
        const Radius.circular(6),
      );

      final dBg = Paint()..color = const Color(0xFF242424);
      final dBorder = Paint()
        ..color = isTouching ? Colors.white60 : Colors.white24
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;

      canvas.drawRRect(dRRect, dBg);
      canvas.drawRRect(dRRect, dBorder);
      datePainter.paint(canvas, Offset(dBadgeX + dPadH, dBadgeY + dPadV));
    }
  }

  String _formatBadgeDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today';
    }
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  String _formatAmount(double val) {
    if (val >= 10000000) {
      final cr = val / 10000000;
      return '${cr.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')} Cr';
    } else if (val >= 100000) {
      final l = val / 100000;
      return '${l.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')} L';
    } else if (val >= 1000) {
      final str = val.toInt().toString();
      final len = str.length;
      if (len > 3) {
        final last3 = str.substring(len - 3);
        final rest = str.substring(0, len - 3);
        final formattedRest = rest.replaceAllMapped(
          RegExp(r'(\d)(?=(\d\d)+$)'),
          (m) => '${m[1]},',
        );
        return '$formattedRest,$last3';
      }
      return str;
    } else {
      final isInt = val.truncateToDouble() == val;
      return isInt ? val.toInt().toString() : val.toStringAsFixed(2);
    }
  }

  @override
  bool shouldRepaint(covariant _SpendingWaveGraphPainter oldDelegate) {
    return oldDelegate.spendingPoints != spendingPoints ||
        oldDelegate.dates != dates ||
        oldDelegate.touchedIndex != touchedIndex ||
        oldDelegate.lineColor != lineColor;
  }
}
