#include "Keyboard.h"

bool Keyboard::isKeyClicked(SDL_Scancode key) {
    return currentKeyState[key] && !previousKeyState[key];
}

bool Keyboard::isKeyPressed(SDL_Scancode key) {
    return currentKeyState[key];
}

void Keyboard::registerEvent(SDL_KeyboardEvent* event) {
    currentKeyState[event->keysym.scancode] = event->state;
}

void Keyboard::update() {
    previousKeyState = currentKeyState;
}
