import 'package:cross_platform_music_player/presentation/blocs/auth/auth_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/auth/auth_state.dart';
import 'package:cross_platform_music_player/presentation/widgets/layout/page_layout.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:cross_platform_music_player/shared/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: BlocListener<AuthCubit, AuthState>(
        listenWhen: (previous, current) =>
            previous.errorMessage != current.errorMessage,
        listener: (context, state) {
          final message = state.errorMessage;
          if (message == null) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(message),
              behavior: SnackBarBehavior.floating,
              backgroundColor: colorScheme.errorContainer,
            ));
        },
        child: Stack(
          children: [
            // Phase 4: Background gradient follows theme brightness
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          Theme.of(context).scaffoldBackgroundColor,
                          colorScheme.surface,
                          colorScheme.secondaryContainer.withValues(
                            alpha: 0.28,
                          ),
                        ]
                      : [
                          colorScheme.surfaceContainerHigh,
                          Theme.of(context).scaffoldBackgroundColor,
                          colorScheme.surface,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const SizedBox.expand(),
            ),
            // Multi-point radial glow orbs (alpha adapts to theme)
            Positioned(
              left: -60,
              top: -30,
              child: _GlowOrb(
                color: colorScheme.primary.withValues(
                  alpha: isDark ? 0.18 : 0.10,
                ),
                size: 280,
              ),
            ),
            Positioned(
              right: -80,
              bottom: -10,
              child: _GlowOrb(
                color: colorScheme.secondary.withValues(
                  alpha: isDark ? 0.15 : 0.08,
                ),
                size: 320,
              ),
            ),
            Positioned(
              left: MediaQuery.sizeOf(context).width * 0.3,
              top: MediaQuery.sizeOf(context).height * 0.15,
              child: _GlowOrb(
                color: colorScheme.primaryContainer.withValues(
                  alpha: isDark ? 0.08 : 0.12,
                ),
                size: 200,
              ),
            ),
            Positioned(
              right: MediaQuery.sizeOf(context).width * 0.2,
              bottom: MediaQuery.sizeOf(context).height * 0.25,
              child: _GlowOrb(
                color: colorScheme.tertiary.withValues(
                  alpha: isDark ? 0.06 : 0.06,
                ),
                size: 180,
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: AppPageLayout.pagePadding(
                    context,
                    top: 24,
                    bottom: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = AppBreakpoints.usesWideContentWidth(
                          constraints.maxWidth,
                        );
                        final intro = _LoginIntro();
                        final form = _LoginForm(
                          formKey: _formKey,
                          serverUrlController: _serverUrlController,
                          usernameController: _usernameController,
                          passwordController: _passwordController,
                          obscurePassword: _obscurePassword,
                          onSubmit: _submit,
                          onToggleObscure: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        );

                        if (!isWide) {
                          return Column(
                            children: [intro, const SizedBox(height: 16), form],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(flex: 4, child: intro),
                            const SizedBox(width: 22),
                            Expanded(flex: 5, child: form),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
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

class _LoginIntro extends StatelessWidget {
  const _LoginIntro();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.asset(
                'assets/icons/logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppConstants.appEnglishName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '连接你的音乐库',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.serverUrlController,
    required this.usernameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onSubmit,
    required this.onToggleObscure,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController serverUrlController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onSubmit;
  final VoidCallback onToggleObscure;

  @override
  Widget build(BuildContext context) {
    return Card(
      // Phase 4: Form card with surfaceContainerHighest alpha: 0.92
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.92),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('登录', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                '连接到你的私有音乐库',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: serverUrlController,
                decoration: const InputDecoration(
                  labelText: '服务器地址',
                  hintText: 'https://your-music-server.example.com',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return '请输入服务器地址';
                  final uri = Uri.tryParse(value.trim());
                  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
                    return '请输入合法的 URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: '用户名'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? '请输入用户名' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: '密码',
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  suffixIcon: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: onToggleObscure,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        obscurePassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        key: ValueKey(obscurePassword),
                        size: 20,
                      ),
                    ),
                  ),
                ),
                obscureText: obscurePassword,
                validator: (value) =>
                    value == null || value.isEmpty ? '请输入密码' : null,
                onFieldSubmitted: (_) => onSubmit(),
              ),
              const SizedBox(height: 22),
              // Phase 4: Capsule login button with Primary glow shadow
              SizedBox(
                width: double.infinity,
                child: BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    final isLoading = state.status == AuthStatus.loading;
                    final colorScheme = Theme.of(context).colorScheme;
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: isLoading ? null : onSubmit,
                        child: isLoading
                            ? const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text('正在连接…'),
                                ],
                              )
                            : const Text('登录并进入乐岛'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0), Colors.transparent],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
      ),
    );
  }
}
