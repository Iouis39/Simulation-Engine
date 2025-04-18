#include <metal_stdlib>
using namespace metal;

struct VertexInput {
    float3 position [[attribute(0)]];
    float3 color    [[attribute(1)]];
};

struct VertexOutput {
    float4 position [[position]];
    half3 color;
    float2 localSpace;
};

struct Uniforms {
    float4x4 view;
    float4x4 projection;
    float4x4 viewProjection;
    /*simd::float4x4 invProjection;
    simd::float4x4 invView;
    simd::float4x4 invViewProjection;*/
};

VertexOutput vertex vertexShader(VertexInput input    [[stage_in]],
                        constant Uniforms &uniforms   [[buffer(1)]],
                                 uint instanceID      [[instance_id]]) {
    VertexOutput output;
    output.position = uniforms.viewProjection * float4(input.position, 1.0f);
    output.color = half3(input.color);
    
    
    return output;
}

half4 fragment fragmentShader(VertexOutput frag [[stage_in]]) {
    return half4(frag.color, 1.0);
}
