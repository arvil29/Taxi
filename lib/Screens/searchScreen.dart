import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uber_clone/Assistants/requestAssistant.dart';
import 'package:uber_clone/DataHandler/appData.dart';
import 'package:uber_clone/Models/address.dart';
import 'package:uber_clone/Models/placePredictions.dart';
import 'package:uber_clone/Widgets/Divider.dart';
import 'package:uber_clone/Widgets/progressDialog.dart';

class SearchScreen extends StatefulWidget {
  SearchScreen({Key key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController pickupTextEditingController = TextEditingController();
  TextEditingController dropOddTextEditingController = TextEditingController();
  List<PlacePredictions> placePredictionList = [];

  @override
  Widget build(BuildContext context) {
    String placeAddress =
        Provider.of<AppData>(context).pickupLocation.placeName ?? "";
    pickupTextEditingController.text = placeAddress;

    return Scaffold(
      body: Column(
        children: [
          //the My Trip box at top of page
          Container(
            height: 230.0,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.white,
                  blurRadius: 7.0,
                  spreadRadius: 0.5,
                  offset: Offset(0.7, 0.7),
                )
              ],
            ),
            child: Padding(
              padding: EdgeInsets.only(
                  left: 25.0, top: 65.0, right: 25.0, bottom: 20.0),
              child: Column(
                children: [
                  SizedBox(height: 5.0),
                  Stack(
                    children: [
                      //cross button
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Icon(Icons.close_outlined),
                      ),

                      //My Trip title
                      Center(
                        child: Text(
                          "My Trip",
                          style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.0),

                  //whole row for my location
                  Row(
                    children: [
                      //my location icon
                      Icon(
                        Icons.brightness_1_outlined,
                        color: Colors.blue,
                        size: 20,
                      ),

                      SizedBox(width: 18.0),

                      //my location text box
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(3.0),
                            child: TextField(
                              controller: pickupTextEditingController,
                              decoration: InputDecoration(
                                hintText: "Pickup",
                                hintStyle: TextStyle(color: Colors.black),
                                fillColor: Colors.grey[100],
                                filled: true,
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.only(
                                    left: 11.0, top: 8.0, bottom: 8.0),
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),

                  SizedBox(height: 10.0),

                  //whole row for drop-off
                  Row(
                    children: [
                      //drop-off icon
                      Icon(
                        Icons.brightness_1_outlined,
                        color: Color(0xFFEEBE1C),
                        size: 20,
                      ),

                      SizedBox(width: 18.0),

                      //drop-off location text box
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(3.0),
                            child: TextField(
                              onChanged: (val) {
                                findPlace(val);
                              },
                              controller: dropOddTextEditingController,
                              decoration: InputDecoration(
                                hintText: "Drop-off",
                                hintStyle: TextStyle(color: Colors.black),
                                fillColor: Colors.grey[100],
                                filled: true,
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.only(
                                    left: 11.0, top: 8.0, bottom: 8.0),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          //if array of predictions exists --> display each prediction by injecting into a PredictionTile
          (placePredictionList.length > 0)
              ? Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: ListView.separated(
                    padding: EdgeInsets.all(0.0),
                    itemBuilder: (context, index) {
                      return PredictionTile(
                        placePredictions: placePredictionList[index],
                      );
                    },

                    //divider after each row
                    separatorBuilder: (BuildContext context, int index) =>
                        DividerWidget(),
                    itemCount: placePredictionList.length,
                    shrinkWrap: true,
                    physics: ClampingScrollPhysics(),
                  ),
                )

              //else show empty container
              : Container(),
        ],
      ),
    );
  }

  //get whatever user types in & try to find similar location matches
  void findPlace(String placeName) async {
    if (placeName.length > 1) {
      String autoCompleteUrl =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$placeName&key=AIzaSyDSJ9L1tN3x8vFkxMhu_ZbKzVxP7EJl4Ss&sessiontoken=1234567890";

      //converts string response to json
      var res = await RequestAssistant.getRequest(autoCompleteUrl);

      if (res == 'failed') {
        return;
      }

      //if response is valid -->
      if (res["status"] == "OK") {
        var predictions = res["predictions"];

        //take all predicted places & store into list
        var placesList = (predictions as List)
            .map((e) => PlacePredictions.fromJson(e))
            .toList();

        //update state by setting array to new list
        setState(() {
          placePredictionList = placesList;
        });
      }
    }
  }
}

//each row of predicted location
class PredictionTile extends StatelessWidget {
  final PlacePredictions placePredictions;

  const PredictionTile({Key key, this.placePredictions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      padding: EdgeInsets.all(0.0),
      onPressed: () {
        getPlaceAddressDetails(placePredictions.place_id, context);
      },
      child: Container(
        child: Column(
          children: [
            Row(
              children: [
                //icon on left
                Icon(
                  Icons.home_work,
                  color: Color(0xFFEEBE1C),
                ),

                SizedBox(width: 14.0),

                //everything to right of icon
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 8.0,
                      ),

                      //name of location on top
                      Text(
                        placePredictions.main_text,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16.0),
                      ),
                      SizedBox(
                        height: 2.0,
                      ),

                      //actual address below
                      Text(
                        placePredictions.secondary_text,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.0, color: Colors.grey),
                      ),
                      SizedBox(
                        height: 8.0,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(width: 10.0),
          ],
        ),
      ),
    );
  }

  //get address details after clicked from location predictions list
  void getPlaceAddressDetails(String placeId, context) async {
    //loading widget
    showDialog(
      context: context,
      builder: (BuildContext context) =>
          ProgressDialog(message: "Setting Drop-off..."),
    );

    //get url for specific location that was clicked
    String placeDetailsUrl =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=AIzaSyDSJ9L1tN3x8vFkxMhu_ZbKzVxP7EJl4Ss";
    var res = await RequestAssistant.getRequest(placeDetailsUrl);

    //remove loading widget after response has been received
    Navigator.pop(context);

    if (res == "Failed") {
      return;
    }

    //if response is a success --> get address details
    if (res["status"] == "OK") {
      Address address = Address();
      address.placeName = res["result"]["name"];
      address.placeId = placeId;
      address.latitude = res["result"]["geometry"]["location"]["lat"];
      address.longitude = res["result"]["geometry"]["location"]["lng"];

      Provider.of<AppData>(context, listen: false)
          .updateDropOffLocationAddress(address);

      print("Drop-off location: ");
      print(address.placeName);

      //after place name is retrieved --> close screen
      Navigator.pop(context, "obtainDirection");
    }
  }
}
