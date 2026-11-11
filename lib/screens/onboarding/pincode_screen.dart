import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/sasta_app_state.dart';
import '../../theme/sasta_theme.dart';
import '../../theme/sasta_tokens.dart';
import '../../widgets/product_art.dart';
import '../../widgets/sasta_background.dart';
import '../../widgets/sasta_components.dart';
import '../../widgets/sasta_motion.dart';

class PincodeScreen extends StatefulWidget {
  const PincodeScreen({
    super.key,
    this.isModalPicker = false,
  });

  final bool isModalPicker;

  @override
  State<PincodeScreen> createState() => _PincodeScreenState();
}

class _PincodeScreenState extends State<PincodeScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;
  String _selectedArea = 'Central Delhi';

  static const _quickPresets = [
    (pin: '110001', area: 'Central Delhi'),
    (pin: '560001', area: 'Bengaluru'),
    (pin: '400001', area: 'Mumbai'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.length != 6) {
      setState(() => _errorText = 'Please enter a valid 6-digit pincode');
      return;
    }
    final area = switch (text) {
      '560001' => 'Bengaluru',
      '400001' => 'Mumbai',
      _ => _selectedArea,
    };
    SastaScope.read(context).completePincode(text, area: area);
    if (widget.isModalPicker && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _detectLocation() {
    setState(() {
      _controller.text = '110001';
      _selectedArea = 'Central Delhi';
      _errorText = null;
    });
    showSastaToast(context, 'Detected 110001 · Central Delhi');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    final state = SastaScope.read(context);

    return Scaffold(
      body: SastaBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              SastaSpace.page,
              14,
              SastaSpace.page,
              SastaSpace.bottomMargin,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 96,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SastaBackButton(
                        onPressed: () {
                          if (widget.isModalPicker) {
                            Navigator.of(context).pop();
                          } else if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            SastaScope.read(context).reopenOnboarding();
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Center(
                      child: FloatBob(
                        amplitude: 7,
                        child: PincodePinIllustration(size: 205),
                      ),
                    ),
                    const SizedBox(height: 22),
                    FadeUp(
                      child: Text(
                        'Where should we\ndeliver?',
                        style: SastaText.display(context, size: 34),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeUp(
                      delay: const Duration(milliseconds: 70),
                      child: Text(
                        'Enter your 6-digit pincode to see prices and stock across quick-commerce stores near you.',
                        style: SastaText.muted(context, size: 15, height: 1.45),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: SastaSizes.input,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: palette.field,
                        borderRadius: BorderRadius.circular(SastaRadius.pill),
                        border: _errorText != null
                            ? Border.all(color: palette.dangerText, width: 1.5)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 22,
                            color: palette.muted,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              onChanged: (_) {
                                if (_errorText != null) {
                                  setState(() => _errorText = null);
                                }
                              },
                              onSubmitted: (_) => _submit(),
                              style: SastaText.body(
                                context,
                                size: 16,
                                weight: FontWeight.w700,
                                tabular: true,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Enter 6-digit pincode',
                                hintStyle: SastaText.body(
                                  context,
                                  size: 15,
                                  weight: FontWeight.w600,
                                  color: palette.muted,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_errorText != null) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(
                          _errorText!,
                          style: SastaText.body(
                            context,
                            size: 12,
                            weight: FontWeight.w600,
                            color: palette.dangerText,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _quickPresets.map((preset) {
                        final isSelected = _controller.text == preset.pin;
                        return SastaChip(
                          label: '${preset.pin} · ${preset.area}',
                          selected: isSelected,
                          onTap: () => setState(() {
                            _controller.text = preset.pin;
                            _selectedArea = preset.area;
                            _errorText = null;
                          }),
                        );
                      }).toList(),
                    ),
                    const Spacer(),
                    const SizedBox(height: 20),
                    SastaPrimaryButton(
                      label: 'Continue',
                      onPressed: () {
                        if (_controller.text.trim().isEmpty &&
                            !widget.isModalPicker) {
                          _controller.text = state.activeLocation.pincode;
                        }
                        _submit();
                      },
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: TextButton.icon(
                        onPressed: _detectLocation,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(160, 48),
                          foregroundColor: palette.ink,
                        ),
                        icon: const Icon(Icons.my_location_rounded, size: 18),
                        label: Text(
                          'Use my current location',
                          style: SastaText.body(
                            context,
                            size: 15,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
