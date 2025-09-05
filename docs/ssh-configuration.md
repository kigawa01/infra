# SSH接続設定

このドキュメントは、インフラストラクチャでのSSH接続設定と管理について詳しく説明します。

## 概要

このインフラストラクチャでは、以下の目的でSSH接続を使用します：
- Node Exporterのリモートインストール
- Kubernetesマニフェストのリモート適用
- リモートホストでのコマンド実行

## SSH設定変数

### 基本設定

| 変数名 | デフォルト値 | 説明 |
|--------|-------------|------|
| `target_host` | `"k8s4"` | 接続先のホスト名またはIPアドレス |
| `ssh_user` | `"kigawa"` | SSH接続用のユーザー名 |
| `ssh_key_path` | `""` | SSH秘密鍵ファイルへのパス |
| `ssh_password` | `""` | SSHパスワード（鍵認証が使用できない場合） |
| `sudo_password` | `""` | sudo実行時のパスワード |

### セキュリティ設定

- すべてのSSH接続で`StrictHostKeyChecking=no`を使用
- SSH鍵認証を優先、パスワード認証はフォールバック
- SSH接続タイムアウト: 30秒（テスト用）、5分（実行用）

## SSH鍵の管理

### 推奨ディレクトリ構造

```
~/.ssh/
├── main/                    # 本番環境用鍵
│   ├── id_rsa
│   └── id_rsa.pub
├── key/                     # 共通鍵・ステージング環境用
│   ├── id_ed25519          # k8s4など
│   ├── id_ed25519.pub
│   ├── id_rsa
│   └── id_rsa.pub
└── dev-key/                 # 開発環境用鍵
    ├── infra_dev_key
    └── infra_dev_key.pub
```

### 鍵のファイル権限

```bash
# 秘密鍵の権限設定
chmod 600 ~/.ssh/key/id_ed25519
chmod 600 ~/.ssh/main/id_rsa

# 公開鍵の権限設定
chmod 644 ~/.ssh/key/id_ed25519.pub
chmod 644 ~/.ssh/main/id_rsa.pub

# .sshディレクトリの権限設定
chmod 700 ~/.ssh
```

## 環境別設定例

### 開発環境 (environments/dev/terraform.tfvars)

```hcl
# SSH connection configuration
target_host = "192.168.1.120"  # k8s4
ssh_user = "kigawa"
ssh_key_path = "~/.ssh/dev-key/infra_dev_key"
ssh_password = ""  # 鍵認証を使用
sudo_password = ""  # パスワードなしsudoまたは別途指定
```

### ステージング環境 (environments/staging/terraform.tfvars)

```hcl
# SSH connection configuration
target_host = "192.168.1.120"  # k8s4
ssh_user = "kigawa"
ssh_key_path = "~/.ssh/key/id_ed25519"
ssh_password = ""
sudo_password = ""
```

### 本番環境 (environments/prod/terraform.tfvars)

```hcl
# SSH connection configuration
target_host = "192.168.1.120"  # k8s4
ssh_user = "kigawa"
ssh_key_path = "~/.ssh/main/id_rsa"
ssh_password = ""
sudo_password = ""
```

## SSH Config ファイルの活用

プロジェクトには`ssh_config`ファイルが含まれており、ホスト別の設定が定義されています：

```
host k8s4
    hostname 192.168.1.120
    user kigawa
    port 22
    identityfile ~/.ssh/key/id_ed25519
```

### SSH Configの使用

```bash
# SSH Configファイルを使用した接続テスト
ssh -F /var/user/dev/kigawa/infra/ssh_config k8s4

# Terraformでの自動ホスト解決
# main.tfでk8s4 -> 192.168.1.120に自動変換される
```

## sudo権限の設定

### 1. sudo_password変数を使用（推奨）

**コマンドライン指定**:
```bash
./terraform.sh apply dev -var="sudo_password=your_password"
```

**tfvarsファイル**:
```hcl
# 注意: バージョン管理に含めないこと
sudo_password = "your_sudo_password"
```

### 2. パスワードなしsudoの設定

