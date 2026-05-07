# EaPlayground 架构设计整理

本文是对 `MQL5 Lab 架构指导文档.md` 的执行版整理。原文档保留为设计草稿和参考材料，本文用于指导当前 `Experts/EaPlayground` 项目的架构落地。

---

## 1. 项目定位

`EaPlayground` 是一个 MQL5 / MetaTrader 5 实验型 EA 项目，用于验证：

- EA 组装层与生命周期运行时的边界
- 启动参数承接和运行时配置传递
- 策略模块化
- 事件分发和责任链
- 日志、K 线、品种、交易、风控等基础模块
- 后续 SQLite 信号记录和实验数据持久化

当前定位不是开发完整实盘 EA，而是先建立一个可演进、可替换策略、可逐步拆分 Core 的工程骨架。

---

## 2. 核心原则

依赖方向保持单向：

```text
EaPlayground.mq5
  -> Framework / launcher
  -> Framework / strategy registry / strategy host
  -> Framework / lifecycle
  -> Framework / dispatcher
  -> Strategy
  -> Framework / event / log / time / trade / risk
  -> MQL5 Standard Library
```

禁止反向依赖：

```text
Framework / Core -> Strategy
Framework / Core -> EaPlayground.mq5
Strategy -> EaPlayground.mq5
```

核心约束：

- `.mq5` 主文件只作为 App Composition Root，不直接承载生命周期业务规则。
- `.mq5` 主文件可以声明 input，但不把 input 变量散发给三层业务模块。
- `Framework/launcher` 负责承接 input，并生成 `LauncherBundle`。
- `Framework/strategy registry` 负责注册策略描述和 factory。
- `Framework/strategy host` 负责选择、创建、自测、初始化和释放策略实例。
- `Framework/lifecycle` 负责生命周期事件转换，构造 `CEventContext`，不直接持有策略实例。
- `Framework/dispatcher` 只负责事件分发，不负责创建、选择或管理策略实例。
- `Strategy` 负责策略组合、信号逻辑、handler 编排。
- `Framework` 只放稳定、可复用、与具体策略无关的基础设施。
- 真实下单只允许集中在 `ExecutionHandler` 或后续交易执行模块中。

MQL5 语法上要求 `OnInit()`、`OnTick()`、`OnTimer()`、`OnDeinit()` 定义在 `.mq5` 主文件中，但这些函数应保持很薄。`OnInit()` 先让 launcher 承接 input，再初始化 lifecycle/container 和 strategy host；`OnDeinit()` 按事件源、strategy host、container 的顺序分阶段释放。

---

## 3. 模块职责

### EaPlayground.mq5

`EaPlayground.mq5` 是三层业务的组装层。

职责：

- 声明 EA input 参数，例如日志级别、timer 秒数、点差阈值、magic number。
- include 当前策略入口 `Strategy/strategy_entry.mqh`。
- 创建或配置 `Framework/launcher` 和 lifecycle runtime。
- 将 input 值写入 `LauncherBundle`。
- 调用策略入口注册函数，将策略描述和 factory 注册进 registry。
- `OnInit()` 先用 launcher 生成 bundle，再初始化 lifecycle/container 和 strategy host。
- `OnTick()` / `OnTimer()` 薄转发给 lifecycle。
- `OnDeinit()` 按“停事件源 -> strategy host teardown -> container shutdown”的顺序释放，确保 teardown 期间仍可解析容器服务。

不放入：

- 生命周期业务调度
- 事件构造和分发规则
- 具体买卖信号
- 风控判断
- 下单逻辑
- 指标计算细节
- 数据库 SQL

示例形态：

```mql5
int OnInit()
{
   g_launcher.ConfigureInputs(InpMinLogLevel, InpTimerSeconds, InpMaxSpreadPoints, InpMagicNumber);

   g_lifecycle.Init(g_launcher.Bundle());
   if(Container() == NULL)
      return INIT_FAILED;

   LogInfo("EaPlayground initializing");

   RegisterStrategies(GetPointer(g_registry));
   g_host.SetRegistry(GetPointer(g_registry));

   if(!g_host.Launch(g_launcher.Bundle()))
      return INIT_FAILED;

   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   g_lifecycle.OnDeinit(reason);

   CServiceContainer* container = Container();
   if(container != NULL)
   {
      CEventDispatcher* dispatcher = (CEventDispatcher*)container.Resolve(SVC_DISPATCHER);
      if(dispatcher != NULL)
         dispatcher.Unregister(GetPointer(g_host));
   }

   g_host.Deinit(reason);
   g_lifecycle.Shutdown();
}

void OnTick()
{
   g_lifecycle.OnTick();
}

void OnTimer()
{
   g_lifecycle.OnTimer();
}
```

### Framework / launcher

Launcher 是 input 到 `LauncherBundle` 的适配器。

职责：

- 承接 `.mq5` 中声明的 input 参数。
- 将输入参数归并到 `LauncherBundle`。
- 初始化 `LauncherBundle` 中的运行时上下文，例如 symbol、timeframe。
- 不持有 strategy registry / strategy host / dispatcher / lifecycle。
- 不负责启动或停止业务模块。

Launcher 不负责：

