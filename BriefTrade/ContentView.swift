//
//  ContentView.swift
//  BriefTrade
//
//  Created by JinZhaoXi on 2026/2/25.
//
import SwiftUI
import SwiftData
import GoogleGenerativeAI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \NewsRecord.date, order: .reverse) private var savedNews: [NewsRecord]
    
    @State private var rawNewsInput: String = ""
    @State private var isAnalyzing: Bool = false
    
    private var apiKeyFromPlist: String {
        // 尋找專案中名為 Secrets.plist 的路徑
        guard let filePath = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: filePath),
              let value = plist["GEMINI_API_KEY"] as? String else {
            // 如果找不到檔案或 Key，App 會直接崩潰並提醒你，這在開發階段很有用
            fatalError("錯誤：找不到 Secrets.plist 或裡面的 GEMINI_API_KEY")
        }
        return value
    }
    
    // ⚠️ 請填入你的 API Key
    private var model: GenerativeModel {
            GenerativeModel(name: "gemini-1.5-flash", apiKey: apiKeyFromPlist)
    }

    var body: some View {
        NavigationStack {
            VStack {
                // 輸入區
                TextEditor(text: $rawNewsInput)
                    .frame(height: 150)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                    .padding()
                
                Button(action: analyzeNews) {
                    if isAnalyzing {
                        ProgressView()
                    } else {
                        Text("開始 AI 識讀總結").bold()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(rawNewsInput.isEmpty || isAnalyzing)

                // 歷史記錄區
                List {
                    Section("今日識讀記錄") {
                        ForEach(savedNews) { record in
                            VStack(alignment: .leading) {
                                Text(record.sentiment)
                                    .font(.caption)
                                    .padding(4)
                                    .background(record.sentiment.contains("利多") ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                                
                                Text(record.summary)
                                    .font(.body)
                                    .lineLimit(3)
                            }
                        }
                        .onDelete(perform: deleteNews)
                    }
                }
            }
            .navigationTitle("BriefTrade 15min")
        }
    }

    func analyzeNews() {
        isAnalyzing = true
        Task {
            do {
                let prompt = "你是一位專業股市分析師。請將以下新聞總結成100字以內，並在開頭標註【利多】、【利空】或【中立】：\n\n\(rawNewsInput)"
                let response = try await model.generateContent(prompt)
                let resultText = response.text ?? "解析失敗"
                
                // 存入 SwiftData 資料庫
                let newRecord = NewsRecord(title: "今日新聞", summary: resultText, sentiment: resultText.prefix(4).description)
                modelContext.insert(newRecord)
                
                rawNewsInput = "" // 清空輸入框
            } catch {
                print("Error: \(error)")
            }
            isAnalyzing = false
        }
    }
    
    private func deleteNews(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(savedNews[index])
        }
    }
}
