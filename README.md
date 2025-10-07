# インフラ管理

このリポジトリは Terraform ベースの Infrastructure as Code (IaC) プロジェクトと、Terraform を実行する Kotlin CLI アプリケーションから構成されています。

## 概要

このプロジェクトは以下のコンポーネントを管理します：

- **Terraform IaC**: Nginx設定とデプロイ、Prometheus監視、Kubernetesリソース管理
- **Kotlin CLI App**: Terraformコマンドを実行するマルチモジュールJavaアプリケーション
- **SSH認証**: Bitwardenからの自動SSH鍵取得と管理
- **Cloudflare R2 Backend**: Terraform state をリモートに保存（Bitwarden統合による自動設定）

## クイックスタート

### Bashスクリプト方式

```bash
# 1. 環境を初期化
./terraform.sh init prod

# 2. 実行計画を確認
./terraform.sh plan prod

# 3. インフラをデプロイ
./terraform.sh apply prod
```

### Kotlin CLI方式（推奨）

```bash
# 1. Bitwardenをアンロック
export BW_SESSION=$(bw unlock --raw)

# 2. 完全なデプロイパイプライン実行（init → plan → apply）
./gradlew run --args="deploy"

# または個別にコマンドを実行
./gradlew run --args="init prod"
./gradlew run --args="plan prod"
./gradlew run --args="apply prod"
```

## 主要機能

### 🔧 ハイブリッド実行環境

2つの方法でTerraformを実行できます：

1. **Bashスクリプト方式** (`terraform.sh`): 従来のshellスクリプト
2. **Kotlin CLI方式** (`app/`): マルチモジュールJavaアプリケーション（Bitwarden統合付き）

```bash
# Bashスクリプト
./terraform.sh [コマンド] [環境] [オプション]

# Kotlin CLI
./gradlew run --args="[コマンド] [環境]"
```

**利用可能なコマンド**: `init`, `plan`, `apply`, `destroy`, `validate`, `fmt`, `deploy`, `setup-r2`
**対応環境**: `prod`

### 🔐 Bitwarden統合による自動設定

DeployコマンドはBitwardenから自動的にCloudflare R2認証情報を取得：

```bash
# 初回のみ：Bitwardenにアイテムを作成
./gradlew run --args="setup-r2"

# デプロイ時に自動でbackend.tfvarsを生成
export BW_SESSION=$(bw unlock --raw)
./gradlew run --args="deploy"
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
├── terraform.sh              # Bashスクリプト
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

## Kotlin アプリケーション開発

### 前提条件
- Java 21
- Terraform
- Bitwarden CLI (オプション、deploy/setup-r2コマンド使用時)

### ビルドとテスト

```bash
# プロジェクト全体のビルド
./gradlew build

# 特定モジュールのビルド
./gradlew :app:build
./gradlew :infrastructure:build

# テスト実行
./gradlew test

# 配布パッケージの作成
./gradlew installDist
app/build/install/app/bin/app help
```

### アーキテクチャ

**マルチモジュール構成**:
- `app`: エントリーポイント、コマンド実装
- `model`: ドメインモデル（`domain`パッケージ）
- `action`: ビジネスロジック層
- `infrastructure`: インフラストラクチャ層（Bitwarden、プロセス実行等）

**依存関係**: `app → action, infrastructure → model`

**依存性注入**: Koinを使用、`AppModule.kt`で設定

## 詳細ドキュメント

- **[CLAUDE.md](CLAUDE.md)** - Claude Code用の詳細なガイド（アーキテクチャ、設計パターン等）
- **[BACKEND_SETUP.md](BACKEND_SETUP.md)** - Cloudflare R2バックエンド設定の詳細

## 本番環境設定

`environments/prod/terraform.tfvars`で以下を設定：

```hcl
# Kubernetes設定
use_ssh_kubectl = false              # Kubernetesプロバイダーモードを使用
apply_k8s_manifests = true           # マニフェスト適用を有効化
kubernetes_config_path = "/home/kigawa/.kube/config"

# Nginx設定
nginx_enabled = true
nginx_server_name = "0.0.0.0"
nginx_target_host = "one-sakura"     # 133.242.178.198にマッピング

# Node Exporter設定
node_exporter_enabled = true
target_host = "k8s4"                 # 192.168.1.120にマッピング
```

## よくある使用例

```bash
# 完全なデプロイパイプライン（推奨）
export BW_SESSION=$(bw unlock --raw)
./gradlew run --args="deploy"

# Terraform変数を上書き
./terraform.sh apply prod -var="nginx_enabled=false"

# Bashスクリプトで個別実行
./terraform.sh validate
./terraform.sh fmt
./terraform.sh plan prod
```

## セキュリティ注意事項

- **SSH秘密鍵**: gitリポジトリに含めない（`.gitignore`で除外済み）
- **backend.tfvars**: gitリポジトリに含めない（自動生成される）
- **Bitwarden認証情報**: `BW_SESSION`環境変数で管理、コミットしない
- **最小権限の原則**: 本番環境では必要最小限の権限のみ付与

## トラブルシューティング

### Bitwarden関連

```bash
# Bitwardenのステータス確認
bw status

# ログイン
bw login

# アンロック
export BW_SESSION=$(bw unlock --raw)

# アイテム一覧確認
bw list items | jq '.[].name'
```

### Terraform関連

```bash
# Terraformバージョン確認
terraform version

# 設定の検証
./gradlew run --args="validate"

# フォーマット
./gradlew run --args="fmt"
```

詳細なトラブルシューティングは[CLAUDE.md](CLAUDE.md)を参照してください。