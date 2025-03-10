#include "gui.h"
#include "patcher.h"

int main() {

    SDL_Window* window          = NULL;
    SDL_Renderer* renderer      = NULL;
    SDL_Texture* background     = NULL;
    Button button               = {};
    TTF_Font* font              = NULL;
    SDL_Texture* textTexture    = NULL;
    Mix_Music* bgMusic          = NULL;

    if (GUI_Init(&window, &renderer, &background, &button, &font, &textTexture, &bgMusic) != 0) { return -1; }

    bool running = true;
    SDL_Event event;

    while (running) {

        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_QUIT) {
                running = false;
            }
            handleButtonEvent(&button, &event);
        }

        render(renderer, background, &button, textTexture);

        if (button.clicked) {
            patch();
            button.clicked = false;
        }
    }

    GNU_Quit(window, renderer, background, &button, font, textTexture, bgMusic);

    return 0;
}
