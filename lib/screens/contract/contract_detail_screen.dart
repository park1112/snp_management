// lib/screens/contract/contract_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/contract_controller.dart';
import '../../controllers/farm_controller.dart';
import '../../controllers/field_controller.dart';
import '../../models/contract_model.dart';
import '../../models/farm_model.dart';
import '../../config/theme.dart';
import '../../utils/custom_loading.dart';

class ContractDetailScreen extends StatefulWidget {
  final String contractId;

  const ContractDetailScreen({
    Key? key,
    required this.contractId,
  }) : super(key: key);

  @override
  State<ContractDetailScreen> createState() => _ContractDetailScreenState();
}

class _ContractDetailScreenState extends State<ContractDetailScreen> {
  final ContractController controller = Get.find<ContractController>();
  final FarmController farmController = Get.find<FarmController>();
  final FieldController fieldController = Get.find<FieldController>();

  @override
  void initState() {
    super.initState();
    // 계약 정보 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.selectContract(widget.contractId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('계약 상세 정보'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'status') {
                _showStatusChangeDialog();
              } else if (value == 'edit') {
                // TODO: 계약 수정 화면 구현
                Get.snackbar(
                  '준비 중',
                  '계약 수정 기능은 다음 업데이트에서 제공될 예정입니다.',
                  snackPosition: SnackPosition.BOTTOM,
                );
              } else if (value == 'delete') {
                _showDeleteConfirmation();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'status',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: AppTheme.primaryColor),
                    SizedBox(width: 8),
                    Text('상태 변경'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: AppTheme.primaryColor),
                    SizedBox(width: 8),
                    Text('수정'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('삭제', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CustomLoading());
        }

