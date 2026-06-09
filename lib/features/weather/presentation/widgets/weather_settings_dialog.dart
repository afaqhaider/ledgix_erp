import 'package:flutter/material.dart';
import '../../models/weather_model.dart';
import '../../../../widgets/erp_ui_components.dart';

class WeatherSettingsDialog extends StatefulWidget {
  final WeatherSettings initialSettings;

  const WeatherSettingsDialog({super.key, required this.initialSettings});

  @override
  State<WeatherSettingsDialog> createState() => _WeatherSettingsDialogState();
}

class _WeatherSettingsDialogState extends State<WeatherSettingsDialog> {
  late TemperatureUnit _unit;
  late TextEditingController _cityController;
  late bool _isEnabled;

  @override
  void initState() {
    super.initState();
    _unit = widget.initialSettings.unit;
    _cityController = TextEditingController(
      text: widget.initialSettings.manualCity,
    );
    _isEnabled = widget.initialSettings.isEnabled;
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ErpGlassModal(
      title: 'Weather Settings',
      onCancel: () => Navigator.pop(context),
      onSave: () {
        final newSettings = WeatherSettings(
          unit: _unit,
          manualCity: _cityController.text.trim().isEmpty
              ? null
              : _cityController.text.trim(),
          isEnabled: _isEnabled,
        );
        Navigator.pop(context, newSettings);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: const Text('Enable Weather Widget'),
            subtitle: const Text('Show live weather data on dashboard'),
            value: _isEnabled,
            onChanged: (val) => setState(() => _isEnabled = val),
          ),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Temperature Unit',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          SegmentedButton<TemperatureUnit>(
            segments: const [
              ButtonSegment(
                value: TemperatureUnit.celsius,
                label: Text('Celsius (°C)'),
              ),
              ButtonSegment(
                value: TemperatureUnit.fahrenheit,
                label: Text('Fahrenheit (°F)'),
              ),
            ],
            selected: {_unit},
            onSelectionChanged: (val) => setState(() => _unit = val.first),
          ),
          const SizedBox(height: 24),
          const Text(
            'Manual City (Optional)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _cityController,
            decoration: ErpFormStyle.inputDecoration(
              context,
              'Enter city name (e.g. London, UK)',
              icon: Icons.location_city_rounded,
            ).copyWith(hintText: 'Leave empty to use company location'),
          ),
          const SizedBox(height: 16),
          Text(
            'By default, LedGix uses your company\'s city from settings.',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
