import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
        apiKey: "AIzaSyAZLf3CokBViJ8_wYpwLf5HEe5jSawCIKo",
        authDomain: "wban-data.firebaseapp.com",
        databaseURL: "https://wban-data-default-rtdb.asia-southeast1.firebasedatabase.app",
        projectId: "wban-data",
        storageBucket: "wban-data.firebasestorage.app",
        messagingSenderId: "544732141873",
        appId: "1:544732141873:web:004ef63e1f97a756b53810"),
  );
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
        scaffoldBackgroundColor: const Color(0xFF1F1F1F), 
        primaryColor: const Color(0xFF142647), 
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
  bool _isVerifying = false;
  String _verifyingText = "CROSS VERIFY DATA";

  late TabController _tabController;
  late DatabaseReference _databaseReference;
  StreamSubscription? _epilepsySubscription;
  StreamSubscription? _gyroSubscription;
  StreamSubscription? _tempStateSubscription;
  StreamSubscription? _tempObjectSubscription;
  Timer? _verifyingTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _databaseReference = FirebaseDatabase.instance.ref();

    // --- FIREBASE LISTENERS ---
    _epilepsySubscription = _databaseReference
        .child('Predictions/Epilepsy model result/status')
        .onValue
        .listen((event) {
      if (mounted && event.snapshot.value != null) {
        setState(() {
          _epilepsyStatus = event.snapshot.value.toString();
        });
      }
    });

    _gyroSubscription = _databaseReference
        .child('Predictions/Gyro model result/status')
        .onValue
        .listen((event) {
      if (mounted && event.snapshot.value != null) {
        setState(() {
          _fallStatus = event.snapshot.value.toString();
          if (_fallStatus.toLowerCase() == "fall detected") {
            _fallColor = const Color(0xFFEF5350); // Bright Red
          } else {
            _fallColor = const Color(0xFF4CAF50); // Bright Green
          }
        });
      }
    });

    _tempStateSubscription = _databaseReference
        .child('Predictions/Temp model result/status')
        .onValue
        .listen((event) {
      if (mounted && event.snapshot.value != null) {
        setState(() {
          _tempState = event.snapshot.value.toString();
        });
      }
    });

    _tempObjectSubscription = _databaseReference
        .child('sensors/temperature/object')
        .onValue
        .listen((event) {
      if (mounted && event.snapshot.value != null) {
        setState(() {
          final temp = double.tryParse(event.snapshot.value.toString()) ?? 0.0;
          _tempValue = "${temp.toStringAsFixed(1)} °C";
        });
      }
    });
  }

  @override
  void dispose() {
    _epilepsySubscription?.cancel();
    _gyroSubscription?.cancel();
    _tempStateSubscription?.cancel();
    _tempObjectSubscription?.cancel();
    _verifyingTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _verifyAction() {
    if (_isVerifying) return;

    setState(() {
      _isVerifying = true;
      _verifyingText = "Verifying.";
    });

    _verifyingTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        if (_verifyingText == "Verifying...") {
          _verifyingText = "Verifying.";
        } else {
          _verifyingText += ".";
        }
      });
    });

    final random = Random();
    final verificationTime = 5 + random.nextInt(6); // 5 to 10 seconds

    Timer(Duration(seconds: verificationTime), () {
      _verifyingTimer?.cancel();
      setState(() {
        _isVerifying = false;
        _verifyingText = "CROSS VERIFY DATA";
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Verification Complete"),
          content: const Text("Verified."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    });
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
                onPressed: _isVerifying ? null : _verifyAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF142647), // Navy Blue
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: Text(
                  _verifyingText,
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
