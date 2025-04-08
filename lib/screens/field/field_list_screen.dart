import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/field_controller.dart';
import '../../controllers/farm_controller.dart';
import '../../models/field_model.dart';
import '../../models/farm_model.dart';
import '../../widgets/field/field_card.dart';
import '../../widgets/field/field_search_bar.dart';
import '../../widgets/field/field_filter.dart';
import '../../widgets/field/field_map.dart';
import '../../config/theme.dart';
import '../../utils/custom_loading.dart';
import 'field_add_screen.dart';
import 'field_detail_screen.dart';

class FieldListScreen extends StatefulWidget {
  final String? farmId; // 특정 농가의 농지만 보기 위한 옵션

  const FieldListScreen({
    Key? key,
    this.farmId,
  }) : super(key: key);

  @override
  State<FieldListScreen> createState() => _FieldListScreenState();
}

class _FieldListScreenState extends State<FieldListScreen> {
  final FieldController controller = Get.find<FieldController>();
  final FarmController farmController = Get.find<FarmController>();
  final searchController = TextEditingController();

  // 지도/목록 뷰 상태
  bool _isMapView = false;

  @override
  void initState() {
    super.initState();

    // 특정 농가의 농지를 보기 위한
    if (widget.farmId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await farmController.selectFarm(widget.farmId!);
        if (farmController.selectedFarm.value != null) {
          controller.selectedFarm.value = farmController.selectedFarm.value;
          controller.loadFieldsByFarm(widget.farmId!);
        }
      });
    } else {
      controller.loadFields();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.farmId != null
            ? Obx(() => Text(controller.selectedFarm.value != null
                ? '${controller.selectedFarm.value!.name}의 농지'
                : '농지 관리'))
            : const Text('농지 관리'),
        actions: [
          // 지도/목록 뷰 전환 버튼
          IconButton(
            icon: Icon(_isMapView ? Icons.list : Icons.map),
            onPressed: () {
              setState(() {
                _isMapView = !_isMapView;
              });
            },
            tooltip: _isMapView ? '목록으로 보기' : '지도로 보기',
          ),
          // 추가 버튼
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Get.to(() => FieldAddScreen(
                    initialFarmId: widget.farmId,
                  ));
            },
            tooltip: '농지 등록',
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색 바
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Obx(() => FieldSearchBar(
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
                    _showFilterModal(context);
                  },
                )),
          ),

          // 필터 표시 영역
          Obx(() {
            bool hasFilters = controller.selectedCropType.isNotEmpty ||
                controller.selectedStage.isNotEmpty ||
                controller.selectedFarm.value != null;

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
                            _getFilterDescription(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            controller.selectedCropType.value = '';
                            controller.selectedStage.value = '';
                            if (widget.farmId == null) {
                              controller.selectedFarm.value = null;
                            }
                            controller.filterFields();
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

          // 농지 목록 또는 지도
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CustomLoading());
              }

              if (controller.filteredFields.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.terrain,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        controller.fields.isEmpty
                            ? '등록된 농지가 없습니다'
                            : '검색 결과가 없습니다',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      controller.fields.isEmpty
                          ? ElevatedButton.icon(
                              onPressed: () {
                                Get.to(() => FieldAddScreen(
                                      initialFarmId: widget.farmId,
                                    ));
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('농지 등록하기'),
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
                                controller.selectedCropType.value = '';
                                controller.selectedStage.value = '';
                                if (widget.farmId == null) {
                                  controller.selectedFarm.value = null;
                                }
                                controller.filterFields();
                              },
                              child: const Text('필터 초기화하기'),
                            ),
                    ],
                  ),
                );
              }

              // 지도 뷰인 경우
              if (_isMapView) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FieldMapWidget(
                    fields: controller.filteredFields,
                    onFieldSelected: (field) {
                      Get.to(() => FieldDetailScreen(fieldId: field.id));
                    },
                  ),
                );
              }

              // 목록 뷰인 경우
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
                        childAspectRatio: (1 / 0.5),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: controller.filteredFields.length,
                      itemBuilder: (context, index) {
                        FieldModel field = controller.filteredFields[index];
                        return _buildFieldCard(field);
                      },
                    );
                  } else {
                    // 모바일용 리스트 뷰
                    return ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: controller.filteredFields.length,
                      itemBuilder: (context, index) {
                        FieldModel field = controller.filteredFields[index];
                        return _buildFieldCard(field);
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
          Get.to(() => FieldAddScreen(
                initialFarmId: widget.farmId,
              ));
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  // 농지 카드 위젯 생성
  Widget _buildFieldCard(FieldModel field) {
    // 농가 이름 조회
    String? farmName;
    if (controller.farms.isNotEmpty) {
      final farm = controller.farms
          .firstWhereOrNull((farm) => farm.id == field.farmerId);
      if (farm != null) {
        farmName = farm.name;
      }
    }

    return FieldCard(
      field: field,
      farmName: farmName,
      onTap: () {
        Get.to(() => FieldDetailScreen(fieldId: field.id));
      },
      onEdit: () {
        // 수정 페이지로 이동
        controller.setFormDataForEdit(field);
        Get.toNamed('/field/edit/${field.id}');
      },
      onDelete: () {
        _showDeleteConfirmation(controller, field);
      },
    );
  }

  // 필터 모달 표시
  void _showFilterModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Obx(() => FieldFilterModal(
              farms: controller.farms,
              cropTypes: controller.cropTypes,
              stages: controller.stages,
              selectedCropType: controller.selectedCropType.value,
              selectedStage: controller.selectedStage.value,
              selectedFarm: controller.selectedFarm.value,
              onCropTypeChanged: (value) {
                controller.selectedCropType.value = value ?? '';
              },
              onStageChanged: (value) {
                controller.selectedStage.value = value ?? '';
              },
              onFarmChanged: (value) {
                controller.selectedFarm.value = value;
              },
              onReset: () {
                controller.selectedCropType.value = '';
                controller.selectedStage.value = '';
                if (widget.farmId == null) {
                  controller.selectedFarm.value = null;
                }
              },
              onApply: () {
                controller.filterFields();
              },
            ));
      },
    );
  }

  // 삭제 확인 다이얼로그
  void _showDeleteConfirmation(
    FieldController controller,
    FieldModel field,
  ) {
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
                await controller.deleteField(field.id);
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
  String _getFilterDescription() {
    List<String> descriptions = [];

    if (controller.selectedFarm.value != null) {
      descriptions.add('농가: ${controller.selectedFarm.value!.name}');
    }

    if (controller.selectedCropType.isNotEmpty) {
      descriptions.add('작물: ${controller.selectedCropType.value}');
    }

    if (controller.selectedStage.isNotEmpty) {
      descriptions.add('단계: ${controller.selectedStage.value}');
    }

    return descriptions.join(' • ');
  }
}
