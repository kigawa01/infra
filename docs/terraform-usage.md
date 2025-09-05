# Terraform使用方法

このドキュメントは、プロジェクトでのTerraformの使用方法について詳しく説明します。

## 実行スクリプト

### terraform.sh スクリプト

異なる環境でのTerraform操作を簡略化するため、bashスクリプト `terraform.sh` が提供されています。

**特徴**:
- Terraformが未インストールの場合、自動インストール
- 環境別設定ファイルの自動適用
- エラーハンドリングとログ出力

### 基本使用方法

```bash
./terraform.sh [コマンド] [環境] [オプション]
```

### 利用可能なコマンド

| コマンド | 説明 | 使用例 |
|----------|------|--------|
| `init` | Terraform作業ディレクトリを初期化 | `./terraform.sh init dev` |
| `plan` | 実行計画を作成して表示 | `./terraform.sh plan prod` |
| `apply` | 変更を適用してインフラを構築 | `./terraform.sh apply staging` |
| `destroy` | Terraformが管理するリソースを削除 | `./terraform.sh destroy dev` |
| `validate` | 設定ファイルの構文を検証 | `./terraform.sh validate` |
| `fmt` | 設定ファイルを標準形式にフォーマット | `./terraform.sh fmt` |
| `help` | ヘルプメッセージを表示 | `./terraform.sh help` |

### 対応環境

| 環境 | 説明 | 設定ファイル |
|------|------|-------------|
| `dev` | 開発環境 | `environments/dev/terraform.tfvars` |
| `staging` | ステージング環境 | `environments/staging/terraform.tfvars` |
| `prod` | 本番環境 | `environments/prod/terraform.tfvars` |

### 利用可能なオプション

| オプション | 説明 | 使用例 |
|------------|------|--------|
| `-auto-approve` | 対話的な承認をスキップ | `./terraform.sh apply dev -auto-approve` |
| `-var-file` | カスタム変数ファイルを指定 | `./terraform.sh apply prod -var-file=custom.tfvars` |
| `-var` | 個別変数を設定 | `./terraform.sh apply dev -var="sudo_password=secret"` |

## 使用例

### 基本的なワークフロー

```bash
# 1. 開発環境の初期化
./terraform.sh init dev

# 2. 実行計画の確認
./terraform.sh plan dev

# 3. 変更の適用
./terraform.sh apply dev

# 4. リソースの確認（Terraformの外）
ssh -i ~/.ssh/key/id_ed25519 kigawa@192.168.1.120 "curl -s http://localhost:9100/metrics | head -5"
```

### 本番環境へのデプロイ

```bash
# 本番環境での慎重なデプロイ
./terraform.sh plan prod
# 計画を確認後...
./terraform.sh apply prod

# 緊急時の自動承認
./terraform.sh apply prod -auto-approve
```

### 個別設定の上書き

```bash
# sudo_passwordを一時的に指定
./terraform.sh apply dev -var="sudo_password=temporary_password"

# nginx-exporterを有効にして適用
./terraform.sh apply prod -var="apply_nginx_exporter=true"

# カスタム設定ファイルを使用
./terraform.sh apply prod -var-file=custom-prod.tfvars
```

### 環境のクリーンアップ

```bash
# 開発環境のリソースを削除
./terraform.sh destroy dev

# 自動承認で削除（注意）
./terraform.sh destroy dev -auto-approve
```

## 直接Terraformコマンドの使用

スクリプトを使用せずに、直接Terraformコマンドを実行することも可能です：

```bash
# 初期化
terraform init

# 開発環境の計画
terraform plan -var-file=environments/dev/terraform.tfvars

# 開発環境への適用
terraform apply -var-file=environments/dev/terraform.tfvars

# 本番環境の計画
terraform plan -var-file=environments/prod/terraform.tfvars

# 特定変数を上書きして適用
terraform apply -var-file=environments/prod/terraform.tfvars -var="node_exporter_enabled=false"
```

## 状態ファイルの管理

### ローカル状態ファイル

現在の設定では、状態ファイル（`terraform.tfstate`）はローカルに保存されます：

