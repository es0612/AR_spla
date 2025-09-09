//
//  TutorialManager.swift
//  ARSplatoonGame
//
//  Created by ARSplatoonGame on 2024.
//

import Foundation
import SwiftUI

// MARK: - TutorialManager

/// チュートリアルとユーザーガイダンスを管理するクラス
@Observable
class TutorialManager {
    // MARK: - Properties

    // チュートリアルの状態
    var isShowingTutorial = false
    var currentTutorialStep: TutorialStep?
    var completedTutorials: Set<TutorialType> = []

    // ガイダンスの状態
    var isShowingGuidance = false
    var currentGuidance: GuidanceType?
    var guidanceMessage: String = ""

    // ヘルプの状態
    var isShowingHelp = false
    var helpContent: HelpContent?

    // ユーザー設定
    var showTutorials = true
    var showHints = true
    var showGuidance = true

    // MARK: - Initialization

    init() {
        loadUserPreferences()
    }

    // MARK: - Tutorial Management

    /// チュートリアルを開始する
    func startTutorial(_ type: TutorialType) {
        guard showTutorials, !completedTutorials.contains(type) else { return }

        currentTutorialStep = type.firstStep
        isShowingTutorial = true
    }

    /// 次のチュートリアルステップに進む
    func nextTutorialStep() {
        guard let currentStep = currentTutorialStep else { return }

        if let nextStep = currentStep.nextStep {
            currentTutorialStep = nextStep
        } else {
            completeTutorial()
        }
    }

    /// 前のチュートリアルステップに戻る
    func previousTutorialStep() {
        guard let currentStep = currentTutorialStep else { return }
        currentTutorialStep = currentStep.previousStep
    }

    /// チュートリアルを完了する
    func completeTutorial() {
        guard let currentStep = currentTutorialStep else { return }

        completedTutorials.insert(currentStep.tutorialType)
        currentTutorialStep = nil
        isShowingTutorial = false

        saveUserPreferences()
    }

    /// チュートリアルをスキップする
    func skipTutorial() {
        guard let currentStep = currentTutorialStep else { return }
        completedTutorials.insert(currentStep.tutorialType)
        currentTutorialStep = nil
        isShowingTutorial = false

        saveUserPreferences()
    }

    // MARK: - Guidance Management

    /// ガイダンスを表示する
    func showGuidance(_ type: GuidanceType, message: String? = nil) {
        guard showGuidance else { return }

        currentGuidance = type
        guidanceMessage = message ?? type.defaultMessage
        isShowingGuidance = true

        // 自動的に非表示にする（タイプに応じて）
        if type.autoHideDuration > 0 {
            Task {
                try? await Task.sleep(nanoseconds: UInt64(type.autoHideDuration * 1_000_000_000))
                await MainActor.run {
                    hideGuidance()
                }
            }
        }
    }

    /// ガイダンスを非表示にする
    func hideGuidance() {
        currentGuidance = nil
        guidanceMessage = ""
        isShowingGuidance = false
    }

    // MARK: - Help Management

    /// ヘルプを表示する
    func showHelp(_ content: HelpContent) {
        helpContent = content
        isShowingHelp = true
    }

    /// ヘルプを非表示にする
    func hideHelp() {
        helpContent = nil
        isShowingHelp = false
    }

    // MARK: - Utility Methods

    /// 特定のチュートリアルが完了しているかチェック
    func isTutorialCompleted(_ type: TutorialType) -> Bool {
        completedTutorials.contains(type)
    }

    /// チュートリアルをリセットする（デバッグ用）
    func resetTutorials() {
        completedTutorials.removeAll()
        saveUserPreferences()
    }

    /// ユーザー設定を更新する
    func updateSettings(showTutorials: Bool, showHints: Bool, showGuidance: Bool) {
        self.showTutorials = showTutorials
        self.showHints = showHints
        self.showGuidance = showGuidance
        saveUserPreferences()
    }

    // MARK: - Private Methods

    private func loadUserPreferences() {
        let defaults = UserDefaults.standard

        showTutorials = defaults.object(forKey: "showTutorials") as? Bool ?? true
        showHints = defaults.object(forKey: "showHints") as? Bool ?? true
        showGuidance = defaults.object(forKey: "showGuidance") as? Bool ?? true

        if let completedData = defaults.data(forKey: "completedTutorials"),
           let completed = try? JSONDecoder().decode(Set<TutorialType>.self, from: completedData) {
            completedTutorials = completed
        }
    }

