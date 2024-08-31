import 'package:quill_ai/core/extension/context.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CardButton extends StatelessWidget {
  const CardButton({
    required this.title,
    required this.imagePath,
    required this.color,
    required this.isMainButton,
    required this.onPressed,
    super.key,
  });
  final String title;
  final String imagePath;
  final Color color;
  final bool isMainButton;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                backgroundColor:
                    Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    imagePath,
                    color: Colors.black,
                  ),
                ),
              ),
              const Icon(
                CupertinoIcons.arrow_up_right,
                color: Colors.black,
                size: 32,
              ),
            ],
          ),
          SizedBox(
            height: isMainButton ? 25 : 25,
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              title,
              style: context.textTheme.bodyLarge!.copyWith(
                color: Colors.black,
                fontSize: isMainButton ? 15 : 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
