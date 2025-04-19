import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../data/models/customer_model.dart';
import '../providers/customer_provider.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  final String? customerId;

  const CustomerFormScreen({Key? key, this.customerId}) : super(key: key);

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;
  bool _isEdit = false;
  CustomerModel? _initialCustomer;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.customerId != null;
  }

  @override
  Widget build(BuildContext context) {
    // If editing, fetch the customer data
    if (_isEdit && _initialCustomer == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? 'Müşteri Düzenle' : 'Yeni Müşteri'),
        ),
        body: ref.watch(customerProvider(widget.customerId!)).when(
              data: (customer) {
                // Store the initial customer data for the form
                _initialCustomer = customer;
                return _buildForm();
              },
              error: (error, stackTrace) => AppErrorWidget(
                error: error.toString(),
                onRetry: () => ref.refresh(customerProvider(widget.customerId!)),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
      );
    }

    // Otherwise, show the form directly
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Müşteri Düzenle' : 'Yeni Müşteri'),
      ),
      body: _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: FormBuilder(
        key: _formKey,
        initialValue: _isEdit
            ? {
                'firstName': _initialCustomer?.firstName ?? '',
                'lastName': _initialCustomer?.lastName ?? '',
                'phone': _initialCustomer?.phone ?? '',
                'district': _initialCustomer?.district ?? '',
                'village': _initialCustomer?.village ?? '',
                'tcKimlikNo': _initialCustomer?.tcKimlikNo ?? '',
              }
            : {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // First name
            FormBuilderTextField(
              name: 'firstName',
              decoration: const InputDecoration(
                labelText: 'Ad*',
                border: OutlineInputBorder(),
              ),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(errorText: 'Ad alanı zorunludur'),
              ]),
            ),
            const SizedBox(height: 16),
            
            // Last name
            FormBuilderTextField(
              name: 'lastName',
              decoration: const InputDecoration(
                labelText: 'Soyad*',
                border: OutlineInputBorder(),
              ),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(errorText: 'Soyad alanı zorunludur'),
              ]),
            ),
            const SizedBox(height: 16),
            
            // Phone
            FormBuilderTextField(
              name: 'phone',
              decoration: const InputDecoration(
                labelText: 'Telefon',
                border: OutlineInputBorder(),
                hintText: '5XX XXX XXXX',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            
            // District
            FormBuilderTextField(
              name: 'district',
              decoration: const InputDecoration(
                labelText: 'İlçe',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Village
            FormBuilderTextField(
              name: 'village',
              decoration: const InputDecoration(
                labelText: 'Köy/Mahalle',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // TC Kimlik No
            FormBuilderTextField(
              name: 'tcKimlikNo',
              decoration: const InputDecoration(
                labelText: 'TC Kimlik No',
                border: OutlineInputBorder(),
                hintText: 'XXXXXXXXXXX',
              ),
              keyboardType: TextInputType.number,
              maxLength: 11,
            ),
            const SizedBox(height: 24),
            
            // Form actions
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(_isEdit ? 'Güncelle' : 'Kaydet'),
              ),
            ),
            const SizedBox(height: 16),
            
            // Cancel button
            SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => context.go(AppConstants.routeCustomers),
                child: const Text('İptal'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final formData = _formKey.currentState!.value;
        
        // Create customer model from form data
        CustomerModel customer = CustomerModel(
          id: _isEdit ? _initialCustomer?.id : null,
          firstName: formData['firstName'],
          lastName: formData['lastName'],
          phone: formData['phone'],
          district: formData['district'],
          village: formData['village'],
          tcKimlikNo: formData['tcKimlikNo'],
        );
        
        // Save or update
        if (_isEdit) {
          await ref.read(customerNotifierProvider.notifier).updateCustomer(customer);
        } else {
          await ref.read(customerNotifierProvider.notifier).createCustomer(customer);
        }
        
        if (!mounted) return;
        
        // Show success message and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Müşteri güncellendi' : 'Müşteri oluşturuldu'),
          ),
        );
        
        context.go(AppConstants.routeCustomers);
      } catch (e) {
        // Show error
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İşlem başarısız: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 