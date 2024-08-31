import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quill_ai/core/config/type_of_bot.dart';
import 'package:quill_ai/core/extension/context.dart';
import 'package:quill_ai/feature/chat/provider/message_provider.dart';
import 'package:quill_ai/feature/chat/widgets/chat_interface_widget.dart';
import 'package:quill_ai/feature/home/provider/chat_bot_provider.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final GlobalKey<ChatInterfaceWidgetState> _chatKey = GlobalKey<ChatInterfaceWidgetState>();

  @override
  Widget build(BuildContext context) {
    final chatBot = ref.watch(messageListProvider);
    final color = chatBot.typeOfBot == TypeOfBot.pdf
        ? context.colorScheme.primary
        : chatBot.typeOfBot == TypeOfBot.text
        ? context.colorScheme.secondary
        : context.colorScheme.tertiary;
    final title = chatBot.typeOfBot == TypeOfBot.pdf
        ? 'PDF'
        : chatBot.typeOfBot == TypeOfBot.image
        ? 'Image'
        : 'Text';

    final List<types.Message> messages = chatBot.messagesList.map((msg) {
      return types.TextMessage(
        author: types.User(id: msg['typeOfMessage'] as String),
        createdAt:
        DateTime.parse(msg['createdAt'] as String).millisecondsSinceEpoch,
        id: msg['id'] as String,
        text: msg['text'] as String,
      );
    }).toList()
      ..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));

    Future<bool> _handleBackButton() async {
      if (_chatKey.currentState != null) {
        _chatKey.currentState!.stopSpeaking();
      }
      await ref.read(chatBotListProvider.notifier).updateChatBotOnHomeScreen(chatBot);
      return true;
    }

    return WillPopScope(
      onWillPop: _handleBackButton,
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                          ),
                          onPressed: () async {
                            await _handleBackButton();
                            context.pop();
                          },
                        ),
                        Center(
                          child: Text(
                            '$title AI',
                            style: TextStyle(
                              color: context.colorScheme.surface,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        if (chatBot.typeOfBot == TypeOfBot.image)
                          Padding(
                            padding: const EdgeInsets.only(right: 15),
                            child: CircleAvatar(
                              maxRadius: 20,
                              backgroundImage: FileImage(
                                File(chatBot.attachmentPath!),
                              ),
                              child: TextButton(
                                onPressed: () {
                                  showDialog<AlertDialog>(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        content: SingleChildScrollView(
                                          child: ClipRRect(
                                            borderRadius:
                                            BorderRadius.circular(15),
                                            child: Image.file(
                                              File(chatBot.attachmentPath!),
                                            ),
                                          ),
                                        ),
                                        actions: <Widget>[
                                          TextButton(
                                            child: const Text(
                                              'Close',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 20,
                                              ),
                                            ),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: const SizedBox.shrink(),
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 42),
                      ],
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Expanded(
                      child: ChatInterfaceWidget(
                        key: _chatKey,
                        messages: messages,
                        chatBot: chatBot,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
