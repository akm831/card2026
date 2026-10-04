# 検証方法と結果

`npm test`：v05のUndo・勝敗確定・保存復帰、およびv06のデッキ制限・対象選択Undo・延期のコスト枠・論点差し替え・疑惑のUndo・人物戻し・投資・勝利確定・保存復帰・onclick構文を確認。

`npm run balance:v06`：4デッキ×3準備選択×100試行。固定seedを用い、人物を優先配置し最初の使用可能カードを使用する単純bot。通常難易度。本戦前に準備結果を保持し、戦闘HP等をリセットする。準備敗北も本戦へ進む。本戦勝率は準備結果込みで、準備勝者のみの条件付き勝率ではない。

v06本戦勝率：

|デッキ|政策論議|マスコミ対応|党内調整|
|---|---:|---:|---:|
|行政＋政治|63%|50%|52%|
|地域＋報道|97%|83%|84%|
|裏人脈＋政治|85%|79%|77%|
|経済＋行政|100%|96%|97%|

各100戦。人間の勝率・完成版バランスの証明ではない。行政型の準備政策戦は44%で特に難しく、経済型は強すぎる傾向がある。実プレイで選択・人物能力の面白さを確認したうえで調整する。

v05は各条件200戦、3ステージ×3初期デッキ×2難易度×初期/収集後の仮編成。収集後は入手可能カードと支持基盤を直接設定した構成で、実際の収集周回をシミュレートしたものではない。JSON内の `grown` がこの区別。

実ブラウザの表示・操作確認は未実施。手動確認項目：スマートフォン幅、対象選択とキャンセル、予告の変化、人物停止表示、デッキ編成、途中保存復帰、準備失敗、本戦勝敗、後日談と再挑戦。

## v07事前検証

4初期デッキ×3準備×2難易度×100回＝2,400組、各組で準備と本戦を実行。最大4,800戦。固定seedの簡易bot、成長型へ合わせた最適化はなし。人間の勝率ではない。本戦勝率は準備失敗も含む。

|デッキ|準備|難易度|準備勝率|本戦勝率|
|---|---|---|---:|---:|
|行政＋政治|policy|normal|90%|98%|
|行政＋政治|policy|advanced|77%|95%|
|行政＋政治|media|normal|99%|82%|
|行政＋政治|media|advanced|95%|78%|
|行政＋政治|party|normal|99%|83%|
|行政＋政治|party|advanced|99%|70%|
|地域＋報道|policy|normal|89%|100%|
|地域＋報道|policy|advanced|76%|99%|
|地域＋報道|media|normal|87%|85%|
|地域＋報道|media|advanced|80%|81%|
|地域＋報道|party|normal|100%|89%|
|地域＋報道|party|advanced|100%|86%|
|裏人脈＋政治|policy|normal|93%|87%|
|裏人脈＋政治|policy|advanced|85%|83%|
|裏人脈＋政治|media|normal|93%|84%|
|裏人脈＋政治|media|advanced|90%|74%|
|裏人脈＋政治|party|normal|93%|86%|
|裏人脈＋政治|party|advanced|91%|78%|
|経済＋行政|policy|normal|98%|100%|
|経済＋行政|policy|advanced|95%|100%|
|経済＋行政|media|normal|100%|98%|
|経済＋行政|media|advanced|100%|100%|
|経済＋行政|party|normal|100%|99%|
|経済＋行政|party|advanced|100%|100%|

極端な低勝率は見られなかった。一方で経済型は上級もほぼ全勝であり、難易度の完成とは判断しない。構造の検証版として公開し、手動プレイで強さと逆転の手触りを確認する。回帰検証は成長のターン持ち越し、成長Undo、成長後コスト2＋6、能力停止での加算抑制、保存復帰、別戦闘でのリセットを追加。実ブラウザでの操作・表示は未確認。

## v08事前検証

4デッキ×3準備×2難易度×100組。同じ簡易botを使用。

