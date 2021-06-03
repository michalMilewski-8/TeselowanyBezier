//SamplerState samp : register(s0);
//Texture2D normTex : register(t0);
//
//
//#define NLIGHTS 2
//float4 lightPos[NLIGHTS];
//float3 lightColor[NLIGHTS];
//float3 surfaceColor;
//float ks, kd, ka, m;
//
//float4 phong(float3 worldPos, float3 norm, float3 view)
//{
//    view = normalize(view);
//    norm = normalize(norm);
//    float3 color = surfaceColor * ka; //ambient
//    for (int k = 0; k < NLIGHTS; ++k)
//    {
//        float3 lightVec = normalize(lightPos[k].xyz - worldPos);
//        float3 halfVec = normalize(view + lightVec);
//        color += lightColor[k] * kd * surfaceColor * saturate(dot(norm, lightVec));//diffuse
//        color += lightColor[k] * ks * pow(saturate(dot(norm, halfVec)), m);//specular
//    }
//    return saturate(float4(color, 1.0f));
//}
//
//float3 normalMapping(float3 N, float3 T, float3 tn) {
//    float3 B = normalize(cross(N, T));
//    T = cross(B, N);
//
//    float3x3 pre = { T,B,N };
//    pre = transpose(pre);
//
//    return mul(pre, tn);
//}

//struct PSInput
//{
//    float4 pos : SV_POSITION;
//    float3 worldPos : POSITION0;
//    float3 norm : NORMAL0;
//    float3 view : VIEWVEC0;
//    float2 tex : TEXCOORD0;
//    float3 tangent : TANGENT0;
//};

//float4 main(PSInput i) : SV_TARGET
//{
//
//    float3 N = normalize(i.norm);
//    float3 dPdx = ddx(i.worldPos);
//    float3 dPdy = ddy(i.worldPos);
//    float2 dtdx = ddx(i.tex);
//    float2 dtdy = ddy(i.tex);
//    float3 T = normalize(-dPdx * dtdy.y + dPdy * dtdx.y);
//
//    float3 tn = normTex.Sample(samp, i.tex).xyz;
//    tn = (tn + 1.0f) / 2.0f;
//    tn.y = -tn.y;
//
//    float3 norm = normalMapping(N, T, tn);
//
//    return phong(i.worldPos, norm, i.view);
//}


//float4 phong(float3 worldPos, float3 norm, float3 view)
//{
//    view = normalize(view);
//    norm = normalize(norm);
//    float3 color = surfaceColor * ka; //ambient
//    for (int k = 0; k < NLIGHTS; ++k)
//    {
//        float3 lightVec = normalize(lightPos[k].xyz - worldPos);
//        float3 halfVec = normalize(view + lightVec);
//        color += lightColor[k] * kd * surfaceColor * saturate(dot(norm, lightVec));//diffuse
//        color += lightColor[k] * ks * pow(saturate(dot(norm, halfVec)), m);//specular
//    }
//    return saturate(float4(color, 1.0f));
//}
SamplerState samp : register(s0);
Texture2D normTex : register(t0);
texture2D albedoTex: register(t1);
texture2D metallicTex: register(t3);
texture2D roughnessTex: register(t2);
textureCUBE irMap;
textureCUBE pfEnvMap;
texture2D brdfTex;
static const float PI = 3.14159265f;

#define NLIGHTS 2
float4 lightPos[NLIGHTS];
float3 lightColor[NLIGHTS];
//float3 albedo;
//float metallness, roughness;

//float4 phong(float3 worldPos, float3 norm, float3 view)
//{
//    view = normalize(view);
//    norm = normalize(norm);
//    float3 color = surfaceColor * ka; //ambient
//    for (int k = 0; k < NLIGHTS; ++k)
//    {
//        float3 lightVec = normalize(lightPos[k].xyz - worldPos);
//        float3 halfVec = normalize(view + lightVec);
//        color += lightColor[k] * kd * surfaceColor * saturate(dot(norm, lightVec));//diffuse
//        color += lightColor[k] * ks * pow(saturate(dot(norm, halfVec)), m);//specular
//    }
//    return saturate(float4(color, 1.0f));
//}

