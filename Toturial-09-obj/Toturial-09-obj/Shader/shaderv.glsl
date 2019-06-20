uniform highp mat4 u_modelViewMatrix;
uniform highp mat4 u_projectionMatrix;

attribute vec3 a_position;
attribute vec2 a_TexCoord;
attribute vec3 a_Normal;


varying lowp vec2 frag_TexCoord;
varying lowp vec3 frag_Normal;
varying lowp vec3 frag_Position;

void main()
{
    frag_TexCoord = a_TexCoord;
    frag_Normal = (u_modelViewMatrix * vec4(a_Normal, 0.0)).xyz;
    frag_Position = (u_modelViewMatrix * vec4(a_position, 1.0)).xyz;
    
    gl_Position = u_projectionMatrix * u_modelViewMatrix * vec4(a_position, 1.0);
}
