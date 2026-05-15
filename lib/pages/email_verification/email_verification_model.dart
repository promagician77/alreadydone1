import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'email_verification_widget.dart' show EmailVerificationWidget;

class EmailVerificationModel extends FlutterFlowModel<EmailVerificationWidget> {
  final codeFocusNode = FocusNode();
  final codeTextController = TextEditingController();
  final passwordFocusNode = FocusNode();
  final passwordTextController = TextEditingController();
  final confirmPasswordFocusNode = FocusNode();
  final confirmPasswordTextController = TextEditingController();

  bool isLoading = false;
  bool recoveryOtpVerified = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    codeFocusNode.dispose();
    codeTextController.dispose();
    passwordFocusNode.dispose();
    passwordTextController.dispose();
    confirmPasswordFocusNode.dispose();
    confirmPasswordTextController.dispose();
  }
}
