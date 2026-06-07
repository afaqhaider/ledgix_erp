import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'weather_details_dialog.dart';
import '../../../company/services/company_service.dart';
import '../../models/weather_model.dart';
import '../../repositories/weather_repository.dart';
import '../../services/weather_service.dart';

class WeatherDisplay extends StatefulWidget {
  final String companyId;
  final bool isCompact;

  const WeatherDisplay({
    super.key,
    required this.companyId,
    this.isCompact = false,
  });

  @override
  State<WeatherDisplay> createState() => _WeatherDisplayState();
}

class _WeatherDisplayState extends State<WeatherDisplay> {
  final _repository = WeatherRepository(WeatherService());
  final _companyService = CompanyService();
  
  WeatherInfo? _weatherInfo;
  WeatherSettings _settings = WeatherSettings();
  bool _isLoading = false;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      _loadData(forceRefresh: true);
    });
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _settings = await _repository.getSettings();
      
      if (!_settings.isEnabled) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      String? city = _settings.manualCity;
      if (city == null || city.isEmpty) {
        final company = await _companyService.getCompany(widget.companyId).first;
        city = company?.city;
      }

      if (city == null || city.isEmpty) {
        city = 'Dubai';
      }

      final info = await _repository.getWeather(
        city, 
        _settings.unit, 
        forceRefresh: forceRefresh
      );

      if (mounted) {
        setState(() {
          _weatherInfo = info;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _showDetails() {
    if (_weatherInfo == null) {
      _loadData(forceRefresh: true);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => WeatherDetailsDialog(
        weatherInfo: _weatherInfo!,
        settings: _settings,
        companyId: widget.companyId,
      ),
    ).then((_) => _loadData()); // Refresh settings/data after dialog close
  }

  @override
  Widget build(BuildContext context) {
    if (!_settings.isEnabled) return const SizedBox.shrink();

    // If not compact (dashboard widget), we return nothing as requested
    if (!widget.isCompact) return const SizedBox.shrink();

    return _buildCompactView();
  }

  void _showErrorDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.orange),
            SizedBox(width: 8),
            Text('Weather Error'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Could not fetch weather data:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_error ?? 'Unknown error'),
            const SizedBox(height: 16),
            const Text('Troubleshooting:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const Text('• Check your internet connection.', style: TextStyle(fontSize: 12)),
            const Text('• Verify the city name in Company Settings.', style: TextStyle(fontSize: 12)),
            const Text('• Ensure the OpenWeather API key is valid.', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadData(forceRefresh: true);
            },
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactView() {
    if (_isLoading && _weatherInfo == null) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_error != null && _weatherInfo == null) {
      return InkWell(
        onTap: _showErrorDetails,
        borderRadius: BorderRadius.circular(4),
        child: const Tooltip(
          message: 'Weather Error. Click for details.',
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange),
          ),
        ),
      );
    }

    if (_weatherInfo == null) return const SizedBox.shrink();

    return InkWell(
      onTap: _showDetails,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildWeatherIcon(_weatherInfo!.iconUrl),
            const SizedBox(width: 6),
            Text(
              '${_weatherInfo!.temperature.round()}°${_settings.unit == TemperatureUnit.celsius ? 'C' : 'F'}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.refresh_rounded, size: 14, color: Colors.grey.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherIcon(String url) {
    return Image.network(
      url,
      width: 24,
      height: 24,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.wb_sunny_rounded, 
        color: Colors.orange, 
        size: 18
      ),
    );
  }
}
