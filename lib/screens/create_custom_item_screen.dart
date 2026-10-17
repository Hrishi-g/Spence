import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum CustomType { category, account }

class CreateCustomItemScreen extends StatefulWidget {
  final CustomType type;
  final Function(String name, IconData icon, Color color) onSave;

  const CreateCustomItemScreen({
    super.key,
    required this.type,
    required this.onSave,
  });

  @override
  State<CreateCustomItemScreen> createState() => _CreateCustomItemScreenState();
}

class _CreateCustomItemScreenState extends State<CreateCustomItemScreen> {
  final TextEditingController _nameController = TextEditingController();
  int _selectedTab = 0; // 0: Expenses, 1: Income
  int _selectedStyle = 0; // Style1, Style2, Style3, Style4
  int _selectedIconIndex = 0;

  // 28 Vector Icon Options matching reference image
  static const List<IconData> availableIcons = [
    Icons.restaurant_outlined, // Food/Fork
    Icons.local_drink_outlined, // Drink/Juice
    Icons.sanitizer_outlined, // Soap/Sanitizer
    Icons.favorite_border_outlined, // Heart/Chat
    Icons.eco_outlined, // Veggie
    Icons.apple_outlined, // Fruit
    Icons.kebab_dining_outlined, // Meat/Chicken
    Icons.cake_outlined, // Candy/Sweets
    Icons.mail_outline_rounded, // Red envelope
    Icons.music_note_outlined, // Media/iPod
    Icons.photo_camera_outlined, // Camera
    Icons.cast_for_education_outlined, // Board 1+1
    Icons.fitness_center_outlined, // Dumbbell
    Icons.sports_tennis_outlined, // Pingpong
    Icons.sports_esports_outlined, // Gameboy
    Icons.movie_outlined, // Film reel
    Icons.explore_outlined, // Signpost
    Icons.face_outlined, // Spa mask
    Icons.brush_outlined, // Lipstick/Makeup
    Icons.checkroom_outlined, // T-shirt/Clothes
    Icons.work_outline, // Handbag
    Icons.hiking_outlined, // Boot
    Icons.face_retouching_natural_outlined, // Hat
    Icons.diamond_outlined, // Jewelry/Earrings
    Icons.directions_car_filled_outlined, // Car
    Icons.sports_bar_outlined, // Beer
    Icons.home_outlined, // House
    Icons.account_balance_outlined, // Bank/Account
  ];

  // Colors based on selected Style tab
  static const List<List<Color>> styleColors = [
    [Color(0xFFFFC107), Color(0xFFFF9800), Color(0xFFFF5722)], // Style 1: Warm Gold / Amber
    [Color(0xFF4FC3F7), Color(0xFF00BCD4), Color(0xFF0288D1)], // Style 2: Cyan / Blue
    [Color(0xFFEC407A), Color(0xFFE91E63), Color(0xFFC2185B)], // Style 3: Pink / Magenta
    [Color(0xFF66BB6A), Color(0xFF4CAF50), Color(0xFF388E3C)], // Style 4: Green / Emerald
  ];

  Color get _currentSelectedColor {
    final palette = styleColors[_selectedStyle];
    return palette[_selectedIconIndex % palette.length];
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter ${widget.type == CustomType.category ? "category" : "account"} name'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    widget.onSave(
      name,
      availableIcons[_selectedIconIndex],
      _currentSelectedColor,
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typeTitle = widget.type == CustomType.category ? 'Category' : 'Account';

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Custom $typeTitle',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.check, color: AppTheme.accentGold, size: 26),
              onPressed: _submit,
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),

              // Tab Bar: Expenses / Income
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTopTab('Expenses', 0),
                  const SizedBox(width: 40),
                  _buildTopTab('Income', 1),
                ],
              ),

              const SizedBox(height: 24),

              // Center Selected Icon Preview Circle
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.accentGold, width: 2.5),
                  color: Colors.black,
                ),
                child: Icon(
                  availableIcons[_selectedIconIndex],
                  color: _currentSelectedColor,
                  size: 42,
                ),
              ),

              const SizedBox(height: 16),

              // Text Field: Enter category/account name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50.0),
                child: TextField(
                  controller: _nameController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter $typeTitle name',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 16),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white38),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.accentGold, width: 2),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Style Tabs: Style1, Style2, Style3, Style4
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: List.generate(4, (index) {
                    final isSelected = index == _selectedStyle;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedStyle = index;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 24),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Style${index + 1}',
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white54,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 15,
                                  ),
                                ),
                                if (index > 0) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.workspace_premium, color: AppTheme.accentGold, size: 14),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (isSelected)
                              Container(
                                width: 45,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: AppTheme.accentGold,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 20),

              // Icon Grid Picker (28 items, 4 per row)
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: availableIcons.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 18,
                  ),
                  itemBuilder: (context, index) {
                    final isSelected = index == _selectedIconIndex;
                    final palette = styleColors[_selectedStyle];
                    final iconColor = palette[index % palette.length];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIconIndex = index;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? AppTheme.surfaceLight : AppTheme.surface,
                          border: isSelected
                              ? Border.all(color: AppTheme.accentGold, width: 2)
                              : Border.all(color: Colors.transparent),
                        ),
                        child: Icon(
                          availableIcons[index],
                          color: iconColor,
                          size: 26,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopTab(String title, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white38,
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          if (isSelected)
            Container(
              width: 50,
              height: 3,
              decoration: BoxDecoration(
                color: AppTheme.accentGold,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}

