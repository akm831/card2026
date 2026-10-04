# Godot試作01・Android APK

## 今回の範囲

`godot/`にGodot **4.6 stable・GDScript・Compatibility描画**のプロジェクトを追加。HTML v18は維持する。今回は「夢の超特急」の国会決戦1戦のみ。

- 4初期デッキから選択、双方HP30、基本3コスト。
- 手札保持、初期5枚、通常1枚、上限7の選択破棄。
- 人物最大3人、成長、停止・手札戻し、配置解除。
- 敵の手札保持・複数行動・予告・固定対象・3コスト内の組み合わせ評価。
- 攻撃予告の対象選択、1手／ターンUndo、勝利確定。
- カード使用時の動き、攻撃・ブロックの数字、成長表示、短い合成SEとミュート。
- 戦闘・Undo履歴・乱数のローカル保存と再開。HTMLの保存とは独立。

準備戦、カード報酬、編成・収集、公害の街、選挙はGodotへまだ移していない。準備成果は開始画面で選択して代用する。v18の新カード12枚の定義も共有データへ入っているが、Godot試作の使用対象ではなく、使用／保存読込で拒否する。

## 使い方

### Android

GitHubの **Actions → Godot Android APK → 成功した実行 → Artifacts** からZIPを取得し、`card2026-godot-preview.apk`を取り出す。端末へ転送し、ファイルを開いてインストールする。初回はファイル管理アプリ等に「この提供元のアプリを許可」が必要になることがある。横画面を推奨。

パッケージID：`com.akm831.card2026.godotpreview`。試作専用の別アプリ。ARM64とARMv7対応。Google Play公開用ではない。ゲーム側のインターネット権限は使わない。

### MacのGodotエディタ

既存のFlutter／Android SDK／外部ストレージ構成は変更しない。リポジトリを取得し、ルートでフォントを用意する：

```sh
python3 scripts/prepare_font.py
```

Godot 4.6で`godot/project.godot`をインポートし、F6/F5で起動。SDKの新規導入はMacで遊ぶだけなら不要。Linux用の`prepare_godot.sh`をMacで実行する必要はない。

## GitHub Actions

`.github/workflows/android.yml`はmainへの該当変更push、PR、手動実行で起動する。手動実行はActionsの「Run workflow」。

1. HTML回帰と共有カードデータ一致を確認。
2. Godot4.6と対応テンプレート、日本語フォントを準備。
3. インポート、戦闘の比較テスト、画面のヘッドレス動作テスト。
4. JDK17、Android API35・Build Tools35.0.1でAPKを生成。
5. APK署名を検証し、APK・SHA256・BUILD_INFOをArtifactsへ保存（14日）。

日本語フォントはGoogle FontsのNoto Sans JP。取得先のコミットとSHA256を固定し、SIL OFL 1.1のライセンスを同梱する。エンジンとテンプレートは同じ4.6 stableを使う。Android向けETC2/ASTCのインポート設定も有効化する。

## 署名と更新時のセーブ

**Secrets未設定でも試遊APKを作れるが、その場合は毎回一時署名鍵を生成する。** 異なるビルドへ更新する際、署名が違うとアンインストールが必要になり、アプリ内セーブも消える。ローカルで提供したAPKとGitHubのAPKの署名も別になる。

継続して同じアプリへ更新したい場合は、リポジトリのSettings → Secrets and variables → Actionsで次の3つを登録する：

| Secret | 内容 |
|---|---|
| `ANDROID_TEST_KEYSTORE_BASE64` | 固定の試遊用keystoreをBase64化した内容 |
| `ANDROID_TEST_KEY_ALIAS` | 鍵のalias |
| `ANDROID_TEST_KEY_PASSWORD` | keystore／鍵の共通パスワード |

鍵はMacなどで一度だけ作り、安全な場所へ保存する。以下は対話的にパスワードを入力する例。テスト鍵を製品公開鍵として流用しない。

```sh
keytool -genkeypair -keystore card2026-test.keystore -alias card2026test \
  -keyalg RSA -keysize 2048 -validity 10000
base64 < card2026-test.keystore | tr -d '\n' | pbcopy
```

Base64値を1つ目のSecretへ貼り付け、aliasとパスワードも登録する。パスワードはGodotの対応を考え英数字を推奨。keystore本体とパスワードはGitへコミットしない。設定後のビルドには`BUILD_INFO.txt`に`stable-test-key`と記録される。未設定なら`temporary-preview-key`。

将来の製品版では別途リリース署名・AAB・ストア配布を整備する。今回Play公開は実行していない。

## 構造・比較検証

- `godot/scripts/battle_engine.gd`：画面・音声から独立した戦闘処理。
- `godot/scripts/main.gd`：UI・演出・SE・入力ロック。
- `godot/data/game.json`：v18から抽出したカード・初期デッキ・論点・成長・敵カード定義。
- `scripts/export_godot_data.cjs`：生成と`--check`による相違検出。
- `scripts/export_godot_fixtures.cjs`：HTML実行からテスト用の操作履歴・期待状態を生成。
- `godot/tests/test_engine.gd`：Godotで同じ操作を実行し状態を比較。
- `godot/tests/test_ui.gd`：4画面、カード使用・演出、Undo、ターン終了、保存再開をヘッドレスで実行。

4初期デッキ×4対策状態×3乱数＝**48戦・896時点**の比較が通過。手札・山札・敵カード・人物成長・予告・乱数などを比較し、ログの文章は除外。戦闘終了後にHTMLが行う報酬抽選の乱数消費はGodotの対象外なので、勝利確定の比較では抽選前の乱数状態を期待値とする。

HTML回帰、データ一致、Godot起動・画面操作、戦闘比較、APK出力・署名検証を行った。**Android実機・目視・実際の音の聴取は未実施。** ヘッドレスの画面操作テストは見た目が適切だと保証するものではない。

### 移行中の注意

v18の予告軽減には、浅いコピーにより敵手札の効果値まで変わる挙動がある。今回の戦闘比較はその既存挙動も再現している。ログだけの問題ではなく将来のバランスに関係するため、敵カード原本／予告効果を切り離す修正と、その変更前後の再測定を別課題として残す。既存バランスが完成した扱いにはしない。

次は実機で文字サイズ、スクロール、対象選択、演出時間を確認し、その後に編成・報酬・準備戦・公害の街を順に移す。

## 公式資料

- [Godot4.6 Android出力](https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_android.html)
- [Godotコマンドライン](https://docs.godotengine.org/en/4.6/tutorials/editor/command_line_tutorial.html)
- [GitHub Actions成果物の取得](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/download-workflow-artifacts)

## 初回CIの実行記録

[GitHub Actions実行](https://github.com/akm831/card2026/actions/runs/37193919825)が成功。`card2026-android-2`のArtifactsからAPKを取得できる。ローカルとCIのAPK出力・署名検証を確認済み。集計はreports/godot_v01.json。
