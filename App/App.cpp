#include "App.h"

App::App() {
    SDL_Init(SDL_INIT_VIDEO);
    // Trap mouse inside window
    SDL_SetRelativeMouseMode(SDL_TRUE);
    SDL_Window* window = SDL_CreateWindow("Metal + SDL2", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                                WINDOW_WIDTH, WINDOW_HEIGHT, SDL_WINDOW_METAL | SDL_WINDOW_ALLOW_HIGHDPI);
    SDL_Renderer* sdlRenderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    NS::SharedPtr<CA::MetalLayer> layer = NS::TransferPtr((CA::MetalLayer*)
                                          SDL_RenderGetMetalLayer(sdlRenderer));
    
    // set camera params
    simd::float3 pos = simd::make_float3(0.0, 0.0, -1.0);
    simd::float3 dir = simd::make_float3(0.0, 0.0, 1.0);
    simd::float3 up = simd::make_float3(0.0, 1.0, 0.0);
    float aspect = WINDOW_WIDTH / WINDOW_HEIGHT;
    
    camera = std::make_unique<Camera>(pos, dir, up, M_PI / 2, aspect, 0.1, 100);
    renderer = std::make_unique<Renderer>(layer, camera->uniforms());
    keyboard = std::make_unique<Keyboard>();
    mouse = std::make_unique<Mouse>();
}

App::~App() {
    SDL_DestroyRenderer(sdlRenderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
}

void App::run() {
    auto last = SDL_GetTicks();
    
    while(isRunning) {
        auto now = SDL_GetTicks();
        //measure time between each frame
        float deltaTime = (now - last) / 1000.0f; // in seconds
        last = now;
        
        /*
        static int frameCount = 0;
        static float timeAccumulator = 0.0f;

        frameCount++;
        timeAccumulator += deltaTime;

        if (timeAccumulator >= 1.0f) {
            std::cout << "FPS: " << frameCount << std::endl;
            frameCount = 0;
            timeAccumulator = 0.0f;
        }*/
        
        processEvents();
        update(deltaTime);
        renderer->draw();
        
        // cap to 60fps ≈ 16ms
        SDL_Delay(16);
    }
}

void App::update(float deltaTime) {
    simd::float3 velocity = {0.0f, 0.0f, 0.0f};

    /* handle camera movement consider...
     https://github.com/michaelg29/yt-tutorials/blob/master/CPP/OpenGL/OpenGLTutorial/OpenGLTutorial/src/io/camera.cpp */
    if (keyboard->isKeyPressed(SDL_SCANCODE_W))      velocity += camera->getDirection();
    if (keyboard->isKeyPressed(SDL_SCANCODE_S))      velocity -= camera->getDirection();
    if (keyboard->isKeyPressed(SDL_SCANCODE_D))      velocity += camera->getRight();
    if (keyboard->isKeyPressed(SDL_SCANCODE_A))      velocity -= camera->getRight();
    if (keyboard->isKeyPressed(SDL_SCANCODE_SPACE))  velocity += camera->getUp();
    if (keyboard->isKeyPressed(SDL_SCANCODE_LSHIFT)) velocity -= camera->getUp();

    camera->setVelocity(velocity);
    camera->adjustOrientation((float)mouse->relX(), (float)-mouse->relY());
    camera->adjustFOV(mouse->getWheelY());
    camera->update(deltaTime);
    mouse->reset();
}

void App::processEvents() {
    SDL_Event e;
    while (SDL_PollEvent(&e)) {
        if(e.type == SDL_QUIT) {
            isRunning = false;
        }
        // track pressed and released keys
        if(e.type == SDL_KEYDOWN || e.type == SDL_KEYUP) {
            keyboard->registerEvent(&e.key);
        }
        // track mouse motion
        if(e.type == SDL_MOUSEMOTION) {
            mouse->registerMouseMotion(&e.motion);
        }
        // track mouse scrolling
        if(e.type == SDL_MOUSEWHEEL) {
            mouse->registerMouseWheel(&e.wheel);
        }
    }
}
