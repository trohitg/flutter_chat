import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/chat/cubit/chat_cubit.dart';
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
      buildWhen: (prev, curr) => prev.messages != curr.messages,
      builder: (context, state) {
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          itemCount: state.messages.length,
          cacheExtent: 1000.0,
          addAutomaticKeepAlives: true,
          addRepaintBoundaries: true,
          addSemanticIndexes: false,
          itemBuilder: (context, index) {
            return RepaintBoundary(
              child: ChatBubble(
                key: ValueKey(state.messages[index].timestamp.millisecondsSinceEpoch),
                message: state.messages[index],
              ),
            );
          },
        );
      },
    );
  }
}