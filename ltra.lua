-- ltra.lua | v1.4.8
-- LTRA: Main Script
-- FIX: 3.1 Boot Protection, Hardware Isolation & State Sync

engine.name = 'Ltra'

local Globals = include('lib/globals')
local Consts = include('lib/consts')
local Bridge = include('lib/engine_bridge')
local Scales = include('lib/scales')
local GridHW = include('lib/grid_hw')
local GridPages = include('lib/grid_pages')
local Matrix = include('lib/mod_matrix')
local Midi16n = include('lib/midi_16n')
local Loopers = include('lib/loopers')
local UI = include('lib/ui')
local Params = include('lib/parameters')
local Arp = include('lib/arp')
local Enc = include('lib/controls_enc')
local Keys = include('lib/controls_key')
local Storage = include('lib/storage')

local g_state

function osc.event(path, args, from) Bridge.handle_osc(path, args) end

function init()
    print("LTRA: Initializing v1.4.8 (Core 3.1 Fixes)...")
    
    util.make_dir(_path.data .. "ltra")
    util.make_dir(_path.audio .. "ltra/snapshots")
    
    g_state = Globals.new()
    g_state.tap_last = 0
    g_state.loaded = false -- FIX 3.1: Boot Flag
    
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
        
        -- FIX 3.1: Sistema 100% Listo. Desbloquear hardware.
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
            -- FIX 3.1: pcall en redraw para evitar crash loops
            local status, err = pcall(UI.redraw)
            if not status then print("Redraw Fault: " .. tostring(err)) end
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

-- FIX 3.1: Aislamiento total de interrupciones asíncronas
function key(n,z) 
    if not g_state or not g_state.loaded then return end
    pcall(Keys.event, n, z) 
end

function enc(n,d) 
    if not g_state or not g_state.loaded then return end
    pcall(Enc.delta, n, d) 
end

function cleanup() 
    print("LTRA: Cleanup")
    metro.free_all()
    softcut.buffer_clear()
end
