-- lib/scales.lua | v3.1.8
-- FIX: Per-oscillator individual scales (scale_mode, osc_scale_idx)

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
            Globals.scale.custom_slots[i] = { modified = false, intervals = {0, 2, 4, 5, 7, 9, 11} }
        end
    end
end

local function get_root_freq()
    if not Globals or not Globals.scale then return 440 end
    local root = Globals.scale.root_note or 1
    local midi = 48 + (root - 1)
    return musicutil.note_num_to_freq(midi)
end

local function get_def_for_idx(scale_idx)
    local num_predefined = #Consts.SCALES_A + #Consts.SCALES_B
    if scale_idx <= #Consts.SCALES_A then
        return Consts.SCALES_A[scale_idx]
    elseif scale_idx <= num_predefined then
        return Consts.SCALES_B[scale_idx - #Consts.SCALES_A]
    else
        local custom_idx = scale_idx - num_predefined
        if Globals.scale.custom_slots and Globals.scale.custom_slots[custom_idx] then
            return { type="TET", intervals=Globals.scale.custom_slots[custom_idx].intervals }
        end
    end
    return nil
end

function Scales.get_freq(degree, octave)
    if not Globals or not Globals.scale then return 440 end
    local def = get_def_for_idx(Globals.scale.current_idx or 1)
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

function Scales.get_freq_for_osc(osc_idx, degree, octave)
    if not Globals or not Globals.scale then return 440 end
    local idx = Globals.osc_scale_idx[osc_idx] or 1
    local def = get_def_for_idx(idx)
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

local function build_scale_map_for_idx(scale_idx, setter_fn)
    local def = get_def_for_idx(scale_idx)
    if not def then return end
    
    if def.type == "JI" then
        local ji_st = {}
        for _, ratio in ipairs(def.intervals) do
            table.insert(ji_st, 12.0 * math.log(ratio) / math.log(2))
        end
        local ji_pool = {}
        for _, st in ipairs(ji_st) do
            table.insert(ji_pool, st)
            table.insert(ji_pool, st - 12)
            table.insert(ji_pool, st + 12)
        end
        for i=0, 11 do
            local nearest_val = ji_st[1]
            local min_d = 100
            for _, st in ipairs(ji_pool) do
                local d = math.abs(i - st)
                if d < min_d then min_d = d; nearest_val = st end
            end
            setter_fn(i, nearest_val)
        end
    else
        local active_notes = {}
        for i=0, 11 do
            if Scales.is_note_active_for_scale(scale_idx, i) then table.insert(active_notes, i) end
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
            setter_fn(i, nearest_val)
        end
    end
end

function Scales.update_scale_map()
    if not Globals or not Globals.scale then return end
    local global_idx = Globals.scale.current_idx or 1
    build_scale_map_for_idx(global_idx, function(pc, val)
        for osc=1, 4 do
            if not Globals.scale_mode[osc] then
                Bridge.set_osc_scale_map(osc, pc, val)
            end
        end
    end)
end

function Scales.update_osc_scale_map(osc_idx)
    if not Globals or not Globals.scale then return end
    local idx = Globals.osc_scale_idx[osc_idx] or 1
    build_scale_map_for_idx(idx, function(pc, val)
        Bridge.set_osc_scale_map(osc_idx, pc, val)
    end)
end

function Scales.update_all_voices()
    if not Globals or not Globals.voices then return end
    Scales.update_scale_map()
    for i=1, 4 do
        if Globals.scale_mode[i] then
            Scales.update_osc_scale_map(i)
        end
    end
    for i=1, 4 do
        local pitch_val = params:get("osc"..i.."_pitch") or 0.5
        local deg = math.floor(pitch_val * 24)
        local oct = params:get("osc"..i.."_octave") or 0
        local hz
        if Globals.scale_mode[i] then
            hz = Scales.get_freq_for_osc(i, deg, oct)
        else
            hz = Scales.get_freq(deg, oct)
        end
        local tune = params:get("osc"..i.."_tune") or 0
        hz = hz * (2 ^ (tune / 12))
        Bridge.set_freq(i, hz)
        Bridge.set_freq(i+4, hz) 
    end
end

function Scales.toggle_custom_note(note_0_11)
    if not Globals or not Globals.scale then return end
    local idx = Globals.scale.current_idx
    local num_predefined = #Consts.SCALES_A + #Consts.SCALES_B
    if idx <= num_predefined then return end 
    
    local custom_idx = idx - num_predefined
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
    return Scales.is_note_active_for_scale(Globals.scale.current_idx, note_0_11)
end

function Scales.is_note_active_for_scale(scale_idx, note_0_11)
    if not Globals or not Globals.scale then return false end
    local intervals = {}
    local num_predefined = #Consts.SCALES_A + #Consts.SCALES_B
    
    if scale_idx <= #Consts.SCALES_A then intervals = Consts.SCALES_A[scale_idx].intervals
    elseif scale_idx <= num_predefined then 
        local b_idx = scale_idx - #Consts.SCALES_A
        if Consts.SCALES_B[b_idx] then intervals = Consts.SCALES_B[b_idx].intervals end
    else
        local custom_idx = scale_idx - num_predefined
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