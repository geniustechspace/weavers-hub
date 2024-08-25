import 'package:flutter/material.dart';


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




class CustomButton extends StatelessWidget {
  final String buttonName;

  final VoidCallback onTap;


  const CustomButton(
      {super.key, required this.buttonName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
          fixedSize: const Size(300, 50),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 5,
          padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 100, vertical: 10.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0.0),
          ),
          textStyle: const TextStyle(
            fontSize: 20,
          )


      ),
      onPressed: onTap,

      child: Text(
        buttonName,
        maxLines: 1,
      ),

    );
  }
}