// To parse this JSON data, do
//
//     final analyticsModel = analyticsModelFromJson(jsonString);

import 'dart:convert';

AnalyticsModel analyticsModelFromJson(String str) => AnalyticsModel.fromJson(json.decode(str));

String analyticsModelToJson(AnalyticsModel data) => json.encode(data.toJson());

class AnalyticsModel {
    bool success;
    List<Datum> data;

    AnalyticsModel({
        required this.success,
        required this.data,
    });

    factory AnalyticsModel.fromJson(Map<String, dynamic> json) => AnalyticsModel(
        success: json["success"],
        data: List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
    };
}

class Datum {
    String day;
    int pickups;
    int deliveries;

    Datum({
        required this.day,
        required this.pickups,
        required this.deliveries,
    });

    factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        day: json["day"],
        pickups: json["pickups"],
        deliveries: json["deliveries"],
    );

    Map<String, dynamic> toJson() => {
        "day": day,
        "pickups": pickups,
        "deliveries": deliveries,
    };
}
