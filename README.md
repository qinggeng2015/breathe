# Breathe - macOS Status Bar App

一个简洁的macOS状态栏呼吸练习应用，帮助你放松身心。

由于在macOS平台没有找到合适且免费的应用，因此通过ai生成了这个项目，项目中几乎全部代码都是ai生成。本应用采用**深度放松训练**的呼吸频率设定（4秒吸气→2秒屏息→4秒呼气），基于科学的呼吸训练理论，旨在帮助用户在工作间隙快速放松，缓解压力，提升专注力。

## 功能特性

- 🫁 **呼吸引导**: 4秒吸气 → 2秒屏息 → 4秒呼气的节奏
- 🎯 **状态栏集成**: 直接在macOS状态栏中显示动画
- 🎨 **视觉反馈**: 动态圆圈和文字提示
- 🖱️ **右键菜单**: 开始、停止、退出功能
- 🔕 **后台运行**: 不显示在Dock中，不干扰工作

## 呼吸功能科学依据

在手环应用中，**呼吸功能**（Breathing Exercise 或 Respiration Training）通常是指一种帮助用户进行深呼吸训练、减压放松或提升专注力的功能。这个功能的核心是引导用户进行有节奏的呼吸练习，常见的模式包括吸气、屏息、呼气等阶段。

### 一、呼吸功能的常见频率设置

虽然不同品牌和型号的手环可能略有差异，但大多数手环中的呼吸训练遵循**低频深呼吸原则**，以达到放松神经、降低心率的效果。以下是一些常见的呼吸频率设定：

| 类型             | 呼吸周期（完整一次吸气+呼气） | 呼吸频率（次/分钟） | 典型模式示例               |
|------------------|-------------------------------|----------------------|----------------------------|
| 深度放松训练     | 10 秒                         | 6 次/分钟            | 吸气4秒 → 屏息2秒 → 呼气4秒 |
| 轻松冥想         | 8-10 秒                       | 6-7.5 次/分钟        | 吸气3秒 → 呼气5秒           |
| 快速调节情绪     | 6-8 秒                        | 7.5-10 次/分钟       | 吸气2秒 → 呼气4秒           |

> 这些参数大多参考了**正念冥想**（Mindfulness）、**自律神经调节**（Autonomic Regulation）以及**呼吸疗法**（Respiratory Therapy）的研究成果。

### 二、支撑这些频率的科学依据

#### 1. **自主神经系统（ANS）调节**
- 缓慢深呼吸可以激活**副交感神经系统**（Parasympathetic Nervous System），有助于降低心率、血压和压力水平。
- 研究表明，**每分钟6次左右的呼吸频率**（即每10秒完成一次呼吸循环）能最有效地增强心率变异性（HRV），从而促进放松状态。

> ✅ 参考文献：Lehrer, P. M., & Gevirtz, R. (2014). Heart rate variability biofeedback: how and why does it work?

#### 2. **心率变异性（HRV）最大化**
- HRV 是衡量身体应对压力能力的重要指标。
- 在大约**6次/分钟**的呼吸频率下，HRV达到最大值，这种现象被称为**共振频率呼吸**（Resonance Frequency Breathing）。

> ✅ 参考文献：Bernardi, L., et al. (2001). Effect of breathing rate on heart rate variability in normal subjects.

#### 3. **正念冥想与临床应用**
- 许多冥想练习建议采用**吸气时间长于呼气或相等**的方式，例如：
  - 吸气4秒 → 呼气6秒（更强调副交感激活）
  - 吸气4秒 → 屏息2秒 → 呼气4秒（平衡身心）

### 三、典型手环厂商的呼吸训练设置（举例）

| 品牌       | 应用名称       | 呼吸频率         | 时间长度 | 特点说明                     |
|------------|----------------|------------------|----------|------------------------------|
| Apple Watch | Breathe App    | 5–7次/分钟       | 1~5分钟  | 引导式动画 + 触觉反馈        |
| Fitbit     | Relaxation Mode | 6次/分钟         | 2~5分钟  | 结合HRV监测反馈              |
| 小米手环   | 压力监测+呼吸训练 | 6–8次/分钟       | 1~3分钟  | 配合压力指数评估             |
| 华为手环   | 压力助手       | 6次/分钟         | 1~5分钟  | 支持呼吸训练与压力释放       |

### 四、总结：推荐呼吸频率及理由

| 推荐频率      | 适用场景                   | 理由                                     |
|---------------|----------------------------|------------------------------------------|
| 6次/分钟      | 放松、冥想、减压           | 激活副交感神经，提升HRV                  |
| 5–7次/分钟    | 焦虑缓解、睡眠准备         | 匹配人体自然共振频率                     |
| 7–10次/分钟   | 快速调整情绪、轻度放松     | 更适合初学者，容易适应                   |

