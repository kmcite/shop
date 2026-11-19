import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shop/business/shop_cubit.dart';

import '../../models/customer_model.dart';
import '../../ui/format.dart';
import '../../ui/spacing.dart';
import '../design/metro.dart';

Future<bool?> openRecordPayment(
  BuildContext context, {
  required CustomerAccount account,
}) {
  return Navigator.of(context).push<bool>(
    metroRoute(
      context: context,
      builder: (_) => RecordPaymentScreen(account: account),
    ),
  );
}

class RecordPaymentScreen extends StatefulWidget {
  const RecordPaymentScreen({super.key, required this.account});

  final CustomerAccount account;

  @override
  State<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends State<RecordPaymentScreen> {
  late final TextEditingController _amount;
  late final TextEditingController _note;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final owing = widget.account.remaining;
    _amount = TextEditingController(
      text: owing > 0 ? owing.toStringAsFixed(owing == owing.roundToDouble() ? 0 : 2) : '',
    );
    _note = TextEditingController();
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final amount = double.tryParse(_amount.text.trim().replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid payment amount')),
      );
      return;
    }
    setState(() => _saving = true);
    final ok = await context.read<ShopCubit>().recordCustomerPayment(
          customerId: widget.account.customer.id,
          amount: amount,
          note: _note.text,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metro = MetroTheme.of(context);
    final owing = widget.account.remaining;

    return Scaffold(
      appBar: AppBar(title: const Text('record payment')),
      body: ListView(
        padding: AppSpacing.sheet,
        children: [
          Text(
            widget.account.customer.name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            owing > 0.005
                ? 'Currently owes ${formatMoney(owing)}'
                : owing < -0.005
                    ? 'Has ${formatMoney(-owing)} credit'
                    : 'Balance is settled',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: metro.colors.mutedForeground,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          MetroTextField(
            controller: _amount,
            label: const Text('Amount received'),
            placeholder: '0',
            prefix: const Icon(Icons.payments_outlined, size: 18),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            autofocus: true,
          ),
          if (owing > 0.005) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: MetroButton(
                onPressed: () {
                  _amount.text = owing == owing.roundToDouble()
                      ? owing.toStringAsFixed(0)
                      : owing.toStringAsFixed(2);
                  _amount.selection = TextSelection.collapsed(
                    offset: _amount.text.length,
                  );
                },
                style: const MetroButtonStyle(minimumSize: Size(0, 36)),
                child: Text('Pay full · ${formatMoney(owing)}'),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          MetroTextField(
            controller: _note,
            label: const Text('Note'),
            placeholder: 'Cash, transfer, partial… (optional)',
            prefix: const Icon(Icons.notes_outlined, size: 18),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          child: SizedBox(
            width: double.infinity,
            child: MetroButton.accent(
              onPressed: _saving ? null : _save,
              style: const MetroButtonStyle(minimumSize: Size(0, 44)),
              child: const Text('Save payment'),
            ),
          ),
        ),
      ),
    );
  }
}
