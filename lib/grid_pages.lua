-- lib/grid_pages.lua | v1.5.11
-- FIX: New Layout, Envelopes, Loopers, Shift Logic

local Pages = {}
local Matrix = require 'ltra/lib/mod_matrix'
local Storage = require 'ltra/lib/storage'
local Scales = require 'ltra/lib/scales'
local Loopers = require 'ltra/lib/loopers'
local Globals
local Consts = require 'ltra/lib/consts'
local HW

function Pages.init(g_ref, hw_ref)
    Globals = g_ref
    HW = hw_ref 
    Matrix.init(g_ref)
    Globals.snap_state = { last_click_time = {}, defer_id = {} }
    Globals.looper_state = { last_click_time = {}, defer_id = {} }
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
    
    -- FIX: Page buttons moved to 13-14
    local page_map = {[13]=1, [14]=2}
    for x=13, 14 do
        local p = page_map[x]
        local b = (Globals.page == p) and Consts.BRIGHT.VAL_HIGH or Consts.BRIGHT.BG_NAV
        led_safe(x, y, b)
    end
    
    -- FIX: Shift Button
    local shift_b = (Globals.button_state[16] and Globals.button_state[16][8]) and Consts.BRIGHT.VAL_HIGH or Consts.BRIGHT.BG_NAV
    led_safe(16, 8, shift_b)
end

local function check_hold()
    if Globals.page ~= 1 then return end
    
    local held_x = nil
    local held_y = nil
    for y=6, 7 do
        for x=1, 16 do
            if Globals.button_state[x] and Globals.button_state[x][y] then 
                held_x = x; held_y = y; break 
            end
        end
        if held_x then break end
    end
    
    if held_x then
        if held_y == 6 then
            if held_x <= 4 then Globals.menu_mode = Consts.MENU.OSC; Globals.menu_target = held_x
            elseif held_x == 13 then Globals.menu_mode = Consts.MENU.DELAY
            elseif held_x == 14 then Globals.menu_mode = Consts.MENU.REVERB
            elseif held_x == 16 then Globals.menu_mode = Consts.MENU.LOOPER 
            end
        elseif held_y == 7 then
            if held_x >= 1 and held_x <= 4 then Globals.menu_mode = Consts.MENU.ENV; Globals.menu_target = held_x -- FIX: ENV Menu
            elseif held_x >= 5 and held_x <= 7 then Globals.menu_mode = Consts.MENU.MOD; Globals.menu_target = held_x - 4
            elseif held_x == 9 then Globals.menu_mode = Consts.MENU.OUTLINE
            elseif held_x == 11 or held_x == 12 then Globals.menu_mode = Consts.MENU.FILTER; Globals.menu_target = (held_x==11 and 1 or 2)
            end
        end
        Globals.dirty = true
        return
    end

    if Globals.button_state[12] and Globals.button_state[12][8] then
        local press_time = Globals.grid_timers[12][8] or 0
        if util.time() - press_time > 0.3 then
            Globals.menu_mode = Consts.MENU.ARP
            Globals.dirty = true
            return
        end
    end

    for y=1, 4 do
        for x=1, 16 do
            if Globals.button_state[x][y] then
                local press_time = Globals.grid_timers[x][y] or 0
                if util.time() - press_time > 0.3 then
                    Globals.menu_mode = Consts.MENU.MATRIX
                    local src_name = ({[1]="MOD1",[2]="MOD2",[3]="MOD3",[4]="OUTLINE"})[y]
                    local dest_name = Consts.COL_TO_DEST_NAMES[x] or "UNK"
                    if dest_name == "DELAY T" then dest_name = "DELAY_T" end
                    if dest_name == "DELAY F" then dest_name = "DELAY_F" end
                    
                    Globals.menu_target = {x=x, y=y, src_name=src_name, dest_name=dest_name} 
                    Globals.dirty = true
                    return
                end
            end
        end
    end

    if Globals.menu_mode ~= Consts.MENU.NONE then 
        Globals.menu_mode = Consts.MENU.NONE; Globals.dirty = true 
    end
end

local function draw_snapshots()
    for i=1, 6 do
        local x = i + 5
        local b = Consts.BRIGHT.BG_NAV 
        if Globals.snapshots[i] then b = Consts.BRIGHT.VAL_MED end 
        led_safe(x, 6, b)
    end
end

local function draw_loopers()
    for i=1, 4 do
        local x = i + 6
        local state = Globals.loopers[i].state
        local b = Consts.BRIGHT.BG_NAV
        if state == 1 then b = Consts.BRIGHT.VAL_PEAK -- Rec
        elseif state == 2 then b = Consts.BRIGHT.VAL_MED -- Play
        elseif state == 3 then b = Consts.BRIGHT.VAL_HIGH -- Dub
        end
        led_safe(x, 8, b)
    end
