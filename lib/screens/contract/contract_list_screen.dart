// lib/screens/contract/contract_list_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/contract_controller.dart';
import '../../models/contract_model.dart';
import '../../widgets/contract/contract_card.dart';
import '../../widgets/contract/contract_search_bar.dart';
import '../../widgets/contract/contract_filter.dart';
import '../../config/theme.dart';
import '../../utils/custom_loading.dart';
import 'contract_add_screen.dart';
import 'contract_detail_screen.dart';

class ContractListScreen extends StatelessWidget {
  final String? farmId; // 특정 농가의 계약만 보기 위한 옵션

  const ContractListScreen({
    Key? key,
    this.farmId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ContractController controller = Get.find<ContractController>();
    final searchController = TextEditingController();

    // 특정 농가의 계약만 불러오기
    if (farmId != null) {
      controller.loadContractsByFarm(farmId!);
      controller.selectedFarmerId.value = farmId!;
    } else {
      controller.loadContracts();
    }

    // 납부 예정일 지난 계약 체크
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.checkDuePayments();
    });

    return Scaffold(
      appBar: AppBar(
        title: farmId != null ? const Text('농가 계약 관리') : const Text('계약 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Get.to(() => ContractAddScreen(initialFarmId: farmId));
            },
            tooltip: '계약 등록',
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색 바
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Obx(() => ContractSearchBar(
                  controller: searchController,
                  onChanged: (value) {
                    controller.searchQuery.value = value;
                  },
                  onClear: () {
                    searchController.clear();
                    controller.searchQuery.value = '';
                  },
                  filterType: controller.filterType.value,
                  onFilterChanged: (value) {
                    controller.filterType.value = value;
                  },
                  onFilterButtonPressed: () {
                    _showFilterModal(context, controller);
                  },
                )),
          ),

          // 필터 표시 영역
          Obx(() {
            bool hasFilters = controller.selectedContractType.isNotEmpty ||
                controller.selectedContractStatus.isNotEmpty ||
                (controller.selectedFarmerId.isNotEmpty && farmId == null);

            return hasFilters
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list,
                            size: 16, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getFilterDescription(controller),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            controller.selectedContractType.value = '';
                            controller.selectedContractStatus.value = '';
                            if (farmId == null) {
                              controller.selectedFarmerId.value = '';
                            }
                            controller.filterContracts();
                          },
                          child: const Text('필터 초기화'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink();
          }),

          // 계약 목록
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CustomLoading());
              }

              if (controller.filteredContracts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        controller.contracts.isEmpty
                            ? '등록된 계약이 없습니다'
                            : '검색 결과가 없습니다',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      controller.contracts.isEmpty
                          ? ElevatedButton.icon(
                              onPressed: () {
                                Get.to(() =>
                                    ContractAddScreen(initialFarmId: farmId));
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('계약 등록하기'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            )
                          : TextButton(
                              onPressed: () {
                                controller.selectedContractType.value = '';
                                controller.selectedContractStatus.value = '';
                                if (farmId == null) {
                                  controller.selectedFarmerId.value = '';
                                }
                                searchController.clear();
                                controller.searchQuery.value = '';
                                controller.filterContracts();
                              },
                              child: const Text('필터 초기화하기'),
                            ),
                    ],
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  // 화면 너비에 따라 반응형 레이아웃 적용
                  bool isWideScreen = constraints.maxWidth > 800;

                  if (isWideScreen) {
                    // 태블릿/데스크톱용 그리드 뷰
                    return GridView.builder(
                      padding: const EdgeInsets.all(16.0),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: (1 / 0.6),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: controller.filteredContracts.length,
                      itemBuilder: (context, index) {
                        ContractModel contract =
                            controller.filteredContracts[index];
                        return ContractCard(
                          contract: contract,
                          onTap: () {
                            Get.to(() =>
                                ContractDetailScreen(contractId: contract.id));
                          },
                          onEdit: () {
                            // 수정 페이지로 이동
                            // Get.to(() => ContractEditScreen(contractId: contract.id));
                            Get.snackbar(
                              '준비 중',
                              '계약 수정 기능은 다음 업데이트에서 제공될 예정입니다.',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          },
                          onDelete: () {
                            _showDeleteConfirmation(
                                context, controller, contract);
                          },
                        );
                      },
                    );
                  } else {
                    // 모바일용 리스트 뷰
                    return ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: controller.filteredContracts.length,
                      itemBuilder: (context, index) {
                        ContractModel contract =
                            controller.filteredContracts[index];
                        return ContractCard(
                          contract: contract,
                          onTap: () {
                            Get.to(() =>
                                ContractDetailScreen(contractId: contract.id));
                          },
                          onEdit: () {
                            // 수정 페이지로 이동
                            // Get.to(() => ContractEditScreen(contractId: contract.id));
                            Get.snackbar(
                              '준비 중',
                              '계약 수정 기능은 다음 업데이트에서 제공될 예정입니다.',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          },
                          onDelete: () {
                            _showDeleteConfirmation(
                                context, controller, contract);
                          },
                        );
                      },
                    );
                  }
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => ContractAddScreen(initialFarmId: farmId));
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  // 필터 모달 표시
  void _showFilterModal(BuildContext context, ContractController controller) {
    showDialog(
      context: context,
      builder: (context) {
        return Obx(() => ContractFilterModal(
              contractTypes: controller.contractTypes,
              contractStatuses: controller.contractStatuses,
              selectedContractType: controller.selectedContractType.value,
              selectedContractStatus: controller.selectedContractStatus.value,
              onContractTypeChanged: (value) {
                controller.selectedContractType.value = value ?? '';
              },
              onContractStatusChanged: (value) {
                controller.selectedContractStatus.value = value ?? '';
              },
              onReset: () {
                controller.selectedContractType.value = '';
                controller.selectedContractStatus.value = '';
              },
              onApply: () {
                controller.filterContracts();
              },
            ));
      },
    );
  }

  // 삭제 확인 다이얼로그
  void _showDeleteConfirmation(
    BuildContext context,
    ContractController controller,
    ContractModel contract,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('계약 삭제'),
          content: Text(
              '계약번호 ${contract.contractNumber}를 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없습니다.'),
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
                await controller.deleteContract(contract.id);
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

  // 적용된 필터 설명 생성
  String _getFilterDescription(ContractController controller) {
    List<String> descriptions = [];

    if (controller.selectedContractType.isNotEmpty) {
      descriptions.add('유형: ${controller.selectedContractType.value}');
    }

    if (controller.selectedContractStatus.isNotEmpty) {
      descriptions.add(
          '상태: ${controller.getStatusLabel(controller.selectedContractStatus.value)}');
    }

    // 농가ID가 있고, farmId가 null인 경우에만 표시 (특정 농가에 대한 화면이 아닌 경우)
    if (controller.selectedFarmerId.isNotEmpty && farmId == null) {
      // 농가 이름을 가져와서 표시하면 좋음
      descriptions.add('농가 ID: ${controller.selectedFarmerId.value}');
    }

    return descriptions.join(' • ');
  }
}
