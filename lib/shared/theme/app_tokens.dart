import 'package:flutter/material.dart';

// ============================================================================
// 色彩系统
// ============================================================================

abstract final class AppColorTokens {
  static const seed = Color(0xFF2F6FED);

  // ──────────────────── 深色模式表面 ────────────────────
  // Tidal Blue 深色表面层级。

  /// 最深基底（页面底层）
  static const darkScaffold = Color(0xFF121417);

  /// 主内容区表面
  static const darkSurface = Color(0xFF1A1918);

  /// 提升表面（卡片、列表项）
  static const darkSurfaceElevated = Color(0xFF202329);

  /// 高层级表面（悬停、选中）
  static const darkSurfaceHigh = Color(0xFF282C33);

  /// 最高层级表面（强调容器）
  static const darkSurfaceHighest = Color(0xFF303640);

  /// 覆盖层表面（弹窗、Sheet）
  static const darkSurfaceOverlay = Color(0xFF393F49);

  /// 侧栏表面
  static const darkSurfaceSidebar = Color(0xFF171A1F);

  // ──────────────────── 浅色模式表面 ────────────────────

  /// 最浅基底
  static const lightScaffold = Color(0xFFFAFAF8);

  /// 主内容区表面（纯白）
  static const lightSurface = Color(0xFFFFFFFF);

  /// 低层级表面（侧栏、背景区域）
  static const lightSurfaceLow = Color(0xFFF3F5F8);

  /// 中层级表面（卡片悬停）
  static const lightSurfaceMid = Color(0xFFEEF1F5);

  /// 高层级表面（输入框、选中）
  static const lightSurfaceHigh = Color(0xFFE8EDF3);

  /// 最高层级表面（强调容器）
  static const lightSurfaceHighest = Color(0xFFE0E6EE);

  /// 侧栏表面
  static const lightSurfaceSidebar = Color(0xFFF3F5F8);

  /// 播放器底部表面
  static const lightPlayerFooter = Color(0xFFFAFAF8);
  static const darkPlayerFooter = Color(0xFF1A1918);

  /// 封面前景遮罩
  static const onArtworkScrim = Color(0xFFF8FAFF);

  // ──────────────────── 主色 ────────────────────

  static const darkPrimary = Color(0xFF7AA2FF);
  static const darkPrimaryHover = Color(0xFF9AB8FF);
  static const darkPrimaryContainer = Color(0xFF182744);

  static const lightPrimary = Color(0xFF2F6FED);
  static const lightPrimaryRole = Color(0xFF245DCC);
  static const lightPrimaryHover = Color(0xFF245DCC);
  static const lightPrimaryContainer = Color(0xFFE8F0FF);
  static const lightOnPrimaryContainer = Color(0xFF12346B);

  // ──────────────────── 次级色 ────────────────────

  static const darkSecondary = Color(0xFFBBCBEE);
  static const darkSecondaryContainer = Color(0xFF25304A);

  static const lightSecondary = Color(0xFF546B9B);
  static const lightSecondaryContainer = Color(0xFFEAF0FC);

  // ──────────────────── 文字色 ────────────────────

  static const darkOnSurface = Color(0xFFF1F3F7);
  static const darkOnSurfaceVariant = Color(0xFFA8B0BF);
  static const darkMuted = Color(0xFF818A9A);

  static const lightOnSurface = Color(0xFF1B1E26);
  static const lightOnSurfaceVariant = Color(0xFF667085);
  static const lightMuted = Color(0xFF667085);

  // ──────────────────── 边框色 ────────────────────

  static const darkOutline = Color(0xFF596172);
  static const darkOutlineVariant = Color(0xFF303744);

  static const lightOutline = Color(0xFF778196);
  static const lightOutlineVariant = Color(0xFFDDE2EA);
  static const lightSimplifiedBorder = Color(0xFFDDE2EA);

  // ──────────────────── 歌词高亮 ────────────────────

  static const darkLyricHighlight = Color(0xFF9AB8FF);
  static const lightLyricHighlight = Color(0xFF245DCC);

