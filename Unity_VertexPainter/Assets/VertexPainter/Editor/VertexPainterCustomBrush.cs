using UnityEngine;
using System.Collections;

namespace VertexPainter
{
	public class VertexPainterCustomBrush : ScriptableObject
	{
#if UNITY_EDITOR
		public enum Channels
		{
			Colors = 1,
			UV0 = 2,
			UV1 = 4,
			UV2 = 8,
			UV3 = 16,
			Normals = 32,
			Positions = 64
		}

		public virtual Color GetPreviewColor()
		{
			return Color.yellow;
		}

		public virtual Channels GetChannels()
		{
			Debug.LogError("GetChannels not implimented in custom brush!");
			return 0;
		}

		public virtual VertexPainterWindow.Lerper GetLerper()
		{
			Debug.LogError("Lerper not implimented in custom brush!");
			return null;
		}

		public virtual object GetBrushObject()
		{
			Debug.LogError("GetBrushObject not implimented in custom brush");
			return null;
		}

		public virtual void BeginApplyStroke(Ray ray)
		{
		}

		public virtual void DrawGUI()
		{
		}
#endif
	}
}
