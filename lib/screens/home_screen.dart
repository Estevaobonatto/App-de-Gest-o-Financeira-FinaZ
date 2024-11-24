import 'dart:async'; // Adicione esta linha no início do arquivo
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../services/database_service.dart';
import '../widgets/expense_chart.dart';
import '../widgets/category_spending_chart.dart';
import '../widgets/account_balance_card.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';
import 'accounts_screen.dart';
import 'categories_screen.dart';
import '../services/event_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeContent(),
          AccountsScreen(),
          CategoriesScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance),
            label: 'Contas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categorias',
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget? _buildFloatingActionButton() {
    switch (_selectedIndex) {
      case 0:
        return FloatingActionButton(
          onPressed: () async {
            final result =
                await Navigator.pushNamed(context, '/add-transaction');
            if (result == true && mounted) {
              setState(() {});
            }
          },
          child: Icon(Icons.add),
        );
      case 1:
        return FloatingActionButton(
          onPressed: () {
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (context) => _showAddAccountDialog(context),
              ).then((_) => setState(() {}));
            }
          },
          child: Icon(Icons.add),
        );
      case 2:
        return FloatingActionButton(
          onPressed: () {
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (context) => CategoryDialog(),
              ).then((_) => setState(() {}));
            }
          },
          child: Icon(Icons.add),
        );
      default:
        return null;
    }
  }

  Widget _showAddAccountDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    String accountType = 'checking';

    return AlertDialog(
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
                keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                  DropdownMenuItem(value: 'savings', child: Text('Poupança')),
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
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              try {
                final authService = AuthService();
                final userId = await authService.getCurrentUserId();
                if (userId != null) {
                  final dbService = DatabaseService();
                  await dbService.addAccount(
                    userId,
                    nameController.text,
                    double.parse(balanceController.text.replaceAll(',', '.')),
                    accountType,
                  );
                  Navigator.pop(context, true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Conta criada com sucesso!')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao criar conta: $e')),
                );
              }
            }
          },
          child: Text('Adicionar'),
        ),
      ],
    );
  }
}

