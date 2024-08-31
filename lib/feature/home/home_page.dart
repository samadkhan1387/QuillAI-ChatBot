import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:quill_ai/core/config/assets_constants.dart';
import 'package:quill_ai/core/config/type_of_bot.dart';
import 'package:quill_ai/core/extension/context.dart';
import 'package:quill_ai/core/navigation/route.dart';
import 'package:quill_ai/core/util/secure_storage.dart';
import 'package:quill_ai/feature/chat/provider/message_provider.dart';
import 'package:quill_ai/feature/hive/model/chat_bot/chat_bot.dart';
import 'package:quill_ai/feature/home/provider/chat_bot_provider.dart';
import 'package:quill_ai/feature/home/widgets/widgets.dart';
import 'package:quill_ai/feature/welcome/widgets/api_key_bottom_sheet.dart';
import 'package:uuid/uuid.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final uuid = const Uuid();

  bool _isBuildingChatBot = false;
  String currentState = '';

  @override
  void initState() {
    super.initState();
    ref.read(chatBotListProvider.notifier).fetchChatBots();
  }

  Widget _buildLoadingIndicator(String currentState) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SpinKitDoubleBounce(
            color: Colors.black,
          ),
          const SizedBox(height: 8),
          Text(currentState, style: const TextStyle(color: Colors.black)),
        ],
      ),
    );
  }

  void _showAllHistory(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final chatBotsList = ref.watch(chatBotListProvider);
            return Column(
              children: [
                Container(
                  height: 4,
                  width: 50,
                  decoration: BoxDecoration(
                    color: context.colorScheme.onSurface,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ListView.separated(
                      itemCount: chatBotsList.length,
                      itemBuilder: (context, index) {
                        final chatBot = chatBotsList[index];
                        final imagePath = chatBot.typeOfBot == TypeOfBot.pdf
                            ? AssetConstants.pdfLogo
                            : chatBot.typeOfBot == TypeOfBot.image
                            ? AssetConstants.imageLogo
                            : AssetConstants.textLogo;
                        final tileColor = chatBot.typeOfBot == TypeOfBot.pdf
                            ? context.colorScheme.primary
                            : chatBot.typeOfBot == TypeOfBot.text
                            ? context.colorScheme.secondary
                            : context.colorScheme.tertiary;
                        return HistoryItem(
                          imagePath: imagePath,
                          label: chatBot.title,
                          color: tileColor,
                          chatBot: chatBot,
                        );
                      },
                      separatorBuilder: (context, index) =>
                      const SizedBox(height: 4),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatBotsList = ref.watch(chatBotListProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: _isBuildingChatBot
          ? _buildLoadingIndicator(currentState)
          : SafeArea(
        child: Stack(
          children: [
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0),
                              offset: const Offset(4, 4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Quill Your Personal AI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Image.asset(
                              AssetConstants.aiStarLogo,
                              scale: 25,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'How may I help you\ntoday?',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge!
                            .copyWith(
                            fontSize: 25,
                            color: Colors.black
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: CardButton(
                          title: 'Chat with PDF',
                          color: context.colorScheme.primary,
                          imagePath: AssetConstants.pdfLogo,
                          isMainButton: true,
                          onPressed: () async {
                            final result =
                            await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf'],
                            );
                            if (result != null) {
                              final filePath = result.files.single.path;
                              setState(() {
                                _isBuildingChatBot = true;
                                currentState = 'Extracting data';
                              });

                              await Future<void>.delayed(
                                const Duration(milliseconds: 100),
                              );

                              final textChunks = await ref
                                  .read(chatBotListProvider.notifier)
                                  .getChunksFromPDF(filePath!);

                              setState(() {
                                currentState = 'Building chatBot';
                              });

                              final embeddingsMap = await ref
                                  .read(chatBotListProvider.notifier)
                                  .batchEmbedChunks(textChunks);

                              final chatBot = ChatBot(
                                messagesList: [],
                                id: uuid.v4(),
                                title: '',
                                typeOfBot: TypeOfBot.pdf,
                                attachmentPath: filePath,
                                embeddings: embeddingsMap,
                              );

                              await ref
                                  .read(chatBotListProvider.notifier)
                                  .saveChatBot(chatBot);
                              await ref
                                  .read(messageListProvider.notifier)
                                  .updateChatBot(chatBot);

                              AppRoute.chat.push(context);
                              setState(() {
                                _isBuildingChatBot = false;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CardButton(
                          title: 'Chat with AI',
                          color: context.colorScheme.secondary,
                          imagePath: AssetConstants.textLogo,
                          isMainButton: false,
                          onPressed: () {
                            final chatBot = ChatBot(
                              messagesList: [],
                              id: uuid.v4(),
                              title: '',
                              typeOfBot: TypeOfBot.text,
                            );
                            ref
                                .read(chatBotListProvider.notifier)
                                .saveChatBot(chatBot);
                            ref
                                .read(messageListProvider.notifier)
                                .updateChatBot(chatBot);
                            AppRoute.chat.push(context);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: CardButton(
                          title: 'Chat with Voice',
                          color: context.colorScheme.tertiary,
                          imagePath: AssetConstants.voiceLogo,
                          isMainButton: false,
                          onPressed: () {
                            final chatBot = ChatBot(
                              messagesList: [],
                              id: uuid.v4(),
                              title: '',
                              typeOfBot: TypeOfBot.text,
                            );
                            ref
                                .read(chatBotListProvider.notifier)
                                .saveChatBot(chatBot);
                            ref
                                .read(messageListProvider.notifier)
                                .updateChatBot(chatBot);
                            AppRoute.chat.push(context);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 5),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'History',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(
                                fontWeight: FontWeight.w500,
                                fontSize: 22,
                                color: Colors.black,
                              ),
                            ),
                            TextButton(
                              onPressed: () => _showAllHistory(context),
                              child: Text(
                                'See More',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .copyWith(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (chatBotsList.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(64),
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceEvenly,
                              children: [
                                const SizedBox(width: 12),
                                Text(
                                  'No chats yet',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .copyWith(
                                    fontSize: 18,
                                    color: Colors.black,
                                  ),
                                ),
                                const Icon(CupertinoIcons.cube_box,color: Colors.black),
                                const SizedBox(width: 0),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: chatBotsList.length > 3
                              ? 3
                              : chatBotsList.length,
                          separatorBuilder: (_, __) =>
                          const SizedBox(height: 4),
                          itemBuilder: (context, index) {
                            final chatBot = chatBotsList[index];
                            final imagePath =
                            chatBot.typeOfBot == TypeOfBot.pdf
                                ? AssetConstants.pdfLogo
                                : chatBot.typeOfBot == TypeOfBot.image
                                ? AssetConstants.imageLogo
                                : AssetConstants.textLogo;
                            final tileColor =
                            chatBot.typeOfBot == TypeOfBot.pdf
                                ? context.colorScheme.primary
                                : chatBot.typeOfBot == TypeOfBot.text
                                ? Theme.of(context)
                                .colorScheme
                                .secondary
                                : Theme.of(context)
                                .colorScheme
                                .tertiary;
                            return HistoryItem(
                              label: chatBot.title,
                              imagePath: imagePath,
                              color: tileColor,
                              chatBot: chatBot,
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
