//
//  ReadingProgressView.swift
//  PDFtts
//
//  Created by Matt on 16/7/2025.
//

import SwiftUI

struct ReadingProgressView: View {
    @ObservedObject var ttsService: EnhancedTTSService
    let languages = ["zh": "中文", "en": "English"]
    
    var body: some View {
        VStack(spacing: 8) {
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
                .disabled(ttsService.isPlaying && !ttsService.isPaused) // 播放时禁用，暂停时可选择
                
                Spacer()
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
}

#Preview {
    VStack {
        ReadingProgressView(ttsService: EnhancedTTSService())
            .padding()
        
        Spacer()
    }
}