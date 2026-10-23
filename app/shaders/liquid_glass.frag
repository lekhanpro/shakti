#version 460 core
#include <flutter/runtime_effect.glsl>

// ImageFilter.shader requires the first float uniform to be a vec2 and the
// first sampler to be its engine-provided filter input. Dart must not bind them.
uniform vec2 u_size;
uniform float u_radius;
uniform float u_pixel_ratio;
uniform sampler2D u_input;

out vec4 frag_color;

float GaussianWeight(int i) {
  if (i == 0 || i == 4) return 0.06136;
  if (i == 1 || i == 3) return 0.24477;
  return 0.38774;
}

vec2 inputUv(vec2 point) {
  vec2 halfTexel = vec2(0.5) / max(u_size, vec2(1.0));
  vec2 uv = clamp(point / max(u_size, vec2(1.0)), halfTexel, 1.0 - halfTexel);
#ifdef IMPELLER_TARGET_OPENGLES
  // Impeller's GLES filter texture has the opposite vertical orientation.
  uv.y = 1.0 - uv.y;
#endif
  return uv;
}

void main() {
  vec2 point = FlutterFragCoord().xy;
  vec2 halfSize = max(u_size * 0.5, vec2(1.0));
  float radius = clamp(u_radius, 0.0, min(halfSize.x, halfSize.y));
  vec2 centered = point - halfSize;
  vec2 q = abs(centered) - (halfSize - vec2(radius));
  vec2 corner = max(q, vec2(0.0));
  float cornerLength = length(corner);
  float signedDistance = cornerLength + min(max(q.x, q.y), 0.0) - radius;

  // The rounded-rectangle normal is exact on straight sides and circular
  // corners. The center stays unwarped; softening still covers the backdrop.
  vec2 normal = cornerLength > 0.001
      ? corner / max(cornerLength, 0.001)
      : (q.x > q.y ? vec2(1.0, 0.0) : vec2(0.0, 1.0));
  normal *= sign(centered);
  float scale = max(u_pixel_ratio, 0.5);
  float band = max(1.0, min(14.0 * scale, min(halfSize.x, halfSize.y) * 0.45));
  float inset = max(-signedDistance, 0.0);
  float rimPosition = clamp(inset / band, 0.0, 1.0);
  float rim = 16.0 * rimPosition * rimPosition
      * (1.0 - rimPosition) * (1.0 - rimPosition);
  vec2 refracted = point - normal * (2.5 * scale) * rim;

  // A fixed 5x5 Gaussian uses 25 texture samples per output pixel. Three-dp
  // sample spacing gives approximately three-dp sigma and six-dp support.
  // Keep this filter on tightly clipped controls; foreground labels are painted
  // afterward, so only the underlying page is softened. Device profiling is
  // still required: this costs more than the former five-sample filter.
  // Clamp within the same input texture instead of composing an expanded blur,
  // which would shift the coordinate bounds used to place the refraction rim.
  float sampleStep = 3.0 * scale;
  vec4 color = vec4(0.0);
  for (int y = 0; y < 5; y++) {
    for (int x = 0; x < 5; x++) {
      vec2 offset = vec2(float(x - 2), float(y - 2)) * sampleStep;
      color += texture(u_input, inputUv(refracted + offset))
          * GaussianWeight(x) * GaussianWeight(y);
    }
  }
  frag_color = color;
}