  // ──────────────────── 音乐氛围色 ────────────────────

  static const lightMusicWarm = Color(0xFFD6A771);
  static const lightMusicWarmSoft = Color(0xFFFDEDDC);
  static const lightMusicRose = Color(0xFFDC937C);
  static const lightMusicRoseSoft = Color(0xFFFFE8E0);
  static const lightMusicTeal = Color(0xFF45A592);
  static const lightMusicTealSoft = Color(0xFFD9F4ED);
  static const lightMusicInk = Color(0xFF20373B);

  static const darkMusicWarm = Color(0xFFCEA26F);
  static const darkMusicWarmSoft = Color(0xFF312313);
  static const darkMusicRose = Color(0xFFD6917B);
  static const darkMusicRoseSoft = Color(0xFF362019);
  static const darkMusicTeal = Color(0xFF5FB7A5);
  static const darkMusicTealSoft = Color(0xFF122C26);
  static const darkMusicInk = Color(0xFFBECECF);

  // ──────────────────── 语义状态色 ────────────────────

  static const lightSuccess = Color(0xFF2E7D4F);
  static const lightWarn = Color(0xFF9A6700);
  static const lightDanger = Color(0xFFB9383A);

  static const darkSuccess = Color(0xFF65C98A);
  static const darkWarn = Color(0xFFE2B85B);
  static const darkDanger = Color(0xFFF08B8D);

  /// 内容区背景渐变 — 左上角色调。
  static const darkAmbientGradientStart = Color(0xFF121417);
  static const lightAmbientGradientStart = Color(0xFFFAFAF8);

  // ──────────────────── Overlay & Scrim ────────────────────

  /// 封面/图片上的深色渐变遮罩（12% 黑）。
  static const overlayDark = Color(0x1F000000);

  /// 封面/图片上的深色渐变遮罩（16% 黑）。
  static const overlayDarkMedium = Color(0x29000000);

  /// 封面/图片上的深色渐变遮罩（65% 黑），用于重叠文字区域。
  static const overlayDarkHeavy = Color(0xA6000000);

  /// 深色背景上的白色前景图标/装饰（12% 白）。
  static const onDarkOverlaySubtle = Color(0x1FFFFFFF);

  /// 深色背景上的白色前景文字（88% 白）。
  static const onDarkOverlayStrong = Color(0xE0FFFFFF);

  /// 深色背景上的次要白色文字（70% 白）。
  static const onDarkOverlayMuted = Color(0xB3FFFFFF);

  // ──────────────────── 玻璃效果 ────────────────────

  /// 玻璃效果背景（深色模式）
  static const darkGlass = Color(0xCC1A1918); // 80% 不透明度

  /// 玻璃效果背景（浅色模式）
  static const lightGlass = Color(0xCCFFFFFF); // 80% 不透明度

  // ──────────────────── 收藏色 ────────────────────

  /// 收藏/喜欢心形图标颜色（使用主色，保持品牌一致性）。
  static const lightFavorite = Color(0xFF2F6FED); // = lightPrimary
  static const darkFavorite = Color(0xFF7AA2FF); // = darkPrimary

  /// 失败态 artwork 去饱和灰色。
  static const desaturatedGrey = Color(0xFF9E9E9E);
}

// ============================================================================
// 圆角系统
// ============================================================================

abstract final class AppRadiusTokens {
  /// 4px - 标签、小徽章
  static const double xs = 4;

  /// 8px - 按钮、输入框
  static const double sm = 8;

  /// 12px - 卡片、列表项、封面
  static const double md = 12;

  /// 16px - 大卡片、迷你播放器、弹窗
  static const double lg = 16;

  /// 20px - 对话框、大型容器
  static const double xl = 20;

  /// 24px - Bottom Sheet、全屏弹窗
  static const double xxl = 24;

  /// 9999px - 胶囊、圆形
  static const double full = 9999;

  // ──── 语义化圆角 ────

  /// 卡片圆角
  static const double card = md;

  /// 按钮圆角
  static const double button = sm;

