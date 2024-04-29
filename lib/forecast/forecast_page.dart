import 'package:flutter/material.dart';
import 'package:simpleweather/models/weather_model.dart';
import 'package:simpleweather/services/weather_service.dart';

class ForecastPage extends StatefulWidget {
  final Weather? weather;

  ForecastPage({this.weather});

  @override
  _ForecastPageState createState() => _ForecastPageState();
}

class _ForecastPageState extends State<ForecastPage> {
  final _weatherService = WeatherService('ae10c6c9a4c9bf10931995caa1616edd');
  List<Weather>? _forecast;

  @override
  void initState() {
    super.initState();
    _fetchForecast();
  }

  _fetchForecast() async {
  if (widget.weather != null) {
    final latitude = widget.weather!.latitude;
    final longitude = widget.weather!.longitude;

    try {
      final forecast = await _weatherService.getForecast(latitude, longitude);
      setState(() {
        _forecast = forecast;
      });
    } catch (e) {
      print(e);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('5-Day Forecast'),
      ),
      body: _forecast == null
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _forecast!.length,
              itemBuilder: (context, index) {
                final forecast = _forecast![index];
                return Card(
                  child: ListTile(
                    title: Text(forecast.cityName),
                    subtitle: Text(
                        'Date: ${forecast.date}, Temp: ${forecast.temperature.round()}°C, Condition: ${forecast.mainCondition}'),
                  ),
                );
              },
            ),
    );
  }
}
