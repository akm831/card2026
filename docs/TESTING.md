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
