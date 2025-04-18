#pragma once
#include "MetalConfig.h"
#include <map>

class Keyboard {
    using KeyState = std::unordered_map<SDL_Scancode, bool>;
   
public:
    bool isKeyClicked(SDL_Scancode key);
    bool isKeyPressed(SDL_Scancode key);
    
    void registerEvent(SDL_KeyboardEvent* event);
    void update();
    
private:
    KeyState currentKeyState;
    KeyState previousKeyState;
};
