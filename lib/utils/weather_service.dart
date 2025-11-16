import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_data.dart';

class WeatherService {
  static const String _cacheKey = 'cached_weather_data';

  // Derive coordinates from student index
  static Map<String, double> deriveCoordinates(String index) {
    if (index.length < 4) {
      throw ArgumentError('Index must be at least 4 characters');
    }

    final firstTwo = int.parse(index.substring(0, 2));
    final nextTwo = int.parse(index.substring(2, 4));

    final lat = 5 + (firstTwo / 10.0);
    final lon = 79 + (nextTwo / 10.0);

    return {'lat': lat, 'lon': lon};
  }

  // Build the API request URL
  static String buildRequestUrl(double lat, double lon) {
    return 'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true';
  }

  // Fetch weather data from API
  static Future<WeatherData> fetchWeather(double lat, double lon) async {
    final url = buildRequestUrl(lat, lon);

    final response = await http.get(Uri.parse(url)).timeout(
      const Duration(seconds: 10),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final currentWeather = data['current_weather'];

      final weatherData = WeatherData(
        temperature: currentWeather['temperature'].toDouble(),
        windSpeed: currentWeather['windspeed'].toDouble(),
        weatherCode: currentWeather['weathercode'],
        lastUpdated: DateTime.now(),
      );

      // Cache the successful result
      await _cacheWeatherData(weatherData);

      return weatherData;
    } else {
      throw Exception('Failed to load weather data: ${response.statusCode}');
    }
  }

  // Cache weather data locally
  static Future<void> _cacheWeatherData(WeatherData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, data.toJsonString());
  }

  // Retrieve cached weather data
  static Future<WeatherData?> getCachedWeather() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedString = prefs.getString(_cacheKey);

    if (cachedString != null) {
      try {
        return WeatherData.fromJsonString(cachedString).copyWith(isCached: true);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
