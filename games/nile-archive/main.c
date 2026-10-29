/* Nile Archive — hidden-object chapters feeding an island-restoration meta-game.
 *
 * The whole interface (header, chapters, shop, dialogs) is drawn by the shared
 * engine; this file holds the content, the hidden-object rules and the screen
 * layout. The island itself is an engine `city`. */
#include "engine.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#endif

#ifndef GAME_DATA_DIR
#define GAME_DATA_DIR "games/nile-archive/data"
#endif

/* ------------------------------------------------------------------ content */

enum { COINS, INFLUENCE };
enum { SCENES = 3, ITEMS = 8, ZONES = 4 };

typedef struct {
    const char *title, *teaser;
    story_line clue[2];             /* told when the chapter is first completed */
    int clue_lines;
    const char *background;
    int gate;                       /* influence needed to enter */
    const char *names[ITEMS];
    vec2 at[ITEMS];                 /* item centres, measured on the painting */
    vec2 radius[ITEMS];             /* elliptical hit areas */
} scene_def;

static const scene_def scenes[SCENES] = {
    {"Двор хранителя", "На столах двора остались вещи отца. Начните с них.",
     {{"nefra", "На свитке — печать семейной мастерской. Отец успел спрятать архив до наводнения."}}, 1, "scene0.png", 0,
     {"Анх", "Веер", "Гранат", "Скарабей", "Ключ", "Кошка", "Свиток", "Перо"},
     {{133, 133}, {268, 422}, {491, 316}, {574, 660}, {1150, 368}, {965, 575}, {195, 598}, {1094, 170}},
     {{27, 55}, {82, 42}, {30, 30}, {40, 24}, {45, 20}, {95, 70}, {90, 42}, {42, 55}}},
    {"Библиотека писца", "В библиотеке спрятан второй след. Для доступа нужно 20 влияния.",
     {{"nefra", "На обороте печати проступил план острова. След ведёт к старому храму у восточного берега."}}, 1, "scene1.png", 20,
     {"Анх", "Веер", "Гранат", "Скарабей", "Ключ", "Кошка", "Карта", "Перо"},
     {{180, 78}, {1023, 617}, {115, 430}, {513, 163}, {450, 617}, {1063, 453}, {273, 500}, {1070, 226}},
     {{25, 52}, {115, 55}, {35, 35}, {30, 42}, {45, 22}, {90, 70}, {195, 55}, {45, 55}}},
    {"Храм на закате", "Соберите последнюю цепочку улик. Нужно 50 влияния.",
     {{"nefra", "Последняя записка отца раскрыта."},
      {"horem", "Книги спрятаны под храмом. Восстанови остров — и библиотека снова откроется.", BUBBLE_THOUGHT}},
     2, "scene2.png", 50,
     {"Анх", "Веер", "Яблоко", "Скарабей", "Ключ", "Кошка", "Свиток", "Перо"},
     {{61, 109}, {1027, 530}, {120, 514}, {527, 334}, {1109, 114}, {656, 574}, {234, 98}, {379, 634}},
     {{30, 72}, {95, 50}, {35, 35}, {42, 24}, {25, 62}, {105, 58}, {70, 28}, {95, 30}}},
};

/* Sprites are 248 px tall inside the old 256 px atlas cells: drawn height and
 * how far below the anchor they reach keep the original placement. */
#define BUILDING(title, size, coins, influence, path)                                                       \
    {.name = title, .sprite_path = path, .height = (size) * 248.0f / 256, .sink = (size) * .1044f, .cost = {{coins}}, \
     .reward = {{0, influence}}}

static building_def buildings[] = {
    BUILDING("Дом садовника", 160, 70, 10, "buildings/0.png"),
    BUILDING("Храм Исиды", 210, 160, 30, "buildings/1.png"),
    BUILDING("Архив", 190, 130, 25, "buildings/2.png"),
    BUILDING("Фонтан", 150, 60, 10, "buildings/3.png"),
    BUILDING("Мастерская", 170, 100, 15, "buildings/4.png"),
};
enum { BUILDING_TYPES = sizeof buildings / sizeof buildings[0] };

