-- lib/midi_16n.lua | v2.6.0
-- FIX: 1:1 Grid Matrix Mapping (Faders 9-12 = Shape)

local Midi16n = {}
local Globals
local Consts = require 'ltra/lib/consts'
local UI_Ref = nil

local FADER_FUNC = {
    [1]="pitch1", [2]="pitch2", [3]="pitch3", [4]="pitch4",
    [5]="amp1",   [6]="amp2",   [7]="amp3",   [8]="amp4",
    [9]="shape1",[10]="shape2",[11]="shape3",[12]="shape4",
    [13]="filt1", [14]="filt2", [15]="tape_time",[16]="tape_fb"
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
    
    if func == "pitch1" then params:set("osc1_pitch", norm); trigger_popup(name, string.format("%.2f", norm))
    elseif func == "pitch2" then params:set("osc2_pitch", norm); trigger_popup(name, string.format("%.2f", norm))
    elseif func == "pitch3" then params:set("osc3_pitch", norm); trigger_popup(name, string.format("%.2f", norm))
    elseif func == "pitch4" then params:set("osc4_pitch", norm); trigger_popup(name, string.format("%.2f", norm))
    elseif func == "amp1" then params:set("osc1_vol", norm); trigger_popup(name, string.format("%.2f", norm))
    elseif func == "amp2" then params:set("osc2_vol", norm); trigger_popup(name, string.format("%.2f", norm))
    elseif func == "amp3" then params:set("osc3_vol", norm); trigger_popup(name, string.format("%.2f", norm))
    elseif func == "amp4" then params:set("osc4_vol", norm); trigger_popup(name, string.format("%.2f", norm))
    elseif func == "shape1" then params:set("osc1_shape", norm * 10.0); trigger_popup(name, string.format("%.2f", norm * 10.0))
    elseif func == "shape2" then params:set("osc2_shape", norm * 10.0); trigger_popup(name, string.format("%.2f", norm * 10.0))
    elseif func == "shape3" then params:set("osc3_shape", norm * 10.0); trigger_popup(name, string.format("%.2f", norm * 10.0))
    elseif func == "shape4" then params:set("osc4_shape", norm * 10.0); trigger_popup(name, string.format("%.2f", norm * 10.0))
    elseif func == "filt1" then 
        local hz = util.linexp(0, 1, 20, 18000, norm)
        params:set("filt1_cutoff", hz); trigger_popup(name, string.format("%.0f Hz", hz))
    elseif func == "filt2" then 
        local hz = util.linexp(0, 1, 20, 18000, norm)
        params:set("filt2_cutoff", hz); trigger_popup(name, string.format("%.0f Hz", hz))
    elseif func == "tape_time" then 
        local t = util.linexp(0, 1, 0.01, 2.0, norm)
        params:set("tapecho_time", t); trigger_popup("TAPE TIME", string.format("%.2f s", t))
    elseif func == "tape_fb" then 
        local fb = util.linlin(0, 1, 0.0, 1.2, norm)
        params:set("tapecho_feedback", fb); trigger_popup("TAPE FB", string.format("%.2f", fb))
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

function Midi16n.sync_faders()
    if not Globals then return end
    for id=1, 16 do
        Globals.fader_ghost[id] = true
        local func = FADER_FUNC[id]
        if func then
            local norm = 0
            if func:match("^pitch%d") then
                norm = params:get("osc"..func:sub(-1).."_pitch")
            elseif func:match("^amp%d") then
                norm = params:get("osc"..func:sub(-1).."_vol")
            elseif func:match("^shape%d") then
                local val = params:get("osc"..func:sub(-1).."_shape")
                norm = util.linlin(0, 10.0, 0, 1, val)
            elseif func:match("^filt%d") then
                local val = params:get("filt"..func:sub(-1).."_cutoff")
                norm = util.explin(20, 18000, 0, 1, val)
            elseif func == "tape_time" then
                local val = params:get("tapecho_time")
                norm = util.explin(0.01, 2.0, 0, 1, val)
            elseif func == "tape_fb" then
                local val = params:get("tapecho_feedback")
                norm = util.linlin(0.0, 1.2, 0, 1, val)
            end
            Globals.fader_virtual[id] = util.clamp(norm, 0, 1)
        end
    end
    Globals.dirty = true
end

return Midi16n