- 具体策略逻辑
- handler 编排
- 策略选择、创建、自测和释放
- 事件分发
- 生命周期入口转发
- 容器解析
- strategy host 注册或注销
- 真实下单
- 数据库写入
- 复杂生命周期规则

### Framework / lifecycle

Lifecycle 是生命周期运行时。

职责：

- 从 `LauncherBundle` 读取日志级别、timer 秒数、运行品种、周期等配置。
- 持有 `CRuntimeState` 公共状态数据。
- 初始化日志。
- 启动和关闭 timer。
- 将 MQL5 原生事件包装成 `CEventContext`。
- 在 `CEventContext` 中放入 `LauncherBundle` 和 `RuntimeState` 指针引用。
- 检测新 K 线并产生 `EVENT_NEW_BAR`。
- 将 `CEventContext` 交给 dispatcher 接口。

Lifecycle 不负责：

- 承接 `.mq5` input
- 创建具体策略类
- 持有策略实例
- 调用策略内部责任链
- 编排策略内部 handler
- 事件分发策略
- 执行真实交易

### Framework / dispatcher

Dispatcher 是事件分发器。

职责：

- 接收 lifecycle 产生的 `CEventContext`。
- 按确定顺序同步分发事件。
- 将事件分发给已注册的 event sink。
- 后续在内部切换为 bounded queue / priority queue。

Dispatcher 面向最小 event sink 接口：

```mql5
class IEventSink
{
public:
   virtual string Name() = 0;
   virtual void OnEvent(CEventContext& context) = 0;
};
```

Dispatcher 不负责：

- 承接 `.mq5` input
- 构造生命周期事件
- 读取 MQL5 原生事件
- 策略发现、选择、自测、初始化和释放
- 持有具体策略实例
- 具体策略逻辑
- 真实下单

依赖约束：

- launcher 不负责分发，只负责 input 到 bundle 的适配。
- launcher 和 lifecycle 不相互回调，不共享策略实例。
- lifecycle 不依赖 launcher，也不持有策略实例。
- lifecycle 只依赖 dispatcher 暴露的最小分发接口。
- dispatcher 不依赖 launcher 或 lifecycle 的具体实现。
- dispatcher 面向 event sink 分发，不直接理解具体策略类型。

### Framework / strategy registry

Strategy Registry 是策略注册表。

职责：

- 保存策略描述 `CStrategyDescriptor`。
- 保存策略 factory。
- 支持按 `StrategyId` 查询策略。
- 支持列出可用策略。
- 支持基础注册校验，例如 id 是否重复、factory 是否为空。

策略描述建议包含：

```mql5
class CStrategyDescriptor
{
public:
   string Id;
   string Name;
   string Version;
   string Description;
   bool EnabledByDefault;
};
```

策略 factory 建议使用抽象类，不依赖函数指针：

```mql5
class IStrategyFactory
{
public:
   virtual string Id() = 0;
   virtual bool SelfTest(CLauncherBundle* bundle, string& reason) = 0;
   virtual IStrategy* Create(CLauncherBundle* bundle) = 0;
};
```

策略入口不再直接暴露单个 `CreateStrategy()`，而是注册策略：

```mql5
void RegisterStrategies(CStrategyRegistry* registry);
```

### Framework / strategy host

Strategy Host 是策略运行宿主。

职责：

- 从 registry 中选择要运行的策略。
- 调用 factory 的 `SelfTest()`。
- 创建策略实例。
- 调用策略 `Init()` 和 `Deinit()`。
- 持有和释放策略实例。
- 自测和初始化通过后，作为 event sink 接入 dispatcher。
- 将 dispatcher 分发来的 `CEventContext` 转给策略 `OnEvent()`。

Strategy Host 不负责：

- 构造生命周期事件
- 事件排序和队列策略
- 具体 handler 逻辑
- 真实下单

### Strategy

Strategy 是可替换策略模块。

职责：

- 提供策略描述和 factory。
- 通过 `RegisterStrategies(CStrategyRegistry* registry)` 注册。
- 实现 `IStrategy`。
- 组合策略需要的 handler chain。
- 处理 `OnEvent(CEventContext& context)`。
- 从 `CEventContext` 读取事件类型、行情上下文和 `LauncherBundle`。
- 生成信号、调用风控和执行 handler。

Strategy 不依赖 `.mq5`，也不直接读取 `.mq5` input。

### Framework / Core

Framework 是项目内 Core 雏形，后续可迁移到 `MQL5/Include/Cheng/Core`。

适合放入：

- launcher
- lifecycle
- dispatcher
- strategy registry
- strategy host
- logger
- event model
- event chain
- new bar 检测
- symbol 工具
- trade 工具
- risk 工具
- SQLite wrapper 和 repository

不适合放入：

- 某个具体策略
- 某个品种专属逻辑
- 某个经纪商专属交易规则
- 具体买卖信号判断

---

## 4. Launcher Bundle 设计

`LauncherBundle` 是启动期配置和运行时共享上下文的载体。它的作用是避免三层模块直接读取 `.mq5` 中的 input 全局变量。

建议第一版保持为简单数据对象：

