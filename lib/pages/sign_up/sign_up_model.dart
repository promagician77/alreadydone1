import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'sign_up_widget.dart' show SignUpWidget;

class SignUpModel extends FlutterFlowModel<SignUpWidget> {
  final nameFocusNode = FocusNode();
  final nameTextController = TextEditingController();
  final emailFocusNode = FocusNode();
  final emailTextController = TextEditingController();
  final passwordFocusNode = FocusNode();
  final passwordTextController = TextEditingController();
  final confirmPasswordFocusNode = FocusNode();
  final confirmPasswordTextController = TextEditingController();
  bool termsAccepted = false;
  bool isLoading = false;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    nameFocusNode.dispose();
    nameTextController.dispose();
    emailFocusNode.dispose();
    emailTextController.dispose();
    passwordFocusNode.dispose();
    passwordTextController.dispose();
    confirmPasswordFocusNode.dispose();
    confirmPasswordTextController.dispose();
  }
}
