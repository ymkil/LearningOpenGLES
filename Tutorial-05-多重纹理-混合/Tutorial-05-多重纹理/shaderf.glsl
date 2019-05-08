varying lowp vec2 tex_coord;

uniform sampler2D tex1;
uniform sampler2D tex2;

void main(void)
{
    gl_FragColor = mix(texture2D(tex1,tex_coord),texture2D(tex2,tex_coord), 0.6);
}
