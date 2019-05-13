
attribute vec3 position;

uniform highp mat4 u_mvpMatrix;

varying lowp vec3 TextCoord;

void main()
{
    gl_Position = u_mvpMatrix * vec4(position, 1.0);
    TextCoord = position;
}
