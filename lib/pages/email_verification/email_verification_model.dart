import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'email_verification_widget.dart' show EmailVerificationWidget;

class EmailVerificationModel extends FlutterFlowModel<EmailVerificationWidget> {
  final codeFocusNode = FocusNode();
  final codeTextController = TextEditingController();

  bool isLoading = false;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    codeFocusNode.dispose();
    codeTextController.dispose();
  }
}

