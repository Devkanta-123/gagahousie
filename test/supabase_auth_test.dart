import 'package:flutter_test/flutter_test.dart';
import 'package:gaga_housie/models/user_model.dart';
import 'package:gaga_housie/services/supabase_config.dart';
import 'package:gaga_housie/services/supabase_service.dart';
import 'package:gaga_housie/utils/validators.dart';
import 'package:gaga_housie/providers/auth_provider.dart';

void main() {
  group('AuthValidator Tests', () {
    test('validateFullName validates required length and characters', () {
      expect(AuthValidator.validateFullName(null), 'Please enter your full name');
      expect(AuthValidator.validateFullName(''), 'Please enter your full name');
      expect(AuthValidator.validateFullName('   '), 'Please enter your full name');
      expect(AuthValidator.validateFullName('Jo'), 'Full name must be at least 3 characters');
      expect(AuthValidator.validateFullName('John Doe'), isNull);
      expect(AuthValidator.validateFullName('Devkanta Singh'), isNull);
      expect(AuthValidator.validateFullName('John123'), 'Full name should only contain letters and spaces');
    });

    test('validateEmail validates email addresses accurately', () {
      expect(AuthValidator.validateEmail(null), 'Please enter your email address');
      expect(AuthValidator.validateEmail(''), 'Please enter your email address');
      expect(AuthValidator.validateEmail('invalid-email'), contains('valid email address'));
      expect(AuthValidator.validateEmail('test@'), contains('valid email address'));
      expect(AuthValidator.validateEmail('test@domain'), contains('valid email address'));
      expect(AuthValidator.validateEmail('admin@gmail.com'), isNull);
      expect(AuthValidator.validateEmail('user.name+tag@example.co.uk'), isNull);
    });

    test('validatePhone strictly enforces 10 digits', () {
      expect(AuthValidator.validatePhone(null), 'Please enter your 10-digit mobile number');
      expect(AuthValidator.validatePhone(''), 'Please enter your 10-digit mobile number');
      expect(AuthValidator.validatePhone('12345'), 'Phone number must be exactly 10 digits');
      expect(AuthValidator.validatePhone('12345678901'), 'Phone number must be exactly 10 digits');
      expect(AuthValidator.validatePhone('98765abcde'), 'Phone number must contain only numbers');
      expect(AuthValidator.validatePhone('9876543210'), isNull);
      expect(AuthValidator.validatePhone('(987) 654-3210'), isNull);
      expect(AuthValidator.cleanPhone('(987) 654-3210'), '9876543210');
    });

    test('validatePassword requires minimum length', () {
      expect(AuthValidator.validatePassword(null), 'Please enter your password');
      expect(AuthValidator.validatePassword(''), 'Please enter your password');
      expect(AuthValidator.validatePassword('123'), 'Password must be at least 4 characters');
      expect(AuthValidator.validatePassword('1234'), isNull);
      expect(AuthValidator.validatePassword('secret123'), isNull);
    });

    test('validateConfirmPassword ensures passwords match', () {
      expect(AuthValidator.validateConfirmPassword('pass123', null), 'Please confirm your password');
      expect(AuthValidator.validateConfirmPassword('pass123', ''), 'Please confirm your password');
      expect(AuthValidator.validateConfirmPassword('pass123', 'pass456'), 'Passwords do not match');
      expect(AuthValidator.validateConfirmPassword('pass123', 'pass123'), isNull);
    });

    test('validateLoginIdentifier accepts valid email or 10-digit phone', () {
      expect(AuthValidator.validateLoginIdentifier(null), 'Please enter your email or 10-digit mobile number');
      expect(AuthValidator.validateLoginIdentifier(''), 'Please enter your email or 10-digit mobile number');
      expect(AuthValidator.validateLoginIdentifier('admin@gmail.com'), isNull);
      expect(AuthValidator.validateLoginIdentifier('9876543210'), isNull);
      expect(AuthValidator.validateLoginIdentifier('98765'), 'Enter a valid email or 10-digit mobile number');
      expect(AuthValidator.validateLoginIdentifier('not-an-email'), 'Enter a valid email or 10-digit mobile number');
    });
  });

  group('Supabase Configuration & UserModel Tests', () {
    test('SupabaseConfig holds user_auth table and columns', () {
      expect(SupabaseConfig.userAuthTable, 'user_auth');
      expect(SupabaseConfig.colFullName, 'fullname');
      expect(SupabaseConfig.colEmail, 'email');
      expect(SupabaseConfig.colPhone, 'phone');
      expect(SupabaseConfig.colPassword, 'password');
      expect(SupabaseConfig.colStatus, 'status');
      expect(SupabaseConfig.colRole, 'role');
    });

    test('UserModel defaults status to active and role to user, with admin role for admin@gmail.com', () {
      final user = UserModel(
        fullName: 'Devkanta Singh',
        email: 'devkanta@gmail.com',
        phone: '9876543210',
        password: 'securePassword',
      );

      expect(user.status, 'active');
      expect(user.role, 'user');
      expect(user.isActive, isTrue);
      expect(user.isUser, isTrue);
      expect(user.isAdmin, isFalse);

      final json = user.toJson();
      expect(json['fullname'], 'Devkanta Singh');
      expect(json['email'], 'devkanta@gmail.com');
      expect(json['phone'], '9876543210');
      expect(json['password'], 'securePassword');
      expect(json['status'], 'active');
      expect(json['role'], 'user');
      expect(user.mobileNumber, '9876543210');

      // fromJson with regular user
      final fromJsonDefault = UserModel.fromJson({
        'fullname': 'Devkanta Singh',
        'email': 'devkanta@gmail.com',
        'phone': '9876543210',
        'password': 'securePassword',
      });
      expect(fromJsonDefault.status, 'active');
      expect(fromJsonDefault.role, 'user');
      expect(fromJsonDefault.isUser, isTrue);
      expect(fromJsonDefault.isAdmin, isFalse);

      // fromJson with admin@gmail.com defaults role to admin
      final fromJsonAdmin = UserModel.fromJson({
        'fullname': 'GaGa Admin',
        'email': 'admin@gmail.com',
        'phone': '9876543210',
        'password': 'securePassword',
      });
      expect(fromJsonAdmin.role, 'admin');
      expect(fromJsonAdmin.isAdmin, isTrue);
      expect(fromJsonAdmin.isUser, isFalse);

      // fromJson with explicit admin role
      final fromJsonCustomAdmin = UserModel.fromJson({
        'fullname': 'Super Admin',
        'email': 'super@gaga.com',
        'phone': '9876543210',
        'password': 'securePassword',
        'role': 'admin',
      });
      expect(fromJsonCustomAdmin.role, 'admin');
      expect(fromJsonCustomAdmin.isAdmin, isTrue);

      // copyWith role and status
      final updated = user.copyWith(status: 'inactive', role: 'admin');
      expect(updated.status, 'inactive');
      expect(updated.role, 'admin');
      expect(updated.isAdmin, isTrue);
    });
  });

  group('AuthProvider Real-Time OTP & Supabase Integration Tests', () {
    test('sendRealTimeRegistrationOtp generates 6-digit code and activates OTP state', () {
      final auth = AuthProvider();
      expect(auth.activeRegistrationOtp, isNull);

      final otp = auth.sendRealTimeRegistrationOtp(
        phone: '9876543210',
        name: 'Devkanta Singh',
      );

      expect(otp.length, 6);
      expect(RegExp(r'^\d{6}$').hasMatch(otp), isTrue);
      expect(auth.activeRegistrationOtp, otp);

      // Verify matching OTP succeeds
      expect(auth.verifyRegistrationOtp(otp), isTrue);
      expect(auth.isOtpVerified, isTrue);

      // Verify wrong OTP fails
      expect(auth.verifyRegistrationOtp('000000'), isFalse);
    });

    test('login without initialized DB returns clear database connection error', () async {
      final auth = AuthProvider();
      final success = await auth.login('admin@gmail.com', '1234');
      expect(success, isFalse);
      expect(auth.isLoggedIn, isFalse);
      expect(auth.errorMessage, isNotNull);
    });

    test('register rejects invalid phone length before network call', () async {
      final auth = AuthProvider();
      final success = await auth.register(
        'Devkanta Singh',
        'devkanta@test.com',
        '12345', // Only 5 digits
        'password123',
      );
      expect(success, isFalse);
      expect(auth.errorMessage, contains('10 digits'));
    });
  });
}
