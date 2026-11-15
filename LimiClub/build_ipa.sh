#!/usr/bin/env bash
# 在 macOS 上一键生成「未签名 .ipa」，可直接交给签名工具或签名服务。
# 用法：bash build_ipa.sh
set -euo pipefail
cd "$(dirname "$0")"

APP_TARGET="LimiClub"
IPA_NAME="LIMI俱乐部-unsigned.ipa"

echo "==> 1/4 生成工程"
if command -v xcodegen >/dev/null 2>&1; then
  xcodegen generate
elif [ -d "LimiClub.xcodeproj" ]; then
  echo "    未安装 xcodegen，改用已有的 LimiClub.xcodeproj"
else
  echo "缺少 xcodegen，请先执行: brew install xcodegen" >&2
  exit 1
fi

echo "==> 2/4 编译（关闭签名）"
rm -rf build out "$IPA_NAME"
xcodebuild -project LimiClub.xcodeproj -target "$APP_TARGET" \
  -sdk iphoneos -configuration Release -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" \
  CODE_SIGN_ENTITLEMENTS="" build

APP_PATH="$(find build/Build/Products/Release-iphoneos -maxdepth 1 -name '*.app' | head -n 1)"
if [ ! -d "$APP_PATH" ]; then
  echo "编译产物里没有 .app，检查上面的报错" >&2
  exit 1
fi

echo "==> 3/4 组装 Payload"
mkdir -p out/Payload
cp -R "$APP_PATH" out/Payload/

echo "==> 4/4 打包"
( cd out && zip -qry "../$IPA_NAME" Payload )

ls -lh "$IPA_NAME"
echo
echo "完成: $(pwd)/$IPA_NAME"
echo "下一步: AltStore / Sideloadly / 爱思助手 / 签名服务 签名后安装。"
