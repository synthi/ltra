-- code/ltra/lib/arp.lua | v0.9.5
local Arp = {}
local Globals
local Scales = require 'ltra/lib/scales'
local Bridge = require 'ltra/lib/engine_bridge'

function Arp.init(g_ref)
    Globals = g_ref
    
    -- Reloj del Arpegiador
    clock.run(function()
        while true do
            -- Leer división del parámetro (1=1/4, 2=1/8, 3=1/16, 4=1/32)
            local div_idx = params:get("arp_div") or 2
            local sync_val = 1/4
            if div_idx == 2 then sync_val = 1/8
            elseif div_idx == 3 then sync_val = 1/16
            elseif div_idx == 4 then sync_val = 1/32 end
            
            clock.sync(sync_val)
            Arp.tick()
        end
    end)
end

function Arp.tick()
    -- Probabilidad de Caos
    local chaos_prob = params:get("arp_chaos") or 0.1

    for i=1, 4 do
        if Globals.voices[i].arp_enabled then
            local reg = Globals.arp.register[i]
            
            -- Rungler Logic (Shift Register)
            -- Bit nuevo = Último Bit XOR Penúltimo Bit (con probabilidad de error/caos)
            local last_bit = reg[8]
            local prev_bit = reg[7]
            local new_bit = (last_bit ~= prev_bit) and 1 or 0 -- XOR
            
            -- Inyección de caos
            if math.random() < chaos_prob then
                new_bit = 1 - new_bit -- Flip bit
            end
            
            -- Desplazar registro
            table.remove(reg) -- Quitar el último
            table.insert(reg, 1, new_bit) -- Insertar al principio
            
            -- Convertir los 3 primeros bits a valor 0-7 (DAC de 3 bits)
            local val = (reg[1] * 4) + (reg[2] * 2) + (reg[3] * 1)
            
            -- Normalizar 0-1
            local norm_val = val / 7
            Globals.arp.step_val[i] = norm_val
            
            -- Enviar al Engine (CV para matriz)
            -- Nota: Engine espera arp_cvX. Usamos un comando param genérico si no existe específico,
            -- o asumimos que Bridge.set_param maneja "arp_cv"..i
            engine.param("arp_cv"..i, norm_val)
            
            -- Generar Nota (Pitch)
            -- Mapear 0-1 a grados de escala (ej. 0-12)
            local deg = math.floor(norm_val * 12)
            local hz = Scales.get_freq(deg, 0)
            
            -- Aplicar al oscilador (sobrescribe fader pitch momentáneamente)
            Bridge.set_freq(i, hz)
            
            -- Disparar Envolvente
            Bridge.trigger_arp(i)
        end
    end
end

return Arp
