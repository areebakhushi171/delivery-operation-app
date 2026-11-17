import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/core.dart';
import '../../providers/admin_providers.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();

  PaymentType _paymentType = PaymentType.cod;
  String? _selectedRiderId;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _areaCtrl.dispose();
    _amountCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    KeyboardUtils.dismiss(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    final amt = int.tryParse(_amountCtrl.text.trim()) ?? 0;
    const uuid = Uuid();
    final newId = 'PK-${uuid.v4().substring(0, 4).toUpperCase()}';
    final now = DateTime.now();

    final order = DeliveryOrder(
      id: newId,
      customerName: _nameCtrl.text.trim(),
      customerPhone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      area: _areaCtrl.text.trim(),
      windowStart: now,
      windowEnd: now.add(const Duration(hours: 4)),
      createdAt: now,
      items: [const OrderItem(name: 'Standard Parcel', quantity: 1)],
      instructions: _instructionsCtrl.text.trim(),
      paymentType: _paymentType,
      codAmount: _paymentType == PaymentType.cod ? amt : 0,
      prepaidAmount: _paymentType == PaymentType.prepaid ? amt : 0,
      status: _selectedRiderId != null ? OrderStatus.assigned : OrderStatus.unassigned,
      riderId: _selectedRiderId,
      history: [
        StatusEntry(
          status: _selectedRiderId != null ? OrderStatus.assigned : OrderStatus.unassigned,
          at: now,
          byUid: 'admin-uid',
          note: _selectedRiderId != null ? 'Created and assigned' : 'Order created',
        ),
      ],
    );

    try {
      await context.read<AdminOrdersProvider>().createOrder(order, 'admin-uid');
      if (mounted) {
        context.showMessage('Order #$newId successfully created and queued!', isSuccess: true);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) context.showMessage('Failed to create order: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final riders = context.watch<AdminDashboardProvider>().riders;

    return Scaffold(
      appBar: const CommonAppBar(title: 'Create New Order'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.md),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CommonSectionHeader('Customer Details'),
              SizedBox(height: AppSpacing.xs),
              CommonTextField(
                label: 'Customer Full Name',
                isRequired: true,
                controller: _nameCtrl,
                hint: 'e.g. Farhan Malik',
                validator: Validators.required,
              ),
              SizedBox(height: AppSpacing.sm),
              CommonTextField(
                label: 'Customer Phone',
                isRequired: true,
                controller: _phoneCtrl,
                hint: 'e.g. +92 300 9876543',
                keyboardType: TextInputType.phone,
                validator: Validators.phone,
              ),
              SizedBox(height: AppSpacing.sm),
              CommonTextField(
                label: 'Delivery Address',
                isRequired: true,
                controller: _addressCtrl,
                hint: 'e.g. Office 402, Beverly Centre, Blue Area',
                maxLines: 2,
                validator: Validators.required,
              ),
              SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: CommonTextField(
                      label: 'City',
                      isRequired: true,
                      controller: _cityCtrl,
                      hint: 'e.g. Islamabad',
                      validator: Validators.required,
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: CommonTextField(
                      label: 'Area / Sector',
                      isRequired: true,
                      controller: _areaCtrl,
                      hint: 'e.g. Blue Area',
                      validator: Validators.required,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md),

              const CommonSectionHeader('Rider Assignment'),
              SizedBox(height: AppSpacing.xs),
              DropdownButtonFormField<String?>(
                isExpanded: true, // overflow fix: poori width use karo
                value: _selectedRiderId,
                decoration: const InputDecoration(
                  labelText: 'Assign Rider (Optional)',
                  hintText: 'Select a registered courier',
                ),
                // Selected value bhi ek line mein ellipsis ke saath dikhe
                selectedItemBuilder: (context) => [
                  const Text(
                    'Unassigned (Queue for later)',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  for (final r in riders)
                    Text(
                      '${r.name} (${r.phone}) • ${r.dutyStatus.name}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                ],
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      'Unassigned (Queue for later)',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  for (final r in riders)
                    DropdownMenuItem<String?>(
                      value: r.id,
                      child: Text(
                        '${r.name} (${r.phone}) • ${r.dutyStatus.name}',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _selectedRiderId = v),
              ),
              SizedBox(height: AppSpacing.md),

              const CommonSectionHeader('Payment & Manifest'),
              SizedBox(height: AppSpacing.xs),
              DropdownButtonFormField<PaymentType>(
                isExpanded: true,
                value: _paymentType,
                items: const [
                  DropdownMenuItem(value: PaymentType.cod, child: Text('COD (Cash on Delivery)')),
                  DropdownMenuItem(value: PaymentType.prepaid, child: Text('Prepaid')),
                ],
                onChanged: (v) => setState(() => _paymentType = v ?? PaymentType.cod),
                decoration: const InputDecoration(labelText: 'Payment Type'),
              ),
              SizedBox(height: AppSpacing.sm),
              CommonTextField(
                label: 'Amount (Rs.)',
                isRequired: true,
                controller: _amountCtrl,
                hint: 'e.g. 4500',
                keyboardType: TextInputType.number,
                validator: Validators.required,
              ),
              SizedBox(height: AppSpacing.sm),
              CommonTextField(
                label: 'Delivery Instructions / Landmark',
                controller: _instructionsCtrl,
                hint: 'e.g. Fragile item, call before arrival',
                maxLines: 2,
              ),
              SizedBox(height: AppSpacing.lg),
              CommonButton(
                label: 'Create & Dispatch Order',
                icon: Icons.check_circle_outline,
                isLoading: _isSaving,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}