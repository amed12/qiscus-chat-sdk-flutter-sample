import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qiscus_chat_flutter_sample/constants.dart';
import 'package:qiscus_chat_flutter_sample/providers/auth_provider.dart';
import 'package:qiscus_chat_flutter_sample/screens/chat_room_screen.dart';
import 'package:qiscus_chat_flutter_sample/screens/login_screen.dart';
import 'package:qiscus_chat_flutter_sample/services/qiscus_service.dart';
import 'package:qiscus_chat_flutter_sample/services/session_service.dart';

class ResumeSessionScreen extends StatefulWidget {
  final Map<String, dynamic> session;

  const ResumeSessionScreen({Key? key, required this.session})
      : super(key: key);

  @override
  State<ResumeSessionScreen> createState() => _ResumeSessionScreenState();
}

class _ResumeSessionScreenState extends State<ResumeSessionScreen> {
  bool _isLoading = false;

  Map<String, dynamic> get _session => widget.session;

  Future<void> _resumeChat() async {
    setState(() => _isLoading = true);

    final messenger = ScaffoldMessenger.of(context);
    try {
      final authProvider = context.read<AuthProvider>();
      final token = _session['userDataToken'] as String?;
      final roomId = int.tryParse('${_session['roomId']}');

      if (token == null || roomId == null) {
        throw Exception('Invalid session data, please start a new session.');
      }

      if (!authProvider.isLoggedIn) {
        final success = await authProvider.loginWithToken(token: token);
        if (!success) {
          throw Exception(
            authProvider.error ?? 'Session expired, please log in again.',
          );
        }
      }

      final room = await QiscusService.instance.getChatRoomById(roomId);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ChatRoomScreen(room: room)),
      );
    } catch (e) {
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            authProvider.error ??
                QiscusErrorCodes.messages[QiscusErrorCodes.unauthorized] ??
                e.toString(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      await SessionService.clearSession();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _startNewSession() async {
    await SessionService.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Session'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Existing chat session found',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'You can continue your previous conversation or start a new one.',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SessionDetailRow(
                      label: 'User',
                      value: '${_session['userId'] ?? '-'}',
                    ),
                    _SessionDetailRow(
                      label: 'Room ID',
                      value: '${_session['roomId'] ?? '-'}',
                    ),
                    _SessionDetailRow(
                      label: 'Resolved',
                      value: '${_session['isResolved'] ?? false}',
                    ),
                    _SessionDetailRow(
                      label: 'Sessional App',
                      value: '${_session['isSessional'] ?? false}',
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _resumeChat,
              icon: _isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isLoading ? 'Connecting...' : 'Resume Chat'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isLoading ? null : _startNewSession,
              child: const Text('Start New Session'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _SessionDetailRow({
    Key? key,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