static character cast[] = {
    {.id = "nefra", .name = "Нефра", .role = "Дочь хранителя · ищет отца и архив", .portrait_path = "characters/nefra.png",
     .color = {46, 140, 134, 255}, .mouth = {.48f, .23f}},
    {.id = "horem", .name = "Хорем", .role = "Пропавший хранитель · оставил подсказки", .portrait_path = "characters/horem.png",
     .color = {185, 134, 46, 255}, .right = true, .mouth = {.42f, .21f}},
    {.id = "merit", .name = "Мерит", .role = "Лодочница · проводник будущих глав", .portrait_path = "characters/merit.png",
     .color = {181, 84, 58, 255}, .right = true, .mouth = {.40f, .22f}},
};
enum { CAST = sizeof cast / sizeof cast[0] };

/* First launch. */
static const story_line intro[] = {
    {"nefra", "Отец исчез после наводнения, а библиотека опустела."},
    {"nefra", "Но он успел спрятать книги и оставил подсказки. Я восстановлю наше поместье — и найду архив."},
};

static const purse scene_reward = {{240, 20}};

/* -------------------------------------------------------------------- state */

typedef enum { MODAL_NONE, MODAL_WIN, MODAL_CAST } modal;

static struct {
    purse wallet;
    int wins[SCENES];
    city island;

    int scene;                      /* -1 = island */
    unsigned found;                 /* bit per item */
    int hint;
    float found_time[ITEMS];
    camera cam;                     /* hidden-object camera */
    vec2 focus;
    float focus_time;

    modal modal;
    float modal_time;
    texture backgrounds[SCENES], coin, influence;
    font *serif, *sans, *sans_bold;
    ui_theme theme;
    text_style eyebrow, heading, body, muted, number, item;
} G;

/* --------------------------------------------------------------- the island */

/* Approximate land outline of island.png: an ellipse minus the pond. */
static bool island_buildable(vec2 p)
{
    if (p.y < 400 || p.y > 1170) return false;
    if (vec2_ellipse(vec2_sub(p, v2(1230, 800)), v2(760, 530)) > 1) return false;
    return !rect_contains(rc(1030, 920, 290, 180), p);
}

static void island_setup(void)
{
    city *c = &G.island;
    c->defs = buildings;
    c->def_count = BUILDING_TYPES;
    c->spacing = 120;
    c->buildable = island_buildable;
    c->zone_count = ZONES;
    c->zones[0] = (city_zone){.area = rc(580, 200, 600, 1050)};
    for (int z = 1; z < ZONES; z++) c->zones[z] = (city_zone){.area = rc(800 + z * 380, 200, 380, 1050), .cost = {{z * 180}}};
    c->cam = (camera){.center = v2(900, 650), .zoom = .8f, .min_zoom = .35f, .max_zoom = 2, .cover = true};
    city_init(c, "island.png");
}

static void new_game(void)
{
    G.wallet = (purse){{260, 10}};
    memset(G.wins, 0, sizeof G.wins);
    G.island.count = 0;
    G.island.open = 1;
    city_add(&G.island, v2(850, 650), 0, 0);
}

static void serialize(save *s, void *user)
{
    int version = 2;
    save_int(s, "version", &version);
    save_int(s, "coins", &G.wallet.v[COINS]);
    save_int(s, "influence", &G.wallet.v[INFLUENCE]);
    save_ints(s, "wins", G.wins, SCENES);
    city_serialize(&G.island, s);
    story_serialize(s);
}

static void save_progress(void) { save_write("progress", serialize, NULL); }

#ifdef __EMSCRIPTEN__
/* Progress of the old HTML version lived in localStorage["nile-v1"] as JSON. */
EM_JS(char *, legacy_progress, (void), {
    try {
        var s = JSON.parse(localStorage.getItem('nile-v1') || 'null');
        if (!s) return 0;
        var t = 'coins=' + (s.coins | 0) + '\ninfluence=' + (s.prestige | 0) + '\nwins=' + (s.wins || [0, 0, 0]).join(' ') +
                '\ncity.zones=' + (s.zones | 0) + '\ncity.count=' + (s.buildings || []).length + '\n';
        (s.buildings || []).forEach(function(b, i) {
            t += 'city.' + i + '.pos=' + b[0] + ' ' + b[1] + '\ncity.' + i + '.type=' + b[2] + '\n';
        });
        var n = lengthBytesUTF8(t) + 1, p = _malloc(n);
        stringToUTF8(t, p, n);
        return p;
    } catch (e) { return 0; }
});
#endif

/* ---------------------------------------------------------- hidden objects */

