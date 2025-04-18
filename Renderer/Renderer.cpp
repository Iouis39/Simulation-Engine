#include "Renderer.h"

Renderer::Renderer(NS::SharedPtr<CA::MetalLayer> l, CameraUniforms& uniforms)
                  : layer(l), cameraUniforms(uniforms) {
    
    device = NS::TransferPtr(MTL::CreateSystemDefaultDevice());
    commandQueue = NS::TransferPtr(device->newCommandQueue());
    layer->setDevice(device.get());
    layer->setPixelFormat(MTL::PixelFormatBGRA8Unorm);
        
    Triangle = buildTriangle(device.get());
    Cube = buildCube(device.get());
    renderPipelineState = NS::TransferPtr(buildShader("vertexShader", "fragmentShader"));
    buildDepthStencilStates();
}

Renderer::~Renderer() {
    
//    Triangle.vertexBuffer->release();
//    Triangle.indexBuffer->release();
}

MTL::RenderPipelineState* Renderer::buildShader(const char *vertName, const char *fragName) {
    NS::Error* error = nullptr;
    MTL::Library* library = device->newDefaultLibrary();
    
    if(!library) {
        std::cout << error->localizedDescription()->utf8String() << std::endl;
    }
    
    // Create Vertex Function
    NS::String* vertexName = NS::String::string(vertName, NS::StringEncoding::UTF8StringEncoding);
    MTL::Function* vertexMain = library->newFunction(vertexName);
    
    // Create Fragment Function
    NS::String* fragmentName = NS::String::string(fragName, NS::StringEncoding::UTF8StringEncoding);
    MTL::Function* fragmentMain = library->newFunction(fragmentName);
    
    MTL::RenderPipelineDescriptor* pipelineDescriptor = MTL::RenderPipelineDescriptor::alloc()->init();
    pipelineDescriptor->setVertexFunction(vertexMain);
    pipelineDescriptor->setFragmentFunction(fragmentMain);
    pipelineDescriptor->colorAttachments()->object(0)->setPixelFormat(MTL::PixelFormat::PixelFormatBGRA8Unorm);
    pipelineDescriptor->colorAttachments()->object(0)->setBlendingEnabled(true);
    pipelineDescriptor->colorAttachments()->object(0)->setRgbBlendOperation(MTL::BlendOperationAdd);
    pipelineDescriptor->colorAttachments()->object(0)->setAlphaBlendOperation(MTL::BlendOperationAdd);
    
    MTL::VertexDescriptor* vertexDescriptor = MTL::VertexDescriptor::alloc()->init();
    auto attributes = vertexDescriptor->attributes();
    // attributes: 0 => position
    auto positionDescriptor = attributes->object(0);
    positionDescriptor->setFormat(MTL::VertexFormat::VertexFormatFloat3);
    positionDescriptor->setOffset(0);
    positionDescriptor->setBufferIndex(0);
    
    // attributes: 1 => color
    auto colorDescriptor = attributes->object(1);
    colorDescriptor->setFormat(MTL::VertexFormat::VertexFormatFloat3);
    colorDescriptor->setOffset(4 * sizeof(float));
    colorDescriptor->setBufferIndex(0);
    
    auto layoutDescriptor = vertexDescriptor->layouts()->object(0);
    layoutDescriptor->setStride(8 * sizeof(float));
    
    pipelineDescriptor->setDepthAttachmentPixelFormat(MTL::PixelFormat::PixelFormatDepth32Float_Stencil8);//PixelFormatDepth16Unorm
    pipelineDescriptor->setStencilAttachmentPixelFormat(MTL::PixelFormat::PixelFormatDepth32Float_Stencil8);//
    pipelineDescriptor->setVertexDescriptor(vertexDescriptor);
    
    MTL::RenderPipelineState* pipeline  = device->newRenderPipelineState(pipelineDescriptor, &error);
    if(!pipeline) std::cout << error->localizedDescription()->utf8String() << std::endl;
    
    vertexMain->release();
    fragmentMain->release();
    pipelineDescriptor->release();
    library->release();
    
    return pipeline;
}

void Renderer::buildDepthStencilStates() {
    MTL::DepthStencilDescriptor* depthStencilDescriptor = MTL::DepthStencilDescriptor::alloc()->init();
    depthStencilDescriptor->setDepthWriteEnabled(MTL::CompareFunctionLess);
    depthStencilDescriptor->setDepthWriteEnabled(true);
    
    depthStencilState = NS::TransferPtr(device->newDepthStencilState(depthStencilDescriptor));
    depthStencilDescriptor->release();
}


//---------------DRAW FUNCITON-----------------//
void Renderer::draw() {
    auto drawable = layer->nextDrawable();
    if(!drawable) return;
    
    NS::AutoreleasePool* pPool = NS::AutoreleasePool::alloc()->init();
    
    MTL::RenderPassDescriptor* pass = MTL::RenderPassDescriptor::renderPassDescriptor();
    pass->colorAttachments()->object(0)->setTexture(drawable->texture());
    pass->colorAttachments()->object(0)->setClearColor(MTL::ClearColor::Make(0.2, 0.76, 1.0, 1.0));
    pass->colorAttachments()->object(0)->setLoadAction(MTL::LoadActionClear);
    pass->colorAttachments()->object(0)->setStoreAction(MTL::StoreActionStore);
    
    MTL::RenderPassDepthAttachmentDescriptor* depthAttachment = pass->depthAttachment();
    depthAttachment->setClearDepth(1.0f);
    
    auto commandBuffer = commandQueue->commandBuffer();
    auto encoder = commandBuffer->renderCommandEncoder(pass);
    
    encoder->setRenderPipelineState(renderPipelineState.get());
    encoder->setDepthStencilState(depthStencilState.get());
    
    encoder->setCullMode(MTL::CullModeBack);
    encoder->setFrontFacingWinding(MTL::WindingCounterClockwise);
    
    encoder->setVertexBuffer(Cube.vertexBuffer.get(), NS::UInteger(0), NS::UInteger(0));
    encoder->setVertexBytes(&cameraUniforms, sizeof(CameraUniforms), NS::UInteger(1));
//    encoder->setVertexBytes(&viewProj, sizeof(simd_float4x4), NS::UInteger(0), NS::UInteger(1));
    encoder->drawIndexedPrimitives(MTL::PrimitiveTypeTriangle, NS::UInteger(36), MTL::IndexTypeUInt16, Cube.indexBuffer.get(), NS::UInteger(0), NS::UInteger(1));
    
    encoder->endEncoding();
    commandBuffer->presentDrawable(drawable);
    commandBuffer->commit();
    
    
    pPool->release();
}

 
