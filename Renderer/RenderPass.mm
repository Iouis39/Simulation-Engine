#include "RenderPass.h"
#include "Metal/MTLRenderCommandEncoder.hpp"

#define IMGUI_IMPL_METAL_CPP
#include "../ImGui/imgui.h"
#include "../ImGui/backends/imgui_impl_sdl2.h"
#include "../ImGui/backends/imgui_impl_metal.h"

#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>

#include <MetalKit/MetalKit.h>

//--------------------------------------------------//
//-------------------MAIN-PASS---------------------//
//------------------------------------------------//

MainPass::MainPass(NS::SharedPtr<MTL::Device> device, Uniforms& cameraUniforms, LightUniforms& lightUniforms,
                   NS::SharedPtr<MTL::Texture> shadowMap, NS::SharedPtr<MTL::SamplerState> shadowSampler,
                   simd::float4x4& modelTransform, std::vector<NS::SharedPtr<MTL::Buffer>> dynamicPositions, 
                   std::vector<NS::SharedPtr<MTL::Buffer>> remapTables, SimulationSettings* simulationSettings)
                   : m_device(device), m_cameraUniforms(cameraUniforms), 
                     m_lightUniforms(lightUniforms), m_shadowMap(shadowMap), 
                     m_shadowSampler(shadowSampler), m_modelTransform(modelTransform),
                     m_dynamicPositions(dynamicPositions), m_remapTables(remapTables),
                     m_simulationSettings(simulationSettings) {
    
    Quad = buildQuad(m_device.get(), simd::make_half3(0.212, 0.271, 0.31));
    Cube = buildCube(m_device.get(), simd::make_half3(0.12, 0.1, 0.6));
    m_renderPipelineState = NS::TransferPtr(buildPipeline("vertexShader", "fragmentShader"));
    buildDepthStencilState();
  };


MTL::RenderPipelineState* MainPass::buildPipeline(const char *vertName, const char *fragName) {
   NS::Error* error = nullptr;
   NS::String* filePath = NS::String::string("/Users/louisgrunberg/Documents/SimulationEngine/build/ShaderBase.metallib", 
                                                                                                  NS::UTF8StringEncoding);
   MTL::Library* library = m_device->newLibrary(filePath, &error);
    
    if(!library) {
        std::cout << error->localizedDescription()->utf8String() << std::endl;
    }
    
    // Create Vertex Function
    NS::String* vertexName = NS::String::string(vertName, NS::StringEncoding::UTF8StringEncoding);
    MTL::Function* vertexMain = library->newFunction(vertexName);
    if(!vertexMain) {
        std::cout << "Vertex Function failed" << std::endl;
    }
    
    // Create Fragment Function
    NS::String* fragmentName = NS::String::string(fragName, NS::StringEncoding::UTF8StringEncoding);
    MTL::Function* fragmentMain = library->newFunction(fragmentName);
    
    MTL::RenderPipelineDescriptor* pipelineDescriptor = MTL::RenderPipelineDescriptor::alloc()->init();
    pipelineDescriptor->setVertexFunction(vertexMain);
    pipelineDescriptor->setFragmentFunction(fragmentMain);
    pipelineDescriptor->colorAttachments()->object(0)->setPixelFormat(MTL::PixelFormat::PixelFormatBGRA8Unorm);
    pipelineDescriptor->colorAttachments()->object(0)->setBlendingEnabled(true);
    pipelineDescriptor->colorAttachments()->object(0)->setRgbBlendOperation(MTL::BlendOperationAdd);
    pipelineDescriptor->colorAttachments()->object(0)->setAlphaBlendOperation(MTL::BlendOperationAdd);
    
    MTL::VertexDescriptor* vertexDescriptor = MTL::VertexDescriptor::alloc()->init();
    auto attributes = vertexDescriptor->attributes();

    auto positionDescriptor = attributes->object(0);
    positionDescriptor->setFormat(MTL::VertexFormat::VertexFormatFloat3);
    positionDescriptor->setOffset(0);
    positionDescriptor->setBufferIndex(0);

    auto normalDescriptor = attributes->object(1);
    normalDescriptor->setFormat(MTL::VertexFormat::VertexFormatFloat3);
    normalDescriptor->setOffset(sizeof(simd::float3));
    normalDescriptor->setBufferIndex(0);

    auto layoutDescriptor = vertexDescriptor->layouts()->object(0);
    layoutDescriptor->setStepFunction(MTL::VertexStepFunctionPerVertex);
    layoutDescriptor->setStride(sizeof(Vertex3));
    
    pipelineDescriptor->setDepthAttachmentPixelFormat(MTL::PixelFormat::PixelFormatDepth32Float);
    pipelineDescriptor->setVertexDescriptor(vertexDescriptor);

    MTL::RenderPipelineState* pipeline = m_device->newRenderPipelineState(pipelineDescriptor, &error);
    if(!pipeline) std::cout << error->localizedDescription()->utf8String() << std::endl;
    
    vertexMain->release();
    fragmentMain->release();
    pipelineDescriptor->release();
    library->release();
    
    return pipeline;
}

