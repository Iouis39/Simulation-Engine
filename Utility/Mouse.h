#pragma once
#include "MetalConfig.h"

class Mouse {
public:
    void registerMouseMotion(SDL_MouseMotionEvent* event);
    void registerMouseWheel(SDL_MouseWheelEvent* event);
   
    void reset();
    
    int32_t relX();
    int32_t relY();
    
    float getWheelX();
    float getWheelY();
    
private:
    int32_t m_relX {};
    int32_t m_relY {};
    
    float m_mouseWheelX {};
    float m_mouseWheelY {};
};
