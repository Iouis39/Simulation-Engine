#include <metal_stdlib>
using namespace metal;

struct VertexInput {
    float3 position [[attribute(0)]];
    float3 normal   [[attribute(1)]];
};

struct VertexOutput {
    float4 position [[position]];
    float4 worldPosition;
    float3 normal;
};

struct CameraUniforms {
    float4x4 view;
    float4x4 projection;
    float4x4 viewProjection;
};

struct ModelUniforms {
  float4x4 model;
  float3 color;
};

struct LightUniforms {
  float4x4 viewProjection;
  float3 position;
};

inline half3 lighting(half3 diffuseColor, float visibilty) {
    return diffuseColor * visibilty;
}

VertexOutput vertex vertexShader(VertexInput input                [[stage_in]],
                                 uint vertexID                    [[vertex_id]],
                        constant CameraUniforms &cameraUniforms   [[buffer(1)]],
                        constant float4x4 &modelMatrix            [[buffer(2)]],
                        const device float3* dynamicPositions     [[buffer(3)]],
                        constant bool& useDynamicPositions        [[buffer(4)]],
                                 uint instanceID                  [[instance_id]]) {
    VertexOutput output;
    if(!useDynamicPositions) {
      output.position = cameraUniforms.viewProjection * modelMatrix * float4(input.position, 1.0f);
    } else {
     output.position = cameraUniforms.viewProjection * modelMatrix * float4(dynamicPositions[vertexID], 1.0f); 
    }
    output.worldPosition = modelMatrix * float4(input.position, 1.0);
    output.normal = input.normal;
    
    return output;
}

half4 fragment fragmentShader(VertexOutput frag      [[ stage_in   ]],
                    constant LightUniforms &lightUniforms [[ buffer(1)  ]],
                    constant half3& color [[buffer(2)]],
                    texture2d<float> shadowMap      [[ texture(0) ]],
                     sampler shadowSampler           [[ sampler(0) ]]) {
                     
  float3 l = normalize(float3(1.0, 3.0, 2.0));
  float3 n = normalize(frag.normal);
  float s = clamp(dot(n, l), 0.3, 1.0);

  float4 posLight = lightUniforms.viewProjection * frag.worldPosition;
  float3 lightNDC = posLight.xyz / posLight.w;

  float2 shadowUV = lightNDC.xy * 0.5 + 0.5;
  shadowUV.y = 1.0 - shadowUV.y;

  float bias = max(0.0005 * (1.0 - dot(n, l)), 0.0001);
  float2 texelSize = 1.0 / float2(shadowMap.get_width(), shadowMap.get_height());

  float shadowSamples = 0.0;
  for (int y = -1; y <= 1; y++) {
    for (int x = -1; x <= 1; x++) {
        float2 offset = float2(x, y) * texelSize;
        float closestDepth = shadowMap.sample(shadowSampler, shadowUV + offset).r;
        if (lightNDC.z - bias > closestDepth) {
            shadowSamples += 1.0;
        }
    }
  }

  float visibility = 1.0 - shadowSamples / 20.0; // divide by 20 instead of 9, softer shadows
  if (lightNDC.z > 1.0) visibility = 1.0;

  return half4(lighting(color, visibility) * s, 1.0);
  //return half4(half3(lightNDC.z), 1.0);
  //return half4(color, 1.0);
}
