class RouteInfo {
  Route? route;

  RouteInfo({this.route});

  RouteInfo.fromJson(Map<String, dynamic> json) {
    route = json['route'] != null ? Route.fromJson(json['route']) : null;
  }
}

class Route {
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
  List<Task>? tasks;
  String? deviceStartLng;
  String? startKm;
  String? started;
  String? deviceStartLat;
  String? lastTripStartReceivedAt;
  String? allTasksFinished;
  String? uniqueStops;
  String? etaFirstStop;
  String? inTripScanFinished;
  String? firstStopLat;
  String? tasksSize;
  String? evaAdded;
  String? tripStartRequestSent;
  String? etaCalculationSuccess;
  String? allParcelKeys;
  String? tasksEnriched;
  String? enrichedFrom;
  String? firstStopLng;

  Route(
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
      this.tasks,
      this.deviceStartLng,
      this.startKm,
      this.started,
      this.deviceStartLat,
      this.lastTripStartReceivedAt,
      this.allTasksFinished,
      this.uniqueStops,
      this.etaFirstStop,
      this.inTripScanFinished,
      this.firstStopLat,
      this.tasksSize,
      this.evaAdded,
      this.tripStartRequestSent,
      this.etaCalculationSuccess,
      this.allParcelKeys,
      this.tasksEnriched,
      this.enrichedFrom,
      this.firstStopLng});

  Route.fromJson(Map<String, dynamic> json) {
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
    if (json['tasks'] != null) {
      tasks = <Task>[];
      json['tasks'].forEach((v) {
        tasks!.add(new Task.fromJson(v));
      });
    }
    deviceStartLng = json['device_start_lng'];
    startKm = json['start_km'];
    started = json['started'];
    deviceStartLat = json['device_start_lat'];
    lastTripStartReceivedAt = json['last_trip_start_received_at'];
    allTasksFinished = json['all_tasks_finished'];
    uniqueStops = json['unique_stops'];
    etaFirstStop = json['eta_first_stop'];
    inTripScanFinished = json['in_trip_scan_finished'];
    firstStopLat = json['first_stop_lat'];
    tasksSize = json['tasks_size'];
    evaAdded = json['eva_added'];
    tripStartRequestSent = json['trip_start_request_sent'];
    etaCalculationSuccess = json['eta_calculation_success'];
    allParcelKeys = json['all_parcel_keys'];
    tasksEnriched = json['tasks_enriched'];
    enrichedFrom = json['enriched_from'];
    firstStopLng = json['first_stop_lng'];
  }
}

class Task {
  String? timeframeKey;
  String? tripKey;
  String? parcelKey;
  String? pid;
  String? postalCodeNumeric;
  String? postalCodeAlpha;
  String? street;
  String? houseNumber;
  String? houseNumberAddition;
  String? city;
  String? addressLatitude;
  String? addressLongitude;
  String? customerShortName;
  String? productTypeDescription;
  String? deliverySequenceNumber;
  String? deliveryMoment;
  String? beginDeliveryPickupWindow;
  String? endDeliveryPickupWindow;
  String? deliveryInstruction;
  dynamic? parcelDeliveryRemark;
  dynamic? courierRemark;
  String? serviceType;
  bool? servicepointParcel;
  String? servicepointid;
  String? nextTimeframeDescrAbbrevation;
  String? parcelStatusKey;
  String? scannedInTrip;
  String? parcelId;
  String? timeframe;
  String? groupFirst;
  String? groupTaskIndex;
  String? grouped;
  String? groupId;
  String? groupSize;
  String? activeGroupSize;
  List<String>? groupPids;
  List<String>? groupParcelKeys;
  String? groupSenderNames;
  String? lat;
  String? lng;
  String? deliveryCode;
  String? fullAddressForNavigation;
  String? finished;
  String? finishedAtTimestamp;
  String? finishedAt;
  String? pNumber;
  String? deviceName;
  String? eta;
  InterventionData? interventionData;
  String? interventionMessageConfirmed;
  String? isIntervention;
  bool? indicationNotAtNeighbours;
  bool? indicationSignatureRequired;
  String? nextTimeframeDescrFull;
  String? nextDeliveryDay;
  List<int>? calculatedGroupPids;

  Task(
      {this.timeframeKey,
      this.tripKey,
      this.parcelKey,
      this.pid,
      this.postalCodeNumeric,
      this.postalCodeAlpha,
      this.street,
      this.houseNumber,
      this.houseNumberAddition,
      this.city,
      this.addressLatitude,
      this.addressLongitude,
      this.customerShortName,
      this.productTypeDescription,
      this.deliverySequenceNumber,
      this.deliveryMoment,
      this.beginDeliveryPickupWindow,
      this.endDeliveryPickupWindow,
      this.deliveryInstruction,
      this.parcelDeliveryRemark,
      this.courierRemark,
      this.serviceType,
      this.servicepointParcel,
      this.servicepointid,
      this.nextTimeframeDescrAbbrevation,
      this.parcelStatusKey,
      this.scannedInTrip,
      this.parcelId,
      this.timeframe,
      this.groupFirst,
      this.groupTaskIndex,
      this.grouped,
      this.groupId,
      this.groupSize,
      this.activeGroupSize,
      this.groupPids,
      this.groupParcelKeys,
      this.groupSenderNames,
      this.lat,
      this.lng,
      this.deliveryCode,
      this.fullAddressForNavigation,
      this.finished,
      this.finishedAtTimestamp,
      this.finishedAt,
      this.pNumber,
      this.deviceName,
      this.eta,
      this.interventionData,
      this.interventionMessageConfirmed,
      this.isIntervention,
      this.indicationNotAtNeighbours,
      this.indicationSignatureRequired,
      this.nextTimeframeDescrFull,
      this.nextDeliveryDay,
      this.calculatedGroupPids});

