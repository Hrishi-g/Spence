import 'package:flutter/material.dart';
import '../state/expense_state.dart';
import '../theme/app_theme.dart';

class SearchTransactionsScreen extends StatefulWidget {
  final ExpenseState expenseState;

  const SearchTransactionsScreen({super.key, required this.expenseState});

  @override
  State<SearchTransactionsScreen> createState() => _SearchTransactionsScreenState();
}

class _SearchTransactionsScreenState extends State<SearchTransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allTx = widget.expenseState.transactions;
    final results = _query.isEmpty
        ? allTx
        : allTx.where((tx) {
            final q = _query.toLowerCase();
            return tx.description.toLowerCase().contains(q) ||
                tx.category.displayName.toLowerCase().contains(q) ||
                tx.account.displayName.toLowerCase().contains(q);
          }).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: const InputDecoration(
            hintText: 'Search notes, category, amount...',
            hintStyle: TextStyle(color: Colors.white38, fontSize: 15),
            border: InputBorder.none,
          ),
          onChanged: (val) {
            setState(() {
              _query = val;
            });
          },
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white70),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _query = '';
                });
              },
            ),
        ],
      ),
      body: SafeArea(
        child: results.isEmpty
            ? const Center(
                child: Text(
                  'No matching transactions found',
                  style: TextStyle(color: Colors.white38),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final tx = results[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
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
                                tx.description,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${tx.category.displayName} • ${tx.account.displayName}',
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '-₹${tx.amount.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