void MainPass::buildDepthStencilState() {
    MTL::DepthStencilDescriptor* depthStencilDescriptor = MTL::DepthStencilDescriptor::alloc()->init();
    depthStencilDescriptor->setDepthCompareFunction(MTL::CompareFunctionLess);
    depthStencilDescriptor->setDepthWriteEnabled(true);
   
    m_depthStencilState = NS::TransferPtr(m_device->newDepthStencilState(depthStencilDescriptor));
    depthStencilDescriptor->release();
}

void MainPass::buildImGui() {
    ImGui::Begin("Simulation Parameters");
    ImGui::StyleColorsClassic();
    ImGuiIO& io = ImGui::GetIO();
    ImGui::SetWindowPos(ImVec2(0.0f, 0.0f));
    ImVec2 windowDimension = ImVec2(io.DisplaySize.x * 0.3, io.DisplaySize.y * 0.4);
    ImGui::SetWindowSize(windowDimension);

    ImGui::Text("Point Masses: %d", m_simulationSettings->pointMassCount);

    ImGui::Checkbox("Wireframe", &useWriteFrameMode);
    ImGui::Checkbox("Pause", &m_simulationSettings->paused);
    ImGui::Checkbox("Gravity", &m_simulationSettings->gravityEnabled);

    ImGui::SetNextItemWidth(windowDimension.x * 0.4);
    ImGui::SliderFloat("Timestep", &m_simulationSettings->dt, 0.001f, 0.01f);

     
    ImGui::End();
}

void MainPass::encode(MTL::CommandBuffer *commandBuffer, MTL::Texture* drawableTexture, std::vector<std::shared_ptr<Mesh>> meshList) {
    m_pass = MTL::RenderPassDescriptor::renderPassDescriptor();
    m_pass->colorAttachments()->object(0)->setTexture(drawableTexture);
    m_pass->colorAttachments()->object(0)->setClearColor(MTL::ClearColor::Make(0.2, 0.76, 1.0, 1.0));
    m_pass->colorAttachments()->object(0)->setLoadAction(MTL::LoadActionClear);
    m_pass->colorAttachments()->object(0)->setStoreAction(MTL::StoreActionStore);
    
    MTL::RenderPassDepthAttachmentDescriptor* depthAttachment = m_pass->depthAttachment();
    depthAttachment->setClearDepth(1.0f);

    bool useDynamicPositions = false;
    
    auto encoder = commandBuffer->renderCommandEncoder(m_pass);
    
    encoder->setDepthStencilState(m_depthStencilState.get());
    encoder->setRenderPipelineState(m_renderPipelineState.get());

    encoder->setCullMode(MTL::CullModeBack);
    encoder->setFrontFacingWinding(MTL::WindingCounterClockwise);
    
    encoder->setFragmentTexture(m_shadowMap.get(), NS::UInteger(0));
    encoder->setFragmentBytes(&m_lightUniforms, sizeof(LightUniforms), NS::UInteger(1));
    encoder->setFragmentBytes(&Quad.color, sizeof(simd::half3), NS::UInteger(2));
    encoder->setFragmentSamplerState(m_shadowSampler.get(), NS::UInteger(0));
    
    // set camera uniform
    encoder->setVertexBytes(&m_cameraUniforms, sizeof(Uniforms), NS::UInteger(1));

    encoder->setVertexBytes(&useDynamicPositions, sizeof(bool), NS::UInteger(4));

    // Render Ground Plane
    encoder->setVertexBuffer(Quad.vertexBuffer.get(), NS::UInteger(0), NS::UInteger(0));
    simd::float4x4 I = matrix_identity_float4x4;
    encoder->setVertexBytes(&I, sizeof(simd::float4x4), NS::UInteger(2));
    encoder->drawIndexedPrimitives(MTL::PrimitiveTypeTriangle, NS::UInteger(6), 
                                         MTL::IndexTypeUInt16, Quad.indexBuffer.get(), NS::UInteger(0), NS::UInteger(1));
    
    // activate dynamic positions
    useDynamicPositions = true;
    encoder->setVertexBytes(&useDynamicPositions, sizeof(bool), NS::UInteger(4));

    size_t i = 0;
    // loop over meshes
    for(auto m : meshList) {
      encoder->setFragmentBytes(&m->color, sizeof(simd::half3), NS::UInteger(2));
      encoder->setVertexBuffer(m->getVertexBuffer(), m->getVertexBufferOffset(), NS::UInteger(0));
      encoder->setVertexBytes(&m->modelMatrix, sizeof(simd::float4x4), NS::UInteger(2));
      encoder->setVertexBuffer(m_dynamicPositions.at(i).get(), NS::UInteger(0), NS::UInteger(3));
      encoder->setVertexBuffer(m_remapTables.at(i).get(), NS::UInteger(0), NS::UInteger(5));
     
      
      if(useWriteFrameMode) encoder->setTriangleFillMode(MTL::TriangleFillModeLines); 
      encoder->drawIndexedPrimitives(MTL::PrimitiveTypeTriangle, m->getIndexCount(), m->getIndexType(), m->getIndexBuffer(), 
                                     m->getIndexBufferOffset(), NS::UInteger(1));   
      i++;
    }

    encoder->setTriangleFillMode(MTL::TriangleFillModeFill);

    // begin ImGui Frame 
    ImGui_ImplMetal_NewFrame((__bridge MTLRenderPassDescriptor*)m_pass);
    ImGui_ImplSDL2_NewFrame();
    ImGui::NewFrame();
    
    buildImGui();
    
    ImGui::Render();
    ImGui_ImplMetal_RenderDrawData(ImGui::GetDrawData(),
                                   (__bridge id<MTLCommandBuffer>)commandBuffer,
                                   (__bridge id<MTLRenderCommandEncoder>)encoder);
    
    encoder->endEncoding();
}

