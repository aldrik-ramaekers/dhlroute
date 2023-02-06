class RouteList {
  List<RouteData>? routes;

  RouteList({this.routes});

  RouteList.fromJson(Map<String, dynamic> json) {
    if (json['routes'] != null) {
      routes = <RouteData>[];
      json['routes'].forEach((v) {
        routes!.add(new RouteData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.routes != null) {
      data['routes'] = this.routes!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class RouteData {
  String? timeframeKey;
  String? tripKey;
  String? tripNumber;
  String? tripPdaStatus;
  String? tripPdaStatusDescription;
  String? tripSequenceNumber;
  String? numberInTrip;
  String? plate;
  bool? damageRegistration;
  String? eva;
  String? tripDate;
  String? firstAddressLat;
  String? firstAddressLng;
  String? started;
  String? allTasksFinished;
  String? startKm;
  String? endKm;
  String? tasksEnriched;
  String? inTripScanFinished;
  String? evaAdded;
  String? tripStartRequestSent;

  RouteData(
      {this.timeframeKey,
      this.tripKey,
      this.tripNumber,
      this.tripPdaStatus,
      this.tripPdaStatusDescription,
      this.tripSequenceNumber,
      this.numberInTrip,
      this.plate,
      this.damageRegistration,
      this.eva,
      this.tripDate,
      this.firstAddressLat,
      this.firstAddressLng,
      this.started,
      this.allTasksFinished,
      this.startKm,
      this.endKm,
      this.tasksEnriched,
      this.inTripScanFinished,
      this.evaAdded,
      this.tripStartRequestSent});

  RouteData.fromJson(Map<String, dynamic> json) {
    timeframeKey = json['timeframe_key'];
    tripKey = json['trip_key'];
    tripNumber = json['trip_number'];
    tripPdaStatus = json['trip_pda_status'];
    tripPdaStatusDescription = json['trip_pda_status_description'];
    tripSequenceNumber = json['trip_sequence_number'];
    numberInTrip = json['number_in_trip'];
    plate = json['plate'];
    damageRegistration = json['damage_registration'];
    eva = json['eva'];
    tripDate = json['trip_date'];
    firstAddressLat = json['first_address_lat'];
    firstAddressLng = json['first_address_lng'];
    started = json['started'];
    allTasksFinished = json['all_tasks_finished'];
    startKm = json['start_km'];
    endKm = json['end_km'];
    tasksEnriched = json['tasks_enriched'];
    inTripScanFinished = json['in_trip_scan_finished'];
    evaAdded = json['eva_added'];
    tripStartRequestSent = json['trip_start_request_sent'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['timeframe_key'] = this.timeframeKey;
    data['trip_key'] = this.tripKey;
    data['trip_number'] = this.tripNumber;
    data['trip_pda_status'] = this.tripPdaStatus;
    data['trip_pda_status_description'] = this.tripPdaStatusDescription;
    data['trip_sequence_number'] = this.tripSequenceNumber;
    data['number_in_trip'] = this.numberInTrip;
    data['plate'] = this.plate;
    data['damage_registration'] = this.damageRegistration;
    data['eva'] = this.eva;
    data['trip_date'] = this.tripDate;
    data['first_address_lat'] = this.firstAddressLat;
    data['first_address_lng'] = this.firstAddressLng;
    data['started'] = this.started;
    data['all_tasks_finished'] = this.allTasksFinished;
    data['start_km'] = this.startKm;
    data['end_km'] = this.endKm;
    data['tasks_enriched'] = this.tasksEnriched;
    data['in_trip_scan_finished'] = this.inTripScanFinished;
    data['eva_added'] = this.evaAdded;
    data['trip_start_request_sent'] = this.tripStartRequestSent;
    return data;
  }
}