```mql5
class CLauncherBundle
{
public:
   LOG_LEVEL MinLogLevel;
   int TimerSeconds;
   int MaxSpreadPoints;
   long MagicNumber;

   string Symbol;
   ENUM_TIMEFRAMES Timeframe;

   CLauncherBundle()
   {
      MinLogLevel = LOG_INFO;
      TimerSeconds = 5;
      MaxSpreadPoints = 300;
      MagicNumber = 0;
      Symbol = _Symbol;
      Timeframe = _Period;
   }
};
```

使用约束：

- `.mq5` 只负责把 input 值写入 bundle。
- `CLauncher::ConfigureInputs()` 将 `.mq5` input 写入 launcher-owned bundle。
- `CLauncher::Bundle()` 返回 launcher-owned bundle 的非 owning 指针。
- 调用方不得在 launcher 生命周期之外保存 `Bundle()` 返回的引用。
- launcher 负责创建和补齐 bundle，不负责启动 strategy host。
- lifecycle 从 bundle 读取运行配置，并把 bundle 指针引用放入事件上下文。
- strategy 和 handler 通过 `CEventContext.Bundle` 读取需要的 bundle 字段。
- 不要让 strategy 或 handler 直接引用 `.mq5` input 变量。
- bundle 第一版只放稳定、跨层共享的配置，不放临时交易状态。
- bundle 是独立对象，不合并进 `CEventContext`，也不把字段摊平到事件上下文中。

后续可以拆分：

```text
LauncherBundle
  -> RuntimeConfig
  -> StrategyConfig
  -> RiskConfig
  -> TradeConfig
```

初期不要过早拆分。

---

## 5. 策略接口设计

策略接口直接采用统一事件入口：

```mql5
class IStrategy
{
public:
   virtual string Name() = 0;
   virtual bool Init() = 0;
   virtual void Deinit(const int reason) = 0;
   virtual void OnEvent(CEventContext& context) = 0;
};
```

每个策略模块必须提供固定注册函数：

```mql5
void RegisterStrategies(CStrategyRegistry* registry);
```

主 EA 只 include：

```mql5
#include "Strategy/strategy_entry.mqh"
```

这样后续切换策略时，主 EA 不需要改代码。

---

## 6. 事件模型设计

MQL5 原生是事件驱动模型。项目在原生事件之上封装轻量 Event Bus。

```text
MQL5 Runtime
  -> EaPlayground.mq5
  -> Framework/launcher
  -> Framework/lifecycle
  -> BuildEventContext(...)
  -> Framework/dispatcher
  -> Dispatch(CEventContext)
  -> EventSink.OnEvent(CEventContext)
  -> StrategyHost.OnEvent(CEventContext)
  -> Strategy.OnEvent(CEventContext)
  -> CEventChain.Dispatch(CEventContext)
  -> Handlers
```

基础事件类型：

```mql5
enum EVENT_TYPE
{
   EVENT_TICK = 0,
   EVENT_NEW_BAR = 1,
   EVENT_TIMER = 2
};
```

后续扩展事件类型：

```mql5
EVENT_TRADE_TRANSACTION
EVENT_NEWS
EVENT_RISK_ALERT
```

责任链结果：

```mql5
enum EVENT_RESULT
{
   EVENT_CONTINUE = 0,
   EVENT_STOP     = 1,
   EVENT_ERROR    = 2
};
```

事件上下文保持轻量。它持有 `LauncherBundle` 和 `CRuntimeState` 的非 owning 指针引用，不拥有这两个对象，也不复制其字段。`State` 在 Phase 1A 中始终为 NULL，Phase 1B 引入 `runtime_state.mqh` 后由 lifecycle 填充：

```mql5
class CEventContext
{
public:
   CLauncherBundle* Bundle;
   CRuntimeState* State;

   EVENT_TYPE Type;
   datetime Time;
   string Symbol;
   ENUM_TIMEFRAMES Timeframe;

   int Signal;
   double Price;
   string Message;

   CEventContext()
   {
      Bundle = NULL;
      State = NULL;
      Type = EVENT_TICK;
      Time = TimeCurrent();
      Symbol = _Symbol;
      Timeframe = _Period;
      Signal = 0;
      Price = 0.0;
      Message = "";
   }
};
```

`LauncherBundle` 不作为参数散落到 strategy / handler 的构造函数里。常规事件流中，strategy 和 handler 通过 `CEventContext.Bundle` 读取共享配置。

禁止把 bundle 字段摊平进事件上下文：

```mql5
// 不推荐
class CEventContext
{
public:
   LOG_LEVEL MinLogLevel;
   int TimerSeconds;
   int MaxSpreadPoints;
   long MagicNumber;
};
```

`LauncherBundle` 和 `CEventContext` 应保持独立文件和独立语义：

```text
Framework/launcher/launcher_bundle.mqh
Framework/event/event_context.mqh
```

后续再按需要增加：

- Ticket
- Retcode
- Volume
- StopLoss
- TakeProfit
- RiskAmount

约束：