//----------------------------------------------------//
//-------------------SHADOW-PASS---------------------//
//--------------------------------------------------//

ShadowPass::ShadowPass(NS::SharedPtr<MTL::Device> device, LightUniforms& lightUniforms,
                       NS::SharedPtr<MTL::Texture> shadowMap, simd::float4x4& modelTransform, 
                       std::vector<NS::SharedPtr<MTL::Buffer>> dynamicPositions, std::vector<NS::SharedPtr<MTL::Buffer>> remapTables)
: m_device(device), m_lightUniforms(lightUniforms), m_shadowMap(shadowMap), m_modelTransform(modelTransform), 
  m_dynamicPositions(dynamicPositions), m_remapTables(remapTables) {
    Quad = buildQuad(m_device.get(), simd::make_half3(0.212, 0.271, 0.31));
    Cube = buildCube(m_device.get(), simd::make_half3(0.12, 0.1, 0.6));
    m_shadowPipelineState = NS::TransferPtr(buildPipeline("vertexShadowShader", "fragmentShadowShader"));
    buildDepthStencilState();
};

MTL::RenderPipelineState* ShadowPass::buildPipeline(const char* vertName, const char* fragName) {
    NS::Error* error = nullptr;
//    MTL::Library* library = m_device->newDefaultLibrary();
    NS::String* filePath = NS::String::string("/Users/louisgrunberg/Documents/SimulationEngine/build/ShaderBase.metallib", NS::UTF8StringEncoding);
    MTL::Library* library = m_device->newLibrary(filePath, &error);

    std::cout << "Lib";
    
    if(!library) {
        std::cout << error->localizedDescription()->utf8String() << std::endl;
    }
    
    // Create Vertex Function
    NS::String* vertexName = NS::String::string(vertName, NS::StringEncoding::UTF8StringEncoding);
    MTL::Function* vertexMain = library->newFunction(vertexName);
    if(!vertexMain) {
        std::cout << "Vertex Function failed" << std::endl;
    }
    
    // Create Fragment Function
    NS::String* fragmentName = NS::String::string(fragName, NS::StringEncoding::UTF8StringEncoding);
    MTL::Function* fragmentMain = library->newFunction(fragmentName);
    
    MTL::RenderPipelineDescriptor* pipelineDescriptor = MTL::RenderPipelineDescriptor::alloc()->init();
    pipelineDescriptor->setVertexFunction(vertexMain);
    pipelineDescriptor->setFragmentFunction(fragmentMain);
    pipelineDescriptor->colorAttachments()->object(0)->setPixelFormat(MTL::PixelFormat::PixelFormatInvalid);
    //    pipelineDescriptor->colorAttachments()->object(0)->setBlendingEnabled(true);
    //    pipelineDescriptor->colorAttachments()->object(0)->setRgbBlendOperation(MTL::BlendOperationAdd);
    //    pipelineDescriptor->colorAttachments()->object(0)->setAlphaBlendOperation(MTL::BlendOperationAdd);
    
    MTL::VertexDescriptor* vertexDescriptor = MTL::VertexDescriptor::alloc()->init();
    auto attributes = vertexDescriptor->attributes();
    // attributes: 0 => position
    auto positionDescriptor = attributes->object(0);
    positionDescriptor->setFormat(MTL::VertexFormat::VertexFormatFloat3);
    positionDescriptor->setOffset(0);
    positionDescriptor->setBufferIndex(0);

    auto normalDescriptor = attributes->object(1);
    normalDescriptor->setFormat(MTL::VertexFormat::VertexFormatFloat3);
    normalDescriptor->setOffset(sizeof(simd::float3));
    normalDescriptor->setBufferIndex(0);
   
    auto layoutDescriptor = vertexDescriptor->layouts()->object(0);
    layoutDescriptor->setStepFunction(MTL::VertexStepFunctionPerVertex);
    layoutDescriptor->setStride(sizeof(Vertex3));
    
    pipelineDescriptor->setDepthAttachmentPixelFormat(MTL::PixelFormat::PixelFormatDepth32Float);  
    pipelineDescriptor->setVertexDescriptor(vertexDescriptor);
    
    MTL::RenderPipelineState* pipeline = m_device->newRenderPipelineState(pipelineDescriptor, &error);
    if(!pipeline) std::cout << error->localizedDescription()->utf8String() << std::endl;
    
    vertexMain->release();
    fragmentMain->release();
    pipelineDescriptor->release();
    library->release();
    
    return pipeline;
}

