import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/database_service.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/accounts_screen.dart';
import 'screens/categories_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('Iniciando aplicação...');

  try {
    final dbService = DatabaseService();

    print('Verificando conexão com banco de dados...');
    final isConnected = await dbService.checkDatabaseConnection();
    if (!isConnected) {
      throw Exception('Não foi possível conectar ao banco de dados');
    }

    if (!await dbService.checkTables()) {
      print('Inicializando banco de dados...');
      if (!await dbService.initializeDatabase()) {
        throw Exception('Erro ao inicializar banco de dados');
      }
    }

    print('Verificando status do login...');
    final authService = AuthService();
    final isLoggedIn = await authService.isLoggedIn();
    print('Status do login: $isLoggedIn');

    runApp(MyApp(isLoggedIn: isLoggedIn));
  } catch (e) {
    print('Erro fatal na inicialização: $e');
    runApp(MyApp(
      isLoggedIn: false,
      initialError: 'Erro ao iniciar o aplicativo: $e\n\n'
          'Verifique se:\n'
          '1. O MySQL está rodando\n'
          '2. O banco de dados "financeiro_app" existe\n'
          '3. As credenciais estão corretas\n'
          '4. O firewall não está bloqueando a conexão',
    ));
  }
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? initialError;

  const MyApp({
    super.key,
    required this.isLoggedIn,
    this.initialError,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle Financeiro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF9C27B0), // Violeta principal
          secondary: Color(0xFFE1BEE7), // Violeta claro
          surface: Color(0xFF1E1E1E), // Superfície escura
          background: Color(0xFF121212), // Fundo mais escuro
          error: Color(0xFFCF6679), // Cor de erro
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onSurface: Colors.white,
          onBackground: Colors.white,
          onError: Colors.black,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF9C27B0),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF9C27B0),
          foregroundColor: Colors.white,
        ),
        cardTheme: CardTheme(
          color: Color(0xFF1E1E1E),
          elevation: 4,
        ),
        scaffoldBackgroundColor: Color(0xFF121212),
      ),
      home: initialError != null
          ? ErrorScreen(error: initialError!)
          : isLoggedIn
              ? HomeScreen()
              : LoginScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(),
        '/add-transaction': (context) => AddTransactionScreen(),
        '/accounts': (context) => AccountsScreen(),
        '/categories': (context) => CategoriesScreen(),
      },
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          settings: settings,
          builder: (context) {
            switch (settings.name) {
              case '/add-transaction':
                return AddTransactionScreen();
              default:
                return HomeScreen();
            }
          },
        );
      },
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String error;

  const ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              SizedBox(height: 16),
              Text(
                'Erro ao iniciar o aplicativo',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Reinicia o app
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
