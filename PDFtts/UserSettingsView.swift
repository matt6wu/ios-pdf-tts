//
//  UserSettingsView.swift
//  PDFtts
//
//  Created by Matt on 17/7/2025.
//

import SwiftUI

struct UserSettingsView: View {
    @Binding var isPresented: Bool
    @ObservedObject var ttsService: EnhancedTTSService
    @State private var showSpeakerSelection = false
    
    var body: some View {
        NavigationView {
            ScrollView {
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
                        // Speaker选择区域
                        VStack(alignment: .leading, spacing: 12) {
                            Text("语音选择")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            // Speaker选择按钮
                            Button(action: {
                                showSpeakerSelection = true
                            }) {
                                HStack {
                                    Image(systemName: "speaker.wave.2")
                                        .foregroundColor(.blue)
                                    Text("选择语音")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text(getCurrentSpeakerText())
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Image(systemName: "chevron.right")
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
                        
                        // API设置区域
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
                                    Text("1.2.0")
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
                    
                    // 未来功能提示
                    VStack(spacing: 8) {
                        Text("🚀 即将推出")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Text("• 自定义TTS API设置\n• 语音参数调整\n• 主题切换\n• 更多个性化选项")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    Spacer(minLength: 50)
                }
                .padding(.vertical)
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
        .sheet(isPresented: $showSpeakerSelection) {
            SpeakerSelectionView(isPresented: $showSpeakerSelection, ttsService: ttsService)
        }
    }
    
    // 获取当前Speaker显示文本
    private func getCurrentSpeakerText() -> String {
        if ttsService.selectedLanguage == "zh" {
            return "中文语音"
        } else {
            return "英文语音 (p335)"
        }
    }
}

// Speaker选择视图
struct SpeakerSelectionView: View {
    @Binding var isPresented: Bool
    @ObservedObject var ttsService: EnhancedTTSService
    @State private var selectedTab = 0 // 0: 中文, 1: 英文
    
    // 定义可用的speakers
    struct Speaker {
        let id: String
        let name: String
        let description: String
    }
    
    let chineseSpeakers: [Speaker] = [
        Speaker(id: "default", name: "标准语音", description: "清晰自然的中文语音")
    ]
    
    let englishSpeakers: [Speaker] = [
        Speaker(id: "p335", name: "p335", description: "标准英文语音"),
        // 预留位置，后期可添加更多
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 语言切换标签
                Picker("语言", selection: $selectedTab) {
                    Text("中文").tag(0)
                    Text("English").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Speaker列表
                List {
                    if selectedTab == 0 {
                        // 中文Speakers
                        ForEach(chineseSpeakers, id: \.id) { speaker in
                            SpeakerRow(
                                speaker: speaker,
                                isSelected: ttsService.selectedLanguage == "zh",
                                onSelect: {
                                    ttsService.selectedLanguage = "zh"
                                }
                            )
                        }
                    } else {
                        // 英文Speakers
                        ForEach(englishSpeakers, id: \.id) { speaker in
                            SpeakerRow(
                                speaker: speaker,
                                isSelected: ttsService.selectedLanguage == "en",
                                onSelect: {
                                    ttsService.selectedLanguage = "en"
                                    // 这里后期可以添加具体的speaker_id选择
                                }
                            )
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("选择语音")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        isPresented = false
                    }
                }
            }
        }
        .onAppear {
            // 根据当前选择的语言设置标签
            selectedTab = ttsService.selectedLanguage == "zh" ? 0 : 1
        }
    }
}

// Speaker行视图
struct SpeakerRow: View {
    let speaker: SpeakerSelectionView.Speaker
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(speaker.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(speaker.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    UserSettingsView(isPresented: .constant(true), ttsService: EnhancedTTSService())
}