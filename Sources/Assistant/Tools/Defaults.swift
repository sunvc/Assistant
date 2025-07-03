//
//  Defaults.swift
//  Deepseek
//
//  Created by lynn on 2025/7/2.
//

@_exported import Defaults
import Foundation


public extension Defaults.Key{
    convenience init(_ name: String, _ defaultValue: Value, iCloud: Bool = false){
        self.init(name, default: defaultValue, iCloud: iCloud)
    }
}


public extension Defaults.Keys{
    static let lang = Key<String>("DeepseekLocalePreferredLanguagesFirst","")
    static let assistantAccouns = Key<[AssistantAccount]>("DeepseekAssistantAccount",[], iCloud: true)
    static let historyMessageCount = Key<Int>("DeepseekHistoryMessageCount", 10)
}

extension AssistantAccount: Defaults.Serializable{}
