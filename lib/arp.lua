-- code/ltra/lib/arp.lua | v0.7
local Arp = {}
local Globals
local Scales = require 'ltra/lib/scales'
local Bridge = require 'ltra/lib/engine_bridge'

function Arp.init(g_ref) Globals = g_ref end

function Arp.pulse(voice_idx)
    if not Globals.voices[voice_idx].arp_enabled then return end
    
    local current = Globals.arp.step_val[voice_idx] or 0
    local chaos_bit = (math.random() > 0.5) and 0.1 or 0.0
    local next_val = (current + 0.1 + chaos_bit) % 1.0
    next_val = math.floor(next_val * 8) / 8
    
    Globals.arp.step_val[voice_idx] = next_val
    local hz = Scales.get_freq_from_voltage(next_val)
    
    Bridge.set_freq(voice_idx, hz)
    
    -- NUEVO: Disparar envolvente en SC
    Bridge.trigger_arp(voice_idx)
end

function Arp.reset()
    for i=1,4 do Globals.arp.step_val[i] = 0 end
end

return Arp
