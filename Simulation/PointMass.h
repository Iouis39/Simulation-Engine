#pragma once
#include <simd/simd.h>

struct PointMass {
  simd::float3 m_position;
  simd::float3 m_velocity;
  float m_mass;

  PointMass(simd::float3 position, simd::float3 velocity = {0.0f, 0.0f, 0.0f}, float mass = 1.0f) 
  : m_position(position), m_velocity(velocity), m_mass(mass) {}

  void integrate(float dt, simd::float3 acceleration) {
    // explicit Euler integration
    m_velocity = m_velocity + dt * acceleration;
    m_position = m_position + dt * m_velocity;
  }

  void resolveGroundCollision(float groundHeight = 0.0f) {
    if(m_position.y < groundHeight) {
      m_position.y = groundHeight;
      m_velocity.y = 0.0f;
    }
  }
};
