//
//  File name:     AudioManager.swift
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Blog  :        https://uuneo.com
//  E-mail:        to@uuneo.com

//  Description:

//  History:
//  Created by uuneo on 2024/12/10.


import Foundation
import AVFoundation
import SwiftUI
import ActivityKit

@MainActor
public class AudioManager: NSObject, ObservableObject,  AVAudioPlayerDelegate, Sendable{
    
    static let shared = AudioManager()
    
    private override init() {
        super.init()
    }
    
    var Toast:((ToastMode, String) -> ())? = nil
    
    @Published var defaultSounds:[URL] =  []
    @Published var customSounds:[URL] =  []
    
    @Published var soundID: SystemSoundID = 0
    
    @Published var audioUrl:URL? = nil
    @Published var speakPlayer:AVAudioPlayer? = nil
    
    @Published var loading:Bool = false
    
    @Published var playingState:playerType = .end
    
    enum playerType{
        case progress
        case playing
        case pause
        case end
    }
    
    /// 通用文件保存方法
    public func saveSound(url sourceUrl: URL, name lastPath: String? = nil) -> Bool{
        // 获取 App Group 的共享铃声目录路径
        guard let groupDirectoryUrl = DatabaseManager.documentUrl() else { return false }
        
        // 构造目标路径：使用传入的自定义文件名（lastPath），否则使用源文件名
        let groupDestinationUrl = groupDirectoryUrl.appendingPathComponent(lastPath ?? sourceUrl.lastPathComponent)
        
        
        
        do {
            // 如果目标文件已存在，先删除旧文件
            if FileManager.default.fileExists(atPath: groupDestinationUrl.path) {
                try? FileManager.default.removeItem(at: groupDestinationUrl)
            }
            // 拷贝文件到共享目录（实现“保存”操作）
            try FileManager.default.copyItem(at: sourceUrl, to: groupDestinationUrl)
            
            // 弹出成功提示（使用 Toast）
            Toast?(.success, String(localized: "保存成功",bundle: .module))
            return true
        } catch {
            // 如果保存失败，弹出错误提示
            Toast?(.error, error.localizedDescription)
            return false
        }
        
    }
    
    public func deleteSound(url: URL) {

        do{
            // 删除本地 sounds 目录下的铃声文件
            try FileManager.default.removeItem(at: url)
        }catch{
            debugPrint(error.localizedDescription)
            Toast?(.error, error.localizedDescription)
        }
        

    }
    
    public func playAudio(url: URL? = nil) {
        // 先释放之前的 SystemSoundID（如果有），避免内存泄漏或重复播放
        AudioServicesDisposeSystemSoundID(self.soundID)
        
        // 如果传入的 URL 为空，或者与当前正在播放的是同一个音频，则认为是“停止播放”的操作
        guard let audio = url, audioUrl != url else {
            self.audioUrl = nil
            self.soundID = 0
            return
        }
        
        // 设置当前正在播放的音频
        self.audioUrl = audio
        
        // 创建 SystemSoundID，用于播放系统音效（仅支持较小的音频文件，通常小于30秒）
        AudioServicesCreateSystemSoundID(audio as CFURL, &self.soundID)
        
        // 播放音频，播放完成后执行回调
        AudioServicesPlaySystemSoundWithCompletion(self.soundID) {
            // 如果回调时仍是当前音频（防止播放期间被替换）
            if self.audioUrl == url {
                // 释放资源
                AudioServicesDisposeSystemSoundID(self.soundID)
                DispatchQueue.main.async {
                    // 重置播放状态
                    self.audioUrl = nil
                    self.soundID = 0
                }
            }
        }
    }
    
    static func playNumber(number: String){
        guard let number = Int(number) else { return }
        AudioServicesPlaySystemSound(SystemSoundID(1200 + number))
    }
    
    public func convertAudioToCAF(inputURL: URL) async -> URL?  {
        
        do{
            
            let fileName = inputURL.deletingPathExtension().lastPathComponent
            
            let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).caf")
            // 如果输出文件已存在，则先删除，防止导出失败
            if FileManager.default.fileExists(atPath: outputURL.path) {
                try FileManager.default.removeItem(at: outputURL)
            }
            
            // 创建 AVAsset 用于处理输入音频资源
            let asset = AVAsset(url: inputURL)
            
            // 创建导出会话，使用 "Passthrough" 预设保持原始音频格式
            guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else { return nil }
            // 获取音频时长（异步加载）
            let assetDurationSeconds = try await asset.load(.duration)
            
            // 设置导出时间范围：如果音频大于 30 秒，最多只导出 29.9 秒
            // AVFoundation 的时间精度有限，设置 29.9 更保险
            let maxDurationCMTime = CMTime(seconds: 29.9, preferredTimescale: 600)
            if assetDurationSeconds > maxDurationCMTime {
                exportSession.timeRange = CMTimeRange(start: .zero, duration: maxDurationCMTime)
            }
            
            // 设置导出文件类型和输出路径
            exportSession.outputFileType = .caf
            exportSession.outputURL = outputURL
            
            // 开始异步导出
            await exportSession.export()
            
            // 根据导出状态返回结果
            return exportSession.status == .completed ? outputURL : nil
            
        }catch{
            return nil
        }
        
        
    }
    
    public func Speak(_ text: String, noCache:Bool = false) async -> AVAudioPlayer? {
        
        do{

           let session =  AVAudioSession.sharedInstance()

            try session.setCategory(.playback, mode: .default)

            try session.setActive(true)

            let start = DispatchTime.now()
            await MainActor.run {
                withAnimation(.default) {
                    self.loading = true
                    self.playingState = .progress
                }
                
            }
            
            let client = try VoiceManager()
            let audio = try await client.createVoice(text: text,noCache: noCache)
            await MainActor.run{
                self.audioUrl  = audio
            }
            
            
            let player = try AVAudioPlayer(contentsOf: audio)
            await MainActor.run {
                self.speakPlayer = player
                self.speakPlayer?.delegate = self
                self.playingState = .playing
                self.loading = false
            }
            
            let end = DispatchTime.now()
            let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
            debugPrint("运行时间：",Double(nanoTime) / 1_000_000_000)
            return self.speakPlayer
        }catch{
            await MainActor.run {
                self.speakPlayer = nil
                self.loading = false
                self.playingState = .end
            }
            debugPrint(error.localizedDescription)
            return nil
        }
    }
    
    nonisolated public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async{
            withAnimation(.default) {
                self.playingState = .end
                self.speakPlayer = nil
            }
        }
    }
   
    public static var AppName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? "Pushback"
    }

    
}

