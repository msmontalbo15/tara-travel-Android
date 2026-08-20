import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/profile_provider.dart';
import 'package:intl/intl.dart';
import 'models/notification_model.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  late List<NotificationItem> _notifications;
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Unread',
    'Expenses',
    'Messages',
    'Alerts',
  ];

  @override
  void initState() {
    super.initState();
    _notifications = const [];
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final rows = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _notifications = (rows as List)
            .map((r) => NotificationItem.fromDb((r as Map).cast<String, dynamic>()))
            .toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _notifications = const []);
    }
  }

  Future<void> _markAsRead(int index) async {
    final item = _notifications[index];
    setState(() {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    });
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'read': true}).eq('id', item.id);
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      _notifications =
          _notifications.map((n) => n.copyWith(isRead: true)).toList();
    });
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('notifications')
            .update({'read': true})
            .eq('user_id', user.id)
            .eq('read', false);
      }
    } catch (_) {}
  }

  List<NotificationItem> get _filteredNotifications {
    if (_selectedFilter == 'All') return _notifications;
    if (_selectedFilter == 'Unread') {
      return _notifications.where((n) => !n.isRead).toList();
    }
    if (_selectedFilter == 'Expenses') {
      return _notifications
          .where((n) =>
              n.category == NotificationCategory.expense ||
              n.category == NotificationCategory.payment)
          .toList();
    }
    if (_selectedFilter == 'Messages') {
      return _notifications
          .where((n) => n.category == NotificationCategory.message)
          .toList();
    }
    if (_selectedFilter == 'Alerts') {
      return _notifications
          .where((n) =>
              n.category == NotificationCategory.proximity ||
              n.category == NotificationCategory.weather)
          .toList();
    }
    return _notifications;
  }

  IconData _getIconForCategory(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.expense:
      case NotificationCategory.payment:
        return Icons.attach_money_rounded;
      case NotificationCategory.message:
        return Icons.chat_bubble_outline_rounded;
      case NotificationCategory.proximity:
        return Icons.location_on_outlined;
      case NotificationCategory.weather:
        return Icons.wb_sunny_outlined;
      case NotificationCategory.packing:
        return Icons.backpack_rounded;
    }
  }

  Color _getColorForCategory(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.expense:
      case NotificationCategory.payment:
        return AppColors.greenBright;
      case NotificationCategory.message:
        return AppColors.primary;
      case NotificationCategory.proximity:
        return AppColors.blue;
      case NotificationCategory.weather:
        return AppColors.amber;
      case NotificationCategory.packing:
        return AppColors.primary;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }
    return DateFormat('MMM d').format(time);
  }

  Widget _buildProfileSetupCard(BuildContext context, List<String> missingTasks) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/profile'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.assignment_ind_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Text(
                          'Complete your profile setup',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Action Required',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add your ${missingTasks.join(' and ')} to easily settle group expenses and unlock all features.',
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Text(
                        'Complete setup now',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 13, color: AppColors.primary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final missingTasks = <String>[];
    if (profile.homeCity.isEmpty) missingTasks.add('home location');
    if (profile.gcashNumber == null || profile.gcashNumber!.isEmpty) {
      missingTasks.add('GCash number');
    }
    final showProfilePrompt = missingTasks.isNotEmpty &&
        (_selectedFilter == 'All' || _selectedFilter == 'Unread' || _selectedFilter == 'Alerts');

    final displayedList = _filteredNotifications;
    final unreadCount = _notifications.where((n) => !n.isRead).length + (missingTasks.isNotEmpty ? 1 : 0);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilter = filter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.cardBorder,
                          width: isSelected ? 1.5 : 0.5,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))]
                            : null,
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          Expanded(
            child: (displayedList.isEmpty && !showProfilePrompt)
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🔔', style: TextStyle(fontSize: 40)),
                        SizedBox(height: 12),
                        Text(
                          'No notifications found.',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 15,
                            color: AppColors.warmMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.only(
                        left: 20, right: 20, top: 8, bottom: 30 + MediaQuery.of(context).padding.bottom),
                    itemCount: (showProfilePrompt ? 1 : 0) + displayedList.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (showProfilePrompt && index == 0) {
                        return _buildProfileSetupCard(context, missingTasks);
                      }

                      final itemIndex = showProfilePrompt ? index - 1 : index;
                      final item = displayedList[itemIndex];
                      final originalIndex =
                          _notifications.indexWhere((n) => n.id == item.id);

                      return GestureDetector(
                        onTap: () {
                          if (!item.isRead && originalIndex != -1) {
                            _markAsRead(originalIndex);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: item.isRead
                                ? Colors.white
                                : AppColors.sand.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: item.isRead
                                  ? AppColors.cardBorder
                                  : AppColors.primary.withValues(alpha: 0.2),
                              width: 0.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _getColorForCategory(item.category)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getIconForCategory(item.category),
                                  color: _getColorForCategory(item.category),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            item.title,
                                            style: const TextStyle(
                                              fontFamily: 'DM Sans',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _formatTime(item.timestamp),
                                          style: const TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.warmMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.message,
                                      style: TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 13,
                                        fontWeight: item.isRead
                                            ? FontWeight.w400
                                            : FontWeight.w500,
                                        color: item.isRead
                                            ? AppColors.textSecondary
                                            : AppColors.textPrimary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!item.isRead) ...[
                                const SizedBox(width: 10),
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
