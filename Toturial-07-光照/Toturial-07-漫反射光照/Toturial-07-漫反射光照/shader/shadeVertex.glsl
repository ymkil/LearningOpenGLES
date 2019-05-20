uniform highp mat4 u_modelMatrix;

attribute vec3 a_Position;
attribute vec2 a_TexCoord;
attribute vec3 a_Normal;

varying lowp vec2 frag_TexCoord;
varying lowp vec3 frag_Normal;

varying lowp vec3 frag_Pos;

void main(void) {
    
    frag_TexCoord = a_TexCoord;
    frag_Normal = vec3(u_modelMatrix * vec4(a_Normal, 0.0));
    frag_Pos = vec3(u_modelMatrix * vec4(a_Position, 1.0));
    
    gl_Position = u_modelMatrix * vec4(a_Position, 1.0);
}
