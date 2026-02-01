-- code/ltra/lib/scales.lua | v1.1
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
    local def = nil
    
    if idx <= #Consts.SCALES_A then
        def = Consts.SCALES_A[idx]
    elseif idx <= #Consts.SCALES_A + #Consts.SCALES_B then
        def = Consts.SCALES_B[idx - #Consts.SCALES_A]
    else
        -- Custom Scale
        local custom_idx = idx - (#Consts.SCALES_A + #Consts.SCALES_B)
        def = { type="TET", intervals=Globals.scale.custom_slots[custom_idx] }
    end
    
    if not def then return 440 end

    if def.type == "JI" then
        local ratios = def.intervals
        local len = #ratios
        local oct_shift = math.floor(degree / len)
        local ratio_idx = (degree % len) + 1
        local ratio = ratios[ratio_idx]
        return get_root_freq() * ratio * (2 ^ (octave + oct_shift))
    else
        local root = 48 + (Globals.scale.root_note - 1)
        local ints = def.intervals
        local len = #ints
        if len == 0 then return get_root_freq() end -- Safety for empty custom
        local oct_shift = math.floor(degree / len)
        local semi = ints[(degree % len) + 1]
        return musicutil.note_num_to_freq(root + semi + ((octave + oct_shift) * 12))
    end
end

function Scales.get_freq_from_voltage(volts)
    local range = 24 
    local degree = math.floor(volts * range)
    return Scales.get_freq(degree, 0)
end

-- Helper para saber si estamos en una escala editable
function Scales.is_custom_idx(idx)
    local total_fixed = #Consts.SCALES_A + #Consts.SCALES_B
    return idx > total_fixed
end

-- Edición de Escala Custom
function Scales.toggle_custom_note(note_0_11)
    local idx = Globals.scale.current_idx
    if not Scales.is_custom_idx(idx) then return end
    
    local custom_idx = idx - (#Consts.SCALES_A + #Consts.SCALES_B)
    local slot = Globals.scale.custom_slots[custom_idx]
    
    -- Buscar si existe
    local found = false
    for i, n in ipairs(slot) do
        if n == note_0_11 then
            table.remove(slot, i)
            found = true
            break
        end
    end
    
    if not found then
        table.insert(slot, note_0_11)
        table.sort(slot)
    end
    
    -- Safety: Si vacía, añadir Root (0)
    if #slot == 0 then table.insert(slot, 0) end
    
    Globals.dirty = true
end

-- Verificar si nota está activa (para Grid)
function Scales.is_note_active(note_0_11)
    local idx = Globals.scale.current_idx
    local intervals = {}
    
    if idx <= #Consts.SCALES_A then intervals = Consts.SCALES_A[idx].intervals
    elseif idx <= #Consts.SCALES_A + #Consts.SCALES_B then 
        -- JI scales don't map cleanly to 0-11 grid, skip visual or approx?
        -- Approx: JI intervals are ratios. Skip for now.
        return false 
    else
        local custom_idx = idx - (#Consts.SCALES_A + #Consts.SCALES_B)
        intervals = Globals.scale.custom_slots[custom_idx]
    end
    
    for _, n in ipairs(intervals) do
        if n == note_0_11 then return true end
    end
    return false
end

return Scales