**ターゲットホストで実行**:
```bash
# 特定ユーザーのパスワードなしsudo設定
echo "kigawa ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/kigawa
sudo chmod 440 /etc/sudoers.d/kigawa

# 設定の確認
sudo -l -U kigawa
```

**セキュリティ強化版（特定コマンドのみ）**:
```bash
# Node Exporterインストールに必要なコマンドのみ許可
echo "kigawa ALL=(ALL) NOPASSWD: /usr/bin/systemctl, /usr/bin/useradd, /usr/bin/chown, /usr/bin/chmod" | sudo tee /etc/sudoers.d/kigawa-limited
```

### 3. rootユーザーでのSSH接続

```hcl
# root直接接続（最も権限が強い）
ssh_user = "root"
sudo_password = ""  # 不要
```

## 接続テストとトラブルシューティング

### 基本的な接続テスト

```bash
# SSH鍵を使用した接続テスト
ssh -i ~/.ssh/key/id_ed25519 -o ConnectTimeout=10 -o StrictHostKeyChecking=no kigawa@192.168.1.120 "echo 'Connection OK'"

# sudo権限テスト
ssh -i ~/.ssh/key/id_ed25519 kigawa@192.168.1.120 "sudo -n echo 'Sudo OK' || echo 'Sudo requires password'"
```

### よくある問題と解決方法

#### 1. SSH接続エラー

**症状**: `dial tcp: lookup k8s4 on 127.0.0.53:53: server misbehaving`

**解決方法**:
```bash
# ホスト名解決の確認
nslookup k8s4
ping 192.168.1.120

# /etc/hostsファイルに追加（一時的）
echo "192.168.1.120 k8s4" | sudo tee -a /etc/hosts
```

#### 2. SSH鍵認証エラー

**症状**: `Permission denied (publickey).`

**解決方法**:
```bash
# 鍵のファイル権限確認
ls -la ~/.ssh/key/id_ed25519

# 権限修正
chmod 600 ~/.ssh/key/id_ed25519

# 公開鍵がリモートホストに登録されているか確認
ssh-copy-id -i ~/.ssh/key/id_ed25519.pub kigawa@192.168.1.120
```

#### 3. sudo権限エラー

**症状**: `sudo: a password is required`

**解決方法**:
```bash
# sudo設定確認
ssh kigawa@192.168.1.120 "sudo -l"

# パスワードなしsudo設定
ssh kigawa@192.168.1.120 'echo "kigawa ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/kigawa'
```

### デバッグ用コマンド

```bash
# SSH詳細ログ
ssh -vvv -i ~/.ssh/key/id_ed25519 kigawa@192.168.1.120

# Terraform SSH デバッグ
export TF_LOG=DEBUG
terraform plan -var-file=environments/dev/terraform.tfvars

# 生成されたスクリプトの確認
cat generated/deploy_to_remote.sh
cat generated/kubectl_apply.sh
```

## セキュリティベストプラクティス

### 1. SSH鍵の管理

- **鍵の定期ローテーション**: 6ヶ月〜1年ごと
- **強力な鍵の使用**: ED25519（推奨）または RSA 4096bit以上
- **パスフレーズの設定**: 鍵ファイルにパスフレーズを設定

```bash
# ED25519鍵の生成（推奨）
ssh-keygen -t ed25519 -f ~/.ssh/key/infra_key -C "infra-management"

# RSA鍵の生成（レガシー対応）
ssh-keygen -t rsa -b 4096 -f ~/.ssh/main/infra_prod_key -C "infra-prod"
```

### 2. アクセス制御

- **IP制限**: 必要に応じてファイアウォール設定
- **ポート変更**: デフォルトポート22から変更を検討
- **fail2ban**: SSH攻撃対策の導入

### 3. 監査とログ

```bash
# SSH接続ログの確認
sudo journalctl -u ssh -f

# 最近のSSH接続一覧
last | grep ssh
```

### 4. バックアップと復旧

```bash
# SSH設定のバックアップ
tar -czf ssh-backup-$(date +%Y%m%d).tar.gz ~/.ssh/

# 重要な鍵の安全な保管場所への複製
cp ~/.ssh/key/id_ed25519 /secure/backup/location/
```