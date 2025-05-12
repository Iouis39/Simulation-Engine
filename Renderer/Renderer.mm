#include "Renderer.h"
#include "Foundation/NSSharedPtr.hpp"
#include "Foundation/NSString.hpp"
#include "Metal/MTLCaptureManager.hpp"
#include "Metal/MTLResource.hpp"
#import <Metal/Metal.h>
#include <cstring>

Renderer::Renderer(NS::SharedPtr<CA::MetalLayer> layer, NS::SharedPtr<MTL::Device> device, 
                   NS::SharedPtr<MTL::CommandQueue> commandQueue, Uniforms& uniforms,
                   MTL::CaptureManager* captureManager, std::vector<std::shared_ptr<Mesh>> meshList, 
                   SimulationSettings* simulationSettings, Simulation* simulation)
: layer(layer), device(device), commandQueue(commandQueue), m_cameraUniforms(uniforms), 
  m_captureManager(captureManager), m_meshList(meshList), m_simulationSettings(simulationSettings),
  m_simulation(simulation) {

    buildShadowMap();
    buildPositionsBuffer();

    m_renderPasses.push_back(std::make_unique<ShadowPass>(device, m_lightUniforms, m_shadowMap, m_modelTransform));
    m_renderPasses.push_back(std::make_unique<MainPass>(device, m_cameraUniforms, m_lightUniforms, m_shadowMap,
                                                        m_shadowSampler, m_modelTransform, m_dynamicPositions, 
                                                        m_remapTables, m_simulationSettings));
}


void Renderer::buildPositionsBuffer() {
    m_remapTables.resize(m_simulation->getPointMassCount());
    // reserve MTL::Buffer, each vertex has one {x, y, z} position...
    m_dynamicPositions.resize(m_meshList.size());

    for(size_t i = 0; i < m_meshList.size(); i++) {
      const size_t remapTableDataSize = m_simulation->getRemapTable(i).size() * sizeof(int);
      m_remapTables.at(i) = NS::TransferPtr(device->newBuffer(remapTableDataSize, MTL::ResourceStorageModeShared));
      m_remapTables.at(i)->setLabel(NS::String::string("Table Buffer ", NS::UTF8StringEncoding));

      const size_t positionDataSize = m_meshList.at(i)->modelIOMesh.vertexCount * sizeof(simd::float3);
      m_dynamicPositions.at(i) = NS::TransferPtr(device->newBuffer(positionDataSize, MTL::ResourceStorageModeShared));
      m_dynamicPositions.at(i)->setLabel(NS::String::string("Positions Buffer ", NS::UTF8StringEncoding));
    }
}

void Renderer::updatePositionsBuffer() {
  for(size_t i = 0; i < m_meshList.size(); i++) {

    auto remapTable = m_simulation->getRemapTable(i);
    memcpy(m_remapTables.at(i)->contents(), remapTable.data(),  remapTable.size() * sizeof(int));

    auto updatedPositions = m_simulation->getPositionList(i);
    memcpy(m_dynamicPositions.at(i)->contents(), updatedPositions.data(),  updatedPositions.size() * sizeof(simd::float3));
  }
}

NS::SharedPtr<MTL::CommandQueue> Renderer::getCommandQueue() {
    return commandQueue;
}

void Renderer::setModelTransform(simd::float4x4 modelTransform) {
  m_modelTransform = modelTransform;
}

//---------------DRAW FUNCITON-----------------//
void Renderer::draw() {
    auto drawable = layer->nextDrawable();
    if(!drawable) return;

    NS::AutoreleasePool* pPool = NS::AutoreleasePool::alloc()->init();
    MTL::CommandBuffer* commandBuffer = commandQueue->commandBuffer();

    m_captureManager->startCapture(commandQueue.get());

    // LOOP OVER RENDER PASSES
    for(auto& pass : m_renderPasses) {
        pass->encode(commandBuffer, drawable->texture(), m_meshList);
    }

    commandBuffer->presentDrawable(drawable);
    commandBuffer->commit();

    m_captureManager->stopCapture();

    pPool->release();
}

void Renderer::buildShadowMap() {
    // pos, dir and up of light
    simd::float3 pos = simd::make_float3(1.0, 3.0, 2.0);
    simd::float3 dir = simd::make_float3(0.0, 0.0, 0.0);
    simd::float3 up = simd::make_float3(0.0, 1.0, 0.0);
    
    // calculate orthographic and lookat from light's perspective
    simd::float4x4 lookAt = matrix_look_at_right_hand(pos, dir, up);
    simd::float4x4 orthoProjection = matrix_ortho_right_hand(-7.f, 7.f, -7.f, 7.f, -7.f, 7.f);

    m_lightUniforms.viewProjection = orthoProjection * lookAt;
    m_lightUniforms.pos = pos;
    
    auto shadowMapDescriptor = MTL::TextureDescriptor::alloc()->init();
    shadowMapDescriptor->setUsage(MTL::TextureUsageRenderTarget | MTL::TextureUsageShaderRead);
    // shadow map resolution
    shadowMapDescriptor->setWidth(2048);
    shadowMapDescriptor->setHeight(2048);
    shadowMapDescriptor->setStorageMode(MTL::StorageModePrivate);
    shadowMapDescriptor->setPixelFormat(MTL::PixelFormatDepth32Float);
    m_shadowMap = NS::TransferPtr(device->newTexture(shadowMapDescriptor));
    
    
    auto shadowSamplerDescriptor = MTL::SamplerDescriptor::alloc()->init();
    shadowSamplerDescriptor->setMinFilter(MTL::SamplerMinMagFilterLinear);
    shadowSamplerDescriptor->setMagFilter(MTL::SamplerMinMagFilterLinear);
    shadowSamplerDescriptor->setCompareFunction(MTL::CompareFunctionLess);
    
    shadowSamplerDescriptor->setSAddressMode(MTL::SamplerAddressModeClampToEdge);
    shadowSamplerDescriptor->setTAddressMode(MTL::SamplerAddressModeClampToEdge);
    shadowSamplerDescriptor->setRAddressMode(MTL::SamplerAddressModeClampToEdge);
    shadowSamplerDescriptor->setBorderColor(MTL::SamplerBorderColorOpaqueWhite);
    
    m_shadowSampler = NS::TransferPtr(device->newSamplerState(shadowSamplerDescriptor));
    
    shadowMapDescriptor->release();
    shadowSamplerDescriptor->release();
}

Renderer::~Renderer() {}