  /// 输入框圆角
  static const double input = sm;

  /// 图标按钮圆角
  static const double iconButton = sm;

  /// 封面网格圆角
  static const double coverGrid = md;

  /// 封面详情圆角
  static const double coverDetail = lg;

  /// 迷你播放器圆角（移动端）
  static const double miniPlayer = lg;

  /// 迷你播放器封面圆角
  static const double miniPlayerArtwork = md;

  /// 对话框圆角
  static const double dialog = xl;

  /// Bottom Sheet 圆角
  static const double sheet = xxl;

  /// 歌手头像圆角（圆形）
  static const double avatar = full;

  // ──── 平台适配 ────

  static const double desktopSm = xs;
  static const double desktopMd = sm;
  static const double desktopLg = md;
  static const double desktopXl = lg;

  static const double mobileSm = sm;
  static const double mobileMd = md;
  static const double mobileLg = lg;
  static const double mobileXl = xl;

  static const double shellContainer = md;
}

// ============================================================================
// 间距系统
// ============================================================================

abstract final class AppSpacingTokens {
  // ──── 页面级间距 ────

  /// 页面顶部间距
  static const double pageTop = 28;

  /// 页面顶部间距（紧凑）
  static const double pageTopCompact = 18;

  /// 移动端页面水平边距
  static const double mobilePageX = 24; // 20 → 24

  /// 桌面端页面水平边距
  static const double desktopPageX = 48; // 40 → 48

  // ──── 区块间距 ────

  /// 区块间距
  static const double sectionGap = 32; // 24 → 32

  /// 区块标题下方间距
  static const double sectionTitleBottomGap = 20; // 16 → 20

  /// 区块内边距
  static const double sectionPadding = 24;

  // ──── 卡片间距 ────

  /// 卡片内边距
  static const double cardPadding = 20; // 16 → 20

  /// 卡片间距
  static const double cardGap = 20; // 16 → 20

  /// 封面网格间距
  static const double gridGap = 20;

  // ──── 列表间距 ────

  /// 列表项高度
  static const double listTileHeight = 60; // 56 → 60

  /// 列表项内边距
  static const double listTilePadding = 16;

  /// 列表项垂直内边距
  static const double listTileVPadding = 12; // 10 → 12

  // ──── 按钮间距 ────

  /// 按钮高度
  static const double buttonHeight = 48; // 44 → 48

  /// 按钮水平内边距（紧凑型）
  static const double buttonPaddingCompactH = 16; // 14 → 16

  /// 按钮水平内边距（标准型）
  static const double buttonPaddingH = 24; // 20 → 24

  /// 按钮垂直内边距
  static const double buttonPaddingV = 14; // 12 → 14

  // ──── 输入框间距 ────

  /// 输入框高度
  static const double inputHeight = 52; // 48 → 52

  /// 输入框内边距
  static const double inputPadding = 20; // 16 → 20

  /// 表单标签间距
  static const double formLabelGap = 10; // 8 → 10

  /// 表单字段垂直内边距
  static const double formFieldVerticalPadding = 14; // 12 → 14

  // ──── 迷你播放器间距 ────

  static const double mobileMiniPlayerHeight = 64; // 60 → 64
  static const double desktopMiniPlayerHeight = 92; // 76 → 92，给控制区留出呼吸空间

  // ──── 其他间距 ────

  static const double headerBottomGap = 14;
  static const double contentBottom = 24;
  static const double compactFieldBottomGap = 12;
  static const double favoriteTrackPadding = 8;
  static const double favoriteTrackArtwork = 56;
  static const double favoriteTrackContentGap = 16;
  static const double headerPadding = 22;

  static const double pageHorizontalCompact = 24; // 20 → 24
  static const double pageHorizontalMedium = 32; // 28 → 32
  static const double pageHorizontalExpanded = 48; // 40 → 48

