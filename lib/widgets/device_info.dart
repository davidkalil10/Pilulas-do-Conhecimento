import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Para checar se é Web
import 'dart:io'; // Para checar se é Android

// --- FUNÇÕES DE LÓGICA (AGORA FORA DA CLASSE) ---

/// Obtém as informações do dispositivo e exibe um AlertDialog.
///
/// Pode ser chamada de qualquer lugar do app que tenha um `BuildContext`.
Future<void> showDeviceInfoDialog(BuildContext context) async {
  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  Map<String, dynamic> deviceData = <String, dynamic>{};

  try {
    // Verifica a plataforma e chama a função correspondente
    if (kIsWeb) {
      deviceData = _readWebBrowserInfo(await deviceInfoPlugin.webBrowserInfo);
    } else if (Platform.isAndroid) {
      deviceData = _readAndroidDeviceInfo(await deviceInfoPlugin.androidInfo);
    } else {
      deviceData = {'Plataforma': 'Não suportada'};
    }
  } catch (e) {
    deviceData = {'Erro': 'Falha ao obter informações do dispositivo: $e'};
  }

  // Garante que o widget que chamou ainda está montado
  if (!context.mounted) return;

  // Exibe o AlertDialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Informações do Dispositivo"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: deviceData.entries.map((entry) {
              final value = entry.value;
              String displayValue;
              if (value is List) {
                displayValue = value.join(', ');
              } else {
                displayValue = value.toString();
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    children: [
                      TextSpan(
                        text: '${entry.key}: ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: displayValue),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Fechar'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

/// Extrai e formata dados específicos do Android.
Map<String, dynamic> _readAndroidDeviceInfo(AndroidDeviceInfo info) {
  return {
    'Modelo': info.model,
    'Marca': info.brand,
    'Fabricante': info.manufacturer,
    'Dispositivo (código)': info.device,
    'Produto': info.product,
    'É Físico?': info.isPhysicalDevice,
    'Versão do Android': info.version.release,
    'Nível SDK': info.version.sdkInt,
    'Patch de Segurança': info.version.securityPatch,
    'Placa (Board)': info.board,
    'Hardware': info.hardware,
    'Fingerprint': info.fingerprint,
    'ABIs Suportadas': info.supportedAbis,
    'Recursos do Sistema': info.systemFeatures,
  };
}

/// Extrai e formata dados específicos da Web.
Map<String, dynamic> _readWebBrowserInfo(WebBrowserInfo info) {
  return {
    'Navegador': info.browserName.name,
    'User Agent': info.userAgent,
    'Plataforma': info.platform,
    'Vendedor': info.vendor,
    'Linguagem': info.language,
    'Núcleos (hardwareConcurrency)': info.hardwareConcurrency,
  };
}

