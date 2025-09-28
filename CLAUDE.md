# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

このプロジェクトは本番環境向けのインフラストラクチャ管理を行うTerraformベースのInfrastructure as Code (IaC) プロジェクトです。主要機能：

- **Nginx設定とデプロイ**: one-sakuraサーバーへのnginxインストールと設定（リバースプロキシ、SSL/TLS、TCP/UDPストリーム設定）
- **Prometheus監視**: Node Exporterのリモートインストール
- **Kubernetesリソース管理**: Terraform Kubernetesプロバイダー経由での直接管理
- **SSH認証**: Bitwardenからの自動SSH鍵取得と管理

## よく使用するコマンド

### 基本操作
```bash
# 本番環境を初期化
./terraform.sh init prod

# 設定を検証
./terraform.sh validate

# デプロイメント計画を作成
./terraform.sh plan prod

# 変更を適用
./terraform.sh apply prod

# Terraformファイルをフォーマット
./terraform.sh fmt
```

### Nginx設定デプロイ（one-sakura）
```bash
# one-sakuraサーバーにnginxをインストール・設定
terraform apply -var="nginx_enabled=true" -var="target_host=one-sakura"

# SSH接続をテスト
ssh -F ssh_config one-sakura
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

### 主要コンポーネント
- **メインTerraform設定** (`main.tf`): SSH経由でのnginxインストール・Node Exporterデプロイメント
- **Kubernetesモジュール** (`kubernetes/`): Terraform Kubernetesプロバイダーを使用してK8sリソースを直接管理
- **テンプレートシステム** (`templates/`): nginx設定、Node Exporterインストール用の動的テンプレート
- **SSH設定** (`ssh_config`): リモートホストへの接続設定、プロジェクト内SSH鍵管理

### nginxアーキテクチャ（one-sakura）
- **HTTP/HTTPSプロキシ**: `base.kigawa.net`へのリバースプロキシ設定
- **TCP/UDPストリーム**: Minecraft（ポート25565）、Kubernetes API（ポート6443）の転送
- **SSL/TLS終端**: Let's Encrypt証明書による暗号化
- **設定管理**: 完全なnginx.confとstream設定の自動生成・配布

### SSH認証パターン
- **Bitwarden統合**: SSH秘密鍵の安全な取得と管理
- **プロジェクト内鍵配置**: `./ssh-keys/id_ed25519`への自動配置
- **ホスト別設定**: `ssh_config`による接続先ホストのマッピング（`one-sakura` → `133.242.178.198`）

## 重要なパターン

### Kubernetesプロバイダー設定
```hcl
provider "kubernetes" {
  config_path    = pathexpand(var.kubernetes_config_path)
  config_context = var.kubernetes_config_context != "" ? var.kubernetes_config_context : null
}
```

### 変数ファイルの処理
- `environments/prod/terraform.tfvars`を使用
- 保存されたプラン（tfplan）適用時は変数ファイル不要
- 直接適用時は`-var-file`で変数を渡す

### Kubernetesリソースアクセス
- 設定ファイル: `/home/kigawa/.kube/config`（デフォルト）
- `kubernetes_config_path`変数でカスタマイズ可能
- `kubernetes_config_context`で特定のコンテキスト指定可能

## CI/CD統合

### GitHub Actionsワークフロー
- Kubernetesアクセス用の設定ファイルを`secrets.KUBE_CONFIG`から設定
- Terraform Kubernetesプロバイダーが直接クラスターに接続
- SSH+kubectlは使用せず、プロバイダー経由でのみリソース管理

### 必要なシークレット
- `BW_ACCESS_TOKEN`: Bitwardenアクセストークン
- `BW_SSH_KEY_GUID`: Node Exporter用SSHキー
- `TERRAFORM_ENV`: 本番環境のTerraform変数
- `KUBE_CONFIG`: Kubernetesクラスターアクセス用設定ファイル

## ファイル構造

```
infra/
├── main.tf                    # Node Exporter SSH デプロイメント
├── variables.tf              # 全変数定義
├── outputs.tf               # 出力定義
├── terraform.sh            # デプロイメントスクリプト
├── environments/
│   └── prod/terraform.tfvars # 本番環境設定
├── kubernetes/              # Kubernetesモジュール
│   ├── kubernetes.tf       # プロバイダー経由のK8sリソース管理
│   ├── variables.tf        # モジュール変数
│   └── manifests/          # YAMLマニフェストファイル
└── templates/              # Node Exporterインストールテンプレート
```

## 本番環境設定

### 重要な設定値
- `use_ssh_kubectl = false`: Kubernetesプロバイダーモードを使用
- `apply_k8s_manifests = true`: Kubernetesマニフェストの適用を有効化
- `kubernetes_config_path = "/home/kigawa/.kube/config"`: デフォルトのkubeconfig
- `apply_one_dev_manifests = true`: one/dev関連マニフェストも適用

### Nginx設定
- `nginx_enabled = true`: nginxインストールを有効化
- `nginx_server_name = "0.0.0.0"`: すべてのリクエストを受け付ける
- `target_host = "one-sakura"`: one-sakuraサーバー（`133.242.178.198`にマッピング）

### Node Exporter設定
- `node_exporter_enabled = true`: Node Exporterインストールを有効化
- `target_host = "k8s4"`: リモートホスト（`192.168.1.120`にマッピング）

## 重要な設定パターン

### ホストマッピング（main.tf内）
```hcl
# one-sakura用の特別なマッピング
host = var.target_host == "one-sakura" ? "133.242.178.198" : var.target_host
# k8s4用の特別なマッピング
host = var.target_host == "k8s4" ? "192.168.1.120" : var.target_host
```

### SSH鍵パス処理
```hcl
# プロジェクト内のSSH鍵を優先使用
private_key = var.ssh_key_path != "" ? file(var.ssh_key_path) : file("./ssh-keys/id_ed25519")
```

### nginx設定テンプレート
- `templates/nginx_default.conf.tpl`: メインnginx設定（HTTP/HTTPS、SSL）
- `templates/nginx_stream.conf.tpl`: ストリーム設定（TCP/UDP転送）
- `templates/nginx_install.sh.tpl`: インストールスクリプト