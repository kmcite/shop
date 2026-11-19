import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shop/business/shop_cubit.dart';

import '../../models/customer_model.dart';
import '../../ui/spacing.dart';
import '../design/metro.dart';

Future<ShopCustomer?> openCustomerEditor(
  BuildContext context, {
  ShopCustomer? existing,
}) {
  return Navigator.of(context).push<ShopCustomer>(
    metroRoute(
      context: context,
      builder: (_) => CustomerEditorScreen(existing: existing),
    ),
  );
}

class CustomerEditorScreen extends StatefulWidget {
  const CustomerEditorScreen({super.key, this.existing});

  final ShopCustomer? existing;

  @override
  State<CustomerEditorScreen> createState() => _CustomerEditorScreenState();
}

class _CustomerEditorScreenState extends State<CustomerEditorScreen> {
  late final TextEditingController _name;
  late final TextEditingController _note;
  var _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _note = TextEditingController(text: widget.existing?.note ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final saved = await context.read<ShopCubit>().upsertCustomer(
          id: widget.existing?.id ?? '',
          name: _name.text,
          note: _note.text,
          createdAt: widget.existing?.createdAt,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved != null) Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'edit customer' : 'new customer'),
      ),
      body: ListView(
        padding: AppSpacing.sheet,
        children: [
          MetroTextField(
            controller: _name,
            label: const Text('Name'),
            placeholder: 'Who is buying on credit?',
            prefix: const Icon(Icons.person_outline, size: 18),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofocus: !_isEdit,
          ),
          const SizedBox(height: AppSpacing.lg),
          MetroTextField(
            controller: _note,
            label: const Text('Note'),
            placeholder: 'Phone, shop, or reminder (optional)',
            prefix: const Icon(Icons.notes_outlined, size: 18),
            maxLines: 3,
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
              child: Text(_isEdit ? 'Save' : 'Add customer'),
            ),
          ),
        ),
      ),
    );
  }
}
