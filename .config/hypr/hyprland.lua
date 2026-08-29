-- Hyprland — ported from bspwmrc + core sxhkdrc binds (Lua)
-- Terminal: alacritty
-- https://wiki.hypr.land/Configuring/Start/

local ok, colors = pcall(require, "colors")
if not ok then
    colors = {
        active_border   = "rgb(5ca7a5)",
        inactive_border = "rgb(4a5750)",
    }
end

------------------
---- PROGRAMS ----
------------------

local terminal    = "alacritty"
local fileManager = "alacritty -e lf"
local browser     = "qutebrowser"
local browserAlt  = "brave"
local mod         = "SUPER"

------------------
---- MONITORS ----
------------------

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    -- Fladen: pillen (~/.config/quickshell/ringdal). Waybar og dunst er vaek
    -- (afinstalleret 29-08) -- der er ingen fallback laengere, og det er med
    -- vilje: to bare der begge kunne staa der var to steder at rette.
    -- Beskederne kommer fra pillen selv (services/Notifs.qml); der kan kun
    -- vaere én paa org.freedesktop.Notifications.
    hl.exec_cmd("qs -c ringdal")
    -- Baggrunden: awww (afloeste hyprpaper 28-08). Gaar gennem et script, fordi
    -- awww holder tilstanden i daemonen og ikke i en configfil -- den skal
    -- spoerges om det sidste billede, og den skal vaere oppe foerst.
    hl.exec_cmd(os.getenv("HOME") .. "/.Scripts/wallpaper-start")
    hl.exec_cmd(os.getenv("HOME") .. "/.Scripts/cliphist-watch")
    hl.exec_cmd(os.getenv("HOME") .. "/.Scripts/low_battery_warning")
    hl.exec_cmd(os.getenv("HOME") .. "/.Scripts/lock_keys ensure")
    -- ACPI firmware buttons still work while lock_keys disables the laptop kb.
    hl.exec_cmd(os.getenv("HOME") .. "/.Scripts/acpid_events")
    -- Undo accidental ThinkPad flight-mode soft-rfkill (hwdb remaps the key too).
    hl.exec_cmd(os.getenv("HOME") .. "/.Scripts/rfkill-guard")
    -- ThinkPad LEDs: power off; micmute inverted (muted=on) via pwrbtnlght.
    hl.exec_cmd(os.getenv("HOME") .. "/.Scripts/pwrbtnlght sync")
    hl.exec_cmd(os.getenv("HOME") .. "/.Scripts/pwrbtnlght watch")
    hl.exec_cmd("hypridle")
    -- TTY→Hyprland never reaches graphical-session.target, so the enabled
    -- user unit (WantedBy=graphical-session.target) does not auto-start.
    hl.exec_cmd("systemctl --user start hyprwhspr.service")
end)

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 7,
        gaps_out = 14,
        border_size = 2,
        col = {
            active_border   = colors.active_border,
            inactive_border = colors.inactive_border,
        },
        resize_on_border = false,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    -- Hardware cursor planes get confused by the Sunshine/Moonlight virtual
    -- output topology and clamp the cursor to one monitor, blocking it from
    -- crossing into the other (known Hyprland multi-monitor cursor bug).
    -- Software cursor rendering avoids it; cost is negligible.
    cursor = {
        no_hardware_cursors = true,
    },

    decoration = {
        rounding         = 15,
        dim_special      = 0.0,
		  --active_opacity   = 1.0,
		  --inactive_opacity = 0.7,
        --dim_inactive     = true,
        --dim_strength     = 0.3,

        blur = {
            enabled = true,
				size = 5,
				passes = 3,
				ignore_opacity = true,
				new_optimizations = true,
        },

        shadow = {
            enabled = false,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
        force_split    = 0,
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        focus_on_activate       = true,
    },

    input = {
        kb_layout  = "dk",
        kb_variant = "nodeadkeys",
        kb_options = "caps:swapescape,shift:both_capslock",

        follow_mouse = 1,
        sensitivity  = 0,

        touchpad = {
            natural_scroll       = true,
            -- 1-finger click = left, 2-finger = right, 3-finger = middle
            clickfinger_behavior = true,
        },
    },
})

