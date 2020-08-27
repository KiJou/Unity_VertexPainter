using UnityEngine;
using System.Collections;
using UnityEditor;


namespace VertexPainter
{
	[CreateAssetMenu(menuName = "Vertex Painter Brush/Blend Normal Brush", fileName = "VertexNormalBlend_brush")]
	public class BlendNormalsBrush : VertexPainterCustomBrush
	{
		private VertexInstanceStream[] streams = default;

		private bool didHit = default;
		private Vector3 normal = default;
		private Vector4 tangent = default;
		public GameObject target = default;

		public override Channels GetChannels() => Channels.Normals;

		public override Color GetPreviewColor() => Color.yellow;

		public override object GetBrushObject() => target;

		public override VertexPainterWindow.Lerper GetLerper() => LerpFunc;

		public override void DrawGUI()
		{
			EditorGUI.BeginChangeCheck();
			target = (GameObject)EditorGUILayout.ObjectField("Blend With", target, typeof(GameObject), true);
			if (EditorGUI.EndChangeCheck())
			{
				if (target == null)
				{
					streams = null;
				}
				else
				{
					streams = target.GetComponentsInChildren<VertexInstanceStream>();
				}
			}
		}

		public override void BeginApplyStroke(Ray ray)
		{
			Vector3 bary = Vector3.zero;
			VertexInstanceStream stream = null;
			didHit = false;
			Mesh best = null;
			int triangle = 0;
			float distance = float.MaxValue;
			if (streams != null)
			{
				for (int i = 0; i < streams.Length; ++i)
				{
					Matrix4x4 mtx = streams[i].transform.localToWorldMatrix;
					Mesh msh = streams[i].GetComponent<MeshFilter>().sharedMesh;

					RaycastHit hit;
					RXLookingGlass.IntersectRayMesh(ray, msh, mtx, out hit);
					if (hit.distance < distance)
					{
						distance = hit.distance;
						bary = hit.barycentricCoordinate;
						best = msh;
						triangle = hit.triangleIndex;
						stream = streams[i];
						didHit = true;
					}
				}
			}
			if (didHit && best != null)
			{
				var triangles = best.triangles;
				int i0 = triangles[triangle];
				int i1 = triangles[triangle + 1];
				int i2 = triangles[triangle + 2];

				normal = stream.GetSafeNormal(i0) * bary.x + stream.GetSafeNormal(i1) * bary.y + stream.GetSafeNormal(i2) * bary.z;
				tangent = stream.GetSafeTangent(i0) * bary.x + stream.GetSafeTangent(i1) * bary.y + stream.GetSafeTangent(i2) * bary.z;
			}
		}

		private void LerpFunc(PaintJob j, int idx, ref object val, float r)
		{
			if (didHit)
			{
				j.stream.normals[idx] = Vector3.Lerp(j.stream.normals[idx], normal, r);
				j.stream.tangents[idx] = Vector4.Lerp(j.stream.tangents[idx], tangent, r);
			}
		}

	}
}

