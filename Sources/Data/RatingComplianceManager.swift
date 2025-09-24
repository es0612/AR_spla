//
//  RatingComplianceManager.swift
//  ARSplatoonGame
//
//  Created by Developer on 2024/12/19.
//

import Foundation
import SwiftUI

// MARK: - RatingComplianceManager

/// レーティングとコンプライアンス管理クラス
@Observable
class RatingComplianceManager {
    static let shared = RatingComplianceManager()

    // MARK: - レーティング情報

    /// 地域別レーティング情報
    struct RegionalRating {
        let region: RegionalSettingsManager.Region
        let ratingSystem: RatingSystem
        let ageRating: String
        let contentDescriptors: [String]
        let interactiveElements: [String]
        let requirements: [String]
    }

    /// レーティングシステム
    enum RatingSystem: String, CaseIterable {
        case esrb = "ESRB" // アメリカ
        case pegi = "PEGI" // ヨーロッパ
        case cero = "CERO" // 日本
        case grac = "GRAC" // 韓国
        case csrr = "CSRR" // 中国（仮想）
        case iarc = "IARC" // 国際（グローバル）

        var displayName: String {
            switch self {
            case .esrb: return "ESRB (Entertainment Software Rating Board)"
            case .pegi: return "PEGI (Pan European Game Information)"
            case .cero: return "CERO (Computer Entertainment Rating Organization)"
            case .grac: return "GRAC (Game Rating and Administration Committee)"
            case .csrr: return "CSRR (China Software Rating Regulation)"
            case .iarc: return "IARC (International Age Rating Coalition)"
            }
        }
    }

    // MARK: - 地域別レーティング定義

    private let regionalRatings: [RegionalSettingsManager.Region: RegionalRating] = [
        .unitedStates: RegionalRating(
            region: .unitedStates,
            ratingSystem: .esrb,
            ageRating: "E10+",
            contentDescriptors: [
                "Cartoon Violence",
                "Users Interact Online"
            ],
            interactiveElements: [
                "Users Interact Online",
                "Shares Location"
            ],
            requirements: [
                "COPPA compliance for users under 13",
                "Parental controls implementation",
                "Data collection transparency"
            ]
        ),

        .europe: RegionalRating(
            region: .europe,
            ratingSystem: .pegi,
            ageRating: "PEGI 7",
            contentDescriptors: [
                "Non-realistic violence in a child-friendly setting",
                "Online gameplay"
            ],
            interactiveElements: [
                "Users Interact Online",
                "Location Sharing"
            ],
            requirements: [
                "GDPR compliance",
                "Right to be forgotten implementation",
                "Explicit consent for data processing",
                "Data portability support"
            ]
        ),

        .japan: RegionalRating(
            region: .japan,
            ratingSystem: .cero,
            ageRating: "CERO A (全年齢対象)",
            contentDescriptors: [
                "軽微な暴力表現",
                "オンライン要素"
            ],
            interactiveElements: [
                "オンライン対戦",
                "位置情報の使用"
            ],
            requirements: [
                "個人情報保護法への準拠",
                "未成年者への配慮",
                "適切な利用時間の推奨"
            ]
        ),

        .korea: RegionalRating(
            region: .korea,
            ratingSystem: .grac,
            ageRating: "전체이용가 (All Ages)",
            contentDescriptors: [
                "가상폭력 (Virtual Violence)",
                "온라인 (Online)"
            ],
            interactiveElements: [
                "온라인 상호작용 (Online Interaction)",
                "위치 정보 사용 (Location Usage)"
            ],
            requirements: [
                "게임산업진흥에 관한 법률 준수",
                "청소년 보호 조치",
                "게임 시간 제한 권고",
                "셧다운제 고려 (만 16세 미만)"
            ]
        ),

        .china: RegionalRating(
            region: .china,
            ratingSystem: .csrr,
            ageRating: "适合所有年龄 (All Ages)",
            contentDescriptors: [
                "轻微暴力 (Mild Violence)",
                "在线功能 (Online Features)"
            ],
            interactiveElements: [
                "在线互动 (Online Interaction)",
                "位置信息 (Location Information)"
            ],
            requirements: [
                "网络安全法合规",
                "未成年人保护",
                "游戏时长限制",
                "实名认证要求",
                "防沉迷系统"
            ]
        ),

        .global: RegionalRating(
            region: .global,
            ratingSystem: .iarc,
            ageRating: "IARC 7+",
            contentDescriptors: [
                "Mild Violence",
                "Online Interaction"
            ],
            interactiveElements: [
                "Users Interact Online",
                "Shares Location",
                "Digital Purchases"
            ],
            requirements: [
                "International privacy law compliance",
                "Multi-regional age verification",
                "Comprehensive parental controls",
                "Cultural sensitivity measures"
            ]
        )
    ]

    // MARK: - コンプライアンスチェック

    /// 現在の地域設定に基づくレーティング情報を取得
    func getCurrentRating() -> RegionalRating? {
        let regionalSettings = RegionalSettingsManager.shared
        return regionalRatings[regionalSettings.currentRegion]
    }

    /// 年齢制限チェック
    func checkAgeCompliance(userAge: Int) -> ComplianceResult {
        guard getCurrentRating() != nil else {
            return ComplianceResult(isCompliant: false, issues: ["レーティング情報が見つかりません"])
        }

        let regionalSettings = RegionalSettingsManager.shared
        let minimumAge = regionalSettings.ageRating.minimumAge

        var issues: [String] = []

        if userAge < minimumAge {
            issues.append("年齢制限: \(minimumAge)歳以上が対象です")
        }

        // 地域別の特別な制限
        switch regionalSettings.currentRegion {
        case .korea:
            if userAge < 16 {
                issues.append("韓国: 16歳未満のユーザーは深夜時間帯の利用が制限されます")
            }
        case .china:
            if userAge < 18 {
                issues.append("中国: 18歳未満のユーザーは平日1.5時間、休日3時間の利用制限があります")
            }
        default:
            break
        }

        return ComplianceResult(isCompliant: issues.isEmpty, issues: issues)
    }

