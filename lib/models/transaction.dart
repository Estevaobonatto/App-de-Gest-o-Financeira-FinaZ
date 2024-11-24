class Transaction {
  final int id;
  final int userId;
  final int accountId;
  final String description;
  final double amount;
  final DateTime date;
  final int categoryId;
  final String type;

  Transaction({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.description,
    required this.amount,
    required this.date,
    required this.categoryId,
    required this.type,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      userId: map['user_id'],
      accountId: map['account_id'],
      description: map['description'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      categoryId: map['category_id'],
      type: map['type'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'account_id': accountId,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'category_id': categoryId,
      'type': type,
    };
  }
}
