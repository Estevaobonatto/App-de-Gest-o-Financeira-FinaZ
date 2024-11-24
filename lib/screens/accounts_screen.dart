import 'dart:async'; // Adicione esta linha no início do arquivo
import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';

class AccountsScreen extends StatefulWidget {
  @override
  _AccountsScreenState createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final DatabaseService _db = DatabaseService();
  final AuthService _auth = AuthService();
  List<Account> _accounts = [];
  bool _isLoading = true;
  late StreamSubscription _databaseSubscription;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    _databaseSubscription = EventService().onDatabaseChanged.listen((event) {
      if (event.contains('account') || event.contains('transaction')) {
        _loadAccounts();
      }
    });
  }

  @override
  void dispose() {
    _databaseSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      final userId = await _auth.getCurrentUserId();
      if (userId != null) {
        final accounts = await _db.getAccounts(userId);
        if (mounted) {
          setState(() {
            _accounts = accounts;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar contas: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showAddAccountDialog() async {
    final _formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    String accountType = 'checking';

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Nova Conta'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nome da Conta',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira um nome';
                      }
                      return null;
                    },
                    autofocus: true,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: balanceController,
                    decoration: InputDecoration(
                      labelText: 'Saldo Inicial',
                      border: OutlineInputBorder(),
                      prefixText: 'R\$ ',
                    ),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira um valor';
                      }
                      if (double.tryParse(value.replaceAll(',', '.')) == null) {
                        return 'Por favor, insira um valor válido';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: accountType,
                    decoration: InputDecoration(
                      labelText: 'Tipo de Conta',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                          value: 'checking', child: Text('Conta Corrente')),
                      DropdownMenuItem(
                          value: 'savings', child: Text('Poupança')),
                      DropdownMenuItem(
                          value: 'investment', child: Text('Investimento')),
                      DropdownMenuItem(
                          value: 'credit', child: Text('Cartão de Crédito')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        accountType = value;
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final userId = await _auth.getCurrentUserId();
                  if (userId != null) {
                    await _db.addAccount(
                      userId,
                      nameController.text,
                      double.parse(balanceController.text.replaceAll(',', '.')),
                      accountType,
                    );
                    Navigator.pop(context, true);
                  }
                }
              },
              child: Text('Adicionar'),
            ),
          ],
        ),
      );

      if (result == true) {
        await _loadAccounts(); // Força o recarregamento imediato
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Conta criada com sucesso!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar conta: $e')),
        );
      }
    }
  }

  Future<void> _deleteAccount(int accountId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar exclusão'),
        content: Text(
            'Deseja realmente excluir esta conta? Todas as transações associadas também serão excluídas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _db.deleteAccount(accountId);
        await _loadAccounts(); // Recarrega a lista
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Conta excluída com sucesso!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir conta: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Minhas Contas'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAccounts,
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _accounts.isEmpty
                ? Center(
                    child: Text(
                      'Nenhuma conta cadastrada',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    physics: AlwaysScrollableScrollPhysics(),
                    itemCount: _accounts.length,
                    itemBuilder: (context, index) {
                      final account = _accounts[index];
                      return Card(
                        margin:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(account.name),
                          subtitle: Text(_getAccountTypeText(account.type)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'R\$ ${account.balance.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: account.balance >= 0
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 16),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => _deleteAccount(account.id),
                                color: Colors.red,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAccountDialog,
        child: Icon(Icons.add),
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
