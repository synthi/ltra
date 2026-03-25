-- lib/ui.lua | v2.1.4
-- FIX: Strict Ergonomic Visual Order (E1 Top, E2 Mid, E3 Bot)

local UI = {}
local Globals
local Consts = require 'ltra/lib/consts'

function UI.init(g_ref) 
    Globals = g_ref 
    Globals.osc_menu_page = Globals.osc_menu_page or 1
    Globals.arp_menu_page = Globals.arp_menu_page or 1
    Globals.mod_menu_page = Globals.mod_menu_page or 1
    Globals.delay_menu_page = Globals.delay_menu_page or 1
    Globals.reverb_menu_page = Globals.reverb_menu_page or 1
    Globals.env_menu_page = Globals.env_menu_page or 1 
    Globals.midi_menu_page = Globals.midi_menu_page or 1
end

local function draw_menu()
    screen.level(15); screen.rect(0,0,128,64); screen.fill(); screen.level(0)
    
    local targets = {Globals.menu_target}
    local t_str = "?"
    local t = Globals.menu_target
    
    if type(Globals.menu_target) == "table" then
        if Globals.menu_target.src_name then
            targets = {Globals.menu_target}
            t_str = "MAT"
        else
            targets = Globals.menu_target
            t_str = table.concat(targets, ",")
            t = targets[1]
        end
    else
        t_str = tostring(Globals.menu_target)
    end
    
    local mode = Globals.menu_mode
    
    if mode == Consts.MENU.OSC then
        if Globals.osc_menu_page == 1 then
            screen.move(5,10); screen.text("OSC "..t_str.." EDIT (1/3)")
            screen.move(5,25); screen.text("E1 Tune: "..string.format("%.2f", params:get("osc"..t.."_tune")))
            screen.move(5,35); screen.text("E2 Shape: "..string.format("%.2f", params:get("osc"..t.."_shape")))
            screen.move(5,45); screen.text("E3 Octave: "..string.format("%+d", params:get("osc"..t.."_octave")))
        elseif Globals.osc_menu_page == 2 then
            screen.move(5,10); screen.text("OSC "..t_str.." EDIT (2/3)")
            screen.move(5,25); screen.text("E1 Vol: "..string.format("%.2f", params:get("osc"..t.."_vol")))
            screen.move(5,35); screen.text("E2 Drift: "..string.format("%.2f", params:get("osc"..t.."_drift")))
            screen.move(5,45); screen.text("E3 Spread: "..string.format("%.2f", params:get("osc"..t.."_spread")))
        else
            screen.move(5,10); screen.text("OSC "..t_str.." EDIT (3/3)")
            screen.move(5,35); screen.text("E2 Glide: "..string.format("%.3fs", params:get("osc"..t.."_glide")))
        end
        local arp_state = params:get("osc"..t.."_arp") == 1 and "ON" or "OFF"
        screen.move(5,58); screen.text("K2: ARP["..arp_state.."]  K3: PAGE")
        
    elseif mode == Consts.MENU.ENV then
        screen.move(5,10); screen.text("ENV "..t_str.." EDIT")
        screen.move(5,25); screen.text("E1 Pan: "..string.format("%.2f", params:get("osc"..t.."_pan")))
        screen.move(5,35); screen.text("E2 Attack: "..string.format("%.3fs", params:get("env_atk"..t)))
        screen.move(5,45); screen.text("E3 Release: "..string.format("%.3fs", params:get("env_rel"..t)))
        
    elseif mode == Consts.MENU.MIDI then
        if Globals.midi_menu_page == 1 then
            screen.move(5,10); screen.text("MIDI "..t_str.." (1/3)")
            screen.move(5,25); screen.text("E1 Vel>Vol: "..string.format("%.0f%%", params:get("osc"..t.."_vel_vol") * 100))
            screen.move(5,35); screen.text("E2 Vel>Shp: "..string.format("%+.0f%%", params:get("osc"..t.."_vel_shp") * 100))
            screen.move(5,45); screen.text("E3 Vel>Atk: "..string.format("%+.0f%%", params:get("osc"..t.."_vel_atk") * 100))
        elseif Globals.midi_menu_page == 2 then
            screen.move(5,10); screen.text("MPE SLIDE "..t_str.." (2/3)")
            screen.move(5,25); screen.text("E1 MW>Filt2: "..string.format("%+.0f%%", params:get("mw_filt2") * 100))
            screen.move(5,35); screen.text("E2 Sld>Vol: "..string.format("%+.0f%%", params:get("osc"..t.."_slide_vol") * 100))
            screen.move(5,45); screen.text("E3 Sld>Shp: "..string.format("%+.0f%%", params:get("osc"..t.."_slide_shp") * 100))
        else
            screen.move(5,10); screen.text("MPE PRESS "..t_str.." (3/3)")
            screen.move(5,25); screen.text("E1 MW>Echo: "..string.format("%+.0f%%", params:get("mw_delay_f") * 100))
            screen.move(5,35); screen.text("E2 Prs>Vol: "..string.format("%+.0f%%", params:get("osc"..t.."_press_vol") * 100))
            screen.move(5,45); screen.text("E3 Prs>Shp: "..string.format("%+.0f%%", params:get("osc"..t.."_press_shp") * 100))
        end
        local midi_state = params:get("osc"..t.."_midi_note") == 1 and "ON" or "OFF"
        screen.move(5,58); screen.text("K2: MIDI["..midi_state.."]  K3: PAGE")
        
    elseif mode == Consts.MENU.MOD then
        if Globals.mod_menu_page == 1 then
            screen.move(5,10); screen.text("MOD "..t_str.." LFO (1/2)")
            screen.move(5,25); screen.text("E1 Shape: "..string.format("%.2f", params:get("mod"..t.."_lfo_shape")))
            if params:get("mod"..t.."_lfo_sync") == 1 then
                local div = params:get("mod"..t.."_lfo_div")
                screen.move(5,35); screen.text("E2 Div: "..Consts.SYNC_DIVS[div].name)
            else
                screen.move(5,35); screen.text("E2 Rate: "..string.format("%.2f Hz", params:get("mod"..t.."_lfo_rate")))
            end
            screen.move(5,45); screen.text("E3 Depth: "..string.format("%.2f", params:get("mod"..t.."_depth")))
            local sync_str = params:get("mod"..t.."_lfo_sync") == 1 and "ON" or "OFF"
            screen.move(5,58); screen.text("K2: SYNC["..sync_str.."]  K3: PAGE")
        else
            screen.move(5,10); screen.text("MOD "..t_str.." CHAOS (2/2)")
            screen.move(5,25); screen.text("E1 Slew: "..string.format("%.2f", params:get("mod"..t.."_chaos_slew")))
            if params:get("mod"..t.."_chaos_sync") == 1 then
                local div = params:get("mod"..t.."_chaos_div")
                screen.move(5,35); screen.text("E2 Div: "..Consts.SYNC_DIVS[div].name)
            else
                screen.move(5,35); screen.text("E2 Rate: "..string.format("%.2f Hz", params:get("mod"..t.."_chaos_rate")))
            end
            screen.move(5,45); screen.text("E3 Mix: "..string.format("%.2f", params:get("mod"..t.."_mix")))
            local sync_str = params:get("mod"..t.."_chaos_sync") == 1 and "ON" or "OFF"
            screen.move(5,58); screen.text("K2: SYNC["..sync_str.."]  K3: PAGE")
        end
        
    elseif mode == Consts.MENU.ARP then
        if Globals.arp_menu_page == 1 then
            screen.move(5,10); screen.text("ARP SETTINGS (1/2)")
            local div_opts = {}
            for _, v in ipairs(Consts.SYNC_DIVS) do table.insert(div_opts, v.name) end
            screen.move(5,25); screen.text("E1 Gate: "..string.format("%.2f", params:get("arp_gate_len")))
            screen.move(5,35); screen.text("E2 Div: "..div_opts[params:get("arp_div")])
            screen.move(5,45); screen.text("E3 Chaos: "..string.format("%.2f", params:get("arp_chaos")))
        else
            screen.move(5,10); screen.text("ARP SETTINGS (2/2)")
            screen.move(5,35); screen.text("E2 Length: "..params:get("arp_length").." bits")
            screen.move(5,45); screen.text("E3 Octaves: "..params:get("arp_octaves"))
        end
        screen.move(5,58); screen.text("K3: PAGE")
        
    elseif mode == Consts.MENU.OUTLINE then
        screen.move(5,10); screen.text("OUTLINE FOLLOWER")
        local src = params:get("outline_src") == 1 and "INT GATE" or "EXT AUDIO"
        screen.move(5,35); screen.text("E2 Source: "..src)
        screen.move(5,45); screen.text("E3 Gain: "..string.format("%.1f", params:get("outline_gain")))
        
    elseif mode == Consts.MENU.FILTER then
        local f_name = (t==1) and "VADIM" or "DFM1"
        screen.move(5,10); screen.text("FILTER "..t.." ("..f_name..")")
        screen.move(5,25); screen.text("E1 Drive: "..string.format("%.2f", params:get("filt"..t.."_drive")))
        screen.move(5,35); screen.text("E2 Cutoff: "..string.format("%.0f Hz", params:get("filt"..t.."_cutoff")))
        screen.move(5,45); screen.text("E3 Res: "..string.format("%.2f", params:get("filt"..t.."_res")))
        local type_str = params:get("filt"..t.."_type") == 0 and "LP" or "HP"
        screen.move(5,58); screen.text("K2: TYPE["..type_str.."]")

    elseif mode == Consts.MENU.DELAY then
        if Globals.delay_menu_page == 1 then
            screen.move(5,10); screen.text("FX TAPE (1/2)")
            screen.move(5,25); screen.text("E1 Send: "..string.format("%.2f", params:get("delay_send")))
            screen.move(5,35); screen.text("E2 Time: "..string.format("%.2f s", params:get("tapecho_time")))
            screen.move(5,45); screen.text("E3 Fdbk: "..string.format("%.2f", params:get("tapecho_feedback")))
        else
            screen.move(5,10); screen.text("FX TAPE (2/2)")
            screen.move(5,25); screen.text("E1 Drive: "..string.format("%.2f", params:get("tapecho_drive")))
            screen.move(5,35); screen.text("E2 Erosion: "..string.format("%.2f", params:get("tapecho_erosion")))
            screen.move(5,45); screen.text("E3 Wow/Flut: "..string.format("%.2f", params:get("tapecho_wow_flutter")))
        end
        screen.move(5,58); screen.text("K3: PAGE")
        
    elseif mode == Consts.MENU.REVERB then
        if Globals.reverb_menu_page == 1 then
            screen.move(5,10); screen.text("FX BLOSSOM (1/3)")
            screen.move(5,25); screen.text("E1 Mix: "..string.format("%.2f", params:get("reverb_mix")))
            screen.move(5,35); screen.text("E2 Bloom: "..string.format("%.2f", params:get("blossomverb_bloom")))
            screen.move(5,45); screen.text("E3 Decay: "..string.format("%.1fs", params:get("blossomverb_decay")))
        elseif Globals.reverb_menu_page == 2 then
            screen.move(5,10); screen.text("FX BLOSSOM (2/3)")
            screen.move(5,35); screen.text("E2 Predelay: "..string.format("%.2fs", params:get("blossomverb_predelay")))
            screen.move(5,45); screen.text("E3 Damp: "..string.format("%.0f Hz", params:get("blossomverb_damp")))
        else
            screen.move(5,10); screen.text("FX BLOSSOM (3/3)")
            screen.move(5,35); screen.text("E2 Mod Rate: "..string.format("%.2f Hz", params:get("blossomverb_mod_rate")))
            screen.move(5,45); screen.text("E3 Mod Depth: "..string.format("%.4f", params:get("blossomverb_mod_depth")))
        end
        screen.move(5,58); screen.text("K3: PAGE")
        
    elseif mode == Consts.MENU.LOOPER then 
        screen.move(5,10); screen.text("OUTPUT & SYSTEM")
        screen.move(5,25); screen.text("E1 Dirt: "..string.format("%.2f", params:get("system_dirt")))
        screen.move(5,35); screen.text("E2 Monitor: "..string.format("%.2f", params:get("monitor_vol")))
        screen.move(5,45); screen.text("E3 Master: "..string.format("%.2f", params:get("master_vol")))
        
    elseif mode == Consts.MENU.MATRIX then
        screen.move(5,10); screen.text("MATRIX EDIT")
        if t and t.src_name then
            screen.move(5,25); screen.text(t.src_name .. " > " .. t.dest_name)
            local id = "mat_"..t.src_name.."_"..t.dest_name
            local val = params:get(id)
            
            local src_idx = Consts.SOURCES[t.src_name]
            local dst_idx = Consts.DESTINATIONS[t.dest_name]
            local q_str = ""
            if dst_idx <= 4 then 
                q_str = (Globals.matrix_quant[src_idx][dst_idx] == 1) and "[Q]" or "[F]"
            end
            
            screen.move(5,40); screen.text("AMT: " .. string.format("%.2f %s", val, q_str))
            
            if dst_idx <= 4 then
                screen.move(5,55); screen.text("K2: Mode  E3: Amt")
            else
                screen.move(5,55); screen.text("E3: Adjust")
            end
        end
    end
