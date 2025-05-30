import 'package:flutter/material.dart';
import 'package:irich/pages/share/favorite_share_tab.dart';
import 'package:irich/pages/share/market_share_tab.dart';

class ShareLeftPanel extends StatefulWidget {
  const ShareLeftPanel({super.key});

  @override
  State<ShareLeftPanel> createState() => _ShareLeftPanelState();
}

class _ShareLeftPanelState extends State<ShareLeftPanel> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  Color? _selectedColor;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedColor = Theme.of(context).primaryColor;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      color: const Color(0xff000000),
      child: Column(
        children: [
          Row(
            children: [
              _buildTab(
                icon: Icons.trending_up,
                label: '市场行情',
                isSelected: _tabController.index == 0,
                onTap: () => _tabController.animateTo(1),
              ),
              _buildTab(
                icon: Icons.star,
                label: '自选股',
                isSelected: _tabController.index == 1,
                onTap: () => _tabController.animateTo(0),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [MarektShareTab(), FavoriteShareTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? _selectedColor : const Color.fromARGB(255, 81, 80, 80),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: isSelected ? _selectedColor : Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? _selectedColor : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
