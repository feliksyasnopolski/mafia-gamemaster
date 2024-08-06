part of 'login_bloc.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object> get props => [];
}

class LoginButtonPressed extends LoginEvent {
  final String email;
  final String password;
  SettingsModel settings;

  LoginButtonPressed({required this.email, required this.password, required this.settings});

  @override
  List<Object> get props => [email, password];

  @override
  String toString() => 'LoginButtonPressed { email: $email, password: $password }';
}