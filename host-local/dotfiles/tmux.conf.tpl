# tmux と OS のクリップボードを同期
set -g set-clipboard on
set -as terminal-features ',*:clipboard'
set -ga update-environment ' WAYLAND_DISPLAY XDG_RUNTIME_DIR'

# vi copy-mode
#bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "sh /home/kigawa/.local/bin/tmux-clipboard copy"
bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "sh /home/kigawa/.local/bin/tmux-clipboard copy"
bind-key -T copy-mode-vi v send-keys -X begin-selection
bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle

# emacs copy-mode
bind-key -T copy-mode-emacs M-w send-keys -X copy-pipe-and-cancel "sh /home/kigawa/.local/bin/tmux-clipboard copy"
bind-key -T copy-mode-emacs C-w send-keys -X copy-pipe-and-cancel "sh /home/kigawa/.local/bin/tmux-clipboard copy"

# OS clipboard -> pane
bind-key C-y run-shell -b 'sh /home/kigawa/.local/bin/tmux-clipboard paste | tmux load-buffer - && tmux paste-buffer'

# status
set-hook -g after-new-session 'run-shell "tmux set -t \"#{session_name}\" @initial_dir \"#{pane_current_path}\""'
set -g status on
set -g status-right '[#{@initial_dir}] %H:%M'
setw -g mode-keys vi

# --- 2026-10-17: マウスドラッグ選択でGUIクリップボードへ自動コピー ---
# マウス有効化（任意: 不要なら mouse off に戻す）
set -g mouse on

# Wayland/xclip を経由してコピー（tmux-clipboard は wl-copy 優先のフォールバック付き）
bind-key -T copy-mode    MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "sh /home/kigawa/.local/bin/tmux-clipboard copy"
bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "sh /home/kigawa/.local/bin/tmux-clipboard copy"

# viモード: y でもコピー（Enter は既存）
bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "sh /home/kigawa/.local/bin/tmux-clipboard copy"
