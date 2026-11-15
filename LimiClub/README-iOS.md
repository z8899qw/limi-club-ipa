# LIMI俱乐部 iOS 端 · 自签名打包说明

这个工程是 iOS 的**外壳 App**：界面全部由服务器下发（`https://limi.xn--fiqs8s/app` 起），
所以**以后改功能、加页面，都不需要重新打包**，装一次就够了。

- 语言：Swift 5
- 最低系统：**iOS 15.0**（覆盖 iPhone 6s 及以后）
- Bundle ID：`club.limi.app`
- 版本：1.0.1 (build 2)
- 仅 iPhone 竖屏
- 支持：网页跳转分流（外链走 Safari）、文件下载（落「文件」App 并可分享）、
  相机/相册选图、alert / confirm / prompt 原生弹窗、离线提示 + 备用 IP 入口

---

## 一、最快路径：有 Mac + Xcode（推荐）

### 1. 用 XcodeGen 生成工程（30 秒）

```bash
# 没装过就装一次
brew install xcodegen

cd LimiClub
xcodegen generate
open LimiClub.xcodeproj
```

不想装 XcodeGen 也可以手动建（见第二节）。

### 2. 填你自己的签名信息

Xcode 里选中左上角 **LimiClub** 工程 → **TARGETS → LimiClub** → **Signing & Capabilities**：

| 项 | 填什么 |
| --- | --- |
| Team | 你的 Apple ID（个人免费账号也行） |
| Bundle Identifier | `club.limi.app`，被占用就改成 `com.你的名字.limi` |
| Automatically manage signing | 打勾 |

> 免费 Apple ID 签名有效期 **7 天**，到期重装即可；
> 付费开发者账号（$99/年）是 **1 年**。

### 3. 装到手机

1. iPhone 用数据线连 Mac，手机上点「信任此电脑」
2. Xcode 顶部选中你的 iPhone（不要选模拟器）
3. 点 ▶️ 运行
4. 第一次会提示「不受信任的开发者」：
   **设置 → 通用 → VPN与设备管理 → 开发者App → 你的 Apple ID → 信任**

### 4. 长期可用（可选）

免费账号 7 天过期，可以在 Mac 上做一次（需要先 `brew install ios-deploy` 或用 Xcode）：

或者直接告诉我要长期方案，可以改成：
- 用 AltStore / SideStore 自动续签（手机端每 7 天自动重签一次）
- 或者用企业证书（你自备）

---

## 二、没有 XcodeGen：手动建工程（3 分钟）

1. Xcode → **File → New → Project → App**
2. Product Name 填 `LimiClub`，Interface 选 **Storyboard**，Language 选 **Swift**
3. 删掉自动生成的 `ViewController.swift`、`Main.storyboard`、`SceneDelegate.swift`、`AppDelegate.swift`
   （右键 → Delete → Move to Trash）
4. 把本工程 `Sources/` 下的 **3 个 .swift 文件**拖进 Xcode（勾选 Copy items if needed）
5. 选中工程 → **Info** 标签，逐个添加：

| Key | 值 |
| --- | --- |
| `NSCameraUsageDescription` | 拍考核截图时使用相机 |
| `NSPhotoLibraryUsageDescription` | 上传考核截图时选择相册里的图片 |
| `NSPhotoLibraryAddUsageDescription` | 保存导出的文件 |
| `UISupportedInterfaceOrientations` | 只留 `Portrait` |
| `UIRequiresFullScreen` | YES |
| `NSAppTransportSecurity` → `NSAllowsArbitraryLoads` | YES（备用 IP 是 http，必须开） |
| `UIApplicationSceneManifest` → `UIApplicationSupportsMultipleScenes` | NO |

6. **Deployment Target 改成 15.0**（Project → Info → iOS Deployment Target）
7. 按第一节第 2、3 步签名并安装

> 如果没有 `UIApplicationSceneManifest`，App 会黑屏 —— 这个键不能漏。
> 代码里已经在 `AppDelegate.configurationForConnecting` 指定了 `SceneDelegate`，所以
> `UISceneConfigurations` 里不写 `UISceneDelegateClassName` 也能跑。

---

## 三、不想签名？用「添加到桌面」（零成本，1 分钟）

