import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import 'package:simpleweather/models/weather_model.dart';
import 'package:simpleweather/services/weather_service.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:simpleweather/forecast/forecast_page.dart';

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
        content: Text('Failed to fetch weather data. Please try again later.'),
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
  title: _currentIndex == 0 ? Autocomplete<String>( // Conditional rendering of Autocomplete widget
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
      return TextField(
        controller: textEditingController,
        focusNode: focusNode,
        decoration: InputDecoration(
          hintText: 'Search',
          border: OutlineInputBorder(),
          suffixIcon: _isLoading
              ? CircularProgressIndicator()
              : null,
        ),
        onChanged: _onSearchTextChanged,
        onSubmitted: (value) {
          _fetchWeatherByCity(value);
        },
      );
    },
  ) : null, // Set to null if _currentIndex is not 0
),


       body: _currentIndex == 0
            ? weatherBody()
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
              _weather?.cityName ?? "Location",
            ),
            Visibility(
              visible: _weather != null,
              child: Column(
                children: [
                  Lottie.asset(getWeatherAnimation(_weather?.mainCondition)),
                  Text(
                    "${_weather?.temperature.round()}°C",
                  ),
                  Text(
                    _weather?.mainCondition ?? "",
                  ),
                ],
              ),
            ),
            Visibility(
              visible: _showFetchWeatherButton,
              child: ElevatedButton(
                onPressed: _fetchWeather,
                child: Text("Weather on my location"),
              ),
            ),
          ],
        ),
      ),
    );
  }
  }
