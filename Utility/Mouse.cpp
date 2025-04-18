#include "Mouse.h"

void Mouse::registerMouseMotion(SDL_MouseMotionEvent* event) {
    m_relX = event->xrel;
    m_relY = event->yrel;
}

void Mouse::registerMouseWheel(SDL_MouseWheelEvent* event) {
    m_mouseWheelX = event->x;
    m_mouseWheelY = event->y;
}

void Mouse::reset() {
    m_relX = 0;
    m_relY = 0;
}

int32_t Mouse::relX() {
    return m_relX;
}
int32_t Mouse::relY() {
    return m_relY;
}

float Mouse::getWheelX() {
    return m_mouseWheelX;
}

float Mouse::getWheelY() {
    return m_mouseWheelY;
}
