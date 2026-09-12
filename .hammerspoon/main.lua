rawset(_G, 'hs', hs)

local window = hs.window
local mouse = hs.mouse
local logger = hs.logger.new('main', 'verbose')
local wf = hs.window.filter
local utils = require('utils')

-- Use Fn + h/l/j/k as arrow keys, y/u/i/o as mouse wheel, ,/. as left/right click.
hs.loadSpoon('FnMate')

window.animationDuration = 0

local function bind(keys, message, fn)
  if message == nil or type(message) == 'function' then
    -- Shift down arguments
    fn = message
    message = nil
  end

  local mods = hs.fnutils.split(keys, '%s+')
  local key = table.remove(mods, #mods)
  hs.hotkey.bind(mods, key, message, fn)
end

bind('cmd H', function()
  hs.hints.windowHints()
end)

hs.urlevent.bind('showText', function()
  local inputFile = '/tmp/hammerspoon_input.txt'
  local file = io.open(inputFile, 'r')

  if file then
    local content = file:read('*all')
    file:close()

    if content and content ~= '' then
      content = content:gsub('[\r\n]+%s*[\r\n]+', '\n'):match('^%s*(.-)%s*$')
      local style = {
        atScreenEdge = 2, -- Bottom edge
      }
      hs.alert.show(content, style, hs.screen.mainScreen(), 5)
    end
  end
end)

bind('shift ctrl alt F', 'Maximize window with Stage Manager', function()
  utils.fitBox(window.focusedWindow(), { right = 200 }, 'right')
end)

bind('shift alt F', 'Maximize window', function()
  utils.fitBox(window.focusedWindow(), nil, 'center')
end)

bind('shift alt W', 'Set window width to 720, max height', function()
  local win = window.focusedWindow()
  local screen = win:screen():frame()
  local f = win:frame()
  f.w = 720
  f.y = screen.y
  f.h = screen.h
  win:setFrame(f)
end)

bind('shift alt M', 'Set window to half screen size, centered', function()
  local win = window.focusedWindow()
  local screen = win:screen():frame()
  local f = win:frame()
  f.w = screen.w / 2
  f.h = screen.h / 2
  f.x = screen.x + (screen.w - f.w) / 2
  f.y = screen.y + (screen.h - f.h) / 2
  win:setFrame(f)
end)

bind('shift alt H', 'Move window to West screen', function()
  local win = window.focusedWindow()
  local oldScreen = win:screen():frame()
  local f = win:frame()
  -- Proportional edge-gap positioning: calculate the window edge's position
  -- as a ratio within the "available space" (screen size minus window size).
  -- This ensures if a window isn't touching the edge on the source screen,
  -- it won't touch the edge on the target screen either. Ratio is naturally
  -- clamped to [0, 1] so no explicit bounds checking is needed,
  -- except when the window is wider/taller than the target screen.
  local ratioX = (f.x - oldScreen.x) / (oldScreen.w - f.w)
  local ratioY = (f.y - oldScreen.y) / (oldScreen.h - f.h)

  win:moveOneScreenWest(true)

  local newScreen = win:screen():frame()
  f = win:frame()
  f.x = math.max(newScreen.x, newScreen.x + ratioX * (newScreen.w - f.w))
  f.y = math.max(newScreen.y, newScreen.y + ratioY * (newScreen.h - f.h))
  win:setFrame(f)

  local app = win:application()
  AppActivatedCallback(app:name(), app)
end)

bind('shift alt K', 'Move window to North screen', function()
  window.focusedWindow():moveOneScreenNorth()
  local app = window.focusedWindow():application()
  AppActivatedCallback(app:name(), app)
end)

bind('shift alt J', 'Move window to South screen', function()
  window.focusedWindow():moveOneScreenSouth()
  local app = window.focusedWindow():application()
  AppActivatedCallback(app:name(), app)
end)

bind('shift alt L', 'Move window to East screen', function()
  local win = window.focusedWindow()
  local oldScreen = win:screen():frame()
  local f = win:frame()
  -- Same proportional edge-gap positioning as West (see comment above)
  local ratioX = (f.x - oldScreen.x) / (oldScreen.w - f.w)
  local ratioY = (f.y - oldScreen.y) / (oldScreen.h - f.h)

  win:moveOneScreenEast(true)
  win:moveOneScreenEast(true)

  local newScreen = win:screen():frame()
  f = win:frame()
  f.x = math.max(newScreen.x, newScreen.x + ratioX * (newScreen.w - f.w))
  f.y = math.max(newScreen.y, newScreen.y + ratioY * (newScreen.h - f.h))
  win:setFrame(f)

  local app = win:application()
  AppActivatedCallback(app:name(), app)
end)

local function moveMousePointerToScreen(direction)
  local mainScreen = hs.screen.mainScreen()
  local newScreen = nil

  if direction == 'West' then
    newScreen = mainScreen:toWest()
  elseif direction == 'South' then
    newScreen = mainScreen:toSouth()
  elseif direction == 'North' then
    newScreen = mainScreen:toNorth()
  elseif direction == 'East' then
    newScreen = mainScreen:toEast()
  end

  if not newScreen then
    return
  end

  local point = mouse.getRelativePosition()
  point = {
    x = point.x * (newScreen:fullFrame().w / mainScreen:fullFrame().w),
    y = point.y * (newScreen:fullFrame().h / mainScreen:fullFrame().h),
  }
  mouse.setRelativePosition(point, newScreen)
  hs.eventtap.leftClick(mouse.getAbsolutePosition())
end

bind('alt ctrl H', 'Move mouse pointer to West screen', function()
  moveMousePointerToScreen('West')
end)

bind('alt ctrl K', 'Move mouse pointer to North screen', function()
  moveMousePointerToScreen('North')
end)

bind('alt ctrl J', 'Move mouse pointer to South screen', function()
  moveMousePointerToScreen('South')
end)

bind('alt ctrl L', 'Move mouse pointer to East screen', function()
  moveMousePointerToScreen('East')
end)

bind('shift ctrl cmd L', 'Rotate DELL P2715Q screen 0', function()
  hs.screen('DELL P2715Q'):rotate(0)
end)

bind('shift ctrl cmd P', 'Rotate DELL P2715Q screen 90', function()
  hs.screen('DELL P2715Q'):rotate(90)
end)

bind('shift ctrl cmd K', 'Set North screen as primary', function()
  local northScreen = hs.screen.primaryScreen():toNorth()
  if northScreen then
    northScreen:setPrimary()
  end
end)

bind('shift ctrl cmd J', 'Set South screen as primary', function()
  local southScreen = hs.screen.primaryScreen():toSouth()
  if southScreen then
    southScreen:setPrimary()
  end
end)

-- for i = 0, 9 do
--   hs.hotkey.bind({ 'ctrl' }, tostring(i), function()
--     hs.eventtap.keyStroke({ 'ctrl' }, tostring(i))
--     hs.timer.doAfter(0.1, function()
--       logger.d('Switch to space ' .. i)
--       local windows = hs.window.orderedWindows()
--       if #windows > 0 then
--         windows[1]:focus()
--       end
--     end)
--   end)
-- end

function AppActivatedCallback(appName, app)
  logger.d('App ' .. appName .. ' activated')
  if appName == 'Finder' then
    app:selectMenuItem({ 'Window', 'Bring All to Front' })
    app:selectMenuItem({ '窗口', '前置全部窗口' })
    app:selectMenuItem({ 'View', 'Clean Up By', 'Kind' })
    app:selectMenuItem({ '显示', '整理方式', '种类' })

    utils.fitBox(app:focusedWindow(), { h = 850, w = 1250 }, 'center')
  elseif appName == 'iD' then
    utils.fitBox(app:mainWindow(), nil, 'bottom')
  elseif appName == 'Dash' or appName == 'kitty' or appName == 'MacVim' or appName == 'VimR' then
    if app:focusedWindow():screen() == hs.screen('DELL P2715Q') then
      utils.fitBox(app:focusedWindow(), { bottom = 200 }, 'top')
    else
      app:focusedWindow():maximize()
    end
  elseif appName == 'X' then
    local screen = app:focusedWindow():screen()
    if screen == hs.screen('DELL U2720Q') then
      utils.fitBox(app:focusedWindow(), { w = 900 }, 'right')
    end
  elseif appName == 'Collins Dictionary' then
    app:selectMenuItem({ 'Search', 'Type new search' })
  end
end

AppWatcher = hs.application.watcher
  .new(function(appName, eventType, app)
    if eventType == hs.application.watcher.activated or eventType == hs.application.watcher.deactivated then
      AppActivatedCallback(appName, app)
    end
  end)
  :start()

FinderWatcher = hs.appfinder
  .appFromName('Finder')
  :newWatcher(function(element)
    element:application():selectMenuItem({ 'View', 'Clean Up By', 'Kind' })
    element:application():selectMenuItem({ '显示', '整理方式', '种类' })
  end)
  :start({ hs.uielement.watcher.focusedWindowChanged })

ScreenWatcher = hs.screen.watcher
  .new(function()
    logger.d('Screen layout changed')
    logger.d(hs.screen.primaryScreen():name() .. ' is primary screen')
  end)
  :start()

local appBindings = {
  { 'ctrl 4', 'iTerm' },
  { 'alt 1', 'Cursor' },
  { 'alt 2', '/Applications/Veil.app' },
  { 'alt 3', '/Applications/Veil.app' },
  { 'alt 4', 'Xcode.app' },
  { 'alt Q', 'QQ' },
  { 'alt W', 'WeChat' },
  { 'alt E', 'ChatWise' },
  { 'alt shift E', 'Elpass' },
  { 'alt R', 'MuMu安卓设备' },
  { 'alt shift R', 'MuMuPlayer' },
  { 'alt T', 'WezTerm' },
  { 'alt shift T', 'ChatGPT' },
  { 'alt Y', 'Typora' },
  { 'alt U', 'Ulysses' },
  { 'alt I', 'iPhone Mirroring' },
  { 'alt O', 'Gemini Chronicle' },
  { 'alt shift O', 'OpenComic' },
  { 'alt P', 'Gmail' },
  { 'alt A', 'Claude' },
  { 'alt shift A', 'Calendar' },
  { 'alt S', 'Safari' },
  { 'alt D', 'Drafts' },
  { 'alt shift D', 'Day One' },
  { 'alt F', 'Finder' },
  { 'alt G', 'Telegram' },
  { 'alt shift G', 'Google Gemini' },
  { 'alt H', 'Dash' },
  { 'alt J', 'jhentai' },
  { 'alt K', 'Ghostty' },
  { 'alt L', 'Dictionaries' },
  { 'alt Z', 'Zen' },
  { 'alt X', 'Google Chrome' },
  { 'alt shift X', 'Figma' },
  { 'alt C', 'Firefox' },
  { 'alt shift C', 'Brave Browser' },
  { 'alt V', 'View' },
  { 'alt B', 'Obsidian' },
  { 'alt N', 'Discord' },
  { 'alt M', 'Messages' },
}

hs.fnutils.each(appBindings, function(binding)
  local key = binding[1]
  local appName = binding[2]

  bind(key, function()
    hs.application.launchOrFocus(appName)
    local app = hs.application.get(appName)
    if app then
      app:activate(true)
    end
  end)
end)

bind('ctrl alt R', function()
  local win = hs.window.find('Android Device')
  if win then
    win:focus()
  end
end)

local fullscreenedWindow = nil

local wf_all = wf.new(true)
wf_all:subscribe(wf.windowFullscreened, function(w)
  fullscreenedWindow = w
end)
wf_all:subscribe(wf.windowUnfullscreened, function(w)
  fullscreenedWindow = nil
end)

bind('ctrl alt 0', function()
  if fullscreenedWindow then
    fullscreenedWindow:focus()
  end
end)