  static const double shellOuterPadding = 0;
  static const double shellGap = 0;
  static const double shellBottomInset = 0;
  static const double macOsTrafficLightInset = 28;
  static const double desktopSidebarWidth = 220;
  static const double mobileTabContentHeight = 54;
  static const double desktopToolbarHeight = 72;
  static const double desktopMainContentPaddingX = 48; // 40 → 48
  static const double desktopMainContentPaddingY = 32; // 28 → 32
  static const double desktopCardGridMinWidth = 160;
  static const double desktopCardGridGapX = 20; // 18 → 20
  static const double desktopCardGridGapY = 24; // 22 → 24
  static const double snackbarMargin = 24; // 20 → 24

  static const double playerHorizontalPadding = 32; // 28 → 32
  static const double playerControlGap = 16; // 14 → 16
  static const double playerToolbarGap = 12; // 10 → 12
  static const double desktopSidebarTopGap = 12;
  static const double desktopSidebarBottomGap = 18;

  static const double miniPlayerOuterHorizontal = 0;
  static const double miniPlayerOuterTop = 0;
  static const double miniPlayerOuterBottomCompact = 0;
  static const double miniPlayerOuterBottomWide = 0;
  static const double miniPlayerInnerHorizontal = 24; // 20 → 24
  static const double miniPlayerInnerVerticalCompact = 0;
  static const double miniPlayerInnerVerticalWide = 0;
  static const double miniPlayerControlGap = 8; // 6 → 8
  static const double miniPlayerSectionGap = 12; // 10 → 12

  // ──── 通用内容间距 ────

  /// 紧凑内容元素间距（按钮内、控件内）。
  static const double compactGap = 6;

  /// 行内元素间距（图标与文字、标签间）。
  static const double inlineGap = 8;

  /// 紧凑行内元素间距（小按钮、标签内）。
  static const double inlineGapCompact = 10;

  /// 内容块间距（段落间、列表项内）。
  static const double contentGap = 12;

  /// 对话框/Sheet 内边距。
  static const double dialogPadding = 24; // 20 → 24
}

// ============================================================================
// 边框系统
// ============================================================================

abstract final class AppBorderTokens {
  /// 细边框（1px）
  static const double thin = 1;

  /// 标准边框（1.5px）
  static const double standard = 1.5;

  /// 焦点边框（2px）
  static const double focus = 2;
}

// ============================================================================
// 阴影系统
// ============================================================================

abstract final class AppShadowTokens {
  // ──── 阴影层级 ────

  /// Level 0: 无阴影
  static const BoxShadow none = BoxShadow(color: Colors.transparent);

  /// Level 1: 轻微阴影（卡片默认）
  static const BoxShadow sm = BoxShadow(
    color: Color(0x0D000000), // 5% 黑
    blurRadius: 4,
    offset: Offset(0, 2),
  );

  /// Level 2: 中等阴影（悬停、浮层）
  static const BoxShadow md = BoxShadow(
    color: Color(0x14000000), // 8% 黑
    blurRadius: 8,
    offset: Offset(0, 4),
  );

  /// Level 3: 明显阴影（弹窗、Sheet）
  static const BoxShadow lg = BoxShadow(
    color: Color(0x1F000000), // 12% 黑
    blurRadius: 16,
    offset: Offset(0, 8),
  );

  /// Level 4: 强阴影（模态层）
  static const BoxShadow xl = BoxShadow(
    color: Color(0x29000000), // 16% 黑
    blurRadius: 24,
    offset: Offset(0, 12),
  );

  // ──── 语义化阴影 ────

  /// 卡片默认阴影
  static const List<BoxShadow> card = [sm];

  /// 卡片悬停阴影
  static const List<BoxShadow> cardHover = [md];

  /// 弹窗阴影
  static const List<BoxShadow> popup = [lg];

  /// 模态层阴影
  static const List<BoxShadow> modal = [xl];

  // ──── 深色模式边框（替代阴影） ────

  /// 深色模式默认边框颜色
  static const Color darkBorder = Color(0x0F000000); // 6% 白

  /// 深色模式悬停边框颜色
  static const Color darkBorderHover = Color(0x19000000); // 10% 白
}