        final contract = controller.selectedContract.value;
        if (contract == null) {
          return const Center(
            child: Text(
              '계약 정보를 찾을 수 없습니다',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          );
        }

        return _buildContractDetails(contract, context);
      }),
    );
  }

  Widget _buildContractDetails(ContractModel contract, BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 계약 개요 카드
          _buildContractSummaryCard(contract),
          const SizedBox(height: 16),

          // 납부 일정 카드
          _buildPaymentScheduleCard(contract),
          const SizedBox(height: 16),

          // 농지 정보 카드
          _buildFieldsInfoCard(contract),
          const SizedBox(height: 16),

          // 계약 세부 정보 카드
          _buildContractDetailsCard(contract),
          const SizedBox(height: 16),

          // 첨부 파일 카드 (있는 경우)
          if (contract.attachments.isNotEmpty)
            _buildAttachmentsCard(contract),
            
          // 메모 카드 (있는 경우)
          if (contract.memo != null && contract.memo!.isNotEmpty)
            _buildMemoCard(contract),
            
          const SizedBox(height: 50), // 하단 여백
        ],
      ),
    );
  }

  // 계약 개요 카드
  Widget _buildContractSummaryCard(ContractModel contract) {
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
            // 계약 번호 및 상태
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '계약 번호',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      Text(
                        contract.contractNumber,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(contract.contractStatus),
              ],
            ),
            const Divider(height: 24),

            // 농가 정보
            FutureBuilder<FarmModel?>(
              future: farmController.getFarm(contract.farmerId),
              builder: (context, snapshot) {
                String farmName = '로딩 중...';
                if (snapshot.hasData && snapshot.data != null) {
                  farmName = snapshot.data!.name;
                } else if (snapshot.connectionState == ConnectionState.done) {
                  farmName = '알 수 없음';
                }

                return Row(
                  children: [
                    const Icon(
                      Icons.agriculture,
                      size: 20,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '농가',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          Text(
                            farmName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        // 농가 상세 페이지로 이동
                        Get.toNamed('/farm/detail/${contract.farmerId}');
                      },
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('상세'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),

            // 계약 정보 행
            _buildInfoRow(
              '계약 유형',
              contract.contractType,
              Icons.description,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              '계약일',
              DateFormat('yyyy년 MM월 dd일').format(contract.contractDate),
              Icons.calendar_today,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              '총 계약금액',
              '${_formatCurrency(contract.totalAmount)}원',
              Icons.monetization_on,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              '등록일',
              DateFormat('yyyy-MM-dd HH:mm').format(contract.createdAt),
              Icons.access_time,
            ),
          ],
        ),
      ),
    );
  }

  // 납부 일정 카드
  Widget _buildPaymentScheduleCard(ContractModel contract) {
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
                  '납부 일정',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Text(
                  '잔여 납부액: ${_calculateRemainingPayment(contract)}원',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,// lib/screens/contract/contract_detail_screen.dart (계속)
                 ),
               ),
             ],
           ),
           const SizedBox(height: 16),

           // 계약금 정보
           _buildPaymentItem(
             title: '계약금',
             payment: contract.downPayment,
             onPayClick: () {
               _showPaymentDialog(contract, 'downPayment', 0);
             },
           ),
           
           // 중도금 정보 (있는 경우)
           if (contract.intermediatePayments.isNotEmpty) ...[
             const Divider(height: 24),
             for (int i = 0; i < contract.intermediatePayments.length; i++)
               Column(
                 children: [
                   _buildPaymentItem(
                     title: '중도금 ${contract.intermediatePayments[i].installmentNumber}회차',
                     payment: contract.intermediatePayments[i],
                     onPayClick: () {
                       _showPaymentDialog(
                         contract, 
                         'intermediate', 
                         contract.intermediatePayments[i].installmentNumber
                       );
                     },
                   ),
                   if (i < contract.intermediatePayments.length - 1)
                     const Divider(height: 24),
                 ],
               ),
           ],

           // 잔금 정보
           const Divider(height: 24),
           _buildPaymentItem(
             title: '잔금',
             payment: contract.finalPayment,
             onPayClick: () {
               _showPaymentDialog(contract, 'finalPayment', 0);
             },
           ),
         ],
       ),
     ),
   );
 }

 // 납부 항목 위젯
 Widget _buildPaymentItem({
   required String title,
   required PaymentInfo payment,
   required VoidCallback onPayClick,
 }) {
   final isPaid = payment.status == 'paid';
   final isOverdue = !isPaid && payment.dueDate != null && 
                    payment.dueDate!.isBefore(DateTime.now());
   
   return Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
       Row(
         mainAxisAlignment: MainAxisAlignment.spaceBetween,
         children: [
           Text(
             title,
             style: const TextStyle(
               fontSize: 16,
               fontWeight: FontWeight.bold,
               color: AppTheme.textPrimaryColor,
             ),
           ),
           _buildPaymentStatusBadge(payment.status, isOverdue),
         ],
       ),
       const SizedBox(height: 8),
       Row(
         children: [
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 _buildInfoRow(
                   '금액',
                   '${_formatCurrency(payment.amount)}원',
                   Icons.monetization_on_outlined,
                   textColor: isPaid ? Colors.grey.shade700 : AppTheme.textPrimaryColor,
                 ),
                 const SizedBox(height: 4),
                 if (payment.dueDate != null)
                   _buildInfoRow(
                     '예정일',
                     DateFormat('yyyy년 MM월 dd일').format(payment.dueDate!),
                     Icons.event,
                     textColor: isOverdue ? Colors.red : (isPaid ? Colors.grey.shade700 : AppTheme.textPrimaryColor),
                   ),
                 if (isPaid && payment.paidDate != null) ...[
                   const SizedBox(height: 4),
                   _buildInfoRow(
                     '납부일',
                     DateFormat('yyyy년 MM월 dd일').format(payment.paidDate!),
                     Icons.check_circle,
                     textColor: Colors.green,
                   ),
                 ],
                 if (isPaid && payment.paidAmount != null) ...[
                   const SizedBox(height: 4),
                   _buildInfoRow(
                     '납부액',
                     '${_formatCurrency(payment.paidAmount!)}원',
                     Icons.payments,
                     textColor: Colors.green,
                   ),
                 ],
               ],
             ),
           ),
           if (!isPaid)
             ElevatedButton.icon(
               onPressed: onPayClick,
               icon: const Icon(Icons.payment, size: 16),
               label: const Text('납부처리'),
               style: ElevatedButton.styleFrom(
                 backgroundColor: isOverdue ? Colors.red : AppTheme.primaryColor,
                 foregroundColor: Colors.white,
                 padding: const EdgeInsets.symmetric(
                   horizontal: 12,
                   vertical: 8,
                 ),
                 shape: RoundedRectangleBorder(
                   borderRadius: BorderRadius.circular(8),
                 ),
               ),
             ),
           if (isPaid && payment.receiptImageUrl != null)
             IconButton(
               onPressed: () {
                 // 영수증 이미지 보기
                 _showReceiptImage(payment.receiptImageUrl!);
               },
               tooltip: '영수증 보기',
               icon: const Icon(Icons.receipt, 
                 color: AppTheme.primaryColor),
             ),
         ],
       ),
     ],
   );
 }

 // 농지 정보 카드
 Widget _buildFieldsInfoCard(ContractModel contract) {
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
               Text(
                 '계약 농지 (${contract.fieldIds.length}개)',
                 style: const TextStyle(
                   fontSize: 18,
                   fontWeight: FontWeight.bold,
                   color: AppTheme.textPrimaryColor,
                 ),
               ),
               if (contract.fieldIds.isNotEmpty)
                 TextButton.icon(
                   onPressed: () {
                     // 농지 목록 페이지로 이동
                     Get.toNamed('/field/list/farm/${contract.farmerId}');
                   },
                   icon: const Icon(Icons.list, size: 16),
                   label: const Text('전체보기'),
                   style: TextButton.styleFrom(
                     padding: EdgeInsets.zero,
                     minimumSize: const Size(0, 0),
                     tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                     foregroundColor: AppTheme.primaryColor,
                   ),
                 ),
             ],
           ),
           const SizedBox(height: 16),

           if (contract.fieldIds.isEmpty)
             Center(
               child: Text(
                 '연결된 농지가 없습니다',
                 style: TextStyle(
                   fontSize: 16,
                   color: Colors.grey.shade600,
                   fontStyle: FontStyle.italic,
                 ),
               ),
             )
           else
             ListView.separated(
               shrinkWrap: true,
               physics: const NeverScrollableScrollPhysics(),
               itemCount: contract.fieldIds.length,
               separatorBuilder: (context, index) => const Divider(height: 16),
               itemBuilder: (context, index) {
                 return FutureBuilder(
                   future: fieldController.getField(contract.fieldIds[index]),
                   builder: (context, snapshot) {
                     if (snapshot.connectionState == ConnectionState.waiting) {
                       return const ListTile(
                         title: Text('로딩 중...'),
                         leading: SizedBox(
                           width: 24,
                           height: 24,
                           child: CircularProgressIndicator(strokeWidth: 2),
                         ),
                       );
                     }
                     
                     if (!snapshot.hasData || snapshot.data == null) {
                       return ListTile(
                         title: Text(
                           '농지 정보를 찾을 수 없습니다',
                           style: TextStyle(color: Colors.grey.shade600),
                         ),
                         leading: Icon(Icons.error_outline, color: Colors.red.shade300),
                       );
                     }
                     
                     final field = snapshot.data!;
                     return ListTile(
                       title: Text(
                         field.address.full,
                         style: const TextStyle(
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                       subtitle: Text(
                         '${field.cropType} | ${field.area.value} ${field.area.unit}',
                       ),
                       leading: Container(
                         width: 40,
                         height: 40,
                         decoration: BoxDecoration(
                           color: Colors.green.shade100,
                           borderRadius: BorderRadius.circular(8),
                         ),
                         child: const Icon(
                           Icons.terrain,
                           color: Colors.green,
                         ),
                       ),
                       trailing: IconButton(
                         icon: const Icon(Icons.arrow_forward_ios, size: 16),
                         onPressed: () {
                           // 농지 상세 페이지로 이동
                           Get.toNamed('/field/detail/${field.id}');
                         },
                       ),
                       contentPadding: EdgeInsets.zero,
                       onTap: () {
                         // 농지 상세 페이지로 이동
                         Get.toNamed('/field/detail/${field.id}');
                       },
                     );
                   },
                 );
               },
             ),
         ],
       ),
     ),
   );
 }

 // 계약 세부 정보 카드
 Widget _buildContractDetailsCard(ContractModel contract) {
   final details = contract.contractDetails;
   
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
             '계약 세부 내용',
             style: TextStyle(
               fontSize: 18,
               fontWeight: FontWeight.bold,
               color: AppTheme.textPrimaryColor,
             ),
           ),
           const SizedBox(height: 16),

           // 단가 정보
           _buildInfoRow(
             '단가',
             '${_formatCurrency(details.pricePerUnit)}원/${details.unitType}',
             Icons.monetization_on_outlined,
           ),
           const SizedBox(height: 8),
           
           // 예상 수확량
           _buildInfoRow(
             '예상 수확량',
             '${details.estimatedQuantity} ${details.unitType}',
             Icons.agriculture_outlined,
           ),
           const SizedBox(height: 8),
           
           // 수확 기간
           if (details.harvestPeriodStart != null && details.harvestPeriodEnd != null) ...[
             _buildInfoRow(
               '수확 기간',
               '${DateFormat('yyyy.MM.dd').format(details.harvestPeriodStart!)} ~ '
               '${DateFormat('yyyy.MM.dd').format(details.harvestPeriodEnd!)}',
               Icons.date_range,
             ),
             const SizedBox(height: 8),
           ],
           
           // 특별 계약 조건
           if (details.specialTerms != null && details.specialTerms!.isNotEmpty) ...[
             const Divider(height: 24),
             const Text(
               '특별 계약 조건',
               style: TextStyle(
                 fontSize: 16,
                 fontWeight: FontWeight.bold,
                 color: AppTheme.textPrimaryColor,
               ),
             ),
             const SizedBox(height: 8),
             Text(
               details.specialTerms!,
               style: const TextStyle(
                 fontSize: 14,
                 color: AppTheme.textSecondaryColor,
               ),
             ),
             const SizedBox(height: 8),
           ],
           
           // 품질 기준
           if (details.qualityStandards != null && details.qualityStandards!.isNotEmpty) ...[
             const Divider(height: 24),
             const Text(
               '품질 기준',
               style: TextStyle(
                 fontSize: 16,
                 fontWeight: FontWeight.bold,
                 color: AppTheme.textPrimaryColor,
               ),
             ),
             const SizedBox(height: 8),
             Text(
               details.qualityStandards!,
               style: const TextStyle(
                 fontSize: 14,
                 color: AppTheme.textSecondaryColor,
               ),
             ),
           ],
         ],
       ),
     ),
   );
 }

 // 첨부 파일 카드
 Widget _buildAttachmentsCard(ContractModel contract) {
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
           Text(
             '첨부 파일 (${contract.attachments.length})',
             style: const TextStyle(
               fontSize: 18,
               fontWeight: FontWeight.bold,
               color: AppTheme.textPrimaryColor,
             ),
           ),
           const SizedBox(height: 16),
           
           ListView.separated(
             shrinkWrap: true,
             physics: const NeverScrollableScrollPhysics(),
             itemCount: contract.attachments.length,
             separatorBuilder: (context, index) => const Divider(height: 8),
             itemBuilder: (context, index) {
               final attachment = contract.attachments[index];
               IconData icon;
               
               if (attachment.type.contains('image')) {
                 icon = Icons.image;
               } else if (attachment.type.contains('pdf')) {
                 icon = Icons.picture_as_pdf;
               } else if (attachment.type.contains('word')) {
                 icon = Icons.description;
               } else if (attachment.type.contains('excel') || 
                          attachment.type.contains('spreadsheet')) {
                 icon = Icons.table_chart;
               } else {
                 icon = Icons.attach_file;
               }
               
               return ListTile(
                 leading: Icon(icon, color: AppTheme.primaryColor),
                 title: Text(attachment.name),
                 subtitle: Text(
                   DateFormat('yyyy-MM-dd HH:mm').format(attachment.uploadedAt),
                   style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                 ),
                 trailing: IconButton(
                   icon: const Icon(Icons.download),
                   onPressed: () {
                     // 첨부 파일 다운로드/보기
                     _viewAttachment(attachment.url, attachment.type);
                   },
                 ),
                 contentPadding: EdgeInsets.zero,
                 onTap: () {
                   // 첨부 파일 보기
                   _viewAttachment(attachment.url, attachment.type);
                 },
               );
             },
           ),
         ],
       ),
     ),
   );
 }

 // 메모 카드
 Widget _buildMemoCard(ContractModel contract) {
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
           const SizedBox(height: 16),
           Text(
             contract.memo ?? '',
             style: const TextStyle(
               fontSize: 16,
               color: AppTheme.textSecondaryColor,
             ),
           ),
         ],
       ),
     ),
   );
 }

 // 상태 배지
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
     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
     decoration: BoxDecoration(
       color: badgeColor.withOpacity(0.1),
       borderRadius: BorderRadius.circular(16),
       border: Border.all(color: badgeColor.withOpacity(0.3)),
     ),
     child: Text(
       statusText,
       style: TextStyle(
         fontSize: 14,
         fontWeight: FontWeight.bold,
         color: badgeColor,
       ),
     ),
   );
 }

 // 납부 상태 배지
 Widget _buildPaymentStatusBadge(String status, bool isOverdue) {
   Color badgeColor;
   String statusText;
   
   if (isOverdue && status != 'paid') {
     badgeColor = Colors.red;
     statusText = '납부지연';
   } else {
     switch (status) {
       case 'pending':
         badgeColor = Colors.blue;
         statusText = '납부예정';
         break;
       case 'paid':
         badgeColor = Colors.green;
         statusText = '납부완료';
         break;
       default:
         badgeColor = Colors.grey;
         statusText = status;
     }
   }
   
   return Container(
     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
     decoration: BoxDecoration(
       color: badgeColor.withOpacity(0.1),
       borderRadius: BorderRadius.circular(12),
       border: Border.all(color: badgeColor.withOpacity(0.3)),
     ),
     child: Text(
       statusText,
       style: TextStyle(
         fontSize: 12,
         fontWeight: FontWeight.bold,
         color: badgeColor,
       ),
     ),
   );
 }

 // 정보 행 위젯
 Widget _buildInfoRow(
   String label, 
   String value, 
   IconData icon, {
   Color? textColor,
 }) {
   return Row(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
       Icon(
         icon,
         size: 18,
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
               style: TextStyle(
                 fontSize: 16,
                 color: textColor ?? AppTheme.textPrimaryColor,
               ),
             ),
           ],
         ),
       ),
     ],
   );
 }

 // 잔여 납부액 계산
 String _formatCurrency(double amount) {
   final formatter = NumberFormat('#,###', 'ko_KR');
   return formatter.format(amount);
 }

 // 잔여 납부액 계산
 String _calculateRemainingPayment(ContractModel contract) {
   double totalAmount = contract.totalAmount;
   double paidAmount = 0;
   
   // 계약금 납부액
   if (contract.downPayment.status == 'paid' && 
       contract.downPayment.paidAmount != null) {
     paidAmount += contract.downPayment.paidAmount!;
   }
   
   // 중도금 납부액
   for (var payment in contract.intermediatePayments) {
     if (payment.status == 'paid' && payment.paidAmount != null) {
       paidAmount += payment.paidAmount!;
     }
   }
   
   // 잔금 납부액
   if (contract.finalPayment.status == 'paid' && 
       contract.finalPayment.paidAmount != null) {
     paidAmount += contract.finalPayment.paidAmount!;
   }
   
   double remainingAmount = totalAmount - paidAmount;
   return _formatCurrency(remainingAmount);
 }

 // 상태 변경 다이얼로그
 void _showStatusChangeDialog() {
   final contract = controller.selectedContract.value;
   if (contract == null) return;
   
   String selectedStatus = contract.contractStatus;
   
   showDialog(
     context: context,
     builder: (context) {
       return StatefulBuilder(
         builder: (context, setState) {
           return AlertDialog(
             title: const Text('계약 상태 변경'),
             content: SingleChildScrollView(
               child: Column(
                 mainAxisSize: MainAxisSize.min,
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const Text('현재 상태:'),
                   const SizedBox(height: 8),
                   _buildStatusBadge(contract.contractStatus),
                   const SizedBox(height: 16),
                   const Text('변경할 상태:'),
                   const SizedBox(height: 8),
                   DropdownButtonFormField<String>(
                     value: selectedStatus,
                     decoration: const InputDecoration(
                       border: OutlineInputBorder(),
                       contentPadding: 
                           EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                     ),
                     items: [
                       DropdownMenuItem(
                         value: 'pending',
                         child: Text(controller.getStatusLabel('pending')),
                       ),
                       DropdownMenuItem(
                         value: 'active',
                         child: Text(controller.getStatusLabel('active')),
                       ),
                       DropdownMenuItem(
                         value: 'completed',
                         child: Text(controller.getStatusLabel('completed')),
                       ),
                       DropdownMenuItem(
                         value: 'cancelled',
                         child: Text(controller.getStatusLabel('cancelled')),
                       ),
                     ],
                     onChanged: (value) {
                       if (value != null) {
                         setState(() {
                           selectedStatus = value;
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
                   if (selectedStatus != contract.contractStatus) {
                     await controller.updateContractStatus(
                       contract.id, 
                       selectedStatus
                     );
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

 // 납부 처리 다이얼로그
 void _showPaymentDialog(
   ContractModel contract, 
   String paymentType, 
   int installmentNumber
 ) {
   controller.paymentAmountController.clear();
   controller.paymentDateController.value = DateTime.now();
   controller.receiptImageFile.value = null;
   
   // 기본 금액 설정
   if (paymentType == 'downPayment') {
     controller.paymentAmountController.text = 
         contract.downPayment.amount.toString();
   } else if (paymentType == 'intermediate') {
     final payment = contract.intermediatePayments.firstWhere(
       (p) => p.installmentNumber == installmentNumber
     );
     controller.paymentAmountController.text = payment.amount.toString();
   } else {
     controller.paymentAmountController.text = 
         contract.finalPayment.amount.toString();
   }
   
   showDialog(
     context: context,
     builder: (context) {
       return AlertDialog(
         title: Text('${_getPaymentTypeLabel(paymentType, installmentNumber)} 납부 처리'),
         content: SingleChildScrollView(
           child: Obx(() => Column(
             mainAxisSize: MainAxisSize.min,
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               // 납부일
               const Text('납부일'),
               const SizedBox(height: 8),
               InkWell(
                 onTap: () async {
                   final date = await showDatePicker(
                     context: context,
                     initialDate: controller.paymentDateController.value,
                     firstDate: DateTime(2020),
                     lastDate: DateTime(2030),
                   );
                   if (date != null) {
                     controller.paymentDateController.value = date;
                   }
                 },
                 child: InputDecorator(
                   decoration: const InputDecoration(
                     border: OutlineInputBorder(),
                     contentPadding: 
                         EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                     suffixIcon: Icon(Icons.calendar_today),
                   ),
                   child: Text(
                     DateFormat('yyyy년 MM월 dd일')
                         .format(controller.paymentDateController.value),
                   ),
                 ),
               ),
               const SizedBox(height: 16),
               
               // 납부액
               const Text('납부액'),
               const SizedBox(height: 8),
               TextFormField(
                 controller: controller.paymentAmountController,
                 decoration: const InputDecoration(
                   border: OutlineInputBorder(),
                   contentPadding: 
                       EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                   suffixText: '원',
                 ),
                 keyboardType: TextInputType.number,
                 inputFormatters: [
                   FilteringTextInputFormatter.digitsOnly,
                 ],
               ),
               const SizedBox(height: 16),
               
               // 영수증 이미지
               const Text('영수증 이미지 (선택)'),
               const SizedBox(height: 8),
               if (controller.receiptImageFile.value != null)
                 Stack(
                   children: [
                     Container(
                       width: double.infinity,
                       height: 150,
                       decoration: BoxDecoration(
                         border: Border.all(color: Colors.grey.shade300),
                         borderRadius: BorderRadius.circular(8),
                       ),
                       child: Image.file(
                         controller.receiptImageFile.value!,
                         fit: BoxFit.cover,
                       ),
                     ),
                     Positioned(
                       top: 0,
                       right: 0,
                       child: IconButton(
                         icon: const Icon(Icons.close),
                         onPressed: () {
                           controller.receiptImageFile.value = null;
                         },
                         color: Colors.red,
                       ),
                     ),
                   ],
                 )
               else
                 TextButton.icon(
                   onPressed: () {
                     controller.pickReceiptImage();
                   },
                   icon: const Icon(Icons.upload_file),
                   label: const Text('영수증 이미지 업로드'),
                   style: TextButton.styleFrom(
                     foregroundColor: AppTheme.primaryColor,
                   ),
                 ),
             ],
           )),
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
               await controller.processPayment(
                 contractId: contract.id,
                 paymentType: paymentType,
                 installmentNumber: installmentNumber,
               );
             },
             style: ElevatedButton.styleFrom(
               backgroundColor: AppTheme.primaryColor,
             ),
             child: const Text('납부 처리'),
           ),
         ],
       );
     },
   );
 }

 // 영수증 이미지 보기
 void _showReceiptImage(String imageUrl) {
   showDialog(
     context: context,
     builder: (context) {
       return Dialog(
         child: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             AppBar(
               title: const Text('영수증 이미지'),
               leading: IconButton(
                 icon: const Icon(Icons.close),
                 onPressed: () {
                   Navigator.pop(context);
                 },
               ),
             ),
             Expanded(
               child: InteractiveViewer(
                 panEnabled: true,
                 boundaryMargin: const EdgeInsets.all(20),
                 minScale: 0.5,
                 maxScale: 4,
                 child: Image.network(
                   imageUrl,
                   fit: BoxFit.contain,
                   loadingBuilder: (context, child, loadingProgress) {
                     if (loadingProgress == null) return child;
                     return Center(
                       child: CircularProgressIndicator(
                         value: loadingProgress.expectedTotalBytes != null
                             ? loadingProgress.cumulativeBytesLoaded /
                                 loadingProgress.expectedTotalBytes!
                             : null,
                       ),
                     );
                   },
                   errorBuilder: (context, error, stackTrace) {
                     return Center(
                       child: Column(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
                           const SizedBox(height: 16),
                           const Text('이미지를 불러올 수 없습니다'),
                         ],
                       ),
                     );
                   },
                 ),
               ),
             ),
           ],
         ),
       );
     },
   );
 }

 // 첨부 파일 보기
 void _viewAttachment(String url, String type) {
   // TODO: 실제 구현에서는 첨부 파