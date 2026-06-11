import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/features/banking/models/bank_account_model.dart';
import 'package:ledgixerp/features/banking/services/bank_account_service.dart';
import 'package:ledgixerp/features/banking/presentation/widgets/bank_account_pane.dart';
import 'package:ledgixerp/core/widgets/voucher_list_page.dart';
import 'package:ledgixerp/core/widgets/erp_dialogs.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';
import 'package:ledgixerp/features/accounting/presentation/screens/account_ledger_screen.dart';

class BankAccountsScreen extends StatefulWidget {
  final AppUser user;
  const BankAccountsScreen({super.key, required this.user});

  @override
  State<BankAccountsScreen> createState() => _BankAccountsScreenState();
}

class _BankAccountsScreenState extends State<BankAccountsScreen> {
  final _bankService = BankAccountService();

  @override
  Widget build(BuildContext context) {
    return VoucherListPage<BankAccountModel>(
      title: 'Bank & Cash Accounts',
      subtitle: 'Monitor and manage your liquid assets and bank balances',
      stream: _bankService.getBankAccounts(widget.user.companyId!),
      onAddNew: () {
        showErpSidePane(
          context: context,
          builder: BankAccountPane(companyId: widget.user.companyId!),
        );
      },
      columns: const [
        'Account Name',
        'Type',
        'Bank',
        'Balance',
        'Status',
        'Actions'
      ],
      emptyTitle: 'No bank or cash accounts found',
      emptyMessage: 'Start by adding your first bank or cash account.',
      rowBuilder: (account, index) {
        return DataRow(
          cells: [
            DataCell(
              InkWell(
                onTap: () => _openLedger(account),
                child: Text(
                  account.accountName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            DataCell(Text(account.accountType.name.toUpperCase())),
            DataCell(Text(account.bankName ?? '-')),
            DataCell(
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  AppFormatters.currency(account.currentBalance),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (account.isActive ? Colors.green : Colors.red)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  account.isActive ? 'ACTIVE' : 'INACTIVE',
                  style: TextStyle(
                    color: account.isActive ? Colors.green : Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            DataCell(
              VoucherActionMenu(
                onView: () => _openLedger(account),
                onEdit: () {
                  showErpSidePane(
                    context: context,
                    builder: BankAccountPane(
                      companyId: widget.user.companyId!,
                      account: account,
                    ),
                  );
                },
                onDelete: () {
                  showDialog(
                    context: context,
                    builder: (context) => ERPConfirmDeleteDialog(
                      title: 'Delete Account',
                      message:
                          'Are you sure you want to delete ${account.accountName}?',
                      onConfirm: () async {
                        try {
                          await _bankService.deleteBankAccount(
                            widget.user.companyId!,
                            account.id,
                          );
                        } catch (e) {
                          if (mounted) {
                            showErpError(context: context, error: e);
                          }
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _openLedger(BankAccountModel account) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountLedgerScreen(
          accountId: account.linkedChartAccountId,
          accountName: account.accountName,
          user: widget.user,
        ),
      ),
    );
  }
}
