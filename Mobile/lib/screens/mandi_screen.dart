import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'dart:math';

class MandiScreen extends StatefulWidget {
  const MandiScreen({super.key});

  @override
  State<MandiScreen> createState() => _MandiScreenState();
}

class _MandiScreenState extends State<MandiScreen> {
  // Form Controllers
  final _stateController = TextEditingController();
  final _districtController = TextEditingController();
  final _talukController = TextEditingController();
  final _villageController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _cropController = TextEditingController();

  bool _isLoading = false;
  bool _showResult = false;
  String? _predictedPrice;
  double _priceChange = 0.0;

  @override
  void dispose() {
    _stateController.dispose();
    _districtController.dispose();
    _talukController.dispose();
    _villageController.dispose();
    _pincodeController.dispose();
    _cropController.dispose();
    super.dispose();
  }

  void _predictPrice() async {
    // Basic validation
    if (_cropController.text.isEmpty || _stateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Crop and State')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _showResult = false;
    });

    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Simulate result based on input
    final random = Random();
    final basePrice = 20 + random.nextInt(40); // 20-60
    final change = (random.nextDouble() * 20) - 5; // -5% to +15%

    setState(() {
      _isLoading = false;
      _showResult = true;
      _predictedPrice = '₹$basePrice/kg';
      _priceChange = change;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Mandi Price Predictor 📈',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get accurate price predictions for your location',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textMuted,
              ),
            ),

            const SizedBox(height: 24),

            // Prediction Form
            _buildPredictionForm(),

            const SizedBox(height: 24),

            // Result Section
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: AppTheme.accentGreen))
            else if (_showResult)
              _buildAnalysisResult(),

            const SizedBox(height: 32),

            // Market Insights (Static for now)
            if (!_showResult) ...[
              const Text(
                'Market Trends (General)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildChartPlaceholder(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField('Crop Name *', 'e.g. Tomato, Paddy', _cropController, Icons.grass),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTextField('State *', 'Tamil Nadu', _stateController, Icons.map)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('District', 'Salem', _districtController, Icons.location_city)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTextField('Taluk', 'Omalur', _talukController, Icons.place)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('Village', 'Kadayampatti', _villageController, Icons.home_work)),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField('Pincode', '636309', _pincodeController, Icons.pin_drop, isNumber: true),
          
          const SizedBox(height: 24),
          
          ElevatedButton(
            onPressed: _predictPrice,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              shadowColor: AppTheme.accentGreen.withValues(alpha: 0.4),
            ),
            child: const Text(
              'Predict Price 🚀',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, IconData icon, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.5), fontSize: 13),
            prefixIcon: Icon(icon, color: AppTheme.accentGreen, size: 20),
            filled: true,
            fillColor: AppTheme.primaryBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisResult() {
    final isPositive = _priceChange >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentGreen.withValues(alpha: 0.15),
            AppTheme.surfaceColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
                  ],
                ),
                child: const Text('💰', style: TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Predicted for ${_cropController.text}',
                      style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
                    ),
                    Text(
                      '${_villageController.text.isNotEmpty ? _villageController.text : _districtController.text.isNotEmpty ? _districtController.text : "Your Location"} Market',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Expected Price', style: TextStyle(color: AppTheme.textMuted)),
                  const SizedBox(height: 4),
                  Text(
                    _predictedPrice ?? '₹--',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.accentGreen,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isPositive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      color: isPositive ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_priceChange.abs().toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Analysis based on historical data from ${_stateController.text} and local weather patterns.',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildChartPlaceholder() {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.textMuted.withValues(alpha: 0.1)),
      ),
      child: Center(
        child: Text(
          'Chart requires prediction data',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      ),
    );
  }
}
