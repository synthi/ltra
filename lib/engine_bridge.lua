-- lib/engine_bridge.lua | v3.0.0
-- FIX: sync_matrix sends zeros, reset_lfos command

local Bridge = {}
local Globals
local Consts = require 'ltra/lib/consts'

function Bridge.init(g_ref) Globals = g_ref end

function Bridge.handle_osc(path, args)
    if not Globals then return end
    
    if path == "/ltra/visuals" then
        if Globals.visuals then
            Globals.visuals.mod_vals = Globals.visuals.mod_vals or {}
            Globals.visuals.mod_vals[1] = args[1]
            Globals.visuals.mod_vals[2] = args[2]
            Globals.visuals.mod_vals[3] = args[3]
            Globals.visuals.outline_val = args[4] or 0 
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
            
            engine.set_matrix(s_idx, d_idx, val)
            if d_idx <= 4 then
                engine.set_matrix_quant(s_idx, d_idx, quant)
            end
        end
    end
end

function Bridge.query_config() engine.query_config() end
function Bridge.clear_delay() engine.clear_delay() end

function Bridge.set_param(name, value) engine.set_engine_param(name, value) end
function Bridge.set_freq(idx, hz) engine.set_engine_param("freq"..idx, hz) end
function Bridge.set_gate(idx, val) engine.set_engine_param("gate"..idx, val) end
function Bridge.set_midi_gate(idx, val) engine.set_engine_param("midi_gate"..idx, val) end
function Bridge.reset_lfo() engine.reset_lfos() end

function Bridge.set_midi_vel(idx, vel) engine.set_engine_param("midi_vel"..idx, vel) end
function Bridge.set_mod_wheel(val) engine.set_engine_param("mod_wheel", val) end
function Bridge.set_pitch_bend(val) engine.set_engine_param("pitch_bend", val) end

function Bridge.set_mpe_bend(idx, val) engine.set_engine_param("mpe_bend"..idx, val) end
function Bridge.set_mpe_slide(idx, val) engine.set_engine_param("slide"..idx, val) end
function Bridge.set_mpe_press(idx, val) engine.set_engine_param("press"..idx, val) end

-- FIX: Ratio Tracking for JI Scales
function Bridge.set_midi_ratio(idx, ratio) engine.set_engine_param("midi_ratio"..idx, ratio) end

function Bridge.set_matrix(src_idx, dest_idx, val)
    engine.set_matrix(src_idx, dest_idx, val)
end

function Bridge.set_matrix_quant(src_idx, dest_idx, val)
    engine.set_matrix_quant(src_idx, dest_idx, val)
end

return Bridge
