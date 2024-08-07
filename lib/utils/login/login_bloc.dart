import "package:bloc/bloc.dart";
import "package:equatable/equatable.dart";

import "../api_calls.dart";
import "../settings.dart";

part "login_event.dart";
part "login_state.dart";

class LoginBloc extends Bloc<LoginEvent, LoginState> {

  LoginBloc() : super(LoginInitial()) {
    on<LoginButtonPressed>(_onLoginButtonPressed);
  }

  Future<void> _onLoginButtonPressed(LoginButtonPressed event, Emitter<LoginState> emit) async {
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

  // @override
  // Stream<LoginState> mapEventToState(LoginEvent event) async* {
  //   if (event is LoginButtonPressed) {
  //     yield LoginLoading();

  //     try {
  //       // Replace this with your own login logic
  //       await Future.delayed(const Duration(seconds: 2));
  //       yield LoginSuccess();
  //     } catch (error) {
  //       yield LoginFailure(error: error.toString());
  //     }
  //   }
  // }
}
