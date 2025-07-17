//
//  ContentView.swift
//  PDFtts
//
//  Created by Matt on 16/7/2025.
//

import SwiftUI
import PDFKit

struct ContentView: View {
    @State private var selectedPDF: URL? = nil
    @State private var showingDocumentPicker = false
    @State private var sidebarVisible = false
    @State private var currentPage = 1
    @State private var totalPages = 0
    @State private var zoomScale: CGFloat = 0.8 // 默认稍微小一点确保适应屏幕
    @State private var localPDFPath: String = "" // 本地PDF路径
    @StateObject private var ttsService = EnhancedTTSService()
    @State private var pdfDocument: PDFDocument?
    @State private var showPageSlider = true // 控制滑块显示
    
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
                        
                        Text("MPDF")
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
                            .disabled(pdfDocument == nil)
                            
                            // 睡眠定时器按钮
                            Button(action: toggleSleepTimer) {
                                Image(systemName: getSleepTimerIcon())
                                    .font(.title2)
                                    .foregroundColor(getSleepTimerColor())
                            }
                            .disabled(pdfDocument == nil)
                            
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
                            // TTS控制界面
                            if ttsService.showTTSInterface {
                                ReadingProgressView(ttsService: ttsService, currentPage: currentPage)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                            }
                            
                            // 睡眠定时器界面
                            if ttsService.showSleepTimer {
                                SleepTimerView(ttsService: ttsService)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                            }
                            
