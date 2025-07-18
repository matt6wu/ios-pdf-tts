//
//  ReadingProgressView.swift
//  PDFtts
//
//  Created by Matt on 16/7/2025.
//

import SwiftUI

struct ReadingProgressView: View {
    @ObservedObject var ttsService: EnhancedTTSService
    let currentPage: Int
    let languages = ["zh": "中文", "en": "English"]
    @State private var textBoxHeight: CGFloat = 120 // 可调整的文本框高度（初始为较小值）
    @State private var autoAdjustHeight: Bool = true // 自动调整高度开关
    @State private var isMinimized: Bool = false // 最小化状态
    
    var body: some View {
        VStack(spacing: 8) {
            
            // 语言选择提示 - 当需要确认语言时显示，或者语言未确认时始终显示
            if ttsService.showLanguagePrompt || !ttsService.isLanguageConfirmed {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("请先选择朗读语言")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    Text(ttsService.showLanguagePrompt ? "选择语言后将自动开始播放" : "请选择朗读语言")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            ttsService.selectedLanguage = "zh"
                            if ttsService.showLanguagePrompt {
                                Task {
                                    await ttsService.confirmLanguageAndStartReading()
                                }
                            } else {
                                // 只是选择语言，不自动播放
                                print("🔄 语言已选择为中文")
                            }
                        }) {
                            HStack {
                                Text("🇨🇳")
                                Text("中文")
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(ttsService.selectedLanguage == "zh" ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(ttsService.selectedLanguage == "zh" ? .white : .primary)
                            .cornerRadius(8)
                        }
                        
                        Button(action: {
                            ttsService.selectedLanguage = "en"
                            if ttsService.showLanguagePrompt {
                                Task {
                                    await ttsService.confirmLanguageAndStartReading()
                                }
                            } else {
                                // 只是选择语言，不自动播放
                                print("🔄 语言已选择为英文")
                            }
                        }) {
                            HStack {
                                Text("🇺🇸")
                                Text("English")
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(ttsService.selectedLanguage == "en" ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(ttsService.selectedLanguage == "en" ? .white : .primary)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 16)
            }
            
            // 语言选择器 - 始终显示
            HStack {
                Picker("Language", selection: $ttsService.selectedLanguage) {
                    Text("中文").tag("zh")
                    Text("English").tag("en")
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(maxWidth: 200)
                .onChange(of: ttsService.selectedLanguage) { newLanguage in
                    print("🔄 UI检测到语言切换: \(newLanguage)")
                }
                
                Spacer()
                
                // 播放控制按钮
                HStack(spacing: 16) {
                    // 主播放/暂停按钮
                    Button(action: {
                        if ttsService.isPlaying {
                            if ttsService.isPaused {
                                ttsService.resumeReading()
                            } else {
                                ttsService.pauseReading()
                            }
                        } else {
                            startReadingCurrentPage()
                        }
                    }) {
                        Image(systemName: getPlayButtonIcon())
                            .font(.title2)
                            .padding(12)
                            .background(getPlayButtonColor())
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                    
                    // 停止按钮
                    if ttsService.isPlaying || ttsService.isPaused {
                        Button(action: {
                            ttsService.stopReading()
                        }) {
                            Image(systemName: "stop.fill")
                                .font(.title2)
                                .padding(12)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                        }
                    }
                    
                    // 状态图标
                    if ttsService.isGeneratingTTS {
                        // TTS生成中 - 动态沙漏图标
                        Image(systemName: "hourglass")
                            .font(.title2)
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(ttsService.isGeneratingTTS ? 180 : 0))
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: ttsService.isGeneratingTTS)
                            .padding(12)
                            .background(Color.orange)
                            .cornerRadius(20)
                    } else if ttsService.isPlaying && !ttsService.isPaused {
                        // 播放中 - 动态音波图标
                        Image(systemName: "waveform")
                            .font(.title2)
                            .foregroundColor(.white)
                            .scaleEffect(ttsService.isPlaying ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: ttsService.isPlaying)
                            .padding(12)
                            .background(Color.blue)
                            .cornerRadius(20)
                    } else if ttsService.isPaused {
                        // 暂停中 - 静态暂停图标
                        Image(systemName: "pause.circle")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.orange)
                            .cornerRadius(20)
                    }
                }
                .padding(.vertical, 8)
                
                
                // 睡眠定时器显示 - 只在定时器激活时显示
                if ttsService.sleepTimer > 0 {
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                            .foregroundColor(.purple)
                        
                        Text(formatTime(ttsService.remainingTime))
                            .font(.caption)
                            .foregroundColor(.purple)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                }
                
                // 回到朗读页按钮 - 只在朗读且不在朗读页时显示
                if ttsService.isPlaying && ttsService.currentReadingPage > 0 && ttsService.currentReadingPage != currentPage {
                    HStack {
                        Spacer()
                        Button(action: {
                            ttsService.goToReadingPage()
                        }) {
                            Image(systemName: "arrow.up.arrow.down.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.green)
                                .cornerRadius(20)
                        }
                        Spacer()
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(8)
            .shadow(radius: 1)
            
            
            // 当前朗读文本 - 可调整大小
            if !ttsService.currentReadingText.isEmpty && !isMinimized {
                VStack(spacing: 0) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            Text(ttsService.currentReadingText)
                                .font(.body)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.blue.opacity(0.1),
                                            Color.cyan.opacity(0.05)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                                )
                                .id("textContent")
                        }
                        .frame(height: textBoxHeight)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(8)
                        .shadow(radius: 2)
                        .onChange(of: ttsService.currentReadingText) { _ in
                            // 当文本变化时自动滚动到顶部
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo("textContent", anchor: .top)
                            }
                            // 自动调整文本框高度
                            autoAdjustTextBoxHeight()
                        }
                    }
                    
                    // 高度调整控制
                    HStack {
                        // 自动调整开关
                        Button(action: {
                            autoAdjustHeight.toggle()
                            if autoAdjustHeight {
                                autoAdjustTextBoxHeight()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: autoAdjustHeight ? "wand.and.stars" : "wand.and.stars.slash")
                                    .font(.caption)
                                Text(autoAdjustHeight ? "自动" : "手动")
                                    .font(.caption2)
                            }
                            .foregroundColor(autoAdjustHeight ? .blue : .gray)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(autoAdjustHeight ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                            .cornerRadius(6)
                        }
                        
                        // 最小化按钮
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isMinimized.toggle()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: isMinimized ? "arrow.up.square" : "arrow.down.square")
                                    .font(.caption)
                                Text(isMinimized ? "展开" : "收起")
                                    .font(.caption2)
                            }
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(6)
                        }
                        
                        Spacer()
                        
                        // 调整大小手柄（仅在手动模式下可用）
                        if !autoAdjustHeight {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.gray.opacity(0.6))
                                .frame(width: 60, height: 6)
                                .padding(.vertical, 12)
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            let newHeight = textBoxHeight + value.translation.height
                                            // 限制最小高度100，最大高度600
                                            textBoxHeight = min(max(newHeight, 100), 600)
                                        }
                                )
                        }
                        
