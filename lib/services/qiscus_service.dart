import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:qiscus_chat_sdk/qiscus_chat_sdk.dart';
import 'package:qiscus_chat_flutter_sample/constants.dart';

/// Singleton service to manage Qiscus SDK
class QiscusService {
  static final QiscusService instance = QiscusService._internal();
  factory QiscusService() => instance;
  QiscusService._internal();

  QiscusSDK? _sdk;
  QiscusSDK get sdk => _sdk ?? QiscusSDK.instance;

  /// Initialize Qiscus SDK
  /// Replace 'YOUR_APP_ID' with your actual Qiscus App ID
  Future<void> initialize() async {
    try {
      const appId = APP_ID;
      debugPrint('🚀 Initializing Qiscus SDK with APP_ID: $appId');
      
      if (appId == 'YOUR_APP_ID') {
        throw Exception('Please replace YOUR_APP_ID with your actual Qiscus App ID in qiscus_service.dart');
      }
      
      _sdk = QiscusSDK.instance;
      await sdk.setup(appId);
      
      // Enable debug mode for development
      sdk.enableDebugMode(enable: true, level: QLogLevel.verbose);
      
      debugPrint('✅ Qiscus SDK initialized successfully');
    } on TypeError catch (e, stackTrace) {
      debugPrint('❌ Type error during initialization: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('SDK initialization failed: Type casting error. Please check your APP_ID.');
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to initialize Qiscus SDK: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Login user with userId and userKey
  Future<QAccount> loginWithCredentials({
    required String userId,
    required String userKey,
    String? username,
    String? avatarUrl,
  }) async {
    try {
      debugPrint('🔐 Attempting login for user: $userId');
      
      // Validate inputs
      if (userId.trim().isEmpty) {
        throw Exception('User ID cannot be empty');
      }
      if (userKey.trim().isEmpty) {
        throw Exception('User key cannot be empty');
      }
      
      final account = await sdk.setUser(
        userId: userId.trim(),
        userKey: userKey.trim(),
        username: username?.trim(),
        avatarUrl: avatarUrl?.trim(),
      );
      
      debugPrint('✅ User logged in: ${account.id}');
      return account;
    } on TypeError catch (e, stackTrace) {
      debugPrint('❌ Type error during login: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Login failed: Type casting error. This usually means the server returned unexpected data. Please check your APP_ID and network connection.');
    } catch (e, stackTrace) {
      debugPrint('❌ Login failed: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Login with JWT token
  Future<QAccount> loginWithToken({required String token}) async {
    try {
      final account = await sdk.setUserWithIdentityToken(token: token);
      debugPrint('✅ User logged in with token: ${account.id}');
      return account;
    } catch (e) {
      debugPrint('❌ Login with token failed: $e');
      rethrow;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      await sdk.clearUser();
      debugPrint('✅ User logged out');
    } catch (e) {
      debugPrint('❌ Logout failed: $e');
      rethrow;
    }
  }

  /// Get current user account
  QAccount? getCurrentUser() {
    return sdk.currentUser;
  }

  /// Check if user is logged in
  bool isLoggedIn() {
    return sdk.isLogin;
  }

  /// Update user profile
  Future<QAccount> updateProfile({
    String? username,
    String? avatarUrl,
    Map<String, dynamic>? extras,
  }) async {
    try {
      final account = await sdk.updateUser(
        name: username,
        avatarUrl: avatarUrl,
        extras: extras,
      );
      debugPrint('✅ Profile updated');
      return account;
    } catch (e) {
      debugPrint('❌ Update profile failed: $e');
      rethrow;
    }
  }

  /// Create 1-on-1 chat room
  Future<QChatRoom> createChatRoom({
    required String userId,
    Map<String, dynamic>? extras,
  }) async {
    try {
      final room = await sdk.chatUser(userId: userId, extras: extras);
      debugPrint('✅ Chat room created: ${room.id}');
      return room;
    } catch (e) {
      debugPrint('❌ Create chat room failed: $e');
      rethrow;
    }
  }

  /// Get chat room by ID
  Future<QChatRoom> getChatRoomById(int roomId) async {
    try {
      debugPrint('📥 Loading chat room: $roomId');
      final roomWithMessages = await sdk.getChatRoomWithMessages(roomId: roomId);
      
      debugPrint('✅ Chat room loaded: ${roomWithMessages.room.name}');
      return roomWithMessages.room;
    } on TypeError catch (e, stackTrace) {
      debugPrint('❌ Type error getting chat room: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Failed to load chat room: Type casting error. The server may have returned unexpected data.');
    } catch (e, stackTrace) {
      debugPrint('❌ Get chat room failed: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Create group chat
  Future<QChatRoom> createGroupChat({
    required String name,
    required List<String> userIds,
    String? avatarUrl,
    Map<String, dynamic>? extras,
  }) async {
    try {
      final room = await sdk.createGroupChat(
        name: name,
        userIds: userIds,
        avatarUrl: avatarUrl,
        extras: extras,
      );
      debugPrint('✅ Group chat created: ${room.id}');
      return room;
    } catch (e) {
      debugPrint('❌ Create group chat failed: $e');
      rethrow;
    }
  }

  /// Create or get channel
  Future<QChatRoom> createChannel({
    required String uniqueId,
    String? name,
    String? avatarUrl,
    Map<String, dynamic>? extras,
  }) async {
    try {
      final room = await sdk.createChannel(
        uniqueId: uniqueId,
        name: name,
        avatarUrl: avatarUrl,
        extras: extras,
      );
      debugPrint('✅ Channel created: ${room.id}');
      return room;
    } catch (e) {
      debugPrint('❌ Create channel failed: $e');
      rethrow;
    }
  }

  /// Get all chat rooms
  Future<List<QChatRoom>> getAllChatRooms({
    bool? showParticipant,
    bool? showRemoved,
    bool? showEmpty,
    int? limit,
    int? page,
  }) async {
    try {
      final rooms = await sdk.getAllChatRooms(
        showParticipant: showParticipant,
        showRemoved: showRemoved,
        showEmpty: showEmpty,
        limit: limit,
        page: page,
      );
      debugPrint('✅ Fetched ${rooms.length} chat rooms');
      return rooms;
    } catch (e) {
      debugPrint('❌ Get chat rooms failed: $e');
      rethrow;
    }
  }

  /// Get chat room with messages
  Future<QChatRoomWithMessages> getChatRoomWithMessages({
    required int roomId,
  }) async {
    try {
      final data = await sdk.getChatRoomWithMessages(roomId: roomId);
      debugPrint('✅ Fetched room with ${data.messages.length} messages');
      return data;
    } catch (e) {
      debugPrint('❌ Get room with messages failed: $e');
      rethrow;
    }
  }

  /// Send text message
  Future<QMessage> sendMessage({
    required int chatRoomId,
    required String text,
    Map<String, dynamic>? extras,
  }) async {
    try {
      final message = sdk.generateMessage(
        chatRoomId: chatRoomId,
        text: text,
        extras: extras,
      );
      final sentMessage = await sdk.sendMessage(message: message);
      debugPrint('✅ Message sent: ${sentMessage.id}');
      return sentMessage;
    } catch (e) {
      debugPrint('❌ Send message failed: $e');
      rethrow;
    }
  }

  /// Send file message
  Stream<QUploadProgress<QMessage>> sendFileMessage({
    required int chatRoomId,
    required File file,
    String? caption,
  }) {
    try {
      final message = sdk.generateFileAttachmentMessage(
        chatRoomId: chatRoomId,
        caption: caption ?? '[file]',
        url: file.path,
      );
      return sdk.sendFileMessage(message: message, file: file);
    } catch (e) {
      debugPrint('❌ Send file message failed: $e');
      rethrow;
    }
  }

  /// Update message
  Future<QMessage> updateMessage({
    required QMessage message,
    required String newText,
  }) async {
    try {
      final updatedMessage = QMessage(
        id: message.id,
        chatRoomId: message.chatRoomId,
        uniqueId: message.uniqueId,
        type: message.type,
        text: newText,
        sender: message.sender,
        timestamp: message.timestamp,
        status: message.status,
        previousMessageId: message.previousMessageId,
        extras: message.extras,
        payload: message.payload,
      );
      final result = await sdk.updateMessage(message: updatedMessage);
      debugPrint('✅ Message updated: ${result.id}');
      return result;
    } catch (e) {
      debugPrint('❌ Update message failed: $e');
      rethrow;
    }
  }

  /// Delete messages
  Future<List<QMessage>> deleteMessages({
    required List<String> messageUniqueIds,
  }) async {
    try {
      final deletedMessages = await sdk.deleteMessages(
        messageUniqueIds: messageUniqueIds,
      );
      debugPrint('✅ ${deletedMessages.length} messages deleted');
      return deletedMessages;
    } catch (e) {
      debugPrint('❌ Delete messages failed: $e');
      rethrow;
    }
  }

  /// Load previous messages
  Future<List<QMessage>> loadPreviousMessages({
    required int roomId,
    required int messageId,
    int? limit,
  }) async {
    try {
      final messages = await sdk.getPreviousMessagesById(
        roomId: roomId,
        messageId: messageId,
        limit: limit,
      );
      debugPrint('✅ Loaded ${messages.length} previous messages');
      return messages;
    } catch (e) {
      debugPrint('❌ Load previous messages failed: $e');
      rethrow;
    }
  }

  /// Mark message as read
  Future<void> markAsRead({
    required int roomId,
    required int messageId,
  }) async {
    try {
      await sdk.markAsRead(roomId: roomId, messageId: messageId);
    } catch (e) {
      debugPrint('❌ Mark as read failed: $e');
    }
  }

  /// Subscribe to chat room for real-time updates
  void subscribeChatRoom(QChatRoom room) {
    sdk.subscribeChatRoom(room);
    debugPrint('✅ Subscribed to room: ${room.id}');
  }

  /// Unsubscribe from chat room
  void unsubscribeChatRoom(QChatRoom room) {
    sdk.unsubscribeChatRoom(room);
    debugPrint('✅ Unsubscribed from room: ${room.id}');
  }

  /// Publish typing indicator
  Future<void> publishTyping({
    required int roomId,
    bool isTyping = true,
  }) async {
    try {
      await sdk.publishTyping(roomId: roomId, isTyping: isTyping);
    } catch (e) {
      debugPrint('❌ Publish typing failed: $e');
    }
  }

  /// Add participants to group chat
  Future<List<QParticipant>> addParticipants({
    required int roomId,
    required List<String> userIds,
  }) async {
    try {
      final participants = await sdk.addParticipants(
        roomId: roomId,
        userIds: userIds,
      );
      debugPrint('✅ Added ${participants.length} participants');
      return participants;
    } catch (e) {
      debugPrint('❌ Add participants failed: $e');
      rethrow;
    }
  }

  /// Remove participants from group chat
  Future<List<String>> removeParticipants({
    required int roomId,
    required List<String> userIds,
  }) async {
    try {
      final removedIds = await sdk.removeParticipants(
        roomId: roomId,
        userIds: userIds,
      );
      debugPrint('✅ Removed ${removedIds.length} participants');
      return removedIds;
    } catch (e) {
      debugPrint('❌ Remove participants failed: $e');
      rethrow;
    }
  }

  /// Get participants
  Future<List<QParticipant>> getParticipants({
    required String roomUniqueId,
    int? page,
    int? limit,
  }) async {
    try {
      final participants = await sdk.getParticipants(
        roomUniqueId: roomUniqueId,
        page: page,
        limit: limit,
      );
      debugPrint('✅ Fetched ${participants.length} participants');
      return participants;
    } catch (e) {
      debugPrint('❌ Get participants failed: $e');
      rethrow;
    }
  }

  /// Get total unread count
  Future<int> getTotalUnreadCount() async {
    try {
      final count = await sdk.getTotalUnreadCount();
      debugPrint('✅ Total unread count: $count');
      return count;
    } catch (e) {
      debugPrint('❌ Get unread count failed: $e');
      rethrow;
    }
  }

  /// Clear messages in chat room
  Future<void> clearMessages({required List<String> roomUniqueIds}) async {
    try {
      await sdk.clearMessagesByChatRoomId(roomUniqueIds: roomUniqueIds);
      debugPrint('✅ Messages cleared');
    } catch (e) {
      debugPrint('❌ Clear messages failed: $e');
      rethrow;
    }
  }

  /// Get JWT nonce for multichannel initiate_chat API
  Future<String> getNonce() async {
    return sdk.getJWTNonce();
  }
}
