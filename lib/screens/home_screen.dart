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
    widget.expenseState.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
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
    final dailyTotals = state.selectedMonthDailyTotals;

    final now = DateTime.now();
    final todayKey = DateTime(now.year, now.month, now.day);
    final isCurrentMonthSelected = state.selectedMonth.year == now.year && state.selectedMonth.month == now.month;

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

                  // DYNAMIC REAL DATA WAVE GRAPH CANVAS
                  SizedBox(
                    height: 90,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _SpendingWaveGraphPainter(
                        dailyTotals: dailyTotals,
                        lineColor: AppTheme.accentGold,
                      ),
                    ),
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
              // Date Grouped Transactions List for Selected Month
              ...dates.map((date) {
                final txList = groupedTransactions[date]!;
                final dailyTotal = txList.fold(0.0, (sum, item) => sum + item.amount);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDateHeaderTitle(date),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
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
                          ],
                        ),
                      ],
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
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
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

// REAL DYNAMIC SPENDING WAVE GRAPH PAINTER
class _SpendingWaveGraphPainter extends CustomPainter {
  final List<double> dailyTotals;
  final Color lineColor;

  _SpendingWaveGraphPainter({
    required this.dailyTotals,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    if (dailyTotals.isEmpty) return;

    final maxSpent = dailyTotals.reduce((a, b) => a > b ? a : b);

    final path = Path();
    final fillPath = Path();

    final count = dailyTotals.length;
    final stepX = w / (count - 1 > 0 ? count - 1 : 1);

    List<Offset> points = [];
    for (int i = 0; i < count; i++) {
      final x = i * stepX;
      final ratio = maxSpent > 0 ? (dailyTotals[i] / maxSpent) : 0.0;
      final y = h * 0.85 - (ratio * h * 0.65);
      points.add(Offset(x, y));
    }

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
    fillPath.lineTo(w, h);
    fillPath.lineTo(0, h);
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
      ..shader = fillGradient.createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);

    if (points.isNotEmpty) {
      final lastPoint = points.last;
      final dotPaint = Paint()..color = Colors.white;
      final dotRingPaint = Paint()..color = lineColor;
      canvas.drawCircle(lastPoint, 5, dotRingPaint);
      canvas.drawCircle(lastPoint, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpendingWaveGraphPainter oldDelegate) {
    return oldDelegate.dailyTotals != dailyTotals || oldDelegate.lineColor != lineColor;
  }
}
