varying lowp vec2 tex_coord;

uniform sampler2D tex1;

void main(void)
{
    gl_FragColor = texture2D(tex1,tex_coord);
}
