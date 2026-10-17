import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../state/expense_state.dart';
import '../theme/app_theme.dart';
import 'all_categories_modal.dart';
import 'all_accounts_modal.dart';

class AddExpenseScreen extends StatefulWidget {
  final ExpenseState expenseState;
  final ExpenseTransaction? initialTransaction;
  final VoidCallback? onExpenseAdded;

  const AddExpenseScreen({
    super.key,
    required this.expenseState,
    this.initialTransaction,
    this.onExpenseAdded,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  String _amountRaw = '';
  late CategoryItem _selectedCategory;
  late AccountItem _selectedAccount;
  DateTime _selectedDate = DateTime.now();

  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _noteController.addListener(_onNoteChanged);
    if (widget.initialTransaction != null) {
      final tx = widget.initialTransaction!;
      final isInt = tx.amount.truncateToDouble() == tx.amount;
      _amountRaw = isInt ? tx.amount.toInt().toString() : tx.amount.toStringAsFixed(2);
      _selectedCategory = tx.category;
      _selectedAccount = tx.account;
      _selectedDate = tx.timestamp;
      _noteController.text = tx.description;
    } else {
      _selectedCategory = widget.expenseState.top5Categories.first;
      _selectedAccount = widget.expenseState.topAccounts.first;
    }
  }

  void _onNoteChanged() {
    setState(() {});
  }

  void _confirmDeleteDescription(String desc) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.white12),
          ),
          title: const Text(
            'Delete Description?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Do you want to delete "$desc" from saved suggestions?',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                widget.expenseState.deleteSavedDescription(desc);
                Navigator.pop(ctx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted "$desc" from suggestions'),
                    backgroundColor: Colors.redAccent,
                    duration: const Duration(seconds: 1),
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

  @override
  void dispose() {
    _noteController.removeListener(_onNoteChanged);
    _noteController.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  void _onKeyPress(String val) {
    setState(() {
      if (val == '.') {
        if (!_amountRaw.contains('.')) {
          if (_amountRaw.isEmpty) {
            _amountRaw = '0.';
          } else {
            _amountRaw += '.';
          }
        }
      } else {
        if (_amountRaw.contains('.')) {
          final parts = _amountRaw.split('.');
          if (parts.length > 1 && parts[1].length >= 2) return;
        }
        if (_amountRaw == '0') {
          _amountRaw = val;
        } else {
          _amountRaw += val;
        }
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (_amountRaw.isNotEmpty) {
        _amountRaw = _amountRaw.substring(0, _amountRaw.length - 1);
      }
    });
  }

  void _pickDate() async {
    FocusScope.of(context).unfocus();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.accentGold,
              onPrimary: Colors.black,
              surface: AppTheme.surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _openCategoryPicker() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AllCategoriesModal(
        selectedCategory: _selectedCategory,
        expenseState: widget.expenseState,
        onSelectCategory: (cat) {
          setState(() {
            _selectedCategory = cat;
          });
        },
      ),
    );
  }

  void _openAccountPicker() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AllAccountsModal(
        selectedAccount: _selectedAccount,
        expenseState: widget.expenseState,
        onSelectAccount: (acc) {
          setState(() {
            _selectedAccount = acc;
          });
        },
      ),
    );
  }

  void _saveExpense() {
    FocusScope.of(context).unfocus();
    final double amount = double.tryParse(_amountRaw) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid expense amount'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (widget.initialTransaction != null) {
      widget.expenseState.updateTransaction(
        id: widget.initialTransaction!.id,
        amount: amount,
        category: _selectedCategory,
        account: _selectedAccount,
        description: _noteController.text,
        date: _selectedDate,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated ₹${amount.toStringAsFixed(2)} under ${_selectedCategory.displayName}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      if (widget.onExpenseAdded != null) {
        widget.onExpenseAdded!();
      } else if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      return;
    } else {
      widget.expenseState.addTransaction(
        amount: amount,
        category: _selectedCategory,
        account: _selectedAccount,
        description: _noteController.text,
        date: _selectedDate,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved ₹${amount.toStringAsFixed(2)} under ${_selectedCategory.displayName}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    setState(() {
      _amountRaw = '';
      _noteController.clear();
      _selectedDate = DateTime.now();
    });

    if (widget.onExpenseAdded != null) {
      widget.onExpenseAdded!();
    }
  }

  String get _displayAmount {
    if (_amountRaw.isEmpty) {
      return '₹0';
    }
    return '₹$_amountRaw';
  }

  String get _displayDateText {
    final now = DateTime.now();
    if (_selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day) {
      return 'Today, ${_selectedDate.day} ${_monthNameAbbr(_selectedDate.month)}';
    }
    return '${_selectedDate.day} ${_monthNameAbbr(_selectedDate.month)} ${_selectedDate.year}';
  }

  String _monthNameAbbr(int month) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialTransaction != null;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text(
            isEditing ? 'Edit Expense' : 'New Expense',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.check, color: AppTheme.accentGold, size: 24),
              onPressed: _saveExpense,
            )
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 16.0,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 4),

                        // Top Amount Display
                        Center(
                          child: Column(
                            children: [
                              Text(
                                _displayAmount,
                                style: const TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Tap keypad below to enter amount',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white38,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // CATEGORY SECTION (Clean Wrap of chips)
                        _buildCategorySection(),

                        const SizedBox(height: 14),

                        // UNIFIED DETAILS CARD (Account, Date, Note)
                        _buildDetailsCard(),

                        // AUTO-SUGGESTED DESCRIPTION PILLS
                        _buildDescriptionSuggestions(),

                        const Spacer(),

                        // If soft keyboard is open, show Done / Action bar
                        if (isKeyboardOpen) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => FocusScope.of(context).unfocus(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white70,
                                    side: const BorderSide(color: Colors.white24),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text('Hide Keyboard'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: _saveExpense,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.accentGold,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    isEditing ? 'Update Expense' : 'Add Expense',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ] else ...[
                          // When keyboard is closed, show custom numeric keypad and Add Expense button
                          const SizedBox(height: 8),
                          _buildKeypad(),
                          const SizedBox(height: 12),
                          _buildBottomButton(isEditing),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    final topCategories = widget.expenseState.top5Categories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CATEGORY',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...topCategories.map((cat) {
              final isSelected = cat.id == _selectedCategory.id;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = cat;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.accentGold : const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppTheme.accentGold : Colors.white12,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cat.icon,
                        size: 15,
                        color: isSelected ? Colors.black : cat.color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cat.displayName,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            GestureDetector(
              onTap: _openCategoryPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 15, color: AppTheme.accentGold),
                    SizedBox(width: 4),
                    Text(
                      'More',
                      style: TextStyle(
                        color: AppTheme.accentGold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          // Account Row
          InkWell(
            onTap: _openAccountPicker,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Text(
                    'Account',
                    style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Icon(_selectedAccount.icon, size: 16, color: _selectedAccount.color),
                  const SizedBox(width: 6),
                  Text(
                    _selectedAccount.displayName,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 18, color: Colors.white38),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          // Date Row
          InkWell(
            onTap: _pickDate,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Text(
                    'Date',
                    style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  const Icon(Icons.calendar_today, size: 14, color: AppTheme.accentGold),
                  const SizedBox(width: 6),
                  Text(
                    _displayDateText,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 18, color: Colors.white38),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          // Note / Description Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Text(
                  'Note',
                  style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    focusNode: _noteFocusNode,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Add a note / description...',
                      hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                if (_noteController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _noteController.clear();
                      setState(() {});
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.clear, size: 16, color: Colors.white38),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSuggestions() {
    final suggestions = widget.expenseState.getMatchingDescriptions(_noteController.text);
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: suggestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final desc = suggestions[index];
              final isMatchingExact =
                  _noteController.text.trim().toLowerCase() == desc.toLowerCase();

              return Container(
                decoration: BoxDecoration(
                  color: isMatchingExact ? AppTheme.accentGold.withOpacity(0.18) : const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isMatchingExact ? AppTheme.accentGold : Colors.white12,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      _noteController.text = desc;
                      _noteController.selection = TextSelection.fromPosition(
                        TextPosition(offset: desc.length),
                      );
                      setState(() {});
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bookmark_outline,
                            size: 13,
                            color: isMatchingExact ? AppTheme.accentGold : Colors.white38,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            desc,
                            style: TextStyle(
                              color: isMatchingExact ? AppTheme.accentGold : Colors.white,
                              fontSize: 12,
                              fontWeight: isMatchingExact ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _confirmDeleteDescription(desc),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.white10,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 11,
                                color: Colors.white60,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildKeypad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '⌫'],
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: keys.map((row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: InkWell(
                    onTap: () {
                      if (key == '⌫') {
                        _onBackspace();
                      } else {
                        _onKeyPress(key);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF202020),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        key,
                        style: TextStyle(
                          fontSize: key == '⌫' ? 18 : 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomButton(bool isEditing) {
    return ElevatedButton(
      onPressed: _saveExpense,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.accentGold,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
      child: Text(
        isEditing ? 'Update Expense' : 'Add Expense',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
