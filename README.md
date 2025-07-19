# インフラ管理

このリポジトリは Terraform を使用したインフラストラクチャコードを含んでいます。

## Terraform 実行スクリプト

異なる環境でのTerraform操作を簡略化するため、bashスクリプト `terraform.sh` が提供されています。スクリプトはTerraformがインストールされていない場合、自動的にインストールを試みます。

### 使用方法

```bash
./terraform.sh [コマンド] [環境] [オプション]
```

### コマンド

- `init` - Terraform作業ディレクトリを初期化
- `plan` - 実行計画を作成
- `apply` - 必要な変更を適用して目的の状態に到達
- `destroy` - Terraformが管理するインフラストラクチャを削除
- `validate` - 設定ファイルを検証
- `fmt` - 設定ファイルを標準形式に再フォーマット
- `help` - ヘルプメッセージを表示

### 環境

- `dev` - 開発環境
- `staging` - ステージング環境
- `prod` - 本番環境

### オプション

- `-auto-approve` - 対話的な承認をスキップ（apply/destroy時）
- `-var-file` - 変数ファイルを指定

### 例

```bash
# 開発環境を初期化
./terraform.sh init dev

# 本番環境の変更を計画
./terraform.sh plan prod

# ステージング環境に変更を適用
./terraform.sh apply staging

# 開発環境を自動承認で削除
./terraform.sh destroy dev -auto-approve

# カスタム変数ファイルで適用
./terraform.sh apply prod -var-file=custom.tfvars
```

## ディレクトリ構造

リポジトリは以下の構造に従います：

```
infra/
├── main.tf               # メインTerraform設定
├── variables.tf          # 変数定義
├── outputs.tf            # 出力定義
├── terraform.sh          # Terraform実行スクリプト
├── templates/            # テンプレートファイル
│   ├── node_exporter_install.sh.tpl  # Node Exporterインストールスクリプトテンプレート
│   └── deploy_remote.sh.tpl          # リモートデプロイスクリプトテンプレート
├── generated/            # 生成されたスクリプト（実行時に作成）
│   ├── install_node_exporter.sh      # 生成されたNode Exporterインストールスクリプト
│   └── deploy_to_remote.sh           # 生成されたリモートデプロイスクリプト
├── kubernetes/           # Kubernetes関連ファイル
│   └── manifests/        # Kubernetesマニフェスト
│       ├── ingress.yml   # Prometheus Grafana用のIngressマニフェスト
│       ├── nginx-exporter.yml # Nginx Exporter用のDeploymentマニフェスト（コメントアウト済み）
│       ├── prometheus.yml # Prometheus用のArgo CD Applicationマニフェスト
│       └── pve-exporter.yml # Proxmox VE Exporter用のDeploymentとServiceマニフェスト
└── environments/         # 環境固有の設定を含む
    ├── dev/              # 開発環境
    ├── staging/          # ステージング環境
    └── prod/             # 本番環境
```

各環境ディレクトリには環境固有の変数ファイル（terraform.tfvars）が含まれています。

## Prometheus Node Exporter

このインフラストラクチャには Prometheus Node Exporter の設定が含まれています。Node Exporter はシステムメトリクスを収集し、Prometheus がスクレイピングできるようにします。

### 設定オプション

Node Exporter の設定は以下の変数で制御できます：

- `node_exporter_enabled` - Node Exporter を有効にするかどうか（デフォルト: true）
- `node_exporter_version` - インストールする Node Exporter のバージョン（デフォルト: 1.6.1）
- `node_exporter_port` - Node Exporter が使用するポート（デフォルト: 9100）

これらの変数は各環境の `terraform.tfvars` ファイルで設定できます：

```hcl
# Node Exporter configuration
node_exporter_enabled = true
node_exporter_version = "1.6.1"
node_exporter_port = 9100
```

## SSH接続オプション

このインフラストラクチャはリモートホストにNode ExporterをデプロイするためにSSH接続を使用します。以下の変数でSSH接続を設定できます：

