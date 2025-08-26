import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/chat/cubit/chat_cubit.dart';
import '../features/chat/cubit/chat_state.dart';
import '../widgets/chat_message_list.dart';
import '../widgets/message_input.dart';
import '../services/permission_service.dart';
import '../services/app_lifecycle_service.dart';
import '../services/bubble_service.dart';
import '../core/di/service_locator.dart';
import 'money_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ChatCubit>(),
      child: const _ChatView(),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView();

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  bool _bubbleVisible = false;

  @override
  void initState() {
    super.initState();
    _loadBubbleState();
  }

  Future<void> _loadBubbleState() async {
    final visible = await AppLifecycleService.instance.loadBubbleState();
    setState(() {
      _bubbleVisible = visible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _saveAppState();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ask Genie'),
          actions: [
            BlocBuilder<ChatCubit, ChatState>(
              buildWhen: (prev, curr) => prev.isConnected != curr.isConnected,
              builder: (context, state) {
                if (!state.isConnected) {
                  return const Icon(
                    Icons.wifi_off,
                    color: Colors.red,
                    semanticLabel: 'No internet connection',
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            if (defaultTargetPlatform == TargetPlatform.android)
              IconButton(
                icon: Icon(
                  _bubbleVisible ? Icons.bubble_chart : Icons.bubble_chart_outlined,
                ),
                onPressed: _toggleBubble,
                tooltip: _bubbleVisible ? 'Hide Chat Bubble' : 'Show Chat Bubble',
              ),
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'money',
                  child: ListTile(
                    leading: Icon(Icons.currency_rupee),
                    title: Text('Money'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear_history',
                  child: ListTile(
                    leading: Icon(Icons.clear_all),
                    title: Text('Clear History'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'about',
                  child: ListTile(
                    leading: Icon(Icons.info),
                    title: Text('About'),
                  ),
                ),
              ],
            ),
          ],
        ),
        body: BlocBuilder<ChatCubit, ChatState>(
          buildWhen: (prev, curr) => 
            prev.status != curr.status || 
            prev.messages.length != curr.messages.length,
          builder: (context, state) {
            if (state.isLoading && state.messages.isEmpty) {
              return const _LoadingView();
            }
            
            return const _ChatBodyView();
          },
        ),
      ),
    );
  }
  
  void _saveAppState() {
    final state = context.read<ChatCubit>().state;
    AppLifecycleService.instance.saveAppState({
      'lastUsed': DateTime.now().toIso8601String(),
      'messageCount': state.messages.length,
    });
    AppLifecycleService.instance.saveBubbleState(_bubbleVisible);
  }

  Future<void> _toggleBubble() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bubble feature is only available on Android'),
          ),
        );
      }
      return;
    }

    if (_bubbleVisible) {
      final success = await BubbleService.hideBubble();
      if (success) {
        setState(() {
          _bubbleVisible = false;
        });
        await AppLifecycleService.instance.saveBubbleState(false);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chat bubble hidden')),
          );
        }
      }
    } else {
      final hasPermission = await PermissionService.instance.requestOverlayPermission(context);
      
      if (!hasPermission) {
        return;
      }

      final success = await BubbleService.showBubble();
      if (success) {
        setState(() {
          _bubbleVisible = true;
        });
        await AppLifecycleService.instance.saveBubbleState(true);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chat bubble is now visible')),
          );
        }
      }
    }
  }

  void _handleMenuAction(String action) async {
    switch (action) {
      case 'money':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const MoneyScreen()),
        );
        break;
      case 'clear_history':
        await _showClearHistoryDialog();
        break;
      case 'about':
        _showAboutDialog();
        break;
    }
  }

  Future<void> _showClearHistoryDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Chat History'),
          content: const Text(
            'Are you sure you want to clear all chat messages? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (result == true && mounted) {
      context.read<ChatCubit>().clearHistory();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat history cleared')),
      );
    }
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Ask Genie',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
          ),
        ),
        child: const Icon(
          Icons.chat,
          color: Colors.white,
          size: 32,
        ),
      ),
      children: const [
        Text('AI-powered chat application with floating bubble support.'),
        SizedBox(height: 16),
        Text('Features:'),
        Text('• Real-time AI chat responses'),
        Text('• Floating chat bubble'),
        Text('• Automatic state preservation'),
        Text('• Network connectivity handling'),
        Text('• Accessibility support'),
      ],
    );
  }
}

// Optimized const widgets for better performance
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Initializing...'),
        ],
      ),
    );
  }
}

class _ChatBodyView extends StatelessWidget {
  const _ChatBodyView();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Expanded(child: ChatMessageList()),
        MessageInput(),
      ],
    );
  }
}