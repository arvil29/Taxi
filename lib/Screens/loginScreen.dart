import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uber_clone/Screens/homeScreen.dart';
import 'package:uber_clone/Screens/registrationScreen.dart';
import 'package:uber_clone/Widgets/progressDialog.dart';
import 'package:uber_clone/main.dart';

class LoginScreen extends StatelessWidget {
  static const String idScreen = "login";
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            children: [
              //logo
              SizedBox(height: 170.0),
              Image(
                image: AssetImage("images/logo.png"),
                width: 300.0,
                height: 200.0,
                alignment: Alignment.center,
              ),

              //title
              SizedBox(height: 30.0),
              Text(
                "Login as Rider",
                style: TextStyle(
                  fontSize: 24.0,
                ),
                textAlign: TextAlign.center,
              ),

              //Column with email, pass, login
              Padding(
                padding: EdgeInsets.all(30.0),
                child: Column(
                  children: [
                    SizedBox(height: 1.0),

                    //email
                    TextField(
                      controller: emailTextEditingController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email",
                        labelStyle: TextStyle(
                          fontSize: 14.0,
                        ),
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 18.0,
                        ),
                      ),
                      style: TextStyle(fontSize: 14.0),
                    ),
                    SizedBox(height: 1.0),

                    //password
                    TextField(
                      controller: passwordTextEditingController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Password",
                        labelStyle: TextStyle(
                          fontSize: 14.0,
                        ),
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 18.0,
                        ),
                      ),
                      style: TextStyle(fontSize: 14.0),
                    ),
                    SizedBox(height: 30.0),

                    //login button
                    RaisedButton(
                      color: Color(0xFFEEBE1C),
                      textColor: Colors.white,
                      child: Container(
                        height: 50.0,
                        child: Center(
                          child: Text(
                            "Login",
                            style: TextStyle(
                                fontSize: 18.0, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      shape: new RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(24.0),
                      ),
                      onPressed: () {
                        //check for valid inputs in fields
                        if (!emailTextEditingController.text.contains("@")) {
                          displayToastMessage(
                              "Email address is not valid", context);
                        } else if (passwordTextEditingController.text.isEmpty) {
                          displayToastMessage("Password is mandatory", context);
                        } else {
                          loginAndAuthenticateUser(context);
                        }
                      },
                    ),
                  ],
                ),
              ),

              //no account? register button
              FlatButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, RegistrationScreen.idScreen, (route) => false);
                },
                child: RichText(
                  text: new TextSpan(
                    children: <TextSpan>[
                      new TextSpan(
                        text: 'New here?',
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                      new TextSpan(
                        text: ' Register',
                        style: TextStyle(
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //get authenticated user's instance
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  void loginAndAuthenticateUser(BuildContext context) async {
    //loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ProgressDialog(message: "Loading...");
      },
    );

    //create firebase user after authentication
    final User firebaseUser = (await _firebaseAuth
            .signInWithEmailAndPassword(
                email: emailTextEditingController.text,
                password: passwordTextEditingController.text)
            .catchError((errMsg) {
      Navigator.pop(context);
      displayToastMessage("Error: " + errMsg.toString(), context);
    }))
        .user;

    //if user is found
    if (firebaseUser != null) {
      //get snapshot of their data
      usersRef.child(firebaseUser.uid).once().then((DataSnapshot snap) {
        //if snapshot found --> can log in --> go to home screen
        if (snap.value != null) {
          Navigator.pushNamedAndRemoveUntil(
              context, HomeScreen.idScreen, (route) => false);
          displayToastMessage("You are now logged in", context);
        } else {
          Navigator.pop(context);
          _firebaseAuth.signOut();
          displayToastMessage(
              "No record exists for this user. Please create an account",
              context);
        }
      });
    }
    //if not --> error
    else {
      Navigator.pop(context);
      displayToastMessage("Error ocurred when signing in!", context);
    }
  }

  //in case of errors --> display error message
  displayToastMessage(String message, BuildContext context) {
    Fluttertoast.showToast(msg: message);
  }
}
