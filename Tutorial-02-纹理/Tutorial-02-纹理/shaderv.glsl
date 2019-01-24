attribute vec3 vPosition;
attribute vec2 textCoordinate;

varying lowp vec2 varyTextCoord;
void main(void)
{
    varyTextCoord = textCoordinate;
    gl_Position = vec4(vPosition.x,-vPosition.y,vPosition.z,1.0);
}
