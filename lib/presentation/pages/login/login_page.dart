import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cross_platform_music_player/presentation/blocs/auth/auth_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/auth/auth_state.dart';
import 'package:cross_platform_music_player/shared/theme/theme.dart';

enum _LoginService { emby, navidrome, subsonic }

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

  _LoginService _selectedService = _LoginService.navidrome;

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

    return Scaffold(
      body: BlocListener<AuthCubit, AuthState>(
        listenWhen: (previous, current) =>
            previous.errorMessage != current.errorMessage,
        listener: (context, state) {
          final message = state.errorMessage;
          if (message == null) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(message),
                behavior: SnackBarBehavior.floating,
                backgroundColor: colorScheme.errorContainer,
              ),
            );
        },
        child: _LoginGate(
          desktopChild: _ConnectCard(
            formKey: _formKey,
            selectedService: _selectedService,
            serverUrlController: _serverUrlController,
            usernameController: _usernameController,
            passwordController: _passwordController,
            onServiceSelected: (service) =>
                setState(() => _selectedService = service),
            onSubmit: _submit,
          ),
          mobileChild: _MobileConnectView(
            formKey: _formKey,
            selectedService: _selectedService,
            serverUrlController: _serverUrlController,
            usernameController: _usernameController,
            passwordController: _passwordController,
            onServiceSelected: (service) =>
                setState(() => _selectedService = service),
            onSubmit: _submit,
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

class _LoginGate extends StatelessWidget {
  const _LoginGate({required this.desktopChild, required this.mobileChild});

  final Widget desktopChild;
  final Widget mobileChild;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: _LoginPalette.bg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final useMobileLayout = size.width < 640;
          final horizontalPadding = useMobileLayout ? 24.0 : 48.0;
          final verticalPadding = useMobileLayout
              ? 20.0
              : (size.height < 760 ? 24.0 : 48.0);
          final maxWidth = useMobileLayout ? 430.0 : 560.0;
          final child = useMobileLayout ? mobileChild : desktopChild;

          return Stack(
            children: [
              Positioned(
                left: size.width * 0.24 - 280,
                top: size.height * 0.18 - 280,
                child: _RadialWash(
                  size: 560,
                  color: _LoginPalette.accent.withValues(alpha: 0.10),
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: useMobileLayout
                      ? Alignment.topCenter
                      : Alignment.center,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: child,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MobileConnectView extends StatelessWidget {
  const _MobileConnectView({
    required this.formKey,
    required this.selectedService,
    required this.serverUrlController,
    required this.usernameController,
    required this.passwordController,
    required this.onServiceSelected,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final _LoginService selectedService;
  final TextEditingController serverUrlController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final ValueChanged<_LoginService> onServiceSelected;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _MobileConnectHero(),
          Text(
            '音乐源',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: _LoginPalette.fgSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          _MobileServicePicker(
            selectedService: selectedService,
            onServiceSelected: onServiceSelected,
          ),
          const SizedBox(height: 16),
          _MobileLoginFields(
            serverUrlController: serverUrlController,
            usernameController: usernameController,
            passwordController: passwordController,
            onSubmit: onSubmit,
          ),
          const SizedBox(height: 6),
          _MobileConnectActions(onSubmit: onSubmit),
        ],
      ),
    );
  }
}

class _MobileConnectHero extends StatelessWidget {
  const _MobileConnectHero();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _LoginPalette.musicWarm,
                  _LoginPalette.musicRose,
                  _LoginPalette.accent,
                ],
                stops: [0, 0.55, 1],
              ),
              boxShadow: [
                BoxShadow(
                  color: _LoginPalette.musicRose.withValues(alpha: 0.22),
                  blurRadius: 38,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Stack(
              children: [
                Positioned(
                  left: 8,
                  top: 7,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _LoginPalette.surface.withValues(alpha: 0.34),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '乐',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: _LoginPalette.surface,
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '连接你的音乐岛屿',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: 31,
              height: 1.08,
              fontWeight: FontWeight.w700,
              color: _LoginPalette.fg,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(
              '选择音乐源，进入自己的私人曲库。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.45,
                color: _LoginPalette.fgSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectCard extends StatelessWidget {
  const _ConnectCard({
    required this.formKey,
    required this.selectedService,
    required this.serverUrlController,
    required this.usernameController,
    required this.passwordController,
    required this.onServiceSelected,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final _LoginService selectedService;
  final TextEditingController serverUrlController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final ValueChanged<_LoginService> onServiceSelected;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: _LoginPalette.fg.withValues(alpha: 0.10),
            blurRadius: 70,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: _LoginPalette.borderLight.withValues(alpha: 0.72),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(
                  _LoginPalette.surface,
                  _LoginPalette.musicTeal,
                  0.06,
                )!,
                _LoginPalette.surface,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -22,
                top: -56,
                child: _RadialWash(
                  size: 240,
                  color: _LoginPalette.musicWarm.withValues(alpha: 0.20),
                ),
              ),
              Positioned(
                right: 30,
                top: 30,
                child: Transform.rotate(
                  angle: math.pi / 60,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(
                            _LoginPalette.surface,
                            _LoginPalette.musicWarm,
                            0.70,
                          )!,
                          Color.lerp(
                            _LoginPalette.fg,
                            _LoginPalette.musicRose,
                            0.89,
                          )!,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _LoginPalette.musicWarm.withValues(
                            alpha: 0.22,
                          ),
                          blurRadius: 48,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: const SizedBox(width: 118, height: 118),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(30),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _ConnectMark(),
                      Text(
                        '连接你的音乐岛屿',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontSize: 30,
                              height: 1.1,
                              fontWeight: FontWeight.w700,
                              color: _LoginPalette.fg,
                              letterSpacing: 0,
                            ),
                      ),
                      const SizedBox(height: 7),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 330),
                        child: Text(
                          '选择一个音乐源，输入地址后进入你的私人收藏。',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                height: 1.55,
                                color: _LoginPalette.fgSecondary,
                              ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _ConnectForm(
                        selectedService: selectedService,
                        serverUrlController: serverUrlController,
                        usernameController: usernameController,
                        passwordController: passwordController,
                        onServiceSelected: onServiceSelected,
                        onSubmit: onSubmit,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectMark extends StatelessWidget {
  const _ConnectMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        color: Color.lerp(_LoginPalette.fg, _LoginPalette.musicWarm, 0.12),
        borderRadius: BorderRadius.circular(15),
      ),
      alignment: Alignment.center,
      child: Text(
        '乐',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: _LoginPalette.surface,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _ConnectForm extends StatelessWidget {
  const _ConnectForm({
    required this.selectedService,
    required this.serverUrlController,
    required this.usernameController,
    required this.passwordController,
    required this.onServiceSelected,
    required this.onSubmit,
  });

  final _LoginService selectedService;
  final TextEditingController serverUrlController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final ValueChanged<_LoginService> onServiceSelected;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ConnectFieldLabel(
          label: '音乐源',
          child: _ServiceOptions(
            selectedService: selectedService,
            onServiceSelected: onServiceSelected,
          ),
        ),
        const SizedBox(height: 15),
        _ConnectTextField(
          label: '服务器地址',
          controller: serverUrlController,
          hintText: 'https://music.example.com',
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.url],
          validator: (value) {
            if (value == null || value.trim().isEmpty) return '请输入服务器地址';
            final uri = Uri.tryParse(value.trim());
            if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
              return '请输入合法的 URL';
            }
            return null;
          },
        ),
        const SizedBox(height: 15),
        _ConnectTextField(
          label: '用户名',
          controller: usernameController,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.username],
          validator: (value) =>
              value == null || value.trim().isEmpty ? '请输入用户名' : null,
        ),
        const SizedBox(height: 15),
        _ConnectTextField(
          label: '密码或 API Token',
          controller: passwordController,
          obscureText: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          validator: (value) =>
              value == null || value.isEmpty ? '请输入密码或 API Token' : null,
          onFieldSubmitted: (_) => onSubmit(),
        ),
        const SizedBox(height: 19),
        _ConnectActions(onSubmit: onSubmit),
      ],
    );
  }
}

class _ConnectFieldLabel extends StatelessWidget {
  const _ConnectFieldLabel({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: _LoginPalette.fgSecondary,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _ServiceOptions extends StatelessWidget {
  const _ServiceOptions({
    required this.selectedService,
    required this.onServiceSelected,
  });

  final _LoginService selectedService;
  final ValueChanged<_LoginService> onServiceSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _LoginPalette.surfaceRaised.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _LoginPalette.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            _ServiceOption(
              title: 'Emby',
              subtitle: '家庭媒体库',
              selected: selectedService == _LoginService.emby,
              onPressed: () => onServiceSelected(_LoginService.emby),
            ),
            const SizedBox(width: 10),
            _ServiceOption(
              title: 'Navidrome',
              subtitle: '轻量音乐库',
              selected: selectedService == _LoginService.navidrome,
              onPressed: () => onServiceSelected(_LoginService.navidrome),
            ),
            const SizedBox(width: 10),
            _ServiceOption(
              title: 'Subsonic',
              subtitle: '经典协议',
              selected: selectedService == _LoginService.subsonic,
              onPressed: () => onServiceSelected(_LoginService.subsonic),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileServicePicker extends StatelessWidget {
  const _MobileServicePicker({
    required this.selectedService,
    required this.onServiceSelected,
  });

  final _LoginService selectedService;
  final ValueChanged<_LoginService> onServiceSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MobileServicePill(
          title: 'Emby',
          selected: selectedService == _LoginService.emby,
          onPressed: () => onServiceSelected(_LoginService.emby),
        ),
        const SizedBox(width: 8),
        _MobileServicePill(
          title: 'Navidrome',
          selected: selectedService == _LoginService.navidrome,
          onPressed: () => onServiceSelected(_LoginService.navidrome),
        ),
        const SizedBox(width: 8),
        _MobileServicePill(
          title: 'Subsonic',
          selected: selectedService == _LoginService.subsonic,
          onPressed: () => onServiceSelected(_LoginService.subsonic),
        ),
      ],
    );
  }
}

class _MobileServicePill extends StatelessWidget {
  const _MobileServicePill({
    required this.title,
    required this.selected,
    required this.onPressed,
  });

  final String title;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: title,
        child: AnimatedScale(
          duration: AppMotion.micro,
          curve: AppMotion.enter,
          scale: selected ? 1 : 0.995,
          child: AnimatedContainer(
            duration: AppMotion.micro,
            curve: AppMotion.enter,
            constraints: const BoxConstraints(minHeight: 82),
            decoration: BoxDecoration(
              color: selected
                  ? Color.lerp(
                      _LoginPalette.surface,
                      _LoginPalette.musicWarm,
                      0.16,
                    )
                  : _LoginPalette.surface.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                width: 0.5,
                color: selected
                    ? Color.lerp(
                        _LoginPalette.border,
                        _LoginPalette.accent,
                        0.42,
                      )!
                    : _LoginPalette.borderLight.withValues(alpha: 0.78),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(18),
                splashColor: _LoginPalette.accent.withValues(alpha: 0.08),
                highlightColor: _LoginPalette.borderLight.withValues(
                  alpha: 0.42,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _ServiceDisc(mobile: true),
                      const SizedBox(height: 7),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _LoginPalette.fg,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceOption extends StatelessWidget {
  const _ServiceOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: '$title，$subtitle',
        child: AnimatedContainer(
          duration: AppMotion.micro,
          curve: AppMotion.enter,
          constraints: const BoxConstraints(minHeight: 86),
          decoration: BoxDecoration(
            color: selected
                ? _LoginPalette.surface
                : _LoginPalette.surface.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(18),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _LoginPalette.fg.withValues(alpha: 0.08),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              hoverColor: selected
                  ? _LoginPalette.surface.withValues(alpha: 0)
                  : _LoginPalette.surface.withValues(alpha: 0.78),
              focusColor: _LoginPalette.accent.withValues(alpha: 0.08),
              splashColor: _LoginPalette.accent.withValues(alpha: 0.08),
              highlightColor: _LoginPalette.surface.withValues(alpha: 0),
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (selected) {
                  return _LoginPalette.surface.withValues(alpha: 0);
                }
                if (states.contains(WidgetState.pressed)) {
                  return _LoginPalette.accent.withValues(alpha: 0.08);
                }
                if (states.contains(WidgetState.hovered)) {
                  return _LoginPalette.surface.withValues(alpha: 0.78);
                }
                if (states.contains(WidgetState.focused)) {
                  return _LoginPalette.accent.withValues(alpha: 0.08);
                }
                return _LoginPalette.surface.withValues(alpha: 0);
              }),
              onTap: onPressed,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _ServiceDisc(),
                        const SizedBox(height: 9),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _LoginPalette.fg,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                height: 1.3,
                                color: _LoginPalette.muted,
                                letterSpacing: 0,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppRadiusTokens.button,
                          ),
                          gradient: const LinearGradient(
                            colors: [
                              _LoginPalette.musicWarm,
                              _LoginPalette.musicTeal,
                            ],
                          ),
                        ),
                        child: const SizedBox(height: 2),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceDisc extends StatelessWidget {
  const _ServiceDisc({this.mobile = false});

  final bool mobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: mobile
            ? SweepGradient(
                startAngle: math.pi / 9,
                colors: [
                  Color.lerp(
                    _LoginPalette.musicWarm,
                    _LoginPalette.surface,
                    0.35,
                  )!,
                  Color.lerp(
                    _LoginPalette.musicRose,
                    _LoginPalette.surface,
                    0.45,
                  )!,
                  Color.lerp(
                    _LoginPalette.accent,
                    _LoginPalette.surface,
                    0.48,
                  )!,
                  Color.lerp(
                    _LoginPalette.musicWarm,
                    _LoginPalette.surface,
                    0.35,
                  )!,
                ],
              )
            : RadialGradient(
                colors: [
                  _LoginPalette.surface,
                  _LoginPalette.surface,
                  Color.lerp(
                    _LoginPalette.musicTeal,
                    _LoginPalette.surface,
                    0.58,
                  )!,
                  Color.lerp(_LoginPalette.musicRose, _LoginPalette.fg, 0.40)!,
                ],
                stops: const [0.0, 0.17, 0.44, 1.0],
              ),
        boxShadow: [
          BoxShadow(
            color: mobile
                ? _LoginPalette.surface.withValues(alpha: 0.42)
                : _LoginPalette.fg.withValues(alpha: 0.08),
            blurRadius: 0,
            spreadRadius: 1,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Container(
        width: mobile ? 6 : 7,
        height: mobile ? 6 : 7,
        decoration: BoxDecoration(
          color: mobile
              ? _LoginPalette.fg.withValues(alpha: 0.18)
              : _LoginPalette.surface,
          shape: BoxShape.circle,
          border: mobile
              ? null
              : Border.all(color: _LoginPalette.fg.withValues(alpha: 0.10)),
        ),
      ),
    );
  }
}

class _MobileLoginFields extends StatelessWidget {
  const _MobileLoginFields({
    required this.serverUrlController,
    required this.usernameController,
    required this.passwordController,
    required this.onSubmit,
  });

  final TextEditingController serverUrlController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _LoginPalette.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          width: 0.5,
          color: _LoginPalette.borderLight.withValues(alpha: 0.70),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MobileLoginTextField(
              label: '服务器',
              controller: serverUrlController,
              hintText: 'https://music.example.com',
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.url],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入服务器地址';
                }
                final uri = Uri.tryParse(value.trim());
                if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
                  return '请输入合法的 URL';
                }
                return null;
              },
            ),
            const _MobileFieldDivider(),
            _MobileLoginTextField(
              label: '账号',
              controller: usernameController,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              validator: (value) =>
                  value == null || value.trim().isEmpty ? '请输入用户名' : null,
            ),
            const _MobileFieldDivider(),
            _MobileLoginTextField(
              label: '密码 / Token',
              controller: passwordController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              validator: (value) =>
                  value == null || value.isEmpty ? '请输入密码或 API Token' : null,
              onFieldSubmitted: (_) => onSubmit(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileFieldDivider extends StatelessWidget {
  const _MobileFieldDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 0.5,
      thickness: 0.5,
      indent: 16,
      color: _LoginPalette.borderLight,
    );
  }
}

class _MobileLoginTextField extends StatelessWidget {
  const _MobileLoginTextField({
    required this.label,
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscureText = false,
    this.validator,
    this.onFieldSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                color: _LoginPalette.fg,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              autofillHints: autofillHints,
              obscureText: obscureText,
              validator: validator,
              onFieldSubmitted: onFieldSubmitted,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _LoginPalette.fg,
                fontSize: 15,
                height: 1.2,
              ),
              cursorColor: _LoginPalette.accent,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: _LoginPalette.muted),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                errorStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectTextField extends StatelessWidget {
  const _ConnectTextField({
    required this.label,
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscureText = false,
    this.validator,
    this.onFieldSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _LoginPalette.accent, width: 1),
    );
    final enabledBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _LoginPalette.border),
    );

    return _ConnectFieldLabel(
      label: label,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autofillHints: autofillHints,
        obscureText: obscureText,
        validator: validator,
        onFieldSubmitted: onFieldSubmitted,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: _LoginPalette.fg, height: 1.2),
        cursorColor: _LoginPalette.accent,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: _LoginPalette.muted.withValues(alpha: 0.56),
          ),
          filled: true,
          fillColor: _LoginPalette.surfaceRaised,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          constraints: const BoxConstraints(minHeight: 42),
          border: enabledBorder,
          enabledBorder: enabledBorder,
          focusedBorder: focusedBorder,
          errorBorder: enabledBorder.copyWith(
            borderSide: BorderSide(color: colorScheme.error),
          ),
          focusedErrorBorder: focusedBorder.copyWith(
            borderSide: BorderSide(color: colorScheme.error),
          ),
        ),
      ),
    );
  }
}

class _ConnectActions extends StatelessWidget {
  const _ConnectActions({required this.onSubmit});

  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final isLoading = state.status == AuthStatus.loading;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 42),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                backgroundColor: _LoginPalette.accent,
                foregroundColor: _LoginPalette.surface,
                disabledBackgroundColor: _LoginPalette.accent.withValues(
                  alpha: 0.58,
                ),
                disabledForegroundColor: _LoginPalette.surface.withValues(
                  alpha: 0.82,
                ),
                shape: const StadiumBorder(),
                textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
              onPressed: isLoading ? null : onSubmit,
              icon: isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _LoginPalette.surface,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(isLoading ? '正在连接…' : '登录并进入乐岛'),
            ),
            const SizedBox(height: 15),
            _ConnectStatus(state: state),
          ],
        );
      },
    );
  }
}