static void open_scene(int i)
{
    G.scene = i;
    G.found = 0;
    G.hint = -1;
    G.island.selected = -1;
    memset(G.found_time, 0, sizeof G.found_time);
    G.cam = (camera){.center = v2(600, 400), .zoom = 0, .world = sz2(1200, 800)};
    fx_clear();
}

static void go_home(void)
{
    G.scene = -1;
    G.modal = MODAL_NONE;
    fx_clear();
}

static int found_count(void)
{
    int n = 0;
    for (int i = 0; i < ITEMS; i++) n += (G.found >> i) & 1;
    return n;
}

static void show_hint(void)
{
    for (int i = 0; i < ITEMS; i++)
        if (!(G.found & 1u << i)) {
            G.hint = i;
            G.focus = scenes[G.scene].at[i];
            G.focus_time = .6f;
            return;
        }
}

static void scene_tap(vec2 screen)
{
    const scene_def *sc = &scenes[G.scene];
    vec2 p = camera_to_world(G.cam, screen);
    for (int i = 0; i < ITEMS; i++) {
        if (G.found & 1u << i) continue;
        if (vec2_ellipse(vec2_sub(p, sc->at[i]), sc->radius[i]) > 1) continue;
        G.found |= 1u << i;
        G.found_time[i] = (float)app_time();
        if (G.hint == i) G.hint = -1;
        fx_sparkle(camera_to_screen(G.cam, sc->at[i]), 40 * G.cam.zoom + 20, hex(0xFFE7A0));
        if (found_count() == ITEMS) {
            G.wallet = purse_add(G.wallet, scene_reward);
            G.wins[G.scene]++;
            story_play(fmt("chapter-%d", G.scene), sc->clue, sc->clue_lines);   /* the clue, the first time */
            save_progress();
            G.modal = MODAL_WIN;
            G.modal_time = 0;
        }
        return;
    }
}

/* ------------------------------------------------------------------ widgets */

static rect amount(vec2 pos, vec2 pivot, texture icon, const char *text, text_style s)
{
    float icon_size = s.size * 1.25f, w = icon_size + 6 + text_measure(s, text).w;
    rect box = rect_anchor(pos, sz2(w, icon_size), pivot);
    draw_image(icon, rect_left(box, icon_size), WHITE);
    text_draw(s, rect_point(rect_offset(box, v2(icon_size + 6, 0)), v2(0, .5f)), v2(0, .5f), text);
    return box;
}

static void pill(rect area, vec2 align, const char *text)
{
    text_style s = ts_size(G.eyebrow, 13);
    rect r = rect_align(area, sz2(text_measure(s, text).w + 28, 34), align);
    draw_round_rect(r, 17, rgba(24, 59, 57, 232));
    draw_round_rect_line(r, 17, 1, rgba(229, 203, 135, 100));
    text_draw(s, rect_center(r), v2(.5f, .5f), text);
}

static bool icon_button(rect r, const char *glyph)
{
    ui_state st = ui_button_frame(r, 0);
    text_draw(ts_size(G.theme.button, 28), rect_center(st.held ? rect_offset(r, v2(0, 1)) : r), v2(.5f, .54f), glyph);
    return st.clicked;
}

/* ------------------------------------------------------------------ screens */

static void draw_header(rect bar)
{
    draw_rect_grad(bar, hex(0x1B4343), hex(0x153637));
    draw_rect(rect_bottom(bar, 1), rgba(191, 166, 107, 70));
    rect inner = rect_inflate2(bar, v2(-18, -6));
    rect brand = rect_cut_left(&inner, 360);
    text_draw(G.eyebrow, brand.pos, v2(0, 0), "ТАЙНЫ ЗАБЫТОГО ОСТРОВА");
    text_draw(G.theme.title, rect_point(brand, v2(0, 1)), v2(0, .92f), "Архив Нила");

    text_style num = G.number;
    rect r = rect_cut_right(&inner, 120);
    amount(rect_point(r, v2(1, .5f)), v2(1, .5f), G.influence, fmt("%d", G.wallet.v[INFLUENCE]), num);
    r = rect_cut_right(&inner, 130);
    amount(rect_point(r, v2(1, .5f)), v2(1, .5f), G.coin, fmt("%d", G.wallet.v[COINS]), num);
    rect_cut_right(&inner, 18);
    if (ui_button(rect_align(rect_cut_right(&inner, 150), sz2(150, 44), v2(1, .5f)), "Персонажи", 0)) G.modal = MODAL_CAST, G.modal_time = 0;
    if (G.scene >= 0) {
        rect_cut_right(&inner, 10);
        if (ui_button(rect_align(rect_cut_right(&inner, 170), sz2(170, 44), v2(1, .5f)), "‹ На остров", 0)) go_home();
    }
}

