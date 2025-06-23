import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import 'todo_screen.dart';
import 'finance_screen.dart';
import 'export_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String userName = '';
  int tugasBelumSelesai = 0;
  int saldoKeuangan = 0;
  int suhuCuaca = 0;
  String statusLokasi = "";

  @override
  void initState() {
    super.initState();
    loadUser();
    loadDynamicData();
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? '';
    setState(() {
      userName = email.split('@').first;
    });
  }

  Future<void> loadDynamicData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      tugasBelumSelesai = prefs.getInt('task_pending') ?? 0;
      saldoKeuangan = prefs.getInt('saldo_keuangan') ?? 0;
      suhuCuaca = prefs.getInt('suhu') ?? 0;
      statusLokasi = prefs.getString('lokasi_status') ?? 'Tidak aktif';
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      MainDashboard(
        userName: userName,
        tugasBelumSelesai: tugasBelumSelesai,
        suhuCuaca: suhuCuaca,
        statusLokasi: statusLokasi,
        saldoKeuangan: saldoKeuangan,
        onRefresh: loadDynamicData,
      ),
      const TodoScreen(),
      const FinanceScreen(),
      const ExportScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) async {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 0) {
            await loadDynamicData(); // 🔁 refresh data dashboard saat kembali
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.check), label: 'Task'),
          BottomNavigationBarItem(icon: Icon(Icons.wallet), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.download), label: 'Export'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class MainDashboard extends StatelessWidget {
  final String userName;
  final int tugasBelumSelesai;
  final int suhuCuaca;
  final String statusLokasi;
  final int saldoKeuangan;
  final Future<void> Function()? onRefresh;

  const MainDashboard({
    super.key,
    required this.userName,
    required this.tugasBelumSelesai,
    required this.suhuCuaca,
    required this.statusLokasi,
    required this.saldoKeuangan,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TRENIX',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.pushNamed(context, '/notifications');
                    },
                  ),
                  const SizedBox(width: 10),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) => IconButton(
                      icon: Icon(
                        themeProvider.themeMode == ThemeMode.dark
                            ? Icons.dark_mode
                            : Icons.light_mode,
                      ),
                      onPressed: themeProvider.toggleTheme,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Halo, $userName 👋',
              style: theme.textTheme.titleMedium,
            ),
          ),
        ),
        const SizedBox(height: 200),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildCard(
                context,
                icon: Icons.check_circle,
                title: 'Tugas Hari Ini',
                subtitle: '$tugasBelumSelesai belum selesai',
                onTap: () {
                  Navigator.pushNamed(context, '/todo').then((_) {
                    onRefresh?.call(); // 🔁 refresh setelah balik dari Todo
                  });
                },
                iconColor: Colors.green,
              ),
              _buildCard(
                context,
                icon: Icons.wallet,
                title: 'Smart Finance',
                subtitle: 'Rp$saldoKeuangan',
                onTap: () {
                  Navigator.pushNamed(context, '/finance').then((_) {
                    onRefresh?.call();
                  });
                },
              ),
              _buildCard(
                context,
                icon: Icons.location_on,
                title: 'Status Lokasi',
                subtitle: statusLokasi,
                onTap: () {
                  Navigator.pushNamed(context, '/map').then((_) {
                    onRefresh?.call();
                  });
                },
              ),
              _buildCard(
                context,
                icon: Icons.cloud,
                title: 'Cuaca',
                subtitle: '$suhuCuaca°C',
                onTap: () {
                  Navigator.pushNamed(context, '/weather').then((_) {
                    onRefresh?.call();
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: iconColor ?? theme.iconTheme.color),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                // ignore: deprecated_member_use
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
