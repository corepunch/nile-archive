-- The cast. The engine (match3.game) delivers the keyed scenes. Portrait
-- sources and crops are recorded in docs/asset-catalogue.md#story-cast.
local R=require('state')
R.cast={
    {id='noelle',name='Noelle',role='Christmas market keeper',portrait_path='story/characters/noelle.png',color=color(136,42,43),mouth=vec2(.51,.42)},
    {id='theo',name='Theo Marsh',role='Tree seller',portrait_path='story/characters/theo.png',color=color(58,96,62),right=true,mouth=vec2(.62,.52)},
    {id='agnes',name='Agnes Holt',role='Baker',portrait_path='story/characters/agnes.png',color=color(150,92,48),right=true,mouth=vec2(.51,.45)},
    {id='henrik',name='Henrik Strand',role='Toymaker',portrait_path='story/characters/henrik.png',color=color(96,70,52),right=true,mouth=vec2(.53,.52)},
    {id='pip',name='Pip Larkin',role='Post runner',portrait_path='story/characters/pip.png',color=color(46,86,128),right=true,mouth=vec2(.65,.50)},
    {id='wren',name='Mr Wren',role='The man with the broom',portrait_path='story/characters/wren.png',color=color(92,92,104),right=true,mouth=vec2(.53,.46)},
    {id='mary',name='Mary Larkin',role="Pip's mum",portrait_path='story/characters/mary.png',color=color(144,66,84),right=true,mouth=vec2(.63,.55)},
    {id='rosa',name='Rosa',role="Noelle's gran",portrait_path='story/characters/rosa.png',color=color(120,48,60),right=true,mouth=vec2(.56,.54)},
    {id='alder',name='Mrs Alder',role="Hot cocoa kiosk",portrait_path='story/characters/alder.png',color=color(128,66,48),right=true,mouth=vec2(.62,.50)},
    {id='finch',name='Mr Finch',role="Fisherman, Lakeside smokehouse",portrait_path='story/characters/finch.png',color=color(52,92,104),right=true,mouth=vec2(.63,.51)},
    {id='ada',name='Ada Pike',role='Bellmere glassblower',portrait_path='story/characters/ada.png',color=color(48,104,98),right=true,mouth=vec2(.68,.35)},
}

return R
