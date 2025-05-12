#pragma once
#include "PointMass.h"
#include "../Utility/Mesh.h"
#include <vector>

#include <unordered_map>

// Hash function for simd::float3 (use int rounding to avoid floating point precision issues)
struct Float3Hasher {
    std::size_t operator()(const simd::float3& v) const {
        auto hash = [](float x) {
            return std::hash<int>()(static_cast<int>(x * 1000)); // round to 0.001
        };
        return hash(v.x) ^ (hash(v.y) << 1) ^ (hash(v.z) << 2);
    }
};

struct Float3Equal {
    bool operator()(const simd::float3& a, const simd::float3& b) const {
        return simd::all(simd::abs(a - b) < 1e-4f);
    }
};

struct SimulationObject {
  std::vector<PointMass> pointMasses;
  std::vector<simd::float3> positionList;
  size_t vertexCount;
  std::vector<int> remapTable;

  void update(float dt, simd::float3 gravity) {
    for(auto& p : pointMasses) {
      p.integrate(dt, gravity);
      p.resolveGroundCollision();
      positionList.push_back(p.m_position);
    }
  }

  void generatePointMasses(std::shared_ptr<Mesh> m) {
    std::unordered_map<simd::float3, int, Float3Hasher, Float3Equal> uniquePositions;
    // find beginning of vertex buffer... offset is added too...
    auto vertexPointer = reinterpret_cast<float*>(reinterpret_cast<uint8_t*>(m->getVertexBuffer()->contents())
                                                                          + m->getVertexBufferOffset());
  
    vertexCount = m->modelIOMesh.vertexCount;
    auto vertexDescriptor = (__bridge MTL::VertexDescriptor*)m->modelIOMesh.vertexDescriptor;
    int positionOffset = static_cast<int>(vertexDescriptor->attributes()->object(0)->offset());
    
    size_t stride = vertexDescriptor->layouts()->object(0)->stride();

    for(size_t i = 0; i < vertexCount; i++) {
      float* positionPtr = reinterpret_cast<float*>(
            reinterpret_cast<uint8_t*>(vertexPointer) + i * stride + positionOffset
        );


      simd::float3 posObj = simd::make_float3(positionPtr[0], positionPtr[1], positionPtr[2]);


      if(uniquePositions.find(posObj) == uniquePositions.end()) {
          int newIndex = static_cast<int>(pointMasses.size());
          pointMasses.emplace_back(simd::make_float3(positionPtr[0], positionPtr[1], positionPtr[2]), 
                                                        simd::float3(0.f), 1.0f);
          uniquePositions[posObj] = newIndex;
      }

      //pointMasses.emplace_back(simd::make_float3(positionPtr[0], positionPtr[1], positionPtr[2]), 
      //                                                 simd::float3(0.f), 1.0f);
      remapTable.push_back(uniquePositions[posObj]);
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

  std::vector<int> getRemapTable() const {
    return remapTable;
  }

  size_t getPointMassCount() const {
    return pointMasses.size();
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
