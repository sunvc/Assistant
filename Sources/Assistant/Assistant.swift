// The Swift Programming Language
// https://docs.swift.org/swift-book


import SwiftUI
import Defaults
import Combine
import GRDB
import PhotosUI




public struct AssistantView<Content: View>:View {
    
    @Default(.assistantAccouns) var assistantAccouns
    
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var manager = openChatManager.shared
    @StateObject private var audioManager = AudioManager.shared
    @State private var inputText:String = ""
    
    @FocusState private var isInputActive: Bool
    
    @State private var showMenu: Bool = false
    @State private var rotateWhenExpands: Bool = false
    @State private var disablesInteractions: Bool = true
    @State private var disableCorners: Bool = true
    
    @State private var showChangeGroupName:Bool = false
    
    @State private var offsetX: CGFloat = 0
    @State private var offsetHistory:CGFloat = 0
    @State private var rotation:Double = 0
    @State private var selectItem: PhotosPickerItem? = nil
    @State private var selectImage:UIImage? = nil
    @State private var showSelectFile:Bool = false
    @State private var selectFile:URL? = nil
    
    @ViewBuilder var content: ()-> Content
    
    var close: (() -> ())? = nil
    
    public init( imageName: String? = nil,
                 content: @escaping ()-> Content,
                 toast: ((ToastMode, String)-> Void)? = nil,
                 close: (() -> ())? = nil ) {
        
        if let imageName{
            openChatManager.shared.imageName = .main(imageName)
        }
        openChatManager.shared.Toast = toast
        self.close = close
        self.content = content
        
    }
    
    
    public var body: some View {
        
            VStack {
                if  manager.chatgroup != nil || manager.isLoading {
                    
                    ChatMessageListView()
                    .onTapGesture {
                        self.hideKeyboard()
                        Haptic.impact()
                    }
                    
                }else{
                    VStack{
                        Spacer()
                        
                        VStack{
                            Group{
                                switch manager.imageName {
                                case .module(let string):
                                    Image(string, bundle: .module)
                                        .resizable()
                                case .main(let string):
                                    Image(string, bundle: .main)
                                        .resizable()
                                }
                            }
                            .scaledToFit()
                            .frame(width: 100)
                            .VButton( onRelease: { _ in true })
                            
                            Text(String(localized: "嗨! 我是智能助手",bundle: .module))
                                .font(.title)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 10)
                            
                            Text(String(localized: "我可以帮你搜索，答疑，写作，请把你的任务交给我吧！",bundle: .module))
                                .multilineTextAlignment(.center)
                                .padding(.vertical)
                                .font(.body)
                                .foregroundStyle(.gray)
                            
                        }
                        
                        Spacer()
                    }
                    .transition(.slide)
                    .onTapGesture {
                        self.hideKeyboard()
                        Haptic.impact()
                    }
                }
                
                
                
                
                Spacer()
               
            }
            .safeAreaInset(edge: .bottom) {
                // 底部输入框
                ChatInputView(
                    text: $inputText,
                    selectImage: $selectImage,
                    selectFile: $selectFile,
                    onSend: sendMessage
                )
                .padding(.bottom)
                .simultaneousGesture(
                    DragGesture()
                        .onEnded({ value in
                            Log.debug(value.translation, value.startLocation)
                            if -value.translation.height > 200{
                                Haptic.impact(.heavy)
                                self.showMenu.toggle()
                            }else if value.translation.height > 100 {
                                self.hideKeyboard()
                            }
                            
                        })
                )
               
                
            }
            .safeAreaInset(edge: .top){
                if audioManager.playingState != .end{
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay { MusicInfo().transition(.move(edge: .leading)) }
                        .frame(height: 70)
                        .overlay(alignment: .bottom, content: {
                            Rectangle()
                                .fill(.gray.opacity(0.3))
                                .frame(height: 1)
                        })
                        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 10, topTrailingRadius: 10))
                        .shadow(radius: 3)
                        .padding(.horizontal, 5)
                        .transition(.move(edge: .trailing))
                }
            }
            .popView(isPresented: $showChangeGroupName){
                showChangeGroupName = false
            }content: {
                if let chatgroup = manager.chatgroup{
                    CustomAlertWithTextField( $showChangeGroupName, text: chatgroup.name) { text in
                        manager.updateGroupName(groupId: chatgroup.id, newName: text)
                    }
                }else {
                    Spacer()
                        .onAppear{
                            self.showChangeGroupName = false
                        }
                }
            }
            .toolbar { principalToolbarContent }
            .sheet(isPresented: $showMenu) {
                OpenChatHistoryView(show: $showMenu)
                    .onChange(of: showMenu) { value in
                        DispatchQueue.main.async {
                           self.hideKeyboard()
                        }
                    }
                    .customPresentationCornerRadius(20)
            }
            .onAppear{ manager.inAssistant = true }
            .onDisappear{ manager.inAssistant = false }
            .environmentObject(manager)
            .navigationDestination(isPresented: manager.showPage) {
                switch manager.page {
                case .assistant:
                    AssistantSettingsView()
                case .voice:
                    SpeakSettingsView()
                default:
                    EmptyView()
                    
                }
            }
        
        
        
    }
    
    
    private var principalToolbarContent: some ToolbarContent {
        
        ToolbarItem(placement: .topBarTrailing) {
            if  manager.isLoading{
                StreamingLoadingView()
                    .transition(.scale)
            }else{
                
                
               
                    Menu {
                        if manager.chatgroup != nil{
                            Section{
                                Button(role: .destructive){
                                    self.showChangeGroupName.toggle()
                                }label: {
                                   
                                    Label(String(localized:"重命名",bundle: .module) , systemImage: "eraser.line.dashed")
                                }
                            }
                            
                            Section{
                                Button{
                                    manager.cancellableRequest?.cancelRequest()
                                    manager.chatgroup = nil
                                    Haptic.impact()
                                } label:{
                                    Label(String(localized: "新对话",bundle: .module), systemImage: "plus.message")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.green, Color.primary)
                                }
                            }
                        }
                        Section{
                            Button{
                                Haptic.impact(.heavy)
                                self.showMenu.toggle()
                            } label:{
                                Label(String(localized: "对话列表",bundle: .module), systemImage: "list.number")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.green, Color.primary)
                            }
                        }
                       
                        
                        
                        
                        Section{
                            Button{
                                manager.page = .assistant
                                Haptic.impact()
                            }label:{
                                Label(String(localized: "设置",bundle: .module), systemImage: "gear.circle")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.green, Color.primary)
                            }
                            
                            Button{
                                manager.page = .voice
                                Haptic.impact()
                            }label:{
                                Label(String(localized: "语音设置",bundle: .module), systemImage: "gear.circle")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.green, Color.primary)
                            }
                        }
                        
                        content()
                        
                        
                    } label: {
                        if let chatGroup = manager.chatgroup{
                            HStack{
                                
                                Text(chatGroup.name.trimmingSpaceAndNewLines)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .padding(.trailing, 3)
                                
                                Image(systemName: "chevron.down")
                                    .imageScale(.large)
                                    .foregroundStyle(.gray.opacity(0.5))
                                    .imageScale(.small)
                                
                                Spacer()
                                
                            }
                            .frame(maxWidth: 150)
                            .foregroundStyle(.foreground)
                            .transition(.scale)
                        }else{
                            HStack{
                                
                                
                                Text( String(localized: "新对话",bundle: .module))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .padding(.trailing, 3)
                                
                                Image(systemName: "chevron.down")
                                    .imageScale(.large)
                                    .foregroundStyle(.gray.opacity(0.5))
                                    .imageScale(.small)
                                
                            }
                            .frame(maxWidth: 150)
                            .foregroundStyle(.foreground)
                            .transition(.scale)
                            .onTapGesture {
                                self.showMenu = true
                                Haptic.impact(.heavy)
                            }
                        }
                        
                        
                    
                    
                }
                
            }
            
        }
        
    }


    
    // 发送消息
    private func sendMessage(_ text: String) {
        
        guard assistantAccouns.first(where: {$0.current}) != nil else {
            openChatManager.shared.Toast?(.error, String(localized: "没有配置账户"))
            manager.page = .assistant
            return
        }
        do{
            if let filePath = self.documentUrl("\(UUID().uuidString).png"),
               let data = selectImage?.pngData(){
                try data.write(to: filePath)
                manager.currentMessage.image = filePath
            }
           
        }catch{
            debugPrint(error.localizedDescription)
        }
        
        if !text.isEmpty {
           
            
            DispatchQueue.main.async {
                manager.resetMessage()
                manager.isLoading = true
                manager.currentMessage.request = text
                self.inputText = ""
            }
            
            manager.chatsStream(text: text) { partialResult in
                switch partialResult {
                case .success(let result):
                   
                    if let res = result.choices.first?.delta.content {
                        
                        DispatchQueue.main.async {
                            manager.currentMessage.content += res
                        }
                        if openChatManager.shared.inAssistant {
                            DispatchQueue.main.async{
                                Haptic.selection()
                            }
                        }
                    }
                    
                case .failure(let error):
                    //Handle chunk error here
                    Log.error(error)
                    
                    openChatManager.shared.Toast?(.error, error.localizedDescription)
                   
                }
            } completion: {  error in
                DispatchQueue.main.async{
                    Haptic.impact()
                }
                if let error{
                    openChatManager.shared.Toast?(.error, error.localizedDescription)
                    Log.error(error)
                     DispatchQueue.main.async{
                        manager.isLoading = false
                         manager.resetMessage()
                    }
                    return
                }
                
                let newGroup = openChatManager.shared.chatgroup ??
                ChatGroup(id: UUID().uuidString, timestamp: .now,
                          name: String(openChatManager.shared.currentMessage.request.trimmingSpaceAndNewLines.prefix(10)),
                          host: "")
                
                Task.detached(priority: .userInitiated) {
                    do{
                        
                        let responseMessage:ChatMessage = {
                            var message = openChatManager.shared.currentMessage
                            message.chat = newGroup.id
                            return message
                        }()
                        
                        try await DatabaseManager.shared.dbPool.write { db in
                            
                            if openChatManager.shared.chatgroup == nil {
                                try newGroup.insert(db)
                                 DispatchQueue.main.async{
                                    openChatManager.shared.chatgroup = newGroup
                                }
                            }
                            
                            try responseMessage.insert(db)
                        }
                        DispatchQueue.main.async {
                            openChatManager.shared.resetMessage()
                            manager.isLoading = false
                            self.hideKeyboard()
                        }
                        
                       
                    }catch{
                        debugPrint(error.localizedDescription)
                        openChatManager.shared.Toast?(.error, error.localizedDescription)
                    }
                }
            }
            
        }
    }
    
}