- `target_host` - Node ExporterをインストールするターゲットホストのIPアドレス（デフォルト: 192.168.1.103）
- `ssh_user` - リモート接続用のSSHユーザー名（デフォルト: kigawa）
- `ssh_key_path` - SSHプライベートキーファイルへのパス（デフォルト: 空文字列）
- `ssh_password` - SSHパスワード（SSHキーが利用できない場合に使用）（デフォルト: 空文字列）
- `sudo_password` - sudo権限でコマンドを実行するためのパスワード（デフォルト: 空文字列）

### sudo権限の要件

Node Exporterのインストールスクリプトはroot権限を必要とするため、sudoを使用して実行されます。以下の点に注意してください：

- インストールスクリプトはsudoコマンドを使用して実行されます
- sudoがパスワードを要求する場合、以下のいずれかの方法で対応できます：
  1. sudo_password変数を設定してsudoパスワードを提供する（最も簡単）
  2. ターゲットホスト上でsudoをパスワードなしで設定する
  3. rootユーザーとしてSSH接続を行う（ssh_userをrootに設定）

#### sudo_password変数を使用する方法

terraform.tfvarsファイルまたはコマンドラインでsudo_password変数を設定します：

```hcl
# terraform.tfvarsファイルに追加
sudo_password = "your_sudo_password"
```

または、コマンドラインで指定：

```bash
./terraform.sh apply dev -var="sudo_password=your_sudo_password"
```

**注意**: セキュリティ上の理由から、sudo_passwordをバージョン管理されたファイルに保存しないでください。

#### sudoをパスワードなしで設定する方法

ターゲットホスト上で以下のコマンドを実行して、特定のユーザー（例：kigawa）がパスワードなしでsudoを使用できるようにします：

```bash
# ターゲットホスト上で実行
echo "kigawa ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/kigawa
sudo chmod 440 /etc/sudoers.d/kigawa
```

**注意**: セキュリティ上の理由から、本番環境では特定のコマンドのみにNOPASSWDを制限することを検討してください。

### SSHキーの保存場所

セキュリティ上の理由から、SSHの秘密鍵はgitの対象外の場所に保存する必要があります。推奨される保存場所は以下の通りです：

- 開発環境: `~/.ssh/dev-key/infra_dev_key`
- ステージング環境: `~/.ssh/key/infra_staging_key`
- 本番環境: `~/.ssh/main/infra_prod_key`

これらの変数は各環境の `terraform.tfvars` ファイルで設定できます：

```hcl
# SSH connection configuration
target_host = "192.168.1.103"
ssh_user = "ubuntu"
ssh_key_path = "~/.ssh/dev-key/infra_dev_key"  # SSHキーのパスを指定（gitの対象外の場所に保存）
ssh_password = ""  # SSHキーを使用する場合は空のままにします
sudo_password = ""  # sudoパスワードが必要な場合に設定します
```

## Kubernetesマニフェスト

このインフラストラクチャには、Terraformを使用してKubernetesクラスターに適用できるマニフェストが含まれています。

### Kubernetesマニフェストの概要

`kubernetes/manifests/` ディレクトリには以下のKubernetesマニフェストが含まれています：

- `ingress.yml` - Prometheus Grafanaにアクセスするための Kubernetes Ingress リソース
- `nginx-exporter.yml` - Nginx メトリクスを収集するための Deployment リソース（現在はコメントアウトされています）
- `prometheus.yml` - Prometheus スタックをデプロイするための Argo CD Application リソース
- `pve-exporter.yml` - Proxmox VE メトリクスを収集するための Deployment と Service リソース

### Kubernetesマニフェストの適用方法

このインフラストラクチャでは、Kubernetesマニフェストを適用するための2つの方法をサポートしています：

1. **Kubernetes Provider方式**: Terraformの Kubernetes プロバイダーを使用して直接適用
2. **SSH+kubectl方式**: 指定されたホスト（デフォルト: 192.168.1.50）にSSH接続し、kubectlコマンドを使用して適用

デフォルトでは、**SSH+kubectl方式**が使用されます。

### Kubernetes設定オプション

Kubernetesマニフェストの適用は以下の変数で制御できます：

#### 共通設定