end

function UI.redraw()
    screen.clear()
    screen.aa(0)
    
    if Globals.menu_mode ~= Consts.MENU.NONE then
        draw_menu()
    elseif Globals.ui_popup.active then
        if util.time() > Globals.ui_popup.deadline then 
            Globals.ui_popup.active = false 
            Globals.dirty = true
        else
            screen.level(15); screen.rect(10,20,108,20); screen.fill(); screen.level(0)
            screen.move(64,34); screen.text_center(Globals.ui_popup.text.." "..Globals.ui_popup.val)
        end
    else
        screen.level(15); screen.move(0,10); screen.text("LTRA v2.1.4")
        
        if Globals.latch_mode then 
            screen.move(120, 10); screen.text("L") 
        end
        
        screen.level(3)
        local s_name = "Unknown"
        if Globals.scale and Globals.scale.current_idx then
            local idx = Globals.scale.current_idx
            if idx <= #Consts.SCALES_A then
                s_name = Consts.SCALES_A[idx].name
            elseif idx <= #Consts.SCALES_A + #Consts.SCALES_B then
                s_name = Consts.SCALES_B[idx-#Consts.SCALES_A].name
            end
        end
        
        local root_name = "?"
        if Consts.NOTE_NAMES and Globals.scale and Globals.scale.root_note then
            root_name = Consts.NOTE_NAMES[Globals.scale.root_note] or "?"
        end
        
        -- FIX: Main Display Ergonomic Order
        screen.move(0, 25); screen.text("E1 Vol: "..string.format("%.2f", params:get("master_vol")))
        screen.move(0, 35); screen.text("E2 Scl: "..s_name)
        screen.move(0, 45); screen.text("E3 Root: "..root_name)
        
        local db_l = 20 * math.log10(math.max(0.0001, Globals.visuals.amp_l))
        local db_r = 20 * math.log10(math.max(0.0001, Globals.visuals.amp_r))
        local vu_l = util.clamp(util.linlin(-48, 0, 0, 40, db_l), 0, 40)
        local vu_r = util.clamp(util.linlin(-48, 0, 0, 40, db_r), 0, 40)
        
        screen.level(15)
        screen.rect(110, 50, 4, -vu_l); screen.fill()
        screen.rect(116, 50, 4, -vu_r); screen.fill()
    end
    screen.update()
end

return UI
