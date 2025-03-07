#ifndef _PATCHER_GRAPHICS_H__
#define _PATCHER_GRAPHICS_H__

#include <assert.h>
#include <TXLib.h>
#include "TXWave.h"

struct point_t
{
    double x;
    double y;
};

struct rectangle_t
{
    double left;
    double right;
    double top;
    double bottom;
};

struct layout_t
{
    rectangle_t* buttons;
    const char** labels;
    size_t number;
};

int patcher_graphics_init();
int patcher_graphics_dtor();

void patcher_start_menu();
int patcher_run_menu (layout_t* menu);
int patcher_draw_menu(layout_t* menu);

bool is_in(point_t *point, rectangle_t *rect);
double get_main_menu_box_center_y(size_t number);
int play_patcher_soundtrack(const char* soundtrack_path);

#endif
