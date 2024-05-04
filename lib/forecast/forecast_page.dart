import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:simpleweather/models/weather_model.dart';
import 'package:simpleweather/services/weather_service.dart';
import 'package:lottie/lottie.dart';
import 'package:country_flags/country_flags.dart';

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

  Widget buildConditionIcon(String condition) {
    String animationAsset;
    switch (condition.toLowerCase()) {
      case 'clouds':
        animationAsset = 'assets/windy.json';
        break;
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
        animationAsset = 'assets/mist.json';
        break;
      case 'rain':
      case 'drizzle':
      case 'shower rain':
        animationAsset = 'assets/rainy.json';
        break;
      case 'thunder':
        animationAsset = 'assets/thunder.json';
        break;
      case 'thunderstorm':
      case 'rainstorm':
        animationAsset = 'assets/storm.json';
        break;
      case 'clear':
        animationAsset = 'assets/sunny.json';
        break;
      case 'snow':
        animationAsset = 'assets/snow.json';
        break;
      default:
        animationAsset = 'assets/sunny.json';
        break;
    }
    return Lottie.asset(
      animationAsset,
      width: 18,
      height: 18,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Set app bar background color to transparent
        elevation: 0, // Remove app bar elevation
        title: Center( // Center the app bar title
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 35.0), // Add horizontal padding
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12.0), // Add vertical padding
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0), // Set border radius
                color: Colors.grey[900], // Set background color to grey
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, // Center the content horizontally
                children: [
                  Text(
                    "${widget.weather?.cityName ?? "Location"},",
                    style: TextStyle(
                      fontFamily: 'Helvetica',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 5), // Add some spacing between city name and flag
                  if (widget.weather?.countryName != null) // Check if countryName is available
                    Text(
                      "${widget.weather!.countryName} ", // Display countryName
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Helvetica',
                      ),
                    ),
                  if (widget.weather?.countryCode != null)
                    CountryFlag.fromCountryCode(
                      widget.weather!.countryCode.toLowerCase(),
                      width: 24,
                      height: 24,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _forecastByDate == null
          ? Center(child: CircularProgressIndicator(color: Colors.white,))
          : ListView.builder(
        itemCount: _forecastByDate!.length,
        itemBuilder: (context, index) {
          final date = _forecastByDate!.keys.elementAt(index);
          final forecastList = _forecastByDate![date]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
  padding: EdgeInsets.symmetric(horizontal: 28.0, vertical: 14.0), // Add horizontal and vertical padding
  child: Text(
    date,
    style: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 18,
    ),
  ),
),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  color: Colors.grey[700],
                  child: ExpansionTile(
                    title: ListTile(
                      title: Row(
                        children: [
                          Text(
                            DateFormat('HH:mm').format(forecastList[0].date),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white,
                              fontFamily: 'Helvetica',
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              buildConditionIcon(forecastList[0].mainCondition),
                              SizedBox(width: 5),
                              Text(
                                '${forecastList[0].temperature.round()}°C, ${forecastList[0].mainCondition}',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontFamily: 'Helvetica',
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.water_drop, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Humidity: ${forecastList[0].humidity}%',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontFamily: 'Helvetica',
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.speed, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Wind Speed: ${forecastList[0].windSpeed.toStringAsFixed(2)} km/h',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontFamily: 'Helvetica',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    iconColor: Colors.white,
                    collapsedIconColor: Colors.white, // Set the color of the dropdown icon
                    children: forecastList.skip(1).map((forecast) {
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          color: Colors.grey[700],
                          child: ListTile(
                            title: Row(
                              children: [
                                Text(
                                  DateFormat('HH:mm').format(forecast.date),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontFamily: 'Helvetica',
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    buildConditionIcon(forecast.mainCondition),
                                    SizedBox(width: 5),
                                    Text(
                                      '${forecast.temperature.round()}°C, ${forecast.mainCondition}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontFamily: 'Helvetica',
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.water_drop, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      'Humidity: ${forecast.humidity}%',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontFamily: 'Helvetica',
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.speed, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      'Wind Speed: ${forecast.windSpeed.toStringAsFixed(2)} km/h',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontFamily: 'Helvetica',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
