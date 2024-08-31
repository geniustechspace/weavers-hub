import 'package:flutter/material.dart';

class FooterButton extends StatelessWidget {
  final String question;
  final String buttonText;
  final VoidCallback onTap;


  const FooterButton({super.key, required this.question, required this.buttonText, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(question),
        CustomTextButton(buttonName: buttonText,  onTap: onTap,)
      ],
    );
  }
}

class CustomTextButton extends StatelessWidget {
  final String buttonName;

  final VoidCallback onTap;


  const CustomTextButton({super.key,required this.buttonName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: Colors.green,
      ),
      onPressed: onTap,
      child: Text(
        buttonName,
        maxLines: 1,
      ),
    );
  }
}