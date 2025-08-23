import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../features/chat/cubit/chat_cubit.dart';
import '../features/chat/cubit/chat_state.dart';
import '../core/utils/performance_monitor.dart';

class MessageInput extends StatefulWidget {
  const MessageInput({super.key});

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();
  final _imagePicker = ImagePicker();
  bool _hasText = false;
  XFile? _selectedImage;
  
  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }
  
  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (_hasText != hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  Widget _buildImagePreview(XFile imageFile) {
    if (kIsWeb) {
      // On web, use Image.network with the XFile path (blob URL)
      return Image.network(
        imageFile.path,
        fit: BoxFit.cover,
        height: 80,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 80,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    } else {
      // On mobile platforms, convert to File
      return Image.file(
        File(imageFile.path),
        fit: BoxFit.cover,
        height: 80,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 80,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    PerformanceMonitor.trackRebuild('MessageInput');
    return BlocBuilder<ChatCubit, ChatState>(
      buildWhen: (prev, curr) => 
        prev.isConnected != curr.isConnected || 
        prev.isSendingMessage != curr.isSendingMessage,
      builder: (context, state) {
        return Container(
          constraints: const BoxConstraints(maxHeight: 200),
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              if (_selectedImage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildImagePreview(_selectedImage!),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _selectedImage = null;
                          });
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  IconButton(
                    onPressed: state.isSendingMessage ? null : _pickImage,
                    icon: const Icon(Icons.image),
                    tooltip: 'Pick image',
                  ),
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
                      enabled: !state.isSendingMessage,
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: ((_hasText || _selectedImage != null) && 
                              state.isConnected &&
                              !state.isSendingMessage)
                        ? () => _sendMessage(_controller.text)
                        : null,
                    icon: state.isSendingMessage 
                      ? const SizedBox(
                          width: 20, 
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  ),
                ],
              ),
            ],
            ),
          ),
        );
      },
    );
  }
  
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }
  
  void _sendMessage(String text) {
    final messageText = text.trim();
    if (messageText.isNotEmpty || _selectedImage != null) {
      if (_selectedImage != null) {
        // Send image message
        context.read<ChatCubit>().sendImageMessage(
          messageText, 
          _selectedImage!,
        );
      } else {
        // Send text message
        context.read<ChatCubit>().sendMessage(messageText);
      }
      
      _controller.clear();
      setState(() {
        _selectedImage = null;
      });
    }
  }
}