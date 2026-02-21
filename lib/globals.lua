-- code/ltra/lib/globals.lua | v1.4.7
-- LTRA: Global State
-- FIX: Added matrix_quant table for Q/F selection

local Globals = {}
local Consts = require 'ltra/lib/consts'

function Globals.new()
    local state = {
        dirty = true,
        engine_bus_id = nil,
        page = 1,
        loading_pset = false,
        
        menu_mode = Consts.MENU.NONE,
        menu_target = nil, 
        ui_popup = { active=false, text="", val="", deadline=0 },
        
        k2_held = false, k3_held = false,
        latch_mode = false,
        
        led_cache = {}, button_state = {}, grid_timers = {},
        
        visuals = { amp_l=0, amp_r=0, lfo_vals={0,0}, chaos_val=0, tape_heads={0,0,0} },

        matrix = {},
        matrix_quant = {}, -- FIX: Tabla de estado Q/F (1=Q, 0=F)
        voices = {}, 
        tracks = {}, 
        snapshots = {}, 
        
        arp = {
            register = {
                {0,0,0,0,0,0,0,0}, {0,0,0,0,0,0,0,0}, 
                {0,0,0,0,0,0,0,0}, {0,0,0,0,0,0,0,0}
            },
            step_val = {0,0,0,0}
        },
        
        fader_values = {}, fader_virtual = {}, fader_ghost = {},
        
        scale = {
            current_idx = 1, root_note = 1,
            custom_slots = {{0,2,4,5,7,9,11}, {0,2,3,5,7,8,10}, {0,1,5,7,8}, {0,2,4,6,8,10}}
        }
    }

    for x=1, 16 do
        state.led_cache[x] = {}; state.button_state[x] = {}; state.grid_timers[x] = {}
        for y=1, 8 do state.led_cache[x][y]=0; state.button_state[x][y]=false; state.grid_timers[x][y]=0 end
        state.fader_values[x]=0; state.fader_virtual[x]=0
    end

    -- Init Matrix & Quantization
    for s=1, 5 do 
        state.matrix[s] = {}
        state.matrix_quant[s] = {} 
        for d=1, 16 do 
            state.matrix[s][d] = 0.0 
            state.matrix_quant[s][d] = 1 -- Default: Quantized (1)
        end 
    end
    
    for i=1, 4 do state.voices[i] = {shape=0, pan=0, tune=0, arp_enabled=false, to_looper=true, latched=false} end

    for i=1, 3 do
        state.tracks[i] = {
            state=1, speed=1.0, vol=0.8, pan=0.0, 
            send_space=0.0, pre_fx=false, feedback=1.0,
            rec_len=0, loop_start=0, loop_end=1
        }
    end
    
    for i=1, 6 do state.snapshots[i] = nil end

    return state
end

return Globals
