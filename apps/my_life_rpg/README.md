# MY_LIFE_RPG (个人心智操作系统)

> *“不仅是管理时间，更是为了对抗熵增，守护心智的连续性。”*

![Platform](https://img.shields.io/badge/Platform-Android%20(8%22%20Tablet)-green) ![Stack](https://img.shields.io/badge/Tech-Flutter%20%7C%20GetX-blue) ![Style](https://img.shields.io/badge/Style-Cyberpunk%20%7C%20Console-purple) ![Status](https://img.shields.io/badge/Status-Alpha%20(Memory%20Persistence)-orange)

## 📖 项目简介

**My Life RPG** 是一个专为 **INTP 人格** 及 **高认知负荷的脑力工作者** 设计的个人管理终端。

这不是一个传统的 Todo List。传统的管理软件假设用户是机器人，能够精确执行计划；而本项目承认人性的弱点——我们会有**启动困难**、**上下文丢失**、**时间感知模糊**以及**对琐事的本能抗拒**。

本项目运行在一台 **8寸常亮 Android 平板** 上，作为您大脑的**外部挂载点 (External Cognitive Mount)**，通过游戏化（RPG）和控制台（Console）的隐喻，帮助您：

1.  **持久化上下文**：解决“散点式学习”回来后忘记进度的痛点。
2.  **可视化时间熵**：直观感受时间的流逝与有效产出。
3.  **系统化维护**：将生活琐事转化为“系统守护进程”，消除决策疲劳。

---

## 💡 核心哲学 (Core Philosophy)

*   **Context Over Tasks (上下文 > 任务)**
    我们不只关注“是否勾选了完成”，更关注“执行过程中的思考与状态”。通过“驾驶舱”模式，像写代码 commit log 一样记录人生。

*   **Stream Over Batch (流 > 批次)**
    人生是连续的流。拒绝死板的截止日期焦虑，拥抱“时间片 (Session)”积累。

*   **Anti-Entropy (反熵增)**
    通过 **Temporal Matrix (时空矩阵)**，将红色的“熵”（无意识的时间流逝）转化为绿色的“产出”（有意识的投入）。

*   **Low Friction (极低摩擦)**
    交互设计遵循“单兵作战终端”风格。宏指令、一键补录、呼吸灯反馈，一切为了在最低心智阻力下启动心流。

---

## 🚀 功能特性 (Features)

### 1. 舰桥仪表盘 (The HUD)
*   **XP 积分板**：实时计算今日有效产出 (XP)，提供即时多巴胺反馈。
*   **时间光谱**：可视化进度条，展示 [有效时间 | 熵 | 未来] 的比例。
*   **终焉倒计时**：距离强制睡眠时间 (01:00) 的动态倒计时。

### 2. 战术驾驶舱 (Session Cockpit)
*   **呼吸计时器**：具有生命感的计时动画，伴随你进入心流。
*   **日志流**：类似 CLI 的日志记录，支持 Bug、里程碑、灵感等多种类型。
*   **宏指令**：一键输入常用 Tag，减少键盘交互。

### 3. 时空矩阵 (Temporal Matrix)
*   **15分钟粒度**：将一天拆解为 96 个时间胶囊。
*   **可视化 Deadline**：在时间轴上通过红框精确标记任务截止点。
*   **事后补录**：忘记计时？直接在矩阵上框选时间段，归档到任务中。

### 4. 任务系统 (Mission & Daemons)
*   **Campaigns (战役)**：长期关注的战略项目（如：Flutter 架构、副业）。
*   **Missions (行动)**：具体的执行单元。
*   **Daemons (守护进程)**：循环触发的生活琐事（如：清理下水道）。自动计算逾期天数，基于“冷却时间”而非“截止日期”。

---

## 🛠 技术架构 (Architecture)

项目采用 **Clean Architecture** 分层设计，确保可维护性与扩展性。

```text
lib/
├── core/                  # 核心基建
│   ├── theme/             # Design Tokens (AppColors, TextStyles)
│   └── widgets/           # 原子组件 (RpgContainer, RpgTag)
├── models/                # 领域模型 (Quest, Session, Project)
├── services/              # 业务逻辑层 (Service)
│   ├── quest_service.dart # 任务管理、数据源
│   └── time_service.dart  # 时间计算、矩阵渲染
├── controllers/           # 视图控制层 (ViewModel)
│   ├── game_controller.dart    # App 启动与编排
│   ├── session_controller.dart # 驾驶舱逻辑
│   └── matrix_controller.dart  # 矩阵交互
└── views/                 # UI 视图层
    ├── home/              # 首页 (HUD, Panels, Matrix)
    └── session/           # 驾驶舱页面
```

*   **State Management**: GetX (Reactive Programming)
*   **Persistence**: 目前为 **Memory-Only (内存模式)**，数据重启即焚（Alpha 阶段特性，专注于功能打磨）。未来计划迁移至 `Drift (SQLite)`。
*   **UI System**: 自研 **Cyberpunk Design System**，脱离 Material 默认样式，使用 Courier 等宽字体与高对比度配色。

---

## 🎮 使用指南 (User Guide)

1.  **启动 (Initialize)**
    *   打开 App，查看 HUD 的状态。
    *   左侧面板展示当前待办 (Active Missions) 和逾期的守护进程 (Daemons)。

2.  **创造 (Deploy)**
    *   点击 Header 上的 `[+]` (橙色) 创建新任务，支持设置精确 Deadline。
    *   点击 Header 上的 `[Loop]` (青色) 创建循环维护任务。

3.  **执行 (Engage)**
    *   点击任意任务卡片进入 **驾驶舱**。
    *   计时开始，呼吸灯闪烁。
    *   在底部输入框或使用宏指令记录过程中的想法、Bug 或进度。
    *   点击 `TERMINATE` 存档退出，赚取 XP。

4.  **复盘 (Audit)**
    *   观察右侧 **时空矩阵**。
    *   实心色块代表已投入的时间，红框代表 Deadline。
    *   如果有未记录的时间段，点击矩阵空白处进行 **手动补录 (Manual Allocate)**。

---

## 📅 Roadmap

- [x] **Phase 1: Prototyping** (当前阶段)
    - [x] HUD & XP 系统
    - [x] 驾驶舱与日志流
    - [x] 时空矩阵与补录
    - [x] 内存数据管理
- [ ] **Phase 2: Persistence**
    - [ ] 引入 `Drift` 数据库
    - [ ] JSON 序列化/反序列化
- [ ] **Phase 3: Intelligence**
    - [ ] 接入 LLM (Local/API)
    - [ ] AI 每日总结与建议
    - [ ] 守护进程 SOP 自动弹窗

---

## 📝 License

Copyright © 2024 Maeiee.
Designed for the restless mind.

---

*“愿你的每一行代码，每一次思考，都被时间温柔地记录。”*