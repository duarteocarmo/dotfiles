-- Pull in the wezterm API
local wezterm = require 'wezterm'

local config = {}

-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- Adaptive theme
function scheme_for_appearance(appearance)
  if appearance:find 'Dark' then
    return 'neobones_dark'
  else
    return 'neobones_light'
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
-- config.window_background_opacity = 0.3
-- config.macos_window_background_blur = 20



-- font
config.font = wezterm.font 'Noto Sans Mono'
-- In newer versions of wezterm, use the config_builder which will
-- config.font =
--   wezterm.font('Noto Sans Mono', { weight = 'Bold', italic = false })

return config
