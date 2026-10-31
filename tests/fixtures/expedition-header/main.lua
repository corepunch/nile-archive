local game=require("game")
local R=require("state")
local init,frame=game.init,game.frame
local tick,stage=0,0
local moves,board
game.init=function()
    init()
    if app.arg("goals-complete") then
        local l=require("rules").level_of(R.g)
        R.g.score,R.g.relics,R.g.dug=l.score,l.relics,l.soil
        R.g.obstacles=0
        R.art_review=true
    end
    moves,board=R.g.moves,R.g
end
local function background() app.inject_click(vec2(6,app.screen().h-4)) end
game.frame=function(dt)
    frame(dt)
    if not app.arg("header-smoke") then return end
    tick=tick+1
    if tick%24~=0 then return end
    if stage==0 then app.inject_click(vec2(40,38))
    elseif stage==1 then
        assert(not R.on_island and R.g==board and R.g.moves==moves,"old island corner must do nothing")
        app.inject_click(vec2(440,38))
    elseif stage==2 then
        assert(R.overlay==R.OV_PAUSE,"authored pause control must open menu")
        app.inject_click(vec2(48,240+R.drop/2))
    elseif stage==3 then
        assert(R.overlay==R.OV_PAUSE,"tapping inside padding must not dismiss")
        app.inject_press(vec2(240,245+R.drop/2))
    elseif stage==4 then app.inject_move(vec2(6,245+R.drop/2))
    elseif stage==5 then app.inject_release(vec2(6,245+R.drop/2))
    elseif stage==6 then
        assert(R.overlay==R.OV_PAUSE,"drag out of popup must not dismiss")
        background()
    elseif stage==7 then
        assert(R.overlay==R.OV_NONE and not R.on_island and R.g==board and R.g.moves==moves and R.selected<0,
               "background dismissal must consume the tap and preserve the round")
        app.inject_click(vec2(440,38))
    elseif stage==8 then app.inject_click(R.pause_form.boxes.guide:center()+vec2(0,R.drop/2))
    elseif stage==9 then assert(R.overlay==R.OV_GUIDE,"guide opens");background()
    elseif stage==10 then
        assert(R.overlay==R.OV_NONE,"guide background closes")
        R.inspect,R.inspect_item,R.overlay=0,-1,R.OV_WONDER
    elseif stage==11 then background()
    elseif stage==12 then
        assert(R.overlay==R.OV_NONE,"details background closes")
        R.zone_card,R.overlay=1,R.OV_ZONE
    elseif stage==13 then background()
    elseif stage==14 then
        assert(R.overlay==R.OV_NONE,"zone background closes")
        R.g.won,R.on_island=true,true
        R.open_catalogue()
    elseif stage==15 then background()
    elseif stage==16 then
        assert(R.overlay==R.OV_NONE,"catalogue background closes through engine stack")
        R.open_expeditions()
    elseif stage==17 then background()
    elseif stage==18 then
        assert(R.overlay==R.OV_NONE,"expedition browser background closes through engine stack")
        R.on_island,R.overlay=false,R.OV_RESULT
    elseif stage==19 then background()
    elseif stage==20 then
        assert(R.overlay==R.OV_RESULT,"required result cannot be dismissed")
        R.g.won,R.g.lost,R.overlay=false,true,R.OV_FAILED
    elseif stage==21 then background()
    elseif stage==22 then
        assert(R.overlay==R.OV_FAILED,"failed result requires an explicit choice")
        print("header: island lock, pause, inside/drag protection, background close for guide/details/zone/shop/browser, and result protection passed")
        app.quit()
    end
    stage=stage+1
end
return game
