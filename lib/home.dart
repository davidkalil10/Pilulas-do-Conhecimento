import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pilulasdoconhecimento/models/model_video.dart';
import 'package:pilulasdoconhecimento/widgets/tutorial_card.dart';
import 'package:pilulasdoconhecimento/widgets/video_player.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late Future<Map<String, List<TutorialVideo>>> _videosFuture;
  String categoriaSelecionada = "";
  String busca = "";
  String ordenacao = "Data"; // ou "Alfabética"
  TextEditingController _searchController = TextEditingController();

  Future<Map<String, List<TutorialVideo>>> fetchVideos() async {
    final response = await http.get(Uri.parse('https://raw.githubusercontent.com/davidkalil10/pilulas-json/refs/heads/main/pilulas.json'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data.map((key, value) =>
          MapEntry(key, (value as List).map((e) => TutorialVideo.fromJson(e)).toList())
      );
    } else {
      throw Exception('Falha ao carregar os vídeos');
    }
  }

  @override
  void initState() {
    super.initState();
    _videosFuture = fetchVideos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Renault Gold
    final renaultGold = const Color(0xFFF6C700);

    return FutureBuilder<Map<String, List<TutorialVideo>>>(
      future: _videosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return Center(child: CircularProgressIndicator());
        if (!snapshot.hasData) return Center(child: Text("Falha ao carregar"));

        final categorias = snapshot.data!.keys.toList();
        if (categoriaSelecionada.isEmpty && categorias.isNotEmpty)
          categoriaSelecionada = categorias[0];

        final videos = snapshot.data![categoriaSelecionada] ?? [];

        List<TutorialVideo> filtered = videos.where((v) {
          final b = busca.toLowerCase();
          return v.titulo.toLowerCase().contains(b) ||
              v.subtitulo.toLowerCase().contains(b) ||
              v.tags.any((t) => t.toLowerCase().contains(b));
        }).toList();

        if (ordenacao == "Alfabética") {
          filtered.sort((a, b) => a.titulo.compareTo(b.titulo));
        } else {
          filtered.sort((a, b) => _parseBrazilDate(b.dataAtualizacao).compareTo(_parseBrazilDate(a.dataAtualizacao)));
        }

        return Scaffold(
          backgroundColor: Colors.grey[100],
          body: SafeArea(
            child: Row(
              children: [
                // MENU LATERAL
                Container(
                  width: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    border: Border(
                      right: BorderSide(width: 1.5, color: renaultGold),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      // Mini logo Renault
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber[600],
                            shape: BoxShape.circle,
                          ),
                          child: Image.asset(
                            'assets/logo_renault.png',
                            height: 36,
                          ),
                        ),
                      ),
                      ...categorias.map((cat) {
                        final selected = cat == categoriaSelecionada;
                        return ListTile(
                          selected: selected,
                          leading: Icon(Icons.folder_open, color: selected ? renaultGold : Colors.white),
                          title: Text(
                            cat,
                            style: TextStyle(
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              color: selected ? renaultGold : Colors.white,
                              fontSize: 19,
                            ),
                          ),
                          tileColor: selected ? Colors.grey[850] : null,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          onTap: () => setState(() => categoriaSelecionada = cat),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                // CONTEÚDO PRINCIPAL
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 44, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// -- Título e Subtítulo
                        Text(
                          "Pílulas do Conhecimento.",
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold,
                            fontSize: 40,
                            color: renaultGold,
                            letterSpacing: 1.3,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Sua dose diária de aprendizado sobre seu novo Renault!",
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w500,
                            fontSize: 22,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 25),

                        /// -- Barra de Busca e Ordenação
                        Row(
                          children: [
                            // Campo de busca
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (val) => setState(() => busca = val),
                                style: TextStyle(fontSize: 18),
                                decoration: InputDecoration(
                                  hintText: 'Buscar vídeos e temas...',
                                  prefixIcon: Icon(Icons.search, color: renaultGold),
                                  // Adicione um sufixo condicional:
                                  suffixIcon: busca.isNotEmpty
                                      ? IconButton(
                                    icon: Icon(Icons.clear, color: Colors.red[600]),
                                    onPressed: () {
                                      setState(() {
                                        busca = '';
                                        _searchController.clear();
                                      });
                                    },
                                    tooltip: 'Limpar busca',
                                  )
                                      : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide(color: renaultGold, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide(color: renaultGold, width: 2),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 18),
                            // Botão de ordenação, agora bem claro
                            PopupMenuButton<String>(
                              icon: Row(
                                children: [
                                  Icon(Icons.sort, color: renaultGold),
                                  SizedBox(width: 6),
                                  Text("Ordenar", style: TextStyle(color: renaultGold, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              onSelected: (v) => setState(() => ordenacao = v),
                              itemBuilder: (ctx) => [
                                PopupMenuItem(child: Text("Por Data"), value: "Data"),
                                PopupMenuItem(child: Text("A-Z"), value: "Alfabética"),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 20),

                        // GRID CARDS
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Divide a área disponível para 2 colunas
                              double itemWidth = (constraints.maxWidth - 22) / 2;
                              return SingleChildScrollView(
                                child: Wrap(
                                  spacing: 22,
                                  runSpacing: 20,
                                  children: filtered.map((v) {
                                    return SizedBox(
                                      width: itemWidth,
                                      child: TutorialCardPremium(
                                        video: v,
                                        renaultGold: renaultGold,
                                        onPlay: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => VideoDialog(url: v.url, title: v.titulo),
                                          );
                                        },
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  DateTime _parseBrazilDate(String s) {
    final p = s.split('/');
    return DateTime(
        int.parse(p[2]), int.parse(p[1]), int.parse(p[0])
    );
  }
}

double _getCardWidth(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final horizontalPadding = 44 * 2; // (igual ao seu Padding na tela)
  final totalSpacing = 22; // espaço entre os cards (igual ao "spacing" do Wrap)
  return (screenWidth - horizontalPadding - totalSpacing) / 2;
}

double _getAspectRatio(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width < 600) return 1.05;  // mobile, cards altos
  if (width < 1200) return 1.4;  // tablet, cards médios
  return 2.0;                    // desktop, cards mais baixos
}