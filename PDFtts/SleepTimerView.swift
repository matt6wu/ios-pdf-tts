//
//  SleepTimerView.swift
//  PDFtts
//
//  Created by Matt on 16/7/2025.
//

import SwiftUI

struct SleepTimerView: View {
    @ObservedObject var ttsService: EnhancedTTSService
    let timerOptions = [1, 15, 20, 30, 45, 60] // 定时器选项（分钟）
    
    var body: some View {
        VStack(spacing: 16) {
            // 当前定时器状态
            if ttsService.sleepTimer > 0 {
                // 显示剩余时间
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.title2)
                            .foregroundColor(.purple)
                        
                        Spacer()
                        
                        Text(formatTime(ttsService.remainingTime))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                    }
                    
                    // 进度条
                    ProgressView(value: Double(ttsService.sleepTimer * 60 - ttsService.remainingTime), total: Double(ttsService.sleepTimer * 60))
                        .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                        .scaleEffect(y: 1.2)
                    
                    // 取消按钮
                    Button(action: {
                        ttsService.cancelSleepTimer()
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                            Text("取消定时器")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                }
                .padding(16)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
            } else {
                // 设置定时器
                VStack(spacing: 16) {
                    // 定时器选项
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        ForEach(timerOptions, id: \.self) { minutes in
                            Button(action: {
                                ttsService.startSleepTimer(minutes: minutes)
                            }) {
                                VStack(spacing: 4) {
                                    Text("\(minutes)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Text("分钟")
                                        .font(.caption)
                                }
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.1))
                                .foregroundColor(.primary)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                    }
                }
                .padding(16)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
            }
        }
        .padding(.horizontal, 16)
        .animation(.easeInOut(duration: 0.3), value: ttsService.sleepTimer)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

#Preview {
    VStack {
        SleepTimerView(ttsService: EnhancedTTSService())
            .padding()
        
        Spacer()
    }
}