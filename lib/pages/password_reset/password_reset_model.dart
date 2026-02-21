import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'password_reset_widget.dart' show PasswordResetWidget;

class PasswordResetModel extends FlutterFlowModel<PasswordResetWidget> {
  final emailFocusNode = FocusNode();
  final emailTextController = TextEditingController();

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    emailFocusNode.dispose();
    emailTextController.dispose();
  }
}
