import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cross_platform_music_player/domain/entities/auth_session.dart';
import 'package:cross_platform_music_player/presentation/blocs/auth/auth_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/auth/auth_state.dart';
import 'package:cross_platform_music_player/presentation/widgets/controls/app_form_field.dart';
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
  bool _manualBackendSelectorExpanded = false;
  MusicBackendType? _selectedBackendType;

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
              final useSplitLayout =
                  constraints.maxWidth >= AppBreakpoints.desktopMinWidth &&
                  constraints.maxHeight >= 680;

              if (useSplitLayout) {
                return BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    return _WideDesktopLogin(
                      formKey: _formKey,
                      serverUrlController: _serverUrlController,
                      usernameController: _usernameController,
                      passwordController: _passwordController,
                      obscurePassword: _obscurePassword,
                      status: state.status,
                      errorMessage: state.errorMessage,
                      recoveryOptions: _recoveryOptions,
                      onTogglePassword: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      onSubmit: _submit,
                    );
                  },
                );
              }

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 16 : 40,
                  vertical: compact ? 20 : 40,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - (compact ? 40 : 80),
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
                          recoveryOptions: _recoveryOptions,
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
    if (_manualBackendSelectorExpanded && _selectedBackendType == null) return;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<AuthCubit>().login(
      serverUrl: _serverUrlController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      preferredBackendType: _manualBackendSelectorExpanded
          ? _selectedBackendType
          : null,
    );
  }

  _LoginRecoveryOptions get _recoveryOptions => _LoginRecoveryOptions(
    expanded: _manualBackendSelectorExpanded,
    selectedBackendType: _selectedBackendType,
    onExpand: () => setState(() => _manualBackendSelectorExpanded = true),
    onBackendSelected: (backendType) =>
        setState(() => _selectedBackendType = backendType),
    onUseAutomaticDetection: () => setState(() {
      _manualBackendSelectorExpanded = false;
      _selectedBackendType = null;
    }),
  );
}

class _LoginRecoveryOptions {
  const _LoginRecoveryOptions({
    required this.expanded,
    required this.selectedBackendType,
    required this.onExpand,
    required this.onBackendSelected,
    required this.onUseAutomaticDetection,
  });

  final bool expanded;
  final MusicBackendType? selectedBackendType;
  final VoidCallback onExpand;
  final ValueChanged<MusicBackendType?> onBackendSelected;
  final VoidCallback onUseAutomaticDetection;

  bool get canSubmit => !expanded || selectedBackendType != null;
}

