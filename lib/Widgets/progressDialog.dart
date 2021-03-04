import 'package:flutter/material.dart';

class ProgressDialog extends StatelessWidget {
  String message;
  ProgressDialog({this.message});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      child: Container(
        margin: EdgeInsets.all(15.0),
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.all(15.0),
          child: Row(
            children: [
              SizedBox(width: 6.0),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFF45C2F7),
                ),
              ),
              SizedBox(width: 26.0),
              Text(
                message,
                style: TextStyle(color: Color(0xFF303131), fontSize: 13.0),
              )
            ],
          ),
        ),
      ),
    );
  }
}
