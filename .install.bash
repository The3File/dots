#!/usr/bin/env bash
# Early machine bootstrap: Arch (post-wiki) / Termux / other.
# Interview first — no side effects until confirmed.
#
# Arch order: pacman foundation (incl. git) → bare clone → extract bootstrap
# → packages → services/groups/etc → config checkout → AIOS(+nested) → Claude
# → drop sync repo last if unwanted.
set -euo pipefail

DOTS_GIT_SSH="git@github.com:The3File/dots.git"
DOTS_GIT_HTTPS="https://github.com/The3File/dots.git"
AIOS_GIT_SSH="git@github.com:The3File/AIOS.git"
AIOS_GIT_HTTPS="https://github.com/The3File/AIOS.git"

DOTFILES="${HOME}/.dotfiles"
BACKUP="${HOME}/.dotfiles-backup"
AIOS_DIR="${HOME}/AIOS"

# Nested AIOS repos (gitignored in umbrella)
AIOS_NESTED=(
	"Noter|The3File/Noter"
	"IndreArbejde_bog|The3File/IndreArbejde_bog"
	"filipringdal.dk|The3File/filipringdal.dk"
)

# --- helpers ---------------------------------------------------------------

die() { printf 'error: %s\n' "$*" >&2; exit 1; }
info() { printf '→ %s\n' "$*"; }

ask() {
	local prompt=$1 default=$2
	read -r -p "${prompt} [${default}]: " REPLY || die "interrupted"
	REPLY=${REPLY:-$default}
}

ask_yn() {
	local prompt=$1 default=$2
	while true; do
		ask "$prompt" "$default"
		case ${REPLY,,} in
		y | yes) REPLY=y; return ;;
		n | no) REPLY=n; return ;;
		esac
		printf '%s\n' "please answer y or n"
	done
}

detect_platform() {
	if [[ $(uname -o 2>/dev/null || true) == Android ]]; then
		printf '%s\n' termux
		return
	fi
	if [[ -f /etc/os-release ]] && grep -qi '^ID=arch' /etc/os-release; then
		printf '%s\n' arch
		return
	fi
	printf '%s\n' other
}

sudo_pacman() {
	if [[ $(id -u) -eq 0 ]]; then
		pacman "$@"
	else
		sudo pacman "$@"
	fi
}

git_url() {
	# git_url owner/repo → full URL from CLONE_METHOD
	local slug=$1
	if [[ ${CLONE_METHOD:-https} == ssh ]]; then
		printf 'git@github.com:%s.git\n' "$slug"
	else
		printf 'https://github.com/%s.git\n' "$slug"
	fi
}

# --- interview -------------------------------------------------------------