- `apply_k8s_manifests` - Kubernetesマニフェストを適用するかどうか（デフォルト: true）
- `apply_nginx_exporter` - nginx-exporterマニフェストを適用するかどうか（デフォルト: false、コメントアウトされているため）

#### 適用方法の選択

- `use_ssh_kubectl` - SSH+kubectl方式を使用するかどうか（デフォルト: true）。falseの場合はKubernetes Provider方式が使用されます

#### Kubernetes Provider方式の設定（use_ssh_kubectl = false の場合）

- `kubernetes_config_path` - Kubernetesの設定ファイルへのパス（デフォルト: "~/.kube/config"）
- `kubernetes_config_context` - 使用するKubernetes設定コンテキスト（デフォルト: ""、現在のコンテキストを使用）

#### SSH+kubectl方式の設定（use_ssh_kubectl = true の場合）

- `target_host` - SSH接続先のホストIPアドレス（デフォルト: "192.168.1.50"）
- `ssh_user` - SSH接続用のユーザー名（デフォルト: "kigawa"）
- `ssh_key_path` - SSH秘密鍵へのパス（デフォルト: ""）
- `ssh_password` - SSHパスワード（SSH鍵が利用できない場合）（デフォルト: ""）
- `remote_manifests_dir` - リモートホスト上でマニフェストをコピーするディレクトリ（デフォルト: "/tmp/k8s-manifests"）
- `remote_kubectl_context` - リモートホスト上で使用するkubectlコンテキスト（デフォルト: ""、現在のコンテキストを使用）

これらの変数は各環境の `terraform.tfvars` ファイルで設定できます：

```hcl
# Kubernetes configuration - SSH+kubectl方式（デフォルト）
target_host = "192.168.1.50"
ssh_user = "kigawa"
ssh_key_path = "~/.ssh/main/infra_prod_key"
use_ssh_kubectl = true
apply_k8s_manifests = true
apply_nginx_exporter = false

# または、Kubernetes Provider方式
use_ssh_kubectl = false
kubernetes_config_path = "~/.kube/config"
kubernetes_config_context = "my-cluster-context"
apply_k8s_manifests = true
```

### Kubernetesマニフェストの適用

Kubernetesマニフェストを適用するには、通常のTerraform操作を使用します：

```bash
# 開発環境でKubernetesマニフェストを適用する計画を作成
./terraform.sh plan dev

# 開発環境にKubernetesマニフェストを適用（SSH+kubectl方式）
./terraform.sh apply dev

# 本番環境にKubernetesマニフェストを適用（特定の変数を上書き）
./terraform.sh apply prod -var="apply_nginx_exporter=true"

# Kubernetes Provider方式を使用して適用
./terraform.sh apply prod -var="use_ssh_kubectl=false"
```

### 注意事項

- SSH+kubectl方式を使用する場合：
  - リモートホスト（デフォルト: 192.168.1.50）にSSHでアクセスできる必要があります
  - リモートホストにkubectlがインストールされている必要があります
  - リモートホスト上のkubectlがKubernetesクラスターにアクセスできる必要があります

- Kubernetes Provider方式を使用する場合：
  - ローカルマシンからKubernetesクラスターにアクセスできる必要があります
  - 指定されたkubeconfigファイルが有効である必要があります

- 共通の注意事項：
  - `nginx-exporter.yml` はデフォルトでコメントアウトされているため、適用するには `apply_nginx_exporter=true` を設定する必要があります
  - Argo CDが設定されている場合、`prometheus.yml` のApplication リソースはArgo CDによって処理されます

## Terraform出力

このインフラストラクチャは、デプロイ後に以下の出力値を提供します：

- `target_host` - Node Exporterインストール用のターゲットホスト
- `node_exporter_version` - 設定されたNode Exporterのバージョン（無効な場合は "disabled"）
- `node_exporter_port` - Node Exporter用に設定されたポート（無効な場合は "N/A"）
- `node_exporter_url` - Node ExporterメトリクスにアクセスするためのURL（無効な場合は "N/A"）
- `installation_status` - インストールステータスメッセージ

これらの出力値は、`terraform apply` または `./terraform.sh apply [環境]` コマンドの実行後に表示されます。