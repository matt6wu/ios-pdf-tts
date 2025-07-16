//
//  PDFReaderView.swift
//  PDFtts
//
//  Created by Matt on 16/7/2025.
//

import SwiftUI
import PDFKit

struct PDFReaderView: UIViewRepresentable {
    let pdfURL: URL
    @Binding var currentPage: Int
    @Binding var totalPages: Int
    @Binding var zoomScale: CGFloat
    @Binding var isReading: Bool
    @Binding var readingProgress: Double
    @Binding var pdfDocument: PDFDocument?
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        
        // 配置PDFView
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.autoScales = true
        pdfView.backgroundColor = UIColor.systemGroupedBackground
        
        // 自适应缩放设置 - 更保守的范围
        pdfView.minScaleFactor = 0.1
        pdfView.maxScaleFactor = 5.0
        
        // 设置缩放模式为适应宽度
        pdfView.autoScales = true
        pdfView.scaleFactor = pdfView.scaleFactorForSizeToFit
        
        // 设置委托
        pdfView.delegate = context.coordinator
        
        // 加载PDF
        if let document = PDFDocument(url: pdfURL) {
            pdfView.document = document
            
            // 更新pdfDocument binding
            DispatchQueue.main.async {
                pdfDocument = document
                totalPages = document.pageCount
                if currentPage > totalPages {
                    currentPage = 1
                }
            }
            
            // 跳转到当前页
            if let page = document.page(at: currentPage - 1) {
                pdfView.go(to: page)
            }
            
            // 延迟设置自适应缩放，确保视图已完全加载
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                // 强制适应屏幕宽度
                let fitScale = pdfView.scaleFactorForSizeToFit
                pdfView.scaleFactor = fitScale * 0.95 // 稍微缩小5%确保不超出屏幕
                pdfView.autoScales = false // 临时禁用自动缩放
                
                // 再次启用自动缩放
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    pdfView.autoScales = true
                }
            }
        }
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        // 更新当前页
        if let document = pdfView.document,
           let page = document.page(at: currentPage - 1) {
            if pdfView.currentPage != page {
                pdfView.go(to: page)
            }
        }
        
        // 更新缩放
        if abs(pdfView.scaleFactor - zoomScale) > 0.1 {
            pdfView.scaleFactor = zoomScale
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PDFViewDelegate {
        var parent: PDFReaderView
        
        init(_ parent: PDFReaderView) {
            self.parent = parent
        }
        
        func pdfViewWillClick(onLink sender: PDFView, with url: URL) {
            // 处理PDF链接点击
            print("PDF链接被点击: \(url)")
        }
        
        func pdfViewDidChangeDocument(_ sender: PDFView) {
            // 文档改变时更新页数
            if let document = sender.document {
                DispatchQueue.main.async {
                    self.parent.totalPages = document.pageCount
                }
            }
        }
        
        func pdfViewDidChangePage(_ sender: PDFView) {
            // 页面改变时更新当前页
            if let document = sender.document,
               let currentPage = sender.currentPage {
                let pageIndex = document.index(for: currentPage)
                DispatchQueue.main.async {
                    self.parent.currentPage = pageIndex + 1
                }
            }
        }
        
        func pdfViewDidChangeScale(_ sender: PDFView) {
            // 缩放改变时更新缩放比例
            DispatchQueue.main.async {
                self.parent.zoomScale = sender.scaleFactor
            }
        }
    }
}

// 扩展PDFDocument以支持文本提取
extension PDFDocument {
    func extractText(from pageIndex: Int) -> String? {
        guard pageIndex >= 0 && pageIndex < pageCount else {
            print("❌ 页面索引无效: \(pageIndex), 总页数: \(pageCount)")
            return nil
        }
        
        guard let page = page(at: pageIndex) else {
            print("❌ 无法获取第 \(pageIndex) 页的PDFPage对象")
            return nil
        }
        
        let text = page.string
        print("🔍 提取第 \(pageIndex) 页文本: \(text?.count ?? 0) 字符")
        
        if let text = text, !text.isEmpty {
            print("📝 文本预览: \(text.prefix(100))...")
        } else {
            print("⚠️  页面文本为空或nil")
            
            // 检查PDF页面属性
            let bounds = page.bounds(for: .mediaBox)
            print("📄 页面尺寸: \(bounds.width) x \(bounds.height)")
            print("📄 页面旋转: \(page.rotation)")
            
            // 尝试其他方法获取文本
            if let attributedString = page.attributedString {
                let alternativeText = attributedString.string
                print("🔄 尝试属性字符串: \(alternativeText.count) 字符")
                if !alternativeText.isEmpty {
                    return alternativeText
                }
            }
            
            // 检查页面内容类型
            print("🔍 检查页面内容...")
            print("📊 页面标签: \(page.label ?? "无标签")")
            print("📊 页面显示盒子: \(page.displaysAnnotations ? "显示注释" : "不显示注释")")
        }
        
        return text
    }
    
    func extractAllText() -> String {
        var allText = ""
        for i in 0..<pageCount {
            if let pageText = extractText(from: i) {
                allText += pageText + "\n\n"
            }
        }
        return allText
    }
}