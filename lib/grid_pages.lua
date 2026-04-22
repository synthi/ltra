-- lib/grid_pages.lua | v2.6.0
-- FIX: 3-Row Grid Layout for 48 Scales

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
    Globals.looper_state = { last_click_time = {}, defer_id = {}, press_time = {} }
    Globals.multi_sel = { active = false, row = nil, targets = {} }
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
        if Globals.voices[i].latched then b = Consts.BRIGHT.VAL_HIGH 
        elseif Globals.voices[i].sustained then b = Consts.BRIGHT.VAL_MED 
        elseif Globals.button_state[i] and Globals.button_state[i][8] then b = Consts.BRIGHT.TOUCH end
        led_safe(i, y, b) 
    end
    local latch_b = Globals.latch_mode and Consts.BRIGHT.VAL_HIGH or Consts.BRIGHT.BG_NAV
    led_safe(5, y, latch_b)
    led_safe(12, y, Consts.BRIGHT.BG_NAV)
    
    local page_map = {[13]=1,[14]=2}
    for x=13, 14 do
        local p = page_map[x]
        local b = (Globals.page == p) and Consts.BRIGHT.VAL_HIGH or Consts.BRIGHT.BG_NAV
        led_safe(x, y, b)
    end
    
    local shift_b = (Globals.button_state[16] and Globals.button_state[16][8]) and Consts.BRIGHT.VAL_HIGH or Consts.BRIGHT.BG_NAV
    led_safe(16, 8, shift_b)
end

local function check_hold_single()
    if Globals.page ~= 1 then return end
    
    local held_x = nil
    for x=6, 16 do
        if Globals.button_state[x] and Globals.button_state[x][6] then held_x = x; break end
    end
    
    if held_x then
        if held_x >= 6 and held_x <= 8 then Globals.menu_mode = Consts.MENU.MOD; Globals.menu_target = {held_x - 5}
        elseif held_x == 9 then Globals.menu_mode = Consts.MENU.OUTLINE
        elseif held_x == 11 or held_x == 12 then Globals.menu_mode = Consts.MENU.FILTER; Globals.menu_target = {held_x==11 and 1 or 2}
        elseif held_x == 13 then Globals.menu_mode = Consts.MENU.DELAY
        elseif held_x == 14 then Globals.menu_mode = Consts.MENU.REVERB
        elseif held_x == 16 then Globals.menu_mode = Consts.MENU.LOOPER 
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

    if Globals.menu_mode ~= Consts.MENU.NONE and not Globals.multi_sel.active then 
        Globals.menu_mode = Consts.MENU.NONE; Globals.dirty = true 
    end
end

local function draw_snapshots()
    for i=1, 6 do
        local x = i + 5
        local b = Consts.BRIGHT.BG_NAV 
        if Globals.snapshots[i] then 
            b = Consts.BRIGHT.VAL_MED 
            if Globals.active_snapshot == i then b = Consts.BRIGHT.VAL_PEAK end 
        end 
        led_safe(x, 7, b)
    end
end

local function draw_loopers()
    local now = util.time()
    for i=1, 3 do
        local x = i + 7
        local state = Globals.loopers[i].state
        local b = Consts.BRIGHT.BG_NAV 
        
        if state == 1 or state == 3 then 
            b = math.floor(util.linlin(-1, 1, 5, 15, math.sin(now * 6)))
        elseif state == 2 then 
            b = Consts.BRIGHT.VAL_HIGH
        elseif state == 4 then 
            b = Consts.BRIGHT.VAL_LOW
        elseif state == 5 or state == 6 then 
            b = math.floor(util.linlin(-1, 1, 2, 15, math.sin(now * 15)))
        end
        led_safe(x, 8, b)
    end
end

