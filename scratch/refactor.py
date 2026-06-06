import re

with open('lib/screens/dashboard_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update DashboardScreen constructor
content = re.sub(
    r'class DashboardScreen extends StatefulWidget \{\n  const DashboardScreen\(\{super\.key\}\);\n  @override\n  State<DashboardScreen> createState\(\) => _DashboardScreenState\(\);\n\}',
    'class DashboardScreen extends StatefulWidget {\n  final Function(int) onNavigate;\n  const DashboardScreen({super.key, required this.onNavigate});\n  @override\n  State<DashboardScreen> createState() => _DashboardScreenState();\n}',
    content
)

# 2. Remove _currentIndex
content = re.sub(r'  int _currentIndex = 0;\n', '', content)

# 3. Replace _onNavTap, build, and _buildDashboardTab with just build
pattern = r'  void _onNavTap\(int i\) \{[\s\S]*?Widget _buildDashboardTab\(\) \{'
content = re.sub(pattern, '  @override\n  Widget build(BuildContext context) {', content)

# 4. Replace _onNavTap calls with widget.onNavigate
content = content.replace('onTap: () => _onNavTap(1),', 'onTap: () => widget.onNavigate(1),')
content = content.replace('onTap: () => _onNavTap(3),', 'onTap: () => widget.onNavigate(3),')

# 5. Remove _buildBottomNav
bottom_nav_pattern = r'  // ─── Bottom Nav ────────────────────────────────────────────────────────\n  Widget _buildBottomNav\(\) \{[\s\S]*?    \);\n  \}\n\}'
content = re.sub(bottom_nav_pattern, '}', content)

# 6. Remove unnecessary imports
content = content.replace("import 'suppliers_screen.dart';\n", '')
content = content.replace("import 'criteria_screen.dart';\n", '')
content = content.replace("import 'results_screen.dart';\n", '')

with open('lib/screens/dashboard_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
