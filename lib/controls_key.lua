-- lib/controls_key.lua | v2.0.0
-- FIX: ENV Menu Pagination and MIDI Toggle

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
        local t = Globals.menu_target
        
        if Globals.menu_mode == Consts.MENU.OSC then
            if n==2 then 
                local curr = params:get("osc"..t.."_arp")
                params:set("osc"..t.."_arp", 1-curr)
            elseif n==3 then
                Globals.osc_menu_page = Globals.osc_menu_page + 1
                if Globals.osc_menu_page > 3 then Globals.osc_menu_page = 1 end
            end
            
        elseif Globals.menu_mode == Consts.MENU.ENV then
            -- FIX: ENV Menu K2 (MIDI Toggle) and K3 (Page)
            if n==2 then
                local curr = params:get("osc"..t.."_midi_note")
                params:set("osc"..t.."_midi_note", 1-curr)
            elseif n==3 then
                Globals.env_menu_page = (Globals.env_menu_page == 1) and 2 or 1
            end
            
        elseif Globals.menu_mode == Consts.MENU.MOD then
            if n==2 then
                if Globals.mod_menu_page == 1 then
                    local curr = params:get("mod"..t.."_lfo_sync")
                    params:set("mod"..t.."_lfo_sync", 1-curr)
                else
                    local curr = params:get("mod"..t.."_chaos_sync")
                    params:set("mod"..t.."_chaos_sync", 1-curr)
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
                local curr = params:get("filt"..t.."_type")
                params:set("filt"..t.."_type", 1-curr)
            end
            
        elseif Globals.menu_mode == Consts.MENU.MATRIX then
            if n==2 then 
                local src_idx = Consts.SOURCES[Globals.menu_target.src_name]
                local dst_idx = Consts.DESTINATIONS[Globals.menu_target.dest_name]
                if src_idx and dst_idx then
                    if dst_idx <= 4 then
                        local current_q = Globals.matrix_quant[src_idx][dst_idx]
                        local new_q = 1 - current_q
                        Globals.matrix_quant[src_idx][dst_idx] = new_q
                        local idx = string.match(Globals.menu_target.dest_name, "(%d+)$") or ""
                        Bridge.set_matrix_quant(Globals.menu_target.src_name:lower(), "pitch", idx, new_q)
                    else
                        local current = Globals.matrix[src_idx][dst_idx]
                        local id = "mat_"..Globals.menu_target.src_name.."_"..Globals.menu_target.dest_name
                        params:set(id, current * -1)
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
