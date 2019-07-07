window = hs.window
mouse = hs.mouse
moon = require 'moon'
logger = hs.logger.new('main', 'verbose')

window.animationDuration = 0

bind = (keys, message, fn) ->
    if message == nil or type(message) == 'function'
        -- Shift down arguments
        fn = message
        message = nil

    mods = hs.fnutils.split(keys, '%s+')
    key = table.remove(mods, rawlen(mods))
    hs.hotkey.bind(mods, key, message, fn)

bind 'cmd H', ->
    hs.hints.windowHints()

bind 'shift alt F', 'Maximize window', ->
    window.focusedWindow()\maximize()

bind 'shift alt K', 'Move window to North screen', ->
    hs.window.focusedWindow()\moveOneScreenNorth()

bind 'shift alt J', 'Move window to South screen', ->
    window.focusedWindow()\moveOneScreenSouth()

bind 'alt ctrl K', 'Move mouse pointer to North screen', ->
    mainScreen = hs.screen.mainScreen()
    northScreen = mainScreen\toNorth()
    return unless northScreen

    point = mouse.getRelativePosition()
    point = {
        x: point.x * (northScreen\fullFrame().w / mainScreen\fullFrame().w)
        y: point.y * (northScreen\fullFrame().h / mainScreen\fullFrame().h)
    }
    mouse.setRelativePosition(point, northScreen)
    hs.eventtap.leftClick(mouse.getAbsolutePosition())

bind 'alt ctrl J', 'Move mouse pointer to South screen', ->
    mainScreen = hs.screen.mainScreen()
    southScreen = mainScreen\toSouth()
    return unless southScreen

    point = mouse.getRelativePosition()
    point = {
        x: point.x * (southScreen\fullFrame().w / mainScreen\fullFrame().w)
        y: point.y * (southScreen\fullFrame().h / mainScreen\fullFrame().h)
    }
    mouse.setRelativePosition(point, southScreen)
    hs.eventtap.leftClick(mouse.getAbsolutePosition())

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


-- A watcher must be exported to avoid Lua GC
export appWatcher = hs.application.watcher.new((appName, eventType, app) ->
    if (eventType == hs.application.watcher.activated)
        switch appName
            when 'Finder'
                -- Bring all Finder windows forward when one gets activated
                app\selectMenuItem({'Window', 'Bring All to Front'})
                app\selectMenuItem({'窗口', '前置全部窗口'})

                app\selectMenuItem({'View', 'Clean Up By', 'Kind'})
                app\selectMenuItem({'显示', '整理方式', '种类'})
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
    { 'alt 1', 'Sublime Text' }
    { 'alt 2', 'Visual Studio Code' }
    { 'alt 3', 'MacVim' }
    { 'alt 4', 'Xcode-beta' }
    { 'alt Q', 'QQ' }
    { 'alt W', 'WeChat' }
    { 'alt E', 'Wunderlist' }
    { 'alt R', 'Evernote' }
    { 'alt T', 'Safari Technology Preview' }
    { 'alt Y', 'Typora' }
    { 'alt U', 'UlyssesMac' }
    { 'alt I', 'Dictionary' }
    { 'alt O', 'OmniFocus' }
    { 'alt P', 'Mailplane' }
    { 'alt A', 'Calendar' }
    { 'alt S', 'Safari' }
    { 'alt D', 'Day One' }
    { 'alt F', 'Finder' }
    { 'alt G', 'Telegram' }
    { 'alt H', 'Dash' }
    { 'alt J', 'IntelliJ IDEA CE' }
    { 'alt L', 'Slack' }
    { 'alt C', 'Google Chrome' }
    { 'alt V', 'EIM' }
    { 'alt B', 'MWeb' }
    { 'alt N', 'Simplenote' }
    { 'alt M', 'Messages' }
}

hs.fnutils.each appBindings, (binding) ->
    bind binding[1], ->
        hs.application.launchOrFocus binding[2]
