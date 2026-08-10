## personal dotfiles

### New machine (Arch)

1. Finish the [Arch install guide](https://wiki.archlinux.org/title/Installation_guide): bootable system, your user + `sudo`, working network.
2. Log in as **your user** (not root).
3. Run:

```bash
curl --url https://raw.githubusercontent.com/The3File/dots/master/.install.bash | /bin/bash
```

4. Answer the questions (nothing runs until you confirm the plan).
5. Re-login when it finishes, then open a TTY — Hyprland starts from `~/.profile` on VT1.

You do **not** need `git` beforehand. The script installs it.

**Termux / other:** same curl command. Say `termux` or `other` when asked — skip Arch packages; you still get configs if you want them.

### Day to day (this machine)

```bash
dot pull              # get updates
dot up "message"      # commit + push your changes
```

(`dot` is `~/.Scripts/dot` — on PATH via `~/.profile`.)

### Tips

- Prefer **https** clone if you have no SSH key yet.
- Say **yes** to sync on Arch if this box should push/pull dots; **no** on Termux (configs stay, sync repo does not).
- Whisper/Piper models and wallpapers are **not** installed — add those yourself later.
