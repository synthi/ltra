-- lib/loopers.lua | v1.5.12
-- FIX: Removed API Hallucinations (level_cut_cut, position_cut), Bulletproof Loop Closing

local Loopers = {}
local Globals

function Loopers.init(g_ref)
    Globals = g_ref
    
    -- Route Engine to Softcut
    audio.level_eng_cut(1)
    
    for i=1, 4 do
        softcut.enable(i, 1)
        softcut.buffer(i, 1)
        softcut.level(i, 1.0)
        softcut.loop(i, 1)
        softcut.rate(i, 1.0)
        softcut.fade_time(i, 0.1)
        softcut.post_filter_fc(i, 18000)
        
        -- Mono mix from stereo engine
        softcut.level_input_cut(1, i, 1.0)
        softcut.level_input_cut(2, i, 1.0)
        
        -- Pan distribution
        if i==1 then softcut.pan(i, -0.5)
        elseif i==2 then softcut.pan(i, 0.5)
        elseif i==3 then softcut.pan(i, -1.0)
        elseif i==4 then softcut.pan(i, 1.0) end
        
        -- 30s buffer per looper
        local start_pos = (i-1) * 30
        softcut.loop_start(i, start_pos)
        softcut.loop_end(i, start_pos + 30)
        softcut.position(i, start_pos)
        
        -- State: 0=Empty, 1=Rec, 2=Play, 3=Dub, 4=Stop
        Globals.loopers = Globals.loopers or {}
        Globals.loopers[i] = { state = 0, start_pos = start_pos, end_pos = start_pos + 30, rec_start_time = 0 }
    end
end

function Loopers.handle_button(idx, shift)
    local l = Globals.loopers[idx]
    
    if shift then
        if l.state == 2 or l.state == 3 then
            l.state = 4
            softcut.play(idx, 0)
            softcut.rec(idx, 0)
        elseif l.state == 4 then
            l.state = 2
            softcut.play(idx, 1)
        end
        return
    end
    
    if l.state == 0 then
        -- Empty -> Rec
        l.state = 1
        l.rec_start_time = util.time() -- FIX: Precise time tracking
        softcut.position(idx, l.start_pos)
        softcut.rec_level(idx, 1.0)
        softcut.pre_level(idx, 0.0)
        softcut.rec(idx, 1)
        softcut.play(idx, 1)
    elseif l.state == 1 then
        -- Rec -> Play (Close Loop)
        l.state = 2
        local elapsed = util.time() - l.rec_start_time -- FIX: Math-based loop closing
        l.end_pos = l.start_pos + elapsed
        softcut.loop_end(idx, l.end_pos)
        softcut.rec(idx, 0)
    elseif l.state == 2 then
        -- Play -> Dub
        l.state = 3
        softcut.rec_level(idx, 1.0)
        softcut.pre_level(idx, 1.0)
        softcut.rec(idx, 1)
    elseif l.state == 3 then
        -- Dub -> Play
        l.state = 2
        softcut.rec(idx, 0)
    elseif l.state == 4 then
        -- Stop -> Play
        l.state = 2
        softcut.play(idx, 1)
    end
end

function Loopers.clear(idx)
    local l = Globals.loopers[idx]
    l.state = 0
    softcut.rec(idx, 0)
    softcut.play(idx, 0)
    softcut.buffer_clear_region(l.start_pos, 30)
    softcut.loop_end(idx, l.start_pos + 30)
end

return Loopers