float3 normalMapping(float3 N, float3 T, float3 tn) {
	float3 B = normalize(cross(N, T));
	T = cross(B, N);

	float3x3 pre = { T,B,N };
	pre = transpose(pre);

	return mul(pre, tn);
}

struct PSInput
{
    float4 pos : SV_POSITION;
    float3 worldPos : POSITION0;
    float3 norm : NORMAL0;
    float3 view : VIEWVEC0;
    float2 tex : TEXCOORD0;
    float3 tangent : TANGENT0;
};

float normalDistributionGGX(float3 N, float3 H, float r) {
	float m = max(dot(N, H), 0);
	float mn = m * m * (r * r - 1) + 1;
	return r * r / (PI * mn * mn);
}

float geometrySchlickGGX(float nw, float r) {
	float q = (r + 1) * (r + 1) / 8;
	return nw / (nw * (1 - q) + q);
}

float geometrySmith(float3 N, float3 V, float3 L, float r) {
	return geometrySchlickGGX(max(dot(N, V), 0.0f), r) * geometrySchlickGGX(max(dot(N, L), 0.0f), r);
}

float3 fresnel(float3 N, float3 L, float3 Fo) {
	float nl = 1 - max(dot(N, L), 0.0f);
	return Fo + (1 - Fo) * pow(nl, 5.0f);
}

float4 main(PSInput i) : SV_TARGET
{
	float3 albedo = albedoTex.Sample(samp, i.tex).xyz;;
	float metallness = metallicTex.Sample(samp, i.tex).x;
	float roughness = roughnessTex.Sample(samp, i.tex).x;

	float3 N = normalize(i.norm);
	float3 V = normalize(i.view);
	float3 dPdx = ddx(i.worldPos);
	float3 dPdy = ddy(i.worldPos);
	float2 dtdx = ddx(i.tex);
	float2 dtdy = ddy(i.tex);
	float3 T = normalize(-dPdx * dtdy.y + dPdy * dtdx.y);




	float3 tn = normTex.Sample(samp, i.tex).xyz;
	tn = (tn + 1.0f) / 2.0f;
	tn.y = -tn.y;
	float3 norm = normalMapping(N, T, tn);
	float3 A = pow(albedo, 2.2f);
	float Fo = float3(0.04f, 0.04f, 0.04f) * (1.0f - metallness) + A * metallness;
	float3 R = reflect(-V, N);
	float3 Ii = pfEnvMap.SampleLevel(samp, R,roughness * 6.0f).rgb;
	float3 Iir = irMap.Sample(samp, N).rgb;
	float2 brdf = brdfTex.Sample(samp, float2(max(dot(N, V), 0.0f), roughness)).rg;
	float3 Id = (1.0f - fresnel(N, V, Fo)) * (1.0f - metallness) * A * Iir;
	float3 Is = Ii * (Fo * brdf.r + brdf.g);

	float3 color = float3(0, 0, 0);
	for (int lig = 0; lig < NLIGHTS; lig++) {
		float3 piz = lightPos[lig].xyz - i.worldPos;
		float pizlen = length(piz);
		float3 li = piz / pizlen;
		float3 Li = (lightColor[lig] * max(dot(N, li), 0.0f)) / (pizlen * pizlen);
		float3 H = (V + li) / length(V + li);

		float3 kd = (1.0f - fresnel(N, li, Fo)) * (1.0f - metallness);
		float mian = (4.0f * max(dot(N, V), 0.0f) * max(dot(N, li), 0.0f)) + 0.001f;
		float3 fct = fresnel(H, li, Fo) * normalDistributionGGX(N, H, roughness) * geometrySmith(N, V, li, roughness) / mian;
		//if(mian != 0.0f)
		//	fct = fresnel(H, li, Fo) * normalDistributionGGX(N, H, roughness) * geometrySmith(N, V, li, roughness) / mian;
		float3 Fl = A / PI;
		kd.x = kd.x * Fl.x;
		kd.y = kd.y * Fl.y;
		kd.z = kd.z * Fl.z;
		float3 fbrdf = kd + fct;

		color = color + (fbrdf * Li);
	}

	float3 ambient = 0.03f * albedo + Id + Is;
	color += ambient;
	color = pow(color, 0.4545f);
	return float4(color,1.0f);
	//return phong(i.worldPos, norm, i.view);
}