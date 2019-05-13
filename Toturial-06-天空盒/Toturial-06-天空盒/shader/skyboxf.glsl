
varying lowp vec3 TextCoord;
uniform samplerCube skybox;

void main()
{
    gl_FragColor = textureCube(skybox, TextCoord);
}
