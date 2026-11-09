-- The cast. The engine (match3.game) delivers the keyed scenes. Portrait
-- sources and crops are recorded in docs/asset-catalogue.md#story-cast.
local R=require('state')
R.cast={
    {id='noelle',name='Noelle',role='Christmas market keeper',portrait_path='characters/noelle.png',color=color(136,42,43),mouth=vec2(.51,.42)},
    {id='theo',name='Theo Marsh',role='Tree seller',portrait_path='characters/theo.png',color=color(58,96,62),right=true,mouth=vec2(.38,.52)},
    {id='agnes',name='Agnes Holt',role='Baker',portrait_path='characters/agnes.png',color=color(150,92,48),right=true,mouth=vec2(.49,.45)},
    {id='henrik',name='Henrik Strand',role='Toymaker',portrait_path='characters/henrik.png',color=color(96,70,52),right=true,mouth=vec2(.47,.52)},
    {id='pip',name='Pip Larkin',role='Post runner',portrait_path='characters/pip.png',color=color(46,86,128),right=true,mouth=vec2(.35,.50)},
    {id='wren',name='Mr Wren',role='The man with the broom',portrait_path='characters/wren.png',color=color(92,92,104),right=true,mouth=vec2(.47,.46)},
}

return R
