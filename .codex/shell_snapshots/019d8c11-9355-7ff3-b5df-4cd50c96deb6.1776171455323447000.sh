# Snapshot file
# Unset all aliases to avoid conflicts with functions
unalias -a 2>/dev/null || true
# Functions
proxy-local () {
	ssh -N -D 1080 -p 2222 thy-local &
	sleep 2
	networksetup -setsocksfirewallproxy "Wi-Fi" 127.0.0.1 1080
	networksetup -setsocksfirewallproxystate "Wi-Fi" on
	export http_proxy="socks5h://127.0.0.1:1080" 
	export https_proxy="socks5h://127.0.0.1:1080" 
	export all_proxy="socks5h://127.0.0.1:1080" 
	export HTTP_PROXY="$http_proxy" 
	export HTTPS_PROXY="$https_proxy" 
	export ALL_PROXY="$all_proxy" 
	git config --global http.proxy "socks5h://127.0.0.1:1080"
	git config --global https.proxy "socks5h://127.0.0.1:1080"
	echo "SOCKS Proxy: ON for Terminal + Safari"
}
proxy-moti () {
	ssh -N -D 1080 -p 2222 thy-moti &
	sleep 2
	networksetup -setsocksfirewallproxy "Wi-Fi" 127.0.0.1 1080
	networksetup -setsocksfirewallproxystate "Wi-Fi" on
	export http_proxy="socks5h://127.0.0.1:1080" 
	export https_proxy="socks5h://127.0.0.1:1080" 
	export all_proxy="socks5h://127.0.0.1:1080" 
	export HTTP_PROXY="$http_proxy" 
	export HTTPS_PROXY="$https_proxy" 
	export ALL_PROXY="$all_proxy" 
	git config --global http.proxy "socks5h://127.0.0.1:1080"
	git config --global https.proxy "socks5h://127.0.0.1:1080"
	echo "SOCKS Proxy: ON for Terminal + Safari"
}
proxy-moti2 () {
	ssh -N -D 1080 -p 2222 thy-moti2 &
	sleep 2
	networksetup -setsocksfirewallproxy "Wi-Fi" 127.0.0.1 1080
	networksetup -setsocksfirewallproxystate "Wi-Fi" on
	export http_proxy="socks5h://127.0.0.1:1080" 
	export https_proxy="socks5h://127.0.0.1:1080" 
	export all_proxy="socks5h://127.0.0.1:1080" 
	export HTTP_PROXY="$http_proxy" 
	export HTTPS_PROXY="$https_proxy" 
	export ALL_PROXY="$all_proxy" 
	git config --global http.proxy "socks5h://127.0.0.1:1080"
	git config --global https.proxy "socks5h://127.0.0.1:1080"
	echo "SOCKS Proxy: ON for Terminal + Safari"
}
proxy-off () {
	networksetup -setsocksfirewallproxystate "Wi-Fi" off
	unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
	git config --global --unset http.proxy
	git config --global --unset https.proxy
	echo "SOCKS Proxy: OFF"
}
proxy-remote () {
	ssh -N -D 1080 -p 2222 thy-remote &
	sleep 2
	networksetup -setsocksfirewallproxy "Wi-Fi" 127.0.0.1 1080
	networksetup -setsocksfirewallproxystate "Wi-Fi" on
	export http_proxy="socks5h://127.0.0.1:1080" 
	export https_proxy="socks5h://127.0.0.1:1080" 
	export all_proxy="socks5h://127.0.0.1:1080" 
	export HTTP_PROXY="$http_proxy" 
	export HTTPS_PROXY="$https_proxy" 
	export ALL_PROXY="$all_proxy" 
	git config --global http.proxy "socks5h://127.0.0.1:1080"
	git config --global https.proxy "socks5h://127.0.0.1:1080"
	echo "SOCKS Proxy: ON for Terminal + Safari"
}
proxy-remote-ip () {
	ssh -N -D 1080 -p 2222 thy-remote-ip &
	sleep 2
	networksetup -setsocksfirewallproxy "Wi-Fi" 127.0.0.1 1080
	networksetup -setsocksfirewallproxystate "Wi-Fi" on
	export http_proxy="socks5h://127.0.0.1:1080" 
	export https_proxy="socks5h://127.0.0.1:1080" 
	export all_proxy="socks5h://127.0.0.1:1080" 
	export HTTP_PROXY="$http_proxy" 
	export HTTPS_PROXY="$https_proxy" 
	export ALL_PROXY="$all_proxy" 
	git config --global http.proxy "socks5h://127.0.0.1:1080"
	git config --global https.proxy "socks5h://127.0.0.1:1080"
	echo "SOCKS Proxy: ON for Terminal + Safari"
}
proxy-remote-ip-home () {
	ssh -N -D 1080 -p 2222 thy-remote-ip-home &
	sleep 2
	networksetup -setsocksfirewallproxy "Wi-Fi" 127.0.0.1 1080
	networksetup -setsocksfirewallproxystate "Wi-Fi" on
	export http_proxy="socks5h://127.0.0.1:1080" 
	export https_proxy="socks5h://127.0.0.1:1080" 
	export all_proxy="socks5h://127.0.0.1:1080" 
	export HTTP_PROXY="$http_proxy" 
	export HTTPS_PROXY="$https_proxy" 
	export ALL_PROXY="$all_proxy" 
	git config --global http.proxy "socks5h://127.0.0.1:1080"
	git config --global https.proxy "socks5h://127.0.0.1:1080"
	echo "SOCKS Proxy: ON for Terminal + Safari"
}
proxy-remote2 () {
	ssh -N -D 1080 -p 2222 thy-remote2 &
	sleep 2
	networksetup -setsocksfirewallproxy "Wi-Fi" 127.0.0.1 1080
	networksetup -setsocksfirewallproxystate "Wi-Fi" on
	export http_proxy="socks5h://127.0.0.1:1080" 
	export https_proxy="socks5h://127.0.0.1:1080" 
	export all_proxy="socks5h://127.0.0.1:1080" 
	export HTTP_PROXY="$http_proxy" 
	export HTTPS_PROXY="$https_proxy" 
	export ALL_PROXY="$all_proxy" 
	git config --global http.proxy "socks5h://127.0.0.1:1080"
	git config --global https.proxy "socks5h://127.0.0.1:1080"
	echo "SOCKS Proxy: ON for Terminal + Safari"
}
proxy-tailscale () {
	ssh -N -D 1080 -p 2222 thy-tailscale &
	sleep 2
	networksetup -setsocksfirewallproxy "Wi-Fi" 127.0.0.1 1080
	networksetup -setsocksfirewallproxystate "Wi-Fi" on
	export http_proxy="socks5h://127.0.0.1:1080" 
	export https_proxy="socks5h://127.0.0.1:1080" 
	export all_proxy="socks5h://127.0.0.1:1080" 
	export HTTP_PROXY="$http_proxy" 
	export HTTPS_PROXY="$https_proxy" 
	export ALL_PROXY="$all_proxy" 
	git config --global http.proxy "socks5h://127.0.0.1:1080"
	git config --global https.proxy "socks5h://127.0.0.1:1080"
	echo "SOCKS Proxy: ON for Terminal + Safari"
}

