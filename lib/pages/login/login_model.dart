import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'login_widget.dart' show LoginWidget;

class LoginModel extends FlutterFlowModel<LoginWidget> {
  final emailFocusNode = FocusNode();
  final emailTextController = TextEditingController();
  final passwordFocusNode = FocusNode();
  final passwordTextController = TextEditingController();
  bool isLoading = false;
  bool obscurePassword = true;
  /// True if user has signed in at least once (persisted); used to show "Welcome Back" after session expiry.
  bool userHasSignedInBefore = false;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    emailFocusNode.dispose();
    emailTextController.dispose();
    passwordFocusNode.dispose();
    passwordTextController.dispose();
  }
}
