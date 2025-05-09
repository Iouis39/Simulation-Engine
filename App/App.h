#pragma once
#include "../Renderer/Renderer.h"
#include "../Utility/Keyboard.h"
#include "../Utility/Mouse.h"

#include "../Simulation/Simulation.h"

class App {
 public:
    App();
    ~App();

    void run();

 private:
    void init();
    void buildMeshes();

    SDL_Window* m_window;
    SDL_Renderer* m_sdlRenderer;
    bool isRunning = true;
    bool guiMode = false;
    
    NS::SharedPtr<CA::MetalLayer> m_layer;
    NS::SharedPtr<MTL::Device> m_device;
    NS::SharedPtr<MTL::CommandQueue> m_commandQueue;
    MTL::CaptureManager* m_captureManager;

    std::unique_ptr<Renderer> renderer;
    std::unique_ptr<Camera> camera;
    std::unique_ptr<Keyboard> keyboard;
    std::unique_ptr<Mouse> mouse;

    std::unique_ptr<Simulation> simulation;

    std::vector<std::shared_ptr<Mesh>> m_meshList;

    void processEvents();
    void update(float deltaTime);
    void ImGuiSetup();
};
