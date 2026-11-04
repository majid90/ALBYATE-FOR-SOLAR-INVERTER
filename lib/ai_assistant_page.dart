import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

const _aiNavy = Color(0xFF263A98);
const _aiPink = Color(0xFFE90070);

class AiAssistantPage extends StatefulWidget {
  final String centerName;
  final String lang;

  const AiAssistantPage({
    super.key,
    required this.centerName,
    required this.lang,
  });

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiChatMessage {
  _AiChatMessage({required this.text, required this.isUser});
  String text;
  final bool isUser;
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_AiChatMessage> _messages = [];
  ChatSession? _chat;
  bool _busy = false;
  String? _setupError;

  bool get _ar => widget.lang == 'ar';
  String t(String ar, String en) => _ar ? ar : en;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
    if (Firebase.apps.isEmpty) {
      _setupError = t(
        'لم يتم إعداد Firebase في هذه النسخة بعد. تأكد من إعداد مشروع Firebase وإعادة بناء التطبيق.',
        'Firebase is not initialized in this build. Complete Firebase setup and rebuild the app.',
      );
      return;
    }

    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-3.8-flash',
        systemInstruction: Content.system(
          _ar
              ? '''أنت ALBYATE AI، مساعد فني لمركز صيانة الإنفيرترات والطاقة الشمسية في العراق.
أجب بالعربية الواضحة وبأسلوب عملي ومختصر، ويمكنك استخدام اللهجة العراقية عند ملاءمتها.
ساعد في فهم أعطال الإنفيرترات، الإلكترونيات، MOSFET و IGBT والمكثفات والبطاريات والطاقة الشمسية، وإدارة المخزون والحسابات بشكل عام.
لا تدّعِ أنك قرأت بيانات التطبيق أو المخزن أو حسابات الزبائن؛ لا تتوفر لك هذه البيانات في هذه المرحلة.
إذا كانت المعلومات غير كافية فاطلب الموديل ورقم الخطأ والقياسات اللازمة.
السلامة أولاً: لا تشجع على العمل على دوائر حية أو جهد خطير. نبّه إلى فصل الكهرباء والبطاريات والألواح والتحقق من تفريغ المكثفات، وأن أعمال الجهد العالي يجب أن ينفذها فني مؤهل.
إذا لم تكن متأكداً من التشخيص فقل ذلك بوضوح ولا تخترع قياسات أو قطعاً تالفة.'''
              : '''You are ALBYATE AI, a technical assistant for a solar inverter repair center in Iraq.
Answer clearly and practically. Help with inverter faults, electronics, MOSFETs, IGBTs, capacitors, batteries, solar power, and general stock/accounting questions.
Do not claim to have read the app database, inventory, or customer accounts; that data is not connected in this phase.
Ask for model, error code, and measurements when needed.
Safety first: never encourage working on energized or hazardous-voltage circuits. Remind users to isolate mains, batteries, and PV panels and verify capacitors are discharged. High-voltage work must be performed by a qualified technician.
If uncertain, say so and do not invent measurements or failed components.''',
        ),
      );
      _chat = model.startChat();
    } catch (e) {
      _setupError = t(
        'تعذر تهيئة المساعد. راجع إعداد Firebase AI Logic.',
        'Could not initialize the assistant. Check Firebase AI Logic setup.',
      );
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? suggested]) async {
    final text = (suggested ?? _input.text).trim();
    if (text.isEmpty || _busy) return;

    if (_chat == null) {
      setState(() {
        _messages.add(_AiChatMessage(
          text: _setupError ?? t('المساعد غير مهيأ حالياً.', 'Assistant is not configured.'),
          isUser: false,
        ));
      });
      _scrollToBottom();
      return;
    }

    _input.clear();
    final answerIndex = _messages.length + 1;
    setState(() {
      _messages.add(_AiChatMessage(text: text, isUser: true));
      _messages.add(_AiChatMessage(text: '', isUser: false));
      _busy = true;
    });
    _scrollToBottom();

    try {
      final stream = _chat!.sendMessageStream(Content.text(text));
      await for (final chunk in stream) {
        final piece = chunk.text ?? '';
        if (piece.isEmpty || !mounted) continue;
        setState(() {
          _messages[answerIndex].text += piece;
        });
        _scrollToBottom();
      }
      if (mounted && _messages[answerIndex].text.trim().isEmpty) {
        setState(() {
          _messages[answerIndex].text = t(
            'لم يصل رد نصي. حاول مرة أخرى.',
            'No text response was returned. Please try again.',
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages[answerIndex].text = _friendlyError(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _scrollToBottom();
      }
    }
  }

  String _friendlyError(Object error) {
    final value = error.toString().toLowerCase();
    if (value.contains('app check') || value.contains('403') || value.contains('permission')) {
      return t(
        'تعذر الوصول إلى خدمة الذكاء الاصطناعي. تحقق من إعداد Firebase AI Logic وApp Check وتسجيل تطبيق Android في Firebase.',
        'AI access was denied. Check Firebase AI Logic, App Check, and Android app registration in Firebase.',
      );
    }
    if (value.contains('quota') || value.contains('429') || value.contains('resource_exhausted')) {
      return t(
        'تم بلوغ حد الاستخدام المتاح حالياً. انتظر قليلاً ثم حاول مجدداً.',
        'The current usage quota has been reached. Wait a while and try again.',
      );
    }
    if (value.contains('network') || value.contains('socket') || value.contains('timeout')) {
      return t(
        'تعذر الاتصال بالإنترنت. تحقق من اتصال الهاتف ثم حاول مرة أخرى.',
        'Network connection failed. Check your internet connection and try again.',
      );
    }
    return t(
      'حدث خطأ أثناء الاتصال بالمساعد. تحقق من تفعيل Gemini Developer API في Firebase ثم حاول مجدداً.',
      'The assistant request failed. Make sure Gemini Developer API is enabled in Firebase and try again.',
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Icon(Icons.auto_awesome, color: _aiPink),
          const SizedBox(width: 8),
          Expanded(child: Text(t('ALBYATE AI', 'ALBYATE AI'))),
        ]),
        backgroundColor: Colors.white,
      ),
      body: Column(children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF2FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            t(
              'مساعد فني عبر الإنترنت يعمل بواسطة Gemini. في هذه المرحلة لا يطّلع على بيانات الزبائن أو الحسابات أو المخزن.',
              'Online technical assistant powered by Gemini. In this phase it cannot access customer, finance, or inventory records.',
            ),
            style: const TextStyle(fontSize: 12, color: _aiNavy),
          ),
        ),
        if (_setupError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Card(
              color: const Color(0xFFFFF4DD),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_setupError!, style: const TextStyle(fontSize: 12)),
              ),
            ),
          ),
        if (_messages.isEmpty)
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF2FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome, size: 42, color: _aiNavy),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      t('مرحباً بك في ALBYATE AI', 'Welcome to ALBYATE AI'),
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: _aiNavy),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t('اسأل عن أعطال الإنفيرتر أو مكونات الدوائر الإلكترونية.', 'Ask about inverter faults or electronic components.'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 18),
                    _suggestion(t('كيف أفحص MOSFET؟', 'How do I test a MOSFET?')),
                    _suggestion(t('ما أسباب ظهور خطأ E01؟', 'What can cause error E01?')),
                    _suggestion(t('اشرح الفرق بين MOSFET و IGBT', 'Explain the difference between MOSFET and IGBT')),
                  ],
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment: message.isUser ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .84),
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: message.isUser ? _aiNavy : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: message.isUser ? null : Border.all(color: const Color(0xFFE5E8F0)),
                    ),
                    child: message.text.isEmpty && !message.isUser
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                        : SelectableText(
                            message.text,
                            style: TextStyle(
                              color: message.isUser ? Colors.white : const Color(0xFF202333),
                              height: 1.45,
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: t('اكتب رسالتك...', 'Write a message...'),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                width: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _aiNavy,
                    padding: EdgeInsets.zero,
                    shape: const CircleBorder(),
                  ),
                  onPressed: _busy ? null : () => _send(),
                  child: const Icon(Icons.send_rounded, color: Colors.white),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _suggestion(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: OutlinedButton(
          onPressed: _busy || _chat == null ? null : () => _send(text),
          style: OutlinedButton.styleFrom(
            foregroundColor: _aiNavy,
            side: const BorderSide(color: Color(0xFFD8DDF4)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Text(text),
        ),
      );
}
