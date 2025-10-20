# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

Terraformを実行するKotlin CLIアプリケーション（マルチモジュール）。Bitwarden統合により、R2バックエンドの認証情報とSSH鍵を自動取得します。

## よく使用するコマンド

### アプリケーション開発
```bash
# ビルドとテスト
./gradlew build
./gradlew test

# アプリケーション実行
./gradlew run --args="help"

# 特定モジュールのビルド
./gradlew :app:build
./gradlew :infrastructure:build
```

### Terraformデプロイ
```bash
# 完全なデプロイパイプライン（推奨）
export BW_SESSION=$(bw unlock --raw)
./gradlew run --args="deploy prod"

# または、bws CLI使用（BWS_ACCESS_TOKENが設定されている場合）
export BWS_ACCESS_TOKEN="your-token"
./gradlew run --args="deploy-sdk prod"

# 個別コマンド
./gradlew run --args="init prod"
./gradlew run --args="plan prod"
./gradlew run --args="apply prod"
```

### Cloudflare R2 Backend設定
```bash
# bw CLI使用（従来方式）
export BW_SESSION=$(bw unlock --raw)
./gradlew run --args="setup-r2"

# bws CLI使用（SDK方式、自動インストール）
export BWS_ACCESS_TOKEN="your-token"
./gradlew run --args="setup-r2-sdk"
```

## アーキテクチャ概要

### Kotlin CLI アプリケーション
Terraformをラップしたマルチモジュールアプリケーション。Bitwarden統合により、R2バックエンドの認証情報を自動取得します。

### Kotlin CLI アプリケーション構造（マルチモジュール）

プロジェクトは4つのGradleモジュールで構成されています：

