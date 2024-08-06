import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:auto_route/auto_route.dart";


import "../widgets/input_dialog.dart";
import "../utils/login/login_bloc.dart";
import "../utils/settings.dart";
import "../utils/navigation.dart";

@RoutePage()
class LoginScreen extends StatefulWidget {
 const LoginScreen({
  Key ? key
 }): super(key: key);

 @override
 _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State <LoginScreen> {
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
   body: BlocListener <LoginBloc, LoginState> (
    listener: (context, state) {
     if (state is LoginFailure) {
      ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(
       content: Text(state.error),
       duration: const Duration(seconds: 3),
      ));
     } else if (state is LoginSuccess) {
      ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(
       content: Text("Вход выполнен"),
       duration: const Duration(seconds: 3),
      ));
      openMainPage(context);
     }
    },
    child: BlocBuilder<LoginBloc, LoginState> (
     builder: (context, state) => Padding(
       padding: const EdgeInsets.all(16.0),
        child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: < Widget > [
          TextFormField(
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
             labelText: "Password",
             border: OutlineInputBorder(),
            ),
           ),
           const SizedBox(height: 16),
            ElevatedButton(
             onPressed: state is !LoginLoading ?
             () {
              loginBloc.add(
               LoginButtonPressed(
                email: _emailController.text,
                password: _passwordController.text,
                settings: Provider.of<SettingsModel>(context, listen: false),
               ),
              );
             } :
             null,
             child: const Text("Login"),
            ),
            if (state is LoginLoading)
             const Padding(
              padding: EdgeInsets.all(8.0),
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