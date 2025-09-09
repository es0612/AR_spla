//
//  LocalizationManager.swift
//  ARSplatoonGame
//
//  Created by Developer on 2024/12/19.
//

import Foundation
import SwiftUI

// MARK: - LocalizationManager

/// 国際化対応を管理するクラス
@Observable
class LocalizationManager {
    static let shared = LocalizationManager()

    /// 現在の言語設定
    var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "selected_language")
            updateBundle()
        }
    }

    /// 利用可能な言語一覧
    let availableLanguages = [
        "ja": "日本語",
        "en": "English"
    ]

    /// 現在のバンドル
    private var bundle: Bundle = .main

    private init() {
        // 保存された言語設定を読み込み、なければシステム言語を使用
        let savedLanguage = UserDefaults.standard.string(forKey: "selected_language")
        let systemLanguage = Locale.current.language.languageCode?.identifier ?? "ja"

        if let saved = savedLanguage, availableLanguages.keys.contains(saved) {
            currentLanguage = saved
        } else if availableLanguages.keys.contains(systemLanguage) {
            currentLanguage = systemLanguage
        } else {
            currentLanguage = "ja" // デフォルトは日本語
        }

        updateBundle()
    }

    /// バンドルを更新
    private func updateBundle() {
        if let path = Bundle.main.path(forResource: currentLanguage, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            self.bundle = bundle
        } else {
            bundle = Bundle.main
        }
    }

    /// ローカライズされた文字列を取得
    func localizedString(for key: String, comment _: String = "") -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    /// フォーマット付きローカライズ文字列を取得
    func localizedString(for key: String, arguments: CVarArg...) -> String {
        let format = localizedString(for: key)
        return String(format: format, arguments: arguments)
    }

    /// 現在の言語に基づいた日付フォーマッターを取得
    func dateFormatter(style: DateFormatter.Style = .medium) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: currentLanguage)
        formatter.dateStyle = style
        return formatter
    }

    /// 現在の言語に基づいた時間フォーマッターを取得
    func timeFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: currentLanguage)
        formatter.timeStyle = .medium
        return formatter
    }

    /// 現在の言語に基づいた数値フォーマッターを取得
    func numberFormatter(style: NumberFormatter.Style = .decimal) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: currentLanguage)
        formatter.numberStyle = style
        return formatter
    }

    /// パーセンテージフォーマッターを取得
    func percentageFormatter() -> NumberFormatter {
        let formatter = numberFormatter(style: .percent)
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter
    }

    /// 現在の言語がRTL（右から左）かどうかを判定
    var isRTL: Bool {
        let locale = Locale(identifier: currentLanguage)
        return Locale.characterDirection(forLanguage: locale.language.languageCode?.identifier ?? "ja") == .rightToLeft
    }

    /// 現在の言語の表示名を取得
    var currentLanguageDisplayName: String {
        availableLanguages[currentLanguage] ?? "日本語"
    }
}

/// String拡張でローカライゼーションを簡単に使用
extension String {
    /// ローカライズされた文字列を取得
    var localized: String {
        LocalizationManager.shared.localizedString(for: self)
    }

    /// フォーマット付きローカライズ文字列を取得
    func localized(with arguments: CVarArg...) -> String {
        LocalizationManager.shared.localizedString(for: self, arguments: arguments)
    }
}

/// SwiftUI用のローカライゼーション環境キー
struct LocalizationEnvironmentKey: EnvironmentKey {
    static let defaultValue = LocalizationManager.shared
}

extension EnvironmentValues {
    var localization: LocalizationManager {
        get { self[LocalizationEnvironmentKey.self] }
        set { self[LocalizationEnvironmentKey.self] = newValue }
    }
}
