#pragma parameter SCANLINE_INTENSITY "Scanline intensity" 0.22 0.0 0.5 0.01
#pragma parameter MASK_INTENSITY "Mask intensity" 0.08 0.0 0.25 0.01
#pragma parameter MASK_SIZE "Mask size" 3.0 2.0 4.0 1.0
#pragma parameter CRT_CURVE "CRT curvature" 0.12 0.0 0.35 0.01
#pragma parameter PIXEL_SHARPEN "Pixel sharpening" 0.55 0.0 1.0 0.05
#pragma parameter OUTPUT_BRIGHTNESS "Brightness" 1.04 0.5 1.4 0.01

#if defined(VERTEX)
#if __VERSION__ >= 130
  #define COMPAT_VARYING out
  #define COMPAT_ATTRIBUTE in
#else
  #define COMPAT_VARYING varying
  #define COMPAT_ATTRIBUTE attribute
#endif

#ifdef GL_ES
  precision mediump float;
  #define COMPAT_VARYING_PRECISION highp
#else
  #define COMPAT_VARYING_PRECISION
#endif

COMPAT_ATTRIBUTE vec4 VertexCoord;
COMPAT_ATTRIBUTE vec4 TexCoord;
COMPAT_VARYING COMPAT_VARYING_PRECISION vec2 vTexCoord;

uniform mat4 MVPMatrix;

void main()
{
  gl_Position = MVPMatrix * VertexCoord;
  vTexCoord = TexCoord.xy;
}

#elif defined(FRAGMENT)
#if __VERSION__ >= 130
  #define COMPAT_VARYING in
  #define COMPAT_TEXTURE texture
  out vec4 FragColor;
#else
  #define COMPAT_VARYING varying
  #define COMPAT_TEXTURE texture2D
  #define FragColor gl_FragColor
#endif

#ifdef GL_ES
  #ifdef GL_FRAGMENT_PRECISION_HIGH
    precision highp float;
  #else
    precision mediump float;
  #endif
#endif
COMPAT_VARYING COMPAT_VARYING_PRECISION vec2 vTexCoord;

uniform sampler2D Texture;
uniform vec2 TextureSize;
uniform vec2 InputSize;
uniform vec2 OutputSize;
uniform float SCANLINE_INTENSITY;
uniform float MASK_INTENSITY;
uniform float MASK_SIZE;
uniform float CRT_CURVE;
uniform float PIXEL_SHARPEN;
uniform float OUTPUT_BRIGHTNESS;

vec2 curveUv(vec2 uv)
{
  vec2 centered = uv * 2.0 - 1.0;
  centered *= 1.0 + CRT_CURVE * centered * centered;
  return centered * 0.5 + 0.5;
}

void main()
{
  vec2 uv = curveUv(vTexCoord);

  if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0)
  {
    FragColor = vec4(0.0, 0.0, 0.0, 1.0);
    return;
  }

  vec2 pixel = uv * TextureSize;
  vec2 samplePos = floor(pixel) + 0.5;
  vec2 nearestUv = samplePos / TextureSize;
  vec2 weights = smoothstep(0.0, 1.0, fract(pixel));
  vec3 color = COMPAT_TEXTURE(Texture, nearestUv).rgb;

  vec2 texel = 1.0 / TextureSize;
  vec3 horizontal = COMPAT_TEXTURE(Texture, nearestUv + vec2(texel.x, 0.0)).rgb
                  - COMPAT_TEXTURE(Texture, nearestUv - vec2(texel.x, 0.0)).rgb;
  vec3 vertical = COMPAT_TEXTURE(Texture, nearestUv + vec2(0.0, texel.y)).rgb
                - COMPAT_TEXTURE(Texture, nearestUv - vec2(0.0, texel.y)).rgb;
  float detail = PIXEL_SHARPEN * 0.25;
  color = clamp(color - (horizontal + vertical) * detail, 0.0, 1.0);

  float scan = 0.5 + 0.5 * cos(uv.y * OutputSize.y * 3.14159265);
  float scanline = mix(1.0, 1.0 - SCANLINE_INTENSITY, scan);
  color *= scanline;

  float column = mod(floor(uv.x * OutputSize.x / MASK_SIZE), 3.0);
  vec3 mask = vec3(1.0);
  if (column == 0.0) mask.r *= 1.0 + MASK_INTENSITY;
  if (column == 1.0) mask.g *= 1.0 + MASK_INTENSITY;
  if (column == 2.0) mask.b *= 1.0 + MASK_INTENSITY;
  color *= mask;

  FragColor = vec4(clamp(color * OUTPUT_BRIGHTNESS, 0.0, 1.0), 1.0);
}
#else
void main() {}
#endif
