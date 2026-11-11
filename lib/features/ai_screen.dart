import '../i18n.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ui/glass.dart';
import 'common.dart';

const _model = 'claude-sonnet-5-5';
const _keyPref = 'ai_api_key';

const _system = 'You are the assistant inside "Noor", a Bangla Islamic app. '
    'Always reply in clear, simple Bangla (Bengali script). Keep answers concise and well organised. '
    'Give Quran and hadith references only when you are confident of them, and never invent a hadith or a verse. '
    'Where scholars differ (for example between madhhabs), say so briefly. '
    'For personal or complex rulings (fatwa), give general guidance and advise the user to ask a qualified local scholar. '
    'Be respectful and kind. If a question is not about Islam or daily life, answer briefly or politely steer back.';

class _Msg {
  final bool user;
  final String text;
  const _Msg(this.user, this.text);
}

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final List<_Msg> _msgs = [];
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  String _key = '';
  bool _busy = false;

  static const _suggestions = [
    'ওযু ভঙ্গের কারণগুলো কী?',
    'যাকাত কীভাবে হিসাব করব?',
    'সফরে নামায কীভাবে পড়ব?',
    'রোযার ফিদইয়া কী?',
  ];

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadKey() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => _key = p.getString(_keyPref) ?? '');
  }

  Future<void> _editKey() async {
    final c = TextEditingController(text: _key);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: panelColor,
        title: const Text('API কী'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'এআই উত্তরের জন্য Anthropic API key লাগবে (console.anthropic.com থেকে পাবেন)। কী-টি শুধু এই ফোনেই সংরক্ষিত থাকে।',
                style: TextStyle(fontSize: 13.5, color: wh(.8), height: 1.4)),
            const SizedBox(height: 12),
            TextField(
              controller: c,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'sk-ant-...'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, c.text.trim()),
              child: const Text('সংরক্ষণ', style: TextStyle(color: kGold))),
        ],
      ),
    );
    c.dispose();
    if (result == null) return;
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyPref, result);
    if (mounted) setState(() => _key = result);
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<String> _ask() async {
    // last 12 turns, must start with a user turn
    var turns = _msgs.length > 12 ? _msgs.sublist(_msgs.length - 12) : List<_Msg>.of(_msgs);
    while (turns.isNotEmpty && !turns.first.user) {
      turns = turns.sublist(1);
    }
    final body = jsonEncode({
      'model': _model,
      'max_tokens': 1200,
      'system': _system,
      'messages': [
        for (final m in turns) {'role': m.user ? 'user' : 'assistant', 'content': m.text},
      ],
    });

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final req = await client.postUrl(Uri.parse('https://api.anthropic.com/v1/messages'));
      req.headers.set('content-type', 'application/json');
      req.headers.set('x-api-key', _key);
      req.headers.set('anthropic-version', '2023-06-01');
      req.add(utf8.encode(body));
      final res = await req.close().timeout(const Duration(seconds: 90));
      final text = await res.transform(utf8.decoder).join();
      if (res.statusCode != 200) {
        if (res.statusCode == 401) throw 'API key সঠিক নয়। আবার দিন।';
        if (res.statusCode == 429) throw 'অনেক বেশি অনুরোধ হয়েছে। একটু পরে চেষ্টা করুন।';
        String detail = '';
        try {
          detail = ((jsonDecode(text) as Map)['error'] as Map)['message'] as String;
        } catch (_) {}
        throw 'ত্রুটি (${res.statusCode}) $detail';
      }
      final j = jsonDecode(text) as Map<String, dynamic>;
      final parts = (j['content'] as List)
          .where((b) => (b as Map)['type'] == 'text')
          .map((b) => (b as Map)['text'] as String)
          .toList();
      final out = parts.join('\n').trim();
      return out.isEmpty ? 'উত্তর পাওয়া যায়নি।' : out;
    } finally {
      client.close();
    }
  }

  Future<void> _send([String? preset]) async {
    final q = (preset ?? _input.text).trim();
    if (q.isEmpty || _busy) return;
    if (_key.isEmpty) {
      await _editKey();
      if (_key.isEmpty) return;
    }
    setState(() {
      _msgs.add(_Msg(true, q));
      _busy = true;
      _input.clear();
    });
    _scrollDown();
    try {
      final answer = await _ask();
      if (mounted) setState(() => _msgs.add(_Msg(false, answer)));
    } on SocketException {
      _fail('ইন্টারনেট সংযোগ নেই।', q);
    } catch (e) {
      _fail(e is String ? e : 'উত্তর আনা যায়নি। আবার চেষ্টা করুন।', q);
    } finally {
      if (mounted) setState(() => _busy = false);
      _scrollDown();
    }
  }

  void _fail(String message, String question) {
    if (!mounted) return;
    setState(() {
      // drop the unanswered question and give it back to the input box
      if (_msgs.isNotEmpty && _msgs.last.user) _msgs.removeLast();
      _input.text = question;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      title: tr('f_ai'),
      actions: [
        IconButton(
          tooltip: 'API কী',
          icon: Icon(Icons.key_rounded, color: _key.isEmpty ? kGold : null),
          onPressed: _editKey,
        ),
        IconButton(
          tooltip: 'নতুন চ্যাট',
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _busy ? null : () => setState(_msgs.clear),
        ),
      ],
      body: Column(
        children: [
          Expanded(
            child: _msgs.isEmpty
                ? _intro()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                    itemCount: _msgs.length + (_busy ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == _msgs.length) {
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5)),
                          ),
                        );
                      }
                      return _bubble(_msgs[i]);
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: GlassCard(
              radius: 26,
              blur: 0,
              padding: const EdgeInsets.fromLTRB(16, 2, 6, 2),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'আপনার প্রশ্ন লিখুন…',
                        hintStyle: TextStyle(color: wh(.55)),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: kGold),
                    onPressed: _busy ? null : _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _intro() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      children: [
        GlassCard(
          blur: 0,
          tint: kGold,
          opacity: 0.12,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.auto_awesome_rounded, color: kGold),
                SizedBox(width: 10),
                Text('AI জিজ্ঞাসা',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 8),
              Text(
                  'ইসলামিক যেকোনো বিষয়ে প্রশ্ন করুন, বাংলায় উত্তর পাবেন। জটিল ও ব্যক্তিগত মাসআলায় অবশ্যই যোগ্য আলেমের পরামর্শ নিন; এআই ভুল করতে পারে।',
                  style: TextStyle(height: 1.5, color: wh(.85))),
              if (_key.isEmpty) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _editKey,
                  icon: const Icon(Icons.key_rounded),
                  label: const Text('API কী দিন'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('উদাহরণ প্রশ্ন', style: TextStyle(color: wh(.7))),
        const SizedBox(height: 8),
        for (final s in _suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              blur: 0,
              radius: 18,
              opacity: 0.10,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              onTap: () => _send(s),
              child: Row(
                children: [
                  Expanded(child: Text(s, style: const TextStyle(fontSize: 15.5))),
                  Icon(Icons.north_east_rounded, size: 18, color: wh(.6)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _bubble(_Msg m) {
    return Align(
      alignment: m.user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.86),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: m.user ? kGold.withOpacity(.28) : wh(.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: wh(.2)),
        ),
        child: SelectableText(m.text, style: const TextStyle(fontSize: 15.5, height: 1.55)),
      ),
    );
  }
}
