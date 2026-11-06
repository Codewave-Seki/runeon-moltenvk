# パッチ適用済み MoltenVK

[English](README.md) | [Chinese](README.zh-CN.md) | [Japanese](README.ja.md)

> この英語の文書が正式版です。中国語と日本語の文書は、読みやすさのための完全な翻訳です。

パッチを適用した [MoltenVK](https://github.com/KhronosGroup/MoltenVK) です。固定した上流コミット、公開フォークから採用した順序付きパッチシリーズ、そして再構築用のスクリプトで構成されます。互換性や適合性は保証しません。MoltenVK のソースツリーやビルド済み dylib は含みません。

## ベースラインと現在のパッチセット

- 上流ベース：MoltenVK `main` の `5189f8de`（`v1.4.2-58-g5189f8de`）。[`base/moltenvk-main-5189f8de.json`](base/moltenvk-main-5189f8de.json) に固定しています。依存関係はその `ExternalRevisions` に従います
- 現在のパッチセット：[`1.4.2-patched.1`](patchsets/1.4.2-patched.1/manifest.json)。パッチ 8 件。その Git タグが、下流で使われるビルドのソースの正式な記録です。バイナリの Release は提供しません。ID は上流の最新リリースを保持します。ソース自体のバージョン定数は 1.4.3 ですが、上流はまだリリースしていません
- レビュー：[MAINTENANCE.md](MAINTENANCE.md#review-records) を参照してください

## リポジトリ構成

| パス | 内容 |
|---|---|
| `base/` | 固定した上流リポジトリとコミット |
| `patchsets/<id>/` | 1 つのパッチセットの `series` と `manifest.json`。スクリプトは最新のものを使い、`MOLTENVK_PATCHSET_DEFINITION=patchsets/<id>` で別のものを選べます |
| `patches/community/` | 公開フォークから採用した修正。1 ファイル 1 コミット |
| `scripts/` | 取得、検査、ビルドのスクリプト |
| `docs/` | レビュー記録 |

## パッチの内容

変更はすべて汎用で既定で有効であり、特定のゲームには一致させません。自明でない変更にはそれぞれ環境変数のスイッチがあります。[MAINTENANCE.md](MAINTENANCE.md#environment-switches) を参照してください。

- present の待機セマフォがシグナルされた後にスワップチェーン画像を表示する
- テッセレーションの一時バッファをシェーダーが実際に書き込むサイズで確保し、間接テッセレーション描画をその範囲に制限する
- ソースが compute のバリアを compute エンコーダー内に留め、バリアが守られる場合は `vkCmdDispatch` エンコーダーを並行実行する
- フラグメントと compute ステージの精密演算ヘルパーを Metal に最適化させる
- 宣言された最大値が非常に大きい indirect-count コマンドでは、エンコードする Metal 描画数に上限を設け、切り詰めが起きたら上限を上げる。しきい値を超える単発コマンドでは描画が失われることがある
- 動的レンダリングの開始前に indirect-count の引数を変換する

## 検証とビルド

```bash
scripts/static-check.sh
scripts/integration-check.sh "$(scripts/fetch-source.sh)"
scripts/build.sh
```

`integration-check.sh` は、固定ベースの一時 worktree に各パッチを `git am` で適用し、結果がマニフェストに記録されたツリーであることを確認します。`build.sh` については [BUILDING.md](BUILDING.md) を参照してください。

## ドキュメント

- [BUILDING.md](BUILDING.md)：dylib のビルド
- [MAINTENANCE.md](MAINTENANCE.md)：レビュー記録、採用基準、環境変数のスイッチ
- [SECURITY.md](SECURITY.md)：セキュリティ問題の報告
- [docs/upstream-reviews.md](docs/upstream-reviews.md)：レビュー記録

## ライセンス

MoltenVK と同じ Apache-2.0 です。[`LICENSE`](LICENSE) を参照してください。採用したコミットは元の作者を保持し、変更したファイルには変更の通知があります。
