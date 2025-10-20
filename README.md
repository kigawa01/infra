# インフラ管理

このリポジトリは Terraform ベースの Infrastructure as Code (IaC) プロジェクトと、Terraform を実行する Kotlin CLI アプリケーションから構成されています。

## 概要

このプロジェクトは `kinfra` というCLIツールで管理される、TerraformベースのInfrastructure as Code (IaC)です。

## インストール

`kinfra`をインストールします。

```bash
curl -fsSL https://raw.githubusercontent.com/kigawa-net/kinfra/main/install.sh | bash
```

## クイックスタート

```bash
# 1. Bitwardenにログイン
kinfra login

# 2. 完全なデプロイパイプライン実行（init → plan → apply）
kinfra deploy

# または個別にコマンドを実行
kinfra init
kinfra plan
kinfra apply
```

## 主要機能

### 🔧 kinfra CLI

TerraformをラップしたCLIツール：

```bash
kinfra [コマンド]
```

**利用可能なコマンド**:
- `init` - Terraform初期化
- `plan` - 実行計画の作成
- `apply` - 変更の適用
- `destroy` - リソースの削除
- `validate` - 設定の検証
- `fmt` - フォーマット
- `deploy` - 完全なデプロイパイプライン（init → plan → apply）



### 🔐 Bitwarden統合による自動設定

DeployコマンドはBitwardenから自動的にCloudflare R2認証情報を取得：

```bash


# デプロイ時に自動でbackend.tfvarsを生成
kinfra login
kinfra deploy
```

**Bitwardenアイテム要件**:
- アイテム名: `Cloudflare R2 Terraform Backend`
- 必須フィールド: `access_key`, `secret_key`, `account_id`
- オプションフィールド: `bucket_name`

### 📊 Node Exporter

Prometheus Node Exporterを自動インストール：
- バージョン管理とポート設定
- SSH経由での安全なデプロイ
- systemdサービスとしての自動起動

### ☸️ Kubernetesマニフェスト

以下のリソースをデプロイ：
- Prometheus Application（Argo CD）
- PVE Exporter（Proxmox VEメトリクス）
- Ingress（HTTPS アクセス）
- Nginx Exporter（オプション）

## ディレクトリ構造

```
infra/
├── README.md                 # このファイル
├── CLAUDE.md                 # Claude Code用ガイド
├── BACKEND_SETUP.md          # R2バックエンド設定ガイド
├── *.tf                      # Terraform設定ファイル
├── settings.gradle.kts       # Gradleマルチモジュール設定
├── app/                      # Kotlin CLIアプリ（エントリーポイント）
│   └── src/main/kotlin/net/kigawa/kinfra/
│       ├── commands/         # コマンド実装
│       ├── di/               # Koin依存性注入設定
│       └── TerraformRunner.kt
├── model/                    # ドメインモデル
│   └── src/main/kotlin/net/kigawa/kinfra/domain/
├── action/                   # ビジネスロジック層
│   └── src/main/kotlin/net/kigawa/kinfra/action/
├── infrastructure/           # インフラストラクチャ層
│   └── src/main/kotlin/net/kigawa/kinfra/infrastructure/
│       ├── bitwarden/        # Bitwarden CLI統合
│       ├── process/          # プロセス実行
│       ├── service/          # TerraformService実装
│       └── terraform/        # Terraform設定管理
├── kubernetes/               # Kubernetesマニフェスト
├── templates/                # テンプレートファイル
└── environments/             # 環境固有の設定
    └── prod/                 # 本番環境
        ├── terraform.tfvars  # Terraform変数
        └── backend.tfvars    # R2バックエンド設定（自動生成）
```



## 詳細ドキュメント

- **[CLAUDE.md](CLAUDE.md)** - Claude Code用の詳細なガイド（アーキテクチャ、設計パターン等）
- **[BACKEND_SETUP.md](BACKEND_SETUP.md)** - Cloudflare R2バックエンド設定の詳細



## よくある使用例

```bash
# 完全なデプロイパイプライン（推奨）
kinfra login
kinfra deploy

# 設定の検証
kinfra validate

# フォーマット
kinfra fmt

# 実行計画の確認
kinfra plan

# Terraform変数を上書き（Terraformのオプションをそのまま渡せる）
kinfra apply -var=nginx_enabled=false
```

## セキュリティ注意事項

- **SSH秘密鍵**: gitリポジトリに含めない（`.gitignore`で除外済み）
- **backend.tfvars**: gitリポジトリに含めない（自動生成される）
- **Bitwarden認証情報**: `BW_SESSION`環境変数で管理、コミットしない
- **最小権限の原則**: 本番環境では必要最小限の権限のみ付与

## トラブルシューティング

### Bitwarden関連

```bash
# kinfra経由でBitwardenにログイン
kinfra login

# Bitwardenのアイテム一覧確認
bw list items | jq '.'.[].name''
```

### Terraform関連

```bash
# Terraformバージョン確認
terraform version

# 設定の検証
kinfra validate

# フォーマット
./gradlew run --args="fmt"
```

詳細なトラブルシューティングは[CLAUDE.md](CLAUDE.md)を参照してください。