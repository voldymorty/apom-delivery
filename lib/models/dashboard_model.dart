// To parse this JSON data, do
//
//     final dashboardModel = dashboardModelFromJson(jsonString);

import 'dart:convert';

DashboardModel dashboardModelFromJson(String str) => DashboardModel.fromJson(json.decode(str));

String dashboardModelToJson(DashboardModel data) => json.encode(data.toJson());

class DashboardModel {
    bool success;
    Data data;

    DashboardModel({
        required this.success,
        required this.data,
    });

    factory DashboardModel.fromJson(Map<String, dynamic> json) => DashboardModel(
        success: json["success"],
        data: Data.fromJson(json["data"]),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "data": data.toJson(),
    };
}

class Data {
    Completed completed;
    Completed inProgress;
    Completed pending;
    Completed upcoming;

    Data({
        required this.completed,
        required this.inProgress,
        required this.pending,
        required this.upcoming,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        completed: Completed.fromJson(json["completed"]),
        inProgress: Completed.fromJson(json["in_progress"]),
        pending: Completed.fromJson(json["pending"]),
        upcoming: Completed.fromJson(json["upcoming"]),
    );

    Map<String, dynamic> toJson() => {
        "completed": completed.toJson(),
        "in_progress": inProgress.toJson(),
        "pending": pending.toJson(),
        "upcoming": upcoming.toJson(),
    };
}

class Completed {
    int total;
    int pickups;
    int deliveries;

    Completed({
        required this.total,
        required this.pickups,
        required this.deliveries,
    });

    factory Completed.fromJson(Map<String, dynamic> json) => Completed(
        total: json["total"],
        pickups: json["pickups"],
        deliveries: json["deliveries"],
    );

    Map<String, dynamic> toJson() => {
        "total": total,
        "pickups": pickups,
        "deliveries": deliveries,
    };
}
