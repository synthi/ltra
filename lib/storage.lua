-- code/ltra/lib/storage.lua | v0.6
-- LTRA: Storage Manager (Hybrid: Pset + Data + Audio)

local Storage = {}
local Globals
local Bridge = require 'ltra/lib/engine_bridge'
local Consts = require 'ltra/lib/consts'

function Storage.init(g_ref)
    Globals = g_ref
    
    -- Hook en el sistema de parámetros de Norns
    params.action_write = function(filename, name, number)
        Storage.save_sidecar(number)
    end
    
    params.action_read = function(filename, silent, number)
        Storage.load_sidecar(number)
    end
end

-- Guardar datos extra que params no ve (Matriz, Gestos, Audio)
function Storage.save_sidecar(pset_number)
    print("LTRA: Saving Sidecar Data for PSET " .. pset_number)
    
    -- 1. Guardar Tablas Lua (Matriz, Gestos, Escalas Custom)
    local data = {
        matrix = Globals.matrix,
        gestures = Globals.gestures,
        custom_scales = Globals.scale.custom_slots,
        tracks_meta = {} -- Guardar estado de transporte/velocidad si no está en params
    }
    
    local data_path = _path.data .. "ltra/pset_" .. pset_number .. ".data"
    tab.save(data, data_path)
    
    -- 2. Guardar Audio (Buffers Softcut)
    -- Buffer 1 (L) y 2 (R)
    local audio_path_L = _path.audio .. "ltra/snapshots/pset_" .. pset_number .. "_L.wav"
    local audio_path_R = _path.audio .. "ltra/snapshots/pset_" .. pset_number .. "_R.wav"
    
    softcut.buffer_write_mono(audio_path_L, 0, -1, 1) -- Buffer 1
    softcut.buffer_write_mono(audio_path_R, 0, -1, 2) -- Buffer 2
    
    print("LTRA: Save Complete.")
end

-- Cargar datos extra
function Storage.load_sidecar(pset_number)
    print("LTRA: Loading Sidecar Data for PSET " .. pset_number)
    
    -- 1. Cargar Tablas
    local data_path = _path.data .. "ltra/pset_" .. pset_number .. ".data"
    local data = tab.load(data_path)
    
    if data then
        if data.matrix then 
            Globals.matrix = data.matrix 
            -- Sincronizar Matriz con Engine inmediatamente
            for s=1, 5 do
                for d=1, 16 do
                    -- Reconstruir nombres para Bridge (un poco hacky pero funcional)
                    -- Idealmente Bridge tendría set_matrix_index(s, d, val)
                    -- Por ahora confiamos en que el usuario mueva algo o forzamos update
                    -- TODO: Implementar Bridge.sync_all_matrix()
                end
            end
        end
        if data.gestures then Globals.gestures = data.gestures end
        if data.custom_scales then Globals.scale.custom_slots = data.custom_scales end
    else
        print("LTRA: No sidecar data found.")
    end
    
    -- 2. Cargar Audio
    local audio_path_L = _path.audio .. "ltra/snapshots/pset_" .. pset_number .. "_L.wav"
    local audio_path_R = _path.audio .. "ltra/snapshots/pset_" .. pset_number .. "_R.wav"
    
    if util.file_exists(audio_path_L) then
        softcut.buffer_read_mono(audio_path_L, 0, 0, -1, 1, 1)
        softcut.buffer_read_mono(audio_path_R, 0, 0, -1, 1, 2)
    end
    
    Globals.dirty = true
end

return Storage
