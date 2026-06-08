import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../common/widgets/premium_card.dart';
import '../../../core/models/life_record.dart';
import '../../../core/providers/app_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('$error')),
        data: (profile) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            PremiumCard(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: profile?.profilePhotoPath == null
                        ? null
                        : FileImage(File(profile!.profilePhotoPath!)),
                    child: profile?.profilePhotoPath == null
                        ? const Icon(Icons.person, size: 44)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile?.name ?? 'No profile',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(profile?.email ?? ''),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _edit(context, ref, profile),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Profile'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _InfoTile(label: 'Mobile', value: profile?.mobileNumber ?? '-'),
            _InfoTile(label: 'Blood Group', value: profile?.bloodGroup ?? '-'),
            _InfoTile(
              label: 'Emergency Contact',
              value: profile?.emergencyContact ?? '-',
            ),
            _InfoTile(
              label: 'Date of Birth',
              value:
                  profile?.dateOfBirth?.toLocal().toString().split(' ').first ??
                  '-',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    UserProfile? profile,
  ) async {
    final name = TextEditingController(text: profile?.name ?? '');
    final mobile = TextEditingController(text: profile?.mobileNumber ?? '');
    final email = TextEditingController(text: profile?.email ?? '');
    final blood = TextEditingController(text: profile?.bloodGroup ?? '');
    final emergency = TextEditingController(
      text: profile?.emergencyContact ?? '',
    );
    String? photo = profile?.profilePhotoPath;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Edit Profile',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                CircleAvatar(
                  radius: 42,
                  backgroundImage: photo == null
                      ? null
                      : FileImage(File(photo!)),
                  child: photo == null ? const Icon(Icons.person) : null,
                ),
                TextButton.icon(
                  onPressed: () async {
                    final image = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null) setState(() => photo = image.path);
                  },
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Change photo'),
                ),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: mobile,
                  decoration: const InputDecoration(labelText: 'Mobile'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: email,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: blood,
                  decoration: const InputDecoration(labelText: 'Blood Group'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emergency,
                  decoration: const InputDecoration(
                    labelText: 'Emergency Contact',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    final repository = await ref.read(
                      lifeRepositoryProvider.future,
                    );
                    await repository.saveProfile(
                      UserProfile(
                        name: name.text.trim(),
                        profilePhotoPath: photo,
                        dateOfBirth: profile?.dateOfBirth,
                        mobileNumber: mobile.text.trim(),
                        email: email.text.trim(),
                        bloodGroup: blood.text.trim(),
                        emergencyContact: emergency.text.trim(),
                      ),
                    );
                    ref.invalidate(profileProvider);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        child: ListTile(
          title: Text(label),
          subtitle: Text(value),
          leading: const Icon(Icons.info_outline),
        ),
      ),
    );
  }
}