- 不设计复杂事件继承树。
- lifecycle 只构造 `CEventContext`，不直接持有策略实例。
- dispatcher 负责把 `CEventContext` 分发到 event sink。
- strategy host 作为 event sink，把事件转给具体策略实例。
- 策略实例通过 `OnEvent(CEventContext& context)` 和内部责任链消费 context。
- `EVENT_TICK` 只做轻量状态更新。
- 主要交易判断优先放在 `EVENT_NEW_BAR`。
- 后续新增原生事件时，优先扩展 `EVENT_TYPE`，避免反复修改策略接口。

---

## 7. 事件信号与分发队列设计

事件的本质是接收到一个 signal。这个 signal 可能来自 MQL5 生命周期，也可能来自新闻、交易事务、策略内部状态或后续外部数据源。

常见 signal 来源：

```text
生命周期 signal：INIT / TICK / TIMER / DEINIT
行情衍生 signal：NEW_BAR
新闻 signal：NEWS
交易 signal：TRADE_TRANSACTION
策略 signal：SIGNAL_BUY / SIGNAL_SELL / SIGNAL_NONE
系统 signal：RISK_ALERT / RECORDER_FLUSH
```

统一处理模型：

```text
Signal source
  -> CEventSignal
  -> CEventContext
  -> Dispatcher / queue
  -> Strategy.OnEvent(context)
  -> CEventChain.Dispatch(context)
```

初期可以同步分发：

```text
OnTick
  -> Build CEventContext
  -> Dispatch immediately
  -> Strategy.OnEvent
  -> Handler chain
```

当信号来源变多时，引入受控队列，而不是直接让多个来源同时调用策略：

```text
Signal source A
Signal source B
  -> CEventQueue
  -> Drain by deterministic order
  -> Dispatcher
  -> Strategy.OnEvent(context)
```

如果同时产生一个新报价和一则新闻，应生成两个独立事件上下文：

```text
CEventContext(Type=EVENT_TICK)
CEventContext(Type=EVENT_NEWS)
```

它们不合并成一个事件，进入同一个 dispatcher / queue 后按确定规则分发。

建议事件调度字段：

```mql5
long Sequence;
int Priority;
datetime EventTime;
datetime ReceivedTime;
```

排序规则：

```text
1. Priority 高的先处理
2. Priority 相同按 ReceivedTime
3. ReceivedTime 相同按 Sequence
```

推荐优先级：

```text
NEWS / RISK_ALERT > TRADE_TRANSACTION > NEW_BAR > TIMER > TICK
```

Tick 事件可以合并或丢弃低价值重复事件，避免队列堆积。新闻、交易事务、风控告警不应随意丢弃。

### 自定义数据结构

为了后续扩展，应预留事件队列和轻量容器模块。

建议文件：

```text
Framework/event/event_signal.mqh
Framework/event/event_queue.mqh
Framework/collections/ring_buffer.mqh
```

`CEventSignal` 表示轻量 signal 描述：

```mql5
class CEventSignal
{
public:
   EVENT_TYPE Type;
   int Priority;
   datetime EventTime;
   datetime ReceivedTime;
   long Sequence;
   string Message;
};
```

`CEventQueue` 后续建议做成 bounded stable priority queue，不追求线程安全：

```text
固定容量
按 Priority / ReceivedTime / Sequence 排序
同 Priority 内保持 FIFO
支持 tick coalescing
溢出时拒绝低优先级事件或记录错误
```

第一版使用 dispatcher 同步分发，不强制启用 queue。`event_queue.mqh` 和 `ring_buffer.mqh` 作为后续扩展，不进入第一阶段实现清单。

加锁原则：

- 单个 EA 的事件处理通常串行，不在事件主路径中引入锁。
- queue 先做确定性顺序和容量控制，不做线程安全容器。
- 跨 EA / 跨进程共享资源，例如同一个 SQLite 文件或公共文件日志，再单独封装资源锁。

---

## 8. 运行状态与状态投影设计

信号到来后通常会改变监控数据，因此系统需要一个可查询的当前聚合状态。可以把它理解成由所有已处理 signal 叠加出来的 runtime state。

推荐模型：

```text
Signal
  -> CEventContext
  -> Projection pipeline
  -> RuntimeState
  -> Strategy / Handler read current snapshot
```

`CEventContext` 表示单次事件，`RuntimeState` 表示截至当前已处理事件后的系统状态。二者不要混在一起。

推荐采用注册式 projection pipeline，而不是把所有状态更新混在普通 handler chain 中。

处理顺序：

```text
CEventContext
  -> Runtime projectors
  -> Strategy projectors
  -> Strategy process / handler chain
```

含义：

- Runtime projectors：由 Framework 注册，先消费 signal，更新公共 `CRuntimeState`。
- Strategy projectors：由策略注册，消费同一个 context，更新策略私有状态。
- Strategy process / handler chain：读取公共状态和策略私有状态，做信号分析、风控和执行决策。

这样所有策略决策都基于“当前 signal 已完成投影之后”的状态快照。

状态示例：

```text
MarketState：最新 bid / ask / spread / last tick time
BarState：当前 bar time / 是否新 K 线 / 最近 N 根 K 线摘要
NewsState：当前是否新闻窗口 / 新闻等级 / 最近新闻时间
TradeState：持仓、订单、最近成交、交易事务状态
RiskState：当前风险开关、当日亏损、冷却期、禁交易原因
SignalState：最近一次策略信号、信号时间、信号来源
```

