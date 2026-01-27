-- code/ltra/lib/grid_pages.lua | v0.6
-- LTRA: Grid Views (Sub-pixel Loopers & Menus)

local Pages = {}
local Matrix = require 'ltra/lib/mod_matrix'
local Globals
local Consts = require 'ltra/lib/consts'
local HW

function Pages.init(g_ref) Globals = g_ref; Matrix.init(g_ref) end
function Pages.set_hw(h) HW = h end

local function led_safe(x, y, val)
    if val > 0 and Globals.button_state[x] and Globals.button_state[x][y] then
        HW.led(x, y, Consts.BRIGHT.TOUCH)
    else
        HW.led(x, y, val)
    end
end

local function draw_nav_bar()
    local y = 8
    for i=1, 4 do led_safe(i, y, Consts.BRIGHT.BG_TRIGGERS) end
    local page_map = {[13]=1, [14]=2, [15]=3}
    for x=13, 15 do
        local p = page_map[x]
        local b = (Globals.page == p) and Consts.BRIGHT.VAL_HIGH or Consts.BRIGHT.BG_NAV
        led_safe(x, y, b)
    end
end

local function check_hold()
    local y = 6
    local held = nil
    for x=1, 16 do
        if Globals.button_state[x] and Globals.button_state[x][y] then held = x; break end
    end
    
    if held then
        if held <= 4 then Globals.menu_mode = Consts.MENU.OSC; Globals.menu_target = held
        elseif held == 13 then Globals.menu_mode = Consts.MENU.DELAY
        elseif held == 14 then Globals.menu_mode = Consts.MENU.REVERB
        elseif held == 11 or held == 12 then Globals.menu_mode = Consts.MENU.FILTER; Globals.menu_target = (held==11 and 1 or 2)
        elseif held == 6 or held == 7 then Globals.menu_mode = Consts.MENU.LFO; Globals.menu_target = (held==6 and 1 or 2)
        -- Loopers (Page 3) handled separately? No, row 6 is always dashboard in Page 1.
        end
        Globals.dirty = true
    else
        if Globals.menu_mode ~= Consts.MENU.NONE then Globals.menu_mode = Consts.MENU.NONE; Globals.dirty = true end
    end
end

local function draw_loopers()
    -- Cintas Horizontales (Filas 1, 3, 5)
    -- Ouroboros Style: Sub-pixel dimming
    local heads = Globals.visuals.tape_heads
    for t=1, 3 do
        local y = (t-1)*2 + 1 -- 1, 3, 5
        local pos_pixel = heads[t] * 15 -- 0 a 15
        local idx = math.floor(pos_pixel) + 1 -- 1 a 16
        local frac = pos_pixel - math.floor(pos_pixel)
        
        for x=1, 16 do
            local b = 0
            -- Fondo tenue en extremos del loop (Implementar visualización loop points luego)
            
            -- Cabezal
            if x == idx then b = math.floor(15 * (1-frac)) end
            if x == idx + 1 then b = math.floor(15 * frac) end
            
            if b > 0 then HW.led(x, y, b) end
        end
    end
    
    -- Fila 6: Selectores de Looper (Para menú contextual)
    for t=1, 3 do
        local x = (t-1)*5 + 1
        led_safe(x, 6, Consts.BRIGHT.BG_DASHBOARD)
    end
end

function Pages.redraw()
    if not HW then return end
    
    if Globals.page == 1 then
        check_hold()
        Matrix.draw(HW, led_safe)
        for i=1, 4 do led_safe(i, 6, Consts.BRIGHT.BG_DASHBOARD) end
        local lfo1 = math.floor(util.linlin(-1, 1, 2, 13, Globals.visuals.lfo_vals[1] or 0))
        led_safe(6, 6, lfo1); led_safe(7, 6, lfo1) -- LFO2 visual missing in globals osc?
        led_safe(13, 6, Consts.BRIGHT.BG_DASHBOARD)
        led_safe(14, 6, Consts.BRIGHT.BG_DASHBOARD)
    end
    
    if Globals.page == 2 then -- Scales
        for x=1, 16 do led_safe(x, 1, (x==Globals.scale.current_idx) and 11 or 2) end
        local blacks = {false, true, false, true, false, false, true, false, true, false, true, false}
        for i=1, 12 do
            local x = i + 2
            if not blacks[i] then led_safe(x, 5, Consts.BRIGHT.VAL_MED) end
            if blacks[i] then led_safe(x, 4, Consts.BRIGHT.BG_MATRIX_B) end
        end
        led_safe(Globals.scale.root_note + 2, 6, 11)
    end
    
    if Globals.page == 3 then -- Loopers
        draw_loopers()
        -- Check hold on Looper Selectors (Row 6)
        local held_looper = nil
        for t=1,3 do 
            local x = (t-1)*5 + 1
            if Globals.button_state[x] and Globals.button_state[x][6] then held_looper = t end
        end
        if held_looper then
            Globals.menu_mode = Consts.MENU.LOOPER; Globals.menu_target = held_looper; Globals.dirty=true
        elseif Globals.menu_mode == Consts.MENU.LOOPER then
            Globals.menu_mode = Consts.MENU.NONE; Globals.dirty=true
        end
    end
    
    draw_nav_bar()
end

function Pages.key(x,y,z)
    if z==1 then Globals.grid_timers[x][y] = util.time() end
    if y==8 and x>=13 and z==1 then Globals.page = ({[13]=1,[14]=2,[15]=3})[x] or 1; Globals.dirty=true; return end
    
    if Globals.page==1 and y<=4 then Matrix.key(x,y,z) end
    if Globals.page==2 then
        if y==1 and z==1 then Globals.scale.current_idx=x; Globals.dirty=true end
        if y==6 and z==1 and x>=3 and x<=14 then Globals.scale.root_note=x-2; Globals.dirty=true end
    end
end
return Pages
