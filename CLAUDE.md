# CLAUDE.md

このファイルは、このリポジトリでコードを操作する際のClaude Code (claude.ai/code) へのガイダンスを提供します。

## プロジェクト概要

このプロジェクトは、本番環境（prod）のPrometheusモニタリングインフラストラクチャとKubernetesデプロイメントを管理するTerraformベースのInfrastructure as Code (IaC) プロジェクトです。Terraform Kubernetesプロバイダーを使用してKubernetesリソースを直接管理し、SSH経由でNode Exporterのリモートインストールを行います。

## よく使用するコマンド

### 本番環境管理
```bash
# 本番環境を初期化
./terraform.sh init prod

# 本番環境のデプロイメント計画を作成
./terraform.sh plan prod -out=tfplan

# 変更を適用（保存されたプランを使用）
./terraform.sh apply prod tfplan

# 変更を直接適用（自動承認）
./terraform.sh apply prod -auto-approve

# インフラストラクチャを破棄
./terraform.sh destroy prod -auto-approve

# 設定を検証
./terraform.sh validate prod

# Terraformファイルをフォーマット
./terraform.sh fmt
```

## アーキテクチャ概要

### 主要コンポーネント
- **メインTerraform設定** (`main.tf`): SSH経由でのNode Exporterデプロイメントを処理
- **Kubernetesモジュール** (`kubernetes/`): Terraform Kubernetesプロバイダーを使用してK8sリソースを直接管理
- **テンプレートシステム** (`templates/`): Node Exporterインストール用の動的スクリプト生成
- **本番環境設定** (`environments/prod/`): 本番環境固有の変数ファイル

### デプロイメントアーキテクチャ
- **Kubernetesプロバイダーモード**: `use_ssh_kubectl = false`（デフォルト）
- Terraform Kubernetesプロバイダーを使用してマニフェストを直接適用
- Kubernetesクラスターに直接接続してリソースを管理
- SSH+kubectlモードは使用しない

### 主要機能
- **Node Exporterインストール**: SSH経由でのリモートホストへの自動インストール
- **Kubernetesリソース管理**: Terraformプロバイダー経由でのマニフェスト適用
- **Prometheusモニタリング**: 統合されたモニタリングスタックのデプロイ
- **統一された設定管理**: TerraformでインフラとK8sリソースを一元管理

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

### Node Exporter設定
- `node_exporter_enabled = true`: Node Exporterインストールを有効化
- `target_host = "k8s4"`: リモートホスト（`192.168.1.120`にマッピング）
- SSH経由でのリモートインストール（Kubernetesプロバイダーとは独立）

## 特別な考慮事項

### プロバイダー分離
- **Kubernetesリソース**: Terraform Kubernetesプロバイダー経由
- **Node Exporterインストール**: SSH経由（独立したプロセス）
- 両方とも同一のTerraform実行で管理

### 設定ファイル管理
- GitHub Actions: `secrets.KUBE_CONFIG`からkubeconfigを設定
- ローカル開発: `~/.kube/config`を使用
- `kubernetes_config_context`で特定のクラスター/名前空間を指定可能

### プランファイル処理
- `terraform apply tfplan`実行時は変数ファイル不要
- terraform.shが自動的に適切な引数を処理