matrix modelMtx, modelInvTMtx, viewProjMtx;
float4 camPos;
float h0, l, r, rsmall;
float  time, xmax, vmax, thalf;
static const float two_pi = 6.283185307179586476925286766559f;
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
	float3 tangent : TANGENT0;
};

float dangle_ds(float l, float r, float h) {
	return sqrt(l * l - h * h) / r;
}

float3 get_position(float s, float r, float h, float a) {
	return float3(r * cos(s * a), s * h, r * sin(s * a));
}

float3 get_tangent(float s, float r, float h, float a) {
	return float3(
		r * (cos(a * s) - a * s*sin(a * s)),
		h,
		r * (sin(a * s) + a * s*cos(a * s))
		);
}

float3 get_normal(float s, float r, float h, float a) {
	return float3(
		-a * r * (2 * sin(a * s) + a * s * cos(a * s)),
		0,
		a * r * (2*cos(a * s) - a * s*sin(a * s))
		);
}

float springHeight(float t) {
	return xmax * pow(e, (-0.693147 * 2 * t) / thalf) * sin((vmax / xmax) * t);
}

VSOutput main(VSInput i)
{
	float tmax = 2 * thalf;
	float dup;
	float h = h0;
	h = h0 + springHeight(modf(time / tmax, dup) * tmax);
	float a = dangle_ds(l, r, h);
	float3 CurvePosition = get_position(i.pos.y, r, h, a);
	float3 CurveTangent = normalize(get_tangent(i.pos.y, r, h, a));
	float3 CurveNormal = normalize(get_normal(i.pos.y, r, h, a));
	float3 CurveBinormal = cross(CurveNormal, CurveTangent);

	float3 Normal = CurveNormal * cos(two_pi * i.pos.x) +
		CurveBinormal * sin(two_pi * i.pos.x);

	float4 Position =
		float4(CurvePosition + rsmall * Normal, 1.0f);

	VSOutput o;
	float4 worldPos = mul(modelMtx, Position);
	o.view = normalize(camPos.xyz - worldPos.xyz);
	o.norm = normalize(mul(modelInvTMtx,
		float4(Normal, 0.0f)).xyz);
	o.worldPos = worldPos.xyz;
	o.pos = mul(viewProjMtx, worldPos);
	o.tangent = mul(modelInvTMtx,
		float4(CurveTangent, 0.0f)).xyz;
	o.tex = float2(i.pos.y * 6.8f, i.pos.x * 0.2f);
	return o;
}