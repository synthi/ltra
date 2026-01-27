-- code/ltra/lib/seq_gestures.lua | v0.6
-- LTRA: Secuenciador de Gestos (Elastic Time)

local Gestures = {}
local Globals
local GridPages -- Inyección

function Gestures.init(g_ref, pages_ref)
    Globals = g_ref
    GridPages = pages_ref
    
    clock.run(function()
        while true do
            clock.sync(1/24)
            Gestures.tick()
        end
    end)
end

function Gestures.record_event(voice_idx, x, y, z)
    local seq = Globals.gestures[voice_idx]
    if seq.state == 1 then -- REC
        local now = clock.get_beats()
        local dt = now - seq.beat_start
        table.insert(seq.data, {dt=dt, x=x, y=y, z=z})
    end
end

function Gestures.tick()
    local now = clock.get_beats()
    
    for i=1, 4 do
        local seq = Globals.gestures[i]
        
        -- Animación visual (Pulsación)
        if seq.state == 1 then -- Rec
            seq.pulse_visual = math.abs(math.sin(now * 4)) * 10 + 5
        elseif seq.state == 4 then -- Dub
            seq.pulse_visual = math.abs(math.sin(now * 16)) * 10 + 5
        end
        
        if seq.state == 2 then -- Play
            -- Lógica de reproducción simplificada para v0.6
            -- (Requiere gestión de índices y loops precisa)
        end
    end
end

function Gestures.toggle(idx)
    local seq = Globals.gestures[idx]
    if seq.state == 0 then -- Empty -> Rec
        seq.state = 1
        seq.data = {}
        seq.beat_start = clock.get_beats()
    elseif seq.state == 1 then -- Rec -> Play
        seq.state = 2
        -- Cerrar loop
    elseif seq.state == 2 then -- Play -> Stop
        seq.state = 3
    elseif seq.state == 3 then -- Stop -> Play
        seq.state = 2
    end
end

return Gestures