function Pages.redraw()
    if not HW then return end
    check_hold_single()
    
    if Globals.page == 1 then
        Matrix.draw(HW, led_safe)
        
        for i=1, 4 do led_safe(i, 5, Consts.BRIGHT.BG_DASHBOARD) end 
        for i=1, 4 do led_safe(i, 6, Consts.BRIGHT.BG_DASHBOARD) end 
        
        local mod1 = math.floor(util.linlin(-1, 1, 2, 13, Globals.visuals.mod_vals[1] or 0))
        led_safe(6, 6, mod1)
        local mod2 = math.floor(util.linlin(-1, 1, 2, 13, Globals.visuals.mod_vals[2] or 0))
        led_safe(7, 6, mod2)
        local mod3 = math.floor(util.linlin(-1, 1, 2, 13, Globals.visuals.mod_vals[3] or 0))
        led_safe(8, 6, mod3)
        
        local outline_val = math.floor(util.linlin(0, 1, 2, 13, Globals.visuals.outline_val or 0))
        led_safe(9, 6, outline_val)
        
        led_safe(11, 6, Consts.BRIGHT.BG_DASHBOARD)
        led_safe(12, 6, Consts.BRIGHT.BG_DASHBOARD)
        led_safe(13, 6, Consts.BRIGHT.BG_DASHBOARD)
        led_safe(14, 6, Consts.BRIGHT.BG_DASHBOARD)
        led_safe(16, 6, Consts.BRIGHT.BG_DASHBOARD) 
        
        for i=1, 4 do 
            local b = Consts.BRIGHT.BG_DASHBOARD
            if params:get("osc"..i.."_midi_note") == 1 then
                local vel_main = Globals.midi_voice_vel and Globals.midi_voice_vel[i] or 0
                local vel_twin = Globals.midi_voice_vel and Globals.midi_voice_vel[i+4] or 0
                
                if vel_main > 0 or vel_twin > 0 then
                    local vel_vol = params:get("osc"..i.."_vel_vol") or 0
                    local added_b = 5
                    
                    local active_vel = vel_main > 0 and vel_main or vel_twin
                    if vel_vol > 0 then
                        added_b = math.floor(util.linlin(1, 127, 2, 9, active_vel))
                    end
                    
                    if vel_main > 0 then
                        added_b = added_b + 3
                    end
                    
                    b = util.clamp(b + added_b, 0, 15)
                end
            end
            led_safe(i, 7, b) 
        end
        
        draw_snapshots() 
        draw_loopers()
    end
    
    if Globals.page == 2 then
        local num_predefined = #Consts.SCALES_A + #Consts.SCALES_B
        
        -- Row 1: TET Scales (1-16)
        for x=1, 16 do 
            led_safe(x, 1, (Globals.scale.current_idx == x) and 11 or 2) 
        end
        
        -- FIX: Row 2: Remaining TET + JI Scales (17-32)
        for x=1, 16 do 
            local s_idx = x + 16
            led_safe(x, 2, (Globals.scale.current_idx == s_idx) and 11 or 2) 
        end
        
        -- Row 3: Custom Scales (33-48)
        for x=1, 16 do
            local s_idx = x + num_predefined
            local is_mod = Globals.scale.custom_slots[x] and Globals.scale.custom_slots[x].modified
            local b = is_mod and 6 or 1
            if Globals.scale.current_idx == s_idx then b = 11 end
            led_safe(x, 3, b)
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
    
    if Globals.page == 1 and y >= 5 and y <= 7 and x >= 1 and x <= 4 then
        if z == 1 then
            if not Globals.multi_sel.active then
                Globals.multi_sel.active = true
                Globals.multi_sel.row = y
                Globals.multi_sel.targets = {[x] = true}
                if y == 5 then Globals.menu_mode = Consts.MENU.MIDI
                elseif y == 6 then Globals.menu_mode = Consts.MENU.OSC
                elseif y == 7 then Globals.menu_mode = Consts.MENU.ENV end
            elseif Globals.multi_sel.row == y then
                Globals.multi_sel.targets[x] = not Globals.multi_sel.targets[x]
            end
        else
            local any_held = false
            for i=1, 4 do
                if Globals.button_state[i][y] then any_held = true; break end
            end
            if not any_held and Globals.multi_sel.row == y then
                Globals.multi_sel.active = false
                Globals.multi_sel.row = nil
                Globals.multi_sel.targets = {}
                Globals.menu_mode = Consts.MENU.NONE
            end
        end
        
        if Globals.multi_sel.active then
            local t = {}
            for i=1, 4 do if Globals.multi_sel.targets[i] then table.insert(t, i) end end
            if #t > 0 then Globals.menu_target = t else Globals.menu_target = {x} end
        end
        Globals.dirty = true
        return
    end
    
    if y == 8 then
        if x == 16 and z == 1 then
            local Bridge = require 'ltra/lib/engine_bridge'
            for i=1, 4 do
                if Globals.button_state[i] and Globals.button_state[i][8] then
                    Globals.voices[i].sustained = not Globals.voices[i].sustained
                    if not Globals.voices[i].arp_enabled then
                        Bridge.set_gate(i, Globals.voices[i].sustained and 1 or 0)
                    end
                end
            end
            Globals.dirty = true
        end

        if x == 5 and z == 1 then
            Globals.latch_mode = not Globals.latch_mode
            if not Globals.latch_mode then
                local Bridge = require 'ltra/lib/engine_bridge'
                for i=1, 4 do 
                    Globals.voices[i].latched = false 
                    if not Globals.voices[i].arp_enabled and not Globals.voices[i].sustained then
                        Bridge.set_gate(i, 0)
                    end
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
                if shift then
                    Globals.voices[x].sustained = not Globals.voices[x].sustained
                    if not Globals.voices[x].arp_enabled then
                        Bridge.set_gate(x, Globals.voices[x].sustained and 1 or 0)
                    end
                else
                    if Globals.latch_mode then
                        Globals.voices[x].latched = not Globals.voices[x].latched
                        if not Globals.voices[x].arp_enabled then
                            Bridge.set_gate(x, Globals.voices[x].latched and 1 or 0)
                        end
                    else
                        if not Globals.voices[x].arp_enabled then
                            Bridge.set_gate(x, 1)
                        end
                    end
                end
            else
                if not shift and not Globals.latch_mode and not Globals.voices[x].sustained then
                    if not Globals.voices[x].arp_enabled then
                        Bridge.set_gate(x, 0)
                    end
                end
            end
            Globals.dirty = true
            return
        end
        
        if x >= 8 and x <= 10 then
            local idx = x - 7
            if z == 1 then
                Globals.looper_state.press_time[idx] = util.time()
            else
                local duration = util.time() - Globals.looper_state.press_time[idx]
                if duration > 0.6 then
                    Loopers.stop_looper(idx)
                else
                    local now = util.time()
                    local last = Globals.looper_state.last_click_time[idx] or 0
                    Globals.looper_state.last_click_time[idx] = now
                    
                    if (now - last) < 0.4 then
                        if Globals.looper_state.defer_id[idx] then clock.cancel(Globals.looper_state.defer_id[idx]) end
                        Loopers.clear(idx)
                    else
                        Globals.looper_state.defer_id[idx] = clock.run(function()
                            clock.sleep(0.4)
                            if shift then
                                Loopers.clear(idx)
                            else
                                Loopers.handle_button(idx)
                            end
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
        if y == 7 and x >= 6 and x <= 11 then
            if z == 0 then
                local snap_idx = x - 5
                if shift then
                    Storage.delete_snapshot(snap_idx)
                    Globals.ui_popup.active = true; Globals.ui_popup.text = "SNAP "..snap_idx; Globals.ui_popup.val = "DELETED"; Globals.ui_popup.deadline = util.time() + 1.5; Globals.dirty = true
                else
                    local press_time = Globals.grid_timers[x][y]
                    local duration = util.time() - press_time
                    local is_filled = (Globals.snapshots[snap_idx] ~= nil)

                    if duration >= 0.8 then
                        if is_filled then
                            Storage.save_snapshot(snap_idx)
                            Globals.ui_popup.active = true; Globals.ui_popup.text = "SNAP "..snap_idx; Globals.ui_popup.val = "UPDATED"; Globals.ui_popup.deadline = util.time() + 1.5; Globals.dirty = true
                        end
                    else
                        if not is_filled then
                            Storage.save_snapshot(snap_idx)
                            Globals.ui_popup.active = true; Globals.ui_popup.text = "SNAP "..snap_idx; Globals.ui_popup.val = "SAVED"; Globals.ui_popup.deadline = util.time() + 1.5; Globals.dirty = true
                        else
                            Storage.load_snapshot(snap_idx)
                            Globals.ui_popup.active = true; Globals.ui_popup.text = "SNAP "..snap_idx; Globals.ui_popup.val = "LOADED"; Globals.ui_popup.deadline = util.time() + 1.5; Globals.dirty = true
                        end
                    end
                end
            end
        end
    end
    
    if Globals.page == 2 then
        local num_predefined = #Consts.SCALES_A + #Consts.SCALES_B
        if y == 1 and z == 1 then 
            params:set("scale_idx", x)
        end
        -- FIX: Row 2 now handles 16 scales (17-32)
        if y == 2 and z == 1 then 
            params:set("scale_idx", x + 16)
        end
        if y == 3 and z == 1 then
            params:set("scale_idx", x + num_predefined)
        end
        if y == 6 and z == 1 and x>=3 and x<=14 then 
            params:set("scale_root", x - 2)
        end
        if z == 1 and (y == 4 or y == 5) and x >= 3 and x <= 14 then
            local note = x - 3 
            if Globals.scale.current_idx <= num_predefined then
                params:set("scale_idx", num_predefined + 1)
            end
            Scales.toggle_custom_note(note)
            Scales.update_all_voices()
        end
    end
end

return Pages
