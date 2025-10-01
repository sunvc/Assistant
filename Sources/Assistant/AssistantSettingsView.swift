//
//  AssistantSettingsView.swift
//  pushback
//
//  Created by uuneo on 2025/2/26.
//

import SwiftUI
import Defaults

public struct AssistantSettingsView: View {

    @StateObject private var chatManager = openChatManager.shared
    
    @Default(.assistantAccouns) var assistantAccouns
    @Default(.historyMessageCount) var historyMessageCount

    
    @State private var showDeleteOk:Bool = false
    @State private var isSecured = true
    @State private var isTestingAPI = false
    @State private var selectAccount:AssistantAccount? = nil
    @State private var addAccount:AssistantAccount? = nil
    
    
    public init(account: AssistantAccount? = nil) {
        if let account{
            self._addAccount = State(wrappedValue: account)
        }
       
    }
    
    
    public  var body: some View {
      
            List{
                Section{
                    
                    Button{
                        self.selectAccount =  AssistantAccount(host: "api.openai.com", basePath: "/v1", key: "", model: "gpt-4o-mini")
                    }label: {
                        HStack{
                            Label(String(localized: "增加新账户",bundle: .module), systemImage: "person.badge.plus")
                            Spacer()
                        }
                        .contentShape(RoundedRectangle(cornerRadius: 0))
                    }
                    
                    
                    
                    ForEach(assistantAccouns,id: \.id){ account in
                        HStack{
                            HStack{
                                Text(verbatim: "\(account.name)")
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .fontWeight( account.current ? .bold : .light)
                                    .foregroundStyle(account.current ? .green : .primary)
                                
                                Spacer()
                            }
                            .padding(.vertical)
                            .padding(.leading, 5)
                            .frame(width: 100)
                            
                            
                            VStack{
                                HStack{
                                    Image(systemName: "network")
                                        .imageScale(.small)
                                    Text(verbatim: "\(account.host)")
                                        .font(.subheadline)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .foregroundStyle(.gray)
                                    Spacer()
                                }
                                .padding(.bottom, 5)
                                HStack{
                                    Image(systemName: "slider.horizontal.2.square.badge.arrow.down")
                                        .imageScale(.small)
                                    Text(verbatim: "\(account.model)")
                                        .font(.caption)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .foregroundStyle(.gray)
                                    Spacer()
                                }
                                
                            }
                            
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.gray)
                                .imageScale(.small)
                        }
                        .contentShape(Rectangle())
                        .listRowInsets(EdgeInsets())
                        .padding(10)
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 0)
                                .fill(.background)
                                .background(.ultraThinMaterial)
                        )
                        .onTapGesture(perform: {
                            self.selectAccount = account
                        })
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                
                                if let index = assistantAccouns.firstIndex(where: {$0.current}){
                                    assistantAccouns[index].current = false
                                }
                                
                                if let index = assistantAccouns.firstIndex(where: {$0.id == account.id}){
                                    assistantAccouns[index].current = true
                                }
            
                            } label: {
                                Label(String(localized: "默认",bundle: .module), systemImage: "cursorarrow.click.2")
                            }.tint(.green)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                if let index = assistantAccouns.firstIndex(where: {$0.id == account.id}){
                                    assistantAccouns.remove(at: index)
                                }
                                Haptic.impact(.heavy)
                               
                            } label: {
                                Label(String(localized: "删除",bundle: .module), systemImage: "trash")
                            }
                        }
                        
                        
                    }
                    .onMove { indexSet, index in
                        assistantAccouns.move(fromOffsets: indexSet, toOffset: index)
                    }
                    
                }header: {
                    Text(String(localized: "账户列表",bundle: .module))
                }footer:{
                    Text(String(localized: "App 所需的账户信息，自行在各大AI网站获取，例如ChatGPT：https://openai.com, 或 自行建立大模型提供服务.（App 支持所有符合 ChatGPT SDK 的模型服务 ）"))
                }

                
                Section(String(localized: "AI 助手",bundle: .module)) {
                    
                   
                    Stepper(
                        value: $historyMessageCount,
                        in: 0...50,
                        step: 1
                    ) {
                        HStack {
                            Label(String(localized: "历史消息数量",bundle: .module), systemImage: "clock.arrow.circlepath")
                            Spacer()
                            Text(verbatim: "\(historyMessageCount)")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text(String(localized: "设置每次对话时包含的历史消息数量，数量越多上下文越完整，但会增加 Token 消耗",bundle: .module))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                
                Section(String(localized: "数据管理",bundle: .module)) {
                    Button(role: .destructive) {
                        self.showDeleteOk = true
                    } label: {
                        Label(String(localized: "清除所有数据",bundle: .module), systemImage: "trash")
                        Spacer()
                    }
                }
               
            }
            .navigationTitle( String(localized: "智能助手",bundle: .module))
            .toolbar(.hidden, for: .tabBar)
            .alert(String(localized: "确认删除",bundle: .module), isPresented: $showDeleteOk) {
                Button(String(localized: "取消",bundle: .module), role: .cancel) { }
                Button(String(localized: "删除",bundle: .module), role: .destructive) {
                    Task.detached(priority: .userInitiated) {
                        try? await DatabaseManager.shared.dbPool.write { db in
                            try ChatMessage.deleteAll(db)
                            try ChatGroup.deleteAll(db)
                        }

                    }
                    
                }
            } message: {
                Text(String(localized: "此操作将删除所有聊天记录和设置数据，且无法恢复。确定要继续吗？",bundle: .module))
            }
            .sheet(item: $selectAccount) { account in
                AddOrChangeChatAccount(assistantAccount: account, isAdd: false)
                    .customPresentationCornerRadius(20)
                    .environmentObject(chatManager)
            }
            .sheet(item: $addAccount) { account in
                AddOrChangeChatAccount(assistantAccount: account, isAdd: true)
                    .customPresentationCornerRadius(20)
                    .environmentObject(chatManager)
            }
        

            
           
        
    }
    
    
}




#Preview {
    AssistantSettingsView()
}