static void draw_chapters(rect panel)
{
    ui_panel(panel);
    rect r = rect_inflate(panel, -16);

    rect intro = rect_cut_top(&r, 150);
    rect face = rect_cut_left(&intro, 92);
    draw_image(cast[0].portrait, rect_fit(face, cast[0].portrait.size), WHITE);
    rect_cut_left(&intro, 10);
    text_draw(G.eyebrow, intro.pos, v2(0, 0), "ЕГИПЕТ · 196 ДО Н. Э.");
    text_box(ts_size(G.heading, 21), rc(intro.pos.x, intro.pos.y + 20, intro.size.w, 52), v2(0, 0), "Остров, который помнит");
    text_box(ts_size(G.muted, 13), rc(intro.pos.x, intro.pos.y + 74, intro.size.w, 76), v2(0, 0),
             "Вы — Нефра. Стройте поместье, повышайте влияние и ищите следы исчезнувшей библиотеки.");

    rect_cut_top(&r, 6);
    text_draw(G.heading, r.pos, v2(0, 0), "Пропавший архив");
    rect_cut_top(&r, 44);
    for (int i = 0; i < SCENES; i++) {
        const scene_def *sc = &scenes[i];
        rect card = rect_cut_top(&r, minf(196, r.size.h / (SCENES - i)));
        draw_rect(rect_top(card, 1), rgba(173, 194, 155, 40));
        rect c = rect_inflate2(card, v2(0, -10));
        text_draw(G.eyebrow, c.pos, v2(0, 0), fmt("ГЛАВА 0%d%s", i + 1, G.wins[i] ? "  ★" : ""));
        text_draw(ts_size(G.heading, 19), vec2_add(c.pos, v2(0, 18)), v2(0, 0), sc->title);
        text_box(G.muted, rc(c.pos.x, c.pos.y + 46, c.size.w, rect_max(c).y - c.pos.y - 46 - 54), v2(0, 0), sc->teaser);
        bool locked = G.wallet.v[INFLUENCE] < sc->gate;
        const char *label = locked ? fmt("Нужно %d влияния", sc->gate) : G.wins[i] ? "Играть снова" : "Найти предметы ›";
        int flags = locked ? UI_DISABLED : (i == 0 || !G.wins[i]) ? UI_ACCENT : 0;
        if (ui_button(rect_bottom(c, 46), label, flags)) open_scene(i);
    }
}

static void draw_shop(rect area)
{
    for (int i = 0; i < BUILDING_TYPES; i++) {
        building_def *d = &buildings[i];
        rect card = rect_col(area, BUILDING_TYPES, i, 10);
        ui_state st = ui_button_frame(card, G.island.selected == i ? UI_ACTIVE : 0);
        if (st.clicked) G.island.selected = G.island.selected == i ? -1 : i;
        rect c = rect_inflate(card, -8);
        rect pic = rect_cut_left(&c, c.size.h * .62f);
        draw_image(d->sprite, rect_fit(pic, d->sprite.size), WHITE);
        rect_cut_left(&c, 6);
        text_box(ts_size(G.heading, 17), rect_cut_top(&c, c.size.h * .55f), v2(0, 1), d->name);
        rect line = rect_cut_top(&c, 22);
        rect cost = amount(rect_point(line, v2(0, .5f)), v2(0, .5f), G.coin, fmt("%d", d->cost.v[COINS]), ts_size(G.number, 14));
        amount(vec2_add(rect_point(cost, v2(1, .5f)), v2(10, 0)), v2(0, .5f), G.influence, fmt("+%d", d->reward.v[INFLUENCE]),
               ts_size(G.number, 14));
    }
}

