sampler blurSampler;
texture2D screen;
texture2D halfscreen1;


struct PSInput
{
	float4 pos : SV_POSITION;
	float2 tex : TEXCOORD0;
};

float4 main(PSInput i) : SV_TARGET
{
	float4 bloom = halfscreen1.Sample(blurSampler, i.tex);
	float4 color = screen.Sample(blurSampler, i.tex) + bloom;
	return color / (1.0f+bloom.a);
}