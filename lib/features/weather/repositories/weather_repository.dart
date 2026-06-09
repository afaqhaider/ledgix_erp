import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';

class WeatherRepository {
  final WeatherService _service;
  static const String _cacheKey = 'weather_cache';
  static const String _settingsKey = 'weather_settings';
  static const Duration _cacheDuration = Duration(minutes: 30);

  WeatherRepository(this._service);

  Future<WeatherInfo?> getCachedWeather() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);
      if (cachedData == null) return null;

      final info = WeatherInfo.fromJson(json.decode(cachedData));
      if (DateTime.now().difference(info.lastUpdated) > _cacheDuration) {
        return null; // Cache expired
      }
      return info;
    } catch (_) {
      return null;
    }
  }

  Future<void> cacheWeather(WeatherInfo info) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, json.encode(info.toJson()));
    } catch (_) {}
  }

  Future<WeatherSettings> getSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsData = prefs.getString(_settingsKey);
      if (settingsData == null) return WeatherSettings();
      return WeatherSettings.fromJson(json.decode(settingsData));
    } catch (_) {
      return WeatherSettings();
    }
  }

  Future<void> saveSettings(WeatherSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_settingsKey, json.encode(settings.toJson()));
    } catch (_) {}
  }

  Future<WeatherInfo> getWeather(
    String city,
    TemperatureUnit unit, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await getCachedWeather();
      // Only use cache if it's the same city and not expired
      if (cached != null &&
          cached.cityName.toLowerCase().contains(city.toLowerCase())) {
        return cached;
      }
    }

    final info = await _service.fetchWeather(city, unit);
    await cacheWeather(info);
    return info;
  }
}
