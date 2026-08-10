// lib/pages/auth/register_page.dart
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// KanaInputFormatter
/// - カタカナを自動でひらがなに変換する
/// - ひらがな・カタカナ・スペース以外の文字を入力させない
class KanaInputFormatter extends TextInputFormatter {
  String _katakanaToHiragana(String s) {
    final buffer = StringBuffer();
    for (final r in s.runes) {
      if (r >= 0x30A1 && r <= 0x30F6) {
        buffer.writeCharCode(r - 0x60);
      } else {
        buffer.write(String.fromCharCode(r));
      }
    }
    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final converted = _katakanaToHiragana(newValue.text);
    final filtered = StringBuffer();
    for (final r in converted.runes) {
      final ch = String.fromCharCode(r);
      if (RegExp(r'[\u3040-\u309F\s]').hasMatch(ch)) {
        filtered.write(ch);
      }
    }
    final resultText = filtered.toString();
    final selectionIndex = resultText.length;
    return TextEditingValue(
      text: resultText,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();      // 漢字などの表示名
  final _kanaController = TextEditingController();      // ふりがな（かな）入力（ローマ字化に使用）
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _workerIdController = TextEditingController();  // 自動生成（表示のみ）

  DateTime? _selectedBirthday;
  final String _selectedRole = 'worker';
  bool _isLoading = false;
  bool _showGenbaInfo = false;

  @override
  void initState() {
    super.initState();
    _kanaController.addListener(_onKanaOrNameChanged);
    _nameController.addListener(_onKanaOrNameChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _kanaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _workerIdController.dispose();
    super.dispose();
  }

  // --- IME対応のひらがなサニタイズユーティリティ ---
  String _katakanaToHiragana(String s) {
    final buffer = StringBuffer();
    for (final r in s.runes) {
      if (r >= 0x30A1 && r <= 0x30F6) {
        buffer.writeCharCode(r - 0x60);
      } else {
        buffer.write(String.fromCharCode(r));
      }
    }
    return buffer.toString();
  }

  String _filterToHiragana(String s) {
    final converted = _katakanaToHiragana(s);
    final buffer = StringBuffer();
    for (final r in converted.runes) {
      final ch = String.fromCharCode(r);
      if (RegExp(r'[\u3040-\u309F\s]').hasMatch(ch)) {
        buffer.write(ch);
      }
    }
    return buffer.toString();
  }

  void _onKanaChangedWithImeSupport(String value) {
    final composing = _kanaController.value.composing;
    if (composing.isValid && composing.isCollapsed == false) {
      return;
    }

    final sanitized = _filterToHiragana(value);
    if (sanitized == value) return;

    _kanaController.value = TextEditingValue(
      text: sanitized,
      selection: TextSelection.collapsed(offset: sanitized.length.clamp(0, sanitized.length)),
      composing: TextRange.empty,
    );

    final birthday = _selectedBirthday;
    if (sanitized.isNotEmpty && birthday != null) {
      final base = _buildWorkerIdFromKana(sanitized, birthday);
      _generateAndSetWorkerId(base);
    } else {
      _workerIdController.clear();
    }
  }

  // かな -> ローマ字変換（内部実装）
  String _kanaToRomaji(String input) {
    if (input.isEmpty) return '';
    final hiragana = _katakanaToHiragana(input);
    String s = hiragana.trim();
    final buffer = StringBuffer();
    final chars = s.runes.toList();
    for (int i = 0; i < chars.length; i++) {
      final ch = String.fromCharCode(chars[i]);
      if (ch == 'っ') {
        if (i + 1 < chars.length) {
          final next = String.fromCharCode(chars[i + 1]);
          final romNext = _singleKanaToRomaji(next);
          if (romNext.isNotEmpty) {
            final firstChar = romNext[0];
            buffer.write(firstChar);
          }
        }
        continue;
      }
      if (i + 1 < chars.length) {
        final pair = ch + String.fromCharCode(chars[i + 1]);
        final romPair = _yoonToRomaji(pair);
        if (romPair != null) {
          buffer.write(romPair);
          i++;
          continue;
        }
      }
      if (ch == 'ー') continue;
      final rom = _singleKanaToRomaji(ch);
      if (rom.isNotEmpty) buffer.write(rom);
    }
    final cleaned = buffer.toString().replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toLowerCase();
    return cleaned;
  }

  String _singleKanaToRomaji(String kana) {
    const map = {
      'あ': 'a', 'い': 'i', 'う': 'u', 'え': 'e', 'お': 'o',
      'か': 'ka', 'き': 'ki', 'く': 'ku', 'け': 'ke', 'こ': 'ko',
      'さ': 'sa', 'し': 'shi', 'す': 'su', 'せ': 'se', 'そ': 'so',
      'た': 'ta', 'ち': 'chi', 'つ': 'tsu', 'て': 'te', 'と': 'to',
      'な': 'na', 'に': 'ni', 'ぬ': 'nu', 'ね': 'ne', 'の': 'no',
      'は': 'ha', 'ひ': 'hi', 'ふ': 'fu', 'へ': 'he', 'ほ': 'ho',
      'ま': 'ma', 'み': 'mi', 'む': 'mu', 'め': 'me', 'も': 'mo',
      'や': 'ya', 'ゆ': 'yu', 'よ': 'yo',
      'ら': 'ra', 'り': 'ri', 'る': 'ru', 'れ': 're', 'ろ': 'ro',
      'わ': 'wa', 'を': 'o', 'ん': 'n',
      'が': 'ga', 'ぎ': 'gi', 'ぐ': 'gu', 'げ': 'ge', 'ご': 'go',
      'ざ': 'za', 'じ': 'ji', 'ず': 'zu', 'ぜ': 'ze', 'ぞ': 'zo',
      'だ': 'da', 'ぢ': 'ji', 'づ': 'zu', 'で': 'de', 'ど': 'do',
      'ば': 'ba', 'び': 'bi', 'ぶ': 'bu', 'べ': 'be', 'ぼ': 'bo',
      'ぱ': 'pa', 'ぴ': 'pi', 'ぷ': 'pu', 'ぺ': 'pe', 'ぽ': 'po',
      'ぁ': 'a', 'ぃ': 'i', 'ぅ': 'u', 'ぇ': 'e', 'ぉ': 'o',
      'ゃ': 'ya', 'ゅ': 'yu', 'ょ': 'yo',
      'ゎ': 'wa'
    };
    return map[kana] ?? '';
  }

  String? _yoonToRomaji(String pair) {
    const map = {
      'きゃ': 'kya', 'きゅ': 'kyu', 'きょ': 'kyo',
      'ぎゃ': 'gya', 'ぎゅ': 'gyu', 'ぎょ': 'gyo',
      'しゃ': 'sha', 'しゅ': 'shu', 'しょ': 'sho',
      'じゃ': 'ja',  'じゅ': 'ju',  'じょ': 'jo',
      'ちゃ': 'cha', 'ちゅ': 'chu', 'ちょ': 'cho',
      'にゃ': 'nya', 'にゅ': 'nyu', 'にょ': 'nyo',
      'ひゃ': 'hya', 'ひゅ': 'hyu', 'ひょ': 'hyo',
      'びゃ': 'bya', 'びゅ': 'byu', 'びょ': 'byo',
      'ぴゃ': 'pya', 'ぴゅ': 'pyu', 'ぴょ': 'pyo',
      'みゃ': 'mya', 'みゅ': 'myu', 'みょ': 'myo',
      'りゃ': 'rya', 'りゅ': 'ryu', 'りょ': 'ryo',
    };
    return map[pair];
  }

  String _buildWorkerIdFromKana(String kana, DateTime birthday) {
    final rom = _kanaToRomaji(kana);
    final mmdd = DateFormat('MMdd').format(birthday);
    return '$rom$mmdd';
  }

  Future<String> _ensureUniqueWorkerId(String baseId) async {
    final usersRef = FirebaseFirestore.instance.collection('users');
    String candidate = baseId;
    int suffix = 0;
    while (true) {
      final q = await usersRef.where('workerId', isEqualTo: candidate).limit(1).get();
      if (q.docs.isEmpty) return candidate;
      suffix++;
      candidate = '${baseId}_$suffix';
      if (suffix > 1000) return '${baseId}_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  void _onKanaOrNameChanged() {
    final kana = _kanaController.text.trim();
    final birthday = _selectedBirthday;
    if (kana.isNotEmpty && birthday != null) {
      final base = _buildWorkerIdFromKana(kana, birthday);
      _generateAndSetWorkerId(base);
    } else {
      _workerIdController.clear();
    }
  }

  Future<void> _generateAndSetWorkerId(String base) async {
    setState(() => _isLoading = true);
    try {
      final unique = await _ensureUniqueWorkerId(base);
      _workerIdController.text = unique;
    } catch (e) {
      _workerIdController.text = base;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final initial = _selectedBirthday ?? DateTime(now.year - 20, 1, 1);
    final firstDate = DateTime(now.year - 100);
    final lastDate = now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('ja'),
    );
    if (picked != null) {
      setState(() => _selectedBirthday = picked);
      final kana = _kanaController.text.trim();
      if (kana.isNotEmpty) {
        final base = _buildWorkerIdFromKana(kana, picked);
        _generateAndSetWorkerId(base);
      }
    }
  }

  bool _isKanaOrKatakana(String s) {
    if (s.isEmpty) return false;
    final regex = RegExp(r'^[\u3040-\u309F\u30A0-\u30FF\s]+$');
    return regex.hasMatch(s);
  }

  Future<void> _registerUser() async {
    final name = _nameController.text.trim();
    final kana = _kanaController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final workerId = _workerIdController.text.trim();

    if (name.isEmpty || kana.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnack('名前（漢字）、ふりがな、メール、パスワードは必須です');
      return;
    }

    if (!_isKanaOrKatakana(kana)) {
      _showSnack('ふりがなはひらがなで入力してください');
      return;
    }

    if (_selectedBirthday == null) {
      _showSnack('生年月日を選択してください（ID自動生成のため）');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1) Firebase Authentication にユーザー作成
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;
      debugPrint('DEBUG: created user uid=$uid');

      // 2) workerId が空なら生成して一意化
      String finalWorkerId = workerId;
      if (finalWorkerId.isEmpty) {
        final base = _buildWorkerIdFromKana(kana, _selectedBirthday!);
        finalWorkerId = await _ensureUniqueWorkerId(base);
      }

      // 3) worker_master ドキュメントを作成（docId を workerId にする）
      final wmRef = FirebaseFirestore.instance.collection('worker_master').doc(finalWorkerId);
      final wmDoc = await wmRef.get();
      if (!wmDoc.exists) {
        await wmRef.set({
          'workerId': finalWorkerId,
          'displayName': name,
          'kana': kana,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint('DEBUG: created worker_master doc workerId=$finalWorkerId');
      } else {
        // 既存があれば必要に応じて更新（ここでは上書きしない）
        debugPrint('DEBUG: worker_master already exists for $finalWorkerId');
      }

      // 4) users/{uid} ドキュメントを作成（role と workerId を含む）
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(uid);
      await userDocRef.set({
        'displayName': name,
        'kana': kana,
        'email': email,
        'role': _selectedRole,
        'workerId': finalWorkerId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('DEBUG: created users doc uid=$uid with workerId=$finalWorkerId');

      _showSnack('ユーザー登録が完了しました');
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      debugPrint('Register error: $e');
      if (e.code == 'email-already-in-use') {
        await _handleEmailAlreadyInUse(email);
      } else if (e.code == 'invalid-email') {
        _showSnack('メールアドレスの形式が正しくありません。');
      } else if (e.code == 'weak-password') {
        _showSnack('パスワードが弱すぎます。別のパスワードを試してください。');
      } else {
        _showSnack('登録エラー: ${e.message ?? e.code}');
      }
    } on FirebaseException catch (e) {
      debugPrint('FirebaseException during register: $e');
      if (e.code == 'permission-denied') {
        await _showPermissionDeniedDialog();
      } else {
        _showSnack('登録エラー: ${e.message ?? e.code}');
      }
    } catch (e) {
      debugPrint('Register unknown error: $e');
      _showSnack('登録エラー: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEmailAlreadyInUse(String email) async {
    List<String> methods = [];
    try {
      methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
    } catch (_) {}
    final usesPassword = methods.contains('password');
    final usesGoogle = methods.contains('google.com');

    await showDialog<void>(
      context: context,
      builder: (context) {
        final providerText = usesPassword
            ? 'メール/パスワードで登録済みです。'
            : usesGoogle
                ? 'Google アカウントで登録済みです。'
                : '既に登録されています。';
        return AlertDialog(
          title: const Text('登録できません'),
          content: Text('$providerText\nログインするかパスワードリセットを行ってください。'),
          actions: [
            if (usesPassword)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed('/login');
                },
                child: const Text('ログインへ'),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _sendPasswordResetPrompt(email);
              },
              child: const Text('パスワードリセット'),
            ),
            if (usesGoogle)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showSnack('Googleでログインしてください');
                },
                child: const Text('Googleでログイン'),
              ),
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('閉じる')),
          ],
        );
      },
    );
  }

  Future<void> _sendPasswordResetPrompt(String email) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('パスワードリセット'),
        content: Text('「$email」にパスワードリセット用のメールを送信します。よろしいですか？'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('送信')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showSnack('パスワードリセット用のメールを送信しました。');
    } catch (e) {
      _showSnack('リセット送信に失敗しました: $e');
    }
  }

  Future<void> _showPermissionDeniedDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('登録エラー'),
        content: const Text('データベースへの書き込み権限がありません。管理者に連絡してください。'),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('閉じる'))],
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final birthdayText = _selectedBirthday == null ? '生年月日を選択' : DateFormat('yyyy/MM/dd').format(_selectedBirthday!);

