import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qiscus_chat_flutter_sample/providers/chat_provider.dart';
import 'package:qiscus_chat_flutter_sample/screens/chat_room_screen.dart';

class CreateChatScreen extends StatefulWidget {
  const CreateChatScreen({Key? key}) : super(key: key);

  @override
  State<CreateChatScreen> createState() => _CreateChatScreenState();
}

class _CreateChatScreenState extends State<CreateChatScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Chat'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '1-on-1'),
            Tab(text: 'Group'),
            Tab(text: 'Channel'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CreateOneOnOneChatTab(),
          CreateGroupChatTab(),
          CreateChannelTab(),
        ],
      ),
    );
  }
}

class CreateOneOnOneChatTab extends StatefulWidget {
  const CreateOneOnOneChatTab({Key? key}) : super(key: key);

  @override
  State<CreateOneOnOneChatTab> createState() => _CreateOneOnOneChatTabState();
}

class _CreateOneOnOneChatTabState extends State<CreateOneOnOneChatTab> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _createChat() async {
    if (!_formKey.currentState!.validate()) return;

    final chatProvider = context.read<ChatProvider>();

    final room = await chatProvider.createChat(
      userId: _userIdController.text.trim(),
    );

    if (!mounted) return;

    if (room != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(room: room),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(chatProvider.error ?? 'Failed to create chat'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Start a 1-on-1 conversation',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _userIdController,
              decoration: const InputDecoration(
                labelText: 'User ID',
                hintText: 'Enter user ID to chat with',
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
            const SizedBox(height: 24),
            Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                return ElevatedButton(
                  onPressed: chatProvider.isLoading ? null : _createChat,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: chatProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Start Chat'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CreateGroupChatTab extends StatefulWidget {
  const CreateGroupChatTab({Key? key}) : super(key: key);

  @override
  State<CreateGroupChatTab> createState() => _CreateGroupChatTabState();
}

class _CreateGroupChatTabState extends State<CreateGroupChatTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _userIdsController = TextEditingController();
  final _avatarUrlController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _userIdsController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    final userIds = _userIdsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (userIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one user'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final chatProvider = context.read<ChatProvider>();

    final room = await chatProvider.createGroupChat(
      name: _nameController.text.trim(),
      userIds: userIds,
      avatarUrl: _avatarUrlController.text.trim().isEmpty
          ? null
          : _avatarUrlController.text.trim(),
    );

    if (!mounted) return;

    if (room != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(room: room),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(chatProvider.error ?? 'Failed to create group'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Create a group chat',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'Enter group name',
                  prefixIcon: Icon(Icons.group),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter group name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _userIdsController,
                decoration: const InputDecoration(
                  labelText: 'User IDs',
                  hintText: 'user1, user2, user3',
                  helperText: 'Separate user IDs with commas',
                  prefixIcon: Icon(Icons.people),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter at least one user ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _avatarUrlController,
                decoration: const InputDecoration(
                  labelText: 'Avatar URL (Optional)',
                  hintText: 'Enter group avatar URL',
                  prefixIcon: Icon(Icons.image),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Consumer<ChatProvider>(
                builder: (context, chatProvider, _) {
                  return ElevatedButton(
                    onPressed: chatProvider.isLoading ? null : _createGroup,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: chatProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Group'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CreateChannelTab extends StatefulWidget {
  const CreateChannelTab({Key? key}) : super(key: key);

  @override
  State<CreateChannelTab> createState() => _CreateChannelTabState();
}

class _CreateChannelTabState extends State<CreateChannelTab> {
  final _formKey = GlobalKey<FormState>();
  final _uniqueIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _avatarUrlController = TextEditingController();

  @override
  void dispose() {
    _uniqueIdController.dispose();
    _nameController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  Future<void> _createChannel() async {
    if (!_formKey.currentState!.validate()) return;

    final chatProvider = context.read<ChatProvider>();

    final room = await chatProvider.createChannel(
      uniqueId: _uniqueIdController.text.trim(),
      name: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
      avatarUrl: _avatarUrlController.text.trim().isEmpty
          ? null
          : _avatarUrlController.text.trim(),
    );

    if (!mounted) return;

    if (room != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(room: room),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(chatProvider.error ?? 'Failed to create channel'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Create or join a channel',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Channels are public chat rooms that anyone can join',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _uniqueIdController,
                decoration: const InputDecoration(
                  labelText: 'Channel Unique ID',
                  hintText: 'e.g., general, announcements',
                  prefixIcon: Icon(Icons.tag),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter channel unique ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Channel Name (Optional)',
                  hintText: 'Enter channel display name',
                  prefixIcon: Icon(Icons.label),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _avatarUrlController,
                decoration: const InputDecoration(
                  labelText: 'Avatar URL (Optional)',
                  hintText: 'Enter channel avatar URL',
                  prefixIcon: Icon(Icons.image),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Consumer<ChatProvider>(
                builder: (context, chatProvider, _) {
                  return ElevatedButton(
                    onPressed: chatProvider.isLoading ? null : _createChannel,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: chatProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create/Join Channel'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
