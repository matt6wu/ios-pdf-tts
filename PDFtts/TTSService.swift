//
//  TTSService.swift
//  PDFtts
//
//  Created by Matt on 16/7/2025.
//

import Foundation
import AVFoundation

class TTSService: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var isPaused = false
    @Published var readingProgress: Double = 0.0
    @Published var currentSegment = 0
    @Published var totalSegments = 0
    
    private let baseURL = "https://tts.mattwu.cc"
    private var audioPlayer: AVAudioPlayer?
    private var audioSession: AVAudioSession?
    private var currentSegments: [String] = []
    private var isProcessing = false
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession?.setCategory(.playback, mode: .default, options: [])
            try audioSession?.setActive(true)
        } catch {
            print("❌ 音频会话设置失败: \(error)")
        }
    }
    
    // 开始朗读文本
    func startReading(text: String) async {
        guard !isProcessing else { return }
        
        isProcessing = true
        
        // 智能分段
        let segments = splitTextIntelligently(text: text)
        currentSegments = segments
        totalSegments = segments.count
        currentSegment = 0
        
        await MainActor.run {
            isPlaying = true
            isPaused = false
            readingProgress = 0.0
        }
        
        // 开始播放分段
        await playSegments()
        
        isProcessing = false
    }
    
    // 停止朗读
    func stopReading() {
        audioPlayer?.stop()
        audioPlayer = nil
        
        DispatchQueue.main.async {
            self.isPlaying = false
            self.isPaused = false
            self.readingProgress = 0.0
            self.currentSegment = 0
        }
    }
    
    // 暂停朗读
    func pauseReading() {
        audioPlayer?.pause()
        
        DispatchQueue.main.async {
            self.isPaused = true
        }
    }
    
    // 恢复朗读
    func resumeReading() {
        audioPlayer?.play()
        
        DispatchQueue.main.async {
            self.isPaused = false
        }
    }
    
    // 播放分段
    private func playSegments() async {
        for (index, segment) in currentSegments.enumerated() {
            guard isPlaying && !isProcessing else { break }
            
            await MainActor.run {
                currentSegment = index
                readingProgress = Double(index) / Double(totalSegments)
            }
            
            // 获取音频数据
            if let audioData = await loadSegmentAudio(text: segment) {
                await playAudioData(audioData)
            }
            
            // 等待播放完成
            await waitForPlaybackCompletion()
        }
        
        // 播放完成
        await MainActor.run {
            isPlaying = false
            isPaused = false
            readingProgress = 1.0
        }
    }
    
    // 加载音频数据
    private func loadSegmentAudio(text: String) async -> Data? {
        guard let url = URL(string: "\(baseURL)/api/tts") else {
            print("❌ 无效的TTS URL")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = ["text": text]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    return data
                } else {
                    print("❌ TTS API错误: \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("❌ 网络请求失败: \(error)")
        }
        
        return nil
    }
    
    // 播放音频数据
    private func playAudioData(_ data: Data) async {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.play()
        } catch {
            print("❌ 音频播放失败: \(error)")
        }
    }
    
    // 等待播放完成
    private func waitForPlaybackCompletion() async {
        while audioPlayer?.isPlaying == true {
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
    }
    
    // 智能文本分段
    private func splitTextIntelligently(text: String, maxLength: Int = 400) -> [String] {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 如果文本长度小于最大长度，直接返回
        if cleanText.count <= maxLength {
            return cleanText.isEmpty ? [] : [cleanText]
        }
        
        var segments: [String] = []
        var currentSegment = ""
        
        // 按句子分割
        let sentences = cleanText.components(separatedBy: CharacterSet(charactersIn: "。！？.!?"))
        
        for sentence in sentences {
            let trimmedSentence = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedSentence.isEmpty { continue }
            
            // 添加标点符号
            let sentenceWithPunctuation = trimmedSentence + "。"
            
            // 检查是否会超过最大长度
            if currentSegment.count + sentenceWithPunctuation.count > maxLength {
                if !currentSegment.isEmpty {
                    segments.append(currentSegment)
                    currentSegment = ""
                }
                
                // 如果单句超过最大长度，按字符分割
                if sentenceWithPunctuation.count > maxLength {
                    let chunks = sentenceWithPunctuation.chunked(into: maxLength)
                    segments.append(contentsOf: chunks)
                } else {
                    currentSegment = sentenceWithPunctuation
                }
            } else {
                currentSegment += sentenceWithPunctuation
            }
        }
        
        // 添加最后一个分段
        if !currentSegment.isEmpty {
            segments.append(currentSegment)
        }
        
        return segments.filter { !$0.isEmpty }
    }
}

// AVAudioPlayer委托
extension TTSService: AVAudioPlayerDelegate {
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

