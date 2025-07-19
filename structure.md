# インフラリポジトリ構造

このドキュメントは Terraform インフラストラクチャリポジトリの構造と組織化について説明します。

## ディレクトリ構造

```
infra/
├── README.md                   # リポジトリドキュメント
├── structure.md                # このファイル - リポジトリ構造のドキュメント
├── .gitignore                  # Terraform ファイルのための Git 無視ルール
├── terraform.sh                # Terraform 実行スクリプト (自動インストール機能付き)
├── main.tf                     # メインTerraform設定
├── variables.tf                # 変数定義
├── outputs.tf                  # 出力定義
├── templates/                  # テンプレートファイル
│   ├── node_exporter_install.sh.tpl  # Node Exporterインストールスクリプトテンプレート
│   └── deploy_remote.sh.tpl    # リモートデプロイスクリプトテンプレート
├── generated/                  # 生成されたスクリプト（実行時に作成）
│   ├── install_node_exporter.sh      # 生成されたNode Exporterインストールスクリプト
│   └── deploy_to_remote.sh     # 生成されたリモートデプロイスクリプト
├── kubernetes/                 # Kubernetes関連ファイル
│   └── manifests/              # Kubernetesマニフェスト
│       ├── ingress.yml         # Prometheus Grafana用のIngressマニフェスト
│       ├── nginx-exporter.yml  # Nginx Exporter用のDeploymentマニフェスト（コメントアウト済み）
│       ├── prometheus.yml      # Prometheus用のArgo CD Applicationマニフェスト
│       └── pve-exporter.yml    # Proxmox VE Exporter用のDeploymentとServiceマニフェスト
└── environments/               # 環境固有の設定
    ├── dev/                    # 開発環境
    │   └── terraform.tfvars    # 開発環境の変数
    ├── staging/                # ステージング環境
    │   └── terraform.tfvars    # ステージング環境の変数
    └── prod/                   # 本番環境
        └── terraform.tfvars    # 本番環境の変数
```

## ファイル説明

### ルートレベルファイル

- **main.tf**: 主要なインフラストラクチャリソースの定義（Node Exporterのインストール、Kubernetesマニフェストの適用）
- **variables.tf**: インフラストラクチャ全体で使用されるすべての入力変数を定義（SSH設定、Node Exporter設定、Kubernetes設定）
- **outputs.tf**: 他の設定で使用したり、デプロイ後に表示できる出力値を定義
- **.gitignore**: 機密ファイル（*.tfstate、*.tfvars（environments/*/terraform.tfvars を除く）、.terraform/、generated/、SSH鍵）をバージョン管理から除外

### テンプレートファイル

- **node_exporter_install.sh.tpl**: Node Exporterをインストールするためのbashスクリプトテンプレート
- **deploy_remote.sh.tpl**: リモートホストにNode Exporterをデプロイするためのbashスクリプトテンプレート

### 生成されたファイル

実行時に生成されるファイル：
- **install_node_exporter.sh**: テンプレートから生成されたNode Exporterインストールスクリプト
- **deploy_to_remote.sh**: テンプレートから生成されたリモートデプロイスクリプト

### Kubernetesマニフェスト

`kubernetes/manifests/` ディレクトリには、Terraformを使用してKubernetesに適用されるマニフェストが含まれています：
- **ingress.yml**: Prometheus Grafanaにアクセスするための Kubernetes Ingress リソース
- **nginx-exporter.yml**: Nginx メトリクスを収集するための Deployment リソース（現在はコメントアウトされています）
- **prometheus.yml**: Prometheus スタックをデプロイするための Argo CD Application リソース
- **pve-exporter.yml**: Proxmox VE メトリクスを収集するための Deployment と Service リソース

これらのマニフェストは、以下の2つの方法のいずれかで適用できます：
1. **Kubernetes Provider方式**: Terraformの Kubernetes プロバイダーを使用して直接適用
2. **SSH+kubectl方式**: 192.168.1.50などの指定されたホストにSSH接続し、kubectlコマンドを使用して適用

### 環境設定

各環境ディレクトリには以下が含まれます：
- **terraform.tfvars**: 環境固有の変数値（環境名、Node Exporterの設定、SSH接続設定など）

### 環境詳細

- **dev/**: 開発環境の設定
- **staging/**: ステージング環境の設定
- **prod/**: 本番環境の設定

## 使用パターン

### 異なる環境へのデプロイ

terraform.sh スクリプトを使用する方法（推奨）:

```bash
# 開発環境を初期化
./terraform.sh init dev

# 開発環境のデプロイメントを計画
./terraform.sh plan dev

# 開発環境に適用
./terraform.sh apply dev

# 本番環境のデプロイメントを計画
./terraform.sh plan prod
```

直接 Terraform コマンドを使用する方法:

```bash
# Terraform を初期化
terraform init

# 開発環境のデプロイメントを計画
terraform plan -var-file=environments/dev/terraform.tfvars

# 開発環境に適用
terraform apply -var-file=environments/dev/terraform.tfvars

# 本番環境のデプロイメントを計画
terraform plan -var-file=environments/prod/terraform.tfvars
```

### 新しい環境の追加

1. `environments/` 配下に新しいディレクトリを作成
2. 環境固有の `terraform.tfvars` ファイルを追加
3. 新しい環境の要件に合わせて変数をカスタマイズ

## ベストプラクティス

- `.gitignore` を使用して機密データをバージョン管理から除外
- 設定には環境固有の変数ファイルを使用
- すべての変数と出力をドキュメント化
- 環境間で一貫した命名規則に従う
- SSHの秘密鍵はgitの対象外の場所に保存する
  - 開発環境: `~/.ssh/dev-key/infra_dev_key`
  - ステージング環境: `~/.ssh/key/infra_staging_key`
  - 本番環境: `~/.ssh/main/infra_prod_key`

## sudo権限の要件

Node Exporterのインストールスクリプト（node_exporter_install.sh.tpl）はroot権限を必要とするため、以下の点に注意してください：

- インストールスクリプトはsudoコマンドを使用して実行されます
- sudoがパスワードを要求する場合、以下のいずれかの方法で対応できます：
  1. sudo_password変数を設定してsudoパスワードを提供する（最も簡単）
  2. ターゲットホスト上でsudoをパスワードなしで設定する
  3. rootユーザーとしてSSH接続を行う（ssh_userをrootに設定）

### sudo_password変数を使用する方法

terraform.tfvarsファイルまたはコマンドラインでsudo_password変数を設定します：

```bash
# terraform.tfvarsファイルに追加
sudo_password = "your_sudo_password"

# または、コマンドラインで指定
terraform apply -var="sudo_password=your_sudo_password" -var-file=environments/dev/terraform.tfvars
```

**注意**: セキュリティ上の理由から、sudo_passwordをバージョン管理されたファイルに保存しないでください。

### sudoをパスワードなしで設定する方法

ターゲットホスト上で以下のコマンドを実行して、特定のユーザー（例：kigawa）がパスワードなしでsudoを使用できるようにします：

```bash
# ターゲットホスト上で実行
echo "kigawa ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/kigawa
sudo chmod 440 /etc/sudoers.d/kigawa
```

**注意**: セキュリティ上の理由から、本番環境では特定のコマンドのみにNOPASSWDを制限することを検討してください。