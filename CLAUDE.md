# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

このプロジェクトは本番環境向けのインフラストラクチャ管理を行うTerraformベースのInfrastructure as Code (IaC) プロジェクトと、Terraformを実行するKotlin CLIアプリケーションから構成されています。

### 主要コンポーネント
- **Terraform IaC**: Nginx設定とデプロイ、Prometheus監視、Kubernetesリソース管理
- **Kotlin CLI App**: Terraformコマンドを実行するJavaアプリケーション（`app/`）
- **SSH認証**: Bitwardenからの自動SSH鍵取得と管理

## よく使用するコマンド

### Terraform関連
```bash
# Terraformスクリプト経由
./terraform.sh init prod
./terraform.sh plan prod
./terraform.sh apply prod
./terraform.sh validate
./terraform.sh fmt

# Kotlin アプリケーション経由
./gradlew run --args="init prod"
./gradlew run --args="plan prod"
./gradlew run --args="apply prod"
./gradlew run --args="validate"
./gradlew run --args="fmt"
```

### Kotlin アプリケーション開発
```bash
# アプリケーションのビルド
./gradlew build

# テスト実行
./gradlew test

# アプリケーション実行（gradleラッパー経由）
./gradlew run --args="help"

# 配布用パッケージの作成
./gradlew installDist

# インストール済みスクリプトの実行
app/build/install/app/bin/app help
```

### Bitwarden SSH鍵取得
```bash
# Bitwardenにログイン
bw login

# SSH鍵を取得してプロジェクトに配置
bw get item "main" --session="..." | jq -r '.sshKey.privateKey' > ./ssh-keys/id_ed25519
chmod 600 ./ssh-keys/id_ed25519
```

## アーキテクチャ概要

### ハイブリッド実行環境
このプロジェクトは2つの方法でTerraformを実行できます：
1. **Bashスクリプト方式** (`terraform.sh`): 既存の shell スクリプト
2. **Kotlin CLI方式** (`app/`): 新しく実装されたJavaアプリケーション

両方の実行方式は同じ機能を提供し、同じ環境設定ファイルを使用します。

### Kotlin CLI アプリケーション構造
```
app/
├── build.gradle.kts                              # Gradle ビルド設定
├── src/main/kotlin/net/kigawa/kinfra/
│   ├── App.kt                                   # エントリーポイント
│   └── TerraformRunner.kt                       # メインロジック
└── src/test/kotlin/net/kigawa/kinfra/
    └── AppTest.kt                               # テスト
```

### Terraform インフラ構造
- **メインTerraform設定** (`*.tf`): SSH経由でのnginx・Node Exporterデプロイ
- **Kubernetesモジュール** (`kubernetes/`): Terraform Kubernetesプロバイダー経由管理
- **テンプレートシステム** (`templates/`): 動的設定生成
- **環境別設定** (`environments/`): dev/staging/prod 設定

### ホストマッピングパターン
Terraformコードは以下の論理名を物理IPアドレスにマッピング：
```hcl
# one-sakura: 133.242.178.198 (Nginx デプロイ先)
# k8s4: 192.168.1.120 (Node Exporter デプロイ先)
# lxc-nginx: LXC コンテナでのNginx デプロイ先
```

## 重要なパターン

### 環境変数ファイルの処理
- 両実行方式とも `environments/{env}/terraform.tfvars` を自動検出
- SSH設定は環境変数 `SSH_CONFIG=./ssh_config` で統一
- Plan ファイル適用時は変数ファイル不要

### Kotlin アプリケーション設計パターン
- **TerraformRunner**: コマンド実行とプロセス管理
- **Color output**: ANSI エスケープコードによる色付きコンソール出力
- **Error handling**: Terraform未インストール検知、適切な終了コード
- **Process delegation**: ProcessBuilder経由でTerraformプロセスを起動

### SSH鍵管理パターン
```hcl
# プロジェクト内SSH鍵を優先、フォールバック設定
private_key = var.ssh_key_path != "" ? file(var.ssh_key_path) : file("./ssh-keys/id_ed25519")
```

## CI/CD統合

### GitHub Actionsワークフロー
- Kubernetesアクセス用設定ファイルを`secrets.KUBE_CONFIG`から設定
- Terraform Kubernetesプロバイダーが直接クラスターに接続
- SSH+kubectlは使用せず、プロバイダー経由でのみリソース管理

### 必要なシークレット
- `BW_ACCESS_TOKEN`: Bitwardenアクセストークン
- `BW_SSH_KEY_GUID`: Node Exporter用SSHキー
- `TERRAFORM_ENV`: 本番環境のTerraform変数
- `KUBE_CONFIG`: Kubernetesクラスターアクセス用設定ファイル

## 本番環境設定

### 重要な設定値
- `use_ssh_kubectl = false`: Kubernetesプロバイダーモードを使用
- `apply_k8s_manifests = true`: Kubernetesマニフェストの適用を有効化
- `kubernetes_config_path = "/home/kigawa/.kube/config"`: デフォルトのkubeconfig
- `apply_one_dev_manifests = true`: one/dev関連マニフェストも適用

### Nginx設定
- `nginx_enabled = true`: nginxインストールを有効化
- `nginx_server_name = "0.0.0.0"`: すべてのリクエストを受け付ける
- `nginx_target_host = "one-sakura"`: one-sakuraサーバー（`133.242.178.198`にマッピング）

### Node Exporter設定
- `node_exporter_enabled = true`: Node Exporterインストールを有効化
- `target_host = "k8s4"`: リモートホスト（`192.168.1.120`にマッピング）

## 開発環境構築

### 前提条件
- Java 21 (Kotlin アプリケーション用)
- Terraform (両実行方式で必要)
- SSH鍵設定 (リモートホストアクセス用)

### Kotlin アプリケーション開発
```bash
# プロジェクトのビルドとテスト
./gradlew build

# 単一テストの実行
./gradlew test --tests AppTest.terraformRunnerCanBeCreated

# 開発時のアプリケーション実行
./gradlew run --args="validate"

# 配布パッケージの作成とテスト
./gradlew installDist
app/build/install/app/bin/app help
```
- 日本語を使う