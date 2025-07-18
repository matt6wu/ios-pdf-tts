//
//  UserSettingsView.swift
//  PDFtts
//
//  Created by Matt on 17/7/2025.
//

import SwiftUI

struct UserSettingsView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 标题
                HStack {
                    Text("用户设置")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.horizontal)
                
                // 设置选项列表
                VStack(spacing: 16) {
                    // API设置区域（预留）
                    VStack(alignment: .leading, spacing: 12) {
                        Text("TTS API设置")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("中文API")
                                    .font(.body)
                                Spacer()
                                Text("ttszh.mattwu.cc")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            
                            HStack {
                                Text("英文API")
                                    .font(.body)
                                Spacer()
                                Text("tts.mattwu.cc")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    
                    Divider()
                    
                    // 应用信息区域
                    VStack(alignment: .leading, spacing: 12) {
                        Text("应用信息")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("应用版本")
                                    .font(.body)
                                Spacer()
                                Text("1.0.0")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            
                            HStack {
                                Text("开发者")
                                    .font(.body)
                                Spacer()
                                Text("Matt")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // 未来功能提示
                VStack(spacing: 8) {
                    Text("🚀 即将推出")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Text("• 自定义TTS API设置\n• 语音参数调整\n• 主题切换\n• 更多个性化选项")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    UserSettingsView(isPresented: .constant(true))
}