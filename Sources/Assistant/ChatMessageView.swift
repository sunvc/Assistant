

import SwiftUI
import Defaults
import MarkdownUI

struct ChatMessageView: View {
    @EnvironmentObject private var manager:openChatManager
    let message: ChatMessage
    let isLoading:Bool
    
    
    
    var body: some View {
        
        VStack{
            
            timestampView
            
            
            if message.request.count > 0 || manager.quote != nil {
                VStack{
                    if let quote = manager.quote {
                        HStack{
                            Spacer()
                            QuoteView(message: quote)
                            Spacer()
                        }
                        .padding(.bottom, 5)
                    }
                    if message.request.count > 0{
                        HStack {
                            Spacer()
                            
                            userMessageView
                                .if(isLoading) { view in
                                    view.lineLimit(2)
                                }
                                
                                
                            
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
            }
            
            
            if  !message.content.isEmpty {
                HStack{
                    assistantMessageView
                        
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
            }
        
            
            
        }
        .padding(.vertical, 4)
    }
    
    
    
    // MARK: - View Components
    
    
    /// 时间戳视图
    private var timestampView: some View {
        HStack {
            

            Spacer()
            Text("\(message.timestamp.formatString())" + "\n")
                .font(.caption2)
                .foregroundStyle(.gray)
                .padding(.horizontal)
        }
        .padding(.horizontal)
        .padding(.vertical, 5)
    }
    
    /// 用户消息视图
    private var userMessageView: some View {
        MarkdownCustomView(content: message.request)
            .padding()
            .foregroundColor(.primary)
            .background(.ultraThinMaterial)
            .overlay {
                Color.blue.opacity(0.2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .contextMenu{
                Button {
                    Task{
                        guard let player = await AudioManager.shared.Speak(message.request)else { return }
                        player.play()
                        Haptic.impact(.light)
                    }
                } label: {
                    Label(String(localized: "朗读",bundle: .module), systemImage: "speaker.wave.3.fill")
                }
                
                Button {
                    Haptic.impact(.light)
                    Clipboard.set(message.request)
                } label: {
                    Label(String(localized: "复制",bundle: .module), systemImage: "doc.on.doc")
                }
            }
        
    }
    
    /// AI助手消息视图
    private var assistantMessageView: some View {
        MarkdownCustomView(content: message.content)
            .padding()
            .foregroundColor(.primary)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .contextMenu{
                Button {
                    Task{
                        guard let player = await AudioManager.shared.Speak(message.content)else { return }
                        player.play()
                        Haptic.impact(.light)
                    }
                } label: {
                    Label(String(localized: "朗读",bundle: .module), systemImage: "speaker.wave.3.fill")
                }
                
                Button {
                    Haptic.impact(.light)
                    Clipboard.set(message.content)
                } label: {
                    Label(String(localized: "复制",bundle: .module), systemImage: "doc.on.doc")
                }
            }
        
    }
    
}


extension View{
    
    func copy(_ text:String)-> some View{
        self
            .onTapGesture(count: 2){
                Clipboard.set(text)
            }
    }
}

struct QuoteView:View {
    var message:String
    
    var body: some View {
        HStack(spacing: 5) {
            
            Text(verbatim: "\(message)")
                .lineLimit(1)
                .truncationMode(.tail)
                .font(.caption2)
            
            
            Image(systemName: "quote.bubble")
                .foregroundColor(.gray)
                .padding(.leading, 10)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    ChatMessageView(message: ChatMessage(id: "", timestamp: .now, chat: "", request: "", content: ""), isLoading: false)
}



