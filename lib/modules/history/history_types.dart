enum HistoryKind { delivered, rejected, profit, dues, debt }

extension HistoryKindX on HistoryKind {
  String get label {
    switch (this) {
      case HistoryKind.delivered:
        return 'سجل تم التسليم';
      case HistoryKind.rejected:
        return 'سجل تم الرفض';
      case HistoryKind.profit:
        return 'سجل الربح';
      case HistoryKind.dues:
        return 'سجل المستحقات';
      case HistoryKind.debt:
        return 'سجل المديونية';
    }
  }

  String get apiType {
    switch (this) {
      case HistoryKind.delivered:
        return 'delivered';
      case HistoryKind.rejected:
        return 'rejected';
      case HistoryKind.profit:
        return 'profit';
      case HistoryKind.dues:
        return 'dues';
      case HistoryKind.debt:
        return 'debt';
    }
  }
}
