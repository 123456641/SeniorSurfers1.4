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
  final _phoneController =
      TextEditingController(); // Now stores only the number part
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
    // Don't set dial code in the text controller anymore
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
    final phone =
        "${_selectedCountry['dialCode']}${_phoneController.text.trim()}"; // Combine dial code and number
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
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
                    return Card(
                      elevation: 0,
                      color:
                          _selectedCountry['code'] == country['code']
                              ? Colors.blue.shade50
                              : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color:
                              _selectedCountry['code'] == country['code']
                                  ? Colors.blue
                                  : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      child: ListTile(
                        leading: Text(
                          country['flag'],
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(country['name']),
                        trailing: Text(country['dialCode']),
                        onTap: () {
                          setState(() {
                            _selectedCountry = country;
                            _phoneErrorText = null;
                          });
                          Navigator.pop(context);
                        },
                      ),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Image.asset(
                    'assets/images/seniorsurfersLogoNoName.png',
                    height: 100,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Create an Account',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Join our community of active seniors',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 30),
                  _buildInputCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(_firstNameController, 'First Name'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(_lastNameController, 'Last Name'),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _buildTextField(
              _emailController,
              'Email Address',
              type: TextInputType.emailAddress,
              isEmail: true,
              prefixIcon: Icons.email_outlined,
            ),
            const SizedBox(height: 15),
            _buildPhoneField(),
            const SizedBox(height: 15),
            const Text(
              'Security',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildPasswordField(),
            const SizedBox(height: 8),
            if (_passwordStrength.isNotEmpty)
              Row(
                children: [
                  const Text(
                    'Strength: ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  Text(
                    _passwordStrength,
                    style: TextStyle(color: _strengthColor, fontSize: 12),
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
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
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
                          'Create Account',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account?'),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text('Log In'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType type = TextInputType.text,
    bool isEmail = false,
    IconData? prefixIcon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Enter your $label',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        filled: true,
        fillColor: Colors.white,
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
        hintText: 'Enter your number',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        errorText: _phoneErrorText,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        prefixIcon: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _showCountryPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey.shade400, width: 1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedCountry['flag'],
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 4),
                Text(
                  _selectedCountry['dialCode'],
                  style: const TextStyle(fontSize: 14),
                ),
                const Icon(Icons.arrow_drop_down, size: 16),
              ],
            ),
          ),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
      ], // Only digits
      onChanged: (value) {
        // Validate phone number format for the selected country
        final phoneRegex = _getPhoneRegexForCountry(_selectedCountry['code'])
            .toString()
            .replaceAll(r'^\+\d+', '') // Remove dial code part from regex
            .replaceAll(r'$', ''); // Remove end anchor

        setState(() {
          _phoneErrorText =
              RegExp(r'^[0-9]+$').hasMatch(value)
                  ? null
                  : 'Only digits allowed';
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        hintText: 'Re-enter your password',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed:
              () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
