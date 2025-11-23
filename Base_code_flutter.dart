import 'package:flutter/material.dart';
import 'dart:async'; // For Timer (replacing Kivy Clock)
import 'dart:math';  // For Random simulation
import 'package:flutter_map/flutter_map.dart'; // OpenStreetMap wrapper
import 'package:latlong2/latlong.dart'; // For LatLng coordinates

void main() {
  runApp(const WBANApp());
}

class WBANApp extends StatelessWidget {
  const WBANApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WBAN Monitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1F1F1F), // ~0.12, 0.12, 0.12
        primaryColor: const Color(0xFF142647), // ~0.08, 0.15, 0.28 (Navy)
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF142647),
          elevation: 4,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF142647),
          secondary: Color(0xFF4D80B3), // Steel Blue
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  // State Variables
  String _tempValue = "--.- °C";
  String _epilepsyStatus = "Waiting...";
  String _fallStatus = "Waiting...";
  Color _fallColor = Colors.grey;
  String _tempState = "Waiting...";
  
  Timer? _timer;
  late TabController _tabController;

  // Firebase placeholder (similar to your python code)
  // final databaseReference = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Equivalent to Kivy Clock.schedule_interval
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _updateData() {
    setState(() {
      // --- SIMULATED DATA ---
      final random = Random();
      
      // Temperature
      int mainTemp = 36 + random.nextInt(2); // 36-38
      int decTemp = random.nextInt(10);
      _tempValue = "$mainTemp.$decTemp °C";

      // Epilepsy
      List<String> epStates = ["Normal", "Normal", "Seizure (S)"];
      _epilepsyStatus = epStates[random.nextInt(epStates.length)];

      // Gyro / Fall
      // Logic: In Kivy you checked if val > 0.5. Here we simulate stable/fall
      bool isStable = random.nextDouble() > 0.1; // 90% chance stable
      if (isStable) {
        _fallStatus = "Stable";
        _fallColor = const Color(0xFF4CAF50); // Bright Green
      } else {
        _fallStatus = "FALL DETECTED";
        _fallColor = const Color(0xFFEF5350); // Bright Red
      }

      // Temp State
      _tempState = "Normal";
    });
  }

  void _verifyAction() {
    print("Security: Sending verification request...");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Security: Sending verification request...")),
    );
  }

  void _recalibrateAction() {
    print("System: Recalibrating Sensors...");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("System: Recalibrating Sensors...")),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Custom Colors matching your Kivy code
    final navyBlue = const Color(0xFF142647); 
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("WBAN Monitor", style: TextStyle(color: Color(0xFFE6E6E6))),
        backgroundColor: navyBlue,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.map), text: "Map"),
            Tab(icon: Icon(Icons.security), text: "Shield"),
            Tab(icon: Icon(Icons.monitor_heart), text: "Vitals"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe to match Kivy feel
        children: [
          // --- SCREEN 1: MAP ---
          _buildMapTab(),

          // --- SCREEN 2: SHIELD ---
          _buildShieldTab(),

          // --- SCREEN 3: VITALS ---
          _buildVitalsTab(),
        ],
      ),
    );
  }

  // --- TAB 1: MAP VIEW ---
  Widget _buildMapTab() {
    return FlutterMap(
      options: MapOptions(
        initialCenter: const LatLng(51.5074, -0.1278), // London
        initialZoom: 12.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.wban.app',
        ),
      ],
    );
  }

  // --- TAB 2: SHIELD ---
  Widget _buildShieldTab() {
    return Container(
      color: const Color(0xFF1F1F1F), // Dark Grey
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.admin_panel_settings, // Shield Account icon
              size: 150,
              color: Color(0xFF4D80B3), // Steel Blue
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              height: 50,
              child: ElevatedButton(
                onPressed: _verifyAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF142647), // Navy Blue
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text(
                  "CROSS VERIFY DATA",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 3: VITALS ---
  Widget _buildVitalsTab() {
    return Container(
      color: const Color(0xFF1F1F1F), // Dark Grey
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Temperature Card
          Card(
            color: const Color(0xFF2E2E2E), // Charcoal Grey
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: double.infinity,
              height: 120,
              padding: const EdgeInsets.all(15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Body Temperature",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _tempValue,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Status Rows
          StatusRow(
            title: "Epilepsy",
            value: _epilepsyStatus,
            icon: Icons.psychology, // Brain
          ),
          const SizedBox(height: 15),
          StatusRow(
            title: "Fall Status",
            value: _fallStatus,
            valueColor: _fallColor,
            icon: Icons.directions_run, // Run fast
          ),
          const SizedBox(height: 15),
          StatusRow(
            title: "Temp State",
            value: _tempState,
            icon: Icons.thermostat, // Thermometer
          ),

          const Spacer(),

          // Recalibrate Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _recalibrateAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF33404D), // Dark Grey/Blue
                elevation: 4,
              ),
              child: const Text(
                "RECALIBRATE SENSORS",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- CUSTOM WIDGET: StatusRow ---
class StatusRow extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color valueColor;

  const StatusRow({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.valueColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          // Icon
          Icon(icon, color: const Color(0xFF4D80B3)), // Steel Blue
          const SizedBox(width: 10),
          
          // Title
          Expanded(
            flex: 4,
            child: Text(
              title,
              style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 16),
            ),
          ),

          // Value Card
          Expanded(
            flex: 6,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2E2E2E), // Charcoal Grey
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                   BoxShadow(
                    color: Colors.black26,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}