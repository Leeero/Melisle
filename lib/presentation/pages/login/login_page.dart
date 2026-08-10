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
    return Scaffold(
      backgroundColor: AppColorTokens.lightScaffold,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = AppBreakpoints.isCompactWidth(constraints.maxWidth);
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 20 : 40,
                vertical: compact ? 24 : 40,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - (compact ? 48 : 80),
                ),
                child: Center(
                  child: BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      return _LoginCard(
                        formKey: _formKey,
                        serverUrlController: _serverUrlController,
                        usernameController: _usernameController,
                        passwordController: _passwordController,
                        obscurePassword: _obscurePassword,
                        status: state.status,
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
    required this.formKey,
    required this.serverUrlController,
    required this.usernameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.status,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController serverUrlController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final AuthStatus status;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  bool get _isLoading => status == AuthStatus.loading;
  bool get _hasError => status == AuthStatus.failure;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      key: const ValueKey('v3-login-card'),
      width: 480,
      padding: const EdgeInsets.fromLTRB(40, 38, 40, 40),
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
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _BrandHeader(),
            if (_hasError) ...[
              const SizedBox(height: 20),
              const _LoginErrorBanner(),
            ],
            const SizedBox(height: 28),
            _LoginField(
              label: '服务器地址',
              controller: serverUrlController,
              hintText: 'https://music.example.com',
              icon: Icons.dns_outlined,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? '请输入服务器地址' : null,
            ),
            const SizedBox(height: 16),
            _LoginField(
              label: '用户名',
              controller: usernameController,
              hintText: '输入用户名',
              icon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? '请输入用户名' : null,
            ),
            const SizedBox(height: 16),
            _LoginField(
              label: '密码',
              controller: passwordController,
              hintText: '输入密码',
              icon: Icons.lock_outline_rounded,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              enabled: !_isLoading,
              onSubmitted: (_) => _isLoading ? null : onSubmit(),
              suffixIcon: IconButton(
                tooltip: obscurePassword ? '显示密码' : '隐藏密码',
                onPressed: _isLoading ? null : onTogglePassword,
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
            const SizedBox(height: 22),
            SizedBox(
              height: 48,
              child: FilledButton(
                key: const ValueKey('v3-login-submit'),
                onPressed: _isLoading ? null : onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColorTokens.lightPrimary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColorTokens.lightPrimary,
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _LoginButtonContent(
                  isLoading: _isLoading,
                  hasError: _hasError,
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
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const _LoginLogo(),
        const SizedBox(height: 14),
        Text(
          'Melisle 乐岛',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '连接您的个人音乐服务器',
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
        ),
      ],
    );
  }
}

class _LoginLogo extends StatelessWidget {
  const _LoginLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('v3-login-logo'),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColorTokens.lightPrimary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.library_music_rounded,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}

class _LoginErrorBanner extends StatelessWidget {
  const _LoginErrorBanner();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: '连接失败，请检查服务器地址、登录凭据或网络连接。',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColorTokens.lightMusicRoseSoft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColorTokens.lightMusicRose),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 20,
              color: AppColorTokens.lightMusicRose,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '连接失败，请检查服务器地址、登录凭据或网络连接。',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: AppColorTokens.lightMusicRose,
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
            fillColor: AppColorTokens.lightSurfaceHighest,
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
              borderSide: const BorderSide(
                color: AppColorTokens.lightPrimary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
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
