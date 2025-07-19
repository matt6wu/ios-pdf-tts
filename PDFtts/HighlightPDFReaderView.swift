//
//  HighlightPDFReaderView.swift
//  PDFtts
//
//  Created by Matt on 16/7/2025.
//

import SwiftUI
import PDFKit

struct HighlightPDFReaderView: UIViewRepresentable {
    let pdfURL: URL
    @Binding var currentPage: Int
    @Binding var totalPages: Int
    @Binding var zoomScale: CGFloat
    @Binding var pdfDocument: PDFDocument?
    @ObservedObject var ttsService: EnhancedTTSService
    
    func makeUIView(context: Context) -> HighlightPDFView {
        let pdfView = HighlightPDFView()
        
        // 配置PDFView
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = UIColor.systemGroupedBackground
        
        // 禁用自动缩放，让用户控制缩放
        pdfView.autoScales = false
        
        // 设置缩放范围
        pdfView.minScaleFactor = 0.25
        pdfView.maxScaleFactor = 5.0
        
        // 设置委托
        pdfView.delegate = context.coordinator
        
        // 设置TTS服务
        pdfView.ttsService = ttsService
        
        // 加载PDF
        if let document = pdfDocument ?? PDFDocument(url: pdfURL) {
            pdfView.document = document
            
            // 更新pdfDocument binding（如果还没有设置）
            if pdfDocument == nil {
                DispatchQueue.main.async {
                    pdfDocument = document
                    totalPages = document.pageCount
                    if currentPage > totalPages {
                        currentPage = 1
                    }
                }
            }
            
            // 跳转到当前页
            if let page = document.page(at: max(0, currentPage - 1)) {
                pdfView.go(to: page)
            }
            
            // 设置初始缩放为屏幕宽度的90%
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak pdfView] in
                guard let pdfView = pdfView else { return }
                let fitScale = pdfView.scaleFactorForSizeToFit
                let targetScale = fitScale * 0.9 // 90%屏幕宽度
                pdfView.scaleFactor = targetScale
                zoomScale = targetScale
                
                // 确保初始页面绑定正确
                if let currentPDFPage = pdfView.currentPage,
                   let pageIndex = pdfView.document?.index(for: currentPDFPage) {
                    let actualPageNumber = pageIndex + 1
                    if currentPage != actualPageNumber {
                        DispatchQueue.main.async {
                            currentPage = actualPageNumber
                            print("📱 初始页面同步: currentPage = \(actualPageNumber)")
                        }
                    }
                }
            }
        }
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: HighlightPDFView, context: Context) {
        // 确保使用相同的document对象
        if let document = pdfDocument, pdfView.document != document {
            pdfView.document = document
        }
        
        // 简单的页面跳转 - 避免复杂的委托管理
        if let document = pdfView.document,
           let targetPage = document.page(at: max(0, currentPage - 1)) {
            if pdfView.currentPage != targetPage {
                pdfView.go(to: targetPage)
            }
        }
        
        // 移除自动缩放更新 - 让用户完全控制缩放
        // 注释掉这个逻辑，防止用户缩放被重置
        // if abs(pdfView.scaleFactor - zoomScale) > 0.01 {
        //     pdfView.scaleFactor = zoomScale
        // }
        
        // 文本变化时立即更新高亮位置（不延迟）
        let currentText = ttsService.currentReadingText
        if pdfView.currentHighlightedText != currentText {
            print("🎵 新段落播放，立即更新高亮位置")
            pdfView.updateHighlight()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PDFViewDelegate {
        var parent: HighlightPDFReaderView
        
        init(_ parent: HighlightPDFReaderView) {
            self.parent = parent
        }
        
        func pdfViewDidChangeDocument(_ sender: PDFView) {
            if let document = sender.document {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.parent.totalPages = document.pageCount
                    
                    // 立即同步当前页面
                    if let currentPDFPage = sender.currentPage {
                        let pageIndex = document.index(for: currentPDFPage)
                        let actualPageNumber = pageIndex + 1
                        if self.parent.currentPage != actualPageNumber {
                            self.parent.currentPage = actualPageNumber
                            print("📚 文档加载完成，页面同步: currentPage = \(actualPageNumber)")
                        }
                    }
                }
            }
        }
        
        func pdfViewDidChangePage(_ sender: PDFView) {
            print("🔄 pdfViewDidChangePage 被调用")
            if let document = sender.document,
               let currentPage = sender.currentPage {
                let pageIndex = document.index(for: currentPage)
                let newPageNumber = pageIndex + 1
                print("📖 页面变更: 从索引 \(pageIndex) 更新到第 \(newPageNumber) 页")
                
                // 防止重复更新相同页面
                if self.parent.currentPage != newPageNumber {
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.parent.currentPage = newPageNumber
                        print("✅ 页面状态已更新: currentPage = \(self.parent.currentPage)")
                    }
                } else {
                    print("📄 页面相同，跳过更新")
                }
            } else {
                print("❌ 无法获取文档或当前页面")
            }
        }
        
        func pdfViewDidChangeScale(_ sender: PDFView) {
            // 只在缩放变化较大时更新，避免微小变化导致的循环更新
            if abs(self.parent.zoomScale - sender.scaleFactor) > 0.01 {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.parent.zoomScale = sender.scaleFactor
                    print("🔍 缩放更新: \(sender.scaleFactor)")
                }
            }
        }
    }
}

