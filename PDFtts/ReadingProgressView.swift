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
    
    var body: some View {
        VStack(spacing: 8) {
            // TTS控制界面标题栏
            HStack {
                Text("🎵 朗读控制")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 关闭按钮
                Button(action: {
                    ttsService.hideTTSControls()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
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
                Text("朗读语言:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
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
                HStack(spacing: 12) {
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
                        HStack(spacing: 6) {
                            Image(systemName: getPlayButtonIcon())
                                .font(.title2)
                            Text(getPlayButtonText())
                                .font(.headline)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(getPlayButtonColor())
                        .foregroundColor(.white)
                        .cornerRadius(25)
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
                }
                .padding(.vertical, 8)
                
                // 自动翻页开关
                Toggle("自动翻页", isOn: $ttsService.autoPageTurn)
                    .font(.caption)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                
                // 后台播放提示
                if ttsService.isPlaying || ttsService.isPaused {
                    HStack(spacing: 4) {
                        Image(systemName: "moon.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text("支持后台播放和锁屏控制")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 2)
                }
                
                // 回到朗读页按钮 - 只在朗读且不在朗读页时显示
                if ttsService.isPlaying && ttsService.currentReadingPage > 0 && ttsService.currentReadingPage != currentPage {
                    Button(action: {
                        ttsService.goToReadingPage()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "book.circle.fill")
                                .font(.caption)
                            Text("第\(ttsService.currentReadingPage)页")
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(8)
            .shadow(radius: 1)
            
            // 进度条
            if ttsService.isPlaying || ttsService.isPaused {
                VStack(spacing: 4) {
                    HStack {
                        Text("朗读进度")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(ttsService.currentSegmentIndex + 1) / \(ttsService.totalSegments)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: ttsService.readingProgress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .scaleEffect(y: 0.8)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(8)
                .shadow(radius: 2)
            }
            
            // 当前朗读文本
            if !ttsService.currentReadingText.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: ttsService.isPaused ? "pause.circle.fill" : "speaker.wave.2.fill")
                                .foregroundColor(ttsService.isPaused ? .orange : .blue)
                                .font(.caption)
                            
                            Text("正在朗读")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            // 语言标识
                            if !ttsService.currentReadingText.isEmpty {
                                Text(ttsService.selectedLanguage == "en" ? "EN" : "中文")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(ttsService.selectedLanguage == "en" ? Color.green : Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                            }
                        }
                        
                        Text(ttsService.currentReadingText)
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                            .background(Color.yellow.opacity(0.2))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.yellow.opacity(0.5), lineWidth: 1)
                            )
                    }
                }
                .frame(maxHeight: 120)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(8)
                .shadow(radius: 2)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: ttsService.isPlaying)
        .animation(.easeInOut(duration: 0.3), value: ttsService.currentReadingText)
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
    
    private func getPlayButtonText() -> String {
        if ttsService.isPlaying && ttsService.isPaused {
            return "继续"
        } else if ttsService.isPlaying {
            return "暂停"
        } else {
            return "播放"
        }
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