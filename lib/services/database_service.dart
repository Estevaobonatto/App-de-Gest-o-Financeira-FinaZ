import 'dart:io';
import 'package:mysql1/mysql1.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../services/event_service.dart';

class DatabaseService {
  // Configurações do banco de dados
  String get _host => Platform.isAndroid ? '192.168.3.4' : 'localhost';
  final int _port = 3001;
  final String _user = 'admin';
  final String _password = 'admin';
  final String _database = 'financeiro_app';

  // Singleton
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final _eventService = EventService();

  // Método para obter conexão
  Future<MySqlConnection> _getConnection() async {
    print('Iniciando conexão com MySQL...');
    print('Plataforma: ${Platform.operatingSystem}');
    print('Host: $_host');
    print('Porta: $_port');
    print('Usuário: $_user');
    print('Banco: $_database');

    final settings = ConnectionSettings(
      host: _host,
      port: _port,
      user: _user,
      password: _password,
      db: _database,
      timeout: Duration(seconds: 30),
    );

    try {
      print('Tentando conectar ao MySQL em $_host:$_port');
      final conn = await MySqlConnection.connect(settings);
      print('Conexão bem sucedida!');
      return conn;
    } catch (e) {
      print('Erro detalhado ao conectar: $e');
      if (e is SocketException) {
        print('Erro de Socket: ${e.message}');
        print('Endereço: ${e.address}');
        print('Porta: ${e.port}');
        print('OS Error: ${e.osError}');
      }
      rethrow;
    }
  }

  // Método público para obter conexão
  Future<MySqlConnection> getConnection() async {
    return await _getConnection();
  }

  // Verificar conexão
  Future<bool> checkDatabaseConnection() async {
    try {
      final conn = await _getConnection();
      await conn.query('SELECT 1');
      await conn.close();
      return true;
    } catch (e) {
      print('Erro na verificação da conexão: $e');
      return false;
    }
  }

  // Buscar transações
  Future<List<Transaction>> getTransactions(int userId) async {
    final conn = await _getConnection();
    try {
      var results = await conn.query(
          'SELECT * FROM transactions WHERE user_id = ? ORDER BY date DESC',
          [userId]);
      return results.map((row) => Transaction.fromMap(row.fields)).toList();
    } finally {
      await conn.close();
    }
  }

  // Adicionar transação
  Future<void> addTransaction(Transaction transaction) async {
    final conn = await _getConnection();
    try {
      // Formata a data para o formato MySQL DATETIME
      String formattedDate = transaction.date.toIso8601String().split('T')[0] +
          ' ' +
          transaction.date.toIso8601String().split('T')[1].split('.')[0];

      await conn.query(
          'INSERT INTO transactions (description, amount, date, category_id, type, user_id, account_id) VALUES (?, ?, ?, ?, ?, ?, ?)',
          [
            transaction.description,
            transaction.amount,
            formattedDate, // Usa a data formatada
            transaction.categoryId,
            transaction.type,
            transaction.userId,
            transaction.accountId,
          ]);

      // Atualiza o saldo da conta
      if (transaction.type == 'expense') {
        await conn.query(
            'UPDATE accounts SET balance = balance - ? WHERE id = ?',
            [transaction.amount, transaction.accountId]);
      } else {
        await conn.query(
            'UPDATE accounts SET balance = balance + ? WHERE id = ?',
            [transaction.amount, transaction.accountId]);
      }

      _eventService.notifyDatabaseChanged('transaction_added');
    } finally {
      await conn.close();
    }
  }

  // Buscar contas
  Future<List<Account>> getAccounts(int userId) async {
    final conn = await _getConnection();
    try {
      var results = await conn.query(
          'SELECT * FROM accounts WHERE user_id = ? ORDER BY name', [userId]);
      return results.map((row) => Account.fromMap(row.fields)).toList();
    } finally {
      await conn.close();
    }
  }

  // Verificar tabelas
  Future<bool> checkTables() async {
    final conn = await _getConnection();
    try {
      final tables = [
        'users',
        'categories',
        'accounts',
        'transactions',
        'budget_goals',
        'spending_limits'
      ];

      var results = await conn.query('SHOW TABLES');
      var existingTables = results.map((row) => row[0].toString()).toList();

      for (var table in tables) {
        if (!existingTables.contains(table)) {
          print('Tabela $table não encontrada');
          return false;
        }
      }
      return true;
    } finally {
      await conn.close();
    }
  }

  Future<bool> initializeDatabase() async {
    final conn = await _getConnection();
    try {
      // Lê o arquivo SQL
      final String sql = await File('lib/database/TABLES1.sql').readAsString();

      // Executa cada comando separadamente
      final commands = sql.split(';').where((cmd) => cmd.trim().isNotEmpty);

      for (var command in commands) {
        await conn.query(command);
      }

      return true;
    } catch (e) {
      print('Erro ao inicializar banco de dados: $e');
      return false;
    } finally {
      await conn.close();
    }
  }

