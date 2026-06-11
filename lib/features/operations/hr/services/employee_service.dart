import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/operations/hr/models/employee_model.dart';
import 'package:ledgixerp/features/operations/hr/models/department_model.dart';
import 'package:ledgixerp/features/operations/hr/models/designation_model.dart';
import 'package:ledgixerp/features/settings/services/financial_settings_service.dart';

class EmployeeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _settingsService = FinancialSettingsService();

  CollectionReference _getEmployeesRef(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('employees');
  }

  CollectionReference _getDepartmentsRef(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('departments');
  }

  CollectionReference _getDesignationsRef(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('designations');
  }

  Future<String> generateEmployeeNumber(String companyId) async {
    return await _settingsService.previewNextDocumentNumber(companyId, 'employee');
  }

  Future<void> createEmployee(EmployeeModel employee) async {
    await _firestore.runTransaction((transaction) async {
      final employeeNumber = await _settingsService.getNextDocumentNumberAndIncrement(
        employee.companyId,
        'employee',
        transaction: transaction,
      );

      final collectionRef = _getEmployeesRef(employee.companyId);
      final employeeRef = employee.id.isEmpty
          ? collectionRef.doc()
          : collectionRef.doc(employee.id);

      final employeeToSave = employee.copyWith(
        id: employeeRef.id,
        employeeNumber: employeeNumber,
      );

      transaction.set(employeeRef, employeeToSave.toMap());
    });
  }

  Future<void> updateEmployee(EmployeeModel employee) async {
    await _getEmployeesRef(employee.companyId).doc(employee.id).update(employee.toMap());
  }

  Future<void> deleteEmployee(String companyId, String employeeId) async {
    await _getEmployeesRef(companyId).doc(employeeId).delete();
  }

  Stream<List<EmployeeModel>> getEmployees(String companyId) {
    return _getEmployeesRef(companyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => EmployeeModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<DepartmentModel>> getDepartments(String companyId) {
    return _getDepartmentsRef(companyId)
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => DepartmentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<void> addDepartment(String companyId, String name) async {
    final doc = _getDepartmentsRef(companyId).doc();
    final dept = DepartmentModel(id: doc.id, companyId: companyId, name: name);
    await doc.set(dept.toMap());
  }

  Stream<List<DesignationModel>> getDesignations(String companyId) {
    return _getDesignationsRef(companyId)
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => DesignationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<void> addDesignation(String companyId, String name) async {
    final doc = _getDesignationsRef(companyId).doc();
    final desig = DesignationModel(id: doc.id, companyId: companyId, name: name);
    await doc.set(desig.toMap());
  }
}
