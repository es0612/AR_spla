# Requirements Document

## Introduction

ARでスプラトゥーンのような対戦ゲームをiOSネイティブアプリとして開発する。SwiftUIとARKitを使用し、まずは一対一のローカル通信対戦機能を実装する。プレイヤーは現実空間でARオブジェクトを使って対戦し、相手の陣地を塗りつぶすことで勝利を目指す。

## Requirements

### Requirement 1

**User Story:** プレイヤーとして、ARカメラを通して現実空間にゲームフィールドを表示したい。そうすることで、物理的な空間でゲームを楽しめる。

#### Acceptance Criteria

1. WHEN アプリを起動し、ARセッションを開始する THEN システムは現実空間にゲームフィールドを表示する SHALL
2. WHEN デバイスを動かす THEN ARオブジェクトは現実空間に固定されて表示される SHALL
3. IF 平面検出が完了していない THEN システムは平面をスキャンするよう促すメッセージを表示する SHALL

### Requirement 2

**User Story:** プレイヤーとして、近くにいる他のプレイヤーとローカル通信で対戦したい。そうすることで、同じ空間で一緒にゲームを楽しめる。

#### Acceptance Criteria

1. WHEN ゲームを開始する THEN システムはMultipeer Connectivityを使用して近くのデバイスを検索する SHALL
2. WHEN 他のプレイヤーが見つかる THEN システムは接続の招待を送信または受信できる SHALL
3. WHEN 接続が確立される THEN システムは対戦準備完了状態になる SHALL
4. IF 接続が切断される THEN システムはエラーメッセージを表示し、再接続を試行する SHALL

### Requirement 3

**User Story:** プレイヤーとして、ARで表示されるインクガンを使って相手の陣地を塗りたい。そうすることで、スプラトゥーンのような対戦体験ができる。

#### Acceptance Criteria

1. WHEN 画面をタップする THEN システムはタップした方向にインクを発射する SHALL
2. WHEN インクが地面に当たる THEN システムはその場所を自分の色で塗る SHALL
3. WHEN インクが相手プレイヤーに当たる THEN システムは相手プレイヤーを一時的に無効化する SHALL
4. WHEN 自分がインクに当たる THEN システムは一定時間移動速度を低下させる SHALL

### Requirement 4

**User Story:** プレイヤーとして、ゲームの進行状況と勝敗を確認したい。そうすることで、競争的なゲーム体験ができる。

#### Acceptance Criteria

1. WHEN ゲームが開始される THEN システムは制限時間のカウントダウンを表示する SHALL
2. WHEN 制限時間が終了する THEN システムは塗った面積を計算し、勝者を決定する SHALL
3. WHEN ゲーム中 THEN システムは現在の塗り面積の割合をリアルタイムで表示する SHALL
4. WHEN ゲームが終了する THEN システムは結果画面を表示し、再戦オプションを提供する SHALL

### Requirement 5

**User Story:** プレイヤーとして、直感的なUI操作でゲームを楽しみたい。そうすることで、ARゲームに集中できる。

#### Acceptance Criteria

1. WHEN ゲームを開始する THEN システムはSwiftUIで作られた直感的なメニューを表示する SHALL
2. WHEN AR画面を表示中 THEN システムは最小限のUIオーバーレイのみを表示する SHALL
3. WHEN 設定を変更したい THEN システムは一時停止メニューからアクセス可能な設定画面を提供する SHALL
4. IF デバイスがARをサポートしていない THEN システムは適切なエラーメッセージを表示する SHALL