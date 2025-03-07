#include "patcher_menu.h"
#include "patcher.h"

int main()
{
    //patch();
    play_patcher_soundtrack("menu_resources\\Megalovania.wav");

    patcher_graphics_init();
    patcher_start_menu();
    patcher_graphics_dtor();

    return 0;
}