  Future<List<Map<String, dynamic>>> getCategories(int userId) async {
    final conn = await _getConnection();
    try {
      var results = await conn.query(
          'SELECT * FROM categories WHERE user_id = ? ORDER BY name', [userId]);
      return results.map((row) => row.fields).toList();
    } finally {
      await conn.close();
    }
  }

  Future<void> addAccount(
      int userId, String name, double balance, String type) async {
    final conn = await _getConnection();
    try {
      await conn.query(
          'INSERT INTO accounts (user_id, name, balance, type) VALUES (?, ?, ?, ?)',
          [userId, name, balance, type]);
      _eventService.notifyDatabaseChanged('account_added');
    } finally {
      await conn.close();
    }
  }

  Future<void> addCategory(
      int userId, String name, int iconCode, String color, String type) async {
    final conn = await _getConnection();
    try {
      await conn.query(
          'INSERT INTO categories (user_id, name, icon_code, color, type) VALUES (?, ?, ?, ?, ?)',
          [userId, name, iconCode, color, type]);
      _eventService.notifyDatabaseChanged('category_added');
    } finally {
      await conn.close();
    }
  }

  Future<void> deleteCategory(int categoryId) async {
    final conn = await _getConnection();
    try {
      await conn.query('DELETE FROM categories WHERE id = ?', [categoryId]);
      _eventService.notifyDatabaseChanged('category_deleted');
    } finally {
      await conn.close();
    }
  }

  Future<void> deleteAccount(int accountId) async {
    final conn = await _getConnection();
    try {
      await conn.query('DELETE FROM accounts WHERE id = ?', [accountId]);
      _eventService.notifyDatabaseChanged('account_deleted');
    } finally {
      await conn.close();
    }
  }

  Future<void> updateCategory(int categoryId, String name) async {
    final conn = await _getConnection();
    try {
      await conn.query(
        'UPDATE categories SET name = ? WHERE id = ?',
        [name, categoryId],
      );
      _eventService.notifyDatabaseChanged('category_updated');
    } finally {
      await conn.close();
    }
  }

  Future<void> updateAccount(int accountId, String name, String type) async {
    final conn = await _getConnection();
    try {
      await conn.query(
        'UPDATE accounts SET name = ?, type = ? WHERE id = ?',
        [name, type, accountId],
      );
      _eventService.notifyDatabaseChanged('account_updated');
    } finally {
      await conn.close();
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final conn = await _getConnection();
    try {
      String formattedDate = transaction.date.toIso8601String().split('T')[0] +
          ' ' +
          transaction.date.toIso8601String().split('T')[1].split('.')[0];

      await conn.query(
        'UPDATE transactions SET description = ?, amount = ?, date = ?, category_id = ?, type = ?, account_id = ? WHERE id = ?',
        [
          transaction.description,
          transaction.amount,
          formattedDate,
          transaction.categoryId,
          transaction.type,
          transaction.accountId,
          transaction.id,
        ],
      );
      _eventService.notifyDatabaseChanged('transaction_updated');
    } finally {
      await conn.close();
    }
  }

  Future<void> deleteTransaction(int transactionId) async {
    final conn = await _getConnection();
    try {
      // Primeiro, obtém os detalhes da transação
      var result = await conn.query(
          'SELECT amount, type, account_id FROM transactions WHERE id = ?',
          [transactionId]);

      if (result.isNotEmpty) {
        var transaction = result.first;
        var amount = transaction['amount'] as double;
        var type = transaction['type'] as String;
        var accountId = transaction['account_id'] as int;

        // Inicia uma transação no banco
        await conn.query('START TRANSACTION');

        // Deleta a transação
        await conn
            .query('DELETE FROM transactions WHERE id = ?', [transactionId]);

        // Atualiza o saldo da conta
        if (type == 'expense') {
          // Se era uma despesa, adiciona o valor de volta
          await conn.query(
              'UPDATE accounts SET balance = balance + ? WHERE id = ?',
              [amount, accountId]);
        } else if (type == 'income') {
          // Se era uma receita, subtrai o valor
          await conn.query(
              'UPDATE accounts SET balance = balance - ? WHERE id = ?',
              [amount, accountId]);
        }

        // Confirma a transação
        await conn.query('COMMIT');
        _eventService.notifyDatabaseChanged('transaction_deleted');
      }
    } catch (e) {
      await conn.query('ROLLBACK');
      throw e;
    } finally {
      await conn.close();
    }
  }
}
