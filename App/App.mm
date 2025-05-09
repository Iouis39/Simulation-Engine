#include "App.h"

//#define IMGUI_IMPL_METAL_CPP
#include "../ImGui/imgui.h"
#include "../ImGui/backends/imgui_impl_sdl2.h"
#include "../ImGui/backends/imgui_impl_metal.h"
#include <SDL.h>

#include <Metal/Metal.hpp>
#include <QuartzCore/QuartzCore.hpp>
// Obj C headers
#import <QuartzCore/QuartzCore.h>
#import <Metal/Metal.h>

App::App() {
    init();
    ImGuiSetup();
    buildMeshes();

    // CAMERA PARAMS
    simd::float3 pos = simd::make_float3(0.0, 0.5, -1.0);
    simd::float3 dir = simd::make_float3(0.0, 0.0, 1.0);
    simd::float3 up = simd::make_float3(0.0, 1.0, 0.0);
    float aspect = WINDOW_WIDTH / WINDOW_HEIGHT;

    camera = std::make_unique<Camera>(pos, dir, up, M_PI / 2, aspect, 0.1, 100);
    renderer = std::make_unique<Renderer>(m_layer, m_device, m_commandQueue, camera->uniforms(), m_captureManager, m_meshList,
                                          &m_simulationSettings);

    simulation = std::make_unique<Simulation>(m_meshList, &m_simulationSettings);
    simulation->setup();
   
    keyboard = std::make_unique<Keyboard>();
    mouse = std::make_unique<Mouse>();   
}

App::~App() {
    // Cleanup ImGui
    ImGui_ImplMetal_Shutdown();
    ImGui_ImplSDL2_Shutdown();
    ImGui::DestroyContext();
    
    // Cleanup SDL
    SDL_DestroyRenderer(m_sdlRenderer);
    SDL_DestroyWindow(m_window);
    SDL_Quit();
}

void App::init() {
    // CREATE WINDOW
    m_window = SDL_CreateWindow("Metal + SDL2", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                   WINDOW_WIDTH, WINDOW_HEIGHT, SDL_WINDOW_RESIZABLE | SDL_WINDOW_ALLOW_HIGHDPI);
    
    // WINDOW SETUP
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER | SDL_INIT_GAMECONTROLLER) != 0) {
        printf("Error: %s\n", SDL_GetError()); }
    
    SDL_SetHint(SDL_HINT_RENDER_DRIVER, "metal");
    SDL_SetHint(SDL_HINT_IME_SHOW_UI, "1");
    SDL_SetRelativeMouseMode(SDL_TRUE); // TRAP MOUSE INSIDE WINDOW
    SDL_ShowCursor(SDL_FALSE);
    
    if (m_window == nullptr) printf("Error creating window: %s\n", SDL_GetError());
    
    // CREATE SDL-RENDERER
    //----------------------------------------------------------------------------VSYNC ENABLED----------
    m_sdlRenderer = SDL_CreateRenderer(m_window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
    
    if (m_sdlRenderer == nullptr) printf("Error creating renderer: %s\n", SDL_GetError());
    
    // INITIALIZE METAL OBJECTS
    m_device = NS::TransferPtr(MTL::CreateSystemDefaultDevice());
    m_commandQueue = NS::TransferPtr(m_device->newCommandQueue());
    m_layer = NS::TransferPtr((CA::MetalLayer*)SDL_RenderGetMetalLayer(m_sdlRenderer));
    m_layer->setDevice(m_device.get());
    m_layer->setPixelFormat(MTL::PixelFormatBGRA8Unorm);
    
    
    int width, height;
    SDL_GetRendererOutputSize(m_sdlRenderer, &width, &height);
    m_layer->setDrawableSize(CGSizeMake(width, height));

    // ------------ CAPTURE DESCRIPTOR --------------- //
    m_captureManager = MTL::CaptureManager::sharedCaptureManager();

    NS::Error* error = nullptr;
    MTL::CaptureDescriptor* captureDescriptor = MTL::CaptureDescriptor::alloc()->init();
    captureDescriptor->setCaptureObject((__bridge id<MTLCommandQueue>)m_commandQueue.get());
    captureDescriptor->setDestination(MTL::CaptureDestinationGPUTraceDocument);
    captureDescriptor->setOutputURL(NS::URL::fileURLWithPath(
               NS::String::string(
               "/Users/louisgrunberg/Documents/SimulationEngine/build/gputrace/framecapture.gputrace", NS::UTF8StringEncoding)));

    // Try to start the capture
    bool captureStarted = m_captureManager->startCapture(captureDescriptor, &error);

    if (!captureStarted) {
      if (error) {
        std::cout << "Capture failed: " << error->localizedDescription()->utf8String() << std::endl;
    } else {
        std::cout << "Capture failed: Unknown reason" << std::endl;
      }
    }

    captureDescriptor->release();
}

