local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

-- Forward this GUI's identity into WSL without translating the Windows socket path.
-- Term Dad inherits it from the supervisor shell, even with several GUIs open.
config.set_environment_variables = {
  WSLENV = (os.getenv 'WSLENV' or '') .. ':WEZTERM_UNIX_SOCKET:WEZTERM_PANE',
}

-- ============================================================
-- WSL by default
-- ============================================================
-- Every new window/tab/pane starts in Ubuntu (WSL) instead of
-- PowerShell/cmd. Launch in your Linux home dir, not /mnt/c.
config.default_domain = 'WSL:Ubuntu'
config.wsl_domains = {
  {
    name = 'WSL:Ubuntu',
    distribution = 'Ubuntu',
    default_cwd = '~/ctm',
  },
}

-- ============================================================
-- Rendering
-- ============================================================
-- GPU-accelerated rendering (this is the default, made explicit here).
-- WebGpu picks Dx12/Vulkan on Windows; HighPerformance prefers the
-- discrete GPU over integrated graphics on dual-GPU machines.
config.front_end = 'WebGpu'
config.webgpu_power_preference = 'HighPerformance'

-- ============================================================
-- Appearance
-- ============================================================
config.color_scheme = 'Catppuccin Mocha' -- try 'Tokyo Night', 'Gruvbox dark, medium (base16)', 'OneDark (base16)'
config.font = wezterm.font_with_fallback {
  'Agave Nerd Font',
  'MesloLGS NF',
  'JetBrains Mono', -- bundled with WezTerm, no install needed
}
config.font_size = 15.0 -- Agave runs a little small
config.window_background_opacity = 0.97
config.window_padding = { left = 8, right = 8, top = 6, bottom = 6 }

-- Tab bar: fancy (native-style) tabs, styled to match Catppuccin Mocha
config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.tab_max_width = 32
config.window_frame = {
  active_titlebar_bg = '#11111b', -- crust
  inactive_titlebar_bg = '#11111b',
  font = wezterm.font { family = 'Agave Nerd Font', weight = 'Bold' },
  font_size = 15.0,
}
config.colors = {
  tab_bar = {
    background = '#11111b', -- crust (used when bar overflows)
    active_tab = {
      bg_color = '#cba6f7', -- mauve
      fg_color = '#11111b',
      intensity = 'Bold',
    },
    inactive_tab = {
      bg_color = '#313244', -- surface0
      fg_color = '#a6adc8', -- subtext0
    },
    inactive_tab_hover = {
      bg_color = '#45475a', -- surface1
      fg_color = '#cdd6f4', -- text
    },
  },
}

-- Tab titles: "1: name" with breathing room, truncated when long
wezterm.on('format-tab-title', function(tab)
  local title = tab.tab_title
  if title == '' then
    title = tab.active_pane.title
  end
  if #title > 24 then
    title = wezterm.truncate_right(title, 23) .. '…'
  end
  return '  ' .. (tab.tab_index + 1) .. ': ' .. title .. '  '
end)

-- The + tab-bar button: also start in ~/ctm instead of inheriting
-- the current pane's directory
wezterm.on('new-tab-button-click', function(window, pane, button, default_action)
  if button == 'Left' then
    window:perform_action(
      act.SpawnCommandInNewTab { cwd = '/home/zak/ctm' },
      pane
    )
    return false -- suppress the default (inheriting) action
  end
  -- right-click keeps its default behaviour (launcher menu)
end)

-- ============================================================
-- Behaviour
-- ============================================================
config.scrollback_lines = 10000
config.default_cursor_style = 'SteadyBar'
config.audible_bell = 'Disabled'
config.window_close_confirmation = 'NeverPrompt' -- set to 'AlwaysPrompt' if you close things by accident
config.max_fps = 120

-- ============================================================
-- Key bindings (panes + tabs, tmux-ish but on ALT)
-- ============================================================
config.keys = {
  -- Shift+Enter inserts a newline in TUI apps like Claude Code
  -- (by default WezTerm sends plain Enter, which submits instead)
  { key = 'Enter', mods = 'SHIFT', action = act.SendString '\x1b\r' },

  -- Split panes
  { key = 'd', mods = 'ALT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 's', mods = 'ALT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
  { key = 'w', mods = 'ALT', action = act.CloseCurrentPane { confirm = true } },

  -- Move between panes
  { key = 'LeftArrow',  mods = 'ALT', action = act.ActivatePaneDirection 'Left' },
  { key = 'RightArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Right' },
  { key = 'UpArrow',    mods = 'ALT', action = act.ActivatePaneDirection 'Up' },
  { key = 'DownArrow',  mods = 'ALT', action = act.ActivatePaneDirection 'Down' },

  -- Zoom current pane (toggle fullscreen within the window)
  { key = 'z', mods = 'ALT', action = act.TogglePaneZoomState },

  -- Tabs (new tabs always start in ~/ctm; the shell reports its cwd via
  -- OSC 7, which would otherwise make new tabs inherit the current dir)
  { key = 't', mods = 'CTRL|SHIFT', action = act.SpawnCommandInNewTab { domain = 'CurrentPaneDomain', cwd = '/home/zak/ctm' } },
  { key = 'Tab', mods = 'CTRL', action = act.ActivateTabRelative(1) },
  { key = 'Tab', mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(-1) },

  -- Quickly open a plain PowerShell tab when you need Windows
  { key = 'p', mods = 'ALT|SHIFT', action = act.SpawnCommandInNewTab { domain = { DomainName = 'local' }, args = { 'powershell.exe' } } },
}

-- ALT+1..9 to jump to a tab
for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = 'ALT',
    action = act.ActivateTab(i - 1),
  })
end

return config
