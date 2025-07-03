//
//  SpeakSettingsView.swift
//  pushback
//
//  Created by lynn on 2025/5/14.
//
import SwiftUI
import Defaults

public struct SpeakSettingsView:View {
    @Default(.ttsConfig) var voiceConfig
  
    @Default(.voiceList) var voiceList
    @StateObject private var manager = AudioManager.shared
    
    var groupedVoices: [String: [VoiceManager.MicrosoftVoice]] {
        if searchText.isEmpty {
            return Dictionary(grouping: voiceList, by: { $0.locale })
        } else {
            let query = searchText.lowercased()

            let results = voiceList.filter { voice in
                voice.displayName.lowercased().contains(query)
                || voice.localName.lowercased().contains(query)
                || voice.shortName.lowercased().contains(query)
                || voice.gender.lowercased().contains(query)
                || voice.locale.lowercased().contains(query)
                || voice.localeName.lowercased().contains(query)
            }

            return Dictionary(grouping: results, by: { $0.locale })
        }
    }

    
    @State private var showVoiceSelect:Bool = false
    @State private var showFormatSelect:Bool = false
    @State private var searchText:String = ""
    
    public var body: some View {
        Form{
            
            
            Section {
                baseRegionField
            }header: {
                Text(String(localized: "语音服务区域",bundle: .module))
                    .padding(.leading)
            }
            .textCase(.none)
            .listRowInsets(EdgeInsets())
            .listRowSpacing(0)
            
            
            Section{
                baseVoiceField
                    .VButton( onRelease: { _ in
                        self.showVoiceSelect.toggle()
                        self.hideKeyboard()
                        return true
                    })
            }header: {
                Text(String(localized: "默认语音",bundle: .module))
                    .padding(.leading)
            }
            .textCase(.none)
            .listRowInsets(EdgeInsets())
            .listRowSpacing(0)
            
            Section {
                HStack{
                    Text(verbatim: "-100")
                    Slider(value:Binding(get: {
                        Double(voiceConfig.defaultRate)
                    }, set: { value in
                        voiceConfig.defaultRate = Int(value)
                    }) , in: -100...100)
                    Text(verbatim: "100")
                }
                .onChange(of: voiceConfig.defaultRate) { _ in
                    Haptic.impact(.light, limitFrequency: true)
                }
            } header: {
                HStack{
                    Text(String(localized: "默认语速",bundle: .module))
                    Spacer()
                    Text(verbatim: "\(voiceConfig.defaultRate)")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                   
                }
            }
            .textCase(.none)
            .listRowSpacing(0)
            
            
            Section {
                HStack{
                    Text(verbatim: "-100")
                    Slider(value: Binding(get: {
                        Double(voiceConfig.defaultPitch)
                    }, set: { value in
                        voiceConfig.defaultPitch = Int(value)
                    }), in: -100...100)
                    Text(verbatim:"100")
                }
                .onChange(of: voiceConfig.defaultPitch) { _ in
                    Haptic.impact(.light,limitFrequency: true)
                }
            } header: {
               HStack{
                   Text(String(localized: "默认语调",bundle: .module))
                   Spacer()
                   Text(verbatim: "\(voiceConfig.defaultPitch)")
                       .font(.body)
                       .fontWeight(.bold)
                       .foregroundStyle(.blue)
                  
               }
           }
            .textCase(.none)
            .listRowSpacing(0)
            
            Section {
                baseFormatField
                    .VButton(onRelease: {_ in
                        showFormatSelect.toggle()
                        return true
                    })
            }header: {
                Text(String(localized: "默认音频格式",bundle: .module))
                    .padding(.leading)
            }
            .textCase(.none)
            .listRowInsets(EdgeInsets())
            .listRowSpacing(0)
        }
        .navigationTitle(String(localized: "语音配置",bundle: .module))
        .sheet(isPresented: $showVoiceSelect) { VoiceSelectView() }
        .sheet(isPresented: $showFormatSelect) {
            NavigationStack{
                Picker(String(localized: "选择格式",bundle: .module), selection: $voiceConfig.defaultFormat) {
                    ForEach(VoiceManager.AudioFormat.allCases, id: \.rawValue) { item in
                        Text(verbatim: "\(item.rawValue)")
                            .foregroundStyle(voiceConfig.defaultFormat == item ? .green : .gray)
                            .tag(item)
                    }
                }
                .pickerStyle(.wheel)
                .navigationTitle(String(localized: "默认音频格式",bundle: .module))
                .navigationBarTitleDisplayMode(.inline)
            }.presentationDetents([.height(300)])
               
        }
        .toolbar {
            ToolbarItem{
                Button{
                    guard manager.playingState == .end  else { return }
                    Task {
                        guard let player = await AudioManager.shared.Speak(
                            String(localized: "欢迎使用 \(AudioManager.AppName)",bundle: .module),noCache: true) else {
                            return
                        }
                        player.play()
                        Haptic.impact(.light)
                        
                    }
                }label:{
                    Label(String(localized: "试听",bundle: .module), systemImage: manager.playingState == .playing ? "livephoto.play" : "play.circle")
                        .animation(.default, value: manager.playingState)
                }
            }
        }
        
    }
    
