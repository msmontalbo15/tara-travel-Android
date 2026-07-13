class DayForecast {
  final DateTime date;
  final double tempMin;
  final double tempMax;
  final String condition;
  final String conditionIcon;
  final double rainProbability;
  final int uvIndex;

  const DayForecast({
    required this.date,
    required this.tempMin,
    required this.tempMax,
    required this.condition,
    required this.conditionIcon,
    required this.rainProbability,
    required this.uvIndex,
  });
}

class WeatherData {
  final double temperature;
  final String condition;
  final String conditionIcon;
  final double humidity;
  final int uvIndex;
  final double rainProbability;
  final double windSpeed;
  final List<DayForecast> forecast;
  final bool hasAlert;
  final String? alertMessage;
  final String? alertLevel;

  const WeatherData({
    required this.temperature,
    required this.condition,
    required this.conditionIcon,
    required this.humidity,
    required this.uvIndex,
    required this.rainProbability,
    required this.windSpeed,
    required this.forecast,
    this.hasAlert = false,
    this.alertMessage,
    this.alertLevel,
  });

  static WeatherData mock() {
    final now = DateTime.now();
    return WeatherData(
      temperature: 31,
      condition: 'Partly Cloudy',
      conditionIcon: '⛅',
      humidity: 78,
      uvIndex: 8,
      rainProbability: 20,
      windSpeed: 12,
      forecast: [
        DayForecast(date: now, tempMin: 26, tempMax: 32, condition: 'Partly Cloudy', conditionIcon: '⛅', rainProbability: 20, uvIndex: 8),
        DayForecast(date: now.add(const Duration(days: 1)), tempMin: 25, tempMax: 30, condition: 'Sunny', conditionIcon: '☀️', rainProbability: 5, uvIndex: 10),
        DayForecast(date: now.add(const Duration(days: 2)), tempMin: 24, tempMax: 29, condition: 'Rainy', conditionIcon: '🌧️', rainProbability: 75, uvIndex: 3),
        DayForecast(date: now.add(const Duration(days: 3)), tempMin: 25, tempMax: 31, condition: 'Sunny', conditionIcon: '☀️', rainProbability: 10, uvIndex: 9),
        DayForecast(date: now.add(const Duration(days: 4)), tempMin: 26, tempMax: 32, condition: 'Partly Cloudy', conditionIcon: '⛅', rainProbability: 25, uvIndex: 7),
      ],
    );
  }

  static WeatherData unavailable() {
    return const WeatherData(
      temperature: 0,
      condition: 'Weather unavailable',
      conditionIcon: '⛅',
      humidity: 0,
      uvIndex: 0,
      rainProbability: 0,
      windSpeed: 0,
      forecast: [],
    );
  }
}
