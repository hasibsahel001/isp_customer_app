import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

class MikrotikApiException implements Exception {
  final String message;
  MikrotikApiException(this.message);
  @override
  String toString() => message;
}

class MikrotikApiClient {
  Socket? _socket;
  final List<int> _buffer = [];
  Completer<void>? _dataWaiter;
  bool _closed = false;

  // صف پاسخ‌ها بر اساس تگ
  final Map<String, StreamController<List<String>>> _tagStreams = {};
  bool _readerRunning = false;
  int _tagCounter = 0;

  Future<void> connect(String host, int port) async {
    _socket = await Socket.connect(host, port, timeout: const Duration(seconds: 6));
    _socket!.listen(
          (data) {
        _buffer.addAll(data);
        _dataWaiter?.complete();
        _dataWaiter = null;
      },
      onError: (_) {
        _closed = true;
        _dataWaiter?.complete();
      },
      onDone: () {
        _closed = true;
        _dataWaiter?.complete();
      },
      cancelOnError: true,
    );
  }

  Future<void> _waitForData() async {
    _dataWaiter ??= Completer<void>();
    await _dataWaiter!.future;
  }

  Future<List<int>> _readBytes(int n) async {
    while (_buffer.length < n) {
      if (_closed) throw MikrotikApiException('اتصال با روتر قطع شد');
      await _waitForData();
    }
    final result = _buffer.sublist(0, n);
    _buffer.removeRange(0, n);
    return result;
  }

  List<int> _encodeLength(int length) {
    if (length < 0x80) return [length];
    if (length < 0x4000) {
      final l = length | 0x8000;
      return [(l >> 8) & 0xFF, l & 0xFF];
    }
    if (length < 0x200000) {
      final l = length | 0xC00000;
      return [(l >> 16) & 0xFF, (l >> 8) & 0xFF, l & 0xFF];
    }
    if (length < 0x10000000) {
      final l = length | 0xE0000000;
      return [(l >> 24) & 0xFF, (l >> 16) & 0xFF, (l >> 8) & 0xFF, l & 0xFF];
    }
    return [0xF0, (length >> 24) & 0xFF, (length >> 16) & 0xFF, (length >> 8) & 0xFF, length & 0xFF];
  }

  Future<int> _readLength() async {
    final b0 = (await _readBytes(1))[0];
    if (b0 & 0x80 == 0) return b0;
    if (b0 & 0xC0 == 0x80) {
      final r = await _readBytes(1);
      return ((b0 & 0x3F) << 8) + r[0];
    }
    if (b0 & 0xE0 == 0xC0) {
      final r = await _readBytes(2);
      return ((b0 & 0x1F) << 16) + (r[0] << 8) + r[1];
    }
    if (b0 & 0xF0 == 0xE0) {
      final r = await _readBytes(3);
      return ((b0 & 0x0F) << 24) + (r[0] << 16) + (r[1] << 8) + r[2];
    }
    final r = await _readBytes(4);
    return (r[0] << 24) + (r[1] << 16) + (r[2] << 8) + r[3];
  }

  Future<String> _readWord() async {
    final len = await _readLength();
    if (len == 0) return '';
    final bytes = await _readBytes(len);
    return utf8.decode(bytes, allowMalformed: true);
  }

  Future<List<String>> _readSentence() async {
    final words = <String>[];
    while (true) {
      final w = await _readWord();
      if (w.isEmpty) break;
      words.add(w);
    }
    return words;
  }

  void _writeWord(String word) {
    final bytes = utf8.encode(word);
    _socket!.add(_encodeLength(bytes.length));
    _socket!.add(bytes);
  }

  Future<void> _writeSentence(List<String> words) async {
    for (final w in words) {
      _writeWord(w);
    }
    _writeWord('');
    await _socket!.flush();
  }

  Map<String, String> parseAttrs(List<String> reply) {
    final attrs = <String, String>{};
    for (final word in reply.skip(1)) {
      if (word.startsWith('=')) {
        final eq = word.indexOf('=', 1);
        if (eq != -1) attrs[word.substring(1, eq)] = word.substring(eq + 1);
      }
    }
    return attrs;
  }

  String? _tagOf(List<String> reply) {
    for (final w in reply) {
      if (w.startsWith('.tag=')) return w.substring(5);
    }
    return null;
  }

