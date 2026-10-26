#!/bin/bash
#
# apply-with-sudo.sh — terraform apply をsudoパスワード入力付きで実行するスクリプト
#
# 使い方:
#   cd host-local
#   ./apply-with-sudo.sh
#
# このスクリプトは以下を行います:
# 1. ユーザーにsudoパスワードを求め、一時的にパスワードレスsudoを設定
# 2. terraform init (必要なら)
# 3. terraform apply を実行
# 4. パスワードレスsudo設定を削除
#

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SUDOERS_FILE="/etc/sudoers.d/terraform-local"
USERNAME="$(whoami)"

cleanup() {
    echo ""
    echo "=== クリーンアップ: パスワードレスsudo設定を削除します ==="
    if [ -f "$SUDOERS_FILE" ]; then
        echo "$PASSWORD" | sudo -S rm -f "$SUDOERS_FILE" 2>/dev/null || true
        echo "削除完了: $SUDOERS_FILE"
    fi
}

# 終了時にクリーンアップ
trap cleanup EXIT

echo "=================================================="
echo " host-local terraform apply (sudoパスワード付き)"
echo "=================================================="
echo ""

# パスワードを入力
echo "sudoパスワードを入力してください:"
read -s PASSWORD
echo ""

# パスワードが正しいか確認
if ! echo "$PASSWORD" | sudo -S -p "" true 2>/dev/null; then
    echo "エラー: パスワードが正しくありません"
    exit 1
fi

echo "パスワード認証成功"
echo ""

# 一時的にパスワードレスsudoを設定
echo "=== パスワードレスsudoを一時的に設定します ==="
echo "$PASSWORD" | sudo -S sh -c "echo '$USERNAME ALL=(ALL) NOPASSWD:ALL' > $SUDOERS_FILE && chmod 440 $SUDOERS_FILE"
echo "設定完了: $SUDOERS_FILE"
echo ""
# sudoersファイルが正しいか確認
if ! sudo -n true 2>/dev/null; then
    echo "エラー: パスワードレスsudo設定に失敗しました"
    exit 1
fi
echo "パスワードレスsudo確認成功"
echo ""

# flatpakのflathub競合を回避するために、既存のflathub-userを削除
echo "=== flatpak flathub-user リモートを削除（競合回避）==="
flatpak remote-delete flathub-user 2>/dev/null || true
echo ""

# terraform init
echo "=== terraform init ==="
cd "$SCRIPT_DIR"
terraform init -backend=false
echo ""

# terraform apply
echo "=== terraform apply ==="
echo "変更を確認してください。'yes'を入力して続行:"
terraform apply -input=false

echo ""
echo "=================================================="
echo " 適用完了"
echo "=================================================="
