import 'package:flutter/material.dart';
import '../theme/AppTheme.dart';

class HomeMenu extends StatefulWidget {
  final Function(String)? onMenuSelected;

  const HomeMenu({super.key, this.onMenuSelected});

  @override
  State<HomeMenu> createState() => _HomeMenuState();
}

class _HomeMenuState extends State<HomeMenu> {
  final List<_MenuItem> menuItems = const [
    _MenuItem("FDFS Book", Icons.movie),
    _MenuItem("VIP Book", Icons.star),
    _MenuItem("Cinema Shorts", Icons.movie_filter),
    _MenuItem("Dream Movie", Icons.local_movies),
    _MenuItem("Trailer & Win", Icons.emoji_events),
  ];

  String? selectedMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly, // fit screen width
        children: menuItems.map((item) {
          final bool isSelected = selectedMenu == item.label;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedMenu = item.label;
              });
              widget.onMenuSelected?.call(item.label);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item.icon,
                    size: 20,
                    color: isSelected ? Colors.black : Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected ? Colors.black : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem {
  final String label;
  final IconData icon;

  const _MenuItem(this.label, this.icon);
}