// 自定义PDFView支持文本高亮
class HighlightPDFView: PDFView {
    var ttsService: EnhancedTTSService?
    private var highlightOverlay: CALayer?
    var currentHighlightedText: String = ""
    private var highlightUpdateTimer: Timer? // 延迟更新定时器
    var autoScrollToHighlight: Bool = true // 控制是否自动滚动到高亮位置
    var autoResetZoomAndCenter: Bool = true // 新段落时重置缩放并居中
    private let defaultZoomScale: CGFloat = 1.0 // 默认缩放比例（适合阅读的舒适比例）
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupHighlightOverlay()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHighlightOverlay()
        setupPageChangeNotification()
        setupTTSObserver()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupHighlightOverlay()
        setupPageChangeNotification()
        setupTTSObserver()
    }
    
    private func setupHighlightOverlay() {
        // 创建高亮层
        highlightOverlay = CALayer()
        highlightOverlay?.backgroundColor = UIColor.yellow.withAlphaComponent(0.3).cgColor
        highlightOverlay?.cornerRadius = 4
        highlightOverlay?.isHidden = true
        
        if let overlay = highlightOverlay {
            self.layer.addSublayer(overlay)
        }
    }
    
    private func setupPageChangeNotification() {
        // 监听页面变更通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pageDidChange),
            name: .PDFViewPageChanged,
            object: self
        )
        
        // 监听视图变化通知（缩放、滚动等）
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(viewDidChange),
            name: .PDFViewVisiblePagesChanged,
            object: self
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(viewDidChange),
            name: .PDFViewScaleChanged,
            object: self
        )
    }
    
    private func setupTTSObserver() {
        // 使用更精确的观察者模式，避免闪烁
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] timer in
            guard let self = self, let ttsService = self.ttsService else {
                timer.invalidate()
                return
            }
            
            let currentText = ttsService.currentReadingText
            // 只有当文本真正改变时才立即更新（文本变化时不延迟）
            if currentText != self.currentHighlightedText {
                print("⏰ Timer检测到文本变化，立即更新高亮")
                DispatchQueue.main.async {
                    self.updateHighlight()
                }
            }
        }
    }
    
    @objc private func pageDidChange() {
        print("📱 PDFView页面变更通知触发")
        // 通知委托
        if let delegate = self.delegate as? HighlightPDFReaderView.Coordinator {
            delegate.pdfViewDidChangePage(self)
        }
        
        // 页面变化时重新计算高亮
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            if let self = self, !self.currentHighlightedText.isEmpty && self.ttsService?.isPlaying == true {
                self.forceUpdateHighlightPosition()
            }
        }
    }
    
    @objc private func viewDidChange() {
        print("📱 PDFView视图变化通知触发")
        // 取消之前的定时器
        highlightUpdateTimer?.invalidate()
        
        // 设置1秒延迟后重新计算高亮
        highlightUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                if let self = self, !self.currentHighlightedText.isEmpty && self.ttsService?.isPlaying == true {
                    print("🔄 延迟重新计算高亮位置")
                    self.forceUpdateHighlightPosition()
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        highlightUpdateTimer?.invalidate() // 清理定时器
    }
    
    func updateHighlight() {
        guard let ttsService = ttsService else { return }
        
        // 获取当前正在朗读的文本
        let currentText = ttsService.currentReadingText
        
        // 避免重复更新相同文本
        if currentText == currentHighlightedText {
            return
        }
        
        let isNewSegment = !currentHighlightedText.isEmpty && currentText != currentHighlightedText
        currentHighlightedText = currentText
        
        if !currentText.isEmpty && ttsService.isPlaying {
            print("🎯 更新高亮到新文本: \(currentText.prefix(30))...")
            
            // 如果是新段落且启用了自动重置，先重置缩放和位置
            if isNewSegment && autoResetZoomAndCenter {
                resetZoomAndCenterHighlight(text: currentText)
            } else {
                highlightCurrentSentence(currentText)
            }
        } else {
            hideHighlight()
        }
    }
    
    // 强制更新高亮位置（用于视图变化后重新定位）
    func forceUpdateHighlightPosition() {
        guard let ttsService = ttsService else { return }
        let currentText = ttsService.currentReadingText
        
        if !currentText.isEmpty && ttsService.isPlaying {
            print("🔄 强制重新定位高亮位置")
            highlightCurrentSentence(currentText)
        } else {
            hideHighlight()
        }
    }
    
    // 重置缩放并居中高亮
    private func resetZoomAndCenterHighlight(text: String) {
        print("🔄 新段落开始：重置缩放并居中高亮")
        
        // 先设置固定缩放比例
        UIView.animate(withDuration: 0.5, animations: {
            self.scaleFactor = self.defaultZoomScale
        }) { _ in
            // 缩放完成后，查找文本位置并居中
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.highlightAndCenterText(text)
            }
        }
    }
    
    // 高亮文本并居中显示
    private func highlightAndCenterText(_ text: String) {
        guard !text.isEmpty,
              let currentPage = self.currentPage,
              let pageText = currentPage.string else {
            hideHighlight()
            return
        }
        
        // 查找文本范围
        if let textRange = findTextRange(text: text, in: pageText, on: currentPage) {
            // 获取文本选择和边界
            if let selection = currentPage.selection(for: textRange) {
                let bounds = selection.bounds(for: currentPage)
                let convertedBounds = convert(bounds, from: currentPage)
                
                // 更新高亮显示
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.highlightOverlay?.frame = convertedBounds
                    self.highlightOverlay?.isHidden = false
                    
                    // 将高亮区域居中显示
                    self.centerHighlightInView(highlightFrame: convertedBounds)
                    
                    // 添加动画效果
                    let animation = CABasicAnimation(keyPath: "opacity")
                    animation.fromValue = 0.0
                    animation.toValue = 1.0
                    animation.duration = 0.3
                    self.highlightOverlay?.add(animation, forKey: "fadeIn")
                }
            }
        } else {
            hideHighlight()
        }
    }
    
    // 将高亮区域居中显示在屏幕中
    private func centerHighlightInView(highlightFrame: CGRect) {
        let viewBounds = self.bounds
        let viewCenter = CGPoint(x: viewBounds.midX, y: viewBounds.midY)
        let highlightCenter = CGPoint(x: highlightFrame.midX, y: highlightFrame.midY)
        
        // 计算需要滚动的偏移量，使高亮居中
        let offsetX = highlightCenter.x - viewCenter.x
        let offsetY = highlightCenter.y - viewCenter.y
        
        // 查找内部的滚动视图并调整位置
        for subview in self.subviews {
            if let scrollView = subview as? UIScrollView {
                let currentOffset = scrollView.contentOffset
                let targetOffset = CGPoint(
                    x: currentOffset.x + offsetX,
                    y: currentOffset.y + offsetY
                )
                
                print("🎯 居中高亮: 当前偏移 \(currentOffset) → 目标偏移 \(targetOffset)")
                
                UIView.animate(withDuration: 0.8, delay: 0, options: [.curveEaseInOut], animations: {
                    scrollView.setContentOffset(targetOffset, animated: false)
                }, completion: { _ in
                    print("✅ 高亮居中完成")
                })
                break
            }
        }
    }
    
    private func highlightCurrentSentence(_ text: String) {
        guard !text.isEmpty,
              let currentPage = self.currentPage,
              let pageText = currentPage.string else {
            hideHighlight()
            return
        }
        
        // 在PDF页面中查找文本位置
        if let textRange = findTextRange(text: text, in: pageText, on: currentPage) {
            showHighlight(for: textRange, on: currentPage)
        } else {
            hideHighlight()
        }
    }
    
    private func findTextRange(text: String, in pageText: String, on page: PDFPage) -> NSRange? {
        // 格式化文本以提高匹配成功率
        let normalizedText = normalizeText(text)
        let normalizedPageText = normalizeText(pageText)
        
        // 1. 尝试精确匹配整个文本
        if let range = normalizedPageText.range(of: normalizedText) {
            return convertRangeToOriginal(range, in: normalizedPageText, original: pageText)
        }
        
        // 2. 尝试匹配文本的开头部分，然后扩展到段落
        let searchLength = min(normalizedText.count, 100) // 取前100个字符作为搜索起点
        let searchText = String(normalizedText.prefix(searchLength))
        
        if let startRange = normalizedPageText.range(of: searchText) {
            // 找到起始位置后，尝试扩展到整个段落
            let startIndex = startRange.lowerBound
            let expandedRange = expandToParagraph(from: startRange, in: normalizedPageText, originalText: normalizedText)
            return convertRangeToOriginal(expandedRange, in: normalizedPageText, original: pageText)
        }
        
        // 3. 尝试模糊匹配（移除所有空白符）
        let compactText = normalizedText.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
        let compactPageText = normalizedPageText.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
        
        if compactText.count >= 20 {
            let searchCompactText = String(compactText.prefix(50))
            if let range = compactPageText.range(of: searchCompactText) {
                // 在原始文本中扩展到段落
                let originalRange = convertRangeToOriginal(range, in: compactPageText, original: pageText)
                if let origRange = originalRange {
                    let expandedRange = expandToParagraphInOriginal(from: origRange, in: pageText)
                    return expandedRange
                }
            }
        }
        
        return nil
    }
    
    // 扩展到整个段落的辅助函数
    private func expandToParagraph(from range: Range<String.Index>, in text: String, originalText: String) -> Range<String.Index> {
        let startIndex = range.lowerBound
        let endIndex = range.upperBound
        
        // 向前扩展到句子开始（寻找句号、换行或段落开始）
        var expandedStart = startIndex
        var currentIndex = startIndex
        while currentIndex > text.startIndex {
            currentIndex = text.index(before: currentIndex)
            let char = text[currentIndex]
            if char == "." || char == "。" || char == "\n" || char == "\r" {
                expandedStart = text.index(after: currentIndex)
                break
            }
            expandedStart = currentIndex
        }
        
        // 向后扩展：优先匹配原始文本长度，或扩展到段落结束
        var expandedEnd = endIndex
        let targetLength = min(originalText.count, 500) // 限制最大高亮长度为500字符
        let currentLength = text.distance(from: expandedStart, to: endIndex)
        
        if currentLength < targetLength {
            currentIndex = endIndex
            while currentIndex < text.endIndex && text.distance(from: expandedStart, to: currentIndex) < targetLength {
                let char = text[currentIndex]
                expandedEnd = currentIndex
                if char == "." || char == "。" || char == "\n" || char == "\r" {
                    // 如果已经接近目标长度，就在句子结束处停止
                    if text.distance(from: expandedStart, to: currentIndex) > targetLength * 3/4 {
                        break
                    }
                }
                currentIndex = text.index(after: currentIndex)
            }
        }
        
        return expandedStart..<expandedEnd
    }
    
    // 在原始文本中扩展到段落
    private func expandToParagraphInOriginal(from range: NSRange, in text: String) -> NSRange {
        let nsString = text as NSString
        let startLocation = max(0, range.location)
        let endLocation = min(nsString.length, range.location + range.length)
        
        // 向前扩展
        var expandedStart = startLocation
        for i in stride(from: startLocation, through: 0, by: -1) {
            let char = nsString.character(at: i)
            if char == 46 || char == 12290 || char == 10 || char == 13 { // '.', '。', '\n', '\r'
                expandedStart = i + 1
                break
            }
            expandedStart = i
        }
        
        // 向后扩展（限制在合理范围内）
        var expandedEnd = endLocation
        let maxLength = min(500, nsString.length - expandedStart) // 最大扩展500字符
        for i in endLocation..<min(nsString.length, expandedStart + maxLength) {
            let char = nsString.character(at: i)
            expandedEnd = i
            if char == 46 || char == 12290 || char == 10 || char == 13 { // '.', '。', '\n', '\r'
                // 如果已经扩展了足够长度，在句子结束处停止
                if (i - expandedStart) > maxLength * 3/4 {
                    break
                }
            }
        }
        
        return NSRange(location: expandedStart, length: expandedEnd - expandedStart)
    }
    
    private func normalizeText(_ text: String) -> String {
        return text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\r\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
    
    private func convertRangeToOriginal(_ range: Range<String.Index>, in normalized: String, original: String) -> NSRange? {
        // 简化版本：直接使用归一化文本的范围
        // 更精确的实现需要追踪字符映射，但对于基本高亮功能这已经足够
        return NSRange(range, in: normalized)
    }
    
    private func showHighlight(for range: NSRange, on page: PDFPage) {
        // 获取文本在页面中的边界框
        let selection = page.selection(for: range)
        
        if let selection = selection {
            let bounds = selection.bounds(for: page)
            
            // 确保边界框有效
            guard bounds.width > 0 && bounds.height > 0 else {
                print("⚠️ 无效的高亮边界框: \(bounds)")
                hideHighlight()
                return
            }
            
            // 将页面坐标转换为视图坐标
            let convertedBounds = convert(bounds, from: page)
            
            print("📍 高亮位置 - 页面坐标: \(bounds), 视图坐标: \(convertedBounds)")
            
            // 更新高亮层
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // 确保转换后的坐标仍然有效
                guard convertedBounds.width > 0 && convertedBounds.height > 0 else {
                    print("⚠️ 转换后的高亮边界框无效: \(convertedBounds)")
                    self.hideHighlight()
                    return
                }
                
                self.highlightOverlay?.frame = convertedBounds
                self.highlightOverlay?.isHidden = false
                
                // 检查高亮是否在可视区域内，如果不在则自动滚动（如果启用且不是居中模式）
                if self.autoScrollToHighlight && !self.autoResetZoomAndCenter {
                    self.ensureHighlightVisible(highlightFrame: convertedBounds)
                }
                
                // 只在高亮层首次显示或位置显著变化时添加动画
                if let overlay = self.highlightOverlay {
                    let previousFrame = overlay.frame
                    let significantChange = abs(convertedBounds.origin.x - previousFrame.origin.x) > 10 ||
                                          abs(convertedBounds.origin.y - previousFrame.origin.y) > 10
                    
                    if overlay.isHidden || significantChange {
                        let animation = CABasicAnimation(keyPath: "opacity")
                        animation.fromValue = 0.0
                        animation.toValue = 1.0
                        animation.duration = 0.2
                        overlay.add(animation, forKey: "fadeIn")
                    }
                }
            }
        } else {
            print("⚠️ 无法创建文本选择，隐藏高亮")
            hideHighlight()
        }
    }
    
    private func hideHighlight() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.highlightOverlay?.isHidden = true
        }
    }
    
    // 确保高亮区域在可视范围内
    private func ensureHighlightVisible(highlightFrame: CGRect) {
        let visibleRect = self.bounds // 使用视图边界
        let margin: CGFloat = 100 // 边距
        
        // 检查高亮是否基本在可视区域内（允许部分超出）
        let expandedVisible = visibleRect.insetBy(dx: -margin, dy: -margin)
        if expandedVisible.intersects(highlightFrame) && 
           highlightFrame.minY >= visibleRect.minY - margin &&
           highlightFrame.maxY <= visibleRect.maxY + margin {
            print("✅ 高亮在可视区域内")
            return
        }
        
        print("📍 高亮超出可视区域，自动滚动")
        print("   可视区域: \(visibleRect)")
        print("   高亮区域: \(highlightFrame)")
        
        // 计算目标矩形，确保高亮在视图中央偏上位置
        let targetRect = CGRect(
            x: max(0, highlightFrame.origin.x - 50), // 左边距
            y: max(0, highlightFrame.origin.y - visibleRect.height * 0.3), // 放在视图上方30%位置
            width: min(visibleRect.width, highlightFrame.width + 100), // 适当宽度
            height: min(visibleRect.height, highlightFrame.height + 200) // 适当高度
        )
        
        print("🔄 滚动到目标区域: \(targetRect)")
        
        // 使用平滑滚动 - 调用父类UIScrollView的方法
        DispatchQueue.main.async {
            // 查找内部的滚动视图并滚动
            for subview in self.subviews {
                if let scrollView = subview as? UIScrollView {
                    let currentOffset = scrollView.contentOffset
                    let targetOffset = CGPoint(
                        x: targetRect.origin.x,
                        y: targetRect.origin.y
                    )
                    
                    UIView.animate(withDuration: 0.6, delay: 0, options: [.curveEaseInOut], animations: {
                        scrollView.setContentOffset(targetOffset, animated: false)
                    }, completion: { _ in
                        print("✅ 自动滚动完成")
                    })
                    break
                }
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 当视图布局改变时，延迟重新计算高亮位置
        if !currentHighlightedText.isEmpty && ttsService?.isPlaying == true {
            // 取消之前的定时器
            highlightUpdateTimer?.invalidate()
            
            // 延迟0.5秒重新计算（layoutSubviews调用频繁，使用较短延迟）
            highlightUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                DispatchQueue.main.async {
                    if let self = self, !self.currentHighlightedText.isEmpty && self.ttsService?.isPlaying == true {
                        print("📐 布局完成，延迟重新计算高亮位置")
                        self.forceUpdateHighlightPosition()
                    }
                }
            }
        }
    }
    
    // 重写缩放方法，确保高亮跟随缩放
    override var scaleFactor: CGFloat {
        didSet {
            // 取消之前的定时器
            highlightUpdateTimer?.invalidate()
            
            // 缩放改变时延迟1秒重新计算高亮位置
            highlightUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
                DispatchQueue.main.async {
                    if let self = self, !self.currentHighlightedText.isEmpty && self.ttsService?.isPlaying == true {
                        print("🔍 缩放完成，延迟重新计算高亮位置")
                        self.forceUpdateHighlightPosition()
                    }
                }
            }
        }
    }
    
    // 重写页面跳转方法，确保高亮跟随页面变化
    override func go(to page: PDFPage) {
        super.go(to: page)
        
        // 页面跳转后重新计算高亮位置
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            if let self = self, !self.currentHighlightedText.isEmpty && self.ttsService?.isPlaying == true {
                self.forceUpdateHighlightPosition()
            }
        }
    }
}

