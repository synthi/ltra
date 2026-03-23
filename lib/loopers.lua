-- lib/loopers.lua v1.5.14
-- FIX: 80s Buffer Allocation, Bidirectional Fade In/Out Logic

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
        
        -- FIX: 80 seconds per looper (349s total memory / 4 = 87.25s. 80s is safe margin)
        local start_pos = (i-1) * 80
        softcut.loop_start(i, start_pos)
        softcut.loop_end(i, start_pos + 80)
        softcut.position(i, start_pos)
        
        -- State: 0=Empty, 1=Rec, 2=Play, 3=Dub, 4=Stop, 5=Fading Out, 6=Fading In
        Globals.loopers = Globals.loopers or {}
        Globals.loopers[i] = { state = 0, start_pos = start_pos, end_pos = start_pos + 80, rec_start_time = 0, current_vol = 1.0 }
    end
end

function Loopers.set_vol(idx, val)
    local l = Globals.loopers[idx]
    if l and (l.state == 1 or l.state == 2 or l.state == 3) then 
        softcut.level(idx, val) 
        l.current_vol = val
    end
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
        if elapsed > 80 then elapsed = 80 end -- FIX: Clamp to 80s
        l.end_pos = l.start_pos + elapsed
        softcut.loop_end(idx, l.end_pos)
        softcut.rec(idx, 0)
    end
end

-- FIX: Bidirectional Fade Logic
function Loopers.do_fade(idx, is_fade_in)
    local l = Globals.loopers[idx]
    local fade_time = params:get("looper"..idx.."_fade") or 0
    local target_vol = params:get("looper"..idx.."_vol") or 1.0

    if l.fade_clock then clock.cancel(l.fade_clock) end

    if fade_time <= 0 then
        if is_fade_in then
            l.current_vol = target_vol
            softcut.level(idx, target_vol)
            softcut.play(idx, 1)
            l.state = 2
        else
            l.current_vol = 0
            softcut.level(idx, 0)
            softcut.play(idx, 0)
            softcut.rec(idx, 0)
            l.state = 4
        end
        return
    end

    local steps = math.floor(fade_time * 20)
    if steps < 1 then steps = 1 end
    local step_time = fade_time / steps

    if is_fade_in then
        l.state = 6
        local start_vol = l.current_vol or 0
        softcut.level(idx, start_vol)
        softcut.play(idx, 1)

        l.fade_clock = clock.run(function()
            for i=1, steps do
                l.current_vol = start_vol + (target_vol - start_vol) * (i/steps)
                softcut.level(idx, l.current_vol)
                clock.sleep(step_time)
            end
            l.current_vol = target_vol
            softcut.level(idx, target_vol)
            l.state = 2
        end)
    else
        l.state = 5
        local start_vol = l.current_vol or target_vol
        l.fade_clock = clock.run(function()
            for i=1, steps do
                l.current_vol = start_vol * (1 - (i/steps))
                softcut.level(idx, l.current_vol)
                clock.sleep(step_time)
            end
            l.current_vol = 0
            softcut.level(idx, 0)
            softcut.play(idx, 0)
            softcut.rec(idx, 0)
            l.state = 4
        end)
    end
end

function Loopers.handle_button(idx, shift)
    local l = Globals.loopers[idx]
    
    if shift then
        if l.state == 2 or l.state == 3 or l.state == 6 then
            Loopers.do_fade(idx, false) -- Fade Out to Stop
        elseif l.state == 4 or l.state == 5 then
            Loopers.do_fade(idx, true) -- Fade In to Play
        end
        return
    end
    
    if l.state == 0 then
        l.state = 1
        l.rec_start_time = util.time()
        l.current_vol = params:get("looper"..idx.."_vol") or 1.0
        softcut.level(idx, l.current_vol)
        softcut.position(idx, l.start_pos)
        softcut.rec_level(idx, 1.0)
        softcut.pre_level(idx, 0.0)
        softcut.rec(idx, 1)
        softcut.play(idx, 1)
        
        -- FIX: Overflow Protection (Max 80s)
        l.overflow_clock = clock.run(function()
            clock.sleep(80)
            Loopers.close_loop(idx)
        end)
        
    elseif l.state == 1 then
        Loopers.close_loop(idx)
    elseif l.state == 2 or l.state == 6 then
        if l.fade_clock then clock.cancel(l.fade_clock) end
        l.state = 3
        l.current_vol = params:get("looper"..idx.."_vol") or 1.0
        softcut.level(idx, l.current_vol)
        softcut.rec_level(idx, 1.0)
        softcut.pre_level(idx, 1.0)
        softcut.rec(idx, 1)
    elseif l.state == 3 then
        l.state = 2
        softcut.rec(idx, 0)
    elseif l.state == 4 or l.state == 5 then
        Loopers.do_fade(idx, true) -- Fade In to Play
    end
end

function Loopers.clear(idx)
    local l = Globals.loopers[idx]
    if l.fade_clock then clock.cancel(l.fade_clock) end
    if l.overflow_clock then clock.cancel(l.overflow_clock) end
    l.state = 0
    l.current_vol = 0
    softcut.rec(idx, 0)
    softcut.play(idx, 0)
    softcut.level(idx, 0)
    softcut.buffer_clear_region(l.start_pos, 80)
    softcut.loop_end(idx, l.start_pos + 80)
end

return Loopers
