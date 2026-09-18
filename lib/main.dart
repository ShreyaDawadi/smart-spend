import 'package:flutter/material.dart';
import 'database_helper.dart';

void main() {
  runApp(const SmartSpendApp());
}

class SmartSpendApp extends StatelessWidget {
  const SmartSpendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartSpend',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6C5CE7),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F7FB),
      ),
      home: const HomeScreen(),
    );
  }
}

class Transaction {
  final int? id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;

  Transaction({
    this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int,
      title: map['title'] as String,
      category: map['category'] as String,
      amount: map['amount'] as double,
      date: DateTime.parse(map['date'] as String),
    );
  }
}

class CategoryStyle {
  final IconData icon;
  final Color color;
  const CategoryStyle(this.icon, this.color);
}

const Map<String, CategoryStyle> categoryStyles = {
  'Groceries': CategoryStyle(Icons.local_grocery_store_rounded, Color(0xFFFF9F43)),
  'Income': CategoryStyle(Icons.account_balance_wallet_rounded, Color(0xFF2ECC71)),
  'Transport': CategoryStyle(Icons.directions_bus_rounded, Color(0xFF3498DB)),
  'Food': CategoryStyle(Icons.restaurant_rounded, Color(0xFFE74C3C)),
  'Shopping': CategoryStyle(Icons.shopping_bag_rounded, Color(0xFFE84393)),
  'Bills': CategoryStyle(Icons.receipt_long_rounded, Color(0xFF9B59B6)),
  'Health': CategoryStyle(Icons.local_hospital_rounded, Color(0xFF00B894)),
  'Other': CategoryStyle(Icons.category_rounded, Color(0xFF95A5A6)),
};

CategoryStyle styleFor(String category) {
  return categoryStyles[category] ?? categoryStyles['Other']!;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Transaction> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final rows = await DatabaseHelper.instance.getAllTransactions();
    setState(() {
      _transactions = rows.map((row) => Transaction.fromMap(row)).toList();
      _loading = false;
    });
  }

  double get _totalBalance => _transactions.fold(0, (sum, t) => sum + t.amount);
  double get _totalExpense =>
      _transactions.where((t) => t.amount < 0).fold(0, (sum, t) => sum + t.amount.abs());
  double get _totalIncome =>
      _transactions.where((t) => t.amount > 0).fold(0, (sum, t) => sum + t.amount);

  Future<void> _addTransaction(Transaction transaction) async {
    await DatabaseHelper.instance.insertTransaction(transaction.toMap());
    _loadTransactions();
  }

  Future<void> _deleteTransaction(int index) async {
    final t = _transactions[index];
    if (t.id == null) return;
    await DatabaseHelper.instance.deleteTransaction(t.id!);
    setState(() {
      _transactions.removeAt(index);
    });
  }

  void _openAddTransactionScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
    );
    if (result != null && result is Transaction) {
      _addTransaction(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF6C5CE7),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'Total Balance',
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Rs ${_totalBalance.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _SummaryPill(
                          icon: Icons.arrow_downward_rounded,
                          label: 'Income',
                          amount: _totalIncome,
                          pillColor: const Color(0xFF00E676),
                        ),
                        const SizedBox(width: 12),
                        _SummaryPill(
                          icon: Icons.arrow_upward_rounded,
                          label: 'Expense',
                          amount: _totalExpense,
                          pillColor: const Color(0xFFFF7675),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_transactions.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No transactions yet.\nTap + to add your first one!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final t = _transactions[index];
                    return Dismissible(
                      key: Key(t.id.toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete_rounded, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        _deleteTransaction(index);
                      },
                      child: TransactionTile(
                        title: t.title,
                        category: t.category,
                        amount: t.amount,
                      ),
                    );
                  },
                  childCount: _transactions.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddTransactionScreen,
        backgroundColor: const Color(0xFF6C5CE7),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;
  final Color pillColor;

  const _SummaryPill({
    required this.icon,
    required this.label,
    required this.amount,
    required this.pillColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: pillColor, shape: BoxShape.circle),
              child: Icon(icon, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  Text(
                    'Rs ${amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  final String title;
  final String category;
  final double amount;

  const TransactionTile({
    super.key,
    required this.title,
    required this.category,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = amount < 0;
    final style = styleFor(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: style.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(style.icon, color: style.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(category, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              ],
            ),
          ),
          Text(
            '${isExpense ? '-' : '+'} Rs ${amount.abs().toStringAsFixed(0)}',
            style: TextStyle(
              color: isExpense ? const Color(0xFFE74C3C) : const Color(0xFF00B894),
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isExpense = true;
  String _selectedCategory = 'Groceries';

  void _save() {
    final title = _titleController.text.trim();
    final amountText = _amountController.text.trim();

    if (title.isEmpty || amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number')),
      );
      return;
    }

    final transaction = Transaction(
      title: title,
      category: _selectedCategory,
      amount: _isExpense ? -amount : amount,
      date: DateTime.now(),
    );

    Navigator.pop(context, transaction);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        title: const Text('Add Transaction'),
        backgroundColor: const Color(0xFFF7F7FB),
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Expense'), icon: Icon(Icons.remove)),
                ButtonSegment(value: false, label: Text('Income'), icon: Icon(Icons.add)),
              ],
              selected: {_isExpense},
              onSelectionChanged: (selection) {
                setState(() {
                  _isExpense = selection.first;
                });
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (Rs)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: categoryStyles.keys.map((cat) {
                final style = categoryStyles[cat]!;
                final selected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = cat;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? style.color : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: style.color.withOpacity(selected ? 1 : 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(style.icon, size: 16, color: selected ? Colors.white : style.color),
                        const SizedBox(width: 6),
                        Text(
                          cat,
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _save,
              child: const Text('Save Transaction', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}