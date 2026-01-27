-- code/ltra/lib/grid_pages.lua | v0.7
local Pages = {}
local Matrix = require 'ltra/lib/mod_matrix'
local Globals
local Consts = require 'ltra/lib/consts'
local Bridge = require 'ltra/lib/engine_bridge'
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
    
    -- Triggers (1-4)
    for i=1, 4 do 
        local b = Consts.BRIGHT.BG_TRIGGERS
        if Globals.voices[i].latched then b = Consts.BRIGHT.VAL_HIGH end -- Latched visual
        led_safe(i, y, b) 
    end
    
    -- LATCH Button (5)
    local latch_b = Globals.latch_mode and Consts.BRIGHT.VAL_HIGH or Consts.BRIGHT.BG_NAV
    led_safe(5, y, latch_b)
    
    -- Pages
    local page_map = {[13]=1, [14]=2, [15]=3}
    for x=13, 15 do
        local p = page_map[x]
        local b = (Globals.page == p) and Consts.BRIGHT.VAL_HIGH or Consts.BRIGHT.BG_NAV
        led_safe(x, y, b)
    end
end

-- ... (draw_dashboard y draw_loopers igual que v0.6) ...
-- Para ahorrar espacio, asumo que esas funciones no cambian, solo draw_nav_bar y key

local function draw_dashboard()
    local y = 6
    for i=1, 4 do led_safe(i, y, Consts.BRIGHT.BG_DASHBOARD) end
    local lfo1 = math.floor(util.linlin(-1, 1, 2, 13, Globals.visuals.lfo_vals[1] or 0))
    led_safe(6, 6, lfo1); local lfo2 = math.floor(util.linlin(-1, 1, 2, 13, Globals.visuals.lfo_vals[2] or 0))
    led_safe(7, 6, lfo2)
    led_safe(8, 6, Consts.BRIGHT.BG_DASHBOARD); led_safe(9, 6, Consts.BRIGHT.BG_DASHBOARD) 
    for i=11, 13 do led_safe(i, y, Consts.BRIGHT.BG_DASHBOARD) end
end

local function draw_loopers()
    local heads = Globals.visuals.tape_heads
    for t=1, 3 do
        local offset = (t-1)*5
        local pos_float = (heads[t] or 0) * 5
        local idx = math.floor(pos_float)
        local frac = pos_float - idx
        for c=1, 5 do
            local x = c + offset
            local b = Consts.BRIGHT.BG_NAV
            if c == idx + 1 then b = math.floor(2 + (13 * (1.0 - frac)))
            elseif c == idx + 2 then b = math.floor(2 + (13 * frac)) end
            led_safe(x, 1, b)
            for r=2, 4 do led_safe(x, r, 2) end
        end
    end
end

function Pages.redraw()
    if not HW then return end
    if Globals.page == 1 then
        Matrix.draw(HW, led_safe)
        draw_dashboard()
    elseif Globals.page == 2 then
        for x=1, 16 do led_safe(x, 1, (x==Globals.scale.current_idx) and 11 or 2) end
        local blacks = {false, true, false, true, false, false, true, false, true, false, true, false}
        for i=1, 12 do
            local x = i + 2
            if not blacks[i] then led_safe(x, 5, Consts.BRIGHT.VAL_MED) end
            if blacks[i] then led_safe(x, 4, Consts.BRIGHT.BG_MATRIX_B) end
        end
        led_safe(Globals.scale.root_note + 2, 6, 11)
    elseif Globals.page == 3 then
        draw_loopers()
    end
    draw_nav_bar()
end

function Pages.key(x, y, z)
    if z==1 then Globals.grid_timers[x][y] = util.time() end
    
    -- ROW 8: PERFORMANCE
    if y == 8 then
        -- LATCH BUTTON (5)
        if x == 5 and z == 1 then
            Globals.latch_mode = not Globals.latch_mode
            -- Si activamos Latch, comprobar si hay triggers pulsados para engancharlos
            if Globals.latch_mode then
                for i=1, 4 do
                    if Globals.button_state[i][8] then Globals.voices[i].latched = true end
                end
            end
            Globals.dirty = true
            return
        end
        
        -- TRIGGERS (1-4)
        if x <= 4 then
            if z == 1 then -- Press
                Bridge.set_gate(x, 1)
                -- Si Latch Mode ON, enganchar
                if Globals.latch_mode then Globals.voices[i].latched = true end
            else -- Release
                -- Si NO está latched, soltar
                if not Globals.voices[x].latched then
                    Bridge.set_gate(x, 0)
                else
                    -- Si ESTÁ latched, pero Latch Mode OFF, desenganchar
                    if not Globals.latch_mode then
                        Globals.voices[x].latched = false
                        Bridge.set_gate(x, 0)
                    end
                end
            end
            return
        end
        
        -- PAGES (13-15)
        if x >= 13 and z == 1 then
            local page_map = {[13]=1, [14]=2, [15]=3}
            if page_map[x] then Globals.page = page_map[x]; Globals.dirty = true end
            return
        end
    end
    
    if Globals.page == 1 and y <= 4 then Matrix.key(x, y, z) end
    
    -- (Resto de lógica de páginas Scales/Loopers igual que v0.6)
end

return Pages
