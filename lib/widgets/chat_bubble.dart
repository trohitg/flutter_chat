import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../features/chat/cubit/chat_cubit.dart';
import '../core/config/app_config.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  bool _isNetworkUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }

  Widget _buildImage(String imageUrl, {BoxFit fit = BoxFit.cover, double? height}) {
    if (_isNetworkUrl(imageUrl)) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        height: height,
        placeholder: (context, url) => Container(
          height: height ?? 100,
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          height: height ?? 100,
          color: Colors.grey[300],
          child: const Icon(
            Icons.broken_image,
            color: Colors.grey,
            size: 32,
          ),
        ),
      );
    } else {
      // Local file - platform aware handling
      if (kIsWeb) {
        // On web, the XFile path is a blob URL that can be used directly
        return Image.network(
          imageUrl,
          fit: fit,
          height: height,
          errorBuilder: (context, error, stackTrace) => Container(
            height: height ?? 100,
            color: Colors.grey[300],
            child: const Icon(
              Icons.broken_image,
              color: Colors.grey,
              size: 32,
            ),
          ),
        );
      } else {
        // On mobile platforms, use File
        return Image.file(
          File(imageUrl),
          fit: fit,
          height: height,
          errorBuilder: (context, error, stackTrace) => Container(
            height: height ?? 100,
            color: Colors.grey[300],
            child: const Icon(
              Icons.broken_image,
              color: Colors.grey,
              size: 32,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messageTime =
        TimeOfDay.fromDateTime(message.timestamp).format(context);

    return Semantics(
      label:
          '${message.isUser ? "Your message" : "AI response"}: ${message.text}',
      hint: 'Sent at $messageTime',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: message.isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: message.isUser
                            ? const Radius.circular(16)
                            : const Radius.circular(4),
                        bottomRight: message.isUser
                            ? const Radius.circular(4)
                            : const Radius.circular(16),
                      ),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.imageUrl != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            constraints: const BoxConstraints(
                              maxHeight: 200,
                              maxWidth: 300,
                            ),
                            child: GestureDetector(
                              onTap: () => _showFullScreenImage(context, message.imageUrl!),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _buildImage(message.imageUrl!),
                              ),
                            ),
                          ),
                        if (message.text.isNotEmpty)
                          Text(
                            message.text,
                            style: TextStyle(
                              color: message.isUser
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onSurface,
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),
                        if (message.isTyping)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            child: const RepaintBoundary(
                              child: TypingIndicator(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20.0),
                minScale: 0.5,
                maxScale: 3.0,
                child: _isNetworkUrl(imageUrl)
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: 64,
                        ),
                      ),
                    )
                  : kIsWeb
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.white,
                              size: 64,
                            ),
                          ),
                        )
                      : Image.file(
                          File(imageUrl),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.white,
                              size: 64,
                            ),
                          ),
                        ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 30,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  TypingIndicatorState createState() => TypingIndicatorState();
}

class TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  static const List<int> _delays = [0, 200, 400]; // Staggered animation delays

  @override
  void initState() {
    super.initState();
    final baseDuration = 800 + AppConfig.getPerformanceSetting<int>('typingIndicatorDelay');
    
    // Create staggered controllers for better performance
    _controllers = List.generate(3, (index) {
      return AnimationController(
        duration: Duration(milliseconds: baseDuration),
        vsync: this,
      );
    });
    
    // Create animations with different curves for natural effect
    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();
    
    // Start animations with delays
    _startStaggeredAnimations();
  }

  void _startStaggeredAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: _delays[i]), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            child: const _TypingDot(), // Pre-built const child
            builder: (context, child) {
              return Opacity(
                opacity: _animations[index].value,
                child: child,
              );
            },
          );
        }),
      ),
    );
  }
}

// Optimized const dot widget to reduce rebuilds
class _TypingDot extends StatelessWidget {
  const _TypingDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: const BoxDecoration(
        color: Color(0xFF586e75),
        shape: BoxShape.circle,
      ),
    );
  }
}