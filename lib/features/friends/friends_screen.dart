import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/friend_model.dart';
import '../../core/providers/friend_provider.dart';
import '../../core/widgets/inputs/app_text_field.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/widgets/scanner/qr_scanner_modal.dart';
import 'widgets/friend_list_item.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _findSearchCtrl = TextEditingController();
  final TextEditingController _localFilterCtrl = TextEditingController();
  String _searchQuery = '';
  String _localFilterQuery = '';
  bool _showOnlineOnly = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _findSearchCtrl.dispose();
    _localFilterCtrl.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = query.trim();
        });
      }
    });
  }

  void _refreshAll() {
    ref.invalidate(friendsProvider);
    ref.invalidate(incomingRequestsProvider);
    ref.invalidate(outgoingRequestsProvider);
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
                  width: 40,
                  height: 4,
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
                'Share your personal QR or ID to connect with travel buddies',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // QR Code Card
              if (userId.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.1),
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
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),

              const SizedBox(height: 18),

              // User name
              Text(
                displayName,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 18,
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

              const SizedBox(height: 24),

              // Share button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    SharePlus.instance.share(
                      ShareParams(
                        text:
                            'Add me on Tara Travel! Use my friend code:\n$userId\n\nDownload Tara Travel to connect and plan trips together! 🌴',
                        subject: 'Add me on Tara Travel',
                      ),
                    );
                  },
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text(
                    'Share Profile Code',
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

  // ── Scan Friend QR Code ──────────────────────────────────────────────────
  Future<void> _scanFriendQr() async {
    final scanned = await QrScannerModal.show(
      context,
      title: 'Scan Friend QR',
      instruction: 'Point camera at your friend’s QR code',
    );
    if (scanned != null && scanned.isNotEmpty) {
      String cleanedId = scanned.trim();
      if (cleanedId.contains('taratravel://user/')) {
        cleanedId = cleanedId.replaceAll('taratravel://user/', '').trim();
      }
      if (mounted) {
        _showAddByCodeDialog(initialQuery: cleanedId);
      }
    }
  }

  // ── Add by Code / Username Dialog with Live User Preview ─────────────────────
  void _showAddByCodeDialog({String? initialQuery}) {
    final ctrl = TextEditingController(text: initialQuery);
    bool isSearching = initialQuery != null && initialQuery.isNotEmpty;
    bool isSending = false;
    FriendModel? resolvedUser;
    String? lookupError;
    Timer? dialogDebounce;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          void doLookup(String query) async {
            try {
              final repo = ref.read(friendRepositoryProvider);
              final found = await repo.lookupUser(query);
              if (context.mounted) {
                setDialogState(() {
                  isSearching = false;
                  resolvedUser = found;
                  lookupError = found == null ? 'No user found' : null;
                });
              }
            } catch (_) {
              if (context.mounted) {
                setDialogState(() {
                  isSearching = false;
                  resolvedUser = null;
                  lookupError = 'User not found';
                });
              }
            }
          }

          if (initialQuery != null && initialQuery.isNotEmpty && resolvedUser == null && lookupError == null && isSearching) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              doLookup(initialQuery);
            });
          }

          void onInputChanged(String text) {
            dialogDebounce?.cancel();
            final query = text.trim();
            if (query.isEmpty) {
              setDialogState(() {
                resolvedUser = null;
                lookupError = null;
                isSearching = false;
              });
              return;
            }

            setDialogState(() => isSearching = true);
            dialogDebounce = Timer(const Duration(milliseconds: 350), () async {
              doLookup(query);
            });
          }

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.person_add_rounded, color: AppColors.primary, size: 22),
                SizedBox(width: 8),
                Text(
                  'Add Friend',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter a friend\'s User ID, display name, or email:',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: ctrl,
                    autofocus: initialQuery == null || initialQuery.isEmpty,
                    onChanged: onInputChanged,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. Maria Clara or User ID',
                      hintStyle: const TextStyle(fontFamily: 'DM Sans', color: AppColors.muted),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                      suffixIcon: ctrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16, color: AppColors.textSecondary),
                              onPressed: () {
                                ctrl.clear();
                                onInputChanged('');
                              },
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 20, color: AppColors.primary),
                                  tooltip: 'Scan Friend QR',
                                  onPressed: () {
                                    dialogDebounce?.cancel();
                                    Navigator.pop(ctx);
                                    _scanFriendQr();
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.paste_rounded, size: 18, color: AppColors.textSecondary),
                                  tooltip: 'Paste from clipboard',
                                  onPressed: () async {
                                    final data = await Clipboard.getData('text/plain');
                                    if (data?.text != null && data!.text!.isNotEmpty) {
                                      ctrl.text = data.text!.trim();
                                      onInputChanged(ctrl.text);
                                    }
                                  },
                                ),
                              ],
                            ),
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Live Preview Card
                  if (isSearching)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                      ),
                    )
                  else if (resolvedUser != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: resolvedUser!.color,
                            backgroundImage: resolvedUser!.profilePhotoUrl != null
                                ? NetworkImage(resolvedUser!.profilePhotoUrl!)
                                : null,
                            child: resolvedUser!.profilePhotoUrl == null
                                ? Text(
                                    resolvedUser!.initials,
                                    style: const TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  resolvedUser!.name,
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (resolvedUser!.email != null)
                                  Text(
                                    resolvedUser!.email!,
                                    style: const TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (resolvedUser!.status == FriendStatus.accepted)
                            const Text('Friends ✓',
                                style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.green))
                          else if (resolvedUser!.status == FriendStatus.pending)
                            const Text('Pending',
                                style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.amber)),
                        ],
                      ),
                    )
                  else if (lookupError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        lookupError!,
                        style: const TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: AppColors.muted),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  dialogDebounce?.cancel();
                  Navigator.pop(ctx);
                },
                child: const Text('Cancel',
                    style: TextStyle(fontFamily: 'DM Sans', color: AppColors.textSecondary)),
              ),
              if (isSending)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                )
              else
                ElevatedButton(
                  onPressed: (ctrl.text.trim().isEmpty ||
                          (resolvedUser != null && resolvedUser!.status == FriendStatus.accepted))
                      ? null
                      : () async {
                          dialogDebounce?.cancel();
                          setDialogState(() => isSending = true);
                          try {
                            final repo = ref.read(friendRepositoryProvider);
                            String targetName;
                            if (resolvedUser != null) {
                              await repo.sendRequest(resolvedUser!.id);
                              targetName = resolvedUser!.name;
                            } else {
                              targetName = await repo.addFriendByCode(ctrl.text);
                            }

                            _refreshAll();
                            if (context.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Friend request sent to $targetName! 🎉',
                                      style: const TextStyle(fontFamily: 'DM Sans')),
                                  backgroundColor: AppColors.green,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSending = false);
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
                  child: const Text('Send Request',
                      style: TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.w600)),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Subscribe to live Realtime presence pings
    ref.watch(friendsRealtimePresenceProvider);

    final incomingRequests = ref.watch(incomingRequestsProvider);
    final requestCount = incomingRequests.value?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
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
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 16, color: AppColors.deepEarth),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Friends',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  // Header Action Buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _headerIconBtn(
                        icon: Icons.qr_code_scanner_rounded,
                        tooltip: 'Scan Friend QR',
                        onTap: _scanFriendQr,
                      ),
                      const SizedBox(width: 8),
                      _headerIconBtn(
                        icon: Icons.qr_code_rounded,
                        tooltip: 'My QR Code',
                        onTap: _showMyQrCodeModal,
                      ),
                      const SizedBox(width: 8),
                      _headerIconBtn(
                        icon: Icons.person_add_rounded,
                        tooltip: 'Add Friend',
                        onTap: () => _showAddByCodeDialog(),
                        isPrimary: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Segmented Tab Bar ─────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE8E3),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(3),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                tabs: [
                  const Tab(text: 'My Friends'),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Requests'),
                        if (requestCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$requestCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Tab(text: 'Find Friends'),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ── Tab Views ─────────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: My Friends
                  _buildMyFriendsTab(),

                  // Tab 2: Requests (Incoming + Sent)
                  _buildRequestsTab(),

                  // Tab 3: Find Friends (Search + Discovery)
                  _buildFindFriendsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── TAB 1: MY FRIENDS ────────────────────────────────────────────────────────
  Widget _buildMyFriendsTab() {
    final friendsAsync = ref.watch(friendsProvider);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => _refreshAll(),
      child: friendsAsync.when(
        data: (friends) {
          if (friends.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.group_rounded, size: 48, color: AppColors.primary),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'No Friends Yet',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Connect with friends to plan trips together, share itineraries, and split travel expenses effortlessly.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _tabController.animateTo(2),
                          icon: const Icon(Icons.person_search_rounded, size: 16),
                          label: const Text('Find Friends',
                              style: TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _showMyQrCodeModal,
                          icon: const Icon(Icons.qr_code_rounded, size: 16),
                          label: const Text('My QR',
                              style: TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.deepEarth,
                            side: const BorderSide(color: AppColors.cardBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          final onlineCount = friends.where((f) => f.isCurrentlyOnline).length;

          // Filter friends locally by name/email + online filter
          final filteredFriends = friends.where((f) {
            if (_showOnlineOnly && !f.isCurrentlyOnline) return false;
            if (_localFilterQuery.isNotEmpty) {
              final query = _localFilterQuery.toLowerCase();
              final matchesName = f.name.toLowerCase().contains(query);
              final matchesEmail = f.email != null && f.email!.toLowerCase().contains(query);
              if (!matchesName && !matchesEmail) return false;
            }
            return true;
          }).toList();

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, 4, 20, 24 + MediaQuery.of(context).padding.bottom),
            children: [
              // Online Summary Banner with Interactive Filter Chips
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder, width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // All Friends Chip
                    GestureDetector(
                      onTap: () => setState(() => _showOnlineOnly = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: !_showOnlineOnly ? AppColors.primary : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'All (${friends.length})',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: !_showOnlineOnly ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Online Friends Chip
                    GestureDetector(
                      onTap: () => setState(() => _showOnlineOnly = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _showOnlineOnly
                              ? AppColors.green
                              : AppColors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: _showOnlineOnly ? Colors.white : AppColors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Online ($onlineCount)',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _showOnlineOnly ? Colors.white : AppColors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Presence indicator text
                    Text(
                      onlineCount > 0 ? '$onlineCount active' : 'All offline',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: onlineCount > 0 ? AppColors.green : AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Search inside friends list if > 4 friends
              if (friends.length > 4) ...[
                TextField(
                  controller: _localFilterCtrl,
                  onChanged: (val) => setState(() => _localFilterQuery = val.trim()),
                  style: const TextStyle(fontFamily: 'DM Sans', fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Filter your friends...',
                    hintStyle: const TextStyle(fontFamily: 'DM Sans', color: AppColors.muted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
                    suffixIcon: _localFilterQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 14, color: AppColors.textSecondary),
                            onPressed: () {
                              _localFilterCtrl.clear();
                              setState(() => _localFilterQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder, width: 0.6),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder, width: 0.6),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (filteredFriends.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          _showOnlineOnly ? Icons.wifi_off_rounded : Icons.search_off_rounded,
                          size: 36,
                          color: AppColors.muted,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _showOnlineOnly
                              ? 'No friends currently online.'
                              : 'No friends match your filter.',
                          style: const TextStyle(fontFamily: 'DM Sans', fontSize: 14, color: AppColors.textSecondary),
                        ),
                        if (_showOnlineOnly) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => setState(() => _showOnlineOnly = false),
                            child: const Text('Show all friends',
                                style: TextStyle(fontFamily: 'DM Sans', color: AppColors.primary)),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              else
                ...filteredFriends.map((f) => FriendListItem(friend: f)),
            ],
          );
        },
        loading: () => const FriendsListSkeleton(count: 5),
        error: (e, _) => Center(
          child: Text('Error loading friends: $e',
              style: const TextStyle(fontFamily: 'DM Sans', color: AppColors.red)),
        ),
      ),
    );
  }

  // ── TAB 2: REQUESTS (INCOMING + SENT) ────────────────────────────────────────
  Widget _buildRequestsTab() {
    final incomingAsync = ref.watch(incomingRequestsProvider);
    final outgoingAsync = ref.watch(outgoingRequestsProvider);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => _refreshAll(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + MediaQuery.of(context).padding.bottom),
        children: [
          // Section 1: Incoming Requests
          Row(
            children: [
              const Icon(Icons.mark_email_unread_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Incoming Requests',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              incomingAsync.when(
                data: (list) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: list.isNotEmpty
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${list.length}',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: list.isNotEmpty ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 10),

          incomingAsync.when(
            data: (incoming) {
              if (incoming.isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder, width: 0.7),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                            size: 32, color: AppColors.green),
                        SizedBox(height: 8),
                        Text(
                          'No incoming requests',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'When someone adds you, their request will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: incoming
                    .map((friend) => FriendListItem(
                          friend: friend,
                          isIncomingRequest: true,
                        ))
                    .toList(),
              );
            },
            loading: () => const FriendsListSkeleton(count: 2),
            error: (e, _) => Text('Error: $e',
                style: const TextStyle(fontFamily: 'DM Sans', color: AppColors.red)),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 16),

          // Section 2: Outgoing Sent Requests
          Row(
            children: [
              const Icon(Icons.outbox_rounded, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              const Text(
                'Sent Requests',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              outgoingAsync.when(
                data: (list) => Text(
                  '${list.length} pending',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 10),

          outgoingAsync.when(
            data: (outgoing) {
              if (outgoing.isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder, width: 0.7),
                  ),
                  child: const Center(
                    child: Text(
                      'No pending sent requests',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: outgoing
                    .map((friend) => FriendListItem(
                          friend: friend,
                          isOutgoingRequest: true,
                        ))
                    .toList(),
              );
            },
            loading: () => const FriendsListSkeleton(count: 2),
            error: (e, _) => Text('Error: $e',
                style: const TextStyle(fontFamily: 'DM Sans', color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  // ── TAB 3: FIND FRIENDS ─────────────────────────────────────────────────────
  Widget _buildFindFriendsTab() {
    return ListView(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + MediaQuery.of(context).padding.bottom),
      children: [
        // Quick Action Tiles
        Row(
          children: [
            Expanded(
              child: _quickActionCard(
                icon: Icons.qr_code_scanner_rounded,
                label: 'Scan QR',
                subtitle: 'Camera scan',
                color: AppColors.primary,
                onTap: _scanFriendQr,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _quickActionCard(
                icon: Icons.qr_code_rounded,
                label: 'My QR',
                subtitle: 'Show & share',
                color: AppColors.deepEarth,
                onTap: _showMyQrCodeModal,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _quickActionCard(
                icon: Icons.badge_rounded,
                label: 'Add by ID',
                subtitle: 'Code / username',
                color: AppColors.blue,
                onTap: () => _showAddByCodeDialog(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Live Search Bar
        AppTextField(
          label: '',
          hint: 'Search travelers by name or email...',
          controller: _findSearchCtrl,
          prefixIcon: Icons.search_rounded,
          onChanged: _onSearchChanged,
        ),
        const SizedBox(height: 16),

        // Search Results / Discovery
        if (_searchQuery.isNotEmpty)
          _buildSearchResults()
        else ...[
          // Discovery Help Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.cardBorder, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.explore_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Find Your Travel Buddies',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  '• Type a friend\'s display name or email in the search bar above\n'
                  '• Tap "Add by ID" to paste a friend\'s unique user code\n'
                  '• Share your personal QR code so others can add you instantly',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _showMyQrCodeModal,
                    icon: const Icon(Icons.share_rounded, size: 16),
                    label: const Text('Share My Profile Link',
                        style: TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchResults() {
    final searchAsync = ref.watch(searchUsersProvider(_searchQuery));

    return searchAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.person_search_rounded, size: 40, color: AppColors.muted),
                  SizedBox(height: 12),
                  Text(
                    'No travelers found.',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Try searching with a different name or email.',
                    style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10, left: 4),
              child: Text(
                'Found ${users.length} ${users.length == 1 ? 'user' : 'users'}',
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ...users.map(
              (u) => FriendListItem(
                friend: u,
                isSearchMode: true,
              ),
            ),
          ],
        );
      },
      loading: () => const FriendsListSkeleton(count: 4),
      error: (e, _) => Center(
        child: Text('Error: $e',
            style: const TextStyle(fontFamily: 'DM Sans', color: AppColors.red)),
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

  Widget _quickActionCard({
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
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
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
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
