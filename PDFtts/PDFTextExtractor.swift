//
//  PDFTextExtractor.swift
//  PDFtts
//
//  Created by Matt on 16/7/2025.
//

import Foundation
import PDFKit

class PDFTextExtractor {
    
    // 提取指定页面的所有文本
    static func extractPageText(from document: PDFDocument, pageIndex: Int) -> String? {
        guard pageIndex >= 0 && pageIndex < document.pageCount,
              let page = document.page(at: pageIndex) else {
            return nil
        }
        
        return page.string
    }
    
    // 按句子分割文本
    static func splitIntoSentences(_ text: String) -> [String] {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 使用正则表达式按句子分割
        let sentencePattern = #"[^.!?]*[.!?]+"#
        
        do {
            let regex = try NSRegularExpression(pattern: sentencePattern, options: [])
            let matches = regex.matches(in: cleanText, options: [], range: NSRange(location: 0, length: cleanText.count))
            
            var sentences: [String] = []
            for match in matches {
                if let range = Range(match.range, in: cleanText) {
                    let sentence = String(cleanText[range])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if !sentence.isEmpty && sentence.count > 5 {
                        sentences.append(sentence)
                    }
                }
            }
            
            return sentences
        } catch {
            // 如果正则表达式失败，使用简单的分割方法
            return text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && $0.count > 5 }
        }
    }
    
    // 提取指定页面的指定句子
    static func extractSentence(from document: PDFDocument, pageIndex: Int, sentenceIndex: Int) -> String? {
        guard let pageText = extractPageText(from: document, pageIndex: pageIndex) else {
            return nil
        }
        
        let sentences = splitIntoSentences(pageText)
        
        guard sentenceIndex >= 0 && sentenceIndex < sentences.count else {
            return nil
        }
        
        return sentences[sentenceIndex]
    }
    
    // 提取页面的指定范围句子
    static func extractSentenceRange(from document: PDFDocument, pageIndex: Int, startSentence: Int, endSentence: Int) -> String? {
        guard let pageText = extractPageText(from: document, pageIndex: pageIndex) else {
            return nil
        }
        
        let sentences = splitIntoSentences(pageText)
        
        guard startSentence >= 0 && endSentence < sentences.count && startSentence <= endSentence else {
            return nil
        }
        
        let selectedSentences = Array(sentences[startSentence...endSentence])
        return selectedSentences.joined(separator: " ")
    }
    
    // 调试函数：显示页面的所有句子
    static func debugPageSentences(from document: PDFDocument, pageIndex: Int) {
        guard let pageText = extractPageText(from: document, pageIndex: pageIndex) else {
            print("❌ 无法提取第\(pageIndex + 1)页文本")
            return
        }
        
        let sentences = splitIntoSentences(pageText)
        
        print("📖 第\(pageIndex + 1)页共有 \(sentences.count) 个句子:")
        print("" + String(repeating: "=", count: 50))
        
        for (index, sentence) in sentences.enumerated() {
            print("[\(index)] \(sentence)")
            print("" + String(repeating: "-", count: 30))
        }
    }
}

// 扩展PDFDocument以便更容易使用
extension PDFDocument {
    func getPageText(at pageIndex: Int) -> String? {
        return PDFTextExtractor.extractPageText(from: self, pageIndex: pageIndex)
    }
    
    func getPageSentences(at pageIndex: Int) -> [String] {
        guard let text = getPageText(at: pageIndex) else { return [] }
        return PDFTextExtractor.splitIntoSentences(text)
    }
    
    func getSentence(at pageIndex: Int, sentenceIndex: Int) -> String? {
        return PDFTextExtractor.extractSentence(from: self, pageIndex: pageIndex, sentenceIndex: sentenceIndex)
    }
    
    func getSentenceRange(at pageIndex: Int, from startSentence: Int, to endSentence: Int) -> String? {
        return PDFTextExtractor.extractSentenceRange(from: self, pageIndex: pageIndex, startSentence: startSentence, endSentence: endSentence)
    }
    
    func debugPageSentences(at pageIndex: Int) {
        PDFTextExtractor.debugPageSentences(from: self, pageIndex: pageIndex)
    }
}