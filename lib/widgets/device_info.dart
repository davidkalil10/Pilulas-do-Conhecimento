import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Para checar se é Web
import 'dart:io';

import '../services/car_service.dart'; // Para checar se é Android

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
          ElevatedButton(
            onPressed: () async {
              // 1) pega a lista de propriedades expostas
              final props = await CarService.listCarProperties();

              // 2) buffer para montar o texto final
              final buffer = StringBuffer();
              buffer.writeln('Scanning ${props.length} properties...');
              print('Scanning ${props.length} properties...');

              // 3) itera por cada propriedade; se tiver propertyId, solicita o valor
              for (final p in props) {
                try {
                  final id = p['propertyId'];
                  final name = p['propertyName'] ?? '(sem nome)';
                  final rawClass = p['rawObjectClass'] ?? '';

                  if (id is int) {
                    // chama o método nativo para ler o valor desta propriedade
                    final map = await CarService.readPropertyById(id);
                    final rawValue = map['rawValue'];
                    final error = map['error'];

                    final line = '$id | $name | class=$rawClass | raw=$rawValue${error != null ? ' | error=$error' : ''}';
                    // imprime no console (Logcat)
                    print(line);
                    // adiciona ao buffer para o dialog
                    buffer.writeln(line);
                  } else {
                    // sem id válido, só mostra metadados
                    final line = '${p['propertyId']} | $name | class=$rawClass (no id)';
                    print(line);
                    buffer.writeln(line);
                  }
                } catch (e, st) {
                  final errLine = 'Erro lendo propriedade item: $e';
                  print(errLine);
                  print(st);
                  buffer.writeln(errLine);
                }
              }

              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Scan de propriedades (resultado)'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: SingleChildScrollView(
                      child: SelectableText(buffer.toString()),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Fechar'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Scan e ler propriedades'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[850],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 440),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 20, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo opcional — descomente se tiver o asset
                            // Image.asset('assets/logo_renault.png', height: 36, color: Colors.white, colorBlendMode: BlendMode.srcIn),

                            const SizedBox(height: 6),
                            const Text(
                              'Desenvolvedor',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Desenvolvedor e idealizador do app:',
                              style: TextStyle(fontSize: 14, color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'David Kalil Braga',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 18),
                            TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: const Color(0xFFF6C700),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Fechar'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            child: const Text('Sobre o App'),
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

