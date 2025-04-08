import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/farm_controller.dart';
import '../../models/farm_model.dart';
import '../../config/theme.dart';
import '../../utils/custom_loading.dart';
import 'farm_edit_screen.dart';

class FarmDetailScreen extends StatefulWidget {
  final String farmId;

  const FarmDetailScreen({
    Key? key,
    required this.farmId,
  }) : super(key: key);

  @override
  State<FarmDetailScreen> createState() => _FarmDetailScreenState();
}

class _FarmDetailScreenState extends State<FarmDetailScreen> {
  final FarmController controller = Get.find<FarmController>();

  @override
  void initState() {
    super.initState();
    // 농가 정보 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.selectFarm(widget.farmId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('농가 상세 정보'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              if (controller.selectedFarm.value != null) {
                controller.setFormDataForEdit(controller.selectedFarm.value!);
                Get.to(() => FarmEditScreen(farmId: widget.farmId));
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

        final farm = controller.selectedFarm.value;
        if (farm == null) {
          return const Center(
            child: Text(
              '농가 정보를 찾을 수 없습니다',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          );
        }

        return _buildFarmDetails(farm, context);
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: 농지 등록 화면으로 이동
          Get.snackbar(
            '준비 중',
            '농지 등록 기능은 다음 업데이트에서 제공됩니다.',
            snackPosition: SnackPosition.BOTTOM,
          );
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('농지 추가'),
      ),
    );
  }

  Widget _buildFarmDetails(FarmModel farm, BuildContext context) {
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
              // 농가 정보 카드
              _buildFarmInfoCard(farm, isWideScreen),
              const SizedBox(height: 24),

              // 농지 목록 섹션
              _buildFieldsSection(farm),
              const SizedBox(height: 24),

              // 추가 정보 섹션
              _buildAdditionalInfoSection(farm, isWideScreen),
              const SizedBox(height: 24),

              // 메모 섹션
              if (farm.memo != null && farm.memo!.isNotEmpty)
                _buildMemoSection(farm),
            ],
          ),
        ),
      ),
    );
  }

  // 농가 정보 카드
  Widget _buildFarmInfoCard(FarmModel farm, bool isWideScreen) {
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 농가 아이콘
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.agriculture,
                    size: 32,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),

                // 기본 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        farm.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // 전화번호
                      GestureDetector(
                        onTap: () {
                          // TODO: 전화 걸기 기능
                        },
                        child: Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              farm.phoneNumber,
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),

                      // 면단위 및 결제소속
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
            const SizedBox(height: 16),

            // 주소 정보
            if (farm.address != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.home,
                        size: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              farm.address!.full,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                            if (farm.address!.detail != null &&
                                farm.address!.detail!.isNotEmpty)
                              Text(
                                farm.address!.detail!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.map,
                          color: AppTheme.primaryColor,
                        ),
                        onPressed: () {
                          // TODO: 지도 보기 기능
                          Get.snackbar(
                            '준비 중',
                            '지도 보기 기능은 다음 업데이트에서 제공됩니다.',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                        tooltip: '지도보기',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // 농지 목록 섹션
  Widget _buildFieldsSection(FarmModel farm) {
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
                  '농지 목록',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                _buildCountBadge(
                  farm.fields.length.toString(),
                  Colors.green.shade700,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),

            farm.fields.isEmpty
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(
                          Icons.terrain,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '등록된 농지가 없습니다',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            // TODO: 농지 등록 화면으로 이동
                            Get.snackbar(
                              '준비 중',
                              '농지 등록 기능은 다음 업데이트에서 제공됩니다.',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('농지 등록하기'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const Text('추후 구현 예정'), // 추후 농지 목록 구현
          ],
        ),
      ),
    );
  }

  // 추가 정보 섹션
  Widget _buildAdditionalInfoSection(FarmModel farm, bool isWideScreen) {
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
              '추가 정보',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),

            // 주민등록번호 및 계좌 정보
            isWideScreen
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildPersonalIdInfo(farm),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildBankInfo(farm),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPersonalIdInfo(farm),
                      const SizedBox(height: 16),
                      _buildBankInfo(farm),
                    ],
                  ),

            const SizedBox(height: 8),

            // 생성/업데이트 정보
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.calendar_today,
                    '등록일',
                    _formatDate(farm.createdAt),
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    Icons.update,
                    '최종 수정일',
                    _formatDate(farm.updatedAt),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 주민등록번호 정보
  Widget _buildPersonalIdInfo(FarmModel farm) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.badge,
          size: 20,
          color: AppTheme.textSecondaryColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '주민등록번호',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              Text(
                farm.personalId ?? '정보 없음',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 계좌 정보
  Widget _buildBankInfo(FarmModel farm) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.account_balance,
          size: 20,
          color: AppTheme.textSecondaryColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '계좌 정보',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              if (farm.bankInfo != null)
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.textPrimaryColor,
                    ),
                    children: [
                      TextSpan(
                        text: farm.bankInfo!.bankName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ' '),
                      TextSpan(text: farm.bankInfo!.accountNumber),
                      const TextSpan(text: '\n'),
                      TextSpan(
                        text: '예금주: ${farm.bankInfo!.accountHolder}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                )
              else
                const Text(
                  '계좌 정보 없음',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // 메모 섹션
  Widget _buildMemoSection(FarmModel farm) {
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
              farm.memo ?? '',
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

  // 정보 항목 위젯 (아이콘, 레이블, 값)
  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.textSecondaryColor,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 카운트 배지 위젯
  Widget _buildCountBadge(String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        count,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // 날짜 포맷팅
  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  // 삭제 확인 다이얼로그
  void _showDeleteConfirmation() {
    final farm = controller.selectedFarm.value;
    if (farm == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('농가 삭제'),
          content: Text('${farm.name} 농가를 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없습니다.'),
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
                bool success = await controller.deleteFarm(farm.id);
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
