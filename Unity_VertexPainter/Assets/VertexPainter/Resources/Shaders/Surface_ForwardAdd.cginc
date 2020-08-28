#ifndef SURFACE_FORWARDADD_INCLUDED
#define SURFACE_FORWARDADD_INCLUDED

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"

sampler2D _Tex1; float4 _Tex1_ST;
half4 _SpecColor1, _Tint1;
half _Glossiness1;

struct Input
{
	float2 uv_MainTex;
};

struct PSInput
{
	float4 pos : POSITION;
	float2 uv : TEXCOORD0;
	float3 worldNormal : TEXCOORD1;
	float3 worldPos : TEXCOORD2;
	UNITY_SHADOW_COORDS(3)
	UNITY_FOG_COORDS(4)
};

void surf(Input IN, inout SurfaceOutputStandard o)
{
	fixed4 c = tex2D(_Tex1, IN.uv_MainTex) * _Tint1;
	o.Albedo = c.rgb;
	o.Metallic = _SpecColor1.rgb;
	o.Smoothness = _Glossiness1;
	o.Alpha = c.a;
}

PSInput VSMain(appdata_full v)
{
	PSInput o = (PSInput)0;
	UNITY_INITIALIZE_OUTPUT(PSInput, o);
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = TRANSFORM_TEX(v.texcoord, _Tex1);
	o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
	o.worldNormal = UnityObjectToWorldNormal(v.normal);
	UNITY_TRANSFER_SHADOW(o,v.texcoord1.xy);
	UNITY_TRANSFER_FOG(o,o.pos);
	return o;
}

fixed4 PSMain(PSInput IN) : SV_Target
{
	Input surfIN;
	UNITY_INITIALIZE_OUTPUT(Input,surfIN);
	surfIN.uv_MainTex.x = 1.0;
	surfIN.uv_MainTex = IN.uv;
	float3 worldPos = IN.worldPos;
	float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
	fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));

	SurfaceOutputStandard o;
	UNITY_INITIALIZE_OUTPUT(SurfaceOutputStandard, o);
	o.Albedo = 0.0;
	o.Emission = 0.0;
	o.Alpha = 0.0;
	o.Occlusion = 1.0;
	o.Normal = IN.worldNormal;
	surf(surfIN, o);
	UNITY_LIGHT_ATTENUATION(atten, IN, worldPos)

	UnityGI gi;
	UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
	gi.indirect.diffuse = 0;
	gi.indirect.specular = 0;
	gi.light.color = _LightColor0.rgb;
	gi.light.dir = lightDir;
	gi.light.color *= atten;

	// Create finalColor
	fixed4 color = LightingStandard(o, worldViewDir, gi);
	color.a = 0.0;
	UNITY_APPLY_FOG(IN.fogCoord, color);
	UNITY_OPAQUE_ALPHA(color.a);
	return color;
}

#endif
