import 'package:get_it/get_it.dart';

import 'api_service.dart';
import 'assigment_api_services.dart';
// Import API services here

final GetIt getIt = GetIt.instance;

class ServiceLocator {
  static void setupServices() {
    // Register API services as singletons
    getIt.registerLazySingleton<ApiService>(() => ApiService());
    getIt.registerLazySingleton<AssignmentApiServices>(() => AssignmentApiServices());
  }

  static T get<T extends Object>() {
    return getIt.get<T>();
  }
}
