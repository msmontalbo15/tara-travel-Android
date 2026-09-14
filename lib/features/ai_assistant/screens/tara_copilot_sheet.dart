import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/trip_model.dart';
import '../../../core/models/itinerary_model.dart';
import '../../../core/providers/itinerary_provider.dart';
import '../../../core/providers/expense_provider.dart';
import '../../../core/providers/packing_provider.dart';
import '../../../core/providers/trip_weather_provider.dart';
import '../../../core/services/gemini_ai_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/feedback/app_feedback.dart';

/// TaraCopilotSheet
/// ─────────────────────────────────────────────────────────────────────────────
/// Conversational AI Travel Assistant Sheet (Plan 16):
/// • Contextually grounded with the active trip's schedule, budget, and weather.
/// • Instant prompt chips for common traveler questions.
/// • Actionable executable tool chips inside answers ([➕ Add Stop], [🎒 Pack]).
/// • Smooth typing / stream display with rich markdown formatting.
/// ─────────────────────────────────────────────────────────────────────────────
class TaraCopilotSheet extends ConsumerStatefulWidget {
  final TripModel trip;

  const TaraCopilotSheet({
    super.key,
    required this.trip,
  });

  static Future<void> show(BuildContext context, TripModel trip) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => TaraCopilotSheet(trip: trip),
    );
  }

  @override
  ConsumerState<TaraCopilotSheet> createState() => _TaraCopilotSheetState();
}

class _ChatMessageItem {
  final bool isUser;
  final String text;
  final List<CopilotActionChip> chips;

  const _ChatMessageItem({
    required this.isUser,
    required this.text,
    this.chips = const [],
  });
}

