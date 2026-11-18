# X-Card 构建与安装说明

一个用于管理信用卡 / 借记卡的本地 iOS App。项目为 Flutter 源码工程，**IPA 需要你在 Codemagic 云端编译**（本机 Windows 无法编译 iOS），编译完成后用 TrollStore 安装。

---

## 一、已实现功能

| 模块          | 内容                                                                       |
| ----------- | ------------------------------------------------------------------------ |
| 卡片管理        | 添加 / 编辑 / 删除卡片；卡号自动脱敏（只保留后四位）；额度、账单日、还款日、有效期、备注                          |
| 卡面图库        | 12 款内置渐变卡面 + 从相册上传自己的卡片照片；添加卡片时可选                                        |
| 信用卡 / 借记卡切换 | 顶部胶囊按钮 + 侧边栏双入口切换，两个界面的数据严格分离                                            |
| 还款提醒        | iOS 本地通知，可为每张信用卡按还款日安排提醒（默认提前 3 天 09:00，可设置 1/2/3/5/7/10 天）              |
| 账单          | 选择具体卡片记账，区分「消费 / 收入」，填写金额、分类、备注、日期；左滑删除；按卡片筛选                            |
| 活动          | 自定义活动目标，例如「本月刷满 10000 元」或「刷卡 8 次」；逐笔记录进度，实时查看已完成 / 还差 / 完成度；可编辑活动内容和进度记录 |
| 消费统计        | 按时间范围查看支出 / 收入 / 结余，支出分类饼图、月度收支柱状图                                       |
| 隐私          | 数据仅存本机 SQLite，不联网、不上传                                                    |

---

## 二、关于「卡面图库」的重要说明

你要求「获取现目前所有的银行卡卡面」——这一点无法照做，原因：

1. 银行卡卡面图案属于各银行的**版权 / 商标资产**，不存在公开 API，批量抓取并内置到 App 中是侵权风险；
2. 即使抓到，卡面随银行发卡版本不断变化，也无法保证「全部」。

因此内置的替代方案是：

- **12 款原创渐变卡面**（曜石黑、深海蓝、香槟金、玫瑰金、森林绿、赤焰红、幻彩紫、极简白、石墨灰、暮光橙、薄荷绿、星空）；
- **上传照片**：在添加 / 编辑卡片时点「上传照片」，从相册选你的真实银行卡照片，App 会把图片复制到应用私有目录并作为卡面显示。

这样你依然能在上传卡片时选择对应卡面，且完全合规。如果你确实需要真实银行 logo 合集，建议自行从各银行官网获取授权素材后放到 `assets/` 并改写 `lib/data/card_faces.dart`。

---

## 三、项目结构

```
x_card/
├─ codemagic.yaml          # Codemagic 构建配置（关键：无签名构建 + 打包 IPA）
├─ pubspec.yaml            # Flutter 依赖
├─ setup_ios.sh            # 本地 Mac 生成 iOS 工程的可选脚本
├─ ios_templates/
│   └─ XCard.entitlements  # 可选：进阶 ldid 伪签名使用的权限文件
├─ lib/
│   ├─ main.dart           # 入口：初始化通知 + 排期还款提醒
│   ├─ app.dart            # 主框架：底部导航 + 侧边栏 + 信用卡/借记卡切换
│   ├─ theme.dart
│   ├─ data/
│   │   ├─ database.dart       # SQLite：cards / bills / activities / activity_logs
│   │   └─ card_faces.dart     # 12 款内置卡面定义
│   ├─ models/                 # bank_card / bill / activity
│   ├─ services/
│   │   └─ notification_service.dart
│   ├─ screens/                # cards / card_editor / card_detail / bills / activities / statistics / settings
│   └─ widgets/                # 卡面渲染 + 通用组件
└─ README.md
```

Bundle ID：`com.xcard.x_card`（Codemagic 生成 iOS 工程时自动设置）。

---

## 四、用 Codemagic 生成 IPA（详细步骤）

### 4.1 准备代码仓库

Codemagic 只从 Git 仓库拉代码，所以先建仓库：

