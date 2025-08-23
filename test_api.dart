import 'lib/services/chat_service.dart';

void main() async {
  print('Testing Chat API...');
  
  final chatService = ChatService.instance;
  
  try {
    final response = await chatService.sendMessage('Hello, test message');
    
    print('Success! Response: $response');
  } catch (e) {
    print('Error: $e');
  }
}