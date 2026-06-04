enum DocumentStatus {
  draft,
  pendingApproval,
  approved,
  posted,
  cancelled;

  String get label {
    switch (this) {
      case DocumentStatus.draft:
        return 'Draft';
      case DocumentStatus.pendingApproval:
        return 'Pending Approval';
      case DocumentStatus.approved:
        return 'Approved';
      case DocumentStatus.posted:
        return 'Posted';
      case DocumentStatus.cancelled:
        return 'Cancelled';
    }
  }
}
