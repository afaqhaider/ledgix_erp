import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:ledgixerp/features/accounting/journal/models/journal_entry_model.dart';
import 'package:ledgixerp/features/accounting/journal/models/journal_line_model.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_model.dart';
import 'package:ledgixerp/features/invoices/models/invoice_model.dart';
import 'package:ledgixerp/features/crm/customer_payments/models/customer_payment_model.dart';
import 'package:ledgixerp/features/supplier_payments/models/supplier_payment_model.dart';
import 'package:ledgixerp/features/suppliers/models/bill_model.dart';
import 'package:ledgixerp/features/expenses/models/expense_voucher_model.dart';
import 'package:ledgixerp/core/audit/audit_service.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/features/settings/services/financial_settings_service.dart';
import 'package:ledgixerp/core/errors/erp_exception.dart';
import '../../inventory/models/inventory_models.dart';

class AccountingPostingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _auditService = AuditService();
  final _settingsService = FinancialSettingsService();

  // --- SALES INVOICE POSTING ---
  Future<String> postSalesInvoice(
    String companyId,
    InvoiceModel invoice,
    AppUser user,
  ) async {
    final List<String> resolvedAccounts = [];
    try {
      debugPrint(
        'AccountingPostingService: Starting postSalesInvoice for ${invoice.invoiceNumber}',
      );
      if (invoice.isPosted) {
        throw Exception('Invoice ${invoice.invoiceNumber} is already posted');
      }

      if (await _settingsService.isPeriodLocked(
        companyId,
        invoice.invoiceDate,
      )) {
        throw Exception(
          'Accounting period for ${invoice.invoiceDate.toString().substring(0, 10)} is locked. Cannot post.',
        );
      }

      final settings = await _settingsService.getSettings(companyId);

      // Validation
      if (invoice.totalAmount <= 0) {
        throw Exception('Invoice total amount must be greater than zero.');
      }
      for (var item in invoice.items) {
        if (item.lineTotal <= 0) {
          throw Exception('Item "${item.description}" has zero or negative total.');
        }
        if (settings.jobBasedAccountingEnabled && (item.jobId == null || item.jobId!.isEmpty) && (invoice.jobId == null || invoice.jobId!.isEmpty)) {
          throw Exception('Job is required for item "${item.description}" when Job-Based Accounting is enabled.');
        }
      }

      // 1. Pre-fetch required system accounts
      final arAccount = await _findAccountByCategory(
        companyId,
        AccountCategory.accountsReceivable,
      );
      resolvedAccounts.add('AR: ${arAccount.accountName} (${arAccount.id})');

      AccountModel? defaultSalesAccount;
      try {
        defaultSalesAccount = await _findAccountByCategory(
          companyId,
          AccountCategory.sales,
        );
        resolvedAccounts.add(
          'Default Sales: ${defaultSalesAccount.accountName} (${defaultSalesAccount.id})',
        );
      } catch (_) {}

      // Look for VAT Output, fallback to VAT Payable (Code 2120 or Category vatPayable)
      AccountModel? vatAccount;
      if (invoice.vatAmount > 0) {
        try {
          vatAccount = await _findAccountByCategory(
            companyId,
            AccountCategory.vatOutput,
          );
        } catch (_) {
          try {
            vatAccount = await _findAccountByCategory(
              companyId,
              AccountCategory.vatPayable,
            );
          } catch (_) {
            try {
              vatAccount = await _findAccountByCode(companyId, '2120');
            } catch (_) {}
          }
        }
        if (vatAccount != null) {
          resolvedAccounts.add(
            'VAT: ${vatAccount.accountName} (${vatAccount.id})',
          );
        }
      }

      AccountModel? defaultCogsAccount;
      AccountModel? defaultInventoryAccount;
      try {
        defaultCogsAccount = await _findAccountByCategory(
          companyId,
          AccountCategory.cogs,
        );
        defaultInventoryAccount = await _findAccountByCategory(
          companyId,
          AccountCategory.inventory,
        );
        resolvedAccounts.add('COGS: ${defaultCogsAccount.accountName}');
        resolvedAccounts.add(
          'Inventory: ${defaultInventoryAccount.accountName}',
        );
      } catch (_) {}

      _validatePostable(arAccount, 'Accounts Receivable');

      String? jeId;

      await _firestore.runTransaction((transaction) async {
        final invoiceRef = _firestore
            .collection('companies')
            .doc(companyId)
            .collection('salesInvoices')
            .doc(invoice.id);
        final invSnap = await transaction.get(invoiceRef);
        if (!invSnap.exists) {
          throw Exception('Invoice document not found in database.');
        }

        final invData = invSnap.data();
        if (invData?['isPosted'] == true) {
          throw Exception('Invoice was already posted by another process.');
        }

        final arAccTx = await _getAccountInTx(
          transaction,
          companyId,
          arAccount.id,
        );

        double totalCogs = 0.0;
        final List<Map<String, dynamic>> productUpdates = [];
        final Map<String, double> salesImpacts = {}; // accountId -> amount
        final Map<String, double> jobRevenueImpacts = {}; // jobId -> amount

        for (var item in invoice.items) {
          String? itemSalesAccountId;

          final effectiveJobId = (item.jobId != null && item.jobId!.isNotEmpty) ? item.jobId : invoice.jobId;
          if (effectiveJobId != null && effectiveJobId.isNotEmpty) {
            jobRevenueImpacts[effectiveJobId] = (jobRevenueImpacts[effectiveJobId] ?? 0) + item.lineSubtotal;
          }

          if (item.productId != null && item.productId!.isNotEmpty) {
            final pRef = _firestore
                .collection('companies')
                .doc(companyId)
                .collection('items')
                .doc(item.productId!);
            final pSnap = await transaction.get(pRef);
            if (pSnap.exists) {
              final pData = pSnap.data()!;
              if (pData['companyId'] == null) pData['companyId'] = companyId;
              final product = InventoryItemModel.fromMap(pData, pSnap.id);
              itemSalesAccountId = product.incomeAccountId;

              if (product.itemType == InventoryItemType.stock) {
                double itemCogs = product.costPrice * item.quantity;
                totalCogs += itemCogs;
                productUpdates.add({
                  'ref': pRef,
                  'newQty': product.stockQuantity - item.quantity,
                  'itemCode': product.itemCode,
                });
              }
            }
          }

          itemSalesAccountId ??= item.accountId.isNotEmpty
              ? item.accountId
              : defaultSalesAccount?.id;

          if (itemSalesAccountId == null || itemSalesAccountId.isEmpty) {
            throw Exception(
              'No sales account found for item "${item.description}". Please ensure a sales account is selected or a default "Sales" account exists.',
            );
          }

          salesImpacts[itemSalesAccountId] =
              (salesImpacts[itemSalesAccountId] ?? 0) + item.lineSubtotal;
          debugPrint(
            'AccountingPostingService: Sales line "${item.description}" -> Account: $itemSalesAccountId, Amount: ${item.lineSubtotal}',
          );
        }

        AccountModel? cogsAccTx;
        AccountModel? invAccTx;
        if (totalCogs > 0) {
          if (defaultCogsAccount == null || defaultInventoryAccount == null) {
            throw Exception(
              'Invoice contains stock items but "Cost of Goods Sold" or "Inventory Asset" accounts are missing in Chart of Accounts.',
            );
          }
          cogsAccTx = await _getAccountInTx(
            transaction,
            companyId,
            defaultCogsAccount.id,
          );
          invAccTx = await _getAccountInTx(
            transaction,
            companyId,
            defaultInventoryAccount.id,
          );

          _validatePostable(cogsAccTx, 'Cost of Goods Sold');
          _validatePostable(invAccTx, 'Inventory Asset');
        }

        final Map<String, AccountModel> salesAccounts = {};
        for (var entry in salesImpacts.entries) {
          if (entry.value == 0) continue;
          final sAccTx = await _getAccountInTx(
            transaction,
            companyId,
            entry.key,
          );
          _validatePostable(sAccTx, sAccTx.accountName);
          salesAccounts[entry.key] = sAccTx;
        }

        AccountModel? vatAccTx;
        if (vatAccount != null && invoice.vatAmount > 0) {
          vatAccTx = await _getAccountInTx(
            transaction,
            companyId,
            vatAccount.id,
          );
          _validatePostable(vatAccTx, vatAccTx.accountName);
        }

        // All transaction reads above this point. Firestore rejects reads after writes.

        final List<JournalLineModel> lines = [];

        // Dr Accounts Receivable
        lines.add(
          _createLine(
            arAccTx,
            invoice.totalAmount,
            0,
            'Sales Invoice ${invoice.invoiceNumber}',
            jobId: invoice.jobId,
            jobNumber: invoice.jobNumber,
            jobName: invoice.jobName,
          ),
        );
        _updateAccountBalanceTx(
          transaction,
          arAccTx,
          invoice.totalAmount,
          0,
          user,
        );

        // Cr Sales Revenue (split by account)
        for (var entry in salesImpacts.entries) {
          if (entry.value == 0) continue;
          final sAccTx = salesAccounts[entry.key]!;
          lines.add(
            _createLine(
              sAccTx,
              0,
              entry.value,
              'Sales Invoice ${invoice.invoiceNumber}: ${sAccTx.accountName}',
              jobId: invoice.jobId,
              jobNumber: invoice.jobNumber,
              jobName: invoice.jobName,
            ),
          );
          _updateAccountBalanceTx(transaction, sAccTx, 0, entry.value, user);
        }

        // Cr VAT Output
        if (vatAccTx != null && invoice.vatAmount > 0) {
          lines.add(
            _createLine(
              vatAccTx,
              0,
              invoice.vatAmount,
              'VAT Output on ${invoice.invoiceNumber}',
              jobId: invoice.jobId,
              jobNumber: invoice.jobNumber,
              jobName: invoice.jobName,
            ),
          );
          _updateAccountBalanceTx(
            transaction,
            vatAccTx,
            0,
            invoice.vatAmount,
            user,
          );
        }

        // Dr COGS / Cr Inventory
        if (totalCogs > 0 && cogsAccTx != null && invAccTx != null) {
          lines.add(
            _createLine(
              cogsAccTx,
              totalCogs,
              0,
              'COGS for Invoice ${invoice.invoiceNumber}',
              jobId: invoice.jobId,
              jobNumber: invoice.jobNumber,
              jobName: invoice.jobName,
            ),
          );
          _updateAccountBalanceTx(transaction, cogsAccTx, totalCogs, 0, user);

          lines.add(
            _createLine(
              invAccTx,
              0,
              totalCogs,
              'Inventory reduction for ${invoice.invoiceNumber}',
              jobId: invoice.jobId,
              jobNumber: invoice.jobNumber,
              jobName: invoice.jobName,
            ),
          );
          _updateAccountBalanceTx(transaction, invAccTx, 0, totalCogs, user);

          for (var update in productUpdates) {
            final pUpdate = {'stockQuantity': update['newQty']};
            debugPrint(
              'TX_WRITE (Item): companies/$companyId/items/${(update['ref'] as DocumentReference).id} | Fields: $pUpdate | UserRole: ${user.role.name}',
            );
            transaction.update(update['ref'] as DocumentReference, pUpdate);
          }
        }

        _validateBalancing(lines);

        final jeRef = _firestore
            .collection('companies')
            .doc(companyId)
            .collection('journalEntries')
            .doc();
        jeId = jeRef.id;

        final journalEntry = JournalEntryModel(
          id: jeRef.id,
          companyId: companyId,
          date: invoice.invoiceDate,
          reference: invoice.invoiceNumber,
          description: 'Posting Sales Invoice ${invoice.invoiceNumber}',
          lines: lines,
          status: JournalStatus.posted,
          createdBy: user.uid,
          createdAt: DateTime.now(),
          sourceType: 'sales_invoice',
          sourceId: invoice.id,
          sourceNumber: invoice.invoiceNumber,
          jobId: invoice.jobId,
          jobNumber: invoice.jobNumber,
          jobName: invoice.jobName,
        );

        transaction.set(jeRef, journalEntry.toMap());
        transaction.update(invoiceRef, {
          'isPosted': true,
          'journalEntryId': jeRef.id,
          'status': 'posted',
          'postedAt': FieldValue.serverTimestamp(),
          'postedBy': user.uid,
          'balanceDue': invoice.totalAmount - invoice.amountPaid,
        });

        // Update Job Balances
        for (var entry in jobRevenueImpacts.entries) {
          _updateJobBalanceTx(transaction, companyId, entry.key, revenueDelta: entry.value);
        }
        if (totalCogs > 0 && invoice.jobId != null && invoice.jobId!.isNotEmpty) {
          _updateJobBalanceTx(transaction, companyId, invoice.jobId, costDelta: totalCogs);
        }
      });

      await _auditService.log(
        companyId: companyId,
        userId: user.uid,
        userName: user.fullName,
        actionType: 'post',
        module: 'invoices',
        documentId: invoice.id,
        documentNumber: invoice.invoiceNumber,
        description: 'Posted Sales Invoice ${invoice.invoiceNumber}',
        newValues: {'isPosted': true},
      );

      return jeId ?? '';
    } catch (e, stack) {
      throw _handleError(e, stack, 'Sales Invoice', resolvedAccounts);
    }
  }

  // --- CUSTOMER PAYMENT POSTING ---
  Future<void> postCustomerPayment(
    String companyId,
    CustomerPaymentModel payment,
    AppUser user,
  ) async {
    final List<String> resolvedAccounts = [];
    try {
      debugPrint(
        'AccountingPostingService: Starting postCustomerPayment for ${payment.paymentNumber}',
      );
      if (payment.isPosted) {
        throw Exception('Payment ${payment.paymentNumber} is already posted');
      }

      if (await _settingsService.isPeriodLocked(
        companyId,
        payment.paymentDate,
      )) {
        throw Exception(
          'Accounting period for ${payment.paymentDate.toString().substring(0, 10)} is locked. Cannot post.',
        );
      }

      if (payment.amount <= 0) {
        throw Exception('Payment amount must be greater than zero.');
      }

      // 1. Pre-fetch required accounts
      final arAccountPre = await _findAccountByCategory(
        companyId,
        AccountCategory.accountsReceivable,
      );
      resolvedAccounts.add(
        'AR: ${arAccountPre.accountName} (${arAccountPre.id})',
      );
      _validatePostable(arAccountPre, 'Accounts Receivable');

      await _firestore.runTransaction((transaction) async {
        final paymentRef = _firestore
            .collection('companies')
            .doc(companyId)
            .collection('customerPayments')
            .doc(payment.id);
        final paySnap = await transaction.get(paymentRef);
        if (!paySnap.exists) {
          throw Exception('Payment document not found in database.');
        }

        final payData = paySnap.data();
        if (payData?['isPosted'] == true) {
          throw Exception('Payment was already posted by another process.');
        }

        AccountModel bankChartAccount;
        DocumentReference? bankAccountRef;
        if (payment.bankAccountId != null &&
            payment.bankAccountId!.isNotEmpty) {
          bankAccountRef = _firestore
              .collection('companies')
              .doc(companyId)
              .collection('bankAccounts')
              .doc(payment.bankAccountId!);
          final bankSnap = await transaction.get(bankAccountRef);
          if (!bankSnap.exists) {
            throw Exception('Linked Bank Account not found');
          }

          final bankData = bankSnap.data() as Map<String, dynamic>;
          final String? linkedId = bankData['linkedChartAccountId'];
          if (linkedId == null || linkedId.isEmpty) {
            throw Exception(
              'Bank account "${bankData['name']}" is not linked to any Chart of Accounts entry.',
            );
          }
          bankChartAccount = await _findAccountById(companyId, linkedId);
        } else {
          bankChartAccount = await _findAccountByCategory(
            companyId,
            AccountCategory.cash,
          );
        }

        resolvedAccounts.add(
          'Bank/Cash: ${bankChartAccount.accountName} (${bankChartAccount.id})',
        );

        final arAccTx = await _getAccountInTx(
          transaction,
          companyId,
          arAccountPre.id,
        );
        final bankAccTx = await _getAccountInTx(
          transaction,
          companyId,
          bankChartAccount.id,
        );

        _validatePostable(bankAccTx, 'Bank/Cash');

        final List<DocumentReference> invRefs = [];
        if (payment.allocations.isNotEmpty) {
          for (var a in payment.allocations) {
            invRefs.add(
              _firestore
                  .collection('companies')
                  .doc(companyId)
                  .collection('salesInvoices')
                  .doc(a.invoiceId),
            );
          }
        } else if (payment.invoiceId != null) {
          invRefs.add(
            _firestore
                .collection('companies')
                .doc(companyId)
                .collection('salesInvoices')
                .doc(payment.invoiceId!),
          );
        }

        final List<DocumentSnapshot> invSnaps = [];
        for (var ref in invRefs) {
          invSnaps.add(await transaction.get(ref));
        }

        final List<JournalLineModel> lines = [];

        // Dr Bank/Cash
        lines.add(
          _createLine(
            bankAccTx,
            payment.amount,
            0,
            'Receipt ${payment.paymentNumber}',
            jobId: payment.jobId,
            jobNumber: payment.jobNumber,
            jobName: payment.jobName,
          ),
        );
        if (bankAccountRef != null) {
          await _updateBankBalanceTx(
            transaction,
            bankAccountRef,
            payment.amount,
            0,
            user,
          );
        }
        _updateAccountBalanceTx(
          transaction,
          bankAccTx,
          payment.amount,
          0,
          user,
        );

        // Cr Accounts Receivable
        lines.add(
          _createLine(
            arAccTx,
            0,
            payment.amount,
            'Receipt ${payment.paymentNumber}',
            jobId: payment.jobId,
            jobNumber: payment.jobNumber,
            jobName: payment.jobName,
          ),
        );
        _updateAccountBalanceTx(transaction, arAccTx, 0, payment.amount, user);

        for (var i = 0; i < invSnaps.length; i++) {
          final snap = invSnaps[i];
          if (snap.exists) {
            final data = snap.data() as Map<String, dynamic>;
            double currentPaid =
                (data['amountPaid'] as num?)?.toDouble() ?? 0.0;
            double total = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
            double allocAmount = payment.allocations.isNotEmpty
                ? payment.allocations[i].amount
                : payment.amount;
            double newPaid = currentPaid + allocAmount;
            double newBalance = total - newPaid;
            transaction.update(snap.reference, {
              'amountPaid': newPaid,
              'balanceDue': newBalance,
              'status': newBalance <= 0.01 ? 'paid' : 'partiallyPaid',
            });
          }
        }

        _validateBalancing(lines);

        final jeRef = _firestore
            .collection('companies')
            .doc(companyId)
            .collection('journalEntries')
            .doc();
        final journalEntry = JournalEntryModel(
          id: jeRef.id,
          companyId: companyId,
          date: payment.paymentDate,
          reference: payment.paymentNumber,
          description: 'Posting Receipt ${payment.paymentNumber}',
          lines: lines,
          status: JournalStatus.posted,
          createdBy: user.uid,
          createdAt: DateTime.now(),
          sourceType: 'receipt',
          sourceId: payment.id,
          sourceNumber: payment.paymentNumber,
          jobId: payment.jobId,
          jobNumber: payment.jobNumber,
          jobName: payment.jobName,
        );

        transaction.set(jeRef, journalEntry.toMap());
        transaction.update(paymentRef, {
          'isPosted': true,
          'journalEntryId': jeRef.id,
          'status': 'posted',
          'postedAt': FieldValue.serverTimestamp(),
          'postedBy': user.uid,
        });
      });

      await _auditService.log(
        companyId: companyId,
        userId: user.uid,
        userName: user.fullName,
        actionType: 'post',
        module: 'payments',
        documentId: payment.id,
        documentNumber: payment.paymentNumber,
        description: 'Posted Receipt ${payment.paymentNumber}',
        newValues: {'isPosted': true},
      );
    } catch (e, stack) {
      throw _handleError(e, stack, 'Receipt', resolvedAccounts);
    }
  }

  // --- SUPPLIER BILL POSTING ---
  Future<void> postSupplierBill(
    String companyId,
    BillModel bill,
    AppUser user,
  ) async {
    AccountModel? apAccount;
    AccountModel? vatInputAccount;
    final List<String> resolvedAccounts = [];

    try {
      debugPrint(
        'AccountingPostingService: Starting postSupplierBill for ${bill.billNumber}',
      );
      if (bill.isPosted) throw Exception('Bill is already posted');

      if (await _settingsService.isPeriodLocked(companyId, bill.billDate)) {
        throw Exception(
          'Accounting period for ${bill.billDate.toString().substring(0, 10)} is locked. Cannot post.',
        );
      }

      final settings = await _settingsService.getSettings(companyId);

      // Validation
      if (bill.totalAmount <= 0) {
        throw Exception('Bill total amount must be greater than zero.');
      }
      for (var item in bill.items) {
        if (item.lineTotal <= 0) {
          throw Exception('Item "${item.description}" has zero or negative total.');
        }
        if (settings.jobBasedAccountingEnabled && (item.jobId == null || item.jobId!.isEmpty) && (bill.jobId == null || bill.jobId!.isEmpty)) {
          throw Exception('Job is required for item "${item.description}" when Job-Based Accounting is enabled.');
        }
      }

      // 1. Pre-fetch required system accounts
      apAccount = await _findAccountByCategory(
        companyId,
        AccountCategory.accountsPayable,
      );
      debugPrint(
        'AccountingPostingService: Resolved AP Account: ${apAccount.accountName} (${apAccount.id})',
      );
      resolvedAccounts.add('AP: ${apAccount.accountName} (${apAccount.id})');

      if (bill.vatAmount > 0) {
        try {
          vatInputAccount = await _findAccountByCategory(
            companyId,
            AccountCategory.vatInput,
          );
          debugPrint(
            'AccountingPostingService: Resolved VAT Input Account: ${vatInputAccount.accountName} (${vatInputAccount.id})',
          );
          resolvedAccounts.add(
            'VAT Input: ${vatInputAccount.accountName} (${vatInputAccount.id})',
          );
        } catch (e) {
          debugPrint(
            'AccountingPostingService: Failed to resolve VAT Input account: $e',
          );
          throw Exception(
            'VAT Input account is missing in Chart of Accounts. Required for bills with VAT.',
          );
        }
      }

      AccountModel? defaultInventoryAcc;
      try {
        defaultInventoryAcc = await _findAccountByCategory(
          companyId,
          AccountCategory.inventory,
        );
        debugPrint(
          'AccountingPostingService: Resolved Default Inventory: ${defaultInventoryAcc.accountName}',
        );
      } catch (_) {}

      AccountModel? defaultExpenseAcc;
      try {
        defaultExpenseAcc = await _findAccountByCategory(
          companyId,
          AccountCategory.operatingExpense,
        );
        debugPrint(
          'AccountingPostingService: Resolved Default Expense: ${defaultExpenseAcc.accountName}',
        );
      } catch (_) {}

      await _validateSupplierBillLineAccounts(
        companyId: companyId,
        bill: bill,
        defaultExpenseAcc: defaultExpenseAcc,
        defaultInventoryAcc: defaultInventoryAcc,
      );

      await _firestore.runTransaction((transaction) async {
        final billRef = _firestore
            .collection('companies')
            .doc(companyId)
            .collection('supplierBills')
            .doc(bill.id);
        final billSnap = await transaction.get(billRef);
        if (!billSnap.exists) {
          throw Exception('Bill document not found in database.');
        }

        final billData = billSnap.data();
        if (billData?['isPosted'] == true) {
          throw Exception('Bill was already posted by another process.');
        }

        final apAccTx = await _getAccountInTx(
          transaction,
          companyId,
          apAccount!.id,
        );
        _validatePostable(apAccTx, 'Accounts Payable');

        final List<JournalLineModel> lines = [];
        final Map<String, double> accountImpacts = {}; // accountId -> subtotal amount
        final Map<String, double> jobCostImpacts = {}; // jobId -> amount
        final List<Map<String, dynamic>> itemUpdates = [];

        for (var item in bill.items) {
          String? targetAccountId;

          final effectiveJobId = (item.jobId != null && item.jobId!.isNotEmpty) ? item.jobId : bill.jobId;
          if (effectiveJobId != null && effectiveJobId.isNotEmpty) {
            jobCostImpacts[effectiveJobId] = (jobCostImpacts[effectiveJobId] ?? 0) + item.lineSubtotal;
          }

          if (item.productId != null && item.productId!.isNotEmpty) {
            final pRef = _firestore
                .collection('companies')
                .doc(companyId)
                .collection('items')
                .doc(item.productId!);
            final pSnap = await transaction.get(pRef);
            if (pSnap.exists) {
              final pData = pSnap.data()!;
              if (pData['companyId'] == null) pData['companyId'] = companyId;
              final product = InventoryItemModel.fromMap(pData, pSnap.id);
              if (product.itemType == InventoryItemType.stock) {
                // Update stock and cost
                final itemUpdate = {
                  'stockQuantity': product.stockQuantity + item.quantity,
                  'costPrice': item.unitPrice,
                };
                itemUpdates.add({'ref': pRef, 'data': itemUpdate});
                targetAccountId =
                    product.inventoryAccountId ?? defaultInventoryAcc?.id;
                debugPrint(
                  'AccountingPostingService: Item "${item.description}" mapped to Inventory Account: $targetAccountId (Product: ${product.itemCode})',
                );
              } else {
                targetAccountId = product.expenseAccountId ?? item.accountId;
                debugPrint(
                  'AccountingPostingService: Item "${item.description}" mapped to Expense Account: $targetAccountId (Product: ${product.itemCode})',
                );
              }
            }
          }

          // Fallback to line item account if still null
          targetAccountId ??= item.accountId.isNotEmpty
              ? item.accountId
              : defaultExpenseAcc?.id;

          if (targetAccountId == null || targetAccountId.isEmpty) {
            throw Exception(
              'No account found for item "${item.description}". Please ensure an account is selected or a default "Operating Expense" account exists.',
            );
          }

          debugPrint(
            'AccountingPostingService: Line item "${item.description}" final account: $targetAccountId, amount: ${item.lineSubtotal}',
          );
          accountImpacts[targetAccountId] =
              (accountImpacts[targetAccountId] ?? 0) + item.lineSubtotal;
        }

        final Map<String, AccountModel> impactedAccounts = {};
        for (var entry in accountImpacts.entries) {
          if (entry.value == 0) continue;
          final accTx = await _getAccountInTx(
            transaction,
            companyId,
            entry.key,
          );
          _validatePostable(accTx, accTx.accountName);
          impactedAccounts[entry.key] = accTx;
        }

        AccountModel? vatAccTx;
        if (bill.vatAmount > 0) {
          if (vatInputAccount == null) {
            throw Exception(
              'VAT Input account is missing in Chart of Accounts. Please ensure a "VAT Input" account exists for processing purchase bills with VAT.',
            );
          }
          vatAccTx = await _getAccountInTx(
            transaction,
            companyId,
            vatInputAccount.id,
          );
          _validatePostable(vatAccTx, vatAccTx.accountName);
        }

        // All transaction reads above this point. Firestore rejects reads after writes.

        // Cr Accounts Payable
        lines.add(
          _createLine(
            apAccTx,
            0,
            bill.totalAmount,
            'Vendor Bill ${bill.billNumber}',
            jobId: bill.jobId,
            jobNumber: bill.jobNumber,
            jobName: bill.jobName,
          ),
        );
        _updateAccountBalanceTx(
          transaction,
          apAccTx,
          0,
          bill.totalAmount,
          user,
        );

        // Dr Inventory / Expenses per account
        for (var entry in accountImpacts.entries) {
          if (entry.value == 0) continue;
          final accTx = impactedAccounts[entry.key]!;
          lines.add(
            _createLine(
              accTx,
              entry.value,
              0,
              'Bill ${bill.billNumber}: ${accTx.accountName}',
              jobId: bill.jobId,
              jobNumber: bill.jobNumber,
              jobName: bill.jobName,
            ),
          );
          _updateAccountBalanceTx(transaction, accTx, entry.value, 0, user);
        }

        // Dr VAT Input
        if (vatAccTx != null && bill.vatAmount > 0) {
          lines.add(
            _createLine(
              vatAccTx,
              bill.vatAmount,
              0,
              'VAT Input on ${bill.billNumber}',
              jobId: bill.jobId,
              jobNumber: bill.jobNumber,
              jobName: bill.jobName,
            ),
          );
          _updateAccountBalanceTx(
            transaction,
            vatAccTx,
            bill.vatAmount,
            0,
            user,
          );
        }

        _validateBalancing(lines);

        for (var update in itemUpdates) {
          final ref = update['ref'] as DocumentReference;
          final data = update['data'] as Map<String, dynamic>;
          debugPrint(
            'TX_WRITE (Item): ${ref.path} | Fields: $data | UserRole: ${user.role.name}',
          );
          transaction.update(ref, data);
        }

        final jeRef = _firestore
            .collection('companies')
            .doc(companyId)
            .collection('journalEntries')
            .doc();
        final journalEntry = JournalEntryModel(
          id: jeRef.id,
          companyId: companyId,
          date: bill.billDate,
          reference: bill.billNumber,
          description: 'Posting Vendor Bill ${bill.billNumber}',
          lines: lines,
          status: JournalStatus.posted,
          createdBy: user.uid,
          createdAt: DateTime.now(),
          sourceType: 'supplier_bill',
          sourceId: bill.id,
          sourceNumber: bill.billNumber,
          jobId: bill.jobId,
          jobNumber: bill.jobNumber,
          jobName: bill.jobName,
        );

        debugPrint(
          'TX_WRITE (JE): companies/$companyId/journalEntries/${jeRef.id} | UserRole: ${user.role.name}',
        );
        transaction.set(jeRef, journalEntry.toMap());

        final billUpdate = {
          'isPosted': true,
          'journalEntryId': jeRef.id,
          'balanceDue': bill.totalAmount,
          'status': 'posted',
          'postedAt': FieldValue.serverTimestamp(),
          'postedBy': user.uid,
        };
        debugPrint(
          'TX_WRITE (Bill): companies/$companyId/supplierBills/${bill.id} | Fields: $billUpdate | UserRole: ${user.role.name}',
        );
        transaction.update(billRef, billUpdate);

        // Update Job Balances
        for (var entry in jobCostImpacts.entries) {
          _updateJobBalanceTx(transaction, companyId, entry.key, costDelta: entry.value);
        }
      });

      await _auditService.log(
        companyId: companyId,
        userId: user.uid,
        userName: user.fullName,
        actionType: 'post',
        module: 'bills',
        documentId: bill.id,
        documentNumber: bill.billNumber,
        description: 'Posted Vendor Bill ${bill.billNumber}',
        newValues: {'isPosted': true},
      );
    } catch (e, stack) {
      throw _handleError(e, stack, 'Supplier Bill', resolvedAccounts);
    }
  }

  // --- SUPPLIER PAYMENT POSTING ---
  Future<void> postSupplierPayment(
    String companyId,
    SupplierPaymentModel payment,
    AppUser user,
  ) async {
    final List<String> resolvedAccounts = [];
    try {
      debugPrint(
        'AccountingPostingService: Starting postSupplierPayment for ${payment.paymentNumber}',
      );
      if (payment.isPosted) {
        throw Exception('Payment ${payment.paymentNumber} is already posted');
      }

      if (await _settingsService.isPeriodLocked(
        companyId,
        payment.paymentDate,
      )) {
        throw Exception(
          'Accounting period for ${payment.paymentDate.toString().substring(0, 10)} is locked. Cannot post.',
        );
      }

      if (payment.amount <= 0) {
        throw Exception('Payment amount must be greater than zero.');
      }

      // 1. Pre-fetch required accounts
      final apAccPre = await _findAccountByCategory(
        companyId,
        AccountCategory.accountsPayable,
      );
      resolvedAccounts.add('AP: ${apAccPre.accountName} (${apAccPre.id})');
      _validatePostable(apAccPre, 'Accounts Payable');

      await _firestore.runTransaction((transaction) async {
        final paymentRef = _firestore
            .collection('companies')
            .doc(companyId)
            .collection('supplierPayments')
            .doc(payment.id);
        final paySnap = await transaction.get(paymentRef);
        if (!paySnap.exists) {
          throw Exception('Payment document not found in database.');
        }

        final payData = paySnap.data();
        if (payData?['isPosted'] == true) {
          throw Exception('Payment was already posted by another process.');
        }

        AccountModel bankChartAccount;
        DocumentReference? bankAccountRef;
        if (payment.bankAccountId != null &&
            payment.bankAccountId!.isNotEmpty) {
          bankAccountRef = _firestore
              .collection('companies')
              .doc(companyId)
              .collection('bankAccounts')
              .doc(payment.bankAccountId!);
          final bankSnap = await transaction.get(bankAccountRef);
          if (!bankSnap.exists) {
            throw Exception('Linked Bank Account not found');
          }

          final bankData = bankSnap.data() as Map<String, dynamic>;
          final String? linkedId = bankData['linkedChartAccountId'];
          if (linkedId == null || linkedId.isEmpty) {
            throw Exception(
              'Bank account "${bankData['name']}" is not linked to any Chart of Accounts entry.',
            );
          }
          bankChartAccount = await _findAccountById(companyId, linkedId);
        } else {
          bankChartAccount = await _findAccountByCategory(
            companyId,
            AccountCategory.cash,
          );
        }

        resolvedAccounts.add(
          'Bank/Cash: ${bankChartAccount.accountName} (${bankChartAccount.id})',
        );

        final apAccTx = await _getAccountInTx(
          transaction,
          companyId,
          apAccPre.id,
        );
        final bankAccTx = await _getAccountInTx(
          transaction,
          companyId,
          bankChartAccount.id,
        );

        _validatePostable(bankAccTx, 'Bank/Cash');

        final List<DocumentReference> billRefs = [];
        if (payment.allocations.isNotEmpty) {
          for (var a in payment.allocations) {
            billRefs.add(
              _firestore
                  .collection('companies')
                  .doc(companyId)
                  .collection('supplierBills')
                  .doc(a.billId),
            );
          }
        } else if (payment.billId != null) {
          billRefs.add(
            _firestore
                .collection('companies')
                .doc(companyId)
                .collection('supplierBills')
                .doc(payment.billId!),
          );
        }

        final List<DocumentSnapshot> billSnaps = [];
        for (var ref in billRefs) {
          billSnaps.add(await transaction.get(ref));
        }

        if (bankAccountRef != null) {
          await _updateBankBalanceTx(
            transaction,
            bankAccountRef,
            0,
            payment.amount,
            user,
          );
        }

        final List<JournalLineModel> lines = [];

        // Dr Accounts Payable
        lines.add(
          _createLine(
            apAccTx,
            payment.amount,
            0,
            'Supplier Payment ${payment.paymentNumber}',
            jobId: payment.jobId,
            jobNumber: payment.jobNumber,
            jobName: payment.jobName,
          ),
        );
        _updateAccountBalanceTx(transaction, apAccTx, payment.amount, 0, user);

        // Cr Bank/Cash
        lines.add(
          _createLine(
            bankAccTx,
            0,
            payment.amount,
            'Supplier Payment ${payment.paymentNumber}',
            jobId: payment.jobId,
            jobNumber: payment.jobNumber,
            jobName: payment.jobName,
          ),
        );
        _updateAccountBalanceTx(
          transaction,
          bankAccTx,
          0,
          payment.amount,
          user,
        );

        for (var i = 0; i < billSnaps.length; i++) {
          final snap = billSnaps[i];
          if (snap.exists) {
            final data = snap.data() as Map<String, dynamic>;
            double currentPaid =
                (data['amountPaid'] as num?)?.toDouble() ?? 0.0;
            double total = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
            double allocAmount = payment.allocations.isNotEmpty
                ? payment.allocations[i].amount
                : payment.amount;
            double newPaid = currentPaid + allocAmount;
            double newBalance = total - newPaid;
            transaction.update(snap.reference, {
              'amountPaid': newPaid,
              'balanceDue': newBalance,
              'status': newBalance <= 0.01 ? 'paid' : 'partiallyPaid',
            });
          }
        }

        _validateBalancing(lines);

        final jeRef = _firestore
            .collection('companies')
            .doc(companyId)
            .collection('journalEntries')
            .doc();
        final journalEntry = JournalEntryModel(
          id: jeRef.id,
          companyId: companyId,
          date: payment.paymentDate,
          reference: payment.paymentNumber,
          description: 'Posting Supplier Payment ${payment.paymentNumber}',
          lines: lines,
          status: JournalStatus.posted,
          createdBy: user.uid,
          createdAt: DateTime.now(),
          sourceType: 'supplier_payment',
          sourceId: payment.id,
          sourceNumber: payment.paymentNumber,
          jobId: payment.jobId,
          jobNumber: payment.jobNumber,
          jobName: payment.jobName,
        );

        transaction.set(jeRef, journalEntry.toMap());
        transaction.update(paymentRef, {
          'isPosted': true,
          'journalEntryId': jeRef.id,
          'status': 'posted',
          'postedAt': FieldValue.serverTimestamp(),
          'postedBy': user.uid,
        });
      });

      await _auditService.log(
        companyId: companyId,
        userId: user.uid,
        userName: user.fullName,
        actionType: 'post',
        module: 'payments',
        documentId: payment.id,
        documentNumber: payment.paymentNumber,
        description: 'Posted Supplier Payment ${payment.paymentNumber}',
        newValues: {'isPosted': true},
      );
    } catch (e, stack) {
      throw _handleError(e, stack, 'Supplier Payment', resolvedAccounts);
    }
  }

  // --- MANUAL JOURNAL ENTRY POSTING ---
  Future<void> postManualJournalEntry(
    String companyId,
    JournalEntryModel entry,
    AppUser user,
  ) async {
    final List<String> resolvedAccounts = [];
    try {
      if (entry.status == JournalStatus.posted) {
        throw Exception('Entry is already posted');
      }
      if (await _settingsService.isPeriodLocked(companyId, entry.date)) {
        throw Exception('Accounting period for this date is locked.');
      }

      await _firestore.runTransaction((transaction) async {
        final jeRef = _firestore
            .collection('companies')
            .doc(companyId)
            .collection('journalEntries')
            .doc(entry.id);
        final jeSnap = await transaction.get(jeRef);
        final jeData = jeSnap.data();
        if (jeSnap.exists && jeData?['status'] == 'posted') {
          throw Exception('Entry is already posted');
        }

        _validateBalancing(entry.lines);

        final Map<String, double> movements = {};
        final Map<String, AccountModel> movementAccounts = {};
        final Map<String, double> jobRevenueUpdates = {};
        final Map<String, double> jobCostUpdates = {};

        for (var line in entry.lines) {
          final accRef = _firestore
              .collection('companies')
              .doc(companyId)
              .collection('chartOfAccounts')
              .doc(line.accountId);
          final accSnap = await transaction.get(accRef);
          if (!accSnap.exists) {
            throw Exception(
              'Account ${line.accountName} (ID: ${line.accountId}) not found.',
            );
          }

          final accData = accSnap.data();
          final account = AccountModel.fromMap(accData!, accSnap.id);
          _validatePostable(account, account.accountName);
          resolvedAccounts.add(
            '${account.accountName} (${account.accountCode})',
          );

          bool isDebitNormal = account.normalBalance == BalanceType.debit;
          double movement = isDebitNormal
              ? (line.debit - line.credit)
              : (line.credit - line.debit);
          movements[account.id] = (movements[account.id] ?? 0) + movement;
          movementAccounts[account.id] = account;

          // Job Costing Updates
          if (line.jobId != null && line.jobId!.isNotEmpty) {
            if (account.accountType == AccountType.income || account.accountType == AccountType.otherIncome) {
              double delta = line.credit - line.debit;
              jobRevenueUpdates[line.jobId!] = (jobRevenueUpdates[line.jobId!] ?? 0) + delta;
            } else if (account.accountType == AccountType.expense || account.accountType == AccountType.costOfSales || account.accountType == AccountType.otherExpense) {
              double delta = line.debit - line.credit;
              jobCostUpdates[line.jobId!] = (jobCostUpdates[line.jobId!] ?? 0) + delta;
            }
          }
        }

        for (var m in movements.entries) {
          final account = movementAccounts[m.key]!;
          _updateAccountMovementTx(
            transaction,
            account,
            m.value,
            user,
            'Account-Manual',
          );
        }

        // Apply Job Updates
        final allJobIds = {...jobRevenueUpdates.keys, ...jobCostUpdates.keys};
        for (var jId in allJobIds) {
          _updateJobBalanceTx(
            transaction,
            companyId,
            jId,
            revenueDelta: jobRevenueUpdates[jId] ?? 0,
            costDelta: jobCostUpdates[jId] ?? 0,
          );
        }

        final jeUpdate = {
          'status': JournalStatus.posted.name,
          'postedAt': FieldValue.serverTimestamp(),
          'postedBy': user.uid,
        };
        debugPrint(
          'TX_WRITE (JE-Status): companies/$companyId/journalEntries/${entry.id} | Fields: $jeUpdate | UserRole: ${user.role.name}',
        );
        transaction.update(jeRef, jeUpdate);
      });

      await _auditService.log(
        companyId: companyId,
        userId: user.uid,
        userName: user.fullName,
        actionType: 'post',
        module: 'accounting',
        documentId: entry.id,
        documentNumber: entry.reference,
        description: 'Posted Manual Journal Entry ${entry.reference}',
      );
    } catch (e, stack) {
      throw _handleError(e, stack, 'Manual Journal Entry', resolvedAccounts);
    }
  }

  // --- EXPENSE VOUCHER POSTING ---
  Future<void> postExpenseVoucher(
    String companyId,
    ExpenseVoucherModel voucher,
    AppUser user,
  ) async {
    final List<String> resolvedAccounts = [];
    try {
      debugPrint(
        'AccountingPostingService: Starting postExpenseVoucher for ${voucher.voucherNumber}',
      );
      if (voucher.status == ExpenseVoucherStatus.posted) {
        throw Exception('Voucher ${voucher.voucherNumber} is already posted');
      }

      if (await _settingsService.isPeriodLocked(companyId, voucher.date)) {
        throw Exception(
          'Accounting period for ${voucher.date.toString().substring(0, 10)} is locked. Cannot post.',
        );
      }

      final settings = await _settingsService.getSettings(companyId);

      // Validation: Zero amount lines and Jobs
      for (var line in voucher.lines) {
        if (line.total <= 0) {
          throw Exception('Expense line for "${line.description}" has zero or negative amount.');
        }
        if (settings.jobBasedAccountingEnabled && (line.jobId == null || line.jobId!.isEmpty) && (voucher.jobId == null || voucher.jobId!.isEmpty)) {
          throw Exception('Job is required for expense line "${line.description}" when Job-Based Accounting is enabled.');
        }
      }

      // 1. Resolve 'From' Account (Bank/Cash)
      final fromAccount = await _getAccountInTxNoTx(companyId, voucher.fromAccountId);
      _validatePostable(fromAccount, fromAccount.accountName);
      resolvedAccounts.add('From: ${fromAccount.accountName} (${fromAccount.id})');

      // Resolve VAT Input Account if needed
      AccountModel? vatInputAccount;
      if (voucher.totalVat > 0) {
        vatInputAccount = await _findAccountByCategory(companyId, AccountCategory.vatInput);
        resolvedAccounts.add('VAT: ${vatInputAccount.accountName}');
      }

      // Check if fromAccount is linked to a BankAccount doc (Pre-fetch outside transaction)
      DocumentReference? linkedBankRef;
      final bankAccs = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('bankAccounts')
          .where('linkedChartAccountId', isEqualTo: fromAccount.id)
          .limit(1)
          .get();
      if (bankAccs.docs.isNotEmpty) {
        linkedBankRef = bankAccs.docs.first.reference;
      }

      await _firestore.runTransaction((transaction) async {
        final voucherRef = _firestore
            .collection('companies')
            .doc(companyId)
            .collection('expenseVouchers')
            .doc(voucher.id);
            
        final vSnap = await transaction.get(voucherRef);
        if (!vSnap.exists) throw Exception('Voucher document not found.');
        if (vSnap.data()?['status'] == 'posted') throw Exception('Voucher already posted.');

        // --- ALL READS FIRST ---

        // Read From Account
        final fromAccTx = await _getAccountInTx(transaction, companyId, fromAccount.id);
        
        // Read Bank Account if linked
        DocumentSnapshot? bankAccSnap;
        if (linkedBankRef != null) {
          bankAccSnap = await transaction.get(linkedBankRef);
        }

        // Read all Expense Accounts (Aggregated to minimize reads)
        final Set<String> expenseAccountIds = voucher.lines.map((l) => l.accountId).toSet();
        final Map<String, AccountModel> expAccountsTx = {};
        for (var accId in expenseAccountIds) {
          // Skip if it's the same as fromAccount (already read)
          if (accId == fromAccount.id) {
            expAccountsTx[accId] = fromAccTx;
            continue;
          }
          final acc = await _getAccountInTx(transaction, companyId, accId);
          _validatePostable(acc, acc.accountName);
          expAccountsTx[accId] = acc;
        }

        // Read VAT Account if needed
        AccountModel? vatAccTx;
        if (vatInputAccount != null && voucher.totalVat > 0) {
          if (vatInputAccount.id == fromAccount.id) {
            vatAccTx = fromAccTx;
          } else if (expAccountsTx.containsKey(vatInputAccount.id)) {
            vatAccTx = expAccountsTx[vatInputAccount.id];
          } else {
            vatAccTx = await _getAccountInTx(transaction, companyId, vatInputAccount.id);
          }
        }

        // --- ALL WRITES AFTER READS ---

        final List<JournalLineModel> lines = [];
        final Map<String, (double, double)> drCrTotals = {}; // accountId -> (debit, credit)
        final Map<String, double> jobCostImpacts = {}; // jobId -> amount

        // Calculate Job Impacts
        for (var line in voucher.lines) {
          final effectiveJobId = (line.jobId != null && line.jobId!.isNotEmpty) ? line.jobId : voucher.jobId;
          if (effectiveJobId != null && effectiveJobId.isNotEmpty) {
            jobCostImpacts[effectiveJobId] = (jobCostImpacts[effectiveJobId] ?? 0) + line.amount;
          }
        }

        void addImpact(String id, double dr, double cr) {
          final current = drCrTotals[id] ?? (0.0, 0.0);
          drCrTotals[id] = (current.$1 + dr, current.$2 + cr);
        }

        // 1. Cr Bank/Cash
        lines.add(_createLine(
          fromAccTx,
          0,
          voucher.totalAmount,
          'Expense Voucher ${voucher.voucherNumber}',
          jobId: voucher.jobId,
          jobNumber: voucher.jobNumber,
          jobName: voucher.jobName,
        ));
        addImpact(fromAccount.id, 0, voucher.totalAmount);

        // 2. Update Bank Account balance if linked
        if (linkedBankRef != null && bankAccSnap != null && bankAccSnap.exists) {
          final bankData = bankAccSnap.data() as Map<String, dynamic>;
          final currentBalance = (bankData['currentBalance'] as num?)?.toDouble() ?? 0.0;
          transaction.update(linkedBankRef, {'currentBalance': currentBalance - voucher.totalAmount});
        }

        // 3. Dr Expense Accounts
        for (var line in voucher.lines) {
          final acc = expAccountsTx[line.accountId]!;
          lines.add(_createLine(
            acc,
            line.amount,
            0,
            line.description,
            jobId: line.jobId ?? voucher.jobId,
            jobNumber: line.jobNumber ?? voucher.jobNumber,
            jobName: line.jobName ?? voucher.jobName,
          ));
          addImpact(line.accountId, line.amount, 0);
        }

        // 4. Dr VAT Input
        if (vatAccTx != null) {
          lines.add(_createLine(
            vatAccTx,
            voucher.totalVat,
            0,
            'VAT Input on ${voucher.voucherNumber}',
            jobId: voucher.jobId,
            jobNumber: voucher.jobNumber,
            jobName: voucher.jobName,
          ));
          addImpact(vatAccTx.id, voucher.totalVat, 0);
        }

        _validateBalancing(lines);

        // Perform aggregated balance updates for all accounts
        for (var entry in drCrTotals.entries) {
          final accId = entry.key;
          final dr = entry.value.$1;
          final cr = entry.value.$2;
          
          AccountModel? acc;
          if (accId == fromAccount.id) {
            acc = fromAccTx;
          } else if (expAccountsTx.containsKey(accId)) {
            acc = expAccountsTx[accId];
          } else if (vatAccTx != null && accId == vatAccTx.id) {
            acc = vatAccTx;
          }

          if (acc != null) {
            _updateAccountBalanceTx(transaction, acc, dr, cr, user);
          }
        }

        final jeRef = _firestore.collection('companies').doc(companyId).collection('journalEntries').doc();
        final journalEntry = JournalEntryModel(
          id: jeRef.id,
          companyId: companyId,
          date: voucher.date,
          reference: voucher.voucherNumber,
          description: voucher.description,
          lines: lines,
          status: JournalStatus.posted,
          createdBy: user.uid,
          createdAt: DateTime.now(),
          sourceType: 'expense_voucher',
          sourceId: voucher.id,
          sourceNumber: voucher.voucherNumber,
          jobId: voucher.jobId,
          jobNumber: voucher.jobNumber,
          jobName: voucher.jobName,
        );

        transaction.set(jeRef, journalEntry.toMap());
        transaction.update(voucherRef, {
          'status': 'posted',
          'isPosted': true,
          'journalEntryId': jeRef.id,
          'postedAt': FieldValue.serverTimestamp(),
          'postedByUserId': user.uid,
        });

        // Update Job Balances
        for (var entry in jobCostImpacts.entries) {
          _updateJobBalanceTx(transaction, companyId, entry.key, costDelta: entry.value);
        }
      });

      await _auditService.log(
        companyId: companyId,
        userId: user.uid,
        userName: user.fullName,
        actionType: 'post',
        module: 'expenses',
        documentId: voucher.id,
        documentNumber: voucher.voucherNumber,
        description: 'Posted Expense Voucher ${voucher.voucherNumber}',
      );
    } catch (e, stack) {
      throw _handleError(e, stack, 'Expense Voucher', resolvedAccounts);
    }
  }

  Future<AccountModel> _getAccountInTxNoTx(String companyId, String accountId) async {
    final doc = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('chartOfAccounts')
        .doc(accountId)
        .get();
    if (!doc.exists) throw Exception('Account with ID $accountId not found.');
    final data = doc.data()!;
    if (data['companyId'] == null) data['companyId'] = companyId;
    return AccountModel.fromMap(data, doc.id);
  }

  // --- REVERSAL LOGIC ---
  Future<void> reversePosting(
    String companyId,
    String journalEntryId,
    AppUser user,
  ) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final jeRef = _firestore
            .collection('companies')
            .doc(companyId)
            .collection('journalEntries')
            .doc(journalEntryId);
        final jeSnap = await transaction.get(jeRef);
        final jeData = jeSnap.data();
        if (!jeSnap.exists || jeData == null) {
          throw Exception('Journal Entry not found');
        }

        final entry = JournalEntryModel.fromMap(jeData, jeSnap.id);
        if (entry.status == JournalStatus.reversed) {
          throw Exception('Entry is already reversed');
        }

        // 1. Reverse GL balances (Aggregated)
        final Map<String, double> movements = {};
        final Map<String, AccountModel> movementAccounts = {};
        for (var line in entry.lines) {
          final accRef = _firestore
              .collection('companies')
              .doc(companyId)
              .collection('chartOfAccounts')
              .doc(line.accountId);
          final accSnap = await transaction.get(accRef);
          final accData = accSnap.data();
          if (accSnap.exists && accData != null) {
            final account = AccountModel.fromMap(accData, accSnap.id);
            bool isDebitNormal = account.normalBalance == BalanceType.debit;
            // Reversing: Cr becomes Dr, Dr becomes Cr
            double movement = isDebitNormal
                ? (line.credit - line.debit)
                : (line.debit - line.credit);
            movements[account.id] = (movements[account.id] ?? 0) + movement;
            movementAccounts[account.id] = account;
          }
        }

        for (var m in movements.entries) {
          final account = movementAccounts[m.key]!;
          _updateAccountMovementTx(
            transaction,
            account,
            m.value,
            user,
            'Account-Reverse',
          );
        }

        // 2. Reverse Sub-ledger impact
        if (entry.sourceType != null && entry.sourceId != null) {
          final String col = _getCollectionForSource(entry.sourceType!);
          if (col.isNotEmpty) {
            final srcRef = _firestore
                .collection('companies')
                .doc(companyId)
                .collection(col)
                .doc(entry.sourceId);
            final srcSnap = await transaction.get(srcRef);
            final data = srcSnap.data();

            if (srcSnap.exists && data != null) {
              // Reverse Stock/Inventory for Invoices and Bills
              if (entry.sourceType == 'sales_invoice') {
                final invoice = InvoiceModel.fromMap(data, srcSnap.id);
                for (var item in invoice.items) {
                  if (item.productId != null) {
                    final pRef = _firestore
                        .collection('companies')
                        .doc(companyId)
                        .collection('items')
                        .doc(item.productId!);
                    final pSnap = await transaction.get(pRef);
                    final productData = pSnap.data();
                    if (pSnap.exists && productData != null) {
                      final product = InventoryItemModel.fromMap(
                        productData,
                        pSnap.id,
                      );
                      if (product.itemType == InventoryItemType.stock) {
                        transaction.update(pRef, {
                          'stockQuantity':
                              product.stockQuantity + item.quantity,
                        });
                      }
                    }
                  }
                }
              } else if (entry.sourceType == 'supplier_bill') {
                final bill = BillModel.fromMap(data, srcSnap.id);
                for (var item in bill.items) {
                  if (item.productId != null) {
                    final pRef = _firestore
                        .collection('companies')
                        .doc(companyId)
                        .collection('items')
                        .doc(item.productId!);
                    final pSnap = await transaction.get(pRef);
                    final productData = pSnap.data();
                    if (pSnap.exists && productData != null) {
                      final product = InventoryItemModel.fromMap(
                        productData,
                        pSnap.id,
                      );
                      if (product.itemType == InventoryItemType.stock) {
                        transaction.update(pRef, {
                          'stockQuantity':
                              product.stockQuantity - item.quantity,
                        });
                      }
                    }
                  }
                }
              }
              // Reverse Payment Allocations for Receipts and Supplier Payments
              else if (entry.sourceType == 'receipt') {
                final payment = CustomerPaymentModel.fromMap(data, srcSnap.id);
                if (payment.bankAccountId != null) {
                  final bRef = _firestore
                      .collection('companies')
                      .doc(companyId)
                      .collection('bankAccounts')
                      .doc(payment.bankAccountId!);
                  await _updateBankBalanceTx(
                    transaction,
                    bRef,
                    0,
                    payment.amount,
                    user,
                  );
                }

                final List<Map<String, dynamic>> allocations =
                    payment.allocations.isNotEmpty
                    ? payment.allocations
                          .map((a) => {'id': a.invoiceId, 'amt': a.amount})
                          .toList()
                    : (payment.invoiceId != null
                          ? [
                              {'id': payment.invoiceId!, 'amt': payment.amount},
                            ]
                          : []);

                for (var a in allocations) {
                  final invRef = _firestore
                      .collection('companies')
                      .doc(companyId)
                      .collection('salesInvoices')
                      .doc(a['id'] as String);
                  final invSnap = await transaction.get(invRef);
                  final invData = invSnap.data();
                  if (invSnap.exists && invData != null) {
                    double paid =
                        (invData['amountPaid'] as num).toDouble() -
                        (a['amt'] as double);
                    double total = (invData['totalAmount'] as num).toDouble();
                    final invUpdate = {
                      'amountPaid': paid,
                      'balanceDue': total - paid,
                      'status': paid > 0 ? 'partiallyPaid' : 'posted',
                    };
                    debugPrint(
                      'TX_WRITE (Invoice-Reverse): ${invRef.path} | Fields: $invUpdate | UserRole: ${user.role.name}',
                    );
                    transaction.update(invRef, invUpdate);
                  }
                }
              } else if (entry.sourceType == 'supplier_payment') {
                final payment = SupplierPaymentModel.fromMap(data, srcSnap.id);
                if (payment.bankAccountId != null) {
                  final bRef = _firestore
                      .collection('companies')
                      .doc(companyId)
                      .collection('bankAccounts')
                      .doc(payment.bankAccountId!);
                  await _updateBankBalanceTx(
                    transaction,
                    bRef,
                    payment.amount,
                    0,
                    user,
                  );
                }

                final List<Map<String, dynamic>> allocations =
                    payment.allocations.isNotEmpty
                    ? payment.allocations
                          .map((a) => {'id': a.billId, 'amt': a.amount})
                          .toList()
                    : (payment.billId != null
                          ? [
                              {'id': payment.billId!, 'amt': payment.amount},
                            ]
                          : []);

                for (var a in allocations) {
                  final billRef = _firestore
                      .collection('companies')
                      .doc(companyId)
                      .collection('supplierBills')
                      .doc(a['id'] as String);
                  final billSnap = await transaction.get(billRef);
                  final billData = billSnap.data();
                  if (billSnap.exists && billData != null) {
                    double paid =
                        (billData['amountPaid'] as num).toDouble() -
                        (a['amt'] as double);
                    double total = (billData['totalAmount'] as num).toDouble();
                    final billUpdate = {
                      'amountPaid': paid,
                      'balanceDue': total - paid,
                      'status': paid > 0 ? 'partiallyPaid' : 'posted',
                    };
                    debugPrint(
                      'TX_WRITE (Bill-Reverse): ${billRef.path} | Fields: $billUpdate | UserRole: ${user.role.name}',
                    );
                    transaction.update(billRef, billUpdate);
                  }
                }
              }

              debugPrint(
                'TX_WRITE (Source-Void): ${srcRef.path} | UserRole: ${user.role.name}',
              );
              transaction.update(srcRef, {
                'isPosted': false,
                'status': 'voided',
              });

              // Reverse Job Impacts
              if (entry.sourceType == 'sales_invoice') {
                for (var line in entry.lines) {
                  if (line.jobId != null && line.credit > 0) {
                    _updateJobBalanceTx(transaction, companyId, line.jobId, revenueDelta: -line.credit);
                  }
                  if (line.jobId != null && line.debit > 0 && line.memo != null && line.memo!.contains('COGS')) {
                    _updateJobBalanceTx(transaction, companyId, line.jobId, costDelta: -line.debit);
                  }
                }
              } else if (entry.sourceType == 'supplier_bill' || entry.sourceType == 'expense_voucher') {
                for (var line in entry.lines) {
                  if (line.jobId != null && line.debit > 0) {
                    _updateJobBalanceTx(transaction, companyId, line.jobId, costDelta: -line.debit);
                  }
                }
              }
            }
          }
        }

        debugPrint(
          'TX_WRITE (JE-Reverse): ${jeRef.path} | UserRole: ${user.role.name}',
        );
        transaction.update(jeRef, {'status': JournalStatus.reversed.name});
      });

      await _auditService.log(
        companyId: companyId,
        userId: user.uid,
        userName: user.fullName,
        actionType: 'reverse',
        module: 'accounting',
        documentId: journalEntryId,
        description: 'Reversed Journal Entry $journalEntryId',
      );
    } catch (e, stack) {
      throw _handleError(e, stack, 'Reversal', []);
    }
  }

  // --- HELPERS ---

  void _updateJobBalanceTx(
    Transaction tx,
    String companyId,
    String? jobId, {
    double revenueDelta = 0,
    double costDelta = 0,
  }) {
    if (jobId == null || jobId.isEmpty) return;

    final jobRef = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('jobs')
        .doc(jobId);

    debugPrint(
      'TX_WRITE (Job): ${jobRef.path} | revenueDelta: $revenueDelta | costDelta: $costDelta',
    );
    tx.update(jobRef, {
      'actualRevenue': FieldValue.increment(revenueDelta),
      'actualCost': FieldValue.increment(costDelta),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  ErpException _handleError(
    dynamic e,
    StackTrace stack,
    String context,
    List<String> resolvedAccounts,
  ) {
    debugPrint('AccountingPostingService ERROR ($context)');
    debugPrint('  runtimeType: ${e.runtimeType}');
    debugPrint('  toString: ${e.toString()}');

    String? boxedInfo = _extractBoxedInfo(e);
    if (boxedInfo != null) {
      debugPrint('  Extracted Boxed Info: $boxedInfo');
    }

    debugPrint('  stackTrace: $stack');
    debugPrint('Resolved Accounts: $resolvedAccounts');

    String title = 'Posting Failed';
    String message = 'An error occurred while posting $context to accounting.';

    String details = 'Context: $context\n';
    if (boxedInfo != null) {
      details += 'Error: $boxedInfo\n';
    } else {
      details += 'Error: $e\n';
    }

    if (resolvedAccounts.isNotEmpty) {
      details += '\nResolved Accounts:\n${resolvedAccounts.join('\n')}';
    }

    details += '\n\nStack Trace:\n$stack';

    if (e is FirebaseException) {
      title = 'Database Error';
      message = 'Firestore error [${e.code}]: ${e.message}';
    } else if (e.toString().contains('locked')) {
      title = 'Period Locked';
      message = e.toString().replaceFirst('Exception: ', '');
    } else if (e is Exception) {
      message = e.toString().replaceFirst('Exception: ', '');
    }

    return ErpException(
      title: title,
      message: message,
      technicalDetails: details,
      originalError: e,
    );
  }

  String? _extractBoxedInfo(dynamic e) {
    try {
      // In Flutter Web, some errors are boxed. Try to extract the real message.
      final dynamic err = e;
      if (err.error != null) {
        return err.error.toString();
      }
    } catch (_) {}
    return null;
  }

  String _getCollectionForSource(String type) {
    switch (type.toLowerCase()) {
      case 'sales_invoice':
        return 'salesInvoices';
      case 'receipt':
        return 'customerPayments';
      case 'supplier_bill':
        return 'supplierBills';
      case 'supplier_payment':
        return 'supplierPayments';
      case 'expense_voucher':
        return 'expenseVouchers';
      default:
        return '';
    }
  }

  /// Finds an account by account code.
  Future<AccountModel> _findAccountByCode(String companyId, String code) async {
    final snap = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('chartOfAccounts')
        .where('accountCode', isEqualTo: code)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      throw Exception('Required system account with code "$code" not found.');
    }

    final data = snap.docs.first.data();
    if (data['companyId'] == null) data['companyId'] = companyId;
    return AccountModel.fromMap(data, snap.docs.first.id);
  }

  /// Finds an account by category. This is preferred for system accounts.
  Future<AccountModel> _findAccountByCategory(
    String companyId,
    AccountCategory category,
  ) async {
    final snap = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('chartOfAccounts')
        .where('accountCategory', isEqualTo: category.name)
        .where('isGroup', isEqualTo: false)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      // Fallback to name-based if category not found (for legacy data)
      String fallbackName = '';
      switch (category) {
        case AccountCategory.accountsReceivable:
          fallbackName = 'Accounts Receivable';
          break;
        case AccountCategory.accountsPayable:
          fallbackName = 'Accounts Payable';
          break;
        case AccountCategory.sales:
          fallbackName = 'Sales Revenue';
          break;
        case AccountCategory.vatOutput:
          fallbackName = 'VAT Output';
          break;
        case AccountCategory.vatInput:
          fallbackName = 'VAT Input';
          break;
        case AccountCategory.cogs:
          fallbackName = 'Cost of Goods Sold';
          break;
        case AccountCategory.inventory:
          fallbackName = 'Inventory Asset';
          break;
        case AccountCategory.cash:
          fallbackName = 'Cash Account';
          break;
        case AccountCategory.operatingExpense:
          fallbackName = 'Operating Expenses';
          break;
        default:
          break;
      }

      if (fallbackName.isNotEmpty) {
        try {
          return await _findAccountByName(companyId, fallbackName);
        } catch (_) {}
      }

      throw Exception(
        'Required system account for category "${category.label}" not found. Please ensure Chart of Accounts is seeded.',
      );
    }

    final data = snap.docs.first.data();
    if (data['companyId'] == null) data['companyId'] = companyId;
    return AccountModel.fromMap(data, snap.docs.first.id);
  }

  /// Finds an account by name (Exact match).
  Future<AccountModel> _findAccountByName(String companyId, String name) async {
    final snap = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('chartOfAccounts')
        .where('accountName', isEqualTo: name)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      throw Exception(
        'Required system account "$name" not found. Please ensure Chart of Accounts is seeded.',
      );
    }

    final data = snap.docs.first.data();
    if (data['companyId'] == null) data['companyId'] = companyId;
    return AccountModel.fromMap(data, snap.docs.first.id);
  }

  /// Finds an account by ID.
  Future<AccountModel> _findAccountById(String companyId, String id) async {
    final doc = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('chartOfAccounts')
        .doc(id)
        .get();
    if (!doc.exists) throw Exception('Account with ID $id not found.');
    final data = doc.data()!;
    if (data['companyId'] == null) data['companyId'] = companyId;
    return AccountModel.fromMap(data, doc.id);
  }

  Future<void> _validateSupplierBillLineAccounts({
    required String companyId,
    required BillModel bill,
    required AccountModel? defaultExpenseAcc,
    required AccountModel? defaultInventoryAcc,
  }) async {
    for (final item in bill.items) {
      String? targetAccountId;

      if (item.productId != null && item.productId!.isNotEmpty) {
        final pSnap = await _firestore
            .collection('companies')
            .doc(companyId)
            .collection('items')
            .doc(item.productId!)
            .get();
        if (pSnap.exists) {
          final pData = pSnap.data()!;
          if (pData['companyId'] == null) pData['companyId'] = companyId;
          final product = InventoryItemModel.fromMap(pData, pSnap.id);
          targetAccountId = product.itemType == InventoryItemType.stock
              ? product.inventoryAccountId ?? defaultInventoryAcc?.id
              : product.expenseAccountId ?? item.accountId;
        }
      }

      targetAccountId ??= item.accountId.isNotEmpty
          ? item.accountId
          : defaultExpenseAcc?.id;

      if (targetAccountId == null || targetAccountId.isEmpty) {
        throw Exception(
          'No account found for item "${item.description}". Please select a posting account or configure a default expense account.',
        );
      }

      final account = await _findAccountById(companyId, targetAccountId);
      debugPrint(
        'AccountingPostingService: Preflight bill item "${item.description}" -> '
        '${account.accountName} (${account.id}) | isGroup: ${account.isGroup} | '
        'allowPosting: ${account.allowPosting} | isActive: ${account.isActive}',
      );
      _validatePostable(account, account.accountName);
    }
  }

  /// Re-fetches an account document within a transaction to ensure strong consistency and locking.
  Future<AccountModel> _getAccountInTx(
    Transaction tx,
    String companyId,
    String accountId,
  ) async {
    final docRef = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('chartOfAccounts')
        .doc(accountId);
    debugPrint('TX_READ (Account): ${docRef.path}');
    final doc = await tx.get(docRef);
    if (!doc.exists) {
      debugPrint('TX_READ (Account): ${docRef.path} | exists: false');
      throw Exception('Account ID $accountId not found during transaction.');
    }

    final data = doc.data()!;
    debugPrint(
      'TX_READ (Account): ${docRef.path} | exists: true | '
      'name: ${data['accountName']} | currentBalance: ${data['currentBalance']} '
      '(${data['currentBalance']?.runtimeType}) | isGroup: ${data['isGroup']} | '
      'allowPosting: ${data['allowPosting']} | isActive: ${data['isActive']} | '
      'companyId: ${data['companyId']}',
    );

    // PRE-POSTING VALIDATION: Ensure currentBalance exists and is numeric
    if (data['currentBalance'] == null || data['currentBalance'] is! num) {
      throw Exception(
        'Account balance migration required for "${data['accountName']}" (${data['accountCode']}). '
        'Please initialize balances before posting.',
      );
    }

    if (data['companyId'] == null) data['companyId'] = companyId;
    return AccountModel.fromMap(data, doc.id);
  }

  JournalLineModel _createLine(
    AccountModel account,
    double debit,
    double credit,
    String memo, {
    String? jobId,
    String? jobNumber,
    String? jobName,
  }) {
    return JournalLineModel(
      accountId: account.id,
      accountName: account.accountName,
      accountCode: account.accountCode,
      debit: debit,
      credit: credit,
      memo: memo,
      jobId: jobId,
      jobNumber: jobNumber,
      jobName: jobName,
    );
  }

  void _updateAccountBalanceTx(
    Transaction tx,
    AccountModel account,
    double debit,
    double credit,
    AppUser user,
  ) {
    bool isDebitNormal = account.normalBalance == BalanceType.debit;
    double movement = isDebitNormal ? (debit - credit) : (credit - debit);

    _updateAccountMovementTx(tx, account, movement, user, 'Account');
  }

  void _updateAccountMovementTx(
    Transaction tx,
    AccountModel account,
    double movement,
    AppUser user,
    String label,
  ) {
    if (account.companyId.isEmpty) {
      debugPrint(
        'WARNING: Account ${account.accountName} (${account.id}) has no companyId. Update might fail.',
      );
    }

    final currentBalance = account.currentBalance;
    final newBalance = currentBalance + movement;
    final docPath =
        'companies/${account.companyId}/chartOfAccounts/${account.id}';
    final updateData = {'currentBalance': newBalance};
    debugPrint(
      'TX_WRITE ($label): $docPath | currentBalanceBefore: $currentBalance | '
      'delta: $movement | currentBalanceAfter: $newBalance | '
      'readInTransaction: true | Fields: $updateData | UserRole: ${user.role.name}',
    );

    tx.update(
      _firestore
          .collection('companies')
          .doc(account.companyId)
          .collection('chartOfAccounts')
          .doc(account.id),
      updateData,
    );
  }

  Future<void> _updateBankBalanceTx(
    Transaction tx,
    DocumentReference bankRef,
    double debit,
    double credit,
    AppUser user,
  ) async {
    final bankSnap = await tx.get(bankRef);
    if (!bankSnap.exists) {
      throw Exception(
        'Bank account ${bankRef.id} not found during transaction.',
      );
    }
    final bankData = bankSnap.data() as Map<String, dynamic>;
    final currentBalance =
        (bankData['currentBalance'] as num?)?.toDouble() ?? 0.0;
    final movement = debit - credit;
    final newBalance = currentBalance + movement;
    final updateData = {'currentBalance': newBalance};
    debugPrint(
      'TX_WRITE (Bank): ${bankRef.path} | currentBalanceBefore: $currentBalance | '
      'delta: $movement | currentBalanceAfter: $newBalance | '
      'readInTransaction: true | Fields: $updateData | UserRole: ${user.role.name}',
    );
    tx.update(bankRef, updateData);
  }

  void _validateBalancing(List<JournalLineModel> lines) {
    double totalDebit = double.parse(
      lines.fold(0.0, (acc, line) => acc + line.debit).toStringAsFixed(4),
    );
    double totalCredit = double.parse(
      lines.fold(0.0, (acc, line) => acc + line.credit).toStringAsFixed(4),
    );
    if ((totalDebit - totalCredit).abs() > 0.001) {
      throw Exception(
        'Journal entry is not balanced. Total Dr: $totalDebit, Total Cr: $totalCredit',
      );
    }
  }

  void _validatePostable(AccountModel account, String displayName) {
    if (account.isGroup) {
      throw Exception(
        'Account "$displayName" is a Group account and cannot be used for posting.',
      );
    }
    if (!account.allowPosting) {
      throw Exception('Account "$displayName" does not allow direct posting.');
    }
    if (!account.isActive) {
      throw Exception('Account "$displayName" is currently inactive.');
    }
  }
}
