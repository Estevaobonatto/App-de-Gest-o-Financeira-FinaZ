import 'package:mysql1/mysql1.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'database_service.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthService {
  final DatabaseService _db = DatabaseService();

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Hash password
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<User?> login(String email, String password) async {
    MySqlConnection? conn;
    try {
      conn = await _db.getConnection();
      final hashedPassword = _hashPassword(password);

      var results = await conn.query(
          'SELECT id, name, email FROM users WHERE email = ? AND password = ?',
          [email, hashedPassword]);

      if (results.isNotEmpty) {
        final user = User.fromMap(results.first.fields);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('userId', user.id!);
        return user;
      }
      return null;
    } catch (e) {
      print('Erro no login: $e');
      return null;
    } finally {
      await conn?.close();
    }
  }

  Future<bool> register(User user) async {
    MySqlConnection? conn;
    try {
      conn = await _db.getConnection();
      final hashedPassword = _hashPassword(user.password!);

      // Inicia uma transação
      await conn.query('START TRANSACTION');

      // Insere o usuário
      var result = await conn.query(
          'INSERT INTO users (name, email, password) VALUES (?, ?, ?)',
          [user.name, user.email, hashedPassword]);

      final userId = result.insertId;

      // Cria uma conta padrão para o usuário
      await conn.query(
          'INSERT INTO accounts (user_id, name, balance, type) VALUES (?, ?, ?, ?)',
          [userId, 'Conta Principal', 0.00, 'checking']);

      // Cria categorias padrão para o usuário
      await conn.query('''
        INSERT INTO categories (user_id, name, icon_code, color, type) VALUES 
        (?, 'Alimentação', 0xe3af, '#4CAF50', 'expense'),
        (?, 'Transporte', 0xe1d8, '#2196F3', 'expense'),
        (?, 'Moradia', 0xe318, '#9C27B0', 'expense'),
        (?, 'Lazer', 0xe3b8, '#FFC107', 'expense'),
        (?, 'Saúde', 0xe3a9, '#F44336', 'expense'),
        (?, 'Educação', 0xe3e7, '#795548', 'expense'),
        (?, 'Salário', 0xe8e5, '#4CAF50', 'income'),
        (?, 'Investimentos', 0xe8e4, '#2196F3', 'income')
      ''', [userId, userId, userId, userId, userId, userId, userId, userId]);

      // Confirma a transação
      await conn.query('COMMIT');
      return true;
    } catch (e) {
      // Em caso de erro, desfaz a transação
      await conn?.query('ROLLBACK');
      print('Erro no registro: $e');
      return false;
    } finally {
      await conn?.close();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
  }

  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasUser = prefs.containsKey('userId');
      print('Usuario está logado: $hasUser');
      return hasUser;
    } catch (e) {
      print('Erro ao verificar login: $e');
      return false;
    }
  }

  Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }
}
