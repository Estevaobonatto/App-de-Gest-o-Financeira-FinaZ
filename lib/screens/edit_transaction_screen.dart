import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/account.dart';

class EditTransactionScreen extends StatefulWidget {
  final Transaction transaction;

  EditTransactionScreen({required this.transaction});

  @override
  _EditTransactionScreenState createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _type = 'expense';
  int _selectedCategoryId = 1;
  bool _isLoading = false;
  List<Map<String, dynamic>> _categories = [];
  List<Account> _accounts = [];
  int _selectedAccountId = 1;

  @override
  void initState() {
    super.initState();
    // Inicializa os campos com os dados da transação
    _descriptionController.text = widget.transaction.description;
    _amountController.text = widget.transaction.amount.toString();
    _selectedDate = widget.transaction.date;
    _type = widget.transaction.type;
    _selectedCategoryId = widget.transaction.categoryId;
    _selectedAccountId = widget.transaction.accountId;
    _loadData();
  }

  Future<void> _loadData() async {
    final authService = AuthService();
    final userId = await authService.getCurrentUserId();
    if (userId != null) {
      final dbService = DatabaseService();
      final categories = await dbService.getCategories(userId);
      final accounts = await dbService.getAccounts(userId);

      setState(() {
        _categories = categories;
        _accounts = accounts;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Transação'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tipo de transação (não editável)
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _type == 'expense' ? 'Despesa' : 'Receita',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(height: 16),

              // Descrição
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira uma descrição';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Valor
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Valor',
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

              // Data
              ListTile(
                title: Text('Data'),
                subtitle: Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
                tileColor: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(color: Colors.grey),
                ),
              ),
              SizedBox(height: 16),

              // Conta
              DropdownButtonFormField<int>(
                value: _selectedAccountId,
                decoration: InputDecoration(
                  labelText: 'Conta',
                  border: OutlineInputBorder(),
                ),
                items: _accounts.map((account) {
                  return DropdownMenuItem<int>(
                    value: account.id,
                    child: Text(
                        '${account.name} (R\$ ${account.balance.toStringAsFixed(2)})'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedAccountId = value);
                  }
                },
              ),
              SizedBox(height: 16),

              // Categoria
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: InputDecoration(
                  labelText: 'Categoria',
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .where((cat) => cat['type'] == _type)
                    .map((category) {
                  return DropdownMenuItem<int>(
                    value: category['id'] as int,
                    child: Text(category['name'] as String),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategoryId = value);
                  }
                },
              ),
              SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text('Atualizar Transação'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final transaction = Transaction(
          id: widget.transaction.id,
          userId: widget.transaction.userId,
          accountId: _selectedAccountId,
          description: _descriptionController.text,
          amount: double.parse(_amountController.text.replaceAll(',', '.')),
          date: _selectedDate,
          categoryId: _selectedCategoryId,
          type: _type,
        );

        final dbService = DatabaseService();
        await dbService.updateTransaction(transaction);

        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transação atualizada com sucesso!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar transação: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
