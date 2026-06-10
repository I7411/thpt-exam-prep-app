import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:thpt_exam_prep_app/app_routes.dart';
import 'package:thpt_exam_prep_app/app_theme.dart';
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

  Future<String?>? _classNameFuture;
  String? _lastClassId;

  Future<String?> _fetchClassName(String classId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .get()
          .timeout(const Duration(seconds: 5));
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          return data['name'] as String? ?? data['className'] as String? ?? 'Lớp không tên';
        }
      }
    } catch (e) {
      debugPrint('Lỗi lấy tên lớp: $e');
    }
    return 'Lớp không tên';
  }

  void _showEditProfileDialog(BuildContext context, AppUser? user) {
    if (user == null) return;
    final controller = TextEditingController(text: user.fullName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cập nhật họ tên'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Họ tên',
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
                    const SnackBar(content: Text('Vui lòng nhập họ tên')),
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
                            ? 'Cập nhật họ tên thành công!'
                            : 'Cập nhật họ tên thất bại.',
                      ),
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

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthController>();
    final user = authProvider.currentUser;
    final roleLabel = user?.role.toValue() ?? 'student';

    final classId = user?.primaryClassId ?? (user?.classIds.isNotEmpty == true ? user?.classIds.first : null);
    if (classId != _lastClassId) {
      _lastClassId = classId;
      if (classId != null) {
        _classNameFuture = _fetchClassName(classId);
      } else {
        _classNameFuture = Future.value(user?.className);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cá nhân'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditProfileDialog(context, user),
            tooltip: 'Sửa họ tên',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileHeader(context, user, roleLabel),
          const SizedBox(height: 20),
          Text(
            'Thông tin học sinh',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'Họ tên', value: user?.fullName ?? 'Học sinh'),
          _InfoRow(label: 'Email', value: user?.email ?? 'Chưa có'),
          FutureBuilder<String?>(
            future: _classNameFuture,
            builder: (context, snapshot) {
              final className = snapshot.data ?? user?.className ?? 'Chưa tham gia';
              return _InfoRow(label: 'Lớp', value: className);
            },
          ),
          _InfoRow(label: 'Mã tài khoản (UID)', value: user?.id ?? ''),
          _InfoRow(label: 'Vai trò', value: roleLabel == 'student' ? 'Học sinh' : roleLabel),
          const SizedBox(height: 20),
          Text(
            'Cài đặt demo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              side: const BorderSide(color: AppColors.line),
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
                  title: const Text('Nhận nhắc học'),
                  subtitle: const Text('Bật/tắt demo thông báo học tập'),
                ),
                SwitchListTile(
                  value: _autoMarkCompleted,
                  onChanged: (value) {
                    setState(() {
                      _autoMarkCompleted = value;
                    });
                  },
                  title: const Text('Tự đánh dấu hoàn thành'),
                  subtitle: const Text('Mô phỏng cài đặt tự động lưu tiến độ'),
                ),
                SwitchListTile(
                  value: _saveMobileData,
                  onChanged: (value) {
                    setState(() {
                      _saveMobileData = value;
                    });
                  },
                  title: const Text('Tiết kiệm dữ liệu'),
                  subtitle: const Text('Giảm tải ảnh và nội dung nặng'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              side: const BorderSide(color: AppColors.line),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_none),
                  title: const Text('Mở thông báo'),
                  subtitle: const Text('Xem các thông báo học tập gần đây'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.studentNotifications);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Giới thiệu'),
                  subtitle: const Text('Bản demo màn hình cá nhân'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đây là cài đặt demo.')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Bảo mật tài khoản',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              side: const BorderSide(color: AppColors.line),
            ),
            child: ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Đổi mật khẩu'),
              subtitle: const Text('Cập nhật mật khẩu bảo mật tài khoản'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _handleChangePasswordTap(context);
              },
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
              label: const Text('Đăng xuất'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
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
        borderRadius: BorderRadius.circular(AppRadius.panel),
        gradient: AppGradients.primary,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
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
                  user?.fullName ?? 'Học sinh',
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
                  'Vai trò: ${roleLabel == 'student' ? 'Học sinh' : roleLabel}',
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
                            content: Text('Đổi mật khẩu thành công. Vui lòng đăng nhập lại nếu được yêu cầu.'),
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
        borderRadius: BorderRadius.circular(AppRadius.card),
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
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
