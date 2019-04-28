precision mediump float;

uniform sampler2D colorMap;

varying vec2 vTexcoord;

void main()
{
    gl_FragColor = texture2D(colorMap, vTexcoord);
}
