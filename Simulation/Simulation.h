#pragma once
#include "PointMass.h"
#include "SimulationObject.h"
#include "../Utility/MathUtilities.h"
#include <vector>

class Simulation {
 public:
  explicit Simulation(std::vector<std::shared_ptr<Mesh>> meshList);

  void setup();
  void update(float dt);

  std::vector<simd::float3> getPositionList(size_t index) const;

 private:
  std::vector<SimulationObject> m_simulationObjects;
  std::vector<std::shared_ptr<Mesh>> m_meshList;
};
