import 'package:flutter/material.dart';
import '../state/expense_state.dart';
import '../theme/app_theme.dart';
import 'add_expense_screen.dart';

class CalendarScreen extends StatefulWidget {
  final ExpenseState expenseState;

  const CalendarScreen({super.key, required this.expenseState});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _currentMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  void _openAddExpense() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(
          expenseState: widget.expenseState,
          initialDate: _selectedDay,
          onExpenseAdded: () {
            widget.expenseState.resetToCurrentDate();
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.expenseState;
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;

    double monthTotalExpenses = 0.0;
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      monthTotalExpenses += state.getDailyExpenseTotal(date);
    }

    final dayTransactions = state.transactions.where((tx) =>
      tx.timestamp.year == _selectedDay.year &&
      tx.timestamp.month == _selectedDay.month &&
      tx.timestamp.day == _selectedDay.day
    ).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _previousMonth,
              child: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            Text(
              _formatMonthYear(_currentMonth),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _nextMonth,
              child: const Icon(Icons.chevron_right, color: Colors.white, size: 28),
            ),
          ],
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddExpense,
        backgroundColor: AppTheme.accentGold,
        elevation: 6,
        child: const Icon(Icons.add, color: Colors.black, size: 30),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Calendar Card Container
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    // Yellow Strip Header
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: const BoxDecoration(
                        color: AppTheme.accentGold,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _WeekHeaderDay('Mon'),
                          _WeekHeaderDay('Tue'),
                          _WeekHeaderDay('Wed'),
                          _WeekHeaderDay('Thu'),
                          _WeekHeaderDay('Fri'),
                          _WeekHeaderDay('Sat'),
                          _WeekHeaderDay('Sun'),
                        ],
                      ),
                    ),

                    // Calendar Days Grid
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: (firstWeekday - 1) + daysInMonth,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          childAspectRatio: 1.0,
                        ),
                        itemBuilder: (context, index) {
                          if (index < firstWeekday - 1) {
                            return const SizedBox.shrink();
                          }
                          final dayNum = index - (firstWeekday - 1) + 1;
                          final date = DateTime(_currentMonth.year, _currentMonth.month, dayNum);
                          final isSelected = date.year == _selectedDay.year &&
                              date.month == _selectedDay.month &&
                              date.day == _selectedDay.day;
                          final dailySpent = state.getDailyExpenseTotal(date);

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDay = date;
                                widget.expenseState.selectedCalendarDate = date;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.all(1.5),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: isSelected
                                    ? Border.all(color: AppTheme.accentGold, width: 2)
                                    : Border.all(color: Colors.transparent),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '$dayNum',
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.white70,
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (dailySpent > 0)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 1.0),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          '-${_formatCompactAmount(dailySpent)}',
                                          maxLines: 1,
                                          style: const TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Footer Summary Bar inside Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: AppTheme.border)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Expenses: ₹${_formatCompactAmount(monthTotalExpenses)}',
                                style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Income: ₹0',
                                style: TextStyle(color: Colors.white70, fontSize: 11.5),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Balance: -₹${_formatCompactAmount(monthTotalExpenses)}',
                                style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Day Details Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Text(
                      _formatDayTitle(_selectedDay),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Transactions list for selected day
              dayTransactions.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30.0),
                      child: Text(
                        'No history records',
                        style: TextStyle(color: Colors.white38, fontSize: 14),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: dayTransactions.length,
                      itemBuilder: (context, index) {
                        final tx = dayTransactions[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: tx.category.color.withOpacity(0.2),
                                child: Icon(tx.category.icon, color: tx.category.color, size: 20),
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
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${tx.description} • ${tx.account.displayName}',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '-₹${tx.amount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

              const SizedBox(height: 80), // FAB space
            ],
          ),
        ),
      ),
    );
  }

  String _formatMonthYear(DateTime dt) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  String _formatDayTitle(DateTime dt) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final prefix = isToday ? 'Today ' : '';
    return '$prefix${months[dt.month - 1]} ${dt.day} ${days[dt.weekday - 1]}';
  }

  String _formatCompactAmount(double amount) {
    if (amount >= 1000000000) {
      double b = amount / 1000000000;
      return '${b.toStringAsFixed(b >= 10 ? 0 : 1).replaceAll('.0', '')}B';
    }
    if (amount >= 1000000) {
      double m = amount / 1000000;
      return '${m.toStringAsFixed(m >= 10 ? 0 : 1).replaceAll('.0', '')}M';
    }
    if (amount > 999) {
      double k = amount / 1000;
      return '${k.toStringAsFixed(k >= 10 ? 0 : 1).replaceAll('.0', '')}k';
    }
    return amount.toStringAsFixed(0);
  }
}

class _WeekHeaderDay extends StatelessWidget {
  final String title;
  const _WeekHeaderDay(this.title);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