void App::buildMeshes() {
  MTKMeshBufferAllocator* allocator = [[MTKMeshBufferAllocator alloc] initWithDevice: (__bridge id<MTLDevice>)m_device.get()];
  simd::half3 color = simd::make_half3(0.8, 0.6, 1.0);
    
  m_meshList.push_back(std::make_shared<Mesh>(m_device.get(), allocator, 
                       "/Users/louisgrunberg/Documents/SimulationEngine/Assets/cube.obj"));
  m_meshList[0]->color = color;
}

void App::run() {
    auto last = SDL_GetTicks();
    
    while(isRunning) {
        auto now = SDL_GetTicks();
        //measure time between each frame
        float deltaTime = (now - last) / 1000.0f; // in seconds
        last = now;
        
        simulation->update(1.0f / 60.f);
        renderer->updatePositionsBuffer(simulation.get());
        processEvents();
        update(deltaTime);
        renderer->draw();

        //m_captureManager->stopCapture();
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
    // accelerate when pressing shift + w
    if (keyboard->isKeyPressed(SDL_SCANCODE_W)
        && keyboard->isKeyPressed(SDL_SCANCODE_LSHIFT)) velocity += 2.0f * camera->getDirection();
    
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
        if(keyboard->isKeyClicked(SDL_SCANCODE_ESCAPE)) {
            guiMode = true;
        }
        
        if(keyboard->isKeyClicked(SDL_SCANCODE_TAB)) {
            guiMode = false;
        }

        if(keyboard->isKeyClicked(SDL_SCANCODE_G)) {
            m_captureManager->stopCapture();
            std::cout << "d" << std::endl;
        }
        
        // track pressed and released keys
        if(e.type == SDL_KEYDOWN || e.type == SDL_KEYUP) {
            keyboard->registerEvent(&e.key);
        }
        
        // WHEN GUIMODE IS FALSE, WE TRACK INPUTS FOR OUR APPLICATION
        if (!guiMode) {
            SDL_SetRelativeMouseMode(SDL_TRUE);
            SDL_ShowCursor(SDL_FALSE);
            SDL_WarpMouseInWindow(m_window, WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2);
            
            //track mouse motion
            if(e.type == SDL_MOUSEMOTION) {
                mouse->registerMouseMotion(&e.motion);
            }
            // track mouse scrolling
            if(e.type == SDL_MOUSEWHEEL) {
                mouse->registerMouseWheel(&e.wheel);
            }
            
            if(e.type == SDL_MOUSEBUTTONDOWN || e.type == SDL_MOUSEBUTTONUP) {
                mouse->registerMouseButton(&e.button);
            }
            
            (void)SDL_GetRelativeMouseState(nullptr, nullptr);
            
            } else {
                SDL_SetRelativeMouseMode(SDL_FALSE);
                SDL_ShowCursor(SDL_TRUE);
            }
        
        ImGui_ImplSDL2_ProcessEvent(&e);
    }
}

void App::ImGuiSetup() {
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;  // Enable Keyboard Controls
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad;   // Enable Gamepad Controls
    
    ImGui_ImplMetal_Init((__bridge id<MTLDevice>)(m_device.get()));
    ImGui_ImplSDL2_InitForMetal(m_window);
}

