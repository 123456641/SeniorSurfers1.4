import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _supabase = Supabase.instance.client;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final _nameRegex = RegExp(r'^[a-zA-Z\s]+$');
  String? _phoneErrorText;

  final List<Map<String, dynamic>> _countries = [
    {'code': 'US', 'name': 'United States', 'dialCode': '+1', 'flag': '🇺🇸'},
    {'code': 'CN', 'name': 'China', 'dialCode': '+86', 'flag': '🇨🇳'},
    {'code': 'JP', 'name': 'Japan', 'dialCode': '+81', 'flag': '🇯🇵'},
    {'code': 'PH', 'name': 'Philippines', 'dialCode': '+63', 'flag': '🇵🇭'},
  ];

  Map<String, dynamic> _selectedCountry = {
    'code': 'PH',
    'name': 'Philippines',
    'dialCode': '+63',
    'flag': '🇵🇭',
  };

  String _passwordStrength = '';
  Color _strengthColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _phoneController.text = _selectedCountry['dialCode'];
  }

  void _checkPasswordStrength(String password) {
    String strength;
    Color color;

    if (password.isEmpty) {
      strength = '';
      color = Colors.grey;
    } else if (password.length < 6) {
      strength = 'Too short';
      color = Colors.red;
    } else if (!RegExp(r'^(?=.*[A-Z])').hasMatch(password)) {
      strength = 'Add uppercase';
      color = Colors.orange;
    } else if (!RegExp(r'^(?=.*[a-z])').hasMatch(password)) {
      strength = 'Add lowercase';
      color = Colors.orange;
    } else if (!RegExp(r'^(?=.*\d)').hasMatch(password)) {
      strength = 'Add number';
      color = Colors.orange;
    } else if (!RegExp(r'^(?=.*[!@#\$&*~])').hasMatch(password)) {
      strength = 'Add special character';
      color = Colors.orange;
    } else if (password.length < 8) {
      strength = 'Weak';
      color = Colors.orange;
    } else {
      strength = 'Strong';
      color = Colors.green;
    }

    setState(() {
      _passwordStrength = strength;
      _strengthColor = color;
    });
  }

  Future<void> _signUp() async {
    FocusScope.of(context).unfocus();

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (firstName.isEmpty || !_nameRegex.hasMatch(firstName)) {
      _showSnackBar('First name must only contain letters and spaces');
      return;
    }

    if (lastName.isEmpty || !_nameRegex.hasMatch(lastName)) {
      _showSnackBar('Last name must only contain letters and spaces');
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar('Passwords do not match');
      return;
    }

    final passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~]).{8,}$',
    );
    if (!passwordRegex.hasMatch(password)) {
      _showSnackBar(
        'Password must be at least 8 characters long and include:\n'
        '- 1 uppercase letter\n- 1 lowercase letter\n- 1 number\n- 1 special character',
        duration: 5,
      );
      return;
    }

    final phoneRegex = _getPhoneRegexForCountry(_selectedCountry['code']);
    if (!phoneRegex.hasMatch(phone)) {
      setState(() {
        _phoneErrorText =
            'Please enter a valid ${_selectedCountry['name']} phone number';
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Step 1: Sign up with auth - this creates the auth user
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'phone': phone,
          'email': email, // Make sure email is in the metadata
        },
      );

      if (authResponse.user?.id == null) {
        throw Exception('User creation failed - no user ID returned');
      }

      // No need to manually insert into users table!
      // Supabase has a "users" table trigger that automatically
      // creates a profile when a new user signs up

      // If you absolutely need to update the user profile with additional fields,
      // use the RPC function approach which bypasses RLS

      if (authResponse.session == null) {
        _showSnackBar(
          'Account created! Please check your email to confirm.',
          color: Colors.green,
          duration: 4,
        );
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      } else {
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      }
    } on AuthException catch (e) {
      _showSnackBar(
        e.message.contains('User already registered')
            ? 'Email already in use. Try logging in.'
            : 'Signup failed: ${e.message}',
      );
    } on PostgrestException catch (e) {
      _showSnackBar('Database error: ${e.message}');
    } catch (e) {
      _showSnackBar('An unexpected error occurred: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {Color? color, int duration = 3}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? Colors.red,
        duration: Duration(seconds: duration),
      ),
    );
  }

  RegExp _getPhoneRegexForCountry(String countryCode) {
    switch (countryCode) {
      case 'US':
        return RegExp(r'^\+1\d{10}$');
      case 'CN':
        return RegExp(r'^\+86\d{11}$');
      case 'JP':
        return RegExp(r'^\+81\d{9,10}$');
      case 'PH':
        return RegExp(r'^\+63\d{9,10}$');
      default:
        return RegExp(r'^\+?\d{8,15}$');
    }
  }

  Future<void> _showCountryPicker() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Select Country',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _countries.length,
                  itemBuilder: (context, index) {
                    final country = _countries[index];
                    return ListTile(
                      leading: Text(
                        country['flag'],
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(country['name']),
                      trailing: Text(country['dialCode']),
                      onTap: () {
                        setState(() {
                          _selectedCountry = country;
                          if (!_phoneController.text.startsWith(
                            country['dialCode'],
                          )) {
                            _phoneController.text = country['dialCode'];
                          }
                          _phoneErrorText = null;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue.shade50,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Image.asset(
                  'assets/images/seniorsurfersLogoNoName.png',
                  height: 120,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Create an Account',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                _buildTextField(_firstNameController, 'First Name'),
                const SizedBox(height: 15),
                _buildTextField(_lastNameController, 'Last Name'),
                const SizedBox(height: 15),
                _buildTextField(
                  _emailController,
                  'Email Address',
                  type: TextInputType.emailAddress,
                  isEmail: true,
                ),
                const SizedBox(height: 15),
                _buildPhoneField(),
                const SizedBox(height: 15),
                _buildPasswordField(),
                const SizedBox(height: 8),
                if (_passwordStrength.isNotEmpty)
                  Row(
                    children: [
                      const Text(
                        'Strength: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _passwordStrength,
                        style: TextStyle(color: _strengthColor),
                      ),
                    ],
                  ),
                const SizedBox(height: 15),
                _buildConfirmPasswordField(),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              'Sign Up',
                              style: TextStyle(fontSize: 18),
                            ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType type = TextInputType.text,
    bool isEmail = false,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Enter your $label',
        border: const OutlineInputBorder(),
      ),
      keyboardType: type,
      textCapitalization:
          isEmail ? TextCapitalization.none : TextCapitalization.words,
      inputFormatters:
          isEmail
              ? []
              : [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
    );
  }

  Widget _buildPhoneField() {
    return TextField(
      controller: _phoneController,
      decoration: InputDecoration(
        labelText: 'Phone Number',
        hintText: 'Enter your phone number',
        border: const OutlineInputBorder(),
        errorText: _phoneErrorText,
        prefixIcon: GestureDetector(
          onTap: _showCountryPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedCountry['flag'],
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Text(_selectedCountry['dialCode']),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ),
      keyboardType: TextInputType.phone,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[+\d]'))],
      onChanged: (value) {
        setState(() {
          _phoneErrorText =
              RegExp(r'^[+\d]+$').hasMatch(value)
                  ? null
                  : 'Only digits allowed (no letters or symbols)';
        });
      },
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      onChanged: _checkPasswordStrength,
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Create a secure password',
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed:
              () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
        ),
      ),
    );
  }
}
