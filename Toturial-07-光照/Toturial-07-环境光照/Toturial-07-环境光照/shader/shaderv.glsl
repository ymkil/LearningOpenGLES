attribute vec3 a_position;
attribute vec2 a_TexCoord;

uniform highp mat4 u_modelMatrix;

varying lowp vec2 frag_TexCoord;

void main()
{
    gl_Position = u_modelMatrix * vec4(a_position, 1.0);
    frag_TexCoord = a_TexCoord;
}
