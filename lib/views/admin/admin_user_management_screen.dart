import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/providers/admin_provider.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  UserRole? _selectedRole;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await context.read<AdminController>().loadData();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminController>();
    final users = provider.users.where((user) {
      final matchesQuery = _query.isEmpty ||
          user.fullName.toLowerCase().contains(_query) ||
          user.email.toLowerCase().contains(_query);
      final matchesRole = _selectedRole == null || user.role == _selectedRole;
      return matchesQuery && matchesRole;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quáº£n lÃ½ tÃ i khoáº£n'),
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'TÃ¬m theo tÃªn hoáº·c email',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _RoleChip(label: 'Táº¥t cáº£', selected: _selectedRole == null, onTap: () => setState(() => _selectedRole = null)),
                      _RoleChip(label: 'Student', selected: _selectedRole == UserRole.student, onTap: () => setState(() => _selectedRole = UserRole.student)),
                      _RoleChip(label: 'Teacher', selected: _selectedRole == UserRole.teacher, onTap: () => setState(() => _selectedRole = UserRole.teacher)),
                      _RoleChip(label: 'Admin', selected: _selectedRole == UserRole.admin, onTap: () => setState(() => _selectedRole = UserRole.admin)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SummaryBar(total: users.length, students: users.where((u) => u.role == UserRole.student).length, teachers: users.where((u) => u.role == UserRole.teacher).length),
                  const SizedBox(height: 16),
                  if (users.isEmpty)
                    const _EmptyState(message: 'KhÃ´ng tÃ¬m tháº¥y tÃ i khoáº£n phÃ¹ há»£p')
                  else
                    ...users.map((user) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _UserCard(user: user),
                        )),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demo UI: thÃªm tÃ i khoáº£n'))),
        icon: const Icon(Icons.person_add),
        label: const Text('ThÃªm user'),
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final int total;
  final int students;
  final int teachers;

  const _SummaryBar({required this.total, required this.students, required this.teachers});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SummaryCard(label: 'Tá»•ng', value: total.toString(), color: Colors.blue)),
        const SizedBox(width: 8),
        Expanded(child: _SummaryCard(label: 'Student', value: students.toString(), color: Colors.green)),
        const SizedBox(width: 8),
        Expanded(child: _SummaryCard(label: 'Teacher', value: teachers.toString(), color: Colors.orange)),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  final AppUser user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(child: Text(user.fullName[0].toUpperCase())),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(user.email, style: TextStyle(color: Colors.grey.shade700)),
                  ],
                ),
              ),
              _RoleBadge(role: user.role),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatusBadge(isActive: user.isActive),
              const SizedBox(width: 8),
              Text(user.schoolName ?? '-', style: TextStyle(color: Colors.grey.shade700)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(onPressed: () {}, icon: const Icon(Icons.edit), label: const Text('Sá»­a')),
              TextButton.icon(onPressed: () {}, icon: const Icon(Icons.delete), label: const Text('XÃ³a')),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final UserRole role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final color = switch (role) {
      UserRole.student => Colors.blue,
      UserRole.teacher => Colors.orange,
      UserRole.admin => Colors.purple,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(999)),
      child: Text(role.getDisplayName(), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;

  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.green : Colors.red;
    final label = isActive ? 'Active' : 'Locked';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.16))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.shade200)),
      child: Text(message, style: TextStyle(color: Colors.grey.shade700)),
    );
  }
}
