# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

このプロジェクトは本番環境向けのインフラストラクチャ管理を行うTerraformベースのInfrastructure as Code (IaC) プロジェクトと、Terraformを実行するKotlin CLIアプリケーションから構成されています。

### 主要コンポーネント
- **Terraform IaC**: Nginx設定とデプロイ、Prometheus監視、Kubernetesリソース管理
- **Kotlin CLI App**: Terraformコマンドを実行するJavaアプリケーション（`app/`）
- **SSH認証**: Bitwardenからの自動SSH鍵取得と管理
- **Cloudflare R2 Backend**: Terraform state をリモートに保存（オプション）

## よく使用するコマンド

### Terraform関連
```bash
# 完全なデプロイパイプライン（推奨）
export BW_SESSION=$(bw unlock --raw)
./gradlew run --args="deploy"

# 個別コマンド
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

### Bitwarden初期設定と認証

#### 1. Bitwarden CLIのインストール
```bash
# macOS (Homebrew)
brew install bitwarden-cli

# または npm経由
npm install -g @bitwarden/cli

# インストール確認
bw --version
```

#### 2. Bitwardenへのログインとセッション管理
```bash
# 初回ログイン（メールアドレスを入力）
bw login your-email@example.com

# ログイン済みか確認
bw login --check

# Vaultのアンロック（セッショントークンを取得）
bw unlock
# または環境変数に直接設定
export BW_SESSION=$(bw unlock --raw)

# セッション状態の確認
bw status | jq
```

#### 3. SSH鍵の保存と取得

**Bitwardenへの保存（初回のみ）**:
```bash
# 既存のSSH秘密鍵をBitwardenに保存
# 1. Bitwarden Webアプリまたはデスクトップアプリでアイテムを作成
# 2. アイテムタイプ: "SSH Key"
# 3. アイテム名: "main" （または任意の名前）
# 4. Private Key フィールドに秘密鍵の内容を貼り付け

# または、CLI経由で作成
bw get template item | jq '.type = 2 | .secureNote.type = 0 | .name = "main" | .notes = "SSH key for infrastructure"' | bw encode | bw create item

# アイテムの確認
bw list items --search "main" | jq
```

**プロジェクトへの取得と配置**:
```bash
# SSH鍵をBitwardenから取得してプロジェクトに配置
bw get item "main" | jq -r '.notes' > ./ssh-keys/id_ed25519
# または、sshKey フィールドが存在する場合
bw get item "main" | jq -r '.sshKey.privateKey' > ./ssh-keys/id_ed25519

# パーミッション設定（重要）
chmod 600 ./ssh-keys/id_ed25519

# 公開鍵も必要な場合
ssh-keygen -y -f ./ssh-keys/id_ed25519 > ./ssh-keys/id_ed25519.pub
```

**セッション管理のベストプラクティス**:
```bash
# セッショントークンを環境変数に保存（推奨）
export BW_SESSION=$(bw unlock --raw)

# セッション付きでコマンド実行
bw list items --session "$BW_SESSION"

# セッションのロック（作業完了時）
bw lock
```

### Cloudflare R2 Backend 自動設定（Bitwarden統合）

#### 1. 準備と設定

**Bitwardenへのアイテム作成（初回のみ）**:
```bash
# 1. Bitwarden WebアプリまたはデスクトップアプリでR2認証情報のアイテムを作成
# 2. アイテム名: Cloudflare R2 Terraform Backend
# 3. カスタムフィールドを追加:
#    - access_key: R2 Access Key ID
#    - secret_key: R2 Secret Access Key
#    - account_id: Cloudflare Account ID
#    - bucket_name: kigawa-infra-state

# セットアップコマンドを実行してbackend.tfvarsを生成
./gradlew run --args="setup-r2"
```

#### 2. デプロイ実行

**推奨：deployコマンドで一括実行**:
```bash
# BW_SESSION環境変数を設定して自動実行
export BW_SESSION=$(bw unlock --raw)
./gradlew run --args="deploy"
```

**deployコマンドの動作フロー**:
1. backend.tfvarsの存在チェック（プレースホルダー検出）
2. Bitwardenから認証情報を取得（BW_SESSION環境変数が必須）
3. backend.tfvarsを自動生成
4. terraform init → plan → apply を順次実行

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
- `model`モジュールは`net.kigawa.kinfra.domain`パッケージを使用（ディレクトリは`model/src/main/kotlin/net/kigawa/kinfra/domain/`）
- 他のモジュールからは`import net.kigawa.kinfra.domain.*`でインポート

### 既存コードとの互換性
- `ProcessExecutor`インターフェースは既に`infrastructure`モジュールに存在
- 新しい実装を追加する場合は、既存のシグネチャ（`args: Array<String>`, `workingDir: File?`等）を維持
- `executeWithOutput()`は出力取得用、`execute()`は標準出力継承用

### 依存性注入の追加
新しいコマンドやサービスを追加する場合：
1. インターフェース/クラスを適切なモジュールに配置
2. `di/AppModule.kt`にバインディングを追加
3. コンストラクタインジェクションを使用

- 日本語を使う