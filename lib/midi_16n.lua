-- code/ltra/lib/midi_16n.lua | v1.4.7
-- LTRA: 16n Control
-- FIX: Name Detection + Jitter Filter

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
    -- FIX: Jitter Filter (Hysteresis)
    -- Only process if change is > 1 (out of 127)
    local old_val = Globals.fader_values[id] or -1
    if math.abs(val - old_val) <= 1 then return end
    
    Globals.fader_values[id] = val
    local norm = val / 127
    
    local func = FADER_FUNC[id]
    if not func then return end
    
    local name = func:upper()
    
    Globals.fader_virtual[id] = norm
    trigger_popup(name, norm)
    
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
    
    for i=1, 16 do Globals.fader_ghost[i] = true end

    clock.run(function()
        -- FIX: Name Detection Strategy (Ncoco style)
        local found = false
        for _, dev in pairs(midi.devices) do
            if dev.name and (string.find(string.lower(dev.name), "16n") or string.find(string.lower(dev.name), "fade")) then
                print("LTRA: Found 16n/Faderbank: " .. dev.name)
                local m = midi.connect(dev.port)
                m.event = function(d)
                    local msg = midi.to_msg(d)
                    if msg.type == "cc" then
                        local id = msg.cc - 31
                        if id < 1 then id = msg.cc end -- Fallback for CC 1-16
                        if id >= 1 and id <= 16 then process_fader(id, msg.val) end
                    end
                end
                found = true
            end
        end
        
        -- Fallback: Connect to all ports if no specific device found
        if not found then
            print("LTRA: 16n not detected by name. Listening on all ports.")
            for i = 1, 4 do
                local dev = midi.connect(i)
                if dev and dev.name then
                    dev.event = function(d) 
                        local m = midi.to_msg(d)
                        if m.type=="cc" then 
                            local id = m.cc - 31 
                            if id < 1 then id = m.cc end
                            if id>=1 and id<=16 then process_fader(id, m.val) end 
                        end 
                    end
                end
            end
        end
    end)
end

return Midi16n
