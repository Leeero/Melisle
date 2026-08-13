import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cross_platform_music_player/presentation/blocs/auth/auth_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/auth/auth_state.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _serverUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: const ValueKey('v3-login-capture'),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = AppBreakpoints.isCompactWidth(
                constraints.maxWidth,
              );
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 40,
                  vertical: compact ? 10 : 40,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - (compact ? 20 : 80),
                  ),
                  child: Center(
                    child: BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, state) {
                        return _LoginCard(
                          compact: compact,
                          formKey: _formKey,
                          serverUrlController: _serverUrlController,
                          usernameController: _usernameController,
                          passwordController: _passwordController,
                          obscurePassword: _obscurePassword,
                          status: state.status,
                          errorMessage: state.errorMessage,
                          onTogglePassword: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          onSubmit: _submit,
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<AuthCubit>().login(
      serverUrl: _serverUrlController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.compact,
    required this.formKey,
    required this.serverUrlController,
    required this.usernameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.status,
    required this.errorMessage,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  final bool compact;
  final GlobalKey<FormState> formKey;
  final TextEditingController serverUrlController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final AuthStatus status;
  final String? errorMessage;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  bool get _isLoading => status == AuthStatus.loading;
  bool get _hasError => status == AuthStatus.failure;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final content = Form(
      key: formKey,
      child: compact
          ? _MobileLoginContent(
              serverUrlController: serverUrlController,
              usernameController: usernameController,
              passwordController: passwordController,
              obscurePassword: obscurePassword,
              isLoading: _isLoading,
              hasError: _hasError,
              errorMessage: errorMessage,
              onTogglePassword: onTogglePassword,
              onSubmit: onSubmit,
            )
          : _DesktopLoginContent(
              serverUrlController: serverUrlController,
              usernameController: usernameController,
              passwordController: passwordController,
              obscurePassword: obscurePassword,
              isLoading: _isLoading,
              hasError: _hasError,
              errorMessage: errorMessage,
              onTogglePassword: onTogglePassword,
              onSubmit: onSubmit,
            ),
    );

    if (compact) {
      return Container(
        key: const ValueKey('v3-login-card'),
        width: 390,
        height: 764,
        padding: const EdgeInsets.fromLTRB(12, 54, 12, 16),
        color: colors.surface,
        child: content,
      );
    }

    return Container(
      key: const ValueKey('v3-login-card'),
      width: 480,
      constraints: const BoxConstraints(minHeight: 620),
      padding: const EdgeInsets.fromLTRB(40, 28, 40, 24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.56),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: content,
    );
  }
}

class _DesktopLoginContent extends StatelessWidget {
  const _DesktopLoginContent({
    required this.serverUrlController,
    required this.usernameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.hasError,
    required this.errorMessage,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  final TextEditingController serverUrlController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _BrandHeader(),
        if (hasError) ...[
          const SizedBox(height: 14),
          _LoginErrorBanner(message: errorMessage),
        ],
        SizedBox(height: hasError ? 10 : 28),
        _LoginField(
          label: '服务器地址',
          controller: serverUrlController,
          hintText: 'https://music.example.com',
          icon: Icons.dns_outlined,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          enabled: !isLoading,
          validator: (value) =>
              value == null || value.trim().isEmpty ? '请输入服务器地址' : null,
        ),
        const SizedBox(height: 12),
        _LoginField(
          label: '用户名',
          controller: usernameController,
          hintText: '输入用户名',
          icon: Icons.person_outline_rounded,
          textInputAction: TextInputAction.next,
          enabled: !isLoading,
          validator: (value) =>
              value == null || value.trim().isEmpty ? '请输入用户名' : null,
        ),
        const SizedBox(height: 12),
        _LoginField(
          label: '密码',
          controller: passwordController,
          hintText: '输入密码',
          icon: Icons.lock_outline_rounded,
          obscureText: obscurePassword,
          textInputAction: TextInputAction.done,
          enabled: !isLoading,
          onSubmitted: (_) => isLoading ? null : onSubmit(),
          suffixIcon: IconButton(
            tooltip: obscurePassword ? '显示密码' : '隐藏密码',
            onPressed: isLoading ? null : onTogglePassword,
            icon: Icon(
              obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 19,
            ),
          ),
          validator: (value) =>
              value == null || value.isEmpty ? '请输入密码或 API Token' : null,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: FilledButton(
            key: const ValueKey('v3-login-submit'),
            onPressed: isLoading ? null : onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: colors.primaryContainer,
              foregroundColor: colors.onPrimaryContainer,
              disabledBackgroundColor: colors.primaryContainer,
              disabledForegroundColor: colors.onPrimaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _LoginButtonContent(
              isLoading: isLoading,
              hasError: hasError,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 15,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '自动识别 Emby、Navidrome 或 Subsonic/OpenSubsonic',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MobileLoginContent extends StatelessWidget {
  const _MobileLoginContent({
    required this.serverUrlController,
    required this.usernameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.hasError,
    required this.errorMessage,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  final TextEditingController serverUrlController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _BrandHeader(mobile: true),
        const SizedBox(height: 30),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: .4),
            ),
          ),
          child: Column(
            children: [
              _MobileField(
                label: '服务器',
                controller: serverUrlController,
                hintText: 'https://music.example.com',
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                enabled: !isLoading,
                validator: _serverValidator,
              ),
              Divider(
                height: 1,
                color: colors.outlineVariant.withValues(alpha: .45),
              ),
              _MobileField(
                label: '用户名',
                controller: usernameController,
                hintText: '输入用户名',
                textInputAction: TextInputAction.next,
                enabled: !isLoading,
                validator: _usernameValidator,
              ),
              Divider(
                height: 1,
                color: colors.outlineVariant.withValues(alpha: .45),
              ),
              _MobileField(
                label: '密码',
                controller: passwordController,
                hintText: '输入密码',
                textInputAction: TextInputAction.done,
                enabled: !isLoading,
                obscureText: obscurePassword,
                onSubmitted: (_) => isLoading ? null : onSubmit(),
                validator: _passwordValidator,
                suffixIcon: IconButton(
                  tooltip: obscurePassword ? '显示密码' : '隐藏密码',
                  onPressed: isLoading ? null : onTogglePassword,
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 19,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Icon(Icons.check_circle_outline, size: 14, color: colors.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Navidrome / Subsonic 协议已就绪',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        ),
        if (hasError) ...[
          const SizedBox(height: 18),
          _LoginErrorBanner(message: errorMessage),
        ],
        const Spacer(),
        SizedBox(
          height: 50,
          child: FilledButton(
            key: const ValueKey('v3-login-submit'),
            onPressed: isLoading ? null : onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: colors.primaryContainer,
              foregroundColor: colors.onPrimaryContainer,
              disabledBackgroundColor: colors.primaryContainer,
              disabledForegroundColor: colors.onPrimaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _LoginButtonContent(
              isLoading: isLoading,
              hasError: hasError,
            ),
          ),
        ),
      ],
    );
  }
}

String? _serverValidator(String? value) =>
    value == null || value.trim().isEmpty ? '请输入服务器地址' : null;
String? _usernameValidator(String? value) =>
    value == null || value.trim().isEmpty ? '请输入用户名' : null;
String? _passwordValidator(String? value) =>
    value == null || value.isEmpty ? '请输入密码或 API Token' : null;

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({this.mobile = false});

  final bool mobile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        _LoginLogo(mobile: mobile),
        SizedBox(height: mobile ? 18 : 14),
        Text(
          'Melisle 乐岛',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontSize: mobile ? 31 : 26,
            fontWeight: mobile ? FontWeight.w700 : FontWeight.w600,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          mobile ? '个人音乐服务器' : '连接您的个人音乐服务器',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: mobile ? 15 : 13,
          ),
        ),
      ],
    );
  }
}

class _LoginLogo extends StatelessWidget {
  const _LoginLogo({this.mobile = false});

  final bool mobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('v3-login-logo'),
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(mobile ? 20 : 16),
      ),
      child: const Icon(
        Icons.library_music_rounded,
        color: Colors.white,
        size: 32,
      ),
    );
  }
}

