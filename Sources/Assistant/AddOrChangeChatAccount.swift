//
//  AddOrChangeChatAccount.swift
//  pushback
//
//  Created by lynn on 2025/5/4.
//
import SwiftUI
import Defaults



struct AddOrChangeChatAccount:View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var chatManager:openChatManager
    @State private var data: AssistantAccount
    @Default(.assistantAccouns) var assistantAccouns
    @State private var isSecured:Bool = true
    @State private var isTestingAPI = false
    @State private var isAdd:Bool = false
    @State private var buttonState:AnimatedButton.buttonState = .normal
    
    var title:String
    
    
    init(assistantAccount: AssistantAccount, isAdd:Bool = false) {
        self._data = State(wrappedValue: assistantAccount)
        self.isAdd = isAdd
        if isAdd{
            self.title = String(localized: "增加新资料",bundle: .module)
        }else{
            self.title = String(localized: "修改资料", bundle: .module)
        }
    }
    
    var body: some View {
        NavigationStack{
            List{
                
                Section(String(localized: "输入别名",bundle: .module)) {
                    baseNameField
                }
                .textCase(.none)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSpacing(0)
                
                Section(String(localized: "请求地址(api.openai.com)",bundle: .module)) {
                    baseHostField
                }
                .textCase(.none)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSpacing(0)
                Section(String(localized: "请求路径: /v1",bundle: .module)) {
                    basePathField
                }
                .textCase(.none)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSpacing(0)
                
                Section(String(localized: "模型名称: (gpt-4o-mini)",bundle: .module)) {
                    baseModelField
                }
                .textCase(.none)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSpacing(0)
                
                Section(String(localized: "请求密钥", bundle: .module)) {
                    apiKeyField
                }
                .textCase(.none)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSpacing(0)
                
                
                Section{
                    HStack{
                        Spacer()
                        AnimatedButton(state:$buttonState, normal:
                                .init(title: String(localized: "测试后保存",bundle: .module),background: .blue,symbolImage: "person.crop.square.filled.and.at.rectangle"), success:
                                .init(title: String(localized: "测试/保存成功",bundle: .module), background: .green,symbolImage: "checkmark.circle"), fail:
                                .init(title: String(localized: "连接失败",bundle: .module),background: .red,symbolImage: "xmark.circle"), loadings: [
                                    .init(title: String(localized: "测试中...",bundle: .module), background: .cyan)
                                ]) { view in
                                    await view.next(.loading(1))
                                    
                                    data.trimAssistantAccountParameters()
                                    
                                    if data.key.isEmpty || data.host.isEmpty || isTestingAPI{
                                        try? await Task.sleep(for: .seconds(1))
                                        await view.next(.fail)
                                        return
                                    }
                                    
                                    self.isTestingAPI = true
                                    let success = await chatManager.test(account: data)
                                    
                                    await view.next(success ? .success : .fail)
                                    await MainActor.run{
                                        self.isTestingAPI = false
                                    }
                                    if success{
                                        await MainActor.run{
                                            self.saveOrChangeData()
                                        }
                                    }
                                }
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
                
                
            }
           
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        self.dismiss()
                    } label: {
                        Text("取消")
                    }.tint(.red)
                        .disabled(isTestingAPI)
                }
            
            }
            .disabled(isTestingAPI)
        }
    }
    
    private func saveOrChangeData(){
        data.trimAssistantAccountParameters()
       
        if data.host.isEmpty || data.key.isEmpty || data.model.isEmpty {

            openChatManager.shared.Toast?(.error, String(localized: "参数不能为空",bundle: .module) )
            return
        }
        
        if assistantAccouns.count == 0{
            data.current = true
        }
        
        
        if let index = assistantAccouns.firstIndex(where: {$0.id == data.id}){
            
            assistantAccouns[index] = data
            openChatManager.shared.Toast?(.success, String(localized: "添加成功",bundle: .module))
            self.dismiss()
            return
        }else{
            
            
            if assistantAccouns.filter({$0.host == data.host && $0.basePath == data.basePath && $0.model == data.model && $0.key == data.key}).count > 0 {
                openChatManager.shared.Toast?(.error, String(localized:  "重复数据",bundle: .module))
                return
            }
            
            assistantAccouns.insert(data, at: 0)
            openChatManager.shared.Toast?(.success, String(localized: "修改成功",bundle: .module))
            self.dismiss()
        }
        
        
       
        
    }
    
    private var apiKeyField: some View {
        HStack {
            if isSecured {
                SecureField("API Key", text: $data.key)
                    .textContentType(.password)
                    .autocapitalization(.none)
                    .customField(
                        icon: "key.icloud"
                    )
            } else {
                TextField("API Key", text: $data.key)
                    .textContentType(.none)
                    .autocapitalization(.none)
                    .customField(
                        icon: "key.icloud"
                    )
            }
            
            Image(systemName: isSecured ? "eye.slash" : "eye")
                .foregroundColor(isSecured ? .gray : .primary)
                .onTapGesture {
                    isSecured.toggle()
                    Haptic.impact()
                }
        }
    }
    
    private var baseNameField: some View {
        TextField("Name", text: $data.name)
            .autocapitalization(.none)
            .keyboardType(.URL)
            .customField(
                icon: "atom"
            )
    }
    
    private var baseHostField: some View {
        TextField("Host", text: $data.host)
            .autocapitalization(.none)
            .keyboardType(.URL)
            .customField(
                icon: "network"
            )
    }
    
    private var basePathField: some View {
        TextField("BasePath", text: $data.basePath)
            .autocapitalization(.none)
            .keyboardType(.URL)
            .customField(
                icon: "point.filled.topleft.down.curvedto.point.bottomright.up"
            )
    }
    
    private var baseModelField: some View {
        TextField("Model", text: $data.model)
            .autocapitalization(.none)
            .keyboardType(.URL)
            .customField(icon: "slider.horizontal.2.square.badge.arrow.down")
    }
    
  
}