-- Blur bag pillen. Quickshell-fladen er én stor gennemsigtig flade (1920x640),
-- så uden ignore_alpha ville hele bunden af skærmen blive sløret -- ikke kun
-- pillen. Tærsklen skal ligge under pillens egen alpha, som er skruen
-- `body.opacity` i ~/.config/quickshell/ringdal/config.json. Den ligger lavt
-- med vilje, så den skrue kan drejes helt ned til ca. 0,25 uden at sløringen
-- falder væk. Alt uden om pillen er alpha 0 og bliver derfor aldrig sløret.
hl.layer_rule({
    name        = "blur-pillen",
    match       = { namespace = "^quickshell$" },
    blur        = true,
    ignore_alpha = 0.2,
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

local function scratchaios_shown()
    local s = hl.get_active_special_workspace()
    return s and s.name:gsub("^special:", "") == "scratchaios"
end

-- Down opens only; up closes only (Super+A still toggles)
hl.gesture({
    fingers = 3,
    direction = "down",
    action = function()
        if scratchaios_shown() then
            return
        end
        hl.exec_cmd(os.getenv("HOME") .. "/.Scripts/scratch aios")
    end,
})

hl.gesture({
    fingers = 3,
    direction = "up",
    action = function()
        if not scratchaios_shown() then
            return
        end
        hl.dispatch(hl.dsp.workspace.toggle_special("scratchaios"))
    end,
})

hl.curve("easeOut", { type = "bezier", points = { { 0.16, 1 }, { 0.3, 1 } } })
hl.animation({ leaf = "windows",    enabled = true, speed = 3, bezier = "easeOut", style = "popin 80%" })
hl.animation({ leaf = "fade",       enabled = true, speed = 3, bezier = "easeOut" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "easeOut", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3, bezier = "easeOut", style = "slidefadevert -50%" })

---------------------
---- KEYBINDINGS ----
---------------------

-- Terminal
hl.bind(mod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + SHIFT + Return", hl.dsp.exec_cmd(terminal .. " --class float"))

-- Apps
hl.bind(mod .. " + O", hl.dsp.exec_cmd(browser))
hl.bind(mod .. " + W", hl.dsp.exec_cmd(browserAlt))
hl.bind(mod .. " + E", hl.dsp.exec_cmd(fileManager))
-- Applikationsaabner: pillen, ikke fuzzel. Samme tast, ny flade.
-- fuzzel_drun ligger stadig i ~/.Scripts; fuzzel bruges ogsaa af fuzzel_nm
-- naar der skal skrives en wifi-kode, saa den bliver.
hl.bind(mod .. " + D", hl.dsp.exec_cmd("qs -c ringdal ipc call launcher toggle"))

-- Et TRYK paa Super alene aabner pillens menu (release = true, saa den foerst
-- falder naar tasten slippes). Holder han den nede og trykker noget andet,
-- er det en genvej, og menuen kommer ikke -- Hyprland lader kun bindet falde,
-- naar modifieren ikke blev brugt til noget.
--
-- Baade venstre og hoejre: tasten til hoejre for hoejre alt er remappet fra
-- print screen til hoejre Super (se hwdb'en 90-prtsc-super), saa den er
-- tommelfingerens vej ind i menuen.
-- Og kun et KORT tryk: holder han Super inde et oejeblik uden at trykke
-- andet, skal menuen ikke komme. Hyprland kan ikke selv maale hold-tiden, saa
-- nedtrykket stempler tiden (non_consuming, ellers holder bindet Super fra at
-- virke som modifier) og pill-super-tap regner differencen ud ved slip.
local pillNed = hl.dsp.exec_cmd("~/.Scripts/pill-super-tap ned")
local pillOp  = hl.dsp.exec_cmd("~/.Scripts/pill-super-tap op")
hl.bind("SUPER_L", pillNed, { non_consuming = true })
hl.bind("SUPER_R", pillNed, { non_consuming = true })
hl.bind(mod .. " + SUPER_L", pillOp, { release = true })
hl.bind(mod .. " + SUPER_R", pillOp, { release = true })
-- Clipboard history (bspwm: super + Insert → clipmenu). Aabner pillen; den
-- kalder cliphist gennem fuzzel_clip, som stadig virker fra en terminal.
hl.bind(mod .. " + Insert", hl.dsp.exec_cmd("qs -c ringdal ipc call pill udklip"))

-- Voice dictation (hyprwhspr): press to start, press again to paste
hl.bind(mod .. " + Space", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.Scripts/hyprwhspr-record-toggle"))
-- Afbryd det der koerer lige nu. ÉN tast, ÉN mening -- hvad der bliver
-- afbrudt, afgoeres af hvad der er i gang: dikterer han, kasseres optagelsen;
-- goer han ikke, springes den linje over, der laeses hoejt. Input vinder over
-- output, samme rangorden som resten af pillen.
-- Beslutningen ligger i `pill afbryd`, fordi pillen allerede VED om der
-- dikteres (Voice) og om der tales (Tale) -- ikke i et script der skulle
-- gaette sig til begge dele.
-- Faldet bagud er med vilje: er qs nede (exit 255), skal dikteringen stadig
-- kunne kasseres. Er qs oppe, svarer den 0 ogsaa naar der intet var at goere.
hl.bind(mod .. " + Escape", hl.dsp.exec_cmd("qs -c ringdal ipc call pill afbryd || hyprwhspr record cancel"))
-- Stemmen skrues op og ned: fuld -> vigtigt -> tavs -> fuld.
-- Pegede foer paa `claude-speak toggle`, som satte et flag INTET laeste --
-- den stemme Filip faktisk hoerer kommer fra `tale`. Genvejen var doed.
hl.bind(mod .. " + SHIFT + V", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/tale skru"))

-- Oeretelefonen som diktafon: ét tryk paa Buds3 Pro starter og slutter
-- dikteringen, saa han kan tale uden at have haenderne paa maskinen.
-- Proppen sender KEY_PLAYCD (XF86AudioPlay) paa ét tryk; det lange tryk naar
-- aldrig hertil, fordi Samsung bruger det til stoejdaempning inde i proppen.
-- Derfor ligger dikteringen paa play-tasten -- og derfor afgoer `buds-tryk`,
-- om trykket hoerer til musikken eller til mikrofonen, i stedet for at vi
-- vaelger én af dem én gang for alle.
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.Scripts/buds-tryk"))
-- To tryk kasserer det, han er ved at sige. Proppen sender KEY_NEXTSONG, saa
-- den mening laegger sig oven paa naeste-nummer -- og `buds-dobbelttryk`
-- afgoer hvilken af de to der gaelder lige nu.
hl.bind("XF86AudioNext", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.Scripts/buds-dobbelttryk"))

-- Kill / force kill
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + Q", hl.dsp.window.kill())

-- Reload / exit
hl.bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(mod .. " + SHIFT + Escape", hl.dsp.exit())
-- Power menu (bspwm: super + alt + shift + q → alacritty_bye). Nu i pillen,
-- med et ekstra "er du sikker" — handlingerne ligger stadig i `bye`.
hl.bind(mod .. " + ALT + SHIFT + Q", hl.dsp.exec_cmd("qs -c ringdal ipc call pill sluk"))
-- Next wallpaper / wal palette
hl.bind(mod .. " + ALT + SHIFT + W", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.Scripts/chwal"))
-- Hold maskinen vaagen, ogsaa med lukket laag (pillen viser "koffein" naar den er taendt)
hl.bind(mod .. " + ALT + SHIFT + K", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.Scripts/koffein toggle"))

-- Bluetooth / WiFi (old sxhkd: Super+Shift+B / Super+Shift+W)
-- Samme taster, men de aabner nu pillen i stedet for fuzzel. Menuerne kalder
-- de samme scripts indeni, saa funktionaliteten er den samme; scriptene virker
-- stadig fra en terminal som fallback.
-- Keylock toggle is ThinkPad ACPI hotkey only (acpid_events → lock_keys toggle),
-- not Super+Shift+K (that bind is window.swap up below).
hl.bind(mod .. " + SHIFT + B", hl.dsp.exec_cmd("qs -c ringdal ipc call pill bluetooth"))
hl.bind(mod .. " + SHIFT + W", hl.dsp.exec_cmd("qs -c ringdal ipc call pill wifi"))

-- Den frie linje til Claude: ét tryk, og feltet staar der.
-- Super+A aabner hele terminalen; Super+Shift+A er den lette udgave af samme
-- gestus -- sig noget til sessionen uden at give skaermen vaek. Samme bogstav
-- med vilje, saa de to hoerer sammen i fingrene.
hl.bind(mod .. " + SHIFT + A", hl.dsp.exec_cmd("qs -c ringdal ipc call pill linje"))

-- Focus
hl.bind(mod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + L", hl.dsp.focus({ direction = "right" }))

-- Swap
hl.bind(mod .. " + SHIFT + H", hl.dsp.window.swap({ direction = "left" }))
hl.bind(mod .. " + SHIFT + J", hl.dsp.window.swap({ direction = "down" }))
hl.bind(mod .. " + SHIFT + K", hl.dsp.window.swap({ direction = "up" }))
hl.bind(mod .. " + SHIFT + L", hl.dsp.window.swap({ direction = "right" }))

-- Workspaces 1–10
for i = 1, 10 do
    local key = i % 10
    hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Cycle workspaces
hl.bind(mod .. " + Tab", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + SHIFT + Tab", hl.dsp.focus({ workspace = "e-1" }))

-- Last window
hl.bind(mod .. " + grave", hl.dsp.focus({ last = true }))

-- Scratchpads
hl.bind(mod .. " + P", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.Scripts/scratch term"))
hl.bind(mod .. " + A", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.Scripts/scratch aios"))

-- Window states
hl.bind(mod .. " + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(mod .. " + CTRL + S", hl.dsp.window.pin())

-- Resize (Super+Alt+hjkl)
hl.bind(mod .. " + ALT + H", hl.dsp.window.resize({ x = -20, y = 0, relative = true }), { repeating = true })
hl.bind(mod .. " + ALT + J", hl.dsp.window.resize({ x = 0, y = 20, relative = true }), { repeating = true })
hl.bind(mod .. " + ALT + K", hl.dsp.window.resize({ x = 0, y = -20, relative = true }), { repeating = true })
hl.bind(mod .. " + ALT + L", hl.dsp.window.resize({ x = 20, y = 0, relative = true }), { repeating = true })

-- Move floating (Alt+Shift+hjkl)
hl.bind("ALT + SHIFT + H", hl.dsp.window.move({ x = -20, y = 0, relative = true }), { repeating = true })
hl.bind("ALT + SHIFT + J", hl.dsp.window.move({ x = 0, y = 20, relative = true }), { repeating = true })
hl.bind("ALT + SHIFT + K", hl.dsp.window.move({ x = 0, y = -20, relative = true }), { repeating = true })
hl.bind("ALT + SHIFT + L", hl.dsp.window.move({ x = 20, y = 0, relative = true }), { repeating = true })

-- Mouse: move / resize with Super
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Volume. Ingen besked til fladen: pillen laeser Pipewire direkte og ser det selv.
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pamixer -i 5"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pamixer -d 5"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pamixer -t"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.Scripts/pwrbtnlght mic-toggle"), { locked = true })
hl.bind(mod .. " + XF86AudioRaiseVolume", hl.dsp.exec_cmd("pamixer --allow-boost -i 5"), { locked = true })
hl.bind(mod .. " + XF86AudioLowerVolume", hl.dsp.exec_cmd("pamixer --allow-boost -d 5"), { locked = true })

-- Brightness. Sysfs siger ikke selv til, saa pillen SKAL vaekkes her -- den
-- poller ikke laengere (Config.backlightInterval = 0).
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("light -A 5; qs -c ringdal ipc call backlight refresh"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("light -U 5; qs -c ringdal ipc call backlight refresh"), { locked = true, repeating = true })

----------------------
---- WINDOW RULES ----
----------------------

local float_classes = { "float", "cal", "net", "gass", "files", "follow" }
for _, cls in ipairs(float_classes) do
    hl.window_rule({
        match = { class = "^(" .. cls .. ")$" },
        float = true,
    })
end

-- Power menu (bspwm: bye rectangle 270x150+50+860, sticky)
hl.window_rule({
    match = { class = "^(bye)$" },
    float = true,
    pin = true,
    size = { 270, 150 },
    move = { 50, 860 },
})

hl.window_rule({
    match = { class = "^(scratchterm)$" },
    float = true,
    size = { 1065, 612 },
    move = { 809, 48 },
    workspace = "special:scratchterm",
})

hl.window_rule({
    match = { class = "^(scratchaios)$" },
    float = true,
    size = { 1060, 960 },
    center = true,
    workspace = "special:scratchaios",
})

-- Keep non-scratch apps off special workspaces. While a scratch is open,
-- Hyprland would otherwise spawn new windows there (behind the scratch float).
local scratch_classes = {
    scratchterm = true,
    scratchaios = true,
}

hl.on("window.open", function(win)
    local ws = win.workspace
    if not (ws and ws.special) then
        return
    end

    local cls = win.initial_class
    if cls == nil or cls == "" then
        cls = win.class
    end
    if scratch_classes[cls] then
        return
    end

    local mon = win.monitor or hl.get_active_monitor()
    local target = mon and mon.active_workspace
    if not target or target.special then
        return
    end

    hl.dispatch(hl.dsp.window.move({
        workspace = target,
        follow = true,
        window = win,
    }))

    -- Dismiss scratch so the new window isn't hidden behind it.
    local special = mon.active_special_workspace
    if special then
        local name = special.name:gsub("^special:", "")
        if name ~= "" then
            hl.dispatch(hl.dsp.workspace.toggle_special(name))
        end
    end
end)

hl.window_rule({
    match = { class = "^(fullscreen)$" },
    fullscreen = true,
})

for _, cls in ipairs({ "files", "follow", "gass" }) do
    hl.window_rule({
        match = { class = "^(" .. cls .. ")$" },
        pin = true,
    })
end

hl.window_rule({
    match = { class = "^(Zathura)$" },
    tile = true,
})

hl.window_rule({
    match = { class = "^(jetbrains-studio)$" },
    tile = true,
})

-- Chromium/Brave on Wayland over-scales touchpad scroll; dampen only here.
hl.window_rule({
    match = { class = "^(brave-browser)$" },
    scroll_touchpad = 0.2,
})
