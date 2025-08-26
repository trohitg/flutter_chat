import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/money_service.dart';
import '../models/payment_models.dart';
import '../core/di/service_locator.dart';

class MoneyScreen extends StatefulWidget {
  const MoneyScreen({super.key});

  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends State<MoneyScreen> {
  late final MoneyService _moneyService;
  final TextEditingController _amountController = TextEditingController();
  
  WalletResponse? _walletData;
  bool _isLoadingWallet = false;
  bool _isProcessingPayment = false;
  String? _error;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _moneyService = sl<MoneyService>();
    // Load wallet data after frame is built to prevent blocking initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWallet();
    });
  }

  Future<void> _loadWallet() async {
    if (_isLoadingWallet) return; // Prevent multiple concurrent loads
    
    if (mounted) {
      setState(() {
        _isLoadingWallet = true;
        _error = null;
      });
    }

    try {
      final wallet = await _moneyService.getWallet().timeout(Duration(seconds: 10));
      if (mounted) {
        setState(() {
          _walletData = wallet;
          _isLoadingWallet = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingWallet = false;
        });
      }
    }
  }

  Future<void> _addMoney() async {
    if (_isProcessingPayment || _isLoadingWallet) return; // Prevent concurrent operations
    
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      _showMessage('Please enter an amount');
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || !MoneyService.isValidAmount(amount)) {
      _showMessage('Please enter a valid amount between ₹1 and ₹2,00,000');
      return;
    }

    if (mounted) {
      setState(() {
        _isProcessingPayment = true;
        _error = null;
      });
    }

    try {
      await _moneyService.startPayment(
        amount: amount,
        onSuccess: (paymentId) {
          if (!mounted) return;
          setState(() {
            _isProcessingPayment = false;
          });
          _showMessage('Payment successful! ID: $paymentId');
          _amountController.clear();
          // Debounced wallet refresh to prevent UI blocking
          _debounceWalletRefresh();
        },
        onFailure: (error) {
          if (!mounted) return;
          setState(() {
            _isProcessingPayment = false;
            _error = error;
          });
          _showMessage('Payment failed: $error');
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
          _error = e.toString();
        });
      }
    }
  }
  
  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
  
  void _debounceWalletRefresh() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 1500), () {
      if (mounted && !_isProcessingPayment) {
        _loadWallet();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Wallet Balance Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Balance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isLoadingWallet)
                      const CircularProgressIndicator()
                    else if (_walletData != null)
                      Text(
                        '₹${_walletData!.balance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      )
                    else if (_error != null)
                      Text(
                        'Error: $_error',
                        style: const TextStyle(color: Colors.red),
                      ),
                    const SizedBox(height: 8),
                    if (_walletData != null)
                      Text(
                        'Last updated: ${_walletData!.lastUpdated.toString().split('.')[0]}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Add Money Section
            const Text(
              'Add Money',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                hintText: 'Enter amount to add',
                border: OutlineInputBorder(),
                prefixText: '₹ ',
              ),
            ),
            
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: (_isProcessingPayment || _isLoadingWallet) ? null : _addMoney,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: _isProcessingPayment
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Add Money',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
            
            const SizedBox(height: 24),
            
            // Recent Transactions
            if (_walletData != null && _walletData!.recentTransactions.isNotEmpty) ...[
              const Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _walletData!.recentTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = _walletData!.recentTransactions[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          transaction.transactionType == 'credit' ? Icons.add_circle : Icons.remove_circle,
                          color: transaction.transactionType == 'credit' ? Colors.green : Colors.red,
                        ),
                        title: Text(transaction.description ?? 'Transaction'),
                        subtitle: Text(transaction.createdAt.toString().split('.')[0]),
                        trailing: Text(
                          '${transaction.transactionType == 'credit' ? '+' : '-'}₹${transaction.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: transaction.transactionType == 'credit' ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
}