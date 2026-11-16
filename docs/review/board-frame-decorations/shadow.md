# Board shadow

The previous shadow drew translucent lines along exposed edges and circles
at both ends of each edge. The ends of adjoining edges overlapped, creating
dark knots at the corners. The renderer now draws one shadow through a soft
distance mask for the board silhouette. Its falloff depends on distance to
the silhouette, so adjacent edges share the same shadow inside openings
and around the outside.

The close-ups show before on the left and after on the right. Relic Rush is
above Christmas Market.

![Close-ups of the shadow before and after](shadow-detail.jpg)

| Board | Before | Single shadow mask |
| --- | --- | --- |
| Relic Rush level 6, 480×900 | ![Previous Relic Rush shadow](relic-480-diagonal.jpg) | ![Relic Rush shadow with continuous falloff](relic-480-shadow.jpg) |
| Relic Rush level 6, 390×844 | ![Previous Relic Rush phone shadow](relic-390-diagonal.jpg) | ![Relic Rush phone shadow with continuous falloff](relic-390-shadow.jpg) |
| Christmas Market level 4, 480×900 | ![Previous Christmas Market shadow](christmas-480-diagonal.jpg) | ![Christmas Market shadow with continuous falloff](christmas-480-shadow.jpg) |
| Christmas Market level 4, 390×844 | ![Previous Christmas Market phone shadow](christmas-390-diagonal.jpg) | ![Christmas Market phone shadow with continuous falloff](christmas-390-shadow.jpg) |

```sh
build/test/all --suite=relic-rush --suite=christmas-market \
  "shot dressing-shore" "shot main-character-board" "shot phone-board"
```
