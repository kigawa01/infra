# Prometheus Node Exporter

このドキュメントは、このインフラストラクチャにおけるPrometheus Node Exporterの設定と使用方法について詳しく説明します。

## 概要

Node Exporterはシステムメトリクス（CPU、メモリ、ディスク、ネットワークなど）を収集し、Prometheusがスクレイピングできる形式で公開するエクスポーターです。

## 設定オプション

Node Exporterの設定は以下の変数で制御できます：

| 変数名 | デフォルト値 | 説明 |
|--------|-------------|------|
| `node_exporter_enabled` | `true` | Node Exporterを有効にするかどうか |
| `node_exporter_version` | `"1.6.1"` | インストールするNode Exporterのバージョン |
| `node_exporter_port` | `9100` | Node Exporterが使用するポート |

## 環境設定例

### 開発環境 (environments/dev/terraform.tfvars)

```hcl
# Node Exporter configuration
node_exporter_enabled = true
node_exporter_version = "1.6.1"
node_exporter_port = 9100
```

### 本番環境 (environments/prod/terraform.tfvars)

```hcl
# Node Exporter configuration
node_exporter_enabled = true
node_exporter_version = "1.6.1"
node_exporter_port = 9100
```

## インストールプロセス

1. **スクリプト生成**: Terraformがテンプレートからインストールスクリプトを生成
2. **SSH接続**: 指定されたターゲットホストにSSH接続
3. **ファイル転送**: インストールスクリプトをリモートホストに転送
4. **インストール実行**: sudo権限でNode Exporterをインストール

## sudo権限の要件

Node Exporterのインストールはroot権限を必要とするため、以下のいずれかの方法でsudo権限を設定する必要があります：

### 1. sudo_password変数を使用（推奨）

```hcl
# terraform.tfvarsファイルに追加
sudo_password = "your_sudo_password"
```

または、コマンドラインで指定：

```bash
terraform apply -var="sudo_password=your_sudo_password" -var-file=environments/dev/terraform.tfvars
```

### 2. パスワードなしsudoの設定

ターゲットホスト上で実行：

```bash
# 特定ユーザーのパスワードなしsudo設定
echo "kigawa ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/kigawa
sudo chmod 440 /etc/sudoers.d/kigawa
```

**セキュリティ注意**: 本番環境では特定のコマンドのみにNOPASSWDを制限することを推奨します。

### 3. rootユーザーでのSSH接続

```hcl
ssh_user = "root"
```

## メトリクスアクセス

Node Exporterが正常にインストールされると、以下のURLでメトリクスにアクセスできます：

```
http://<target_host>:9100/metrics
```

## トラブルシューティング

### よくある問題

1. **SSH接続エラー**
   - SSH鍵のパスが正しいか確認
   - ターゲットホストにSSH接続できるか確認

2. **sudo権限エラー**
   - sudo_password変数が設定されているか確認
   - パスワードなしsudoが設定されているか確認

3. **ポート競合**
   - 既に9100ポートが使用されていないか確認
   - 必要に応じて`node_exporter_port`変数を変更

### ログの確認

Node Exporterのログを確認：

```bash
# systemdログの確認
sudo journalctl -u node_exporter -f

# Node Exporterの状態確認
sudo systemctl status node_exporter
```

## セキュリティ考慮事項

1. **SSH鍵の管理**
   - SSH秘密鍵はgitリポジトリに含めない
   - 適切なファイル権限を設定（600）

2. **sudo権限の制限**
   - 本番環境では必要最小限の権限のみ付与
   - sudo_passwordをバージョン管理に含めない

3. **ネットワークアクセス**
   - 必要に応じてファイアウォール設定を調整
   - メトリクスエンドポイントへのアクセス制御