1. **app/** - エントリーポイントとコマンド実装
   - `commands/` - 各Terraformコマンドの実装（InitCommand, PlanCommand, ApplyCommand, DeployCommandなど）
   - `TerraformRunner.kt` - コマンドディスパッチャー
   - `di/AppModule.kt` - Koin依存性注入設定

2. **model/** - ドメインモデル
   - `domain/` パッケージに配置（実際のディレクトリは`model/src/main/kotlin/net/kigawa/kinfra/domain/`）
   - Command, Environment, TerraformConfig, R2BackendConfig, BitwardenItemなど

3. **action/** - ビジネスロジック層
   - TerraformService - Terraform操作の抽象化
   - EnvironmentValidator - 環境検証

4. **infrastructure/** - インフラストラクチャ層
   - `bitwarden/` - Bitwarden CLI統合
   - `process/` - プロセス実行（ProcessExecutor）
   - `service/` - TerraformServiceの実装
   - `terraform/` - Terraform設定管理
   - `validator/` - バリデーター実装

依存関係: `app → action, infrastructure → model`

### Terraform インフラ構造
- **メインTerraform設定** (`*.tf`): SSH経由でのnginx・Node Exporterデプロイ
- **ホストモジュール** (`terraform/host/`): ホスト別の独立したモジュール
  - `one-sakura/`: Nginxインストールモジュール
  - `k8s4/`: Node Exporterインストールモジュール
  - `lxc-nginx/`: LXC Nginxインストールモジュール
  - 各モジュールは`main.tf`、`variables.tf`、`locals.tf`（必要に応じて）で構成
- **ホスト管理** (`terraform/hosts.tf`): 全ホストモジュールの一元管理
- **Kubernetesモジュール** (`kubernetes/`): Terraform Kubernetesプロバイダー経由管理
- **テンプレートシステム** (`templates/`): 動的設定生成
- **環境別設定** (`environments/`): dev/staging/prod 設定

### ホストモジュールパターン

**モジュール構造**:
```hcl
# terraform/hosts.tf でモジュールを一元管理
module "one_sakura" {
  source = "./host/one-sakura"
  count  = var.enable_one_sakura ? 1 : 0

  nginx_enabled     = true
  nginx_server_name = "0.0.0.0"
  ssh_user          = var.ssh_user
  ssh_key_path      = var.ssh_key_path
}
```

**ホストの有効/無効制御**:
- `var.enable_one_sakura`: one-sakuraモジュールの有効化（デフォルト: true）
- `var.enable_k8s4`: k8s4モジュールの有効化（デフォルト: true）
- `var.enable_lxc_nginx`: lxc-nginxモジュールの有効化（デフォルト: false）

**ローカル変数パターン**:
各ホストモジュールで`locals.tf`を使用してネストした変数構造を定義可能：
```hcl
# terraform/host/lxc-nginx/locals.tf
locals {
  home = {
    gate = {
      nginx = {
        install = {
          script = {
            tmpPath = "/tmp/install_lxc_nginx.sh"
          }
        }
        conf = {
          proxy = {
            tmpPath = "/tmp/lxc_proxy.stream.conf"
          }
        }
      }
    }
  }
}
# 使用例: local.home.gate.nginx.install.script.tmpPath
```

### ホストマッピングパターン
Terraformコードは以下の論理名を物理IPアドレスにマッピング：
```hcl
# one-sakura: 133.242.178.198 (Nginx デプロイ先)
# k8s4: 192.168.1.120 (Node Exporter デプロイ先)
# lxc-nginx: 192.168.3.100 (LXC Nginx デプロイ先)
```

## 重要なパターン

### 環境変数ファイルの処理
- `environments/{env}/terraform.tfvars` を自動検出
- SSH設定は環境変数 `SSH_CONFIG=./ssh_config` で統一
- Plan ファイル適用時は変数ファイル不要
- `BW_SESSION` 環境変数でBitwarden認証

### Kotlin アプリケーション設計パターン

**依存性注入（Koin）**:
- すべてのコマンドとサービスはKoinで管理
- `AppModule.kt`で依存関係を定義
- `single<T>`でシングルトン、`named("command-name")`で名前付きバインディング

**コマンドパターン**:
- `Command`インターフェース: `execute()`, `requiresEnvironment()`, `getDescription()`
- `EnvironmentCommand`抽象クラス: 環境が必要なコマンドの基底クラス（共通の色定数を提供）
- 各コマンド実装: InitCommand, PlanCommand, ApplyCommand, DeployCommand等

**プロセス実行**:
- `ProcessExecutor`インターフェース: `execute()`, `executeWithOutput()`, `checkInstalled()`
- `CommandResult` vs `ExecutionResult`: 前者はexitCodeのみ、後者はoutput/errorも含む
- ProcessBuilder経由でTerraformプロセスを起動、inheritIO()で標準出力継承

**Bitwarden統合**:
- `BitwardenRepository`: CLI経由でBitwardenとやり取り
- `isInstalled()`, `isLoggedIn()`, `unlock()`, `getItem()`, `listItems()`
- JSON解析にGsonを使用（kotlinx-serializationではなく）

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

### ホストモジュール設定

**one-sakura (Nginx)**:
- `enable_one_sakura = true`: モジュールを有効化（デフォルト: true）
- `nginx_enabled = true`: nginxインストールを有効化
- `nginx_server_name = "0.0.0.0"`: すべてのリクエストを受け付ける
- `nginx_target_host = "one-sakura"`: one-sakuraサーバー（`133.242.178.198`にマッピング）

**k8s4 (Node Exporter)**:
- `enable_k8s4 = true`: モジュールを有効化（デフォルト: true）
- `node_exporter_enabled = true`: Node Exporterインストールを有効化
- `node_exporter_version = "1.6.1"`: Node Exporterバージョン
- `node_exporter_port = 9100`: Node Exporterポート
- `target_host = "k8s4"`: リモートホスト（`192.168.1.120`にマッピング）

**lxc-nginx (LXC Nginx)**:
- `enable_lxc_nginx = false`: モジュールを有効化（デフォルト: false）
- `lxc_nginx_enabled = true`: LXC nginxインストールを有効化
- `lxc_nginx_server_name = "0.0.0.0"`: すべてのリクエストを受け付ける
- `lxc_nginx_target_host = "lxc-nginx"`: LXCホスト（`192.168.3.100`にマッピング）
- SSH接続はrootユーザーを使用

## 開発環境構築

### 前提条件
- Java 21 (Kotlin アプリケーション用)
- Terraform (両実行方式で必要)
- SSH鍵設定 (リモートホストアクセス用)

### Kotlin アプリケーション開発
```bash
# プロジェクトのビルドとテスト（全モジュール）
./gradlew build

# 特定モジュールのビルド
./gradlew :app:build
./gradlew :infrastructure:build

# 単一テストの実行
./gradlew test --tests AppTest.terraformRunnerCanBeCreated

# 開発時のアプリケーション実行
./gradlew run --args="validate"

# 配布パッケージの作成とテスト
./gradlew installDist
app/build/install/app/bin/app help
```

## 重要な実装上の注意点

### パッケージ構造の注意
- `model`モジュールは`net.kigawa.kinfra.model`パッケージを使用（ディレクトリは`model/src/main/kotlin/net/kigawa/kinfra/domain/`）
- 他のモジュールからは`import net.kigawa.kinfra.model.*`でインポート

### 既存コードとの互換性
- `ProcessExecutor`インターフェースは既に`infrastructure`モジュールに存在
- 新しい実装を追加する場合は、既存のシグネチャ（`args: Array<String>`, `workingDir: File?`等）を維持
- `executeWithOutput()`は出力取得用、`execute()`は標準出力継承用

### 依存性注入の追加
新しいコマンドやサービスを追加する場合：
1. インターフェース/クラスを適切なモジュールに配置
2. `di/AppModule.kt`にバインディングを追加
3. コンストラクタインジェクションを使用

### 新しいホストモジュールの追加
新しいホストを追加する手順：

1. **モジュールディレクトリの作成**:
   ```bash
   mkdir -p terraform/host/new-host
   ```

2. **variables.tfの作成**:
   ```hcl
   # terraform/host/new-host/variables.tf
   variable "ssh_user" {
     description = "SSH username"
     type        = string
     default     = "kigawa"
   }

   variable "ssh_key_path" {
     description = "Path to SSH private key"
     type        = string
     default     = ""
   }
   # ... その他の変数
   ```

3. **main.tfの作成**:
   - SSH接続設定（`connection`ブロック）
   - リソース定義（`null_resource`でプロビジョニング）
   - テンプレートファイルの参照

4. **locals.tf（オプション）**:
   - 複雑なパス構造が必要な場合に作成
   - ネストした変数構造を定義

5. **hosts.tfへの追加**:
   ```hcl
   # terraform/hosts.tf
   module "new_host" {
     source = "./host/new-host"
     count  = var.enable_new_host ? 1 : 0

     ssh_user     = var.ssh_user
     ssh_key_path = var.ssh_key_path
   }
   ```

6. **variables.tfへの追加**:
   ```hcl
   # terraform/variables.tf
   variable "enable_new_host" {
     description = "Whether to enable new-host configuration"
     type        = bool
     default     = false
   }
   ```

- 日本語を使う
