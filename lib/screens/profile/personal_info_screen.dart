import 'package:flutter/material.dart';

import '../../data/sasta_app_state.dart';
import '../../theme/sasta_theme.dart';
import '../../theme/sasta_tokens.dart';
import '../../widgets/sasta_background.dart';
import '../../widgets/sasta_components.dart';
import '../../widgets/sasta_mascot.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final state = SastaScope.read(context);
      _nameCtrl = TextEditingController(text: state.fullName);
      _emailCtrl = TextEditingController(text: state.email);
      _phoneCtrl = TextEditingController(text: state.phone);
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = SastaScope.of(context);
    final palette = context.sasta;
    final avatarColor = switch (state.avatarStyleIndex % 4) {
      1 => SastaColors.zepto,
      2 => SastaColors.blinkit,
      3 => SastaColors.instamart,
      _ => SastaColors.flipkartMinutes,
    };
    final avatarExpression = switch (state.avatarStyleIndex % 4) {
      1 => MascotExpression.happy,
      2 => MascotExpression.calm,
      3 => MascotExpression.joy,
      _ => MascotExpression.joy,
    };
    final avatarHalo = switch (state.avatarStyleIndex % 4) {
      1 => palette.lavender,
      2 => palette.butter,
      3 => palette.peach,
      _ => palette.sky,
    };

    return Scaffold(
      body: SastaBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              SastaSpace.page,
              14,
              SastaSpace.page,
              SastaSpace.bottomMargin,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SastaHeaderBar(title: 'Personal information'),
                const SizedBox(height: 18),
                Center(
                  child: Semantics(
                    button: true,
                    label: 'Change avatar style',
                    child: GestureDetector(
                      onTap: () {
                        state.cycleAvatarStyle();
                        showSastaToast(context, 'Avatar style updated');
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          SastaMascot(
                            size: 98,
                            color: avatarColor,
                            expression: avatarExpression,
                            haloColor: avatarHalo,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: palette.primaryCtaBg,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: palette.screen,
                                  width: 2.5,
                                ),
                              ),
                              child: Icon(
                                Icons.edit_rounded,
                                size: 16,
                                color: palette.primaryCtaFg,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                _LabeledInput(
                  label: 'Full name',
                  controller: _nameCtrl,
                  hint: 'Enter your name',
                ),
                const SizedBox(height: 14),
                _LabeledInput(
                  label: 'Email address',
                  controller: _emailCtrl,
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                _LabeledInput(
                  label: 'Mobile number',
                  controller: _phoneCtrl,
                  hint: '+91 98765 43210',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 18),
                SastaCard(
                  color: palette.lavender,
                  shadow: false,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Member since',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: SastaText.muted(context, size: 13),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Nov 2026',
                            style: SastaText.body(
                              context,
                              size: 14,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Account status',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: SastaText.muted(context, size: 13),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SastaTag(
                            label: 'Active',
                            backgroundColor: palette.mint,
                            textColor: palette.successText,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SastaPrimaryButton(
                  label: 'Save changes',
                  onPressed: () {
                    final name = _nameCtrl.text.trim();
                    final email = _emailCtrl.text.trim();
                    final phone = _phoneCtrl.text.trim();
                    if (name.isEmpty) {
                      showSastaToast(context, 'Enter your name');
                      return;
                    }
                    if (email.isNotEmpty &&
                        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(email)) {
                      showSastaToast(context, 'Enter a valid email address');
                      return;
                    }
                    final phoneDigits =
                        phone.replaceAll(RegExp(r'[^0-9]'), '');
                    if (phone.isNotEmpty && phoneDigits.length < 10) {
                      showSastaToast(context, 'Enter a valid mobile number');
                      return;
                    }
                    state.updateProfile(
                      name: name,
                      email: email,
                      phone: phone,
                    );
                    Navigator.of(context).pop();
                    showSastaToast(context, 'Profile updated');
                  },
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: SastaText.body(
                        context,
                        size: 15,
                        weight: FontWeight.w700,
                        color: palette.muted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LabeledInput extends StatelessWidget {
  const _LabeledInput({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 6),
          child: Text(
            label,
            style: SastaText.muted(context, size: 12, weight: FontWeight.w700),
          ),
        ),
        Container(
          height: SastaSizes.input,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: palette.field,
            borderRadius: BorderRadius.circular(SastaRadius.pill),
          ),
          alignment: Alignment.center,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: SastaText.body(context, size: 15, weight: FontWeight.w600),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              hintText: hint,
              hintStyle: SastaText.muted(context, size: 15),
            ),
          ),
        ),
      ],
    );
  }
}
