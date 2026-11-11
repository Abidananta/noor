import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../ui/glass.dart';
import 'common.dart';
import 'kitab_data.dart';

/// Opens a PDF book on its own page (like a surah opens in the Quran reader).
/// The file is downloaded once, then read from the phone (works offline, and
/// remembers the last page).
Future<void> openBook(BuildContext context, Book b) async {
  await KitabHistory.record(b);
  if (!context.mounted) return;
  await Navigator.push(context, MaterialPageRoute(builder: (_) => KitabReaderScreen(book: b)));
}

class KitabReaderScreen extends StatefulWidget {
  final Book book;
  const KitabReaderScreen({super.key, required this.book});

  @override
  State<KitabReaderScreen> createState() => _KitabReaderScreenState();
}

class _KitabReaderScreenState extends State<KitabReaderScreen> {
  final PdfViewerController _ctl = PdfViewerController();
  File? _file;
  double _progress = 0; // 0..1, -1 = unknown size
  String? _error;
  int _startPage = 1;
  int _page = 1;
  int _pages = 0;
  bool _restored = false;
  HttpClient? _client;

  String get _pageKey => 'kitab_p_${widget.book.file}';

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void dispose() {
    _client?.close(force: true);
    super.dispose();
  }

  Future<void> _prepare() async {
    setState(() {
      _error = null;
      _progress = 0;
    });
    try {
      final p = await SharedPreferences.getInstance();
      _startPage = p.getInt(_pageKey) ?? 1;

      final dir = await getApplicationSupportDirectory();
      final folder = Directory('${dir.path}/kitab');
      if (!await folder.exists()) await folder.create(recursive: true);
      final f = File('${folder.path}/${widget.book.file}');

      // Already downloaded (and complete) -> open straight away.
      if (await f.exists() && await f.length() > 0) {
        if (mounted) setState(() => _file = f);
        return;
      }

      final tmp = File('${f.path}.part');
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
      _client = client;
      final req = await client.getUrl(Uri.parse(widget.book.url));
      final res = await req.close();
      if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
      final total = res.contentLength;
      var got = 0;
      final sink = tmp.openWrite();
      try {
        await for (final chunk in res.timeout(const Duration(seconds: 30))) {
          sink.add(chunk);
          got += chunk.length;
          if (mounted) setState(() => _progress = total > 0 ? got / total : -1);
        }
      } finally {
        await sink.close();
      }
      await tmp.rename(f.path);
      if (mounted) setState(() => _file = f);
    } catch (e) {
      if (mounted) setState(() => _error = 'বইটি ডাউনলোড করা যায়নি। ইন্টারনেট দেখে আবার চেষ্টা করুন।');
    }
  }

  Future<void> _savePage(int n) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_pageKey, n);
  }

  Future<void> _deleteAndRetry() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final f = File('${dir.path}/kitab/${widget.book.file}');
      if (await f.exists()) await f.delete();
    } catch (_) {}
    if (mounted) setState(() => _file = null);
    _prepare();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.book;
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(b.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            if (_pages > 0)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(bnDigits('$_page/$_pages'),
                      style: TextStyle(fontSize: 14, color: wh(.8))),
                ),
              ),
          ],
        ),
        body: _body(),
      ),
    );
  }

  Widget _body() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 48, color: wh(.6)),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: wh(.85))),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _prepare,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('আবার চেষ্টা করুন'),
              ),
            ],
          ),
        ),
      );
    }
    final f = _file;
    if (f == null) {
      final pct = _progress >= 0 ? (_progress * 100).round() : null;
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('বই ডাউনলোড হচ্ছে…', style: TextStyle(fontSize: 16, color: wh(.9))),
              const SizedBox(height: 14),
              LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                color: kGold,
                backgroundColor: wh(.2),
                borderRadius: BorderRadius.circular(6),
                minHeight: 6,
              ),
              const SizedBox(height: 8),
              Text(
                  pct == null
                      ? widget.book.sizeText
                      : '${bnDigits('$pct')}%  ${widget.book.sizeText.isEmpty ? '' : '· ${bnDigits(widget.book.sizeText)}'}',
                  style: TextStyle(fontSize: 13, color: wh(.65))),
              const SizedBox(height: 10),
              Text('একবার ডাউনলোড হলে পরে অফলাইনেও পড়তে পারবেন।',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: wh(.5))),
            ],
          ),
        ),
      );
    }
    return SfPdfViewer.file(
      f,
      controller: _ctl,
      pageSpacing: 6,
      onDocumentLoaded: (d) {
        if (!mounted) return;
        setState(() => _pages = d.document.pages.count);
        if (!_restored && _startPage > 1 && _startPage <= d.document.pages.count) {
          _restored = true;
          _ctl.jumpToPage(_startPage);
        }
      },
      onDocumentLoadFailed: (_) {
        // A broken / partial file: remove it and download again.
        _deleteAndRetry();
      },
      onPageChanged: (d) {
        _page = d.newPageNumber;
        if (mounted) setState(() {});
        _savePage(d.newPageNumber);
      },
    );
  }
}
