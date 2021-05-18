import 'package:flutter/material.dart';

import 'package:flutter/cupertino.dart';
import 'package:uber_clone/Models/address.dart';

class AppData extends ChangeNotifier {
  Address pickupLocation;
  Address dropoffLocation;

  void updatePickupLocationAddress(Address pickupAddress) {
    pickupLocation = pickupAddress;
    notifyListeners();
  }

  void updateDropOffLocationAddress(Address dropOffAddress) {
    dropoffLocation = dropOffAddress;
    notifyListeners();
  }
}
