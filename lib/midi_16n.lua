-- lib/midi_16n.lua | v1.5.6
-- FIX: Fader Controlspec Mapping, Sync Logic

local Midi16n = {}
local Globals
local Consts = require 'ltra/lib/consts'
local UI_Ref = nil

local FADER_FUNC = {
    [1]="pitch1",[2]="pitch2", [3]="pitch3", [4]="pitch4",
    [5]="amp1",   [6]="amp2",   [7]="amp3",   [8]="amp4",
    [9]="filt1",[10]="filt2", [11]="chaos",[12]="lfo1",[13]="lfo2",  [14]="delay_t",[15]="delay_fb",[16]="delay_send"
}

local function trigger_popup(text, val_str)
    if Globals.ui_popup then
        Globals.ui_popup.active = true
        Globals.ui_popup.text = text
        Globals.ui_popup.val = val_str
        Globals.ui_popup.deadline = util.time() + 2
        Globals.dirty = true
    end
end

local function process_fader(id, val)
    local norm = val / 127
    local func = FADER_FUNC[id]
    if not func then return end
    local name = func:upper()
    
    if Globals.fader_ghost[id] then
        local virt = Globals.fader_virtual[id] or 0
        if math.abs(norm - virt) < 0.05 then
            Globals.fader_ghost[id] = false
        else
            local arrow = (norm < virt) and "->" or "<-"
            local display_str = string.format("%.2f %s %.2f", norm, arrow, virt)
            trigger_popup(name, display_str)
            Globals.fader_values[id] = val 
            return 
        end
    end
    
    if Globals.fader_values[id] == val then return end
    
    Globals.fader_values[id] = val
    Globals.fader_virtual[id] = norm
    
    -- FIX: Proper Controlspec Mapping and Sync Logic
    if func == "pitch1" then params:set("osc1_pitch", norm); trigger_popup(name, string.format("%.2f", norm))
    elseif func == "pitch2" then params:set("osc2_pitch", norm); trigger_popup(name, string.format("%.2f", norm))
    elseif func == "pitch3" then params:set("osc3_pitch", norm); trigger_popup(name, string.format("%.2f", norm))
    elseif func == "pitch4" then params:set("osc4_pitch", norm); trigger_popup(name, string.format("%.2f", norm))
    elseif func == "amp1" then params:set("osc1_vol", norm); trigger_popup(name, string.format("%.2f", norm))
    elseif func == "amp2" then params:set("osc2_vol", norm); trigger_popup(name, string.format("%.2f", norm))
    elseif func == "amp3" then params:set("osc3_vol", norm); trigger_popup(name, string.format("%.2f", norm))
    elseif func == "amp4" then params:set("osc4_vol", norm); trigger_popup(name, string.format("%.2f", norm))
    elseif func == "filt1" then 
        local hz = params:lookup_param("filt1_cutoff").controlspec:map(norm)
        params:set("filt1_cutoff", hz); trigger_popup(name, string.format("%.0f Hz", hz))
    elseif func == "filt2" then 
        local hz = params:lookup_param("filt2_cutoff").controlspec:map(norm)
        params:set("filt2_cutoff", hz); trigger_popup(name, string.format("%.0f Hz", hz))
    elseif func == "chaos" then 
        if params:get("chaos_sync") == 1 then
            local div = math.floor(norm * 7) + 1
            params:set("chaos_div", div)
            trigger_popup("CHAOS SYNC", Consts.SYNC_DIVS[div].name)
        else
            local hz = params:lookup_param("chaos_rate").controlspec:map(norm)
            params:set("chaos_rate", hz); trigger_popup(name, string.format("%.2f Hz", hz))
        end
    elseif func == "lfo1" then 
        if params:get("lfo1_sync") == 1 then
            local div = math.floor(norm * 7) + 1
            params:set("lfo1_div", div)
            trigger_popup("LFO1 SYNC", Consts.SYNC_DIVS[div].name)
        else
            local hz = params:lookup_param("lfo1_rate").controlspec:map(norm)
            params:set("lfo1_rate", hz); trigger_popup(name, string.format("%.2f Hz", hz))
        end
    elseif func == "lfo2" then 
        if params:get("lfo2_sync") == 1 then
            local div = math.floor(norm * 7) + 1
            params:set("lfo2_div", div)
            trigger_popup("LFO2 SYNC", Consts.SYNC_DIVS[div].name)
        else
            local hz = params:lookup_param("lfo2_rate").controlspec:map(norm)
            params:set("lfo2_rate", hz); trigger_popup(name, string.format("%.2f Hz", hz))
        end
    elseif func == "delay_t" then 
        local t = params:lookup_param("fx_tape_time").controlspec:map(norm)
        params:set("fx_tape_time", t); trigger_popup("TAPE TIME", string.format("%.2f s", t))
    elseif func == "delay_fb" then 
        local fb = params:lookup_param("fx_tape_feedback").controlspec:map(norm)
        params:set("fx_tape_feedback", fb); trigger_popup("TAPE FB", string.format("%.2f", fb))
    elseif func == "delay_send" then 
        params:set("delay_send", norm); trigger_popup(name, string.format("%.2f", norm))
    end
end

function Midi16n.init(g_ref, ui_ref)
    Globals = g_ref
    UI_Ref = ui_ref
    
    for i=1, 16 do Globals.fader_ghost[i] = true end

    Midi16n.clock_id = clock.run(function()
        local found = false
        for _, dev in pairs(midi.devices) do
            if dev.name and (string.find(string.lower(dev.name), "16n") or string.find(string.lower(dev.name), "fade")) then
                print("LTRA: Found 16n/Faderbank: " .. dev.name)
                local m = midi.connect(dev.port)
                m.event = function(d)
                    local msg = midi.to_msg(d)
                    if msg.type == "cc" then
                        local id = msg.cc - 31
                        if id < 1 then id = msg.cc end 
                        if id >= 1 and id <= 16 then process_fader(id, msg.val) end
                    end
                end
                found = true
            end
        end
        
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

function Midi16n.stop()
    if Midi16n.clock_id then clock.cancel(Midi16n.clock_id) end
end

return Midi16n
