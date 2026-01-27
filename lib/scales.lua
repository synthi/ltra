-- code/ltra/lib/scales.lua | v0.9.5
local Scales = {}
local Consts = require 'ltra/lib/consts'
local musicutil = require 'musicutil'
local Globals 

function Scales.init(g_ref) Globals = g_ref end

local function get_root_freq()
    local midi = 48 + (Globals.scale.root_note - 1)
    return musicutil.note_num_to_freq(midi)
end

function Scales.get_freq(degree, octave)
    local idx = Globals.scale.current_idx
    local def = (idx <= #Consts.SCALES_A) and Consts.SCALES_A[idx] or Consts.SCALES_B[idx - #Consts.SCALES_A]
    
    if not def then return 440 end

    if def.type == "JI" then
        local ratios = def.intervals
        local len = #ratios
        local oct_shift = math.floor(degree / len)
        -- Ajuste de índice Lua (1-based)
        local ratio_idx = (degree % len) + 1
        local ratio = ratios[ratio_idx]
        return get_root_freq() * ratio * (2 ^ (octave + oct_shift))
    else
        local root = 48 + (Globals.scale.root_note - 1)
        local ints = def.intervals
        local len = #ints
        local oct_shift = math.floor(degree / len)
        local semi = ints[(degree % len) + 1]
        return musicutil.note_num_to_freq(root + semi + ((octave + oct_shift) * 12))
    end
end

-- Helper para Arp/Modulación (0.0-1.0 -> Hz)
function Scales.get_freq_from_voltage(volts)
    local range = 24 -- 2 octavas
    local degree = math.floor(volts * range)
    return Scales.get_freq(degree, 0)
end

return Scales
