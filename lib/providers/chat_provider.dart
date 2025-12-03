import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:qiscus_chat_sdk/qiscus_chat_sdk.dart';
import 'package:qiscus_chat_flutter_sample/services/qiscus_service.dart';

class ChatProvider with ChangeNotifier {
  final QiscusService _qiscusService = QiscusService.instance;

  List<QChatRoom> _chatRooms = [];
  QChatRoom? _currentRoom;
  List<QMessage> _messages = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  final Map<String, bool> _typingUsers = {};
  final Map<String, bool> _onlineUsers = {};
  int _unreadCount = 0;
  // Track upload progress for each message (uniqueId -> progress percentage)
  final Map<String, int> _uploadProgress = {};
  bool _disposed = false;
  RealtimeStatus _realtimeStatus = RealtimeStatus.disconnected;

  List<QChatRoom> get chatRooms => _chatRooms;
  QChatRoom? get currentRoom => _currentRoom;
  List<QMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  Map<String, bool> get typingUsers => _typingUsers;
  Map<String, bool> get onlineUsers => _onlineUsers;
  int get unreadCount => _unreadCount;
  Map<String, int> get uploadProgress => _uploadProgress;
  RealtimeStatus get realtimeStatus => _realtimeStatus;
  /// Get upload progress for a specific message
  int getUploadProgress(String messageUniqueId) {
    return _uploadProgress[messageUniqueId] ?? 0;
  }

  StreamSubscription? _messageReceivedSub;
  StreamSubscription? _messageDeliveredSub;
  StreamSubscription? _messageReadSub;
  StreamSubscription? _messageDeletedSub;
  StreamSubscription? _userTypingSub;
  StreamSubscription? _userPresenceSub;
  StreamSubscription? _realtimeStatusSub;

  ChatProvider() {
    _setupEventListeners();
  }

  /// Setup real-time event listeners
  void _setupEventListeners() {
    // Listen to new messages
    _messageReceivedSub = _qiscusService.onMessageReceived.listen((message) {
      final isCurrentRoom =
          _currentRoom != null && message.chatRoomId == _currentRoom!.id;

      if (isCurrentRoom) {
        _addMessage(message);
        // Auto mark as read
        if (message.sender.id != _qiscusService.sdk.currentUser?.id && message.status == QMessageStatus.delivered) {
          _qiscusService.markAsRead(
            roomId: message.chatRoomId,
            messageId: message.id,
          );
        }
      }

      _updateRoomFromMessage(message, isCurrentRoom: isCurrentRoom);
      _updateUnreadCount();
    });

    // Listen to message delivered
    _messageDeliveredSub = _qiscusService.onMessageDelivered.listen((message) {
      _updateMessageStatus(message);
    });

    // Listen to message read
    _messageReadSub = _qiscusService.onMessageRead.listen((message) {
      _updateMessageStatus(message);
    });

    // Listen to deleted messages
    _messageDeletedSub = _qiscusService.onMessageDeleted.listen((message) {
      _removeMessage(message);
    });

    // Listen to typing indicator
    _userTypingSub = _qiscusService.onUserTyping.listen((typing) {
      if (_currentRoom != null && typing.roomId == _currentRoom!.id) {
        _typingUsers[typing.userId] = typing.isTyping;
        _notifySafely();
      }
    });

    // Listen to user presence
    _userPresenceSub = _qiscusService.onUserPresence.listen((presence) {
      _onlineUsers[presence.userId] = presence.isOnline;
      _notifySafely();
    });

    // Listen to realtime connection status
    _realtimeStatusSub =
        _qiscusService.onRealtimeStatus.listen((status) {
      _realtimeStatus = status;
      _notifySafely();
    });
  }

