import 'dart:ui' show Color;
import 'package:flutter/material.dart' show Colors;

// lib/modules/disesase/logic/models/prediction_model.dart

class TopPrediction {
  final String className;
  final double confidence;
  final int rank;

  TopPrediction({
    required this.className,
    required this.confidence,
    required this.rank,
  });

  factory TopPrediction.fromJson(Map<String, dynamic> json) {
    return TopPrediction(
      className: json['class_name'] ?? json['className'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      rank: json['rank'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'class_name': className,
    'confidence': confidence,
    'rank': rank,
  };

  // Helper methods
  bool get isHealthy =>
      className.toLowerCase().contains('sehat') ||
      className.toLowerCase().contains('harvest') ||
      className.toLowerCase().contains('normal');

  String get confidenceLevel {
    if (confidence >= 80) return 'Tinggi';
    if (confidence >= 60) return 'Sedang';
    return 'Rendah';
  }

  Color get confidenceColor {
    if (confidence >= 80) return Colors.green;
    if (confidence >= 60) return Colors.orange;
    return Colors.red;
  }

  String get diseaseCategory {
    if (isHealthy) return 'Sehat';
    return 'Penyakit';
  }

  @override
  String toString() {
    return 'TopPrediction(rank: $rank, class: $className, confidence: ${confidence.toStringAsFixed(1)}%)';
  }
}

class PredictionResult {
  final String predictedClass;
  final double confidencePercentage;
  final String? expertAdvice;
  final double? processingTime;
  final bool success;

  // PostgreSQL integration fields
  final String? predictionId;
  final bool? savedToDatabase;
  final String? databaseNote;
  final Map<String, dynamic>? performance;

  // Top 3 predictions support
  final List<TopPrediction>? topPredictions;
  final Map<String, dynamic>? rawPredictions;

  PredictionResult({
    required this.predictedClass,
    required this.confidencePercentage,
    this.expertAdvice,
    this.processingTime,
    required this.success,
    this.predictionId,
    this.savedToDatabase,
    this.databaseNote,
    this.performance,
    this.topPredictions,
    this.rawPredictions,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    // Parse top predictions
    List<TopPrediction>? topPredictions;

    if (json['top_predictions'] != null) {
      try {
        final topPredsList = json['top_predictions'] as List;
        topPredictions =
            topPredsList.asMap().entries.map((entry) {
              int index = entry.key;
              var predData = entry.value;

              // Ensure predData is Map
              if (predData is Map<String, dynamic>) {
                // Add rank if not present
                if (!predData.containsKey('rank')) {
                  predData['rank'] = index + 1;
                }
                return TopPrediction.fromJson(predData);
              } else {
                // Handle case where predData might be in different format
                return TopPrediction(
                  className: predData.toString(),
                  confidence: 0.0,
                  rank: index + 1,
                );
              }
            }).toList();

        print('✅ Parsed ${topPredictions.length} top predictions');
        for (var pred in topPredictions) {
          print(
            '   ${pred.rank}. ${pred.className}: ${pred.confidence.toStringAsFixed(1)}%',
          );
        }
      } catch (e) {
        print('❌ Error parsing top_predictions: $e');
        topPredictions = null;
      }
    }

    // Alternative: Parse from raw_predictions if top_predictions not available
    if (topPredictions == null && json['raw_predictions'] != null) {
      try {
        final rawPreds = json['raw_predictions'] as Map<String, dynamic>;
        final sortedPreds =
            rawPreds.entries
                .map(
                  (entry) =>
                      MapEntry(entry.key, (entry.value as num).toDouble()),
                )
                .toList()
              ..sort((a, b) => b.value.compareTo(a.value));

        topPredictions =
            sortedPreds
                .take(3)
                .toList()
                .asMap()
                .entries
                .map(
                  (entry) => TopPrediction(
                    className: entry.value.key,
                    confidence:
                        entry.value.value * 100, // Convert to percentage
                    rank: entry.key + 1,
                  ),
                )
                .toList();

        print(
          '✅ Generated top predictions from raw_predictions: ${topPredictions.length}',
        );
      } catch (e) {
        print('❌ Error generating top predictions from raw_predictions: $e');
        topPredictions = null;
      }
    }

    return PredictionResult(
      predictedClass: json['predicted_class'] ?? '',
      confidencePercentage: (json['confidence_percentage'] ?? 0).toDouble(),
      expertAdvice: json['recommendation'] ?? json['expert_advice'],
      processingTime: (json['detection_time_ms'] ?? json['processing_time'])?.toDouble(),
      success: json['predicted_class'] != null,
      predictionId: json['prediction_id']?.toString(),
      savedToDatabase: json['saved_to_database'],
      databaseNote: json['database_note'],
      performance: json['performance'],
      topPredictions: topPredictions,
      rawPredictions: json['raw_predictions'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'predicted_class': predictedClass,
    'confidence_percentage': confidencePercentage,
    'expert_advice': expertAdvice,
    'processing_time': processingTime,
    'success': success,
    'prediction_id': predictionId,
    'saved_to_database': savedToDatabase,
    'database_note': databaseNote,
    'performance': performance,
    'top_predictions': topPredictions?.map((pred) => pred.toJson()).toList(),
    'raw_predictions': rawPredictions,
  };

  // Helper methods
  bool get isHealthy =>
      predictedClass.toLowerCase().contains('sehat') ||
      predictedClass.toLowerCase().contains('harvest') ||
      predictedClass.toLowerCase().contains('normal');

  String get confidenceLevel {
    if (confidencePercentage >= 80) return 'Tinggi';
    if (confidencePercentage >= 60) return 'Sedang';
    return 'Rendah';
  }

  Color get confidenceColor {
    if (confidencePercentage >= 80) return Colors.green;
    if (confidencePercentage >= 60) return Colors.orange;
    return Colors.red;
  }

  String get diseaseCategory {
    if (isHealthy) return 'Sehat';
    return 'Penyakit';
  }

  // New helper methods for top predictions
  bool get hasTopPredictions =>
      topPredictions != null && topPredictions!.isNotEmpty;

  TopPrediction? get topPrediction =>
      hasTopPredictions ? topPredictions!.first : null;

  List<TopPrediction> get top3Predictions {
    if (!hasTopPredictions) return [];
    return topPredictions!.take(3).toList();
  }

  // Get alternative predictions (excluding the main prediction)
  List<TopPrediction> get alternativePredictions {
    if (!hasTopPredictions) return [];
    return topPredictions!
        .where((pred) => pred.className != predictedClass)
        .take(2)
        .toList();
  }

  // Calculate prediction diversity (how close are the top predictions)
  double get predictionDiversity {
    if (!hasTopPredictions || topPredictions!.length < 2) return 0.0;

    final top = topPredictions!.first.confidence;
    final second =
        topPredictions!.length > 1 ? topPredictions![1].confidence : 0.0;

    return top - second; // Higher difference = more confident
  }

  // Get prediction reliability level
  String get reliabilityLevel {
    if (!hasTopPredictions) return 'Unknown';

    final diversity = predictionDiversity;
    if (diversity >= 30) return 'Sangat Yakin';
    if (diversity >= 15) return 'Yakin';
    if (diversity >= 5) return 'Cukup Yakin';
    return 'Kurang Yakin';
  }

  // Get reliability color
  Color get reliabilityColor {
    final diversity = predictionDiversity;
    if (diversity >= 30) return Colors.green;
    if (diversity >= 15) return Colors.lightGreen;
    if (diversity >= 5) return Colors.orange;
    return Colors.red;
  }

  // Summary information
  String get predictionSummary {
    if (!hasTopPredictions) {
      return '$predictedClass (${confidencePercentage.toStringAsFixed(1)}%)';
    }

    final top3 = top3Predictions;
    final summary = top3
        .map(
          (pred) =>
              '${pred.className} (${pred.confidence.toStringAsFixed(1)}%)',
        )
        .join(', ');

    return 'Top 3: $summary';
  }

  @override
  String toString() {
    return 'PredictionResult(\n'
        '  predictedClass: $predictedClass,\n'
        '  confidence: ${confidencePercentage.toStringAsFixed(1)}%,\n'
        '  topPredictions: ${topPredictions?.length ?? 0} items,\n'
        '  reliability: $reliabilityLevel,\n'
        '  success: $success\n'
        ')';
  }

  // Create a copy with updated fields
  PredictionResult copyWith({
    String? predictedClass,
    double? confidencePercentage,
    String? expertAdvice,
    double? processingTime,
    bool? success,
    String? predictionId,
    bool? savedToDatabase,
    String? databaseNote,
    Map<String, dynamic>? performance,
    List<TopPrediction>? topPredictions,
    Map<String, dynamic>? rawPredictions,
  }) {
    return PredictionResult(
      predictedClass: predictedClass ?? this.predictedClass,
      confidencePercentage: confidencePercentage ?? this.confidencePercentage,
      expertAdvice: expertAdvice ?? this.expertAdvice,
      processingTime: processingTime ?? this.processingTime,
      success: success ?? this.success,
      predictionId: predictionId ?? this.predictionId,
      savedToDatabase: savedToDatabase ?? this.savedToDatabase,
      databaseNote: databaseNote ?? this.databaseNote,
      performance: performance ?? this.performance,
      topPredictions: topPredictions ?? this.topPredictions,
      rawPredictions: rawPredictions ?? this.rawPredictions,
    );
  }

  // Factory method untuk create dari raw predictions
  factory PredictionResult.fromRawPredictions({
    required Map<String, double> rawPredictions,
    String? expertAdvice,
    double? processingTime,
    String? predictionId,
  }) {
    // Sort predictions by confidence
    final sortedPreds =
        rawPredictions.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    // Get main prediction
    final mainPred = sortedPreds.first;

    // Create top predictions
    final topPredictions =
        sortedPreds
            .take(3)
            .toList()
            .asMap()
            .entries
            .map(
              (entry) => TopPrediction(
                className: entry.value.key,
                confidence: entry.value.value * 100,
                rank: entry.key + 1,
              ),
            )
            .toList();

    return PredictionResult(
      predictedClass: mainPred.key,
      confidencePercentage: mainPred.value * 100,
      expertAdvice: expertAdvice,
      processingTime: processingTime,
      success: true,
      predictionId: predictionId,
      topPredictions: topPredictions,
      rawPredictions: rawPredictions.map((k, v) => MapEntry(k, v as dynamic)),
    );
  }
}

// Extension untuk debugging
extension PredictionResultDebug on PredictionResult {
  void debugPrint() {
    print('🔍 PredictionResult Debug:');
    print(
      '   Main: $predictedClass (${confidencePercentage.toStringAsFixed(1)}%)',
    );
    print('   Success: $success');
    print('   Reliability: $reliabilityLevel');

    if (hasTopPredictions) {
      print('   Top Predictions:');
      for (var pred in top3Predictions) {
        print(
          '     ${pred.rank}. ${pred.className}: ${pred.confidence.toStringAsFixed(1)}%',
        );
      }
      print('   Diversity: ${predictionDiversity.toStringAsFixed(1)}%');
    } else {
      print('   No top predictions available');
    }

    if (expertAdvice != null) {
      print('   Expert Advice: ${expertAdvice!.length} characters');
    }
  }
}