建议文件：

```text
Framework/state/runtime_state.mqh
Framework/state/market_state.mqh
Framework/state/news_state.mqh
Framework/state/trade_state.mqh
Framework/state/risk_state.mqh
Framework/state/state_projector.mqh
Framework/state/projection_pipeline.mqh
```

第一版可以先收敛成一个轻量 `CRuntimeState`：

```mql5
class CRuntimeState
{
public:
   datetime LastTickTime;
   double LastBid;
   double LastAsk;
   int LastSpreadPoints;

   datetime LastBarTime;
   bool IsNewsActive;
   string LastRiskReason;

   CRuntimeState()
   {
      LastTickTime = 0;
      LastBid = 0.0;
      LastAsk = 0.0;
      LastSpreadPoints = 0;
      LastBarTime = 0;
      IsNewsActive = false;
      LastRiskReason = "";
   }
};
```

lifecycle 持有 `CRuntimeState`，并在构造 `CEventContext` 时放入 state 指针。`CEventContext` 的主定义见“事件模型设计”，不要在其他章节重新定义。

约束：

- `RuntimeState` 是独立状态对象，不合并进 `CEventContext`。
- `CEventContext` 只携带 state 指针，不复制完整状态。
- signal 处理顺序决定 state 的最终结果，因此 dispatcher / queue 必须有确定顺序。
- 状态更新应集中在注册过的 projector 中，不要让任意 handler 随意改共享状态。
- 策略读取的是“当前已处理事件之后”的状态快照，不代表未来事件已经进入状态。
- 单 EA 初期按串行事件流处理，不需要锁；跨 EA 共享状态再单独设计资源锁或持久化同步。

推荐策略消费顺序：

```text
RuntimeProjectionPipeline
  -> StrategyProjectionPipeline
  -> EventLogHandler
  -> MarketFilterHandler
  -> SignalHandler
  -> RiskHandler
  -> TradeGuardHandler
  -> ExecutionHandler
  -> RecorderHandler
```

这样新闻、报价、交易事务等外部 signal 到来后，先完成统一投影，后续策略和 handler 再读取一致的当前状态。

通用状态投影属于 Framework，不属于具体策略。策略专属投影通过 strategy factory / strategy host 注册到 strategy projection pipeline。

---

## 9. 责任链设计

handler 接口：

```mql5
class IEventHandler
{
public:
   virtual string Name() = 0;
   virtual EVENT_RESULT Handle(CEventContext& context) = 0;
};
```

推荐处理顺序：

```text
EventLogHandler
  -> MarketFilterHandler
  -> SignalHandler
  -> RiskHandler
  -> TradeGuardHandler
  -> ExecutionHandler
  -> RecorderHandler
```

第一版 handler：

```text
EventLogHandler
SpreadFilterHandler
DummySignalHandler
DummyExecutionHandler
```

约束：

- handler 职责单一。
- handler 顺序稳定。
- handler 默认读取已完成 projection 的状态，不负责公共状态投影。
- 下单只能集中到 `ExecutionHandler`。
- `DummyExecutionHandler` 只打印，不调用真实交易 API。
- handler 使用 `new` 时必须有清晰释放路径。
- 不让多个 handler 同时具备下单能力。

---

## 10. Logger 设计

MQL5 自定义函数不适合模拟 `Print()` 的可变参数接口。

Logger 使用单字符串接口：

```mql5
LogDebug("message");
LogInfo("message");
LogWarning("message");
LogError("message");
```

需要格式化时在调用侧处理：

```mql5
LogInfo(StringFormat("Spread: %d points", spread));
```

约束：

- 不做自定义 variadic function。
- 日志级别来自 `LauncherBundle.MinLogLevel`。
- Logger 不依赖 Strategy 或 `.mq5`。

---

## 11. Signal 设计

Signal 是系统接收到的原始或派生触发。它比 event context 更轻，表示“某件事发生了”。Event context 是 signal 被标准化后的分发载体，供 dispatcher、strategy host、strategy 和 handler 消费。

推荐抽象：

```text
SignalSource
  -> CEventSignal
  -> CEventContext
  -> Dispatcher
  -> EventSink
```

常见 signal source：

```text
LifecycleSignalSource：OnInit / OnTick / OnTimer / OnDeinit
MarketSignalSource：tick / spread / symbol state
BarSignalSource：new bar
NewsSignalSource：news / calendar
TradeSignalSource：trade transaction
SystemSignalSource：risk alert / recorder flush
```

约束：

- Signal source 只负责检测或接收变化，不负责策略判断。
- 同一个 signal source 可以产生零个、一个或多个 `CEventSignal`。
- `CEventSignal` 必须转换成 `CEventContext` 后再进入 dispatcher。
- Strategy 不直接依赖具体 signal source。
- 所有 signal 转换后的事件都走同一条 dispatcher 路径。

### NewBar 示例

新 K 线检测是一个典型的行情衍生 signal。它不是策略逻辑，应包装成 `EVENT_NEW_BAR` 的 `CEventContext` 供策略消费。

推荐模型：