|デッキ|準備|難易度|準備勝率|本戦勝率|
|---|---|---|---:|---:|
|admin|policy|normal|95%|100%|
|admin|policy|advanced|83%|99%|
|admin|media|normal|98%|100%|
|admin|media|advanced|91%|96%|
|admin|party|normal|100%|100%|
|admin|party|advanced|96%|94%|
|regional|policy|normal|92%|100%|
|regional|policy|advanced|73%|96%|
|regional|media|normal|95%|98%|
|regional|media|advanced|52%|83%|
|regional|party|normal|100%|97%|
|regional|party|advanced|98%|84%|
|noir|policy|normal|93%|97%|
|noir|policy|advanced|92%|98%|
|noir|media|normal|93%|97%|
|noir|media|advanced|92%|97%|
|noir|party|normal|93%|96%|
|noir|party|advanced|94%|94%|
|economic|policy|normal|98%|100%|
|economic|policy|advanced|94%|100%|
|economic|media|normal|100%|99%|
|economic|media|advanced|96%|97%|
|economic|party|normal|100%|99%|
|economic|party|advanced|100%|98%|

HP30、指定2属性構成、成長官僚のターン開始防御、停止中の防御抑制、更迭の行政人物対象、予告論点・コストのHTML表示、対象なし軽減カードを追加検証。スクリーンショットの表示不具合を元にCSSを修正したが、修正版の実ブラウザ描画確認は未実施。経済型等の高勝率は残る。人間の勝率とは異なる。

## v09：同一条件でのバランス比較

各条件100組、全2,400組（4デッキ×3準備×2難易度）。同じ簡易bot・seedで比較。準備失敗も本戦へ進む。

|デッキ|準備|難易度|準備勝率|本戦勝率|
|---|---|---|---:|---:|
|admin|policy|normal|84%|97%|
|admin|policy|advanced|84%|85%|
|admin|media|normal|93%|86%|
|admin|media|advanced|93%|53%|
|admin|party|normal|99%|80%|
|admin|party|advanced|99%|53%|
|regional|policy|normal|84%|95%|
|regional|policy|advanced|84%|85%|
|regional|media|normal|85%|75%|
|regional|media|advanced|85%|37%|
|regional|party|normal|99%|84%|
|regional|party|advanced|99%|52%|
|noir|policy|normal|63%|82%|
|noir|policy|advanced|63%|74%|
|noir|media|normal|69%|72%|
|noir|media|advanced|69%|62%|
|noir|party|normal|74%|75%|
|noir|party|advanced|74%|60%|
|economic|policy|normal|80%|98%|
|economic|policy|advanced|80%|91%|
|economic|media|normal|93%|88%|
|economic|media|advanced|93%|61%|
|economic|party|normal|100%|86%|
|economic|party|advanced|100%|56%|

一律攻撃＋2の本戦案では地域上級の一部が6〜11%となったため不採用。現案の本戦は通常72〜98%、上級37〜91%。通常の平均は約85%、上級は約65%。目標に完全到達したとは言えず、財源対策はまだ強い。人間の勝率・操作の工夫による改善を測ったものではない。乱数と手順が変わるため、準備成功率と本戦勝率だけから因果関係は断定しない。ブラウザでの手動試遊は未実施。

## 追加の対照試験

19,200戦の比較を `docs/BALANCE_REVIEW_V09.md` に記録。準備成功を直接設定するため、以前の2,400組と混同しない。予告対応botでは地域・行政・経済の勝率が大きく上がり、v09は易しすぎる傾向。財源対策優位は残った。

## 手札ルールの比較

19,200組の4方式比較をdocs/HAND_RULES_REVIEW.mdへ記録。実験VM内だけの変更。温存を許す予告対応botと単純botを比較。カード供給・未使用コスト・手詰まり・超過捨て札も記録。1枚補充の正式採用は見送り。

## v11 手札保持・1枚ドロー

`npm test`は旧版回帰に加え、v11の初期5枚/保持1枚補充、超過7枚の選択とUndo、追加2枚、敵の無効化済みカード消費、上限・コスト3、人物各1枚、初期化と保存キー独立、記者の成長後攻撃限定ドローを確認。

`npm run compare:draw`：v10効果を保持して追加ドロー型と効率型を16枚共通で比較（9,600案件）。`npm run balance:v11`：実際のv11本体を初期構成と比較構成で検証（14,400案件）。別乱数の初期構成検証9,600案件はreports/balance_v11_holdout.json。全て準備戦＋本戦。計算が安定したことを楽しさ・人間の勝率と読み替えない。

