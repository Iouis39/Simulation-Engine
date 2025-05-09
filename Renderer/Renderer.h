#pragma once
#include "../App/MetalConfig.h"
#include "Camera.h"
#include "RenderPass.h"
#include "../Utility/Primitives.h"
#include "../Simulation/Simulation.h"
#include <vector>

#include "../ImGui/backends/imgui_impl_metal.h"
#include "../ImGui/backends/imgui_impl_sdl2.h"

class Renderer {
public:
    Renderer(NS::SharedPtr<CA::MetalLayer> layer, NS::SharedPtr<MTL::Device> device, 
             NS::SharedPtr<MTL::CommandQueue> commandQueue, Uniforms& uniforms,
             MTL::CaptureManager* cpatureManager, std::vector<std::shared_ptr<Mesh>> meshList);
    ~Renderer();
    void draw();

    NS::SharedPtr<MTL::CommandQueue> getCommandQueue();
    void setModelTransform(simd::float4x4 modelTransform);
    std::vector<std::shared_ptr<Mesh>> getMeshList();
   
    void buildShadowMap();
    void buildPositionsBuffer();
    void updatePositionsBuffer(const Simulation* sim);
    
private:
    NS::SharedPtr<MTL::Device> device;
    NS::SharedPtr<MTL::CommandQueue> commandQueue;
    NS::SharedPtr<CA::MetalLayer> layer;

    MTL::CaptureManager* m_captureManager;
    
    Uniforms& m_cameraUniforms;
    LightUniforms m_lightUniforms;
    simd::float4x4 m_modelTransform = matrix4x4_identity();

    std::vector<NS::SharedPtr<MTL::Buffer>> m_dynamicPositions;
    
    NS::SharedPtr<MTL::Texture> m_shadowMap;
    NS::SharedPtr<MTL::SamplerState> m_shadowSampler;

    std::vector<std::unique_ptr<RenderPass>> m_renderPasses;
    std::vector<std::shared_ptr<Mesh>> m_meshList;
};