```text
OnTick
  -> Tick signal
  -> Bar detector
  -> NewBar signal
  -> CEventContext(Type=EVENT_NEW_BAR)
  -> Dispatcher
  -> StrategyHost
  -> Strategy.OnEvent(context)
```

`Framework/time/bar.mqh` 只负责检测和维护 K 线状态，不直接调用策略。

第一版可以支持当前图表品种和周期：

```mql5
bool BarIsNew();
```

`.mq5` 的 tick 入口只薄转发给 lifecycle：

```mql5
void OnTick()
{
   g_lifecycle.OnTick();
}
```

lifecycle runtime 内部负责把检测结果转换成 signal / context：

```mql5
DispatchEventContext(EVENT_TICK, "tick");

if(BarIsNew())
   DispatchEventContext(EVENT_NEW_BAR, "new bar");
```

`EVENT_NEW_BAR` 必须进入与其他 signal 相同的 dispatcher 路径，不允许策略绕过事件系统直接查询 `BarIsNew()` 作为主交易入口。

Runtime projector 先更新 `RuntimeState.BarState`，策略 projector 可更新策略私有 K 线状态，然后策略和后续 handler 再读取当前 K 线状态。

后续多品种、多周期时，再演进为带 `symbol` 和 `timeframe` 的 bar detector / bar state 对象。

---

## 12. 数据库设计约束

MQL5 原生支持 SQLite 和 transaction。数据库模块不进入初期主路径。

后续目录：

```text
Framework/db
├─ sqlite_db.mqh
└─ signal_repository.mqh
```

适合保存：

- 策略信号
- 决策原因
- 回测实验结果
- 参数组合表现
- 非关键审计日志

不建议：

- 每个 tick 全量落库
- 下单前必须查数据库
- 多 EA 高频写同一个 SQLite 文件
- 把 SQLite 当消息队列

数据库第一版只做：

```text
创建 signal_logs 表
保存每次策略信号
```

策略不要直接写 SQL，应调用 repository：

```mql5
SignalRepositorySave(signal);
```

---

## 13. 容器选择约束

优先级：

1. 原生数组 `T[]`
2. `struct[]`
3. `CArrayObj`
4. 泛型集合，例如 `CArrayList<T>`

建议：

- K 线、tick、指标 buffer 使用原生数组。
- 信号记录、实验结果优先使用 `struct[]`。
- 多对象指针集合再使用 `CArrayObj`。
- 事件队列、滑动窗口、去重缓存可以封装自定义轻量结构，例如 bounded queue 或 ring buffer。
- 使用 `CArrayObj` 时明确对象所有权，避免重复 delete 或泄漏。
- 不按 C++ STL 心智模型强行模拟 `vector / map / set`。

---

## 14. 推荐目录结构

当前阶段推荐使用项目内 `Framework`，暂时不强制迁移到 `MQL5/Include`。

```text
Experts/EaPlayground
├─ EaPlayground.mq5
├─ EaPlayground.mqproj
├─ Framework
│  ├─ log
│  │  └─ logger.mqh
│  ├─ event
│  │  ├─ event_context.mqh
│  │  ├─ event_signal.mqh
│  │  ├─ event_handler.mqh
│  │  └─ event_chain.mqh
│  ├─ dispatcher
│  │  ├─ event_sink.mqh
│  │  └─ event_dispatcher.mqh
│  ├─ state
│  │  ├─ runtime_state.mqh
│  │  ├─ market_state.mqh
│  │  ├─ news_state.mqh
│  │  ├─ trade_state.mqh
│  │  ├─ risk_state.mqh
│  │  ├─ state_projector.mqh
│  │  └─ projection_pipeline.mqh
│  ├─ launcher
│  │  ├─ launcher.mqh
│  │  └─ launcher_bundle.mqh
│  ├─ lifecycle
│  │  └─ ea_lifecycle.mqh
│  ├─ strategy
│  │  ├─ strategy_interface.mqh
│  │  ├─ strategy_descriptor.mqh
│  │  ├─ strategy_factory.mqh
│  │  ├─ strategy_registry.mqh
│  │  └─ strategy_host.mqh
│  └─ time
│     └─ bar.mqh
├─ Strategy
│  ├─ strategy_entry.mqh
│  └─ handlers
│     ├─ event_log_handler.mqh
│     ├─ spread_filter_handler.mqh
│     ├─ dummy_signal_handler.mqh
│     └─ dummy_execution_handler.mqh
└─ doc
   ├─ MQL5 Lab 架构指导文档.md
   └─ EaPlayground 架构设计整理.md
```

说明：

- `Strategy/handlers` 里的 handler 第一版只打印和模拟，不执行真实下单。
- `event_queue.mqh`、`ring_buffer.mqh` 等自定义结构作为后续扩展加入，不进入第一阶段最小目录。
- 后续稳定后，再考虑把 `Framework` 移到 `MQL5/Include/Cheng/Core`。

---

## 15. Include 依赖方向

MQL5 对 include cycle 比较敏感，第一阶段按下面的依赖方向生成文件。

推荐顺序：

