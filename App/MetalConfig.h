#pragma once
#include <Foundation/Foundation.hpp>
#include <Metal/Metal.hpp>
#include <QuartzCore/QuartzCore.hpp>
#include <simd/simd.h>

#include <iostream>
#include <SDL.h>

// Window Size
// have to be defined as float... otherwise aspect would be rounded to 1
const float WINDOW_WIDTH = 800;
const float WINDOW_HEIGHT = 600;

// Metal Types
struct Vertex2 {
    simd::float2 pos;
    simd::float3 color;
};

struct Vertex3 {
    simd::float3 pos;
    simd::float3 color;
};
