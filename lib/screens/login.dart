import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:provider/provider.dart";

import "../utils/login/login_bloc.dart";
import "../utils/navigation.dart";
import "../utils/settings.dart";

@RoutePage()
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
  });

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginBloc = BlocProvider.of<LoginBloc>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Вход в систему"),
        automaticallyImplyLeading: false,
      ),
      body: BlocListener<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginFailure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  duration: const Duration(seconds: 3),
                ),
              );
          } else if (state is LoginSuccess) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  content: Text("Вход выполнен"),
                  duration: Duration(seconds: 3),
                ),
              );
            openMainPage(context);
          }
        },
        child: BlocBuilder<LoginBloc, LoginState>(
          builder: (context, state) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Пароль",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: state is! LoginLoading
                      ? () {
                          loginBloc.add(
                            LoginButtonPressed(
                              email: _emailController.text,
                              password: _passwordController.text,
                              settings: Provider.of<SettingsModel>(
                                context,
                                listen: false,
                              ),
                            ),
                          );
                        }
                      : null,
                  child: const Text("Войти"),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: state is! LoginLoading
                      ? () {
                          loginBloc.add(
                            LoginGoogleButtonPressed(
                              settings: Provider.of<SettingsModel>(
                                context,
                                listen: false,
                              ),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(0), shape: StadiumBorder()),
                  child: Image(
                    height: 32,
                    image: const AssetImage("assets/google_sign_in.png"),
                  ),
                ),
                if (state is LoginLoading)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