  Task.fromJson(Map<String, dynamic> json) {
    timeframeKey = json['timeframe_key'];
    tripKey = json['trip_key'];
    parcelKey = json['parcel_key'];
    pid = json['pid'];
    postalCodeNumeric = json['postal_code_numeric'];
    postalCodeAlpha = json['postal_code_alpha'];
    street = json['street'];
    houseNumber = json['house_number'];
    houseNumberAddition = json['house_number_addition'];
    city = json['city'];
    addressLatitude = json['address_latitude'];
    addressLongitude = json['address_longitude'];
    customerShortName = json['customer_short_name'];
    productTypeDescription = json['product_type_description'];
    deliverySequenceNumber = json['delivery_sequence_number'];
    deliveryMoment = json['delivery_moment'];
    beginDeliveryPickupWindow = json['begin_delivery_pickup_window'];
    endDeliveryPickupWindow = json['end_delivery_pickup_window'];
    deliveryInstruction = json['delivery_instruction'];
    parcelDeliveryRemark = json['parcel_delivery_remark'];
    courierRemark = json['courier_remark'];
    serviceType = json['service_type'];
    servicepointParcel = json['servicepoint_parcel'];
    servicepointid = json['servicepointid'];
    nextTimeframeDescrAbbrevation = json['next_timeframe_descr_abbrevation'];
    parcelStatusKey = json['parcel_status_key'];
    scannedInTrip = json['scanned_in_trip'];
    parcelId = json['parcel_id'];
    timeframe = json['timeframe'];
    groupFirst = json['group_first'];
    groupTaskIndex = json['group_task_index'];
    grouped = json['grouped'];
    groupId = json['group_id'];
    groupSize = json['group_size'];
    activeGroupSize = json['active_group_size'];
    groupPids = json['group_pids'].cast<String>();
    groupParcelKeys = json['group_parcel_keys'].cast<String>();
    groupSenderNames = json['group_sender_names'];
    lat = json['lat'];
    lng = json['lng'];
    deliveryCode = json['delivery_code'];
    fullAddressForNavigation = json['full_address_for_navigation'];
    finished = json['finished'];
    finishedAtTimestamp = json['finished_at_timestamp'];
    finishedAt = json['finished_at'];
    pNumber = json['p_number'];
    deviceName = json['device_name'];
    eta = json['eta'];
    interventionData = json['intervention_data'] != null
        ? new InterventionData.fromJson(json['intervention_data'])
        : null;
    interventionMessageConfirmed = json['intervention_message_confirmed'];
    isIntervention = json['is_intervention'];
    indicationNotAtNeighbours = json['indication_not_at_neighbours'];
    indicationSignatureRequired = json['indication_signature_required'];
    nextTimeframeDescrFull = json['next_timeframe_descr_full'];
    nextDeliveryDay = json['next_delivery_day'];
    if (json['calculated_group_pids'] != null) {
      calculatedGroupPids = <int>[];
      json['calculated_group_pids'].forEach((v) {
        calculatedGroupPids!.add(int.parse(v));
      });
    }
  }
}

class InterventionData {
  ServicePointDelivery? servicePointDelivery;
  String? timestamp;
  String? status;
  String? parcelId;
  String? interventionId;
  String? type;
  String? parcelKey;
  TimeframeChange? timeframeChange;
  AgreedPlace? agreedPlace;
  String? agreedPlaceDescription;

  InterventionData(
      {this.servicePointDelivery,
      this.timestamp,
      this.status,
      this.parcelId,
      this.interventionId,
      this.type,
      this.parcelKey,
      this.timeframeChange,
      this.agreedPlace,
      this.agreedPlaceDescription});

  InterventionData.fromJson(Map<String, dynamic> json) {
    servicePointDelivery = json['servicePointDelivery'] != null
        ? new ServicePointDelivery.fromJson(json['servicePointDelivery'])
        : null;
    timestamp = json['timestamp'];
    status = json['status'];
    parcelId = json['parcelId'];
    interventionId = json['interventionId'];
    type = json['type'];
    parcelKey = json['parcelKey'];
    timeframeChange = json['timeframeChange'] != null
        ? new TimeframeChange.fromJson(json['timeframeChange'])
        : null;
    agreedPlace = json['agreedPlace'] != null
        ? new AgreedPlace.fromJson(json['agreedPlace'])
        : null;
    agreedPlaceDescription = json['agreed_place_description'];
  }
}

class ServicePointDelivery {
  String? servicePointId;

  ServicePointDelivery({this.servicePointId});

  ServicePointDelivery.fromJson(Map<String, dynamic> json) {
    servicePointId = json['servicePointId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['servicePointId'] = this.servicePointId;
    return data;
  }
}

class TimeframeChange {
  Timeframe? timeframe;

  TimeframeChange({this.timeframe});

  TimeframeChange.fromJson(Map<String, dynamic> json) {
    timeframe = json['timeframe'] != null
        ? new Timeframe.fromJson(json['timeframe'])
        : null;
  }
}

class Timeframe {
  String? from;
  String? to;

  Timeframe({this.from, this.to});

  Timeframe.fromJson(Map<String, dynamic> json) {
    from = json['from'];
    to = json['to'];
  }
}

class AgreedPlace {
  String? placeDescription;
  String? agreeWithTerms;

  AgreedPlace({this.placeDescription, this.agreeWithTerms});

  AgreedPlace.fromJson(Map<String, dynamic> json) {
    placeDescription = json['placeDescription'];
    agreeWithTerms = json['agreeWithTerms'];
  }
}
