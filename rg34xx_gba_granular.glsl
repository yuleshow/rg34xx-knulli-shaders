#pragma parameter GBA_GRID_INTENSITY "Granular grid intensity" 0.18 0.0 0.35 0.01
#pragma parameter GBA_PIXEL_SHARPEN "Pixel sharpness" 0.72 0.0 1.0 0.02
#pragma parameter GBA_PIXEL_BRIGHTNESS "Brightness" 1.10 0.7 1.4 0.01
#pragma parameter GBA_GRID_GAMMA "Granular gamma" 0.92 0.8 1.1 0.01

#ifdef GL_ES
#define COMPAT_VARYING_PRECISION mediump
#else
#define COMPAT_VARYING_PRECISION
#endif

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
uniform float GBA_GRID_INTENSITY;
uniform float GBA_PIXEL_SHARPEN;
uniform float GBA_PIXEL_BRIGHTNESS;
uniform float GBA_GRID_GAMMA;

void main()
{
  vec2 texel = 1.0 / TextureSize;
  vec2 pixelPos = vTexCoord * TextureSize;
  vec2 pixelCenter = (floor(pixelPos) + 0.5) * texel;

  vec3 center = COMPAT_TEXTURE(Texture, pixelCenter).rgb;
  vec3 left = COMPAT_TEXTURE(Texture, pixelCenter - vec2(texel.x, 0.0)).rgb;
  vec3 right = COMPAT_TEXTURE(Texture, pixelCenter + vec2(texel.x, 0.0)).rgb;
  vec3 up = COMPAT_TEXTURE(Texture, pixelCenter - vec2(0.0, texel.y)).rgb;
  vec3 down = COMPAT_TEXTURE(Texture, pixelCenter + vec2(0.0, texel.y)).rgb;

  vec3 neighbors = (left + right + up + down) * 0.25;
  vec3 color = mix(neighbors, center, 0.55 + GBA_PIXEL_SHARPEN * 0.45);

  vec2 outputPixel = vTexCoord * OutputSize;
  vec2 phase = fract(outputPixel);
  float horizontalGap = smoothstep(0.12, 0.32, abs(phase.x - 0.5));
  float verticalGap = smoothstep(0.10, 0.30, abs(phase.y - 0.5));
  float gap = min(horizontalGap, verticalGap);

  float outputColumn = mod(floor(outputPixel.x), 3.0);
  vec3 granular = vec3(1.0);
  if (outputColumn == 0.0) granular.r += GBA_GRID_INTENSITY * 0.55;
  if (outputColumn == 1.0) granular.g += GBA_GRID_INTENSITY * 0.65;
  if (outputColumn == 2.0) granular.b += GBA_GRID_INTENSITY * 0.55;
  granular -= (1.0 - gap) * GBA_GRID_INTENSITY * vec3(0.22, 0.18, 0.26);

  color *= granular;
  color *= mix(0.94, 1.08, verticalGap);
  color = pow(max(color, 0.0), vec3(GBA_GRID_GAMMA));
  color *= GBA_PIXEL_BRIGHTNESS;

  FragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
#else
void main() {}
#endif
