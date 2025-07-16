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
                
                
                // 回到朗读页按钮 - 只在朗读且不在朗读页时显示
                if ttsService.isPlaying && ttsService.currentReadingPage > 0 && ttsService.currentReadingPage != currentPage {
                    HStack {
                        Spacer()
                        Button(action: {
                            ttsService.goToReadingPage()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "book.circle.fill")
                                    .font(.caption2)
                                Text("回到第\(ttsService.currentReadingPage)页")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(16)
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
            
            
            // 当前朗读文本
            if !ttsService.currentReadingText.isEmpty {
                ScrollViewReader { proxy in
                    ScrollView {
                        Text(ttsService.currentReadingText)
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(Color.yellow.opacity(0.2))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.yellow.opacity(0.5), lineWidth: 1)
                            )
                            .id("textContent")
                    }
                    .frame(maxHeight: 400)
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
                    }
                }
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