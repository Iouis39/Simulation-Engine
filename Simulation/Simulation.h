#pragma once
#include "PointMass.h"
#include "SimulationObject.h"
#include "../Utility/MathUtilities.h"
#include <vector>

struct SimulationSettings {
  float dt = 1.0f / 60.f;
  simd::float3 gravity = { 0.0f, -9.81f, 0.0f };
  bool gravityEnabled = true;
  bool paused = true;

  int pointMassCount = 0;
};

class Simulation {
 public:
  explicit Simulation(std::vector<std::shared_ptr<Mesh>> meshList, SimulationSettings* simulationSettings);

  void setup();
  void update();

  std::vector<simd::float3> getPositionList(size_t index) const;
  std::vector<int> getRemapTable(size_t index) const;
  size_t getPointMassCount() const;

 private:
  std::vector<SimulationObject> m_simulationObjects;
  std::vector<std::shared_ptr<Mesh>> m_meshList;

  SimulationSettings* m_simulationSettings;
};
