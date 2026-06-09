import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _getNotificationsRef(String companyId, String userId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('members')
        .doc(userId)
        .collection('notifications');
  }

  Stream<List<NotificationModel>> getNotifications(
    String companyId,
    String userId,
  ) {
    return _getNotificationsRef(companyId, userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => NotificationModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  Stream<int> getUnreadCount(String companyId, String userId) {
    return _getNotificationsRef(companyId, userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markAsRead(
    String companyId,
    String userId,
    String notificationId,
  ) async {
    await _getNotificationsRef(
      companyId,
      userId,
    ).doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllAsRead(String companyId, String userId) async {
    final snapshot = await _getNotificationsRef(
      companyId,
      userId,
    ).where('isRead', isEqualTo: false).get();
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> sendNotification({
    required String userId,
    required String companyId,
    required String title,
    required String message,
    required NotificationType type,
    String? relatedDocId,
    String? relatedDocType,
  }) async {
    final notification = NotificationModel(
      id: '',
      userId: userId,
      companyId: companyId,
      title: title,
      message: message,
      type: type,
      relatedDocId: relatedDocId,
      relatedDocType: relatedDocType,
      createdAt: DateTime.now(),
    );

    await _getNotificationsRef(companyId, userId).add(notification.toMap());
  }
}
