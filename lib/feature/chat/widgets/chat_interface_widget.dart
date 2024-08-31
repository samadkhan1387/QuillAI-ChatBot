import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quill_ai/core/config/type_of_message.dart';
import 'package:quill_ai/core/extension/context.dart';
import 'package:quill_ai/feature/chat/provider/message_provider.dart';
import 'package:quill_ai/feature/hive/model/chat_bot/chat_bot.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class ChatInterfaceWidget extends ConsumerStatefulWidget {
  const ChatInterfaceWidget({
    required this.messages,
    required this.chatBot,
    required this.color,
    super.key,
  });

  final List<types.Message> messages;
  final ChatBot chatBot;
  final Color color;

  @override
  ChatInterfaceWidgetState createState() => ChatInterfaceWidgetState();
}

class ChatInterfaceWidgetState extends ConsumerState<ChatInterfaceWidget> {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  bool _isSpeaking = false;
  String _text = '';
  TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  @override
  void dispose() {
    stopSpeaking();
    super.dispose();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => setState(() {
          print('onStatus: $val');
          _isListening = val == 'listening';
        }),
        onError: (val) => setState(() {
          print('onError: $val');
          _isListening = false;
        }),
      );
      if (available) {
        setState(() => _isListening = true);
        await _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
            _controller.text = _text;
          }),
        );
      } else {
        print('The user has denied the use of speech recognition.');
      }
    } else {
      setState(() => _isListening = false);
      await _speech.stop();
    }
  }

  void _speak(String text) async {
    setState(() {
      _isSpeaking = true;
    });
    await _flutterTts.speak(text);
  }

  void stopSpeaking() async {
    setState(() {
      _isSpeaking = false;
    });
    await _flutterTts.stop();
  }

  void _speakLastReceivedMessage() {
    if (_isSpeaking) {
      stopSpeaking();
    } else {
      // Find the latest received message
      final lastReceivedMessage = widget.messages.reversed.lastWhere(
            (message) => message.author.id != TypeOfMessage.user,
        orElse: () => types.TextMessage(id: '', author: types.User(id: ''), text: '', createdAt: DateTime.now().millisecondsSinceEpoch),
      );

      if (lastReceivedMessage is types.TextMessage && lastReceivedMessage.text.isNotEmpty) {
        _speak(lastReceivedMessage.text);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(0),
          child: Chat(
            messages: widget.messages,
            onSendPressed: (text) {
              ref.watch(messageListProvider.notifier).handleSendPressed(
                text: text.text,
                imageFilePath: widget.chatBot.attachmentPath,
              );
              _controller.clear();
            },
            user: const types.User(id: TypeOfMessage.user),
            customBottomWidget: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: context.colorScheme.onBackground,
                  borderRadius: const BorderRadius.all(Radius.circular(15)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: context.colorScheme.onBackground,
                          hintText: 'Type/Record Your Message',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                          hintStyle: TextStyle(
                            color: context.colorScheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        style: TextStyle(color: context.colorScheme.onSurface),
                      ),
                    ),
                    IconButton(
                      icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                      color: context.colorScheme.onSurface,
                      onPressed: _listen,
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      color: context.colorScheme.onSurface,
                      onPressed: () {
                        ref.watch(messageListProvider.notifier).handleSendPressed(
                          text: _controller.text,
                          imageFilePath: widget.chatBot.attachmentPath,
                        );
                        _controller.clear();
                      },
                    ),
                  ],
                ),
              ),
            ),
            theme: DefaultChatTheme(
              backgroundColor: Colors.white,
              primaryColor: const Color(0xFF3EBE75),
              secondaryColor: Colors.grey,
              inputBackgroundColor: context.colorScheme.onBackground,
              inputTextColor: Colors.white,
              sendingIcon: Icon(
                Icons.send,
                color: context.colorScheme.onSurface,
              ),
              inputTextCursorColor: Colors.white,
              receivedMessageBodyTextStyle: TextStyle(
                color: context.colorScheme.onBackground,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
              sentMessageBodyTextStyle: TextStyle(
                color: context.colorScheme.onBackground,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
              dateDividerTextStyle: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
              inputTextStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.5,
                color: context.colorScheme.onSurface,
              ),
              inputTextDecoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isCollapsed: true,
                fillColor: context.colorScheme.onBackground,
              ),
              inputBorderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            customMessageBuilder: (message, {required int messageWidth}) => _buildMessage(message, messageWidth: messageWidth),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 85,
          child: FloatingActionButton(
            backgroundColor: context.colorScheme.onBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onPressed: _speakLastReceivedMessage,
            child: Icon(
              _isSpeaking ? Icons.stop : Icons.volume_up,
              size: 25,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessage(types.Message message, {required int messageWidth}) {
    if (message is types.TextMessage) {
      return GestureDetector(
        onTap: () {
          if (!_isSpeaking) {
            _speak(message.text);
          } else {
            stopSpeaking();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: message.author.id == TypeOfMessage.user
                ? context.colorScheme.primary
                : context.colorScheme.secondary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            message.text,
            style: TextStyle(
              color: message.author.id == TypeOfMessage.user
                  ? Colors.white
                  : Colors.black,
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
