using UnityEngine;
using System.Collections;
using UnityEditor;


namespace VertexPainter
{
	[CreateAssetMenu(menuName = "Vertex Painter Brush/Noise Brush", fileName = "noise_brush")]
	public class VertexPainterNoiseBrush : VertexPainterCustomBrush
	{
		[System.Serializable]
		public class BrushData
		{
			public float frequency = 10;
			public float amplitude = 1;
		}
		public BrushData brushData = new BrushData();

		public override Channels GetChannels()
		{
			return Channels.Colors;
		}

		public override Color GetPreviewColor()
		{
			return Color.yellow;
		}

		public override object GetBrushObject()
		{
			return brushData;
		}

		public override void DrawGUI()
		{
			brushData.frequency = EditorGUILayout.Slider("frequency", brushData.frequency, 0.01f, 100.0f);
			brushData.amplitude = EditorGUILayout.Slider("amplitude", brushData.amplitude, 0.1f, 10.0f);
		}

		void LerpFunc(PaintJob j, int idx, ref object val, float r)
		{
			BrushData bd = val as BrushData;
			var s = j.stream;
			Vector3 pos = j.GetPosition(idx);
			pos = j.renderer.localToWorldMatrix.MultiplyPoint(pos);
			pos.x *= bd.frequency;
			pos.y *= bd.frequency;
			pos.z *= bd.frequency;
			float noise = 0.5f * (0.5f * SimplexNoise.Noise.Generate(pos.x, pos.y, pos.z) + 0.5f);
			noise += 0.25f * (0.5f * SimplexNoise.Noise.Generate(pos.y * 2.031f, pos.z * 2.031f, pos.x * 2.031f) + 0.5f);
			noise += 0.25f * (0.5f * SimplexNoise.Noise.Generate(pos.z * 4.01f, pos.x * 4.01f, pos.y * 4.01f) + 0.5f);
			noise *= bd.amplitude;
			// lerp the noise in
			Color c = s.colors[idx];
			c.r = Mathf.Lerp(c.r, noise, r);
			c.g = Mathf.Lerp(c.g, noise, r);
			c.b = Mathf.Lerp(c.b, noise, r);

			s.colors[idx] = c;
		}

		public override VertexPainterWindow.Lerper GetLerper()
		{
			return LerpFunc;
		}

	}
}
