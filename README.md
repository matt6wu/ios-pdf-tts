# PDFtts - iOS PDF阅读器与TTS朗读应用

一个基于SwiftUI和PDFKit开发的iOS PDF阅读器，集成了中英文TTS（文本转语音）功能。

## 功能特性

### 📚 PDF阅读功能
- 支持PDF文档查看和缩放
- 自适应页面显示
- 缩略图侧边栏导航
- 支持文件选择器和拖拽导入
- 页面翻页控制（手势滑动 + 按钮控制）

### 🎵 TTS朗读功能
- **中英文分离TTS**：智能识别并使用不同的API
  - 中文：`https://ttszh.mattwu.cc/tts`（POST请求）
  - 英文：`https://tts.mattwu.cc/api/tts`（GET请求）
- **智能文本分段**：
  - 中文：150字符分段
  - 英文：400字符分段
- **播放控制**：播放/暂停/停止
- **实时进度显示**：显示当前朗读进度和文本内容
- **语言选择器**：可在中英文TTS之间切换

### 🎯 高级功能
- **当前页朗读**：播放按钮读取当前页面内容
- **文本提取**：精确提取PDF页面文本
- **高亮显示**：朗读时高亮当前文本（开发中）
- **状态同步**：页面状态与PDF视图完全同步

## 技术架构

### 核心组件
```
PDFtts/
├── ContentView.swift              # 主界面
├── EnhancedTTSService.swift       # 增强版TTS服务
├── HighlightPDFReaderView.swift   # 高亮PDF阅读器
├── PDFReaderView.swift            # 基础PDF阅读器
├── ReadingProgressView.swift      # 朗读进度显示
├── PDFThumbnailSidebar.swift      # 缩略图侧边栏
└── PDFTextExtractor.swift         # PDF文本提取工具
```

### 技术栈
- **UI框架**：SwiftUI
- **PDF处理**：PDFKit
- **音频播放**：AVFoundation
- **网络请求**：URLSession
- **异步处理**：async/await

## 实现历程

### 🏗️ 第一阶段：基础功能搭建
1. **PDF阅读器开发**
   - 创建基本PDF显示组件
   - 实现页面导航和缩放功能
   - 解决白屏问题（NavigationView → GeometryReader）

2. **TTS服务集成**
   - 集成基础TTS API调用
   - 实现音频播放控制
   - 添加播放/暂停/停止逻辑

### 🔧 第二阶段：功能增强
3. **中英文分离**
   - 参考webexample实现语言检测
   - 配置双API支持（中文POST + 英文GET）
   - 添加语言选择器界面

4. **智能文本分段**
   - 实现基于语言的分段策略
   - 优化句子分割算法
   - 添加文本预处理逻辑

### 🐛 第三阶段：问题修复
5. **文件选择问题**
   - 修复文件选择按钮无响应
   - 解决PDF加载状态管理
   - 优化文件导入流程

6. **页面状态同步**
   - **关键问题**：页码显示始终为第一页
   - **根因分析**：PDFView委托方法未正确调用
   - **解决方案**：
     ```swift
     // 问题：委托类型转换错误
     delegate.pdfViewDidChangePage(self)  // ❌
     
     // 解决：正确的类型转换
     if let delegate = self.delegate as? HighlightPDFReaderView.Coordinator {
         delegate.pdfViewDidChangePage(self)  // ✅
     }
     ```

7. **音频播放崩溃**
   - **问题**：NSMapTable崩溃
   - **原因**：音频播放器生命周期管理问题
   - **解决**：增强资源清理和空值检查

8. **PDF文本提取**
   - **问题**：无法提取PDF文本内容
   - **原因**：PDF文档权限或格式问题
   - **解决**：添加多种文本提取方法和详细调试

### 🎨 第四阶段：用户体验优化
9. **界面优化**
   - 侧边栏默认隐藏
   - 语言选择器始终显示
   - 播放控制按钮状态逻辑

10. **错误处理**
    - 添加详细的调试日志
    - 网络请求重试机制
    - 用户友好的错误提示

## 技术难点与解决方案

### 1. PDF页面状态同步
**问题**：滑动翻页时页码不更新
**解决**：
- 添加`PDFViewPageChanged`通知监听
- 重写`go(to:)`方法手动触发委托
- 正确的委托类型转换

### 2. 中英文TTS API集成
**问题**：不同语言需要不同的API格式
**解决**：
```swift
// 中文 - POST请求
let payload = ["text": segment.text]
request.httpBody = try JSONSerialization.data(withJSONObject: payload)

// 英文 - GET请求  
let urlString = "\(apiURL)?text=\(encodedText)&speaker_id=p335"
```

### 3. 音频播放器生命周期管理
**问题**：NSMapTable崩溃
**解决**：
- 安全的播放器清理
- 委托置空防止悬挂引用
- 音频会话状态管理

### 4. 自定义PDFView委托调用
**问题**：自定义PDFView子类委托方法不触发
**解决**：
- 通知中心监听页面变化
- 类型转换调用具体委托方法
- 手动触发委托回调

## 使用说明

1. **加载PDF**：点击文件夹图标选择PDF文件
2. **翻页**：使用底部按钮或直接滑动PDF页面
3. **选择语言**：在顶部选择中文或English
4. **开始朗读**：点击播放按钮朗读当前页内容
5. **控制播放**：使用暂停/停止按钮控制播放状态

## 开发环境

- **Xcode**: 15.0+
- **iOS**: 17.0+
- **Swift**: 5.9+

## 项目结构

```
PDFtts/
├── webexample/           # 网页版参考实现
├── PDFtts/
│   ├── ContentView.swift
│   ├── EnhancedTTSService.swift
│   ├── HighlightPDFReaderView.swift
│   ├── PDFReaderView.swift
│   ├── ReadingProgressView.swift
│   ├── PDFThumbnailSidebar.swift
│   └── PDFTextExtractor.swift
├── today.pdf            # 测试PDF文件
└── README.md
```

## 未来规划

- [ ] 完善文本高亮显示功能
- [ ] 集成Box云存储支持
- [ ] 添加书签和笔记功能
- [ ] 优化TTS音频缓存机制
- [ ] 支持更多TTS语音选择
- [ ] 添加阅读历史记录

## 致谢

感谢在开发过程中遇到的每一个bug，它们让这个应用变得更加稳定和完善。特别是那个让人头疼的页面状态同步问题，最终通过委托类型转换得到了完美解决。

---

*"代码不会说谎，但调试会让人发疯。"*