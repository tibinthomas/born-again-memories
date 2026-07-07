import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'milestone_home_page.dart';

class AccountRecoveryScreen extends ConsumerStatefulWidget {
  final DateTime scheduledDeletion;
  final bool deleteDriveBackup;

  const AccountRecoveryScreen({
    super.key,
    required this.scheduledDeletion,
    required this.deleteDriveBackup,
  });

  @override
  ConsumerState<AccountRecoveryScreen> createState() =>
      _AccountRecoveryScreenState();
}

class _AccountRecoveryScreenState extends ConsumerState<AccountRecoveryScreen> {
  bool _recovering = false;
  bool _deleting = false;

  int get _daysRemaining =>
      widget.scheduledDeletion.difference(DateTime.now()).inDays.clamp(0, 28);

  Future<void> _recover() async {
    setState(() => _recovering = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) await ref.read(authServiceProvider).recoverAccount(uid);
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MilestoneHomePage()),
          (_) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _recovering = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recovery failed. Please try again.')),
      );
    }
  }

  Future<void> _deleteNow() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete now?'),
        content: const Text(
            'This will permanently delete your account immediately. '
            'This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(authServiceProvider).permanentlyDelete();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      final msg = e.code == 'requires-recent-login'
          ? 'Please sign out and sign back in, then try again.'
          : (e.message ?? 'Deletion failed. Please try again.');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deletion failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final deletion =
        '${widget.scheduledDeletion.day}/${widget.scheduledDeletion.month}/${widget.scheduledDeletion.year}';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF8F0), Color(0xFFFFF0F5), Color(0xFFE8F4FF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                // Icon
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.orange.shade50,
                      border: Border.all(
                          color: Colors.orange.shade200, width: 2),
                    ),
                    child: const Center(
                      child: Text('⏳', style: TextStyle(fontSize: 48)),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // Title
                const Text(
                  'Account scheduled\nfor deletion',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4A3728),
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 16),
                // Days remaining badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: _daysRemaining <= 3
                          ? Colors.red.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: _daysRemaining <= 3
                            ? Colors.red.shade200
                            : Colors.orange.shade200,
                      ),
                    ),
                    child: Text(
                      '$_daysRemaining day${_daysRemaining == 1 ? '' : 's'} remaining · deletes on $deletion',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _daysRemaining <= 3
                            ? Colors.red.shade700
                            : Colors.orange.shade800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Info card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(
                        icon: '💾',
                        text: 'Your memories and milestones are safe until $deletion.',
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(
                        icon: widget.deleteDriveBackup ? '🗑️' : '☁️',
                        text: widget.deleteDriveBackup
                            ? 'Your Google Drive backup has been deleted.'
                            : 'Your Google Drive backup is untouched.',
                      ),
                      const SizedBox(height: 10),
                      const _InfoRow(
                        icon: '↩️',
                        text:
                            'Tap "Recover account" below to cancel the deletion and keep everything.',
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Recover button
                FilledButton(
                  onPressed:
                      (_recovering || _deleting) ? null : _recover,
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _recovering
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Recover account',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
                const SizedBox(height: 12),
                // Delete now (text link style)
                TextButton(
                  onPressed: (_recovering || _deleting) ? null : _deleteNow,
                  child: _deleting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Delete my account now',
                          style: TextStyle(color: Colors.red, fontSize: 14),
                        ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      );
}
