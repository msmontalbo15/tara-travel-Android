import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/selected_trip_provider.dart';
import '../../core/models/trip_model.dart';
import '../../core/models/weather_model.dart';
import '../itinerary/itinerary_screen.dart';
import '../budget/budget_screen.dart';
import '../packing/packing_screen.dart';
import '../members/members_screen.dart';
import '../activity/activity_log_screen.dart';
import '../chat/chat_screen.dart';

class TripDetailScreen extends ConsumerStatefulWidget {
  const TripDetailScreen({super.key});

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _weather = WeatherData.unavailable();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(selectedTripProvider);

    return tripAsync.when(
      data: (trip) {
        if (trip == null) {
          return const Scaffold(body: Center(child: Text('Trip not found')));
        }
        return Scaffold(
          backgroundColor: AppColors.deepEarth,
          body: Column(
            children: [
              _buildHero(trip),
              // Tab bar
              Container(
                color: AppColors.deepEarth,
                child: TabBar(
                  controller: _tabCtrl,
                  isScrollable: true,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 2.5,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white38,
                  labelStyle: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600),
                  tabAlignment: TabAlignment.start,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Itinerary'),
                    Tab(text: 'Budget'),
                    Tab(text: 'Packing'),
                    Tab(text: 'Members'),
                    Tab(text: 'Activity'),
                    Tab(text: 'Chat'),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [
                    ItineraryScreen(showHeader: false),
                    BudgetScreen(showHeader: false),
                    PackingScreen(showHeader: false),
                    MembersScreen(showHeader: false),
                    _ActivityWrapper(),
                    ChatScreen(showHeader: false),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(backgroundColor: AppColors.deepEarth, body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(backgroundColor: AppColors.deepEarth, body: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildHero(TripModel trip) {
    final daysLeft = trip.fromDate.difference(DateTime.now()).inDays;
    final budgetPct = trip.totalBudget > 0 ? trip.totalSpent / trip.totalBudget : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A0A04), AppColors.deepEarth],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.name, style: const TextStyle(fontFamily: 'Playfair Display', fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                    Text('${trip.destination} · ${DateFormat('MMM d').format(trip.fromDate)}–${DateFormat('MMM d').format(trip.toDate)}', style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: Colors.white.withValues(alpha: 0.4))),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/navigation'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.navigation_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text('Navigate', style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            children: [
              _statChip('📅', '${trip.fromDate.difference(trip.toDate).abs().inDays + 1} days'),
              const SizedBox(width: 8),
              _statChip('👥', '${trip.members.length} people'),
              const SizedBox(width: 8),
              _statChip('💰', '₱${(trip.totalBudget / 1000).toStringAsFixed(0)}k'),
              const Spacer(),
              if (daysLeft > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Text('$daysLeft days left', style: const TextStyle(fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryLight)),
                )
              else if (daysLeft == 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.greenBright.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Trip starts today!', style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.greenBright)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // Budget bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('₱${trip.totalSpent.toInt()} spent', style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: Colors.white.withValues(alpha: 0.5))),
                  Text('of ₱${trip.totalBudget.toInt()}', style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: Colors.white.withValues(alpha: 0.3))),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: budgetPct.clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(budgetPct > 1.0 ? AppColors.red : budgetPct > 0.9 ? AppColors.amber : AppColors.greenBright),
                  minHeight: 5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Weather card
          _buildWeatherRow(),
        ],
      ),
    );
  }

  Widget _buildWeatherRow() {
    return GestureDetector(
      onTap: () => _showWeatherDetail(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Text(_weather.conditionIcon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_weather.temperature.toInt()}°C · ${_weather.condition}', style: const TextStyle(fontFamily: 'DM Sans', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                  Text(
                    _weather.forecast.isEmpty
                        ? 'Forecast not connected yet'
                        : 'UV ${_weather.uvIndex} · 💧${_weather.rainProbability.toInt()}% rain',
                    style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: Colors.white.withValues(alpha: 0.4)),
                  ),
                ],
              ),
            ),
            Row(
              children: _weather.forecast.take(4).map((f) => Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Column(
                  children: [
                    Text(f.conditionIcon, style: const TextStyle(fontSize: 14)),
                    Text('${f.tempMax.toInt()}°', style: TextStyle(fontFamily: 'DM Sans', fontSize: 9, color: Colors.white.withValues(alpha: 0.5))),
                  ],
                ),
              )).toList(),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.3), size: 16),
          ],
        ),
      ),
    );
  }

  void _showWeatherDetail() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _WeatherDetailSheet(weather: _weather),
    );
  }

  Widget _statChip(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }
}

class _ActivityWrapper extends StatelessWidget {
  const _ActivityWrapper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: Consumer(
        builder: (context, ref, _) {
          return const ActivityLogScreenInline();
        },
      ),
    );
  }
}

class _WeatherDetailSheet extends StatelessWidget {
  final WeatherData weather;
  const _WeatherDetailSheet({required this.weather});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Row(
              children: [
                const Text('Weather Forecast', style: TextStyle(fontFamily: 'Playfair Display', fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                const Spacer(),
                GestureDetector(onTap: () => Navigator.pop(context), child: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.3))),
              ],
            ),
          ),
          // Current
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(weather.conditionIcon, style: const TextStyle(fontSize: 56)),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${weather.temperature.toInt()}°C', style: const TextStyle(fontFamily: 'Playfair Display', fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white)),
                    Text(weather.condition, style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, color: Colors.white.withValues(alpha: 0.5))),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _infoTag('💧', '${weather.humidity.toInt()}%'),
                    const SizedBox(height: 4),
                    _infoTag('☀️', 'UV ${weather.uvIndex}'),
                    const SizedBox(height: 4),
                    _infoTag('🌧️', '${weather.rainProbability.toInt()}% rain'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
              children: weather.forecast.map((f) => _ForecastRow(forecast: f)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTag(String emoji, String text) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
      ],
    );
  }
}

class _ForecastRow extends StatelessWidget {
  final DayForecast forecast;
  const _ForecastRow({required this.forecast});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(DateFormat('EEE').format(forecast.date), style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: Colors.white.withValues(alpha: 0.6)))),
          Text(forecast.conditionIcon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text(forecast.condition, style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: Colors.white.withValues(alpha: 0.4)))),
          Text('${forecast.tempMin.toInt()}°–${forecast.tempMax.toInt()}°', style: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }
}
