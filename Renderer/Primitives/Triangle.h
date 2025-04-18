#pragma once
#include "MetalConfig.h"

struct Triangle{
    NS::SharedPtr<MTL::Buffer> vertexBuffer, indexBuffer;
};

Triangle buildTriangle(MTL::Device* pDevice);
