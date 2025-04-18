#pragma once
#include <SDL.h>
#include "Renderer.h"
#include "Keyboard.h"
#include "Mouse.h"


class App {
public:
    App();
    ~App();
    
    void run();
    
private:
    SDL_Window* window = nullptr;
    SDL_Renderer* sdlRenderer = nullptr;
    bool isRunning = true;

    std::unique_ptr<Renderer> renderer;
    std::unique_ptr<Camera> camera;
    std::unique_ptr<Keyboard> keyboard;
    std::unique_ptr<Mouse> mouse;

    void processEvents();
    void update(float deltaTime);
};
