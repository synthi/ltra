-- ltra.lua | v1.4.11
-- LTRA: Main Script
-- FIX: Unified Memory Space (require) & OS Screen Hijack Fix

engine.name = 'Ltra'

-- FIX CRÍTICO: Usar 'require' en lugar de 'include' para unificar la memoria RAM.
-- Ahora todos los archivos del script comparten la misma instancia de las librerías.
local Globals = require('ltra/lib/globals')
local Consts = require('ltra/lib/consts')
local Bridge = require('ltra/lib/engine_bridge')
local Scales = require('ltra/lib/scales')
local GridHW = require('ltra/lib/grid_hw')
local GridPages = require('ltra/lib/grid_pages')
local Matrix = require('ltra/lib/mod_matrix')
local Midi16n = require('ltra/lib/midi_16n')
local Loopers = require('ltra/lib/loopers')
local UI = require('ltra/lib/ui')
local Params = require('ltra/lib/parameters')
local Arp = require('ltra/lib/arp')
local Enc = require('ltra/lib/controls_enc')
local Keys = require('ltra/lib/controls_key')
local Storage = require('ltra/lib/storage')

local g_state

function osc.event(path, args, from) Bridge.handle_osc(path, args) end

function init()
    print("LTRA: Initializing v1.4.11 (Core Architecture Fix)...")
    
    util.make_dir(_path.data .. "ltra")
    util.make_dir(_path.audio .. "ltra/snapshots")
    
    g_state = Globals.new()
    g_state.tap_last = 0
    g_state.loaded = false 
    
    Bridge.init(g_state)
    Scales.init(g_state)
    Matrix.init(g_state)
    Params.init(g_state)
    Loopers.init(g_state)
    UI.init(g_state)
    Arp.init(g_state)
    Enc.init(g_state)
    Keys.init(g_state)
    Storage.init(g_state)
    
    GridPages.init(g_state, nil)
    GridHW.init(g_state, 1, GridPages)
    GridPages.set_hw(GridHW)
    
    clock.run(function()
        clock.sleep(0.5)
        Midi16n.init(g_state, UI)
        Bridge.query_config()
        
        params:bang()
        g_state.dirty = true
        
        g_state.loaded = true
        print("LTRA: System Ready.")
    end)
    
    Bridge.set_filter_tone(1, 0.0)
    Bridge.set_filter_tone(2, 0.0)
    Bridge.set_param("delay_send", 0.5)
    
    local fps = metro.init()
    fps.time = 1/15 
    fps.event = function() 
        if g_state.ui_popup.active and util.time() > g_state.ui_popup.deadline then
            g_state.ui_popup.active = false
            g_state.dirty = true
        end
        if g_state.dirty then 
            -- FIX CRÍTICO: Llamar a la función global redraw() para respetar el menú de Norns
            redraw() 
            g_state.dirty = false 
        end
    end
    fps:start()
    
    local grid_fps = metro.init()
    grid_fps.time = 1/30
    grid_fps.event = function() 
        if g_state.loaded then GridHW.redraw() end 
    end
    grid_fps:start()
end

function key(n,z) 
    if not g_state or not g_state.loaded then return end
    pcall(Keys.event, n, z) 
end

function enc(n,d) 
    if not g_state or not g_state.loaded then return end
    pcall(Enc.delta, n, d) 
end

-- FIX CRÍTICO: Función global redraw() requerida por el sistema operativo de Norns
function redraw()
    if not g_state or not g_state.loaded then return end
    pcall(UI.redraw)
end

function cleanup() 
    print("LTRA: Cleanup")
    metro.free_all()
    softcut.buffer_clear()
end