class _TaraCopilotSheetState extends ConsumerState<TaraCopilotSheet> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessageItem> _messages = [];
  bool _isLoading = false;

  final List<String> _quickSuggestions = [
    '🌦️ Rain contingency plan?',
    '🍽️ Best dinner spots nearby?',
    '🎒 What did we forget to pack?',
    '💸 How much budget left per person?',
  ];

  @override
  void initState() {
    super.initState();
    // Seed initial greeting
    _messages.add(
      _ChatMessageItem(
        isUser: false,
        text: 'Kumusta! I am your **Tara Copilot**. How can I help you and your squad in **${widget.trip.destination}** today?',
        chips: const [],
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSend(String query) async {
    final clean = query.trim();
    if (clean.isEmpty || _isLoading) return;

    _inputController.clear();
    setState(() {
      _messages.add(_ChatMessageItem(isUser: true, text: clean));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final stops = ref.read(itineraryStopsProvider(widget.trip.id)).value ?? [];
      final expenses = ref.read(expenseProvider(widget.trip.id)).asData?.value ?? [];
      final packingSub = ref.read(packingProvider(widget.trip.id));
      final packingState = ref.read(packingSub);
      final packingItems = packingState.categories.expand((c) => c.items).toList();
      final weather = ref.read(tripCurrentWeatherProvider(widget.trip.id)).value;

      String? weatherSummary;
      if (weather != null) {
        weatherSummary = '${weather.condition}, ${weather.temperature.round()}°C';
      }

      final response = await GeminiAiService.instance.askCopilot(
        query: clean,
        trip: widget.trip,
        stops: stops,
        expenses: expenses,
        packingItems: packingItems,
        weatherSummary: weatherSummary,
      );

      if (mounted) {
        setState(() {
          _messages.add(
            _ChatMessageItem(
              isUser: false,
              text: response.markdownText,
              chips: response.actionChips,
            ),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            _ChatMessageItem(
              isUser: false,
              text: 'Sorry, I ran into an issue connecting to Tara Copilot: $e',
            ),
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _executeActionChip(CopilotActionChip chip) async {
    switch (chip.type) {
      case CopilotActionType.addStop:
        try {
          final subProvider = ref.read(itineraryProvider(widget.trip.id));
          final itineraryState = ref.read(subProvider).asData?.value;
          final title = chip.data['title']?.toString() ?? 'New Stop';
          final location = chip.data['location']?.toString() ?? widget.trip.destination;
          final cost = (chip.data['cost'] as num?)?.toDouble();

          final newStop = ItineraryStop(
            id: const Uuid().v4(),
            title: title,
            type: StopType.activity,
            location: location,
            estimatedCost: cost,
          );

          final targetDay = itineraryState?.activeDay ?? 1;
          await ref.read(subProvider.notifier).addStop(targetDay, newStop);

          if (mounted) {
            AppFeedback.showSuccess(
              context,
              'Added "$title" to Day $targetDay itinerary!',
              title: 'Stop Added 📍',
            );
          }
        } catch (e) {
          if (mounted) AppFeedback.showError(context, 'Failed to add stop: $e');
        }
        break;

      case CopilotActionType.addPackingItem:
        try {
          final itemName = chip.data['name']?.toString() ?? 'Essential Item';
          final category = chip.data['category']?.toString() ?? 'General';
          final packingSub = ref.read(packingProvider(widget.trip.id));
          final packingNotifier = ref.read(packingSub.notifier);
          await packingNotifier.addItem(itemName, subCategory: category);

          if (mounted) {
            AppFeedback.showSuccess(
              context,
              'Added "$itemName" to packing list!',
              title: 'Item Added 🎒',
            );
          }
        } catch (e) {
          if (mounted) AppFeedback.showError(context, 'Failed to add packing item: $e');
        }
        break;

      case CopilotActionType.logExpense:
        Navigator.pushNamed(context, '/budget');
        break;

      case CopilotActionType.infoOnly:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Handle pill
            const SizedBox(height: 12),
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

            // Header with Gradient badge
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD85A30), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tara Copilot',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.deepEarth,
                          ),
                        ),
                        Text(
                          'AI Trip Guide · ${widget.trip.destination}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.dividerLight),

            // Conversation Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, i) {
                  final msg = _messages[i];
                  return _buildMessageRow(msg);
                },
              ),
            ),

            // Suggestions Carousel
            if (!_isLoading && _messages.length <= 2)
              Container(
                height: 38,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _quickSuggestions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final sug = _quickSuggestions[i];
                    return ActionChip(
                      label: Text(sug, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      backgroundColor: const Color(0xFFFBF4ED),
                      side: const BorderSide(color: Color(0xFFF3DCD3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onPressed: () => _handleSend(sug),
                    );
                  },
                ),
              ),

            // Loading indicator
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                    SizedBox(width: 8),
                    Text('Tara is thinking...', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                  ],
                ),
              ),

            // Input Bar
            Padding(
              padding: EdgeInsets.fromLTRB(16, 6, 16, bottomInset > 0 ? bottomInset + 8 : 14),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _inputController,
                        style: const TextStyle(fontSize: 14),
                        textInputAction: TextInputAction.send,
                        onSubmitted: _handleSend,
                        decoration: const InputDecoration(
                          hintText: 'Ask about local spots, weather, packing...',
                          hintStyle: TextStyle(fontSize: 13, color: AppColors.muted),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _handleSend(_inputController.text),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFD85A30), Color(0xFFEF9F27)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageRow(_ChatMessageItem msg) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10, left: 40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16).copyWith(bottomRight: Radius.zero),
          ),
          child: Text(
            msg.text,
            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F7F5),
                borderRadius: BorderRadius.circular(16).copyWith(topLeft: Radius.zero),
                border: Border.all(color: const Color(0xFFECE7E1)),
              ),
              child: Text(
                msg.text,
                style: const TextStyle(
                  color: AppColors.deepEarth,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
            if (msg.chips.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: msg.chips.map((chip) {
                  return ActionChip(
                    avatar: const Icon(Icons.bolt_rounded, size: 14, color: AppColors.primary),
                    label: Text(chip.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.deepEarth)),
                    backgroundColor: const Color(0xFFFFF4ED),
                    side: const BorderSide(color: Color(0xFFF8D7C8)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onPressed: () => _executeActionChip(chip),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
