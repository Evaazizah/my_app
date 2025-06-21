import 'package:dio/dio.dart';
import 'package:trenix/services/api/dio_client.dart';

class TrackingStatus {
  final String trackingId;
  final String carrier;
  final String status;
  final String lastUpdate;
  final String location;

  TrackingStatus({
    required this.trackingId,
    required this.carrier,
    required this.status,
    required this.lastUpdate,
    required this.location,
  });

  factory TrackingStatus.fromJson(Map<String, dynamic> json) {
    return TrackingStatus(
      trackingId: json['trackingId'],
      carrier: json['carrier'],
      status: json['status'],
      lastUpdate: json['lastUpdate'],
      location: json['location'],
    );
  }
}

class TrackApiService {
  final Dio _dio = DioClient().dio;

  Future<TrackingStatus> startTracking(
    String trackingNumber,
    String carrier,
  ) async {
    try {
      final response = await _dio.post(
        '/tracking',
        data: {'trackingNumber': trackingNumber, 'carrier': carrier},
      );
      if (response.statusCode == 201) {
        return TrackingStatus.fromJson(response.data);
      } else {
        throw Exception('Failed to start tracking');
      }
    } on DioException catch (e) {
      throw Exception('Failed to start tracking: ${e.message}');
    }
  }

  Future<TrackingStatus> getTrackingStatus(String trackingId) async {
    try {
      final response = await _dio.get('/tracking/$trackingId');
      if (response.statusCode == 200) {
        return TrackingStatus.fromJson(response.data);
      } else {
        throw Exception('Failed to get tracking status');
      }
    } on DioException catch (e) {
      throw Exception('Failed to get tracking status: ${e.message}');
    }
  }

  Future<List<TrackingStatus>> getAllTrackingStatuses() async {
    try {
      final response = await _dio.get('/tracking');
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => TrackingStatus.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to get tracking statuses');
      }
    } on DioException catch (e) {
      throw Exception('Failed to get tracking statuses: ${e.message}');
    }
  }

  Future<void> stopTracking(String trackingId) async {
    try {
      final response = await _dio.delete('/tracking/$trackingId');
      if (response.statusCode != 204) {
        throw Exception('Failed to stop tracking');
      }
    } on DioException catch (e) {
      throw Exception('Failed to stop tracking: ${e.message}');
    }
  }

  Future<void> updateTrackingStatus(
    String trackingId,
    String status,
    String location,
  ) async {
    try {
      final response = await _dio.put(
        '/tracking/$trackingId',
        data: {'status': status, 'location': location},
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update tracking status');
      }
    } on DioException catch (e) {
      throw Exception('Failed to update tracking status: ${e.message}');
    }
  }
}
