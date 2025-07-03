//
//  Model.swift
//  Deepseek
//
//  Created by lynn on 2025/7/2.
//
import Foundation
import GRDB

public struct ChatGroup: Codable, FetchableRecord, PersistableRecord,
                         Identifiable, Hashable, Sendable, Equatable {
    public  var id: String = UUID().uuidString
    public  var timestamp: Date
    public  var name: String = String(localized: "新对话", bundle: .module)
    public  var host: String
    
    public  enum Columns{
        static let id = Column(CodingKeys.id)
        static let timestamp = Column(CodingKeys.timestamp)
        static let name = Column(CodingKeys.name)
        static let host = Column(CodingKeys.host)
    }
    
    public static func createInit(dbPool: DatabasePool) throws {
        try dbPool.write { db in
            try db.create(table: "chatGroup", ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("timestamp", .date).notNull()
                t.column("name", .text).notNull()
                t.column("host", .text).notNull()
            }
        }
        
        
    }
    
    
}




public struct ChatMessage: Codable,  Identifiable,
                           Hashable, Sendable, Equatable,
                           FetchableRecord, PersistableRecord{
    public var id: String = UUID().uuidString
    public var timestamp: Date
    public var chat:String
    public var request:String
    public var content: String
    public var image:URL?
    public var file:URL?
    
    public enum Columns{
        static let id = Column(CodingKeys.id)
        static let timestamp = Column(CodingKeys.timestamp)
        static let chat = Column(CodingKeys.chat)
        static let request = Column(CodingKeys.request)
        static let content = Column(CodingKeys.content)
        static let image = Column(CodingKeys.image)
        static let file = Column(CodingKeys.file)
    }
    
    public static func createInit(dbPool: DatabasePool) throws {
        try dbPool.write { db in
            try db.create(table: "chatMessage", ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("timestamp", .date).notNull()
                t.column("chat", .text).notNull()
                t.column("request", .text).notNull()
                t.column("content", .text).notNull()
                t.column("message", .text)
                t.column("image", .text)
                t.column("file", .text)
            }
        }
    }
    
    public func reset() -> Self{
        var content = self
        content.id = UUID().uuidString
        content.request = ""
        content.chat = ""
        content.content = ""
        content.image = nil
        content.file = nil
        return content
    }
}


public struct ChatPrompt: Codable, FetchableRecord, PersistableRecord, Identifiable, Equatable, Hashable, Sendable {
    public  var id: String = UUID().uuidString
    public  var timestamp: Date = .now
    public  var title: String
    public  var content: String
    public  var inside: Bool
    
    
    public enum Columns{
        static let id = Column(CodingKeys.id)
        static let timestamp = Column(CodingKeys.timestamp)
        static let title = Column(CodingKeys.title)
        static let content = Column(CodingKeys.content)
        static let inside = Column(CodingKeys.inside)
    }
    
    public static func createInit(dbPool: DatabasePool) throws {
        try dbPool.write { db in
            try db.create(table: "chatPrompt", ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("timestamp", .text).notNull()
                t.column("title", .text).notNull()
                t.column("content", .date).notNull()
                t.column("inside", .boolean)
            }
        }
    }
    
    @MainActor public static let prompts = ChatPromptMode.prompts
    
}


public enum ChatPromptMode: Sendable{
    case summary
    case translate
    case writing
    case code
    case abstract
    
    public static var summaryPrompt: ChatPrompt{
        ChatPrompt(
            timestamp: .now,
            title: String(localized: "总结助手",bundle: .module),
            content: String(localized: """
            你是一名专业总结助手，擅长从大量信息中提炼关键内容。总结时请遵循以下原则：
            1. 提取核心观点，排除冗余信息。
            2. 保持逻辑清晰，结构紧凑, 确定文章的中心主题，理解作者的论点和观点。
            3. 列出关键点来传达文章的信息和细节。确保总结保持一致性，语言简洁明了
            4. 可根据需要生成段落式或要点式总结, 遵循原文结构以提升阅读体验。
            5. 有效地传达主要观点和情感层面，同时使用简洁清晰的语言
            下面我给你内容，直接按照 \(Self.lang()) 语言给我回复
            """,bundle: .module),
            inside: true
        )
    }
    
    public static var abstractPrompt: ChatPrompt{
        ChatPrompt(
            timestamp: .now,
            title: String(localized: "摘要助手",bundle: .module),
            content: String(localized: """
                你是一名专业摘要助手，擅长用简洁准确的语言提炼关键信息。
                请基于以下内容，提炼出 2~3 句话，清晰概括核心观点和情感基调。
                仅输出摘要内容，不添加解释或说明。
                下面我给你内容，直接按照 \(Self.lang()) 语言给我回复
                """,bundle: .module),
            inside: true
        )
    }
    
    public  static var translatePrompt:ChatPrompt{
        ChatPrompt(
            timestamp: .now,
            title: String(localized: "翻译助手",bundle: .module),
            content: String(localized: """
           你是一名专业翻译，精通多国语言，能够准确传达原文含义与风格。翻译时请遵循以下要点：
           1. 保持语气一致，忠实还原原文风格。
           2. 合理调整以符合目标语言习惯与文化。
           3. 优先选择自然、通顺的表达方式, 只返回翻译，不要添加任何其他内容。
           下面我给你内容，直接按照 \(Self.lang()) 语言进行翻译, 如果来源和目标语言相同，请翻译成英语
           """,bundle: .module),
            inside: true
        )
    }
    
    public static var writingPrompt: ChatPrompt{
        ChatPrompt(
            timestamp: .now,
            title: String(localized: "写作助手",bundle: .module),
            content: String(localized: """
            你是一名专业写作助手，擅长各类文体的写作与润色。请根据以下要求优化文本：
            1. 明确文章结构，增强逻辑连贯性。
            2. 优化用词，使语言更准确流畅。
            3. 强调重点，突出核心信息。
            4. 使风格贴合目标读者的阅读习惯。
            5. 纠正语法、标点和格式错误。
            下面我给你内容，直接按照 \(Self.lang()) 语言给我回复
            """,bundle: .module),
            inside: true
        )
    }
    
    public static var codePrompt: ChatPrompt {
        ChatPrompt(
            timestamp: .now,
            title: String(localized: "代码助手",bundle: .module),
            content: String(localized: """
            你是一位经验丰富的程序员，擅长编写清晰、简洁、易于维护的代码。请根据以下原则回答问题：
            1. 提供完整、可运行的代码示例。
            2. 简明解释关键实现细节。
            3. 指出潜在的性能或结构优化点。
            4. 关注代码的可扩展性、安全性和效率。
            下面我给你内容，直接按照 \(Self.lang()) 语言给我回复
            """,bundle: .module),
            inside: true
        )
    }
    
    public static func lang() -> String{
        Locale.preferredLanguages.first ?? "English"
    }
    
    public static var prompts:[ChatPrompt]{
        [summaryPrompt, translatePrompt, writingPrompt, codePrompt]
    }
    
    public var prompt:ChatPrompt{
        switch self {
        case .summary: Self.summaryPrompt
        case .translate: Self.translatePrompt
        case .writing:  Self.writingPrompt
        case .code:  Self.codePrompt
        case .abstract: Self.abstractPrompt
        }
    }
    
}
