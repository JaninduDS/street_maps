import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../core/utils/app_notifications.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  bool _isLoading = true;
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .order('created_at', ascending: false);
      
      if (mounted) {
        setState(() {
          _users = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching users: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateRole(String userId, String newRole) async {
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'role': newRole})
          .eq('id', userId);
          
      AppNotifications.show(
        context: context,
        message: 'User role updated to ${newRole.toUpperCase()}',
        icon: CupertinoIcons.check_mark_circled_solid,
        iconColor: AppColors.accentGreen,
      );
      _fetchUsers(); // Refresh list
    } catch (e) {
      AppNotifications.show(
        context: context,
        message: 'Failed to update role',
        icon: CupertinoIcons.exclamationmark_triangle_fill,
        iconColor: AppColors.accentRed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Manage Staff',
          style: TextStyle(fontFamily: 'GoogleSansFlex', color: textColor, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentBlue))
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                final role = user['role'] as String;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _getRoleColor(role).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(CupertinoIcons.person_fill, color: _getRoleColor(role)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['name'] ?? 'Unknown User',
                                style: TextStyle(fontFamily: 'GoogleSansFlex', color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                user['phone'] ?? 'No phone provided',
                                style: TextStyle(fontFamily: 'GoogleSansFlex', color: textColor.withOpacity(0.5), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        // Role Dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: role,
                              dropdownColor: isDark ? AppColors.bgElevated : Colors.white,
                              style: TextStyle(fontFamily: 'GoogleSansFlex', color: textColor, fontSize: 14, fontWeight: FontWeight.w500),
                              items: const [
                                DropdownMenuItem(value: 'public', child: Text('Public')),
                                DropdownMenuItem(value: 'marker', child: Text('Marker')),
                                DropdownMenuItem(value: 'electrician', child: Text('Electrician')),
                                DropdownMenuItem(value: 'council', child: Text('Council')),
                              ],
                              onChanged: (newRole) {
                                if (newRole != null && newRole != role) {
                                  _updateRole(user['id'], newRole);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'council': return AppColors.accentGreen;
      case 'electrician': return AppColors.accentAmber;
      case 'marker': return AppColors.accentBlue;
      default: return Colors.grey;
    }
  }
}