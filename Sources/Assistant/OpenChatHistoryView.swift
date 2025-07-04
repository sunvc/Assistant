//
//  OpenChatHistoryView.swift
//  pushback
//
//  Created by uuneo on 2025/2/25.
//

import SwiftUI
import GRDB

struct ChatMessageSection {
    var id:String = UUID().uuidString
    var title: String // 分组名称，例如 "[今天]"
    var messages: [ChatGroup]
}




struct OpenChatHistoryView: View {
    @State private var chatGroups:[ChatGroup] = []
    
    var chatGroupSection:[ChatMessageSection]{
        getGroupedMessages(allMessages: chatGroups)
    }
    @Binding var show:Bool
    @State private var text:String = ""
    @State private var showChangeGroupName:Bool = false
    
    @State private var selectdChatGroup:ChatGroup? = nil
    
    @EnvironmentObject private var chatManager: openChatManager
    var body: some View {
        NavigationStack{
            VStack{
                ScrollView {
                    if chatGroups.isEmpty{
                        emptyView
                    }else{
                        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                            ForEach(chatGroupSection, id: \.id){ section in
                                chatView(section: section)
                            }
                        }
                    }
                    
                }
                .scrollIndicators(.hidden)
                
            }
            .navigationTitle(String(localized: "最近使用",bundle: .module))
            .searchable(text: $text)
            .popView(isPresented: $showChangeGroupName){
                withAnimation {
                    showChangeGroupName = false
                    self.selectdChatGroup = nil
                }
            }content: {
                if let chatgroup = selectdChatGroup{
                    CustomAlertWithTextField( $showChangeGroupName, text: chatgroup.name) { text in
                        Task.detached(priority: .background) {
                            do {
                                try await DatabaseManager.shared.dbPool.write { db in
                                    if var group = try ChatGroup
                                        .filter(ChatGroup.Columns.id == chatgroup.id)
                                        .fetchOne(db)
                                    {
                                        group.name = text
                                        try group.update(db)
                                    }
                                }
                            } catch {
                                print("❌ 更新 group.name 失败: \(error)")
                            }
                        }
                    }

                }else {
                    Spacer()
                        .onAppear{
                            self.showChangeGroupName = false
                            self.selectdChatGroup = nil
                        }
                }
            }
            .toolbar{
                ToolbarItem {
                    Label(String(localized: "关闭",bundle: .module), systemImage: "xmark.seal")
                        .foregroundStyle(.red)
                        .VButton(onRelease: { _ in
                            self.show.toggle()
                            return true
                        })
                }
            }
            .task {
                loadGroups()
            }
            
        }
    }
    
    private func loadGroups(){
        Task.detached(priority: .background) {
            do{
                let groups = try  await DatabaseManager.shared.dbPool.read { db in
                    try ChatGroup.fetchAll(db)
                }
                await MainActor.run {
                    self.chatGroups = groups
                }
            }catch{
                debugPrint(error.localizedDescription)
            }
        }
    }
    
    @ViewBuilder
    private func chatView(section: ChatMessageSection) -> some View{
        Section{
            LazyVStack(spacing: 10, pinnedViews: [.sectionHeaders]) {
                ForEach(section.messages, id: \.id){ chatgroup in
                    
                    HStack{
                        Button{
                            chatManager.chatgroup = chatgroup
                            self.show.toggle()
                        }label: {
                            
                            HStack{
                                Label(chatgroup.name.trimmingSpaceAndNewLines,
                                      systemImage: getleftIconName(group: chatgroup.id))
                                    .fontWeight(.medium)
                                    .lineLimit(1) // 限制为单行
                                    .truncationMode(.tail) // 超出部分用省略号
                                    .padding(.vertical, 10)
                                    .padding(.leading, 10)
                                    .foregroundColor( chatManager.chatgroup == chatgroup ? .green : .primary)
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .imageScale(.large)
                                    .foregroundColor(chatManager.chatgroup == chatgroup  ? .green : .gray)
                                    
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 10)
                            .background( .ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal, 10)
                            
                            
                            
                        }
                    }
                    .contextMenu {
                        Button{
                            
                            self.selectdChatGroup = chatgroup
                            self.showChangeGroupName = true
                        }label:{
                            Text(String(localized: "重命名",bundle: .module))
                        }
                        Button(role: .destructive){
                            Task.detached(priority: .background) {
                                try? await DatabaseManager.shared.dbPool.write { db in
                                    // 查找 ChatGroup
                                    let groups = try ChatGroup.fetchCount(db)
                                    if groups == 1 || openChatManager.shared.chatgroup == chatgroup{
                                        DispatchQueue.main.async{
                                            openChatManager.shared.chatgroup = nil
                                        }
                                        
                                    }
                                    if let group = try ChatGroup.fetchOne(db, key: chatgroup.id) {
                                        // 删除与该 group.id 关联的所有 ChatMessage
                                        try ChatMessage
                                            .filter(ChatMessage.Columns.chat == group.id)
                                            .deleteAll(db)
                                        
                                        // 删除该 ChatGroup 本身
                                        try group.delete(db)
                                        
                                    }
                                }
                                await loadGroups()
                            }
                        }label:{
                            Text(String(localized: "删除",bundle: .module))
                        }
                    }
                }
            }
            .padding(.vertical)
        }header: {
            HStack{
                
                Text(section.title)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .padding(.leading)
                
                Spacer()
                
            }
            .padding(.vertical, 5)
            .background( .ultraThinMaterial )
        }
        
        
        
    }
    
    private var emptyView: some View{
        VStack(alignment: .center){
            HStack{
                Spacer()
                Image(systemName: "plus.message")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70)
                Spacer()
            }
            .padding(.top, 50)
            .padding(.bottom, 20)
            HStack{
                Spacer()
                Text(String(localized: "无聊天",bundle: .module))
                    .font(.title)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(.bottom)
            HStack(alignment: .center){
                Spacer()
                Text(String(localized: "当您与智能助手对话时，您的对话将显示在此处",bundle: .module))
                    .font(.body)
                    .multilineTextAlignment(.center)
                Spacer()
                
            }.padding(.bottom)
            HStack{
                Spacer()
                Button{
                    chatManager.chatgroup = nil

                    self.show.toggle()
                }label: {
                    Text(String(localized: "开始新聊天",bundle: .module))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue)
                        )
                }
                
                Spacer()
            }
        }.padding()
    }
    
    private func getleftIconName(group:String)-> String{
        return "rectangle.3.group.bubble"
    }
    
    
    private func getGroupedMessages(allMessages: [ChatGroup]) -> [ChatMessageSection] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 定义时间分组规则
        let timeIntervals: [(title: String, start: Date, end: Date)] = [
            (String(localized: "今天", bundle: .module), today, calendar.date(byAdding: .day, value: 1, to: today)!),
            (String(localized: "昨天", bundle: .module), calendar.date(byAdding: .day, value: -1, to: today)!, today),
            (String(localized: "前天", bundle: .module), calendar.date(byAdding: .day, value: -2, to: today)!, calendar.date(byAdding: .day, value: -1, to: today)!),
            (String(localized: "2天前", bundle: .module), calendar.date(byAdding: .day, value: -3, to: today)!, calendar.date(byAdding: .day, value: -2, to: today)!),
            (String(localized: "一周前", bundle: .module), calendar.date(byAdding: .day, value: -7, to: today)!, calendar.date(byAdding: .day, value: -3, to: today)!),
            (String(localized: "两周前", bundle: .module), calendar.date(byAdding: .day, value: -14, to: today)!, calendar.date(byAdding: .day, value: -7, to: today)!),
            (String(localized: "1月前", bundle: .module), calendar.date(byAdding: .month, value: -1, to: today)!, calendar.date(byAdding: .day, value: -14, to: today)!),
            (String(localized: "3月前", bundle: .module), calendar.date(byAdding: .month, value: -3, to: today)!, calendar.date(byAdding: .month, value: -1, to: today)!),
            (String(localized: "半年前", bundle: .module), calendar.date(byAdding: .month, value: -6, to: today)!, calendar.date(byAdding: .month, value: -3, to: today)!)
        ]
        
        // 按时间分组
        var groupedMessages: [ChatMessageSection] = []
        
        for interval in timeIntervals {
            let messages = allMessages.filter { $0.timestamp >= interval.start && $0.timestamp < interval.end }
            if !messages.isEmpty {
                groupedMessages.append(ChatMessageSection(title: interval.title, messages: Array(messages)))
            }
        }
        
        return groupedMessages
    }
}

#Preview {
    OpenChatHistoryView(show: .constant(false))
}
