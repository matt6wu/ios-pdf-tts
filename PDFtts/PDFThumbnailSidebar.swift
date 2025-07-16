//
//  PDFThumbnailSidebar.swift
//  PDFtts
//
//  Created by Matt on 16/7/2025.
//

import SwiftUI
import PDFKit

struct PDFThumbnailSidebar: View {
    let pdfURL: URL?
    @Binding var currentPage: Int
    @Binding var totalPages: Int
    @State private var pdfDocument: PDFDocument?
    @State private var thumbnails: [UIImage] = []
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题
            HStack {
                Text("页面导航")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(UIColor.systemBackground))
            
            Divider()
            
            // 缩略图列表
            if !thumbnails.isEmpty {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(0..<thumbnails.count, id: \.self) { index in
                                ThumbnailRow(
                                    thumbnail: thumbnails[index],
                                    pageNumber: index + 1,
                                    isSelected: currentPage == index + 1
                                ) {
                                    currentPage = index + 1
                                }
                                .id(index + 1)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                    }
                    .onChange(of: currentPage) { newPage in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(newPage, anchor: .center)
                        }
                    }
                }
            } else if pdfURL != nil {
                // 加载状态
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    
                    Text("正在生成缩略图...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // 空状态
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    
                    Text("未选择PDF文件")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(UIColor.secondarySystemBackground))
        .onChange(of: pdfURL) { newURL in
            loadPDF(url: newURL)
        }
        .onAppear {
            loadPDF(url: pdfURL)
        }
    }
    
    private func loadPDF(url: URL?) {
        guard let url = url else {
            pdfDocument = nil
            thumbnails = []
            return
        }
        
        isLoading = true
        
        Task {
            let document = PDFDocument(url: url)
            let pageCount = document?.pageCount ?? 0
            var newThumbnails: [UIImage] = []
            
            for i in 0..<pageCount {
                if let page = document?.page(at: i) {
                    let thumbnail = await generateThumbnail(for: page)
                    newThumbnails.append(thumbnail)
                }
            }
            
            await MainActor.run {
                self.pdfDocument = document
                self.thumbnails = newThumbnails
                self.totalPages = pageCount
                self.isLoading = false
            }
        }
    }
    
    private func generateThumbnail(for page: PDFPage) async -> UIImage {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let pageSize = page.bounds(for: .mediaBox)
                let scale: CGFloat = 150.0 / max(pageSize.width, pageSize.height)
                let scaledSize = CGSize(
                    width: pageSize.width * scale,
                    height: pageSize.height * scale
                )
                
                let renderer = UIGraphicsImageRenderer(size: scaledSize)
                let image = renderer.image { context in
                    context.cgContext.setFillColor(UIColor.white.cgColor)
                    context.cgContext.fill(CGRect(origin: .zero, size: scaledSize))
                    
                    context.cgContext.saveGState()
                    context.cgContext.translateBy(x: 0, y: scaledSize.height)
                    context.cgContext.scaleBy(x: scale, y: -scale)
                    
                    page.draw(with: .mediaBox, to: context.cgContext)
                    context.cgContext.restoreGState()
                }
                
                continuation.resume(returning: image)
            }
        }
    }
}

struct ThumbnailRow: View {
    let thumbnail: UIImage
    let pageNumber: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // 缩略图
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 150)
                    .background(Color.white)
                    .cornerRadius(4)
                    .shadow(radius: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(
                                isSelected ? Color.blue : Color.clear,
                                lineWidth: 2
                            )
                    )
                
                // 页码
                Text("\(pageNumber)")
                    .font(.caption)
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .fontWeight(isSelected ? .medium : .regular)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}