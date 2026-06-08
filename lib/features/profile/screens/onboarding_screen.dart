import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../common/widgets/premium_card.dart';
import '../../../core/models/life_record.dart';
import '../../../core/providers/app_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _blood = TextEditingController();
  final _emergency = TextEditingController();
  DateTime? _dob;
  String? _photo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: PremiumCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome to Life Manager Pro',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Set up your offline profile. Everything stays on this device.',
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: GestureDetector(
                          onTap: _pickPhoto,
                          child: CircleAvatar(
                            radius: 48,
                            backgroundImage: _photo == null
                                ? null
                                : FileImage(File(_photo!)),
                            child: _photo == null
                                ? const Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 36,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: 'User Name',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Name is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _pickDob,
                        icon: const Icon(Icons.cake_outlined),
                        label: Text(
                          _dob == null
                              ? 'Date of Birth'
                              : _dob!.toLocal().toString().split(' ').first,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _mobile,
                        decoration: const InputDecoration(
                          labelText: 'Mobile Number (Optional)',
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(
                          labelText: 'Email (Optional)',
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _blood,
                        decoration: const InputDecoration(
                          labelText: 'Blood Group',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emergency,
                        decoration: const InputDecoration(
                          labelText: 'Emergency Contact',
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.check),
                          label: const Text('Start managing'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _photo = image.path);
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final repository = await ref.read(lifeRepositoryProvider.future);
    await repository.saveProfile(
      UserProfile(
        name: _name.text.trim(),
        profilePhotoPath: _photo,
        dateOfBirth: _dob,
        mobileNumber: _mobile.text.trim(),
        email: _email.text.trim(),
        bloodGroup: _blood.text.trim(),
        emergencyContact: _emergency.text.trim(),
      ),
    );
    ref.invalidate(profileProvider);
  }
}
