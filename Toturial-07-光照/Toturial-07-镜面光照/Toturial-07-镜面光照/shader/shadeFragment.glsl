uniform sampler2D u_Texture;

varying lowp vec2 frag_TexCoord;
varying lowp vec3 frag_Normal;
varying lowp vec3 frag_Pos;

struct Light {
    lowp vec3 Color;
    lowp float AmbientIntensity;
    lowp float DiffuseIntensity;
    lowp vec3 LightPos;
    highp float SpecularIntensity;
    highp float Shininess;
};
uniform Light u_Light;

void main(void) {
    
    // Ambient
    lowp vec3 AmbientColor = u_Light.Color * u_Light.AmbientIntensity;
    
    // Diffuse
    lowp vec3 Normal = normalize(frag_Normal);
    lowp vec3 lightDir = normalize(u_Light.LightPos - frag_Pos);
    lowp float DiffuseFactor = max(-dot(Normal, lightDir), 0.0);
    lowp vec3 DiffuseColor = u_Light.Color * u_Light.DiffuseIntensity * DiffuseFactor;
    
    // Specular
    lowp vec3 Eye = normalize(frag_Pos);
    lowp vec3 Reflection = reflect(-lightDir, Normal);
    lowp float SpecularFactor = pow(max(0.0, dot(Reflection, Eye)), u_Light.Shininess);
    lowp vec3 SpecularColor = u_Light.Color * u_Light.SpecularIntensity * SpecularFactor;
    
    gl_FragColor = texture2D(u_Texture, frag_TexCoord) * vec4((AmbientColor + DiffuseColor + SpecularColor), 1.0);
}
