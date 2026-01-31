-- code/ltra/lib/storage.lua | v1.0
local Storage = {}
local Globals
local Bridge = require 'ltra/lib/engine_bridge'
local Consts = require 'ltra/lib/consts'

function Storage.init(g_ref)
    Globals = g_ref
    params.action_write = function(filename, name, number) Storage.save_sidecar(number) end
    params.action_read = function(filename, silent, number) Storage.load_sidecar(number) end
end

function Storage.save_sidecar(pset_number)
    print("LTRA: Saving Sidecar Data for PSET " .. pset_number)
    local data = {
        custom_scales = Globals.scale.custom_slots,
        snapshots = Globals.snapshots
    }
    local data_path = _path.data .. "ltra/pset_" .. pset_number .. ".data"
    tab.save(data, data_path)
    
    local audio_path_L = _path.audio .. "ltra/snapshots/pset_" .. pset_number .. "_L.wav"
    local audio_path_R = _path.audio .. "ltra/snapshots/pset_" .. pset_number .. "_R.wav"
    softcut.buffer_write_mono(audio_path_L, 0, -1, 1)
    softcut.buffer_write_mono(audio_path_R, 0, -1, 2)
    print("LTRA: Save Complete.")
end

function Storage.load_sidecar(pset_number)
    print("LTRA: Loading Sidecar Data for PSET " .. pset_number)
    local data_path = _path.data .. "ltra/pset_" .. pset_number .. ".data"
    if util.file_exists(data_path) then
        local data = tab.load(data_path)
        if data then
            if data.custom_scales then Globals.scale.custom_slots = data.custom_scales end
            if data.snapshots then Globals.snapshots = data.snapshots end
        end
    end
    
    local audio_path_L = _path.audio .. "ltra/snapshots/pset_" .. pset_number .. "_L.wav"
    local audio_path_R = _path.audio .. "ltra/snapshots/pset_" .. pset_number .. "_R.wav"
    if util.file_exists(audio_path_L) then
        softcut.buffer_read_mono(audio_path_L, 0, 0, -1, 1, 1)
        softcut.buffer_read_mono(audio_path_R, 0, 0, -1, 1, 2)
    end
    
    Bridge.sync_matrix()
    Globals.dirty = true
end

-- SNAPSHOTS (RAM)
function Storage.save_snapshot(slot)
    local snap = { params={} }
    for _, id in ipairs(params.lookup) do
        local p = params:lookup_param(id)
        -- Filtrar por patrones
        for _, pat in ipairs(Consts.SNAPSHOT_PATTERNS) do
            if string.find(p.id, pat) then
                snap.params[p.id] = p:get()
                break
            end
        end
    end
    Globals.snapshots[slot] = snap
    print("LTRA: Snapshot "..slot.." saved.")
end

function Storage.load_snapshot(slot)
    local snap = Globals.snapshots[slot]
    if not snap then return end
    for id, val in pairs(snap.params) do
        params:set(id, val) -- Dispara acciones y actualiza engine
    end
    print("LTRA: Snapshot "..slot.." loaded.")
end

return Storage
