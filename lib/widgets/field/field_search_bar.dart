import 'package:flutter/material.dart';
import '../../config/theme.dart';

class FieldSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final VoidCallback onClear;
  final String filterType;
  final Function(String) onFilterChanged;
  final VoidCallback? onFilterButtonPressed;

  const FieldSearchBar({
    Key? key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.filterType,
    required this.onFilterChanged,
    this.onFilterButtonPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 검색 아이콘
          Icon(
            Icons.search,
            color: AppTheme.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 8),

          // 검색 입력 필드
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: _getHintText(),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                isDense: true,
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 16,
                ),
              ),
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),

          // 지우기 버튼
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.grey.shade700,
                  size: 16,
                ),
              ),
            ),

          const SizedBox(width: 8),

          // 필터 드롭다운
          _buildFilterDropdown(),

          // 필터 버튼 (고급 필터링용)
          if (onFilterButtonPressed != null)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: onFilterButtonPressed,
              color: AppTheme.primaryColor,
              tooltip: '상세 필터',
            ),
        ],
      ),
    );
  }

  // 힌트 텍스트 설정
  String _getHintText() {
    switch (filterType) {
      case 'farm':
        return '농가별 검색';
      case 'cropType':
        return '작물 종류로 검색';
      case 'stage':
        return '작업 단계로 검색';
      default:
        return '주소로 검색';
    }
  }

  // 필터 드롭다운 구현
  Widget _buildFilterDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: filterType,
          icon: const Icon(Icons.arrow_drop_down, size: 20),
          iconEnabledColor: AppTheme.primaryColor,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w500,
          ),
          isDense: true,
          items: [
            DropdownMenuItem(
              value: 'all',
              child: const Text('주소'),
            ),
            DropdownMenuItem(
              value: 'farm',
              child: const Text('농가'),
            ),
            DropdownMenuItem(
              value: 'cropType',
              child: const Text('작물'),
            ),
            DropdownMenuItem(
              value: 'stage',
              child: const Text('단계'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              onFilterChanged(value);
            }
          },
        ),
      ),
    );
  }
}
