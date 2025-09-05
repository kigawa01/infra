# インフラ管理

このリポジトリは Terraform を使用したインフラストラクチャコードを含んでいます。

## 概要

このプロジェクトは以下のコンポーネントを管理します：

- **Prometheus Node Exporter**: システムメトリクス収集
- **Kubernetesマニフェスト**: Prometheus エコシステムのデプロイ
- **SSH経由の自動化**: リモートホストへの安全なデプロイ

## クイックスタート

```bash
# 1. リポジトリをクローン
git clone <repository-url>
cd infra

# 2. 開発環境を初期化
./terraform.sh init dev

# 3. 実行計画を確認
./terraform.sh plan dev

# 4. インフラをデプロイ
./terraform.sh apply dev
```

## 主要機能

### 🔧 Terraform実行スクリプト

`terraform.sh` スクリプトが環境別のデプロイを簡素化：

```bash
./terraform.sh [コマンド] [環境] [オプション]
```

**利用可能なコマンド**: `init`, `plan`, `apply`, `destroy`, `validate`, `fmt`  
**対応環境**: `dev`, `staging`, `prod`

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
├── README.md             # このファイル
├── main.tf               # メインTerraform設定
├── variables.tf          # 変数定義
├── outputs.tf            # 出力定義
├── terraform.sh          # Terraform実行スクリプト
├── ssh_config            # SSH接続設定
├── docs/                 # 詳細ドキュメント
│   ├── terraform-usage.md    # Terraform使用方法
│   ├── node-exporter.md      # Node Exporter設定
│   ├── kubernetes.md         # Kubernetes設定
│   └── ssh-configuration.md  # SSH設定
├── templates/            # テンプレートファイル
├── generated/            # 生成されたスクリプト（実行時作成）
├── kubernetes/           # Kubernetes関連ファイル
│   └── manifests/        # Kubernetesマニフェスト
└── environments/         # 環境固有の設定
    ├── dev/              # 開発環境
    ├── staging/          # ステージング環境
    └── prod/             # 本番環境
```

## 詳細ドキュメント

各コンポーネントの詳細な設定と使用方法については、以下のドキュメントを参照してください：

- **[Terraform使用方法](docs/terraform-usage.md)** - terraform.shスクリプトの詳細な使用方法
- **[Node Exporter設定](docs/node-exporter.md)** - Prometheus Node Exporterの設定とトラブルシューティング
- **[Kubernetes設定](docs/kubernetes.md)** - Kubernetesマニフェストの管理と適用方法  
- **[SSH設定](docs/ssh-configuration.md)** - SSH接続とセキュリティ設定

## 環境設定例

### 開発環境 (environments/dev/terraform.tfvars)

```hcl
environment = "dev"

# Node Exporter
node_exporter_enabled = true
node_exporter_version = "1.6.1"
node_exporter_port = 9100

# SSH設定
target_host = "192.168.1.120"  # k8s4
ssh_user = "kigawa"
ssh_key_path = "~/.ssh/key/id_ed25519"

# Kubernetes設定
apply_k8s_manifests = true
use_ssh_kubectl = true
apply_nginx_exporter = false
```

## よくある使用例

```bash
# sudo_passwordを指定してデプロイ
./terraform.sh apply dev -var="sudo_password=your_password"

# nginx-exporterを有効にしてデプロイ
./terraform.sh apply prod -var="apply_nginx_exporter=true"

# Kubernetes Provider方式でデプロイ
./terraform.sh apply prod -var="use_ssh_kubectl=false"
```

## セキュリティ注意事項

- SSH秘密鍵はgitリポジトリに含めない
- `sudo_password`をバージョン管理に含めない
- 本番環境では最小権限の原則に従う

## トラブルシューティング

問題が発生した場合は、以下を確認してください：

1. SSH接続: `ssh -i ~/.ssh/key/id_ed25519 kigawa@192.168.1.120`
2. sudo権限: リモートホストでパスワードなしsudoが設定されているか
3. Kubernetes設定: kubeconfigファイルが正しく配置されているか

詳細なトラブルシューティング情報は各ドキュメントを参照してください。