import 'package:flutter/material.dart';
import 'package:myorders_core/myorders_core.dart';
import 'package:provider/provider.dart';

import '../widgets/common.dart';

/// "Become a partner" pitch and sign-up form for stores.
class PartnerScreen extends StatefulWidget {
  const PartnerScreen({super.key});

  @override
  State<PartnerScreen> createState() => _PartnerScreenState();
}

class _PartnerScreenState extends State<PartnerScreen> {
  final _form = GlobalKey<FormState>();
  final _business = TextEditingController();
  final _contact = TextEditingController();
  final _phone = TextEditingController();
  final _notes = TextEditingController();
  Section _section = Section.food;
  bool _sending = false;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      await context.read<MyOrdersRepository>().submitPartnerApplication(
        businessName: _business.text.trim(),
        contactName: _contact.text.trim(),
        phone: _phone.text.trim(),
        section: _section,
        notes: _notes.text.trim(),
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(context.t('applicationSent')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(context.t('close'))),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    for (final c in [_business, _contact, _phone, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String? required(String? v) => (v ?? '').trim().isEmpty ? context.t('required') : null;
    return Scaffold(
      appBar: AppBar(title: Text(context.t('becomePartner'))),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PhotoBanner(
              image: AppImages.partner,
              title: context.t('partnerPitch'),
              body: context.t('partnerPitchBody'),
              height: 170,
            ),
            const SizedBox(height: 16),
            for (final section in Section.values)
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: _section == section ? AppColors.teal : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: ListTile(
                  onTap: () => setState(() => _section = section),
                  leading: CircleAvatar(
                    backgroundColor: SectionStyle.of[section]!.color,
                    child: Icon(SectionStyle.of[section]!.icon, color: Colors.white),
                  ),
                  title: Text(
                    context.section(section),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: _section == section
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.teal)
                      : null,
                ),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _business,
              validator: required,
              decoration: InputDecoration(labelText: context.t('businessName')),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contact,
              validator: required,
              decoration: InputDecoration(labelText: context.t('contactName')),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              validator: required,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: context.t('phone')),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLines: 2,
              decoration: InputDecoration(labelText: context.t('notes')),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _sending ? null : _submit,
              child: Text(context.t('becomePartner')),
            ),
          ],
        ),
      ),
    );
  }
}