// Diálogo para adicionar categoria
class CategoryDialog extends StatefulWidget {
  @override
  _CategoryDialogState createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedType = 'expense';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Nova Categoria'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nome da Categoria',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, insira um nome';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: 'Tipo',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'expense', child: Text('Despesa')),
                DropdownMenuItem(value: 'income', child: Text('Receita')),
              ],
              onChanged: (value) {
                setState(() => _selectedType = value!);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _handleSubmit,
          child: Text('Adicionar'),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      try {
        final authService = AuthService();
        final userId = await authService.getCurrentUserId();
        if (userId != null) {
          final dbService = DatabaseService();
          await dbService.addCategory(
            userId,
            _nameController.text,
            0, // valor padrão para icon_code
            '#000000', // valor padrão para color
            _selectedType,
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar categoria: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}

class HomeContent extends StatefulWidget {
  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final DatabaseService _db = DatabaseService();
  final AuthService _auth = AuthService();
  List<Transaction> _transactions = [];
  List<Account> _accounts = [];
  bool _isLoading = true;
  String? _error;
  late StreamSubscription _databaseSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _databaseSubscription = EventService().onDatabaseChanged.listen((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _databaseSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = await _auth.getCurrentUserId();
      if (userId == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final transactions = await _db.getTransactions(userId);
      final accounts = await _db.getAccounts(userId);

      setState(() {
        _transactions = transactions;
        _accounts = accounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar dados: $e';
        _isLoading = false;
      });
    }
  }

  List<FlSpot> _getExpenseSpots() {
    final Map<int, double> dailyExpenses = {};

    for (var transaction in _transactions) {
      if (transaction.type == 'expense') {
        final day = transaction.date.day;
        dailyExpenses[day] = (dailyExpenses[day] ?? 0) + transaction.amount;
      }
    }

    return dailyExpenses.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  Future<List<Map<String, dynamic>>> _getCategoryIncome() async {
    final Map<int, double> categoryIncomes = {};
    final Map<int, String> categoryNames = {};

    // Primeiro, vamos buscar os nomes das categorias
    final userId = await _auth.getCurrentUserId();
    if (userId != null) {
      final categories = await _db.getCategories(userId);
      for (var category in categories) {
        categoryNames[category['id'] as int] = category['name'] as String;
      }
    }

    // Calcular receitas por categoria
    for (var transaction in _transactions) {
      if (transaction.type == 'income') {
        categoryIncomes[transaction.categoryId] =
            (categoryIncomes[transaction.categoryId] ?? 0) + transaction.amount;
      }
    }

    // Criar lista de resultados
    final List<Map<String, dynamic>> result = [];
    categoryIncomes.forEach((categoryId, amount) {
      result.add({
        'name': categoryNames[categoryId] ?? 'Categoria Desconhecida',
        'amount': amount,
        'percentage': (amount / _getTotalIncome() * 100),
      });
    });

    // Ordenar por valor (maior para menor)
    result.sort(
        (a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
    return result;
  }

  double _getTotalIncome() {
    return _transactions
        .where((t) => t.type == 'income')
        .fold(0, (sum, t) => sum + t.amount);
  }

  double _getTotalBalance() {
    return _accounts.fold(0, (sum, account) => sum + account.balance);
  }

  Future<List<Map<String, dynamic>>> _getMonthlyExpenses() async {
    final Map<int, double> categoryExpenses = {};
    final Map<int, String> categoryNames = {};

    final userId = await _auth.getCurrentUserId();
    if (userId != null) {
      final categories = await _db.getCategories(userId);
      for (var category in categories) {
        categoryNames[category['id'] as int] = category['name'] as String;
      }
    }

    for (var transaction in _transactions) {
      if (transaction.type == 'expense' &&
          transaction.date.month == DateTime.now().month &&
          transaction.date.year == DateTime.now().year) {
        categoryExpenses[transaction.categoryId] =
            (categoryExpenses[transaction.categoryId] ?? 0) +
                transaction.amount;
      }
    }

    final List<Map<String, dynamic>> result = [];
    categoryExpenses.forEach((categoryId, amount) {
      result.add({
        'name': categoryNames[categoryId] ?? 'Categoria Desconhecida',
        'amount': amount,
        'percentage': (amount / _getTotalMonthlyExpenses() * 100),
      });
    });

    result.sort(
        (a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
    return result;
  }

  double _getTotalMonthlyExpenses() {
    return _transactions
        .where((t) =>
            t.type == 'expense' &&
            t.date.month == DateTime.now().month &&
            t.date.year == DateTime.now().year)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double _getTotalMonthlyIncome() {
    return _transactions
        .where((t) =>
            t.type == 'income' &&
            t.date.month == DateTime.now().month &&
            t.date.year == DateTime.now().year)
        .fold(0, (sum, t) => sum + t.amount);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _loadData,
              child: Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saldo Total',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Text(
              'R\$ ${_getTotalBalance().toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: _getTotalBalance() >= 0
                    ? Colors.green
                    : Theme.of(context).colorScheme.error,
              ),
            ),
            SizedBox(height: 24),

            // Resumo do Mês
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumo do Mês',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Receitas'),
                            Text(
                              'R\$ ${_getTotalMonthlyIncome().toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Despesas'),
                            Text(
                              'R\$ ${_getTotalMonthlyExpenses().toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            Text(
              'Suas Contas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _accounts.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 200,
                    margin: EdgeInsets.only(right: 16),
                    child: AccountBalanceCard(account: _accounts[index]),
                  );
                },
              ),
            ),
            SizedBox(height: 24),

            Text(
              'Despesas do Mês por Categoria',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _getMonthlyExpenses(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final categories = snapshot.data!;
                if (categories.isEmpty) {
                  return Center(
                    child: Text('Nenhuma despesa registrada este mês'),
                  );
                }

                return Column(
                  children: categories.map((category) {
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(
                          category['name'],
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          '${category['percentage'].toStringAsFixed(1)}% do total',
                          style: TextStyle(color: Colors.white70),
                        ),
                        trailing: Text(
                          'R\$ ${category['amount'].toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red[300],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            SizedBox(height: 24),

            Text(
              'Receitas do Mês por Categoria',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _getCategoryIncome(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final categories = snapshot.data!;
                if (categories.isEmpty) {
                  return Center(
                    child: Text('Nenhuma receita registrada este mês'),
                  );
                }

                return Column(
                  children: categories.map((category) {
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(
                          category['name'],
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          '${category['percentage'].toStringAsFixed(1)}% do total',
                          style: TextStyle(color: Colors.white70),
                        ),
                        trailing: Text(
                          'R\$ ${category['amount'].toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[300],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
