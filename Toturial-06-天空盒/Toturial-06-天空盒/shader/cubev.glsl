attribute vec3 position;
attribute vec2 textCoordinate;

uniform highp mat4 u_mvpMatrix;

varying lowp vec2 varyTextCoord;

void main()
{
    varyTextCoord = textCoordinate;
    gl_Position = u_mvpMatrix * vec4(position, 1.0);
}
