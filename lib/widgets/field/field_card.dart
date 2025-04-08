import 'package:flutter/material.dart';
import '../../models/field_model.dart';
import '../../config/theme.dart';

class FieldCard extends StatelessWidget {
  final FieldModel field;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String? farmName; // 농가 이름 (옵션)
  final bool isSelected;

  const FieldCard({
    Key? key,
    required this.field,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.farmName,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: AppTheme.primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          field.address.full,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (field.address.detail != null &&
                            field.address.detail!.isNotEmpty)
                          Text(
                            field.address.detail!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (onEdit != null || onDelete != null)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'edit' && onEdit != null) {
                          onEdit!();
                        } else if (value == 'delete' && onDelete != null) {
                          onDelete!();
                        }
                      },
                      itemBuilder: (context) => [
                        if (onEdit != null)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('수정'),
                              ],
                            ),
                          ),
                        if (onDelete != null)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text('삭제', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  // 농가 정보 (제공된 경우)
                  if (farmName != null)
                    Expanded(
                      child: _buildInfoItem(
                        Icons.agriculture,
                        farmName!,
                        '농가',
                      ),
                    ),

                  // 면적 정보
                  Expanded(
                    child: _buildInfoItem(
                      Icons.straighten,
                      '${field.area.value} ${field.area.unit}',
                      '면적',
                    ),
                  ),

                  // 작물 종류
                  Expanded(
                    child: _buildInfoItem(
                      Icons.grass,
                      field.cropType,
                      '작물',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 작업 단계 및 수확 예정일
              Row(
                children: [
                  // 작업 단계 배지
                  _buildStageBadge(field.currentStage.stage),

                  const SizedBox(width: 12),

                  // 수확 예정일
                  if (field.estimatedHarvestDate != null)
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: AppTheme.textSecondaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '수확예정: ${_formatDate(field.estimatedHarvestDate!)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, String label) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStageBadge(String stage) {
    // 단계별 색상 구분
    Color stageColor;
    switch (stage) {
      case '계약예정':
        stageColor = Colors.blue;
        break;
      case '계약완료':
        stageColor = Colors.purple;
        break;
      case '뽑기준비':
      case '뽑기진행':
        stageColor = Colors.orange;
        break;
      case '뽑기완료':
        stageColor = Colors.green;
        break;
      case '자르기준비':
      case '자르기진행':
        stageColor = Colors.amber;
        break;
      case '자르기완료':
        stageColor = Colors.lightGreen;
        break;
      case '담기준비':
      case '담기진행':
        stageColor = Colors.indigo;
        break;
      case '담기완료':
        stageColor = Colors.teal;
        break;
      case '운송예정':
      case '운송진행':
        stageColor = Colors.deepOrange;
        break;
      case '운송완료':
        stageColor = Colors.green.shade800;
        break;
      default:
        stageColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: stageColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: stageColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStageIcon(stage),
            size: 14,
            color: stageColor,
          ),
          const SizedBox(width: 4),
          Text(
            stage,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: stageColor,
            ),
          ),
        ],
      ),
    );
  }

  // 작업 단계별 아이콘
  IconData _getStageIcon(String stage) {
    if (stage.contains('계약')) {
      return Icons.description;
    } else if (stage.contains('뽑기')) {
      return Icons.grass;
    } else if (stage.contains('자르기')) {
      return Icons.content_cut;
    } else if (stage.contains('담기')) {
      return Icons.shopping_basket;
    } else if (stage.contains('운송')) {
      return Icons.local_shipping;
    } else {
      return Icons.help_outline;
    }
  }

  // 날짜 포맷팅
  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}
