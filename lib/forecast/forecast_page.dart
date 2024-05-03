import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:simpleweather/models/weather_model.dart';
import 'package:simpleweather/services/weather_service.dart';
import 'package:lottie/lottie.dart';

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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 3.0), // Add padding
      child: Card(
        elevation: 0, // Remove the shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0), // Set border radius
        ),
        color: Colors.grey[700], // Set background color to grey
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
      SizedBox(width: 5),
      buildConditionIcon(forecast.mainCondition),
    ],
  ),
  subtitle: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '${forecast.temperature.round()}°C, ${forecast.mainCondition}',
        style: TextStyle(
          fontSize: 18,
          color: Colors.white,
          fontFamily: 'Helvetica',
        ),
      ),
      SizedBox(height: 4),
      Text(
        'Humidity: ${forecast.humidity}%, Wind Speed: ${forecast.windSpeed.toStringAsFixed(2)} km/h',
        style: TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontFamily: 'Helvetica',
        ),
      ),
    ],
  ),
),


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
