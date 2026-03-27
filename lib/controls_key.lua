-- lib/controls_key.lua | v2.2.2
-- FIX: Matrix Quantization uses params:set for Snapshot compatibility

local Keys = {}
local Globals
local Consts = require 'ltra/lib/consts'
local Bridge = require 'ltra/lib/engine_bridge'

function Keys.init(g_ref) Globals = g_ref end

function Keys.event(n, z)
    if n == 1 then return end
    if z == 0 then return end
    
    Globals.dirty = true
    
    if Globals.menu_mode ~= Consts.MENU.NONE then
        local targets = {Globals.menu_target}
        if type(Globals.menu_target) == "table" then
            if Globals.menu_target.src_name then
                targets = {Globals.menu_target}
            else
                targets = Globals.menu_target
            end
        end
        
        if Globals.menu_mode == Consts.MENU.OSC then
            if n==2 then 
                for _, t in ipairs(targets) do
                    local curr = params:get("osc"..t.."_arp")
                    params:set("osc"..t.."_arp", 1-curr)
                end
            elseif n==3 then
                Globals.osc_menu_page = Globals.osc_menu_page + 1
                if Globals.osc_menu_page > 3 then Globals.osc_menu_page = 1 end
            end
            
        elseif Globals.menu_mode == Consts.MENU.MIDI then
            if n==2 then
                for _, t in ipairs(targets) do
                    local curr = params:get("osc"..t.."_midi_note")
                    params:set("osc"..t.."_midi_note", 1-curr)
                end
            elseif n==3 then
                Globals.midi_menu_page = Globals.midi_menu_page + 1
                if Globals.midi_menu_page > 3 then Globals.midi_menu_page = 1 end
            end
            
        elseif Globals.menu_mode == Consts.MENU.MOD then
            if n==2 then
                for _, t in ipairs(targets) do
                    if Globals.mod_menu_page == 1 then
                        local curr = params:get("mod"..t.."_lfo_sync")
                        params:set("mod"..t.."_lfo_sync", 1-curr)
                    else
                        local curr = params:get("mod"..t.."_chaos_sync")
                        params:set("mod"..t.."_chaos_sync", 1-curr)
                    end
                end
            elseif n==3 then
                Globals.mod_menu_page = (Globals.mod_menu_page == 1) and 2 or 1
            end
            
        elseif Globals.menu_mode == Consts.MENU.ARP then
            if n==3 then
                Globals.arp_menu_page = (Globals.arp_menu_page == 1) and 2 or 1
            end
            
        elseif Globals.menu_mode == Consts.MENU.DELAY then
            if n==3 then
                Globals.delay_menu_page = (Globals.delay_menu_page == 1) and 2 or 1
            end
            
        elseif Globals.menu_mode == Consts.MENU.REVERB then
            if n==3 then
                Globals.reverb_menu_page = Globals.reverb_menu_page + 1
                if Globals.reverb_menu_page > 3 then Globals.reverb_menu_page = 1 end
            end
            
        elseif Globals.menu_mode == Consts.MENU.FILTER then
            if n==2 then 
                for _, t in ipairs(targets) do
                    local curr = params:get("filt"..t.."_type")
                    params:set("filt"..t.."_type", 1-curr)
                end
            end
            
        elseif Globals.menu_mode == Consts.MENU.MATRIX then
            if n==2 then 
                for _, t in ipairs(targets) do
                    local src_idx = Consts.SOURCES[t.src_name]
                    local dst_idx = Consts.DESTINATIONS[t.dest_name]
                    if src_idx and dst_idx then
                        if dst_idx <= 4 then
                            -- FIX: Use params:set to ensure Snapshot compatibility
                            local q_id = "quant_"..t.src_name.."_"..t.dest_name
                            local current_q = params:get(q_id)
                            params:set(q_id, 1 - current_q)
                        else
                            local current = Globals.matrix[src_idx][dst_idx]
                            local id = "mat_"..t.src_name.."_"..t.dest_name
                            params:set(id, current * -1)
                        end
                    end
                end
            end
        end
        return
    end
    
    if n==2 then Bridge.reset_lfo()
    elseif n==3 then Globals.latch_mode = not Globals.latch_mode end
end
return Keys
