import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:qiscus_chat_sdk/qiscus_chat_sdk.dart';
import 'package:qiscus_chat_flutter_sample/services/qiscus_service.dart';

class ChatProvider with ChangeNotifier {
  final QiscusService _qiscusService = QiscusService.instance;

  ChatConnectionStatus _connectionStatus = ChatConnectionStatus.connected;
  QChatRoom? _currentRoom;
  List<QMessage> _messages = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isLogin = false;
  String? _error;
  Map<String, bool> _typingUsers = {};
  final Map<String, bool> _onlineUsers = {};
  int _unreadCount = 0;
  // Track upload progress for each message (uniqueId -> progress percentage)
  final Map<String, int> _uploadProgress = {};
  QChatRoom? get currentRoom => _currentRoom;
  List<QMessage> get messages => _messages;
  bool get isLogin => _isLogin;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  Map<String, bool> get typingUsers => _typingUsers;
  Map<String, bool> get onlineUsers => _onlineUsers;
  int get unreadCount => _unreadCount;
  Map<String, int> get uploadProgress => _uploadProgress;
  ChatConnectionStatus get connectionStatus => _connectionStatus;
  
  /// Get upload progress for a specific message
  int getUploadProgress(String messageUniqueId) {
    return _uploadProgress[messageUniqueId] ?? 0;
  }

  StreamSubscription? _messageReceivedSub;
  StreamSubscription? _messageDeliveredSub;
  StreamSubscription? _messageReadSub;
  StreamSubscription? _messageDeletedSub;
  StreamSubscription? _messageUpdatedSub;
  StreamSubscription? _userTypingSub;
  StreamSubscription? _userPresenceSub;
  StreamSubscription? _roomClearedSub;
  StreamSubscription? _connectedSub;
  StreamSubscription? _disconnectedSub;

  ChatProvider() {
    _messageReceivedSub =
        _qiscusService.sdk.onMessageReceived().listen((message) {
      debugPrint('📨 Message received provider: ${message.text}');
      if (_currentRoom != null && message.chatRoomId == _currentRoom!.id) {
        _addMessage(message);
        // Auto mark as read
        _qiscusService.markAsRead(
          roomId: message.chatRoomId,
          messageId: message.id,
        );
      }
      _updateUnreadCount();
    });

    // Listen to message delivered
    _messageDeliveredSub =
        _qiscusService.sdk.onMessageDelivered().listen((message) {
      _updateMessageStatus(message);
    });

    // Listen to message read
    _messageReadSub = _qiscusService.sdk.onMessageRead().listen((message) {
      _updateMessageStatus(message);
    });

    // Listen to deleted messages
    _messageDeletedSub =
        _qiscusService.sdk.onMessageDeleted().listen((message) {
      _removeMessage(message);
    });

    // Listen to typing indicator
    _userTypingSub = _qiscusService.sdk.onUserTyping().listen((typing) {
      if (_currentRoom != null && typing.roomId == _currentRoom!.id) {
        _typingUsers[typing.userId] = typing.isTyping;
        notifyListeners();
      }
    });

    // Listen to user presence
    _userPresenceSub =
        _qiscusService.sdk.onUserOnlinePresence().listen((presence) {
      _onlineUsers[presence.userId] = presence.isOnline;
      notifyListeners();
    });

    // Listen to message updates (edits/status changes from server)
    _messageUpdatedSub =
        _qiscusService.sdk.onMessageUpdated().listen(_updateMessageStatus);

    // Listen when a room is cleared from another device/session
    _roomClearedSub =
        _qiscusService.sdk.onChatRoomCleared().listen((roomId) {
      if (_currentRoom != null && _currentRoom!.id == roomId) {
        _messages = [];
        notifyListeners();
      }
    });

    // Basic connection awareness for UI
    _connectedSub = _qiscusService.sdk.onConnected().listen((_) {
      _setConnectionStatus(ChatConnectionStatus.connected);
    });
    _disconnectedSub = _qiscusService.sdk.onDisconnected().listen((_) async {
      //delay 1 second
      await Future.delayed(const Duration(seconds: 3));
      _setConnectionStatus(ChatConnectionStatus.disconnected);
      await _qiscusService.sdk.openRealtimeConnection().then((_) {
        _setConnectionStatus(ChatConnectionStatus.connected);
      }).onError((_, __) {
        _setConnectionStatus(ChatConnectionStatus.disconnected);
      });
    });
  }

  /// Enter chat room
  Future<void> enterChatRoom(QChatRoom room) async {
    _setLoading(true);
    _error = null;
    _currentRoom = room;

    try {
      // Subscribe to room for real-time updates
      _qiscusService.subscribeChatRoom(room);

      // Load messages
      final data = await _qiscusService.getChatRoomWithMessages(roomId: room.id);
      _messages = data.messages.reversed.toList();

      // Mark last message as read
      if (_messages.isNotEmpty) {
        await _qiscusService.markAsRead(
          roomId: room.id,
          messageId: _messages.last.id,
        );
      }
      _isLogin = true;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      _isLogin = false;
      notifyListeners();
    }
  }