class _MobileConnectActions extends StatelessWidget {
  const _MobileConnectActions({required this.onSubmit});

  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final isLoading = state.status == AuthStatus.loading;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                backgroundColor: _LoginPalette.fg,
                foregroundColor: _LoginPalette.bg,
                disabledBackgroundColor: _LoginPalette.fg.withValues(
                  alpha: 0.72,
                ),
                disabledForegroundColor: _LoginPalette.bg.withValues(
                  alpha: 0.82,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
              onPressed: isLoading ? null : onSubmit,
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('进入乐岛'),
            ),
            const SizedBox(height: 12),
            _ConnectStatus(state: state, mobile: true),
          ],
        );
      },
    );
  }
}

class _ConnectStatus extends StatelessWidget {
  const _ConnectStatus({required this.state, this.mobile = false});

  final AuthState state;
  final bool mobile;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = switch (state.status) {
      AuthStatus.loading => (
        text: '正在验证服务器与账号…',
        color: _LoginPalette.muted,
        background: _LoginPalette.surfaceRaised,
        border: _LoginPalette.borderLight,
      ),
      AuthStatus.authenticated => (
        text: '连接成功，正在进入乐岛',
        color: _LoginPalette.success,
        background: Color.lerp(
          _LoginPalette.surface,
          _LoginPalette.success,
          0.10,
        )!,
        border: _LoginPalette.success.withValues(alpha: 0.20),
      ),
      AuthStatus.failure => (
        text: '连接失败，请检查信息',
        color: colorScheme.error,
        background: colorScheme.errorContainer.withValues(alpha: 0.36),
        border: colorScheme.error.withValues(alpha: 0.20),
      ),
      AuthStatus.unknown => (
        text: '正在恢复会话…',
        color: _LoginPalette.muted,
        background: _LoginPalette.surfaceRaised,
        border: _LoginPalette.borderLight,
      ),
      AuthStatus.unauthenticated => (
        text: '等待登录',
        color: _LoginPalette.muted,
        background: _LoginPalette.surfaceRaised,
        border: _LoginPalette.borderLight,
      ),
    };

    if (mobile) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              status.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: status.color,
                fontSize: 12,
                height: 1.3,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      );
    }

    return AnimatedContainer(
      duration: AppMotion.micro,
      curve: AppMotion.enter,
      constraints: const BoxConstraints(minHeight: 34),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(AppRadiusTokens.button),
        border: Border.all(color: status.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            status.text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: status.color,
              fontSize: 12,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _RadialWash extends StatelessWidget {
  const _RadialWash({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
            stops: const [0.0, 0.68],
          ),
        ),
      ),
    );
  }
}

abstract final class _LoginPalette {
  static const bg = Color(0xFFF7FCFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceRaised = Color(0xFFFAFEFE);
  static const fg = Color(0xFF070F11);
  static const fgSecondary = Color(0xFF444F52);
  static const muted = Color(0xFF6E7A7B);
  static const border = Color(0xFFD8DEDD);
  static const borderLight = Color(0xFFE8ECEC);
  static const accent = Color(0xFF1A9480);
  static const musicWarm = Color(0xFFD6A771);
  static const musicRose = Color(0xFFDC937C);
  static const musicTeal = Color(0xFF45A592);
  static const success = Color(0xFF308639);
}
