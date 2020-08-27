using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;

namespace VertexPainter
{
	[System.Serializable]
	public class SaveMeshes : IVertexPainterUtility
	{
		public string GetName()
		{
			return "Save Meshes";
		}

		public bool GetEnable()
		{
			return true;
		}

		public void OnGUI(PaintJob[] jobs)
		{
			EditorGUILayout.BeginHorizontal();
			EditorGUILayout.Space();
			if (GUILayout.Button("Save Mesh", GUILayout.Width(200f), GUILayout.Height(30f)))
			{
				VertexPainterUtilities.SaveMesh(jobs);
			}

			EditorGUILayout.Space();
			EditorGUILayout.EndHorizontal();
		}
	}
}

