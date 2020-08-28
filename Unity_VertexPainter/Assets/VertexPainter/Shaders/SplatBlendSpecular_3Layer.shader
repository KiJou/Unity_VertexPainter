
Shader "VertexPainter/SplatBlendSpecular_3Layer"
{
	Properties
	{
		[Enum(OFF,0,FRONT,1,BACK,2)] _CullMode("Cull Mode", int) = 2
		// 1Layer
		_Tex1("Albedo + Height", 2D) = "white" {}
		_Tint1("Tint", Color) = (1, 1, 1, 1)
		[NoScaleOffset][Normal]_Normal1("Normal", 2D) = "bump" {}
		_Glossiness1("Smoothness", Range(0,1)) = 0.5
		_SpecColor1("Specular Color", Color) = (0.2, 0.2, 0.2, 0.2)
		[NoScaleOffset]_SpecGlossMap1("Specular/Gloss Map", 2D) = "black" {}
		_Emissive1("Emissive", 2D) = "black" {}
		_EmissiveMult1("Emissive Multiplier", Float) = 1
		_Parallax1("Parallax Height", Range(0.005, 0.08)) = 0.02
		_TexScale1("Texture Scale", Float) = 1
		// 2Layer
		_Tex2("Albedo + Height", 2D) = "white" {}
		_Tint2("Tint", Color) = (1, 1, 1, 1)
		[NoScaleOffset][Normal]_Normal2("Normal", 2D) = "bump" {}
		_Glossiness2("Smoothness", Range(0,1)) = 0.5
		_SpecColor2("Specular Color", Color) = (0.2, 0.2, 0.2, 0.2)
		[NoScaleOffset]_SpecGlossMap2("Specular/Gloss Map", 2D) = "black" {}
		_Metallic2("Metallic", Range(0,1)) = 0.0
		_Emissive2("Emissive", 2D) = "black" {}
		_EmissiveMult2("Emissive Multiplier", Float) = 1
		_Parallax2("Parallax Height", Range(0.005, 0.08)) = 0.02
		_TexScale2("Texture Scale", Float) = 1
		_Contrast2("Contrast", Range(0,0.99)) = 0.5
		// 3Layer
		_Tex3("Albedo + Height", 2D) = "white" {}
		_Tint3("Tint", Color) = (1, 1, 1, 1)
		[NoScaleOffset][Normal]_Normal3("Normal", 2D) = "bump" {}
		_Glossiness3("Smoothness", Range(0,1)) = 0.5
		_SpecColor3("Specular Color", Color) = (0.2, 0.2, 0.2, 0.2)
		[NoScaleOffset]_SpecGlossMap3("Specular/Gloss Map", 2D) = "black" {}
		_Emissive3("Emissive", 2D) = "black" {}
		_EmissiveMult3("Emissive Multiplier", Float) = 1
		_Parallax3("Parallax Height", Range(0.005, 0.08)) = 0.02
		_TexScale3("Texture Scale", Float) = 1
		_Contrast3("Contrast", Range(0,0.99)) = 0.5

		_FlowSpeed("Flow Speed", Float) = 0
		_FlowIntensity("Flow Intensity", Float) = 1
		_FlowAlpha("Flow Alpha", Range(0, 1)) = 1
		_FlowRefraction("Flow Refraction", Range(0, 0.3)) = 0.04
		_DistBlendMin("Distance Blend Begin", Float) = 0
		_DistBlendMax("Distance Blend Max", Float) = 100
		_DistUVScale1("Distance UV Scale", Float) = 0.5
		_DistUVScale2("Distance UV Scale", Float) = 0.5
		_DistUVScale3("Distance UV Scale", Float) = 0.5
	}

	SubShader
	{
		Tags { "RenderType" = "Opaque" "PerformanceChecks" = "False" }

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			Cull[_CullMode]
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex VSMain
			#pragma fragment PSMain
			#pragma multi_compile_instancing
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase
			#pragma shader_feature _ _PARALLAXMAP
			#pragma shader_feature _ _NORMALMAP
			#pragma shader_feature _ _SPECGLOSSMAP
			#pragma shader_feature _ _EMISSION
			#pragma shader_feature _ _FLOW1 _FLOW2 _FLOW3
			#pragma shader_feature _ _FLOWDRIFT 
			#pragma shader_feature _ _FLOWREFRACTION
			#pragma shader_feature _ _DISTBLEND
			#pragma multi_compile _LAYERTHREE
			#include "UnityCG.cginc"
			#include "SplatBlend_Forward.cginc"
			ENDCG
		}

		UsePass "VertexPainter/SplatBlendSpecular_1Layer/FORWARD_DELTA"
		UsePass "VertexPainter/SplatBlendSpecular_1Layer/SHADOW_CASTER"
		UsePass "VertexPainter/SplatBlendSpecular_1Layer/META"
	}
	CustomEditor "VertexPainter.CustomShaderGUI"
	FallBack Off
}
