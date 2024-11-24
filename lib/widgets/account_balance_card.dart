import 'package:flutter/material.dart';
import '../models/account.dart';

class AccountBalanceCard extends StatelessWidget {
  final Account account;

  const AccountBalanceCard({required this.account});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              account.name,
              style: Theme.of(context).textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Text(
              'R\$ ${account.balance.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: account.balance >= 0
                    ? Colors.green
                    : Theme.of(context).colorScheme.error,
              ),
            ),
            SizedBox(height: 4),
            Text(
              _getAccountTypeText(account.type),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _getAccountTypeText(String type) {
    switch (type) {
      case 'checking':
        return 'Conta Corrente';
      case 'savings':
        return 'Poupança';
      case 'investment':
        return 'Investimento';
      case 'credit':
        return 'Cartão de Crédito';
      default:
        return type;
    }
  }
}