  /// Leave chat room
  void leaveChatRoom({bool notify = true}) {
    if (_currentRoom != null) {
      _qiscusService.unsubscribeChatRoom(_currentRoom!);
      _currentRoom = null;
      _messages = [];
      _typingUsers = {};
      _isLogin = false;
      if (notify) {
        final scheduler = SchedulerBinding.instance;
        final phase = scheduler.schedulerPhase;
        if (phase == SchedulerPhase.idle ||
            phase == SchedulerPhase.postFrameCallbacks) {
          notifyListeners();
        } else {
          scheduler.addPostFrameCallback((_) {
            if (hasListeners) {
              notifyListeners();
            }
          });
        }
      }
    }
  }                     

  /// Send text message
  Future<void> sendMessage(String text) async {
    if (_currentRoom == null || text.trim().isEmpty) return;

    try {
      // Send message to server
      await _qiscusService.sendMessage(
        chatRoomId: _currentRoom!.id,
        text: text,
      );
      _qiscusService.sdk.synchronize();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
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
            notifyListeners();
            debugPrint('✅ File uploaded: ${uploadedMessage.text}');
          } else {
            // Update upload progress
            _uploadProgress[placeholderMessage.uniqueId] = progress.progress.toInt();
            notifyListeners();
            debugPrint('📤 Upload progress: ${progress.progress}%');
          }
        },
        onError: (error) {
          // Remove placeholder message on error
          _removeMessage(placeholderMessage);
          _uploadProgress.remove(placeholderMessage.uniqueId);
          _error = 'Failed to upload file: $error';
          notifyListeners();
          debugPrint('❌ Upload failed: $error');
        },
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('❌ Error: $e');
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
            debugPrint('File uploaded: ${progress.data!.text}');
          } else {
            debugPrint('Upload progress: ${progress.progress}%');
          }
        },
        onError: (error) {
          _error = error.toString();
          notifyListeners();
        },
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
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
      notifyListeners();
    }
  }

  /// Delete messages
  Future<void> deleteMessages(List<String> messageUniqueIds) async {
    try {
      await _qiscusService.deleteMessages(messageUniqueIds: messageUniqueIds);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Load previous messages
  Future<void> loadPreviousMessages() async {
    if (_currentRoom == null || _messages.isEmpty || _isLoadingMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final oldMessages = await _qiscusService.loadPreviousMessages(
        roomId: _currentRoom!.id,
        messageId: _messages.first.id,
        limit: 20,
      );

      _messages.insertAll(0, oldMessages.reversed);
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoadingMore = false;
      notifyListeners();
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
      debugPrint('Error publishing typing: $e');
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
      notifyListeners();
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
      notifyListeners();
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
      notifyListeners();
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
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Update unread count
  Future<void> _updateUnreadCount() async {
    try {
      _unreadCount = await _qiscusService.getTotalUnreadCount();
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating unread count: $e');
    }
  }

  /// Expose unread count refresh for UI triggers
  Future<void> refreshUnreadCount() async {
    await _updateUnreadCount();
  }

  /// Add or update message to list
  void _addMessage(QMessage message) {
    final index = _messages.indexWhere((m) => m.id == message.id);
    if (index == -1) {
      _messages.add(message);
      notifyListeners();
    } else {
      _messages[index] = message;
      notifyListeners();
    }
  }

  /// Update message status
  void _updateMessageStatus(QMessage message) {
    final index = _messages.indexWhere((m) => m.id == message.id);
    if (index != -1) {
      _messages[index] = message;
      notifyListeners();
    }
  }

  /// Update message in list (for replacing placeholder with actual message)
  void _updateMessageInList(QMessage oldMessage, QMessage newMessage) {
    final index = _messages.indexWhere((m) => m.uniqueId == oldMessage.uniqueId);
    if (index != -1) {
      _messages[index] = newMessage;
      notifyListeners();
    } else {
      // If not found by uniqueId, try to find by text and add new message
      _addMessage(newMessage);
    }
  }

  /// Remove message from list
  void _removeMessage(QMessage message) {
    _messages.removeWhere((m) => m.id == message.id);
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _messageReceivedSub?.cancel();
    _messageDeliveredSub?.cancel();
    _messageReadSub?.cancel();
    _messageDeletedSub?.cancel();
    _messageUpdatedSub?.cancel();
    _userTypingSub?.cancel();
    _userPresenceSub?.cancel();
    _roomClearedSub?.cancel();
    _connectedSub?.cancel();
    _disconnectedSub?.cancel();
    super.dispose();
  }

  void _setConnectionStatus(ChatConnectionStatus status) {
    if (_connectionStatus != status) {
      _connectionStatus = status;
      notifyListeners();
    }
  }
}

enum ChatConnectionStatus { connected, disconnected }
