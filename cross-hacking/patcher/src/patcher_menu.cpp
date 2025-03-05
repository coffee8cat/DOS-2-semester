#include "patcher_menu.h"

static HDC WindowBackground = NULL;

static size_t WindowLength = 800;
static size_t WindowHeight = 600;

static const size_t ButtonsNumber = 1;
static double ButtonLength = 300;
static double ButtonHeight = 200;

int patcher_graphics_init()
{
    txCreateWindow(WindowLength, WindowHeight);
    WindowBackground = txLoadImage("alchemist.bmp");
    txBitBlt(txDC(), 0, 0, WindowLength, WindowHeight, WindowBackground);

    return 0;
}

int patcher_graphics_dtor()
{
    txDeleteDC(WindowBackground);
    WindowBackground = NULL;
    txDisableAutoPause();

    return 0;
}

void patcher_prepare_to_display_window()
{
    //txBitBlt(txDC(), 0, 0, WindowLength, WindowHeight, WindowBackground);
    rectangle_t rectangles[ButtonsNumber] = {};
    for(size_t i = 0; i < ButtonsNumber; i++)
    {
        double box_center_y  = get_main_menu_box_center_y(i);

        rectangles[i].left   = (WindowLength - ButtonLength) / 2;
        rectangles[i].right  = (WindowLength + ButtonLength) / 2;
        rectangles[i].top    = box_center_y + ButtonHeight / 2;
        rectangles[i].bottom = box_center_y - ButtonHeight / 2;
    }

    const char* labels[] = { "Start" };
    layout_t menu = {
        .buttons = rectangles,
        .labels = labels,
        .number = ButtonsNumber
    };

    //patcher_run_menu(&menu);
}
/*
int patcher_run_menu(layout_t* menu)
{
    assert(menu);

txBegin();
    akinator_draw_menu(menu, *chosen_case);
    while(true) {
        POINT   tx_mouse_pos   = txMousePos();
        point_t mouse_position = {.x = (double)tx_mouse_pos.x,
                                  .y = (double)tx_mouse_pos.y};
        bool is_set     = false;
        bool is_running = true;
        for(size_t i = 0; i < menu->number; i++) {
            if(is_in(&mouse_position, menu->button_boxes + i)) {
                *chosen_case = i;
                is_set = true;
                if(txGetAsyncKeyState(VK_LBUTTON)) {
                    is_running = false;
                }
            }
        }
        if(!is_set) {
            *chosen_case = menu->number;
        }
        if(!is_running) {
            akinator_draw_menu(menu, menu->number);
            break;
        }
        akinator_draw_menu(menu, *chosen_case);
    }
    txEnd();
    return AKINATOR_SUCCESS;
}
*/

/*
int patcher_draw_menu(akinator_menu_t *menu, size_t highlighted)
{
    for(size_t i = 0; i < menu->number; i++) {
        COLORREF fill_color = BoxColor;
        COLORREF color      = BoxColor;
        if(i == highlighted) {
            fill_color = HighlightedBoxColor;
            color = HighlightedBoxColor;
        }

        txSetColor(color);
        txSetFillColor(fill_color);
        rectangle_t *box_rectangle = menu->button_boxes + i;
        txRectangle(box_rectangle->left,
                    box_rectangle->bottom,
                    box_rectangle->right,
                    box_rectangle->top);

        txSetColor(TextColor);
        txDrawText(box_rectangle->left,
                   box_rectangle->bottom,
                   box_rectangle->right,
                   box_rectangle->top,
                   menu->labels[i]);
    }
    txRedrawWindow();

    return 0;
}
*/

bool is_in(point_t *point, rectangle_t *rect)
{
    if(point->x < rect->left ||
       point->x > rect->right) {
        return false;
    }
    if(point->y < rect->bottom ||
       point->y > rect->top) {
        return false;
    }

    return true;
}

inline double get_main_menu_box_center_y(size_t number)
{
    return WindowHeight / 2 + (2 * (double)number - (double)ButtonsNumber) * ButtonHeight;
}

int play_patcher_soundtrack(const char* soundtrack_path)
{
    assert(soundtrack_path);

    txWaveData_t soundtrack = txWaveLoadWav(soundtrack_path);
    txWaveOut(soundtrack);
    txWaveOut();

    return 0;
}
