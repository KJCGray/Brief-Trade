//
//  Item.swift
//  BriefTrade
//
//  Created by JinZhaoXi on 2026/2/25.

import Foundation
import SwiftData

@Model
final class NewsRecord {
    var date: Date
    var title: String
    var summary: String
    var sentiment: String // 利多、利空 或 觀望
    
    init(date: Date = Date(), title: String, summary: String, sentiment: String) {
        self.date = date
        self.title = title
        self.summary = summary
        self.sentiment = sentiment
    }
}
