#include "Cube.h"

Cube buildCube(MTL::Device* device) {
    Cube Cube;
    const float s = 0.1f;
    
    Vertex3 vertices[] {
        { { -s, -s, +s }, { 0.4f, 0.4f, 0.8f } },
        { { +s, -s, +s }, { 0.4f, 0.4f, 0.8f } },
        { { +s, +s, +s }, { 0.4f, 0.4f, 0.8f } },
        { { -s, +s, +s }, { 0.4f, 0.4f, 0.8f } },
        
        { { +s, -s, +s }, { 0.1f, 0.4f, 0.2f } },
        { { +s, -s, -s }, { 0.1f, 0.4f, 0.2f } },
        { { +s, +s, -s }, { 0.1f, 0.4f, 0.2f } },
        { { +s, +s, +s }, { 0.1f, 0.4f, 0.2f } },
        
        { { +s, -s, -s }, { 0.9f, 0.7f, 0.1f } },
        { { -s, -s, -s }, { 0.9f, 0.7f, 0.1f } },
        { { -s, +s, -s }, { 0.9f, 0.7f, 0.1f } },
        { { +s, +s, -s }, { 0.9f, 0.7f, 0.1f } },
        
        { { -s, -s, -s }, { 0.2f, 0.1f, 0.1f } },
        { { -s, -s, +s }, { 0.2f, 0.1f, 0.1f } },
        { { -s, +s, +s }, { 0.2f, 0.1f, 0.1f } },
        { { -s, +s, -s }, { 0.2f, 0.1f, 0.1f } },
        
        { { -s, +s, +s }, { 0.2f, 0.8f, 0.9f } },
        { { +s, +s, +s }, { 0.2f, 0.8f, 0.9f } },
        { { +s, +s, -s }, { 0.2f, 0.8f, 0.9f } },
        { { -s, +s, -s }, { 0.2f, 0.8f, 0.9f } },
        
        { { -s, -s, -s }, { 0.3f, 0.5f, 0.7f } },
        { { +s, -s, -s }, { 0.3f, 0.5f, 0.7f } },
        { { +s, -s, +s }, { 0.3f, 0.5f, 0.7f } },
        { { -s, -s, +s }, { 0.3f, 0.5f, 0.7f } },
    };
    
    ushort indices[] = {
         0,  1,  2,  2,  3,  0, /* front */
         4,  5,  6,  6,  7,  4, /* right */
         8,  9, 10, 10, 11,  8, /* back */
        12, 13, 14, 14, 15, 12, /* left */
        16, 17, 18, 18, 19, 16, /* top */
        20, 21, 22, 22, 23, 20, /* bottom */
    };
    
    const size_t vertexDataSize = sizeof(vertices);
    const size_t indexDataSize = sizeof(indices);
    
    Cube.vertexBuffer = NS::TransferPtr(device->newBuffer(vertexDataSize, MTL::ResourceStorageModeShared));
    Cube.vertexBuffer->setLabel(NS::String::string("Vertex Buffer", NS::UTF8StringEncoding));
    memcpy(Cube.vertexBuffer->contents(), vertices, vertexDataSize);
    
    Cube.indexBuffer = NS::TransferPtr(device->newBuffer(indexDataSize, MTL::ResourceStorageModeShared));
    Cube.indexBuffer->setLabel(NS::String::string("Index Buffer", NS::UTF8StringEncoding));
    memcpy(Cube.indexBuffer->contents(), indices, indexDataSize);
    
    
    return Cube;
}
