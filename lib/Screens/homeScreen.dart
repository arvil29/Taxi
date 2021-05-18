import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uber_clone/Assistants/assistantMethods.dart';
import 'package:uber_clone/DataHandler/appData.dart';
import 'package:uber_clone/Models/directionDetails.dart';
import 'package:uber_clone/Screens/searchScreen.dart';
import 'package:uber_clone/Widgets/Divider.dart';
import 'package:uber_clone/Widgets/progressDialog.dart';
import 'package:uber_clone/configMaps.dart';
import 'package:stripe_payment/stripe_payment.dart';

import 'loginScreen.dart';

class HomeScreen extends StatefulWidget {
  static const String idScreen = "homeScreen";

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  Token _paymentToken;
  PaymentMethod _paymentMethod;
  PaymentIntentResult _paymentIntent;
  Source _source;

  Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController newGoogleMapController;

  List<LatLng> pLineCoordinates = [];
  Set<Polyline> polylineSet = {};

  Position currentPosition;
  double bottomPaddingOfMap = 0;
  GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
  DirectionDetails tripDirectionDetails;

  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};

  double rideDetailsContainerHeight = 0;
  double requestRideContainerHeight = 0;
  double searchContainerHeight = 310;

  bool drawerOpen = true;

  DatabaseReference rideRequestRef;

  final CreditCard testCard = CreditCard(
    number: '4111111111111111',
    expMonth: 08,
    expYear: 22,
  );

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    AssistantMethods.getCurrentOnLineUserInfo();

    StripePayment.setOptions(StripeOptions(
        publishableKey: "pk_test_xVwuB3wboGJYNOPwMJozr9CJ00mjDjNEsR",
        merchantId:
            "sk_test_51Fnv4mEAMy8EFUc1HHHOsdTvBzY4ZPpOu0TL1krBXLV7B2XjYsn3dZCaL4PLWujf3TK8VXWrRc5fSTqnanbvB5M000xaM8BmHz",
        androidPayMode: 'test'));
  }

  void saveRideRequest() {
    rideRequestRef =
        FirebaseDatabase.instance.reference().child("Ride Requests");

    var pickUp = Provider.of<AppData>(context, listen: false).pickupLocation;
    var dropOff = Provider.of<AppData>(context, listen: false).dropoffLocation;

    Map pickupLocMap = {
      "latitude": pickUp.latitude.toString(),
      "longitude": pickUp.longitude.toString(),
    };

    Map dropoffLocMap = {
      "latitude": dropOff.latitude.toString(),
      "longitude": dropOff.longitude.toString(),
    };

    Map rideInfoMap = {
      "driver_id": "waiting",
      "payment_method": "cash",
      "pickup": pickupLocMap,
      "dropoff": dropoffLocMap,
      "created_at": DateTime.now().toString(),
      "rider_name": userCurrentInfo.name,
      "rider_phone": userCurrentInfo.phone,
      "pickup_address": pickUp.placeName,
      "dropoff_address": dropOff.placeName,
    };

    rideRequestRef.set(rideInfoMap);
  }

  void cancelRideRequest() {
    rideRequestRef.remove();
  }

  void displayRequestRideContainer() {
    setState(() {
      requestRideContainerHeight = 310.0;
      rideDetailsContainerHeight = 0;
      bottomPaddingOfMap = 310;
      drawerOpen = true; //keep showing hamburger button
    });

    saveRideRequest(); //save ride req to db
  }

  //reset app to initial state after cross button is clicked
  resetApp() {
    setState(() {
      drawerOpen = true;
      searchContainerHeight = 310.0;
      rideDetailsContainerHeight = 0;
      requestRideContainerHeight = 0;
      bottomPaddingOfMap = 310.0;

      polylineSet.clear();
      markersSet.clear();
      circlesSet.clear();
      pLineCoordinates.clear();
    });

    locatePosition();
  }

  //make search dropoff/pickup container hidden
  void displayRideDetailsContainer() async {
    await getPlaceDirection();
    setState(() {
      searchContainerHeight = 0;
      rideDetailsContainerHeight = 310.0;
      bottomPaddingOfMap = 310.0;
      drawerOpen = false; //show cross button when on car request page
    });
  }

  //use geocoding to find user's current location
  void locatePosition() async {
    //get current position
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    currentPosition = position;

    LatLng latLngPosition = LatLng(position.latitude, position.longitude);

    //camera moves when fingers move
    CameraPosition cameraPosition =
        new CameraPosition(target: latLngPosition, zoom: 14);
    newGoogleMapController
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    //gets your address
    String address =
        await AssistantMethods.searchCoordinateAddress(position, context);
    print("This is your Address: " + address);
  }

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,

      //hamburger button drawer on top left
      drawer: Container(
        color: Colors.white,
        width: 255.0,
        child: Drawer(
          child: ListView(
            children: [
              //Drawer Header
              Container(
                height: 165.0,
                child: DrawerHeader(
                  decoration: BoxDecoration(color: Colors.white),
                  child: Row(
                    children: [
                      //profile pic on left
                      Image.asset("images/user_icon.png",
                          height: 65.0, width: 65.0),
                      SizedBox(width: 16.0),

                      //everything to right
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Arvil Dey",
                            style: TextStyle(
                                fontSize: 16.0, fontFamily: "Brand-Bold"),
                          ),
                          SizedBox(height: 6.0),
                          Text("Visit Profile"),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              DividerWidget(),

              SizedBox(height: 12.0),

              //Drawer Body Buttons
              //History
              ListTile(
                leading: Icon(Icons.history),
                title: Text(
                  "History",
                  style: TextStyle(fontSize: 15.0),
                ),
              ),

              //Visit Profile
              ListTile(
                leading: Icon(Icons.person),
                title: Text(
                  "Visit Profile",
                  style: TextStyle(fontSize: 15.0),
                ),
              ),

              //About
              ListTile(
                leading: Icon(Icons.info),
                title: Text(
                  "About",
                  style: TextStyle(fontSize: 15.0),
                ),
              ),

              //Logout
              GestureDetector(
                onTap: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                      context, LoginScreen.idScreen, (route) => false);
                },
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text(
                    "Sign Out",
                    style: TextStyle(fontSize: 15.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      body: Stack(
        children: [
          //Google Maps
          GoogleMap(
            padding: EdgeInsets.only(bottom: bottomPaddingOfMap),
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            initialCameraPosition: _kGooglePlex,
            myLocationEnabled: true,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: true,
            polylines: polylineSet,
            markers: markersSet,
            onMapCreated: (GoogleMapController controller) {
              _controllerGoogleMap.complete(controller);
              newGoogleMapController = controller;

              setState(() {
                bottomPaddingOfMap = 300.0;
              });

              locatePosition();
            },
          ),

          //hamburger button for drawer
          Positioned(
            top: 57.0,
            left: 30.0,
            child: GestureDetector(
              onTap: () {
                if (drawerOpen) {
                  scaffoldKey.currentState.openDrawer();
                } else {
                  //after cross button is clicked --> reset app to initial home page state
                  resetApp();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 6.0,
                      spreadRadius: 0.5,
                      offset: Offset(
                        0.7,
                        0.7,
                      ),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon((drawerOpen) ? Icons.menu : Icons.close,
                      color: Colors.black),
                  radius: 20.0,
                ),
              ),
            ),
          ),

          //White box at the bottom of home screen for pickup/dropoff
          Positioned(
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            child: AnimatedSize(
              vsync: this,
              curve: Curves.bounceIn,
              duration: new Duration(milliseconds: 160),
              child: Container(
                height: searchContainerHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18.0),
                    topRight: Radius.circular(18.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 16.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 6.0),

                      //hi there
                      Text(
                        "Hi there!",
                        style: TextStyle(
                          fontSize: 11.0,
                        ),
                      ),

                      //where to?
                      Text(
                        "Where to?",
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20.0),

                      //search box
                      GestureDetector(
                        onTap: () async {
                          //search function
                          var res = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SearchScreen(),
                            ),
                          );

                          //after searching screen is closed res should have "obtainDirection"
                          //this was sent after popping from SearchScreen
                          //if that's the case then get place direction
                          if (res == "obtainDirection") {
                            displayRideDetailsContainer();
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 6.0,
                                spreadRadius: 0.5,
                                offset: Offset(0.7, 0.7),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                //search icon
                                Icon(
                                  Icons.search,
                                  color: Color(0xFFEEBE1C),
                                ),

                                //placeholder text
                                SizedBox(width: 10.0),
                                Text("Search Destination"),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 24.0),

                      //your home address box
                      Row(
                        children: [
                          Icon(Icons.home, color: Colors.grey),
                          SizedBox(width: 12.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(Provider.of<AppData>(context)
                                          .pickupLocation !=
                                      null
                                  ? Provider.of<AppData>(context)
                                      .pickupLocation
                                      .placeName
                                  : "Add Home"),
                              SizedBox(height: 4.0),
                              Text(
                                "Your home address",
                                style: TextStyle(
                                    color: Colors.black54, fontSize: 12.0),
                              ),
                            ],
                          )
                        ],
                      ),
                      SizedBox(height: 10.0),

                      //divider
                      DividerWidget(),

                      SizedBox(height: 16.0),

                      //your work address box
                      Row(
                        children: [
                          Icon(Icons.work, color: Colors.grey),
                          SizedBox(width: 12.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Add Work"),
                              SizedBox(height: 4.0),
                              Text(
                                "Your office address",
                                style: TextStyle(
                                    color: Colors.black54, fontSize: 12.0),
                              ),
                            ],
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),

          //White box for bottom of home screen for car & payment
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: AnimatedSize(
              vsync: this,
              curve: Curves.bounceIn,
              duration: new Duration(milliseconds: 160),
              child: Container(
                height: rideDetailsContainerHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.0),
                    topRight: Radius.circular(16.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 16.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 30.0),
                  child: Column(
                    children: [
                      //available cars container
                      Container(
                        width: double.infinity,
                        color: Colors.teal[100],
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: Row(
                            children: [
                              Image.asset(
                                "images/taxi2.png",
                                height: 85.0,
                                width: 85.0,
                              ),
                              SizedBox(width: 16.0),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  //type of vehicle
                                  Text(
                                    "Car",
                                    style: TextStyle(
                                        fontSize: 18.0,
                                        fontFamily: "Brand-Bold"),
                                  ),

                                  //distance
                                  Text(
                                    (tripDirectionDetails != null)
                                        ? tripDirectionDetails.distanceText
                                        : "",
                                    style: TextStyle(
                                        fontSize: 14.0,
                                        color: Colors.grey[600]),
                                  )
                                ],
                              ),
                              Expanded(child: Container()),

                              //price of trip
                              Text(
                                ((tripDirectionDetails != null)
                                    ? '\$${AssistantMethods.calculateFares(tripDirectionDetails)}'
                                    : ""),
                                style: TextStyle(
                                    fontSize: 16.0, color: Colors.grey[600]),
                              )
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 20.0),

                      //payment method implementation with Stripe
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 25.0),
                        child: Row(
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _source = null;
                                  _paymentIntent = null;
                                  _paymentMethod = null;
                                  _paymentToken = null;
                                });

                                StripePayment.createPaymentMethod(
                                  PaymentMethodRequest(
                                    card: testCard,
                                  ),
                                ).then((paymentMethod) {
                                  scaffoldKey.currentState.showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Received ${paymentMethod.id}')));
                                  setState(() {
                                    _paymentMethod = paymentMethod;
                                  });
                                });
                              },
                              child: Text("Add Payment Method"),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 15.0),

                      //request button
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: RaisedButton(
                          onPressed: () {
                            displayRequestRideContainer();
                          },
                          color: Color(0xFFEEBE1C),
                          shape: new RoundedRectangleBorder(
                            borderRadius: new BorderRadius.circular(24.0),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(17.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Request",
                                  style: TextStyle(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Icon(Icons.local_taxi,
                                    color: Colors.white, size: 26.0),
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),

          //White box at bottom of screen for ride requesting/cancel
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    spreadRadius: 0.5,
                    blurRadius: 16.0,
                    color: Colors.black54,
                    offset: Offset(0.7, 0.7),
                  ),
                ],
              ),
              height: requestRideContainerHeight,
              child: Column(
                children: [
                  SizedBox(height: 30.0),
                  SizedBox(
                    width: 295.0,
                    child: DefaultTextStyle(
                      style: const TextStyle(
                        fontSize: 30.0,
                        fontFamily: 'Agne',
                        color: Colors.black,
                      ),
                      child: AnimatedTextKit(
                        animatedTexts: [
                          TypewriterAnimatedText(''),
                          TypewriterAnimatedText('Requesting a ride...'),
                          TypewriterAnimatedText(''),
                          TypewriterAnimatedText('Please wait...'),
                          TypewriterAnimatedText(''),
                        ],
                        onTap: () {
                          print("Tap Event");
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 50.0),
                  GestureDetector(
                    onTap: () {
                      cancelRideRequest();
                      resetApp();
                    },
                    child: Container(
                      height: 60.0,
                      width: 60.0,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30.0),
                        border: Border.all(
                          width: 2.0,
                          color: Colors.yellowAccent[400],
                        ),
                      ),
                      child: Icon(Icons.close,
                          size: 26.0, color: Colors.grey[600]),
                    ),
                  ),
                  SizedBox(
                    height: 12.0,
                  ),
                  Container(
                    width: double.infinity,
                    child: Text(
                      "Cancel Ride",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14.0),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  //gets initial location's lat & long
  //gets destination location's lat & long
  //set polyline between both points
  Future<void> getPlaceDirection() async {
    var initialPos =
        Provider.of<AppData>(context, listen: false).pickupLocation;
    var finalPos = Provider.of<AppData>(context, listen: false).dropoffLocation;

    var pickupLatLng = LatLng(initialPos.latitude, initialPos.longitude);
    var dropoffLatLng = LatLng(finalPos.latitude, finalPos.longitude);

    //show loading screen
    showDialog(
      context: context,
      builder: (BuildContext context) =>
          ProgressDialog(message: "Setting Drop-off..."),
    );

    //retrieve route from pickup to dropoff
    var details = await AssistantMethods.obtainPlaceDirectionDetails(
        pickupLatLng, dropoffLatLng);

    setState(() {
      tripDirectionDetails = details;
    });

    //stop loading screen
    Navigator.pop(context);

    print("Encoded points: ");
    print(details.encodedPoints);

    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodedPolyLinePointsResult =
        polylinePoints.decodePolyline(details.encodedPoints);

    if (decodedPolyLinePointsResult.isNotEmpty) {
      decodedPolyLinePointsResult.forEach(
        (PointLatLng pointLatLng) {
          pLineCoordinates.add(
            LatLng(pointLatLng.latitude, pointLatLng.longitude),
          );
        },
      );
    }

    polylineSet.clear();

    setState(() {
      Polyline polyline = Polyline(
        color: Color(0xFFEEBE1C),
        polylineId: PolylineId("PolylineID"),
        jointType: JointType.round,
        points: pLineCoordinates,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      polylineSet.add(polyline);
    });

    LatLngBounds latLngBounds;
    if (pickupLatLng.latitude > dropoffLatLng.latitude &&
        pickupLatLng.longitude > dropoffLatLng.longitude) {
      latLngBounds =
          LatLngBounds(southwest: dropoffLatLng, northeast: pickupLatLng);
    } else if (pickupLatLng.longitude > dropoffLatLng.longitude) {
      latLngBounds = LatLngBounds(
        southwest: LatLng(pickupLatLng.latitude, dropoffLatLng.longitude),
        northeast: LatLng(dropoffLatLng.latitude, pickupLatLng.longitude),
      );
    } else if (pickupLatLng.latitude > dropoffLatLng.latitude) {
      latLngBounds = LatLngBounds(
        southwest: LatLng(dropoffLatLng.latitude, pickupLatLng.longitude),
        northeast: LatLng(pickupLatLng.latitude, dropoffLatLng.longitude),
      );
    } else {
      latLngBounds =
          LatLngBounds(southwest: pickupLatLng, northeast: dropoffLatLng);
    }

    newGoogleMapController
        .animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 70));

    Marker pickupLocMarker = Marker(
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
      infoWindow:
          InfoWindow(title: initialPos.placeName, snippet: "My Location"),
      position: pickupLatLng,
      markerId: MarkerId("pickupID"),
    );

    Marker dropoffLocMarker = Marker(
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
      infoWindow:
          InfoWindow(title: finalPos.placeName, snippet: "Drop-off Location"),
      position: dropoffLatLng,
      markerId: MarkerId("dropoffID"),
    );

    setState(() {
      markersSet.add(pickupLocMarker);
      markersSet.add(dropoffLocMarker);
    });

    Circle pickupLocCircle = Circle(
      fillColor: Colors.blueAccent,
      center: pickupLatLng,
      radius: 12,
      strokeWidth: 4,
      strokeColor: Colors.blueAccent,
      circleId: CircleId("pickupID"),
    );

    Circle dropoffLocCircle = Circle(
      fillColor: Colors.deepPurple,
      center: dropoffLatLng,
      radius: 12,
      strokeWidth: 4,
      strokeColor: Colors.deepPurple,
      circleId: CircleId("dropoffID"),
    );

    setState(() {
      circlesSet.add(pickupLocCircle);
      circlesSet.add(dropoffLocCircle);
    });
  }
}
