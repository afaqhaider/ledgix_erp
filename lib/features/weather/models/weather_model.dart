
enum TemperatureUnit { celsius, fahrenheit }

class WeatherInfo {
  final double temperature;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final int humidity;
  final int pressure;
  final double windSpeed;
  final String condition;
  final String description;
  final String iconCode;
  final String cityName;
  final DateTime lastUpdated;

  WeatherInfo({
    required this.temperature,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.humidity,
    required this.pressure,
    required this.windSpeed,
    required this.condition,
    required this.description,
    required this.iconCode,
    required this.cityName,
    required this.lastUpdated,
  });

  factory WeatherInfo.fromOpenWeatherMap(Map<String, dynamic> json) {
    final weather = json['weather'][0];
    final main = json['main'];
    final wind = json['wind'];
    
    return WeatherInfo(
      temperature: (main['temp'] as num).toDouble(),
      feelsLike: (main['feels_like'] as num).toDouble(),
      tempMin: (main['temp_min'] as num).toDouble(),
      tempMax: (main['temp_max'] as num).toDouble(),
      humidity: (main['humidity'] as num).toInt(),
      pressure: (main['pressure'] as num).toInt(),
      windSpeed: (wind['speed'] as num).toDouble(),
      condition: weather['main'] as String,
      description: weather['description'] as String,
      iconCode: weather['icon'] as String,
      cityName: json['name'] as String,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'feelsLike': feelsLike,
      'tempMin': tempMin,
      'tempMax': tempMax,
      'humidity': humidity,
      'pressure': pressure,
      'windSpeed': windSpeed,
      'condition': condition,
      'description': description,
      'iconCode': iconCode,
      'cityName': cityName,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    };
  }

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    return WeatherInfo(
      temperature: json['temperature'],
      feelsLike: json['feelsLike'],
      tempMin: json['tempMin'],
      tempMax: json['tempMax'],
      humidity: json['humidity'],
      pressure: json['pressure'] ?? 1013,
      windSpeed: json['windSpeed'],
      condition: json['condition'],
      description: json['description'],
      iconCode: json['iconCode'],
      cityName: json['cityName'],
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(json['lastUpdated']),
    );
  }

  String get iconUrl => 'https://openweathermap.org/img/wn/$iconCode@2x.png';
}

class WeatherSettings {
  final TemperatureUnit unit;
  final String? manualCity;
  final bool isEnabled;

  WeatherSettings({
    this.unit = TemperatureUnit.celsius,
    this.manualCity,
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'unit': unit.index,
      'manualCity': manualCity,
      'isEnabled': isEnabled,
    };
  }

  factory WeatherSettings.fromJson(Map<String, dynamic> json) {
    return WeatherSettings(
      unit: TemperatureUnit.values[json['unit'] ?? 0],
      manualCity: json['manualCity'],
      isEnabled: json['isEnabled'] ?? true,
    );
  }

  WeatherSettings copyWith({
    TemperatureUnit? unit,
    String? manualCity,
    bool? isEnabled,
  }) {
    return WeatherSettings(
      unit: unit ?? this.unit,
      manualCity: manualCity ?? this.manualCity,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
