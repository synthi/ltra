-- code/ltra/lib/scales.lua | v0.6
local Scales = {}
local Consts = require 'ltra/lib/consts'
local musicutil = require 'musicutil'
local Globals 

function Scales.init(g_ref) Globals = g_ref end

local function get_root_freq()
    -- C3 = 48 (MIDI) -> Hz
    local midi = 48 + (Globals.scale.root_note - 1)
    return musicutil.note_num_to_freq(midi)
end

-- Convierte un grado (0, 1, 2...) y octava a Hz
function Scales.get_freq(degree, octave)
    local idx = Globals.scale.current_idx
    local def = (idx <= #Consts.SCALES_A) and Consts.SCALES_A[idx] or Consts.SCALES_B[idx - #Consts.SCALES_A]
    
    if not def then return 440 end

    if def.type == "JI" then
        -- Entonación Justa (Matemática pura)
        local ratios = def.intervals
        local len = #ratios
        local oct_shift = math.floor(degree / len)
        local ratio_idx = (degree % len) + 1
        local ratio = ratios[ratio_idx]
        return get_root_freq() * ratio * (2 ^ (octave + oct_shift))
    else
        -- Temperamento Igual (MusicUtil)
        local root = 48 + (Globals.scale.root_note - 1)
        local ints = def.intervals
        local len = #ints
        local oct_shift = math.floor(degree / len)
        local semi = ints[(degree % len) + 1]
        return musicutil.note_num_to_freq(root + semi + ((octave + oct_shift) * 12))
    end
end

-- Convierte voltaje 0.0-1.0 a la nota más cercana de la escala
function Scales.get_freq_from_voltage(volts)
    local range = 24 -- 2 Octavas de rango para modulación
    local degree = math.floor(volts * range)
    return Scales.get_freq(degree, 0)
end

function Scales.toggle_custom_note(slot_idx, note)
    -- Placeholder para edición futura
end

return Scales