詳細、条件別の表、信頼区間の目安と未解決点はBALANCE_REVIEW_V11.md。実ブラウザ確認の手順はPLAYTEST_V11.md。

## v12 敵AI

`npm test`にAI単体テストとv12戦闘回帰を追加。全組み合わせ、低HPの防御、勝利できる攻撃、成長人物の優先対象、属性条件、停止済み対象除外、重複防御、延期予算、入力の非変更、AIソースとHTML同梱の一致を確認。ゲーム側ではプレイヤー手札・山札の変更が敵予告に影響しないことと、配置後の対象固定を確認。

`npm run compare:enemy`は旧v11と新v12を同一初期デッキ・種・プレイヤー方策で各9,600案件、合計19,200案件比較。1案件は準備戦＋本戦。各条件200回。追加乱数検証は `TRIALS=100 SEED_BASE=246810 REPORT_PATH=reports/compare_enemy_v12_holdout.json node tests/compare_enemy_v12.cjs`。

予告攻撃・防御・対象あり人物干渉・複数行動・余りコストも収集する。これは予告時の値であり、プレイヤーに無効化された後の実ダメージではない。詳細はENEMY_AI_V12.md。

## v13 入門・実戦

`npm run balance:v13`：4初期デッキ×3プロファイル×3準備×2方策×200＝14,400案件。入門の主指標は単純使用方策を3準備で等重み平均した値。熟練参考の予告評価方策も別表示する。

別乱数：`PROFILES=intro TRIALS=300 SEED_BASE=246810 REPORT_PATH=reports/balance_v13_holdout.json node tests/balance_v13.cjs`（7,200案件）。`npm run compare:rebuild`は実戦で初期デッキと少数交換を同じ条件で比較（4,800案件）。実戦1で選択報酬1枚以内、実戦2で2枚以内＋初期所持カードの追加コピーだけを用いる。ランダム報酬と完全収集を仮定しない。

v13回帰は段階解放、プロファイル構成/置換枚数、報酬選択/未選択時の進行停止/二重受取/全収集時の交換、ヒントと新UIのハンドラを含む。人間の初見勝率・描画・面白さは別に確認する。

## v14 地域＋報道

`npm run ablate:regional`は旧v13の人物3要因と通常補充/予告対策を個別に除去。報告を分けた再現は `VARIANTS=baseline,noReporterDraw,noOrganizerHeal,noGrowthAttack node tests/ablate_regional_v13.cjs` と `VARIANTS=baseline,noCardDraw,noForecastControl REPORT_PATH=reports/ablate_regional_cards_v13.json node tests/ablate_regional_v13.cjs`。

`npm run balance:v14`は全初期デッキ/3段階/3準備/2方策で検証。予約ドローを評価する方策を使うため、旧版の比較も `VERSION=v13 TYPES=regional TRIALS=200 REPORT_PATH=reports/regional_baseline_v13.json node tests/balance_v14.cjs` で同じ方策を適用する。別乱数入門確認は `TYPES=regional PROFILES=intro TRIALS=300 SEED_BASE=246810 REPORT_PATH=reports/regional_v14_holdout.json node tests/balance_v14.cjs`。

回帰は人物の介入/成長/攻撃で共通枠を使うこと、ターン切替/停止/Undo、記者説明の当ターン未補充と次ターン解決、予定ドロー表示、裏取りコスト2を含む。各人物のドローを単独除去する実験は、合計上限の採用テストとは区別する。詳細はREGIONAL_BALANCE_V14.md。

## v14：収集デッキ比較

`npm run compare:collection`。同数の候補探索と独立した測定乱数で、初期所持＋選択2枚／初期2属性全所持を比較。初期比較は `CANDIDATES=1 TRAIN=1 BUDGETS=starter REPORT_PATH=reports/collection_starters_v14.json node tests/collection_v14.cjs`。方法・判断・限界は `COLLECTION_BALANCE_V14.md`。ゲーム本体は変更せず、測定21,600案件の打ち切り0。