                            // PDF阅读器 + 右侧滑块
                            ZStack(alignment: .trailing) {
                                // PDF阅读器
                                HighlightPDFReaderView(
                                    pdfURL: pdfURL,
                                    currentPage: $currentPage,
                                    totalPages: $totalPages,
                                    zoomScale: $zoomScale,
                                    pdfDocument: $pdfDocument,
                                    ttsService: ttsService
                                )
                                .onAppear {
                                    setupTTSCallbacks()
                                }
                                .onTapGesture(count: 2) {
                                    // 双击显示/隐藏滑块
                                    showPageSlider.toggle()
                                }
                                
                                // 右侧页面滑块 - 只在显示时出现
                                if totalPages > 1 && showPageSlider {
                                    VStack {
                                        Spacer()
                                        
                                        // 垂直滑块
                                        VStack(spacing: 0) {
                                            Slider(
                                                value: Binding(
                                                    get: { Double(totalPages - currentPage + 1) },
                                                    set: { newValue in
                                                        let newPage = totalPages - Int(newValue.rounded()) + 1
                                                        if newPage != currentPage {
                                                            currentPage = newPage
                                                        }
                                                    }
                                                ),
                                                in: 1...Double(totalPages),
                                                step: 1
                                            )
                                            .rotationEffect(.degrees(-90))
                                            .frame(width: 100, height: 100)
                                            .accentColor(.blue)
                                            
                                            // 页码显示
                                            Text("\(currentPage)/\(totalPages)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .padding(.top, 4)
                                        }
                                        .padding(.trailing, 8)
                                        .padding(.vertical, 20)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.secondary.opacity(0.1))
                                        )
                                        
                                        Spacer()
                                    }
                                    .transition(.opacity)
                                    .animation(.easeInOut(duration: 0.3), value: showPageSlider)
                                }
                            }
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
            allowsMultipleSelection: false,
            onCompletion: { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        // 请求文件访问权限
                        if url.startAccessingSecurityScopedResource() {
                            defer { url.stopAccessingSecurityScopedResource() }
                            
                            // 停止当前播放
                            ttsService.stopReading()
                            
                            // 尝试将文件复制到本地
                            if let localURL = copyPDFToLocal(url) {
                                selectedPDF = localURL
                                localPDFPath = localURL.path
                                print("📁 使用本地PDF: \(localURL.path)")
                            } else {
                                selectedPDF = url
                                localPDFPath = ""
                                print("📁 使用原始PDF: \(url.path)")
                            }
                            
                            // 重置PDF相关状态（选择新文件时需要重置）
                            currentPage = 1
                            totalPages = 0
                            zoomScale = 0.8
                            
                            // 加载新文档
                            loadPDFDocument(url: selectedPDF!)
                            
                            // 保存新的阅读状态
                            saveReadingState()
                        } else {
                            print("❌ 无法访问文件: \(url)")
                        }
                    }
                case .failure(let error):
                    print("❌ 文件选择失败: \(error)")
                }
            }
        )
        .onAppear {
            // 应用启动时恢复阅读状态
            restoreReadingState()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            // 应用即将进入后台时保存状态
            saveReadingState()
            print("📱 应用即将进入后台，保存状态")
        }
        .onChange(of: currentPage) { newPage in
            // 页面变化时保存状态
            print("📖 页面变化: \(newPage)，正在保存状态...")
            saveReadingState()
        }
    }
    
    private func toggleReading() {
        if ttsService.showTTSInterface {
            print("🎛️ 关闭TTS界面")
            ttsService.hideTTSControls()
        } else {
            print("🎛️ 启动TTS界面")
            ttsService.showTTSControls()
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
    
    // 设置TTS服务的PDF控制回调
    private func setupTTSCallbacks() {
        ttsService.onPageChange = { newPage in
            DispatchQueue.main.async {
                currentPage = newPage
            }
        }
        
        ttsService.getCurrentPage = {
            return currentPage
        }
        
        ttsService.getTotalPages = {
            return totalPages
        }
        
        ttsService.getPageText = { pageNumber in
            guard let document = pdfDocument else {
                print("❌ PDF文档未加载")
                return nil
            }
            
            let pageIndex = pageNumber - 1
            print("📖 获取第 \(pageNumber) 页文本 (索引: \(pageIndex))")
            let text = document.extractText(from: pageIndex)
            print("📝 获取到的文本长度: \(text?.count ?? 0)")
            if let text = text, !text.isEmpty {
                print("📝 文本预览: \(text.prefix(100))...")
            }
            return text
        }
        
        print("✅ TTS回调函数已设置")
    }
    
    private func loadPDFDocument(url: URL) {
        print("🔄 开始加载PDF: \(url.path)")
        
        // 检查文件是否存在
        if !FileManager.default.fileExists(atPath: url.path) {
            print("❌ 文件不存在: \(url.path)")
            return
        }
        
        // 尝试加载PDF文档
        if let document = PDFDocument(url: url) {
            pdfDocument = document
            totalPages = document.pageCount
            print("✅ PDF加载成功，共 \(totalPages) 页")
            
            // 检查文档是否可以读取
            if document.isLocked {
                print("⚠️  PDF文档被锁定，可能需要密码")
            }
        } else {
            print("❌ PDF加载失败: \(url.path)")
            print("📋 尝试的URL: \(url)")
            
            // 检查资源是否可访问
            do {
                let isReachable = try url.checkResourceIsReachable()
                print("📋 URL是否可访问: \(isReachable)")
            } catch {
                print("📋 检查资源可访问性失败: \(error)")
            }
            
            pdfDocument = nil
        }
    }
    
    // MARK: - 状态保存和恢复
    private func saveReadingState() {
        guard let pdfPath = localPDFPath.isEmpty ? selectedPDF?.path : localPDFPath else { 
            print("⚠️ 无法保存状态：PDF路径为空")
            return 
        }
        
        UserDefaults.standard.set(pdfPath, forKey: "LastPDFPath")
        UserDefaults.standard.set(currentPage, forKey: "LastCurrentPage")
        UserDefaults.standard.set(totalPages, forKey: "LastTotalPages")
        UserDefaults.standard.set(zoomScale, forKey: "LastZoomScale")
        
        print("📚 已保存阅读状态: \(pdfPath) 第\(currentPage)页/共\(totalPages)页")
    }
    
    private func restoreReadingState() {
        guard let savedPath = UserDefaults.standard.string(forKey: "LastPDFPath") else { 
            print("📚 没有保存的阅读状态，加载默认PDF")
            // 如果没有保存的状态，加载默认PDF
            if let defaultPDF = Bundle.main.url(forResource: "today", withExtension: "pdf") {
                selectedPDF = defaultPDF
                loadPDFDocument(url: defaultPDF)
            }
            return 
        }
        
        let savedPage = UserDefaults.standard.integer(forKey: "LastCurrentPage")
        let savedTotal = UserDefaults.standard.integer(forKey: "LastTotalPages")
        let savedZoom = UserDefaults.standard.double(forKey: "LastZoomScale")
        
        print("📚 尝试恢复阅读状态:")
        print("   - 路径: \(savedPath)")
        print("   - 页数: \(savedPage)")
        print("   - 总页数: \(savedTotal)")
        print("   - 缩放: \(savedZoom)")
        
        // 检查本地文件是否存在
        if FileManager.default.fileExists(atPath: savedPath) {
            let url = URL(fileURLWithPath: savedPath)
            selectedPDF = url
            localPDFPath = savedPath
            currentPage = savedPage > 0 ? savedPage : 1
            totalPages = savedTotal
            zoomScale = savedZoom > 0 ? CGFloat(savedZoom) : 0.8
            
            loadPDFDocument(url: url)
            print("📚 已恢复阅读状态: \(savedPath) 第\(currentPage)页/共\(totalPages)页")
        } else {
            print("❌ 保存的PDF文件不存在: \(savedPath)")
            // 文件不存在，清除保存的状态
            UserDefaults.standard.removeObject(forKey: "LastPDFPath")
            UserDefaults.standard.removeObject(forKey: "LastCurrentPage")
            UserDefaults.standard.removeObject(forKey: "LastTotalPages")
            UserDefaults.standard.removeObject(forKey: "LastZoomScale")
            
            // 加载默认PDF
            if let defaultPDF = Bundle.main.url(forResource: "today", withExtension: "pdf") {
                selectedPDF = defaultPDF
                loadPDFDocument(url: defaultPDF)
            }
        }
    }
    
    private func copyPDFToLocal(_ sourceURL: URL) -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = sourceURL.lastPathComponent
        let destinationURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            // 如果目标文件已存在，先删除
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            // 复制文件
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            print("📁 PDF已复制到本地: \(destinationURL.path)")
            return destinationURL
        } catch {
            print("❌ 复制PDF失败: \(error)")
            return nil
        }
    }
    
    private func toggleSleepTimer() {
        if ttsService.showSleepTimer {
            ttsService.hideSleepTimerControls()
        } else {
            ttsService.showSleepTimerControls()
        }
    }
    
    private func getSleepTimerIcon() -> String {
        if ttsService.sleepTimer > 0 {
            return "clock.fill"
        } else {
            return "clock"
        }
    }
    
    private func getSleepTimerColor() -> Color {
        if ttsService.sleepTimer > 0 {
            return .purple
        } else if ttsService.showSleepTimer {
            return .orange
        } else {
            return .gray
        }
    }
    
    // 获取TTS界面启动按钮图标
    private func getReadingButtonIcon() -> String {
        return "speaker.wave.2.fill"  // 始终显示朗读图标，表示启动TTS界面
    }
    
    // 获取TTS界面启动按钮颜色
    private func getReadingButtonColor() -> Color {
        return ttsService.showTTSInterface ? .orange : .blue
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
                            
                            // 尝试将文件复制到本地
                            if let localURL = copyPDFToLocal(url) {
                                selectedPDF = localURL
                                localPDFPath = localURL.path
                                print("📁 使用本地PDF: \(localURL.path)")
                            } else {
                                selectedPDF = url
                                localPDFPath = ""
                                print("📁 使用原始PDF: \(url.path)")
                            }
                            
                            // 重置PDF相关状态（选择新文件时需要重置）
                            currentPage = 1
                            totalPages = 0
                            zoomScale = 0.8
                            
                            // 加载新文档
                            loadPDFDocument(url: selectedPDF!)
                            
                            // 保存新的阅读状态
                            saveReadingState()
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

