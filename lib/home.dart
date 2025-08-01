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

  Future<Map<String, List<TutorialVideo>>> fetchVideos() async {
    final response = await http.get(Uri.parse('https://gist.githubusercontent.com/davidkalil10/ae2000661d0ee03329703a9b4d213da3/raw/d0ef05912a1baad1c75ef6e8c4c6cc2fa762dc37/pilulas.json'));

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
  Widget build(BuildContext context) {
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
            filtered.sort((a, b) {
              // dataAtualizacao = "dd/MM/yyyy"
              final d1 = _parseBrazilDate(a.dataAtualizacao);
              final d2 = _parseBrazilDate(b.dataAtualizacao);
              return d2.compareTo(d1);
            });
          }

          return Scaffold(
            backgroundColor: Colors.grey[200],
            body: SafeArea(
              child: Row(
                children: [
                  // Menu lateral com as categorias
                  Container(
                    width: 140,
                    color: Colors.blueGrey[50],
                    child: ListView(
                      children: categorias.map((cat) {
                        final selected = cat == categoriaSelecionada;
                        return ListTile(
                          selected: selected,
                          leading: Icon(Icons.folder, color: selected ? Colors.blue : null),
                          title: Text(cat, style: TextStyle(fontWeight: FontWeight.bold)),
                          onTap: () => setState(() => categoriaSelecionada = cat),
                        );
                      }).toList(),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// Barra de Busca e opções de ordenação
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  onChanged: (val) => setState(() => busca = val),
                                  decoration: InputDecoration(
                                    hintText: 'Buscar vídeos...',
                                    prefixIcon: Icon(Icons.search),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    fillColor: Colors.white,
                                    filled: true,
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              DropdownButton(
                                value: ordenacao,
                                items: [
                                  DropdownMenuItem(child: Text("Data"), value: "Data"),
                                  DropdownMenuItem(child: Text("Alfabética"), value: "Alfabética"),
                                ],
                                onChanged: (val) => setState(() => ordenacao = val as String),
                              ),
                            ],
                          ),
                          SizedBox(height: 24),
                          /// Grid de cards
                          Expanded(
                            child: GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 16/9,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, i) {
                                final v = filtered[i];
                                return TutorialCard(
                                  video: v,
                                  onTap: () => showDialog(
                                    context: context,
                                    builder: (_) => VideoDialog(url: v.url, title: v.titulo),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        }
    );
  }

  DateTime _parseBrazilDate(String s) {
    final p = s.split('/');
    return DateTime(
        int.parse(p[2]), int.parse(p[1]), int.parse(p[0])
    );
  }
}
