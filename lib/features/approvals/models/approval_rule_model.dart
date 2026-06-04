import 'package:ledgixerp/core/auth/user_role.dart';

enum ApprovalModule {
  quotations,
  salesInvoices,
  customerPayments,
  purchaseOrders,
  supplierPayments,
  journalEntries,
  supplierBills,
}

class ApprovalRuleModel {
  final String id;
  final String companyId;
  final ApprovalModule module;
  final double minAmount;
  final double maxAmount;
  final List<UserRole> requiredApproverRoles;
  final bool isEnabled;

  ApprovalRuleModel({
    required this.id,
    required this.companyId,
    required this.module,
    this.minAmount = 0,
    this.maxAmount = double.infinity,
    required this.requiredApproverRoles,
    this.isEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'module': module.name,
      'minAmount': minAmount,
      'maxAmount': maxAmount,
      'requiredApproverRoles': requiredApproverRoles
          .map((e) => e.name)
          .toList(),
      'isEnabled': isEnabled,
    };
  }

  factory ApprovalRuleModel.fromMap(Map<String, dynamic> map, String id) {
    return ApprovalRuleModel(
      id: id,
      companyId: map['companyId'] ?? '',
      module: ApprovalModule.values.firstWhere(
        (e) => e.name == map['module'],
        orElse: () => ApprovalModule.quotations,
      ),
      minAmount: (map['minAmount'] as num?)?.toDouble() ?? 0,
      maxAmount: (map['maxAmount'] as num?)?.toDouble() ?? double.infinity,
      requiredApproverRoles:
          (map['requiredApproverRoles'] as List?)
              ?.map((e) => UserRole.values.firstWhere((role) => role.name == e))
              .toList() ??
          [],
      isEnabled: map['isEnabled'] ?? true,
    );
  }
}
