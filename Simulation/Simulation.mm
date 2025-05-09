#include "Simulation.h"

Simulation::Simulation(std::vector<std::shared_ptr<Mesh>> meshList, SimulationSettings* simulationSettings) 
: m_meshList(meshList), m_simulationSettings(simulationSettings)  {}


void Simulation::setup() {
    for(size_t i = 0; i < m_meshList.size(); i++) {
      SimulationObject obj;
      obj.generatePointMasses(m_meshList.at(i));
      m_simulationObjects.push_back(std::move(obj));
  }
}

void Simulation::update(float dt) {
  for(auto& obj : m_simulationObjects) {
    obj.update(dt);
  }
}

std::vector<simd::float3> Simulation::getPositionList(size_t index) const {
  std::vector<simd::float3> result;
  result = m_simulationObjects.at(index).getPositionList();
  return result;
}
