window = hs.window
mouse = hs.mouse
logger = hs.logger.new('main', 'verbose')
wf = hs.window.filter

-- Use Fn + h/l/j/k as arrow keys, y/u/i/o as mouse wheel, ,/. as left/right click.
hs.loadSpoon 'FnMate'

window.animationDuration = 0

bind = (keys, message, fn) ->
    if message == nil or type(message) == 'function'
        -- Shift down arguments
        fn = message
        message = nil

    mods = hs.fnutils.split(keys, '%s+')
    key = table.remove(mods, rawlen(mods))
    hs.hotkey.bind(mods, key, message, fn)

yabai = (args) ->
    -- FIXME
    -- if hs.fs.attributes('/opt/homebrew/bin/yabai') != nil
    yabai_cmd = '/opt/homebrew/bin/yabai'
    -- else
        -- yabai_cmd = '/usr/local/bin/yabai'
    hs.task.new(yabai_cmd, nil, args)\start()

bind 'cmd H', ->
    hs.hints.windowHints()

bind 'shift alt F', 'Maximize window', ->
    window.focusedWindow()\maximize()

bind 'shift alt H', 'Move window to West screen', ->
    window.focusedWindow()\moveOneScreenWest()

bind 'shift alt K', 'Move window to North screen', ->
    window.focusedWindow()\moveOneScreenNorth()

bind 'shift alt J', 'Move window to South screen', ->
    window.focusedWindow()\moveOneScreenSouth()

bind 'shift alt L', 'Move window to East screen', ->
    window.focusedWindow()\moveOneScreenEast()
    window.focusedWindow()\moveOneScreenEast()

-- Conflict with non-ctrl keys
bind 'shift alt ctrl H', 'Move window to West space', ->
    log.d window.focusedWindow()\title()
    log.d window.focusedWindow()\id()
    yabai {'-m', 'window', "#{window.focusedWindow()\id()}", '--space',  'prev'}

bind 'shift alt ctrl L', 'Move window to East space', ->
    log.d window.focusedWindow()\title()
    log.d window.focusedWindow()\id()
    yabai {'-m', 'window', "#{window.focusedWindow()\id()}", '--space', 'next'}

moveMousePointerToScreen = (direction) ->
    mainScreen = hs.screen.mainScreen()
    -- Use different algorithms for different screens layout
    newScreen = switch direction
        when 'West'
            mainScreen\toWest()
        when 'South'
            mainScreen\toSouth()
        when 'North'
            mainScreen\toNorth()
        when 'East'
            mainScreen\toEast()

    return unless newScreen

    point = mouse.getRelativePosition()
    point = {
        x: point.x * (newScreen\fullFrame().w / mainScreen\fullFrame().w)
        y: point.y * (newScreen\fullFrame().h / mainScreen\fullFrame().h)
    }
    mouse.setRelativePosition(point, newScreen)
    hs.eventtap.leftClick(mouse.getAbsolutePosition())

bind 'alt ctrl H', 'Move mouse pointer to West screen', ->
    moveMousePointerToScreen('West')

bind 'alt ctrl K', 'Move mouse pointer to North screen', ->
    moveMousePointerToScreen('North')

bind 'alt ctrl J', 'Move mouse pointer to South screen', ->
    moveMousePointerToScreen('South')

bind 'alt ctrl L', 'Move mouse pointer to East screen', ->
    moveMousePointerToScreen('East')

bind 'shift ctrl cmd L', 'Rotate DELL P2715Q screen 0', ->
    hs.screen('DELL P2715Q')\rotate(0)

bind 'shift ctrl cmd P', 'Rotate DELL P2715Q screen 90', ->
    hs.screen('DELL P2715Q')\rotate(90)

bind 'shift ctrl cmd K', 'Set North screen as primary', ->
    northScreen = hs.screen.primaryScreen()\toNorth()
    northScreen\setPrimary() if northScreen

bind 'shift ctrl cmd J', 'Set South screen as primary', ->
    southScreen = hs.screen.primaryScreen()\toSouth()
    southScreen\setPrimary() if southScreen

-- Download Twitter Media
bind 'ctrl cmd T', ->
    hs.eventtap.keyStroke({'shift', 'cmd'}, 'C', 100000, hs.application.frontmostApplication())
    hs.eventtap.keyStroke({'cmd'}, 'B', 100000, hs.application.frontmostApplication())
    hs.eventtap.keyStroke({'ctrl', 'shift', 'cmd'}, 'T', 100000, hs.application.frontmostApplication())