interview() {
	local detected
	detected=$(detect_platform)

	printf '%s\n\n' "dots bootstrap — nothing runs until you confirm."
	printf '%s\n\n' "Arch: run after wiki install (user + sudo + network). git is installed by this script."

	while true; do
		ask "Platform (arch/termux/other)" "$detected"
		case ${REPLY,,} in
		arch | termux | other) PLATFORM=${REPLY,,}; break ;;
		esac
		printf '%s\n' "please answer arch, termux, or other"
	done

	ask_yn "Install config files from dots into \$HOME?" y
	WANT_CONFIGS=$REPLY

	WANT_SYNC=n
	CLONE_METHOD=https
	if [[ $WANT_CONFIGS == y ]]; then
		local sync_default=y
		[[ $PLATFORM == arch ]] || sync_default=n
		ask_yn "Keep dots sync repo (~/.dotfiles + dot pull/up)?" "$sync_default"
		WANT_SYNC=$REPLY

		local method_default=https
		[[ $PLATFORM == arch && $WANT_SYNC == y ]] && method_default=ssh
		while true; do
			ask "Clone method (ssh/https)" "$method_default"
			case ${REPLY,,} in
			s | ssh) CLONE_METHOD=ssh; break ;;
			u | https | url) CLONE_METHOD=https; break ;;
			esac
			printf '%s\n' "please answer ssh or https"
		done
	fi

	WANT_FOUNDATION=n
	WANT_DESKTOP=n
	WANT_THINKPAD=n
	WANT_SERVICES=n
	WANT_ETC=n
	if [[ $PLATFORM == arch ]]; then
		ask_yn "Pacman foundation (multilib, parallel downloads, install git)?" y
		WANT_FOUNDATION=$REPLY

		local desk_default=n
		[[ $WANT_CONFIGS == y ]] && desk_default=y
		ask_yn "Install Arch desktop packages (Hyprland stack)?" "$desk_default"
		WANT_DESKTOP=$REPLY

		if [[ $WANT_DESKTOP == y ]]; then
			ask_yn "Install ThinkPad extras (tlp, thinkfan)?" n
			WANT_THINKPAD=$REPLY
			ask_yn "Enable system services (NetworkManager, bluetooth, seatd, …)?" y
			WANT_SERVICES=$REPLY
			local etc_default=n
			[[ $WANT_THINKPAD == y ]] && etc_default=y
			ask_yn "Apply /etc templates from bootstrap (TLP/thinkfan/lid)?" "$etc_default"
			WANT_ETC=$REPLY
		fi
	fi

	local aios_default=n
	[[ $PLATFORM == arch ]] && aios_default=y
	ask_yn "Clone AIOS + nested repos (Noter, book, website) → ~/AIOS?" "$aios_default"
	WANT_AIOS=$REPLY

	ask_yn "Install Claude Code (npm user-local)?" y
	WANT_CLAUDE=$REPLY

	printf '\n%s\n' "── plan ──"
	printf '  platform:    %s\n' "$PLATFORM"
	printf '  configs:     %s\n' "$WANT_CONFIGS"
	printf '  sync repo:   %s\n' "$WANT_SYNC"
	printf '  clone:       %s\n' "$CLONE_METHOD"
	printf '  foundation:  %s\n' "$WANT_FOUNDATION"
	printf '  desktop:     %s\n' "$WANT_DESKTOP"
	printf '  thinkpad:    %s\n' "$WANT_THINKPAD"
	printf '  services:    %s\n' "$WANT_SERVICES"
	printf '  /etc tmpls:  %s\n' "$WANT_ETC"
	printf '  AIOS+nested: %s\n' "$WANT_AIOS"
	printf '  Claude:      %s\n' "$WANT_CLAUDE"
	printf '%s\n\n' "──────────"
	ask_yn "Proceed with this plan?" y
	[[ $REPLY == y ]] || die "aborted"
}

# --- preconditions ---------------------------------------------------------

preflight() {
	if [[ $(id -u) -eq 0 ]]; then
		die "run as your normal user (not root) — AUR/makepkg needs a non-root account"
	fi
	[[ -w $HOME ]] || die "\$HOME is not writable"

	if [[ $PLATFORM == arch ]]; then
		command -v pacman >/dev/null 2>&1 || die "pacman not found"
		command -v curl >/dev/null 2>&1 || die "curl not found (needed for entry / checks)"
		sudo -v || die "sudo failed — add your user to wheel and configure sudoers"
	else
		# configs / AIOS need git; foundation does not install it here
		if [[ $WANT_CONFIGS == y || $WANT_AIOS == y ]]; then
			command -v git >/dev/null 2>&1 || die "git not found — install it first (e.g. pkg install git)"
		fi
	fi
}

# --- pacman foundation -----------------------------------------------------

enable_multilib() {
	local conf=/etc/pacman.conf
	grep -qE '^\[multilib\]' "$conf" && return 0
	info "enabling [multilib] in pacman.conf"
	sudo cp -a "$conf" "${conf}.bak.$(date +%Y%m%d%H%M%S)"
	sudo awk '
		/^#\[multilib\]/ { print "[multilib]"; getline; if ($0 ~ /^#Include/) sub(/^#/, ""); print; next }
		{ print }
	' "$conf" | sudo tee "$conf.tmp" >/dev/null
	sudo mv "$conf.tmp" "$conf"
}

