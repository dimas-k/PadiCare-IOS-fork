import 'package:flutter/material.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/logic/models/prediction_model.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/logic/utils/disease_label.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/presentation/widgets/top_predictions_card.dart';
import 'expert_advice_card.dart';

class PredictionResultCard extends StatelessWidget {
  final PredictionResult result;
  final bool isHistoryMode;
  final Color primaryColor;
  final Color accentColor;

  const PredictionResultCard({
    Key? key,
    required this.result,
    required this.isHistoryMode,
    required this.primaryColor,
    required this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          if (result.hasTopPredictions)
            TopPredictionsCard(
              predictions: result.top3Predictions,
              isHistoryMode: isHistoryMode,
              primaryColor: primaryColor,
            )
          else if (isHistoryMode)
            _buildNoTopPredictionsMessage(),
          SizedBox(height: 16),
          if (result.expertAdvice != null && result.expertAdvice!.isNotEmpty)
            ExpertAdviceCard(
              advice: result.expertAdvice!,
              primaryColor: primaryColor,
              accentColor: accentColor,
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.1),
            accentColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.science_outlined, color: primaryColor, size: 28),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Hasil Diagnosa',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    if (isHistoryMode) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Riwayat',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  formatDiseaseName(result.predictedClass),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          // Badge confidence disembunyikan untuk hasil OOD (bukan padi),
          // karena tidak ada skor keyakinan penyakit yang relevan.
          if (result.predictedClass != 'bukan_padi')
            Container(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: result.confidencePercentage > 70
                  ? Colors.green.withOpacity(0.15)
                  : Colors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: result.confidencePercentage > 70
                    ? Colors.green.withOpacity(0.3)
                    : Colors.orange.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              '${result.confidencePercentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: result.confidencePercentage > 70
                    ? Colors.green.shade700
                    : Colors.orange.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoTopPredictionsMessage() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Top 3 prediksi tidak tersedia untuk riwayat ini',
                style: TextStyle(color: Colors.orange[700], fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
