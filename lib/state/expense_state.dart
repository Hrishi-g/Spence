import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/database_service.dart';

class ExpenseState extends ChangeNotifier {
  final List<ExpenseTransaction> _transactions = [];
  final List<CategoryItem> _allCategories = List.from(CategoryItem.defaults);
  final List<AccountItem> _allAccounts = List.from(AccountItem.defaults);

  final Map<String, int> _categoryUsageCount = {};
  final Map<String, int> _accountUsageCount = {};

  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedCalendarDate;
  bool _isInitialized = false;
  Future<void>? _initFuture;

  bool get isInitialized => _isInitialized;

  final List<String> _savedDescriptions = [];

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
      DatabaseService.instance.insertSavedDescription(trimmed);
      notifyListeners();
    }
  }

  void deleteSavedDescription(String description) {
    final trimmed = description.trim();
    _savedDescriptions.removeWhere(
      (d) => d.toLowerCase() == trimmed.toLowerCase(),
    );
    DatabaseService.instance.deleteSavedDescription(trimmed);
    notifyListeners();
  }

  ExpenseState();

  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_initFuture != null) return _initFuture!;
    _initFuture = _doInitialize();
    return _initFuture!;
  }

  Future<void> _doInitialize() async {
    try {
      final dbService = DatabaseService.instance;
      await dbService.init();
      await _loadFromDatabase();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing database: $e');
    }
  }

  Future<void> reloadFromDatabase() async {
    await _loadFromDatabase();
    notifyListeners();
  }

  Future<String> getDatabasePath() async {
    return await DatabaseService.instance.getDatabasePath();
  }

  Future<bool> importDatabase(String sourceFilePath) async {
    final success = await DatabaseService.instance.importDatabase(sourceFilePath);
    if (success) {
      await _loadFromDatabase();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<String> exportDatabase({String? destinationDirectory}) async {
    return await DatabaseService.instance.exportDatabase(destinationDirectory: destinationDirectory);
  }

  Future<void> _loadFromDatabase() async {
    final dbService = DatabaseService.instance;
    final dbCategories = await dbService.getCategories();
    if (dbCategories.isNotEmpty) {
      _allCategories.clear();
      _allCategories.addAll(dbCategories);
    }

    final dbAccounts = await dbService.getAccounts();
    if (dbAccounts.isNotEmpty) {
      _allAccounts.clear();
      _allAccounts.addAll(dbAccounts);
    }

    final dbDescriptions = await dbService.getSavedDescriptions();
    if (dbDescriptions.isNotEmpty) {
      _savedDescriptions.clear();
      _savedDescriptions.addAll(dbDescriptions);
    }

    final catMap = {for (var c in _allCategories) c.id: c};
    final accMap = {for (var a in _allAccounts) a.id: a};

    final dbTransactions = await dbService.getTransactions(catMap, accMap);
    _transactions.clear();
    _transactions.addAll(dbTransactions);

    _categoryUsageCount.clear();
    _accountUsageCount.clear();
    for (var tx in _transactions) {
      _categoryUsageCount[tx.category.id] = (_categoryUsageCount[tx.category.id] ?? 0) + 1;
      _accountUsageCount[tx.account.id] = (_accountUsageCount[tx.account.id] ?? 0) + 1;
    }
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

  void resetToCurrentDate() {
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _selectedCalendarDate = null;
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

  // Dynamic daily totals for active days in selected month (chronological order)
  List<double> get selectedMonthDailyTotals {
    final grouped = selectedMonthGroupedByDate;
    final sortedDates = grouped.keys.toList()..sort((a, b) => a.compareTo(b));
    return sortedDates.map((date) =>
      grouped[date]!.fold(0.0, (sum, tx) => sum + tx.amount)
    ).toList();
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
    DatabaseService.instance.insertCategory(category, _allCategories.length);
    notifyListeners();
  }

  void addAccount(AccountItem account) {
    _allAccounts.add(account);
    DatabaseService.instance.insertAccount(account, _allAccounts.length);
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

    DatabaseService.instance.insertTransaction(transaction);

    final trimmedDesc = description.trim();
    if (trimmedDesc.isNotEmpty && trimmedDesc.toLowerCase() != category.displayName.toLowerCase()) {
      final exists = _savedDescriptions.any((d) => d.toLowerCase() == trimmedDesc.toLowerCase());
      if (!exists) {
        _savedDescriptions.insert(0, trimmedDesc);
        DatabaseService.instance.insertSavedDescription(trimmedDesc);
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
      final updatedTx = ExpenseTransaction(
        id: id,
        amount: amount,
        category: category,
        account: account,
        description: description.trim().isEmpty ? category.displayName : description,
        timestamp: date ?? oldTx.timestamp,
      );
      _transactions[index] = updatedTx;

      DatabaseService.instance.updateTransaction(updatedTx);

      final trimmedDesc = description.trim();
      if (trimmedDesc.isNotEmpty && trimmedDesc.toLowerCase() != category.displayName.toLowerCase()) {
        final exists = _savedDescriptions.any((d) => d.toLowerCase() == trimmedDesc.toLowerCase());
        if (!exists) {
          _savedDescriptions.insert(0, trimmedDesc);
          DatabaseService.instance.insertSavedDescription(trimmedDesc);
        }
      }
      notifyListeners();
    }
  }

  void deleteTransaction(String id) {
    final index = _transactions.indexWhere((tx) => tx.id == id);
    if (index != -1) {
      final tx = _transactions.removeAt(index);
      final currentCatCount = _categoryUsageCount[tx.category.id] ?? 1;
      _categoryUsageCount[tx.category.id] = currentCatCount > 1 ? currentCatCount - 1 : 0;
      final currentAccCount = _accountUsageCount[tx.account.id] ?? 1;
      _accountUsageCount[tx.account.id] = currentAccCount > 1 ? currentAccCount - 1 : 0;

      DatabaseService.instance.deleteTransaction(id);
      notifyListeners();
    }
  }

  double getAccountMonthlyExpense(String accountId) {
    return selectedMonthTransactions
        .where((tx) => tx.account.id == accountId)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double getAccountTotalExpense(String accountId) {
    return _transactions
        .where((tx) => tx.account.id == accountId)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  List<ExpenseTransaction> getAccountTransactions(String accountId) {
    return transactions
        .where((tx) => tx.account.id == accountId)
        .toList();
  }

  double getCategoryTotalExpense(String categoryId) {
    return _transactions
        .where((tx) => tx.category.id == categoryId)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  List<ExpenseTransaction> getCategoryTransactions(String categoryId) {
    return transactions
        .where((tx) => tx.category.id == categoryId)
        .toList();
  }
}
