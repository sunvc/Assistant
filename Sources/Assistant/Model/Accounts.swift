//
//  Accounts.swift
//  Deepseek
//
//  Created by lynn on 2025/7/2.
//
import Foundation


public struct AssistantAccount: Codable, Identifiable, Equatable,Hashable, Sendable{
    public var id:String = UUID().uuidString
    public var current:Bool = false
    public var timestamp:Date = .now
    public var name:String = String(localized: "智能助手", bundle: .module)
    public var host:String
    public var basePath:String
    public var key:String
    public var model:String
    
    public func toBase64() -> String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return data.base64EncodedString()
    }
    
    public init( current: Bool = false, name: String = "", host: String, basePath: String, key: String, model: String) {
        if name.isEmpty{
            self.name = String(localized: "智能助手", bundle: .module)
        }
        self.current = current
        self.name = name
        self.host = host
        self.basePath = basePath
        self.key = key
        self.model = model
    }
    
    
    public init?(base64: String) {
        guard let data = Data(base64Encoded: base64), let decoded = try? JSONDecoder().decode(Self.self, from: data) else {
            return nil
        }
        self = decoded
        self.id = UUID().uuidString
    }
    
    
    

}


public extension AssistantAccount{
    mutating func trimAssistantAccountParameters() {
        name = name.trimmingSpaceAndNewLines
        host = host.trimmingSpaceAndNewLines
        host = host.removeHTTPPrefix()
        basePath = basePath.trimmingSpaceAndNewLines
        key = key.trimmingSpaceAndNewLines
        model = model.trimmingSpaceAndNewLines
    }

}

extension String{
    var trimmingSpaceAndNewLines: String{
        self.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
    }
    
    /// 移除 URL 的 HTTP/HTTPS 前缀
    func removeHTTPPrefix() -> String {
        return self.replacingOccurrences(of: "^(https?:\\/\\/)?", with: "", options: .regularExpression)
    }
}

public enum ToastMode {
    case error
    case success
}