    private func saveUserPreferences() {
        let defaults = UserDefaults.standard

        defaults.set(showTutorials, forKey: "showTutorials")
        defaults.set(showHints, forKey: "showHints")
        defaults.set(showGuidance, forKey: "showGuidance")

        if let completedData = try? JSONEncoder().encode(completedTutorials) {
            defaults.set(completedData, forKey: "completedTutorials")
        }
    }
}

// MARK: - TutorialType

/// チュートリアルの種類
enum TutorialType: String, CaseIterable, Codable {
    case firstLaunch
    case arSetup
    case gameControls
    case multiplayer

    var displayName: String {
        switch self {
        case .firstLaunch:
            return "初回起動"
        case .arSetup:
            return "AR設定"
        case .gameControls:
            return "ゲーム操作"
        case .multiplayer:
            return "マルチプレイヤー"
        }
    }

    var firstStep: TutorialStep {
        switch self {
        case .firstLaunch:
            return .welcome
        case .arSetup:
            return .arIntroduction
        case .gameControls:
            return .tapToShoot
        case .multiplayer:
            return .multiplayerIntroduction
        }
    }
}

// MARK: - TutorialStep

/// チュートリアルのステップ
enum TutorialStep: String, CaseIterable {
    // 初回起動チュートリアル
    case welcome
    case appOverview
    case permissions

    // AR設定チュートリアル
    case arIntroduction
    case planeDetection
    case gameFieldSetup

    // ゲーム操作チュートリアル
    case tapToShoot
    case playerMovement
    case scoring

    // マルチプレイヤーチュートリアル
    case multiplayerIntroduction
    case connectionSetup
    case gameStart

    var tutorialType: TutorialType {
        switch self {
        case .welcome, .appOverview, .permissions:
            return .firstLaunch
        case .arIntroduction, .planeDetection, .gameFieldSetup:
            return .arSetup
        case .tapToShoot, .playerMovement, .scoring:
            return .gameControls
        case .multiplayerIntroduction, .connectionSetup, .gameStart:
            return .multiplayer
        }
    }

    var title: String {
        switch self {
        case .welcome:
            return "AR Splatoonへようこそ！"
        case .appOverview:
            return "アプリの概要"
        case .permissions:
            return "権限の設定"
        case .arIntroduction:
            return "ARについて"
        case .planeDetection:
            return "平面検出"
        case .gameFieldSetup:
            return "ゲームフィールドの設置"
        case .tapToShoot:
            return "インクの発射"
        case .playerMovement:
            return "プレイヤーの移動"
        case .scoring:
            return "スコアリング"
        case .multiplayerIntroduction:
            return "マルチプレイヤーモード"
        case .connectionSetup:
            return "接続の設定"
        case .gameStart:
            return "ゲーム開始"
        }
    }

    var content: String {
        switch self {
        case .welcome:
            return "AR Splatoonは、現実空間でスプラトゥーン風の対戦ゲームを楽しめるアプリです。"
        case .appOverview:
            return "ARカメラを使って現実空間にゲームフィールドを表示し、他のプレイヤーと対戦します。"
        case .permissions:
            return "ゲームを楽しむために、カメラとローカルネットワークへのアクセスを許可してください。"
        case .arIntroduction:
            return "ARKit技術を使用して、現実空間にゲームオブジェクトを配置します。"
        case .planeDetection:
            return "デバイスを動かして周囲をスキャンし、平面を検出してください。"
        case .gameFieldSetup:
            return "検出された平面にゲームフィールドが自動的に配置されます。"
        case .tapToShoot:
            return "画面をタップしてインクを発射し、相手の陣地を塗りつぶしましょう。"
        case .playerMovement:
            return "デバイスを持って移動することで、ゲーム内でのプレイヤー位置が変わります。"
        case .scoring:
            return "制限時間内により多くの面積を塗った方が勝利です。"
        case .multiplayerIntroduction:
            return "近くにいる他のプレイヤーとローカル通信で対戦できます。"
        case .connectionSetup:
            return "マルチプレイヤーメニューから相手を検索し、接続してください。"
        case .gameStart:
            return "接続が完了したら、ARゲーム画面でゲームを開始できます。"
        }
    }

    var icon: String {
        switch self {
        case .welcome:
            return "hand.wave"
        case .appOverview:
            return "info.circle"
        case .permissions:
            return "checkmark.shield"
        case .arIntroduction:
            return "arkit"
        case .planeDetection:
            return "viewfinder"
        case .gameFieldSetup:
            return "square.grid.3x3"
        case .tapToShoot:
            return "hand.tap"
        case .playerMovement:
            return "figure.walk"
        case .scoring:
            return "target"
        case .multiplayerIntroduction:
            return "person.2"
        case .connectionSetup:
            return "wifi"
        case .gameStart:
            return "play"
        }
    }

