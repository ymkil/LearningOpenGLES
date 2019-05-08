attribute vec2 in_position;
attribute vec2 in_tex_coord;

varying lowp vec2 tex_coord;


void main(void)
{
    tex_coord = in_tex_coord;
    
    gl_Position = vec4(in_position, 0.0, 1.0);
}
