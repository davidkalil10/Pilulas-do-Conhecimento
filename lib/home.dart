import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pilulasdoconhecimento/l10n/app_localizations.dart';
import 'package:pilulasdoconhecimento/models/categoria.dart';
import 'package:pilulasdoconhecimento/models/model_video.dart';
import 'package:pilulasdoconhecimento/widgets/tutorial_card.dart';
import 'package:pilulasdoconhecimento/widgets/video_player.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late Future<Map<String, Categoria>> _categoriasFuture;
  final TextEditingController _searchController = TextEditingController();

  String categoriaSelecionada = "";
  String busca = "";
  String ordenacao = "Data";

  @override
  void initState() {
    super.initState();
    _categoriasFuture = fetchCategorias();
    // Atualiza a busca conforme o usuário digita
    _searchController.addListener(() {
      if (busca != _searchController.text) {
        setState(() {
          busca = _searchController.text;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<Map<String, Categoria>> fetchCategorias() async {

    const String binId = '689c0085ae596e708fc8b523';
    const String url = 'https://api.jsonbin.io/v3/b/$binId/latest';

    final response = await http.get(Uri.parse(
       // 'https://raw.githubusercontent.com/davidkalil10/pilulas-json/refs/heads/main/pilulas.json')); // URL CORRIGIDA PARA SEU REPO    final response = await http.get(Uri.parse(
        url)); // URL CORRIGIDA PARA SEU REPO

    /*if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data.map((key, value) =>
          MapEntry(key, Categoria.fromJson(value as Map<String, dynamic>)));
    } else {
      throw Exception('Falha ao carregar os dados');
    }*/

    if (response.statusCode == 200) {
      // O JSONBin retorna os dados dentro de uma chave "record"
      final Map<String, dynamic> data = json.decode(response.body);
      final Map<String, dynamic> record = data['record'];

      return record.map((key, value) =>
          MapEntry(key, Categoria.fromJson(value as Map<String, dynamic>)));
    } else {
      throw Exception('Falha ao carregar dados do JSONBin');
    }

  }

  DateTime _parseBrazilDate(String s) {
    final p = s.split('/');
    return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
  }

  @override
  Widget build(BuildContext context) {
    final renaultGold = const Color(0xFFF6C700);
    // Ponto de quebra para decidir o layout
    final bool isMobile = MediaQuery.of(context).size.width < 850;

    return FutureBuilder<Map<String, Categoria>>(
      future: _categoriasFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Scaffold(body: Center(child: Text("Falha ao carregar dados. Erro: ${snapshot.error}")));
        }

        final categorias = snapshot.data!;
        final categoriaNomes = categorias.keys.toList();
        if (categoriaSelecionada.isEmpty && categoriaNomes.isNotEmpty) {
          categoriaSelecionada = categoriaNomes.first;
        }

        final videos = categorias[categoriaSelecionada]!.videos;
        final filtered = _getFilteredAndSortedVideos(videos);

        // O widget do menu lateral, agora separado para ser reutilizado
        final menuLateralWidget = _buildMenuLateral(categorias, categoriaNomes, renaultGold, isMobile);

        return Scaffold(
          backgroundColor: Colors.grey[100],
          // Adiciona um Drawer (menu deslizante) no layout mobile
          drawer: isMobile ? Drawer(child: menuLateralWidget) : null,
          // Adiciona uma AppBar com botão para o Drawer no layout mobile
          appBar: isMobile
              ? AppBar(
            title: Text(
                AppLocalizations.of(context)!.appTitle, // <-- CORRIGIDO
                style: const TextStyle(color: Colors.white)
            ),
            backgroundColor: Colors.grey[900],
            iconTheme: IconThemeData(color: renaultGold),
          )
              : null,
          body: SafeArea(
            child: isMobile
                ? _buildMobileLayout(filtered, renaultGold)
                : _buildDesktopLayout(menuLateralWidget, filtered, renaultGold),
          ),
        );
      },
    );
  }

  // Lógica de filtro e ordenação, agora em um método separado
  List<TutorialVideo> _getFilteredAndSortedVideos(List<TutorialVideo> videos) {
    List<TutorialVideo> filtered = videos.where((v) {
      if (busca.isEmpty) {
        return true; // Se a busca estiver vazia, retorna todos os vídeos
      }

      final b = busca.toLowerCase();

      // Função helper para verificar se o termo de busca existe em qualquer tradução de um campo
      bool checkMatch(Map<String, dynamic> translations) {
        // itera sobre todos os valores do mapa de tradução (ex: "Ajuste Lombar", "Lumbar Adjustment", etc.)
        for (var text in translations.values) {
          if (text is String && text.toLowerCase().contains(b)) {
            return true;
          }
        }
        return false;
      }

      // Função helper para verificar as tags
      bool checkTagsMatch(Map<String, dynamic> tagTranslations) {
        for (var tagList in tagTranslations.values) {
          if (tagList is List) {
            for (var tag in tagList) {
              if (tag is String && tag.toLowerCase().contains(b)) {
                return true;
              }
            }
          }
        }
        return false;
      }

      // Aplica a verificação no título, subtítulo e tags
      return checkMatch(v.titulo) ||
          checkMatch(v.subtitulo) ||
          checkTagsMatch(v.tags);

    }).toList();

    // A lógica de ordenação não precisa mudar, pois 'titulo' ainda é acessado
    // para comparação, mas vamos usar o título no idioma atual para ordenar.
    if (ordenacao == "Alfabética") {
      filtered.sort((a, b) => a.getTitulo(context).compareTo(b.getTitulo(context)));
    } else {
      // A ordenação por data já está correta e não precisa de mudança
      filtered.sort((a, b) =>
          _parseBrazilDate(b.dataAtualizacao)
              .compareTo(_parseBrazilDate(a.dataAtualizacao)));
    }
    return filtered;
  }

  // -- MÉTODOS PARA CONSTRUIR PARTES DA UI --

  Widget _buildMenuLateral(Map<String, Categoria> categorias, List<String> categoriaNomes, Color renaultGold, bool isMobile) {
    return Container(
      width: isMobile ? 280 : 180,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: isMobile ? null : Border(right: BorderSide(width: 1.5, color: renaultGold)),
      ),
      child: Column( // A Column principal do menu
        children: [
          // O conteúdo do menu que já existe
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.amber[600], shape: BoxShape.circle),
                    child: Image.asset('assets/logo_renault.png', height: 36),
                  ),
                ),
                ...categoriaNomes.map((cat) {
                  // ... seu código para os itens de categoria vai aqui ...
                  final selected = cat == categoriaSelecionada;
                  final thumbnail = categorias[cat]!.thumbnail;
                  return InkWell(
                    onTap: () {
                      setState(() => categoriaSelecionada = cat);
                      if (isMobile) Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? Colors.grey[850] : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: thumbnail.isNotEmpty
                                ? Image.network(thumbnail, width: 72, height: 54, fit: BoxFit.cover)
                                : Icon(Icons.directions_car, size: 50, color: selected ? renaultGold : Colors.white70),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            cat,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              color: selected ? renaultGold : Colors.white,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          // ----- ADIÇÃO DA MARCA D'ÁGUA/ASSINATURA -----
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Desenvolvido por David Kalil Braga",
              style: TextStyle(
                color: Colors.white.withOpacity(0.4), // Cor discreta
                fontSize: 12, // Tamanho pequeno
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(Widget menuLateral, List<TutorialVideo> filtered, Color renaultGold) {
    return Row(
      children: [
        menuLateral,
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(renaultGold),
                const SizedBox(height: 25),
                _buildSearchBar(renaultGold),
                const SizedBox(height: 20),
                _buildCardsGrid(filtered, renaultGold, isDesktop: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(List<TutorialVideo> filtered, Color renaultGold) {
    // Usar ListView como base para garantir a rolagem e evitar overflow
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Todos os widgets agora são filhos diretos do ListView
        _buildSearchBar(renaultGold),
        const SizedBox(height: 20),

        // Se não houver vídeos, mostre a mensagem
        if (filtered.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 50.0),
              child: Text("Nenhum vídeo encontrado.", style: TextStyle(fontSize: 18)),
            ),
          )
        else
        // Se houver vídeos, construa a lista
          ...filtered.map((video) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: TutorialCardPremium(
                video: video,
                renaultGold: renaultGold,
                onPlay: () {
                  // Pega o título e a URL no idioma correto ANTES de chamar o dialog
                  final String videoTitle = video.getTitulo(context);
                  final String videoUrl = video.getUrl(context);

                  showDialog(
                    context: context,
                    builder: (_) => VideoDialog(url: videoUrl, title: videoTitle),
                  );
                },
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildHeader(Color renaultGold) {
    // Use AppLocalizations para pegar os textos traduzidos
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.appTitle, // <-- CORRIGIDO
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40, color: renaultGold),
        ),
        const SizedBox(height: 6),
        Text(
          AppLocalizations.of(context)!.appSubtitle, // <-- CORRIGIDO
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 22, color: Colors.grey[800]),
        ),
      ],
    );
  }

  Widget _buildSearchBar(Color renaultGold) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 18),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.searchHint,
              prefixIcon: Icon(Icons.search, color: renaultGold),
              suffixIcon: busca.isNotEmpty
                  ? IconButton(
                icon: Icon(Icons.clear, color: Colors.grey[600]),
                onPressed: () => _searchController.clear(),
              )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // CÓDIGO CORRIGIDO E INTERNACIONALIZADO
        PopupMenuButton<String>(
          icon: Icon(Icons.sort, color: renaultGold, size: 30),
          onSelected: (v) => setState(() => ordenacao = v),
          itemBuilder: (ctx) => [
            PopupMenuItem(
              value: "Data", // O valor interno não muda
              child: Text(AppLocalizations.of(context)!.sortByDate), // Texto traduzido
            ),
            PopupMenuItem(
              value: "Alfabética", // O valor interno não muda
              child: Text(AppLocalizations.of(context)!.sortByAlphabet), // Texto traduzido
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardsGrid(List<TutorialVideo> filtered, Color renaultGold, {required bool isDesktop}) {
    if (filtered.isEmpty) {
      return const Center(child: Text("Nenhum vídeo encontrado.", style: TextStyle(fontSize: 18)));
    }

    return Expanded(
      child: isDesktop
          ? LayoutBuilder(
        builder: (context, constraints) {
          double itemWidth = (constraints.maxWidth - 22) / 2;
          return SingleChildScrollView(
            child: Wrap(
              spacing: 22,
              runSpacing: 20,
              children: filtered.map((v) => SizedBox(
                width: itemWidth,
                child: TutorialCardPremium(
                  video: v,
                  renaultGold: renaultGold,
                  // CÓDIGO NOVO E CORRETO
                  onPlay: () {
                    // Pega o título e a URL no idioma correto ANTES de chamar o dialog
                    final String videoTitle = v.getTitulo(context);
                    final String videoUrl = v.getUrl(context);

                    showDialog(
                      context: context,
                      builder: (_) => VideoDialog(url: videoUrl, title: videoTitle),
                    );
                  },
                ),
              )).toList(),
            ),
          );
        },
      )
          : ListView.builder(
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final video = filtered[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: TutorialCardPremium(
              video: video,
              renaultGold: renaultGold,
              // CÓDIGO NOVO E CORRETO
              onPlay: () {
                // Pega o título e a URL no idioma correto ANTES de chamar o dialog
                final String videoTitle = video.getTitulo(context);
                final String videoUrl = video.getUrl(context);

                showDialog(
                  context: context,
                  builder: (_) => VideoDialog(url: videoUrl, title: videoTitle),
                );
              },
            ),
          );
        },
      ),
    );
  }
}