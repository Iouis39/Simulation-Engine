#pragma once
#include "../App/MetalConfig.h"
#include "Camera.h"
#include "../Utility/Primitives.h"
#include "../Utility/Mesh.h"
#include "../Simulation/Simulation.h"
#include <vector>

class RenderPass {
public:
  virtual ~RenderPass() = default;
  virtual void encode(MTL::CommandBuffer* commandBuffer, MTL::Texture* texture, std::vector<std::shared_ptr<Mesh>> meshList) = 0;

  virtual MTL::RenderPipelineState* buildPipeline(const char* vertName, const char* fragName) = 0;
  virtual void buildDepthStencilState() = 0;
};

class MainPass : public RenderPass {
public:
  MainPass(NS::SharedPtr<MTL::Device> device, Uniforms& cameraUniforms, LightUniforms& lightUniforms,
           NS::SharedPtr<MTL::Texture> shadowMap,  NS::SharedPtr<MTL::SamplerState> shadowSampler,
           simd::float4x4& modelTransform, std::vector<NS::SharedPtr<MTL::Buffer>> dynamicPositions,
           SimulationSettings* simulationSettings);
  void encode(MTL::CommandBuffer* commandBuffer, MTL::Texture* drawableTexture, std::vector<std::shared_ptr<Mesh>> meshList);

  MTL::RenderPipelineState* buildPipeline(const char* vertName, const char* fragName);
  void buildDepthStencilState();
  void buildImGui();

private:
  NS::SharedPtr<MTL::Device> m_device;
  NS::SharedPtr<MTL::RenderPipelineState> m_renderPipelineState;
  NS::SharedPtr<MTL::DepthStencilState> m_depthStencilState;
  MTL::RenderPassDescriptor* m_pass;

  Uniforms& m_cameraUniforms;
  LightUniforms& m_lightUniforms;
  simd::float4x4& m_modelTransform;
  std::vector<NS::SharedPtr<MTL::Buffer>> m_dynamicPositions;
  simd::float4 m_color;

  MTL::Texture* m_depthTexture;

  NS::SharedPtr<MTL::Texture> m_shadowMap;
  NS::SharedPtr<MTL::SamplerState> m_shadowSampler;

  Quad Quad;
  Cube Cube;

  bool useWriteFrameMode = false;
  SimulationSettings* m_simulationSettings;
};

class ShadowPass : public RenderPass {
public:
  ShadowPass(NS::SharedPtr<MTL::Device> device, LightUniforms &lightUniforms,
             NS::SharedPtr<MTL::Texture> shadowMap, simd::float4x4& modelTransform);
  void encode(MTL::CommandBuffer* commandBuffer, MTL::Texture* drawableTexture, std::vector<std::shared_ptr<Mesh>> meshList);

  MTL::RenderPipelineState* buildPipeline(const char* vertName, const char* fragName);
  void buildDepthStencilState();

private:
  NS::SharedPtr<MTL::Device> m_device;
  NS::SharedPtr<MTL::RenderPipelineState> m_shadowPipelineState;
  NS::SharedPtr<MTL::DepthStencilState> m_depthStencilState;

  LightUniforms& m_lightUniforms;
  simd::float4x4& m_modelTransform;
  NS::SharedPtr<MTL::Texture> m_shadowMap;

  Quad Quad;
  Cube Cube;
};
