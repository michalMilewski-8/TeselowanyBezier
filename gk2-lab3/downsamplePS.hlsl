sampler blurSampler;
texture2D screen;
float cutoff;

struct PSInput
{
	float4 pos : SV_POSITION;
	float2 tex : TEXCOORD0;
};

float4 main(PSInput i) : SV_TARGET
{
	float4 color = screen.Sample(blurSampler, i.tex);
	float luminance = dot(color.rgb, float3(0.3f, 0.58f, 0.12f));
	return luminance < cutoff ? float4(0.0f, 0.0f, 0.0f, 0.0f) : color;
}