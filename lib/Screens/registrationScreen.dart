import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uber_clone/Screens/loginScreen.dart';
import 'package:uber_clone/Screens/homeScreen.dart';
import 'package:uber_clone/Widgets/progressDialog.dart';
import 'package:uber_clone/main.dart';

import 'homeScreen.dart';

class RegistrationScreen extends StatelessWidget {
  static const String idScreen = "register";

  TextEditingController nameTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController phoneTextEditingController = TextEditingController();
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
              SizedBox(height: 120.0),

              //logo
              Image(
                image: AssetImage("images/logo.png"),
                width: 300.0,
                height: 200.0,
                alignment: Alignment.center,
              ),

              //title
              SizedBox(height: 30.0),
              Text(
                "Register as Rider",
                style: TextStyle(fontSize: 24.0),
                textAlign: TextAlign.center,
              ),

              //Column with name, email, phone, password, button
              Padding(
                padding: EdgeInsets.all(30.0),
                child: Column(
                  children: [
                    //name
                    SizedBox(height: 1.0),
                    TextField(
                      controller: nameTextEditingController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: "Name",
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

                    //email
                    SizedBox(height: 1.0),
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

                    //phone
                    SizedBox(height: 1.0),
                    TextField(
                      controller: phoneTextEditingController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Phone",
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

                    //password
                    SizedBox(height: 1.0),
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

                    //create account button
                    RaisedButton(
                      color: Color(0xFFEEBE1C),
                      textColor: Colors.white,
                      child: Container(
                        height: 50.0,
                        child: Center(
                          child: Text(
                            "Create Account",
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      shape: new RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(24.0),
                      ),
                      onPressed: () {
                        //check for valid inputs in fields
                        if (nameTextEditingController.text.length < 3) {
                          displayToastMessage(
                              "Name must be at least 3 characters", context);
                        } else if (!emailTextEditingController.text
                            .contains("@")) {
                          displayToastMessage(
                              "Email address is not valid", context);
                        } else if (phoneTextEditingController.text.isEmpty) {
                          displayToastMessage(
                              "Phone number is mandatory", context);
                        } else if (passwordTextEditingController.text.length <
                            6) {
                          displayToastMessage(
                              "Password must be atleast 6 characters long",
                              context);
                        } else {
                          registerNewUser(context);
                        }
                      },
                    ),
                  ],
                ),
              ),

              //have account? login button
              FlatButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, LoginScreen.idScreen, (route) => false);
                },
                child: RichText(
                  text: new TextSpan(
                    children: <TextSpan>[
                      new TextSpan(
                        text: 'Have an account?',
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                      new TextSpan(
                        text: ' Login',
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

  void registerNewUser(BuildContext context) async {
    //loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ProgressDialog(message: "Loading...");
      },
    );

    //create firebase user with instance
    final User firebaseUser = (await _firebaseAuth
            .createUserWithEmailAndPassword(
                email: emailTextEditingController.text,
                password: passwordTextEditingController.text)
            .catchError((errMsg) {
      Navigator.pop(context);
      displayToastMessage("Error: " + errMsg.toString(), context);
    }))
        .user;

    //if user created
    if (firebaseUser != null) {
      //set child of 'users' in db to uid
      usersRef.child(firebaseUser.uid);

      //store user's data in map
      Map userDataMap = {
        "name": nameTextEditingController.text.trim(),
        "email": emailTextEditingController.text.trim(),
        "phone": phoneTextEditingController.text.trim(),
      };

      //set child of uid in db to user's data
      usersRef.child(firebaseUser.uid).set(userDataMap);
      displayToastMessage(
          "Congratulations! Your account has been created", context);

      //go to main screen after registering
      Navigator.pushNamedAndRemoveUntil(
          context, HomeScreen.idScreen, (route) => false);
    }
    //if not --> save user info to database
    else {
      Navigator.pop(context);
      displayToastMessage("User has not been created", context);
    }
  }

  //in case of errors --> display error message
  displayToastMessage(String message, BuildContext context) {
    Fluttertoast.showToast(msg: message);
  }
}
