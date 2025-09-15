// lib/services/car_service.dart
import 'package:flutter/services.dart';

class CarService {
  // O nome do canal DEVE ser o mesmo da MainActivity.kt
  static const MethodChannel _channel = MethodChannel('com.pilulasdoconhecimento.dev/car_info');

  /// Retorna um Map com as chaves:
  ///  - 'parked': bool
  ///  - 'property': String? (nome da property lida no Android)
  ///  - 'rawValue': String? (valor cru lido)
  ///
  /// O método lida com dois formatos possíveis do side-native:
  /// 1) um Map (recomendado pela implementação Kotlin),
  /// 2) ou um bool (compatibilidade retroativa).
  static Future<Map<String, dynamic>> getCarInfoRaw() async {
    try {
      final res = await _channel.invokeMethod('isCarParked');

      // Caso o nativo retorne um Map (Map<dynamic,dynamic>), convertemos para Map<String,dynamic>
      if (res is Map) {
        // converte keys/values para String/dynamic (seguro)
        return Map<String, dynamic>.from(res.map((k, v) => MapEntry(k.toString(), v)));
      }

      // Caso o nativo retorne apenas um bool (versões antigas), transformamos em Map
      if (res is bool) {
        return {'parked': res, 'property': null, 'rawValue': null};
      }

      // Caso inesperado, retorna fallback seguro
      return {'parked': true, 'property': null, 'rawValue': null};
    } on PlatformException catch (e) {
      // Em caso de erro de platform, log e retorna fallback seguro
      print("CarService.getCarInfoRaw - PlatformException: ${e.message}");
      return {'parked': true, 'property': null, 'rawValue': null};
    } catch (e) {
      print("CarService.getCarInfoRaw - Erro: $e");
      return {'parked': true, 'property': null, 'rawValue': null};
    }
  }

  /// Conveniência: retorna só o boolean 'parked'.
  /// Usa getCarInfoRaw() internamente.
  static Future<bool> isCarParked() async {
    final raw = await getCarInfoRaw();
    try {
      final p = raw['parked'];
      if (p is bool) return p;
      // fallback se value estiver em outro formato
      return p.toString().toLowerCase() == 'true';
    } catch (_) {
      return true; // fallback seguro
    }
  }

  static Future<List<Map<String, dynamic>>> listCarProperties() async {
    try {
      final res = await _channel.invokeMethod('listCarProperties');
      if (res is List) {
        return res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } on PlatformException catch (e) {
      print("Erro listCarProperties: ${e.message}");
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> readPropertyById(int id) async {
    try {
      final res = await _channel.invokeMethod('readPropertyById', id);
      if (res is Map) return Map<String, dynamic>.from(res.map((k,v) => MapEntry(k.toString(), v)));
      return {'propertyId': id, 'rawValue': null, 'error': 'unexpected result'};
    } on PlatformException catch (e) {
      return {'propertyId': id, 'rawValue': null, 'error': e.message};
    } catch (e) {
      return {'propertyId': id, 'rawValue': null, 'error': e.toString()};
    }
  }
}