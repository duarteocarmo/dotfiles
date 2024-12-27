-- Pull in the wezterm API
local wezterm = require 'wezterm'

local config = {}

-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end


-- local darktheme = 'Ef-Dark'
-- local lighttheme = 'Ef-Duo-Light'
-- local darktheme = 'Modus-Vivendi'
-- local lighttheme = 'Modus-Operandi'
-- local lighttheme = 'neobones_light'
-- local lighttheme = 'Gruvbox light, soft (base16)'
-- local darktheme = 'Gruvbox dark, hard (base16)'
-- local darktheme = 'Tokyo Night'
-- local lighttheme = 'Tokyo Night Day'
local darktheme = 'Modus-Vivendi-Tinted'
local lighttheme = 'Modus-Operandi-Tinted'
-- local darktheme = 'Ef-Dark'
-- local lighttheme = 'Ef-Day'

-- Adaptive theme
function scheme_for_appearance(appearance)
  if appearance:find 'Dark' then
    return darktheme
  else
    return lighttheme
  end
end

wezterm.on('window-config-reloaded', function(window, pane)
  local overrides = window:get_config_overrides() or {}
  local appearance = window:get_appearance()
  local scheme = scheme_for_appearance(appearance)
  if overrides.color_scheme ~= scheme then
    overrides.color_scheme = scheme
    window:set_config_overrides(overrides)
  end
end)


config.hide_tab_bar_if_only_one_tab = true
--
config.window_close_confirmation = 'NeverPrompt'
config.freetype_load_flags = 'NO_HINTING'


-- font
-- config.font = wezterm.font 'Noto Sans Mono'
-- config.font = wezterm.font 'Comic Mono'
-- config.font = wezterm.font 'Fira Code Retina'
-- config.font = wezterm.font 'JetBrains Mono'
config.font = wezterm.font 'SF Mono'
-- In newer versions of wezterm, use the config_builder which will
-- config.font =
--   wezterm.font('Noto Sans Mono', { weight = 'Bold', italic = false })
config.hyperlink_rules = wezterm.default_hyperlink_rules()

-- make task numbers clickable
-- the first matched regex group is captured in $1.
table.insert(config.hyperlink_rules, {
  regex = [[\b[tt](\d+)\b]],
  format = 'https://example.com/tasks/?t=$1',
})

-- make username/project paths clickable. this implies paths like the following are for github.
-- ( "nvim-treesitter/nvim-treesitter" | wbthomason/packer.nvim | wez/wezterm | "wez/wezterm.git" )
-- as long as a full url hyperlink regex exists above this it should not match a full url to
-- github or gitlab / bitbucket (i.e. https://gitlab.com/user/project.git is still a whole clickable url)
table.insert(config.hyperlink_rules, {
  regex = [[["]?([\w\d]{1}[-\w\d]+)(/){1}([-\w\d\.]+)["]?]],
  format = 'https://www.github.com/$1/$3',
})


config.keys = {
  { key = "LeftArrow",  mods = "OPT", action = wezterm.action { SendString = "\x1bb" } },
  { key = "RightArrow", mods = "OPT", action = wezterm.action { SendString = "\x1bf" } },
}

config.audible_bell = "Disabled"
-- config.front_end = "WebGpu"

return config


