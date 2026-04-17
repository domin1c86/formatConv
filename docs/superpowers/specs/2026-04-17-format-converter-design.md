# 格式转换工具设计文档

**日期**: 2026-04-17  
**状态**: 已确认

---

## 1. 项目概述

一款轻量级的 Windows 桌面格式转换工具，支持视频、音频、图片文件转换为指定格式。基于 Python + PySide6 开发，未来可平滑迁移至 macOS。

核心依赖 `ffmpeg`（由用户自行安装），程序本体保持轻量（安装后约 70–140 MB）。

---

## 2. 用户交互形式

**桌面图形界面（GUI）**，采用卡片式任务列表管理器：
- 左侧：固定控制面板（文件添加、格式批量应用、全局操作）
- 右侧：任务列表 / 设置页面
- 任务分为"待转换"和"已完成"两个栏目
- 转换完成后弹出 Windows 系统通知

---

## 3. 技术栈

| 层级 | 选型 | 说明 |
|------|------|------|
| GUI 框架 | PySide6 | 现代 UI、QThread 并发成熟、原生跨平台、系统通知支持完善 |
| 转换引擎 | ffmpeg | 通过 `subprocess` 调用，用户需自行安装并配置 PATH |
| 系统通知 | `plyer` 或 `win10toast` | Windows 原生气泡通知 |
| 打包 | PyInstaller | 单文件夹模式，精简不用的 Qt 模块以控制体积 |

---

## 4. 界面布局

### 4.1 左侧控制面板（固定宽度 280px）
- **添加文件** 按钮
- **视频格式设置**：下拉框（默认"保持不变"）+ **应用** 按钮
- **音频格式设置**：下拉框（默认"保持不变"）+ **应用** 按钮
- **图片格式设置**：下拉框（默认"保持不变"）+ **应用** 按钮
- 底部分隔线
- **启动全部任务**（固定在底部）
- **设置**（固定在底部）

点击某个格式设置的"应用"按钮时，仅将对应类型的待转换任务更新为目标格式。

### 4.2 右侧区域

#### 任务列表视图（默认）
顶部 Tab 切换：
- **待转换**：垂直排列的任务卡片
- **已完成**：历史结果

**任务卡片内容**：
- 文件图标（显示源格式后缀）
- 文件名 + 源文件路径
- 状态标签（等待中 / 转换中 / 已完成 / 失败）
- 操作按钮：单个 **启动** / **取消** / **删除**
- 源格式 → 目标格式下拉框（可单独覆盖）
- 进度条 + 百分比 + 预估剩余时间（仅转换中显示）
- 可展开/折叠的实时 ffmpeg 日志区域（默认折叠，最多保留 200 行）

#### 设置页面
点击左侧"设置"后右侧切换为设置面板，包含：
- **常规**
  - 默认输出目录（空表示"同目录"）
  - GPU 加速开关（默认关闭）
- **默认目标格式**
  - 视频默认格式
  - 音频默认格式
  - 图片默认格式
- **自定义格式**
  - 视频 / 音频 / 图片的标签列表
  - 每个分类支持"+ 添加"自定义格式

---

## 5. 任务队列与数据模型

### 5.1 Task 对象
```python
class Task:
    id: str                    # UUID
    source_path: str           # 源文件绝对路径
    source_format: str         # 源格式（小写扩展名）
    file_type: str             # video | audio | image
    target_format: str         # 目标格式
    output_dir: str            # 输出目录（继承全局设置）
    status: str                # waiting | running | completed | failed | cancelled
    progress: int              # 0–100
    estimated_seconds: int     # 预估剩余时间
    log_lines: List[str]       # ffmpeg 实时日志（上限 200 行）
    error_message: str         # 失败摘要
    completed_at: Optional[datetime]
```

### 5.2 TaskManager
- 维护待转换和已完成两个列表
- 提供 `add_tasks()`, `remove_task()`, `start_task()`, `start_all()`, `cancel_task()` 接口
- 信号驱动 UI 更新

### 5.3 并发策略
- **默认串行**：同时只运行 **1** 个转换任务
- 每个转换任务在独立的 `QThread` 中执行，通过 `QObject` + `moveToThread` 实现
- UI 与转换逻辑解耦，界面不卡顿
- 预留并发数接口，后续可在设置中开放"最大并发数"

