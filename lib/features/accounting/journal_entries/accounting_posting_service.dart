import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/accounting/journal/models/journal_entry_model.dart';
import 'package:ledgixerp/features/accounting/journal/models/journal_line_model.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_model.dart';
import 'package:ledgixerp/features/banking/models/bank_account_model.dart';
import 'package:ledgixerp/features/invoices/models/invoice_model.dart';
import 'package:ledgixerp/features/crm/customer_payments/models/customer_payment_model.dart';
import 'package:ledgixerp/features/supplier_payments/models/supplier_payment_model.dart';
import 'package:ledgixerp/features/suppliers/models/bill_model.dart';
import 'package:ledgixerp/core/audit/audit_service.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/features/settings/services/financial_settings_service.dart';
import 'package:ledgixerp/features/inventory/services/inventory_service.dart';
import '../../inventory/models/inventory_models.dart';

class AccountingPostingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _auditService = AuditService();
  final _settingsService = FinancialSettingsService();
  final _inventoryService = InventoryService();

  Future<void> postSalesInvoice(
    String companyId,
    InvoiceModel invoice,
    AppUser user,
  ) async {
    final String userId = user.uid;
    if (invoice.isPosted) throw Exception('Invoice is already posted');

    if (await _settingsService.isPeriodLocked(companyId, invoice.invoiceDate)) {
      throw Exception('Accounting period for this invoice date is locked.');
    }

    final arAccount = await _findAccount(
      companyId,
      'Accounts Receivable',
      AccountType.asset,
    );
    _validatePostable(arAccount);

    final salesAccount = await _findAccount(
      companyId,
      'Sales Revenue',
      AccountType.income,
    );
    _validatePostable(salesAccount);

    final vatAccount = invoice.vatAmount > 0
        ? await _findAccount(companyId, 'VAT Payable', AccountType.liability)
        : null;
    if (vatAccount != null) _validatePostable(vatAccount);

    final List<JournalLineModel> lines = [];

    lines.add(
      JournalLineModel(
        accountId: arAccount.id,
        accountName: arAccount.accountName,
        accountCode: arAccount.accountCode,
        debit: invoice.totalAmount,
        credit: 0,
        memo: 'Sales Invoice ${invoice.invoiceNumber}',
      ),
    );

    lines.add(
      JournalLineModel(
        accountId: salesAccount.id,
        accountName: salesAccount.accountName,
        accountCode: salesAccount.accountCode,
        debit: 0,
        credit: invoice.subtotal,
        memo: 'Sales Invoice ${invoice.invoiceNumber}',
      ),
    );

    if (vatAccount != null && invoice.vatAmount > 0) {
      lines.add(
        JournalLineModel(
          accountId: vatAccount.id,
          accountName: vatAccount.accountName,
          accountCode: vatAccount.accountCode,
          debit: 0,
          credit: invoice.vatAmount,
          memo: 'VAT on ${invoice.invoiceNumber}',
        ),
      );
    }

    // Inventory & COGS logic
    double totalCogs = 0.0;
    final batch = _firestore.batch();

    for (var item in invoice.items) {
      if (item.productId != null && item.productId!.isNotEmpty) {
        final product = await _inventoryService.getItem(
          companyId,
          item.productId!,
        );
        if (product.itemType == InventoryItemType.stock) {
          final itemCogs = await _inventoryService.recordSale(
            companyId: companyId,
            productId: item.productId!,
            quantity: item.quantity,
            batch: batch,
          );
          totalCogs += itemCogs;
        }
      }
    }

    if (totalCogs > 0) {
      final cogsAccount = await _findAccount(
        companyId,
        'Cost of Goods Sold',
        AccountType.costOfSales,
      );
      final inventoryAccount = await _findAccount(
        companyId,
        'Inventory Asset',
        AccountType.asset,
      );

      _validatePostable(cogsAccount);
      _validatePostable(inventoryAccount);

      lines.add(
        JournalLineModel(
          accountId: cogsAccount.id,
          accountName: cogsAccount.accountName,
          accountCode: cogsAccount.accountCode,
          debit: totalCogs,
          credit: 0,
          memo: 'COGS for Invoice ${invoice.invoiceNumber}',
        ),
      );

      lines.add(
        JournalLineModel(
          accountId: inventoryAccount.id,
          accountName: inventoryAccount.accountName,
          accountCode: inventoryAccount.accountCode,
          debit: 0,
          credit: totalCogs,
          memo: 'Inventory reduction for Invoice ${invoice.invoiceNumber}',
        ),
      );
    }

    final journalEntry = JournalEntryModel(
      id: '',
      companyId: companyId,
      date: invoice.invoiceDate,
      reference: invoice.invoiceNumber,
      description: 'Posting Sales Invoice ${invoice.invoiceNumber}',
      lines: lines,
      status: JournalStatus.posted,
      createdBy: userId,
      createdAt: DateTime.now(),
      sourceType: 'sales_invoice',
      sourceId: invoice.id,
      sourceNumber: invoice.invoiceNumber,
    );

    _validateBalancing(lines);

    // final batch = _firestore.batch(); // Already created above
    final jeRef = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('journalEntries')
        .doc();

    final entryData = journalEntry.toMap();
    entryData['id'] = jeRef.id;
    batch.set(jeRef, entryData);

    final invoiceRef = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('salesInvoices')
        .doc(invoice.id);
    batch.update(invoiceRef, {'isPosted': true, 'journalEntryId': jeRef.id});

    await batch.commit();

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
  }

  Future<void> postCustomerPayment(
    String companyId,
    CustomerPaymentModel payment,
    AppUser user,
  ) async {
    final String userId = user.uid;
    if (payment.isPosted) throw Exception('Payment is already posted');

    if (await _settingsService.isPeriodLocked(companyId, payment.paymentDate)) {
      throw Exception('Accounting period for this payment date is locked.');
    }

    AccountModel bankChartAccount;
    if (payment.bankAccountId != null) {
      final bankAccount = await _findBankAccount(
        companyId,
        payment.bankAccountId!,
      );
      bankChartAccount = await _findAccountById(
        companyId,
        bankAccount.linkedChartAccountId,
      );
    } else {
      bankChartAccount = await _findAccount(
        companyId,
        'Bank Account',
        AccountType.asset,
      );
    }
    _validatePostable(bankChartAccount);

    final arAccount = await _findAccount(
      companyId,
      'Accounts Receivable',
      AccountType.asset,
    );
    _validatePostable(arAccount);

    final List<JournalLineModel> lines = [
      JournalLineModel(
        accountId: bankChartAccount.id,
        accountName: bankChartAccount.accountName,
        accountCode: bankChartAccount.accountCode,
        debit: payment.amount,
        credit: 0,
        memo: 'Receipt ${payment.paymentNumber}',
      ),
      JournalLineModel(
        accountId: arAccount.id,
        accountName: arAccount.accountName,
        accountCode: arAccount.accountCode,
        debit: 0,
        credit: payment.amount,
        memo: 'Receipt ${payment.paymentNumber}',
      ),
    ];

    final journalEntry = JournalEntryModel(
      id: '',
      companyId: companyId,
      date: payment.paymentDate,
      reference: payment.paymentNumber,
      description: 'Posting Receipt ${payment.paymentNumber}',
      lines: lines,
      status: JournalStatus.posted,
      createdBy: userId,
      createdAt: DateTime.now(),
      sourceType: 'receipt',
      sourceId: payment.id,
      sourceNumber: payment.paymentNumber,
    );

    _validateBalancing(lines);

    final batch = _firestore.batch();
    final jeRef = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('journalEntries')
        .doc();

    final entryData = journalEntry.toMap();
    entryData['id'] = jeRef.id;
    batch.set(jeRef, entryData);

    final paymentRef = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('customerPayments')
        .doc(payment.id);
    batch.update(paymentRef, {'isPosted': true, 'journalEntryId': jeRef.id});

    await batch.commit();

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
  }

  Future<void> postSupplierPayment(
    String companyId,
    SupplierPaymentModel payment,
    AppUser user,
  ) async {
    final String userId = user.uid;
    if (payment.isPosted) throw Exception('Payment is already posted');

    if (await _settingsService.isPeriodLocked(companyId, payment.paymentDate)) {
      throw Exception('Accounting period for this payment date is locked.');
    }

    AccountModel bankChartAccount;
    if (payment.bankAccountId != null) {
      final bankAccount = await _findBankAccount(
        companyId,
        payment.bankAccountId!,
      );
      bankChartAccount = await _findAccountById(
        companyId,
        bankAccount.linkedChartAccountId,
      );
    } else {
      bankChartAccount = await _findAccount(
        companyId,
        'Bank Account',
        AccountType.asset,
      );
    }
    _validatePostable(bankChartAccount);

    final apAccount = await _findAccount(
      companyId,
      'Accounts Payable',
      AccountType.liability,
    );
    _validatePostable(apAccount);

    final List<JournalLineModel> lines = [
      JournalLineModel(
        accountId: apAccount.id,
        accountName: apAccount.accountName,
        accountCode: apAccount.accountCode,
        debit: payment.amount,
        credit: 0,
        memo: 'Supplier Payment ${payment.paymentNumber}',
      ),
      JournalLineModel(
        accountId: bankChartAccount.id,
        accountName: bankChartAccount.accountName,
        accountCode: bankChartAccount.accountCode,
        debit: 0,
        credit: payment.amount,
        memo: 'Supplier Payment ${payment.paymentNumber}',
      ),
    ];

    final journalEntry = JournalEntryModel(
      id: '',
      companyId: companyId,
      date: payment.paymentDate,
      reference: payment.paymentNumber,
      description: 'Posting Supplier Payment ${payment.paymentNumber}',
      lines: lines,
      status: JournalStatus.posted,
      createdBy: userId,
      createdAt: DateTime.now(),
      sourceType: 'supplier_payment',
      sourceId: payment.id,
      sourceNumber: payment.paymentNumber,
    );

    _validateBalancing(lines);

    final batch = _firestore.batch();
    final jeRef = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('journalEntries')
        .doc();

    final entryData = journalEntry.toMap();
    entryData['id'] = jeRef.id;
    batch.set(jeRef, entryData);

    final paymentRef = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('supplierPayments')
        .doc(payment.id);
    batch.update(paymentRef, {'isPosted': true, 'journalEntryId': jeRef.id});

    await batch.commit();

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
  }

  Future<void> postSupplierBill(
    String companyId,
    BillModel bill,
    AppUser user,
  ) async {
    final String userId = user.uid;
    if (bill.isPosted) throw Exception('Bill is already posted');

    if (await _settingsService.isPeriodLocked(companyId, bill.billDate)) {
      throw Exception('Accounting period for this bill date is locked.');
    }

    final apAccount = await _findAccount(
      companyId,
      'Accounts Payable',
      AccountType.liability,
    );
    _validatePostable(apAccount);

    final expenseAccount = await _findAccount(
      companyId,
      'Expenses',
      AccountType.expense,
    );
    _validatePostable(expenseAccount);

    final inventoryAccount = await _findAccount(
      companyId,
      'Inventory Asset',
      AccountType.asset,
    );
    _validatePostable(inventoryAccount);

    final vatAccount = bill.vatAmount > 0
        ? await _findAccount(companyId, 'VAT Payable', AccountType.liability)
        : null;
    if (vatAccount != null) _validatePostable(vatAccount);

    final List<JournalLineModel> lines = [];

    // AP (Credit)
    lines.add(
      JournalLineModel(
        accountId: apAccount.id,
        accountName: apAccount.accountName,
        accountCode: apAccount.accountCode,
        debit: 0,
        credit: bill.totalAmount,
        memo: 'Vendor Bill ${bill.billNumber}',
      ),
    );

    double inventorySubtotal = 0;
    double expenseSubtotal = 0;
    final batch = _firestore.batch();

    for (var item in bill.items) {
      if (item.productId != null && item.productId!.isNotEmpty) {
        final product = await _inventoryService.getItem(
          companyId,
          item.productId!,
        );
        if (product.itemType == InventoryItemType.stock) {
          await _inventoryService.recordPurchase(
            companyId: companyId,
            productId: item.productId!,
            quantity: item.quantity,
            unitCost: item.unitPrice,
            purchaseId: bill.id,
            batch: batch,
          );
          inventorySubtotal += item.lineSubtotal;
        } else {
          expenseSubtotal += item.lineSubtotal;
        }
      } else {
        expenseSubtotal += item.lineSubtotal;
      }
    }

    // Inventory Asset (Debit)
    if (inventorySubtotal > 0) {
      lines.add(
        JournalLineModel(
          accountId: inventoryAccount.id,
          accountName: inventoryAccount.accountName,
          accountCode: inventoryAccount.accountCode,
          debit: inventorySubtotal,
          credit: 0,
          memo: 'Inventory purchase on bill ${bill.billNumber}',
        ),
      );
    }

    // Expense (Debit)
    if (expenseSubtotal > 0) {
      lines.add(
        JournalLineModel(
          accountId: expenseAccount.id,
          accountName: expenseAccount.accountName,
          accountCode: expenseAccount.accountCode,
          debit: expenseSubtotal,
          credit: 0,
          memo: 'Expenses on bill ${bill.billNumber}',
        ),
      );
    }

    // VAT (Debit)
    if (vatAccount != null && bill.vatAmount > 0) {
      lines.add(
        JournalLineModel(
          accountId: vatAccount.id,
          accountName: vatAccount.accountName,
          accountCode: vatAccount.accountCode,
          debit: bill.vatAmount,
          credit: 0,
          memo: 'VAT on ${bill.billNumber}',
        ),
      );
    }

    final journalEntry = JournalEntryModel(
      id: '',
      companyId: companyId,
      date: bill.billDate,
      reference: bill.billNumber,
      description: 'Posting Vendor Bill ${bill.billNumber}',
      lines: lines,
      status: JournalStatus.posted,
      createdBy: userId,
      createdAt: DateTime.now(),
      sourceType: 'supplier_bill',
      sourceId: bill.id,
      sourceNumber: bill.billNumber,
    );

    _validateBalancing(lines);

    // final batch = _firestore.batch(); // Already created above
    final jeRef = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('journalEntries')
        .doc();

    final entryData = journalEntry.toMap();
    entryData['id'] = jeRef.id;
    batch.set(jeRef, entryData);

    final billRef = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('supplierBills')
        .doc(bill.id);
    batch.update(billRef, {'isPosted': true, 'journalEntryId': jeRef.id});

    await batch.commit();

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
  }

  Future<AccountModel> _findAccount(
    String companyId,
    String name,
    AccountType fallbackType,
  ) async {
    final snapshot = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('chartOfAccounts')
        .where('accountName', isEqualTo: name)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception(
        'Required account "$name" not found in Chart of Accounts. Please create it first.',
      );
    }

    return AccountModel.fromMap(
      snapshot.docs.first.data(),
      snapshot.docs.first.id,
    );
  }

  Future<AccountModel> _findAccountById(String companyId, String id) async {
    final doc = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('chartOfAccounts')
        .doc(id)
        .get();

    if (!doc.exists) {
      throw Exception('Chart of Account not found');
    }

    return AccountModel.fromMap(doc.data()!, doc.id);
  }

  Future<BankAccountModel> _findBankAccount(String companyId, String id) async {
    final doc = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('bankAccounts')
        .doc(id)
        .get();

    if (!doc.exists) {
      throw Exception('Bank Account not found');
    }

    return BankAccountModel.fromMap(doc.data()!, doc.id);
  }

  void _validateBalancing(List<JournalLineModel> lines) {
    double totalDebit = lines.fold(0.0, (acc, line) => acc + line.debit);
    double totalCredit = lines.fold(0.0, (acc, line) => acc + line.credit);

    if ((totalDebit - totalCredit).abs() > 0.001) {
      throw Exception(
        'Journal entry is not balanced. Dr: $totalDebit, Cr: $totalCredit',
      );
    }
  }

  void _validatePostable(AccountModel account) {
    if (account.isGroup) {
      throw Exception(
        'Account "${account.accountName}" is a group account and cannot be posted to.',
      );
    }
    if (!account.allowPosting) {
      throw Exception(
        'Account "${account.accountName}" does not allow posting.',
      );
    }
    if (!account.isActive) {
      throw Exception('Account "${account.accountName}" is inactive.');
    }
  }
}
