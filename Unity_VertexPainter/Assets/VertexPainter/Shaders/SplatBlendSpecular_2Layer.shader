Shader "G2Studios/VertexPainter/SplatBlendSpecular_2Layer"
{
    Properties
    {
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

        _Tex2("Albedo + Height", 2D) = "white" {}
        _Tint2("Tint", Color) = (1, 1, 1, 1)
        [NoScaleOffset][Normal]_Normal2("Normal", 2D) = "bump" {}
        _Glossiness2("Smoothness", Range(0,1)) = 0.5
        _SpecColor2("Specular Color", Color) = (0.2, 0.2, 0.2, 0.2)
        [NoScaleOffset]_SpecGlossMap2("Specular/Gloss Map", 2D) = "black" {}
        _Emissive2("Emissive", 2D) = "black" {}
        _EmissiveMult2("Emissive Multiplier", Float) = 1
        _Parallax2("Parallax Height", Range(0.005, 0.08)) = 0.02
        _TexScale2("Texture Scale", Float) = 1
        _Contrast2("Contrast", Range(0,0.99)) = 0.5

        _FlowSpeed("Flow Speed", Float) = 0
        _FlowIntensity("Flow Intensity", Float) = 1
        _FlowAlpha("Flow Alpha", Range(0, 1)) = 1
        _FlowRefraction("Flow Refraction", Range(0, 0.3)) = 0.04

        _DistBlendMin("Distance Blend Begin", Float) = 0
        _DistBlendMax("Distance Blend Max", Float) = 100
        _DistUVScale1("Distance UV Scale", Float) = 0.5
        _DistUVScale2("Distance UV Scale", Float) = 0.5
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "PerformanceChecks" = "False" }
        LOD 100

        CGPROGRAM

        #pragma surface surf Standard vertex:vert fullforwardshadows
        #pragma shader_feature __ _PARALLAXMAP
        #pragma shader_feature __ _NORMALMAP
        #pragma shader_feature __ _SPECGLOSSMAP
        #pragma shader_feature __ _EMISSION
        #pragma shader_feature __ _FLOW1 _FLOW2 
        #pragma shader_feature __ _FLOWDRIFT 
        #pragma shader_feature __ _FLOWREFRACTION
        #pragma shader_feature __ _DISTBLEND
        #pragma target 3.0
        #include "SplatBlend_Shared.cginc"

        void vert(inout appdata_full v, out Input o)
        {
            SharedVert(v,o);
        }

        void surf(Input IN, inout SurfaceOutputStandard o)
        {
            COMPUTEDISTBLEND

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

        }
        ENDCG
        UsePass "G2Studios/VertexPainter/Standard/FORWARD_DELTA"
        UsePass "G2Studios/VertexPainter/Standard/SHADOWCASTER"
        UsePass "G2Studios/VertexPainter/Standard/META"
    }
    CustomEditor "SplatMapShaderGUI"
    FallBack "Diffuse"
}