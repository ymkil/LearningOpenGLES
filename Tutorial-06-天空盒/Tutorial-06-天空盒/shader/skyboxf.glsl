
varying lowp vec3 TextCoord;
uniform samplerCube skybox;

void main()
{
    gl_FragColor = texture2D(skybox, TextCoord);
}
