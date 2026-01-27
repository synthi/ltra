-- code/ltra/lib/arp.lua | v0.6
-- LTRA: Shift Register Arpeggiator (Pseudo-Rungler)

local Arp = {}
local Globals
local Scales = require 'ltra/lib/scales'
local Bridge = require 'ltra/lib/engine_bridge'

function Arp.init(g_ref) Globals = g_ref end

-- Avanzar un paso el registro de la voz indicada
function Arp.pulse(voice_idx)
    if not Globals.voices[voice_idx].arp_enabled then return end
    
    -- Estado actual (0-255 simulado como float 0-1)
    local current = Globals.arp.step_val[voice_idx] or 0
    
    -- Lógica Shift Register:
    -- Tomamos el valor, lo desplazamos y añadimos un bit de caos
    -- Simulación matemática:
    local chaos_bit = (math.random() > 0.5) and 0.1 or 0.0
    local next_val = (current + 0.1 + chaos_bit) % 1.0
    
    -- Cuantizar a pasos discretos (8 pasos como un registro de 3 bits)
    next_val = math.floor(next_val * 8) / 8
    
    Globals.arp.step_val[voice_idx] = next_val
    
    -- Convertir voltaje a frecuencia de escala
    local hz = Scales.get_freq_from_voltage(next_val)
    
    -- Enviar al Engine
    Bridge.set_freq(voice_idx, hz)
end

-- Resetear fases (al iniciar transporte)
function Arp.reset()
    for i=1,4 do Globals.arp.step_val[i] = 0 end
end

return Arp
