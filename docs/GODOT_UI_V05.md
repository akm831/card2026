# Godot UI05 — Issue #9 / #10

## 変更

戦闘ルール・カード性能・敵AI・HP30/コスト3・手札保持/通常1枚ドローは変更しない。

- 手札は同じ画面サイズで固定幅/高さ。標準1280×720では156×156、7枚が入る幅を上限に計算。1/2/4枚は中央寄せ、8枚以上は手札の横スクロール。枚数が減っても幅を伸ばさない。
- 絵は縦横比を保って全体表示。名前/コストは2行固定の領域、属性/タイプも表示。絵の余白は紙色。全文は選択後の共通説明欄で確認。人物肖像も全体表示。
- ログ/全文/人物/クレジットは閲覧用タッチScrollContainer。指のドラッグとマウスホイール、固定の閉じるボタン。ネイティブWindowから画面内オーバーレイへ変更。
- Androidの物理的な安全領域/カメラ穴を画面→キャンバス座標へ換算。Control.get_screen_transform()の逆変換にはウィンドウ位置を含むため重複して差し引かない。穴に近い辺を避け、標準16px/広め28pxの余白を追加。背景だけは全画面。
- 設定にBGM/SEの個別音量（0でミュート）、広めの余白、演出ON/OFF。`user://ui_settings.json`に保存。アプリ中断時は音を止め、復帰時にBGM設定を復元。
- 選択の短い発光/持ち上がり、使用カードから対象への軌跡、ダメージ/防御/成長/予告介入の文字と枠、HPバー変化。予告変更は対象行へ表示。停止人物は暗くし、成長人物は金枠。通常は約0.44秒、演出OFFで待ちを省く。画面全体の揺れや国旗等は使用しない。
- 64秒のオリジナルBGM1曲とSE8種類。鍵盤/柔らかな持続音、紙/決定/攻防/介入/成長/勝利。SEは4プレイヤーのプールで重複を制限。

## 音素材の生成と権利情報

`python scripts/generate_audio.py`（numpyとffmpeg/libvorbisが必要）。seed 20261004、22050Hz。波形合成と固定乱数のみで制作し、既存楽曲・録音素材・既存作品の旋律を使用していない。BGMはAm(add9)/Fmaj7/C(add9)/Gsus2の疎な音配置、円環バッファで持続音を接続。Ogg Vorbisで保存し、元WAVは削除。SEはPCM WAV。生成コードと計測値を同梱。音素材は本プロジェクトのオリジナル試作用素材として使用可能。画像/フォントの情報はART_UI_V04.md/OFL.txtを参照。

## 検証

- `npm test`：HTML v05〜v18の回帰を通過。
- データ一致、48戦896状態のHTML/Godot比較、保存往復を通過。
- 4デッキの操作/演出/Undo/ターン終了/再開を通過。
- 従来の3横画面サイズ、7枚/3人物/3予告/長文/選択/勝利/超過手札の配置検証を通過。
- 新規`test_mobile.gd`：物理座標の拡大率/画面位置、左右カメラ穴44px、下部24px、標準/広め余白、1/2/4/7/8枚、固定寸法/全体表示、超過最後のカード到達、ポップアップ安全領域、Viewportへ注入した指ドラッグ、長いログ最終部、独立音量スライダー、設定保存、ミュート、中断/復帰、音素材長/ループを通過。
- 実OpenGL描画（Mesa/仮想X11）で選択/対象/勝利/1・2・4枚/安全領域/設定/追加絵を確認。PNG9枚をAPK Artifactへ同梱。
- Oggをデコードして64.0秒、ピーク0.35522、最終→先頭のサンプル差0.00283を確認。SE8種類のピーク0.85未満。これは数値検証であり、聴感評価ではない。

## 実機で残る確認

Androidの左右両向きでカメラホール/丸い端/操作領域が隠れないこと、指でログを最後まで送れること、スピーカー/イヤホンの音量と繰り返しの疲れにくさはユーザー実機で要確認。模擬テスト/スクリーンショットを実機保証として扱わない。

新規3×3アトラスで財務アドバイザー/地域の世話役/裏の仲介人、採決の調整/裏取り/先行投資/地域の支え/密室取引/議場の説得へ個別絵を追加。初期6属性の人物に肖像を用意した。通常カードの残りは属性内共通絵。全カードの個別絵は将来の素材拡充。Godot側は国会決戦1戦のみ。キャンペーンはHTML v18に残っている。

## ビルド

GitHub Actionsは`test_mobile.gd`を追加。Godot4.6/Android SDK35、version code5、version name0.1-ui05。音素材はコミット済みなので通常のAPKビルドでnumpy/ffmpegは不要。固定テスト署名キー未設定時は実行ごとに署名が変わる。インストールの更新が拒否された場合、旧版削除が必要（旧版の保存も消える）。

## 追加画像の生成記録

内蔵imagegenで生成し、768×768のJPEGへ最適化。保存先`godot/art/generated/political_atlas_v05.jpg`。既存アトラスを画風参照のみとして、新規9タイルを作成。プロンプト：

Original fictional political card game, EXACT equal 3×3 tiles, no gutters or borders. Coarse early PlayStation/3DS tactical RPG handpainted look matching existing atlas, bold ink contours, simplified faces, muted navy/ochre/earth colors. Row1 financial adviser woman/glasses/ledger; older community organizer/green jacket; secretive middle-aged intermediary/dark suit. Row2 parliamentary raised-hand voting; evidence folder/magnifying glass; industrial construction/investment. Row3 town-hall community meeting; sealed-envelope exchange across dim desk; speaker persuading assembly. No flags, chrysanthemum, real politicians, national emblems, logos, lettering, card frames, UI or captions.