struct CustomAlertWithTextField: View {
    @State private var text: String = ""
    @Binding var show: Bool
    var confirm: (String) -> ()
    /// View Properties
    ///
    init(_ show: Binding<Bool>, text: String, confirm: @escaping (String) -> Void) {
        self.text = text
        self._show = show
        self.confirm = confirm
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.badge.key.fill")
                .font(.title)
                .foregroundStyle(.white)
                .frame(width: 65, height: 65)
                .background {
                    Circle()
                        .fill(.blue.gradient)
                        .background {
                            Circle()
                                .fill(.background)
                                .padding(-5)
                        }
                }
            
            Text("修改分组名称")
                .fontWeight(.semibold)
            
            Text("此名称用来查找历史分组使用")
                .multilineTextAlignment(.center)
                .font(.caption)
                .foregroundStyle(.gray)
                .padding(.top, 5)
            
            
            
            TextField("输入分组名称", text: $text, axis: .vertical)
                .frame(maxHeight: 150)
                .padding(.vertical, 10)
                .padding(.horizontal, 15)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.bar)
                }
                .padding(.vertical, 10)
            
            HStack(spacing: 10) {
                Button {
                    show = false
                } label: {
                    Text("取消")
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 25)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.red.gradient)
                        }
                }
                
                Button {
                    show = false
                    confirm(text)
                } label: {
                    Text("确认")
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 25)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.blue.gradient)
                        }
                }
            }
        }
        .frame(width: UIScreen.main.bounds.width * 0.8)
        .padding([.horizontal, .bottom], 20)
        .background {
            RoundedRectangle(cornerRadius: 25)
                .fill(.background)
                .padding(.top, 25)
        }
    }
}

struct StreamingLoadingView: View {
    @EnvironmentObject private var chatManager:openChatManager
    @State private var dots = ""
    @State private var timer: Timer.TimerPublisher = Timer.publish(every: 0.3, on: .main, in: .common)
    @State private var timerCancellable: Cancellable?
    
    var userType:String{
        if chatManager.isLoading && chatManager.currentMessage.content.isEmpty {
            return "思考中"
        }else{
           return  "正在输入\(dots)"
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            // AI头像或图标
            Image(systemName: "brain")
                .foregroundColor(.blue)
                .imageScale(.medium)
            
            // 思考中的动画点
            Text(userType)
                .foregroundColor(.secondary)
                .font(.subheadline)
                .animation(.bouncy, value: dots)
        }
        .onAppear {
            self.timerCancellable = self.timer.connect()
        }
        .onDisappear {
            self.timerCancellable?.cancel()
        }
        .onReceive(timer) { _ in
            withAnimation {
                if dots.count >= 3 {
                    dots = ""
                } else {
                    dots += "."
                }
            }
        }
    }
}
