import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/friend_provider.dart';
import '../../core/widgets/inputs/app_text_field.dart';
import '../../core/widgets/shimmer_loading.dart';
import 'widgets/friend_list_item.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── My QR Code Modal ───────────────────────────────────────────────────────
  void _showMyQrCodeModal() async {
    final repo = ref.read(friendRepositoryProvider);
    final profile = await repo.getCurrentUserProfile();
    final userId = profile?['id'] as String? ?? '';
    final displayName = profile?['display_name'] as String? ?? 'Me';

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        top: false,
        child: Container(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + MediaQuery.of(ctx).padding.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'My Friend Code',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Share this QR or code to let others add you',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // QR Code
            if (userId.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: QrImageView(
                  data: userId,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: AppColors.deepEarth,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: AppColors.deepEarth,
                  ),
                ),
              )
            else
              const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),

            const SizedBox(height: 20),

            // User name
            Text(
              displayName,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),

            if (userId.isNotEmpty) ...[
              const SizedBox(height: 8),
              // Copy ID chip
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: userId));
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Friend ID copied!', style: TextStyle(fontFamily: 'DM Sans')),
                      backgroundColor: AppColors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.copy_rounded, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        '${userId.substring(0, 8)}…',
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 28),

            // Share button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  SharePlus.instance.share(
                    ShareParams(
                      text: 'Add me on Tara Travel! Use my friend code:\n$userId\n\nDownload Tara Travel to connect and plan trips together! 🌴',
                      subject: 'Add me on Tara Travel',
                    ),
                  );
                },
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text(
                  'Share Profile Link',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  // ── Add by Code Dialog ─────────────────────────────────────────────────────
  void _showAddByCodeDialog() {
    final ctrl = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Add Friend by Code',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter a friend\'s unique ID or display name to send them a request.',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: true,
                style: const TextStyle(fontFamily: 'DM Sans', fontSize: 15, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Friend ID or username',
                  hintStyle: const TextStyle(fontFamily: 'DM Sans', color: AppColors.muted),
                  prefixIcon: const Icon(Icons.person_search_rounded, color: AppColors.textSecondary, size: 20),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(fontFamily: 'DM Sans', color: AppColors.textSecondary)),
            ),
            if (isLoading)
              const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              )
            else
              ElevatedButton(
                onPressed: () async {
                  if (ctrl.text.trim().isEmpty) return;
                  setDialogState(() => isLoading = true);
                  try {
                    final repo = ref.read(friendRepositoryProvider);
                    final name = await repo.addFriendByCode(ctrl.text);
                    ref.invalidate(friendsProvider);
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Friend request sent to $name! 🎉', style: const TextStyle(fontFamily: 'DM Sans')),
                          backgroundColor: AppColors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    setDialogState(() => isLoading = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$e', style: const TextStyle(fontFamily: 'DM Sans')),
                          backgroundColor: AppColors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Send Request', style: TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.deepEarth),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Friends',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  // Action buttons on the right
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _headerIconBtn(
                        icon: Icons.qr_code_rounded,
                        tooltip: 'My QR Code',
                        onTap: _showMyQrCodeModal,
                      ),
                      const SizedBox(width: 8),
                      _headerIconBtn(
                        icon: Icons.person_add_rounded,
                        tooltip: 'Add by Code',
                        onTap: _showAddByCodeDialog,
                        isPrimary: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Quick Actions ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _actionCard(
                      icon: Icons.qr_code_scanner_rounded,
                      label: 'My QR Code',
                      subtitle: 'Show & share your code',
                      color: AppColors.primary,
                      onTap: _showMyQrCodeModal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _actionCard(
                      icon: Icons.badge_rounded,
                      label: 'Add by ID',
                      subtitle: 'Enter friend code or name',
                      color: AppColors.blue,
                      onTap: _showAddByCodeDialog,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Search Bar ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AppTextField(
                label: '',
                hint: 'Search friends by name or email',
                controller: _searchCtrl,
                prefixIcon: Icons.search,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            // ── Content ──────────────────────────────────────────────────────
            Expanded(
              child: _searchQuery.isNotEmpty ? _buildSearchResults() : _buildFriendsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerIconBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isPrimary ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isPrimary ? AppColors.primary : AppColors.cardBorder),
          ),
          child: Icon(icon, size: 18, color: isPrimary ? Colors.white : AppColors.deepEarth),
        ),
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder, width: 0.7),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Text(subtitle, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 10, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final searchAsync = ref.watch(searchUsersProvider(_searchQuery));
    return searchAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return const Center(
            child: Text('No users found.', style: TextStyle(fontFamily: 'DM Sans', color: AppColors.textSecondary)),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + MediaQuery.of(context).padding.bottom),
          itemCount: users.length,
          itemBuilder: (context, index) {
            return FriendListItem(
              friend: users[index],
              isSearchMode: true,
            );
          },
        );
      },
      loading: () => const FriendsListSkeleton(count: 4),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(fontFamily: 'DM Sans', color: AppColors.red))),
    );
  }

  Widget _buildFriendsList() {
    final friendsAsync = ref.watch(friendsProvider);
    return friendsAsync.when(
      data: (friends) {
        if (friends.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.group_rounded, size: 44, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Friends Yet',
                  style: TextStyle(fontFamily: 'DM Sans', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Search for friends by name or email, share your QR code, or enter a friend\'s ID to connect.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _showMyQrCodeModal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code_rounded, size: 16, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Show My QR Code', style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + MediaQuery.of(context).padding.bottom),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            return FriendListItem(
              friend: friends[index],
              isSearchMode: false,
            );
          },
        );
      },
      loading: () => const FriendsListSkeleton(count: 4),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(fontFamily: 'DM Sans', color: AppColors.red))),
    );
  }
}
