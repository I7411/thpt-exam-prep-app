import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thpt_exam_prep_app/core/routes/app_routes.dart';
import 'package:thpt_exam_prep_app/controllers/teacher_controller.dart';
import 'package:thpt_exam_prep_app/controllers/auth_controller.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthController>();
    await context.read<TeacherController>().ensureLoaded(authProvider.currentUser);
  }

  Future<void> _logout() async {
    await context.read<AuthController>().logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthController>();
    final teacherProvider = context.watch<TeacherController>();
    final teacher = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ giáo viên'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditProfileDialog(context, teacher),
            tooltip: 'Sửa họ tên',
          ),
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: teacherProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeader(teacher),
                  const SizedBox(height: 16),
                  _buildStats(teacherProvider),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    title: 'Thông tin tài khoản',
                    children: [
                      _InfoRow(label: 'Email', value: teacher?.email ?? '-'),
                      _InfoRow(label: 'Trường', value: teacher?.schoolName ?? '-'),
                      _InfoRow(label: 'Vai trò', value: teacher?.role.getDisplayName() ?? '-'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    title: 'Bảo mật tài khoản',
                    children: [
                      _ActionRow(
                        icon: Icons.lock_outline,
                        title: 'Đổi mật khẩu',
                        onTap: () => _handleChangePasswordTap(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    title: 'Thao tác nhanh',
                    children: [
                      _ActionRow(
                        icon: Icons.class_,
                        title: 'Danh sách lớp',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.teacherClasses),
                      ),
                      _ActionRow(
                        icon: Icons.quiz,
                        title: 'Ngân hàng câu hỏi',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.teacherQuestions),
                      ),

                      _ActionRow(
                        icon: Icons.logout,
                        title: 'Đăng xuất',
                        onTap: _logout,
                        destructive: true,
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader(dynamic teacher) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF6C00), Color(0xFFE65100)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withOpacity(0.16),
            child: Text(
              (teacher?.fullName ?? 'G')[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teacher?.fullName ?? 'Giáo viên',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  teacher?.bio ?? 'Quản lý lớp và đề thi',
                  style: TextStyle(color: Colors.white.withOpacity(0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(TeacherController teacherProvider) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.8,
      ),
      children: [
        _ProfileStat(label: 'Lớp', value: teacherProvider.classes.length.toString(), color: Colors.blue),
        _ProfileStat(label: 'Học sinh', value: teacherProvider.totalStudents.toString(), color: Colors.green),
        _ProfileStat(label: 'Đề', value: teacherProvider.assignedExams.length.toString(), color: Colors.orange),
        _ProfileStat(label: 'Tiến độ', value: '${teacherProvider.averageProgress.toStringAsFixed(0)}%', color: Colors.purple),
      ],
    );
  }

  Widget _buildInfoCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, dynamic teacher) {
    if (teacher == null) return;
    final controller = TextEditingController(text: teacher.fullName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cập nhật họ tên'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Họ tên giáo viên',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập họ tên.')),
                  );
                  return;
                }
                if (name.length < 2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Họ tên phải có ít nhất 2 ký tự.')),
                  );
                  return;
                }
                Navigator.pop(context);
                
                final authProvider = Provider.of<AuthController>(context, listen: false);
                final success = await authProvider.updateProfile(fullName: name);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Cập nhật tên giáo viên thành công.'
                            : 'Không thể cập nhật tên. Vui lòng thử lại.',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  void _handleChangePasswordTap(BuildContext context) {
    final isPasswordUser = _isPasswordUser();
    if (!isPasswordUser) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Đổi mật khẩu'),
          content: const Text(
            'Tài khoản Google không thể đổi mật khẩu trong ứng dụng. Vui lòng quản lý mật khẩu trong tài khoản Google.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đồng ý'),
            ),
          ],
        ),
      );
      return;
    }

    _showChangePasswordDialog(context);
  }

  bool _isPasswordUser() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    for (final provider in currentUser.providerData) {
      if (provider.providerId == 'password') {
        return true;
      }
    }
    return false;
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Đổi mật khẩu'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: currentPasswordController,
                        obscureText: obscureCurrent,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu hiện tại',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => obscureCurrent = !obscureCurrent),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập mật khẩu hiện tại.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: obscureNew,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu mới',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => obscureNew = !obscureNew),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập mật khẩu mới.';
                          }
                          if (value.length < 6) {
                            return 'Mật khẩu mới phải có ít nhất 6 ký tự.';
                          }
                          if (value == currentPasswordController.text) {
                            return 'Mật khẩu mới không được trùng mật khẩu hiện tại.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Xác nhận mật khẩu mới',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng xác nhận mật khẩu mới.';
                          }
                          if (value != newPasswordController.text) {
                            return 'Mật khẩu xác nhận không khớp.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() != true) return;
                    
                    // Show progress indicator
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(child: CircularProgressIndicator()),
                    );

                    final authController = Provider.of<AuthController>(context, listen: false);
                    final success = await authController.changePassword(
                      currentPassword: currentPasswordController.text,
                      newPassword: newPasswordController.text,
                    );

                    // Dismiss progress indicator
                    if (context.mounted) {
                      Navigator.pop(context);
                    }

                    if (success) {
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đổi mật khẩu thành công.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(authController.errorMessage.isNotEmpty 
                                ? authController.errorMessage 
                                : 'Không thể đổi mật khẩu. Vui lòng thử lại.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Cập nhật mật khẩu'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ProfileStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: TextStyle(color: Colors.grey.shade700))),
          Expanded(flex: 3, child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool destructive;

  const _ActionRow({required this.icon, required this.title, required this.onTap, this.destructive = false});

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.red : Colors.blueGrey;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600))),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
