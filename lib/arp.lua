-- lib/arp.lua | v1.5.0
-- FIX: Memory Leak, API Crash, and Pitch Hijack

local Arp = {}
local Globals
local Scales = require 'ltra/lib/scales'
local Bridge = require 'ltra/lib/engine_bridge'

function Arp.init(g_ref)
    Globals = g_ref
    
    Arp.clock_id = clock.run(function()
        while true do
            local div_idx = params:get("arp_div") or 2
            local sync_val = 1/4
            if div_idx == 2 then sync_val = 1/8
            elseif div_idx == 3 then sync_val = 1/16
            elseif div_idx == 4 then sync_val = 1/32 end
            
            clock.sync(sync_val)
            Arp.tick()
        end
    end)
end

function Arp.stop()
    if Arp.clock_id then clock.cancel(Arp.clock_id) end
end

function Arp.tick()
    local chaos_prob = params:get("arp_chaos") or 0.1

    for i=1, 4 do
        if Globals.voices[i].arp_enabled then
            local reg = Globals.arp.register[i]
            
            local last_bit = reg[8]
            local prev_bit = reg[7]
            local new_bit = (last_bit ~= prev_bit) and 1 or 0 
            
            if math.random() < chaos_prob then new_bit = 1 - new_bit end
            
            table.remove(reg)
            table.insert(reg, 1, new_bit)
            
            local val = (reg[1] * 4) + (reg[2] * 2) + (reg[3] * 1)
            local norm_val = val / 7
            Globals.arp.step_val[i] = norm_val
            
            Bridge.set_param("arp_cv"..i, norm_val)
            
            -- FIX: 24 degrees (2 octaves) + Octave Param
            local deg = math.floor(norm_val * 24)
            local hz = Scales.get_freq(deg, params:get("osc"..i.."_octave") or 0)
            local tune = params:get("osc"..i.."_tune") or 0
            hz = hz * (2 ^ (tune / 12))
            
            Bridge.set_freq(i, hz)
            Bridge.trigger_arp(i)
        end
    end
end

return Arp
