import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/sasta_app_state.dart';
import '../../models/models.dart';
import '../../services/pincode_location_service.dart';
import '../../theme/sasta_theme.dart';
import '../../theme/sasta_tokens.dart';
import '../../widgets/sasta_background.dart';
import '../../widgets/sasta_components.dart';
import '../../widgets/sasta_mascot.dart';
import '../../widgets/sasta_sheets.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  bool _isDetecting = false;

  Future<void> _detectCurrentLocation() async {
    if (_isDetecting) return;
    setState(() => _isDetecting = true);
    final state = SastaScope.read(context);
    final result = await state.detectAndApplyCurrentLocation();
    if (!mounted) return;
    setState(() => _isDetecting = false);
    final resolved = result.resolved;
    if (resolved != null) {
      showSastaToast(
        context,
        'Location set to ${resolved.pincode} · ${resolved.displayArea}',
      );
    } else {
      showSastaToast(
        context,
        result.errorMessage ?? 'Could not detect location.',
      );
    }
  }

  Future<void> _openAddLocationSheet(
    BuildContext context, {
    SavedLocation? existing,
  }) async {
    final state = SastaScope.read(context);
    final labelCtrl = TextEditingController(text: existing?.label ?? '');
    final pinCtrl = TextEditingController(text: existing?.pincode ?? '');
    final areaCtrl = TextEditingController(text: existing?.area ?? '');
    var makeDefault = existing?.isDefault ?? true;
    var lookingUpPin = false;
    double? resolvedLat = existing?.lat;
    double? resolvedLng = existing?.lng;
    String? modalError;

    try {
      await showSastaSheet(
        context: context,
        builder: (ctx) {
          final palette = ctx.sasta;
          return StatefulBuilder(
            builder: (ctx, setModalState) {
              Future<void> handlePinChanged(String value) async {
                final trimmed = value.trim();
                if (modalError != null) {
                  setModalState(() => modalError = null);
                }
                if (existing == null || trimmed != existing.pincode) {
                  resolvedLat = null;
                  resolvedLng = null;
                }
                if (!PincodeLocationService.isValidPincode(trimmed)) return;
                setModalState(() => lookingUpPin = true);
                final resolved =
                    await state.locationService.lookupPincode(trimmed);
                if (!ctx.mounted) return;
                setModalState(() => lookingUpPin = false);
                if (resolved != null && pinCtrl.text.trim() == trimmed) {
                  areaCtrl.text = resolved.displayArea;
                  resolvedLat = resolved.lat;
                  resolvedLng = resolved.lng;
                }
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      existing == null ? 'Add new location' : 'Edit location',
                      style: SastaText.display(ctx, size: 22),
                    ),
                    const SizedBox(height: 14),
                    _ModalField(
                      controller: labelCtrl,
                      hint: 'Label (e.g. Home, Work)',
                    ),
                    const SizedBox(height: 10),
                    _ModalField(
                      controller: pinCtrl,
                      hint: '6-digit pincode',
                      digitsOnly: true,
                      maxLength: 6,
                      onChanged: (v) => unawaited(handlePinChanged(v)),
                    ),
                    const SizedBox(height: 10),
                    _ModalField(
                      controller: areaCtrl,
                      hint: lookingUpPin
                          ? 'Looking up area via India Post…'
                          : 'City / Area',
                    ),
                    if (modalError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        modalError!,
                        style: SastaText.body(
                          ctx,
                          size: 13,
                          color: palette.dangerText,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Set as default delivery address',
                            style: SastaText.body(
                              ctx,
                              size: 14,
                              weight: FontWeight.w600,
                              color: palette.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SastaSwitch(
                          value: makeDefault,
                          onChanged: (v) =>
                              setModalState(() => makeDefault = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SastaPrimaryButton(
                      label: existing == null
                          ? 'Save location'
                          : 'Update location',
                      onPressed: () {
                        final pin = pinCtrl.text.trim();
                        if (!PincodeLocationService.isValidPincode(pin)) {
                          setModalState(
                            () => modalError =
                                'Enter a valid 6-digit Indian pincode',
                          );
                          return;
                        }
                        final label = labelCtrl.text.trim().isEmpty
                            ? 'Saved place'
                            : labelCtrl.text.trim();
                        final area = areaCtrl.text.trim().isEmpty
                            ? 'India'
                            : areaCtrl.text.trim();
                        if (existing == null) {
                          state.addLocation(
                            label: label,
                            pincode: pin,
                            area: area,
                            lat: resolvedLat,
                            lng: resolvedLng,
                            makeDefault: makeDefault,
                          );
                        } else {
                          state.updateLocation(
                            SavedLocation(
                              id: existing.id,
                              label: label,
                              pincode: pin,
                              area: area,
                              isDefault: makeDefault,
                              lat: resolvedLat,
                              lng: resolvedLng,
                            ),
                          );
                          if (makeDefault) {
                            state.setDefaultLocation(existing.id);
                          }
                        }
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    } finally {
      labelCtrl.dispose();
      pinCtrl.dispose();
      areaCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = SastaScope.of(context);
    final palette = context.sasta;
    final active = state.activeLocation;

    return Scaffold(
      body: SastaBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              SastaSpace.page,
              14,
              SastaSpace.page,
              SastaSpace.bottomMargin,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SastaHeaderBar(title: 'Manage locations'),
                const SizedBox(height: 18),
                SastaCard(
                  color: palette.mint,
                  shadow: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delivering to ${active.pincode}',
                              style: SastaText.display(
                                context,
                                size: 22,
                                color: palette.successText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${active.label} · ${active.area}',
                              style: SastaText.body(
                                context,
                                size: 13,
                                weight: FontWeight.w600,
                                color: palette.successText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SastaMascot(
                        size: 62,
                        color: SastaColors.gold,
                        expression: MascotExpression.joy,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('SAVED LOCATIONS', style: SastaText.eyebrow(context)),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: state.locations.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 10, color: palette.divider),
                    itemBuilder: (context, i) {
                      final loc = state.locations[i];
                      return InkWell(
                        onTap: () {
                          state.setDefaultLocation(loc.id);
                          showSastaToast(
                            context,
                            'Switched delivery to ${loc.pincode}',
                          );
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: loc.isDefault
                                      ? palette.mint
                                      : palette.field,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.location_on_outlined,
                                  color: loc.isDefault
                                      ? palette.successText
                                      : palette.muted,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            loc.label,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: SastaText.body(
                                              context,
                                              size: 15,
                                              weight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        if (loc.isDefault) ...[
                                          const SizedBox(width: 8),
                                          SastaTag(
                                            label: 'Default',
                                            backgroundColor: palette.mint,
                                            textColor: palette.successText,
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      '${loc.pincode} · ${loc.area}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: SastaText.muted(context, size: 12),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.all(6),
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                                onPressed: () => _openAddLocationSheet(
                                  context,
                                  existing: loc,
                                ),
                                icon: Icon(
                                  Icons.edit_outlined,
                                  size: 19,
                                  color: palette.muted,
                                ),
                              ),
                              if (state.locations.length > 1)
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.all(6),
                                  constraints: const BoxConstraints(
                                    minWidth: 36,
                                    minHeight: 36,
                                  ),
                                  onPressed: () => state.deleteLocation(loc.id),
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    size: 19,
                                    color: palette.dangerText,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                SastaPrimaryButton(
                  label: 'Add new location',
                  onPressed: () => _openAddLocationSheet(context),
                ),
                const SizedBox(height: 8),
                SastaOutlineButton(
                  label: _isDetecting
                      ? 'Detecting location…'
                      : 'Detect current location',
                  height: 48,
                  onPressed: _isDetecting ? null : _detectCurrentLocation,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModalField extends StatelessWidget {
  const _ModalField({
    required this.controller,
    required this.hint,
    this.digitsOnly = false,
    this.maxLength,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final bool digitsOnly;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: palette.field,
        borderRadius: BorderRadius.circular(26),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: digitsOnly ? TextInputType.number : TextInputType.text,
        inputFormatters: [
          if (digitsOnly) FilteringTextInputFormatter.digitsOnly,
          if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
        ],
        style: SastaText.body(context, size: 15, weight: FontWeight.w600),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: hint,
          hintStyle: SastaText.muted(context, size: 14),
        ),
      ),
    );
  }
}
