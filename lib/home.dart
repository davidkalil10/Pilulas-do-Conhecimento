import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import 'package:pilulasdoconhecimento/widgets/category_tab.dart'; // <-- seu widget customizado
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
  String carroSelecionado = "";
  String busca = "";
  String ordenacao = "Data";
  String categoriaSelecionada = "todos";
  late stt.SpeechToText _speech;
  bool _isListening = false;

  // Favoritos
  Box? _favBox;
  Set<String> favoritos = {};
  String _downloadingId = ""; // id do vídeo que está sendo baixado
  double _downloadProgress = 0.0; // progresso do download

  @override
  void initState() {
    super.initState();
    _categoriasFuture = fetchCategorias();
    _speech = stt.SpeechToText();
    _searchController.addListener(() {
      if (busca != _searchController.text) {
        setState(() {
          busca = _searchController.text;
        });
      }
    });
    _initHive();
  }

  Future<void> _initHive() async {
    _favBox = await Hive.openBox('favorites');
    setState(() {
      favoritos = Set<String>.from(_favBox!.keys);
    });
  }

  void _playVideo(TutorialVideo video) async {
    final videoTitle = video.getTitulo(context);
    final videoUrl = video.getUrl(context);

    bool isFileVideo = false;
    String localPath = "";

    // Somente para Android/iOS (não web)
    if (!kIsWeb) {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/${video.id}.mp4';
      if (File(filePath).existsSync()) {
        isFileVideo = true;
        localPath = filePath;
      }
    }

    showDialog(
      context: context,
      builder: (_) => VideoDialog(
        url: isFileVideo ? localPath : videoUrl,
        title: videoTitle,
        isFile: isFileVideo,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<Map<String, Categoria>> fetchCategorias() async {
    const String binId = '689c0085ae596e708fc8b523';
    const String url = 'https://api.jsonbin.io/v3/b/$binId/latest';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final Map<String, dynamic> record = data['record'];

        // Salva backup local do JSON em SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('categorias_json', json.encode(record));

        return record.map((key, value) =>
            MapEntry(key, Categoria.fromJson(value as Map<String, dynamic>)));
      }
    } catch (e) {
      debugPrint("Falha no fetch remoto: $e");

      // Recupera do SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final recordString = prefs.getString('categorias_json');
      if (recordString != null) {
        final Map<String, dynamic> recordMap = json.decode(recordString);
        return recordMap.map((key, value) =>
            MapEntry(key, Categoria.fromJson(value as Map<String, dynamic>)));
      }
    }
    throw Exception('Não foi possível carregar conteúdos: sem internet e sem cache local.');
  }

  DateTime _parseBrazilDate(String s) {
    final p = s.split('/');
    return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
  }

  // Filtro de vídeos por busca, categoria e ordenação
  List<TutorialVideo> _getFilteredAndSortedVideos(List<TutorialVideo> videos) {
    final languageCode = Localizations.localeOf(context).languageCode;
    List<TutorialVideo> filtered = videos.where((v) {
      // 1. Se a barra de categoria estiver em "favoritos", só mostra os favoritos
      if (categoriaSelecionada == "favoritos" && !favoritos.contains(v.id)) return false;

      // 2. Bloqueia conteúdos vazios para o idioma atual
      final titulo = v.titulo[languageCode]?.trim() ?? '';
      final subtitulo = v.subtitulo[languageCode]?.trim() ?? '';
      final url = v.url[languageCode]?.trim() ?? '';
      final categoria = v.categoria[languageCode]?.trim() ?? '';
      bool vazio = titulo.isEmpty || subtitulo.isEmpty || url.isEmpty || categoria.isEmpty;
      if (vazio) return false;

      // 3. Filtro por categoria, exceto "todos" e "favoritos"
      final catTexto = v.categoria[languageCode] ?? v.categoria['pt'] ?? '';
      if (
      categoriaSelecionada != "todos" &&
          categoriaSelecionada != "favoritos" &&
          catTexto != categoriaSelecionada
      ) return false;

      // 4. Filtro de busca
      if (busca.isEmpty) return true;
      final b = busca.toLowerCase();
      bool checkMatch(Map<String, dynamic> translations) {
        for (var text in translations.values) {
          if (text is String && text.toLowerCase().contains(b)) return true;
        }
        return false;
      }
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
      return checkMatch(v.titulo) ||
          checkMatch(v.subtitulo) ||
          checkTagsMatch(v.tags);
    }).toList();

    // Ordenação
    if (ordenacao == "Alfabética") {
      filtered.sort((a, b) => a.getTitulo(context).compareTo(b.getTitulo(context)));
    } else {
      filtered.sort((a, b) =>
          _parseBrazilDate(b.dataAtualizacao)
              .compareTo(_parseBrazilDate(a.dataAtualizacao)));
    }
    return filtered;
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == "done") {
            setState(() => _isListening = false);
          }
        },
        onError: (val) {
          setState(() => _isListening = false);
        },
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _searchController.text = val.recognizedWords;
              busca = val.recognizedWords;
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  List<String> _buildCategoriasMenu(List<TutorialVideo> videos) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final categorias = videos
        .map((v) => (v.categoria[languageCode] ?? v.categoria['pt'] ?? '').trim())
        .where((cat) => cat.isNotEmpty)
        .toSet()
        .toList();
    categorias.sort();
    return ["todos", "favoritos", ...categorias];
  }

  // Favoritar/desfavoritar + baixar vídeo se não for web
  Future<void> toggleFavorite(TutorialVideo video) async {
    print("Toggle favorito: ${video.id}");
    if (_favBox == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Favoritos não disponíveis, espere carregar..."))
      );
      return;
    }
    final isFavorite = favoritos.contains(video.id);
    if (isFavorite) {
      // Remove favorito e arquivo local
      await _favBox!.delete(video.id);
      if (!kIsWeb) {
        final dir = await getApplicationDocumentsDirectory();
        final f = File('${dir.path}/${video.id}.mp4');
        if (await f.exists()) await f.delete();
      }
      setState(() => favoritos.remove(video.id));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              kIsWeb
                  ? "Favorito removido!"
                  : "Favorito removido e arquivo de vídeo excluído."
          ),
        ),
      );
    } else {
      // Adiciona favorito e inicia download
      await _favBox!.put(video.id, true);
      setState(() => favoritos.add(video.id));
      if (!kIsWeb) {
        setState(() {
          _downloadingId = video.id;
          _downloadProgress = 0.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Baixando vídeo para acesso offline...")),
        );
        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}/${video.id}.mp4';
        try {
          await Dio().download(
            video.getUrl(context),
            filePath,
            onReceiveProgress: (received, total) {
              setState(() {
                _downloadProgress = (total > 0) ? received / total : 0;
              });
            },
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erro ao baixar o vídeo")),
          );
          await _favBox!.delete(video.id); // remove favorito se erro
          setState(() => favoritos.remove(video.id));
        }
        setState(() {
          _downloadingId = "";
          _downloadProgress = 0.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Vídeo baixado! Favorito salvo offline.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Favorito salvo!!")),
        );
      }
    }
  }

  // Checar se vídeo está baixado no Android/iOS
  Future<bool> isVideoDownloaded(TutorialVideo video) async {
    if (kIsWeb) return false;
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/${video.id}.mp4';
    return File(filePath).existsSync();
  }

  @override
  Widget build(BuildContext context) {
    final renaultGold = const Color(0xFFF6C700);
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
        if (carroSelecionado.isEmpty && categoriaNomes.isNotEmpty) {
          carroSelecionado = categoriaNomes.first;
        }
        final videos = categorias[carroSelecionado]!.videos;
        final categoriasDoMenu = _buildCategoriasMenu(videos);
        if (!categoriasDoMenu.contains(categoriaSelecionada)) {
          categoriaSelecionada = "todos";
        }
        final filtered = _getFilteredAndSortedVideos(videos);

        final menuLateralWidget = _buildMenuLateral(categorias, categoriaNomes, renaultGold, isMobile);

        return Scaffold(
          backgroundColor: Colors.black,
          drawer: isMobile ? Drawer(child: menuLateralWidget) : null,
          appBar: isMobile
              ? AppBar(
            title: Text(
                "Renault: "+AppLocalizations.of(context)!.appTitle,
                style: const TextStyle(color: Colors.white)
            ),
            backgroundColor: Colors.black,
            iconTheme: IconThemeData(color: Colors.white),
          )
              : null,
          body: SafeArea(
            child: isMobile
                ? _buildMobileLayout(filtered, renaultGold, categoriasDoMenu)
                : _buildDesktopLayout(menuLateralWidget, filtered, renaultGold, categoriasDoMenu),
          ),
        );
      },
    );
  }

  Widget _buildMenuLateral(Map<String, Categoria> categorias, List<String> categoriaNomes, Color renaultGold, bool isMobile) {
    return Container(
      width: isMobile ? 280 : 180,
      decoration: BoxDecoration(
        color: Colors.black,
        border: isMobile ? null : Border(right: BorderSide(width: 1.5, color: renaultGold)),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: renaultGold, shape: BoxShape.circle),
                    child: Image.asset('assets/logo_renault.png', height: 36, color: Colors.white, colorBlendMode: BlendMode.srcIn),
                  ),
                ),
                ...categoriaNomes.map((carro) {
                  final selected = carro == carroSelecionado;
                  final thumbnail = categorias[carro]!.thumbnail;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        carroSelecionado = carro;
                        categoriaSelecionada = "todos";
                      });
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
                            carro,
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Desenvolvido por David Kalil Braga",
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
      Widget menuLateral,
      List<TutorialVideo> filtered,
      Color renaultGold,
      List<String> categoriasDoMenu
      ) {
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
                const SizedBox(height: 18),
                _buildSearchBar(renaultGold),
                const SizedBox(height: 14),
                _buildCategoriasHorizontal(categoriasDoMenu, renaultGold),
                const SizedBox(height: 18),
                _buildCardsGrid(filtered, renaultGold, isDesktop: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
      List<TutorialVideo> filtered,
      Color renaultGold,
      List<String> categoriasDoMenu
      ) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildHeader(renaultGold),
        const SizedBox(height: 12),
        _buildSearchBar(renaultGold),
        const SizedBox(height: 12),
        _buildCategoriasHorizontal(categoriasDoMenu, renaultGold),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 50.0),
              child: Text("Nenhum vídeo encontrado.", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          )
        else
          ...filtered.map((video) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: TutorialCardPremium(
                video: video,
                renaultGold: renaultGold,
                onPlay: () => _playVideo(video),
                dark: true,
                isFavorite: favoritos.contains(video.id),
                onFavorite: () => toggleFavorite(video),
                isDownloading: _downloadingId == video.id,
                downloadProgress: _downloadProgress,
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildHeader(Color renaultGold) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo_renault.png',
              height: 50,
              color: Colors.white,
              colorBlendMode: BlendMode.srcIn,
            ),
            const SizedBox(width: 12),
            Text(
              "Renault: " + AppLocalizations.of(context)!.appTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 30,
                color: Colors.white,
                fontFamily: 'RenaultSans',
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Padding(
          padding: EdgeInsets.only(left: 5),
          child: Text(
            AppLocalizations.of(context)!.appSubtitle,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 18,
              color: Colors.white70,
              fontFamily: 'RenaultSans',
            ),
          ),
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
            style: const TextStyle(fontSize: 18, color: Colors.white),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.searchHint,
              hintStyle: const TextStyle(color: Colors.white54, fontFamily: 'RenaultSans'),
              prefixIcon: Icon(Icons.search, color: Colors.white),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? renaultGold : Colors.white54,
                    ),
                    onPressed: _listen,
                  ),
                  if (busca.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.clear, color: Colors.white54),
                      onPressed: () => _searchController.clear(),
                    ),
                ],
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
              filled: true,
              fillColor: Colors.grey[900],
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
            ),
          ),
        ),
        const SizedBox(width: 10),
        PopupMenuButton<String>(
          icon: Icon(Icons.sort, color: Colors.white, size: 30),
          onSelected: (v) => setState(() => ordenacao = v),
          itemBuilder: (ctx) => [
            PopupMenuItem(
              value: "Data",
              child: Text(AppLocalizations.of(context)!.sortByDate),
            ),
            PopupMenuItem(
              value: "Alfabética",
              child: Text(AppLocalizations.of(context)!.sortByAlphabet),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoriasHorizontal(List<String> categoriasDoMenu, Color renaultGold) {
    const double tabHeight = 38;
    const double horizontalPad = 28;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (int i = 0; i < categoriasDoMenu.length; i++) ...[
            if (categoriasDoMenu[i] == 'favoritos')
              CategoryTabIcon(
                icon: Icons.favorite,
                selected: categoriaSelecionada == 'favoritos',
                isFirst: false,
                isLast: false,
                height: tabHeight,
                horizontalPadding: horizontalPad - 6,
                onTap: () => setState(() => categoriaSelecionada = 'favoritos'),
                color: categoriaSelecionada == 'favoritos' ? Colors.white : Colors.white,
              )
            else
            CategoryTab(
              label: categoriasDoMenu[i],
              selected: categoriasDoMenu[i] == categoriaSelecionada,
              isFirst: i == 0,
              isLast: i == categoriasDoMenu.length - 1,
              height: tabHeight,
              horizontalPadding: horizontalPad,
              onTap: () => setState(() => categoriaSelecionada = categoriasDoMenu[i]),
            ),
            if (i < categoriasDoMenu.length - 1)
              Text(
                '/',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardsGrid(List<TutorialVideo> filtered, Color renaultGold, {required bool isDesktop}) {
    if (filtered.isEmpty) {
      return const Center(child: Text("Nenhum vídeo encontrado.", style: TextStyle(fontSize: 18, color: Colors.white)));
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
                  onPlay: () => _playVideo(v),
                  dark: true,
                  isFavorite: favoritos.contains(v.id),
                  onFavorite: () => toggleFavorite(v),
                  isDownloading: _downloadingId == v.id,
                  downloadProgress: _downloadProgress,
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
              onPlay: () => _playVideo(video),
              dark: true,
              isFavorite: favoritos.contains(video.id),
              onFavorite: () => toggleFavorite(video),
              isDownloading: _downloadingId == video.id,
              downloadProgress: _downloadProgress,
            ),
          );
        },
      ),
    );
  }
}