```text
logger
launcher_bundle
event_context
event_handler
event_chain
event_sink
event_dispatcher
strategy_interface
strategy_factory
strategy_registry
strategy_host
launcher
lifecycle
strategy_entry
EaPlayground.mq5
```

依赖约束：

- `event_context` 可以依赖 `launcher_bundle`。Phase 1B 后也可以依赖 `runtime_state`。
- `strategy_interface` 可以依赖 `event_context`。
- `strategy_factory` 可以依赖 `strategy_interface` 和 `launcher_bundle`。
- `strategy_registry` 可以依赖 `strategy_factory`。
- `strategy_host` 可以依赖 `strategy_interface`、`strategy_factory`、`strategy_registry`、`event_sink`。
- `dispatcher` 只依赖 `event_sink` 和 `event_context`。
- `lifecycle` 依赖 dispatcher 的最小接口、`event_context`、`launcher_bundle`；Phase 1B 后依赖 `runtime_state`。
- `strategy_entry` 依赖 registry / factory / interface 和策略 handlers。
- `EaPlayground.mq5` 只 include launcher、lifecycle、logger 和 `Strategy/strategy_entry.mqh` 等入口文件。

---

## 16. 第一阶段目标

第一阶段拆成 Phase 1A 和 Phase 1B。Phase 1A 先跑通最小闭环，Phase 1B 再加入状态投影。

### Phase 1A：最小闭环

- 编译 0 errors
- EA 能加载到图表
- `.mq5` 输入参数能被 Launcher 接收并封装到 `LauncherBundle`
- `.mq5` 的 `OnInit()` 能正确使用 launcher 生成 bundle，并初始化 lifecycle/container 与 strategy host；`OnTick()` / `OnTimer()` 能正确委托到 lifecycle，`OnDeinit()` 能按顺序完成 timer 停止、strategy host teardown 和 container shutdown
- 策略通过 `RegisterStrategies()` 注册 descriptor 和 factory
- strategy registry 能完成策略注册和查询
- strategy host 能选择策略、执行 `SelfTest()`、创建、初始化和释放策略实例
- strategy host 只在自测和初始化通过后接入 dispatcher
- dispatcher 能同步分发事件到 strategy host 这个 event sink
- lifecycle runtime 能将 `Tick / Timer / Deinit` 等生命周期入口转换为 `CEventContext`
- 事件分发由 dispatcher 负责，第一阶段使用同步 dispatch
- `Init` 阶段打印启动日志
- `Timer` 阶段能定时产生事件
- `Tick` 阶段能产生 tick 事件
- 策略通过 `OnEvent(CEventContext& context)` 接收统一事件上下文
- 责任链能按顺序处理事件
- ownership 规则明确并按 Phase 1A 释放顺序实现
- 能输出 Phase 1A 编译验收日志样例中的关键日志
- 不加入真实交易逻辑

### Phase 1B：状态投影

- lifecycle 持有 `CRuntimeState` 公共状态数据
- `CEventContext` 携带非 owning `RuntimeState` 指针
- `runtime_state.mqh` 提供最小公共状态对象
- `state_projector.mqh` 定义投影接口
- `projection_pipeline.mqh` 支持注册和顺序执行 projector
- `market_state.mqh` 承载报价 / 点差 / tick 时间等市场状态
- `risk_state.mqh` 承载风险开关 / 禁交易原因等最小风险状态
- 外部 signal 能先更新 `RuntimeState`，策略和 handler 能读取当前状态快照

第一阶段不做：

- 真实下单
- SQLite
- 多品种
- 多周期上下文
- 复杂风控
- bounded queue / ring buffer
- 策略软链接切换
- Core 迁移到 `MQL5/Include`

---

## 17. 第一阶段实施清单

### Phase 1A：最小闭环

1. `Framework/log/logger.mqh`
2. `Framework/launcher/launcher_bundle.mqh`
3. `Framework/event/event_context.mqh`
4. `Framework/event/event_handler.mqh`
5. `Framework/event/event_chain.mqh`
6. `Framework/dispatcher/event_sink.mqh`
7. `Framework/dispatcher/event_dispatcher.mqh`
8. `Framework/strategy/strategy_interface.mqh`
9. `Framework/strategy/strategy_factory.mqh`
10. `Framework/strategy/strategy_registry.mqh`
11. `Framework/strategy/strategy_host.mqh`
12. `Framework/launcher/launcher.mqh`
13. `Framework/lifecycle/ea_lifecycle.mqh`
14. `Strategy/strategy_entry.mqh`
15. `Strategy/handlers/event_log_handler.mqh`
16. `Strategy/handlers/spread_filter_handler.mqh`
17. `Strategy/handlers/dummy_signal_handler.mqh`
18. `Strategy/handlers/dummy_execution_handler.mqh`
19. `EaPlayground.mq5`

### Phase 1B：状态投影

1. `Framework/state/runtime_state.mqh`
2. `Framework/state/state_projector.mqh`
3. `Framework/state/projection_pipeline.mqh`
4. `Framework/state/market_state.mqh`
5. `Framework/state/risk_state.mqh`

---

## 18. 质量监控与验收

### Ownership 规则

Phase 1A 必须明确对象所有权，避免 MQL5 中 `new / delete` 使用混乱。