void ShadowPass::encode(MTL::CommandBuffer *commandBuffer, MTL::Texture *texture, std::vector<std::shared_ptr<Mesh>> meshList) {
    MTL::RenderPassDescriptor* pass = MTL::RenderPassDescriptor::renderPassDescriptor();
    
    MTL::RenderPassDepthAttachmentDescriptor* depthAttachment = pass->depthAttachment();
    depthAttachment->setTexture(m_shadowMap.get());
    depthAttachment->setLoadAction(MTL::LoadActionClear);
    depthAttachment->setStoreAction(MTL::StoreActionStore);
    depthAttachment->setClearDepth(1.0f);
    
    auto encoder = commandBuffer->renderCommandEncoder(pass);
    
    encoder->setRenderPipelineState(m_shadowPipelineState.get());
    encoder->setDepthStencilState(m_depthStencilState.get());
    
    // trick for preventing self-shadowing
    encoder->setCullMode(MTL::CullModeFront);
    encoder->setFrontFacingWinding(MTL::WindingCounterClockwise);

    // set light uniforms
    encoder->setVertexBytes(&m_lightUniforms, sizeof(LightUniforms), NS::UInteger(1));
    
    // Render Ground Plane
    encoder->setVertexBuffer(Quad.vertexBuffer.get(), NS::UInteger(0), NS::UInteger(0));
    simd::float4x4 I = matrix4x4_identity();
    encoder->setVertexBytes(&I, sizeof(simd::float4x4), NS::UInteger(2));
    encoder->drawIndexedPrimitives(MTL::PrimitiveTypeTriangle, NS::UInteger(6), 
                 MTL::IndexTypeUInt16, Quad.indexBuffer.get(), NS::UInteger(0), NS::UInteger(1));

    // activate dynamic positions
    useDynamicPositions = true;
    encoder->setVertexBytes(&useDynamicPositions, sizeof(bool), NS::UInteger(4));

    size_t i = 0;
    // loop over meshes
    for(auto m : meshList) {
      encoder->setFragmentBytes(&m->color, sizeof(simd::half3), NS::UInteger(2));
      encoder->setVertexBuffer(m->getVertexBuffer(), m->getVertexBufferOffset(), NS::UInteger(0));
      encoder->setVertexBytes(&m->modelMatrix, sizeof(simd::float4x4), NS::UInteger(2));
      encoder->setVertexBuffer(m_dynamicPositions.at(i).get(), NS::UInteger(0), NS::UInteger(3));
      encoder->setVertexBuffer(m_remapTables.at(i).get(), NS::UInteger(0), NS::UInteger(5));
     
      encoder->drawIndexedPrimitives(MTL::PrimitiveTypeTriangle, m->getIndexCount(), m->getIndexType(), m->getIndexBuffer(), 
                                     m->getIndexBufferOffset(), NS::UInteger(1));   
      i++;
    }

    encoder->endEncoding();
}

void ShadowPass::buildDepthStencilState() {
    MTL::DepthStencilDescriptor* depthStencilDescriptor = MTL::DepthStencilDescriptor::alloc()->init();
    depthStencilDescriptor->setDepthCompareFunction(MTL::CompareFunctionLess);
    depthStencilDescriptor->setDepthWriteEnabled(true);
    
    m_depthStencilState = NS::TransferPtr(m_device->newDepthStencilState(depthStencilDescriptor));
    depthStencilDescriptor->release();
}
