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
local skin={button=function()end,button_text=function()end,label=function()end,focus=function()end}
form:draw(rect(0,0,300,160),skin,{input={key=input.KEY_TAB}})
check(form.focus=="accept","Tab focuses the first actionable control")
form:draw(rect(0,0,300,160),skin,{input={key=input.KEY_TAB}})
check(form.focus=="sound","Tab follows resource order")
local was=form:get("sound")
local event=form:draw(rect(0,0,300,160),skin,{input={key=input.KEY_RETURN}})
check(event and event.id=="sound" and form:get("sound")~=was,"Return activates a focused bound toggle")
check(not form:draw(rect(0,0,300,160),skin,{interactive=false,input={key=input.KEY_RETURN}}),"lower modal cannot activate via keyboard")
print(("UI forms: %d checks, %d failures"):format(checks,failures))
return failures