                        Spacer()
                    }
                    .background(Color(UIColor.systemBackground))
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 2)
            }
            
            // 最小化状态下的简化控制栏
            if isMinimized && !ttsService.currentReadingText.isEmpty {
                HStack {
                    // 显示当前状态
                    HStack(spacing: 8) {
                        Image(systemName: ttsService.isPlaying ? "play.circle.fill" : "pause.circle.fill")
                            .foregroundColor(ttsService.isPlaying ? .green : .orange)
                            .font(.title2)
                        
                        Text(ttsService.isPlaying ? "正在朗读..." : "已暂停")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // 展开按钮
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isMinimized = false
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.square")
                                .font(.caption)
                            Text("展开")
                                .font(.caption2)
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(8)
                .shadow(radius: 1)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: ttsService.isPlaying)
        .animation(.easeInOut(duration: 0.3), value: ttsService.currentReadingText)
        .onAppear {
            // 界面首次出现时进行初始高度调整
            autoAdjustTextBoxHeight()
        }
    }
    
    // 计算文本所需高度
    private func calculateTextHeight(for text: String) -> CGFloat {
        // 如果文本为空或很短，返回较小的默认高度
        if text.isEmpty || text.count < 20 {
            return 120 // 空文本或短文本的默认高度
        }
        
        let font = UIFont.preferredFont(forTextStyle: .body)
        let maxWidth = UIScreen.main.bounds.width - 64 // 减去padding
        
        let textSize = text.boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        ).size
        
        // 基础padding + 文本高度，限制在120-600之间
        let calculatedHeight = textSize.height + 60 // 32 padding + 28 额外空间
        return min(max(calculatedHeight, 120), 600)
    }
    
    // 自动调整文本框高度
    private func autoAdjustTextBoxHeight() {
        if autoAdjustHeight {
            let newHeight = calculateTextHeight(for: ttsService.currentReadingText)
            withAnimation(.easeInOut(duration: 0.3)) {
                textBoxHeight = newHeight
            }
        }
    }
    
    // 播放控制辅助函数
    private func startReadingCurrentPage() {
        // 这里需要调用ContentView的startReading逻辑
        // 临时解决方案：通过TTS服务获取当前页面文本
        if let getCurrentPage = ttsService.getCurrentPage,
           let getPageText = ttsService.getPageText {
            let currentPageNum = getCurrentPage()
            if let pageText = getPageText(currentPageNum), !pageText.isEmpty {
                print("🔊 开始播放第 \(currentPageNum) 页")
                Task {
                    await ttsService.startReading(text: pageText)
                }
            } else {
                print("❌ 无法获取当前页面文本")
            }
        }
    }
    
    private func getPlayButtonIcon() -> String {
        if ttsService.isPlaying && ttsService.isPaused {
            return "play.fill"
        } else if ttsService.isPlaying {
            return "pause.fill"
        } else {
            return "play.fill"
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    private func getPlayButtonColor() -> Color {
        if ttsService.isPlaying && !ttsService.isPaused {
            return .orange
        } else {
            return .blue
        }
    }
}

#Preview {
    VStack {
        ReadingProgressView(ttsService: EnhancedTTSService(), currentPage: 1)
            .padding()
        
        Spacer()
    }
}