end

function Pages.redraw()
    if not HW then return end
    check_hold()
    
    if Globals.page == 1 then
        Matrix.draw(HW, led_safe)
        
        for i=1, 4 do led_safe(i, 6, Consts.BRIGHT.BG_DASHBOARD) end
        draw_snapshots() 
        led_safe(13, 6, Consts.BRIGHT.BG_DASHBOARD)
        led_safe(14, 6, Consts.BRIGHT.BG_DASHBOARD)
        led_safe(16, 6, Consts.BRIGHT.BG_DASHBOARD) 
        
        -- FIX: Row 7 Layout (ENV, MOD, Outline, Filter)
        for i=1, 4 do led_safe(i, 7, 1) end -- ENV
        
        local mod1 = math.floor(util.linlin(-1, 1, 2, 13, Globals.visuals.mod_vals[1] or 0))
        led_safe(5, 7, mod1)
        local mod2 = math.floor(util.linlin(-1, 1, 2, 13, Globals.visuals.mod_vals[2] or 0))
        led_safe(6, 7, mod2)
        local mod3 = math.floor(util.linlin(-1, 1, 2, 13, Globals.visuals.mod_vals[3] or 0))
        led_safe(7, 7, mod3)
        
        local outline_val = math.floor(util.linlin(0, 1, 2, 13, Globals.visuals.outline_val or 0))
        led_safe(9, 7, outline_val)
        
        led_safe(11, 7, Consts.BRIGHT.BG_DASHBOARD)
        led_safe(12, 7, Consts.BRIGHT.BG_DASHBOARD)
        
        draw_loopers()
    end
    
    if Globals.page == 2 then
        for x=1, 16 do 
            led_safe(x, 1, (Globals.scale.current_idx == x) and 11 or 2) 
            local u_idx = x + 16
            local is_mod = Globals.scale.custom_slots[x] and Globals.scale.custom_slots[x].modified
            local b = is_mod and 6 or 1
            if Globals.scale.current_idx == u_idx then b = 11 end
            led_safe(x, 2, b)
        end
        
        local blacks = {false, true, false, true, false, false, true, false, true, false, true, false}
        for i=1, 12 do
            local x = i + 2
            local note = i - 1
            local is_active = Scales.is_note_active(note)
            if not blacks[i] then 
                local b = is_active and Consts.BRIGHT.VAL_HIGH or Consts.BRIGHT.VAL_MED
                led_safe(x, 5, b) 
            end
            if blacks[i] then 
                local b = is_active and Consts.BRIGHT.VAL_HIGH or Consts.BRIGHT.BG_MATRIX_B
                led_safe(x, 4, b) 
            end
        end
        led_safe(Globals.scale.root_note + 2, 6, 11)
    end
    
    draw_nav_bar()
end

