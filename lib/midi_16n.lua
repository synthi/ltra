-- code/ltra/lib/midi_16n.lua | v0.9.5
local Midi16n = {}
local Globals
local Bridge = require 'ltra/lib/engine_bridge'
local Scales = require 'ltra/lib/scales'
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

local function check_takeover(id, val)
    local virt = Globals.fader_virtual[id]
    if Globals.fader_ghost[id] then
        if math.abs(val - virt) < 0.05 then 
            Globals.fader_ghost[id] = nil
            return true 
        end
        return false
    end
    return true
end

local function process_fader(id, val)
    Globals.fader_values[id] = val
    local norm = val / 127
    
    if not check_takeover(id, norm) then Globals.dirty = true; return end
    Globals.fader_virtual[id] = norm
    
    local func = FADER_FUNC[id]
    
    if func == "pitch1" then params:set("osc1_pitch", norm); trigger_popup("PITCH 1", norm)
    elseif func == "pitch2" then params:set("osc2_pitch", norm); trigger_popup("PITCH 2", norm)
    elseif func == "pitch3" then params:set("osc3_pitch", norm); trigger_popup("PITCH 3", norm)
    elseif func == "pitch4" then params:set("osc4_pitch", norm); trigger_popup("PITCH 4", norm)
    
    elseif func == "amp1" then params:set("osc1_vol", norm); trigger_popup("VOL 1", norm)
    elseif func == "amp2" then params:set("osc2_vol", norm)
    elseif func == "amp3" then params:set("osc3_vol", norm)
    elseif func == "amp4" then params:set("osc4_vol", norm)
    
    elseif func == "filt1" then params:set("filt1_tone", norm*2-1); trigger_popup("FILT 1", norm*2-1)
    elseif func == "filt2" then params:set("filt2_tone", norm*2-1); trigger_popup("FILT 2", norm*2-1)
    
    elseif func == "chaos" then params:set("chaos_rate", norm); trigger_popup("CHAOS", norm)
    elseif func == "lfo1" then params:set("lfo1_rate", norm); trigger_popup("LFO 1", norm)
    elseif func == "lfo2" then params:set("lfo2_rate", norm); trigger_popup("LFO 2", norm)
    
    elseif func == "delay_t" then params:set("delay_time", norm); trigger_popup("DELAY T", norm)
    elseif func == "delay_fb" then params:set("delay_fb", norm); trigger_popup("DELAY FB", norm)
    elseif func == "delay_send" then params:set("delay_send", norm); trigger_popup("DELAY SEND", norm)
    end
end

function Midi16n.init(g_ref, ui_ref)
    Globals = g_ref
    UI_Ref = ui_ref
    clock.run(function()
        midi.connect(); clock.sleep(0.2)
        local dev = midi.connect(1)
        if dev then
            dev.event = function(d) 
                local m = midi.to_msg(d)
                if m.type=="cc" then 
                    local id = m.cc - 31 
                    if id>=1 and id<=16 then process_fader(id, m.val) end 
                end 
            end
            pcall(function() midi.send(dev, {0xf0, 0x7d, 0x00, 0x00, 0x1f, 0xf7}) end)
        end
    end)
end

return Midi16n
