# ホスト別Terraform管理

各ホストを独立したTerraformプロジェクトとして管理します。各ホストディレクトリには専用のstate、backend設定、プロバイダー設定があります。

## ディレクトリ構造

```
hosts/
├── one-sakura/      # Nginxインストール (133.242.178.198)
├── k8s4/            # Node Exporterインストール (192.168.1.120)
├── lxc-nginx/       # LXC Nginxインストール (192.168.3.100)
├── host5/           # Node Exporterインストール (192.168.1.50)
└── kubernetes/      # Kubernetesマニフェスト適用
```

## 各ホストの説明

### one-sakura
- **ホスト**: 133.242.178.198
- **用途**: Nginxインストールと設定
- **SSH接続**: kigawa@133.242.178.198
- **デプロイ内容**: Nginx本体、nginx.conf、proxy.stream.conf

### k8s4
- **ホスト**: 192.168.1.120
- **用途**: Node Exporterインストール
- **SSH接続**: kigawa@192.168.1.120
- **デプロイ内容**: Node Exporter v1.6.1 (ポート: 9100)

### lxc-nginx
- **ホスト**: 192.168.3.100
- **用途**: LXC環境でのNginxインストール
- **SSH接続**: root@192.168.3.100
- **デプロイ内容**: Nginx本体、lxc_nginx.conf、lxc_proxy.stream.conf

### host5
- **ホスト**: 192.168.1.50
- **用途**: Node Exporterインストール
- **SSH接続**: kigawa@192.168.1.50
- **デプロイ内容**: Node Exporter v1.6.1 (ポート: 9100)

### kubernetes
- **用途**: Kubernetesマニフェストの適用
- **接続**: kubeconfigを使用 (デフォルト: ~/.kube/config)
- **デプロイ内容**: ingress.yml, prometheus.yml, pve-exporter.yml等

## 使用方法

### 基本コマンド

各ホストディレクトリで個別にTerraformを実行します：

```bash
# one-sakuraホストの初期化とデプロイ
cd hosts/one-sakura
terraform init -backend-config="bucket=<bucket-name>" -backend-config="key=one-sakura/terraform.tfstate" -backend-config="endpoint=<r2-endpoint>" -backend-config="region=auto" -backend-config="access_key=<access-key>" -backend-config="secret_key=<secret-key>"
terraform plan -var="ssh_key_path=../../ssh-keys/id_ed25519" -var="sudo_password=<password>"
terraform apply -var="ssh_key_path=../../ssh-keys/id_ed25519" -var="sudo_password=<password>"

# k8s4ホストのデプロイ
cd hosts/k8s4
terraform init -backend-config="bucket=<bucket-name>" -backend-config="key=k8s4/terraform.tfstate" -backend-config="endpoint=<r2-endpoint>" -backend-config="region=auto" -backend-config="access_key=<access-key>" -backend-config="secret_key=<secret-key>"
terraform plan -var="ssh_key_path=../../ssh-keys/id_ed25519" -var="sudo_password=<password>"
terraform apply -var="ssh_key_path=../../ssh-keys/id_ed25519" -var="sudo_password=<password>"

# Kubernetesマニフェストの適用
cd hosts/kubernetes
terraform init -backend-config="bucket=<bucket-name>" -backend-config="key=kubernetes/terraform.tfstate" -backend-config="endpoint=<r2-endpoint>" -backend-config="region=auto" -backend-config="access_key=<access-key>" -backend-config="secret_key=<secret-key>"
terraform plan
terraform apply
```

### 環境変数を使用する場合

```bash
export TF_VAR_ssh_key_path="../../ssh-keys/id_ed25519"
export TF_VAR_sudo_password="your-password"

cd hosts/one-sakura
terraform plan
terraform apply
```

### terraform.tfvarsを使用する場合

各ホストディレクトリに`terraform.tfvars`を作成：

```hcl
# hosts/one-sakura/terraform.tfvars
environment      = "prod"
ssh_user         = "kigawa"
ssh_key_path     = "../../ssh-keys/id_ed25519"
sudo_password    = "your-password"
nginx_server_name = "0.0.0.0"
```

その後、varsファイルなしでコマンド実行：

```bash
cd hosts/one-sakura
terraform plan
terraform apply
```

## 共通ファイル

### テンプレート
すべてのホストが共通のテンプレートを参照します：
- `terraform/templates/nginx_install.sh.tpl`
- `terraform/templates/nginx_default.conf.tpl`
- `terraform/templates/nginx_stream.conf.tpl`
- `terraform/templates/node_exporter_install.sh.tpl`
- `terraform/templates/lxc_nginx.conf.tpl`
- `terraform/templates/lxc_stream.conf.tpl`

### SSH鍵
共通のSSH鍵ディレクトリを使用：
- `ssh-keys/id_ed25519`

各ホストからは相対パス `../../ssh-keys/id_ed25519` で参照します。

## Backend設定

各ホストは独立したstateファイルをCloudflare R2に保存します：

- `one-sakura/terraform.tfstate`
- `k8s4/terraform.tfstate`
- `lxc-nginx/terraform.tfstate`
- `host5/terraform.tfstate`
- `kubernetes/terraform.tfstate`

## 利点

1. **独立性**: 各ホストが独立したstateを持つため、1つのホストの変更が他に影響しません
2. **並列デプロイ**: 複数ホストを同時にデプロイ可能
3. **シンプルな構成**: enable/disableフラグが不要
4. **明確な責任範囲**: 各ホストの設定が専用ディレクトリに集約
5. **柔軟性**: ホストごとに異なるTerraformバージョンやプロバイダーを使用可能

## 注意事項

- 各ホストのデプロイは完全に独立しているため、依存関係がある場合は手動で順序を制御する必要があります
- backend設定（R2認証情報）は各ホストで個別に設定が必要です
- SSH鍵やテンプレートファイルへのパスは相対パスで記述されているため、ホストディレクトリから実行する必要があります
