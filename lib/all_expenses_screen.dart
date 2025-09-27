import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart'; // Import main.dart to access existing classes

// --- All Expenses Screen ---
class AllExpensesScreen extends StatefulWidget {
  const AllExpensesScreen({super.key});

  @override
  State<AllExpensesScreen> createState() => _AllExpensesScreenState();
}

class _AllExpensesScreenState extends State<AllExpensesScreen> {
  String _selectedCategory = 'All';
  String _sortBy = 'Date (Newest First)';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Expense> _getFilteredAndSortedExpenses(List<Expense> expenses) {
    List<Expense> filtered = List.from(expenses);

    // Filter by search query
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((expense) =>
        expense.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
        expense.category.displayName.toLowerCase().contains(_searchController.text.toLowerCase())
      ).toList();
    }

    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered.where((expense) =>
        expense.category.displayName == _selectedCategory
      ).toList();
    }

    // Sort expenses
    switch (_sortBy) {
      case 'Date (Newest First)':
        filtered.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'Date (Oldest First)':
        filtered.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'Amount (High to Low)':
        filtered.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'Amount (Low to High)':
        filtered.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case 'Title (A-Z)':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'Category':
        filtered.sort((a, b) => a.category.displayName.compareTo(b.category.displayName));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Expenses'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'Date (Newest First)',
                child: Row(
                  children: [
                    Icon(Icons.calendar_today),
                    SizedBox(width: 8),
                    Text('Date (Newest First)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'Date (Oldest First)',
                child: Row(
                  children: [
                    Icon(Icons.calendar_today),
                    SizedBox(width: 8),
                    Text('Date (Oldest First)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'Amount (High to Low)',
                child: Row(
                  children: [
                    Icon(Icons.currency_rupee),
                    SizedBox(width: 8),
                    Text('Amount (High to Low)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'Amount (Low to High)',
                child: Row(
                  children: [
                    Icon(Icons.currency_rupee),
                    SizedBox(width: 8),
                    Text('Amount (Low to High)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'Title (A-Z)',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha),
                    SizedBox(width: 8),
                    Text('Title (A-Z)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'Category',
                child: Row(
                  children: [
                    Icon(Icons.category),
                    SizedBox(width: 8),
                    Text('Category'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<ExpenseManager>(
        builder: (context, expenseManager, child) {
          final List<Expense> allExpenses = _getFilteredAndSortedExpenses(expenseManager.expenses);
          final double totalAmount = allExpenses.fold(0.0, (sum, expense) => sum + expense.amount);

          return Column(
            children: [
              // Header with search and stats
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Search bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search expenses...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                  });
                                },
                                icon: const Icon(Icons.clear),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Category filter
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCategoryChip('All'),
                          ...ExpenseCategory.values.map((category) => 
                            _buildCategoryChip(category.displayName)
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Stats row
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Expenses',
                            allExpenses.length.toString(),
                            Icons.receipt_long,
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Total Amount',
                            '₹${totalAmount.toStringAsFixed(2)}',
                            Icons.currency_rupee,
                            const Color(0xFFFF6B6B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Expenses list
              Expanded(
                child: allExpenses.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: allExpenses.length,
                        itemBuilder: (context, index) {
                          final expense = allExpenses[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ExpenseListItem(expense: expense),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute<Widget>(
              builder: (context) => const AddExpenseScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final bool isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
        },
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        selectedColor: Theme.of(context).colorScheme.primaryContainer,
        checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected 
              ? Theme.of(context).colorScheme.onPrimaryContainer
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchController.text.isNotEmpty || _selectedCategory != 'All'
                ? 'No expenses found'
                : 'No expenses yet',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty || _selectedCategory != 'All'
                ? 'Try adjusting your search or filter'
                : 'Add your first expense to get started',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchController.text.isEmpty && _selectedCategory == 'All') ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<Widget>(
                    builder: (context) => const AddExpenseScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
            ),
          ],
        ],
      ),
    );
  }
}