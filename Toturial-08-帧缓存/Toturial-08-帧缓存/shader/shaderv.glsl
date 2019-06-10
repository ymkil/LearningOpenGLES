attribute vec3 a_position;
attribute vec2 a_TexCoord;

varying lowp vec2 frag_TexCoord;

void main()
{
    gl_Position = vec4(a_position.x,-a_position.y,a_position.z,1.0);
    frag_TexCoord = a_TexCoord;
}
