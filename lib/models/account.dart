class Account {
  final int id;
  final int userId;
  final String name;
  final double balance;
  final String type;

  Account({
    required this.id,
    required this.userId,
    required this.name,
    required this.balance,
    required this.type,
  });

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      userId: map['user_id'],
      name: map['name'],
      balance: map['balance'],
      type: map['type'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'balance': balance,
      'type': type,
    };
  }
}
