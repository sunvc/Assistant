//
//  ChatManager.swift
//  Deepseek
//
//  Created by lynn on 2025/7/2.
//

import Foundation
import OpenAI
import Defaults
import GRDB
import UIKit
import SwiftUI


public class openChatManager: ObservableObject, @unchecked Sendable {
    
    public static let shared = openChatManager()
    
    @Published var currentMessage = ChatMessage(timestamp: .now, chat: "", request: "", content: "")
 
    @Published var isFocusedInput:Bool = false
    
    @Published var groupsCount:Int = 0
    @Published var messagesCount:Int = 0
    @Published var promptCount:Int = 0
    
    @Published var chatgroup:ChatGroup? = nil
    @Published var chatPrompt:ChatPrompt? = nil
    @Published var chatMessages:[ChatMessage] = []
    
    
    @Published var isLoading:Bool = false
    @Published var inAssistant:Bool = false
    
    @Published var quote:String? = nil
    
    @Published var page:Page = .home
    
    @Published var imageName:ImageMode = .module("AssistantOpenchat")
    
    var Toast:((ToastMode, String)-> Void)? = nil
    
    private let DB: DatabaseManager = DatabaseManager.shared

    private var observationCancellable: AnyDatabaseCancellable?
    public var cancellableRequest:CancellableRequest? = nil
    
    
    private init(){
        startObservingUnreadCount()
    }
    
    enum Page{
        case assistant
        case voice
        case home
    }
    
    var showPage:Binding<Bool>{
        Binding {
            self.page != .home
        } set: { value in
            self.page = .home
        }

    }

    
    private func startObservingUnreadCount() {
        let observation = ValueObservation.tracking { db -> (Int,Int,Int) in
            let groupsCount:Int =  try ChatGroup.fetchCount(db)
            let messagesCount:Int = try ChatMessage.filter(ChatMessage.Columns.chat == self.chatgroup?.id).fetchCount(db)
            let promptCount:Int = try ChatPrompt.fetchCount(db)
            return (groupsCount, messagesCount, promptCount)
        }
        
        observationCancellable = observation.start(
            in: DB.dbPool,
            scheduling: .async(onQueue: .global()),
            onError: { error in
                print("Failed to observe unread count:", error)
            },
            onChange: { [weak self] newUnreadCount in
                print("监听 SqlLite \(newUnreadCount)")
                
                DispatchQueue.main.async {
                    self?.groupsCount = newUnreadCount.0
                    self?.messagesCount = newUnreadCount.1
                    self?.promptCount = newUnreadCount.2
                }
            }
        )
    }
    
    
    public func resetMessage() {
        currentMessage = currentMessage.reset()
    }
    
    public func updateGroupName( groupId: String, newName: String) {
        Task.detached(priority: .userInitiated) {
            do {
                try await self.DB.dbPool.write { db in
                    if var group = try ChatGroup.filter(Column("id") == groupId).fetchOne(db) {
                        group.name = newName
                        try group.update(db)
                        
                        openChatManager.shared.chatgroup = group
                        
                    }
                }
            } catch {
                print("更新失败: \(error)")
            }
        }
        
    }
    @MainActor
    public class func openUrl(url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
}

public extension openChatManager{
    func test(account: AssistantAccount) async ->Bool{
        
        do{
            if account.host.isEmpty || account.key.isEmpty || account.basePath.isEmpty || account.model.isEmpty{
                Log.debug(account)
                
                return false
            }
            
            
            guard let openchat = self.getReady(account: account) else {  return false }
            
            let query = ChatQuery(messages: [.user(.init(content: .string("Hello")))], model: account.model)
            
            _ = try await openchat.chats(query: query)
            
            return true
            
        }catch{
            debugPrint(error)
            return false
        }
        
        
    }
    
    func onceParams(text: String, tips:ChatPromptMode) -> ChatQuery?{
        guard  let account =  Defaults[.assistantAccouns].first(where: { $0.current }) else {
            return nil
        }
        let params:[ChatQuery.ChatCompletionMessageParam] = [
            .system(.init(content: .textContent(tips.prompt.content),name: tips.prompt.title)),
            .user(.init(content: .string(text)))
        ]
        
        return ChatQuery(messages: params, model: account.model)
        
    }
    
