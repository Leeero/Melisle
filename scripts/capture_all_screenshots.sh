#!/bin/bash
set -e

echo "=== Melisle 截图捕获 ==="
echo ""

# 登录页面
echo "📷 Capturing login screenshots..."
flutter test test/widget_test.dart -e CAPTURE_LOGIN_SCREENSHOTS=true 2>&1 | tail -3

# App Shell
echo "📷 Capturing app shell screenshots..."
flutter test test/widget_test.dart -e CAPTURE_APP_SHELL_SCREENSHOTS=true 2>&1 | tail -3

# 首页
echo "📷 Capturing home screenshots..."
flutter test test/presentation/pages/home/ -e CAPTURE_HOME_SCREENSHOTS=true 2>&1 | tail -3

# 媒体库
echo "📷 Capturing library screenshots..."
flutter test test/presentation/pages/library/ -e CAPTURE_LIBRARY_SCREENSHOTS=true 2>&1 | tail -3

# 收藏
echo "📷 Capturing favorites screenshots..."
flutter test test/presentation/pages/favorites/ -e CAPTURE_FAVORITES_SCREENSHOTS=true 2>&1 | tail -3

# 历史
echo "📷 Capturing history screenshots..."
flutter test test/presentation/pages/history/ -e CAPTURE_HISTORY_SCREENSHOTS=true 2>&1 | tail -3

# 设置
echo "📷 Capturing settings screenshots..."
flutter test test/presentation/pages/settings/ -e CAPTURE_SETTINGS_SCREENSHOTS=true 2>&1 | tail -3

# 搜索
echo "📷 Capturing search screenshots..."
flutter test test/presentation/pages/search/ -e CAPTURE_SEARCH_SCREENSHOTS=true 2>&1 | tail -3

# 播放列表
echo "📷 Capturing playlists screenshots..."
flutter test test/presentation/pages/playlists/ -e CAPTURE_PLAYLISTS_SCREENSHOTS=true 2>&1 | tail -3

echo ""
echo "=== 截图捕获完成 ==="
echo ""
echo "截图保存在: design-reference/screenshots/actual/"
echo ""
echo "下一步:"
echo "  1. STITCH_GOLDEN_TESTS=true flutter test test/presentation/visual"
echo "  2. 对比 reference 和 actual 目录的截图"
