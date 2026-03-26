-- lib/scales.lua | v2.1.6
-- FIX: 8-Voice Frequency Update

local Scales = {}
local Consts = require 'ltra/lib/consts'
local musicutil = require 'musicutil'
local Bridge = require 'ltra/lib/engine_bridge'
local Globals 

function Scales.init(g_ref) 
    Globals = g_ref 
    
    if not Globals.scale.custom_slots or #Globals.scale.custom_slots < 16 then
        Globals.scale.custom_slots = {}
        for i=1, 16 do
            Globals.scale.custom_slots[i] = { modified = false, intervals = {} }
            local preset = Consts.SCALES_A[i]
            if not preset then preset = Consts.SCALES_B[i - #Consts.SCALES_A] end
            if preset then
                for _, v in ipairs(preset.intervals) do table.insert(Globals.scale.custom_slots[i].intervals, v) end
            else
                Globals.scale.custom_slots[i].intervals = {0, 2, 4, 5, 7, 9, 11}
            end
        end
    end
end

local function get_root_freq()
    if not Globals or not Globals.scale then return 440 end
    local root = Globals.scale.root_note or 1
    local midi = 48 + (root - 1)
    return musicutil.note_num_to_freq(midi)
end

function Scales.get_freq(degree, octave)
    if not Globals or not Globals.scale then return 440 end
    
    local idx = Globals.scale.current_idx or 1
    local def = nil
    
    if idx <= #Consts.SCALES_A then
        def = Consts.SCALES_A[idx]
    elseif idx <= 16 then
        def = Consts.SCALES_B[idx - #Consts.SCALES_A]
    else
        local custom_idx = idx - 16
        if Globals.scale.custom_slots and Globals.scale.custom_slots[custom_idx] then
            def = { type="TET", intervals=Globals.scale.custom_slots[custom_idx].intervals }
        end
    end
    
    if not def then return 440 end

    if def.type == "JI" then
        local ratios = def.intervals
        local len = #ratios
        if len == 0 then return get_root_freq() end
        local oct_shift = math.floor(degree / len)
        local ratio_idx = (degree % len) + 1
        local ratio = ratios[ratio_idx] or 1
        return get_root_freq() * ratio * (2 ^ (octave + oct_shift))
    else
        local root = 48 + (Globals.scale.root_note - 1)
        local ints = def.intervals
        local len = #ints
        if len == 0 then return get_root_freq() end 
        local oct_shift = math.floor(degree / len)
        local semi = ints[(degree % len) + 1] or 0
        return musicutil.note_num_to_freq(root + semi + ((octave + oct_shift) * 12))
    end
end

function Scales.update_scale_map()
    if not Globals or not Globals.scale then return end
    local active_notes = {}
    for i=0, 11 do
        if Scales.is_note_active(i) then table.insert(active_notes, i) end
    end
    if #active_notes == 0 then active_notes = {0} end
    
    for i=0, 11 do
        local nearest_val = active_notes[1]
        local min_d = 100
        for _, n in ipairs(active_notes) do
            if math.abs(i - n) < min_d then min_d = math.abs(i - n); nearest_val = n end
            if math.abs(i - (n+12)) < min_d then min_d = math.abs(i - (n+12)); nearest_val = n+12 end
            if math.abs(i - (n-12)) < min_d then min_d = math.abs(i - (n-12)); nearest_val = n-12 end
        end
        Bridge.set_param("scale_map_"..i, nearest_val)
    end
end

function Scales.update_all_voices()
    if not Globals or not Globals.voices then return end
    Scales.update_scale_map()
    for i=1, 4 do
        local pitch_val = params:get("osc"..i.."_pitch") or 0.5
        local deg = math.floor(pitch_val * 24)
        local hz = Scales.get_freq(deg, params:get("osc"..i.."_octave") or 0)
        local tune = params:get("osc"..i.."_tune") or 0
        hz = hz * (2 ^ (tune / 12))
        Bridge.set_freq(i, hz)
        Bridge.set_freq(i+4, hz) -- FIX: Update Twin Voice Base Frequency
    end
end

function Scales.toggle_custom_note(note_0_11)
    if not Globals or not Globals.scale then return end
    local idx = Globals.scale.current_idx
    if idx <= 16 then return end 
    
    local custom_idx = idx - 16
    local slot = Globals.scale.custom_slots[custom_idx]
    slot.modified = true
    
    local found = false
    for i, n in ipairs(slot.intervals) do
        if n == note_0_11 then
            table.remove(slot.intervals, i)
            found = true
            break
        end
    end
    
    if not found then
        table.insert(slot.intervals, note_0_11)
        table.sort(slot.intervals)
    end
    if #slot.intervals == 0 then table.insert(slot.intervals, 0) end
    Globals.dirty = true
end

function Scales.is_note_active(note_0_11)
    if not Globals or not Globals.scale then return false end
    local idx = Globals.scale.current_idx
    local intervals = {}
    
    if idx <= #Consts.SCALES_A then intervals = Consts.SCALES_A[idx].intervals
    elseif idx <= 16 then 
        local b_idx = idx - #Consts.SCALES_A
        if Consts.SCALES_B[b_idx] then intervals = Consts.SCALES_B[b_idx].intervals end
    else
        local custom_idx = idx - 16
        if Globals.scale.custom_slots[custom_idx] then
            intervals = Globals.scale.custom_slots[custom_idx].intervals
        end
    end
    
    if not intervals then return false end
    
    for _, n in ipairs(intervals) do
        if n == note_0_11 then return true end
    end
    return false
end

return Scales
