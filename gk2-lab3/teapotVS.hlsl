matrix modelMtx, modelInvTMtx, viewProjMtx;
float4 camPos;
float h0;
float  time, xmax, vmax, thalf;
static const float e = 2.7182818284590452353602874f;

struct VSInput
{
	float3 pos : POSITION0;
	float3 norm : NORMAL0;
	float2 tex : TEXCOORD0;
};

struct VSOutput
{
	float4 pos : SV_POSITION;
	float3 worldPos : POSITION0;
	float3 norm : NORMAL0;
	float3 view : VIEWVEC0;
	float2 tex : TEXCOORD0;
};

float springHeight(float t) {
	return xmax * pow(e, (-0.693147 * 2 * t) / thalf) * sin((vmax / xmax) * t);
}

VSOutput main(VSInput i)
{
	float tmax = 2 * thalf;
	float dup;
	VSOutput o;
	float4 worldPos = mul(modelMtx, float4(i.pos, 1.0f));
	worldPos.y += h0 + springHeight(modf(time / tmax, dup) * tmax);
	o.view = normalize(camPos.xyz - worldPos.xyz);
	o.norm = normalize(mul(modelInvTMtx, float4(i.norm, 0.0f)).xyz);
	o.worldPos = worldPos.xyz;
	o.pos = mul(viewProjMtx, worldPos);
	o.tex = i.tex / 4.0f;
	return o;
}