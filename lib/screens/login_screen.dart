import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qiscus_chat_flutter_sample/constants.dart';
import 'package:qiscus_chat_flutter_sample/providers/auth_provider.dart';
import 'package:qiscus_chat_flutter_sample/screens/chat_room_screen.dart';
import 'package:qiscus_chat_flutter_sample/services/multichannel_api.dart';
import 'package:qiscus_chat_flutter_sample/services/qiscus_service.dart';
import 'package:qiscus_chat_flutter_sample/services/session_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _userKeyController = TextEditingController();
  final _usernameController = TextEditingController();
  final _avatarUrlController = TextEditingController();
  bool _isStartingChat = false;

  @override
  void dispose() {
    _userIdController.dispose();
    _userKeyController.dispose();
    _usernameController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  void _fillDemoCredentials() {
    _userIdController.text = 'demo-user-${DateTime.now().millisecondsSinceEpoch}';
    _userKeyController.text = 'demo-password';
    _usernameController.text = 'Demo User';
  }

  Future<void> _startMultichannelChat() async {
    final userId = _userIdController.text.trim().isEmpty
        ? 'guest-${DateTime.now().millisecondsSinceEpoch}'
        : _userIdController.text.trim();
    final displayName = _usernameController.text.trim().isEmpty
        ? userId
        : _usernameController.text.trim();
    final avatar = _avatarUrlController.text.trim().isEmpty
        ? null
        : _avatarUrlController.text.trim();

    setState(() => _isStartingChat = true);

    try {
      final messenger = ScaffoldMessenger.of(context);
      final result = await MultichannelAPI.initiateChat(
        appId: APP_ID,
        channelId: CHANNEL_ID,
        userId: userId,
        name: displayName,
        avatar: avatar,
      );

      final identityToken = result['identity_token'] as String?;
      final customerRoom =
          (result['customer_room'] ?? {}) as Map<String, dynamic>;
      final roomId = int.tryParse('${customerRoom['room_id']}');
      final isResolved = customerRoom['is_resolved'] == true;
      final isSessional = await MultichannelAPI.checkSessional(APP_ID);

      if (identityToken == null || roomId == null) {
        throw Exception('Multichannel response is incomplete');
      }

      await SessionService.saveSession({
        'appId': APP_ID,
        'userId': userId,
        'userDataToken': identityToken,
        'roomId': roomId,
        'isSessional': isSessional,
        'isResolved': isResolved,
      });

      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      final success =
          await authProvider.loginWithToken(token: identityToken);
      if (!success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(authProvider.error ??
                'Failed to start chat session, please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final room = await QiscusService.instance.getChatRoomById(roomId);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ChatRoomScreen(room: room)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isStartingChat = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                Icon(
                  Icons.chat_bubble_rounded,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Welcome to Qiscus Chat',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _userIdController,
                  decoration: const InputDecoration(
                    labelText: 'User ID',
                    hintText: 'Enter your user ID',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter user ID';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _userKeyController,
                  decoration: const InputDecoration(
                    labelText: 'User Key',
                    hintText: 'Enter your user key',
                    prefixIcon: Icon(Icons.key),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter user key';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Display Name (Optional)',
                    hintText: 'Enter your display name',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _avatarUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Avatar URL (Optional)',
                    hintText: 'Enter avatar URL',
                    prefixIcon: Icon(Icons.image),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _startMultichannelChat,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: authProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(fontSize: 16),
                            ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _fillDemoCredentials,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Use Demo Credentials',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 12),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return ElevatedButton.icon(
                      onPressed: (authProvider.isLoading || _isStartingChat)
                          ? null
                          : _startMultichannelChat,
                      icon: _isStartingChat
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.chat_bubble),
                      label: Text(
                        _isStartingChat
                            ? 'Starting Multichannel...'
                            : 'Start Multichannel Chat',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Note: Replace "YOUR_APP_ID" in QiscusService with your actual Qiscus App ID',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
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
