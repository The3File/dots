-- Hyprland — ported from bspwmrc + core sxhkdrc binds (Lua)
-- Terminal: alacritty
-- https://wiki.hypr.land/Configuring/Start/

local ok, colors = pcall(require, "colors")
if not ok then
    colors = {
        active_border   = "rgb(5ca7a5)",
        inactive_border = "rgb(191a1a)",
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
    hl.exec_cmd("waybar")
    hl.exec_cmd("dunst")
    hl.exec_cmd("hyprpaper")
end)

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 7,
        gaps_out = 15,
        border_size = 2,
        col = {
            active_border   = colors.active_border,
            inactive_border = colors.inactive_border,
        },
        resize_on_border = false,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding         = 10,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        blur = {
            enabled            = true,
            size               = 6,
            passes             = 4,
            ignore_opacity     = true,
            new_optimizations  = true,
            xray               = false,
            noise              = 0.03,
            contrast           = 0.9,
            brightness         = 0.95,
            vibrancy           = 0.5,
            vibrancy_darkness  = 0.1,
            special            = false,
            popups             = true,
            popups_ignorealpha = 0.2,
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
            natural_scroll = true,
        },
    },
})

-- gestures: swipe off unless you add hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

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
hl.bind(mod .. " + D", function()
    hl.exec_cmd("/home/ringdal/.Scripts/fuzzel_drun")
end)

-- Kill / force kill
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + Q", hl.dsp.window.kill())

-- Reload / exit
hl.bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(mod .. " + SHIFT + Escape", hl.dsp.exit())

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
hl.bind(mod .. " + A", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.Scripts/scratch math"))

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

-- Volume (RTMIN+1 refreshes waybar custom/vol)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pamixer -i 5; pkill -RTMIN+1 waybar"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pamixer -d 5; pkill -RTMIN+1 waybar"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pamixer -t; pkill -RTMIN+1 waybar"), { locked = true })
hl.bind(mod .. " + XF86AudioRaiseVolume", hl.dsp.exec_cmd("pamixer --allow-boost -i 5; pkill -RTMIN+1 waybar"), { locked = true })
hl.bind(mod .. " + XF86AudioLowerVolume", hl.dsp.exec_cmd("pamixer --allow-boost -d 5; pkill -RTMIN+1 waybar"), { locked = true })

-- Brightness (RTMIN+2 refreshes waybar custom/light)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("sudo light -A 5; pkill -RTMIN+2 waybar"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("sudo light -U 5; pkill -RTMIN+2 waybar"), { locked = true, repeating = true })

----------------------
---- WINDOW RULES ----
----------------------

local float_classes = { "float", "bye", "cal", "net", "gass", "files", "follow" }
for _, cls in ipairs(float_classes) do
    hl.window_rule({
        match = { class = "^(" .. cls .. ")$" },
        float = true,
    })
end

hl.window_rule({
    match = { class = "^(scratchterm)$" },
    float = true,
    workspace = "special:scratchterm",
})

hl.window_rule({
    match = { class = "^(scratchmath)$" },
    float = true,
    size = { 1000, 400 },
    workspace = "special:scratchmath",
})

-- Keep non-scratch apps off special workspaces. While a scratch is open,
-- Hyprland would otherwise spawn new windows there (behind the scratch float).
local scratch_classes = {
    scratchterm = true,
    scratchmath = true,
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

-- Blur translucent layers (waybar)
hl.layer_rule({
    match = { namespace = "waybar" },
    blur = true,
    ignore_alpha = 0.2,
})
