-- lib/loopers.lua | v1.5.13
-- FIX: Overflow Protection (30s), Fade Out Logic, Param Setters

local Loopers = {}
local Globals

function Loopers.init(g_ref)
    Globals = g_ref
    audio.level_eng_cut(1)
    
    for i=1, 4 do
        softcut.enable(i, 1)
        softcut.buffer(i, 1)
        softcut.level(i, 1.0)
        softcut.loop(i, 1)
        softcut.rate(i, 1.0)
        softcut.fade_time(i, 0.1)
        softcut.post_filter_fc(i, 18000)
        
        softcut.level_input_cut(1, i, 1.0)
        softcut.level_input_cut(2, i, 1.0)
        
        if i==1 then softcut.pan(i, -0.5)
        elseif i==2 then softcut.pan(i, 0.5)
        elseif i==3 then softcut.pan(i, -1.0)
        elseif i==4 then softcut.pan(i, 1.0) end
        
        local start_pos = (i-1) * 30
        softcut.loop_start(i, start_pos)
        softcut.loop_end(i, start_pos + 30)
        softcut.position(i, start_pos)
        
        -- State: 0=Empty, 1=Rec, 2=Play, 3=Dub, 4=Stop, 5=Fading
        Globals.loopers = Globals.loopers or {}
        Globals.loopers[i] = { state = 0, start_pos = start_pos, end_pos = start_pos + 30, rec_start_time = 0 }
    end
end

-- Setters for parameters.lua
function Loopers.set_vol(idx, val)
    local l = Globals.loopers[idx]
    if l and l.state ~= 5 then softcut.level(idx, val) end
end
function Loopers.set_cut(idx, val) softcut.post_filter_fc(idx, val) end
function Loopers.set_res(idx, val) softcut.post_filter_rq(idx, util.linlin(0, 1, 2.0, 0.1, val)) end
function Loopers.set_pan(idx, val) softcut.pan(idx, val) end

function Loopers.close_loop(idx)
    local l = Globals.loopers[idx]
    if l.state == 1 then
        if l.overflow_clock then clock.cancel(l.overflow_clock); l.overflow_clock = nil end
        l.state = 2
        local elapsed = util.time() - l.rec_start_time
        if elapsed > 30 then elapsed = 30 end
        l.end_pos = l.start_pos + elapsed
        softcut.loop_end(idx, l.end_pos)
        softcut.rec(idx, 0)
    end
end

function Loopers.stop_looper(idx)
    local l = Globals.loopers[idx]
    local fade_time = params:get("looper"..idx.."_fade") or 0
    
    if fade_time > 0 then
        l.state = 5 -- Fading
        if l.fade_clock then clock.cancel(l.fade_clock) end
        l.fade_clock = clock.run(function()
            local steps = 20
            local step_time = fade_time / steps
            local start_vol = params:get("looper"..idx.."_vol") or 1.0
            for i=1, steps do
                local current_vol = start_vol * (1 - (i/steps))
                softcut.level(idx, current_vol)
                clock.sleep(step_time)
            end
            softcut.play(idx, 0)
            softcut.rec(idx, 0)
            softcut.level(idx, start_vol) -- Restore volume for next play
            l.state = 4
        end)
    else
        l.state = 4
        softcut.play(idx, 0)
        softcut.rec(idx, 0)
    end
end

function Loopers.handle_button(idx, shift)
    local l = Globals.loopers[idx]
    
    if shift then
        if l.state == 2 or l.state == 3 then
            Loopers.stop_looper(idx)
        elseif l.state == 4 then
            l.state = 2
            softcut.play(idx, 1)
        elseif l.state == 5 then
            -- Cancel fade and resume play
            if l.fade_clock then clock.cancel(l.fade_clock) end
            softcut.level(idx, params:get("looper"..idx.."_vol") or 1.0)
            l.state = 2
            softcut.play(idx, 1)
        end
        return
    end
    
    if l.state == 0 then
        l.state = 1
        l.rec_start_time = util.time()
        softcut.position(idx, l.start_pos)
        softcut.rec_level(idx, 1.0)
        softcut.pre_level(idx, 0.0)
        softcut.rec(idx, 1)
        softcut.play(idx, 1)
        
        -- FIX: Overflow Protection (Max 30s)
        l.overflow_clock = clock.run(function()
            clock.sleep(30)
            Loopers.close_loop(idx)
        end)
        
    elseif l.state == 1 then
        Loopers.close_loop(idx)
    elseif l.state == 2 then
        l.state = 3
        softcut.rec_level(idx, 1.0)
        softcut.pre_level(idx, 1.0)
        softcut.rec(idx, 1)
    elseif l.state == 3 then
        l.state = 2
        softcut.rec(idx, 0)
    elseif l.state == 4 then
        l.state = 2
        softcut.play(idx, 1)
    end
end

function Loopers.clear(idx)
    local l = Globals.loopers[idx]
    if l.fade_clock then clock.cancel(l.fade_clock) end
    if l.overflow_clock then clock.cancel(l.overflow_clock) end
    l.state = 0
    softcut.rec(idx, 0)
    softcut.play(idx, 0)
    softcut.level(idx, params:get("looper"..idx.."_vol") or 1.0)
    softcut.buffer_clear_region(l.start_pos, 30)
    softcut.loop_end(idx, l.start_pos + 30)
end

return Loopers
