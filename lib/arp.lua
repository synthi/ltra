-- lib/arp.lua | v1.5.6
-- FIX: Length and Octaves Params

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
    local len = params:get("arp_length") or 8
    local oct_range = params:get("arp_octaves") or 1

    for i=1, 4 do
        if Globals.voices[i].arp_enabled then
            local reg = Globals.arp.register[i]
            
            -- FIX: Shift register respects length
            local last_bit = reg[len]
            local prev_bit = reg[len-1]
            if prev_bit == nil then prev_bit = 0 end
            
            local new_bit = (last_bit ~= prev_bit) and 1 or 0 
            
            if math.random() < chaos_prob then new_bit = 1 - new_bit end
            
            table.remove(reg)
            table.insert(reg, 1, new_bit)
            
            local val = (reg[1] * 4) + (reg[2] * 2) + (reg[3] * 1)
            local norm_val = val / 7
            Globals.arp.step_val[i] = norm_val
            
            Bridge.set_param("arp_cv"..i, norm_val)
            
            local deg = math.floor(norm_val * 24)
            local oct_offset = math.floor(norm_val * oct_range)
            local hz = Scales.get_freq(deg, (params:get("osc"..i.."_octave") or 0) + oct_offset)
            local tune = params:get("osc"..i.."_tune") or 0
            hz = hz * (2 ^ (tune / 12))
            
            Bridge.set_freq(i, hz)
            
            -- FIX: Gate Length Param
            Bridge.set_param("t_arp"..i, params:get("arp_gate_len") or 0.5)
        end
    end
end

return Arp