class _WideDesktopLogin extends StatelessWidget {
  const _WideDesktopLogin({
    required this.formKey,
    required this.serverUrlController,
    required this.usernameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.status,
    required this.errorMessage,
    required this.recoveryOptions,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController serverUrlController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final AuthStatus status;
  final String? errorMessage;
  final _LoginRecoveryOptions recoveryOptions;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLoading = status == AuthStatus.loading;
    final hasError = status == AuthStatus.failure;

    return Row(
      key: const ValueKey('v3-login-split'),
      children: [
        Expanded(
          flex: 13,
          child: ColoredBox(
            key: const ValueKey('v3-login-brand-panel'),
            color: colors.surfaceContainerLow,
            child: const _DesktopBrandPanel(),
          ),
        ),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: colors.outlineVariant.withValues(alpha: .4),
        ),
        Expanded(
          flex: 12,
          child: ColoredBox(
            key: const ValueKey('v3-login-form-panel'),
            color: colors.surfaceContainerLowest,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compactRecovery =
                    hasError &&
                    recoveryOptions.expanded &&
                    constraints.maxHeight < 960;
                final verticalPadding = compactRecovery ? 24.0 : 48.0;
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 56,
                    vertical: verticalPadding,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - verticalPadding * 2,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Form(
                          key: formKey,
                          child: _WideDesktopLoginContent(
                            serverUrlController: serverUrlController,
                            usernameController: usernameController,
                            passwordController: passwordController,
                            obscurePassword: obscurePassword,
                            isLoading: isLoading,
                            hasError: hasError,
                            errorMessage: errorMessage,
                            recoveryOptions: recoveryOptions,
                            compactRecovery: compactRecovery,
                            onTogglePassword: onTogglePassword,
                            onSubmit: onSubmit,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _DesktopBrandPanel extends StatelessWidget {
  const _DesktopBrandPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final dense = constraints.maxHeight < 780;
        return Padding(
          padding: EdgeInsets.fromLTRB(64, dense ? 40 : 56, 56, 40),
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _BrandWordmark(),
                  const Spacer(),
                  Semantics(
                    header: true,
                    child: Text(
                      '把自己的音乐，\n带回日常聆听。',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontSize: dense ? 46 : 56,
                        height: 1.12,
                        letterSpacing: -1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(height: dense ? 18 : 24),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 540),
                    child: Text(
                      '连接你的自托管音乐服务。账号和音乐数据只在设备与服务器之间流动。',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.7,
                      ),
                    ),
                  ),
                  SizedBox(height: dense ? 28 : 44),
                  _BrandArtwork(dense: dense),
                  const Spacer(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BrandWordmark extends StatelessWidget {
  const _BrandWordmark();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Melisle 乐岛',
      image: true,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 38,
              height: 38,
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(colors.primary, BlendMode.srcIn),
                child: Image.asset(
                  'assets/icons/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Melisle',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontFamily: 'Righteous',
                color: colors.primary,
                fontSize: 30,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '乐岛',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandArtwork extends StatelessWidget {
  const _BrandArtwork({required this.dense});

  final bool dense;

  @override
  Widget build(BuildContext context) {
    final size = dense ? 150.0 : 176.0;

    return SizedBox(
      key: const ValueKey('v3-login-brand-artwork'),
      width: size * 2.3,
      height: size * 1.05,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 8,
            top: 14,
            child: Transform.rotate(
              angle: -.09,
              child: _BrandArtworkTile(
                size: size,
                imageAsset: 'assets/images/login/dawn-river.png',
              ),
            ),
          ),
          Positioned(
            left: size * .72,
            top: 2,
            child: _BrandArtworkTile(
              size: size,
              imageAsset: 'assets/images/login/forest-echo.png',
            ),
          ),
          Positioned(
            left: size * 1.42,
            top: 12,
            child: Transform.rotate(
              angle: .08,
              child: _BrandArtworkTile(
                size: size,
                imageAsset: 'assets/images/login/night-city.png',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandArtworkTile extends StatelessWidget {
  const _BrandArtworkTile({required this.size, required this.imageAsset});

  final double size;
  final String imageAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: .5),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: .12),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Image.asset(
        imageAsset,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
      ),
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
    required this.recoveryOptions,
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
  final _LoginRecoveryOptions recoveryOptions;
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
              recoveryOptions: recoveryOptions,
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
              recoveryOptions: recoveryOptions,
              onTogglePassword: onTogglePassword,
              onSubmit: onSubmit,
            ),
    );

    if (compact) {
      return Container(
        key: const ValueKey('v3-login-card'),
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadiusTokens.mobileXl),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.48),
          ),
        ),
        child: content,
      );
    }

    return Container(
      key: const ValueKey('v3-login-card'),
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 480, minHeight: 620),
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
    required this.recoveryOptions,
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
  final _LoginRecoveryOptions recoveryOptions;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _BrandHeader(),
        const SizedBox(height: 28),
        _DesktopLoginForm(
          serverUrlController: serverUrlController,
          usernameController: usernameController,
          passwordController: passwordController,
          obscurePassword: obscurePassword,
          isLoading: isLoading,
          hasError: hasError,
          errorMessage: errorMessage,
          recoveryOptions: recoveryOptions,
          compactRecovery: false,
          onTogglePassword: onTogglePassword,
          onSubmit: onSubmit,
        ),
      ],
    );
  }
}

class _WideDesktopLoginContent extends StatelessWidget {
  const _WideDesktopLoginContent({
    required this.serverUrlController,
    required this.usernameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.hasError,
    required this.errorMessage,
    required this.recoveryOptions,
    required this.compactRecovery,
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
  final _LoginRecoveryOptions recoveryOptions;
  final bool compactRecovery;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '连接音乐源',
          style: theme.textTheme.labelLarge?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        Semantics(
          header: true,
          child: Text(
            '欢迎来到乐岛',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontSize: 36,
              letterSpacing: -.5,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '填写服务器地址与登录信息，乐岛会自动识别服务类型。',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        SizedBox(height: compactRecovery ? 20 : 32),
        _DesktopLoginForm(
          serverUrlController: serverUrlController,
          usernameController: usernameController,
          passwordController: passwordController,
          obscurePassword: obscurePassword,
          isLoading: isLoading,
          hasError: hasError,
          errorMessage: errorMessage,
          recoveryOptions: recoveryOptions,
          compactRecovery: compactRecovery,
          onTogglePassword: onTogglePassword,
          onSubmit: onSubmit,
        ),
      ],
    );
  }
}

class _DesktopLoginForm extends StatelessWidget {
  const _DesktopLoginForm({
    required this.serverUrlController,
    required this.usernameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.hasError,
    required this.errorMessage,
    required this.recoveryOptions,
    required this.compactRecovery,
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
  final _LoginRecoveryOptions recoveryOptions;
  final bool compactRecovery;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasError) ...[
          _LoginErrorBanner(message: errorMessage),
          const SizedBox(height: 12),
          _BackendRecoveryPanel(
            options: recoveryOptions,
            isLoading: isLoading,
            compact: compactRecovery,
          ),
          SizedBox(height: compactRecovery ? 12 : 16),
        ],
        _LoginField(
          label: '服务器地址',
          controller: serverUrlController,
          hintText: 'https://music.example.com',
          icon: Icons.dns_outlined,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          enabled: !isLoading,
          validator: _serverValidator,
        ),
        SizedBox(height: compactRecovery ? 12 : 14),
        _LoginField(
          label: '用户名',
          controller: usernameController,
          hintText: '输入用户名',
          icon: Icons.person_outline_rounded,
          textInputAction: TextInputAction.next,
          enabled: !isLoading,
          validator: _usernameValidator,
        ),
        SizedBox(height: compactRecovery ? 12 : 14),
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
          validator: _passwordValidator,
        ),
        SizedBox(height: compactRecovery ? 16 : 20),
        SizedBox(
          height: 50,
          child: FilledButton(
            key: const ValueKey('v3-login-submit'),
            onPressed: isLoading || !recoveryOptions.canSubmit
                ? null
                : onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              disabledBackgroundColor: colors.onSurface.withValues(alpha: .12),
              disabledForegroundColor: colors.onSurface.withValues(alpha: .38),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _LoginButtonContent(
              isLoading: isLoading,
              hasError: hasError,
              preferredBackendType: recoveryOptions.selectedBackendType,
            ),
          ),
        ),
        if (!recoveryOptions.expanded ||
            recoveryOptions.selectedBackendType != null) ...[
          SizedBox(height: compactRecovery ? 12 : 16),
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
                  _loginModeHint(recoveryOptions),
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
    required this.recoveryOptions,
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
  final _LoginRecoveryOptions recoveryOptions;
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
                _loginModeHint(recoveryOptions),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        ),
        if (hasError) ...[
          const SizedBox(height: 18),
          _LoginErrorBanner(message: errorMessage),
          const SizedBox(height: 12),
          _BackendRecoveryPanel(options: recoveryOptions, isLoading: isLoading),
        ],
        const SizedBox(height: 28),
        SizedBox(
          height: 50,
          child: FilledButton(
            key: const ValueKey('v3-login-submit'),
            onPressed: isLoading || !recoveryOptions.canSubmit
                ? null
                : onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: colors.primaryContainer,
              foregroundColor: colors.onPrimaryContainer,
              disabledBackgroundColor: colors.onSurface.withValues(alpha: .12),
              disabledForegroundColor: colors.onSurface.withValues(alpha: .38),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _LoginButtonContent(
              isLoading: isLoading,
              hasError: hasError,
              preferredBackendType: recoveryOptions.selectedBackendType,
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
      child: Icon(
        Icons.library_music_rounded,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacingTokens.buttonPaddingCompactH,
          vertical: AppSpacingTokens.buttonPaddingV,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(AppRadiusTokens.sm),
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

class _BackendRecoveryPanel extends StatelessWidget {
  const _BackendRecoveryPanel({
    required this.options,
    required this.isLoading,
    this.compact = false,
  });

  final _LoginRecoveryOptions options;
  final bool isLoading;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (!options.expanded) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          key: const ValueKey('v3-login-show-manual-backend'),
          onPressed: isLoading ? null : options.onExpand,
          icon: const Icon(Icons.tune_rounded, size: 18),
          label: const Text('手动指定服务类型'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
            side: BorderSide(color: colors.outlineVariant),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadiusTokens.md),
            ),
          ),
        ),
      );
    }

    final selectedBackendType = options.selectedBackendType;
    return Container(
      key: const ValueKey('v3-login-manual-backend-panel'),
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .72)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (compact)
            Row(
              children: [
                Expanded(
                  child: Text('手动指定服务类型', style: theme.textTheme.titleSmall),
                ),
                TextButton.icon(
                  key: const ValueKey('v3-login-use-auto-detection'),
                  onPressed: isLoading ? null : options.onUseAutomaticDetection,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: const Text('恢复自动识别'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            )
          else ...[
            Text('手动指定服务类型', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              '选择后将跳过自动探测，仅连接指定服务。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
          SizedBox(height: compact ? 8 : 12),
          SegmentedButton<MusicBackendType>(
            key: const ValueKey('v3-login-backend-segments'),
            segments: const [
              ButtonSegment(
                value: MusicBackendType.navidrome,
                label: Text('Navidrome / Subsonic'),
                icon: Icon(Icons.cloud_outlined, size: 18),
              ),
              ButtonSegment(
                value: MusicBackendType.emby,
                label: Text('Emby'),
                icon: Icon(Icons.video_library_outlined, size: 18),
              ),
            ],
            selected: selectedBackendType == null
                ? const <MusicBackendType>{}
                : {selectedBackendType},
            emptySelectionAllowed: true,
            showSelectedIcon: false,
            expandedInsets: EdgeInsets.zero,
            onSelectionChanged: isLoading
                ? null
                : (selection) => options.onBackendSelected(
                    selection.isEmpty ? null : selection.first,
                  ),
          ),
          if (selectedBackendType == null) ...[
            SizedBox(height: compact ? 6 : 8),
            Text(
              '请选择服务类型后重新连接。',
              style: theme.textTheme.bodySmall?.copyWith(color: colors.error),
            ),
          ],
          if (!compact) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('v3-login-use-auto-detection'),
                onPressed: isLoading ? null : options.onUseAutomaticDetection,
                icon: const Icon(Icons.auto_awesome_rounded, size: 17),
                label: const Text('恢复自动识别'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _backendLabel(MusicBackendType backendType) => switch (backendType) {
  MusicBackendType.emby => 'Emby',
  MusicBackendType.navidrome => 'Navidrome / Subsonic',
};

String _loginModeHint(_LoginRecoveryOptions options) {
  final selectedBackendType = options.selectedBackendType;
  if (selectedBackendType != null) {
    return '已指定 ${_backendLabel(selectedBackendType)}，将跳过自动识别';
  }
  if (options.expanded) return '请选择服务类型后重新连接';
  return '自动识别 Emby、Navidrome 或 Subsonic/OpenSubsonic';
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
    return AppFormField(
      label: label,
      controller: controller,
      hintText: hintText,
      prefixIcon: icon,
      suffixIcon: suffixIcon,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onSubmitted: onSubmitted,
      obscureText: obscureText,
      enabled: enabled,
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
  const _LoginButtonContent({
    required this.isLoading,
    required this.hasError,
    required this.preferredBackendType,
  });

  final bool isLoading;
  final bool hasError;
  final MusicBackendType? preferredBackendType;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      final onPrimary = Theme.of(context).colorScheme.onPrimary;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: onPrimary),
          ),
          const SizedBox(width: 10),
          Text(
            preferredBackendType == null
                ? '正在自动识别…'
                : '正在连接 ${_backendLabel(preferredBackendType!)}…',
          ),
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
        Text(
          preferredBackendType == null
              ? (hasError ? '重新自动识别' : '连接服务器')
              : (hasError
                    ? '使用 ${_backendLabel(preferredBackendType!)} 重新连接'
                    : '连接 ${_backendLabel(preferredBackendType!)}'),
        ),
      ],
    );
  }
}
