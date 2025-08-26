import 'package:get_it/get_it.dart';
import '../../services/chat_service.dart';
import '../../services/image_chat_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/app_lifecycle_service.dart';
import '../../services/permission_service.dart';
import '../../services/api_service.dart';
import '../../services/money_service.dart';
import '../../features/chat/cubit/chat_cubit.dart';

final GetIt sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // Core Services - Singletons that live for the entire app lifecycle
  sl.registerLazySingleton<ApiService>(() => ApiService.instance);
  sl.registerLazySingleton<ChatService>(() => ChatService.instance);
  sl.registerLazySingleton<ImageChatService>(() => ImageChatService.instance);
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService.instance);
  sl.registerLazySingleton<AppLifecycleService>(() => AppLifecycleService.instance);
  sl.registerLazySingleton<PermissionService>(() => PermissionService.instance);
  
  // Money Services (unified wallet + payments)
  sl.registerLazySingleton<MoneyService>(() => MoneyService());
  
  // Presentation Layer - Cubits (Factories for state management)
  sl.registerFactory<ChatCubit>(
    () => ChatCubit(
      chatService: sl<ChatService>(),
      imageChatService: sl<ImageChatService>(),
      appLifecycleService: sl<AppLifecycleService>(),
      connectivityService: sl<ConnectivityService>(),
    ),
  );
}

/// Convenience method to reset dependencies (useful for testing)
Future<void> resetDependencies() async {
  await sl.reset();
}