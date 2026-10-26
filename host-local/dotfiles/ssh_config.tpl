
Host nginx
	hostname 192.168.1.103
	user kigawa
	port 22
	identityfile ~/.ssh/main/id_rsa

Host k8s-worker1
	hostname 192.168.3.105
	user kigawa
	port 22
	identityfile ~/.ssh/key/id_ed25519

Host k8s-worker3
	hostname 192.168.1.130
	user kigawa
	port 22
	identityfile ~/.ssh/key/id_ed25519

Host k8s-worker2
	hostname 192.168.1.109
	user kigawa
	port 22
	identityfile ~/.ssh/main/id_rsa

Host ionos
	hostname 74.208.55.86
	user root
	port 22
	identityfile ~/.ssh/key/id_ed25519

Host knot-resolver2
	hostname 192.168.1.105
	user kigawa
	port 22
	identityfile ~/.ssh/main/id_rsa

Host knot-resolver1
	hostname 192.168.3.16
	user root
	port 22
	identityfile ~/.ssh/key/id_ed25519

Host host3
	hostname 192.168.1.30
	user root
	port 22
	identityfile ~/.ssh/main/id_rsa

Host knot
	hostname 192.168.1.102
	user kigawa
	port 22
	identityfile ~/.ssh/main/id_rsa

Host nfs
	hostname 192.168.1.114
	user kigawa
	port 22
	identityfile ~/.ssh/main/id_rsa

Host host4
	hostname 192.168.1.40
	user root
	port 22
	identityfile ~/.ssh/main/id_rsa

Host lxc-nginx
	hostname 192.168.3.100
	user root
	port 22
	identityfile ~/.ssh/key/id_ed25519

Host pixelsia-sin
	hostname 162.43.70.232
	user pixelsia
	port 54522
	identityfile ~/.ssh/key/id_ed25519

Host k8s-worker4
	hostname 192.168.1.121
	user kigawa
	port 22
	identityfile ~/.ssh/main/id_rsa

Host github.com
	hostname github.com
	user git
	port 22
	identityfile ~/.ssh/key/id_ed25519

Host dev
	hostname 192.168.1.50
	user kigawa
	port 7521
	identityfile ~/.ssh/key/id_ed25519
#	ForwardX11  yes

Host develop
	hostname 192.168.1.239
	user kigawa
	port 22
	identityfile ~/.ssh/key/id_ed25519

Host knot-resolver3
	hostname 192.168.1.113
	user root
	port 22
	identityfile ~/.ssh/key/id_ed25519

Host postgres1
	hostname 192.168.3.11
	user root
	port 22
	identityfile ~/.ssh/key/id_ed25519


Host develop-k8s
	hostname develop-k8s
	user kigawa
	port 22
	identityfile ~/.ssh/key/id_ed25519

Host k8s4
	hostname 192.168.1.120
	user kigawa
	port 22
	identityfile ~/.ssh/key/id_ed25519

Host k8s3
	hostname 192.168.1.107
	user kigawa
	port 22
	identityfile ~/.ssh/main/id_rsa

Host k8s2
	hostname 192.168.1.20
	user kigawa
	port 22
	identityfile ~/.ssh/key/id_ed25519

Host mc2
	hostname 192.168.0.102
	user kigawa
	port 22
	identityfile ~/.ssh/main/id_rsa

Host k8s1
	hostname 192.168.1.103
	user kigawa
	port 22
	identityfile ~/.ssh/key/id_ed25519

Host mysql
	hostname 192.168.0.114
	user kigawa
	port 22
	identityfile ~/.ssh/main/id_rsa

Host kigawa-net
	hostname 192.168.0.111
	user kigawa
	port 22
	identityfile ~/.ssh/main/id_rsa

Host one
	hostname 192.168.1.100
	user kigawa
	port 22
	identityfile ~/.ssh/main/id_rsa

Host one-mysql-old
	hostname 192.168.0.29
	user root
	port 22
	identityfile ~/.ssh/main/id_rsa
Host nfs
	hostname 192.168.0.115
	user kigawa
	port 22
	identityfile ~/.ssh/main/id_rsa
Host apache
	hostname 192.168.0.27
	user root
	port 22
	identityfile ~/.ssh/main/id_rsa
Host haproxy
	hostname 192.168.1.104
	user kigawa
	port 22
	identityfile ~/.ssh/main/id_rsa
Host mysql-old
	hostname 192.168.0.23
	user root
	port 22
	identityfile ~/.ssh/main/id_rsa
Host lunail
	hostname 192.168.0.107
	user root
	port 22
	identityfile ~/.ssh/main/id_rsa
Host build
	hostname 192.168.0.106
	user root
	port 22
	identityfile ~/.ssh/main/id_rsa
