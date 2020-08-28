using System.Collections;
using UnityEditor;
using System.Collections.Generic;


namespace VertexPainter
{
	/// <summary>
	/// GetWindow Class
	/// </summary>
	public partial class VertexPainterWindow : EditorWindow
	{
		[MenuItem("Custom/Vertex Painter")]
		public static void ShowWindow()
		{
			var window = GetWindow<VertexPainterWindow>();
			window.InitMeshes();
			window.Show();
		}
	}
}
