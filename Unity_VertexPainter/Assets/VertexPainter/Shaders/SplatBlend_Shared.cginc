#ifndef SPLATBLEND_SHARED_INCLUDED
#define SPLATBLEND_SHARED_INCLUDED

#include "HLSLSupport.cginc"
#include "UnityShaderVariables.cginc"
#include "UnityShaderUtilities.cginc"
#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"


#define LAYER(__N) sampler2D _Tex##__N; fixed4 _Tint##__N; sampler2D _Normal##__N; sampler2D _GlossinessTex##__N; half _Glossiness##__N; half _Metallic##__N; half _Parallax##__N; half _TexScale##__N; half _Contrast##__N; sampler2D _Emissive##__N; half _EmissiveMult##__N; fixed4 _SpecColor##__N; sampler2D _SpecGlossMap##__N; float _DistUVScale##__N;

LAYER(1)
LAYER(2)
LAYER(3)

half  _FlowSpeed;
half  _FlowIntensity;
fixed _FlowAlpha;
half  _FlowRefraction;
float _DistBlendMin;
float _DistBlendMax;

struct Input 
{
    float2 uv_Tex1;
    float4 color;
    float3 worldPos;
    float3 worldNormal;
    float4 flowDir;
};

struct PSInput
{
	UNITY_POSITION(pos);
	float4 color : COLOR;

