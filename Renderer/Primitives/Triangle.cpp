#include "Triangle.h"

Triangle buildTriangle(MTL::Device* device) {
    Triangle Triangle;
    
    Vertex2 vertices[] {
        {{ -0.8, -0.8 },   { 0.5f, 0.1f, 0.9f }},
        {{  0.8, -0.8 },   { 0.6f, 0.4f, 0.4f }},
        {{  0.0,  0.8 },   { 0.9f, 0.3f ,0.3f }}
    };
    
    ushort indices[] {
        0, 1, 2
    };
    
    const size_t vertexDataSize = sizeof(vertices);
    const size_t indexDataSize = sizeof(indices);
    
    Triangle.vertexBuffer = NS::TransferPtr(device->newBuffer(vertexDataSize, MTL::ResourceStorageModeShared));
    Triangle.vertexBuffer->setLabel(NS::String::string("Vertex Buffer", NS::UTF8StringEncoding));
    memcpy(Triangle.vertexBuffer->contents(), vertices, vertexDataSize);
    
    Triangle.indexBuffer = NS::TransferPtr(device->newBuffer(indexDataSize, MTL::ResourceStorageModeShared));
    Triangle.indexBuffer->setLabel(NS::String::string("Index Buffer", NS::UTF8StringEncoding));
    memcpy(Triangle.indexBuffer->contents(), indices, indexDataSize);
    
    return Triangle;
}
