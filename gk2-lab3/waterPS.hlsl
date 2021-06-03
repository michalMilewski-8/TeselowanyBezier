float4 camPos;
sampler samp;
textureCUBE envMap;
texture3D perlin;
float time;

texture2D screenColor;
texture2D screenDepth;
matrix viewProjMtx;
float2 viewportDim;
float nearZ;
static float maxDistance = 30.0f;

matrix projInvMtx;
float depthThickness;


struct PSInput
{
	float4 pos : SV_POSITION;
	float3 localPos : POSITION0;
	float3 worldPos : POSITION1;
};
float3 intersectRay(float3 p, float3 d) {
	float tx = max((1 - p.x) / d.x, (-1 - p.x) / d.x);
	float ty = max((1 - p.y) / d.y, (-1 - p.y) / d.y);
	float tz = max((1 - p.z) / d.z, (-1 - p.z) / d.z);
	float t = min(tx, min(ty, tz));
	return p + d * t;
}
float fresnel(float3 N, float3 V) {
	float n2 = 4.0f / 3.0f;
	float n1 = 1.0f;
	//float Fo = (n2 - n1) / (n2 + n1);
	//Fo = Fo * Fo;
	float Fo = 0.17f;
	if (dot(N, V) < 0) N = -N;
	float cs = max(dot(N, V), 0);
	return Fo + (1 - Fo) * (1 - cs) * (1 - cs) * (1 - cs) * (1 - cs) * (1 - cs);
}

float linearizeDepth(float depth)
{
	float4 p = float4(0.0f, 0.0f, depth, 1.0f);
		p = mul(projInvMtx, p);
	return p.z / p.w;
}

float4 screenSpaceRayCast(float3 wOrg, float3 wDir)
{
	float3 wEnd = wOrg + wDir * maxDistance;
	//NDC ray endpoints
	float4 ssOrg = mul(viewProjMtx, float4(wOrg, 1.0f));
	float4 ssEnd = mul(viewProjMtx, float4(wEnd, 1.0f));

	if (ssEnd.w < nearZ) {
		float toNearZ = maxDistance *
			(nearZ - ssOrg.w) / (ssEnd.w - ssOrg.w);
		wEnd = wOrg + wDir * toNearZ;
		ssEnd = mul(viewProjMtx, float4(wEnd, 1.0f));
	}

	ssOrg = float4(ssOrg.xyz, 1.0f) / ssOrg.w;
	ssEnd = float4(ssEnd.xyz, 1.0f) / ssEnd.w;

	ssOrg.xy = (float2(ssOrg.x, -ssOrg.y) + 1.0f) *
		viewportDim / 2.0f;
	ssEnd.xy = (float2(ssEnd.x, -ssEnd.y) + 1.0f) *
		viewportDim / 2.0f;

	float2 delta = (ssEnd.xy - ssOrg.xy);
	bool coordSwap = false;
	if (abs(delta.x) < abs(delta.y))
	{
		//DDA will iterate vertically, swap coordinates
		delta = delta.yx;
		ssOrg.xy = ssOrg.yx;
		ssEnd.xy = ssEnd.yx;
		coordSwap = true;
	}
	//Iteration direction:
	float stepDir = sign(delta.x);
	float4 dP = stepDir * (ssEnd - ssOrg) / delta.x;
	float4 P = ssOrg;
	float endX = stepDir * ssEnd.x;
	float prevZ = 1 / P.w;
	for (; (P.x * stepDir) < endX; P += dP)
	{
		int3 pxCoord = int3(coordSwap ? P.yx : P.xy, 0);
		float screenZ = linearizeDepth(screenDepth.Load(pxCoord).r);
		float rayZ = 1.0f / (P.w + 0.5f * dP.w);
		float maxZ = max(rayZ, prevZ);
		float minZ = min(rayZ, prevZ);
		prevZ = rayZ;
		if (screenZ - depthThickness < maxZ)
		{
			if (screenZ > minZ)
				return screenColor.Load(pxCoord);
			else break;
		}
	}
	return float4(0.0f, 0.0f, 0.0f, 0.0f);
}

float4 main(PSInput i) : SV_TARGET
{
	float3 tex = float3(i.localPos.xz * 10.0f, time);
	float ex = perlin.Sample(samp, tex).r;
	float ez = perlin.Sample(samp, tex + 0.5f).r;
	ex = 2 * ex - 1;
	ez = 2 * ez - 1;

	float3 viewVec = normalize(camPos.xyz - i.worldPos);
	float3 norm = normalize(float3(ex, 20.0f, ez));
	//float3 norm = float3(0.0f, 1.0f, 0.0f);
	float wsp = 0.14f;
	if (dot(norm, viewVec) < 0) {
		norm = -norm;
		wsp = 4.0f / 3.0f;
	}
	float3 d = reflect(-viewVec, norm);
	float3 p = refract(-viewVec, norm, wsp);
	float4 colorD = envMap.Sample(samp, intersectRay(i.localPos,d));
	float4 ssReflColor = screenSpaceRayCast(i.worldPos, d);
	colorD = lerp(colorD, ssReflColor, ssReflColor.a);
	float4 colorP = envMap.Sample(samp, intersectRay(i.localPos,p));
	float4 ssRefrColor = screenSpaceRayCast(i.worldPos, p);
	colorP = lerp(colorP, ssRefrColor, ssRefrColor.a);
	float f = fresnel(norm, viewVec);
	float4 color = lerp(colorP, colorD, f);
	if (!any(p)) {
		color = colorD;
	}


	color = pow(color, 0.4545f);
	return color;
}
