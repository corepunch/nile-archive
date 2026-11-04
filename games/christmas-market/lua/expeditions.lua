-- Repeatable earning and the one-time discovery track share one scene browser.
local R=require('state')
local rules=require('rules')
local island=require('island')
local journey=require('journey')
local stack=ui.modals(R.form_skin)
local form=require('match3').expedition_form('Winter wishes',
    'First clear: the next story scene, Christmas Stars and scheduled stall materials.\nReplay: 60 Gold + up to 40 for moves saved.',
    'BACK TO MARKET', R.PAL_CREAM)
R.expedition_form=form

local function bells(n) return n==0 and '' or n==1 and ', 1 Bell' or (', %d Bells'):format(n) end

local function refresh()
    local entries={}
    local pending=island.wonder_count(R.island)<journey.earned(R.prog.level)
    for i=0,rules.LEVELS-1 do
        local done=i<R.prog.level
        local current=i==R.prog.level
        local available=done or (current and not pending)
        local active=R.g and R.g.level==i and not R.g.won and not R.g.lost
        entries[#entries+1]={id=tostring(i),level=i,title=('%d. %s'):format(i+1,rules.levels[i+1].name),available=available,
            action=active and available and 'RESUME PUZZLE' or done and 'REPLAY FOR GOLD' or current and (pending and 'BUILD YOUR STALL FIRST' or 'NEW WINTER WISH') or 'COMPLETE EARLIER WISHES',
            note=active and available and 'Continue the unfinished board. Rewards are paid only after a win.' or done and 'Gold only. No extra Stars, Bells or story unlocks.' or
                ((journey.wonder_at(i+1) and 'First clear: stall funded + 80–120 spare Gold, 3 Stars%s.' or 'First clear: the next story scene + 80–120 Gold, 3 Stars%s.')):format(bells(rules.compass_rewards[i+1]))}
    end
    assert(form:set_items('levels',entries))
end

function R.open_expeditions(review_page)
    refresh()
    if review_page then
        local level=num.clampi((math.floor(review_page)-1)*3,0,rules.LEVELS-1)
        form:scroll_to('levels',tostring(level))
    else
        form:scroll_to('levels',tostring(math.min(R.prog.level,rules.LEVELS-1)//3*3))
    end
    if stack:active() then stack:close() end
    assert(stack:open('expeditions',form,{}, {width=448,blur=7,dim=color(5,22,22,185),cancel='close'}))
    R.overlay=R.OV_EXPEDITIONS
end

function R.draw_expeditions(dt)
    local ev=stack:draw(dt,{reduced_motion=R.reduced_motion})
    if not ev then return end
    if ev.id=='close' or ev.kind=='cancel' then stack:close();R.overlay=R.OV_NONE
    elseif ev.source=='levels' then
        local entry=form:get_item('levels',ev.key)
        if entry and entry.available then
            stack:close()
            R.overlay=R.OV_NONE
            R.play_level(entry.level)
        end
    end
end

return R
