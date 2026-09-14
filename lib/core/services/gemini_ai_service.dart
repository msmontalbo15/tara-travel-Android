import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trip_model.dart';
import '../models/itinerary_model.dart';
import '../models/expense_model.dart';
import '../models/packing_model.dart';

enum CopilotActionType {
  addStop,
  addPackingItem,
  logExpense,
  infoOnly,
}

class CopilotActionChip {
  final CopilotActionType type;
  final String label;
  final Map<String, dynamic> data;

  const CopilotActionChip({
    required this.type,
    required this.label,
    required this.data,
  });
}

class CopilotResponse {
  final String markdownText;
  final List<CopilotActionChip> actionChips;

  const CopilotResponse({
    required this.markdownText,
    this.actionChips = const [],
  });
}

/// Service providing conversational travel assistance with dual-path execution (Edge Function / direct Gemini API)
/// and tool-call action chip synthesis.
class GeminiAiService {
  GeminiAiService._();
  static final GeminiAiService instance = GeminiAiService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Generates context-aware response for the trip.
  Future<CopilotResponse> askCopilot({
    required String query,
    required TripModel trip,
    List<ItineraryStop> stops = const [],
    List<ExpenseModel> expenses = const [],
    List<PackingItem> packingItems = const [],
    String? weatherSummary,
  }) async {
    final systemPrompt = _buildSystemPrompt(
      trip: trip,
      stops: stops,
      expenses: expenses,
      packingItems: packingItems,
      weatherSummary: weatherSummary,
    );

    // Path 1: Supabase Edge Function (Primary, secure)
    try {
      final edgeRes = await _supabase.functions.invoke(
        'tara-copilot',
        body: {
          'prompt': query,
          'system_instruction': systemPrompt,
          'trip_id': trip.id,
        },
      );
      if (edgeRes.status == 200 && edgeRes.data != null) {
        final text = edgeRes.data['reply']?.toString() ?? edgeRes.data['text']?.toString() ?? '';
        if (text.isNotEmpty) {
          return _parseResponse(text, trip);
        }
      }
    } catch (edgeErr) {
      debugPrint('[GeminiAiService] Edge function path note: $edgeErr');
    }

    // Path 2: Direct Google Gemini REST API fallback via API key
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isNotEmpty) {
      try {
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
        );
        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': '$systemPrompt\n\nUser Question: $query'}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.7,
              'maxOutputTokens': 800,
            }
          }),
        );

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          final candidate = body['candidates']?[0]?['content']?['parts']?[0]?['text'];
          if (candidate != null && candidate.toString().isNotEmpty) {
            return _parseResponse(candidate.toString(), trip);
          }
        }
      } catch (geminiErr) {
        debugPrint('[GeminiAiService] Gemini REST API fallback note: $geminiErr');
      }
    }

    // Path 3: Smart Local Offline Heuristic Fallback
    return _generateLocalHeuristicResponse(query, trip, stops);
  }

  String _buildSystemPrompt({
    required TripModel trip,
    required List<ItineraryStop> stops,
    required List<ExpenseModel> expenses,
    required List<PackingItem> packingItems,
    String? weatherSummary,
  }) {
    final totalSpent = expenses.fold<double>(0, (s, e) => s + e.amount);
    final remainingBudget = trip.totalBudget - totalSpent;
    final stopNames = stops.take(5).map((s) => s.title).join(', ');

    return '''
You are Tara Copilot, an elite AI travel assistant specialized in Philippine travel.
You provide friendly, local, culturally-attuned, practical advice (jeepneys, tricycles, roll-on/roll-off ferries, pasalubong, local delicacies, tollways).

Active Trip:
- Destination: ${trip.destination} (${trip.name})
- Dates: ${trip.fromDate.toString().split(' ').first} to ${trip.toDate.toString().split(' ').first}
- Budget: ₱${trip.totalBudget.toStringAsFixed(0)} (Remaining: ₱${remainingBudget.toStringAsFixed(0)})
- Current Stops: ${stopNames.isNotEmpty ? stopNames : 'None scheduled yet'}
- Travelers: ${trip.members.length} companions
- Weather: ${weatherSummary ?? 'Fair Philippine tropical weather'}

Instructions:
1. Provide concise, helpful responses (2-4 paragraphs max).
2. When suggesting new attractions or diners, format with: `[ACTION:ADD_STOP|Title|Location|Food/Activity|EstimatedCost]`.
3. When suggesting essentials to pack, format with: `[ACTION:PACK|ItemName|Category]`.
4. When suggesting budgeting or expense items, format with: `[ACTION:EXPENSE|Description|Amount|Category]`.
''';
  }

  CopilotResponse _parseResponse(String rawText, TripModel trip) {
    final chips = <CopilotActionChip>[];
    var cleanedText = rawText;

    // Parse [ACTION:ADD_STOP|Title|Location|Category|Cost]
    final stopRegex = RegExp(r'\[ACTION:ADD_STOP\|([^|]+)\|([^|]+)\|([^|]+)\|([^\]]+)\]');
    for (final match in stopRegex.allMatches(rawText)) {
      final title = match.group(1)?.trim() ?? 'New Stop';
      final location = match.group(2)?.trim() ?? trip.destination;
      final category = match.group(3)?.trim() ?? 'Activity';
      final cost = double.tryParse(match.group(4)?.trim() ?? '0') ?? 0;

      chips.add(
        CopilotActionChip(
          type: CopilotActionType.addStop,
          label: '➕ Add to Itinerary: $title',
          data: {
            'title': title,
            'location': location,
            'category': category,
            'cost': cost,
          },
        ),
      );
      cleanedText = cleanedText.replaceAll(match.group(0)!, '');
    }

    // Parse [ACTION:PACK|ItemName|Category]
    final packRegex = RegExp(r'\[ACTION:PACK\|([^|]+)\|([^\]]+)\]');
    for (final match in packRegex.allMatches(rawText)) {
      final item = match.group(1)?.trim() ?? 'Item';
      final category = match.group(2)?.trim() ?? 'Essentials';

      chips.add(
        CopilotActionChip(
          type: CopilotActionType.addPackingItem,
          label: '🎒 Add to Packing: $item',
          data: {
            'name': item,
            'category': category,
          },
        ),
      );
      cleanedText = cleanedText.replaceAll(match.group(0)!, '');
    }

    // Parse [ACTION:EXPENSE|Description|Amount|Category]
    final expRegex = RegExp(r'\[ACTION:EXPENSE\|([^|]+)\|([^|]+)\|([^\]]+)\]');
    for (final match in expRegex.allMatches(rawText)) {
      final desc = match.group(1)?.trim() ?? 'Expense';
      final amount = double.tryParse(match.group(2)?.trim() ?? '0') ?? 0;
      final category = match.group(3)?.trim() ?? 'food';

      chips.add(
        CopilotActionChip(
          type: CopilotActionType.logExpense,
          label: '💸 Log Expense: ₱${amount.toStringAsFixed(0)} ($desc)',
          data: {
            'description': desc,
            'amount': amount,
            'category': category,
          },
        ),
      );
      cleanedText = cleanedText.replaceAll(match.group(0)!, '');
    }

    return CopilotResponse(
      markdownText: cleanedText.trim(),
      actionChips: chips,
    );
  }

  CopilotResponse _generateLocalHeuristicResponse(String query, TripModel trip, List<ItineraryStop> stops) {
    final lower = query.toLowerCase();

    if (lower.contains('rain') || lower.contains('weather')) {
      return CopilotResponse(
        markdownText: '🌦️ **Rain Contingency for ${trip.destination}**\n\n'
            'If tropical rains or sudden downpours arrive, pivot to indoor cafes, heritage museums, or covered markets. '
            'Always pack an umbrella and keep gadgets in dry bags!',
        actionChips: const [
          CopilotActionChip(
            type: CopilotActionType.addPackingItem,
            label: '🎒 Add Dry Bag & Umbrella',
            data: {'name': 'Dry Bag & Compact Umbrella', 'category': 'Gear'},
          ),
        ],
      );
    } else if (lower.contains('food') || lower.contains('eat') || lower.contains('dinner')) {
      return CopilotResponse(
        markdownText: '🍽️ **Local Food Recommendation**\n\n'
            'For dinner in ${trip.destination}, check out local home-style carinderias or authentic seafood grill spots. '
            'Ask the locals for the freshest catch of the day or regional soup specialties!',
        actionChips: [
          CopilotActionChip(
            type: CopilotActionType.addStop,
            label: '➕ Add Dinner Stop to Itinerary',
            data: {
              'title': 'Local Food & Seafood Grill',
              'location': trip.destination,
              'category': 'Food',
              'cost': 450.0,
            },
          ),
        ],
      );
    } else {
      return CopilotResponse(
        markdownText: '✨ **Tara Copilot Advice for ${trip.destination}**\n\n'
            'You currently have ${stops.length} stops planned. Remember to pace your group schedule, '
            'keep small peso bills (₱20, ₱50, ₱100) ready for trikes and environmental fees, and log expenses as you go!',
        actionChips: const [
          CopilotActionChip(
            type: CopilotActionType.addPackingItem,
            label: '🎒 Pack Power Bank & Cash Pouch',
            data: {'name': 'Power Bank & Cash Pouch', 'category': 'Essentials'},
          ),
        ],
      );
    }
  }
}
