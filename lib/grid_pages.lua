-- code/ltra/lib/grid_pages.lua | v1.3
-- LTRA: Grid Views
-- FIX: Hold Logic Robustness

local Pages = {}
local Matrix = require 'ltra/lib/mod_matrix'
local Loopers = require 'ltra/lib/loopers'
local Storage = require 'ltra/lib/storage'
local Scales = require 'ltra/lib/scales'
local Globals
local Consts = require 'ltra/lib/consts'
local HW

function Pages.init(g_ref, hw_ref)
    Globals = g_ref
    HW = hw_ref 
    Matrix.init(g_ref)
end

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
    for i=1, 4 do 
        local b = Consts.BRIGHT.BG_TRIGGERS
        if Globals.voices[i].latched then b = Consts.BRIGHT.VAL_HIGH end
        led_safe(i, y, b) 
    end
    local latch_b = Globals.latch_mode and Consts.BRIGHT.VAL_HIGH or Consts.BRIGHT.BG_NAV
    led_safe(5, y, latch_b)
    led_safe(12, y, Consts.BRIGHT.BG_NAV)
    local page_map = {[13]=1, [14]=2, [15]=3}
    for x=13, 15 do
        local p = page_map[x]
        local b = (Globals.page == p) and Consts.BRIGHT.VAL_HIGH or Consts.BRIGHT.BG_NAV
        led_safe(x, y, b)
    end
end

local function check_hold()
    -- Solo comprobar Hold en Página 1 (Dashboard)
    if Globals.page ~= 1 then 
        if Globals.menu_mode ~= Consts.MENU.NONE then
            Globals.menu_mode = Consts.MENU.NONE
            Globals.dirty = true
        end
        return 
    end

    local y = 6
    local held = nil
    for x=1, 16 do
        if Globals.button_state[x] and Globals.button_state[x][y] then held = x; break end
    end
    
    if held then
        local new_mode = Consts.MENU.NONE
        if held <= 4 then new_mode = Consts.MENU.OSC; Globals.menu_target = held
        elseif held == 13 then new_mode = Consts.MENU.DELAY
        elseif held == 14 then new_mode = Consts.MENU.REVERB
        elseif held == 11 or held == 12 then new_mode = Consts.MENU.FILTER; Globals.menu_target = (held==11 and 1 or 2)
        elseif held == 6 or held == 7 then new_mode = Consts.MENU.LFO; Globals.menu_target = (held==6 and 1 or 2)
        end
        
        if new_mode ~= Globals.menu_mode then
            Globals.menu_mode = new_mode
            Globals.dirty = true
        end
    else
        if Globals.menu_mode ~= Consts.MENU.NONE and Globals.menu_mode ~= Consts.MENU.LOOPER then 
            Globals.menu_mode = Consts.MENU.NONE
            Globals.dirty = true 
        end
    end
end

-- ... (draw_loopers, draw_snapshots, redraw, key se mantienen igual que v1.0.1)
-- Asegúrate de copiar el resto del archivo v1.0.1 aquí si no lo tienes a mano, 
-- o usa el bloque completo anterior.
-- Para seguridad, incluyo redraw y key completos:

local function draw_loopers()
    local heads = Globals.visuals.tape_heads
    local now = util.time()
    for t=1, 3 do
        local offset = (t-1)*5
        local pos_float = (heads[t] or 0) * 5
        local idx = math.floor(pos_float)
        local frac = pos_float - idx
        local y_tape = (t-1)*2 + 1
        for c=1, 5 do
            local x = c + offset
            local b = Consts.BRIGHT.BG_NAV
            if c == idx + 1 then b = math.floor(2 + (13 * (1.0 - frac))) end
            if c == idx + 2 then b = math.floor(2 + (13 * frac)) end
            led_safe(x, y_tape, b)
        end
        local x_sel = (t-1)*5 + 1
        local state = Globals.tracks[t].state
        local b_sel = Consts.BRIGHT.BG_DASHBOARD
        if state == 2 then b_sel = math.floor(util.linlin(-1, 1, 5, 15, math.sin(now * 5)))
        elseif state == 3 then b_sel = Consts.BRIGHT.VAL_HIGH
        elseif state == 4 then b_sel = math.floor(util.linlin(-1, 1, 5, 15, math.sin(now * 15)))
        elseif state == 5 then b_sel = Consts.BRIGHT.VAL_MED end
        led_safe(x_sel, 6, b_sel)
    end
end

local function draw_snapshots()
    for i=1, 6 do
        local b = Consts.BRIGHT.BG_NAV 
        if Globals.snapshots[i] then b = Consts.BRIGHT.VAL_MED end 
        led_safe(i, 7, b)
    end
