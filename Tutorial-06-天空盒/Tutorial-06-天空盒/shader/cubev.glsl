attribute vec3 position;
attribute vec2 textCoordinate;

uniform mat4 projection;
uniform mat4 view;
uniform mat4 model;

varying lowp vec2 varyTextCoord;

void main()
{
    varyTextCoord = textCoordinate;
    gl_Position = projection * view * model * vec4(position, 1.0);
}