    func getHistoryParams(text: String, image:URL? = nil )-> ChatQuery?{
        
        
        guard  let account = Defaults[.assistantAccouns].first(where: {$0.current}) else {
            return nil
        }
        var params:[ChatQuery.ChatCompletionMessageParam] = []
        
        ///  增加system的前置参数
        if let promt = try? DB.dbPool.read({ db in
            try ChatPrompt.filter(ChatPrompt.Columns.id == chatPrompt?.id).fetchOne(db)
        }){
            params.append(.system(.init(content: .textContent(promt.content), name: promt.title)))
        }
        
        let limit = Defaults[.historyMessageCount]
        if  let messageRaw = try? DB.dbPool.read({ db in
            try ChatMessage
                .filter(ChatMessage.Columns.chat == chatgroup?.id)
                .order(Column("timestamp").desc)
                .limit(limit)
                .fetchAll(db)
        }){
            for message in messageRaw{
                params.append(.user(.init(content: .string(message.request))))
                params.append(.assistant(.init(content: .textContent(message.content))))
                
            }
            if let image = image,
               let imageData = UIImage(contentsOfFile: image.path())?.pngData(),
               let param = ChatQuery.ChatCompletionMessageParam(role: .user,
                                                                content: text,
                                                                imageData: imageData){
                params.append(param)
                
            }else{
                params.append(.user(.init(content: .string(text))))
            }
            
           
        }
        
        
        
        
        
        return ChatQuery(messages: params, model: account.model)
    }
    
    func getReady(account:AssistantAccount? = nil) -> OpenAI?{
        if let account = account {
            
            let config = OpenAI.Configuration(token: account.key,host: account.host, basePath: account.basePath)
            
            return OpenAI(configuration: config)
        }else {
            guard  let account = Defaults[.assistantAccouns].first(where: {$0.current}) else {
                return nil
            }
            let config = OpenAI.Configuration(token: account.key,host: account.host, basePath: account.basePath)
            
            return OpenAI(configuration: config)
        }
        
    }
    
    func chatsStream(text:String,image:URL? = nil, account:AssistantAccount? = nil,onResult: @escaping @Sendable (Result<ChatStreamResult, Error>) -> Void, completion: (@Sendable (Error?) -> Void)?)  {
        guard let openchat = self.getReady(),
                let query = self.getHistoryParams(text: text, image: image) else {
            completion?(chatError.noConfig)
            return
        }
        self.cancellableRequest = openchat.chatsStream(query: query, onResult: onResult, completion: completion)
    }
    
    func chatsStream(text:String, tips:ChatPromptMode, account:AssistantAccount? = nil,onResult: @escaping @Sendable (Result<ChatStreamResult, Error>) -> Void, completion: (@Sendable (Error?) -> Void)?) -> CancellableRequest? {
        guard let openchat = self.getReady(), let query = self.onceParams(text: text, tips: tips) else {
            completion?(chatError.noConfig)
            return nil
        }
        
        return openchat.chatsStream(query: query, onResult: onResult, completion: completion)
    }
    
    enum chatError: Error {
        case noConfig
    }
    
    func clearunuse(){
        Task.detached(priority: .background) {
            do {
                try self.DB.dbPool.write { db in
                    
                    // 1. 查找无关联 ChatMessage 的 ChatGroup
                    let allGroups = try ChatGroup.fetchAll(db)
                    var deleteList: [ChatGroup] = []
                    
                    for group in allGroups {
                        let messageCount = try ChatMessage
                            .filter(ChatMessage.Columns.chat == group.id)
                            .fetchCount(db)
                        
                        if messageCount == 0 {
                            deleteList.append(group)
                        }
                    }
                    
                    for group in deleteList {
                        try group.delete(db)
                    }
                }
            } catch {
                print("GRDB 错误: \(error)")
            }
        }
       
    }
}


enum ImageMode: Equatable{
    case module(String)
    case main(String)
    // 自定义 Equatable 实现，忽略关联值
    static func == (lhs: ImageMode, rhs: ImageMode) -> Bool {
        switch (lhs, rhs) {
        case (.module, .module), (.main, .main):
            return true  // 只要 case 相同就返回 true
        default:
            return false
        }
    }
}
