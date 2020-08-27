Shader "G2Studios/VertexPainter/Standard"
{
    Properties
    {
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Factor", Float) = 1.0
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Factor", Float) = 0.0
        [Enum(Off, 0, On, 1)] _ZWrite("ZWrite", Float) = 1.0

        [HDR]_Color("Color", Color) = (1,1,1,1)
        _MainTex("Albedo", 2D) = "white" {}
        _SubTex("SubTex", 2D) = "white" {}
        _BlendWeight("BlendWeight",Range(0, 1)) = 0
        _Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
        _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
    }

CGINCLUDE
    #define UNITY_SETUP_BRDF_INPUT MetallicSetup
ENDCG

    SubShader
    {
        Tags { "RenderType" = "Opaque" "PerformanceChecks" = "False" }
        LOD 100

        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }
            Cull Back

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #pragma multi_compile_instancing
            #pragma multi_compile_fog
            #pragma multi_compile_fwdbase
            #include "HLSLSupport.cginc"
            #include "UnityShaderVariables.cginc"
            #include "UnityShaderUtilities.cginc"

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "UnityPBSLighting.cginc"
            #include "AutoLight.cginc"

            sampler2D _MainTex; float4 _MainTex_ST;
            sampler2D _SubTex; float4 _SubTex_ST;
            sampler2D _BumpMap;
            half _Glossiness;
            half _Metallic;
            fixed4 _Color;
            half _BlendWeight;
            //half _BumpScale;

            struct Input
            {
                float2 uv_MainTex;
            };

            struct appdata
            {
                float vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                UNITY_POSITION(pos);
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                float4 lmap : TEXCOORD3;
                UNITY_SHADOW_COORDS(4)
                UNITY_FOG_COORDS(5)
#ifndef LIGHTMAP_ON
    #if UNITY_SHOULD_SAMPLE_SH
                    half3 sh : TEXCOORD6;
    #endif
#endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            void surf(Input IN, inout SurfaceOutputStandard o)
            {
                fixed4 col = tex2D(_MainTex, IN.uv_MainTex) * _Color;
                fixed4 sub = tex2D(_SubTex, IN.uv_MainTex);
                o.Albedo = col * (1 - _BlendWeight) + sub * _BlendWeight;
                o.Metallic = _Metallic;
                o.Smoothness = _Glossiness;
                o.Alpha = col.a;
                //fixed4 n   = tex2D(_BumpMap, IN.uv_MainTex);
                //o.Normal   = UnpackScaleNormal(n, _BumpScale);
            }

            v2f vert(appdata_full v)
            {
                v2f o = (v2f)0;
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = worldPos;
                o.worldNormal = worldNormal;
#ifdef DYNAMICLIGHTMAP_ON
                o.lmap.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
#endif
#ifdef LIGHTMAP_ON
                o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
#endif

#ifndef LIGHTMAP_ON
    #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
                o.sh = 0;
        #ifdef VERTEXLIGHT_ON
                o.sh += Shade4PointLights(
                    unity_4LightPosX0,
                    unity_4LightPosY0,
                    unity_4LightPosZ0,
                    unity_LightColor[0].rgb,
                    unity_LightColor[1].rgb,
                    unity_LightColor[2].rgb,
                    unity_LightColor[3].rgb,
                    unity_4LightAtten0,
                    worldPos,
                    worldNormal);
        #endif
                o.sh = ShadeSHPerVertex(worldNormal, o.sh);
    #endif
#endif
                UNITY_TRANSFER_SHADOW(o,v.texcoord1.xy);
                UNITY_TRANSFER_FOG(o,o.pos);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
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
                surfIN.uv_MainTex.x = 1.0;
                surfIN.uv_MainTex = i.uv.xy;
                SurfaceOutputStandard o;
                UNITY_INITIALIZE_OUTPUT(SurfaceOutputStandard, o);
                o.Albedo = 0.0;
                o.Emission = 0.0;
                o.Alpha = 0.0;
                o.Occlusion = 1.0;
                o.Normal = i.worldNormal;
                surf(surfIN, o);
                UNITY_LIGHT_ATTENUATION(atten, i, worldPos)
                fixed4 c = 0;
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
                giInput.lightmapUV = i.lmap;
#else
                giInput.lightmapUV = 0.0;
#endif
                giInput.ambient.rgb = 0.0;

                giInput.probeHDR[0] = unity_SpecCube0_HDR;
                giInput.probeHDR[1] = unity_SpecCube1_HDR;
#if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
                giInput.boxMin[0] = unity_SpecCube0_BoxMin;
#endif
                LightingStandard_GI(o, giInput, gi);
                c += LightingStandard(o, worldViewDir, gi);
                UNITY_APPLY_FOG(i.fogCoord, c);
                UNITY_OPAQUE_ALPHA(c.a);
                return c;
            }
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
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #pragma multi_compile_fwdadd
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_fog
            #include "HLSLSupport.cginc"
            #include "UnityShaderVariables.cginc"
            #include "UnityShaderUtilities.cginc"
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "UnityPBSLighting.cginc"
            #include "AutoLight.cginc"

            sampler2D _MainTex; float4 _MainTex_ST;
            half _Glossiness;
            half _Metallic;
            fixed4 _Color;

            struct Input
            {
                float2 uv_MainTex;
            };

            struct v2f
            {
                UNITY_POSITION(pos);
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                UNITY_SHADOW_COORDS(3)
                UNITY_FOG_COORDS(4)
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            void surf(Input IN, inout SurfaceOutputStandard o)
            {
                fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
                o.Albedo = c.rgb;
                o.Metallic = _Metallic;
                o.Smoothness = _Glossiness;
                o.Alpha = c.a;
            }

            v2f vert(appdata_full v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f,o);
                UNITY_TRANSFER_INSTANCE_ID(v,o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                UNITY_TRANSFER_SHADOW(o,v.texcoord1.xy);
                UNITY_TRANSFER_FOG(o,o.pos);
                return o;
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(IN);
                Input surfIN;
                UNITY_INITIALIZE_OUTPUT(Input,surfIN);
                surfIN.uv_MainTex.x = 1.0;
                surfIN.uv_MainTex = IN.uv.xy;
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
                fixed4 c = 0;
                UnityGI gi;
                UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
                gi.indirect.diffuse = 0;
                gi.indirect.specular = 0;
                gi.light.color = _LightColor0.rgb;
                gi.light.dir = lightDir;
                gi.light.color *= atten;
                c += LightingStandard(o, worldViewDir, gi);
                c.a = 0.0;
                UNITY_APPLY_FOG(IN.fogCoord, c);
                UNITY_OPAQUE_ALPHA(c.a);
                return c;
            }
            ENDCG
        }

        Pass
        {
            Name "SHADOWCASTER"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On ZTest LEqual

            CGPROGRAM
            #pragma target 3.0
            #pragma shader_feature_local _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing
            #pragma vertex vertShadowCaster
            #pragma fragment fragShadowCaster

            #include "UnityCG.cginc"
            #include "UnityShaderVariables.cginc"
            #include "UnityStandardConfig.cginc"
            #include "UnityStandardUtils.cginc"

            #if (defined(_ALPHABLEND_ON) || defined(_ALPHAPREMULTIPLY_ON)) && defined(UNITY_USE_DITHER_MASK_FOR_ALPHABLENDED_SHADOWS)
                #define UNITY_STANDARD_USE_DITHER_MASK 1
            #endif

            #if defined(_ALPHATEST_ON) || defined(_ALPHABLEND_ON) || defined(_ALPHAPREMULTIPLY_ON)
                #define UNITY_STANDARD_USE_SHADOW_UVS 1
            #endif

            #if !defined(V2F_SHADOW_CASTER_NOPOS_IS_EMPTY) || defined(UNITY_STANDARD_USE_SHADOW_UVS)
                #define UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT 1
            #endif

            #ifdef UNITY_STEREO_INSTANCING_ENABLED
                #define UNITY_STANDARD_USE_STEREO_SHADOW_OUTPUT_STRUCT 1
            #endif

            half4 _Color;
            half _Cutoff;
            sampler2D _MainTex; float4 _MainTex_ST;
            #ifdef UNITY_STANDARD_USE_DITHER_MASK
                sampler3D  _DitherMaskLOD;
            #endif

            half4 _SpecColor;
            half _Metallic;
            uniform half4 _ShadowColor;

            #ifdef _SPECGLOSSMAP
                sampler2D   _SpecGlossMap;
            #endif

            half MetallicSetup_ShadowGetOneMinusReflectivity(half2 uv)
            {
                half metallicity = _Metallic;
                return OneMinusReflectivityFromMetallic(metallicity);
            }

            half RoughnessSetup_ShadowGetOneMinusReflectivity(half2 uv)
            {
                half metallicity = _Metallic;
                return OneMinusReflectivityFromMetallic(metallicity);
            }

            half SpecularSetup_ShadowGetOneMinusReflectivity(half2 uv)
            {
                half3 specColor = _SpecColor.rgb;
                return (1 - SpecularStrength(specColor));
            }

            struct VertexInput
            {
                float4 vertex   : POSITION;
                float3 normal   : NORMAL;
                float2 uv0      : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            #ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
            struct VertexOutputShadowCaster
            {
                V2F_SHADOW_CASTER_NOPOS
                #if defined(UNITY_STANDARD_USE_SHADOW_UVS)
                    float2 tex : TEXCOORD1;

                    #if defined(_PARALLAXMAP)
                        half3 viewDirForParallax : TEXCOORD2;
                    #endif
                #endif
            };
            #endif

            void vertShadowCaster(VertexInput v, out float4 opos : SV_POSITION
                #ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
                , out VertexOutputShadowCaster o
                #endif
            )
            {
                UNITY_SETUP_INSTANCE_ID(v);
                TRANSFER_SHADOW_CASTER_NOPOS(o,opos)
            }

            half4 fragShadowCaster(UNITY_POSITION(vpos)
                #ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
                    , VertexOutputShadowCaster i
                #endif
                ) : SV_Target
            {

                #if defined(UNITY_STANDARD_USE_SHADOW_UVS)
                    half alpha = tex2D(_MainTex, i.tex.xy).a * _Color.a;
                    #if defined(_ALPHATEST_ON)
                        clip(alpha - _Cutoff);
                    #endif
                    #if defined(_ALPHABLEND_ON) || defined(_ALPHAPREMULTIPLY_ON)
                        #if defined(UNITY_STANDARD_USE_DITHER_MASK)
                            #ifdef LOD_FADE_CROSSFADE
                                #define _LOD_FADE_ON_ALPHA
                                alpha *= unity_LODFade.y;
                            #endif
                            half alphaRef = tex3D(_DitherMaskLOD, float3(vpos.xy*0.25,alpha*0.9375)).a;
                            clip(alphaRef - 0.01);
                        #else
                            clip(alpha - _Cutoff);
                        #endif
                    #endif
                #endif
                SHADOW_CASTER_FRAGMENT(i)
            }
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
            #include "UnityCG.cginc"
            #include "UnityStandardInput.cginc"
            #include "UnityMetaPass.cginc"
            #include "UnityStandardCore.cginc"

            struct v2f_meta
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
            #ifdef EDITOR_VISUALIZATION
                float2 vizUV        : TEXCOORD1;
                float4 lightCoord   : TEXCOORD2;
            #endif
            };

            v2f_meta vert_meta(VertexInput v)
            {
                v2f_meta o;
                o.pos = UnityMetaVertexPosition(v.vertex, v.uv1.xy, v.uv2.xy, unity_LightmapST, unity_DynamicLightmapST);
                o.uv = TexCoords(v);
            #ifdef EDITOR_VISUALIZATION
                o.vizUV = 0;
                o.lightCoord = 0;
                if (unity_VisualizationMode == EDITORVIZ_TEXTURE)
                {
                    o.vizUV = UnityMetaVizUV(unity_EditorViz_UVIndex, v.uv0.xy, v.uv1.xy, v.uv2.xy, unity_EditorViz_Texture_ST);
                }
                else if (unity_VisualizationMode == EDITORVIZ_SHOWLIGHTMASK)
                {
                    o.vizUV = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
                    o.lightCoord = mul(unity_EditorViz_WorldToLight, mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1)));
                }
            #endif
                return o;
            }

            half3 UnityLightmappingAlbedo(half3 diffuse, half3 specular, half smoothness)
            {
                half roughness = SmoothnessToRoughness(smoothness);
                half3 res = diffuse;
                res += specular * roughness * 0.5;
                return res;
            }

            float4 frag_meta(v2f_meta i) : SV_Target
            {
                FragmentCommonData data = UNITY_SETUP_BRDF_INPUT(i.uv);

                UnityMetaInput o;
                UNITY_INITIALIZE_OUTPUT(UnityMetaInput, o);
            #ifdef EDITOR_VISUALIZATION
                o.Albedo = data.diffColor;
                o.VizUV = i.vizUV;
                o.LightCoord = i.lightCoord;
            #else
                o.Albedo = UnityLightmappingAlbedo(data.diffColor, data.specColor, data.smoothness);
            #endif
                o.SpecularColor = data.specColor;
                o.Emission = Emission(i.uv.xy);
                return UnityMetaFragment(o);
            }
            ENDCG
        }
    }
    FallBack "VertexLit"
}
