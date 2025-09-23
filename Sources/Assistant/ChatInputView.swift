

import SwiftUI
import Combine
import Defaults
import GRDB
import PhotosUI

struct ChatInputView: View {
    @EnvironmentObject private var manager:openChatManager
    
    @Binding var text: String
    
    @Binding var selectImage:UIImage?
    @Binding var selectFile:URL?
    
    let onSend: (String) -> Void
    
    @State private var showPromptChooseView = false
    @FocusState private var isFocusedInput: Bool

    @State private var showSelectFile:Bool = false
    @State private var showCamera:Bool = false
    @State private var showPhoto:Bool = false
    var body: some View {
        VStack {
            
            HStack() {
                PromptLabelView(prompt: manager.chatPrompt)
            }.padding( 5)
            
            
            HStack(spacing: 10) {
                if let image = selectImage{
                    Menu{
                        Button(role: .destructive){
                            self.selectImage = nil
                        }label: {
                            Label(String(localized: "清除",bundle: .module), systemImage: "eraser")
                        }
                    }label: {
                        Image(uiImage: image)
                            .frame(width: 50, height: 50)
                            .aspectRatio(contentMode: .fill)
                            .clipShape(Circle())
                            .background(
                                ColoredBorder(lineWidth: 5, cornerRadius: 100,padding: 0 )
                            )
                            .padding(.vertical, 5)
                            
                    }
                    
                }
                inputField
                    .disabled(manager.isLoading)
                rightActionButton
                
            }
            .padding(.horizontal)
            .padding(.top, 5)
            .animation(.default, value: text)
            
            
            
        }
        .background(.background)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30))
        .onTapGesture {
            self.isFocusedInput = !manager.isLoading
            Haptic.impact()
        }
        .shadow(color: .gray.opacity(0.3), radius: 2, x: 0, y: -5)
        .photo($showPhoto, selectImage: $selectImage)
        .camera($showCamera, selectImage: $selectImage)
        .fileImport($showSelectFile, outfile: $selectFile, types: [.pdf, .plainText])
    }
    
    // MARK: - Subviews
    private var inputField: some View {
        HStack {
            TextField(String(localized: "给智能助手发消息",bundle: .module), text: $text, axis: .vertical)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .focused($isFocusedInput)
                .frame(minHeight: 40)
                .font(.subheadline)
                .onChange(of: isFocusedInput){
                    manager.isFocusedInput = $0
                }
            
            PromptButtonView()
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
        
    }
    
    @ViewBuilder
    private var rightActionButton: some View {
        
        if manager.isLoading{
            Button(action: {
                manager.cancellableRequest?.cancelRequest()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 35, height: 35)
                    .foregroundColor(.blue)
                    .opacity(0.7)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 2)
            }
            .transition(.scale)
        }else{
            if !text.isEmpty {
                // 发送按钮
                Button(action: {
                    
                    self.text = text.trimmingCharacters(in: .whitespaces)
                    if text.count > 1{
                        onSend(text)
                        self.selectImage = nil
                        isFocusedInput = false
                    }else {
                        // "至少2个字符"
                    }
                    
                    
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 35, height: 35)
                        .foregroundColor(.blue)
                        .opacity(0.7)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 2)
                }
                .transition(.scale)
            } else {
                
                // 附件菜单
                Menu {
  
                    Button{
                        self.showPhoto = true
                    }label: {
                        Label(String(localized: "图片",bundle: .module), systemImage: "photo.fill")
                    }
                    Button{
                        self.showCamera = true
                    }label: {
                        Label(String(localized: "拍照",bundle: .module), systemImage: "camera.fill")
                    }
                    
                    
                    Button{
                        self.showSelectFile = true
                    }label: {
                        Label(String(localized: "文件",bundle: .module), systemImage: "folder.fill")
                    }
                    
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 35, height: 35)
                        .foregroundColor(.blue)
                        .opacity(0.7)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 2)
                        .transition(.scale)
                }
                .transition(.scale)
                

            }
        }
        
        
    }
    
    @ViewBuilder
    func PromptLabelView(prompt: ChatPrompt?)-> some View{
        HStack {
            
            if let prompt {
                Menu{
                    Button(role: .destructive){
                        manager.chatPrompt = nil
                    }label: {
                        Label(String(localized: "清除",bundle: .module), systemImage: "eraser")
                    }
                }label: {
                    
                    Text(prompt.title)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.blue.opacity(0.8))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: .blue.opacity(0.2), radius: 3, x: 0, y: 2)
                    
                }
            }
            
            if let file = selectFile{
                Menu{
                    Button(role: .destructive){
                        self.selectFile = nil
                    }label: {
                        Label(String(localized: "清除",bundle: .module), systemImage: "eraser")
                    }
                }label: {
                    Text(verbatim: file.lastPathComponent)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .padding(3)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .frame(maxWidth: (min(screenWidth, screenHeight) / 2 - 50))
                        .shadow(color: .gray.opacity(0.3), radius: 3, x: -1, y: 1)
                        
                }
                
            }
            
            Spacer()
            
            
            
            if let quote = manager.quote{
                Menu{
                    Button(role: .destructive){
                        manager.quote = nil
                    }label: {
                        Label(String(localized: "清除",bundle: .module), systemImage: "eraser")
                    }
                }label: {
                    QuoteView(message: quote)
                        .onAppear{
                            Task.detached(priority: .background) {
                                try? await  DatabaseManager.shared.dbPool.write { db in
                                    DispatchQueue.main.async{
                                        openChatManager.shared.chatgroup = nil
                                    }
                                    
                                    // 如果不存在，创建一个新的
                                    let group = ChatGroup(
                                        id: UUID().uuidString,
                                        timestamp: .now,
                                        name: quote,
                                        host: ""
                                    )
                                    try group.insert(db)
                                    openChatManager.shared.chatgroup = group
                                }
                            }
                        }
                }
            }
        }
        .padding(.horizontal)
    }
    
}




