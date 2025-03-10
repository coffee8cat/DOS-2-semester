#ifndef _GRAPHICAL_USER_INTERFACE_H__
#define _GRAPHICAL_USER_INTERFACE_H__

#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>
#include <SDL2/SDL_ttf.h>
#include <SDL2/SDL_mixer.h>
#include <stdio.h>
#include <assert.h>

struct Button {
    SDL_FRect rect;
    SDL_Texture* texture;
    SDL_Texture* hoverTexture;
    bool hovered;
    bool clicked;
};

int GUI_Init(SDL_Window** window, SDL_Renderer** renderer, SDL_Texture** background,
             Button* button, TTF_Font** font, SDL_Texture** textTexture, Mix_Music** bgMusic);

void GNU_Quit(SDL_Window* window, SDL_Renderer* renderer, SDL_Texture* background,
             Button* button, TTF_Font* font, SDL_Texture* textTexture, Mix_Music* bgMusic);

void render(SDL_Renderer* renderer, SDL_Texture* background, Button* button, SDL_Texture* textTexture);

SDL_Texture* createColorTexture(SDL_Renderer* renderer, SDL_Color color, int width, int height);
SDL_Texture* CreateTextTexture(SDL_Renderer* renderer, TTF_Font* font, const char* text, SDL_Color color);
SDL_Texture* loadTexture(SDL_Renderer* renderer, const char* path);

void handleButtonEvent(Button* button, SDL_Event* event);
bool is_in(SDL_FRect* rect, SDL_Event* event);
void renderButton(SDL_Renderer* renderer, Button* button);

#endif
