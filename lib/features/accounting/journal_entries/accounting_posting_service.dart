import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/accounting/journal/models/journal_entry_model.dart';
import 'package:ledgixerp/features/accounting/journal/models/journal_line_model.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_model.dart';
import 'package:ledgixerp/features/banking/models/bank_account_model.dart';
import 'package:ledgixerp/features/invoices/models/invoice_model.dart';
import 'package:ledgixerp/features/crm/customer_payments/models/customer_payment_model.dart';
import 'package:ledgixerp/features/supplier_payments/models/supplier_payment_model.dart';
import 'package:ledgixerp/core/audit/audit_service.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/features/settings/services/financial_settings_service.dart';

class AccountingPostingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _auditService = AuditService();
  final _settingsService = FinancialSettingsService();

  Future<void> postSalesInvoice(
    String companyId,
    InvoiceModel invoice,
    AppUser user,
  ) async {
    final String userId = user.uid;
    if (invoice.isPosted) throw 'Invoice is already posted';

    if (await _settingsService.isPeriodLocked(companyId, invoice.invoiceDate)) {
      throw 'Accounting period for this invoice date is locked.';
    }

    final arAccount = await _findAccount(
      companyId,
      'Accounts Receivable',
      AccountType.asset,
    );
    final salesAccount = await _findAccount(
      companyId,
      'Sales Revenue',
      AccountType.income,
    );
    final vatAccount = invoice.vatAmount > 0
        ? await _findAccount(companyId, 'VAT Payable', AccountType.liability)
        : null;

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

    final batch = _firestore.batch();
    final jeRef = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('journalEntries')
        .doc();
    batch.set(jeRef, journalEntry.toMap()..['id'] = jeRef.id);

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
    if (payment.isPosted) throw 'Payment is already posted';

    if (await _settingsService.isPeriodLocked(companyId, payment.paymentDate)) {
      throw 'Accounting period for this payment date is locked.';
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
        'Bank',
        AccountType.asset,
      );
    }

    final arAccount = await _findAccount(
      companyId,
      'Accounts Receivable',
      AccountType.asset,
    );

    final List<JournalLineModel> lines = [
      JournalLineModel(
        accountId: bankChartAccount.id,
        accountName: bankChartAccount.accountName,
        accountCode: bankChartAccount.accountCode,
        debit: payment.amount,
        credit: 0,
        memo: 'Customer Payment ${payment.paymentNumber}',
      ),
      JournalLineModel(
        accountId: arAccount.id,
        accountName: arAccount.accountName,
        accountCode: arAccount.accountCode,
        debit: 0,
        credit: payment.amount,
        memo: 'Customer Payment ${payment.paymentNumber}',
      ),
    ];

    final journalEntry = JournalEntryModel(
      id: '',
      companyId: companyId,
      date: payment.paymentDate,
      reference: payment.paymentNumber,
      description: 'Posting Customer Payment ${payment.paymentNumber}',
      lines: lines,
      status: JournalStatus.posted,
      createdBy: userId,
      createdAt: DateTime.now(),
      sourceType: 'customer_payment',
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
    batch.set(jeRef, journalEntry.toMap()..['id'] = jeRef.id);

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
      description: 'Posted Customer Payment ${payment.paymentNumber}',
      newValues: {'isPosted': true},
    );
  }

  Future<void> postSupplierPayment(
    String companyId,
    SupplierPaymentModel payment,
    AppUser user,
  ) async {
    final String userId = user.uid;
    if (payment.isPosted) throw 'Payment is already posted';

    if (await _settingsService.isPeriodLocked(companyId, payment.paymentDate)) {
      throw 'Accounting period for this payment date is locked.';
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
        'Bank',
        AccountType.asset,
      );
    }

    final apAccount = await _findAccount(
      companyId,
      'Accounts Payable',
      AccountType.liability,
    );

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
    batch.set(jeRef, journalEntry.toMap()..['id'] = jeRef.id);

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
      throw 'Required account "$name" not found in Chart of Accounts. Please create it first.';
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
      throw 'Chart of Account not found';
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
      throw 'Bank Account not found';
    }

    return BankAccountModel.fromMap(doc.data()!, doc.id);
  }

  void _validateBalancing(List<JournalLineModel> lines) {
    double totalDebit = lines.fold(0.0, (acc, line) => acc + line.debit);
    double totalCredit = lines.fold(0.0, (acc, line) => acc + line.credit);

    if ((totalDebit - totalCredit).abs() > 0.001) {
      throw 'Journal entry is not balanced. Dr: $totalDebit, Cr: $totalCredit';
    }
  }
}
