//
//  GamePhase.swift
//  ARSplatoonGame
//
//  Created by Kiro on 2025-01-09.
//

import Foundation

// MARK: - GamePhase

/// ゲームの現在のフェーズを表す列挙型
public enum GamePhase: String, CaseIterable, Codable {
    case waiting
    case connecting
    case playing
    case finished

    /// 表示名
    public var displayName: String {
        switch self {
        case .waiting:
            return "待機中"
        case .connecting:
            return "接続中"
        case .playing:
            return "ゲーム中"
        case .finished:
            return "終了"
        }
    }

    /// ゲームがアクティブかどうか
    public var isActive: Bool {
        switch self {
        case .playing:
            return true
        case .waiting, .connecting, .finished:
            return false
        }
    }

    /// パフォーマンス最適化プロファイル
    public var performanceProfile: PerformanceTarget {
        switch self {
        case .waiting:
            return .powerSaving
        case .connecting:
            return .balanced
        case .playing:
            return .performance
        case .finished:
            return .balanced
        }
    }
}



// MARK: - GamePhase + CustomStringConvertible

extension GamePhase: CustomStringConvertible {
    public var description: String {
        displayName
    }
}
