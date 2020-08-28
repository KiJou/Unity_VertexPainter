using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;
using System.Linq;

namespace VertexPainter
{
	public class CustomShaderGUI : ShaderGUI
	{
		public enum CullingMode
		{
			CullingOff,
			FrontCulling,
			BackCulling
		}

		public enum FlowChannel
		{
			None = 0,
			One,
			Two,
			Three,
		}

		private static readonly string[] CHANNEL_NAMES = new string[]
		{
			"None",
			"One",
			"Two",
			"Three",
		};

		private bool[] layerFoldOuts = new bool[CHANNEL_NAMES.Length];

		private CullingMode cullingMode;

		private static int GetLayerCount(string shaderName)
		{
			int layerCount = (int)FlowChannel.None;
			if (shaderName == "VertexPainter/Surface_1Layer")
			{
				layerCount = (int)FlowChannel.One;
			}
			else if (shaderName == "VertexPainter/Surface_2Layer")
			{
				layerCount = (int)FlowChannel.Two;
			}
			else if (shaderName == "VertexPainter/Surface_3Layer")
			{
				layerCount = (int)FlowChannel.Three;
			}
			return layerCount;
		}

		private static FlowChannel GetFlowChannel(string[] keyWords)
		{
			FlowChannel flowChannel = FlowChannel.None;
			if (keyWords.Contains("_FLOW1"))
			{
				flowChannel = FlowChannel.One;
			}
			if (keyWords.Contains("_FLOW2"))
			{
				flowChannel = FlowChannel.Two;
			}
			if (keyWords.Contains("_FLOW3"))
			{
				flowChannel = FlowChannel.Three;
			}
			return flowChannel;
		}

		private static bool Foldout(bool display, string title)
		{
			var style = new GUIStyle("ShurikenModuleTitle");
			style.font = new GUIStyle(EditorStyles.boldLabel).font;
			style.border = new RectOffset(15, 7, 4, 4);
			style.fixedHeight = 22;
			style.contentOffset = new Vector2(20f, -2f);
			var rect = GUILayoutUtility.GetRect(16f, 22f, style);
			GUI.Box(rect, title, style);
			var e = Event.current;
			var toggleRect = new Rect(rect.x + 4f, rect.y + 2f, 13f, 13f);
			if (e.type == EventType.Repaint)
			{
				EditorStyles.foldout.Draw(toggleRect, false, false, display, false);
			}
			if (e.type == EventType.MouseDown && rect.Contains(e.mousePosition))
			{
				display = !display;
				e.Use();
			}
			return display;
		}

		public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
		{
			Material targetMat = materialEditor.target as Material;
			string[] keyWords = targetMat.shaderKeywords;
			int layerCount = GetLayerCount(targetMat.shader.name);

			FlowChannel flowChannel = GetFlowChannel(keyWords);
			bool flowDrift = keyWords.Contains("_FLOWDRIFT");
			bool flowRefraction = keyWords.Contains("_FLOWREFRACTION");
			bool parallax = keyWords.Contains("_PARALLAXMAP");
			bool hasGloss = (HasTexture(layerCount, targetMat, "_GlossinessTex"));
			bool hasSpec = (HasTexture(layerCount, targetMat, "_SpecGlossMap"));
			bool hasEmis = (HasTexture(layerCount, targetMat, "_Emissive"));
			bool hasDistBlend = keyWords.Contains("_DISTBLEND");

			EditorGUI.BeginChangeCheck();

			int oldLayerCount = layerCount;
			layerCount = EditorGUILayout.IntField("Layer Count", layerCount);
			if (oldLayerCount != layerCount)
			{
				if (layerCount < 1)
				{
					layerCount = 1;
				}
				if (layerCount > 3)
				{
					layerCount = 3;
				}

				targetMat.shader = Shader.Find("VertexPainter/Surface_" + layerCount + "Layer");
				return;
			}

			EditorGUILayout.Space();
			GUI_SetCullingMode(targetMat);

			parallax = EditorGUILayout.Toggle("Parallax Offset", parallax);
			hasDistBlend = EditorGUILayout.Toggle("UV Scale in distance", hasDistBlend);
			var distBlendMin = FindProperty("_DistBlendMin", props);
			var distBlendMax = FindProperty("_DistBlendMax", props);

			if (hasDistBlend)
			{
				materialEditor.ShaderProperty(distBlendMin, "Distance Blend Min");
				materialEditor.ShaderProperty(distBlendMax, "Distance Blend Max");

				if (distBlendMin.floatValue > distBlendMax.floatValue)
				{
					distBlendMax.floatValue = distBlendMin.floatValue;
				}

				if (distBlendMax.floatValue <= 1)
				{
					distBlendMax.floatValue = 1;
				}
			}

			// Setting LayerGUI
			EditorGUILayout.Space();
			for (int i = 0; i < layerCount; ++i)
			{
				layerFoldOuts[i] = Foldout(layerFoldOuts[i], "Layer " + (i + 1) + " Setting");
				if (layerFoldOuts[i])
				{
					EditorGUI.indentLevel++;
					EditorGUILayout.Space();
					DrawLayer(materialEditor, i + 1, props, keyWords, hasGloss, hasSpec, parallax, hasEmis, hasDistBlend);
					EditorGUI.indentLevel--;
				}
			}
			EditorGUILayout.Space();

			flowChannel = (FlowChannel)EditorGUILayout.Popup((int)flowChannel, CHANNEL_NAMES);
			if (flowChannel != FlowChannel.None)
			{
				var flowSpeed = FindProperty("_FlowSpeed", props);
				var flowIntensity = FindProperty("_FlowIntensity", props);
				var flowAlpha = FindProperty("_FlowAlpha", props);
				var flowRefract = FindProperty("_FlowRefraction", props);

				materialEditor.ShaderProperty(flowSpeed, "Flow Speed");
				materialEditor.ShaderProperty(flowIntensity, "Flow Intensity");
				materialEditor.ShaderProperty(flowAlpha, "Flow Alpha");
				if (layerCount > 1)
				{
					flowRefraction = EditorGUILayout.Toggle("Flow Refraction", flowRefraction);
					if (flowRefraction)
					{
						materialEditor.ShaderProperty(flowRefract, "Refraction Amount");
					}
				}
				flowDrift = EditorGUILayout.Toggle("Flow Drift", flowDrift);
			}
			if (EditorGUI.EndChangeCheck())
			{
				var newKeywords = new List<string>();
				newKeywords.Add("_LAYERS" + layerCount.ToString());
				if (hasDistBlend)
				{
					newKeywords.Add("_DISTBLEND");
				}
				if (parallax)
				{
					newKeywords.Add("_PARALLAXMAP");
				}
				if (HasTexture(layerCount, targetMat, "_Normal"))
				{
					newKeywords.Add("_NORMALMAP");
				}
				if (hasSpec)
				{
					newKeywords.Add("_SPECGLOSSMAP");
				}
				if (hasEmis)
				{
					newKeywords.Add("_EMISSION");
				}
				if (flowChannel != FlowChannel.None)
				{
					newKeywords.Add("_FLOW" + (int)flowChannel);
				}
				if (flowDrift)
				{
					newKeywords.Add("_FLOWDRIFT");
				}
				if (flowRefraction && layerCount > 1)
				{
					newKeywords.Add("_FLOWREFRACTION");
				}
				targetMat.shaderKeywords = newKeywords.ToArray();
				EditorUtility.SetDirty(targetMat);
			}
		}

