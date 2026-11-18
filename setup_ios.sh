#!/usr/bin/env bash
# 在本地 Mac 上生成 iOS 工程（不覆盖已有源码）
set -e
cd "$(dirname "$0")"

if [ -d "ios" ]; then
  echo "ios/ 已存在，无需生成。"
  exit 0
fi

cp pubspec.yaml /tmp/xcard_pubspec.yaml
cp -R lib /tmp/xcard_lib
if [ -d assets ]; then cp -R assets /tmp/xcard_assets; fi

flutter create --platforms ios --project-name x_card --org com.xcard .

cp /tmp/xcard_pubspec.yaml pubspec.yaml
rm -rf lib && cp -R /tmp/xcard_lib lib
if [ -d /tmp/xcard_assets ]; then rm -rf assets && cp -R /tmp/xcard_assets assets; fi

/usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string X-Card" ios/Runner/Info.plist 2>/dev/null || /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName X-Card" ios/Runner/Info.plist
/usr/libexec/PlistBuddy -c "Add :CFBundleName string X-Card" ios/Runner/Info.plist 2>/dev/null || /usr/libexec/PlistBuddy -c "Set :CFBundleName X-Card" ios/Runner/Info.plist
/usr/libexec/PlistBuddy -c "Add :NSPhotoLibraryUsageDescription string 用于从相册选择并上传你的银行卡卡面照片" ios/Runner/Info.plist 2>/dev/null || true

echo "完成。Bundle ID: com.xcard.x_card"
