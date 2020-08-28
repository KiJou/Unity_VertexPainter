using UnityEngine;
using UnityEditor;
using System.Collections;
using System;
using System.Linq;
using System.Reflection;

namespace VertexPainter
{
	[InitializeOnLoad]
	public class RXLookingGlass
	{
		public static Type type_HandleUtility;
		protected static MethodInfo infoIntersectRayMesh;
		static object[] parameters = new object[4];

		static RXLookingGlass()
		{
			var editorTypes = typeof(Editor).Assembly.GetTypes();

			type_HandleUtility = editorTypes.FirstOrDefault(t => t.Name == "HandleUtility");
			infoIntersectRayMesh = type_HandleUtility.GetMethod("IntersectRayMesh", (BindingFlags.Static | BindingFlags.NonPublic));
		}

		public static bool IntersectRayMesh(Ray ray, MeshFilter meshFilter, out RaycastHit hit) => IntersectRayMesh(ray, meshFilter.sharedMesh, meshFilter.transform.localToWorldMatrix, out hit);

		public static bool IntersectRayMesh(Ray ray, Mesh mesh, Matrix4x4 matrix, out RaycastHit hit)
		{
			parameters[0] = ray;
			parameters[1] = mesh;
			parameters[2] = matrix;
			parameters[3] = null;
			bool result = (bool)infoIntersectRayMesh.Invoke(null, parameters);
			hit = (RaycastHit)parameters[3];
			return result;
		}
	}
}