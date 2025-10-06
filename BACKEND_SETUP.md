# Cloudflare R2 バックエンド設定ガイド

このガイドでは、Terraform の状態ファイルを Cloudflare R2 に保存する方法を説明します。

## 1. Cloudflare R2 の準備

### R2 バケットの作成

1. [Cloudflare Dashboard](https://dash.cloudflare.com/) にログイン
2. **R2 Object Storage** に移動
3. **Create bucket** をクリック
4. バケット名を入力（例: `kigawa-infra-state`）
5. バケットを作成

### API トークンの作成

1. Cloudflare Dashboard で **R2** → **Manage R2 API Tokens** に移動
2. **Create API Token** をクリック
3. 以下の権限を設定：
   - **Permissions**: Edit (Read & Write)
   - **Bucket**: 作成したバケットを選択
4. トークンを作成し、以下の情報を保存：
   - Access Key ID
   - Secret Access Key
   - Account ID

## 2. Backend 設定ファイルの作成

### 環境別設定（推奨）

本番環境用の設定ファイルを作成：

```bash
# environments/prod/backend.tfvars を編集
cat > environments/prod/backend.tfvars << 'EOF'
bucket     = "kigawa-infra-state"
key        = "prod/terraform.tfstate"
region     = "auto"
endpoint   = "https://<YOUR_ACCOUNT_ID>.r2.cloudflarestorage.com"
access_key = "<YOUR_ACCESS_KEY_ID>"
secret_key = "<YOUR_SECRET_ACCESS_KEY>"
EOF

# 権限を制限
chmod 600 environments/prod/backend.tfvars
```

### グローバル設定（オプション）

すべての環境で共通の設定を使う場合：

```bash
# backend.tfvars を作成
cat > backend.tfvars << 'EOF'
bucket     = "kigawa-infra-state"
key        = "terraform.tfstate"
region     = "auto"
endpoint   = "https://<YOUR_ACCOUNT_ID>.r2.cloudflarestorage.com"
access_key = "<YOUR_ACCESS_KEY_ID>"
secret_key = "<YOUR_SECRET_ACCESS_KEY>"
EOF

# 権限を制限
chmod 600 backend.tfvars
```

## 3. Terraform の初期化

### Bash スクリプト経由

```bash
# 既存のローカル state から移行する場合
./terraform.sh init prod

# 新規初期化の場合
./terraform.sh init prod
```

### Kotlin CLI 経由

```bash
# Kotlin アプリケーションを使用
./gradlew run --args="init prod"

# または、インストール済みバイナリを使用
app/build/install/app/bin/app init prod
```

## 4. 既存の State の移行

ローカルに既存の state ファイルがある場合、R2 への移行が必要です。

```bash
# 1. Backend 設定を追加して初期化
./terraform.sh init prod

# 2. Terraform が自動的に移行を提案します
#    "Do you want to copy existing state to the new backend?" → yes

# 3. 移行完了後、ローカルの state ファイルを削除（任意）
# rm terraform.tfstate terraform.tfstate.backup
```

## 5. 動作確認

```bash
# State が R2 に保存されているか確認
./terraform.sh plan prod

# State list を表示
terraform state list
```

## 6. セキュリティのベストプラクティス

### 1. 設定ファイルを Git から除外

`.gitignore` は既に設定済みですが、確認してください：

```bash
# backend.tfvars が除外されていることを確認
git status | grep backend.tfvars
# → 何も表示されなければOK
```

### 2. 環境変数を使用（推奨）

機密情報をファイルに保存したくない場合、環境変数を使用：

```bash
export TF_CLI_ARGS_init="-backend-config=bucket=kigawa-infra-state \
  -backend-config=key=prod/terraform.tfstate \
  -backend-config=region=auto \
  -backend-config=endpoint=https://<ACCOUNT_ID>.r2.cloudflarestorage.com \
  -backend-config=access_key=$R2_ACCESS_KEY \
  -backend-config=secret_key=$R2_SECRET_KEY"

terraform init
```

### 3. Bitwarden での管理（推奨）

R2 認証情報を Bitwarden で管理：

```bash
# Bitwarden に保存
bw create item '{
  "organizationId": null,
  "folderId": null,
  "type": 1,
  "name": "Cloudflare R2 Terraform Backend",
  "notes": "",
  "fields": [
    {"name": "access_key", "value": "<YOUR_ACCESS_KEY>", "type": 0},
    {"name": "secret_key", "value": "<YOUR_SECRET_KEY>", "type": 1},
    {"name": "account_id", "value": "<YOUR_ACCOUNT_ID>", "type": 0}
  ]
}'

# 認証情報を取得して backend.tfvars を生成
bw get item "Cloudflare R2 Terraform Backend" | jq -r '.fields[] | "\(.name) = \"\(.value)\""'
```

## 7. CI/CD での使用

### GitHub Actions の例

```yaml
- name: Configure Terraform Backend
  env:
    R2_ACCESS_KEY: ${{ secrets.R2_ACCESS_KEY }}
    R2_SECRET_KEY: ${{ secrets.R2_SECRET_KEY }}
    R2_ACCOUNT_ID: ${{ secrets.R2_ACCOUNT_ID }}
  run: |
    cat > backend.tfvars << EOF
    bucket     = "kigawa-infra-state"
    key        = "prod/terraform.tfstate"
    region     = "auto"
    endpoint   = "https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com"
    access_key = "${R2_ACCESS_KEY}"
    secret_key = "${R2_SECRET_KEY}"
    EOF

- name: Terraform Init
  run: ./terraform.sh init prod
```

## トラブルシューティング

### エラー: "Error configuring the backend"

- `backend.tfvars` のパスが正しいか確認
- 認証情報が正しいか確認
- R2 バケットが存在するか確認

### エラー: "Access Denied"

- API トークンの権限を確認
- バケット名が正しいか確認

### State のロック

R2 は state locking をサポートしていません。DynamoDB を使用する場合は、追加設定が必要です。

```hcl
# 将来的に state locking が必要な場合
# DynamoDB テーブルを作成し、以下を追加：
# dynamodb_table = "terraform-state-lock"
```

## 参考リンク

- [Cloudflare R2 Documentation](https://developers.cloudflare.com/r2/)
- [Terraform S3 Backend](https://www.terraform.io/docs/language/settings/backends/s3.html)
- [Terraform Backend Configuration](https://www.terraform.io/docs/language/settings/backends/configuration.html)