function Pages.key(x, y, z)
    if z==1 then Globals.grid_timers[x][y] = util.time() end
    local shift = Globals.button_state[16] and Globals.button_state[16][8]
    
    if y == 8 then
        if x == 5 and z == 1 then
            Globals.latch_mode = not Globals.latch_mode
            if not Globals.latch_mode then
                local Bridge = require 'ltra/lib/engine_bridge'
                for i=1, 4 do 
                    Globals.voices[i].latched = false 
                    Bridge.set_gate(i, 0)
                end
            end
            Globals.dirty = true; return
        end
        if x == 12 and z == 0 then
            local press_time = Globals.grid_timers[x][y] or 0
            if util.time() - press_time < 0.3 then
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
        end
        
        if x <= 4 then
            local Bridge = require 'ltra/lib/engine_bridge'
            if z == 1 then
                if Globals.latch_mode then
                    if Globals.voices[x].latched then
                        Globals.voices[x].latched = false
                        Bridge.set_gate(x, 0)
                    else
                        Globals.voices[x].latched = true
                        Bridge.set_gate(x, 1)
                    end
                else
                    Bridge.set_gate(x, 1)
                end
            else
                if not Globals.latch_mode then
                    Bridge.set_gate(x, 0)
                end
            end
            return
        end
        
        -- FIX: Loopers Logic
        if x >= 7 and x <= 10 then
            if z == 0 then
                local idx = x - 6
                local press_time = Globals.grid_timers[x][y]
                local duration = util.time() - press_time
                
                if duration >= 1.0 then
                    Loopers.clear(idx)
                else
                    local now = util.time()
                    local last = Globals.looper_state.last_click_time[idx] or 0
                    Globals.looper_state.last_click_time[idx] = now
                    
                    if (now - last) < 0.4 then
                        if Globals.looper_state.defer_id[idx] then clock.cancel(Globals.looper_state.defer_id[idx]) end
                        Loopers.handle_button(idx, true) -- Double click = Stop
                    else
                        Globals.looper_state.defer_id[idx] = clock.run(function()
                            clock.sleep(0.4)
                            Loopers.handle_button(idx, shift)
                        end)
                    end
                end
            end
            return
        end
        
        if x >= 13 and x <= 14 and z == 1 then
            local page_map = {[13]=1,[14]=2}
            if page_map[x] then Globals.page = page_map[x]; Globals.dirty = true end
            return
        end
    end
    
    if Globals.page == 1 then
        if y <= 4 then 
            if z == 0 then
                local press_time = Globals.grid_timers[x][y] or 0
                if util.time() - press_time < 0.3 then
                    -- FIX: Shift + Matrix = Reset
                    if shift then
                        local src_name = ({[1]="MOD1",[2]="MOD2",[3]="MOD3",[4]="OUTLINE"})[y]
                        local dest_name = Consts.COL_TO_DEST_NAMES[x] or "UNK"
                        local id = "mat_"..src_name.."_"..dest_name
                        params:set(id, 0)
                    else
                        Matrix.key(x, y, 1) 
                        
                        local src_name = ({[1]="MOD1",[2]="MOD2",[3]="MOD3",[4]="OUTLINE"})[y]
                        local dest_name = Consts.COL_TO_DEST_NAMES[x] or "UNK"
                        if dest_name == "DELAY T" then dest_name = "DELAY_T" end
                        if dest_name == "DELAY F" then dest_name = "DELAY_F" end
                        
                        local src_idx = Consts.SOURCES[src_name]
                        local val = Globals.matrix[src_idx][x]
                        
                        local q_str = ""
                        if x <= 4 then 
                            q_str = (Globals.matrix_quant[src_idx][x] == 1) and "[Q]" or "[F]"
                        end
                        
                        Globals.ui_popup.active = true
                        Globals.ui_popup.text = src_name.." > "..dest_name
                        Globals.ui_popup.val = string.format("%.2f %s", val, q_str)
                        Globals.ui_popup.deadline = util.time() + 1.5
                        Globals.dirty = true
                    end
                end
            end
        end
        if y == 6 and x >= 6 and x <= 11 then
            if z == 0 then
                local snap_idx = x - 5
                local press_time = Globals.grid_timers[x][y]
                local duration = util.time() - press_time
                local is_filled = (Globals.snapshots[snap_idx] ~= nil)
                
                if duration >= 0.8 then
                    if is_filled then
                        Storage.save_snapshot(snap_idx)
                        Globals.ui_popup.active = true; Globals.ui_popup.text = "SNAP "..snap_idx; Globals.ui_popup.val = "UPDATED"; Globals.ui_popup.deadline = util.time() + 1.5; Globals.dirty = true
                    end
                else
                    local now = util.time()
                    local last = Globals.snap_state.last_click_time[snap_idx] or 0
                    Globals.snap_state.last_click_time[snap_idx] = now
                    
                    if (now - last) < 0.4 then
                        if Globals.snap_state.defer_id[snap_idx] then clock.cancel(Globals.snap_state.defer_id[snap_idx]) end
                        if is_filled then
                            Storage.delete_snapshot(snap_idx)
                            Globals.ui_popup.active = true; Globals.ui_popup.text = "SNAP "..snap_idx; Globals.ui_popup.val = "DELETED"; Globals.ui_popup.deadline = util.time() + 1.5; Globals.dirty = true
                        end
                    else
                        Globals.snap_state.defer_id[snap_idx] = clock.run(function()
                            clock.sleep(0.4)
                            if not is_filled then
                                Storage.save_snapshot(snap_idx)
                                Globals.ui_popup.active = true; Globals.ui_popup.text = "SNAP "..snap_idx; Globals.ui_popup.val = "SAVED"; Globals.ui_popup.deadline = util.time() + 1.5; Globals.dirty = true
                            else
                                Storage.load_snapshot(snap_idx)
                                Globals.ui_popup.active = true; Globals.ui_popup.text = "SNAP "..snap_idx; Globals.ui_popup.val = "LOADED"; Globals.ui_popup.deadline = util.time() + 1.5; Globals.dirty = true
                            end
                        end)
                    end
                end
            end
        end
    end
    
    if Globals.page == 2 then
        if y == 1 and z == 1 then 
            params:set("scale_idx", x)
        end
        if y == 2 and z == 1 then 
            params:set("scale_idx", x + 16)
        end
        if y == 6 and z == 1 and x>=3 and x<=14 then 
            params:set("scale_root", x - 2)
        end
        if z == 1 and (y == 4 or y == 5) and x >= 3 and x <= 14 then
            local note = x - 3 
            if Globals.scale.current_idx <= 16 then
                params:set("scale_idx", Globals.scale.current_idx + 16)
            end
            Scales.toggle_custom_note(note)
            Scales.update_all_voices()
        end
    end
end

return Pages
