-- ui.skin: declarative skin files compiled into the form paint contract.

-- Layers with a paint callback record where and how they were drawn.
local drawn={}
local function rec(name) return function(box) drawn[#drawn+1]={name=name,box=box} end end
local function find(name) for _,d in ipairs(drawn) do if d.name==name then return d end end end
local function count(name) local n=0;for _,d in ipairs(drawn) do if d.name==name then n=n+1 end end;return n end
local function names() local t={};for _,d in ipairs(drawn) do t[#t+1]=d.name end;return table.concat(t,",") end

local base_font=ui.theme().text.font
local skin=ui.skin{
    fonts={body={font=base_font,scale=2}},
    colors={ink="#102030",veil="ink"},
    text={
        body={font="body",em=10,fill="ink",outline="#000000",outline_width=1,shadow="#00000080",shadow_offset={0,2}},
        title={extends="body",em=20,fill="#FF0000"},
    },
    roles={headline={text="title",em=30}},
    controls={
        button={text="body",em=12,
            normal={layers={{name="shadow",paint=rec("shadow"),fixed=true},{name="body",paint=rec("body")},{name="gloss",paint=rec("gloss"),inset={2,2,2,0},height_ratio=.5}}},
            hover={set={body={paint=rec("body-hover")}}},
            pressed={offset={0,3}},
            selected={set={gloss={paint=rec("gloss-on")}}},
            disabled={set={body={paint=rec("body-off")}}},
            variants={flat={normal={layers={}}},accent={normal={set={body={paint=rec("body-accent")}}}},
                      danger={normal={set={body={paint=rec("body-danger")}}}}},
        },
        toggle={extends="button"},
        checkbox={size=20,gap=6,text="body",
            box={normal={layers={{name="face",paint=rec("box")}}},pressed={set={face={paint=rec("box-pressed")}}}},
            mark={normal={layers={{paint=rec("mark")}}}}},
        focus={normal={layers={{paint=rec("focus")}}}},
        panel={normal={layers={{paint=rec("panel")}}}},
        label={text="body",em=14,wrap_text="title",wrap_em=9},
    },
    theme={dim="veil",backdrop_blur=5,radius=7},
}

-- Colours, theme and named palette entries resolve through the skin file.
check(skin.theme.dim.r==16 and skin.theme.dim.g==32 and skin.theme.dim.b==48 and skin.theme.dim.a==255,"named colour chains to #RRGGBB")
check(skin.theme.backdrop_blur==5 and skin.theme.radius==7,"theme numbers pass through")

-- Text styles: extends, font scale, and lengths scale with the requested em.
local s=skin:text("title")
check(math.abs(s.size-40)<.01,"extended style keeps its own em, times the font scale")
check(s.fill.r==255 and s.fill.g==0 and s.outline.a==255,"extended style overrides fill, inherits outline")
s=skin:text("body",20)
check(math.abs(s.outline_width-2)<.01 and math.abs(s.shadow_offset.y-4)<.01,"outline and shadow scale with em")
check(math.abs(skin.style({kind="label",role="headline"}).size-60)<.01,"roles pick a style and size")
check(math.abs(skin.style({kind="label",wrap=true}).size-18)<.01,"wrapped labels use wrap_text/wrap_em")
check(math.abs(skin.style({kind="button",em=8}).size-16)<.01,"a node's em overrides the control's")
check(math.abs(skin.style({kind="toggle"}).size-24)<.01,"toggle extends button")

-- States merge over normal in order: selected, hover, pressed, disabled.
local box=rect(10,20,100,40)
local function paint(st,node) drawn={};skin:paint(node and node.kind or "button",box,st,node) end
paint({})
check(names()=="shadow,body,gloss","normal look draws its layers in order")
local gloss=find("gloss").box
check(gloss.x==12 and gloss.y==22 and gloss.w==96 and gloss.h==18,"height_ratio cuts the top, then inset applies")
paint({hot=true})
check(names()=="shadow,body-hover,gloss","hover patches one named layer")
paint({hot=true,held=true})
check(find("body-hover").box.y==23 and find("shadow").box.y==20,"pressed offset moves layers except fixed ones")
paint({selected=true,hot=true})
check(names()=="shadow,body-hover,gloss-on","selected and hover combine")
paint({disabled=true,hot=true,held=true})
check(names()=="shadow,body-off,gloss" and find("body-off").box.y==20,"disabled wins; no hover or press while disabled")
paint({},{kind="button",flat=true})
check(names()=="","flat variant draws nothing")
paint({},{kind="button",accent=true})
check(names()=="shadow,body-accent,gloss","accent variant patches the normal look")
paint({hot=true},{kind="button",role="danger"})
check(names()=="shadow,body-hover,gloss","a variant keeps the control's other states")
paint({},{kind="toggle"})
check(names()=="shadow,body,gloss","toggle inherits button looks")

-- The paint transform scales and offsets every layer (animated dialogs).
skin.transform=function() return 2,vec2(5,0),.5 end
drawn={};skin:paint("panel",rect(10,10,20,20))
check(find("panel").box.x==10 and find("panel").box.w==20,"paint callbacks receive logical boxes")
check(math.abs(skin:text("body").size-40)<.01 and math.abs(skin:text("body").fade-.5)<.01,"text follows the transform scale and opacity")
check(math.abs(skin.style({kind="label"}).size-28)<.01,"measurement ignores the transform")
skin.transform=nil

-- Bound form images share the skin transform, fitting before painting while
-- their logical layout stays fixed (building cards and resource icons).
local image_draw, images=gfx.image,{}
gfx.image=function(im,bounds,tint) images[#images+1]={image=im,box=bounds,tint=tint} end -- luacheck: ignore 122
local im={tex=true,w=80,h=40}
local image_form=ui.form{kind="image",id="art",image=im}
skin.transform=function() return .5,vec2(5,7),.25 end
image_form:draw(rect(10,20,100,100),skin,{input={}})
image_form.root.cover=true
image_form:draw(rect(10,20,100,100),skin,{input={}})
skin.transform=nil
image_form:draw(rect(10,20,100,100),skin,{input={}})
image_form:draw(rect(10,20,100,100),{},{input={}})
gfx.image=image_draw -- luacheck: ignore 122
check(#images==4 and images[1].image==im,"all image paint paths preserve the bound texture")
local fitted=images[1].box
near(fitted.x,10,"fitted image follows popup x")
near(fitted.y,29.5,"fitted image follows popup y")
near(fitted.w,50,"fitted image follows popup scale")
near(fitted.h,25,"image retains its aspect ratio")
check(images[1].tint.a==64 and images[2].tint.a==64,"images share popup opacity")
near(images[2].box.h,50,"cover image scales its allocated bounds")
near(image_form.boxes.art.w,100,"paint transform does not change logical bounds")
check(images[3].box.h==100 and images[3].tint.a==255,"settled skin restores full size and opacity")
check(images[4].box.h==100 and images[4].tint.a==255,"native image fallback stays available")

-- Checkbox: an engine control, bound like a toggle, painted by the skin.
local form=ui.form{root={kind="column",gap=4,children={
    {kind="checkbox",id="hints",text="Hints",height=30},
    {kind="checkbox",id="locked",text="Locked",height=30,enabled=false,value=true},
    {kind="button",id="ok",text="OK",height=30},
}},bindings={{id="hints",field="hints",type="boolean"}}}
local model={hints=false}
check(form:push(model) and form:get("hints")==false and form:get("locked")==true,"checkbox binds a boolean; value seeds an unbound one")
local w,h=form:measure(200,skin)
check(w>=20+6 and h>=30*3+8,"checkbox measures box, gap and caption")
drawn={}
form:draw(rect(0,0,200,120),skin,{input={key=input.KEY_TAB}})
check(form.focus=="hints","Tab focuses the first checkbox; the disabled one is skipped")
check(count("box")==2 and count("mark")==1,"only the checked (locked) box draws a mark")
local event=form:draw(rect(0,0,200,120),skin,{input={key=input.KEY_SPACE}})
check(event and event.id=="hints" and event.kind=="change" and event.value==true,"Space toggles a focused checkbox and reports change")
check(model.hints==false,"the model changes only on pull")
check(form:pull(model) and model.hints==true,"pull commits the checkbox")
drawn={}
form:draw(rect(0,0,200,120),skin,{input={}})
check(count("mark")==2,"a newly checked box draws its mark")
form:draw(rect(0,0,200,120),skin,{input={key=input.KEY_TAB}})
check(form.focus=="ok" and count("focus")>0,"Tab moves and paints keyboard focus past the disabled checkbox")
drawn={}
form:draw(rect(0,0,200,120),skin,{input={pressed=true}})
check(form.focus=="ok" and count("focus")==0,"pointer use removes the ring while retaining the focused control")
check(not pcall(ui.form,{kind="checkbox"}),"checkbox needs an ID")

-- The native look stays available without a skin.
local plain=ui.form{root={kind="checkbox",id="c",text="Plain",height=30}}
check(pcall(plain.draw,plain,rect(0,0,200,30),{},{input={}}),"checkbox draws with the native theme")

-- Immediate mode: the same skin paints hand-placed widgets.
drawn={}
check(skin:draw_button(rect(0,0,80,30),"Go",{input={}})==false and find("body"),"immediate button paints the button look")
drawn={}
check(skin:draw_checkbox(rect(0,0,80,30),"On",true)==true and find("mark"),"immediate checkbox keeps its value and draws the mark")

-- Looks can shrink or fade the whole control; layers can hide; variants that
-- touch one layer keep the control's patches to the others.
local native=ui.skin{fonts={f={font=base_font}},text={t={font="f",em=10,shadow="#000000",shadow_offset={0,2},scale_lengths=false},
        faded={extends="t",fade=.45}},
    colors={gold="#F4CB78"},
    controls={
        button={text="t",
            normal={layers={{name="shadow",paint=rec("shadow")},{name="body",paint=rec("body")},{name="pin",paint=rec("pin"),fixed=true}}},
            hover={set={body={paint=rec("body-hot")}}},
            pressed={inset=2,set={shadow={hidden=true}}},
            disabled={alpha=.45,text="faded"},
            variants={accent={normal={set={shadow={paint=rec("shadow-gold")}}},hover={set={body={paint=rec("body-gold")}}}}}},
        pill={text="t",normal={layers={{paint=rec("pill")}}}},
    },
    theme={text={"t",30},accent="gold",radius=9}}
drawn={};native:paint("button",box,{hot=true,held=true})
check(names()=="body-hot,pin" and find("body-hot").box.x==12 and find("body-hot").box.w==96,"pressed inset shrinks non-fixed layers and hides one")
check(find("pin").box.x==10,"fixed layers ignore the look's inset")
drawn={};native:paint("button",box,{hot=true},{kind="button",accent=true})
check(names()=="shadow-gold,body-gold,pin","an accent hover patch keeps the accent normal patch")
check(math.abs(native:text("t",20).shadow_offset.y-2)<.01,"scale_lengths=false pins shadow lengths")
check(math.abs(native:text("faded").fade-.45)<.01,"text styles can fade")
check(rawget(native,"theme")==nil,"the theme waits until it is used")
check(math.abs(native.theme.text.size-30)<.01 and native.theme.accent.r==244 and native.theme.radius==9,"{style, em} theme entries and colours")
check(native.theme.active.a>0,"unnamed theme fields keep the engine theme")
check(native:color("gold").g==203,"skin:color resolves palette names")
drawn={}
native:draw_button(rect(0,0,80,30),"Go",{kind="pill"})
check(names()=="pill","draw_button paints any control kind")
local plain_buttons=ui.skin{fonts={f={font=base_font}},text={t={font="f"}},controls={button={text="t"}}}
check(plain_buttons.button==nil and plain_buttons.button_text~=nil,"text-only buttons keep the native button paint")

-- Authored images must exist for every state; the audit lists what is missing.
local art=ui.skin{fonts={f={font=base_font}},text={t={font="f"}},controls={
    button={normal={layers={{image="missing.png"}}},pressed={layers={{image="missing-pressed.png"}}}},
    panel={normal={layers={{fill="#000000"}}}},
}}
local missing=art:audit()
check(#missing==2 and missing[1].state=="disabled" and missing[2].state=="hover","audit lists image states without artwork")
check(#art:audit({button={"pressed"}})==0,"audit takes the game's required states")

-- Mistakes fail when the file is compiled or first used, not silently.
check(not pcall(ui.skin,{text={a={em=3}}}),"text needs a font")
check(not pcall(ui.skin,{fonts={f={font=base_font}},text={a={extends="b"}}}),"extends must name a style")
check(not pcall(ui.skin,{controls={button={focused={}}}}),"focus is its own control, not a state")
check(not pcall(function() ui.skin{fonts={f={font=base_font}},text={a={font="f",fill="nope"}}}:text("a") end),"unknown colours are errors")
check(not pcall(function() ui.skin{theme={dim="#12"}} end),"malformed hex is an error")

