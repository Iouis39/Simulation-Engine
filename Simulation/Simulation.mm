#include "Simulation.h"

Simulation::Simulation(std::vector<std::shared_ptr<Mesh>> meshList, SimulationSettings* simulationSettings) 
: m_meshList(meshList), m_simulationSettings(simulationSettings)  {

}


void Simulation::setup() {
    for(size_t i = 0; i < m_meshList.size(); i++) {
      SimulationObject obj;
      // convert mesh to point masses
      obj.generatePointMasses(m_meshList.at(i));
      m_simulationObjects.push_back(std::move(obj));
      // count point masses
      m_simulationSettings->pointMassCount = getPointMassCount(); 
  }
}

void Simulation::update() {
  if(m_simulationSettings->paused) return;
  for(auto& obj : m_simulationObjects) {
    simd::float3 g = m_simulationSettings->gravityEnabled ? m_simulationSettings->gravity : simd::float3(0.0f);
    obj.update(m_simulationSettings->dt, g);
  }
}

std::vector<simd::float3> Simulation::getPositionList(size_t index) const {
  std::vector<simd::float3> result;
  result = m_simulationObjects.at(index).getPositionList();
  return result;
}

std::vector<int> Simulation::getRemapTable(size_t index) const {
  return m_simulationObjects.at(index).getRemapTable();
}

size_t Simulation::getPointMassCount() const {
  size_t count = 0;
  for(size_t i = 0; i < m_simulationObjects.size(); i++) {
     count += m_simulationObjects.at(i).getPointMassCount();
  } 

  return count;
}
