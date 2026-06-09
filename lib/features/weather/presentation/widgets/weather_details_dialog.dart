import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/weather_model.dart';
import 'weather_settings_dialog.dart';
import '../../repositories/weather_repository.dart';
import '../../services/weather_service.dart';

class WeatherDetailsDialog extends StatefulWidget {
  final WeatherInfo weatherInfo;
  final WeatherSettings settings;
  final String companyId;

  const WeatherDetailsDialog({
    super.key,
    required this.weatherInfo,
    required this.settings,
    required this.companyId,
  });

  @override
  State<WeatherDetailsDialog> createState() => _WeatherDetailsDialogState();
}

class _WeatherDetailsDialogState extends State<WeatherDetailsDialog> {
  late WeatherInfo _weatherInfo;
  late WeatherSettings _settings;
  bool _isLoading = false;
  final _repository = WeatherRepository(WeatherService());

  @override
  void initState() {
    super.initState();
    _weatherInfo = widget.weatherInfo;
    _settings = widget.settings;
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    try {
      final info = await _repository.getWeather(
        _weatherInfo.cityName,
        _settings.unit,
        forceRefresh: true,
      );
      if (mounted) {
        setState(() {
          _weatherInfo = info;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to refresh: $e')));
      }
    }
  }

  void _showSettings() async {
    final newSettings = await showDialog<WeatherSettings>(
      context: context,
      builder: (context) => WeatherSettingsDialog(initialSettings: _settings),
    );

    if (newSettings != null) {
      await _repository.saveSettings(newSettings);
      setState(() => _settings = newSettings);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unitStr = _settings.unit == TemperatureUnit.celsius ? 'C' : 'F';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _weatherInfo.cityName,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      DateFormat(
                        'EEEE, MMM d, HH:mm',
                      ).format(_weatherInfo.lastUpdated),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.refresh_rounded,
                        size: 20,
                        color: _isLoading ? theme.colorScheme.primary : null,
                      ),
                      onPressed: _isLoading ? null : _refresh,
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, size: 20),
                      onPressed: _showSettings,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Image.network(
                  _weatherInfo.iconUrl,
                  width: 64,
                  height: 64,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.wb_cloudy_rounded, size: 48),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_weatherInfo.temperature.round()}°$unitStr',
                        style: GoogleFonts.inter(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        _weatherInfo.condition,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Wrap(
              spacing: 20,
              runSpacing: 16,
              children: [
                _buildStat(
                  'Feels Like',
                  '${_weatherInfo.feelsLike.round()}°$unitStr',
                ),
                _buildStat('Humidity', '${_weatherInfo.humidity}%'),
                _buildStat('Wind Speed', '${_weatherInfo.windSpeed} m/s'),
                _buildStat('Pressure', '${_weatherInfo.pressure} hPa'),
                _buildStat('High', '${_weatherInfo.tempMax.round()}°$unitStr'),
                _buildStat('Low', '${_weatherInfo.tempMin.round()}°$unitStr'),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 90,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
