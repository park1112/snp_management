import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/field_controller.dart';
import '../../models/field_model.dart';
import '../../config/theme.dart';
import '../../utils/custom_loading.dart';
import 'field_edit_screen.dart';

class FieldDetailScreen extends StatefulWidget {
  final String fieldId;

  const FieldDetailScreen({
    Key? key,
    required this.fieldId,
  }) : super(key: key);

  @override
  State<FieldDetailScreen> createState() => _FieldDetailScreenState();
}

class _FieldDetailScreenState extends State<FieldDetailScreen> {
  final FieldController controller = Get.find<FieldController>();

  @override
  void initState() {
    super.initState();
    // 농지 정보 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.selectField(widget.fieldId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('농지 상세 정보'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              if (controller.selectedField.value != null) {
                controller.setFormDataForEdit(controller.selectedField.value!);
                Get.to(() => FieldEditScreen(fieldId: widget.fieldId));
              }
            },
            tooltip: '수정',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmation(),
            tooltip: '삭제',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CustomLoading());
        }

        final field = controller.selectedField.value;
        if (field == null) {
          return const Center(
            child: Text(
              '농지 정보를 찾을 수 없습니다',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          );
        }

        return _buildFieldDetails(field, context);
      }),
      floatingActionButton: Obx(() {
        final field = controller.selectedField.value;
        if (field == null) return const SizedBox.shrink();

        return FloatingActionButton.extended(
          onPressed: () => _showStageChangeDialog(field),
          backgroundColor: AppTheme.primaryColor,
          icon: const Icon(Icons.edit_calendar),
          label: const Text('작업 단계 변경'),
        );
      }),
    );
  }

  Widget _buildFieldDetails(FieldModel field, BuildContext context) {
    // 반응형 레이아웃을 위한 화면 너비 체크
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWideScreen = screenWidth > 800;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isWideScreen ? 800 : double.infinity,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 농지 정보 카드
              _buildFieldInfoCard(field, isWideScreen),
              const SizedBox(height: 24),

              // 농가 정보 섹션
              _buildFarmInfoSection(isWideScreen),
              const SizedBox(height: 24),

              // 작업 단계 타임라인
              _buildStageTimelineSection(field),
              const SizedBox(height: 24),

              // 지도 섹션
              _buildMapSection(field),
              const SizedBox(height: 24),

              // 메모 섹션
              if (field.memo != null && field.memo!.isNotEmpty)
                _buildMemoSection(field),
            ],
          ),
        ),
      ),
    );
  }

  // 농지 정보 카드
  Widget _buildFieldInfoCard(FieldModel field, bool isWideScreen) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 작업 단계 배지
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStageBadge(field.currentStage.stage),
                Text(
                  '작업 상태: ${_getStagePercentage(field.currentStage.stage)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // 주소 정보
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on,
                  size: 20,
                  color: Colors.red.shade700,
                ),
                const SizedBox(width: 8),
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
                      ),
                      if (field.address.detail != null &&
                          field.address.detail!.isNotEmpty)
                        Text(
                          field.address.detail!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 면적 및 작물 정보
            isWideScreen
                ? Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          Icons.straighten,
                          '면적',
                          '${field.area.value} ${field.area.unit}',
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          Icons.grass,
                          '작물 종류',
                          field.cropType,
                        ),
                      ),
                      Expanded(
                        child: field.estimatedHarvestDate != null
                            ? _buildInfoItem(
                                Icons.calendar_today,
                                '수확 예정일',
                                _formatDate(field.estimatedHarvestDate!),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildInfoItem(
                        Icons.straighten,
                        '면적',
                        '${field.area.value} ${field.area.unit}',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoItem(
                        Icons.grass,
                        '작물 종류',
                        field.cropType,
                      ),
                      const SizedBox(height: 8),
                      if (field.estimatedHarvestDate != null)
                        _buildInfoItem(
                          Icons.calendar_today,
                          '수확 예정일',
                          _formatDate(field.estimatedHarvestDate!),
                        ),
                    ],
                  ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // 등록일 / 수정일
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '등록일: ${_formatDate(field.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '최종 수정일: ${_formatDate(field.updatedAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 농가 정보 섹션
  Widget _buildFarmInfoSection(bool isWideScreen) {
    final farm = controller.selectedFarm.value;
    if (farm == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '농가 정보',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // 농가 상세 정보 페이지로 이동
                    Get.toNamed('/farm/detail/${farm.id}');
                  },
                  icon: const Icon(
                    Icons.visibility,
                    size: 16,
                  ),
                  label: const Text('농가 상세 보기'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),

            // 농가 기본 정보
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: const Icon(
                    Icons.agriculture,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        farm.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone,
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            farm.phoneNumber,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: AppTheme.textSecondaryColor,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    farm.subdistrict,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.account_balance,
                                  size: 16,
                                  color: AppTheme.textSecondaryColor,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    farm.paymentGroup,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 작업 단계 타임라인 섹션
  Widget _buildStageTimelineSection(FieldModel field) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '작업 단계',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 16),

            // 작업 단계 타임라인
            _buildStageFLowTimeline(field.currentStage.stage),

            const SizedBox(height: 16),

            // 현재 단계 정보
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    _getStageColor(field.currentStage.stage).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      _getStageColor(field.currentStage.stage).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStageIcon(field.currentStage.stage),
                    color: _getStageColor(field.currentStage.stage),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '현재 단계: ${field.currentStage.stage}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getStageColor(field.currentStage.stage),
                          ),
                        ),
                        Text(
                          '마지막 업데이트: ${_formatDateTime(field.currentStage.updatedAt)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showStageChangeDialog(field),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('단계 변경'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // 지도 섹션
  Widget _buildMapSection(FieldModel field) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '위치 정보',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: 길찾기 기능 구현
                    Get.snackbar(
                      '준비 중',
                      '길찾기 기능은 다음 업데이트에서 제공됩니다.',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  icon: const Icon(Icons.directions, size: 16),
                  label: const Text('길찾기'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),

            // 미니 지도 (더미 구현)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  '지도 기능 구현 예정 (Google Maps API 연동)',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 메모 섹션
  Widget _buildMemoSection(FieldModel field) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '메모',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              field.memo ?? '',
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 작업 단계 타임라인 위젯
  Widget _buildStageFLowTimeline(String currentStage) {
    const stages = [
      '계약예정',
      '계약완료',
      '뽑기준비',
      '뽑기진행',
      '뽑기완료',
      '자르기준비',
      '자르기진행',
      '자르기완료',
      '담기준비',
      '담기진행',
      '담기완료',
      '운송예정',
      '운송진행',
      '운송완료'
    ];

    int currentIndex = stages.indexOf(currentStage);
    if (currentIndex < 0) currentIndex = 0;

    // 단계 그룹화
    const stageGroups = [
      {'name': '계약', 'color': Colors.blue, 'icon': Icons.description},
      {'name': '뽑기', 'color': Colors.orange, 'icon': Icons.grass},
      {'name': '자르기', 'color': Colors.amber, 'icon': Icons.content_cut},
      {'name': '담기', 'color': Colors.indigo, 'icon': Icons.shopping_basket},
      {'name': '운송', 'color': Colors.deepOrange, 'icon': Icons.local_shipping},
    ];

    // 현재 단계의 그룹 인덱스 계산
    int currentGroupIndex = 0;
    if (currentStage.contains('계약')) {
      currentGroupIndex = 0;
    } else if (currentStage.contains('뽑기')) {
      currentGroupIndex = 1;
    } else if (currentStage.contains('자르기')) {
      currentGroupIndex = 2;
    } else if (currentStage.contains('담기')) {
      currentGroupIndex = 3;
    } else if (currentStage.contains('운송')) {
      currentGroupIndex = 4;
    }

    return Container(
      height: 80,
      width: double.infinity,
      child: Row(
        children: List.generate(stageGroups.length, (index) {
          // 각 단계별 상태 결정
          bool isDone = index < currentGroupIndex;
          bool isCurrent = index == currentGroupIndex;
          bool isFuture = index > currentGroupIndex;

          Color color = (stageGroups[index]['color'] as Color);
          Color stageColor = isDone
              ? color
              : isCurrent
                  ? color
                  : Colors.grey.shade300;

          return Expanded(
            child: Row(
              children: [
                // 연결선 (첫 번째 단계에는 없음)
                if (index > 0)
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 3,
                      color: isDone ? color : Colors.grey.shade300,
                    ),
                  ),

                // 단계 아이콘
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: stageColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: stageColor,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          stageGroups[index]['icon'] as IconData,
                          color: stageColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stageGroups[index]['name'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCurrent ? color : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // 연결선 (마지막 단계에는 없음)
                if (index < stageGroups.length - 1)
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 3,
                      color: isDone ? color : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // 작업 단계 배지
  Widget _buildStageBadge(String stage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStageColor(stage).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getStageColor(stage).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStageIcon(stage),
            size: 16,
            color: _getStageColor(stage),
          ),
          const SizedBox(width: 6),
          Text(
            stage,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _getStageColor(stage),
            ),
          ),
        ],
      ),
    );
  }

  // 정보 항목 위젯
  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 단계별 색상
  Color _getStageColor(String stage) {
    if (stage.contains('계약')) {
      return Colors.blue;
    } else if (stage.contains('뽑기')) {
      return stage.contains('완료') ? Colors.green : Colors.orange;
    } else if (stage.contains('자르기')) {
      return stage.contains('완료') ? Colors.lightGreen : Colors.amber;
    } else if (stage.contains('담기')) {
      return stage.contains('완료') ? Colors.teal : Colors.indigo;
    } else if (stage.contains('운송')) {
      return stage.contains('완료') ? Colors.green.shade800 : Colors.deepOrange;
    } else {
      return Colors.grey;
    }
  }

  // 단계별 아이콘
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

  // 단계 진행도 퍼센트
  String _getStagePercentage(String stage) {
    const stages = [
      '계약예정',
      '계약완료',
      '뽑기준비',
      '뽑기진행',
      '뽑기완료',
      '자르기준비',
      '자르기진행',
      '자르기완료',
      '담기준비',
      '담기진행',
      '담기완료',
      '운송예정',
      '운송진행',
      '운송완료'
    ];

    int index = stages.indexOf(stage);
    if (index < 0) index = 0;

    int percentage = ((index + 1) / stages.length * 100).round();
    return '$percentage%';
  }

  // 날짜 포맷팅
  String _formatDate(DateTime date) {
    return DateFormat('yyyy년 MM월 dd일').format(date);
  }

  // 날짜 시간 포맷팅
  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  // 작업 단계 변경 다이얼로그
  void _showStageChangeDialog(FieldModel field) {
    const stages = [
      '계약예정',
      '계약완료',
      '뽑기준비',
      '뽑기진행',
      '뽑기완료',
      '자르기준비',
      '자르기진행',
      '자르기완료',
      '담기준비',
      '담기진행',
      '담기완료',
      '운송예정',
      '운송진행',
      '운송완료'
    ];

    String selectedStage = field.currentStage.stage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('작업 단계 변경'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('현재 단계:'),
                    const SizedBox(height: 8),
                    _buildStageBadge(field.currentStage.stage),
                    const SizedBox(height: 16),
                    const Text('변경할 단계:'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedStage,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: stages
                          .map((stage) => DropdownMenuItem(
                                value: stage,
                                child: Row(
                                  children: [
                                    Icon(
                                      _getStageIcon(stage),
                                      size: 16,
                                      color: _getStageColor(stage),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(stage),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedStage = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    if (selectedStage != field.currentStage.stage) {
                      await controller.updateStage(field.id, selectedStage);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text('변경'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 삭제 확인 다이얼로그
  void _showDeleteConfirmation() {
    final field = controller.selectedField.value;
    if (field == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('농지 삭제'),
          content: Text(
              '이 농지를 삭제하시겠습니까?\n\n주소: ${field.address.full}\n작물: ${field.cropType}\n\n이 작업은 되돌릴 수 없습니다.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                bool success = await controller.deleteField(field.id);
                if (success) {
                  Get.back(); // 목록 화면으로 이동
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
  }
}
