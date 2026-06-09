import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:thpt_exam_prep_app/app_routes.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/providers_auth.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  bool _receiveLearningNotifications = true;
  bool _saveMobileData = false;
  bool _autoMarkCompleted = true;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthController>();
    final user = authProvider.currentUser;
    final roleLabel = user?.role.toValue() ?? 'student';

    return Scaffold(
      appBar: AppBar(
        title: const Text('CÃ¡ nhÃ¢n'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileHeader(context, user, roleLabel),
          const SizedBox(height: 20),
          Text(
            'ThÃ´ng tin há»c sinh',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'Há» tÃªn', value: user?.fullName ?? 'Há»c sinh'),
          _InfoRow(label: 'Email', value: user?.email ?? 'ChÆ°a cÃ³'),
          _InfoRow(label: 'Lá»›p', value: user?.className ?? '12A1'),
          _InfoRow(label: 'Vai trÃ²', value: roleLabel),
          const SizedBox(height: 20),
          Text(
            'CÃ i Ä‘áº·t demo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: _receiveLearningNotifications,
                  onChanged: (value) {
                    setState(() {
                      _receiveLearningNotifications = value;
                    });
                  },
                  title: const Text('Nháº­n nháº¯c há»c'),
                  subtitle: const Text('Báº­t/táº¯t demo thÃ´ng bÃ¡o há»c táº­p'),
                ),
                SwitchListTile(
                  value: _autoMarkCompleted,
                  onChanged: (value) {
                    setState(() {
                      _autoMarkCompleted = value;
                    });
                  },
                  title: const Text('Tá»± Ä‘Ã¡nh dáº¥u hoÃ n thÃ nh'),
                  subtitle: const Text('MÃ´ phá»ng cÃ i Ä‘áº·t tá»± Ä‘á»™ng lÆ°u tiáº¿n Ä‘á»™'),
                ),
                SwitchListTile(
                  value: _saveMobileData,
                  onChanged: (value) {
                    setState(() {
                      _saveMobileData = value;
                    });
                  },
                  title: const Text('Tiáº¿t kiá»‡m dá»¯ liá»‡u'),
                  subtitle: const Text('Giáº£m táº£i áº£nh vÃ  ná»™i dung náº·ng'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_none),
                  title: const Text('Má»Ÿ thÃ´ng bÃ¡o'),
                  subtitle: const Text('Xem cÃ¡c thÃ´ng bÃ¡o há»c táº­p gáº§n Ä‘Ã¢y'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.studentNotifications);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Giá»›i thiá»‡u'),
                  subtitle: const Text('Báº£n demo mÃ n hÃ¬nh cÃ¡ nhÃ¢n'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ÄÃ¢y lÃ  cÃ i Ä‘áº·t demo.')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: authProvider.isLoading
                  ? null
                  : () async {
                      await authProvider.logout();
                      if (!mounted) return;
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.login,
                        (route) => false,
                      );
                    },
              icon: const Icon(Icons.logout),
              label: const Text('ÄÄƒng xuáº¥t'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, AppUser? user, String roleLabel) {
    final initial = (user?.fullName ?? 'H').trim().isNotEmpty
        ? (user?.fullName ?? 'H').trim()[0].toUpperCase()
        : 'H';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Colors.indigo.shade600, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? 'Há»c sinh',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  user?.email ?? 'student@example.com',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Vai trÃ²: $roleLabel',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.85),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
