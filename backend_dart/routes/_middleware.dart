import 'package:backend_dart/di/setup.dart';
import 'package:dart_frog/dart_frog.dart';

Handler middleware(Handler innerHandler) {
  return (context) async {
    setupDependencyInjection();
    return innerHandler(context);
  };
}
