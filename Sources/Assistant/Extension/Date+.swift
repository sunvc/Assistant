//
//  Date+.swift
//  Deepseek
//
//  Created by lynn on 2025/7/2.
//

import Foundation

extension Date {
    func formatString(format: String = "yyyy-MM-dd HH:mm:ss") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
    
}
