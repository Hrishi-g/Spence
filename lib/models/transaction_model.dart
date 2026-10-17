import 'package:flutter/material.dart';

class CategoryItem {
  final String id;
  final String displayName;
  final IconData icon;
  final Color color;
  final bool isCustom;

  const CategoryItem({
    required this.id,
    required this.displayName,
    required this.icon,
    required this.color,
    this.isCustom = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  static const List<CategoryItem> defaults = [
    CategoryItem(id: 'dining', displayName: 'Dining', icon: Icons.restaurant, color: Color(0xFFFF6B6B)),
    CategoryItem(id: 'groceries', displayName: 'Groceries', icon: Icons.shopping_basket, color: Color(0xFF4ECDC4)),
    CategoryItem(id: 'transport', displayName: 'Transport', icon: Icons.directions_bus, color: Color(0xFF45B7D1)),
    CategoryItem(id: 'shopping', displayName: 'Shopping', icon: Icons.shopping_bag, color: Color(0xFF96CEB4)),
    CategoryItem(id: 'health', displayName: 'Health', icon: Icons.medical_services, color: Color(0xFFFF9F43)),
    CategoryItem(id: 'housing', displayName: 'Housing', icon: Icons.home, color: Color(0xFF9B59B6)),
    CategoryItem(id: 'bill', displayName: 'Bill', icon: Icons.receipt_long, color: Color(0xFFF1C40F)),
    CategoryItem(id: 'personal', displayName: 'Personal', icon: Icons.person, color: Color(0xFF3498DB)),
    CategoryItem(id: 'telephone', displayName: 'Telephone', icon: Icons.phone_android, color: Color(0xFFE74C3C)),
  ];
}

class AccountItem {
  final String id;
  final String displayName;
  final IconData icon;
  final Color color;
  final bool isCustom;

  const AccountItem({
    required this.id,
    required this.displayName,
    required this.icon,
    required this.color,
    this.isCustom = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  static const List<AccountItem> defaults = [
    AccountItem(id: 'bank', displayName: 'Bank', icon: Icons.account_balance, color: Color(0xFF1E88E5)),
    AccountItem(id: 'mastercard', displayName: 'Mastercard', icon: Icons.credit_card, color: Color(0xFFEB001B)),
    AccountItem(id: 'rupay_card', displayName: 'Rupay card', icon: Icons.credit_card_outlined, color: Color(0xFF00838F)),
    AccountItem(id: 'upi', displayName: 'UPI', icon: Icons.qr_code_scanner, color: Color(0xFF2E7D32)),
  ];
}

class ExpenseTransaction {
  final String id;
  final double amount;
  final CategoryItem category;
  final AccountItem account;
  final String description;
  final DateTime timestamp;

  ExpenseTransaction({
    required this.id,
    required this.amount,
    required this.category,
    required this.account,
    required this.description,
    required this.timestamp,
  });
}
