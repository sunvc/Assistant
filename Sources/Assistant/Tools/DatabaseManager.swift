//
//  DatabaseManager.swift
//  Deepseek
//
//  Created by lynn on 2025/7/2.
//
import GRDB
import Foundation

public class DatabaseManager: @unchecked Sendable {
    
    public static let shared = try! DatabaseManager()
    
    public let dbPool: DatabasePool
    public let localPath:URL
    
    private init() throws {
        let local = try FileManager.default.url( for: .documentDirectory,
                                                 in: .userDomainMask,
                                                 appropriateFor: nil,
                                                 create: true)
        let path = local.appendingPathComponent("Deepseek.sqlite", conformingTo: .database)
        self.localPath = path
        // DatabasePool 只在这里创建一次
        self.dbPool = try DatabasePool(path: path.path)
        
        try ChatGroup.createInit(dbPool: dbPool)
        try ChatMessage.createInit(dbPool: dbPool)
        try ChatPrompt.createInit(dbPool: dbPool)
    }
    
    public static func documentUrl(_ fileName: String? = nil) -> URL?{
        do{
            let filePaeh =  try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            if let fileName{
                return filePaeh.appendingPathComponent(fileName, conformingTo: .fileURL)
            }
           return filePaeh
        }catch{
            debugPrint(error.localizedDescription)
            return nil
        }
        
    }
    
    public static func getVoiceDirectory() -> URL? {
        guard let containerURL = documentUrl() else { return nil }
        
        let imagesDirectory = containerURL.appendingPathComponent("Voice")
        
        // If the directory doesn't exist, create it
        if !FileManager.default.fileExists(atPath: imagesDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                Log.error("Failed to create images directory: \(error.localizedDescription)")
                return nil
            }
        }
        return imagesDirectory
    }

}
