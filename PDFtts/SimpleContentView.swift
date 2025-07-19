//
//  SimpleContentView.swift
//  PDFtts
//
//  Created by Matt on 16/7/2025.
//

import SwiftUI
import PDFKit

struct SimpleContentView: View {
    @State private var selectedPDF: URL?
    @State private var showingDocumentPicker = false
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题
            Text("PDF 电子阅读器")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 50)
            
            // 如果没有选择PDF，显示选择界面
            if selectedPDF == nil {
                VStack(spacing: 30) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 80))
                        .fontWeight(.light)
                        .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
                    
                    Text("选择一个PDF文件开始阅读")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        print("🔄 按钮被点击，准备打开文件选择器")
                        showingDocumentPicker = true
                    }) {
                        HStack {
                            Image(systemName: "folder")
                                .fontWeight(.light)
                            Text("选择PDF文件")
                                .fontWeight(.light)
                        }
                        .font(.headline)
                        .foregroundColor(Color(red: 0.3, green: 0.6, blue: 1.0))
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(red: 0.3, green: 0.6, blue: 1.0), lineWidth: 1)
                        )
                    }
                    .frame(minWidth: 200, minHeight: 50)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // 显示PDF
                if let pdfURL = selectedPDF {
                    SimplePDFView(pdfURL: pdfURL)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            
            // 底部按钮
            HStack {
                Button("重新选择") {
                    selectedPDF = nil
                }
                .font(.body)
                .fontWeight(.light)
                .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
                .padding()
                
                Spacer()
                
                if selectedPDF != nil {
                    Button("朗读") {
                        // TODO: 实现朗读功能
                    }
                    .font(.body)
                    .fontWeight(.light)
                    .padding()
                    .background(Color.clear)
                    .foregroundColor(Color(red: 0.3, green: 0.6, blue: 1.0))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(red: 0.3, green: 0.6, blue: 1.0), lineWidth: 1)
                    )
                }
            }
            .padding()
        }
        .background(Color(UIColor.systemBackground))
        .fileImporter(
            isPresented: $showingDocumentPicker,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            print("📁 文件选择器回调触发")
            switch result {
            case .success(let urls):
                print("✅ 文件选择成功: \(urls)")
                if let url = urls.first {
                    print("📄 选择的PDF文件: \(url)")
                    selectedPDF = url
                }
            case .failure(let error):
                print("❌ 文件选择失败: \(error)")
            }
        }
    }
}

struct SimplePDFView: UIViewRepresentable {
    let pdfURL: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.displayMode = .singlePageContinuous
        pdfView.autoScales = true
        pdfView.backgroundColor = UIColor.systemBackground
        
        if let document = PDFDocument(url: pdfURL) {
            pdfView.document = document
        }
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        // 更新逻辑
    }
}

#Preview {
    SimpleContentView()
}