import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pilulasdoconhecimento/l10n/app_localizations.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pilulasdoconhecimento/home.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// Um modelo simples para guardar a informação do carro
class CarInfo {
  final String name;
  final String thumbnailUrl;

  CarInfo({required this.name, required this.thumbnailUrl});
}

class CarSelectionScreen extends StatefulWidget {
  const CarSelectionScreen({Key? key}) : super(key: key);

  @override
  State<CarSelectionScreen> createState() => _CarSelectionScreenState();
}

class _CarSelectionScreenState extends State<CarSelectionScreen> {
  late Future<List<CarInfo>> _carsFuture;

  @override
  void initState() {
    super.initState();
    _carsFuture = _fetchCars();
  }

  //retonar a url para testar container
  String getBaseUrl() {

    const String binId = '689c0085ae596e708fc8b523';
    const String url = 'https://api.jsonbin.io/v3/b/$binId/latest';
   // const String url = "https://pilulas-backend-latest.onrender.com";

    // Para testes locais, usamos endereços diferentes dependendo da plataforma.
    // kIsWeb é para Flutter Web.
    if (kIsWeb) {
     // return 'http://localhost:8000';
      return url;
    }

    // Platform.is... é para apps nativos.
    if (Platform.isAndroid) {
      // O emulador Android usa este IP especial para acessar o 'localhost' da sua máquina.
     // return 'http://10.0.2.2:8000';
    return url;
    }

    // Para outras plataformas como Windows/macOS/Linux Desktop
   // return 'http://localhost:8000';
    return url;
  }

  // Função para buscar apenas os nomes e thumbnails dos carros
  Future<List<CarInfo>> _fetchCars() async {

    final String baseUrl = getBaseUrl();
   // final String url = '$baseUrl/conteudo'; // para o docker
    final String url = baseUrl; //para o jsonbin

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final Map<String, dynamic> record = data['record'];

      return record.entries.map((entry) {
        return CarInfo(
          name: entry.key,
          thumbnailUrl: entry.value['categoria_thumbnail'] ?? '',
        );
      }).toList();
    } else {
      throw Exception('Falha ao carregar a lista de carros');
    }
  }

  // Salva o carro selecionado e navega para a Home
  void _selectCar(String carName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedCar', carName);

    // Usa pushReplacement para que o usuário não possa voltar para esta tela com o botão "back"
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => Home()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ---- LÓGICA RESPONSIVA ----
    final double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 2; // Padrão para telas pequenas
    double childAspectRatio = 0.8; // Deixa os cards mais altos que largos

    if (screenWidth > 1200) {
      crossAxisCount = 4; // Telas muito largas
      childAspectRatio = 0.9;
    } else if (screenWidth > 700) {
      crossAxisCount = 3; // Telas de tablet/web médias
      childAspectRatio = 0.85;
    }
    // ----------------------------

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0), // Ajuste de padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              Row(
                children: [
                  Image.asset('assets/logo_renault.png', height: 70, color: Colors.white),
                  const SizedBox(width: 16),
                  Text(
                    AppLocalizations.of(context)!.appTitle + " Renault",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Textos de boas-vindas
              Text(
                AppLocalizations.of(context)!.carSelectionWelcomeTitle,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.carSelectionWelcomeSubtitle,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              // Grid de carros
              Expanded(
                child: FutureBuilder<List<CarInfo>>(
                  future: _carsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFFF6C700)));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Erro ao carregar carros: ${snapshot.error}', style: TextStyle(color: Colors.red)));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('Nenhum carro encontrado.'));
                    }
                    final cars = snapshot.data!;
                    return GridView.builder(
                      // Usa as variáveis responsivas que calculamos
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemCount: cars.length,
                      itemBuilder: (context, index) {
                        return _CarCard(
                          car: cars[index],
                          onTap: () => _selectCar(cars[index].name),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget para o card do carro, para manter o código limpo
class _CarCard extends StatelessWidget {
  final CarInfo car;
  final VoidCallback onTap;

  const _CarCard({required this.car, required this.onTap, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: Colors.grey[900],
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Imagem do carro
              Image.network(
                car.thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.directions_car, size: 50)),
              ),
              // Gradiente para escurecer a parte de baixo e dar legibilidade ao texto
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                    ),
                  ),
                ),
              ),
              // Nome do carro
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Text(
                  car.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}