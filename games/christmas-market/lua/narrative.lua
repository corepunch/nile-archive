-- The cast. The engine (match3.game) delivers the keyed scenes. Portrait
-- sources and crops are recorded in docs/asset-catalogue.md#story-cast.
local R=require('state')
local l10n=require('l10n')
local tr=l10n.tr
R.cast={
    -- TRANSLATORS: a speaker's name and role on the story screen
    {id='noelle',name=tr('Noelle'),role=tr('Christmas market keeper'),portrait_path='story/characters/noelle.png',color=color(136,42,43),mouth=vec2(.51,.42)},
    {id='theo',name=tr('Theo Marsh'),role=tr('Tree seller'),portrait_path='story/characters/theo.png',color=color(58,96,62),right=true,mouth=vec2(.62,.52)},
    {id='agnes',name=tr('Agnes Holt'),role=tr('Baker'),portrait_path='story/characters/agnes.png',color=color(150,92,48),right=true,mouth=vec2(.51,.45)},
    {id='henrik',name=tr('Henrik Strand'),role=tr('Toymaker'),portrait_path='story/characters/henrik.png',color=color(96,70,52),right=true,mouth=vec2(.53,.52)},
    {id='pip',name=tr('Pip Larkin'),role=tr('Post runner'),portrait_path='story/characters/pip.png',color=color(46,86,128),right=true,mouth=vec2(.65,.50)},
    {id='wren',name=tr('Mr Wren'),role=tr('The man with the broom'),portrait_path='story/characters/wren.png',color=color(92,92,104),right=true,mouth=vec2(.53,.46)},
    {id='mary',name=tr('Mary Larkin'),role=tr("Pip's mum"),portrait_path='story/characters/mary.png',color=color(144,66,84),right=true,mouth=vec2(.63,.55)},
    {id='rosa',name=tr('Rosa'),role=tr("Noelle's gran"),portrait_path='story/characters/rosa.png',color=color(120,48,60),right=true,mouth=vec2(.56,.54)},
    {id='alder',name=tr('Mrs Alder'),role=tr("Hot cocoa kiosk"),portrait_path='story/characters/alder.png',color=color(128,66,48),right=true,mouth=vec2(.62,.50)},
    {id='finch',name=tr('Mr Finch'),role=tr("Fisherman, Lakeside smokehouse"),portrait_path='story/characters/finch.png',color=color(52,92,104),right=true,mouth=vec2(.63,.51)},
    {id='ada',name=tr('Ada Pike'),role=tr('Bellmere glassblower'),portrait_path='story/characters/ada.png',color=color(48,104,98),right=true,mouth=vec2(.68,.35)},
    {id='otis',name=tr('Otis Bell'),role=tr('Station clock keeper'),portrait_path='story/characters/otis.png',color=color(76,76,118),right=true,mouth=vec2(.66,.36)},
}

return R
