import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/weather_data.dart';
import 'utils/weather_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const WeatherScreen(),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController _indexController = TextEditingController(text: '224097E');
  
  double? _latitude;
  double? _longitude;
  String? _requestUrl;
  WeatherData? _weatherData;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _calculateCoordinates();
    _loadCachedData();
  }

  void _calculateCoordinates() {
    final index = _indexController.text.trim();
    if (index.length >= 4) {
      try {
        final coords = WeatherService.deriveCoordinates(index);
        setState(() {
          _latitude = coords['lat'];
          _longitude = coords['lon'];
          _requestUrl = WeatherService.buildRequestUrl(_latitude!, _longitude!);
          _errorMessage = null;
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'Invalid index format';
          _latitude = null;
          _longitude = null;
          _requestUrl = null;
        });
      }
    }
  }

  Future<void> _loadCachedData() async {
    final cached = await WeatherService.getCachedWeather();
    if (cached != null && _weatherData == null) {
      setState(() {
        _weatherData = cached;
      });
    }
  }

  Future<void> _fetchWeather() async {
    if (_latitude == null || _longitude == null) {
      setState(() {
        _errorMessage = 'Please enter a valid student index';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final weatherData = await WeatherService.fetchWeather(_latitude!, _longitude!);
      setState(() {
        _weatherData = weatherData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to fetch weather. ${_weatherData?.isCached == true ? 'Showing cached data.' : 'Please check your internet connection.'}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Weather App'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Student Index Input
            TextField(
              controller: _indexController,
              decoration: const InputDecoration(
                labelText: 'Student Index',
                border: OutlineInputBorder(),
                hintText: 'e.g., 224097E',
              ),
              onChanged: (value) => _calculateCoordinates(),
            ),
            const SizedBox(height: 16),

            // Coordinates Display
            if (_latitude != null && _longitude != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coordinates',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Latitude: ${_latitude!.toStringAsFixed(2)}°'),
                      Text('Longitude: ${_longitude!.toStringAsFixed(2)}°'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Fetch Weather Button
            ElevatedButton(
              onPressed: _isLoading ? null : _fetchWeather,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Fetch Weather'),
            ),
            const SizedBox(height: 16),

            // Error Message
            if (_errorMessage != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Weather Data Display
            if (_weatherData != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Current Weather',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_weatherData!.isCached)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'CACHED',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildWeatherRow(
                        Icons.thermostat,
                        'Temperature',
                        '${_weatherData!.temperature.toStringAsFixed(1)}°C',
                      ),
                      const SizedBox(height: 12),
                      _buildWeatherRow(
                        Icons.air,
                        'Wind Speed',
                        '${_weatherData!.windSpeed.toStringAsFixed(1)} km/h',
                      ),
                      const SizedBox(height: 12),
                      _buildWeatherRow(
                        Icons.cloud,
                        'Weather Code',
                        _weatherData!.weatherCode.toString(),
                      ),
                      const SizedBox(height: 12),
                      _buildWeatherRow(
                        Icons.access_time,
                        'Last Updated',
                        DateFormat('yyyy-MM-dd HH:mm:ss').format(_weatherData!.lastUpdated),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Request URL Display
            if (_requestUrl != null)
              Card(
                color: Colors.grey.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Request URL:',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        _requestUrl!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue.shade700),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _indexController.dispose();
    super.dispose();
  }
}
