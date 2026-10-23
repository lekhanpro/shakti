import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../../domain/engines/phone_number.dart';
import '../../../domain/entities/entities.dart';

/// Values captured by [ContactForm]. `phone` is already normalised.
typedef ContactDraft = ({String name, String phone, String relationship});

/// Validated name / phone / relationship form. Shared by the contacts sheet
/// and onboarding step 3. Call [ContactFormState.submit] (via a GlobalKey)
/// to validate and read the draft, or use the built-in [submitLabel] button.
class ContactForm extends StatefulWidget {
  const ContactForm({
    this.initial,
    this.onSubmit,
    this.submitLabel,
    this.existingPhones = const {},
    super.key,
  });

  final EmergencyContact? initial;

  /// Called with a valid draft. When null, no submit button is shown.
  final ValueChanged<ContactDraft>? onSubmit;
  final String? submitLabel;

  /// Normalised numbers already saved, used to reject duplicates.
  final Set<String> existingPhones;

  @override
  State<ContactForm> createState() => ContactFormState();
}

class ContactFormState extends State<ContactForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _phone = TextEditingController(text: widget.initial?.phone ?? '');
  late String _relationship =
      widget.initial?.relationship ?? EmergencyContact.relationships.first;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  static String? validateName(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Enter a name';
    if (s.length > 40) return 'Keep the name under 40 characters';
    return null;
  }

  String? _validatePhone(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Enter a phone number';
    if (!PhoneNumber.isValid(s)) {
      return 'Enter a valid mobile number, like 98450 12345';
    }
    final n = PhoneNumber.normalize(s);
    if (PhoneNumber.helplines.contains(n)) {
      return 'Helplines are built in. Add a person you trust';
    }
    if (n != widget.initial?.phone && widget.existingPhones.contains(n)) {
      return 'This number is already a trusted contact';
    }
    return null;
  }

  /// Validates; returns the draft or null.
  ContactDraft? submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return null;
    final draft = (
      name: _name.text.trim(),
      phone: PhoneNumber.normalize(_phone.text),
      relationship: _relationship,
    );
    widget.onSubmit?.call(draft);
    return draft;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            key: const ValueKey('contact-name'),
            controller: _name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Someone you trust',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            validator: validateName,
          ),
          const SizedBox(height: ShaktiSpace.md),
          TextFormField(
            key: const ValueKey('contact-phone'),
            controller: _phone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.telephoneNumber],
            decoration: const InputDecoration(
              labelText: 'Mobile number',
              helperText: 'Indian numbers get +91 added',
              helperMaxLines: 3,
              errorMaxLines: 4,
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            validator: _validatePhone,
            onFieldSubmitted: (_) => widget.onSubmit == null ? null : submit(),
          ),
          const SizedBox(height: ShaktiSpace.md),
          Semantics(
            header: true,
            child: Text('Relationship', style: t.labelMedium),
          ),
          const SizedBox(height: ShaktiSpace.xs),
          Wrap(
            spacing: ShaktiSpace.xs,
            runSpacing: ShaktiSpace.xs,
            children: [
              for (final r in EmergencyContact.relationships)
                ChoiceChip(
                  label: Text(r),
                  selected: _relationship == r,
                  onSelected: (_) => setState(() => _relationship = r),
                  selectedColor: context.shakti.accentContainer,
                  checkmarkColor: context.shakti.accent,
                  side: BorderSide(
                    color: _relationship == r
                        ? context.shakti.accent
                        : context.shakti.outline,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                ),
            ],
          ),
          if (widget.onSubmit != null) ...[
            const SizedBox(height: ShaktiSpace.lg),
            FilledButton.icon(
              key: const ValueKey('contact-save'),
              onPressed: submit,
              icon: const Icon(Icons.check_rounded),
              label: Text(widget.submitLabel ?? 'Save contact'),
            ),
          ],
        ],
      ),
    );
  }
}
