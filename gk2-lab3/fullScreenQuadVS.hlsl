
struct VSOutput
{
	float4 pos : SV_POSITION;
	float2 tex : TEXCOORD0;
};

VSOutput main(float3 pos : POSITION0)
{
	VSOutput o;
	o.pos = float4(pos.x,pos.z,0,1);
	o.tex = float2((pos.x + 1) / 2.0f, (-pos.z + 1) / 2.0f);
	return o;
}