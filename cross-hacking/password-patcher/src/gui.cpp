#include "gui.h"

const int WINDOW_WIDTH = 1280;
const int WINDOW_HEIGHT = 720;

const char* window_name = "Patcher for Kanareyka";
const char* bg_img      = "assets/pic/giant.jpg";
const char* button_font = "./assets/fonts/OpenSans_Condensed-Light.ttf";

const SDL_Color button_text_color = {255, 255, 255, 255};
const SDL_Color normalColor = {150, 50, 0, 255};  // красный
const SDL_Color hoverColor  = {200,  0, 0, 255};  // ярче при наведении

const SDL_FRect textRect    = {740, 380, 60, 40};
const SDL_FRect button_rect = {730, 360, 80, 80};

int GUI_Init(SDL_Window** window, SDL_Renderer** renderer, SDL_Texture** background,
             Button* button, TTF_Font** font, SDL_Texture** textTexture, Mix_Music** bgMusic)
{
    // Инициализация SDL
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) < 0)
    {
        printf("Ошибка инициализации SDL: %s\n", SDL_GetError());
        return -1;
    }

    // Инициализация SDL_mixer
    if (Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 2048) < 0)
    {
        printf("Ошибка инициализации SDL_mixer: %s\n", Mix_GetError());
        return -1;
    }

    if (TTF_Init() == -1)
    {
        printf("Ошибка инициализации SDL_ttf: %s\n", TTF_GetError());
        return -1;
    }

    *window   = SDL_CreateWindow(window_name, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, WINDOW_WIDTH, WINDOW_HEIGHT, SDL_WINDOW_SHOWN);
    *renderer = SDL_CreateRenderer(*window, -1, SDL_RENDERER_ACCELERATED);

    if (!*window || !*renderer)
    {
        printf("Ошибка создания окна или рендера: %s\n", SDL_GetError());
        SDL_Quit();
        return -1;
    }

    *background = loadTexture(*renderer, bg_img);
    if (!*background) {
        // Если не удалось загрузить, создаём однотонный фон
        *background = createColorTexture(*renderer, {50, 50, 50, 255}, WINDOW_WIDTH, WINDOW_HEIGHT);
    }

    *button = {
        button_rect,
        createColorTexture(*renderer, normalColor, button_rect.w, button_rect.h),
        createColorTexture(*renderer, hoverColor,  button_rect.w, button_rect.h),
        false, false
    };

    *font = TTF_OpenFont(button_font, 14);
    if (!font) {
        printf("Ошибка загрузки шрифта: %s\n", TTF_GetError());
        return -1;
    }

    *textTexture = CreateTextTexture(*renderer, *font, "Patch!", button_text_color);

    *bgMusic = Mix_LoadMUS("assets/music/17. Weapon Merchant.mp3");
    if (!*bgMusic) {
        printf("Ошибка загрузки музыки: %s\n", Mix_GetError());
    }
    else {
        Mix_PlayMusic(*bgMusic, -1); // -1 = бесконечно
    }

    return 0;
}

void GNU_Quit(SDL_Window* window, SDL_Renderer* renderer, SDL_Texture* background,
             Button* button, TTF_Font* font, SDL_Texture* textTexture, Mix_Music* bgMusic)
{
// Очистка памяти
    Mix_HaltMusic();
    Mix_FreeMusic(bgMusic);
    SDL_DestroyTexture(button -> texture);
    SDL_DestroyTexture(button -> hoverTexture);
    SDL_DestroyTexture(background);
    SDL_DestroyTexture(textTexture);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);

    TTF_CloseFont(font);
    Mix_CloseAudio();
    TTF_Quit();
    SDL_Quit();
}

void render(SDL_Renderer* renderer, SDL_Texture* background, Button* button, SDL_Texture* textTexture) {
    SDL_RenderClear(renderer);
    SDL_RenderCopy(renderer, background, NULL, NULL);

    renderButton(renderer, button);

    SDL_RenderCopyF(renderer, textTexture, NULL, &textRect);

    SDL_RenderPresent(renderer);
}

SDL_Texture* createColorTexture(SDL_Renderer* renderer, SDL_Color color, int width, int height)
{
    SDL_Texture* texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, width, height);
    SDL_SetRenderTarget(renderer, texture);
    SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, color.a);
    SDL_RenderClear(renderer);
    SDL_SetRenderTarget(renderer, NULL);
    return texture;
}

SDL_Texture* CreateTextTexture(SDL_Renderer* renderer, TTF_Font* font, const char* text, SDL_Color color)
{
    SDL_Surface* surface = TTF_RenderText_Blended(font, text, color);
    if (!surface) {
        printf("Ошибка создания поверхности текста: %s\n", TTF_GetError());
        return nullptr;
    }

    SDL_Texture* texture = SDL_CreateTextureFromSurface(renderer, surface);
    SDL_FreeSurface(surface);
    return texture;
}

SDL_Texture* loadTexture(SDL_Renderer* renderer, const char* path)
{
    SDL_Texture* texture = IMG_LoadTexture(renderer, path);
    return texture;
}

void handleButtonEvent(Button* button, SDL_Event* event)
{
    assert(button);
    assert(event);

    if (event -> type == SDL_MOUSEMOTION) {
        button -> hovered = is_in(&(button -> rect), event);
    }
    if (event -> type == SDL_MOUSEBUTTONDOWN && button -> hovered) {
        button -> clicked = true;
    }
}

bool is_in(SDL_FRect* rect, SDL_Event* event)
{
    assert(rect);

    int mx = event -> motion.x;
    int my = event -> motion.y;

    return (mx >= rect -> x && mx <= rect -> x + rect -> w &&
            my >= rect -> y && my <= rect -> y + rect -> h);
}

void renderButton(SDL_Renderer* renderer, Button* button)
{
    SDL_RenderCopyF(renderer, button -> hovered ? button -> hoverTexture : button -> texture, NULL, &(button -> rect));
}