    return Scaffold(
      appBar: AppBar(title: const Text('ユーザー新規登録')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '名前（漢字）',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _kanaController,
                  inputFormatters: [KanaInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'ふりがな（ひらがな）',
                    hintText: '例: たなか たろう',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _onKanaChangedWithImeSupport,
                ),
                const SizedBox(height: 6),
                const Text(
                  'ひらがなで入力してください',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: '生年月日',
                          border: OutlineInputBorder(),
                        ),
                        child: InkWell(
                          onTap: _pickBirthday,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(birthdayText),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(icon: const Icon(Icons.calendar_today), onPressed: _pickBirthday),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _workerIdController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: '作業員ID（自動生成）',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Visibility(
                  visible: _showGenbaInfo,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('所属現場は後から編集できます', style: TextStyle(color: Colors.black54)),
                      SizedBox(height: 12),
                      Text('権限: 一般（自動設定）', style: TextStyle(color: Colors.black54)),
                      SizedBox(height: 12),
                    ],
                  ),
                ),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'メールアドレス', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'パスワード', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: _isLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.person_add),
                    label: _isLoading ? const Text('登録中...') : const Text('登録する'),
                    onPressed: _isLoading ? null : _registerUser,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    final email = _emailController.text.trim();
                    if (email.isEmpty) {
                      _showSnack('パスワードリセットするメールアドレスを入力してください。');
                      return;
                    }
                    _sendPasswordResetPrompt(email);
                  },
                  child: const Text('パスワードを忘れた場合はこちら'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
