import "package:bloc/bloc.dart";
import "package:equatable/equatable.dart";


import "../api_calls.dart";
import "../settings.dart";

part "login_event.dart";
part "login_state.dart";

const googleClientId =
    "249216389685-3fu96ho8vl9r13ovb2cjpgdoa1ipn8bu.apps.googleusercontent.com";

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(LoginInitial()) {
    on<LoginButtonPressed>(_onLoginButtonPressed);
    on<LoginGoogleButtonPressed>(_onLoginGoogleButtonPressed);
  }

  Future<void> _onLoginButtonPressed(
    LoginButtonPressed event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());

    try {
      // Replace this with your own login logic
      // await Future.delayed(const Duration(seconds: 2));

      // event.settings.setAppToken("token");
      await ApiCalls().login(event.email, event.password);
      emit(LoginSuccess());
    } catch (error) {
      emit(LoginFailure(error: error.toString()));
    }
  }

  Future<void> _onLoginGoogleButtonPressed(
    LoginGoogleButtonPressed event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());

    try {
      await ApiCalls().loginGoogle();

      emit(LoginSuccess());
    } catch (error) {
      emit(LoginFailure(error: error.toString()));
    }
  }
}