static void island_frame(rect body, input world)
{
    rect side = rect_cut_right(&body, minf(270, body.size.w * .26f));
    rect_cut_right(&body, 12);
    rect shop = rect_cut_bottom(&body, 112);
    rect_cut_bottom(&body, 10);
    rect footer = rect_cut_bottom(&body, 50);
    rect_cut_bottom(&body, 8);
    rect view = body;

    G.island.cam.view = view;
    if (G.modal == MODAL_NONE) {
        city_event ev = city_update(&G.island, world, &G.wallet, app_clock(), app_dt());
        switch (ev.result) {
        case CITY_BUILT:
            save_progress();
            fx_burst(ev.screen, 26, hex(0xF2D29A), 260, 9);
            ui_toast(fmt("Постройка готова · +%d влияния", buildings[G.island.items[ev.building].type].reward.v[INFLUENCE]));
            break;
        case CITY_CANT_AFFORD: ui_toast("Недостаточно монет. Пройдите сцену ещё раз."); break;
        case CITY_BLOCKED: ui_toast("Нужно свободное место на открытом берегу"); break;
        default: break;
        }
    }

    draw_shadow(rect_offset(view, v2(0, 8)), 14, 26, rgba(0, 0, 0, 70));
    city_draw(&G.island, world, app_clock());
    draw_round_rect_line(rect_inflate(view, 2), 14, 4, hex(0x102F32));
    fx_draw();

    rect overlay = rect_inflate(view, -10);
    pill(overlay, v2(0, 0), fmt("ОСТРОВ ФИЛА · ЗОНА %d / %d", city_open_count(&G.island), ZONES));
    pill(overlay, v2(1, 0), G.island.selected < 0 ? "Тяните, чтобы исследовать" : "Коснитесь места для постройки");
    rect zoom = rect_align(overlay, sz2(102, 46), v2(1, 1));
    if (icon_button(rect_left(zoom, 46), "−")) G.island.cam = camera_zoom_at(G.island.cam, 1 / 1.25f, rect_center(view));
    if (icon_button(rect_right(zoom, 46), "+")) G.island.cam = camera_zoom_at(G.island.cam, 1.25f, rect_center(view));

    rect expand = rect_cut_right(&footer, 270);
    text_box(G.muted, rect_inflate2(footer, v2(-4, 0)), v2(0, .5f),
             G.island.selected < 0 ? "Выберите здание и коснитесь свободного места на острове."
                                   : fmt("Строится: %s. Повторное нажатие на карточку снимает выбор.", buildings[G.island.selected].name));
    int next = city_next_zone(&G.island, G.wallet);
    if (next < 0) {
        ui_button(expand, "Весь остров открыт", UI_DISABLED);
    } else {
        purse cost = G.island.zones[next].cost;
        if (ui_button(expand, fmt("Открыть берег · %d монет", cost.v[COINS]), 0)) {
            if (city_unlock(&G.island, next, &G.wallet)) {
                save_progress();
                story_line_add((story_line){"merit", "Открыт новый берег! Перетащите остров влево, чтобы его осмотреть.", BUBBLE_SHOUT});
            } else {
                ui_toast("Нужно больше монет — пройдите сцену");
            }
        }
    }
    draw_shop(shop);
    draw_chapters(side);
}

