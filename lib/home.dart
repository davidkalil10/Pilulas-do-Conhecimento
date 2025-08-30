import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pilulasdoconhecimento/car_selection_screen.dart';
import 'package:pilulasdoconhecimento/widgets/device_info.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pilulasdoconhecimento/services/car_service.dart';
import 'package:pilulasdoconhecimento/widgets/category_tab.dart';
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
  bool _isCarParked = true; // Começa como true (seguro)
  Box? _favBox;
  Set<String> favoritos = {};
  String _downloadingId = "";
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    // Carrega o último carro selecionado das SharedPreferences
    _loadSelectedCar();
    _checkDrivingState(); // Chama a verificação quando a tela inicia
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

  Future<void> _checkDrivingState() async {
    final bool parked = await CarService.isCarParked();
    if (mounted) {
      setState(() {
        _isCarParked = parked;
      });
    }
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

  // Função para navegar para a tela de seleção de carro
  void _navigateToCarSelection() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => CarSelectionScreen()),
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('categorias_json', json.encode(record));
        return record.map((key, value) =>
            MapEntry(key, Categoria.fromJson(value as Map<String, dynamic>)));
      }
    } catch (e) {
      debugPrint("Falha no fetch remoto: $e");
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

  List<TutorialVideo> _getFilteredAndSortedVideos(List<TutorialVideo> videos) {
    final languageCode = Localizations.localeOf(context).languageCode;
    List<TutorialVideo> filtered = videos.where((v) {
      if (categoriaSelecionada == "favoritos" && !favoritos.contains(v.id)) return false;
      final titulo = v.titulo[languageCode]?.trim() ?? '';
      final subtitulo = v.subtitulo[languageCode]?.trim() ?? '';
      final url = v.url[languageCode]?.trim() ?? '';
      final categoria = v.categoria[languageCode]?.trim() ?? '';
      if (titulo.isEmpty || subtitulo.isEmpty || url.isEmpty || categoria.isEmpty) return false;
      final catTexto = v.categoria[languageCode] ?? v.categoria['pt'] ?? '';
      if (categoriaSelecionada != "todos" && categoriaSelecionada != "favoritos" && catTexto != categoriaSelecionada) return false;
      if (busca.isEmpty) return true;
      final b = busca.toLowerCase();
      bool checkMatch(Map<String, dynamic> translations) => translations.values.any((text) => text is String && text.toLowerCase().contains(b));
      bool checkTagsMatch(Map<String, dynamic> tagTranslations) => tagTranslations.values.any((tagList) => tagList is List && tagList.any((tag) => tag is String && tag.toLowerCase().contains(b)));
      return checkMatch(v.titulo) || checkMatch(v.subtitulo) || checkTagsMatch(v.tags);
    }).toList();

    if (ordenacao == "Alfabética") {
      filtered.sort((a, b) => a.getTitulo(context).compareTo(b.getTitulo(context)));
    } else {
      filtered.sort((a, b) => _parseBrazilDate(b.dataAtualizacao).compareTo(_parseBrazilDate(a.dataAtualizacao)));
    }
    return filtered;
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => {if (val == "done") setState(() => _isListening = false)},
        onError: (val) => setState(() => _isListening = false),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (val) => setState(() => _searchController.text = val.recognizedWords));
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

  Future<void> toggleFavorite(TutorialVideo video) async {
    if (_favBox == null) return;
    final isFavorite = favoritos.contains(video.id);
    if (isFavorite) {
      await _favBox!.delete(video.id);
      if (!kIsWeb) {
        final dir = await getApplicationDocumentsDirectory();
        final f = File('${dir.path}/${video.id}.mp4');
        if (await f.exists()) await f.delete();
      }
      setState(() => favoritos.remove(video.id));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(kIsWeb ? "Favorito removido!" : "Favorito removido e vídeo offline excluído.")));
    } else {
      await _favBox!.put(video.id, true);
      setState(() => favoritos.add(video.id));
      if (!kIsWeb) {
        setState(() { _downloadingId = video.id; _downloadProgress = 0.0; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Baixando vídeo para acesso offline...")));
        try {
          final dir = await getApplicationDocumentsDirectory();
          await Dio().download(video.getUrl(context), '${dir.path}/${video.id}.mp4', onReceiveProgress: (received, total) {
            setState(() => _downloadProgress = (total > 0) ? received / total : 0);
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Vídeo baixado! Favorito salvo.")));
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao baixar o vídeo.")));
          await _favBox!.delete(video.id);
          setState(() => favoritos.remove(video.id));
        } finally {
          setState(() { _downloadingId = ""; _downloadProgress = 0.0; });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Favorito salvo!")));
      }
    }
  }

  Future<void> _loadSelectedCar() async {
    final prefs = await SharedPreferences.getInstance();
    final String? selectedCar = prefs.getString('selectedCar');

    // Se um carro foi encontrado no SharedPreferences, atualiza o estado.
    if (selectedCar != null) {
      // Usamos 'mounted' para garantir que o widget ainda existe antes de chamar setState.
      if (mounted) {
        setState(() {
          carroSelecionado = selectedCar;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final renaultGold = const Color(0xFFF6C700);
    final bool isMobile = MediaQuery.of(context).size.width < 850;

    return FutureBuilder<Map<String, Categoria>>(
      future: _categoriasFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Scaffold(backgroundColor: Colors.black, body: Center(child: Text("Falha ao carregar dados. Erro: ${snapshot.error}", style: TextStyle(color: Colors.white))));
        }
        final categorias = snapshot.data!;
        final categoriaNomes = categorias.keys.toList();

        // Lógica de seleção inicial do carro.
        // Isso precisará ser integrado com a sua CarSelectionScreen.
        if (carroSelecionado.isEmpty && categoriaNomes.isNotEmpty) {
          carroSelecionado = categoriaNomes.first;
        }

        final videos = categorias[carroSelecionado]?.videos ?? [];
        final categoriasDoMenu = _buildCategoriasMenu(videos);
        if (!categoriasDoMenu.contains(categoriaSelecionada)) {
          categoriaSelecionada = "todos";
        }
        final filtered = _getFilteredAndSortedVideos(videos);

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: isMobile ? AppBar(
            automaticallyImplyLeading: false, // Remove o botão de voltar/menu padrão
            title: Row(
              children: [
                Image.asset(
                  'assets/logo_renault.png',
                  height: 40,
                  color: Colors.white,
                  colorBlendMode: BlendMode.srcIn,
                ),
                Text( //aqui
                    AppLocalizations.of(context)!.appTitle + " Renault",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                ),
              ],
            ),
            /*leading: Padding(
              padding:  EdgeInsets.only(left: 5),
              child: Image.asset(
                'assets/logo_renault.png',
                height: 50,
                color: Colors.white,
                colorBlendMode: BlendMode.srcIn,
              ),
            ),*/
            backgroundColor: Colors.black,
            actions: [
              TextButton.icon(
                onPressed: _navigateToCarSelection,
                onLongPress: () => showDeviceInfoDialog(context),
                icon: Icon(Icons.directions_car_outlined, color: Colors.white, size: 20),
                label: Text(
                  AppLocalizations.of(context)!.appCarSelectionTitle,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(foregroundColor: Colors.white.withOpacity(0.8)),
              ),
              const SizedBox(width: 8),
            ],
          ) : null,
          body: SafeArea(
            child: isMobile
                ? _buildMobileLayout(filtered, renaultGold, categoriasDoMenu)
                : _buildDesktopLayout(filtered, renaultGold, categoriasDoMenu),
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout(List<TutorialVideo> filtered, Color renaultGold, List<String> categoriasDoMenu) {
    return Padding(
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
    );
  }

  Widget _buildMobileLayout(List<TutorialVideo> filtered, Color renaultGold, List<String> categoriasDoMenu) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Padding( // Subtítulo para mobile
          padding: EdgeInsets.only(left: 5, bottom: 8),
          child: Text(
            AppLocalizations.of(context)!.appSubtitle,
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18, color: Colors.white70),
          ),
        ),
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
          ...filtered.map((video) => Padding(
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
          )).toList(),
      ],
    );
  }

  Widget _buildHeader(Color renaultGold) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset('assets/logo_renault.png', height: 35, color: Colors.white),
        const SizedBox(width: 16),
        Text(
          AppLocalizations.of(context)!.appTitle + " Renault",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: Colors.white),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: _navigateToCarSelection,
          onLongPress: () => showDeviceInfoDialog(context),
          icon: Icon(Icons.directions_car_outlined, color: Colors.white, size: 20),
          label: Text(
            AppLocalizations.of(context)!.appCarSelectionTitle,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF2d2d2d),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: Icon(Icons.search, color: Colors.white),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? renaultGold : Colors.white54),
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
            PopupMenuItem(value: "Data", child: Text(AppLocalizations.of(context)!.sortByDate)),
            PopupMenuItem(value: "Alfabética", child: Text(AppLocalizations.of(context)!.sortByAlphabet)),
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
      return const Expanded(child: Center(child: Text("Nenhum vídeo encontrado.", style: TextStyle(fontSize: 18, color: Colors.white))));
    }
    return Expanded(
      child: isDesktop
          ? LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = (constraints.maxWidth / 400).floor().clamp(1, 4);
          double spacing = 22.0;
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: 1.6,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final video = filtered[index];
              return TutorialCardPremium(
                video: video,
                renaultGold: renaultGold,
                onPlay: () => _playVideo(video),
                dark: true,
                isFavorite: favoritos.contains(video.id),
                onFavorite: () => toggleFavorite(video),
                isDownloading: _downloadingId == video.id,
                downloadProgress: _downloadProgress,
              );
            },
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