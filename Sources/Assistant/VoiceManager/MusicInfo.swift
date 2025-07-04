//
//  MusicInfo.swift
//  AppleMusicBottomSheet
//
//  Created by Balaji on 18/03/23.
//

import SwiftUI


/// Resuable File
public struct MusicInfo: View {
    @StateObject private var audioManager = AudioManager.shared
    @State private var progress: CGFloat = 0
    @State private var duration: TimeInterval = 0
    
    @State private var currentTime: TimeInterval = 0
    @State private var isPlaying: Bool = false
    @State private var onActive: Bool = false
    @State private var waitTimes: TimeInterval = 0
   
    
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    public var body: some View {
        HStack(spacing: 0) {
            VStack{
                if let audioUrl = audioManager.audioUrl{
                    ShareLink(item: audioUrl, preview: SharePreview("pushback.mp3")){
                        Image(systemName: "display.and.arrow.down")
                    }.simultaneousGesture(
                        TapGesture()
                            .onEnded({ _ in
                                audioManager.speakPlayer?.pause()
                            })
                    )
                    
                }
            }
            .if(audioManager.loading) { view in
                ProgressView()
            }
            
          
            /// Adding Matched Geometry Effect (Hero Animation
            VStack{
                Spacer()
                
                if let player = audioManager.speakPlayer, let audio = player.url{
                    WaveformScrubber( url: audio, progress: $progress, info: { info in
                        self.duration = info.duration
                    }, onGestureActive: { active in
                        onActive = active
                        player.currentTime = duration * progress
                    })
                    .overlay( alignment: .top){
                        HStack {
                            Text(formatTime(currentTime))
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Spacer(minLength: 0)
                            
                            Text(formatTime(duration))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }else{
                    VStack{
                        Spacer()
                        HStack {
                            Spacer(minLength: 0)
                            Text(formatTime(waitTimes / 10))
                                .font(.body)
                                .foregroundColor(.red)
                            Text(String(localized: "正在处理中...",bundle: .module))
                                .font(.body)
                                .foregroundColor(.gray)
                            Spacer(minLength: 0)
                        }
                        Spacer()
                    }
                   
                }
                
                
            }
            .padding(.leading, 10)
            .padding(.trailing)
            
            
            Spacer(minLength: 0)
            
            HStack{
                Button {
                    withAnimation {
                        if let player = audioManager.speakPlayer{
                            
                            if isPlaying{
                                player.pause()
                            }else{
                                player.play()
                            }
                        }
                    }
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                }
                
                
                Button {
                    withAnimation {
                        audioManager.speakPlayer?.stop()
                        audioManager.speakPlayer = nil
                        audioManager.playingState = .end
                    }
                    
                } label: {
                    Image(systemName: "xmark.seal.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                }
                .padding(.leading, 10)
            }
           
            
        }
    
        .foregroundColor(.primary)
        .padding(.horizontal)
        .padding(.bottom, 5)
        .frame(height: 70)
        .contentShape(Rectangle())
        .onReceive(timer) { _ in
            if let player = audioManager.speakPlayer {
                currentTime = player.currentTime
                if !onActive{
                    progress =  currentTime / duration
                }
                self.isPlaying = player.isPlaying
            }else{
                waitTimes += 1
            }
        }
    }
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    
    func safeFrameWidth(progress: CGFloat, width: CGFloat) -> CGFloat {
        guard progress.isFinite, width.isFinite, width > 0 else { return 0.1 }
        let value = abs(progress * width)
        return min(max(value, 0.1), width)
    }
}