end

function Pages.redraw()
    if not HW then return end
    check_hold()
    
    if Globals.page == 1 then
        Matrix.draw(HW, led_safe)
        for i=1, 4 do led_safe(i, 6, Consts.BRIGHT.BG_DASHBOARD) end
        local lfo1 = math.floor(util.linlin(-1, 1, 2, 13, Globals.visuals.lfo_vals[1] or 0))
        led_safe(6, 6, lfo1); local lfo2 = math.floor(util.linlin(-1, 1, 2, 13, Globals.visuals.lfo_vals[2] or 0))
        led_safe(7, 6, lfo2)
        led_safe(8, 6, Consts.BRIGHT.BG_DASHBOARD); led_safe(9, 6, Consts.BRIGHT.BG_DASHBOARD) 
        for i=11, 14 do led_safe(i, 6, Consts.BRIGHT.BG_DASHBOARD) end
        draw_snapshots() 
    end
    
    if Globals.page == 2 then
        for x=1, 16 do led_safe(x, 1, (x==Globals.scale.current_idx) and 11 or 2) end
        local blacks = {false, true, false, true, false, false, true, false, true, false, true, false}
        for i=1, 12 do
            local x = i + 2
            if not blacks[i] then led_safe(x, 5, Consts.BRIGHT.VAL_MED) end
            if blacks[i] then led_safe(x, 4, Consts.BRIGHT.BG_MATRIX_B) end
        end
        led_safe(Globals.scale.root_note + 2, 6, 11)
    end
    
    if Globals.page == 3 then
        draw_loopers()
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

function Pages.key(x, y, z)
    if z==1 then Globals.grid_timers[x][y] = util.time() end
    
    if y == 8 then
        if x == 5 and z == 1 then
            Globals.latch_mode = not Globals.latch_mode
            if Globals.latch_mode then
                for i=1, 4 do if Globals.button_state[i][8] then Globals.voices[i].latched = true end end
            end
            Globals.dirty = true; return
        end
        if x == 12 and z == 1 then
            local now = util.time()
            if Globals.tap_last then
                local diff = now - Globals.tap_last
                if diff > 0.1 and diff < 2.0 then
                    local bpm = 60 / diff
                    params:set("clock_tempo", bpm)
                    Globals.ui_popup.active = true; Globals.ui_popup.text = "TAP BPM"; Globals.ui_popup.val = string.format("%.1f", bpm); Globals.ui_popup.deadline = now + 1
                    Globals.dirty = true
                end
            end
            Globals.tap_last = now; return
        end
        if x <= 4 then
            local Bridge = require 'ltra/lib/engine_bridge'
            if z == 1 then 
                Bridge.set_gate(x, 1)
                if Globals.latch_mode then Globals.voices[x].latched = true end
            else 
                if not Globals.voices[x].latched then Bridge.set_gate(x, 0)
                elseif not Globals.latch_mode then Globals.voices[x].latched = false; Bridge.set_gate(x, 0) end
            end
            return
        end
        if x >= 13 and z == 1 then
            local page_map = {[13]=1, [14]=2, [15]=3}
            if page_map[x] then Globals.page = page_map[x]; Globals.dirty = true end
            return
        end
    end
    
    if Globals.page == 1 then
        if y <= 4 then Matrix.key(x, y, z) end
        if y == 7 and x <= 6 then
            if z == 1 then Storage.load_snapshot(x)
            else
                local press_time = Globals.grid_timers[x][y]
                if util.time() - press_time > 1.0 then Storage.save_snapshot(x) end
            end
        end
    end
    
    if Globals.page == 2 then
        if y == 1 and z == 1 then Globals.scale.current_idx = x; Globals.dirty=true end
        if y == 6 and z == 1 and x>=3 and x<=14 then Globals.scale.root_note = x - 2; Globals.dirty=true end
        if z == 1 and (y == 4 or y == 5) and x >= 3 and x <= 14 then
            local note = x - 3 
            Scales.toggle_custom_note(note)
        end
    end
    
    if Globals.page == 3 then
        if y == 1 then Loopers.handle_grid_input(1, x, z) end
        if y == 3 then Loopers.handle_grid_input(2, x, z) end
        if y == 5 then Loopers.handle_grid_input(3, x, z) end
        if y == 6 and z == 1 then
            if x == 1 then Loopers.transport_action(1, "press") end
            if x == 6 then Loopers.transport_action(2, "press") end
            if x == 11 then Loopers.transport_action(3, "press") end
        end
    end
end

return Pages