```text
Launcher
  owns Bundle
  does not own Registry / Dispatcher / Lifecycle / StrategyHost

StrategyHost
  owns current IStrategy instance

Strategy
  owns its CEventChain

CEventChain
  owns handler instances

Dispatcher
  does not own Strategy
  does not own sinks
  holds non-owning IEventSink references
  Dispatcher holds a non-owning pointer/reference to StrategyHost

CEventContext
  does not own Bundle
  does not own RuntimeState
  only holds non-owning pointers
```

释放顺序建议：

```text
Lifecycle stops timer
Dispatcher unregisters sinks
StrategyHost deinitializes and deletes Strategy
Strategy deletes CEventChain
CEventChain deletes handlers
Container releases RuntimeState / Dispatcher / signal services
```

约束：

- 非 owning pointer 不允许 `delete`。
- dispatcher 注册 sink 前，sink 必须已完成自测和初始化。
- dispatcher 释放或清空前，应先 unregister sinks。
- `CEventContext` 只在同步 dispatch 期间有效，不跨事件长期保存。
- handler 不保存 `CEventContext*`；需要持久化的数据必须写入 state 或策略私有状态。

### 编译验收日志样例

Phase 1A 编译目标：

```text
0 errors
```

Phase 1A 中，EA 加载后应能看到类似日志：

```text
[INFO] EaPlayground initializing
[INFO] Strategy registered: dummy
[INFO] Strategy self-test passed
[INFO] Strategy initialized: DummyStrategy
[INFO] Dispatcher sink registered: StrategyHost
[INFO] EVENT_TIMER dispatched
[INFO] DummyExecutionHandler skipped real execution
```

日志验收含义：

- `EaPlayground initializing`：`.mq5` 的启动链路已触发，bundle 和 runtime 初始化完成。
- `Strategy registered: dummy`：registry 收到策略 descriptor 和 factory。
- `Strategy self-test passed`：strategy host 完成 factory 自测。
- `Strategy initialized: DummyStrategy`：strategy host 创建并初始化策略实例。
- `Dispatcher sink registered: StrategyHost`：strategy host 作为 event sink 接入 dispatcher。
- `EVENT_TIMER dispatched`：lifecycle 生成 context，dispatcher 完成同步分发。
- `DummyExecutionHandler skipped real execution`：执行 handler 被调用，但没有真实下单。

---

## 19. 后续演进路线

```text
阶段 1A：最小闭环
阶段 1B：RuntimeState + ProjectionPipeline
阶段 2：EventQueue / RingBuffer / deterministic dispatch
阶段 3：NewBar 检测 + Dummy signal
阶段 4：真实指标信号，例如 MA cross
阶段 5：Spread / Risk / TradeGuard 完善
阶段 6：ExecutionHandler 接入 CTrade
阶段 7：RecorderHandler + SQLite signal_logs
阶段 8：Strategy 目录可替换
阶段 9：Framework 迁移到 Include/Cheng/Core
阶段 10：Core 独立 repo
阶段 11：Strategy 独立 repo
```

---

## 20. 当前决策结论

- 项目名保留 `EaPlayground`，不改成 `Mql5Lab`。
- 当前使用项目内 `Framework`，后续再迁移到 `Include/Cheng/Core`。
- `EaPlayground.mq5` 是三层业务的组装层，不直接承担生命周期业务分发。
- `Framework/launcher` 承接 input 参数，并生成 `LauncherBundle`。
- launcher 不负责事件分发，也不创建策略实例，只负责承接 input 并生成 `LauncherBundle`。
- 策略必须通过 registry 注册 descriptor 和 factory。
- strategy host 负责策略选择、自测、创建、初始化、释放，并作为 event sink 接入 dispatcher。
- `LauncherBundle` 保持独立对象；`CEventContext` 只携带 bundle 指针，不合并或摊平 bundle 字段。
- `Framework/lifecycle` 负责生命周期事件转换，不持有策略实例。
- `Framework/dispatcher` 只负责事件分发，不管理策略实例生命周期。
- ownership 明确：launcher 拥有 bundle，container 拥有运行时服务，strategy host 拥有策略实例，strategy 拥有 chain，chain 拥有 handlers，context 只持有 non-owning pointer。
- 事件是 signal 的统一载体；多个来源产生多个独立 `CEventContext`，由 dispatcher 分发给 event sink，后续可切换到 queue。
- signal 会叠加更新 `RuntimeState`；策略和 handler 读取当前已处理事件后的状态快照。
- 状态更新集中在注册式 projection pipeline 中，不让状态修改散落到任意 handler。
- 引入自定义轻量数据结构方向：bounded queue、ring buffer、priority + sequence 排序。
- 单 EA 主事件流初期不加锁，跨 EA / 跨进程共享资源再单独封装资源锁。
- 策略接口直接使用 `OnEvent(CEventContext& context)`。
- 第一阶段拆成 Phase 1A 最小闭环和 Phase 1B 状态投影。
- 第一阶段只模拟信号和执行，不真实下单。
- SQLite 是后续 observability / persistence 模块，不进入关键交易路径。
- 容器优先使用原生数组和简单结构，不提前模拟 STL。