set_pacman_options() {
	local conf=/etc/pacman.conf
	local need=0
	grep -qE '^ParallelDownloads' "$conf" || need=1
	grep -qE '^Color' "$conf" || need=1
	grep -qE '^DownloadUser' "$conf" || need=1
	((need)) || return 0
	info "setting ParallelDownloads / Color / DownloadUser"
	sudo cp -a "$conf" "${conf}.bak.$(date +%Y%m%d%H%M%S)"
	local tmp
	tmp=$(mktemp)
	cp "$conf" "$tmp"
	grep -qE '^Color' "$tmp" || sed -i 's/^#Color$/Color/' "$tmp"
	grep -qE '^Color' "$tmp" || sed -i '/^\[options\]/a Color' "$tmp"
	if grep -qE '^#?ParallelDownloads' "$tmp"; then
		sed -i 's/^#\?ParallelDownloads.*/ParallelDownloads = 5/' "$tmp"
	else
		sed -i '/^\[options\]/a ParallelDownloads = 5' "$tmp"
	fi
	if grep -qE '^#?DownloadUser' "$tmp"; then
		sed -i 's/^#\?DownloadUser.*/DownloadUser = alpm/' "$tmp"
	else
		sed -i '/^ParallelDownloads/a DownloadUser = alpm' "$tmp"
	fi
	sudo cp "$tmp" "$conf"
	rm -f "$tmp"
}

pacman_foundation() {
	[[ $PLATFORM == arch ]] || return 0
	[[ $WANT_FOUNDATION == y ]] || {
		# Still need git before any clone if configs/aios/desktop requested
		if [[ $WANT_CONFIGS == y || $WANT_AIOS == y || $WANT_DESKTOP == y ]]; then
			if ! command -v git >/dev/null 2>&1; then
				info "git missing — installing git (required for clones)"
				sudo_pacman -S --needed --noconfirm git
			fi
		fi
		return 0
	}

	enable_multilib
	set_pacman_options
	info "pacman -Sy"
	sudo_pacman -Sy
	info "installing foundation packages (git, base-devel, curl, wget)"
	sudo_pacman -S --needed --noconfirm base-devel git curl wget
}

# --- dots bare + extract ---------------------------------------------------

dots_git() {
	git --git-dir="$DOTFILES" --work-tree="$HOME" "$@"
}

extract_bootstrap() {
	[[ -d $DOTFILES ]] || die "extract_bootstrap: $DOTFILES missing"
	info "extracting bootstrap kit into $DOTFILES"
	mkdir -p "$DOTFILES/pkgs" "$DOTFILES/etc"
	local path
	for path in \
		bootstrap/install-pkgs \
		bootstrap/pkgs/official.txt \
		bootstrap/pkgs/aur.txt \
		bootstrap/pkgs/thinkpad.txt; do
		local dest
		case $path in
		bootstrap/install-pkgs) dest="$DOTFILES/install-pkgs" ;;
		bootstrap/pkgs/*) dest="$DOTFILES/pkgs/${path##*/}" ;;
		esac
		git --git-dir="$DOTFILES" show "HEAD:$path" >"$dest"
	done
	chmod +x "$DOTFILES/install-pkgs"

	# etc templates (best-effort; tree may grow)
	local etc_list
	etc_list=$(git --git-dir="$DOTFILES" ls-tree -r --name-only HEAD bootstrap/etc 2>/dev/null || true)
	if [[ -n $etc_list ]]; then
		while IFS= read -r path; do
			[[ -z $path ]] && continue
			local rel=${path#bootstrap/etc/}
			mkdir -p "$DOTFILES/etc/$(dirname "$rel")"
			git --git-dir="$DOTFILES" show "HEAD:$path" >"$DOTFILES/etc/$rel"
		done <<<"$etc_list"
	fi
}

backup_conflicts() {
	info "conflicting files — backing up to ${BACKUP}/"
	mkdir -p "$BACKUP"
	local line path parent
	while IFS= read -r line; do
		[[ $line =~ ^[[:space:]]+(.+)$ ]] || continue
		path=${BASH_REMATCH[1]}
		[[ -e $HOME/$path || -L $HOME/$path ]] || continue
		parent=$(dirname "$path")
		mkdir -p "$BACKUP/$parent"
		mv "$HOME/$path" "$BACKUP/$path"
		info "moved ~/$path → $BACKUP/$path"
	done
}

bare_clone_dots() {
	# Needed when configs OR we need bootstrap kit for desktop pkgs
	if [[ $WANT_CONFIGS != y && $WANT_DESKTOP != y ]]; then
		return 0
	fi

	command -v git >/dev/null 2>&1 || die "git not installed — enable foundation or install git"

	if [[ -e $DOTFILES ]] && [[ -n $(ls -A "$DOTFILES" 2>/dev/null || true) ]]; then
		if [[ -f $DOTFILES/HEAD ]]; then
			info "$DOTFILES already present — reusing"
			extract_bootstrap
			return 0
		fi
		die "$DOTFILES exists and is not a bare repo — remove/rename it first"
	fi

	local url=$DOTS_GIT_HTTPS
	[[ $CLONE_METHOD == ssh ]] && url=$DOTS_GIT_SSH
	info "cloning dots (bare) → $DOTFILES"
	git clone --bare "$url" "$DOTFILES"
	extract_bootstrap
}

