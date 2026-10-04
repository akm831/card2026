# 架空国家のビジュアル・UI04

## 方針

架空国家として描く。日本国旗、菊の紋章、実在国家の旗・紋章・実在政治家の肖像は使わない。日本の政治行政を参考にした用語や題材は残す。画風は初代PS〜3DS頃を思わせる太い輪郭、少数の陰影、粗めの塗り。文字は高解像度・静的太字で表示する。

## 素材

built-in imagegenで生成。背景は議場1枚、アトラスは3×3の9タイル（人物4人、資料提出、予算精査、根回し、資料答弁、世論調査）。JPEGへ最適化し、GodotのAtlasTextureで分割参照。画像にカード名/コスト/効果を焼き込まない。

- `godot/art/generated/chamber.jpg`
- `godot/art/generated/political_atlas.jpg`

人物4人のうち委員の肖像は将来用。敵人物の能力・退場ルールは今回は実装しない。初期人物のうち行政・政治・報道に個別肖像。他属性人物は仮アイコン。通常カードの一部は属性別の共通絵。全カードの個別絵は未制作。

### 生成指示

Atlas: original fictional political card game, exact equal 3×3 tiles, no gutters/frames/letters. Early PlayStation/3DS Japanese tactics RPG handpainted illustration, bold outlines, simplified mature faces, muted earth colors, coarse paint. Row1: elder bespectacled official / dark-haired parliamentary leader / woman journalist. Row2: silver-haired expert / dossiers on desk / ledger and calculator. Row3: corridor negotiation / document answer at lectern / newspaper-survey. No flags, chrysanthemum, real people, emblems, logos or text.

Background: original fictional parliamentary chamber, curved wood desks, dark teal seats, plain geometric wall panels, podium, warm lamps; low-detail dark navy/brown painted PS-era environment. No flags/chrysanthemum/emblems/logos/characters/UI/text.

## 文字・枠の修正

前回はLabelの折り返し/省略指定で一部の文字領域の高さが0になっていた。実OpenGL描画で再現して修正。全Labelへの省略指定を撤回し、状態欄等の限定箇所だけ使う。クリップされたボタンは文字幅から最小幅を設定。フォントはNoto Sans JPをfontToolsでweight700の静的フォントに変換し、モバイルでの可変フォント変形に依存しない。OFLは維持。

### セットアップ

Godot4.6。新規環境は `python -m pip install fonttools==4.61.1` の後 `python scripts/prepare_font.py`。Godotエディタで再インポート。GitHub Actionsにも同じ準備を追加。

## 検証

- 3横画面サイズ、7枚/3人物/3予告/詳細/長い状態文/超過手札/勝利確定の配置、全Labelの正の高さ。
- HTMLとの48戦896状態一致、保存往復。
- 4デッキの操作・Undo・ターン終了・再開。
- OpenGL Compatibilityを仮想X11＋Mesa software renderで実際に描画。選択/対象指定/勝利画面を目視。Androidの実機確認ではない。
- CIにxvfb-run描画とスクリーンショットを追加。APK ArtifactにPNG3枚を同梱。

BGMの新作・全カード絵・敵人物ルールは次の作業。既存SEは維持。
