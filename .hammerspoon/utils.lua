local M = {}

--- 将窗口放入指定的“活动区域”内，并根据重力吸附
-- @param win   hs.window 对象
-- @param rules table 配置规则 (所有字段均为可选):
--    {
--       -- [尺寸设定]
--       w = 800,     -- 指定宽度 (数字)。如果不填(nil)，则尝试填满活动区域宽度
--       h = 600,     -- 指定高度 (数字)。如果不填(nil)，则尝试填满活动区域高度
--
--       -- [活动区域缩进 / 边距]
--       top = 0,     -- 顶部避让距离 (例如避让菜单栏或留空)
--       bottom = 0,  -- 底部避让距离 (例如避让 Dock)
--       left = 0,    -- 左侧避让距离
--       right = 0    -- 右侧避让距离
--    }
-- @param anchor string 重力锚点/对齐方式:
--    "top-left" (默认), "top-right", "bottom-left", "bottom-right",
--    "center", "left", "right", "top", "bottom"
function M.fitBox(win, rules, anchor)
  if not win then
    return
  end
  local screen = win:screen()
  if not screen then
    return
  end

  -- 0. 初始化默认值
  rules = rules or {}
  anchor = anchor or 'top-left'
  local screenRect = screen:fullFrame()

  -- 1. 定义“活动区域” (Playground)
  -- 也就是：窗口允许存在的最大范围 (屏幕 - 边距)
  local playground = {
    x = screenRect.x + (rules.left or 0),
    y = screenRect.y + (rules.top or 0),
    w = screenRect.w - (rules.left or 0) - (rules.right or 0),
    h = screenRect.h - (rules.top or 0) - (rules.bottom or 0),
  }

  -- 2. 确定“目标尺寸”
  -- 如果 rules 里指定了 w/h，就用指定的；
  -- 否则，默认让窗口“膨胀”去填满整个活动区域
  local targetW = rules.w or playground.w
  local targetH = rules.h or playground.h

  -- 3. 应用尺寸 (先变身)
  -- 关键是让 App 尝试变成这个大小 (并触发 App 可能存在的最大宽高限制)
  win:setFrame({ x = playground.x, y = playground.y, w = targetW, h = targetH })

  -- 4. 回马枪：读取 App 实际响应后的真实尺寸 (Real Size)
  local realFrame = win:frame()

  -- 5. 应用“重力” (在活动区域内吸附)
  -- 这里的计算基准是 playground，而不是 screen

  -- [垂直方向 Y]
  if string.find(anchor, 'bottom') then
    -- 贴底：活动区域底部 - 真实高度
    realFrame.y = (playground.y + playground.h) - realFrame.h
  elseif string.find(anchor, 'center') then
    -- 垂直居中
    realFrame.y = playground.y + (playground.h - realFrame.h) / 2
  else
    -- 默认贴顶
    realFrame.y = playground.y
  end

  -- [水平方向 X]
  if string.find(anchor, 'right') then
    -- 贴右：活动区域右边 - 真实宽度
    realFrame.x = (playground.x + playground.w) - realFrame.w
  elseif string.find(anchor, 'center') then
    -- 水平居中
    realFrame.x = playground.x + (playground.w - realFrame.w) / 2
  else
    -- 默认贴左
    realFrame.x = playground.x
  end

  -- 6. 应用最终位置
  win:setFrame(realFrame)
end

return M
