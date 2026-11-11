import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../i18n.dart';
import '../ui/glass.dart';

/// One place to read (or download) a book.
class BookLink {
  final String label;
  final String url;

  /// true  = opens inside the app (in-app browser)
  /// false = handed over to the phone (browser / PDF app), for PDF files
  final bool inApp;
  const BookLink(this.label, this.url, {this.inApp = true});
}

class Book {
  final String title;
  final String author;
  final String about;
  final List<BookLink> links;
  const Book(this.title, this.author, this.about, this.links);
}

// ---------------------------------------------------------------------------
// To point a book at a better source, just change its links below.
// A book with several links asks which one to open (for example volume 1 / 2).
// ---------------------------------------------------------------------------

const _ihadis = BookLink('অনলাইনে পড়ুন (iHadis)', 'https://ihadis.com/');
const _archiveHadith =
    BookLink('PDF সংগ্রহ (Internet Archive)', 'https://archive.org/details/hadith-books-bangla');

/// Fallback for books without a direct link: search the web for it.
List<BookLink> _find(String title) => [
      BookLink('ইন্টারনেট আর্কাইভে খুঁজুন',
          'https://archive.org/search?query=${Uri.encodeQueryComponent(title)}'),
      BookLink('ওয়েবে খুঁজুন',
          'https://www.google.com/search?q=${Uri.encodeQueryComponent('$title বাংলা pdf')}'),
    ];

final List<Book> kBooks = <Book>[
  const Book('রিয়াদুস সালেহীন', 'ইমাম নববী (রহ.)',
      'আখলাক, ইবাদত ও দৈনন্দিন জীবনের হাদীস সংকলন', [
    BookLink('খণ্ড ১ (PDF)',
        'https://islamcontent.com/storage/contents/501/bn_01_Riadus_Salehin.pdf',
        inApp: false),
    BookLink('খণ্ড ২ (PDF)',
        'https://islamcontent.com/storage/contents/501/bn_02_Riadus_Salehin.pdf',
        inApp: false),
    _ihadis,
  ]),
  Book('আল-আরবাঈন আন-নববীয়্যাহ', 'ইমাম নববী (রহ.)',
      'দ্বীনের মূল ভিত্তিসংক্রান্ত চল্লিশটি হাদীস', [_ihadis, ..._find('আল-আরবাঈন আন-নববীয়্যাহ')]),
  const Book('সহীহ বুখারী', 'ইমাম বুখারী (রহ.)', 'সবচেয়ে প্রসিদ্ধ হাদীস সংকলন', [
    BookLink('অনলাইনে পড়ুন (iHadis)', 'https://ihadis.com/bukhari'),
    _archiveHadith,
  ]),
  const Book('সহীহ মুসলিম', 'ইমাম মুসলিম (রহ.)', 'সিহাহ সিত্তাহর অন্যতম প্রধান গ্রন্থ', [
    BookLink('অনলাইনে পড়ুন (iHadis)', 'https://ihadis.com/muslim'),
    _archiveHadith,
  ]),
  Book('হিসনুল মুসলিম', 'সাঈদ ইবনু আলী আল-কাহতানী',
      'কুরআন-সুন্নাহর দু\'আ ও যিকিরের সংকলন', _find('হিসনুল মুসলিম')),
  Book('আর-রাহীকুল মাখতূম', 'সফিউর রহমান মুবারকপুরী', 'রাসূলুল্লাহ ﷺ-এর সীরাত',
      _find('আর-রাহীকুল মাখতূম')),
  Book('তাফসীর ইবনু কাসীর', 'ইমাম ইবনু কাসীর (রহ.)', 'কুরআনের প্রসিদ্ধ তাফসীর',
      _find('তাফসীর ইবনু কাসীর')),
  Book('ফিকহুস সুন্নাহ', 'সাইয়্যিদ সাবিক (রহ.)', 'ইবাদত ও লেনদেনের মাসআলা',
      _find('ফিকহুস সুন্নাহ')),
  Book('বেহেশতী জেওর', 'আশরাফ আলী থানভী (রহ.)', 'দৈনন্দিন মাসআলা-মাসায়েল',
      _find('বেহেশতী জেওর')),
  Book('ফাযায়েলে আমল', 'যাকারিয়া কান্ধলভী (রহ.)', 'আমলের ফযীলতসংক্রান্ত সংকলন',
      _find('ফাযায়েলে আমল')),
];

Future<bool> _launch(BookLink l) async {
  final uri = Uri.parse(l.url);
  try {
    if (l.inApp) {
      final ok = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      if (ok) return true;
    }
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

/// Opens the book for reading and writes it into the reading history.
Future<void> openBook(BuildContext context, int i) async {
  final b = kBooks[i];
  BookLink? pick;
  if (b.links.length == 1) {
    pick = b.links.first;
  } else {
    pick = await showModalBottomSheet<BookLink>(
      context: context,
      backgroundColor: panelColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(b.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
            ),
            for (final l in b.links)
              ListTile(
                leading: Icon(l.inApp ? Icons.menu_book_rounded : Icons.picture_as_pdf_rounded,
                    color: kGold),
                title: Text(l.label),
                onTap: () => Navigator.pop(ctx, l),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
  if (pick == null) return;
  await KitabHistory.record(i);
  final ok = await _launch(pick);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('kt_open_fail'))));
  }
}

class HistoryEntry {
  final int book;
  final DateTime at;
  final int opens;
  const HistoryEntry(this.book, this.at, this.opens);
}

/// Which books were opened, newest first (shown on the profile page).
class KitabHistory {
  static const _key = 'kitab_history_v1';

  static Future<List<HistoryEntry>> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key);
      if (raw == null || raw.isEmpty) return [];
      final out = <HistoryEntry>[];
      for (final e in jsonDecode(raw) as List) {
        final m = e as Map;
        final b = m['b'] as int;
        if (b < 0 || b >= kBooks.length) continue;
        out.add(HistoryEntry(
            b, DateTime.fromMillisecondsSinceEpoch(m['t'] as int), (m['n'] as int?) ?? 1));
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  static Future<void> record(int book) async {
    final p = await SharedPreferences.getInstance();
    final list = await load();
    var opens = 1;
    final old = list.indexWhere((e) => e.book == book);
    if (old >= 0) {
      opens = list[old].opens + 1;
      list.removeAt(old);
    }
    list.insert(0, HistoryEntry(book, DateTime.now(), opens));
    if (list.length > 30) list.removeRange(30, list.length);
    await p.setString(
        _key,
        jsonEncode([
          for (final e in list) {'b': e.book, 't': e.at.millisecondsSinceEpoch, 'n': e.opens}
        ]));
    // Opening a book that was only "in the list" / "want to read" = reading it now.
    final s = p.getInt('kitab_$book') ?? 0;
    if (s == 0 || s == 1) await p.setInt('kitab_$book', 2);
  }
}

/// 11/11/2026  09:40 (digits follow the app language).
String formatStamp(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return localizeDigits('${two(d.day)}/${two(d.month)}/${d.year}  ${two(d.hour)}:${two(d.minute)}');
}
