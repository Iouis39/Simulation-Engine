#pragma once
#include "MetalConfig.h"

struct Cube {
    NS::SharedPtr<MTL::Buffer> vertexBuffer, indexBuffer;
};

Cube buildCube(MTL::Device* device);
