# ドキュメント

このディレクトリには、インフラストラクチャプロジェクトの詳細ドキュメントが含まれています。

## ドキュメント一覧

### 基本設定

- **[terraform-usage.md](terraform-usage.md)** - Terraform実行スクリプトの詳細な使用方法
  - terraform.shスクリプトの使用方法
  - 環境別デプロイの実行方法
  - デバッグとトラブルシューティング

- **[ssh-configuration.md](ssh-configuration.md)** - SSH接続とセキュリティ設定
  - SSH鍵の管理と設定
  - sudo権限の設定方法
  - セキュリティベストプラクティス

### コンポーネント別設定

- **[node-exporter.md](node-exporter.md)** - Prometheus Node Exporterの設定
  - インストールプロセスの詳細
  - 設定オプションとトラブルシューティング
  - メトリクスアクセス方法

- **[kubernetes.md](kubernetes.md)** - Kubernetesマニフェストの管理
  - マニフェスト一覧と役割
  - SSH+kubectl方式とKubernetes Provider方式
  - デプロイ前提条件とトラブルシューティング

### アーキテクチャ

- **[structure.md](structure.md)** - リポジトリの構造と組織化
  - ディレクトリ構造の詳細説明
  - ファイルの役割と責任
  - ベストプラクティスと使用パターン

## ドキュメントの使い方

### 初回セットアップ時

1. [terraform-usage.md](terraform-usage.md) - 基本的な実行方法
2. [ssh-configuration.md](ssh-configuration.md) - SSH設定の準備
3. [node-exporter.md](node-exporter.md) または [kubernetes.md](kubernetes.md) - 必要なコンポーネントの設定

### トラブルシューティング時

各ドキュメントの「トラブルシューティング」セクションを参照してください：

- SSH接続エラー → [ssh-configuration.md](ssh-configuration.md)
- Node Exporterの問題 → [node-exporter.md](node-exporter.md)
- Kubernetesデプロイの問題 → [kubernetes.md](kubernetes.md)
- Terraformコマンドの問題 → [terraform-usage.md](terraform-usage.md)

### カスタマイズ時

- 新しい環境の追加 → [structure.md](structure.md)
- セキュリティ設定の強化 → [ssh-configuration.md](ssh-configuration.md)
- マニフェストの追加・変更 → [kubernetes.md](kubernetes.md)

## 更新とメンテナンス

これらのドキュメントは、インフラストラクチャの変更に合わせて定期的に更新してください：

- 新しい変数や設定オプションの追加時
- セキュリティ要件の変更時
- トラブルシューティング情報の追加時
- ベストプラクティスの更新時