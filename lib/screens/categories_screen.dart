import 'dart:async'; // Adicione esta linha no início do arquivo
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';

class CategoriesScreen extends StatefulWidget {
  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();
  final AuthService _auth = AuthService();
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  late TabController _tabController;
  String _selectedType = 'expense';
  late StreamSubscription _databaseSubscription;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    _databaseSubscription = EventService().onDatabaseChanged.listen((event) {
      if (event.contains('category')) {
        _loadCategories();
      }
    });
  }

  @override
  void dispose() {
    _databaseSubscription.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedType = _tabController.index == 0 ? 'expense' : 'income';
        });
      }
    });
    await _loadCategories();
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final userId = await _auth.getCurrentUserId();
      if (userId != null) {
        final categories = await _db.getCategories(userId);
        if (mounted) {
          setState(() {
            _categories = List<Map<String, dynamic>>.from(categories);
            _isLoading = false;
          });
          print('Categorias carregadas: ${_categories.length}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar categorias: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadCategories,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Categorias'),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Despesas'),
              Tab(
                text: 'Receitas',
              ),
            ],
          ),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildCategoryList('expense'),
                  _buildCategoryList('income'),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddCategoryDialog,
          child: Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildCategoryList(String type) {
    final filteredCategories =
        _categories.where((c) => c['type'] == type).toList();

    if (filteredCategories.isEmpty) {
      return Center(
        child: Text(
          type == 'expense'
              ? 'Nenhuma categoria de despesa'
              : 'Nenhuma categoria de receita',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return ListView.builder(
      physics: AlwaysScrollableScrollPhysics(),
      itemCount: filteredCategories.length,
      itemBuilder: (context, index) {
        final category = filteredCategories[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(
              category['name'],
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              category['type'] == 'expense' ? 'Despesa' : 'Receita',
              style: TextStyle(color: Colors.white70),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.white),
                  onPressed: () => _editCategory(category),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.white),
                  onPressed: () => _deleteCategory(category['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddCategoryDialog() async {
    final nameController = TextEditingController();

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Nova Categoria'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Nome da Categoria',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final userId = await _auth.getCurrentUserId();
                  if (userId != null) {
                    await _db.addCategory(
                      userId,
                      nameController.text,
                      0,
                      '#000000',
                      _selectedType,
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
        // Força o recarregamento imediato
        await _loadCategories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Categoria adicionada com sucesso!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar categoria: $e')),
        );
      }
    }
  }

  Future<void> _deleteCategory(int categoryId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar exclusão'),
        content: Text('Deseja realmente excluir esta categoria?'),
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
        await _db.deleteCategory(categoryId);
        await _loadCategories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Categoria excluída com sucesso!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao deletar categoria: $e')),
          );
        }
      }
    }
  }

  Future<void> _editCategory(Map<String, dynamic> category) async {
    final nameController = TextEditingController(text: category['name']);

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Editar Categoria'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Nome da Categoria',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  await _db.updateCategory(
                    category['id'],
                    nameController.text,
                  );
                  Navigator.pop(context, true);
                }
              },
              child: Text('Salvar'),
            ),
          ],
        ),
      );

      if (result == true) {
        await _loadCategories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Categoria atualizada com sucesso!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar categoria: $e')),
        );
      }
    }
  }
}
