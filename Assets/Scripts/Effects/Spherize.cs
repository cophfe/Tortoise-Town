using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Spherize : MonoBehaviour
{
	[Min(0)] public float radius = 0.5f;
	Mesh mesh;
	Vector3[] initialVertices;
	Vector3[] sphereVertices;
	Vector3 centre;
	MeshFilter mFilter;

	float percentSpherized = 0;
	public float PercentSpherized
	{
		get
		{
			return percentSpherized;
		}
		set
		{
			percentSpherized = Mathf.Clamp01(value);
			SpherizeMesh();
		}
	}
	private void Awake()
	{
		SetupMesh();
		mFilter = GetComponent<MeshFilter>();
	}

	public void SetupMesh()
	{
		if (!mFilter || !mFilter.mesh || mFilter.mesh.vertices == null || mFilter.mesh.vertices.Length == 0) return;

		mesh = new Mesh();
		initialVertices = mFilter.mesh.vertices;
		mesh.vertices = initialVertices;
		mesh.triangles = mFilter.mesh.triangles;
		mFilter.mesh = mesh;
		mesh.name = "Spherized Mesh";

		centre = Vector3.zero;

		sphereVertices = new Vector3[initialVertices.Length];
		for (int i = 0; i < initialVertices.Length; i++)
		{
			sphereVertices[i] = (initialVertices[i] - centre).normalized * radius;
		}
	}

	void SpherizeMesh()
	{
		if (mesh == null)
			SetupMesh();

		if (initialVertices == null || initialVertices.Length == 0 || !mFilter || !mFilter.mesh) return;

		Vector3[] vertices = new Vector3[initialVertices.Length];
		for (int i = 0; i < vertices.Length; i++)
		{
			vertices[i] = Vector3.Lerp(initialVertices[i], sphereVertices[i], percentSpherized);
		}
		mFilter.mesh.vertices = vertices;
	}
	private void OnDrawGizmosSelected()
	{
		Gizmos.matrix = Matrix4x4.TRS(transform.position, transform.rotation, transform.lossyScale);
		Gizmos.DrawWireSphere(Vector3.zero, radius);
	}

	private void OnValidate()
	{
		if (Application.isPlaying)
			SpherizeMesh();
	}
}