1. 新建一个 GitHub（或 GitLab / Bitbucket）仓库，例如 `x-card`。
2. 把 `x_card` 文件夹**里面的内容**（`codemagic.yaml`、`pubspec.yaml`、`lib/`、`assets/`、`ios_templates/`、`README.md`）提交到仓库根目录。注意不要把外层的 `x_card` 文件夹本身作为一层目录提交，否则 `codemagic.yaml` 不在根目录不会被识别。
3. 确认 `codemagic.yaml` 位于仓库根目录。

用命令行示例（在 `x_card` 目录内执行）：

```bash
git init
git add .
git commit -m "X-Card initial"
git branch -M main
git remote add origin https://github.com/你的用户名/x-card.git
git push -u origin main
```

### 4.2 在 Codemagic 添加应用

1. 打开 <https://codemagic.io> 注册 / 登录（可用 GitHub 账号直接授权）。
2. 点 **Add application**，选择刚才的仓库。
3. 项目类型选 **Flutter App**，配置方式选 \** codemagic.yaml\*\*（Configuration as code）。Codemagic 会自动读取仓库根目录的 `codemagic.yaml`。
4. 无需配置任何签名证书——我们的工作流是 `flutter build ios --release --no-codesign`，不需要 Apple Developer 账号。

### 4.3 触发构建

1. 进入应用 → **Start new build**。
2. 分支选 `main`。
3. 在 **Select workflow from codemagic.yaml** 下拉框选择 `ios-trollstore-unsigned`。
4. 点 **Start new build**，等待约 5–15 分钟。
5. 构建成功后，在 **Artifacts** 中下载 `X-Card.ipa`。

构建流程做了 4 件事：拉依赖 → 若仓库没有 `ios/` 则用 `flutter create` 自动生成并设置 Bundle ID → 无签名编译 → 把 `.app` 打包成标准 IPA 结构。

> 如果构建报 Flutter 版本相关错误，可把 `codemagic.yaml` 里的 `flutter: stable` 改成具体版本（例如 `flutter: 3.24.5`）。  
> 如果实例类型不可用，把 `instance_type: mac_mini_m1` 改成 `mac_mini` 或 `mac_mini_m2`。

### 4.4 产物

下载得到 `X-Card.ipa`，这是一个**未签名**的 IPA。这正是 TrollStore 需要的输入——TrollStore 会用伪根证书重签并永久安装。

---

## 五、安装 TrollStore（你的 iOS 16.3.1）

你的系统 **iOS 16.3.1 在 TrollStore 2 支持范围内**（官方支持 14.0 beta 2 – 16.6.1、16.7 RC、17.0）。**不要升级系统**，升级后大概率失去兼容。

如果你已装好 TrollStore，可跳过本节。

推荐路径（iOS 16.0–16.6.1）：**TrollInstallerX + Sideloadly**。

1. 在电脑下载 Sideloadly（<https://sideloadly.io>，支持 Windows / macOS）。
2. 从 TrollInstallerX 的 GitHub Releases 页下载最新的 `TrollInstallerX.ipa`。
3. iPhone 用数据线连电脑，弹窗点「信任此电脑」。
4. 打开 Sideloadly，选择设备，点 IPA 图标选中 `TrollInstallerX.ipa`。
5. 输入一个**Apple ID**（建议用次要账号，仅用于向 Apple 验证签名，7 天有效，装完 TrollStore 后不再需要）。
6. 点 **Start**，等待完成。
7. 手机上若打不开，去「设置 → 通用 → VPN 与设备管理」信任对应开发者证书。
8. **iOS 16 需开启开发者模式**：设置 → 隐私与安全性 → 开发者模式 → 开启 → 重启 → 弹窗点「打开」。
9. 打开 TrollInstallerX，点 **Install TrollStore**，按提示选择一个系统应用作为「持久化助手」（例如「提示 / Tips」）；安装完成后重启。
10. 主屏出现 TrollStore 图标。打开 TrollStore → **Settings** → 点 **Install ldid**（处理未签名 IPA 需要）。

更权威、随版本更新的说明见：<https://ios.cfw.guide/installing-trollstore/>，按你的 iOS 16.3.1 选择对应方法即可。

---

## 六、用 TrollStore 安装 X-Card

