import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/chat/cubit/chat_cubit.dart';
import '../features/chat/cubit/chat_state.dart';
import '../core/config/app_config.dart';
import '../core/utils/performance_monitor.dart';
import 'chat_bubble.dart';

class ChatMessageList extends StatefulWidget {
  const ChatMessageList({super.key});

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mounted) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatCubit, ChatState>(
      listenWhen: (prev, curr) => prev.messages.length != curr.messages.length,
      listener: (_, __) => _scrollToBottom(),
      buildWhen: (prev, curr) => 
        prev.messages.length != curr.messages.length ||
        (prev.messages.isNotEmpty && curr.messages.isNotEmpty &&
         prev.messages.last != curr.messages.last),
      builder: (context, state) {
        PerformanceMonitor.trackRebuild('ChatMessageList');
        final maxCachedMessages = AppConfig.getPerformanceSetting<int>('maxCachedMessages');
        final messages = state.messages;
        
        // Limit messages shown to prevent memory issues
        final visibleMessages = messages.length > maxCachedMessages
            ? messages.sublist(messages.length - maxCachedMessages)
            : messages;

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          itemCount: visibleMessages.length,
          // Optimized cache settings based on environment
          cacheExtent: AppConfig.isDevelopment ? 800.0 : 1200.0,
          addAutomaticKeepAlives: false, // Disable for better memory usage
          addRepaintBoundaries: true,
          addSemanticIndexes: false,
          // Add estimated item extent for better performance
          itemExtent: null, // Let Flutter calculate, but provide hint
          findChildIndexCallback: (Key key) {
            // Optimize scrolling for large lists
            if (key is ValueKey<int>) {
              final timestamp = key.value;
              for (int i = 0; i < visibleMessages.length; i++) {
                if (visibleMessages[i].timestamp.millisecondsSinceEpoch == timestamp) {
                  return i;
                }
              }
            }
            return null;
          },
          itemBuilder: (context, index) {
            final message = visibleMessages[index];
            return RepaintBoundary(
              child: ChatBubble(
                key: ValueKey(message.timestamp.millisecondsSinceEpoch),
                message: message,
              ),
            );
          },
        );
      },
    );
  }
}