```bash
# 状態ファイルの確認
ls -la terraform.tfstate*

# 状態の表示
terraform show

# 特定リソースの状態表示
terraform state show null_resource.install_node_exporter[0]
```

### バックアップとリストア

```bash
# 状態ファイルのバックアップ
cp terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d-%H%M%S)

# 状態ファイルの一覧表示
terraform state list

# 特定リソースを状態から削除（注意）
terraform state rm null_resource.test_ssh_connection[0]
```

## デバッグとトラブルシューティング

### デバッグログの有効化

```bash
# 詳細ログを有効にして実行
export TF_LOG=DEBUG
./terraform.sh plan dev

# 特定レベルのログ
export TF_LOG=INFO    # INFO, WARN, ERROR, DEBUG, TRACE
./terraform.sh apply dev

# ログを無効化
unset TF_LOG
```

### 生成ファイルの確認

```bash
# 生成されたスクリプトファイルの確認
ls -la generated/
cat generated/install_node_exporter.sh
cat generated/kubectl_apply.sh
```

### よくある問題と解決方法

#### 1. 初期化エラー

```bash
# .terraformディレクトリを削除して再初期化
rm -rf .terraform .terraform.lock.hcl
./terraform.sh init dev
```

#### 2. 状態ファイルの不整合

```bash
# 状態の更新
terraform refresh -var-file=environments/dev/terraform.tfvars

# 強制的な状態同期（注意）
terraform apply -refresh-only -var-file=environments/dev/terraform.tfvars
```

#### 3. リソースの強制再作成

```bash
# 特定リソースを強制再作成
terraform taint null_resource.install_node_exporter[0]
./terraform.sh apply dev

# または、直接的な再作成指定
terraform apply -replace="null_resource.install_node_exporter[0]" -var-file=environments/dev/terraform.tfvars
```

## 設定ファイルの管理

### 環境固有設定

各環境ディレクトリの`terraform.tfvars`ファイルで設定を管理：

```hcl
# environments/dev/terraform.tfvars
environment = "dev"

# Node Exporter設定
node_exporter_enabled = true
node_exporter_version = "1.6.1"
node_exporter_port = 9100

# SSH設定
target_host = "192.168.1.120"
ssh_user = "kigawa"
ssh_key_path = "~/.ssh/key/id_ed25519"

# Kubernetes設定
apply_k8s_manifests = true
use_ssh_kubectl = true
apply_nginx_exporter = false
```

### 機密情報の管理

```bash
# 機密情報は環境変数で管理
export TF_VAR_sudo_password="secret_password"
export TF_VAR_ssh_password="ssh_password"

# または、.gitignoreされたファイルで管理
echo 'sudo_password = "secret"' > environments/dev/secrets.tfvars
./terraform.sh apply dev -var-file=environments/dev/secrets.tfvars
```

## パフォーマンス最適化

### 並列実行の調整

```bash
# 並列実行数を制限
terraform apply -parallelism=1 -var-file=environments/prod/terraform.tfvars

# 多くのリソースがある場合は並列実行数を増加
terraform apply -parallelism=20 -var-file=environments/dev/terraform.tfvars
```

### プランの保存と適用

```bash
# プランを保存
terraform plan -var-file=environments/prod/terraform.tfvars -out=prod.tfplan

# 保存されたプランを適用
terraform apply prod.tfplan

# プランファイルの確認
terraform show prod.tfplan
```

## セキュリティ考慮事項

### 1. 機密情報の保護

- `terraform.tfvars`ファイルに機密情報を含めない
- 環境変数またはセキュアなファイル管理システムを使用
- 状態ファイルにも機密情報が含まれることに注意

### 2. 状態ファイルのセキュリティ

```bash
# 状態ファイルの暗号化バックアップ
gpg --cipher-algo AES256 --compress-algo 1 --s2k-mode 3 --s2k-digest-algo SHA512 --s2k-count 65536 --symmetric --output terraform.tfstate.gpg terraform.tfstate

# 復号化
gpg --output terraform.tfstate --decrypt terraform.tfstate.gpg
```

### 3. アクセス制御

- SSH鍵の適切な権限設定
- sudo権限の最小化
- ネットワークアクセスの制限