-- Activate first window when switching to a new space
for i=0, 9
    hs.hotkey.bind {"ctrl"}, tostring(i), ->
        hs.eventtap.keyStroke {"ctrl"}, tostring(i)
        hs.timer.doAfter 0.1, ->

            logger.d "Switch to space #{i}"
            windows = hs.window.orderedWindows!
            windows[1]\focus! if #windows > 0

-- A watcher must be exported to avoid Lua GC
export appWatcher = hs.application.watcher.new((appName, eventType, app) ->
    if (eventType == hs.application.watcher.activated)
        logger.d "App #{appName} activated"
        switch appName
            when 'Finder'
                -- Bring all Finder windows forward when one gets activated
                app\selectMenuItem({'Window', 'Bring All to Front'})
                app\selectMenuItem({'窗口', '前置全部窗口'})

                app\selectMenuItem({'View', 'Clean Up By', 'Kind'})
                app\selectMenuItem({'显示', '整理方式', '种类'})

                rect = app\focusedWindow()\frame()
                rect.h = 850
                rect.w = 1250
                app\focusedWindow()\setFrame(rect)

            -- when 'Dash', 'iTerm2', 'kitty', 'MacVim', 'VimR'
            when 'Dash', 'kitty', 'MacVim', 'VimR'
                logger.d app\focusedWindow()\screen()
                if app\focusedWindow()\screen() != hs.screen('DELL P2715Q')
                    app\focusedWindow()\maximize()
                else
                    rect = app\focusedWindow()\screen()\frame()
                    rect.h = rect.h - 200
                    logger.d rect
                    app\focusedWindow()\setFrame(rect)
            when 'Twitter'
                if app\focusedWindow()\screen() == hs.screen('DELL U2720Q') or
                    app\focusedWindow()\screen() == hs.screen('DELL S2721QS')
                    rect = app\focusedWindow()\screen()\frame()
                    rect.x = rect.w - 900
                    rect.w = 900
                    logger.d rect
                    app\focusedWindow()\setFrame(rect)
            when 'Collins Dictionary'
                app\selectMenuItem({'Search', 'Type new search'})
)\start()

export finderWatcher = hs.appfinder.appFromName('Finder')\newWatcher((element) ->
    element\application()\selectMenuItem({'View', 'Clean Up By', 'Kind'})
    element\application()\selectMenuItem({'显示', '整理方式', '种类'})
)\start({hs.uielement.watcher.focusedWindowChanged})

export screenWatcher = hs.screen.watcher.new(->
    logger.d 'Screen layout changed'
    logger.d "#{hs.screen.primaryScreen()\name()} is primary screen"
)\start()

appBindings = {
    { 'alt 1', 'Cursor' }
    { 'alt 2', 'VimR' }
    { 'alt 3', 'MacVim' }
    { 'alt 4', 'Xcode.app' }
    { 'alt Q', 'QQ' }
    { 'alt W', 'WeChat' }
    { 'alt E', 'Elpass' }
    { 'alt R', 'MuMu安卓设备' }
    { 'alt shift R', 'MuMu模拟器Pro' }
    { 'alt T', 'ChatGPT' }
    { 'alt Y', 'Typora' }
    { 'alt U', 'Ulysses' }
    { 'alt I', 'iPhone Mirroring' }
    { 'alt O', 'Discord' }
    { 'alt P', 'Gmail' }
    { 'alt A', 'Calendar' }
    { 'alt S', 'Safari' }
    { 'alt D', 'Drafts' }
    { 'alt shift D', 'Day One' }
    { 'alt F', 'Finder' }
    { 'alt G', 'Telegram' }
    { 'alt H', 'Dash' }
    { 'alt J', 'IntelliJ IDEA CE' }
    { 'alt K', 'kitty' }
    { 'alt L', 'Dictionaries' }
    { 'alt X', 'Arc' }
    { 'alt C', 'Google Chrome' }
    { 'alt B', 'Obsidian' }
    { 'alt N', 'Linear' }
    { 'alt M', 'Messages' }
}


hs.fnutils.each appBindings, (binding) ->
    key = binding[1]
    appName = binding[2]

    bind key, ->
        hs.application.launchOrFocus appName
        app = hs.application.get(appName)
        app\activate(true) if app

fullscreenedWindow = nil

wf_all = wf.new(true)
wf_all\subscribe wf.windowFullscreened, (w) ->
    fullscreenedWindow = w
wf_all\subscribe wf.windowUnfullscreened, (w) ->
    fullscreenedWindow = nil

bind 'ctrl alt 0', ->
    if fullscreenedWindow
        fullscreenedWindow\focus()

-- vim: set sts=4 sw=4:
