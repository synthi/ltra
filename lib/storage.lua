-- code/ltra/lib/storage.lua | v0.9.5
-- LTRA: Storage Manager (Hybrid Persistence)

local Storage = {}
local Globals
local Bridge = require 'ltra/lib/engine_bridge'

function Storage.init(g_ref)
    Globals = g_ref
    
    -- Hook en el sistema de parámetros
    params.action_write = function(filename, name, number)
        Storage.save_sidecar(number)
    end
    
    params.action_read = function(filename, silent, number)
        Storage.load_sidecar(number)
    end
end

function Storage.save_sidecar(pset_number)
    print("LTRA: Saving Sidecar Data for PSET " .. pset_number)
    
    -- 1. Guardar Datos Lua (Gestos, Escalas Custom)
    -- Nota: La Matriz se guarda automáticamente vía Params Ocultos (v0.9.5)
    local data = {
        gestures = Globals.gestures,
        custom_scales = Globals.scale.custom_slots,
        snapshots = Globals.snapshots -- Bancos de sonido Fila 7
    }
    
    local data_path = _path.data .. "ltra/pset_" .. pset_number .. ".data"
    tab.save(data, data_path)
    
    -- 2. Guardar Audio (Buffers Softcut)
    -- Guardamos el buffer completo (L y R)
    local audio_path_L = _path.audio .. "ltra/snapshots/pset_" .. pset_number .. "_L.wav"
    local audio_path_R = _path.audio .. "ltra/snapshots/pset_" .. pset_number .. "_R.wav"
    
    -- Buffer 1 (L) y 2 (R), start 0, length -1 (todo)
    softcut.buffer_write_mono(audio_path_L, 0, -1, 1)
    softcut.buffer_write_mono(audio_path_R, 0, -1, 2)
    
    print("LTRA: Save Complete.")
end

function Storage.load_sidecar(pset_number)
    print("LTRA: Loading Sidecar Data for PSET " .. pset_number)
    
    -- 1. Cargar Datos Lua
    local data_path = _path.data .. "ltra/pset_" .. pset_number .. ".data"
    if util.file_exists(data_path) then
        local data = tab.load(data_path)
        if data then
            if data.gestures then Globals.gestures = data.gestures end
            if data.custom_scales then Globals.scale.custom_slots = data.custom_scales end
            if data.snapshots then Globals.snapshots = data.snapshots end
        end
    end
    
    -- 2. Cargar Audio
    local audio_path_L = _path.audio .. "ltra/snapshots/pset_" .. pset_number .. "_L.wav"
    local audio_path_R = _path.audio .. "ltra/snapshots/pset_" .. pset_number .. "_R.wav"
    
    if util.file_exists(audio_path_L) then
        softcut.buffer_read_mono(audio_path_L, 0, 0, -1, 1, 1)
        softcut.buffer_read_mono(audio_path_R, 0, 0, -1, 1, 2)
    else
        print("LTRA: No audio found for this PSET.")
    end
    
    Globals.dirty = true
end

return Storage
