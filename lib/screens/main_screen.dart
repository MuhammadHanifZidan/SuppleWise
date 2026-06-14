import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'dashboard_screen.dart';
import 'suppliers_screen.dart';
import 'criteria_screen.dart';
import 'results_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _switchTab(int i) {
    if (_currentIndex == i) return;
    setState(() => _currentIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;
    switch (_currentIndex) {
      case 1:
        bodyContent = const SuppliersScreen();
        break;
      case 2:
        bodyContent = const CriteriaScreen();
        break;
      case 3:
        bodyContent = const ResultsScreen();
        break;
      case 0:
      default:
        bodyContent = DashboardScreen(onNavigate: _switchTab);
        break;
    }

    return Scaffold(
      body: bodyContent,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    const items = [
      (icon: Icons.dashboard_outlined, active: Icons.dashboard, label: 'Dashboard'),
      (icon: Icons.inventory_2_outlined, active: Icons.inventory_2, label: 'Suppliers'),
      (icon: Icons.rule_outlined, active: Icons.rule, label: 'Criteria'),
      (icon: Icons.analytics_outlined, active: Icons.analytics, label: 'Results'),
    ];
    final mq = MediaQuery.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
          left: 8, right: 8, top: 8, bottom: mq.padding.bottom + 8),
      child: Row(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final active = i == _currentIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => _switchTab(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primaryContainer.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      active ? item.active : item.icon,
                      color: active
                          ? AppColors.primary
                          : AppColors.onSecondaryContainer,
                      size: 24,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: active
                            ? AppColors.primary
                            : AppColors.onSecondaryContainer,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}