---

## 6. 转换流程

1. 用户添加文件
2. 根据扩展名推断文件类型和源格式
3. 为新任务分配默认目标格式（按类型读取设置）
4. 渲染到"待转换"列表
5. 用户点击"启动"或"启动全部"
6. `Converter` 串行取出 `waiting` 任务，启动 `ffmpeg` 子进程
7. 实时解析 `ffmpeg` stderr 输出，计算进度和剩余时间
8. 通过 Qt 信号推送进度到对应任务卡片
9. 任务完成：
   - 成功 → 移到"已完成"列表 + Windows 系统通知
   - 失败 → 状态改为 `failed`，显示错误摘要
10. 继续执行队列中的下一个 `waiting` 任务

---

## 7. 输出目录规则

- 全局设置一个"默认输出目录"
- 当设置为空字符串时，表示"与原文件同目录"
- **不支持**为单个任务单独指定输出目录
- 输出文件命名规则：`{原文件名}_converted.{目标格式}` 或 `{原文件名}.{目标格式}`
  - **待实现时确认**：本节具体命名规则在编码阶段确定

---

## 8. 错误处理

### 8.1 ffmpeg 环境检测
- 程序启动时检测 `ffmpeg` 是否在系统 PATH 中
- 未检测到则弹窗提示，并提供安装说明链接

### 8.2 转换过程异常
| 场景 | 处理策略 |
|------|----------|
| 源格式不支持 | 任务标记 `failed`，日志区显示错误摘要 |
| 输出文件已存在 | 弹窗询问"覆盖 / 跳过 / 自动重命名" |
| 磁盘空间不足 / 权限不足 | 任务标记 `failed`，显示对应错误信息 |
| GPU 加速失败 | 自动降级为 CPU 模式，记录警告日志 |
| 用户取消 | 发送终止信号给 ffmpeg，任务回到 `waiting` |

---

## 9. 格式推断与内置列表

### 9.1 内置格式
- **视频**：`mp4, mkv, avi, mov`
- **音频**：`mp3, wav, flac, aac`
- **图片**：`jpg, jpeg, png, gif, webp`

### 9.2 自定义格式
- 用户可在设置中添加自定义格式
- 自定义格式与内置格式合并后显示

### 9.3 类型推断
- 根据文件扩展名（不区分大小写）匹配内置或自定义格式
- 匹配成功则自动判定 `file_type`
- 匹配失败则弹窗让用户手动选择"视频 / 音频 / 图片"

---

## 10. 持久化配置

配置文件路径：`%APPDATA%/FormatConverter/config.json`

```json
{
  "default_output_dir": "",
  "default_video_format": "mkv",
  "default_audio_format": "mp3",
  "default_image_format": "png",
  "gpu_acceleration": false,
  "max_concurrent_jobs": 1,
  "custom_formats": {
    "video": [],
    "audio": [],
    "image": []
  },
  "window_size": [1000, 760]
}
```

- `default_output_dir` 为空表示"同目录"
- 程序启动时读取，设置变更时自动写入
- 队列状态 **不持久化**，关闭程序后未完成任务直接丢弃
- **预留状态持久化接口**，方便后续扩展

---

## 11. 项目结构

```
format-converter/
├── src/
│   ├── main.py
│   ├── app.py
│   ├── models/
│   │   ├── task.py
│   │   └── task_manager.py
│   ├── converter/
│   │   ├── ffmpeg_runner.py
│   │   └── format_registry.py
│   ├── ui/
│   │   ├── task_card.py
│   │   ├── task_list_view.py
│   │   ├── settings_panel.py
│   │   └── main_window.py
│   ├── config/
│   │   └── settings.py
│   └── utils/
│       └── notifications.py
├── docs/
│   └── superpowers/
│       └── specs/
│           └── 2026-04-17-format-converter-design.md
├── requirements.txt
└── .gitignore
```

---

## 12. 后续扩展预留

- macOS 平台打包适配
- 任务队列状态持久化与恢复
- 设置中开放"最大并发数"调节
- 输出文件命名规则自定义
- ffmpeg 预设参数（码率、分辨率等）高级设置
