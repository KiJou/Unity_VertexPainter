using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;

namespace VertexPainter
{
	[System.Serializable]
	public class CombineMeshes : IVertexPainterUtility
	{
		public string GetName()
		{
			return "Combine Meshes";
		}

		public bool GetEnable()
		{
			return true;
		}

		public void OnGUI(PaintJob[] jobs)
		{
			EditorGUILayout.BeginHorizontal();
			EditorGUILayout.Space();
			if (GUILayout.Button("Combine and Save", GUILayout.Width(200f), GUILayout.Height(30f)))
			{
				if (jobs.Length != 0)
				{
					string path = EditorUtility.SaveFilePanel("Save Asset", Application.dataPath, "models", "asset");
					if (!string.IsNullOrEmpty(path))
					{
						path = FileUtil.GetProjectRelativePath(path);
						GameObject go = VertexPainterUtilities.MergeMeshes(jobs);
						Mesh m = go.GetComponent<MeshFilter>().sharedMesh;
						AssetDatabase.CreateAsset(m, path);
						AssetDatabase.SaveAssets();
						AssetDatabase.ImportAsset(path);
						GameObject.DestroyImmediate(go);
					}
				}
			}
			EditorGUILayout.Space();
			EditorGUILayout.EndHorizontal();
		}
	}
}
