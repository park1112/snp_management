import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/farm_controller.dart';
import '../../models/farm_model.dart';
import '../../widgets/farm/farm_card.dart';
import '../../widgets/farm/farm_search_bar.dart';
import '../../widgets/farm/farm_filter.dart';
import '../../config/theme.dart';
import '../../utils/custom_loading.dart';
import 'farm_add_screen.dart';
import 'farm_detail_screen.dart';

class FarmListScreen extends StatelessWidget {
  const FarmListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FarmController controller = Get.put(FarmController());
    final searchController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('농가 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Get.to(() => const FarmAddScreen());
            },
            tooltip: '농가 등록',
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색 바
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Obx(() => FarmSearchBar(
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
            bool hasFilters = controller.selectedSubdistrict.isNotEmpty ||
                controller.selectedPaymentGroup.isNotEmpty;

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
                            controller.selectedSubdistrict.value = '';
                            controller.selectedPaymentGroup.value = '';
                            controller.filterFarms();
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

          // 농가 목록
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CustomLoading());
              }

              if (controller.filteredFarms.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        controller.farms.isEmpty
                            ? '등록된 농가가 없습니다'
                            : '검색 결과가 없습니다',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      controller.farms.isEmpty
                          ? ElevatedButton.icon(
                              onPressed: () {
                                Get.to(() => const FarmAddScreen());
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('농가 등록하기'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            )
                          : TextButton(
                              onPressed: () {
                                controller.resetForm();
                                searchController.clear();
                                controller.searchQuery.value = '';
                                controller.selectedSubdistrict.value = '';
                                controller.selectedPaymentGroup.value = '';
                                controller.filterFarms();
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
                        childAspectRatio: (1 / 0.4),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: controller.filteredFarms.length,
                      itemBuilder: (context, index) {
                        FarmModel farm = controller.filteredFarms[index];
                        return FarmCard(
                          farm: farm,
                          onTap: () {
                            Get.to(() => FarmDetailScreen(farmId: farm.id));
                          },
                          onEdit: () {
                            // 수정 페이지로 이동
                            controller.setFormDataForEdit(farm);
                            Get.toNamed('/farm/edit/${farm.id}');
                          },
                          onDelete: () {
                            _showDeleteConfirmation(context, controller, farm);
                          },
                        );
                      },
                    );
                  } else {
                    // 모바일용 리스트 뷰
                    return ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: controller.filteredFarms.length,
                      itemBuilder: (context, index) {
                        FarmModel farm = controller.filteredFarms[index];
                        return FarmCard(
                          farm: farm,
                          onTap: () {
                            Get.to(() => FarmDetailScreen(farmId: farm.id));
                          },
                          onEdit: () {
                            // 수정 페이지로 이동
                            controller.setFormDataForEdit(farm);
                            Get.toNamed('/farm/edit/${farm.id}');
                          },
                          onDelete: () {
                            _showDeleteConfirmation(context, controller, farm);
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
          Get.to(() => const FarmAddScreen());
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  // 필터 모달 표시
  void _showFilterModal(BuildContext context, FarmController controller) {
    showDialog(
      context: context,
      builder: (context) {
        return Obx(() => FarmFilterModal(
              subdistricts: controller.subdistricts,
              paymentGroups: controller.paymentGroups,
              selectedSubdistrict: controller.selectedSubdistrict.value,
              selectedPaymentGroup: controller.selectedPaymentGroup.value,
              onSubdistrictChanged: (value) {
                controller.selectedSubdistrict.value = value ?? '';
              },
              onPaymentGroupChanged: (value) {
                controller.selectedPaymentGroup.value = value ?? '';
              },
              onReset: () {
                controller.selectedSubdistrict.value = '';
                controller.selectedPaymentGroup.value = '';
              },
              onApply: () {
                controller.filterFarms();
              },
            ));
      },
    );
  }

  // 삭제 확인 다이얼로그
  void _showDeleteConfirmation(
    BuildContext context,
    FarmController controller,
    FarmModel farm,
  ) {
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
                await controller.deleteFarm(farm.id);
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
  String _getFilterDescription(FarmController controller) {
    List<String> descriptions = [];

    if (controller.selectedSubdistrict.isNotEmpty) {
      descriptions.add('면단위: ${controller.selectedSubdistrict.value}');
    }

    if (controller.selectedPaymentGroup.isNotEmpty) {
      descriptions.add('결제소속: ${controller.selectedPaymentGroup.value}');
    }

    return descriptions.join(' • ');
  }
}