static void scene_frame(rect body, input world, float dt)
{
    const scene_def *sc = &scenes[G.scene];
    rect strip = rect_cut_bottom(&body, 64);
    rect_cut_bottom(&body, 10);
    rect view = body;

    G.cam.view = view;
    G.cam.min_zoom = camera_fit_zoom(G.cam);
    G.cam.max_zoom = G.cam.min_zoom * 3;
    G.cam = camera_clamp(G.cam);
    if (G.modal == MODAL_NONE) {
        G.cam = camera_clamp(camera_input(G.cam, world));
        if (world.tap && rect_contains(view, world.pos)) scene_tap(world.pos);
    }
    if (G.focus_time > 0) {
        G.focus_time -= dt;
        G.cam = camera_clamp(camera_look(G.cam, vec2_approach(G.cam.center, G.focus, 10, dt)));
    }

    draw_round_rect(view, 14, hex(0x0C2629));
    gfx_clip(view);
    camera_draw_texture(G.cam, G.backgrounds[G.scene]);
    for (int i = 0; i < ITEMS; i++) {
        vec2 p = camera_to_screen(G.cam, sc->at[i]);
        if (G.found & 1u << i) {
            float t = ease_out_back(saturate(((float)app_time() - G.found_time[i]) * 3));
            draw_ring(p, 15 * t, 2.5f, rgba(172, 239, 195, 230));
            draw_ring(p, 21 * t, 1.5f, rgba(172, 239, 195, 120));
        } else if (G.hint == i) {
            float r = maxf(25, minf(sc->radius[i].x, sc->radius[i].y)) * G.cam.zoom;
            float pulse = 1 + sinf((float)app_time() * 6) * .06f;
            draw_glow(p, r * 1.6f, rgba(255, 225, 116, 70), rgba(255, 225, 116, 0));
            draw_ring(p, r * pulse, 3, rgba(255, 225, 116, 255));
        }
    }
    fx_draw();
    gfx_unclip();
    draw_round_rect_line(rect_inflate(view, 2), 14, 4, hex(0x102F32));

    rect overlay = rect_inflate(view, -10);
    pill(overlay, v2(0, 0), fmt("%s · %d/%d", sc->title, found_count(), ITEMS));
    pill(overlay, v2(1, 0), "Найдите предметы");
    rect zoom = rect_align(overlay, sz2(102, 46), v2(1, 1));
    if (icon_button(rect_left(zoom, 46), "−")) G.cam = camera_zoom_at(G.cam, 1 / 1.25f, rect_center(view));
    if (icon_button(rect_right(zoom, 46), "+")) G.cam = camera_zoom_at(G.cam, 1.25f, rect_center(view));

    rect hint = rect_cut_right(&strip, 170);
    rect_cut_right(&strip, 10);
    if (ui_button(hint, "Подсказка", UI_ACCENT)) show_hint();
    ui_panel_ex(strip, hex(0x1B3F3E), hex(0x173A39), CLEAR, 12);
    rect chips = rect_inflate(strip, -6);
    for (int i = 0; i < ITEMS; i++) {
        rect chip = rect_col(chips, ITEMS, i, 6);
        bool done = G.found & 1u << i;
        draw_round_rect(chip, 9, done ? rgba(49, 83, 74, 110) : hex(0x31534A));
        rect label = text_fit(ts_fade(G.item, done ? .6f : 0), rect_inflate(chip, -6), v2(.5f, .5f), sc->names[i]);
        if (done) draw_line(rect_point(label, v2(0, .55f)), rect_point(label, v2(1, .55f)), 2, rgba(244, 232, 202, 160));
    }
}

static void win_dialog(float t)
{
    const scene_def *sc = &scenes[G.scene];
    rect s = app_screen();
    rect box = rect_centered(rect_center(s), sz2(620, 340));
    box = rect_offset(box, v2(0, (1 - ease_out_cubic(t * 3)) * 40));
    ui_panel_ex(box, hex(0x1F4645), hex(0x183B3A), hex(0xD4B775), 20);
    rect r = rect_inflate(box, -30);
    text_draw(G.eyebrow, r.pos, v2(0, 0), "ФРАГМЕНТ АРХИВА НАЙДЕН");
    rect_cut_top(&r, 22);
    text_draw(ts_size(G.theme.title, 34), r.pos, v2(0, 0), "Память возвращается");
    rect_cut_top(&r, 54);
    rect button = rect_cut_bottom(&r, 50);
    rect reward = rect_cut_bottom(&r, 40);
    const char *clue = sc->clue_lines > 1 ? fmt("%s «%s»", sc->clue[0].text, sc->clue[1].text) : sc->clue[0].text;
    text_box(ts_size(G.body, 18), r, v2(0, 0), clue);
    rect label = text_draw(G.body, rect_point(reward, v2(0, .5f)), v2(0, .5f), "Награда:");
    rect coins = amount(vec2_add(rect_point(label, v2(1, .5f)), v2(12, 0)), v2(0, .5f), G.coin, fmt("%d", scene_reward.v[COINS]), G.number);
    amount(vec2_add(rect_point(coins, v2(1, .5f)), v2(18, 0)), v2(0, .5f), G.influence, fmt("%d", scene_reward.v[INFLUENCE]), G.number);
    if (ui_button(rect_align(button, sz2(280, 50), v2(0, .5f)), "Вернуться на остров", UI_ACCENT)) go_home();
}