  /// Load all chat rooms
  Future<void> loadChatRooms({
    bool? showParticipant = true,
    int? limit = 20,
    int? page,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final rooms = await _qiscusService.getAllChatRooms(
        showParticipant: showParticipant,
        limit: limit,
        page: page,
      );

      _chatRooms = rooms;
      _sortRoomsByLastMessage();
      _setLoading(false);
      await _updateUnreadCount();
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  /// Create 1-on-1 chat
  Future<QChatRoom?> createChat({
    required String userId,
    Map<String, dynamic>? extras,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final room = await _qiscusService.createChatRoom(
        userId: userId,
        extras: extras,
      );
      _setLoading(false);
      return room;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return null;
    }
  }

  /// Create group chat
  Future<QChatRoom?> createGroupChat({
    required String name,
    required List<String> userIds,
    String? avatarUrl,
    Map<String, dynamic>? extras,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final room = await _qiscusService.createGroupChat(
        name: name,
        userIds: userIds,
        avatarUrl: avatarUrl,
        extras: extras,
      );
      _setLoading(false);
      return room;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return null;
    }
  }

  /// Create or get channel
  Future<QChatRoom?> createChannel({
    required String uniqueId,
    String? name,
    String? avatarUrl,
    Map<String, dynamic>? extras,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final room = await _qiscusService.createChannel(
        uniqueId: uniqueId,
        name: name,
        avatarUrl: avatarUrl,
        extras: extras,
      );
      _setLoading(false);
      return room;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return null;
    }
  }

  /// Refresh a specific room (e.g., after returning from chat room)
  Future<void> refreshRoom(int roomId) async {
    try {
      final room = await _qiscusService.getChatRoomById(roomId);
      _upsertRoom(room);
    } catch (e) {
      _error = e.toString();
      _notifySafely();
    }
  }

  /// Update room from message
  /// This method updates the room's last message and unread count
  void _updateRoomFromMessage(QMessage message, {required bool isCurrentRoom}) {
    final index = _chatRooms.indexWhere((r) => r.id == message.chatRoomId);
    if (index == -1) return;

    final room = _chatRooms[index];
    room.lastMessage = message;

    final currentUserId = _qiscusService.sdk.currentUser?.id;
    final isOwnMessage = currentUserId != null && message.sender.id == currentUserId;

    if (isCurrentRoom) {
      room.unreadCount = 0; // reading this room, reset
    } else if (!isOwnMessage) {
      room.unreadCount = (room.unreadCount) + 1; // only count others' messages
    }

    _chatRooms[index] = room;
    _sortRoomsByLastMessage();
    _notifySafely();
  }

  /// Enter chat room
  Future<void> enterChatRoom(QChatRoom room) async {
    _setLoading(true);
    _error = null;
    _currentRoom = room;

    try {
      // Subscribe to room for real-time updates
      _qiscusService.subscribeChatRoom(room);

      // Publish online status when room is single
      if (room.type == QRoomType.single) {
        _qiscusService.sdk.publishOnlinePresence(isOnline: true);
      }

      // Sync missed messages/events before fetching current room data
      await synchronizeMessages();

      // Load messages
      final data = await _qiscusService.getChatRoomWithMessages(roomId: room.id);
      _messages = data.messages.reversed.toList();
      _notifySafely(); // ensure listeners (UI) know messages are ready

      // Mark last message as read
      if (_messages.isNotEmpty) {
        await _qiscusService.markAsRead(
          roomId: room.id,
          messageId: _messages.last.id,
        );
      }

      await refreshRoom(room.id);
      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  /// Leave chat room
  void leaveChatRoom() {
    if (_currentRoom != null) {
      _qiscusService.unsubscribeChatRoom(_currentRoom!);
      if (_currentRoom!.type == QRoomType.single) {
        _qiscusService.sdk.publishOnlinePresence(isOnline: false);
      }
      _currentRoom = null;
      _messages.clear();
      _typingUsers.clear();
      _onlineUsers.clear();
      _unreadCount = 0;
      _uploadProgress.clear();
      _error = null;
      _notifySafely();
    }
  }

  /// Send text message
  Future<void> sendMessage(String text) async {
    if (_currentRoom == null || text.trim().isEmpty) return;

    try {
      final message = await _qiscusService.sendMessage(
        chatRoomId: _currentRoom!.id,
        text: text,
      );
      _addMessage(message);
    } catch (e) {
      _error = e.toString();
      _notifySafely();
    }
  }

  /// Send file message with placeholder (like JavaScript flow)
  Future<void> sendFileMessageWithPlaceholder(File file, {String? caption}) async {
    if (_currentRoom == null) return;

    try {
      // Get file extension
      final fileName = file.path.split('/').last;
      final extension = fileName.split('.').last.toUpperCase();
      
      // Prepare placeholder message
      final placeholderText = caption ?? 'File attachment .$extension';
      final placeholderMessage = _qiscusService.sdk.generateMessage(
        chatRoomId: _currentRoom!.id,
        text: placeholderText,
      );
      
      // Add placeholder message to UI immediately
      _addMessage(placeholderMessage);
      
      // Upload file and track progress
      _qiscusService.sendFileMessage(
        chatRoomId: _currentRoom!.id,
        file: file,
        caption: placeholderText,
      ).listen(
        (progress) {
          if (progress.data != null) {
            // File uploaded successfully, update the placeholder message
            final uploadedMessage = progress.data!;
            _updateMessageInList(placeholderMessage, uploadedMessage);
            // Remove from upload progress tracking
            _uploadProgress.remove(placeholderMessage.uniqueId);
            _notifySafely();
            print('✅ File uploaded: ${uploadedMessage.text}');
          } else {
            // Update upload progress
            _uploadProgress[placeholderMessage.uniqueId] = progress.progress.toInt();
            _notifySafely();
            print('📤 Upload progress: ${progress.progress}%');
          }
        },
        onError: (error) {
          // Remove placeholder message on error
          _removeMessage(placeholderMessage);
          _uploadProgress.remove(placeholderMessage.uniqueId);
          _error = 'Failed to upload file: $error';
          _notifySafely();
          print('❌ Upload failed: $error');
        },
      );
    } catch (e) {
      _error = e.toString();
      _notifySafely();
      print('❌ Error: $e');
    }
  }

  /// Send file message (original method - kept for backward compatibility)
  Future<void> sendFileMessage(File file, {String? caption}) async {
    if (_currentRoom == null) return;

    try {
      _qiscusService.sendFileMessage(
        chatRoomId: _currentRoom!.id,
        file: file,
        caption: caption,
      ).listen(
        (progress) {
          if (progress.data != null) {
            print('File uploaded: ${progress.data!.text}');
          } else {
            print('Upload progress: ${progress.progress}%');
          }
        },
        onError: (error) {
          _error = error.toString();
          _notifySafely();
        },
      );
    } catch (e) {
      _error = e.toString();
      _notifySafely();
    }
  }

  /// Update message
  Future<void> updateMessage(QMessage message, String newText) async {
    try {
      await _qiscusService.updateMessage(
        message: message,
        newText: newText,
      );
    } catch (e) {
      _error = e.toString();
      _notifySafely();
    }
  }

  /// Delete messages
  Future<void> deleteMessages(List<String> messageUniqueIds) async {
    try {
      await _qiscusService.deleteMessages(messageUniqueIds: messageUniqueIds);
    } catch (e) {
      _error = e.toString();
      _notifySafely();
    }
  }

  /// Load previous messages
  Future<void> loadPreviousMessages() async {
    if (_currentRoom == null || _messages.isEmpty || _isLoadingMore) return;

    _isLoadingMore = true;
    _notifySafely();

    try {
      final oldMessages = await _qiscusService.loadPreviousMessages(
        roomId: _currentRoom!.id,
        messageId: _messages.first.id,
        limit: 20,
      );

      _messages.insertAll(0, oldMessages.reversed);
      _isLoadingMore = false;
      _notifySafely();
    } catch (e) {
      _error = e.toString();
      _isLoadingMore = false;
      _notifySafely();
    }
  }

  /// Manually trigger SDK synchronize to fetch missed messages/events
  Future<void> synchronizeMessages() async {
    try {
      // Use last local message as a hint; SDK will manage its own cursor
      final lastId = _messages.isNotEmpty ? _messages.last.id.toString() : null;
      _qiscusService.sdk.synchronize(lastMessageId: lastId);
    } catch (e) {
      _error = e.toString();
      _notifySafely();
    }
  }

  /// Publish typing indicator
  Future<void> publishTyping(bool isTyping) async {
    if (_currentRoom == null) return;

    try {
      await _qiscusService.publishTyping(
        roomId: _currentRoom!.id,
        isTyping: isTyping,
      );
    } catch (e) {
      print('Error publishing typing: $e');
    }
  }

  /// Add participants to group
  Future<bool> addParticipants(List<String> userIds) async {
    if (_currentRoom == null) return false;

    try {
      await _qiscusService.addParticipants(
        roomId: _currentRoom!.id,
        userIds: userIds,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      _notifySafely();
      return false;
    }
  }

  /// Remove participants from group
  Future<bool> removeParticipants(List<String> userIds) async {
    if (_currentRoom == null) return false;

    try {
      await _qiscusService.removeParticipants(
        roomId: _currentRoom!.id,
        userIds: userIds,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      _notifySafely();
      return false;
    }
  }

  /// Get participants
  Future<List<QParticipant>> getParticipants() async {
    if (_currentRoom == null) return [];

    try {
      return await _qiscusService.getParticipants(
        roomUniqueId: _currentRoom!.uniqueId,
      );
    } catch (e) {
      _error = e.toString();
      _notifySafely();
      return [];
    }
  }

  /// Clear messages in room
  Future<void> clearMessages() async {
    if (_currentRoom == null) return;

    try {
      await _qiscusService.clearMessages(
        roomUniqueIds: [_currentRoom!.uniqueId],
      );
      _messages = [];
      _notifySafely();
    } catch (e) {
      _error = e.toString();
      _notifySafely();
    }
  }

  /// Update unread count
  Future<void> _updateUnreadCount() async {
    try {
      _unreadCount = await _qiscusService.getTotalUnreadCount();
      _notifySafely();
    } catch (e) {
      print('Error updating unread count: $e');
    }
  }

  /// Add message to list
  void _addMessage(QMessage message) {
    final index = _messages.indexWhere((m) => m.id == message.id);
    if (index == -1) {
      _messages.add(message);
      _notifySafely();
    }
  }

  /// Update message status
  void _updateMessageStatus(QMessage message) {
    final index = _messages.indexWhere((m) => m.id == message.id);
    if (index != -1) {
      _messages[index] = message;
      _notifySafely();
    }
  }

  /// Update message in list (for replacing placeholder with actual message)
  void _updateMessageInList(QMessage oldMessage, QMessage newMessage) {
    final index = _messages.indexWhere((m) => m.uniqueId == oldMessage.uniqueId);
    if (index != -1) {
      _messages[index] = newMessage;
      _notifySafely();
    } else {
      // If not found by uniqueId, try to find by text and add new message
      _addMessage(newMessage);
    }
  }

  /// Remove message from list
  void _removeMessage(QMessage message) {
    _messages.removeWhere((m) => m.id == message.id);
    _notifySafely();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _notifySafely();
  }

  void clearError() {
    _error = null;
    _notifySafely();
  }


  void _upsertRoom(QChatRoom room) {
    final index = _chatRooms.indexWhere((r) => r.id == room.id);
    if (index == -1) {
      _chatRooms.insert(0, room);
    } else {
      _chatRooms[index] = room;
    }
    _sortRoomsByLastMessage();
    _notifySafely();
  }

  void _sortRoomsByLastMessage() {
    _chatRooms.sort((a, b) {
      final aTime = a.lastMessage?.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.lastMessage?.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
  }

  void _notifySafely() {
    if (_disposed) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle) {
      super.notifyListeners();
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) {
          super.notifyListeners();
        }
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _messageReceivedSub?.cancel();
    _messageDeliveredSub?.cancel();
    _messageReadSub?.cancel();
    _messageDeletedSub?.cancel();
    _userTypingSub?.cancel();
    _userPresenceSub?.cancel();
    _realtimeStatusSub?.cancel();
    super.dispose();
  }
  
}