install_configs() {
	[[ $WANT_CONFIGS == y ]] || return 0
	[[ -d $DOTFILES ]] || die "configs requested but $DOTFILES missing"

	info "checking out work tree into \$HOME"
	local err
	err=$(mktemp)
	if ! dots_git checkout 2>"$err"; then
		cat "$err" >&2
		backup_conflicts <"$err"
		dots_git checkout
	fi
	rm -f "$err"

	# bootstrap/ is tracked for the repo but belongs in ~/.dotfiles, not $HOME
	if [[ -d $HOME/bootstrap ]]; then
		info "removing ~/bootstrap (kit lives in ~/.dotfiles)"
		rm -rf "$HOME/bootstrap"
	fi

	if [[ $WANT_SYNC == y ]]; then
		dots_git config --local status.showUntrackedFiles no
		if [[ -f $HOME/README.md ]]; then
			dots_git update-index --assume-unchanged "$HOME/README.md" 2>/dev/null || true
		fi
		info "sync repo ready — ~/.Scripts/dot pull | dot up"
	fi
}

maybe_drop_sync() {
	[[ $WANT_CONFIGS == y ]] || return 0
	[[ $WANT_SYNC == y ]] && return 0
	if [[ -d $DOTFILES ]]; then
		info "removing bare sync repo (configs kept)"
		rm -rf "$DOTFILES"
	fi
}

# --- packages / services / etc ---------------------------------------------

install_desktop_pkgs() {
	[[ $WANT_DESKTOP == y ]] || return 0
	[[ $PLATFORM == arch ]] || return 0
	[[ -x $DOTFILES/install-pkgs ]] || die "missing $DOTFILES/install-pkgs — bare clone/extract failed"
	local -a args=(--desktop)
	[[ $WANT_THINKPAD == y ]] && args+=(--thinkpad)
	"$DOTFILES/install-pkgs" "${args[@]}"
}

enable_services() {
	[[ $WANT_SERVICES == y ]] || return 0
	[[ $PLATFORM == arch ]] || return 0
	local unit
	for unit in NetworkManager bluetooth seatd fstrim.timer; do
		if systemctl list-unit-files "${unit}" &>/dev/null || systemctl cat "${unit}" &>/dev/null; then
			info "enable $unit"
			sudo systemctl enable "$unit" 2>/dev/null || true
		fi
	done
	if [[ $WANT_THINKPAD == y ]]; then
		sudo systemctl enable tlp 2>/dev/null || true
		sudo systemctl enable thinkfan 2>/dev/null || true
	fi
}

apply_etc_templates() {
	[[ $WANT_ETC == y ]] || return 0
	[[ $PLATFORM == arch ]] || return 0
	local src_root="$DOTFILES/etc"
	[[ -d $src_root ]] || {
		info "no etc templates in $src_root — skip"
		return 0
	}

	install_one() {
		local rel=$1 dest=$2
		local src="$src_root/$rel"
		[[ -f $src ]] || return 0
		if [[ -e $dest ]]; then
			sudo cp -a "$dest" "${dest}.bak.$(date +%Y%m%d%H%M%S)"
		fi
		sudo mkdir -p "$(dirname "$dest")"
		sudo cp "$src" "$dest"
		info "installed $dest"
	}

	install_one "tlp.d/01-ringdal.conf" /etc/tlp.d/01-ringdal.conf
	install_one "modprobe.d/99-thinkfan.conf" /etc/modprobe.d/99-thinkfan.conf
	install_one "thinkfan.conf" /etc/thinkfan.conf
	install_one "systemd/logind.conf.d/lid.conf" /etc/systemd/logind.conf.d/lid.conf

	if [[ ! -f /etc/vconsole.conf ]] || ! grep -q '^KEYMAP=' /etc/vconsole.conf 2>/dev/null; then
		info "hint: set KEYMAP=dk-latin1 in /etc/vconsole.conf if needed"
	fi
}

