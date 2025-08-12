import 'package:checking_app/screens/foodcheck_screen.dart';
import 'package:checking_app/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class EntryCheckScreen extends StatefulWidget {
  const EntryCheckScreen({super.key});

  @override
  State<EntryCheckScreen> createState() => EntryCheckScreenState();
}

class EntryCheckScreenState extends State<EntryCheckScreen> {
  late MobileScannerController cameraController;
  bool _isScanning = false;
  bool _torchEnabled = false;
  final CameraFacing _cameraFacing = CameraFacing.back;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: _cameraFacing,
      torchEnabled: _torchEnabled,
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
      }
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String? _extractUuidFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      if (pathSegments.length >= 3 &&
          pathSegments[0] == 'api' &&
          pathSegments[2] == 'checkin') {
        return pathSegments[1];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  bool _isValidUuid(String uuid) {
    final regex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return regex.hasMatch(uuid);
  }

  void _handleBarcode(BarcodeCapture barcodes) async {
    if (!_isScanning) {
      setState(() => _isScanning = true);

      final String? scannedValue = barcodes.barcodes.firstOrNull?.rawValue;

      if (scannedValue != null) {
        try {
          HapticFeedback.lightImpact();
          final uuid = _extractUuidFromUrl(scannedValue) ?? scannedValue;

          if (!_isValidUuid(uuid)) {
            throw 'Invalid QR code format';
          }

          final result = await _apiService.checkInAttendee(uuid);

          if (result['status'] == 'already_checked_in') {
            _showAlreadyCheckedIn();
          } else {
            _showScanSuccess();
          }
        } catch (e) {
          _showScanError(scannedValue, e.toString());
        }
      } else {
        _showScanError(null, 'No QR code detected');
      }
    }
  }

  void _showAlreadyCheckedIn() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.info_outline, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              'Already Checked In',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.orange[800],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This attendee was previously checked in',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CLOSE'),
              ),
            ),
          ],
        ),
      ),
    ).then((_) => setState(() => _isScanning = false));
  }

  void _showScanSuccess() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Checkin Successful!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.green[800],
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text(
                  'DONE',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((_) => setState(() => _isScanning = false));
  }

  void _showScanError(String? code, String error) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Checkin Failed',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.red[800],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              code != null ? 'Error: $error' : 'No QR code detected',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Try again',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((_) => setState(() => _isScanning = false));
  }

  void _toggleTorch() {
    setState(() => _torchEnabled = !_torchEnabled);
    cameraController.toggleTorch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.fastfood_outlined),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const FoodCheckScreen()),
                );
              },
              tooltip: 'Logout',
              color: Colors.white,
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all<Color>(
                  // ignore: deprecated_member_use
                  Colors.green,
                ),
              ),
            ),
            const Text('Entry check'),
            IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _torchEnabled ? Icons.flash_on : Icons.flash_off,
                  key: ValueKey(_torchEnabled),
                  color: _torchEnabled
                      ? Theme.of(context).colorScheme.primary
                      : Colors.black,
                ),
              ),
              onPressed: _toggleTorch,
            ),
            IconButton(
              icon: Icon(Icons.logout_outlined),
              onPressed: _showLogoutConfirmation,
              tooltip: 'Logout',
              color: Colors.white,
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all<Color>(
                  // ignore: deprecated_member_use
                  Colors.red,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        actionsPadding: EdgeInsets.only(right: 10, left: 10),
      ),
      body: Stack(
        children: [
          MobileScanner(controller: cameraController, onDetect: _handleBarcode),
          _buildScannerOverlay(context),
          _buildInstructionText(),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay(BuildContext context) {
    return Center(
      child: CustomPaint(
        painter: _ModernScannerOverlay(
          scanAreaSize: MediaQuery.of(context).size.width * 0.8,
          borderColor: Colors.green,
        ),
      ),
    );
  }

  Widget _buildInstructionText() {
    return Positioned(
      bottom: 48,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Align QR code within frame',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              shadows: [
                // ignore: deprecated_member_use
                Shadow(blurRadius: 8, color: Colors.black.withOpacity(0.8)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernScannerOverlay extends CustomPainter {
  final double scanAreaSize;
  final Color borderColor;

  const _ModernScannerOverlay({
    required this.scanAreaSize,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      // ignore: deprecated_member_use
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final backgroundPath = Path()
      ..addRect(Rect.fromLTRB(0, 0, size.width, size.height));

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scanAreaRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: scanAreaSize,
      height: scanAreaSize,
    );

    final scanAreaPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(scanAreaRect, const Radius.circular(16)),
      );

    backgroundPath.addPath(scanAreaPath, Offset.zero);
    backgroundPath.fillType = PathFillType.evenOdd;

    canvas.drawPath(backgroundPath, backgroundPaint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        scanAreaRect.deflate(1.5),
        const Radius.circular(16),
      ),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
