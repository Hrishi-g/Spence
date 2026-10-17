import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../state/expense_state.dart';
import '../theme/app_theme.dart';
import 'create_custom_item_screen.dart';

class AllCategoriesModal extends StatelessWidget {
  final CategoryItem selectedCategory;
  final ExpenseState expenseState;
  final ValueChanged<CategoryItem> onSelectCategory;

  const AllCategoriesModal({
    super.key,
    required this.selectedCategory,
    required this.expenseState,
    required this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    final allCategories = expenseState.allCategories;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Category',
                style: TextStyle(
                  color: AppTheme.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AppTheme.secondaryText),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: allCategories.length + 1, // +1 for "Add Custom Category" button
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) {
              if (index == allCategories.length) {
                // Add New Custom Category Button
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateCustomItemScreen(
                          type: CustomType.category,
                          onSave: (name, icon, color) {
                            final newCat = CategoryItem(
                              id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
                              displayName: name,
                              icon: icon,
                              color: color,
                              isCustom: true,
                            );
                            expenseState.addCategory(newCat);
                            onSelectCategory(newCat);
                          },
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.accentGold.withOpacity(0.6),
                        width: 1.5,
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline, color: AppTheme.accentGold, size: 28),
                        SizedBox(height: 6),
                        Text(
                          'Add Custom',
                          style: TextStyle(
                            color: AppTheme.accentGold,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final cat = allCategories[index];
              final isSelected = cat == selectedCategory;
              return GestureDetector(
                onTap: () {
                  onSelectCategory(cat);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cat.color.withOpacity(0.25)
                        : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? cat.color : AppTheme.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cat.color.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(cat.icon, color: cat.color, size: 22),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cat.displayName,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.primaryText,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
