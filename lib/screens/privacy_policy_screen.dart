import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = <({String heading, String body})>[
    (
      heading: 'Who we are',
      body:
          'Growing Memories (“the App”) is a private family memory and '
          'child-development journal. Before publication, replace the '
          'developer and contact placeholders below with the same legal '
          'developer name used in the Google Play listing.',
    ),
    (
      heading: 'Information you provide',
      body:
          'Depending on the features you use, the App may process your name, '
          'email address, account identifier, child profile details such as '
          'name, nickname, date of birth and gender, memories, milestone '
          'notes, tags, growth measurements, developmental checklist status, '
          'stories, questions, answers, reminders, future plans, saved links, '
          'documents, family invitation email addresses, photos, videos, '
          'audio recordings and other files you choose to add.',
    ),
    (
      heading: 'Information processed automatically',
      body:
          'The App processes authentication state, cloud record identifiers, '
          'backup status and push-notification tokens needed to operate its '
          'services. Service providers may also process standard technical '
          'information such as IP address, device information, timestamps and '
          'diagnostic or security information when you connect to their '
          'services. The App does not use this information for advertising.',
    ),
    (
      heading: 'How information is used',
      body:
          'Information is used to authenticate you; save, synchronize and '
          'display your profiles and memories; provide growth, checklist, '
          'reminder, document, link, story and forum features; back up and '
          'restore files; share selected information with invited family '
          'members; deliver service notifications; respond to support and '
          'deletion requests; prevent abuse; and maintain the security and '
          'reliability of the App.',
    ),
    (
      heading: 'Public and shared content',
      body:
          'Questions, answers and community stories may be visible to other '
          'signed-in App users. Do not include sensitive information in public '
          'content. Profile memories shared through Family Sharing may be '
          'viewed by people invited by the profile owner. Content shared '
          'through the device share sheet is handled by the service or person '
          'you select.',
    ),
    (
      heading: 'Device access',
      body:
          'The App requests camera and microphone access only for media you '
          'choose to capture, photo or file access for items you choose to '
          'import, notification access for reminders and service alerts, and '
          'calendar access when you choose to create or manage calendar '
          'events. You can deny or revoke these permissions in device '
          'settings, although the related feature may stop working.',
    ),
    (
      heading: 'Service providers',
      body:
          'The App uses Google Firebase services, including Authentication, '
          'Cloud Firestore and Firebase Cloud Messaging, to provide accounts, '
          'cloud data and notifications. If you choose the related features, '
          'the App may also use Google Sign-In, Sign in with Apple, Google '
          'Drive, iCloud, Google Photos, device calendar services, websites '
          'used to retrieve saved-link previews, and your operating system’s '
          'sharing service. These providers process information under their '
          'own terms and privacy policies. We do not sell personal information '
          'or share it for targeted advertising.',
    ),
    (
      heading: 'Storage and security',
      body:
          'Cloud records are stored using Firebase services. Selected media '
          'may also be stored locally on your device and, when you enable '
          'backup, in your Google Drive or iCloud account. We use access '
          'controls and encrypted network connections provided by these '
          'platforms. No method of storage or transmission is completely '
          'secure, so absolute security cannot be guaranteed.',
    ),
    (
      heading: 'Retention and deletion',
      body:
          'You can delete individual profiles and content in the App. You can '
          'also start account deletion from Settings. The current account '
          'deletion flow provides a 28-day recovery period before removing '
          'authentication access. Some cloud records or service backups may '
          'remain until the developer’s deletion process removes them or a '
          'provider’s backup-retention period expires. A complete server-side '
          'data-deletion process and public deletion-request page must be '
          'operational before production publication.',
    ),
    (
      heading: 'Children’s privacy',
      body:
          'The App is intended for parents and guardians, not for children to '
          'use independently. Adults are responsible for the child information '
          'and media they add and for having authority to upload and share it. '
          'Children should not create accounts or submit public content.',
    ),
    (
      heading: 'Your choices',
      body:
          'You can edit or delete content, manage family access, disable '
          'optional permissions, turn off notifications, disable cloud backup '
          'and request account deletion. Removing an item from the App may not '
          'remove copies that another person previously saved or that you '
          'shared through an external service.',
    ),
    (
      heading: 'International processing',
      body:
          'Service providers may process information in countries other than '
          'your own. Their privacy terms describe the safeguards they apply to '
          'international transfers.',
    ),
    (
      heading: 'Changes to this policy',
      body:
          'We may update this Privacy Policy as the App or legal requirements '
          'change. The effective date will be updated, and material changes '
          'will be communicated where required.',
    ),
    (
      heading: 'Contact',
      body:
          'Developer: [REPLACE WITH PLAY CONSOLE LEGAL DEVELOPER NAME]\n'
          'Privacy email: [REPLACE WITH PRIVACY CONTACT EMAIL]\n'
          'Public policy URL: [REPLACE WITH PUBLIC HTTPS URL]\n'
          'Account deletion URL: [REPLACE WITH PUBLIC HTTPS URL]',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            Text(
              'Growing Memories Privacy Policy',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Effective: July 27, 2026',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            for (final section in _sections) ...[
              Text(
                section.heading,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(section.body),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}
