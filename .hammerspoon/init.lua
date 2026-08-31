hs.hotkey.bind('shift alt ctrl', 'r', 'Reload Hammerspoon config', function()
  hs.reload()
  hs.notify.show('Hammerspoon', 'Config reloaded', '')
end)

require('main')
