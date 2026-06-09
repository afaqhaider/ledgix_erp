import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  // Try to load from environment variable first (for deployed builds)
  static const String _apiKey = String.fromEnvironment(
    'OPENWEATHER_API_KEY',
    defaultValue: '6015f88eaa5ae1b6ad2aec3d103e156d',
  );
  static const String _baseUrl =
      'https://api.openweathermap.org/data/2.5/weather';

  Future<WeatherInfo> fetchWeather(String city, TemperatureUnit unit) async {
    final units = unit == TemperatureUnit.celsius ? 'metric' : 'imperial';
    final encodedCity = Uri.encodeComponent(city);
    final url = '$_baseUrl?q=$encodedCity&appid=$_apiKey&units=$units';

    // Diagnostics
    final maskedKey = _apiKey.length > 8
        ? '${_apiKey.substring(0, 4)}...${_apiKey.substring(_apiKey.length - 4)}'
        : 'INVALID_OR_EMPTY';

    debugPrint('WeatherService: Fetching weather for $city');
    debugPrint(
      'WeatherService: URL: $_baseUrl?q=$encodedCity&appid=$maskedKey&units=$units',
    );

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      debugPrint('WeatherService: Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return WeatherInfo.fromOpenWeatherMap(json.decode(response.body));
      } else {
        debugPrint('WeatherService: Error Body: ${response.body}');
        if (response.statusCode == 401) {
          throw Exception(
            'Weather API Key is invalid or not yet active. (OpenWeatherMap 401)',
          );
        } else if (response.statusCode == 404) {
          throw Exception(
            'City "$city" not found. Please check spelling in company settings.',
          );
        } else if (response.statusCode == 429) {
          throw Exception(
            'Weather API rate limit exceeded. Please try again later.',
          );
        } else {
          try {
            final error = json.decode(response.body);
            throw Exception(error['message'] ?? 'Failed to fetch weather data');
          } catch (_) {
            throw Exception('Failed to fetch weather: ${response.statusCode}');
          }
        }
      }
    } catch (e) {
      debugPrint('WeatherService: Exception: $e');
      if (e is http.ClientException) {
        throw Exception(
          'Network error or CORS issue while fetching weather data.',
        );
      }
      rethrow;
    }
  }
}
