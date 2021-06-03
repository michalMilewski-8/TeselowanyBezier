#include "shaderDemo.h"

using namespace mini;
using namespace gk2;
using namespace DirectX;
using namespace std;
using namespace utils;

ShaderDemo::ShaderDemo(HINSTANCE hInst) : GK2ShaderDemoBase(hInst)
{
	//Shader Variables
	m_variables.AddSemanticVariable("modelMtx", VariableSemantic::MatM);
	m_variables.AddSemanticVariable("modelInvTMtx", VariableSemantic::MatMInvT);
	m_variables.AddSemanticVariable("viewProjMtx", VariableSemantic::MatVP);
	m_variables.AddSemanticVariable("camPos", VariableSemantic::Vec4CamPos);

	XMFLOAT4 lightPos[2] = {
	{ -1.f, 0.0f, -3.5f, 1.f },
	{ 0.f, 3.5f, 0.0f, 1.f } };
	XMFLOAT3 lightColor[2] = {
	{ 12.f, 9.f, 10.f },
	{ 1.f, 0.f, 30.f } };
	m_variables.AddGuiVariable("lightPos",
		lightPos, -10, 10);
	m_variables.AddGuiVariable("lightColor",
		lightColor, 0, 100, 1);
	//m_variables.AddGuiColorVariable("albedo",
	//	XMFLOAT3{ 1.f, 1.f, 1.f });
	//m_variables.AddGuiVariable("metallness", 1.0f);
	//m_variables.AddGuiVariable("roughness", .3f, .1f);
	m_variables.AddGuiVariable("m", 50.f, 10.f, 200.f);

	auto h0 = 1.5f;
	m_variables.AddGuiVariable("h0", h0, 0, 3);
	m_variables.AddGuiVariable("l", 15.f, 5, 25);
	m_variables.AddGuiVariable("r", 0.5f, 0.01f, 1);
	m_variables.AddGuiVariable("rsmall", 0.1f, 0.01f, 0.5f);

	m_variables.AddGuiVariable("thalf", 3.f, 1.f, 5.f);
	m_variables.AddGuiVariable("xmax", .5f, .1f, 1.f);
	m_variables.AddGuiVariable("vmax", 4.f, .5f, 10.f);
	m_variables.AddSemanticVariable("time", VariableSemantic::FloatT);

	m_variables.AddSemanticVariable("mvpMtx", VariableSemantic::MatMVP);

	m_variables.AddGuiVariable("cutoff", 0.72f, 0.1f, 1.0f);

	m_variables.AddGuiVariable("waterLevel", -0.05f, -1, 1, 0.001f);

	m_variables.AddSemanticVariable("nearZ", VariableSemantic::FloatNearPlane);

	m_variables.AddTexture(m_device, "irMap", L"textures/cubeMapIrradiance.dds");
	m_variables.AddTexture(m_device, "pfEnvMap", L"textures/cubeMapRadiance.dds");
	m_variables.AddTexture(m_device, "brdfTex", L"textures/brdf_lut.png");

	m_variables.AddSemanticVariable("projInvMtx",
		VariableSemantic::MatPInv);
	m_variables.AddGuiVariable("depthThickness",
		0.05f, 0.0f, 0.5f);

	//Models
	const auto sphere = addModelFromString("s 0 0 0 0.5");
	auto teapot = addModelFromFile("models/Teapot.3ds");
	auto plane = addModelFromFile("models/Plane.obj");
	auto quad = addModelFromString("pp 4\n1 0 1 0 1 0\n1 0 -1 0 1 0\n-1 0 -1 0 1 0\n-1 0 1 0 1 0\n");
	auto envModel = addModelFromString("hex 0 0 0 1.73205");

	XMFLOAT4X4 modelMtx;
	XMStoreFloat4x4(&modelMtx, XMMatrixScaling(1.0f / 60.0f, 1.0f / 60.0f, 1.0f / 60.0f) * XMMatrixRotationX(-XM_PIDIV2) * XMMatrixTranslation(0, 0.5f - h0, 0));
	model(teapot).applyTransform(modelMtx);

	XMStoreFloat4x4(&modelMtx, XMMatrixTranslation(0, -h0, 0));
	model(plane).applyTransform(modelMtx);

	XMStoreFloat4x4(&modelMtx, XMMatrixScaling(20, 20, 20));
	model(quad).applyTransform(modelMtx);
	model(envModel).applyTransform(modelMtx);

	// Textura i sampler
	auto screenSize = m_window.getClientSize();
	m_variables.AddRenderableTexture(m_device,
		"screen", screenSize);
	SIZE halfscreenSize; halfscreenSize.cx = screenSize.cx / 2.0f; halfscreenSize.cy = screenSize.cy / 2.0f;
	m_variables.AddRenderableTexture(m_device,
		"halfscreen1", halfscreenSize);
	m_variables.AddRenderableTexture(m_device,
		"halfscreen2", halfscreenSize);

	m_variables.AddTexture(m_device, "screenColor",
		Texture2DDescription(screenSize.cx, screenSize.cy,
			DXGI_FORMAT_R8G8B8A8_UNORM, 1));
	m_variables.AddTexture(m_device, "screenDepth",
		Texture2DDescription(screenSize.cx, screenSize.cy,
			DXGI_FORMAT_R24_UNORM_X8_TYPELESS, 1));

	m_variables.AddSemanticVariable("viewportDim",
		VariableSemantic::Vec2ViewportDims);
	m_variables.AddGuiVariable("blurScale",
		1.0f, 0.1f, 2.0f);
	SamplerDescription sDesc;
	sDesc.AddressU = D3D11_TEXTURE_ADDRESS_CLAMP;
	sDesc.AddressV = D3D11_TEXTURE_ADDRESS_CLAMP;
	sDesc.Filter = D3D11_FILTER_MIN_MAG_MIP_LINEAR;
	m_variables.AddSampler(m_device,
		"blurSampler", sDesc);

	m_variables.AddSampler(m_device, "samp");
	m_variables.AddTexture(m_device, "normTex", L"textures/jagged-cliff1-normal-dx.png");

	m_variables.AddTexture(m_device, "envMap", L"textures/cubeMap.dds");
	m_variables.AddTexture(m_device, "perlin", L"textures/NoiseVolume.dds");
	//m_variables.AddTexture(m_device, "albedoTex", L"textures/rustediron2/albedo.png");
	//m_variables.AddTexture(m_device, "roughnessTex", L"textures/rustediron2/roughness.png");
	//m_variables.AddTexture(m_device, "metallicTex", L"textures/rustediron2/metallness.png");
	m_variables.AddTexture(m_device, "albedoTex", L"textures/rustediron2/albedo.png");
	m_variables.AddTexture(m_device, "roughnessTex", L"textures/rustediron2/roughness.png");
	m_variables.AddTexture(m_device, "metallicTex", L"textures/rustediron2/metallness.png");

	//Render Passes
	//const auto passSphere = addPass(L"sphereVS.cso", L"spherePS.cso");
	//addModelToPass(passSphere, sphere);
	auto passTeapot = addPass(L"teapotVS.cso", L"teapotPS.cso", "screen");
	addModelToPass(passTeapot, teapot);
	auto passSpring = addPass(L"springVS.cso", L"springPS.cso");
	addModelToPass(passSpring, plane);
	auto passWater = addPass(L"waterVS.cso", L"waterPS.cso");
	addModelToPass(passWater, quad);

	copyRenderTarget(passWater, "screenColor");
	copyDepthBuffer(passWater, "screenDepth");

	auto passEnv = addPass(L"envVS.cso", L"envPS.cso");
	addModelToPass(passEnv, envModel);
	
	RasterizerDescription rs;
	rs.CullMode = D3D11_CULL_NONE;
	addRasterizerState(passWater, rs);
	addRasterizerState(passEnv, RasterizerDescription(true));

	auto passDownsample = addPass(L"fullScreenQuadVS.cso", L"downsamplePS.cso" ,"halfscreen1");
	addModelToPass(passDownsample, quad);

	auto passHBlur = addPass(L"fullScreenQuadVS.cso",
		L"hblurPS.cso", "halfscreen2");
	addModelToPass(passHBlur, quad);

	auto passVBlur = addPass(L"fullScreenQuadVS.cso",
		L"vblurPS.cso", "halfscreen1", true);
	addModelToPass(passVBlur, quad);

	auto passComposite = addPass(
		L"fullScreenQuadVS.cso", L"compositePS.cso",
		getDefaultRenderTarget());
	addModelToPass(passComposite, quad);
}