  // خواننده مرکزی: هر جمله را به تگ خودش تحویل می‌دهد
  void _startReader() {
    if (_readerRunning) return;
    _readerRunning = true;
    () async {
      try {
        while (!_closed) {
          final sentence = await _readSentence();
          if (sentence.isEmpty) continue;
          final tag = _tagOf(sentence);
          final ctrl = _tagStreams[tag ?? ''];
          if (ctrl != null && !ctrl.isClosed) ctrl.add(sentence);
        }
      } catch (_) {
        for (final c in _tagStreams.values) {
          if (!c.isClosed) c.addError(MikrotikApiException('اتصال با روتر قطع شد'));
        }
      }
    }();
  }

  // دستور معمولی (با تگ، تا با استریم‌ها قاطی نشود)
  Future<List<Map<String, String>>> talk(List<String> sentence) async {
    _startReader();
    final tag = 't${_tagCounter++}';
    final ctrl = StreamController<List<String>>();
    _tagStreams[tag] = ctrl;

    final results = <Map<String, String>>[];
    final done = Completer<List<Map<String, String>>>();

    final sub = ctrl.stream.listen((reply) {
      final type = reply[0];
      final attrs = parseAttrs(reply);
      if (type == '!re') {
        results.add(attrs);
      } else if (type == '!trap') {
        if (!done.isCompleted) {
          done.completeError(MikrotikApiException(attrs['message'] ?? 'خطای نامشخص از روتر'));
        }
      } else if (type == '!done') {
        if (attrs.isNotEmpty) results.add(attrs);
        if (!done.isCompleted) done.complete(results);
      }
    }, onError: (e) {
      if (!done.isCompleted) done.completeError(e);
    });

    try {
      await _writeSentence([...sentence, '.tag=$tag']);
      return await done.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw MikrotikApiException('پاسخی از روتر دریافت نشد'),
      );
    } finally {
      await sub.cancel();
      _tagStreams.remove(tag);
      await ctrl.close();
    }
  }

  // استریم دائمی؛ تا وقتی cancel نشود روتر پیوسته داده می‌فرستد
  Stream<Map<String, String>> stream(List<String> sentence) {
    _startReader();
    final tag = 's${_tagCounter++}';
    final ctrl = StreamController<List<String>>();
    _tagStreams[tag] = ctrl;

    final out = StreamController<Map<String, String>>();
    ctrl.stream.listen((reply) {
      final type = reply[0];
      if (type == '!re') {
        out.add(parseAttrs(reply));
      }
    }, onError: (e) {
      if (!out.isClosed) out.addError(e);
    });

    _writeSentence([...sentence, '.tag=$tag']);

    out.onCancel = () async {
      try {
        _tagCounter++;
        await _writeSentence(['/cancel', '=tag=$tag']);
      } catch (_) {}
      _tagStreams.remove(tag);
      await ctrl.close();
    };
    return out.stream;
  }

  List<int> _hexToBytes(String hex) {
    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return bytes;
  }

  Future<void> login(String username, String password) async {
    // لاگین قبل از راه‌اندازی خواننده مرکزی و بدون تگ انجام می‌شود
    Future<List<Map<String, String>>> plain(List<String> s) async {
      await _writeSentence(s);
      final results = <Map<String, String>>[];
      while (true) {
        final reply = await _readSentence().timeout(
          const Duration(seconds: 8),
          onTimeout: () => throw MikrotikApiException('پاسخی از روتر دریافت نشد'),
        );
        if (reply.isEmpty) continue;
        final type = reply[0];
        final attrs = parseAttrs(reply);
        if (type == '!trap') {
          throw MikrotikApiException(attrs['message'] ?? 'خطای نامشخص از روتر');
        }
        if (type == '!re') results.add(attrs);
        if (type == '!done') {
          if (attrs.isNotEmpty) results.add(attrs);
          return results;
        }
      }
    }

    final result = await plain(['/login', '=name=$username', '=password=$password']);
    if (result.isNotEmpty && result.first.containsKey('ret')) {
      final challengeBytes = _hexToBytes(result.first['ret']!);
      final digest = md5.convert(<int>[0, ...utf8.encode(password), ...challengeBytes]);
      await plain(['/login', '=name=$username', '=response=00$digest']);
    }
  }

  Future<void> close() async {
    _closed = true;
    try {
      await _socket?.close();
    } catch (_) {}
    for (final c in _tagStreams.values) {
      if (!c.isClosed) await c.close();
    }
    _tagStreams.clear();
  }
}