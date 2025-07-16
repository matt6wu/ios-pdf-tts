//
//  ContentView.swift
//  PDFtts
//
//  Created by Matt on 16/7/2025.
//

import SwiftUI
import PDFKit

struct ContentView: View {
    @State private var selectedPDF: URL? = URL(fileURLWithPath: "/Users/matt/Documents/app/PDFtts/today.pdf")
    @State private var showingDocumentPicker = false
    @State private var sidebarVisible = false
    @State private var currentPage = 1
    @State private var totalPages = 0
    @State private var zoomScale: CGFloat = 1.0
    @StateObject private var ttsService = EnhancedTTSService()
    @State private var pdfDocument: PDFDocument?
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // 侧边栏
                if sidebarVisible {
                    PDFThumbnailSidebar(
                        pdfURL: selectedPDF,
                        currentPage: $currentPage,
                        totalPages: $totalPages
                    )
                    .frame(width: min(300, geometry.size.width * 0.3))
                }
                
                // 主内容区域
                VStack(spacing: 0) {
                    // 顶部工具栏
                    HStack {
                        Button(action: { sidebarVisible.toggle() }) {
                            Image(systemName: sidebarVisible ? "sidebar.left" : "sidebar.left")
                                .font(.title2)
                                .foregroundColor(sidebarVisible ? .blue : .gray)
                        }
                        
                        Spacer()
                        
                        Text("PDF 电子阅读器")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            // 测试按钮
                            Button(action: testTextExtraction) {
                                Image(systemName: "magnifyingglass")
                                    .font(.title2)
                                    .foregroundColor(.green)
                            }
                            .disabled(selectedPDF == nil)
                            
                            // 朗读/暂停按钮
                            Button(action: toggleReading) {
                                Image(systemName: getReadingButtonIcon())
                                    .font(.title2)
                                    .foregroundColor(getReadingButtonColor())
                            }
                            .disabled(selectedPDF == nil)
                            
                            // 停止按钮
                            if ttsService.isPlaying || ttsService.isPaused {
                                Button(action: stopReading) {
                                    Image(systemName: "stop.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.red)
                                }
                            }
                            
                            // 文件选择按钮
                            Button(action: { showingDocumentPicker = true }) {
                                Image(systemName: "folder.fill")
                                    .font(.title2)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(UIColor.systemBackground))
                    .shadow(radius: 1)
                    
                    // PDF内容区域
                    if let pdfURL = selectedPDF {
                        VStack(spacing: 0) {
                            // 朗读进度显示
                            if ttsService.isPlaying || ttsService.isPaused || !ttsService.currentReadingText.isEmpty {
                                ReadingProgressView(ttsService: ttsService)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                            }
                            
                            // PDF阅读器
                            HighlightPDFReaderView(
                                pdfURL: pdfURL,
                                currentPage: $currentPage,
                                totalPages: $totalPages,
                                zoomScale: $zoomScale,
                                pdfDocument: $pdfDocument,
                                ttsService: ttsService
                            )
                        }
                    } else {
                        // 空状态 - 拖拽上传区域
                        VStack(spacing: 30) {
                            VStack(spacing: 16) {
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.blue)
                                
                                Text("拖拽PDF文件到此处")
                                    .font(.title2)
                                    .fontWeight(.medium)
                                
                                Text("或点击选择文件")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            
                            Button(action: { showingDocumentPicker = true }) {
                                HStack {
                                    Image(systemName: "folder.fill")
                                    Text("选择文件")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(8)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(UIColor.systemGroupedBackground))
                        .onDrop(of: ["public.file-url"], isTargeted: nil) { providers in
                            handleDrop(providers: providers)
                        }
                    }
                    
                    // 底部控制栏
                    if selectedPDF != nil {
                        HStack {
                            Button(action: previousPage) {
                                Image(systemName: "chevron.left")
                                    .font(.title2)
                            }
                            .disabled(currentPage <= 1)
                            
                            Spacer()
                            
                            Text("第 \(currentPage) 页 / 共 \(totalPages) 页")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button(action: nextPage) {
                                Image(systemName: "chevron.right")
                                    .font(.title2)
                            }
                            .disabled(currentPage >= totalPages)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(UIColor.systemBackground))
                        .shadow(radius: 1)
                    }
                }
            }
        }
        .background(Color(UIColor.systemBackground))
        .onAppear {
            if let pdfURL = selectedPDF {
                loadPDFDocument(url: pdfURL)
            }
        }
        .fileImporter(
            isPresented: $showingDocumentPicker,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    // 停止当前播放
                    ttsService.stopReading()
                    
                    // 设置新的PDF URL
                    selectedPDF = url
                    
                    // 重置PDF相关状态（选择新文件时需要重置）
                    currentPage = 1
                    totalPages = 0
                    zoomScale = 1.0
                    
                    // 加载新文档
                    loadPDFDocument(url: url)
                }
            case .failure(let error):
                print("Error selecting file: \(error)")
            }
        }
    }
    
    private func toggleReading() {
        if ttsService.isPlaying {
            if ttsService.isPaused {
                ttsService.resumeReading()
            } else {
                ttsService.pauseReading()
            }
        } else {
            startReading()
        }
    }
    
    private func startReading() {
        guard let document = pdfDocument else { 
            print("❌ PDF文档未加载")
            return 
        }
        
        print("🔍 开始获取第 \(currentPage) 页文本，总页数: \(document.pageCount)")
        print("📍 当前页面状态: currentPage=\(currentPage), totalPages=\(totalPages)")
        
        // 获取当前页面文本
        let pageIndex = currentPage - 1
        if let pageText = document.extractText(from: pageIndex), !pageText.isEmpty {
            print("✅ 成功获取第 \(currentPage) 页文本，长度: \(pageText.count) 字符")
            print("📝 文本预览: \(pageText.prefix(100))...")
            Task {
                await ttsService.startReading(text: pageText)
            }
        } else {
            print("❌ 无法获取当前页面文本")
            print("📊 当前页: \(currentPage), 页面索引: \(pageIndex), 总页数: \(document.pageCount)")
            
            // 尝试获取第一页作为fallback
            if let firstPageText = document.extractText(from: 0), !firstPageText.isEmpty {
                print("🔄 使用第一页文本作为fallback")
                Task {
                    await ttsService.startReading(text: firstPageText)
                }
            }
        }
    }
    
    private func stopReading() {
        ttsService.stopReading()
    }
    
    private func loadPDFDocument(url: URL) {
        if let document = PDFDocument(url: url) {
            pdfDocument = document
            totalPages = document.pageCount
            print("✅ PDF加载成功，共 \(totalPages) 页")
        } else {
            print("❌ PDF加载失败: \(url.path)")
            pdfDocument = nil
        }
    }
    
    // 获取朗读按钮图标（基于网页版逻辑）
    private func getReadingButtonIcon() -> String {
        if ttsService.isPlaying && ttsService.isPaused {
            return "play.circle.fill"  // 已暂停 -> 显示播放图标
        } else if ttsService.isPlaying {
            return "pause.circle.fill"  // 正在播放 -> 显示暂停图标
        } else {
            return "speaker.wave.2.fill"  // 未开始 -> 显示朗读图标
        }
    }
    
    // 获取朗读按钮颜色
    private func getReadingButtonColor() -> Color {
        if ttsService.isPlaying {
            return .orange
        } else {
            return .blue
        }
    }
    
    private func testTextExtraction() {
        guard let document = pdfDocument else { 
            print("❌ PDF文档未加载")
            return 
        }
        
        print("🔍 开始测试文本提取...")
        print("📚 PDF总页数: \(document.pageCount)")
        
        // 测试第10页（索引为9）
        let pageIndex = 9
        
        if pageIndex < document.pageCount {
            // 显示第10页的所有句子
            document.debugPageSentences(at: pageIndex)
            
            // 测试提取特定句子
            let sentences = document.getPageSentences(at: pageIndex)
            
            if sentences.count > 0 {
                print("\n🎯 测试提取第10页的句子:")
                
                // 提取第1句（索引0）
                if let firstSentence = document.getSentence(at: pageIndex, sentenceIndex: 0) {
                    print("第1句: \(firstSentence)")
                }
                
                // 提取第3句（索引2）
                if let thirdSentence = document.getSentence(at: pageIndex, sentenceIndex: 2) {
                    print("第3句: \(thirdSentence)")
                }
                
                // 提取句子范围（第2-4句）
                if let sentenceRange = document.getSentenceRange(at: pageIndex, from: 1, to: 3) {
                    print("第2-4句: \(sentenceRange)")
                    
                    // 测试TTS朗读这个句子范围
                    print("\n🎵 测试朗读句子范围...")
                    Task {
                        await ttsService.startReading(text: sentenceRange)
                    }
                }
            }
        } else {
            print("❌ 页面索引超出范围，PDF只有\(document.pageCount)页")
        }
    }
    
    private func previousPage() {
        if currentPage > 1 {
            currentPage -= 1
            print("⬅️  上一页: currentPage = \(currentPage)")
        }
    }
    
    private func nextPage() {
        if currentPage < totalPages {
            currentPage += 1
            print("➡️  下一页: currentPage = \(currentPage)")
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        DispatchQueue.main.async {
                            // 停止当前播放
                            ttsService.stopReading()
                            
                            // 设置新的PDF URL
                            selectedPDF = url
                            
                            // 重置PDF相关状态（选择新文件时需要重置）
                            currentPage = 1
                            totalPages = 0
                            zoomScale = 1.0
                            
                            // 加载新文档
                            loadPDFDocument(url: url)
                        }
                    }
                }
                return true
            }
        }
        return false
    }
}

#Preview {
    ContentView()
}