---

## 系统要求

- macOS 11.0+
- Xcode 15.0+（开发需要）

## 构建方式

### 1. 使用 Xcode（推荐开发）

```bash
# 打开项目
open breathe.xcodeproj

# 在Xcode中按 Cmd+R 运行
```

### 2. 命令行构建

```bash
# Debug构建
xcodebuild -scheme breathe -configuration Debug

# Release构建
xcodebuild -scheme breathe -configuration Release

# 运行应用
open ~/Library/Developer/Xcode/DerivedData/breathe-*/Build/Products/Debug/breathe.app
```

## GitHub Actions 自动构建

本项目配置了完整的GitHub Actions工作流，可以自动构建多架构DMG包。

### 触发条件

- 推送到 `main` 或 `master` 分支
- 创建标签（如 `v1.0.0`）
- Pull Request
- 手动触发

### 构建产物

工作流会生成以下文件：

1. **breathe-x86_64.dmg** - Intel Mac版本
2. **breathe-arm64.dmg** - Apple Silicon版本  

### 工作流特性

- ✅ **多架构支持**: 同时构建x86_64和ARM64
- ✅ **自动发布**: 标签推送时自动创建GitHub Release
- ✅ **Artifacts保存**: 30天保留期
- ✅ **构建摘要**: 可视化构建结果

### 手动触发构建

1. 进入GitHub仓库的Actions页面
2. 选择"Build DMG Packages"工作流
3. 点击"Run workflow"
4. 选择分支并点击绿色按钮

### 发布新版本

```bash
# 创建并推送标签
git tag v1.0.0
git push origin v1.0.0

# GitHub Actions会自动：
# 1. 构建所有架构
# 2. 创建DMG包
# 3. 发布GitHub Release
# 4. 上传DMG文件到Release
```

## 构建配置说明

### Debug vs Release vs Archive

| 构建类型 | 优化级别 | 调试信息 | 用途 |
|---------|---------|---------|------|
| **Debug** | 无优化 (`-Onone`) | 完整调试符号 | 开发调试 |
| **Release** | 全优化 (`-O`) | dSYM文件 | 性能测试、分发 |
| **Archive** | 全优化 + 签名 | dSYM文件 | App Store、正式分发 |

### 架构支持

- **x86_64**: Intel Mac
- **arm64**: Apple Silicon (M1/M2/M3)

## 项目结构

```
breathe/
├── .github/workflows/
│   └── build-dmg.yml          # GitHub Actions工作流
├── breathe/
│   ├── breatheApp.swift       # 主应用代码
│   ├── ContentView.swift      # SwiftUI视图（未使用）
│   ├── breathe.entitlements   # 应用权限
│   └── Assets.xcassets/       # 资源文件
├── breatheTests/              # 单元测试
├── breatheUITests/            # UI测试
├── .gitignore                # Git忽略文件
└── README.md                 # 项目说明
```

## 开发工具

### 推荐编辑器

1. **Xcode** - 原生支持，功能最全
2. **Cursor** - AI辅助编程
3. **VS Code** - 轻量级，丰富插件

### 调试工具

```bash
# Xcode调试器（推荐）
# 在Xcode中设置断点调试

# 命令行调试
lldb breathe.app/Contents/MacOS/breathe

# 性能分析
instruments -t "Time Profiler" breathe.app

# 内存检查
leaks breathe
```

## 安装和分发

### 本地安装

```bash
# 复制到Applications目录
sudo cp -R breathe.app /Applications/

# 或者使用DMG包
open breathe.dmg
# 拖拽到Applications文件夹
```

### 代码签名（分发用）

```bash
# 签名应用
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application: Your Name" \
  breathe.app

# 验证签名
codesign --verify --verbose breathe.app
spctl --assess --verbose breathe.app
```

## 故障排除

### 常见问题

1. **应用无法启动**
   - 检查macOS版本是否兼容
   - 尝试在终端中运行查看错误信息
   - 尝试打开 “终端” 执行如下命令：sudo xattr -cr /Applications/breathe.app

2. **状态栏图标不显示**
   - 检查系统偏好设置中的状态栏项目
   - 重启应用或重启系统

3. **构建失败**
   - 检查Xcode版本和命令行工具

### 调试日志

```bash
# 查看应用日志
log show --predicate 'process == "breathe"' --last 1h

# 系统控制台
open /Applications/Utilities/Console.app
```

## 贡献指南

1. Fork项目
2. 创建功能分支
3. 提交更改
4. 推送到分支
5. 创建Pull Request

## 许可证

本项目采用MIT许可证 - 详见LICENSE文件。

## 联系方式

如有问题或建议，请提交Issue或Pull Request。 