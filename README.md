# today_madness（今日份发疯）

## 项目简介

**今日份发疯** 是一款情绪视觉化卡片生成器，基于 Flutter 跨平台开发，支持 Android、Web、Windows 多端运行。核心流程：用户选择心情 Emoji → AI 生成"发疯语录" → 搭配粒子动画 & 毛玻璃渐变背景 → 生成卡片 → 保存分享。

- **技术栈**: Flutter 3.12.1 / Dart / Provider / sqflite / Dio / DeepSeek API / fl_chart
- **设计规范**: Material 3

---

## 小组分工

| 成员 | 角色 | 负责模块 | 文件 |
|:---|:---|:---|:---|
| 成员 1 | 数据层 | Part 1 数据库存储 | `madness_card_model.dart` `madness_database.dart` `madness_local.json` |
| 成员 2 | 状态管理 | Part 2 首页 UI | `madness_provider.dart` `home_page.dart` |
| 成员 3 | AI 服务 | Part 3 AI 生成 & 粒子动画 | `ai_madness_service.dart` `chaos_particle.dart` |
| 成员 4 | 预览与保存 | Part 4 预览 & 截图 | `preview_page.dart` `screenshot_helper.dart` `save_file_web.dart` `save_file_stub.dart` |
| 成员 5 / 组长 | 主框架 & 整合 | Part 5 主框架 + 最终提交 | `main.dart` `pubspec.yaml` `timeline_page.dart` `stats_page.dart` `README.md` |

---

## 项目文件清单

### 入口 & 配置

| 文件 | 说明 |
|:---|:---|
| `pubspec.yaml` | 项目配置、第三方依赖声明 |
| `lib/main.dart` | APP 入口：MultiProvider + MaterialApp + 路由 + 底部导航 |

### 数据层

| 文件 | 说明 |
|:---|:---|
| `lib/models/madness_card_model.dart` | 发疯卡片数据模型 |
| `lib/services/madness_database.dart` | 数据库服务（sqflite / SharedPreferences 兼容 Web） |
| `assets/madness_local.json` | 本地语录兜底数据 |

### 业务逻辑

| 文件 | 说明 |
|:---|:---|
| `lib/services/ai_madness_service.dart` | DeepSeek API 调用 + 本地 JSON 兜底 |
| `lib/providers/madness_provider.dart` | Provider 状态管理 |

### 页面

| 文件 | 说明 |
|:---|:---|
| `lib/screens/home_page.dart` | 首页：心情选择 + 贴纸 + 生成卡片 |
| `lib/screens/preview_page.dart` | 预览页：毛玻璃卡片 + 粒子动画 + 保存 |
| `lib/screens/timeline_page.dart` | 时光轴：日历视图 + 按日期查询历史 |
| `lib/screens/stats_page.dart` | 周报：7 天情绪占比饼图 + 截图 |

### 工具 & 组件

| 文件 | 说明 |
|:---|:---|
| `lib/widgets/chaos_particle.dart` | CustomPainter 粒子动画 |
| `lib/utils/screenshot_helper.dart` | 截图保存辅助 |
| `lib/utils/save_file_web.dart` | Web 端文件下载 |
| `lib/utils/save_file_stub.dart` | 移动端空实现（条件导入） |
