#version 330

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;

// Input uniform values
uniform sampler2D texture0;
uniform vec4 colDiffuse;

// Output fragment color
out vec4 finalColor;

uniform float mixing = 0.1;

const int paletteSize = 15;
uniform vec4 paletteArray[paletteSize] = vec4[](
  vec4(0.0627, 0.0039, 0.0471, 1.0), // #10010C
  vec4(0.0824, 0.0039, 0.0627, 1.0), // #150110
  vec4(0.1333, 0.0000, 0.0980, 1.0), // #220119
  vec4(0.2000, 0.0039, 0.1451, 1.0), // #330225
  vec4(0.2824, 0.0000, 0.1961, 1.0), // #480232
  vec4(0.3765, 0.0000, 0.2431, 1.0), // #60033E
  vec4(0.4863, 0.0000, 0.2902, 1.0), // #7C044A
  vec4(0.6118, 0.0000, 0.3294, 1.0), // #9C0654
  vec4(0.7451, 0.0000, 0.3569, 1.0), // #BE075B
  vec4(0.8980, 0.0000, 0.3451, 1.0), // #E50758
  vec4(1.0000, 0.2509, 0.3294, 1.0), // #FF4054
  vec4(1.0000, 0.4941, 0.4078, 1.0), // #FF7E68
  vec4(1.0000, 0.6667, 0.5216, 1.0), // #FFAA85
  vec4(1.0000, 0.8157, 0.6745, 1.0), // #FFD0AC
  vec4(1.0000, 0.9490, 0.8706, 1.0)  // #FFF2DE
);

vec4 palette(vec4 i) {
  float minDelta = 1e20;
  int minI = 0;
  for(int j = 0; j < paletteSize; ++j) {
    vec4 diff = paletteArray[j] - i;
    float delta = dot(diff.rgb, diff.rgb);
    if(delta < minDelta) {
      minDelta = delta;
      minI = j;
    }
  }
  return vec4(mix(paletteArray[minI], i, mixing).rgb, i.a); // lerp it a little so that way it keeps gradients
}

void main() {
  finalColor = palette(texture(texture0, fragTexCoord));
}