		private void DrawLayer(MaterialEditor editor, int i, MaterialProperty[] props, string[] keyWords, bool hasGloss, bool hasSpec, bool isParallax, bool hasEmis, bool hasDistBlend)
		{
			EditorGUIUtility.labelWidth = 0f;
			var albedoMap = FindProperty("_Tex" + i, props);
			var tint = FindProperty("_Tint" + i, props);
			var normalMap = FindProperty("_Normal" + i, props);
			var smoothness = FindProperty("_Glossiness" + i, props);
			//var glossinessMap = FindProperty("_GlossinessTex" + i, props, false);
			//var metallic = FindProperty("_Metallic" + i, props, false);
			var emissionTex = FindProperty("_Emissive" + i, props);
			var emissionMult = FindProperty("_EmissiveMult" + i, props);
			var parallax = FindProperty("_Parallax" + i, props);
			var texScale = FindProperty("_TexScale" + i, props);
			var specMap = FindProperty("_SpecGlossMap" + i, props, false);
			var specColor = FindProperty("_SpecColor" + i, props, false);
			var distUVScale = FindProperty("_DistUVScale" + i, props, false);

			editor.TexturePropertySingleLine(new GUIContent("Base Texture"), albedoMap, tint);
			editor.TexturePropertySingleLine(new GUIContent("Specular(RGB)/Gloss(A)"), specMap, specColor);
			editor.TexturePropertySingleLine(new GUIContent("Normal"), normalMap);
			editor.TexturePropertySingleLine(new GUIContent("Emission"), emissionTex);
			editor.ShaderProperty(smoothness, "Smoothness");
			editor.ShaderProperty(emissionMult, "Emissive Multiplier");
			editor.ShaderProperty(texScale, "Texture Scale");

			if (hasDistBlend)
			{
				editor.ShaderProperty(distUVScale, "Distance UV Scale");
			}
			if (isParallax)
			{
				editor.ShaderProperty(parallax, "Parallax Height");
			}

			if (i > 1)
			{
				editor.ShaderProperty(FindProperty("_Contrast" + i, props), "Interpolation Contrast");
			}
		}

		private void GUI_SetCullingMode(Material material)
		{
			int cullMode = material.GetInt("_CullMode");
			if ((int)CullingMode.CullingOff == cullMode)
			{
				cullingMode = CullingMode.CullingOff;
			}
			else if ((int)CullingMode.FrontCulling == cullMode)
			{
				cullingMode = CullingMode.FrontCulling;
			}
			else
			{
				cullingMode = CullingMode.BackCulling;
			}
			cullingMode = (CullingMode)EditorGUILayout.EnumPopup("Culling Mode", cullingMode);
			if (cullingMode == CullingMode.CullingOff)
			{
				material.SetInt("_CullMode", 0);
			}
			else if (cullingMode == CullingMode.FrontCulling)
			{
				material.SetInt("_CullMode", 1);
			}
			else
			{
				material.SetInt("_CullMode", 2);
			}
		}

		private bool HasTexture(int numLayers, Material mat, string key)
		{
			for (int i = 0; i < numLayers; ++i)
			{
				int index = i + 1;
				string prop = key + index;
				if (mat.HasProperty(prop) && mat.GetTexture(prop) != null)
				{
					return true;
				}
			}
			return false;
		}

	}

}

