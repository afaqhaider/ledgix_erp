import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _getTaskRef(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('tasks');
  }

  Stream<List<TaskModel>> getTasks(String companyId) {
    return _getTaskRef(companyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TaskModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> addTask(TaskModel task) async {
    final docRef = _getTaskRef(task.companyId).doc();
    await docRef.set(task.toMap()..['id'] = docRef.id);
  }

  Future<void> updateTask(TaskModel task) async {
    await _getTaskRef(task.companyId).doc(task.id).update(task.toMap());
  }

  Future<void> deleteTask(String companyId, String taskId) async {
    await _getTaskRef(companyId).doc(taskId).delete();
  }
}
