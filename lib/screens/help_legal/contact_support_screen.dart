import 'package:flutter/material.dart';

import '../../data/sasta_app_state.dart';
import '../../theme/sasta_theme.dart';
import '../../theme/sasta_tokens.dart';
import '../../widgets/sasta_background.dart';
import '../../widgets/sasta_components.dart';

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  static const _topics = [
    'Incorrect price',
    'Incorrect availability',
    'Product information',
    'Location issue',
    'Retailer redirection',
    'Basket comparison',
    'Price alert',
    'Sasta+ subscription',
    'Payment issue',
    'General feedback',
  ];

  String _selectedTopic = 'Incorrect price';
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _hasAttachment = false;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_messageCtrl.text.trim().isEmpty) {
      showSastaToast(context, 'Please add a short message so we can help.');
      return;
    }
    SastaScope.read(context).submitSupportTicket(
      topic: _selectedTopic,
      subject: _subjectCtrl.text,
      message: _messageCtrl.text,
    );
    _subjectCtrl.clear();
    _messageCtrl.clear();
    setState(() => _hasAttachment = false);
    FocusScope.of(context).unfocus();
    showSastaToast(context, 'Request submitted. We’ll update you soon.');
  }

  @override
  Widget build(BuildContext context) {
    final state = SastaScope.of(context);
    final palette = context.sasta;

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
                const SastaHeaderBar(title: 'Contact support'),
                const SizedBox(height: 18),
                Text(
                  'WHAT IS IT ABOUT?',
                  style: SastaText.eyebrow(context),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final topic in _topics)
                      SastaChip(
                        label: topic,
                        selected: _selectedTopic == topic,
                        height: 38,
                        onTap: () => setState(() => _selectedTopic = topic),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _subjectCtrl,
                  textInputAction: TextInputAction.next,
                  style: SastaText.body(
                    context,
                    size: 15,
                    weight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Subject',
                    filled: true,
                    fillColor: palette.field,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(SastaRadius.pill),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _messageCtrl,
                  minLines: 4,
                  maxLines: 6,
                  style: SastaText.body(
                    context,
                    size: 15,
                    weight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Describe the issue or share platform details…',
                    filled: true,
                    fillColor: palette.field,
                    contentPadding: const EdgeInsets.all(18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(SastaRadius.card),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    setState(() => _hasAttachment = !_hasAttachment);
                    showSastaToast(
                      context,
                      _hasAttachment
                          ? 'Attached sample screenshot: basket_compare.png'
                          : 'Attachment removed',
                    );
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: _hasAttachment ? palette.lavender : palette.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _hasAttachment
                            ? palette.lavenderText
                            : palette.divider,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _hasAttachment
                              ? Icons.check_circle_outline_rounded
                              : Icons.add_photo_alternate_outlined,
                          size: 20,
                          color: _hasAttachment
                              ? palette.lavenderText
                              : palette.ink,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _hasAttachment
                                ? 'basket_compare.png attached (tap to remove)'
                                : '+ Attach a screenshot (optional)',
                            style: SastaText.body(
                              context,
                              size: 13,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SastaPrimaryButton(
                  label: 'Submit request',
                  onPressed: _submit,
                ),
                const SizedBox(height: 10),
                SastaOutlineButton(
                  label: 'Open email support ↗',
                  height: 48,
                  onPressed: () async {
                    final subject = _subjectCtrl.text.trim().isEmpty
                        ? 'Sasta Support: $_selectedTopic'
                        : _subjectCtrl.text.trim();
                    final body = _messageCtrl.text.trim().isEmpty
                        ? 'Hi Sasta team,\n\nI need help with $_selectedTopic.'
                        : _messageCtrl.text.trim();
                    final launched = await state.retailerLauncher.openSupportEmail(
                      subject: subject,
                      body: body,
                    );
                    if (!context.mounted) return;
                    if (!launched) {
                      showSastaToast(
                        context,
                        'Email support@sastaapp.in or submit above.',
                      );
                    }
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'PREVIOUS REQUESTS',
                  style: SastaText.eyebrow(context),
                ),
                const SizedBox(height: 10),
                for (final ticket in state.supportTickets) ...[
                  SastaCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ticket.subject,
                                style: SastaText.body(
                                  context,
                                  size: 15,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${ticket.topic} · ${ticket.dateLabel}',
                                style: SastaText.muted(context, size: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        SastaTag(
                          label: ticket.status,
                          backgroundColor: ticket.status == 'Resolved'
                              ? palette.mint
                              : palette.butter,
                          textColor: ticket.status == 'Resolved'
                              ? palette.successText
                              : palette.warningText,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
