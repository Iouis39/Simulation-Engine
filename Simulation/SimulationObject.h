#pragma once
#include "PointMass.h"
#include "../Utility/Mesh.h"
#include <vector>

const simd::float3 gravity = simd::make_float3(0.0f, -1.8f, 0.0f);

struct SimulationObject {
  std::vector<PointMass> pointMasses;
  std::vector<simd::float3> positionList;

  void update(float dt) {
    for(auto& p : pointMasses) {
      p.integrate(dt, gravity);
      p.resolveGroundCollision();
      positionList.push_back(p.m_position);
    }
  }

  void generatePointMasses(std::shared_ptr<Mesh> m) {
    // find beginning of vertex buffer... offset is added too...
    auto vertexPointer = reinterpret_cast<float*>(reinterpret_cast<uint8_t*>(m->getVertexBuffer()->contents())
                                                                          + m->getVertexBufferOffset());
  
    size_t vertexCount = m->modelIOMesh.vertexCount;
    auto vertexDescriptor = (__bridge MTL::VertexDescriptor*)m->modelIOMesh.vertexDescriptor;
    int positionOffset = static_cast<int>(vertexDescriptor->attributes()->object(0)->offset());
    std::cout << positionOffset << std::endl;
    
    size_t stride = vertexDescriptor->layouts()->object(0)->stride();

    for(size_t i = 0; i < vertexCount; i++) {
      float* positionPtr = reinterpret_cast<float*>(
            reinterpret_cast<uint8_t*>(vertexPointer) + i * stride + positionOffset
        );


      simd::float3 posObj = simd::make_float3(positionPtr[0], positionPtr[1], positionPtr[2]);
      pointMasses.emplace_back(simd::make_float3(positionPtr[0], positionPtr[1], positionPtr[2]), 
                                                        simd::float3(0.f), 1.0f);
    }
  }

  std::vector<simd::float3> getPositionList() const {
    std::vector<simd::float3> positions;
    positions.reserve(pointMasses.size());
    for(const auto& pm : pointMasses) {
      positions.push_back(pm.m_position);
    }
    return positions;
  }

  void clearPositionList() {
    positionList.clear();
  }

  simd::float3 calculateCenter() const { 
    simd::float3 positionSum(0.0f);
    for(const auto& p : pointMasses) {
      positionSum += p.m_position;
    }
    return positionSum / pointMasses.size();
  }
};
