//
//  EnhancedTTSService.swift
//  PDFtts
//
//  Created by Matt on 16/7/2025.
//

import Foundation
import AVFoundation

class EnhancedTTSService: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var isPaused = false
    @Published var readingProgress: Double = 0.0
    @Published var currentSegmentIndex = 0
    @Published var totalSegments = 0
    @Published var currentReadingText = ""
    @Published var highlightedSentences: [String] = []
    @Published var selectedLanguage: String = "zh" // 默认中文
    
    private let chineseURL = "https://ttszh.mattwu.cc/tts"
    private let englishURL = "https://tts.mattwu.cc/api/tts"
    private var audioPlayer: AVAudioPlayer?
    private var audioSession: AVAudioSession?
    private var currentSegments: [TextSegment] = []
    private var isProcessing = false
    private var shouldStop = false
    
    struct TextSegment {
        let text: String
        let isEnglish: Bool
        let index: Int
    }
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            audioSession = AVAudioSession.sharedInstance()
            try audioSession?.setCategory(.playback, mode: .default, options: [.defaultToSpeaker])
            try audioSession?.setActive(true)
            print("✅ 音频会话设置成功")
        } catch {
            print("❌ 音频会话设置失败: \(error)")
        }
    }
    
    // 检测文本语言
    private func detectLanguage(text: String) -> Bool {
        let chineseRange = text.range(of: "\\p{Han}", options: .regularExpression)
        let englishRange = text.range(of: "[A-Za-z]", options: .regularExpression)
        
        let chineseCount = text.components(separatedBy: CharacterSet(charactersIn: "\\p{Han}")).count - 1
        let englishCount = text.components(separatedBy: CharacterSet.letters.inverted).filter { !$0.isEmpty }.count
        
        // 如果中文字符更多，返回false（中文），否则返回true（英文）
        return englishCount > chineseCount
    }
    
    // 智能分段（基于用户选择的语言）
    private func createSegments(from text: String) -> [TextSegment] {
        let sentences = splitTextIntelligently(text: text)
        let isEnglish = selectedLanguage == "en"
        
        return sentences.enumerated().map { index, sentence in
            TextSegment(
                text: sentence,
                isEnglish: isEnglish,
                index: index
            )
        }
    }
    
    // 开始朗读
    func startReading(text: String) async {
        guard !isProcessing else { return }
        
        isProcessing = true
        shouldStop = false
        
        // 创建分段
        let segments = createSegments(from: text)
        
        await MainActor.run {
            currentSegments = segments
            totalSegments = segments.count
            currentSegmentIndex = 0
            isPlaying = true
            isPaused = false
            readingProgress = 0.0
            highlightedSentences = segments.map { $0.text }
        }
        
        print("🔊 开始朗读，共 \(totalSegments) 段")
        
        // 开始播放分段
        await playSegments()
        
        isProcessing = false
    }
    
    // 播放分段
    private func playSegments() async {
        for (index, segment) in currentSegments.enumerated() {
            guard isPlaying && !shouldStop else { break }
            
            await MainActor.run {
                currentSegmentIndex = index
                currentReadingText = segment.text
                readingProgress = Double(index) / Double(totalSegments)
            }
            
            print("🎵 播放第 \(index + 1)/\(totalSegments) 段: \(segment.text.prefix(50))...")
            
            // 获取音频数据
            if let audioData = await loadSegmentAudio(segment: segment) {
                await playAudioData(audioData)
            } else {
                print("❌ API调用失败，跳过此段: \(segment.text.prefix(50))...")
                // 如果API失败，短暂等待后继续下一段
                try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
            }
            
            // 等待播放完成
            await waitForPlaybackCompletion()
        }
        
        // 播放完成
        await MainActor.run {
            isPlaying = false
            isPaused = false
            readingProgress = 1.0
            currentReadingText = ""
        }
        
        print("✅ 朗读完成")
    }
    
    // 根据语言选择API并加载音频（基于网页版逻辑）
    private func loadSegmentAudio(segment: TextSegment, retryCount: Int = 3) async -> Data? {
        let apiURL = segment.isEnglish ? englishURL : chineseURL
        
        print("📡 \(segment.isEnglish ? "英文" : "中文")API: \(apiURL)")
        
        for attempt in 1...retryCount {
            do {
                print("📡 正在生成\(segment.isEnglish ? "英文" : "中文")语音 (尝试 \(attempt)/\(retryCount))...")
                
                let data: Data
                
                if segment.isEnglish {
                    // 英文TTS - GET请求
                    let urlString = "\(apiURL)?text=\(segment.text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&speaker_id=p335"
                    guard let url = URL(string: urlString) else {
                        print("❌ 无效的URL")
                        continue
                    }
                    
                    let (responseData, response) = try await URLSession.shared.data(from: url)
                    
                    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                        data = responseData
                    } else {
                        print("❌ TTS API错误: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                        continue
                    }
                } else {
                    // 中文TTS - POST请求
                    guard let url = URL(string: apiURL) else {
                        print("❌ 无效的URL")
                        continue
                    }
                    
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.timeoutInterval = 300 // 5分钟超时
                    
                    let payload = ["text": segment.text]
                    request.httpBody = try JSONSerialization.data(withJSONObject: payload)
                    
                    let (responseData, response) = try await URLSession.shared.data(for: request)
                    
                    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                        data = responseData
                    } else {
                        print("❌ TTS API错误: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                        continue
                    }
                }
                
                print("🎵 \(segment.isEnglish ? "英文" : "中文")音频生成完成，大小: \(data.count / 1024) KB")
                return data
                
            } catch {
                print("❌ 第 \(attempt) 次尝试失败: \(error)")
                
                if attempt < retryCount {
                    // 重试前等待
                    try? await Task.sleep(nanoseconds: UInt64(1000000000 * attempt))
                }
            }
        }
        
        return nil
    }
    
    // 播放音频数据
    private func playAudioData(_ data: Data) async {
        guard !shouldStop else { return }
        
        do {
            // 确保音频会话激活
            try audioSession?.setActive(true)
            
            // 创建新的音频播放器
            let player = try AVAudioPlayer(data: data)
            player.delegate = self
            player.prepareToPlay()
            
            // 设置音频播放器
            audioPlayer = player
            
            // 开始播放
            if player.play() {
                print("✅ 音频播放开始")
            } else {
                print("❌ 音频播放启动失败")
            }
        } catch {
            print("❌ 音频播放失败: \(error)")
            // 播放失败时清理
            audioPlayer?.delegate = nil
            audioPlayer = nil
        }
    }
    
    // 等待播放完成
    private func waitForPlaybackCompletion() async {
        while let player = audioPlayer, player.isPlaying && !shouldStop {
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
    }
    
    // 暂停朗读
    func pauseReading() {
        print("⏸️ 暂停朗读")
        if let player = audioPlayer, player.isPlaying {
            player.pause()
            DispatchQueue.main.async {
                self.isPaused = true
            }
        }
    }
    
    // 恢复朗读
    func resumeReading() {
        print("▶️ 恢复朗读")
        if let player = audioPlayer, !player.isPlaying {
            player.play()
            DispatchQueue.main.async {
                self.isPaused = false
            }
        }
    }
    
    // 停止朗读
    func stopReading() {
        print("🛑 停止朗读")
        shouldStop = true
        
        // 安全地停止和清理音频播放器
        if let player = audioPlayer {
            player.stop()
            player.delegate = nil
            audioPlayer = nil
        }
        
        // 重置处理状态
        isProcessing = false
        
        DispatchQueue.main.async {
            self.isPlaying = false
            self.isPaused = false
            self.readingProgress = 0.0
            self.currentSegmentIndex = 0
            self.currentReadingText = ""
            self.highlightedSentences = []
        }
    }
    
    // 智能文本分段（基于网页版逻辑）
    private func splitTextIntelligently(text: String, maxLength: Int? = nil) -> [String] {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 根据语言选择分段长度
        let actualMaxLength = maxLength ?? (selectedLanguage == "zh" ? 150 : 400)
        
        if cleanText.count <= actualMaxLength {
            return cleanText.isEmpty ? [] : [cleanText]
        }
        
        var segments: [String] = []
        var currentSegment = ""
        
        // 按句子分割（中英文标点符号）
        let sentences = cleanText.components(separatedBy: CharacterSet(charactersIn: "。！？.!?"))
        
        for sentence in sentences {
            let trimmedSentence = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedSentence.isEmpty { continue }
            
            let sentenceWithPunctuation = trimmedSentence + "。"
            
            if currentSegment.count + sentenceWithPunctuation.count > actualMaxLength {
                if !currentSegment.isEmpty && currentSegment.count > 10 {
                    segments.append(currentSegment)
                    currentSegment = ""
                }
                
                if sentenceWithPunctuation.count > actualMaxLength {
                    let chunks = sentenceWithPunctuation.chunked(into: actualMaxLength)
                    segments.append(contentsOf: chunks.filter { $0.count > 10 })
                } else {
                    currentSegment = sentenceWithPunctuation
                }
            } else {
                currentSegment += sentenceWithPunctuation
            }
        }
        
        if !currentSegment.isEmpty && currentSegment.count > 10 {
            segments.append(currentSegment)
        }
        
        // 如果没有分段成功，按长度强制分段
        if segments.isEmpty && cleanText.count > actualMaxLength {
            let chunks = cleanText.chunked(into: actualMaxLength)
            segments.append(contentsOf: chunks.filter { $0.count > 10 })
        }
        
        // 如果仍然没有分段，直接返回原文本
        if segments.isEmpty && cleanText.count > 0 {
            segments.append(cleanText)
        }
        
        print("📊 文本分段结果: \(segments.count) 段")
        for (index, segment) in segments.enumerated() {
            let preview = segment.count > 50 ? String(segment.prefix(50)) + "..." : segment
            print("段 \(index + 1): \"\(preview)\" (\(segment.count) 字符)")
        }
        
        return segments.filter { !$0.isEmpty }
    }
    
    // 获取当前高亮句子（用于UI显示）
    func getCurrentHighlightedSentence() -> String {
        if currentSegmentIndex < highlightedSentences.count {
            return highlightedSentences[currentSegmentIndex]
        }
        return ""
    }
}

// AVAudioPlayer委托
extension EnhancedTTSService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if !flag {
            print("❌ 音频播放未成功完成")
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            print("❌ 音频解码错误: \(error)")
        }
    }
}

// String扩展
extension String {
    func chunked(into size: Int) -> [String] {
        return stride(from: 0, to: count, by: size).map {
            let start = index(startIndex, offsetBy: $0)
            let end = index(start, offsetBy: min(size, count - $0))
            return String(self[start..<end])
        }
    }
}