    @ViewBuilder
    func VoiceSelectView() -> some View{
        NavigationStack{
            ScrollViewReader {  proxy in
                ScrollView{
                    LazyVStack(alignment: .leading, pinnedViews: [.sectionHeaders]) {
                        ForEach(groupedVoices.keys.sorted(), id: \.self ){locale in
                            
                            Section {
                                ForEach(groupedVoices[locale]!,id: \.id){ item in
                                    HStack{
                                        Text(verbatim: "\(item.localName)")
                                            .padding(.horizontal)
                                            .fontWeight(item.shortName == voiceConfig.defaultVoice ? .bold : .light)
                                        Text(verbatim: "(\(item.gender))")
                                        Spacer()
                                        Button {
                                            voiceConfig.defaultVoice = item.shortName
                                            self.showVoiceSelect.toggle()
                                            Haptic.impact()
                                        }label:{
                                            Image(systemName: "cursorarrow.click")
                                                .imageScale(.large)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        item.shortName == voiceConfig.defaultVoice ? Color.green : Color.gray.opacity(0.1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .padding(.horizontal)
                                    
                                    .id(item.shortName)
                                
                                    
                                    
                                }
                            } header: {
                                HStack{
                                    Spacer()
                                    Text(locale)
                                        .fontWeight(.black)
                                        .padding(.trailing)
                                        .foregroundStyle(Color.accentColor)
                                        .blendMode(.difference)
                                }
                            }
                            
                            
                        }
                    }
                    if voiceList.count == 0{
                        ProgressView {
                            Label(String(localized: "加载中",bundle: .module), systemImage: "ellipsis")
                        }
                    }
                }
                .onAppear{
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        proxy.scrollTo(voiceConfig.defaultVoice, anchor: .center)
                    }
                }
                .task(priority: .background, {
                    do{
                        let client = try VoiceManager()
                        _ = try await client.listVoices()
                        withAnimation {
                            proxy.scrollTo(voiceConfig.defaultVoice, anchor: .center)
                        }
                    }catch{
                        debugPrint(error)
                    }
                })
                .navigationTitle(String(localized: "选择语音模型",bundle: .module))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem {
                        Image(systemName: "gobackward")
                            .VButton(onRelease: {_ in
                                Defaults.reset(.voiceList)
                                Task{
                                    let client = try VoiceManager()
                                    _ = try await client.listVoices()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                                        withAnimation {
                                            proxy.scrollTo(voiceConfig.defaultVoice, anchor: .center)
                                        }
                                    }
                                }
                                
                                return true
                            })
                    }
                    ToolbarItem(placement: .topBarLeading) {
                        Image(systemName: "pin.fill")
                            .VButton(onRelease: {_ in
                                withAnimation {
                                    proxy.scrollTo(voiceConfig.defaultVoice, anchor: .center)
                                }
                                return true
                            })
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        
        }
    }
    
    private var baseRegionField: some View {
        TextField("Region", text: $voiceConfig.region)
            .autocapitalization(.none)
            .customField(
                icon: "atom", false
            )
    }
    
    private var baseVoiceField: some View {
        TextField("Voice", text: $voiceConfig.defaultVoice)
            .autocapitalization(.none)
            .disabled(true)
            .customField(
                icon: "speaker.wave.2.bubble.left", false
            )
    }
    
    
    
    private var baseFormatField: some View {
        TextField("Format", text: Binding(get: {  voiceConfig.defaultFormat.rawValue }, set: { _ in}))
            .autocapitalization(.none)
            .disabled(true)
            .customField(
                icon: "paintbrush", false
            )
    }
    
    
}