setup_groups() {
	[[ $WANT_DESKTOP == y ]] || return 0
	[[ $PLATFORM == arch ]] || return 0
	local g
	for g in input audio video render; do
		getent group "$g" >/dev/null 2>&1 || continue
		if id -nG "$USER" | tr ' ' '\n' | grep -qx "$g"; then
			continue
		fi
		info "adding $USER to $g"
		sudo usermod -aG "$g" "$USER" || true
	done
}

enable_user_services() {
	[[ $WANT_DESKTOP == y ]] || return 0
	[[ $PLATFORM == arch ]] || return 0
	if command -v systemctl >/dev/null 2>&1; then
		systemctl --user enable hyprwhspr.service 2>/dev/null || true
	fi
}

# --- AIOS / Claude ---------------------------------------------------------

clone_repo() {
	local dir=$1 slug=$2
	if [[ -d $dir/.git ]]; then
		info "skip $dir (already a git repo)"
		return 0
	fi
	if [[ -e $dir ]] && [[ -n $(ls -A "$dir" 2>/dev/null || true) ]]; then
		info "skip $dir (exists, not empty, no .git)"
		return 0
	fi
	local url
	url=$(git_url "$slug")
	info "cloning $slug → $dir"
	git clone "$url" "$dir" || return 1
}

install_aios() {
	[[ $WANT_AIOS == y ]] || return 0
	command -v git >/dev/null 2>&1 || die "git required for AIOS"

	local umbrella
	umbrella=$(git_url The3File/AIOS)
	if [[ -d $AIOS_DIR/.git ]]; then
		info "~/AIOS already present — skip umbrella clone"
	elif [[ -e $AIOS_DIR ]] && [[ -n $(ls -A "$AIOS_DIR" 2>/dev/null || true) ]]; then
		die "$AIOS_DIR exists and is not empty"
	else
		info "cloning AIOS → $AIOS_DIR"
		git clone "$umbrella" "$AIOS_DIR"
	fi

	local entry name slug
	for entry in "${AIOS_NESTED[@]}"; do
		name=${entry%%|*}
		slug=${entry#*|}
		if ! clone_repo "$AIOS_DIR/$name" "$slug"; then
			info "warning: failed to clone $slug — continuing"
		fi
	done
}

install_claude() {
	[[ $WANT_CLAUDE == y ]] || return 0
	if ! command -v npm >/dev/null 2>&1; then
		if [[ $PLATFORM == arch ]]; then
			info "installing nodejs/npm for Claude"
			sudo_pacman -S --needed --noconfirm nodejs npm
		else
			die "npm not found — install Node first"
		fi
	fi

	mkdir -p "${HOME}/.local/bin"
	local npmrc="${HOME}/.npmrc"
	if [[ -f $npmrc ]]; then
		grep -q 'allow-scripts=@anthropic-ai/claude-code' "$npmrc" 2>/dev/null ||
			printf '\n%s\n' "allow-scripts=@anthropic-ai/claude-code" >>"$npmrc"
	else
		printf '%s\n' "allow-scripts=@anthropic-ai/claude-code" >"$npmrc"
	fi

	info "npm install -g @anthropic-ai/claude-code"
	npm install -g @anthropic-ai/claude-code

	local install_cjs
	install_cjs=$(npm root -g)/@anthropic-ai/claude-code/install.cjs
	if [[ -f $install_cjs ]]; then
		info "running Claude native install.cjs"
		node "$install_cjs" || true
	fi
}

next_steps() {
	cat <<'EOF'

── next steps ──
  • re-login if groups were added
  • Arch: VT1 → start-hyprland via ~/.profile
  • Whisper / Piper models are NOT downloaded — fetch manually for hyprwhspr / claude-speak
  • wallpaper / wal: ~/.Scripts/chwal
  • Claude memory symlink for AIOS: see setup-memory-symlink skill / AIOS docs
  • with sync: ~/.Scripts/dot pull | dot up
  • ssh clone: ensure ~/.ssh keys exist before re-running with ssh
EOF
}

# --- main ------------------------------------------------------------------

main() {
	interview
	preflight

	if [[ $PLATFORM == arch ]]; then
		pacman_foundation
		bare_clone_dots
		install_desktop_pkgs
		enable_services
		apply_etc_templates
		setup_groups
		install_configs
		enable_user_services
	else
		bare_clone_dots
		install_configs
	fi

	install_aios
	install_claude
	maybe_drop_sync
	next_steps
	info "done"
}

main "$@"
