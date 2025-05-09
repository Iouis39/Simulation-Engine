#include "App.h"

int main() {
    App app;
    app.run();
    return 0;
}

// Dear ImGui: standalone example application for GLFW + Metal, using programmable pipeline
// (GLFW is a cross-platform general purpose library for handling windows, inputs, OpenGL/Vulkan/Metal graphics context creation, etc.)
// If you are new to Dear ImGui, read documentation from the docs/ folder + read the top of imgui.cpp.
// Read online: https://github.com/ocornut/imgui/tree/master/docs

// Metal CPP headers
//#include <Metal/Metal.hpp>
//#include <QuartzCore/QuartzCore.hpp>
//#include <Foundation/Foundation.hpp>
/*
#define IMGUI_IMPL_METAL_CPP
#include "../im-gui/imgui.h"
#include "../im-gui/backends/imgui_impl_sdl2.h"
#include "../im-gui/backends/imgui_impl_metal.h"
#include <SDL.h>
//#include <stdio.h>

#include <Metal/Metal.hpp>
#include <QuartzCore/QuartzCore.hpp>
// Obj C headers
#import <QuartzCore/QuartzCore.h>
#import <Metal/Metal.h>


int main(int, char**)
{
    // Setup Dear ImGui context
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;
    //io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;  // Enable Keyboard Controls
    //io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad;   // Enable Gamepad Controls

    // Setup style
    ImGui::StyleColorsDark();
    //ImGui::StyleColorsLight();

    // Load Fonts
    // - If no fonts are loaded, dear imgui will use the default font. You can also load multiple fonts and use ImGui::PushFont()/PopFont() to select them.
    // - AddFontFromFileTTF() will return the ImFont* so you can store it if you need to select the font among multiple.
    // - If the file cannot be loaded, the function will return NULL. Please handle those errors in your application (e.g. use an assertion, or display an error and quit).
    // - The fonts will be rasterized at a given size (w/ oversampling) and stored into a texture when calling ImFontAtlas::Build()/GetTexDataAsXXXX(), which ImGui_ImplXXXX_NewFrame below will call.
    // - Use '#define IMGUI_ENABLE_FREETYPE' in your imconfig file to use Freetype for higher quality font rendering.
    // - Read 'docs/FONTS.md' for more instructions and details.
    // - Remember that in C/C++ if you want to include a backslash \ in a string literal you need to write a double backslash \\ !
    //io.Fonts->AddFontDefault();
    //io.Fonts->AddFontFromFileTTF("c:\\Windows\\Fonts\\segoeui.ttf", 18.0f);
    //io.Fonts->AddFontFromFileTTF("../../misc/fonts/DroidSans.ttf", 16.0f);
    //io.Fonts->AddFontFromFileTTF("../../misc/fonts/Roboto-Medium.ttf", 16.0f);
    //io.Fonts->AddFontFromFileTTF("../../misc/fonts/Cousine-Regular.ttf", 15.0f);
    //ImFont* font = io.Fonts->AddFontFromFileTTF("c:\\Windows\\Fonts\\ArialUni.ttf", 18.0f, NULL, io.Fonts->GetGlyphRangesJapanese());
    //IM_ASSERT(font != NULL);

    // Setup window
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER | SDL_INIT_GAMECONTROLLER) != 0)
      {
          printf("Error: %s\n", SDL_GetError());
          return -1;
      }

      // Inform SDL that we will be using metal for rendering. Without this hint initialization of metal renderer may fail.
      SDL_SetHint(SDL_HINT_RENDER_DRIVER, "metal");

      // Enable native IME.
      SDL_SetHint(SDL_HINT_IME_SHOW_UI, "1");

      SDL_Window* window = SDL_CreateWindow("Dear ImGui SDL+Metal example", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 1280, 720, SDL_WINDOW_RESIZABLE | SDL_WINDOW_ALLOW_HIGHDPI);
      if (window == nullptr)
      {
          printf("Error creating window: %s\n", SDL_GetError());
          return -2;
      }

      SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
      if (renderer == nullptr)
      {
          printf("Error creating renderer: %s\n", SDL_GetError());
          return -3;
      }

    // Metal Cpp device - could be used in external rendeing cpp code
    MTL::Device* device = MTL::CreateSystemDefaultDevice();
    MTL::CommandQueue* commandQueue = device->newCommandQueue();

    // Setup Platform/Renderer backends
    ImGui_ImplMetal_Init((__bridge id<MTLDevice>)(device));
    ImGui_ImplSDL2_InitForMetal(window);

    // Here is key thing for integration GLFW with Metal Cpp
    // GLFW supports only obj c window handle
    CA::MetalLayer* layer = (CA::MetalLayer*)SDL_RenderGetMetalLayer(renderer);
    layer->setDevice(device);
    layer->setPixelFormat(MTL::PixelFormatBGRA8Unorm);

    MTL::RenderPassDescriptor *renderPassDescriptor = MTL::RenderPassDescriptor::renderPassDescriptor();

    // Our state
    bool show_demo_window = true;
    bool show_another_window = false;
    float clear_color[4] = {0.45f, 0.55f, 0.60f, 1.00f};

    bool done = false;
    
    // Main loop
    while (!done)
    {
        @autoreleasepool
        {
            SDL_Event event;
            while(SDL_PollEvent(&event)) {
                ImGui_ImplSDL2_ProcessEvent(&event);
                if (event.type == SDL_QUIT)
                    done = true;
                if (event.type == SDL_WINDOWEVENT && event.window.event == SDL_WINDOWEVENT_CLOSE && event.window.windowID == SDL_GetWindowID(window))
                    done = true;
            }

            int width, height;
            SDL_GetRendererOutputSize(renderer, &width, &height);
            layer->setDrawableSize(CGSizeMake(width, height));
            CA::MetalDrawable* drawable = layer->nextDrawable();

            // bridge to obj c code for ImGui but it is possible to use cpp too
            id<MTLCommandBuffer> commandBuffer =
                (__bridge id<MTLCommandBuffer>)(commandQueue->commandBuffer());
            renderPassDescriptor->colorAttachments()->object(0)->setClearColor(MTL::ClearColor::Make(clear_color[0] * clear_color[3], clear_color[1] * clear_color[3], clear_color[2] * clear_color[3], clear_color[3]));
            renderPassDescriptor->colorAttachments()->object(0)->setTexture(drawable->texture());
            renderPassDescriptor->colorAttachments()->object(0)->setLoadAction(MTL::LoadActionClear);
            renderPassDescriptor->colorAttachments()->object(0)->setStoreAction(MTL::StoreActionStore);

            id <MTLRenderCommandEncoder> renderEncoder =
            [commandBuffer renderCommandEncoderWithDescriptor:(__bridge MTLRenderPassDescriptor*)renderPassDescriptor];
            [renderEncoder pushDebugGroup:@"ImGui demo"];

            // Start the Dear ImGui frame
            ImGui_ImplMetal_NewFrame((__bridge MTLRenderPassDescriptor*)renderPassDescriptor);
            ImGui_ImplSDL2_NewFrame();
            ImGui::NewFrame();

            // 1. Show the big demo window (Most of the sample code is in ImGui::ShowDemoWindow()! You can browse its code to learn more about Dear ImGui!).
            if (show_demo_window)
                ImGui::ShowDemoWindow(&show_demo_window);

            // 2. Show a simple window that we create ourselves. We use a Begin/End pair to create a named window.
            {
                static float f = 0.0f;
                static int counter = 0;

                ImGui::Begin("Hello, world!");                          // Create a window called "Hello, world!" and append into it.

                ImGui::Text("This is some useful text.");               // Display some text (you can use a format strings too)
                ImGui::Checkbox("Demo Window", &show_demo_window);      // Edit bools storing our window open/close state
                ImGui::Checkbox("Another Window", &show_another_window);

                ImGui::SliderFloat("float", &f, 0.0f, 1.0f);            // Edit 1 float using a slider from 0.0f to 1.0f
                ImGui::ColorEdit3("clear color", (float*)&clear_color); // Edit 3 floats representing a color

                if (ImGui::Button("Button"))                            // Buttons return true when clicked (most widgets return true when edited/activated)
                    counter++;
                ImGui::SameLine();
                ImGui::Text("counter = %d", counter);

                ImGui::Text("Application average %.3f ms/frame (%.1f FPS)", 1000.0f / ImGui::GetIO().Framerate, ImGui::GetIO().Framerate);
                ImGui::End();
            }

            // 3. Show another simple window.
            if (show_another_window)
            {
                ImGui::Begin("Another Window", &show_another_window);   // Pass a pointer to our bool variable (the window will have a closing button that will clear the bool when clicked)
                ImGui::Text("Hello from another window!");
                if (ImGui::Button("Close Me"))
                    show_another_window = false;
                ImGui::End();
            }

            // Rendering
            ImGui::Render();
            ImGui_ImplMetal_RenderDrawData(ImGui::GetDrawData(), commandBuffer, renderEncoder);

            [renderEncoder popDebugGroup];
            [renderEncoder endEncoding];

            [commandBuffer presentDrawable:(__bridge id<MTLDrawable>)drawable];
            [commandBuffer commit];
        }
    }

    // Cleanup
    ImGui_ImplMetal_Shutdown();
    ImGui_ImplSDL2_Shutdown();
    ImGui::DestroyContext();
    
    // Cleanup SDL
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    

    return 0;
}
*/