1. 把 `X-Card.ipa` 传到手机（AirDrop、iCloud Drive、或用浏览器下载到「文件」App）。
2. 在「文件」App 中长按 IPA → 共享 → 选择 **TrollStore**；  
   或打开 TrollStore → **Apps** 标签 → 点 `+` → 选择 IPA。
3. 等待安装完成，主屏出现 **X-Card** 图标。

> 若提示签名相关错误：先确认 TrollStore 设置里已点过 **Install ldid**，然后重试。  
> TrollStore 安装的应用**只能通过 TrollStore 自身卸载**，长按图标不会出现「移除 App」。

---

## 七、首次使用配置

1. 打开 X-Card → 允许通知权限。
2. 顶部切换到「信用卡」，点「添加信用卡」：
   - 填写名称、银行、卡号（建议只填后四位）、额度、账单日、还款日；
   - 在「选择卡面」里挑一款内置卡面，或点「上传照片」用真实卡面。
3. 切到「设置与通知」：
   - 选择提前提醒天数；
   - 点「重新安排所有提醒」；
   - 点「发送测试通知」确认能收到。
4. 切回「账单」开始记账；「活动」里新建目标（例如本月消费 10000 元），之后逐笔记录进度即可看到完成度。
5. 顶部胶囊按钮或侧边栏可随时切换信用卡 / 借记卡，两套数据互不影响。

---

## 八、进阶：手动伪签名（可选，一般不需要）

TrollStore 会自动重签，通常无需这一步。若某些版本要求 IPA 内二进制已带 entitlements，可在 Mac 上执行：

```bash
unzip X-Card.ipa -d xcard_tmp
# 注意：二进制文件名是 Runner，即使外层 .app 已改名为 X-Card.app
ldid -Sios_templates/XCard.entitlements xcard_tmp/Payload/X-Card.app/Runner
cd xcard_tmp && zip -qr ../X-Card-fakesigned.ipa Payload
```

`XCard.entitlements` 只声明了 `get-task-allow`，在你的 iOS 16.3.1 上是安全的。

**不要**添加以下权限——iOS 15+ 的 A12 及更新机型已封禁，App 会启动即崩溃：

- `com.apple.private.cs.debugger`
- `dynamic-codesigning`
- `com.apple.private.skip-library-validation`

---

## 九、已知限制与风险

- **卡面**：内置的是原创渐变设计，不是真实银行卡卡面；真实卡面需自行拍照上传。
- **卡号安全**：App 只保存卡号后四位，不保存完整卡号、有效期外的 CVV 等敏感信息。不建议在此类本地工具中存放完整支付凭证。
- **数据仅本机**：SQLite 存在 App 沙盒里，卸载 App（包括用 TrollStore 卸载）会丢失数据；当前版本未实现导出 / 备份。
- **通知**：依赖 iOS 本地通知。App 至少启动过一次才会排期；重启设备、低电量模式或长时间未打开时，触发时机可能有延迟，不能当作金融级强提醒。
- **TrollStore 风险**：属于利用系统漏洞的侧载方式，与 Apple 服务条款相冲突；建议使用备用机，重要数据先备份。
- **系统升级**：升级到不支持的 iOS 版本会导致 TrollStore 及其安装的应用无法启动。

---

## 十、常见问题

**Q：Codemagic 构建失败，报 code signing 相关错误？**  
确认 `codemagic.yaml` 中没有 `ios_signing` 段落，构建命令必须是 `flutter build ios --release --no-codesign`。

**Q：下载到的不是 IPA 而是一个 `.app.zip`？**  
说明手动构建时走了默认 artifact 配置；请用仓库自带的 `codemagic.yaml`，其第 4 步会打包出 `output/X-Card.ipa`。

**Q：TrollStore 里安装后打不开？**  
确认已开启开发者模式（iOS 16 必须）；检查 TrollStore 设置中的持久化助手；如图标缓存重载后失效，打开被注入的系统应用（如「提示」）执行 Refresh App Registrations。

**Q：收不到还款提醒？**  
到「设置与通知」点「发送测试通知」验证权限；若测试通知也没有，去 iOS 设置 → 通知 → X-Card 打开允许通知；再点一次「重新安排所有提醒」。