static void cast_dialog(float t)
{
    rect s = app_screen();
    rect box = rect_centered(rect_center(s), sz2(minf(1000, s.size.w - 60), minf(640, s.size.h - 80)));
    box = rect_offset(box, v2(0, (1 - ease_out_cubic(t * 3)) * 40));
    ui_panel_ex(box, hex(0x1F4645), hex(0x183B3A), hex(0xD4B775), 20);
    rect r = rect_inflate(box, -24);
    rect head = rect_cut_top(&r, 50);
    text_draw(ts_size(G.theme.title, 34), rect_point(head, v2(0, .5f)), v2(0, .5f), "Люди острова");
    if (ui_button(rect_align(head, sz2(50, 46), v2(1, .5f)), "×", 0)) G.modal = MODAL_NONE;
    rect_cut_top(&r, 10);
    for (int i = 0; i < CAST; i++) {
        rect col = rect_col(r, CAST, i, 20);
        rect caption = rect_cut_bottom(&col, 92);
        draw_glow(rect_point(col, v2(.5f, .78f)), col.size.w * .45f, rgba(242, 210, 140, 40), rgba(242, 210, 140, 0));
        texture face = cast[i].portrait;
        draw_image(face, rect_align(col, size2_scale(face.size, size2_fit(face.size, col.size)), v2(.5f, 1)), WHITE);
        text_draw(ts_size(G.heading, 25), rect_point(caption, v2(.5f, 0)), v2(.5f, 0), cast[i].name);
        text_box(G.muted, rect_inflate2(rect_bottom(caption, 54), v2(-10, 0)), v2(.5f, 0), cast[i].role);
    }
}

/* ------------------------------------------------------------------- frame */

static void frame(float dt)
{
    input in = input_get();
    input world = input_world();
    bool talking = story_active();
    if (G.modal != MODAL_NONE || talking) world = (input){.pos = in.pos, .pinch = 1};
    if (in.back && !talking) {
        if (G.modal == MODAL_WIN) go_home();
        else if (G.modal) G.modal = MODAL_NONE;
        else if (G.scene >= 0) go_home();
    }
    fx_update(dt);

    rect screen = app_screen();
    draw_rect_grad(screen, hex(0x12393B), hex(0x0E2B2E));
    rect header = rect_cut_top(&screen, 66);
    rect body = rect_inflate(screen, -12);

    ui_set_enabled(G.modal == MODAL_NONE && !talking);
    if (G.scene < 0) island_frame(body, world);
    else scene_frame(body, world, dt);
    draw_header(header);
    ui_set_enabled(true);

    if (G.modal != MODAL_NONE && !talking) {   /* a dialogue goes first: the reward waits for it */
        G.modal_time += dt;
        ui_modal_backdrop(G.modal_time * 4);
        if (G.modal == MODAL_WIN) win_dialog(G.modal_time);
        else cast_dialog(G.modal_time);
    }
    story_frame(dt);
}

/* -------------------------------------------------------------------- setup */

static void setup_theme(void)
{
    G.serif = font_load("fonts/Philosopher-Bold.ttf");
    G.sans = font_load("fonts/PT_Sans-Web-Regular.ttf");
    G.sans_bold = font_load("fonts/PT_Sans-Web-Bold.ttf");
    font_set_fallback(G.serif, G.sans_bold);

    color cream = hex(0xF4E8CA), ink = hex(0x0B2426);
    text_style base = {.font = G.sans, .size = 17, .fill = cream, .shadow = rgba(0, 0, 0, 90), .shadow_offset = {0, 1}, .shadow_blur = 1};
    G.body = base;
    G.muted = ts_fill(ts_size(base, 14), hex(0xB5C6B9));
    G.eyebrow = (text_style){.font = G.sans_bold, .size = 12, .fill = hex(0xB6C9BC), .tracking = 1.6f};
    G.heading = (text_style){.font = G.serif, .size = 22, .fill = cream, .shadow = rgba(0, 0, 0, 120), .shadow_offset = {0, 2}, .shadow_blur = 2};
    G.number = (text_style){.font = G.sans_bold, .size = 19, .fill = cream, .outline = ink, .outline_width = 1};
    G.item = (text_style){.font = G.sans_bold, .size = 16, .fill = cream};

    G.theme = (ui_theme){
        .text = base,
        .small = G.eyebrow,
        .title = ts_shadow(ts_outline(ts_grad((text_style){.font = G.serif, .size = 30}, hex(0xFFF3D1), hex(0xE2B46A)), 1.4f, ink),
                           v2(0, 3), 4, rgba(0, 0, 0, 140)),
        .button = (text_style){.font = G.sans_bold, .size = 17, .fill = hex(0xF5E7C5)},
        .accent_text = (text_style){.font = G.sans_bold, .size = 17, .fill = hex(0x293E39)},
        .panel = hex(0x1D4442), .panel2 = hex(0x183A39), .border = rgba(167, 173, 117, 90),
        .button_bg = hex(0x2A524F), .button_bg2 = hex(0x1F4442), .button_hot = hex(0x38615B),
        .button_border = rgba(191, 166, 107, 110),
        .accent = hex(0xF0CF8E), .accent2 = hex(0xD8AE66), .active = hex(0xE4C080),
        .dim = rgba(6, 28, 33, 215), .toast_bg = hex(0xF0D49D), .toast_text = hex(0x203C36), .radius = 10,
    };
    ui_set_theme(&G.theme);
    story_setup(cast, CAST,
                &(story_style){.text = {.font = G.sans, .size = 22, .fill = hex(0x203C36)},
                               .name = {.font = G.sans_bold, .size = 17, .fill = hex(0xFFF6E0)},
                               .bubble = hex(0xFBF1DA), .edge = hex(0x9C7A3C), .dim = rgba(6, 28, 33, 120),
                               .portrait_height = .64f, .skip = "Пропустить"});
}

