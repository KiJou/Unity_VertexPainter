using UnityEngine;
using System.Collections;
using System;
using System.Collections.Generic;

namespace VertexPainter
{
	[ExecuteInEditMode]
	public class VertexInstanceStream : MonoBehaviour
	{
		public bool keepRuntimeData = false;

		[HideInInspector]
		[SerializeField]
		private Color[] _colors;

		[HideInInspector]
		[SerializeField]
		private List<Vector4> _uv0;

		[HideInInspector]
		[SerializeField]
		private List<Vector4> _uv1;

		[HideInInspector]
		[SerializeField]
		private List<Vector4> _uv2;

		[HideInInspector]
		[SerializeField]
		private List<Vector4> _uv3;

		[HideInInspector]
		[SerializeField]
		private Vector3[] _positions;

		[HideInInspector]
		[SerializeField]
		private Vector3[] _normals;

		[HideInInspector]
		[SerializeField]
		private Vector4[] _tangents;

		private Mesh meshStream;

#if UNITY_EDITOR
		private Vector3[] cachedPositions;
		private Vector3[] cachedNormals;
		private Vector4[] cachedTangents;

		[HideInInspector]
		public Material[] originalMaterial;
		public static Material vertexShaderMat;

		public Mesh GetModifierMesh => meshStream;
		private MeshRenderer meshRend = null;


#endif
		bool enforcedColorChannels = false;

		public Color[] colors
		{
			get
			{
				return _colors;
			}
			set
			{
				enforcedColorChannels = (!(_colors == null || (value != null && _colors.Length != value.Length)));
				_colors = value;
				Apply();
			}
		}

		public List<Vector4> uv0
		{
			get
			{
				return _uv0;
			}
			set
			{
				_uv0 = value;
				Apply();
			}
		}

		public List<Vector4> uv1
		{
			get
			{
				return _uv1;
			}
			set
			{
				_uv1 = value;
				Apply();
			}
		}

		public List<Vector4> uv2
		{
			get
			{
				return _uv2;
			}
			set
			{
				_uv2 = value;
				Apply();
			}
		}

		public List<Vector4> uv3
		{
			get
			{
				return _uv3;
			}
			set
			{
				_uv3 = value;
				Apply();
			}
		}

		public Vector3[] positions
		{
			get
			{
				return _positions;
			}
			set
			{
				_positions = value;
				Apply();
			}
		}

		public Vector3[] normals
		{
			get
			{
				return _normals;
			}
			set
			{
				_normals = value;
				Apply();
			}
		}

		public Vector4[] tangents
		{
			get
			{
				return _tangents;
			}
			set
			{
				_tangents = value;
				Apply();
			}
		}

#if UNITY_EDITOR
		public Vector3 GetSafePosition(int index)
		{
			if (_positions != null && index < _positions.Length)
			{
				return _positions[index];
			}
			if (cachedPositions == null)
			{
				MeshFilter mf = GetComponent<MeshFilter>();
				if (mf == null || mf.sharedMesh == null)
				{
					Debug.LogError("No Mesh Filter or Mesh available");
					return Vector3.zero;
				}
				cachedPositions = mf.sharedMesh.vertices;
			}
			if (index < cachedPositions.Length)
			{
				return cachedPositions[index];
			}
			return Vector3.zero;
		}

		public Vector3 GetSafeNormal(int index)
		{
			if (_normals != null && index < _normals.Length)
			{
				return _normals[index];
			}
			if (cachedPositions == null)
			{
				MeshFilter mf = GetComponent<MeshFilter>();
				if (mf == null || mf.sharedMesh == null)
				{
					Debug.LogError("No Mesh Filter or Mesh available");
					return Vector3.zero;
				}
				cachedNormals = mf.sharedMesh.normals;
			}
			if (cachedNormals != null && index < cachedNormals.Length)
			{
				return cachedNormals[index];
			}
			return new Vector3(0, 0, 1);
		}

		public Vector4 GetSafeTangent(int index)
		{
			if (_tangents != null && index < _tangents.Length)
			{
				return _tangents[index];
			}
			if (cachedTangents == null)
			{
				MeshFilter mf = GetComponent<MeshFilter>();
				if (mf == null || mf.sharedMesh == null)
				{
					Debug.LogError("No Mesh Filter or Mesh available");
					return Vector3.zero;
				}
				cachedTangents = mf.sharedMesh.tangents;
			}
			if (cachedTangents != null && index < cachedTangents.Length)
			{
				return cachedTangents[index];
			}
			return new Vector4(0, 1, 0, 1);
		}

