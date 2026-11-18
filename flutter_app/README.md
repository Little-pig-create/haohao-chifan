# 好好吃饭 · Flutter

一套 Flutter 代码，Android / iOS 共用；桌面与 Web 用于预览。所有数字都来自本机记录或系统健康数据，界面里不再有预置的假数据。

## 页面

| 一级 | 内容 |
| --- | --- |
| 首页 | 步数 / 心率 / 睡眠 / 饮水四块指标、分段热量环、营养概览、今日目标、快捷记录 |
| 饮食 | 每日摄入、三餐时间线、拍照识别、搜索添加、一句话记录、饮水 |
| 运动 | 今日步数环、7 天活动柱状图、Health Connect 同步的运动、68 种内置运动、按时长/数量记录、常用优先排序、AI 自定义运动 |
| 趋势 | 热量趋势、宏量环形图、身体信号、体重曲线、目标完成度、AI 洞察、日报/周报 |
| AI | 健康评分、今日总结、可执行计划、真实模型对话 |
| 我的 | 账号（本地）、目标、AI 引擎、提醒、备份导入导出 |

## 首次引导

新用户填完个人资料后，会进入两步设置向导：

1. **每日目标**：按身高、体重、年龄和轻活动量估算热量，并给出蛋白质、饮水、步数与目标体重建议；全部可以微调，也能一键回到推荐值。
2. **AI 引擎**：从内置的国内服务商里选择一家，填入自己的 API Key，保存后自动拉取模型并启用第一个模型；也可以先跳过，或转到完整模型设置页自定义地址。

两步都可以跳过。跳过后首页会保留一张设置清单，完成后自动消失；也可以在「我的 → 新手引导」里重新进入。每日目标保存后，首页的热量环、饮水、步数和蛋白质目标会立即同步。

## 数据都是真的

| 数据 | 来源 | 说明 |
| --- | --- | --- |
| 步数 | Health Connect → 手机计步传感器 | HC 有全天数据时优先用 HC；没有时读 `TYPE_STEP_COUNTER`，从首次打开起累计 |
| 心率 / 睡眠 / 体重 / 体脂 / 活动消耗 | Health Connect（HealthKit） | 只读，需要用户授权 |
| 运动记录 | Health Connect `ExerciseSession` + 手动记录 | 设备同步的运动会单独列出，不重复计入手动记录 |
| 运动消耗模型 | `assets/data/exercise_energy.json` + AI 自定义结果 | 线性系数 + 二次修正，按体重与强度换算；自定义结果写入本地并随备份导出 |
| 饮食 / 饮水 | 用户记录 | 完成一餐或手动添加后计入，未记录就是 0 |
| 体重 / 围度 | 用户记录或 HC 同步 | 没有记录显示「未记录」，不显示占位数字 |
| AI 结论 | 你配置的模型 | 未配置时使用本地规则，并在卡片上标明「本地规则」 |

### 运动数据到底怎么接

1. **Health Connect（推荐）**：Android 14+ 系统自带；Android 13 及以下需要安装 Health Connect。用户在 App 里点「连接」授权后，可读取步数、心率、睡眠、体重、体脂、活动消耗和运动 session。
2. **手机计步传感器**：`pedometer` 读取 `TYPE_STEP_COUNTER`，只依赖 `ACTIVITY_RECOGNITION` 权限，不需要任何第三方 App。缺点是传感器给的是「开机以来」的累计值，本 App 用跨天基线换算成今天的数据，因此从首次打开起累计。
3. **厂商健康 App**：OPPO / 一加「健康」、华为运动健康、小米运动健康都有自己的 SDK，需要企业资质与商务申请，个人包无法直接接入；可行做法是让用户在系统设置里把这些 App 的数据同步到 Health Connect。
4. **手动记录**：始终可用，也是没有可穿戴设备时最可靠的方式。

### 运动消耗模型怎么维护

内置运动的消耗关系放在 `assets/data/exercise_energy.json`，不再写死在页面里。每一项包含：

- `metric`：`duration` 按时长（分钟）或 `count` 按数量（个）。
- `met`：代谢当量，用于展示和兜底计算。
- `linearKcalPerUnit`：60kg、适中强度下每单位消耗；时长型是千卡/分钟，数量型是千卡/个。
- `quadraticKcalPerUnit2`：二次修正系数，默认 0；长时段边际消耗下降时填负值。
- `repsPerMinute`：数量型运动每分钟完成次数，用来估算记录时长。

计算公式：

```text
kcal = (linearKcalPerUnit * x + quadraticKcalPerUnit2 * x^2)
       * weightKg / referenceWeightKg
       * intensityFactor
```

其中 `x` 对时长型是分钟、数量型是个数；强度系数为低 0.8、适中 1.0、高 1.25。找不到的运动可在「添加运动 → 让 AI 估算」里输入名称、记录方式和数量，AI 返回的 `met`、`repsPerMinute` 与可选的二次修正会写入「自定义」分类，并随本地备份导出，后续可直接复用。

## AI 模型

「我的 → AI 引擎」里管理提供商：

- 预设：DeepSeek、通义千问、Kimi、智谱 GLM、火山方舟、硅基流动、MiniMax、腾讯混元、百度千帆，以及任意兼容 OpenAI 协议的地址。
- 填 Base URL + API Key 后自动拉取 `/models`；服务不提供该接口时用预设清单兜底，也可以手动输入模型 ID。
- 拉取到的模型可以逐个勾选，只有勾选的模型会出现在切换列表里。
- API Key 只写入系统安全存储（Keychain / Keystore），不写进 SharedPreferences，也不会打包进应用。
- 网络请求由设备直接发往所选提供商，不经过本项目的服务器。

AI 参与的功能：一句话记饮食、拍照识别餐盘、身体数据一句话记录、自定义运动消耗估算、健康问答、三餐生成、搭配建议、日报/周报。

## 权限

Android（`AndroidManifest.xml`）：

- `INTERNET`
- `ACTIVITY_RECOGNITION`、`BODY_SENSORS`
- `health.READ_STEPS / HEART_RATE / RESTING_HEART_RATE / SLEEP / WEIGHT / BODY_FAT / ACTIVE_CALORIES_BURNED`
- `CAMERA`、`POST_NOTIFICATIONS`

iOS（`Info.plist`）：HealthKit 读取、相机、相册、运动与健身（`NSMotionUsageDescription`）。

## 运行与打包

```bash
flutter pub get
flutter run -d linux      # 桌面预览（390×844 窗口）
flutter build apk --release
```

产物：`build/app/outputs/flutter-apk/app-release.apk`

包名 `com.haohao.haohao_chifan`，versionName 2.0.0。release 目前用 Flutter 模板的 debug 签名，可直接安装测试，上架前请替换为自己的签名。

## 本地存储

- 记录：`SharedPreferences`（key `haohao.flutter.v3`），可在「我的 → 数据」导出 JSON 到剪贴板或从剪贴板恢复。
- 自定义运动与 AI 消耗模型：同样写入本地记录 JSON 的 `customExercises` 字段，导出/导入时一起迁移。
- AI 聊天记录、日报和周报：写入本地记录 JSON 的 `chatMessages` / `aiReports` 字段，重启和备份恢复后仍在。
- 模型密钥：`flutter_secure_storage`（`llm_key_<providerId>`）。
- 计步基线：`haohao.step.*`。

## 已知限制

- Health Connect 里没有数据时，只能依赖手机传感器，步数从首次打开起算。
- HarmonyOS 暂未接入（需要鸿蒙原生或 ArkUI 版本，Flutter 官方支持仍在推进）。
- 没有后端账号系统，登录仅在本机生效。