/* Debug/QA entry points used to capture screenshots: --screen island|build|scene0..2|cast|win */
static void apply_screen_arg(void)
{
    const char *screen = app_arg("screen");
    G.wallet.v[INFLUENCE] = 100;
    G.wallet.v[COINS] = 900;
    if (!strncmp(screen, "scene", 5)) {
        open_scene(clampi(screen[5] - '0', 0, SCENES - 1));
        if (app_arg("found")) {
            G.found = 0x2Du;
            show_hint();
        }
    } else if (!strcmp(screen, "build")) {
        G.island.selected = 1;
    } else if (!strcmp(screen, "cast")) {
        G.modal = MODAL_CAST, G.modal_time = 1;
    } else if (!strcmp(screen, "win")) {
        open_scene(1);
        G.found = 0xFF;
        G.modal = MODAL_WIN, G.modal_time = 1;
    } else if (!strcmp(screen, "story")) {
        story_play("intro", intro, 2);
    } else if (!strcmp(screen, "horem")) {
        open_scene(2);
        G.scene = 2;
        story_play("chapter-2", scenes[2].clue, scenes[2].clue_lines);
        story_next();   /* Nefra listens while her father's note speaks */
    } else if (!strcmp(screen, "merit")) {
        story_line_add((story_line){"merit", "Открыт новый берег! Перетащите остров влево, чтобы его осмотреть.", BUBBLE_SHOUT});
    } else if (!strcmp(screen, "island")) {
        int types[] = {1, 2, 3, 4, 1};
        vec2 spots[] = {{1060, 600}, {760, 860}, {960, 1000}, {1400, 700}, {1700, 900}};
        G.island.open = 7;
        for (int i = 0; i < 5; i++) city_add(&G.island, spots[i], types[i], 0);
        G.island.cam.center = v2(1150, 720);
        G.island.cam.zoom = .55f;
    }
}

static void init(void)
{
    setup_theme();
    for (int i = 0; i < SCENES; i++) G.backgrounds[i] = tex_load(scenes[i].background);
    G.coin = tex_load("icons/coin.png");
    G.influence = tex_load("icons/influence.png");
    island_setup();
    new_game();
#ifdef __EMSCRIPTEN__
    char *legacy = legacy_progress();
    if (legacy) save_inject("progress", legacy), free(legacy);
#endif
    save_read("progress", serialize, NULL);
    G.scene = -1;
    G.hint = -1;
    if (app_arg("screen")) apply_screen_arg();
    else story_play("intro", intro, 2);
}

int main(int argc, char **argv)
{
    return app_run((app_desc){
                       .title = "Архив Нила",
                       .id = "nile-archive",
                       .design = {1200, 900},
                       .max_aspect = 16.0f / 9,
                       .landscape = true,
                       .rotate_text = "«Архив Нила» играется только в альбомной ориентации. Поверните устройство.",
                       .clear = {14, 43, 46, 255},
                       .data_dir = GAME_DATA_DIR,
                       .init = init,
                       .frame = frame,
                   },
                   argc, argv);
}
