# MY_LIFE_RPG (个人心智操作系统)

> *“不仅是管理时间，更是为了对抗熵增，守护心智的连续性。”*

![Platform](https://img.shields.io/badge/Platform-Android%20(8%22%20Tablet)-green) ![Stack](https://img.shields.io/badge/Tech-Flutter%20%7C%20GetX-blue) ![Arch](https://img.shields.io/badge/Architecture-Clean%20%7C%20Repo%20Pattern-orange) ![Style](https://img.shields.io/badge/Style-Cyberpunk%20%7C%20Console-purple)

## 📖 项目简介 (Introduction)

**My Life RPG** 是一个运行在 **8寸常亮 Android 平板** 上的个人管理终端。它专为 **INTP 人格** 及 **高认知负荷的脑力工作者** 设计。

本项目拒绝将用户视为只会执行指令的机器人。我们承认人性的弱点——启动困难、时间感知模糊、上下文丢失。因此，我们通过 **赛博朋克控制台 (Console)** 的隐喻和 **RPG 游戏化** 的反馈机制，将生活琐事转化为“系统守护进程”，将深度工作转化为“主线战役”。

目前版本专注于**运行时体验 (Runtime Experience)** 与 **逻辑自洽性 (Logical Consistency)**，采用全内存模式运行，追求极致的交互响应与代码纯洁性。

---

## 💡 核心特性 (Core Features)

### 1. 战术指挥中心 (Tactical Command / Mission Panel)
*   **智能过滤 (Smart Filters)**：基于 **Specification Pattern** 构建的过滤器，支持按 `[URGENT]`, `[DAEMON]`, `[PROJECT]` 维度瞬间聚焦。
*   **认知排序 (Cognitive Sorting)**：自动计算“焦虑值”，将逾期 Deadline 和紧急守护进程置顶，逼迫大脑直面红区。
*   **任务编年史 (Quest Chronicles)**：不仅能编辑任务属性，更能回溯该任务的历史投入记录，支持逐条审计与删除。

### 2. 沉浸式驾驶舱 (Immersion Cockpit / Session)
*   **心流保护**：全屏呼吸计时器，伴随动态脉冲动画，屏蔽外界干扰。
*   **战术结算 (Debriefing)**：任务结束时弹出全屏结算报告，根据时长评定等级 (S/A/B)，提供 **XP 结算**、**完成状态流转** 及 **容错丢弃 (Discard)** 选项。
*   **物理修正**：修正了 Timer 漂移问题，采用物理时间差计算，确保数据绝对精准。

### 3. 时空矩阵 (Temporal Matrix)
*   **视觉连贯性**：将离散的时间格渲染为连续的 **时间胶囊 (Time Capsules)**，直观展示时间流逝的长度。
*   **当下指针 (Now Cursor)**：红色的垂直光标实时指示当前时间在矩阵中的位置。
*   **交互式复盘**：支持点击已占用的时间块查看详情 (Inspector)，并允许**时间回溯**（删除错误记录，自动扣除 XP）。

### 4. 玩家身份系统 (Identity System / HUD)
*   **等级机制**：基于幂函数曲线的升级系统，从 *Novice* 到 *Cyber Deity*。
*   **仪表盘布局**：重构的 HUD 包含 身份卡片、时间光谱分析、以及今日产出/睡眠倒计时仪表盘。
*   **战略视图**：顶部的 **Campaign Bar** 以数据磁带的形式展示各项目进度，支持颜色编码与动态百分比。

---

## 🛠 硬核架构 (Hardcore Architecture)

为了避免“代码屎山”，本项目严格遵循 **Clean Architecture** 原则，实现了高内聚低耦合的工程结构。

### 1. 分层设计 (Layered Design)

*   **Presentation Layer (UI/Controller)**:
    *   只负责状态管理 (`GetX`) 和界面渲染。
    *   不包含任何业务逻辑，只通过 Service 调用能力。
*   **Domain Layer (Service/Logic)**:
    *   **Pure Logic**: 剥离了 `TimeDomain` (时间算法) 和 `XpStrategy` (数值策划) 到纯 Dart 类中，不依赖 Flutter。
    *   **QuestService**: 作为 Facade，协调 Repository 和纯逻辑类，处理业务规则（如 Daemon 冷却计算）。
*   **Data Layer (Repository)**:
    *   **Repository Pattern**: 实现了 `QuestRepository` 和 `ProjectRepository`。
    *   完全解耦了数据存储实现。目前为 `In-Memory`，未来可无缝切换至 `SQLite` 或 `Network` 而不影响上层业务。

### 2. 设计模式 (Design Patterns)

*   **Specification Pattern (规格模式)**:
    *   在 `lib/core/data/specifications.dart` 中定义业务规则（如 `ActiveMissionSpec`, `UrgentSpec`）。
    *   通过 `spec.and(otherSpec)` 组合复杂的查询逻辑，彻底消灭了 Controller 中的 `if-else` 嵌套。
*   **Strategy Pattern (策略模式)**:
    *   XP 计算逻辑被封装在 `XpStrategy` 中，支持未来扩展不同的奖励算法。

### 3. 目录结构 (Directory Structure)

```text
lib/
├── core/
│   ├── data/              # 规格定义 (Specifications)
│   ├── domain/            # 纯领域逻辑 (TimeDomain)
│   ├── logic/             # 业务算法 (LevelLogic, RankLogic)
│   ├── theme/             # 设计系统 (Cyberpunk Tokens)
│   └── widgets/           # 原子组件库
├── repositories/          # 仓储层 (QuestRepo, ProjectRepo)
├── models/                # 数据模型 (Quest, Session, Project)
├── services/              # 业务服务层 (QuestService, TimeService)
├── controllers/           # 状态控制层 (MissionController, MatrixController...)
└── views/                 # 视图层 (Home, Session, HUD...)