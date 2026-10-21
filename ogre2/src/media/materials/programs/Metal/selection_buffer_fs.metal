/*
 * Copyright (C) 2018 Open Source Robotics Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */
 
#include <metal_stdlib>
using namespace metal;

struct PS_INPUT
{
  float2 uv0;
  float3 cameraDir;
};

struct Params
{
  float2  projectionParams;
  float   far;
  float   inf;
  float4  colorTexResolution;
};

float packFloat(float4 color)
{
  // Use uint for bit operations to avoid potential sign extension issues
  uint r = uint(clamp(color.x, 0.0f, 1.0f) * 255.0 + 0.5);
  uint g = uint(clamp(color.y, 0.0f, 1.0f) * 255.0 + 0.5);
  uint b = uint(clamp(color.z, 0.0f, 1.0f) * 255.0 + 0.5);
  uint a = uint(clamp(color.w, 0.0f, 1.0f) * 255.0 + 0.5);

  uint rgba = (r << 24) | (g << 16) | (b << 8) | a;
  return as_type<float>(rgba);
}

fragment float4 main_metal
(
  PS_INPUT inPs [[stage_in]],
  texture2d<float> colorTexture [[texture(0)]],
  texture2d<float> depthTexture [[texture(1)]],
  sampler          colorSampler	[[sampler(0)]],
  sampler          depthSampler	[[sampler(1)]],
  constant Params &p [[buffer(PARAMETER_SLOT)]]
)
{
  // get linear depth
  float fDepth = depthTexture.sample(depthSampler, inPs.uv0).x;

  float d = p.projectionParams.y / (fDepth - p.projectionParams.x);

  // reconstruct 3d viewspace pos from depth
  float3 viewSpacePos = inPs.cameraDir * d;

  // convert to z up
  float3 point = float3(-viewSpacePos.z, -viewSpacePos.x, viewSpacePos.y);

  // set to inf if point is at far clip plane
  if (point.x > p.far - 1e-4)
    point = float3(p.inf);

  // color
  // Either: Metal equivalent of texelFetch
  float4 color = colorTexture.read(
      uint2(inPs.uv0 * p.colorTexResolution.xy), 0);
  // Or: Use standard sampler
  // float4 color = colorTexture.sample(colorSampler, inPs.uv0);

  float rgba = packFloat(color);

  return float4(point.xyz, rgba);
}
