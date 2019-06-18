varying lowp vec2 frag_TexCoord;
uniform sampler2D u_Texture;
void main()
{
    gl_FragColor = texture2D(u_Texture, frag_TexCoord);
}