# setopts 2
setopt nohashdirs
setopt login

# aliases 7
alias codex='CODEX_HOME="$PWD/.codex" codex'
alias proxy-alt-on='ssh -N -D 1080 -p 2222 thy-tailscale &; sleep 2; networksetup -setsocksfirewallproxy "Wi-Fi" 127.0.0.1 1080; networksetup -setsocksfirewallproxystate "Wi-Fi" on; export http_proxy=socks5h://127.0.0.1:1080; export https_proxy=socks5h://127.0.0.1:1080; export all_proxy=socks5h://127.0.0.1:1080; echo "SOCKS Proxy: ON"'
alias proxy-on='ssh -N -D 1080 -p 2222 thy-local &; sleep 2; networksetup -setsocksfirewallproxy "Wi-Fi" 127.0.0.1 1080; networksetup -setsocksfirewallproxystate "Wi-Fi" on; export http_proxy=socks5h://127.0.0.1:1080; export https_proxy=socks5h://127.0.0.1:1080; export all_proxy=socks5h://127.0.0.1:1080; echo "SOCKS Proxy: ON"'
alias proxy-remote-ip-on='ssh -N -D 1080 -p 2222 thy-remote &; sleep 2; networksetup -setsocksfirewallproxy "Wi-Fi" 127.0.0.1 1080; networksetup -setsocksfirewallproxystate "Wi-Fi" on; export http_proxy=socks5h://127.0.0.1:1080; export https_proxy=socks5h://127.0.0.1:1080; export all_proxy=socks5h://127.0.0.1:1080; echo "SOCKS Proxy: ON"'
alias proxy-status='pgrep -f "ssh.*1080" && echo "SSH: ON" || echo "SSH: OFF"; networksetup -getsocksfirewallproxy "Wi-Fi"; echo "Terminal proxy: $http_proxy"'
alias run-help=man
alias which-command=whence

# exports 22
export CODEX_HOME=/Users/ulas.sancak/Desktop/Projects/Personal/Resting/.codex
export COLORTERM=truecolor
export FIREBASE_TOOLS=/Users/ulas.sancak/firebase
export HOME=/Users/ulas.sancak
export JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home'
export LANG=C.UTF-8
export LC_CTYPE=UTF-8
export LOGNAME=ulas.sancak
export OSLogRateLimit=64
export PHP_HOME=/Applications/MAMP/bin/php/php8.3.14
export SHELL=/bin/zsh
export SSH_AUTH_SOCK=/private/tmp/com.apple.launchd.7HSYLCrcYs/Listeners
export TERM=xterm-256color
export TERM_PROGRAM=Apple_Terminal
export TERM_PROGRAM_VERSION=466
export TERM_SESSION_ID=CDC2AC88-C418-416E-A7F0-7C74C93FEC5D
export TMPDIR=/var/folders/hj/wmzxz2kx2k1954xw4mt3vm2m0000gn/T/
export USER=ulas.sancak
export XPC_FLAGS=0x0
export XPC_SERVICE_NAME=0
export __CFBundleIdentifier=com.apple.Terminal
export __CF_USER_TEXT_ENCODING=0x1F5:0x0:0x0