    /// データ収集コンプライアンスチェック
    func checkDataCollectionCompliance(userAge: Int) -> ComplianceResult {
        let regionalSettings = RegionalSettingsManager.shared
        var issues: [String] = []

        switch regionalSettings.currentRegion {
        case .unitedStates:
            if userAge < 13, !regionalSettings.dataCollectionRestricted {
                issues.append("COPPA: 13歳未満のユーザーからのデータ収集には保護者の同意が必要です")
            }
        case .europe:
            if !regionalSettings.dataCollectionRestricted {
                issues.append("GDPR: データ処理には明示的な同意が必要です")
            }
        case .china:
            if userAge < 14 {
                issues.append("中国個人情報保護法: 14歳未満のユーザーからのデータ収集には保護者の同意が必要です")
            }
        default:
            break
        }

        return ComplianceResult(isCompliant: issues.isEmpty, issues: issues)
    }

    /// ソーシャル機能コンプライアンスチェック
    func checkSocialFeaturesCompliance(userAge: Int) -> ComplianceResult {
        let regionalSettings = RegionalSettingsManager.shared
        var issues: [String] = []

        if regionalSettings.socialFeaturesRestricted {
            issues.append("地域設定によりソーシャル機能が制限されています")
        }

        switch regionalSettings.currentRegion {
        case .china:
            if userAge < 18 {
                issues.append("中国: 18歳未満のユーザーはソーシャル機能の利用が制限されます")
            }
        case .korea:
            if userAge < 14 {
                issues.append("韓国: 14歳未満のユーザーはオンライン機能の利用に制限があります")
            }
        default:
            break
        }

        return ComplianceResult(isCompliant: issues.isEmpty, issues: issues)
    }

    /// 総合コンプライアンスチェック
    func performComprehensiveComplianceCheck(userAge: Int) -> ComplianceReport {
        let ageCompliance = checkAgeCompliance(userAge: userAge)
        let dataCompliance = checkDataCollectionCompliance(userAge: userAge)
        let socialCompliance = checkSocialFeaturesCompliance(userAge: userAge)

        let allIssues = ageCompliance.issues + dataCompliance.issues + socialCompliance.issues
        let isFullyCompliant = ageCompliance.isCompliant && dataCompliance.isCompliant && socialCompliance.isCompliant

        return ComplianceReport(
            isFullyCompliant: isFullyCompliant,
            ageCompliance: ageCompliance,
            dataCompliance: dataCompliance,
            socialCompliance: socialCompliance,
            allIssues: allIssues,
            recommendations: generateRecommendations(userAge: userAge)
        )
    }

    // MARK: - 推奨事項生成

    private func generateRecommendations(userAge: Int) -> [String] {
        let regionalSettings = RegionalSettingsManager.shared
        var recommendations: [String] = []

        // 年齢に基づく推奨事項
        if userAge < 13 {
            recommendations.append("保護者の監督の下でプレイすることをお勧めします")
            recommendations.append("プレイ時間を制限することをお勧めします")
        }

        // 地域別の推奨事項
        switch regionalSettings.currentRegion {
        case .korea:
            if userAge < 16 {
                recommendations.append("深夜時間帯（午前0時〜6時）の利用を避けることをお勧めします")
            }
        case .china:
            if userAge < 18 {
                recommendations.append("平日は1.5時間以内、休日は3時間以内の利用をお勧めします")
                recommendations.append("定期的な休憩を取ることをお勧めします")
            }
        case .japan:
            recommendations.append("適度な休憩を取りながらプレイすることをお勧めします")
        default:
            recommendations.append("健康的なゲームプレイを心がけることをお勧めします")
        }

        return recommendations
    }

    // MARK: - レーティング表示用情報

    /// レーティング表示用の情報を取得
    func getRatingDisplayInfo() -> RatingDisplayInfo? {
        guard let rating = getCurrentRating() else { return nil }

        return RatingDisplayInfo(
            ratingSystem: rating.ratingSystem.displayName,
            ageRating: rating.ageRating,
            contentDescriptors: rating.contentDescriptors,
            interactiveElements: rating.interactiveElements
        )
    }
}

// MARK: - ComplianceResult

struct ComplianceResult {
    let isCompliant: Bool
    let issues: [String]
}

// MARK: - ComplianceReport

struct ComplianceReport {
    let isFullyCompliant: Bool
    let ageCompliance: ComplianceResult
    let dataCompliance: ComplianceResult
    let socialCompliance: ComplianceResult
    let allIssues: [String]
    let recommendations: [String]
}

// MARK: - RatingDisplayInfo

struct RatingDisplayInfo {
    let ratingSystem: String
    let ageRating: String
    let contentDescriptors: [String]
    let interactiveElements: [String]
}

// MARK: - RatingComplianceEnvironmentKey

struct RatingComplianceEnvironmentKey: EnvironmentKey {
    static let defaultValue = RatingComplianceManager.shared
}

extension EnvironmentValues {
    var ratingCompliance: RatingComplianceManager {
        get { self[RatingComplianceEnvironmentKey.self] }
        set { self[RatingComplianceEnvironmentKey.self] = newValue }
    }
}