`LIMI俱乐部-iOS-添加到桌面.mobileconfig` 是 iOS 的 **Web Clip 描述文件**：

1. 手机上打开 `https://limi.中国/app`
2. Safari 底部 **分享** → **添加到主屏幕**
3. 或者把 `LIMI俱乐部-iOS-添加到桌面.mobileconfig` 发到手机（微信/AirDrop/邮件），
   点开 → 设置里 **已下载描述文件** → 安装

装完桌面会出现带兔子图标的 **LIMI俱乐部**，点开全屏运行、没有 Safari 地址栏，
体验和 App 几乎一样。区别只有两点：没有离线缓存（断网打不开）、不会自己更新版本号。

---

## 四、改了什么要重新打包？

| 改动 | 要不要重打 IPA |
| --- | --- |
| 页面、功能、数据、样式 | **不要**（服务器下发） |
| 换域名 / 换入口地址 | 要改 `ViewController.swift` 顶部 `C.start` / `C.alt` 后重打 |
| 换图标、改 App 名 | 要 |
| 改下载目录、加原生能力 | 要 |

---

## 五、文件清单

```
LimiClub/
├─ project.yml                     XcodeGen 工程描述
├─ README-iOS.md                   本文件
└─ Sources/
   ├─ AppDelegate.swift             入口 + 指定 SceneDelegate
   ├─ SceneDelegate.swift           建窗口
   └─ ViewController.swift          WKWebView 外壳（全部逻辑都在这）
```

图标素材在服务器上（`/apple-touch-icon.png`、`/icon-512.png`），
要做 AppIcon 直接下载这俩拖进 `Assets.xcassets` 即可。

## 怎么出 .ipa（三条路，按你的条件选）

> 先说结论：**Windows 上出不了 .ipa**。`.ipa` 本质是 `Payload/xxx.app` 的 zip，
> 而 `.app` 里的可执行文件必须由 Apple 的 iOS SDK 编译（swiftc 只能装在 macOS 上）。
> 签名工具只能给**已编译好的二进制**签名，不能把源码变成二进制。

### 路线 1：有 Mac → 一条命令（推荐）

```bash
cd LimiClub
bash build_ipa.sh
```

跑完就在当前目录得到 `LIMI俱乐部-unsigned.ipa`，直接丢给
AltStore / Sideloadly / 爱思助手 / 签名服务。

脚本做的事：`xcodegen generate` → `xcodebuild -sdk iphoneos -configuration Release`
（关掉签名）→ 组装 `Payload/` → `zip` 成 ipa。没装 xcodegen 就先 `brew install xcodegen`。

### 路线 2：没有 Mac，但有 GitHub 账号 → 免费 Mac 替你编译

1. 在 GitHub 新建一个仓库（Public 或 Private 都行）
2. 网页上「Add file → Upload files」，把整个 `LimiClub` 文件夹连同里面隐藏的
   `.github/` 一起拖进去（**`.github/workflows/ios-build.yml` 必须一起传**）
3. 进 Actions 标签 → 左边选 `build-unsinged-ipa` → 右侧 **Run workflow**
4. 等 3–5 分钟，任务详情页底部 **Artifacts** 里下载 `limi-club-ipa`，解压就是 ipa

免费额度对个人仓库足够（macOS 虚拟机每月有免费分钟数），**不需要本地装任何东西**。

### 路线 3：直接找签名服务

把路线 1 或 2 得到的 ipa 发给签名商（企业签 / 个人签 / 超级签）。
他们需要的就是一个**未签名的正常 ipa**，路线 1、2 产出的正是这个。

### 签完怎么装

- **Sideloadly / AltStore**：手机连电脑 → 选 ipa → 输 Apple ID → 装
- **爱思助手**：工具 → IPA 签名 → 导入 ipa + 证书 → 装
- **TrollStore**（部分系统版本）：直接把 ipa 拖进手机
- 免费 Apple ID 签的 **7 天过期**，到期重签；付费开发者账号 1 年

### 为什么一开始给的是 Web Clip

`LIMI俱乐部-iOS-添加到桌面.mobileconfig` 不需要编译、不需要签名、不需要 Mac，
30 秒就能装上用，是「没有 Mac 又不想折腾」时的最优解。
真 APP 的价值只有两点：能拿到系统级能力（下载落地、拍照直连），以及没有 7 天过期。
