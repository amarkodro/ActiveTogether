import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _codeSent = false;
  bool _isLoading = false;

  AuthService _authService(BuildContext context) {
    final apiClient = context.read<ApiClient>();
    final storageService = context.read<StorageService>();
    return AuthService(apiClient, storageService);
  }

  Future<void> _sendCode() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _authService(context).forgotPassword(_emailController.text.trim());
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ako email postoji u sistemu, kod je poslan. Provjeri inbox.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Slanje koda nije uspjelo. Pokušaj ponovo.'),
        ),
      );
    }
  }

  Future<void> _resetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _authService(context).resetPassword(
        email: _emailController.text.trim(),
        code: _codeController.text.trim(),
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lozinka je uspješno promijenjena. Prijavi se sa novom lozinkom.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      String message = 'Reset lozinke nije uspio.';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          message = data['message'].toString();
        }
      }
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zaboravljena lozinka')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: !_codeSent ? _buildEmailStep() : _buildResetStep(),
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Unesite email adresu povezanu sa vašim nalogom. Poslat ćemo vam kod za reset lozinke.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          const Text('Email', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email je obavezan.';
              if (!v.contains('@')) return 'Unesite ispravan email.';
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _sendCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Pošalji kod'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetStep() {
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Kod je poslan na $_emailController.text ako nalog postoji. Unesite kod i novu lozinku.'
                .replaceAll(r'$_emailController.text', _emailController.text),
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          const Text(
            'Kod iz emaila',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '6-cifreni kod',
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Kod je obavezan.' : null,
          ),
          const SizedBox(height: 14),
          const Text(
            'Nova lozinka',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _newPasswordController,
            obscureText: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Nova lozinka je obavezna.';
              if (v.length < 6) return 'Lozinka mora imati bar 6 karaktera.';
              return null;
            },
          ),
          const SizedBox(height: 14),
          const Text(
            'Potvrdi novu lozinku',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            validator: (v) => v != _newPasswordController.text
                ? 'Lozinke se ne podudaraju.'
                : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _resetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Resetuj lozinku'),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _codeSent = false),
            child: const Text('Nisi dobio kod? Pošalji ponovo'),
          ),
        ],
      ),
    );
  }
}