	float2 uv : TEXCOORD0;
	float3 worldPos : TEXCOORD1;
	float3 worldNormal : TEXCOORD2;
	float4 flowDir : TEXCOORD3;
	float4 lightMap : TEXCOORD4;
	UNITY_SHADOW_COORDS(5)
	UNITY_FOG_COORDS(6)

#ifndef LIGHTMAP_ON
	#if UNITY_SHOULD_SAMPLE_SH
		half3 sh : TEXCOORD7;
	#endif
#endif
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

UNITY_INSTANCING_BUFFER_START(Props)
UNITY_INSTANCING_BUFFER_END(Props)


#if _DISTBLEND
#define COMPUTEDISTBLEND float dist = saturate((distance(_WorldSpaceCameraPos, IN.worldPos) / _DistBlendMax) - _DistBlendMin);
#else
#define COMPUTEDISTBLEND  
#endif

#if (_FLOW1 || _FLOW2 || _FLOW3)
#define INIT_FLOW half flowInterp; float2 fuv1; float2 fuv2; Flow(IN.flowDir.xy, IN.flowDir.zw, _FlowSpeed, _FlowIntensity, fuv1, fuv2, flowInterp);
#else
#define INIT_FLOW  
#endif

#if _FLOW1
#define FETCH_TEX1(_T, _UV) lerp(tex2D(_T, fuv1), tex2D(_T, fuv2), flowInterp)
#elif _DISTBLEND
#define FETCH_TEX1(_T, _UV) lerp(tex2D(_T, _UV), tex2D(_T, _UV*_DistUVScale1), dist)
#else
#define FETCH_TEX1(_T, _UV) tex2D(_T, _UV)
#endif

#if _FLOW2
#define FETCH_TEX2(_T, _UV) lerp(tex2D(_T, fuv1), tex2D(_T, fuv2), flowInterp)
#elif _DISTBLEND
#define FETCH_TEX2(_T, _UV) lerp(tex2D(_T, _UV), tex2D(_T, _UV*_DistUVScale2), dist)
#else
#define FETCH_TEX2(_T, _UV) tex2D(_T, _UV)
#endif

#if _FLOW3
#define FETCH_TEX3(_T, _UV) lerp(tex2D(_T, fuv1), tex2D(_T, fuv2), flowInterp)
#elif _DISTBLEND
#define FETCH_TEX3(_T, _UV) lerp(tex2D(_T, _UV), tex2D(_T, _UV*_DistUVScale3), dist)
#else
#define FETCH_TEX3(_T, _UV) tex2D(_T, _UV)
#endif


half HeightBlend(half h1, half h2, half slope, half contrast)
{
   h2 = 1-h2;
   half tween = saturate( ( slope - min( h1, h2 ) ) / max(abs( h1 - h2 ), 0.001)); 
   half threshold = contrast;
   half width = 1.0 - contrast;
   return saturate( ( tween - threshold ) / max(width, 0.001) );
}

void Flow(float2 uv, half2 flow, half speed, float intensity, out float2 uv1, out float2 uv2, out half interp)
{
   float2 flowVector = (flow * 2.0 - 1.0) * intensity;  
   float timeScale = _Time.y * speed;
   float2 phase = frac(float2(timeScale, timeScale + .5));
   uv1 = (uv - flowVector * half2(phase.x, phase.x));
   uv2 = (uv - flowVector * half2(phase.y, phase.y));   
   interp = abs(0.5 - phase.x) / 0.5;
}

PSInput VSMain(appdata_full  v)
{
	PSInput o =(PSInput)0;
	UNITY_INITIALIZE_OUTPUT(PSInput, o);
	UNITY_SETUP_INSTANCE_ID(v);
	UNITY_TRANSFER_INSTANCE_ID(v, o);

	float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
	float3 worldNormal = UnityObjectToWorldNormal(v.normal);
	o.worldPos = worldPos;
	o.worldNormal = worldNormal;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = v.texcoord;
    o.color = v.color;

#if (_FLOW1 || _FLOW2 || _FLOW3)
    o.flowDir.xy = v.texcoord.xy;
    o.flowDir.zw = v.texcoord2.xy;
#endif
    
#if (_FLOW1)
    o.flowDir.xy *= _TexScale1;
#endif
#if (_FLOW2)
    o.flowDir.xy *= _TexScale2;
#endif
#if (_FLOW3)
    o.flowDir.xy *= _TexScale3; 
#endif


#ifdef DYNAMICLIGHTMAP_ON
	o.lightMap.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
#endif

#ifdef LIGHTMAP_ON
	o.lightMap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
#endif

#ifndef LIGHTMAP_ON
	#if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
	o.sh = 0;
		#ifdef VERTEXLIGHT_ON
		o.sh += Shade4PointLights(unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0, unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb, unity_4LightAtten0, worldPos, worldNormal);
		#endif
		o.sh = ShadeSHPerVertex(worldNormal, o.sh);
	#endif
#endif
	UNITY_TRANSFER_SHADOW(o, v.texcoord1.xy);
	UNITY_TRANSFER_FOG(o, o.pos);
	return o;
}

// PS inlucde surface function
void surf(Input IN, inout SurfaceOutputStandard o)
{
	COMPUTEDISTBLEND
// SplatBlendSpecular_1Layer
#ifdef _LAYERONE
	float2 uv1 = IN.uv_Tex1 * _TexScale1;
	INIT_FLOW
	#if _FLOWDRIFT || !_PARALLAXMAP 
		fixed4 c1 = FETCH_TEX1(_Tex1, uv1);
	#elif _DISTBLEND
		fixed4 c1 = lerp(tex2D(_Tex1, uv1), tex2D(_Tex1, uv1*_DistUVScale1), dist);
	#else
		fixed4 c1 = tex2D(_Tex1, uv1);
	#endif

	#if _PARALLAXMAP
		float parallax = _Parallax1;
		float2 offset = ParallaxOffset(c1.a, parallax, IN.worldPos);
		uv1 += offset;
		#if (_FLOW1 || _FLOW2 || _FLOW3)
			fuv1 += offset;
			fuv2 += offset;
		#endif
		c1 = FETCH_TEX1(_Tex1, uv1);
	#endif
	c1 *= _Tint1;

	#if _SPECGLOSSMAP
		fixed4 g1 = FETCH_TEX1(_SpecGlossMap1, uv1);
		o.Smoothness = g1.a;
		o.Metallic = g1.rgb;
	#else
		o.Smoothness = _Glossiness1;
		o.Metallic = _SpecColor1.rgb;
	#endif 

	#if _EMISSION
		fixed4 e1 = FETCH_TEX1(_Emissive1, uv1);
		o.Emission = e1.rgb * _EmissiveMult1;
	#endif

	#if _NORMALMAP
		fixed4 n1 = FETCH_TEX1(_Normal1, uv1);
		o.Normal = UnpackNormal(n1);
	#endif
	o.Albedo = c1.rgb;

// SplatBlendSpecular_2Layer
#elif _LAYERTWO
	float2 uv1 = IN.uv_Tex1 * _TexScale1;
	float2 uv2 = IN.uv_Tex1 * _TexScale2;
	INIT_FLOW
	#if _FLOWDRIFT || !_PARALLAXMAP 
		fixed4 c1 = FETCH_TEX1(_Tex1, uv1);
		fixed4 c2 = FETCH_TEX2(_Tex2, uv2);
	#elif _DISTBLEND
		fixed4 c1 = lerp(tex2D(_Tex1, uv1), tex2D(_Tex1, uv1*_DistUVScale1), dist);
		fixed4 c2 = lerp(tex2D(_Tex2, uv2), tex2D(_Tex2, uv2*_DistUVScale2), dist);
	#else
		fixed4 c1 = tex2D(_Tex1, uv1);
		fixed4 c2 = tex2D(_Tex2, uv2);
	#endif
	half b1 = HeightBlend(c1.a, c2.a, IN.color.r, _Contrast2);
	#if _FLOW2
		b1 *= _FlowAlpha;
		#if _FLOWREFRACTION && _NORMALMAP
			half4 rn = FETCH_TEX2(_Normal2, uv2) - 0.5;
			uv1 += rn.xy * b1 * _FlowRefraction;
			#if !_PARALLAXMAP 
				c1 = FETCH_TEX1(_Tex1, uv1);
			#endif
		#endif
	#endif

	#if _PARALLAXMAP
		float parallax = lerp(_Parallax1, _Parallax2, b1);
		float2 offset = ParallaxOffset(lerp(c1.a, c2.a, b1), parallax, IN.worldPos);
		uv1 += offset;
		uv2 += offset;
		c1 = FETCH_TEX1(_Tex1, uv1);
		c2 = FETCH_TEX2(_Tex2, uv2);
		#if (_FLOW1 || _FLOW2 || _FLOW3)
			fuv1 += offset;
			fuv2 += offset;
		#endif
	#endif

	fixed4 c = lerp(c1 * _Tint1, c2 * _Tint2, b1);
	#if _SPECGLOSSMAP
		fixed4 g1 = FETCH_TEX1(_SpecGlossMap1, uv1);
		fixed4 g2 = FETCH_TEX2(_SpecGlossMap2, uv2);
		fixed4 gf = lerp(g1, g2, b1);
		o.Smoothness = gf.a;
		o.Metallic = gf.rgb;
	#else
		o.Smoothness = lerp(_Glossiness1, _Glossiness2, b1);
		o.Metallic = lerp(_SpecColor1, _SpecColor2, b1).rgb;
	#endif

	#if _EMISSION
		fixed4 e1 = FETCH_TEX1(_Emissive1, uv1);
		fixed4 e2 = FETCH_TEX2(_Emissive2, uv2);
		o.Emission = lerp(e1.rgb * _EmissiveMult1, e2.rgb * _EmissiveMult2, b1);
	#endif

	#if _NORMALMAP
		half4 n1 = FETCH_TEX1(_Normal1, uv1);
		half4 n2 = FETCH_TEX2(_Normal2, uv2);
		o.Normal = UnpackNormal(lerp(n1, n2, b1));
	#endif
	o.Albedo = c.rgb;

// SplatBlendSpecular_3Layer
#elif _LAYERTHREE
	float2 uv1 = IN.uv_Tex1 * _TexScale1;
	float2 uv2 = IN.uv_Tex1 * _TexScale2;
	float2 uv3 = IN.uv_Tex1 * _TexScale3;
	INIT_FLOW

	#if _FLOWDRIFT || !_PARALLAXMAP 
		fixed4 c1 = FETCH_TEX1(_Tex1, uv1);
		fixed4 c2 = FETCH_TEX2(_Tex2, uv2);
		fixed4 c3 = FETCH_TEX3(_Tex3, uv3);
	#elif _DISTBLEND
		fixed4 c1 = lerp(tex2D(_Tex1, uv1), tex2D(_Tex1, uv1*_DistUVScale1), dist);
		fixed4 c2 = lerp(tex2D(_Tex2, uv2), tex2D(_Tex2, uv2*_DistUVScale2), dist);
		fixed4 c3 = lerp(tex2D(_Tex3, uv3), tex2D(_Tex3, uv3*_DistUVScale3), dist);
	#else
		fixed4 c1 = tex2D(_Tex1, uv1);
		fixed4 c2 = tex2D(_Tex2, uv2);
		fixed4 c3 = tex2D(_Tex3, uv3);
	#endif

	half b1 = HeightBlend(c1.a, c2.a, IN.color.r, _Contrast2);
	fixed h1 = lerp(c1.a, c2.a, b1);
	half b2 = HeightBlend(h1, c3.a, IN.color.g, _Contrast3);

	#if _FLOW2
		b1 *= _FlowAlpha;
		#if _FLOWREFRACTION && _NORMALMAP
			half4 rn = FETCH_TEX2(_Normal2, uv2) - 0.5;
			uv1 += rn.xy * b1 * _FlowRefraction;
			#if !_PARALLAXMAP 
				c1 = FETCH_TEX1(_Tex1, uv1);
			#endif
		#endif
	#endif

	#if _FLOW3
		b2 *= _FlowAlpha;
		#if _FLOWREFRACTION && _NORMALMAP
			half4 rn = FETCH_TEX3(_Normal3, uv3) - 0.5;
			uv1 += rn.xy * b1 * _FlowRefraction;
			uv2 += rn.xy * b2 * _FlowRefraction;
			#if !_PARALLAXMAP 
				c1 = FETCH_TEX1(_Tex1, uv1);
				c2 = FETCH_TEX2(_Tex2, uv2);
			#endif
		#endif
	#endif

	#if _PARALLAXMAP
		float parallax = lerp(lerp(_Parallax1, _Parallax2, b1), _Parallax3, b2);
		float2 offset = ParallaxOffset(lerp(lerp(c1.a, c2.a, b1), c3.a, b2), parallax, IN.worldPos);
		uv1 += offset;
		uv2 += offset;
		uv3 += offset;
		c1 = FETCH_TEX1(_Tex1, uv1);
		c2 = FETCH_TEX2(_Tex2, uv2);
		c3 = FETCH_TEX3(_Tex3, uv3);
		#if (_FLOW1 || _FLOW2 || _FLOW3)
			fuv1 += offset;
			fuv2 += offset;
		#endif
	#endif

	fixed4 c = lerp(lerp(c1 * _Tint1, c2 * _Tint2, b1), c3 * _Tint3, b2);

	#if _SPECGLOSSMAP
		fixed4 g1 = FETCH_TEX1(_SpecGlossMap1, uv1);
		fixed4 g2 = FETCH_TEX2(_SpecGlossMap2, uv2);
		fixed4 g3 = FETCH_TEX3(_SpecGlossMap3, uv3);
		fixed4 gf = lerp(lerp(g1, g2, b1), g3, b2);
		o.Smoothness = gf.a;
		o.Metallic = gf.rgb;
	#else
		o.Smoothness = lerp(lerp(_Glossiness1, _Glossiness2, b1), _Glossiness3, b2);
		o.Metallic = lerp(lerp(_SpecColor1, _SpecColor2, b1), _SpecColor3, b2).rgb;
	#endif

	#if _EMISSION
		fixed4 e1 = FETCH_TEX1(_Emissive1, uv1);
		fixed4 e2 = FETCH_TEX2(_Emissive2, uv2);
		fixed4 e3 = FETCH_TEX3(_Emissive3, uv3);
		o.Emission = lerp(lerp(e1.rgb * _EmissiveMult1, e2.rgb * _EmissiveMult2, b1), e3.rgb * _EmissiveMult3, b2);
	#endif

	#if _NORMALMAP
		half4 n1 = (FETCH_TEX1(_Normal1, uv1));
		half4 n2 = (FETCH_TEX2(_Normal2, uv2));
		half4 n3 = (FETCH_TEX3(_Normal3, uv3));
		o.Normal = UnpackNormal(lerp(lerp(n1, n2, b1), n3, b2));
	#endif
	o.Albedo = c.rgb;
#endif

}


fixed4 PSMain(PSInput i) : SV_Target
{
	UNITY_SETUP_INSTANCE_ID(i);
	float3 worldPos = i.worldPos;
	float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
#ifndef USING_DIRECTIONAL_LIGHT
	fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
#else
	fixed3 lightDir = _WorldSpaceLightPos0.xyz;
#endif
	Input surfIN;
	UNITY_INITIALIZE_OUTPUT(Input, surfIN);
	surfIN.uv_Tex1 = i.uv;
	surfIN.color = i.color;

	SurfaceOutputStandard o;
	UNITY_INITIALIZE_OUTPUT(SurfaceOutputStandard, o);
	o.Albedo = 0.0;
	o.Emission = 0.0;
	o.Alpha = 0.0;
	o.Occlusion = 1.0;
	o.Normal = i.worldNormal;
	surf(surfIN, o);
	UNITY_LIGHT_ATTENUATION(atten, i, worldPos)
	half4 color = 0;
	UnityGI gi;
	UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
	gi.indirect.diffuse = 0;
	gi.indirect.specular = 0;
	gi.light.color = _LightColor0.rgb;
	gi.light.dir = lightDir;
	UnityGIInput giInput;
	UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
	giInput.light = gi.light;
	giInput.worldPos = worldPos;
	giInput.worldViewDir = worldViewDir;
	giInput.atten = atten;
#if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
	giInput.lightmapUV = i.lightMap;
#else
	giInput.lightmapUV = 0.0;
#endif
	giInput.ambient.rgb = 0.0;
	giInput.probeHDR[0] = unity_SpecCube0_HDR;
	giInput.probeHDR[1] = unity_SpecCube1_HDR;
#if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
	giInput.boxMin[0] = unity_SpecCube0_BoxMin;
#endif

	// UnityPBSLighting 
	LightingStandard_GI(o, giInput, gi);
	color += LightingStandard(o, worldViewDir, gi);
	UNITY_APPLY_FOG(i.fogCoord, color);
	UNITY_OPAQUE_ALPHA(color.a);
	return color;
}


// @NOTE
// Old Surface Function
void SharedVert (inout appdata_full v, out Input o) 
{
    UNITY_INITIALIZE_OUTPUT(Input, o);
#if (_FLOW1 || _FLOW2 || _FLOW3)
    o.flowDir.xy = v.texcoord.xy;
    o.flowDir.zw = v.texcoord2.xy;
#endif
    
#if (_FLOW1)
    o.flowDir.xy *= _TexScale1;
#endif
#if (_FLOW2)
    o.flowDir.xy *= _TexScale2;
#endif
#if (_FLOW3)
    o.flowDir.xy *= _TexScale3; 
#endif

    o.uv_Tex1 = v.texcoord.xy;
    o.color = v.color;
    float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
    float3 worldNormal = UnityObjectToWorldNormal(v.normal);
    o.worldPos = worldPos;
    o.worldNormal = worldNormal;
}

#endif
