#pragma once
#include "MetalConfig.h"
#include "MathUtilities.h"
#include <simd/simd.h>
#include <algorithm>

struct CameraUniforms {
    simd::float4x4 view;
    simd::float4x4 projection;
    simd::float4x4 viewProjection;

    /*simd::float4x4 invProjection;
    simd::float4x4 invView;
    simd::float4x4 invViewProjection;*/
};

class Camera {
public:
    Camera(simd::float3 position, simd::float3 direction, simd::float3 up, float fov,
           float aspectRatio, float nearPlane, float farPlane);
    
    void update(float deltaTime);
    
    CameraUniforms& uniforms();
    void setProjection(float fov, float aspect, float zNear, float zFar);
    void setVelocity(simd::float3 velocity);
    void adjustOrientation(float deltaX, float deltaY);
    void adjustFOV(float dy);
    
    simd::float3 getDirection();
    simd::float3 getRight();
    simd::float3 getUp();
private:
    void updateBasisVectors();
    void updateUniforms();
    
    CameraUniforms m_uniforms {};
    simd::float3 m_position;
    
    //------ORTHONORMAL BASIS-------------//
    simd::float3 m_direction;
    simd::float3 m_up;
    simd::float3 m_right;
    
    //------LOOK-AT-MATRIX PARAMS---------//
    float m_fov;
    float m_aspectRatio;
    float m_nearPlane;
    float m_farPlane;
    
    //-------MOVEMENT AND ORIENTATION-----//
    float m_speed = 1.5f;
    simd::float3 m_velocity;
    float m_yaw = 90.0f;//HORIZONTAL ROTATION
    float m_pitch = 0.0f;//VERTICAL ROTATION
    const float m_sensitivity = 0.09f;
};
