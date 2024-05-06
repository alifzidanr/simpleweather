import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import 'package:simpleweather/models/weather_model.dart';
import 'package:simpleweather/services/weather_service.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:simpleweather/forecast/forecast_page.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:country_flags/country_flags.dart';
import 'package:connectivity/connectivity.dart';

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

  void _checkConnectivity() async {
  ConnectivityResult connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult != ConnectivityResult.none) {
    _fetchWeatherForJakarta();
  } else {
    setState(() {
      _showNoInternetDialog = true; // Show the dialog if there's no internet connectivity
    });
  }
}

  Timer? _debounce;
  Map<String, List<String>> _cachedSuggestions = {};
  bool _isLoading = false;
  bool _showFetchWeatherButton = true;
  bool _showNoInternetDialog = false;

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
  _checkConnectivity();

  // Add listener for connectivity changes
  Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
    if (result != ConnectivityResult.none) {
      _fetchWeatherForJakarta();
    } else {
      setState(() {
        _showNoInternetDialog = true; // Show the dialog if there's no internet connectivity
      });
    }
  });
}


  _fetchWeatherForJakarta() async {
  try {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _showNoInternetDialog = true;
      });
      return;
    } else {
      setState(() {
        _showNoInternetDialog = false; // Hide the dialog if there's internet connectivity
      });
    }

    final weather = await _weatherService.getWeather("Jakarta");
    setState(() {
      _weather = weather;
      _showFetchWeatherButton = true;
    });
  } catch (e) {
    // Handle error
  }
}

  _fetchWeather() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        setState(() {
          _showNoInternetDialog = true;
        });
        return;
      }

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
        return 'assets/snow.json';
      default:
        return 'assets/sunny.json';
    }
  }

 _fetchWeatherByCity(String city) async {
  try {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _showNoInternetDialog = true;
      });
      return;
    }

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
        content: Text('Failed to fetch weather data for $city. Please input location name in correct order or try again later.'),
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
                        fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
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
                                border: InputBorder.none,
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_isLoading)
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: SpinKitDoubleBounce(
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                    IconButton(
                                      icon: Icon(Icons.info, color: Colors.white),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16.0),
                                              ),
                                              title: Text(
                                                'Search engine is very flexible. How it works:',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontFamily: 'Helvetica',
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              content: Text(
                                                'To make it more precise put the city\'s name, comma, 2-letter country code (ISO3166). You will get all proper cities in chosen country.\n\nThe order is important - the first is city name then comma then country. Example - London, GB or New York, US.',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontFamily: 'Helvetica',
                                                  color: Colors.black, // Set the text color to black
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: Text(
                                                    'OK',
                                                    style: TextStyle(
                                                      color: const Color.fromARGB(255, 48, 107, 50), // Set the button text color to grey[900]
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              onChanged: _onSearchTextChanged,
                              onSubmitted: (value) {
                                _fetchWeatherByCity(value);
                              },
                              style: TextStyle(color: Colors.white),
                              cursorColor: Colors.white,
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
        body: Stack(
          children: [
            _currentIndex == 0
                ? Padding(
                    padding: EdgeInsets.only(top: 24.0), // Add padding to the top of the body
                    child: weatherBody(),
                  )
                : ForecastPage(weather: _weather), // Show ForecastPage when index is 1

            Visibility(
  visible: _showNoInternetDialog,
  child: AlertDialog(
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'No Connection',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Helvetica',
              fontSize: 22,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
            height: 200, // Adjust the height as per your requirement
            width: 200, // Adjust the width as per your requirement
            child: Image.asset('assets/error.png'),
          ),
          SizedBox(height: 8),
          Text(
            'Please connect to a network first.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Helvetica',
              fontSize: 18,
              color: Colors.black,
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () {
          setState(() {
            _showNoInternetDialog = false;
          });
        },
        child: Text(
          'OK',
        ),
      ),
    ],
  ),
),





          ],
        ),
        bottomNavigationBar: Stack(
          children: [
            BottomNavigationBar(
              onTap: onTabTapped,
              currentIndex: _currentIndex,
              backgroundColor: Colors.grey[900],
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white.withOpacity(0.5),
              showSelectedLabels: true,
              showUnselectedLabels: true,
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.cloud, color: Colors.white),
                  label: 'Weather',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.access_time, color: Colors.white),
                  label: 'Forecast',
                ),
              ],
              selectedIconTheme: IconThemeData(size: 30),
              unselectedIconTheme: IconThemeData(size: 25),
              selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
              selectedFontSize: 14,
              unselectedFontSize: 12,
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                color: Colors.transparent,
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: MediaQuery.of(context).size.width / 2,
                  margin: EdgeInsets.only(
                    left: _currentIndex == 0 ? 0 : MediaQuery.of(context).size.width / 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${_weather?.cityName ?? "Location"}, ${_weather?.countryName ?? ""}",
                  style: TextStyle(
                    fontFamily: 'Helvetica',
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(width: 5), // Add spacing between city name and flag
                if (_weather?.countryCode != null)
                  CountryFlag.fromCountryCode(
                    _weather!.countryCode.toLowerCase(),
                    width: 24,
                    height: 24,
                  ),
              ],
            ),
            Visibility(
              visible: _weather != null,
              child: Column(
                children: [
                  Lottie.asset(getWeatherAnimation(_weather?.mainCondition)),
                  SizedBox(height: 16), // Add vertical spacing between Lottie animation and temperature
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${_weather?.temperature.round()}°C",
                        style: TextStyle(
                          fontFamily: 'Helvetica',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2), // Add vertical spacing
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _weather?.mainCondition ?? "",
                        style: TextStyle(
                          fontFamily: 'Helvetica',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 8), // Add vertical spacing
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.water_drop,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Humidity: ${_weather?.humidity}%',
                        style: TextStyle(
                          fontFamily: 'Helvetica',
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4), // Add vertical spacing
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.speed,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Wind Speed: ${_weather?.windSpeed.toStringAsFixed(2)} km/h',
                        style: TextStyle(
                          fontFamily: 'Helvetica',
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
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