Host one-build
	hostname 192.168.0.108
	user root
	port 22
	identityfile ~/.ssh/main/id_rsa
Host bungee
	hostname 192.168.0.100
	user root
	port 22
	identityfile ~/.ssh/main/id_rsa
Host lobby
	hostname 192.168.0.21
	user root
	port 22
	identityfile ~/.ssh/main/id_rsa
Host normal
	hostname 192.168.0.20
	user kigawa
	port 22
	identityfile ~/.ssh/main/normal
Host host2
	hostname 192.168.1.20
	user root
	port 22
	identityfile ~/.ssh/main/id_rsa
Host db
	hostname 192.168.0.18
	user kigawa
	port 22
	identityfile ~/.ssh/main/db
Host db1
	hostname 192.168.0.23
	user root
	port 22
	identityfile ~/.ssh/main/id_rsa
Host mc
	hostname 192.168.0.17
	user kigawa
	port 22
	identityfile ~/.ssh/main/kvm_minecraft
Host linode_web
	hostname 139.162.89.197
	user kigawa
	port 22
	identityfile ~/.ssh/main/tatami
Host host1
    HostName 192.168.1.10
    User root
    Port 22
    IdentityFile ~/.ssh/main/id_rsa
host	kvm_tatami
	hostname 192.168.0.14
	user kigawa
	identityfile C:\Users/kigaw/.ssh/main/kvm_tatami
host	kvm_important
	hostname 192.168.0.15
	user kigawa
	identityfile C:\Users/kigaw/.ssh/main/kvm_important
Host agames
    HostName 219.117.219.18
    User kigawa
    Port 12600
	IdentityFile ~/.ssh/main/tatami
Host kagoya
	HostName 133.18.172.230
	User kigawa
	IdentityFile ~/.ssh/main/tatami_kagoya_01
Host k8s-worker5
	HostName 192.168.1.150
	User kigawa
	IdentityFile ~/.ssh/key/id_ed25519
Host kigawa_gcp
	HostName 35.188.79.161
	User kigawa
	IdentityFile ~/.ssh/main/kigawa_gcp
Host hal-sennka
	HostName 192.168.1.101
	User kigawa
	IdentityFile C:\Users/kigaw/.ssh/key/id_rsa

Host cross
	hostname croover.sakura.ne.jp
	user croover
	port 22
	Identityfile ~/.ssh/main/id_rsa

# --- START CODER JETBRAINS coder.kigawa.net
Host coder-jetbrains-coder.kigawa.net--*
  ProxyCommand /home/kigawa/.local/share/coder-gateway/coder.kigawa.net/coder-linux-amd64 --global-config /home/kigawa/.local/share/coder-gateway/coder.kigawa.net/config --url https://coder.kigawa.net ssh --stdio --usage-app=jetbrains --ssh-host-prefix coder-jetbrains-coder.kigawa.net-- %h
  ConnectTimeout 0
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  LogLevel ERROR
  SetEnv CODER_SSH_SESSION_TYPE=JetBrains

Host coder-jetbrains-coder.kigawa.net-bg--*
  ProxyCommand /home/kigawa/.local/share/coder-gateway/coder.kigawa.net/coder-linux-amd64 --global-config /home/kigawa/.local/share/coder-gateway/coder.kigawa.net/config --url https://coder.kigawa.net ssh --stdio --usage-app=disable --ssh-host-prefix coder-jetbrains-coder.kigawa.net-bg-- %h
  ConnectTimeout 0
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  LogLevel ERROR
  SetEnv CODER_SSH_SESSION_TYPE=JetBrains
# --- END CODER JETBRAINS coder.kigawa.net

# --- START CODER JETBRAINS TOOLBOX coder.kigawa.net
Host coder-jetbrains-toolbox-coder.kigawa.net--*
  ProxyCommand /home/kigawa/.local/share/coder-toolbox/coder.kigawa.net/coder-linux-amd64 --global-config /home/kigawa/.local/share/coder-toolbox/coder.kigawa.net/config --url https://coder.kigawa.net ssh --stdio --network-info-dir /home/kigawa/.local/share/coder-toolbox/ssh-network-metrics --usage-app=jetbrains --ssh-host-prefix coder-jetbrains-toolbox-coder.kigawa.net-- %h
  ConnectTimeout 0
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  LogLevel ERROR
  SetEnv CODER_SSH_SESSION_TYPE=JetBrains

# --- END CODER JETBRAINS TOOLBOX coder.kigawa.net
Host pixelsia1
	HostName pixelsia-1.tail0dcb61.ts.net
	Port 22
	User kigawa
  IdentityFile ~/.ssh/key/id_ed25519