    var nextStep: TutorialStep? {
        switch self {
        case .welcome:
            return .appOverview
        case .appOverview:
            return .permissions
        case .permissions:
            return nil
        case .arIntroduction:
            return .planeDetection
        case .planeDetection:
            return .gameFieldSetup
        case .gameFieldSetup:
            return nil
        case .tapToShoot:
            return .playerMovement
        case .playerMovement:
            return .scoring
        case .scoring:
            return nil
        case .multiplayerIntroduction:
            return .connectionSetup
        case .connectionSetup:
            return .gameStart
        case .gameStart:
            return nil
        }
    }

    var previousStep: TutorialStep? {
        switch self {
        case .welcome:
            return nil
        case .appOverview:
            return .welcome
        case .permissions:
            return .appOverview
        case .arIntroduction:
            return nil
        case .planeDetection:
            return .arIntroduction
        case .gameFieldSetup:
            return .planeDetection
        case .tapToShoot:
            return nil
        case .playerMovement:
            return .tapToShoot
        case .scoring:
            return .playerMovement
        case .multiplayerIntroduction:
            return nil
        case .connectionSetup:
            return .multiplayerIntroduction
        case .gameStart:
            return .connectionSetup
        }
    }
}

// MARK: - GuidanceType

/// ガイダンスの種類
enum GuidanceType: String, CaseIterable {
    case arPlaneDetection
    case arTrackingLimited
    case networkSearching
    case gameStarting
    case inkCooldown
    case playerHit

    var defaultMessage: String {
        switch self {
        case .arPlaneDetection:
            return "デバイスを動かして平面を検出してください"
        case .arTrackingLimited:
            return "明るい場所でデバイスをゆっくり動かしてください"
        case .networkSearching:
            return "近くのプレイヤーを検索中..."
        case .gameStarting:
            return "ゲームを開始します"
        case .inkCooldown:
            return "インク発射のクールダウン中です"
        case .playerHit:
            return "インクに当たりました！"
        }
    }

    var icon: String {
        switch self {
        case .arPlaneDetection:
            return "viewfinder"
        case .arTrackingLimited:
            return "exclamationmark.triangle"
        case .networkSearching:
            return "magnifyingglass"
        case .gameStarting:
            return "play.circle"
        case .inkCooldown:
            return "clock"
        case .playerHit:
            return "exclamationmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .arPlaneDetection:
            return .blue
        case .arTrackingLimited:
            return .orange
        case .networkSearching:
            return .green
        case .gameStarting:
            return .blue
        case .inkCooldown:
            return .yellow
        case .playerHit:
            return .red
        }
    }

    var autoHideDuration: TimeInterval {
        switch self {
        case .arPlaneDetection, .arTrackingLimited:
            return 0 // 手動で非表示
        case .networkSearching:
            return 0 // 手動で非表示
        case .gameStarting:
            return 3
        case .inkCooldown:
            return 2
        case .playerHit:
            return 3
        }
    }
}

// MARK: - HelpContent

/// ヘルプコンテンツ
struct HelpContent {
    let title: String
    let sections: [HelpSection]

    static let gameHelp = HelpContent(
        title: "ゲームヘルプ",
        sections: [
            HelpSection(
                title: "基本操作",
                items: [
                    HelpItem(title: "インク発射", description: "画面をタップしてインクを発射します"),
                    HelpItem(title: "移動", description: "デバイスを持って移動することでプレイヤーが移動します"),
                    HelpItem(title: "ゲーム終了", description: "左上の「終了」ボタンでゲームを終了できます")
                ]
            ),
            HelpSection(
                title: "ゲームルール",
                items: [
                    HelpItem(title: "勝利条件", description: "制限時間内により多くの面積を塗った方が勝利"),
                    HelpItem(title: "インク効果", description: "相手のインクに当たると一時的に動けなくなります"),
                    HelpItem(title: "クールダウン", description: "インク発射には0.5秒のクールダウンがあります")
                ]
            ),
            HelpSection(
                title: "トラブルシューティング",
                items: [
                    HelpItem(title: "平面が検出されない", description: "明るい場所でテクスチャのある平面をスキャンしてください"),
                    HelpItem(title: "接続できない", description: "両方のデバイスが同じWi-Fiネットワークに接続されているか確認してください"),
                    HelpItem(title: "動作が重い", description: "他のアプリを終了してメモリを確保してください")
                ]
            )
        ]
    )
}

// MARK: - HelpSection

struct HelpSection {
    let title: String
    let items: [HelpItem]
}

// MARK: - HelpItem

struct HelpItem {
    let title: String
    let description: String
}
