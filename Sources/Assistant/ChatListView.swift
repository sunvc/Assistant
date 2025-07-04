

import SwiftUI
import Defaults
import Combine
import GRDB


struct ChatMessageListView: View {
    @State private var messages:[ChatMessage] = []
    
    @EnvironmentObject private var manager:openChatManager
    
    @State private var showHistory:Bool = false
    
    @State private var messageCount:Int = 10
    
    let chatLastMessageId = "currentChatMessageId"
    
    let throttler = Throttler(delay: 0.1)
    
    @State private var offsetY: CGFloat = 0
    
    var suffixCount:Int{
        min(messages.count, 10)
    }
    
    // MARK: - Body
    var body: some View {
        ScrollViewReader { scrollViewProxy in
            
            ScrollView {
                
                if messages.count > suffixCount{
                    Button{
                        self.showHistory.toggle()
                    }label: {
                        HStack{
                            Spacer()
                            Text(verbatim: "\(suffixCount)/\(messages.count)")
                                .padding(.trailing, 10)
                            Text(String(localized: "点击查看更多",bundle: .module))
                           
                            Spacer()
                        }
                        .padding(.vertical)
                        .contentShape(Rectangle())
                        .font(.footnote)
                        .foregroundStyle(.gray)
                    }
                }
                
            
                
                ForEach(messages,id: \.id) { message in
                    ChatMessageView(message: message,isLoading: manager.isLoading)
                        .id(message.id)
                }
                
                VStack{
                    if manager.isLoading{
                        
                        ChatMessageView(message: manager.currentMessage,isLoading: manager.isLoading)
                    }
                    
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color.clear)
                        .opacity(0.001)
                        .frame(height: 50)
                        .background(
                            GeometryReader { proxy in
                                Color.clear
                                    .preference(key: OffsetKey.self, value: proxy.frame(in: .global).maxY)
                            }
                        )
                        .onPreferenceChange(OffsetKey.self) { newValue in
                            offsetY = newValue
                        }
                }.id(chatLastMessageId)
                
            }
            .onAppear {
                DispatchQueue.main.async{
                    withAnimation(.snappy(duration: 0.1)){
                        scrollViewProxy.scrollTo(chatLastMessageId)
                    }
                }
                Haptic.impact(.soft)
            }
            .onChange(of: manager.isFocusedInput) { newValue in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
                    scrollViewProxy.scrollTo(chatLastMessageId)
                }
            }
            .onChange(of: manager.chatgroup){ _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
                    scrollViewProxy.scrollTo(chatLastMessageId)
                }
            }
            .onChange(of: manager.currentMessage){ _ in
                throttler.throttle {
                    if offsetY < 800{
                        withAnimation(.snappy(duration: 0.1)){
                            scrollViewProxy.scrollTo(chatLastMessageId, anchor: .bottom)
                        }
                    }
                   
                }
            }
            .onChange(of: manager.isLoading){ value in
                if offsetY < 800{
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
                        scrollViewProxy.scrollTo(chatLastMessageId, anchor: .bottom)
                    }
                }
            }
            .sheet(isPresented: $showHistory) {
                if let chatgroup = manager.chatgroup{
                    HistoryMessage(showHistory: $showHistory, group: chatgroup.id)
                        .customPresentationCornerRadius(20)
                }else{
                    Spacer()
                        .onAppear{
                            self.showHistory.toggle()
                        }
                }
                
            }
            .task {
                loadData()
            }
            .onChange(of: manager.messagesCount) { value in
                debugPrint(value)
                loadData()
            }
            .onChange(of: manager.groupsCount) { value in
                debugPrint(value)
                loadData()
            }
            .onChange(of: manager.chatgroup) { _ in
                loadData()
            }
        }
    }
    
    private func loadData(){
        if let id = manager.chatgroup?.id{
            Task.detached(priority: .background) {
                let results = try await  DatabaseManager.shared.dbPool.read { db in
                    let results  =  try ChatMessage
                        .filter(ChatMessage.Columns.chat == id)
                        .limit(10)
                        .fetchAll(db)
                    return results
                }
                await MainActor.run {
                    self.messages = results
                }
            }
        }
    }
}




class Throttler {
    private var lastExecution: Date = .distantPast
    private let queue: DispatchQueue
    private let delay: TimeInterval
    private var pendingWorkItem: DispatchWorkItem?
    
    init(delay: TimeInterval, queue: DispatchQueue = .main) {
        self.delay = delay
        self.queue = queue
    }
    
    func throttle(_ action: @escaping () -> Void) {
        let now = Date()
        let timeSinceLastExecution = now.timeIntervalSince(lastExecution)
        
        if timeSinceLastExecution >= delay {
            // 超过 1 秒，立即执行
            lastExecution = now
            action()
        } else {
            // 取消之前的任务，确保 1 秒内只执行最后一次
            pendingWorkItem?.cancel()
            
            let workItem = DispatchWorkItem {
                self.lastExecution = Date()
                action()
            }
            
            pendingWorkItem = workItem
            queue.asyncAfter(deadline: .now() + delay - timeSinceLastExecution, execute: workItem)
        }
    }
}

struct OffsetKey: PreferenceKey, Sendable {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
