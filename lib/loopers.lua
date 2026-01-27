-- code/ltra/lib/loopers.lua | v0.6
-- LTRA: Softcut Manager (Partitioned Buffers)

local Loopers = {}
local Globals
local Consts = require 'ltra/lib/consts'

function Loopers.init(g_ref)
    Globals = g_ref
    
    audio.level_adc_cut(1) -- Input fisico a SC (monitor)
    
    for i=1, 3 do
        local pair = Consts.LOOPER_PAIRS[i]
        local bounds = Consts.LOOPER_BOUNDS[i]
        
        for _, v in ipairs(pair) do
            softcut.enable(v, 1)
            softcut.buffer(v, (v%2 == 1) and 1 or 2)
            softcut.level(v, 1.0)
            softcut.loop(v, 1)
            
            -- LIMITES ESTRICTOS POR PISTA
            softcut.loop_start(v, bounds.min)
            softcut.loop_end(v, bounds.max)
            softcut.position(v, bounds.min)
            
            softcut.play(v, 1)
            softcut.rate(v, 1.0)
            softcut.fade_time(v, 0.05) -- Anti-click
            
            softcut.post_filter_lp(v, 1.0)
            softcut.post_filter_dry(v, 0.0)
            softcut.post_filter_fc(v, 18000)
            softcut.post_filter_rq(v, 2.0)
        end
    end
    
    softcut.event_phase(function(v, pos)
        -- Normalizar posición para visualización (0.0 a 1.0 dentro del tramo)
        if v == 1 or v == 3 or v == 5 then
            local track_idx = (v+1)/2
            local bounds = Consts.LOOPER_BOUNDS[track_idx]
            local len = bounds.max - bounds.min
            local rel_pos = (pos - bounds.min) / len
            Globals.visuals.tape_heads[track_idx] = util.clamp(rel_pos, 0, 1)
            Globals.dirty = true -- Redraw grid/screen
        end
    end)
    
    softcut.poll_start_phase()
end

function Loopers.configure_audio_routing(g_ref)
    -- En v0.6 usamos el ruteo global de Norns
    -- Engine -> DAC (y Softcut escucha DAC por defecto si no se corta)
    -- Softcut -> DAC
    -- No hay ruteo especial individual posible sin hacks.
    print("LTRA: Audio Routing Configured (Standard)")
end

function Loopers.transport_action(track_idx, action)
    local t = Globals.tracks[track_idx]
    local pair = Consts.LOOPER_PAIRS[track_idx]
    
    -- Máquina de estados simple v0.6
    if action == "press" then
        if t.state == 1 then -- Empty -> Rec
            t.state = 2
            for _, v in ipairs(pair) do
                softcut.pre_level(v, 0.0)
                softcut.rec_level(v, 1.0)
                softcut.rec(v, 1)
            end
        elseif t.state == 2 then -- Rec -> Play
            t.state = 3
            for _, v in ipairs(pair) do
                softcut.rec(v, 0)
            end
        elseif t.state == 3 then -- Play -> Dub
            t.state = 4
            for _, v in ipairs(pair) do
                softcut.pre_level(v, t.feedback)
                softcut.rec_level(v, 1.0)
                softcut.rec(v, 1)
            end
        elseif t.state == 4 then -- Dub -> Play
            t.state = 3
            for _, v in ipairs(pair) do softcut.rec(v, 0) end
        end
    elseif action == "hold" then
        -- Clear
        t.state = 1
        for _, v in ipairs(pair) do 
            softcut.rec(v, 0); softcut.rate(v, 1.0)
            -- Reset position
            local bounds = Consts.LOOPER_BOUNDS[track_idx]
            softcut.position(v, bounds.min)
        end
    end
end

return Loopers
