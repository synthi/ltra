-- code/ltra/lib/midi_16n.lua | v1.4.2
-- LTRA: 16n Control
-- FIX: Removed Ghost Locking (Immediate Response) & Safe Connect

local Midi16n = {}
local Globals
local UI_Ref = nil

local FADER_FUNC = {
    [1]="pitch1", [2]="pitch2", [3]="pitch3", [4]="pitch4",
    [5]="amp1",   [6]="amp2",   [7]="amp3",   [8]="amp4",
    [9]="filt1",  [10]="filt2", [11]="chaos", [12]="lfo1",
    [13]="lfo2",  [14]="delay_t",[15]="delay_fb",[16]="delay_send"
}

local function trigger_popup(text, val)
    if Globals.ui_popup then
        Globals.ui_popup.active = true
        Globals.ui_popup.text = text
        Globals.ui_popup.val = string.format("%.2f", val)
        Globals.ui_popup.deadline = util.time() + 2
        Globals.dirty = true
    end
end

local function process_fader(id, val)
    Globals.fader_values[id] = val
    local norm = val / 127
    
    local func = FADER_FUNC[id]
    if not func then return end
    
    local name = func:upper()
    
    -- FIX: Respuesta inmediata (Sin Ghost Locking)
    Globals.fader_virtual[id] = norm
    trigger_popup(name, norm)
    
    -- Mapeo Directo
    if func == "pitch1" then params:set("osc1_pitch", norm)
    elseif func == "pitch2" then params:set("osc2_pitch", norm)
    elseif func == "pitch3" then params:set("osc3_pitch", norm)
    elseif func == "pitch4" then params:set("osc4_pitch", norm)
    
    elseif func == "amp1" then params:set("osc1_vol", norm)
    elseif func == "amp2" then params:set("osc2_vol", norm)
    elseif func == "amp3" then params:set("osc3_vol", norm)
    elseif func == "amp4" then params:set("osc4_vol", norm)
    
    elseif func == "filt1" then params:set("filt1_tone", norm*2-1)
    elseif func == "filt2" then params:set("filt2_tone", norm*2-1)
    
    elseif func == "chaos" then params:set("chaos_rate", norm)
    elseif func == "lfo1" then params:set("lfo1_rate", norm)
    elseif func == "lfo2" then params:set("lfo2_rate", norm)
    
    elseif func == "delay_t" then params:set("delay_time", norm)
    elseif func == "delay_fb" then params:set("delay_fb", norm)
    elseif func == "delay_send" then params:set("delay_send", norm)
    end
end

function Midi16n.init(g_ref, ui_ref)
    Globals = g_ref
    UI_Ref = ui_ref
    
    -- Intentar conectar a todos los puertos MIDI activos
    for i=1,4 do
        local dev = midi.connect(i)
        if dev and dev.name then
            print("LTRA: Listening to MIDI port "..i.." ("..dev.name..")")
            dev.event = function(d)
                local m = midi.to_msg(d)
                if m.type == "cc" then
                    -- Asumimos canales 1-16. 16n suele enviar en CH1.
                    -- Mapeo estándar 16n: CC 32-47 o similar.
                    -- Ajuste: Si el usuario usa default 16n config (CC 32-47)
                    local id = -1
                    if m.cc >= 32 and m.cc <= 47 then id = m.cc - 31
                    elseif m.cc >= 1 and m.cc <= 16 then id = m.cc end -- Fallback
                    
                    if id >= 1 and id <= 16 then process_fader(id, m.val) end
                end
            end
        end
    end
end

return Midi16n
