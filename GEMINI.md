# GEMINI.md

## プロジェクト概要

このプロジェクトは、`kinfra` というツールで管理されるInfrastructure as Code (IaC) を含んでいます。`kinfra` はKotlinで書かれたTerraformのラッパーツールで、Bitwarden Secret Managerと連携して安全にシークレットを管理する機能を持ちます。プロジェクトの設定は `kinfra.yaml` ファイルで行われます。

## ビルドと実行

インフラストラクチャは `kinfra` ツールを使用して管理されます。`kinfra` がTerraformのコマンドをラップしているため、直接Terraformコマンドを実行する代わりに `kinfra` を使用します。

**前提条件:**
- `kinfra` ツールがインストールされていること。（インストールは `curl -fsSL https://raw.githubusercontent.com/kigawa-net/kinfra/main/install.sh | bash` で行えます）
- Terraformがインストールされていること。
- Kubernetesリソースを管理する場合、`kubectl`がインストールされ、対象のKubernetesクラスタに接続できるように設定されていること。
- 対象ホストへのSSHアクセスが可能であること。
- Bitwarden Secret Managerを使用するため、環境変数 `BWS_ACCESS_TOKEN` と `BW_PROJECT` が設定されていること。

**一般的なワークフロー:**

`kinfra` を使って各コンポーネント（モジュール）のインフラを管理します。

```bash
# ヘルプの表示
kinfra --help

# 変更の計画
kinfra plan <モジュール名>
#例: kinfra plan host5

# 初期化から適用までを一括実行
kinfra deploy <モジュール名>
#例: kinfra deploy host5

# リソースの破棄
kinfra destroy <モジュール名>
#例: kinfra destroy host5
```

## 開発規約

- **モジュラー構造**: プロジェクトはモジュールに整理されており、各モジュールがインフラの個別の部分を表します。共有設定やモジュールは`shared`ディレクトリに配置されます。
- **テンプレート**: テンプレートファイル (`.tpl`) を使用して設定ファイルやスクリプトを生成します。これにより、変数に基づいた動的な設定が可能になります。
- **リモート実行**: Terraformの`null_resource`と`remote-exec`プロビジョナを使用して、SSH経由でリモートホスト上でコマンドを実行します。これは既存のマシンを設定するための一般的なパターンです。
- **変数駆動の設定**: インフラストラクチャは`variables.tf`ファイルで定義された変数を使用して設定されます。これにより、異なる環境のカスタマイズが容易になります。
- serenaにメモする