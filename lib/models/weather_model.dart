class Weather {
  final String cityName;
  final double temperature;
  final String mainCondition;
  final DateTime date;
  final double latitude;
  final double longitude;

  Weather({
    required this.cityName,
    required this.temperature,
    required this.mainCondition,
    required this.date,
    required this.latitude,
    required this.longitude,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
  final coordJson = json['coord'];
  final mainJson = json['main'];
  final weatherJson = json['weather'];

  return Weather(
    cityName: json['name'] ?? '',
    temperature: mainJson?['temp']?.toDouble() ?? 0.0,
    mainCondition: weatherJson is List && weatherJson.isNotEmpty ? weatherJson[0]['main'] ?? '' : '',
    date: DateTime.parse(json['dt_txt'] ?? '1900-01-01 00:00:00'),
    latitude: coordJson?['lat']?.toDouble() ?? 0.0,
    longitude: coordJson?['lon']?.toDouble() ?? 0.0,
  );
}
}