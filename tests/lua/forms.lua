local checks,failures=0,0
local function check(c,message) checks=checks+1;if not c then failures=failures+1;print("FAIL UI forms: "..message) end end
local template={
    root={kind="column",padding=10,gap=5,children={
        {kind="label",id="name",height=20},
        {kind="row",id="row",height=40,gap=10,children={
            {kind="button",id="accept",width=80},{kind="toggle",id="sound",grow=1},
        }},
        {kind="label",id="count",height=20},
    }},
    bindings={{id="name",field="name"},{id="sound",field="settings.sound",type="boolean"},
              {id="count",field="items.1",type="integer",min=0,max=10}},
}
local form=ui.form(template)
local model={name="Explorer",settings={sound=false},items={3}}
check(form:push(model),"push model")
check(form:get("sound")==false and form:get("count")==3,"false booleans and numeric paths survive push")
form:set("name","Mara"):set("sound",true):set("count",11)
check(not form:pull(model),"out of range rejected")
check(model.name=="Explorer" and not model.settings.sound,"invalid pull changes no fields")
form:set("count",4)
check(not form:pull(model,function()return false,"validation" end),"custom validation rejection")
check(model.name=="Explorer","validator prevents commit")
check(form:pull(model),"valid pull")
check(model.name=="Mara" and model.settings.sound and model.items[1]==4,"all bindings transferred")
form:set("name","Uncommitted")
check(model.name=="Mara","editing does not mutate model before pull")
local boxes=form:layout(rect(10,20,300,160))
check(boxes.name.x==20 and boxes.name.y==30 and boxes.name.w==280,"container padding")
check(boxes.row.y==55 and boxes.row.h==40,"vertical gap")
check(boxes.accept.w==80 and boxes.sound.x==110 and boxes.sound.w==190,"fixed and weighted row")
check(form:layout(rect(0,0,200,160)).sound.w==90,"reflow in narrower parent")
check(not pcall(ui.form,{kind="mystery"}),"unknown controls rejected")
check(not pcall(ui.form,{kind="row",children={{kind="button",id="x"},{kind="button",id="x"}}}),"duplicate IDs rejected")
check(not pcall(ui.form,{kind="button"}),"interactive control needs ID")
local readonly=ui.form{root={kind="label",id="x"},bindings={{id="x",field="name",readonly=true}}}
check(readonly:push(model),"readonly push")
readonly:set("x","changed");check(readonly:pull(model) and model.name=="Mara","readonly model field preserved")
local stack=ui.modals()
check(not stack:active(),"empty modal stack")
check(stack:open("one",form,model),"first modal")
check(stack:open("two",readonly,model),"nested modal")
check(not stack:close("one") and stack:active(),"only top modal can close")
check(stack:close("two") and stack:close("one") and not stack:active(),"nested stack unwinds")
-- Backdrop dismissal belongs to the shared engine, including custom dialogs.
local modal_bounds=rect(50,50,200,200)
local outside={captured=true,released=true,tap=true,pos=vec2(20,30),press_pos=vec2(20,30)}
check(ui.modal_dismiss(modal_bounds,{input=outside}),"background tap cancels")
check(not ui.modal_dismiss(modal_bounds,{input=outside,fresh=true}),"opening release cannot cancel")
check(not ui.modal_dismiss(modal_bounds,{input=outside,close_on_background=false}),"required result can opt out")
outside.press_pos=vec2(100,100)
check(not ui.modal_dismiss(modal_bounds,{input=outside}),"inside-to-outside release cannot cancel")
outside.press_pos=vec2(20,30);outside.pos=vec2(100,100)
check(not ui.modal_dismiss(modal_bounds,{input=outside}),"outside-to-inside release cannot cancel")
outside.pos=vec2(20,30);outside.dragging=true
check(not ui.modal_dismiss(modal_bounds,{input=outside}),"backdrop pan cannot cancel")
outside.dragging=false;outside.multi_touch=true
check(not ui.modal_dismiss(modal_bounds,{input=outside}),"pinch cannot cancel")
outside.multi_touch=false;outside.captured=false
check(not ui.modal_dismiss(modal_bounds,{input=outside}),"inherited world press cannot cancel")
check(ui.modal_dismiss(modal_bounds,{input={back=true},close_on_background=false}),"back key remains separate from backdrop policy")
local backdrop_stack=ui.modals({label=function()end})
outside.captured=true
assert(backdrop_stack:open("lower",readonly,model,{bounds=modal_bounds}))
assert(backdrop_stack:open("upper",readonly,model,{bounds=modal_bounds}))
check(not backdrop_stack:draw(0,{input=outside,reduced_motion=true}),"fresh nested layer ignores opening background release")
local cancel=backdrop_stack:draw(0,{input=outside,reduced_motion=true})
check(cancel and cancel.kind=="cancel" and cancel.modal=="upper","only top nested layer receives background cancel")
check(#backdrop_stack.layers==2,"cancel event does not mutate modal stack implicitly")
assert(backdrop_stack:close("upper"));assert(backdrop_stack:close("lower"))
assert(backdrop_stack:open("required",readonly,model,{bounds=modal_bounds,close_on_background=false}))
backdrop_stack:draw(0,{input=outside,reduced_motion=true})
check(not backdrop_stack:draw(0,{input=outside,reduced_motion=true}),"required modal ignores background taps")
backdrop_stack:close()
local skin={button=function()end,button_text=function()end,label=function()end,focus=function()end}
form:draw(rect(0,0,300,160),skin,{input={key=input.KEY_TAB}})
check(form.focus=="accept","Tab focuses the first actionable control")
form:draw(rect(0,0,300,160),skin,{input={key=input.KEY_TAB}})
check(form.focus=="sound","Tab follows resource order")
local was=form:get("sound")
local event=form:draw(rect(0,0,300,160),skin,{input={key=input.KEY_RETURN}})
check(event and event.id=="sound" and form:get("sound")~=was,"Return activates a focused bound toggle")
check(not form:draw(rect(0,0,300,160),skin,{interactive=false,input={key=input.KEY_RETURN}}),"lower modal cannot activate via keyboard")
-- Data source replacement, row ownership and stable-key keyboard focus.
local builds=0
local list=ui.form{kind="list",id="topics",gap=8,item=function(item)
    builds=builds+1
    if item.bad then error("invalid row payload") end
    return {kind="row",gap=12,align="center",children={
        {kind="custom",width=60,height=60,visible=item.icon~=false},
        {kind="column",id="content",grow=1,gap=4,children={
            {kind="label",id="title",text=item.title,height=20,text_align=item.icon==false and "center" or "start"},
            {kind="label",id="description",text="Explanation",height=20,wrap=true},
        }},
        {kind="button",id="open",text="Open",width=40,height=40,action="choose"},
    }}
end}
local data={{id="a",title="First"},{id="b",title="Second",icon=false}}
check(list:set_items("topics",data),"populate data source")
local function item_node(key,id)
    for _,node in pairs(list.nodes) do if node.item_key==key and node.local_id==id then return node end end
end
local a,b=item_node("a","content"),item_node("b","content")
local row_boxes=list:layout(rect(0,0,300,200))
check(row_boxes[a.id].x==72 and row_boxes[a.id].w==176,"icon column consumes width before measuring text")
check(row_boxes[b.id].x==0 and row_boxes[b.id].y==68,"iconless row uses its own measured stack")
local drawn_align={}
local list_skin={button=function()end,button_text=function()end,focus=function()end,label=function(_,_,node) drawn_align[node.id]=node.text_align end}
list:draw(rect(0,0,300,200),list_skin,{input={key=input.KEY_TAB}})
local focused=list.focus
check(focused==item_node("a","open").id,"list controls participate in form focus order")
local selected=list:draw(rect(0,0,300,200),list_skin,{input={key=input.KEY_RETURN}})
check(selected and selected.id=="choose" and selected.source=="topics" and selected.key=="a","list actions identify their source and record")
local list_stack=ui.modals(list_skin)
check(list_stack:open("catalogue",list,{}, {bounds=rect(0,0,300,200)}),"list opens in modal")
check(not list_stack:draw(0,{input={key=input.KEY_RETURN,back=true},reduced_motion=true}),
    "opening input cannot activate or cancel a newly opened modal")
local modal_selected=list_stack:draw(0,{input={key=input.KEY_RETURN},reduced_motion=true})
check(modal_selected and modal_selected.modal=="catalogue" and modal_selected.source=="topics" and modal_selected.key=="a",
    "modal list actions preserve record identity")
list_stack:close()
check(drawn_align[item_node("a","title").id]=="start" and drawn_align[item_node("b","title").id]=="center","alignment follows icon presence")
check(builds==2,"rows are cached across layout and draw")
check(list:set_items("topics",{data[2],data[1]}) and list.focus==focused,"stable keys preserve focus across reordering")
check(not list:set_items("topics",{data[1],data[1]}),"duplicate source keys rejected")
check(list.focus==focused and #list.nodes.topics.children==2,"bad refresh leaves current rows and focus intact")
check(not list:set_items("topics",{data[2],{id="broken",bad=true}}),"row builder failures reject refresh")
check(list.focus==focused and #list.nodes.topics.children==2,"partially built refresh never leaks into live rows")
check(not list:set_items("topics",{[1]=data[1],[3]=data[2]}),"sparse source rejected")
check(not list:set_items("topics",{{title="Missing key"}}),"stable source key required")
check(list:set_items("topics",{data[2]}) and list.focus==nil and not list.nodes[focused],"removed records release nodes and focus")
data[2].title="Updated"
check(list:set_items("topics",data) and item_node("b","title").text=="Updated","source refresh replaces row contents")
check(list:set_items("topics",{}) and #list.nodes.topics.children==0,"empty source clears its stack")
check(not pcall(ui.form,{kind="list",id="bad"}),"list requires a row builder")
check(not pcall(ui.form,{kind="label",text_align="diagonal"}),"unknown text alignment rejected")
local measured=ui.form{kind="list",id="rows",item=function(item)
    return {kind="row",gap=12,children={{kind="custom",width=60,height=50},
        {kind="label",grow=1,wrap=true,text=item.text,text_align="start"}}}
end}
check(measured:set_items("rows",{{id="long",text="Every little row can wrap into several lines beside its icon"}}),"wrap source")
local measured_font=font.load("games/relic-rush/data/fonts/LilitaOne-Regular.ttf")
local font_style={style=function()return style{font=measured_font,size=20}end}
local accent=ui.form{kind="button",id="confirm",text="Confirm",accent=true}
local plain=ui.form{kind="button",id="cancel",text="Confirm"}
local typed_skin={theme={button=style{font=measured_font,size=10},accent_text=style{font=measured_font,size=30}}}
local accent_w=accent:measure(300,typed_skin)
local plain_w=plain:measure(300,typed_skin)
check(accent_w>plain_w,"native accent buttons use the theme's accent typography for measure and paint")
local _,wide=measured:measure(320,font_style)
local _,narrow=measured:measure(180,font_style)
check(narrow>wide,"row height grows when icon leaves less width for wrapped copy")
measured.root.children[1].align="center"
measured:layout(rect(0,0,180,narrow),font_style)
local wrapped=measured.root.children[1].children[2].box
check(wrapped.h==narrow and wrapped.y==0,"centered grow content uses its allocated width when arranging wrapped text")
local leaf={kind="list",id="deep",item=function()return {kind="column",children={{kind="label",text="too deep"}}}end}
for _=1,30 do leaf={kind="column",children={leaf}} end
local deep=ui.form(leaf)
check(not deep:set_items("deep",{{id="x"}}),"data rows obey the whole resource nesting limit")
print(("UI forms: %d checks, %d failures"):format(checks,failures))
return failures
