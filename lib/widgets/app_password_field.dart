import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

class AppPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData? icon;
  final bool enabled;
  final bool showLabel;
  final bool outlineBorder;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final Duration autoHideDuration;
  final Key? textFieldKey;

  const AppPasswordField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    this.icon = Icons.lock_outline_rounded,
    this.enabled = true,
    this.showLabel = true,
    this.outlineBorder = false,
    this.validator,
    this.textInputAction,
    this.onChanged,
    this.onFieldSubmitted,
    this.autoHideDuration = const Duration(seconds: 10),
    this.textFieldKey,
  });

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField>
    with WidgetsBindingObserver {
  final FocusNode _focusNode = FocusNode();
  Timer? _autoHideTimer;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoHideTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _hidePassword(unfocus: true);
      case AppLifecycleState.resumed:
        break;
    }
  }

  void _toggleVisibility() {
    final selection = widget.controller.selection;
    setState(() {
      _isVisible = !_isVisible;
    });
    _restoreSelection(selection);

    if (_isVisible) {
      _startAutoHideTimer();
    } else {
      _autoHideTimer?.cancel();
    }

    SemanticsService.announce(
      _isVisible ? 'Password is visible' : 'Password is hidden',
      Directionality.of(context),
    );
  }

  void _startAutoHideTimer() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(widget.autoHideDuration, _hidePassword);
  }

  void _hidePassword({bool unfocus = false}) {
    if (!_isVisible || !mounted) {
      return;
    }

    final selection = widget.controller.selection;
    setState(() {
      _isVisible = false;
    });
    _autoHideTimer?.cancel();
    _restoreSelection(selection);

    if (unfocus) {
      _focusNode.unfocus();
    }
  }

  void _restoreSelection(TextSelection selection) {
    if (!selection.isValid) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || selection.end > widget.controller.text.length) {
        return;
      }
      widget.controller.selection = selection;
    });
  }

  @override
  Widget build(BuildContext context) {
    final passwordField = TextFormField(
      key: widget.textFieldKey,
      controller: widget.controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      obscureText: !_isVisible,
      enableSuggestions: false,
      autocorrect: false,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: InputDecoration(
        labelText: widget.showLabel ? null : widget.label,
        hintText: widget.hintText,
        prefixIcon: widget.icon == null ? null : Icon(widget.icon),
        border: widget.outlineBorder ? const OutlineInputBorder() : null,
        suffixIcon: IconButton(
          tooltip: _isVisible ? 'Hide password' : 'Show password',
          onPressed: widget.enabled ? _toggleVisibility : null,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: Icon(
              _isVisible
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              key: ValueKey<bool>(_isVisible),
            ),
          ),
        ),
      ),
    );

    if (!widget.showLabel) {
      return passwordField;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        passwordField,
      ],
    );
  }
}
