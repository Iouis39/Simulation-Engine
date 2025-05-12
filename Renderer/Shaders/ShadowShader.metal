#include <metal_stdlib>
using namespace metal;


struct VertexInput {
    float3 position [[attribute(0)]];
    float3 normal   [[attribute(1)]];
};

struct VertexOutput {
    float4 position [[position]];
};

struct Uniforms {
    float4x4 view;
    float4x4 projection;
    float4x4 viewProjection;
};

struct LightUniforms {
  float4x4 viewProjection;
  float3 pos;
};

VertexOutput vertex vertexShadowShader(VertexInput input  [[stage_in]],
                                            uint vertexID [[vertex_id]],
                         constant LightUniforms& uniforms [[buffer(1)]],
                        constant float4x4& modelTransform [[buffer(2)]],
                    const device float3* dynamicPositions [[buffer(3)]],
                       constant bool& useDynamicPositions [[buffer(4)]],
                             const device int* remapTable [[buffer(5)]]) {
    VertexOutput output;
    if(!useDynamicPositions) { 
      output.position = uniforms.viewProjection * modelTransform * float4(input.position, 1.0f);
    } else {
    // model transform already on CPU-Side
      output.position = uniforms.viewProjection * float4(dynamicPositions[remapTable[vertexID]], 1.0f);
    }
    
    return output;
}

void fragment fragmentShadowShader(VertexOutput frag [[stage_in]]) {}
