// lib/widgets/contract/contract_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/contract_model.dart';
import '../../config/theme.dart';

class ContractCard extends StatelessWidget {
  final ContractModel contract;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isSelected;

  const ContractCard({
    Key? key,
    required this.contract,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contract.contractNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        Text(
                          '계약일: ${DateFormat('yyyy-MM-dd').format(contract.contractDate)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
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
              // lib/widgets/contract/contract_card.dart (계속)
              const SizedBox(height: 8),

              // 계약 상태 배지
              _buildStatusBadge(contract.contractStatus),

              const SizedBox(height: 12),

              // 금액 정보
              Row(
                children: [
                  Icon(
                    Icons.monetization_on_outlined,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatCurrency(contract.totalAmount)}원',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // 필드 연결 정보
              Row(
                children: [
                  Icon(
                    Icons.terrain,
                    size: 16,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '농지 ${contract.fieldIds.length}개',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // 납부 정보
              _buildNextPaymentInfo(contract),
            ],
          ),
        ),
      ),
    );
  }

  // 계약 상태 배지
  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    String statusText;

    switch (status) {
      case 'pending':
        badgeColor = Colors.blue;
        statusText = '계약예정';
        break;
      case 'active':
        badgeColor = Colors.green;
        statusText = '계약중';
        break;
      case 'completed':
        badgeColor = Colors.teal;
        statusText = '완료';
        break;
      case 'cancelled':
        badgeColor = Colors.red;
        statusText = '취소됨';
        break;
      default:
        badgeColor = Colors.grey;
        statusText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(status),
            size: 14,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  // 다음 납부 정보
  Widget _buildNextPaymentInfo(ContractModel contract) {
    // 납부 예정이 있는지 확인
    if (contract.downPayment.status == 'pending') {
      return _buildPaymentInfoRow(
          '계약금', contract.downPayment.amount, contract.downPayment.dueDate);
    }

    // 중도금 확인
    for (var payment in contract.intermediatePayments) {
      if (payment.status == 'pending') {
        return _buildPaymentInfoRow('중도금 ${payment.installmentNumber}회차',
            payment.amount, payment.dueDate);
      }
    }

    // 잔금 확인
    if (contract.finalPayment.status == 'pending') {
      return _buildPaymentInfoRow(
          '잔금', contract.finalPayment.amount, contract.finalPayment.dueDate);
    }

    // 모든 납부가 완료된 경우
    return Row(
      children: [
        Icon(
          Icons.check_circle,
          size: 16,
          color: Colors.green,
        ),
        const SizedBox(width: 4),
        Text(
          '모든 납부 완료',
          style: TextStyle(
            fontSize: 14,
            color: Colors.green,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // 납부 정보 행
  Widget _buildPaymentInfoRow(String label, double amount, DateTime? dueDate) {
    final now = DateTime.now();
    bool isOverdue = dueDate != null && dueDate.isBefore(now);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 납부 종류
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isOverdue ? Colors.red : Colors.grey.shade700,
          ),
        ),

        // 금액
        Text(
          '${_formatCurrency(amount)}원',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isOverdue ? Colors.red : AppTheme.textPrimaryColor,
          ),
        ),

        // 예정일
        if (dueDate != null)
          Row(
            children: [
              Icon(
                isOverdue ? Icons.warning : Icons.calendar_today,
                size: 14,
                color: isOverdue ? Colors.red : Colors.grey.shade700,
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('MM/dd').format(dueDate),
                style: TextStyle(
                  fontSize: 12,
                  color: isOverdue ? Colors.red : Colors.grey.shade700,
                ),
              ),
            ],
          ),
      ],
    );
  }

  // 상태 아이콘 반환
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'active':
        return Icons.assignment;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  // 금액 포맷
  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'ko_KR');
    return formatter.format(amount);
  }
}
