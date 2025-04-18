#pragma once
#include "MetalConfig.h"
#include "Triangle.h"
#include "Cube.h"
#include "Camera.h"

class Renderer {
public:
    Renderer(NS::SharedPtr<CA::MetalLayer> layer, CameraUniforms& uniforms);
    ~Renderer();
    void draw();
    
    // Utility
    MTL::RenderPipelineState* buildShader(const char* vertName, const char* fragName);
    void buildDepthStencilStates();
    
private:
    NS::SharedPtr<MTL::RenderPipelineState> renderPipelineState;
    NS::SharedPtr<MTL::DepthStencilState> depthStencilState;
    
    NS::SharedPtr<MTL::Device> device;
    NS::SharedPtr<MTL::CommandQueue> commandQueue;
    NS::SharedPtr<CA::MetalLayer> layer;
    
    CameraUniforms& cameraUniforms;
    
    Triangle Triangle;
    Cube Cube;
};
