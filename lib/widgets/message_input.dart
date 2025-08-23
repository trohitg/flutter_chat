import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/chat/cubit/chat_cubit.dart';

class MessageInput extends StatefulWidget {
  const MessageInput({super.key});

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {}); // Trigger rebuild for send button state
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      buildWhen: (prev, curr) => 
        prev.isConnected != curr.isConnected || 
        prev.isLoading != curr.isLoading,
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: state.isConnected ? 'Message...' : 'Offline',
                    border: const OutlineInputBorder(),
                    suffixIcon: !state.isConnected
                        ? const Icon(Icons.wifi_off, color: Colors.red)
                        : null,
                  ),
                  maxLines: null,
                  maxLength: 1000,
                  textInputAction: TextInputAction.send,
                  enabled: !state.isLoading,
                  onSubmitted: _sendMessage,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: (_controller.text.trim().isNotEmpty && 
                          state.isConnected &&
                          !state.isLoading)
                    ? () => _sendMessage(_controller.text)
                    : null,
                icon: state.isLoading 
                  ? const SizedBox(
                      width: 20, 
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _sendMessage(String text) {
    if (text.trim().isNotEmpty) {
      context.read<ChatCubit>().sendMessage(text.trim());
      _controller.clear();
    }
  }
}