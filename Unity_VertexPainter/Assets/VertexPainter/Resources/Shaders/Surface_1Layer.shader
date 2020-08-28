
Shader "VertexPainter/Surface_1Layer"
{
	Properties
	{
		[Enum(OFF,0,FRONT,1,BACK,2)] _CullMode("Cull Mode", int) = 2
		// 1Layer
		_Tex1("Base Texture", 2D) = "white" {}
		_Tint1("Base Color", Color) = (1, 1, 1, 1)
		[NoScaleOffset][Normal]_Normal1("Normal", 2D) = "bump" {}
		_Glossiness1("Smoothness", Range(0,1)) = 0.5
		_SpecColor1("Specular Color", Color) = (0.2, 0.2, 0.2, 0.2)
		[NoScaleOffset]_SpecGlossMap1("Specular/Gloss Map", 2D) = "black" {}
		_Emissive1("Emissive", 2D) = "black" {}
		_EmissiveMult1("Emissive Multiplier", Float) = 1
		_Parallax1("Parallax Height", Range(0.005, 0.08)) = 0.02
		_TexScale1("Texture Scale", Float) = 1

		_FlowSpeed("Flow Speed", Float) = 0
		_FlowIntensity("Flow Intensity", Float) = 1
		_FlowAlpha("Flow Alpha", Range(0, 1)) = 1
		_FlowRefraction("Flow Refraction", Range(0, 0.3)) = 0.04
		_DistBlendMin("Distance Blend Begin", Float) = 0
		_DistBlendMax("Distance Blend Max", Float) = 100
		_DistUVScale1("Distance UV Scale", Float) = 0.5
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
			#pragma shader_feature _ _FLOW1
			#pragma shader_feature _ _FLOWDRIFT 
			#pragma shader_feature _ _FLOWREFRACTION
			#pragma shader_feature _ _DISTBLEND
			#pragma multi_compile _LAYERONE
			#include "Surface_Forward.cginc"
			ENDCG
		}

		Pass
		{
			Name "FORWARD_DELTA"
			Tags { "LightMode" = "ForwardAdd" }
			ZWrite Off
			Blend One One
			Fog { Color(0,0,0,0) }
			ZTest LEqual

			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			#pragma target 3.0
			#pragma multi_compile_fwdadd
			#pragma multi_compile_fwdadd_fullshadows
			#pragma multi_compile_fog
			#include "Surface_ForwardAdd.cginc"
			ENDCG
		}

		Pass
		{
			Name "SHADOW_CASTER"
			Tags { "LightMode" = "ShadowCaster" }
			ZWrite On ZTest LEqual
			CGPROGRAM
			#pragma target 3.0
			#pragma shader_feature_local _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			#pragma multi_compile_shadowcaster
			#pragma multi_compile_instancing
			#pragma vertex vertShadowCaster
			#pragma fragment fragShadowCaster
			#include "UnityStandardShadow.cginc"
			ENDCG
		}

		Pass
		{
			Name "META"
			Tags { "LightMode" = "Meta" }
			Cull Off
			CGPROGRAM
			#pragma vertex vert_meta
			#pragma fragment frag_meta
			#pragma shader_feature _EMISSION
			#pragma shader_feature_local _METALLICGLOSSMAP
			#pragma shader_feature_local _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			#pragma shader_feature_local _DETAIL_MULX2
			#pragma shader_feature EDITOR_VISUALIZATION
			#include "UnityStandardMeta.cginc"
			ENDCG
		}

	}
	CustomEditor "VertexPainter.CustomShaderGUI"
	FallBack Off
}
