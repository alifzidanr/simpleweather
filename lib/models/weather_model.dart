class Weather {
  final String cityName;
  final String countryName; // Add country name property
  final double temperature;
  final String mainCondition;
  final DateTime date;
  final double latitude;
  final double longitude;
  final int humidity; // Add humidity property
  final double windSpeed; // Add wind speed property

  Weather({
    required this.cityName,
    required this.countryName, // Add country name parameter
    required this.temperature,
    required this.mainCondition,
    required this.date,
    required this.latitude,
    required this.longitude,
    required this.humidity,
    required this.windSpeed,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    final coordJson = json['coord'];
    final mainJson = json['main'];
    final weatherJson = json['weather'];

    return Weather(
      cityName: json['name'] ?? '',
      countryName: json['sys']['country'] ?? '', // Parse country name from JSON
      temperature: mainJson?['temp']?.toDouble() ?? 0.0,
      mainCondition: weatherJson is List && weatherJson.isNotEmpty ? weatherJson[0]['main'] ?? '' : '',
      date: DateTime.parse(json['dt_txt'] ?? '1900-01-01 00:00:00'),
      latitude: coordJson?['lat']?.toDouble() ?? 0.0,
      longitude: coordJson?['lon']?.toDouble() ?? 0.0,
      humidity: mainJson?['humidity'] ?? 0, // Parse humidity from JSON
      windSpeed: (json['wind']?['speed']?.toDouble() ?? 0) * 3.6, // Parse wind speed from JSON and convert m/s to km/h
    );
  }
}