		private void Awake()
		{
			MeshRenderer meshRenderer = GetComponent<MeshRenderer>();
			if (meshRenderer != null)
			{
				if (meshRenderer.sharedMaterials != null && 
					meshRenderer.sharedMaterial == vertexShaderMat && 
					originalMaterial != null && 
					originalMaterial.Length == meshRenderer.sharedMaterials.Length && 
					originalMaterial.Length > 1)
				{
					Material[] materials = new Material[meshRenderer.sharedMaterials.Length];
					for (int i = 0; i < meshRenderer.sharedMaterials.Length; ++i)
					{
						if (originalMaterial[i] != null)
						{
							materials[i] = originalMaterial[i];
						}
					}
					meshRenderer.sharedMaterials = materials;
				}
				else if (originalMaterial != null && originalMaterial.Length > 0)
				{
					if (originalMaterial[0] != null)
					{
						meshRenderer.sharedMaterial = originalMaterial[0];
					}
				}
			}
		}
#endif

		private void Start()
		{
			Apply(!keepRuntimeData);
			if (keepRuntimeData)
			{
				MeshFilter meshFilter = GetComponent<MeshFilter>();
				_positions = meshFilter.sharedMesh.vertices;
			}
		}

		private void OnDestroy()
		{
			if (!Application.isPlaying)
			{
				MeshRenderer meshRenderer = GetComponent<MeshRenderer>();
				if (meshRenderer != null)
				{
					meshRenderer.additionalVertexStreams = null;
				}
			}
		}

		private void EnforceOriginalMeshHasColors(Mesh stream)
		{
			if (enforcedColorChannels)
			{
				return;
			}
			enforcedColorChannels = true;
			MeshFilter mf = GetComponent<MeshFilter>();
			Color[] origColors = mf.sharedMesh.colors;
			if (stream != null && stream.colors.Length > 0 && (origColors == null || origColors.Length == 0))
			{
				mf.sharedMesh.colors = stream.colors;
			}
		}

		public Mesh Apply(bool markNoLongerReadable = true)
		{
			MeshRenderer meshRenderer = GetComponent<MeshRenderer>();
			MeshFilter meshFilter = GetComponent<MeshFilter>();

			if (meshRenderer != null && 
				meshFilter != null && 
				meshFilter.sharedMesh != null)
			{
				int vertexCount = meshFilter.sharedMesh.vertexCount;
				Mesh stream = meshStream;
				if (stream == null || vertexCount != stream.vertexCount)
				{
					if (stream != null)
					{
						DestroyImmediate(stream);
					}
					stream = new Mesh();

					stream.vertices = new Vector3[meshFilter.sharedMesh.vertexCount];
					stream.vertices = meshFilter.sharedMesh.vertices;
					stream.MarkDynamic();
					stream.triangles = meshFilter.sharedMesh.triangles;
					meshStream = stream;

					stream.hideFlags = HideFlags.HideAndDontSave;
				}
				if (_positions != null && _positions.Length == vertexCount)
				{
					stream.vertices = _positions;
				}

				if (_normals != null && _normals.Length == vertexCount)
				{
					stream.normals = _normals;
				}
				else
				{
					stream.normals = null;
				}

				if (_tangents != null && _tangents.Length == vertexCount)
				{
					stream.tangents = _tangents;
				}
				else
				{
					stream.tangents = null;
				}

				if (_colors != null && _colors.Length == vertexCount)
				{
					stream.colors = _colors;
				}
				else
				{
					stream.colors = null;
				}

				if (_uv0 != null && _uv0.Count == vertexCount)
				{
					stream.SetUVs(0, _uv0);
				}
				else
				{
					stream.uv = null;
				}

				if (_uv1 != null && _uv1.Count == vertexCount)
				{
					stream.SetUVs(1, _uv1);
				}
				else
				{
					stream.uv2 = null;
				}

				if (_uv2 != null && _uv2.Count == vertexCount)
				{
					stream.SetUVs(2, _uv2);
				}
				else
				{
					stream.uv3 = null;
				}

				if (_uv3 != null && _uv3.Count == vertexCount)
				{
					stream.SetUVs(3, _uv3);
				}
				else
				{
					stream.uv4 = null;
				}

				EnforceOriginalMeshHasColors(stream);

				if (!Application.isPlaying || Application.isEditor)
				{
					markNoLongerReadable = false;
				}

				stream.UploadMeshData(markNoLongerReadable);
				meshRenderer.additionalVertexStreams = stream;
				return stream;
			}
			return null;
		}


#if UNITY_EDITOR
		public void SetColor(Color c, int count)
		{
			_colors = new Color[count];
			for (int i = 0; i < count; ++i)
			{
				_colors[i] = c;
			}
			Apply();
		}

		public void SetUV0(Vector4 uv, int count)
		{
			_uv0 = new List<Vector4>(count);
			for (int i = 0; i < count; ++i)
			{
				_uv0.Add(uv);
			}
			Apply();
		}

		public void SetUV1(Vector4 uv, int count)
		{
			_uv1 = new List<Vector4>(count);
			for (int i = 0; i < count; ++i)
			{
				_uv1.Add(uv);
			}
			Apply();
		}

		public void SetUV2(Vector4 uv, int count)
		{
			_uv2 = new List<Vector4>(count);
			for (int i = 0; i < count; ++i)
			{
				_uv2.Add(uv);
			}
			Apply();
		}

