import 'package:flutter/material.dart';
import '../models/transaction_model.dart';

class ExpenseState extends ChangeNotifier {
  final List<ExpenseTransaction> _transactions = [];
  final List<CategoryItem> _allCategories = List.from(CategoryItem.defaults);
  final List<AccountItem> _allAccounts = List.from(AccountItem.defaults);

  final Map<String, int> _categoryUsageCount = {};
  final Map<String, int> _accountUsageCount = {};

  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedCalendarDate;

  final List<String> _savedDescriptions = [
    'Khana',
    'Dinner with friends',
    'Super hair',
    'Groceries',
    'Metro recharge',
    'Snacks',
    'Coffee',
    'Medicines',
    'Shopping',
    'Fuel',
  ];

  List<String> get savedDescriptions => List.unmodifiable(_savedDescriptions);

  List<String> getMatchingDescriptions(String query) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      return _savedDescriptions.take(8).toList();
    }
    return _savedDescriptions
        .where((desc) => desc.toLowerCase().contains(cleanQuery))
        .toList();
  }

  void addSavedDescription(String description) {
    final trimmed = description.trim();
    if (trimmed.isEmpty) return;
    final exists = _savedDescriptions.any(
      (d) => d.toLowerCase() == trimmed.toLowerCase(),
    );
    if (!exists) {
      _savedDescriptions.insert(0, trimmed);
      notifyListeners();
    }
  }

  void deleteSavedDescription(String description) {
    _savedDescriptions.removeWhere(
      (d) => d.toLowerCase() == description.trim().toLowerCase(),
    );
    notifyListeners();
  }

  ExpenseState() {
    _loadInitialSampleData();
  }

  DateTime get selectedMonth => _selectedMonth;
  set selectedMonth(DateTime date) {
    _selectedMonth = date;
    notifyListeners();
  }

  DateTime? get selectedCalendarDate => _selectedCalendarDate;
  set selectedCalendarDate(DateTime? date) {
    _selectedCalendarDate = date;
    notifyListeners();
  }

  List<ExpenseTransaction> get transactions {
    List<ExpenseTransaction> list = List.from(_transactions);
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  // Filter transactions strictly for the selected month & year
  List<ExpenseTransaction> get selectedMonthTransactions {
    return transactions.where((tx) =>
      tx.timestamp.year == _selectedMonth.year &&
      tx.timestamp.month == _selectedMonth.month
    ).toList();
  }

  double get totalExpenses {
    return _transactions.fold(0.0, (sum, item) => sum + item.amount);
  }

  // Monthly expenses for currently selected month
  double get monthlyExpensesTotal {
    return selectedMonthTransactions.fold(0.0, (sum, item) => sum + item.amount);
  }

  // Filter transactions strictly for the selected year
  List<ExpenseTransaction> get selectedYearTransactions {
    return transactions.where((tx) =>
      tx.timestamp.year == _selectedMonth.year
    ).toList();
  }

  // Yearly expenses for currently selected year
  double get yearlyExpensesTotal {
    return selectedYearTransactions.fold(0.0, (sum, item) => sum + item.amount);
  }

  // Dynamic daily totals for selected month (used for wave graph)
  List<double> get selectedMonthDailyTotals {
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final List<double> totals = List.filled(daysInMonth, 0.0);
    for (var tx in selectedMonthTransactions) {
      final dayIdx = tx.timestamp.day - 1;
      if (dayIdx >= 0 && dayIdx < daysInMonth) {
        totals[dayIdx] += tx.amount;
      }
    }
    return totals;
  }

  List<CategoryItem> get allCategories => List.unmodifiable(_allCategories);
  List<AccountItem> get allAccounts => List.unmodifiable(_allAccounts);

  List<CategoryItem> get top5Categories {
    List<CategoryItem> sorted = List.from(_allCategories);
    sorted.sort((a, b) {
      int countA = _categoryUsageCount[a.id] ?? 0;
      int countB = _categoryUsageCount[b.id] ?? 0;
      if (countA != countB) {
        return countB.compareTo(countA);
      }
      return 0;
    });
    return sorted.take(5).toList();
  }

  List<AccountItem> get topAccounts {
    List<AccountItem> sorted = List.from(_allAccounts);
    sorted.sort((a, b) {
      int countA = _accountUsageCount[a.id] ?? 0;
      int countB = _accountUsageCount[b.id] ?? 0;
      if (countA != countB) {
        return countB.compareTo(countA);
      }
      return 0;
    });
    return sorted;
  }

  List<ExpenseTransaction> get top10RankedExpenses {
    List<ExpenseTransaction> list = List.from(selectedMonthTransactions);
    list.sort((a, b) => b.amount.compareTo(a.amount));
    return list.take(10).toList();
  }

  double getDailyExpenseTotal(DateTime day) {
    return _transactions.where((tx) =>
      tx.timestamp.year == day.year &&
      tx.timestamp.month == day.month &&
      tx.timestamp.day == day.day
    ).fold(0.0, (sum, item) => sum + item.amount);
  }

  // Group selected month transactions by Date
  Map<DateTime, List<ExpenseTransaction>> get selectedMonthGroupedByDate {
    final Map<DateTime, List<ExpenseTransaction>> map = {};
    for (var tx in selectedMonthTransactions) {
      final dateKey = DateTime(tx.timestamp.year, tx.timestamp.month, tx.timestamp.day);
      if (!map.containsKey(dateKey)) {
        map[dateKey] = [];
      }
      map[dateKey]!.add(tx);
    }
    return map;
  }

  void addCategory(CategoryItem category) {
    _allCategories.add(category);
    notifyListeners();
  }

  void addAccount(AccountItem account) {
    _allAccounts.add(account);
    notifyListeners();
  }

  void addTransaction({
    required double amount,
    required CategoryItem category,
    required AccountItem account,
    required String description,
    DateTime? date,
  }) {
    final transaction = ExpenseTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      category: category,
      account: account,
      description: description.trim().isEmpty ? category.displayName : description,
      timestamp: date ?? DateTime.now(),
    );

    _transactions.add(transaction);
    _categoryUsageCount[category.id] = (_categoryUsageCount[category.id] ?? 0) + 1;
    _accountUsageCount[account.id] = (_accountUsageCount[account.id] ?? 0) + 1;

    final trimmedDesc = description.trim();
    if (trimmedDesc.isNotEmpty && trimmedDesc.toLowerCase() != category.displayName.toLowerCase()) {
      final exists = _savedDescriptions.any((d) => d.toLowerCase() == trimmedDesc.toLowerCase());
      if (!exists) {
        _savedDescriptions.insert(0, trimmedDesc);
      }
    }
    notifyListeners();
  }

  void updateTransaction({
    required String id,
    required double amount,
    required CategoryItem category,
    required AccountItem account,
    required String description,
    DateTime? date,
  }) {
    final index = _transactions.indexWhere((tx) => tx.id == id);
    if (index != -1) {
      final oldTx = _transactions[index];
      if (oldTx.category.id != category.id) {
        _categoryUsageCount[oldTx.category.id] =
            (_categoryUsageCount[oldTx.category.id] ?? 1) - 1;
        _categoryUsageCount[category.id] =
            (_categoryUsageCount[category.id] ?? 0) + 1;
      }
      if (oldTx.account.id != account.id) {
        _accountUsageCount[oldTx.account.id] =
            (_accountUsageCount[oldTx.account.id] ?? 1) - 1;
        _accountUsageCount[account.id] =
            (_accountUsageCount[account.id] ?? 0) + 1;
      }
      _transactions[index] = ExpenseTransaction(
        id: id,
        amount: amount,
        category: category,
        account: account,
        description: description.trim().isEmpty ? category.displayName : description,
        timestamp: date ?? oldTx.timestamp,
      );

      final trimmedDesc = description.trim();
      if (trimmedDesc.isNotEmpty && trimmedDesc.toLowerCase() != category.displayName.toLowerCase()) {
        final exists = _savedDescriptions.any((d) => d.toLowerCase() == trimmedDesc.toLowerCase());
        if (!exists) {
          _savedDescriptions.insert(0, trimmedDesc);
        }
      }
      notifyListeners();
    }
  }

  void deleteTransaction(String id) {
    final index = _transactions.indexWhere((tx) => tx.id == id);
    if (index != -1) {
      final tx = _transactions.removeAt(index);
      _categoryUsageCount[tx.category.id] =
          (_categoryUsageCount[tx.category.id] ?? 1) - 1;
      _accountUsageCount[tx.account.id] =
          (_accountUsageCount[tx.account.id] ?? 1) - 1;
      notifyListeners();
    }
  }

  double getAccountMonthlyExpense(String accountId) {
    return selectedMonthTransactions
        .where((tx) => tx.account.id == accountId)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  void _loadInitialSampleData() {
    final now = DateTime.now();
    final dining = _allCategories.firstWhere((c) => c.id == 'dining');
    final groceries = _allCategories.firstWhere((c) => c.id == 'groceries');
    final transport = _allCategories.firstWhere((c) => c.id == 'transport');
    final shopping = _allCategories.firstWhere((c) => c.id == 'shopping');
    final health = _allCategories.firstWhere((c) => c.id == 'health');
    final personal = _allCategories.firstWhere((c) => c.id == 'personal');

    final upi = _allAccounts.firstWhere((a) => a.id == 'upi');
    final bobBank = _allAccounts.firstWhere((a) => a.id == 'bob_bank');
    final rupay = _allAccounts.firstWhere((a) => a.id == 'rupay_card');
    final mastercard = _allAccounts.firstWhere((a) => a.id == 'mastercard');

    final sampleData = [
      ExpenseTransaction(
        id: '1',
        amount: 1850.0,
        category: health,
        account: upi,
        description: 'Super hair',
        timestamp: DateTime(now.year, now.month, 1, 22, 37),
      ),
      ExpenseTransaction(
        id: '2',
        amount: 190.0,
        category: health,
        account: upi,
        description: 'Super hair cut',
        timestamp: DateTime(now.year, now.month, 2, 10, 51),
      ),
      ExpenseTransaction(
        id: '3',
        amount: 105.0,
        category: personal,
        account: bobBank,
        description: 'Super nashta',
        timestamp: DateTime(now.year, now.month, 2, 0, 1),
      ),
      ExpenseTransaction(
        id: '4',
        amount: 100.0,
        category: personal,
        account: rupay,
        description: 'Super dadar',
        timestamp: DateTime(now.year, now.month, 3, 19, 12),
      ),
      ExpenseTransaction(
        id: '5',
        amount: 100.0,
        category: dining,
        account: upi,
        description: 'Super Nashta',
        timestamp: DateTime(now.year, now.month, 2, 18, 13),
      ),
      ExpenseTransaction(
        id: '6',
        amount: 60.0,
        category: dining,
        account: upi,
        description: 'Super Nashta',
        timestamp: DateTime(now.year, now.month, 7, 16, 39),
      ),
      ExpenseTransaction(
        id: '7',
        amount: 56.0,
        category: dining,
        account: mastercard,
        description: 'Super khana',
        timestamp: DateTime(now.year, now.month, 1, 13, 8),
      ),
      ExpenseTransaction(
        id: '8',
        amount: 39.0,
        category: dining,
        account: upi,
        description: 'Super Nashta',
        timestamp: DateTime(now.year, now.month, 5, 18, 11),
      ),
      ExpenseTransaction(
        id: '9',
        amount: 25.0,
        category: dining,
        account: upi,
        description: 'Super Nashta',
        timestamp: DateTime(now.year, now.month, 8, 17, 28),
      ),
      ExpenseTransaction(
        id: '10',
        amount: 25.0,
        category: transport,
        account: upi,
        description: 'IDFC bus',
        timestamp: DateTime(now.year, now.month, 1, 10, 46),
      ),
    ];

    for (var tx in sampleData) {
      _transactions.add(tx);
      _categoryUsageCount[tx.category.id] = (_categoryUsageCount[tx.category.id] ?? 0) + 1;
      _accountUsageCount[tx.account.id] = (_accountUsageCount[tx.account.id] ?? 0) + 1;
    }
  }
}
