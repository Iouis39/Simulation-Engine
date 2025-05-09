#include "Camera.h"

Camera::Camera(simd::float3 position, simd::float3 direction, simd::float3 up, 
               float fov, float aspectRatio, float nearPlane, float farPlane) :
m_position(position),
m_direction(direction),
m_up(up),
m_fov(fov),
m_aspectRatio(aspectRatio),
m_nearPlane(nearPlane),
m_farPlane(farPlane) {
    updateBasisVectors();
    updateUniforms();
}

Uniforms& Camera::uniforms() {
    return m_uniforms;
}

void Camera::update(float deltaTime) {
    m_position += m_velocity * deltaTime * m_speed;
    updateUniforms();
}

void Camera::setVelocity(simd::float3 velocity) {
    m_velocity = velocity;
}

void Camera::setProjection(float fov, float aspect, float zNear, float zFar) {
    m_fov = fov;
    m_aspectRatio = aspect;
    m_nearPlane = zNear;
    m_farPlane = zFar;
    updateUniforms();
}

void Camera::adjustOrientation(float deltaX, float deltaY) {
    m_yaw   += deltaX * m_sensitivity;
    m_pitch += deltaY * m_sensitivity;
    
    //VERTICAL ROTATION BETWEEN -PI/2 AND PI/2
    if (m_pitch > 89.0f) {
        m_pitch = 89.0f;
    }
    if (m_pitch < -89.0f) {
        m_pitch = -89.0f;
    }
    
    //CONVERT SPHERICAL COORDINATES (1, yaw, pitch) --> (x, y, z)
    m_direction = simd::normalize(simd::make_float3(
                                    cosf(radians_from_degrees(m_pitch)) * cosf(radians_from_degrees(m_yaw)),
                                    sinf(radians_from_degrees(m_pitch)),
                                    cosf(radians_from_degrees(m_pitch)) * sinf(radians_from_degrees(m_yaw))));
    
    updateBasisVectors();
}

void Camera::adjustFOV(float dy) {
    m_fov += dy * m_sensitivity;
    //FOV RANGES FROM [15dgr, 90dgr]
    m_fov = simd::clamp(m_fov, 15.0f * static_cast<float>(M_PI) / 180.f,
                                90.0f * static_cast<float>(M_PI) / 180.f);
}

simd::float3 Camera::getDirection() { return m_direction; }
simd::float3 Camera::getRight() { return m_right; }
simd::float3 Camera::getUp() { return m_up; }

void Camera::updateBasisVectors() {
    const simd::float3 worldUp = simd::make_float3(0.0f, 1.0f, 0.0f);
    m_right = simd::normalize(simd::cross(m_direction, worldUp));
    m_up = simd::normalize(simd::cross(m_right, m_direction));
}

void Camera::updateUniforms() {
    //position and direction have to be added! do not forget...
    m_uniforms.view = matrix_look_at_right_hand(m_position, m_position + m_direction, m_up);
    m_uniforms.projection = matrix_perspective_right_hand(m_fov, m_aspectRatio, m_nearPlane, m_farPlane);
    m_uniforms.viewProjection = m_uniforms.projection * m_uniforms.view;
}
