using UnityEngine;
using System.Collections;
using UnityEditor;

namespace VertexPainter
{
	public interface IVertexPainterUtility
	{
		string GetName();
		void OnGUI(PaintJob[] jobs);

		bool GetEnable();
	}
}