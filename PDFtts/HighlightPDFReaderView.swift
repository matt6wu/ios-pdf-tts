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
        pdfView.autoScales = true
        pdfView.backgroundColor = UIColor.systemGroupedBackground
        
        // 自适应缩放设置
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
            
            // 延迟设置自适应缩放
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                pdfView.autoScales = true
            }
        }
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: HighlightPDFView, context: Context) {
        // 确保使用相同的document对象
        if let document = pdfDocument, pdfView.document != document {
            pdfView.document = document
        }
        
        // 更新当前页
        if let document = pdfView.document,
           let page = document.page(at: max(0, currentPage - 1)) {
            if pdfView.currentPage != page {
                pdfView.go(to: page)
                print("📱 更新PDF视图到第 \(currentPage) 页")
            }
        }
        
        // 更新缩放
        if abs(pdfView.scaleFactor - zoomScale) > 0.1 {
            pdfView.scaleFactor = zoomScale
        }
        
        // 更新高亮
        pdfView.updateHighlight()
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
                DispatchQueue.main.async {
                    self.parent.totalPages = document.pageCount
                }
            }
        }
        
        func pdfViewDidChangePage(_ sender: PDFView) {
            print("🔄 pdfViewDidChangePage 被调用")
            if let document = sender.document,
               let currentPage = sender.currentPage {
                let pageIndex = document.index(for: currentPage)
                print("📖 页面变更: 从索引 \(pageIndex) 更新到第 \(pageIndex + 1) 页")
                DispatchQueue.main.async {
                    self.parent.currentPage = pageIndex + 1
                    print("✅ 页面状态已更新: currentPage = \(self.parent.currentPage)")
                }
            } else {
                print("❌ 无法获取文档或当前页面")
            }
        }
        
        func pdfViewDidChangeScale(_ sender: PDFView) {
            DispatchQueue.main.async {
                self.parent.zoomScale = sender.scaleFactor
            }
        }
    }
}

// 自定义PDFView支持文本高亮
class HighlightPDFView: PDFView {
    var ttsService: EnhancedTTSService?
    private var highlightOverlay: CALayer?
    private var currentHighlightedText: String = ""
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupHighlightOverlay()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHighlightOverlay()
        setupPageChangeNotification()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupHighlightOverlay()
        setupPageChangeNotification()
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
    }
    
    @objc private func pageDidChange() {
        print("📱 PDFView页面变更通知触发")
        // 通知委托
        if let delegate = self.delegate as? HighlightPDFReaderView.Coordinator {
            delegate.pdfViewDidChangePage(self)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func updateHighlight() {
        guard let ttsService = ttsService else { return }
        
        // 临时禁用高亮功能，后续可以优化
        hideHighlight()
        
        // TODO: 实现更精确的文本高亮功能
        // 目前先专注于基本的TTS功能
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
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPageText = pageText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 查找文本在页面中的位置
        if let range = cleanPageText.range(of: cleanText) {
            let nsRange = NSRange(range, in: cleanPageText)
            return nsRange
        }
        
        return nil
    }
    
    private func showHighlight(for range: NSRange, on page: PDFPage) {
        // 获取文本在页面中的边界框
        let selection = page.selection(for: range)
        
        if let selection = selection {
            let bounds = selection.bounds(for: page)
            
            // 将页面坐标转换为视图坐标
            let convertedBounds = convert(bounds, from: page)
            
            // 更新高亮层
            DispatchQueue.main.async {
                self.highlightOverlay?.frame = convertedBounds
                self.highlightOverlay?.isHidden = false
                
                // 添加动画效果
                let animation = CABasicAnimation(keyPath: "opacity")
                animation.fromValue = 0.0
                animation.toValue = 1.0
                animation.duration = 0.3
                self.highlightOverlay?.add(animation, forKey: "fadeIn")
            }
        }
    }
    
    private func hideHighlight() {
        DispatchQueue.main.async {
            self.highlightOverlay?.isHidden = true
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 重新计算高亮位置
        updateHighlight()
    }
    
    // 确保页面变更时通知委托
    override func go(to page: PDFPage) {
        super.go(to: page)
        
        // 手动触发页面变更通知
        if let delegate = self.delegate as? HighlightPDFReaderView.Coordinator {
            delegate.pdfViewDidChangePage(self)
        }
    }
}

// PDFPage扩展支持文本选择
extension PDFPage {
    func selection(for range: NSRange) -> PDFSelection? {
        guard let pageText = self.string else { return nil }
        
        let startIndex = pageText.index(pageText.startIndex, offsetBy: range.location)
        let endIndex = pageText.index(startIndex, offsetBy: range.length)
        let substring = String(pageText[startIndex..<endIndex])
        
        // 使用PDFPage的查找功能
        return self.selection(for: substring)
    }
    
    func selection(for text: String) -> PDFSelection? {
        // 在页面中查找文本并返回选择
        // 创建一个简单的选择对象
        guard let pageText = self.string,
              let document = self.document else { return nil }
        
        if let range = pageText.range(of: text) {
            let nsRange = NSRange(range, in: pageText)
            // 创建一个基本的选择对象
            return PDFSelection(document: document)
        }
        
        return nil
    }
}