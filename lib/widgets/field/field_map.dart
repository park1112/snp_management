import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/field_model.dart';

class FieldMapWidget extends StatelessWidget {
  final List<FieldModel> fields;
  final Function(FieldModel) onFieldSelected;
  final FieldModel? selectedField;

  const FieldMapWidget({
    Key? key,
    required this.fields,
    required this.onFieldSelected,
    this.selectedField,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        children: [
          // 가상 지도 배경 (실제로는 Google Maps나 다른 지도 API 사용)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: Colors.grey.shade100,
              child: GridPaper(
                interval: 100,
                divisions: 2,
                subdivisions: 1,
                color: Colors.grey.withOpacity(0.2),
                child: const SizedBox.expand(),
              ),
            ),
          ),

          // 방위 표시
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.navigation,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
          ),

          // 농지 마커들
          ...fields.map((field) => _buildFieldMarker(field, context)),

          // 지도 조작 버튼들
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              children: [
                _buildMapButton(Icons.add, '확대'),
                const SizedBox(height: 8),
                _buildMapButton(Icons.remove, '축소'),
                const SizedBox(height: 8),
                _buildMapButton(Icons.my_location, '현재 위치'),
              ],
            ),
          ),

          // 피쳐 매니저
          Positioned(
            left: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '범례',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '뽑기 완료',
                        style: TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '뽑기 진행 중',
                        style: TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '계약 완료',
                        style: TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 구현 중 메시지
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '지도 기능 구현 예정 (Google Maps API 연동)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 가상의 농지 마커 위치 생성 (실제 구현에서는 좌표 사용)
  Widget _buildFieldMarker(FieldModel field, BuildContext context) {
    // 화면 크기 가져오기
    final size = MediaQuery.of(context).size;

    // 무작위 위치 생성 (재현 가능하도록 농지 ID 기반)
    final hashCode = field.id.hashCode;
    final x = (hashCode % 100) / 100 * (size.width - 80) + 40;
    final y = ((hashCode ~/ 100) % 100) / 100 * (size.height - 80) + 40;

    // 현재 단계에 따른 색상 결정
    Color markerColor;
    switch (field.currentStage.stage) {
      case '계약예정':
      case '계약완료':
        markerColor = Colors.blue;
        break;
      case '뽑기준비':
      case '뽑기진행':
        markerColor = Colors.orange;
        break;
      case '뽑기완료':
        markerColor = Colors.green;
        break;
      case '자르기준비':
      case '자르기진행':
        markerColor = Colors.amber;
        break;
      case '자르기완료':
        markerColor = Colors.lightGreen;
        break;
      case '담기준비':
      case '담기진행':
        markerColor = Colors.indigo;
        break;
      case '담기완료':
        markerColor = Colors.teal;
        break;
      case '운송예정':
      case '운송진행':
        markerColor = Colors.deepOrange;
        break;
      case '운송완료':
        markerColor = Colors.green.shade800;
        break;
      default:
        markerColor = Colors.grey;
    }

    final isSelected = selectedField?.id == field.id;

    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onTap: () => onFieldSelected(field),
        child: Column(
          children: [
            // 선택 효과 (선택된 경우에만)
            if (isSelected)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: markerColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: markerColor.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              )
            else
              // 일반 마커
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: markerColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),

            // 마커 레이블 (선택된 경우에만)
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Text(
                  field.cropType,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: markerColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 지도 조작 버튼
  Widget _buildMapButton(IconData icon, String tooltip) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: () {
          // 지도 기능 구현 시 여기에 로직 추가
        },
        color: AppTheme.primaryColor,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
