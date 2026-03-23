-- lib/engine_bridge.lua | v1.5.11
-- FIX: Matrix translation to isolated namespace (tapecho_*)

local Bridge = {}
local Globals
local Consts = require 'ltra/lib/consts'

function Bridge.init(g_ref) Globals = g_ref end

function Bridge.handle_osc(path, args)
    if not Globals then return end
    
    if path == "/ltra/visuals" then
        if Globals.visuals then
            Globals.visuals.amp_l = args[1]
            Globals.visuals.amp_r = args[2]
            Globals.visuals.mod_vals = Globals.visuals.mod_vals or {}
            Globals.visuals.mod_vals[1] = args[3]
            Globals.visuals.mod_vals[2] = args[4]
            Globals.visuals.mod_vals[3] = args[5]
            Globals.visuals.outline_val = args[6] or 0 
            
            Globals.dirty = true
        end
    elseif path == "/ltra/config" then
        Globals.engine_bus_id = args[1]
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
                if dest == "filt" then dest = "filt" end 
                if dest == "morph" then dest = "shape" end 
                -- FIX: Translate matrix visual names to isolated namespace
                if dest == "delay_t" then dest = "tapecho_time" end
                if dest == "delay_f" then dest = "tapecho_feedback" end
                
                engine.set_engine_param("mod_" .. s_name:lower() .. "_" .. dest .. idx, val)
                
                if dest == "pitch" then
                    engine.set_engine_param("quant_" .. s_name:lower() .. "_" .. dest .. idx, quant)
                end
            end
        end
    end
end

function Bridge.query_config() engine.query_config() end
function Bridge.clear_delay() engine.clear_delay() end

function Bridge.set_param(name, value) engine.set_engine_param(name, value) end
function Bridge.set_freq(idx, hz) engine.set_engine_param("freq"..idx, hz) end
function Bridge.set_gate(idx, val) engine.set_engine_param("gate"..idx, val) end
function Bridge.reset_lfo() engine.set_engine_param("t_reset", 1) end

function Bridge.set_matrix(src, dest, idx, val)
    engine.set_engine_param("mod_"..src.."_"..dest..idx, val)
end

function Bridge.set_matrix_quant(src, dest, idx, val)
    engine.set_engine_param("quant_"..src.."_"..dest..idx, val)
end

return Bridge