class _LoginErrorBanner extends StatelessWidget {
  const _LoginErrorBanner({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: message ?? '连接失败，请检查服务器地址、登录凭据或网络连接。',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.error.withValues(alpha: .2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.error,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                message ?? '连接失败，请检查服务器地址、登录凭据或网络连接。',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.label,
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.textInputAction,
    required this.enabled,
    required this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final bool enabled;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontSize: 12,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          enabled: enabled,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, size: 19),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: colors.surfaceContainerHigh,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            constraints: const BoxConstraints(minHeight: 48),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileField extends StatelessWidget {
  const _MobileField({
    required this.label,
    required this.controller,
    required this.hintText,
    required this.textInputAction,
    required this.enabled,
    required this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final bool enabled;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      enabled: enabled,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: colors.surfaceContainerLowest,
        constraints: const BoxConstraints(minHeight: 66),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.primary),
        ),
      ),
    );
  }
}

class _LoginButtonContent extends StatelessWidget {
  const _LoginButtonContent({required this.isLoading, required this.hasError});

  final bool isLoading;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 10),
          Text('正在连接…'),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasError) ...[
          const Icon(Icons.refresh_rounded, size: 20),
          const SizedBox(width: 8),
        ],
        Text(hasError ? '重新连接' : '连接服务器'),
      ],
    );
  }
}