// PDFPage扩展支持文本选择
extension PDFPage {
    func selection(for range: NSRange) -> PDFSelection? {
        guard let pageText = self.string,
              range.location >= 0,
              range.location + range.length <= pageText.count else { return nil }
        
        // 确保范围有效
        let startIndex = pageText.index(pageText.startIndex, offsetBy: range.location)
        let endIndex = pageText.index(startIndex, offsetBy: range.length)
        let substring = String(pageText[startIndex..<endIndex])
        
        // 使用PDFPage的查找功能
        return self.selection(for: substring)
    }
    
    func selection(for text: String) -> PDFSelection? {
        guard self.string != nil,
              !text.isEmpty else { return nil }
        
        // 尝试在页面中查找文本
        let selections = self.selections(for: text)
        
        // 返回第一个匹配的选择
        return selections.first
    }
    
    private func selections(for text: String) -> [PDFSelection] {
        var selections: [PDFSelection] = []
        
        // 使用PDFDocument的搜索功能
        guard let document = self.document else { return selections }
        
        let searchOptions: NSString.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        let foundSelections = document.findString(text, withOptions: searchOptions)
        
        // 过滤出当前页面的选择
        for selection in foundSelections {
            if selection.pages.contains(self) {
                selections.append(selection)
            }
        }
        
        return selections
    }
}