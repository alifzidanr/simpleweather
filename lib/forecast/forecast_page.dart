import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
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
  Map<String, List<Weather>>? _forecastByDate;

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
        _groupForecastByDate(forecast);
      } catch (e) {
        print(e);
      }
    }
  }

  void _groupForecastByDate(List<Weather> forecast) {
    _forecastByDate = {};
    for (var weather in forecast) {
      final dateKey = DateFormat('EEEE, MMMM d').format(weather.date); // Format date
      if (!_forecastByDate!.containsKey(dateKey)) {
        _forecastByDate![dateKey] = [];
      }
      _forecastByDate![dateKey]!.add(weather);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  backgroundColor: Colors.grey[900], // Set background color to grey
  title: Text(
    "${widget.weather?.cityName ?? "Location"}, ${widget.weather?.countryName ?? ""}",
    style: TextStyle(
      fontFamily: 'Helvetica',
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),
),

      body: _forecastByDate == null
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _forecastByDate!.length,
              itemBuilder: (context, index) {
                final date = _forecastByDate!.keys.elementAt(index);
                final forecastList = _forecastByDate![date]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        date,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: forecastList.length,
                      itemBuilder: (context, index) {
                        final forecast = forecastList[index];
                        return ListTile(
                          title: Text(
                            DateFormat('HH:mm').format(forecast.date),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white, // Set text color to khaki
                              fontFamily: 'Helvetica', // Set font family to Helvetica
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${forecast.temperature.round()}°C, ',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white, // Set text color to khaki
                                      fontFamily: 'Helvetica', // Set font family to Helvetica
                                    ),
                                  ),
                                  Text(
                                    forecast.mainCondition,
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white, // Set text color to khaki
                                      fontFamily: 'Helvetica', // Set font family to Helvetica
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Humidity: ${forecast.humidity}%, Wind Speed: ${forecast.windSpeed.toStringAsFixed(2)} km/h',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white, // Set text color to white
                                  fontFamily: 'Helvetica', // Set font family to Helvetica
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Divider(),
                  ],
                );
              },
            ),
    );
  }
}
