import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import 'package:simpleweather/models/weather_model.dart';
import 'package:simpleweather/services/weather_service.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:simpleweather/forecast/forecast_page.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({Key? key}) : super(key: key);

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final _weatherService = WeatherService('ae10c6c9a4c9bf10931995caa1616edd');
  Weather? _weather;
  TextEditingController _searchController = TextEditingController();
  int _currentIndex = 0;

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

   Timer? _debounce;
  Map<String, List<String>> _cachedSuggestions = {};
  bool _isLoading = false;
  bool _showFetchWeatherButton = true;

  Future<List<String>> fetchAutocompleteSuggestions(String query) async {
  if (_cachedSuggestions.containsKey(query)) {
    return _cachedSuggestions[query]!;
  }

  final url = 'https://photon.komoot.io/api/?q=$query';
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final suggestions = data['features'] as List<dynamic>;
    final suggestionNames = suggestions.map((suggestion) => suggestion['properties']['name'] as String).toList();
    _cachedSuggestions[query] = suggestionNames;
    return suggestionNames;
  } else {
    throw Exception('Failed to fetch autocomplete suggestions');
  }
}


  void _onSearchTextChanged(String value) {
    setState(() {
      _isLoading = true;
    });

    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      fetchAutocompleteSuggestions(value).then((suggestions) {
        setState(() {
          _isLoading = false;
        });
      });
    });
  }


  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  _fetchWeather() async {
  try {
    String cityName = await _weatherService.getCurrentCity();
    final weather = await _weatherService.getWeather(cityName);
    setState(() {
      _weather = weather;
      _showFetchWeatherButton = false;
    });
  } catch (e) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text('Failed to fetch weather data. Please allow location access or try again later.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
    print('Error fetching weather: $e');
  }
}

  String getWeatherAnimation(String? mainCondition) {
    if (mainCondition == null) return 'assets/sunny.json'; //default

    switch (mainCondition.toLowerCase()) {
      case 'clouds':
        return 'assets/windy.json';
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
        return 'assets/mist.json';
      case 'rain':
      case 'drizzle':
      case 'shower rain':
        return 'assets/rainy.json';
      case 'thunder':
        return 'assets/thunder.json';
      case 'thunderstorm':
      case 'rainstorm':
        return 'assets/storm.json';
      case 'clear':
        return 'assets/sunny.json';
      case 'snow':
      case 'snow':
      case 'snow':
        return 'assets/snow.json';
      default:
        return 'assets/sunny.json';
    }
  }

_fetchWeatherByCity(String city) async {
  try {
    final weather = await _weatherService.getWeather(city);
    setState(() {
      _weather = weather;
      _showFetchWeatherButton = true;
    });
  } catch (e) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text('Failed to fetch weather data for $city. Please try again later.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
    print('Error fetching weather for $city: $e');
  }
}

  @override
Widget build(BuildContext context) {
  return MaterialApp(
    theme: ThemeData(
      fontFamily: 'Helvetica',
      scaffoldBackgroundColor: Colors.grey[800],
      textTheme: TextTheme(
        bodyText2: TextStyle(color: Colors.white, fontSize: 24),
      ),
    ),
    home: Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[800], // Set background color for the app bar
        title: _currentIndex == 0
            ? Row(
                children: [
                  Expanded(
                    child: Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        final query = textEditingValue.text;
                        if (query.isEmpty) {
                          return [];
                        } else {
                          return _cachedSuggestions[query] ?? [];
                        }
                      },
                      onSelected: (String selectedValue) {
                        _searchController.text = selectedValue;
                        _fetchWeatherByCity(selectedValue);
                      },
                      fieldViewBuilder: (BuildContext context,
                          TextEditingController textEditingController,
                          FocusNode focusNode,
                          VoidCallback onFieldSubmitted) {
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.0), // Add padding to the text field
                          decoration: BoxDecoration(
                            color: Colors.grey[900], // Set background color for the text field
                            borderRadius: BorderRadius.circular(8.0), // Set border radius for the text field
                          ),
                          child: TextField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              hintText: 'Search by city or country...',
                              hintStyle: TextStyle(color: Colors.white),
                              border: InputBorder.none, // Remove border
                              suffixIcon: _isLoading
    ? SizedBox(
        width: 20,
        height: 20,
        child: SpinKitDoubleBounce(
          size: 20,
          color: Colors.white,
        ),
      )
    : null,



                            ),
                            onChanged: _onSearchTextChanged,
                            onSubmitted: (value) {
                              _fetchWeatherByCity(value);
                            },
                            style: TextStyle(color: Colors.white), // Set text color for the text field
                          ),
                        );
                      },
                    ),
                  ),
                ],
              )
            : Container(
    alignment: Alignment.center,
    child: Text(
      'Forecasts',
      style: TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontFamily: 'Helvetica',
        fontWeight: FontWeight.bold,
      ),
    ),
  ), // Remove app bar when index is not 0
      ),
      body: _currentIndex == 0
          ? Padding(
              padding: EdgeInsets.only(top: 24.0), // Add padding to the top of the body
              child: weatherBody(),
            )
          : ForecastPage(weather: _weather), // Show ForecastPage when index is 1
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud),
            label: 'Weather',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Forecast', // Label for ForecastPage
          ),
        ],
      ),
    ),
  );
}



       Widget weatherBody() {
  return SingleChildScrollView(
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.location_on,
            color: Colors.white,
            size: 24,
          ),
          SizedBox(height: 8),
          Text(
            "${_weather?.cityName ?? "Location"}, ${_weather?.countryName ?? ""}",
            // Display city name and country name if available
          ),
          Visibility(
            visible: _weather != null,
            child: Column(
              children: [
                Lottie.asset(getWeatherAnimation(_weather?.mainCondition)),
                SizedBox(height: 8), // Add vertical spacing between Lottie animation and temperature
                Text(
                  "${_weather?.temperature.round()}°C",
                ),
                Text(
                  _weather?.mainCondition ?? "",
                ),
                SizedBox(height: 16), // Add vertical padding between weather condition and button
                Visibility(
                  visible: _showFetchWeatherButton,
                  child: Padding(
                    padding: EdgeInsets.only(top: 16), // Add top padding
                    child: ElevatedButton(
                      onPressed: _fetchWeather,
                      child: Text("Weather on my location"),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  }
