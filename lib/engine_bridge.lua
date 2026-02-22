-- code/ltra/lib/engine_bridge.lua | v1.4.9
-- LTRA: OSC Bridge
-- FIX: Safe OSC Command Name (set_engine_param)

local Bridge = {}
local Globals
local Loopers = require 'ltra/lib/loopers'
local Consts = require 'ltra/lib/consts'

function Bridge.init(g_ref) Globals = g_ref end

function Bridge.handle_osc(path, args)
    if not Globals then return end
    
    if path == "/ltra/visuals" then
        if Globals.visuals then
            Globals.visuals.amp_l = args[1]
            Globals.visuals.amp_r = args[2]
            Globals.visuals.lfo_vals[1] = args[3]
            Globals.visuals.lfo_vals[2] = args[4]
            Globals.visuals.chaos_val = args[5] or 0
            
            if Globals.menu_mode == Consts.MENU.NONE then
                if Globals.page == 1 or Globals.page == 3 then
                    Globals.dirty = true
                end
            end
        end
    elseif path == "/ltra/config" then
        Globals.engine_bus_id = args[1]
        Loopers.configure_audio_routing(Globals)
        Globals.dirty = true
    end
end

function Bridge.sync_matrix()
    for s_name, s_idx in pairs(Consts.SOURCES) do
        for d_name, d_idx in pairs(Consts.DESTINATIONS) do
            local val = Globals.matrix[s_idx][d_idx]
            local quant = Globals.matrix_quant[s_idx][d_idx] or 1
            
            if val > 0 or quant ~= 1 then 
                local idx = string.match(d_name, "(%d+)$") or ""
                local dest = d_name:lower():gsub("%d", "")
                if dest == "delay_t" then dest = "delay_time" end
                if dest == "delay_f" then dest = "delay_fb" end
                if dest == "filt" then dest = "filt" end 
                
                -- FIX 3.1: Usar set_engine_param
                engine.set_engine_param("mod_" .. s_name:lower() .. "_" .. dest .. idx, val)
                
                if dest == "pitch" then
                    engine.set_engine_param("quant_" .. s_name:lower() .. "_" .. dest .. idx, quant)
                end
            end
        end
    end
end

function Bridge.query_config() engine.query_config() end

-- FIX 3.1: Enrutamiento a set_engine_param
function Bridge.set_param(name, value) engine.set_engine_param(name, value) end
function Bridge.set_freq(idx, hz) engine.set_engine_param("freq"..idx, hz) end
function Bridge.set_gate(idx, val) engine.set_engine_param("gate"..idx, val) end
function Bridge.trigger_arp(idx) engine.set_engine_param("t_arp"..idx, 1) end
function Bridge.reset_lfo() engine.set_engine_param("t_reset", 1) end

function Bridge.set_filter_tone(idx, val)
    local tone = util.linlin(0, 1, -1.0, 1.0, val)
    engine.set_engine_param("filt"..idx.."_tone", tone)
end

function Bridge.set_matrix(src, dest, idx, val)
    engine.set_engine_param("mod_"..src.."_"..dest..idx, val)
end

function Bridge.set_matrix_quant(src, dest, idx, val)
    engine.set_engine_param("quant_"..src.."_"..dest..idx, val)
end

return Bridge