		public void SetUV3(Vector4 uv, int count)
		{
			_uv3 = new List<Vector4>(count);
			for (int i = 0; i < count; ++i)
			{
				_uv3.Add(uv);
			}
			Apply();
		}

		public void SetUV0_XY(Vector2 uv, int count)
		{
			if (_uv0 == null || _uv0.Count != count)
			{
				_uv0 = new List<Vector4>(count);
				for (int i = 0; i < count; ++i)
				{
					_uv0[i] = Vector4.zero;
				}
			}

			for (int i = 0; i < count; ++i)
			{
				Vector4 v = _uv0[i];
				v.x = uv.x;
				v.y = uv.y;
				_uv0[i] = v;
			}
			Apply();
		}

		public void SetUV0_ZW(Vector2 uv, int count)
		{
			if (_uv0 == null || _uv0.Count != count)
			{
				_uv0 = new List<Vector4>(count);
				for (int i = 0; i < count; ++i)
				{
					_uv0[i] = Vector4.zero;
				}
			}

			for (int i = 0; i < count; ++i)
			{
				Vector4 v = _uv0[i];
				v.z = uv.x;
				v.w = uv.y;
				_uv0[i] = v;
			}
			Apply();
		}

		public void SetUV1_XY(Vector2 uv, int count)
		{
			if (_uv1 == null || _uv1.Count != count)
			{
				_uv1 = new List<Vector4>(count);
				for (int i = 0; i < count; ++i)
				{
					_uv1[i] = Vector4.zero;
				}
			}

			for (int i = 0; i < count; ++i)
			{
				Vector4 v = _uv1[i];
				v.x = uv.x;
				v.y = uv.y;
				_uv1[i] = v;
			}
			Apply();
		}

		public void SetUV1_ZW(Vector2 uv, int count)
		{
			if (_uv1 == null || _uv1.Count != count)
			{
				_uv1 = new List<Vector4>(count);
				for (int i = 0; i < count; ++i)
				{
					_uv1[i] = Vector4.zero;
				}
			}

			for (int i = 0; i < count; ++i)
			{
				Vector4 v = _uv1[i];
				v.z = uv.x;
				v.w = uv.y;
				_uv1[i] = v;
			}
			Apply();
		}

		public void SetUV2_XY(Vector2 uv, int count)
		{
			if (_uv2 == null || _uv2.Count != count)
			{
				_uv2 = new List<Vector4>(count);
				for (int i = 0; i < count; ++i)
				{
					_uv2[i] = Vector4.zero;
				}
			}

			for (int i = 0; i < count; ++i)
			{
				Vector4 v = _uv2[i];
				v.x = uv.x;
				v.y = uv.y;
				_uv2[i] = v;
			}
			Apply();
		}

		public void SetUV2_ZW(Vector2 uv, int count)
		{
			if (_uv2 == null || _uv2.Count != count)
			{
				_uv2 = new List<Vector4>(count);
				for (int i = 0; i < count; ++i)
				{
					_uv2[i] = Vector4.zero;
				}
			}

			for (int i = 0; i < count; ++i)
			{
				Vector4 v = _uv2[i];
				v.z = uv.x;
				v.w = uv.y;
				_uv2[i] = v;
			}
			Apply();
		}

		public void SetUV3_XY(Vector2 uv, int count)
		{
			if (_uv3 == null || _uv3.Count != count)
			{
				_uv3 = new List<Vector4>(count);
				for (int i = 0; i < count; ++i)
				{
					_uv3[i] = Vector4.zero;
				}
			}

			for (int i = 0; i < count; ++i)
			{
				Vector4 v = _uv3[i];
				v.x = uv.x;
				v.y = uv.y;
				_uv3[i] = v;
			}
			Apply();
		}

		public void SetUV3_ZW(Vector2 uv, int count)
		{
			if (_uv3 == null || _uv3.Count != count)
			{
				_uv3 = new List<Vector4>(count);
				for (int i = 0; i < count; ++i)
				{
					_uv3[i] = Vector4.zero;
				}
			}

			for (int i = 0; i < count; ++i)
			{
				Vector4 v = _uv3[i];
				v.z = uv.x;
				v.w = uv.y;
				_uv3[i] = v;
			}
			Apply();
		}

		public void SetColorRG(Vector2 rg, int count)
		{
			if (_colors == null || _colors.Length != count)
			{
				_colors = new Color[count];
				enforcedColorChannels = false;
			}
			for (int i = 0; i < count; ++i)
			{
				_colors[i].r = rg.x;
				_colors[i].g = rg.y;
			}
			Apply();
		}

		public void SetColorBA(Vector2 ba, int count)
		{
			if (_colors == null || _colors.Length != count)
			{
				_colors = new Color[count];
				enforcedColorChannels = false;
			}
			for (int i = 0; i < count; ++i)
			{
				_colors[i].r = ba.x;
				_colors[i].g = ba.y;
			}
			Apply();
		}

		private void Update()
		{
			if (meshRend == null)
			{
				meshRend = GetComponent<MeshRenderer>();
			}
			meshRend.additionalVertexStreams = meshStream;
		}
#endif

	}
}
