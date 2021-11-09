using System.Collections.Generic;
using System.Collections.ObjectModel;
using UnityEngine;
using System.Collections.Concurrent;
using System.Threading.Tasks;
using UnityEngine.Jobs;

//used marching cubes lookup table and way to access them from
//http://paulbourke.net/geometry/polygonise/
//also looked at this for help with metaballs
//http://jamie-wong.com/2014/08/19/metaballs-and-marching-squares/
//also sebastion lagues video on marching cubes
//https://youtu.be/M3iI2l0ltbE

[RequireComponent(typeof(MeshFilter))]
public class IsosurfaceGenerator : MonoBehaviour
{
	[Range(0.5f,15)] public float resolution =5;
	public bool smooth = true;
	public bool addWallsAtBounds = true;
	public bool autoGenerateBounds = false;
	public Bounds meshBounds;
	IsoShape[] metaShapes;
	public float threshold = 1;
	public float UVtiling = 1;
	public bool useParallel = false;
	float[,,] isoValues;
	Vector3 startPoint;
	float inverseResolution;

	TransformCapturedState transformState;

	public void Generate()
	{
		//var watch = new System.Diagnostics.Stopwatch();
		
		//watch.Start();
		InitializeForParallel();
		GenerateBounds();
		GenerateMeta();
		//watch.Stop();
		//long eS = watch.ElapsedMilliseconds;
		//Debug.Log("Time for generating isovalues: " + eS + " ms.");
		//watch.Restart();
		if (useParallel)
			GenerateMeshParallel();
		else
			GenerateMesh();
		//watch.Stop();
		//Debug.Log("Time for generating mesh: " + (watch.ElapsedMilliseconds) + " ms.");
		//Debug.Log("Total time with useParallel set to " + useParallel + ": " + (watch.ElapsedMilliseconds  + eS) + " ms.");
		isoValues = null;
	}

	public void InitializeForParallel()
	{
		transformState = new TransformCapturedState(transform);
		for (int i = 0; i < metaShapes.Length; i++)
		{
			metaShapes[i].InitializeForParallel();
		}
	}

	public void GenerateBounds()
	{
		metaShapes = GetComponentsInChildren<IsoShape>(false);
		
		if (!autoGenerateBounds)
		{
			return;
		}

		if (metaShapes.Length == 0)
		{
			meshBounds = new Bounds();
			return;
		}	

		Bounds bounds = metaShapes[0].GetInfluenceBounds(threshold, transform);
		Vector3 bottomLeft = bounds.center - bounds.size / 2;
		Vector3 topRight = bounds.center + bounds.size / 2;

		for (int i = 1; i < metaShapes.Length; i++)
		{
			bounds = metaShapes[i].GetInfluenceBounds(threshold, transform);
			Vector3 newBottomLeft = bounds.center - bounds.size / 2;
			Vector3 newTopRight = bounds.center + bounds.size / 2;

			bottomLeft.x = bottomLeft.x < newBottomLeft.x ? bottomLeft.x : newBottomLeft.x;
			bottomLeft.y = bottomLeft.y < newBottomLeft.y ? bottomLeft.y : newBottomLeft.y;
			bottomLeft.z = bottomLeft.z < newBottomLeft.z ? bottomLeft.z : newBottomLeft.z;

			topRight.x = topRight.x > newTopRight.x ? topRight.x : newTopRight.x;
			topRight.y = topRight.y > newTopRight.y ? topRight.y : newTopRight.y;
			topRight.z = topRight.z > newTopRight.z ? topRight.z : newTopRight.z;
		}

		Vector3 v = Vector3.one / resolution;
		meshBounds.center = Vector3.Lerp(bottomLeft, topRight, 0.5f) + v/2;
		meshBounds.size = (topRight - bottomLeft) + v;
	}
	void GenerateMeta()
	{
		Vector3Int extent = new Vector3Int(Mathf.CeilToInt(meshBounds.size.x * resolution), Mathf.CeilToInt(meshBounds.size.y * resolution), Mathf.CeilToInt(meshBounds.size.z * resolution));
		if (extent.x == 0 || extent.y == 0 || extent.z == 0 )
		{
			isoValues = new float[0, 0, 0];
			return;
		}	
		isoValues = new float[extent.x, extent.y, extent.z];
		startPoint = meshBounds.center - meshBounds.size/2;
		inverseResolution = 1 / resolution;

		if (useParallel)
		{
			Parallel.For(0, extent.x, x =>
			{
				for (int y = 0; y < extent.y; y++)
				{
					for (int z = 0; z < extent.z; z++)
					{

						if (x == 0 || x == extent.x - 1
							|| y == 0 || y == extent.y - 1
							|| z == 0 || z == extent.z - 1)
						{
							isoValues[x, y, z] = Mathf.Min(threshold - 0.1f, GetIsoValueParallel(CalculatePositionAtIndex(x, y, z)));
						}
						else
						{
							isoValues[x, y, z] = GetIsoValueParallel(CalculatePositionAtIndex(x, y, z));
						}
					}
				}
			});
		}
		else
		{
			for (int x = 0; x < extent.x; x++)
			{
				for (int y = 0; y < extent.y; y++)
				{
					for (int z = 0; z < extent.z; z++)
					{

						if (x == 0 || x == extent.x - 1
							|| y == 0 || y == extent.y - 1
							|| z == 0 || z == extent.z - 1)
						{
							isoValues[x, y, z] = Mathf.Min(threshold - 0.1f, GetIsoValue(CalculatePositionAtIndex(x, y, z)));
						}
						else
						{
							isoValues[x, y, z] = GetIsoValue(CalculatePositionAtIndex(x, y, z));
						}
					}
				}
			}
		}
	}

	float GetIsoValue(Vector3 point)
	{
		float metaValue = 0;
		foreach (var shape in metaShapes)
			metaValue += shape.GetIsoValue(point, transform);
		return metaValue;
	}

	float GetIsoValueParallel(Vector3 point)
	{
		float metaValue = 0;
		foreach (var shape in metaShapes)
			metaValue += shape.GetIsoValueParallel(point, ref transformState);
		return metaValue;
	}

	void GenerateMesh()
	{
		if (metaShapes.Length == 0)
		{
			GetComponent<MeshFilter>().mesh = null;
			return;
		}
		List<Vector3> vertices = new List<Vector3>();
		LinkedList<int> triangles = new LinkedList<int>();
		MarchingCubesData data = new MarchingCubesData();

		Vector3[] vertexList = new Vector3[12];
		Vector3Int[] corners = new Vector3Int[8];
		//using cube xyz, not point xyz
		for (int x = 0; x < isoValues.GetLength(0) - 1; x++)
		{
			for (int y = 0; y < isoValues.GetLength(1) - 1; y++)
			{
				for (int z = 0; z < isoValues.GetLength(2) - 1; z++)
				{
					byte index = GetCubeIndex(x, y, z);

					//no triangles to be generated in this case
					if (data.edgeTable[index] == 0) continue;

					SetCorners(x, y, z, corners);

					if ((data.edgeTable[index] & 1) != 0)
						vertexList[0] = GetPointBetweenPoints(corners[0], corners[1]);
					if ((data.edgeTable[index] & 2) != 0)
						vertexList[1] = GetPointBetweenPoints(corners[1], corners[2]);
					if ((data.edgeTable[index] & 4) != 0)
						vertexList[2] = GetPointBetweenPoints(corners[2], corners[3]);
					if ((data.edgeTable[index] & 8) != 0)
						vertexList[3] = GetPointBetweenPoints(corners[3], corners[0]);
					if ((data.edgeTable[index] & 16) != 0)
						vertexList[4] = GetPointBetweenPoints(corners[4], corners[5]);
					if ((data.edgeTable[index] & 32) != 0)
						vertexList[5] = GetPointBetweenPoints(corners[5], corners[6]);
					if ((data.edgeTable[index] & 64) != 0)
						vertexList[6] = GetPointBetweenPoints(corners[6], corners[7]);
					if ((data.edgeTable[index] & 128) != 0)
						vertexList[7] = GetPointBetweenPoints(corners[7], corners[4]);
					if ((data.edgeTable[index] & 256) != 0)
						vertexList[8] = GetPointBetweenPoints(corners[0], corners[4]);
					if ((data.edgeTable[index] & 512) != 0)
						vertexList[9] = GetPointBetweenPoints(corners[1], corners[5]);
					if ((data.edgeTable[index] & 1024) != 0)
						vertexList[10] = GetPointBetweenPoints(corners[2], corners[6]);
					if ((data.edgeTable[index] & 2048) != 0)
						vertexList[11] = GetPointBetweenPoints(corners[3], corners[7]);

					//the lookup table is super smart and uses this to access the vertices
					for (int i = 0; data.triTable[index].Length > i; i++)
					{
						Vector3 vertex = vertexList[data.triTable[index][i]];

						int vertexIndex = vertices.LastIndexOf(vertex);
						if (vertexIndex == -1)
						{
							triangles.AddLast(vertices.Count);
							vertices.Add(vertex);
						}
						else
						{
							triangles.AddLast(vertexIndex);
						}
					}
				}
			}
		}

		Mesh newMesh = new Mesh();
		newMesh.name = "generated mesh";

		newMesh.vertices = vertices.ToArray();
		int[] triArray = new int[triangles.Count];
		triangles.CopyTo(triArray, 0);
		newMesh.triangles = triArray;

		//calculate UVs
		Vector2[] uvList = new Vector2[vertices.Count];
		for (int i = 0; i < vertices.Count; i++)
		{
			uvList[i] = new Vector2(vertices[i].x * UVtiling, vertices[i].z * UVtiling);
		}
		newMesh.uv = uvList;
		
		newMesh.RecalculateNormals();
		newMesh.RecalculateBounds();
		newMesh.RecalculateTangents();
			

		var filter = GetComponent<MeshFilter>();
		filter.sharedMesh = null;
		filter.mesh = newMesh;
	}

	void GenerateMeshParallel()
	{
		if (metaShapes.Length == 0)
		{
			GetComponent<MeshFilter>().mesh = null;
			return;
		}

		MarchingCubesData data = new MarchingCubesData();
		
		var vertices = new List<Vector3>();
		var triangles = new List<int>();

		var result = Parallel.For(0, isoValues.GetLength(0) - 1,  x =>
		{
			Vector3[] vertexList = new Vector3[12];
			Vector3Int[] corners = new Vector3Int[8];
			//using cube xyz, not point xyz
			List<Vector3> planeVertices = new List<Vector3>();
			List<int> verticeIndexes = new List<int>();

			for (int y = 0; y < isoValues.GetLength(1) - 1; y++)
			{
				for (int z = 0; z < isoValues.GetLength(2) - 1; z++)
				{
					byte index = GetCubeIndex(x, y, z);

					//no triangles to be generated in this case
					if (data.edgeTable[index] == 0) continue;

					SetCorners(x, y, z, corners);

					if ((data.edgeTable[index] & 1) != 0)
						vertexList[0] = GetPointBetweenPoints(corners[0], corners[1]);
					if ((data.edgeTable[index] & 2) != 0)
						vertexList[1] = GetPointBetweenPoints(corners[1], corners[2]);
					if ((data.edgeTable[index] & 4) != 0)
						vertexList[2] = GetPointBetweenPoints(corners[2], corners[3]);
					if ((data.edgeTable[index] & 8) != 0)
						vertexList[3] = GetPointBetweenPoints(corners[3], corners[0]);
					if ((data.edgeTable[index] & 16) != 0)
						vertexList[4] = GetPointBetweenPoints(corners[4], corners[5]);
					if ((data.edgeTable[index] & 32) != 0)
						vertexList[5] = GetPointBetweenPoints(corners[5], corners[6]);
					if ((data.edgeTable[index] & 64) != 0)
						vertexList[6] = GetPointBetweenPoints(corners[6], corners[7]);
					if ((data.edgeTable[index] & 128) != 0)
						vertexList[7] = GetPointBetweenPoints(corners[7], corners[4]);
					if ((data.edgeTable[index] & 256) != 0)
						vertexList[8] = GetPointBetweenPoints(corners[0], corners[4]);
					if ((data.edgeTable[index] & 512) != 0)
						vertexList[9] = GetPointBetweenPoints(corners[1], corners[5]);
					if ((data.edgeTable[index] & 1024) != 0)
						vertexList[10] = GetPointBetweenPoints(corners[2], corners[6]);
					if ((data.edgeTable[index] & 2048) != 0)
						vertexList[11] = GetPointBetweenPoints(corners[3], corners[7]);

					for (int i = 0; data.triTable[index].Length > i; i++)
					{
						Vector3 vertex = vertexList[data.triTable[index][i]];

						int vertexIndex = planeVertices.LastIndexOf(vertex);
						if (vertexIndex == -1)
						{
							verticeIndexes.Add(planeVertices.Count);
							planeVertices.Add(vertex);
						}
						else
						{
							verticeIndexes.Add(vertexIndex);
						}
					}
				}
			}
			lock(vertices) lock (triangles)
			{
				int verticesCount = vertices.Count;
				vertices.AddRange(planeVertices);
				triangles.Capacity += verticeIndexes.Count;
				for (int i = 0; i < verticeIndexes.Count; i++)
				{
					triangles.Add(verticeIndexes[i] + verticesCount);
				}
			}
		});

		Mesh newMesh = new Mesh();
		newMesh.name = "generated mesh";

		var vertexArray = vertices.ToArray();
		newMesh.vertices = vertexArray;
		var triangleArray = triangles.ToArray();
		newMesh.triangles = triangleArray;

		//calculate UVs
		Vector2[] uvList = new Vector2[vertexArray.Length];
		for (int i = 0; i < vertexArray.Length; i++)
		{
			uvList[i] = new Vector2(vertexArray[i].x * UVtiling, vertexArray[i].z * UVtiling);
		}
		newMesh.uv = uvList;

		newMesh.RecalculateNormals();
		newMesh.RecalculateBounds();
		newMesh.RecalculateTangents();


		var filter = GetComponent<MeshFilter>();
		filter.sharedMesh = null;
		filter.mesh = newMesh;
	}

	bool IsVertexEqual(ref Vector3 a, ref Vector3 b)
	{
		return (a - b).sqrMagnitude < 0.0001f;
	}

	Vector3 GetPointBetweenPoints(Vector3Int index1, Vector3Int index2)
	{
		if (smooth)
		{
			float v1 = isoValues[index1.x, index1.y, index1.z];
			float v2 = isoValues[index2.x, index2.y, index2.z];
			float t = (threshold - v1) / (v2 - v1);

			return Vector3.Lerp(CalculatePositionAtIndex(index1), CalculatePositionAtIndex(index2), t);
		}
		else
		{
			return Vector3.Lerp(CalculatePositionAtIndex(index1), CalculatePositionAtIndex(index2), 0.5f);
		}
		
	}

	private void OnDrawGizmos()
	{
		Gizmos.matrix = Matrix4x4.TRS(transform.position, transform.rotation, transform.lossyScale);
		Gizmos.DrawWireCube(meshBounds.center, meshBounds.size);
	}

	Vector3 CalculatePositionAtIndex(int x, int y, int z)
	{
		return new Vector3(x * inverseResolution, y * inverseResolution, z * inverseResolution) + startPoint;
	}
	Vector3 CalculatePositionAtIndex(Vector3Int index)
	{
		return CalculatePositionAtIndex(index.x, index.y, index.z);
	}

	//x y z index here is index of cubes
	byte GetCubeIndex(int x, int y, int z)
	{
		byte index = 0;
		if (isoValues[x, y, z] > threshold)
			index |= 1;		
		if (isoValues[x, y + 1, z] > threshold)
			index |= 2;		
		if (isoValues[x + 1, y + 1, z] > threshold)
			index |= 4;		
		if (isoValues[x + 1, y, z] > threshold)
			index |= 8;	
		if (isoValues[x, y, z + 1] > threshold)
			index |= 16;	
		if (isoValues[x, y + 1, z + 1] > threshold)
			index |= 32;	
		if (isoValues[x + 1, y + 1, z + 1] > threshold)
			index |= 64;	
		if (isoValues[x + 1, y, z + 1] > threshold)
			index |= 128;
		return index;
	}

	void SetCorners(int x, int y, int z, Vector3Int[] cornerArray)
	{
		cornerArray[0] = new Vector3Int(x, y, z);
		cornerArray[1] = new Vector3Int(x, y + 1, z);
		cornerArray[2] = new Vector3Int(x + 1, y + 1, z);
		cornerArray[3] = new Vector3Int(x + 1, y, z);
		cornerArray[4] = new Vector3Int(x, y, z + 1);
		cornerArray[5] = new Vector3Int(x, y + 1, z + 1);
		cornerArray[6] = new Vector3Int(x + 1, y + 1, z + 1);
		cornerArray[7] = new Vector3Int(x + 1, y, z + 1);
	}
	Vector3Int GetCornerValueFromCubeIndex(int x, int y, int z, int index)
	{
		switch (index)
		{
			case 0:	return new Vector3Int(x, y, z);
			case 1:	return new Vector3Int(x, y + 1, z);
			case 2:	return new Vector3Int(x + 1, y + 1, z);
			case 3:	return new Vector3Int(x + 1, y, z);
			case 4: return new Vector3Int(x, y, z + 1);
			case 5:	return new Vector3Int(x, y + 1, z + 1);
			case 6:	return new Vector3Int(x + 1, y + 1, z + 1);
			default: return new Vector3Int(x + 1, y, z + 1);

		}
	}

	[System.Serializable]
	public class Metaball
	{
		public Vector3 position = Vector3.zero;
		public float radius = 1;

		public float GetMetaValue(Vector3 point)
		{
			Vector3 delta = point - position;
			return (radius * radius) / (delta.x * delta.x + delta.y * delta.y + delta.z * delta.z);
		}
	}

	class OrderedVector3HashSet : KeyedCollection<Vector3, Vector3>
	{
		protected override Vector3 GetKeyForItem(Vector3 item)
		{
			return item;
		}
	}

	class MarchingCubesData
	{
		public readonly short[] edgeTable = new short[256]{
			0x0  , 0x109, 0x203, 0x30a, 0x406, 0x50f, 0x605, 0x70c,
			0x80c, 0x905, 0xa0f, 0xb06, 0xc0a, 0xd03, 0xe09, 0xf00,
			0x190, 0x99 , 0x393, 0x29a, 0x596, 0x49f, 0x795, 0x69c,
			0x99c, 0x895, 0xb9f, 0xa96, 0xd9a, 0xc93, 0xf99, 0xe90,
			0x230, 0x339, 0x33 , 0x13a, 0x636, 0x73f, 0x435, 0x53c,
			0xa3c, 0xb35, 0x83f, 0x936, 0xe3a, 0xf33, 0xc39, 0xd30,
			0x3a0, 0x2a9, 0x1a3, 0xaa , 0x7a6, 0x6af, 0x5a5, 0x4ac,
			0xbac, 0xaa5, 0x9af, 0x8a6, 0xfaa, 0xea3, 0xda9, 0xca0,
			0x460, 0x569, 0x663, 0x76a, 0x66 , 0x16f, 0x265, 0x36c,
			0xc6c, 0xd65, 0xe6f, 0xf66, 0x86a, 0x963, 0xa69, 0xb60,
			0x5f0, 0x4f9, 0x7f3, 0x6fa, 0x1f6, 0xff , 0x3f5, 0x2fc,
			0xdfc, 0xcf5, 0xfff, 0xef6, 0x9fa, 0x8f3, 0xbf9, 0xaf0,
			0x650, 0x759, 0x453, 0x55a, 0x256, 0x35f, 0x55 , 0x15c,
			0xe5c, 0xf55, 0xc5f, 0xd56, 0xa5a, 0xb53, 0x859, 0x950,
			0x7c0, 0x6c9, 0x5c3, 0x4ca, 0x3c6, 0x2cf, 0x1c5, 0xcc ,
			0xfcc, 0xec5, 0xdcf, 0xcc6, 0xbca, 0xac3, 0x9c9, 0x8c0,
			0x8c0, 0x9c9, 0xac3, 0xbca, 0xcc6, 0xdcf, 0xec5, 0xfcc,
			0xcc , 0x1c5, 0x2cf, 0x3c6, 0x4ca, 0x5c3, 0x6c9, 0x7c0,
			0x950, 0x859, 0xb53, 0xa5a, 0xd56, 0xc5f, 0xf55, 0xe5c,
			0x15c, 0x55 , 0x35f, 0x256, 0x55a, 0x453, 0x759, 0x650,
			0xaf0, 0xbf9, 0x8f3, 0x9fa, 0xef6, 0xfff, 0xcf5, 0xdfc,
			0x2fc, 0x3f5, 0xff , 0x1f6, 0x6fa, 0x7f3, 0x4f9, 0x5f0,
			0xb60, 0xa69, 0x963, 0x86a, 0xf66, 0xe6f, 0xd65, 0xc6c,
			0x36c, 0x265, 0x16f, 0x66 , 0x76a, 0x663, 0x569, 0x460,
			0xca0, 0xda9, 0xea3, 0xfaa, 0x8a6, 0x9af, 0xaa5, 0xbac,
			0x4ac, 0x5a5, 0x6af, 0x7a6, 0xaa , 0x1a3, 0x2a9, 0x3a0,
			0xd30, 0xc39, 0xf33, 0xe3a, 0x936, 0x83f, 0xb35, 0xa3c,
			0x53c, 0x435, 0x73f, 0x636, 0x13a, 0x33 , 0x339, 0x230,
			0xe90, 0xf99, 0xc93, 0xd9a, 0xa96, 0xb9f, 0x895, 0x99c,
			0x69c, 0x795, 0x49f, 0x596, 0x29a, 0x393, 0x99 , 0x190,
			0xf00, 0xe09, 0xd03, 0xc0a, 0xb06, 0xa0f, 0x905, 0x80c,
			0x70c, 0x605, 0x50f, 0x406, 0x30a, 0x203, 0x109, 0x0   
		};

		public readonly sbyte[][] triTable = new sbyte[][]
		{
			new sbyte[] {},
			new sbyte[] {0, 8, 3 },
			new sbyte[] {0, 1, 9 },
			new sbyte[] {1, 8, 3, 9, 8, 1 },
			new sbyte[] {1, 2, 10 },
			new sbyte[] {0, 8, 3, 1, 2, 10 },
			new sbyte[] {9, 2, 10, 0, 2, 9 },
			new sbyte[] {2, 8, 3, 2, 10, 8, 10, 9, 8 },
			new sbyte[] {3, 11, 2 },
			new sbyte[] {0, 11, 2, 8, 11, 0 },
			new sbyte[] {1, 9, 0, 2, 3, 11 },
			new sbyte[] {1, 11, 2, 1, 9, 11, 9, 8, 11 },
			new sbyte[] {3, 10, 1, 11, 10, 3 },
			new sbyte[] {0, 10, 1, 0, 8, 10, 8, 11, 10 },
			new sbyte[] {3, 9, 0, 3, 11, 9, 11, 10, 9 },
			new sbyte[] {9, 8, 10, 10, 8, 11 },
			new sbyte[] {4, 7, 8 },
			new sbyte[] {4, 3, 0, 7, 3, 4 },
			new sbyte[] {0, 1, 9, 8, 4, 7 },
			new sbyte[] {4, 1, 9, 4, 7, 1, 7, 3, 1 },
			new sbyte[] {1, 2, 10, 8, 4, 7 },
			new sbyte[] {3, 4, 7, 3, 0, 4, 1, 2, 10 },
			new sbyte[] {9, 2, 10, 9, 0, 2, 8, 4, 7 },
			new sbyte[] {2, 10, 9, 2, 9, 7, 2, 7, 3, 7, 9, 4 },
			new sbyte[] {8, 4, 7, 3, 11, 2 },
			new sbyte[] {11, 4, 7, 11, 2, 4, 2, 0, 4 },
			new sbyte[] {9, 0, 1, 8, 4, 7, 2, 3, 11 },
			new sbyte[] {4, 7, 11, 9, 4, 11, 9, 11, 2, 9, 2, 1 },
			new sbyte[] {3, 10, 1, 3, 11, 10, 7, 8, 4 },
			new sbyte[] {1, 11, 10, 1, 4, 11, 1, 0, 4, 7, 11, 4 },
			new sbyte[] {4, 7, 8, 9, 0, 11, 9, 11, 10, 11, 0, 3 },
			new sbyte[] {4, 7, 11, 4, 11, 9, 9, 11, 10 },
			new sbyte[] {9, 5, 4 },
			new sbyte[] {9, 5, 4, 0, 8, 3 },
			new sbyte[] {0, 5, 4, 1, 5, 0 },
			new sbyte[] {8, 5, 4, 8, 3, 5, 3, 1, 5 },
			new sbyte[] {1, 2, 10, 9, 5, 4 },
			new sbyte[] {3, 0, 8, 1, 2, 10, 4, 9, 5 },
			new sbyte[] {5, 2, 10, 5, 4, 2, 4, 0, 2 },
			new sbyte[] {2, 10, 5, 3, 2, 5, 3, 5, 4, 3, 4, 8 },
			new sbyte[] {9, 5, 4, 2, 3, 11 },
			new sbyte[] {0, 11, 2, 0, 8, 11, 4, 9, 5 },
			new sbyte[] {0, 5, 4, 0, 1, 5, 2, 3, 11 },
			new sbyte[] {2, 1, 5, 2, 5, 8, 2, 8, 11, 4, 8, 5 },
			new sbyte[] {10, 3, 11, 10, 1, 3, 9, 5, 4 },
			new sbyte[] {4, 9, 5, 0, 8, 1, 8, 10, 1, 8, 11, 10 },
			new sbyte[] {5, 4, 0, 5, 0, 11, 5, 11, 10, 11, 0, 3 },
			new sbyte[] {5, 4, 8, 5, 8, 10, 10, 8, 11 },
			new sbyte[] {9, 7, 8, 5, 7, 9 },
			new sbyte[] {9, 3, 0, 9, 5, 3, 5, 7, 3 },
			new sbyte[] {0, 7, 8, 0, 1, 7, 1, 5, 7 },
			new sbyte[] {1, 5, 3, 3, 5, 7 },
			new sbyte[] {9, 7, 8, 9, 5, 7, 10, 1, 2 },
			new sbyte[] {10, 1, 2, 9, 5, 0, 5, 3, 0, 5, 7, 3 },
			new sbyte[] {8, 0, 2, 8, 2, 5, 8, 5, 7, 10, 5, 2 },
			new sbyte[] {2, 10, 5, 2, 5, 3, 3, 5, 7 },
			new sbyte[] {7, 9, 5, 7, 8, 9, 3, 11, 2 },
			new sbyte[] {9, 5, 7, 9, 7, 2, 9, 2, 0, 2, 7, 11 },
			new sbyte[] {2, 3, 11, 0, 1, 8, 1, 7, 8, 1, 5, 7 },
			new sbyte[] {11, 2, 1, 11, 1, 7, 7, 1, 5 },
			new sbyte[] {9, 5, 8, 8, 5, 7, 10, 1, 3, 10, 3, 11 },
			new sbyte[] {5, 7, 0, 5, 0, 9, 7, 11, 0, 1, 0, 10, 11, 10, 0 },
			new sbyte[] {11, 10, 0, 11, 0, 3, 10, 5, 0, 8, 0, 7, 5, 7, 0 },
			new sbyte[] {11, 10, 5, 7, 11, 5 },
			new sbyte[] {10, 6, 5 },
			new sbyte[] {0, 8, 3, 5, 10, 6 },
			new sbyte[] {9, 0, 1, 5, 10, 6 },
			new sbyte[] {1, 8, 3, 1, 9, 8, 5, 10, 6 },
			new sbyte[] {1, 6, 5, 2, 6, 1 },
			new sbyte[] {1, 6, 5, 1, 2, 6, 3, 0, 8 },
			new sbyte[] {9, 6, 5, 9, 0, 6, 0, 2, 6 },
			new sbyte[] {5, 9, 8, 5, 8, 2, 5, 2, 6, 3, 2, 8 },
			new sbyte[] {2, 3, 11, 10, 6, 5 },
			new sbyte[] {11, 0, 8, 11, 2, 0, 10, 6, 5 },
			new sbyte[] {0, 1, 9, 2, 3, 11, 5, 10, 6 },
			new sbyte[] {5, 10, 6, 1, 9, 2, 9, 11, 2, 9, 8, 11 },
			new sbyte[] {6, 3, 11, 6, 5, 3, 5, 1, 3 },
			new sbyte[] {0, 8, 11, 0, 11, 5, 0, 5, 1, 5, 11, 6 },
			new sbyte[] {3, 11, 6, 0, 3, 6, 0, 6, 5, 0, 5, 9 },
			new sbyte[] {6, 5, 9, 6, 9, 11, 11, 9, 8 },
			new sbyte[] {5, 10, 6, 4, 7, 8 },
			new sbyte[] {4, 3, 0, 4, 7, 3, 6, 5, 10 },
			new sbyte[] {1, 9, 0, 5, 10, 6, 8, 4, 7 },
			new sbyte[] {10, 6, 5, 1, 9, 7, 1, 7, 3, 7, 9, 4 },
			new sbyte[] {6, 1, 2, 6, 5, 1, 4, 7, 8 },
			new sbyte[] {1, 2, 5, 5, 2, 6, 3, 0, 4, 3, 4, 7 },
			new sbyte[] {8, 4, 7, 9, 0, 5, 0, 6, 5, 0, 2, 6 },
			new sbyte[] {7, 3, 9, 7, 9, 4, 3, 2, 9, 5, 9, 6, 2, 6, 9 },
			new sbyte[] {3, 11, 2, 7, 8, 4, 10, 6, 5 },
			new sbyte[] {5, 10, 6, 4, 7, 2, 4, 2, 0, 2, 7, 11 },
			new sbyte[] {0, 1, 9, 4, 7, 8, 2, 3, 11, 5, 10, 6 },
			new sbyte[] {9, 2, 1, 9, 11, 2, 9, 4, 11, 7, 11, 4, 5, 10, 6 },
			new sbyte[] {8, 4, 7, 3, 11, 5, 3, 5, 1, 5, 11, 6 },
			new sbyte[] {5, 1, 11, 5, 11, 6, 1, 0, 11, 7, 11, 4, 0, 4, 11 },
			new sbyte[] {0, 5, 9, 0, 6, 5, 0, 3, 6, 11, 6, 3, 8, 4, 7 },
			new sbyte[] {6, 5, 9, 6, 9, 11, 4, 7, 9, 7, 11, 9 },
			new sbyte[] {10, 4, 9, 6, 4, 10 },
			new sbyte[] {4, 10, 6, 4, 9, 10, 0, 8, 3 },
			new sbyte[] {10, 0, 1, 10, 6, 0, 6, 4, 0 },
			new sbyte[] {8, 3, 1, 8, 1, 6, 8, 6, 4, 6, 1, 10 },
			new sbyte[] {1, 4, 9, 1, 2, 4, 2, 6, 4 },
			new sbyte[] {3, 0, 8, 1, 2, 9, 2, 4, 9, 2, 6, 4 },
			new sbyte[] {0, 2, 4, 4, 2, 6 },
			new sbyte[] {8, 3, 2, 8, 2, 4, 4, 2, 6 },
			new sbyte[] {10, 4, 9, 10, 6, 4, 11, 2, 3 },
			new sbyte[] {0, 8, 2, 2, 8, 11, 4, 9, 10, 4, 10, 6 },
			new sbyte[] {3, 11, 2, 0, 1, 6, 0, 6, 4, 6, 1, 10 },
			new sbyte[] {6, 4, 1, 6, 1, 10, 4, 8, 1, 2, 1, 11, 8, 11, 1 },
			new sbyte[] {9, 6, 4, 9, 3, 6, 9, 1, 3, 11, 6, 3 },
			new sbyte[] {8, 11, 1, 8, 1, 0, 11, 6, 1, 9, 1, 4, 6, 4, 1 },
			new sbyte[] {3, 11, 6, 3, 6, 0, 0, 6, 4 },
			new sbyte[] {6, 4, 8, 11, 6, 8 },
			new sbyte[] {7, 10, 6, 7, 8, 10, 8, 9, 10 },
			new sbyte[] {0, 7, 3, 0, 10, 7, 0, 9, 10, 6, 7, 10 },
			new sbyte[] {10, 6, 7, 1, 10, 7, 1, 7, 8, 1, 8, 0 },
			new sbyte[] {10, 6, 7, 10, 7, 1, 1, 7, 3 },
			new sbyte[] {1, 2, 6, 1, 6, 8, 1, 8, 9, 8, 6, 7 },
			new sbyte[] {2, 6, 9, 2, 9, 1, 6, 7, 9, 0, 9, 3, 7, 3, 9 },
			new sbyte[] {7, 8, 0, 7, 0, 6, 6, 0, 2 },
			new sbyte[] {7, 3, 2, 6, 7, 2 },
			new sbyte[] {2, 3, 11, 10, 6, 8, 10, 8, 9, 8, 6, 7 },
			new sbyte[] {2, 0, 7, 2, 7, 11, 0, 9, 7, 6, 7, 10, 9, 10, 7 },
			new sbyte[] {1, 8, 0, 1, 7, 8, 1, 10, 7, 6, 7, 10, 2, 3, 11 },
			new sbyte[] {11, 2, 1, 11, 1, 7, 10, 6, 1, 6, 7, 1 },
			new sbyte[] {8, 9, 6, 8, 6, 7, 9, 1, 6, 11, 6, 3, 1, 3, 6 },
			new sbyte[] {0, 9, 1, 11, 6, 7 },
			new sbyte[] {7, 8, 0, 7, 0, 6, 3, 11, 0, 11, 6, 0 },
			new sbyte[] {7, 11, 6 },
			new sbyte[] {7, 6, 11 },
			new sbyte[] {3, 0, 8, 11, 7, 6 },
			new sbyte[] {0, 1, 9, 11, 7, 6 },
			new sbyte[] {8, 1, 9, 8, 3, 1, 11, 7, 6 },
			new sbyte[] {10, 1, 2, 6, 11, 7 },
			new sbyte[] {1, 2, 10, 3, 0, 8, 6, 11, 7 },
			new sbyte[] {2, 9, 0, 2, 10, 9, 6, 11, 7 },
			new sbyte[] {6, 11, 7, 2, 10, 3, 10, 8, 3, 10, 9, 8 },
			new sbyte[] {7, 2, 3, 6, 2, 7 },
			new sbyte[] {7, 0, 8, 7, 6, 0, 6, 2, 0 },
			new sbyte[] {2, 7, 6, 2, 3, 7, 0, 1, 9 },
			new sbyte[] {1, 6, 2, 1, 8, 6, 1, 9, 8, 8, 7, 6 },
			new sbyte[] {10, 7, 6, 10, 1, 7, 1, 3, 7 },
			new sbyte[] {10, 7, 6, 1, 7, 10, 1, 8, 7, 1, 0, 8 },
			new sbyte[] {0, 3, 7, 0, 7, 10, 0, 10, 9, 6, 10, 7 },
			new sbyte[] {7, 6, 10, 7, 10, 8, 8, 10, 9 },
			new sbyte[] {6, 8, 4, 11, 8, 6 },
			new sbyte[] {3, 6, 11, 3, 0, 6, 0, 4, 6 },
			new sbyte[] {8, 6, 11, 8, 4, 6, 9, 0, 1 },
			new sbyte[] {9, 4, 6, 9, 6, 3, 9, 3, 1, 11, 3, 6 },
			new sbyte[] {6, 8, 4, 6, 11, 8, 2, 10, 1 },
			new sbyte[] {1, 2, 10, 3, 0, 11, 0, 6, 11, 0, 4, 6 },
			new sbyte[] {4, 11, 8, 4, 6, 11, 0, 2, 9, 2, 10, 9 },
			new sbyte[] {10, 9, 3, 10, 3, 2, 9, 4, 3, 11, 3, 6, 4, 6, 3 },
			new sbyte[] {8, 2, 3, 8, 4, 2, 4, 6, 2 },
			new sbyte[] {0, 4, 2, 4, 6, 2 },
			new sbyte[] {1, 9, 0, 2, 3, 4, 2, 4, 6, 4, 3, 8 },
			new sbyte[] {1, 9, 4, 1, 4, 2, 2, 4, 6 },
			new sbyte[] {8, 1, 3, 8, 6, 1, 8, 4, 6, 6, 10, 1 },
			new sbyte[] {10, 1, 0, 10, 0, 6, 6, 0, 4 },
			new sbyte[] {4, 6, 3, 4, 3, 8, 6, 10, 3, 0, 3, 9, 10, 9, 3 },
			new sbyte[] {10, 9, 4, 6, 10, 4 },
			new sbyte[] {4, 9, 5, 7, 6, 11 },
			new sbyte[] {0, 8, 3, 4, 9, 5, 11, 7, 6 },
			new sbyte[] {5, 0, 1, 5, 4, 0, 7, 6, 11 },
			new sbyte[] {11, 7, 6, 8, 3, 4, 3, 5, 4, 3, 1, 5 },
			new sbyte[] {9, 5, 4, 10, 1, 2, 7, 6, 11 },
			new sbyte[] {6, 11, 7, 1, 2, 10, 0, 8, 3, 4, 9, 5 },
			new sbyte[] {7, 6, 11, 5, 4, 10, 4, 2, 10, 4, 0, 2 },
			new sbyte[] {3, 4, 8, 3, 5, 4, 3, 2, 5, 10, 5, 2, 11, 7, 6 },
			new sbyte[] {7, 2, 3, 7, 6, 2, 5, 4, 9 },
			new sbyte[] {9, 5, 4, 0, 8, 6, 0, 6, 2, 6, 8, 7 },
			new sbyte[] {3, 6, 2, 3, 7, 6, 1, 5, 0, 5, 4, 0 },
			new sbyte[] {6, 2, 8, 6, 8, 7, 2, 1, 8, 4, 8, 5, 1, 5, 8 },
			new sbyte[] {9, 5, 4, 10, 1, 6, 1, 7, 6, 1, 3, 7 },
			new sbyte[] {1, 6, 10, 1, 7, 6, 1, 0, 7, 8, 7, 0, 9, 5, 4 },
			new sbyte[] {4, 0, 10, 4, 10, 5, 0, 3, 10, 6, 10, 7, 3, 7, 10 },
			new sbyte[] {7, 6, 10, 7, 10, 8, 5, 4, 10, 4, 8, 10 },
			new sbyte[] {6, 9, 5, 6, 11, 9, 11, 8, 9 },
			new sbyte[] {3, 6, 11, 0, 6, 3, 0, 5, 6, 0, 9, 5 },
			new sbyte[] {0, 11, 8, 0, 5, 11, 0, 1, 5, 5, 6, 11 },
			new sbyte[] {6, 11, 3, 6, 3, 5, 5, 3, 1 },
			new sbyte[] {1, 2, 10, 9, 5, 11, 9, 11, 8, 11, 5, 6 },
			new sbyte[] {0, 11, 3, 0, 6, 11, 0, 9, 6, 5, 6, 9, 1, 2, 10 },
			new sbyte[] {11, 8, 5, 11, 5, 6, 8, 0, 5, 10, 5, 2, 0, 2, 5 },
			new sbyte[] {6, 11, 3, 6, 3, 5, 2, 10, 3, 10, 5, 3 },
			new sbyte[] {5, 8, 9, 5, 2, 8, 5, 6, 2, 3, 8, 2 },
			new sbyte[] {9, 5, 6, 9, 6, 0, 0, 6, 2 },
			new sbyte[] {1, 5, 8, 1, 8, 0, 5, 6, 8, 3, 8, 2, 6, 2, 8 },
			new sbyte[] {1, 5, 6, 2, 1, 6 },
			new sbyte[] {1, 3, 6, 1, 6, 10, 3, 8, 6, 5, 6, 9, 8, 9, 6 },
			new sbyte[] {10, 1, 0, 10, 0, 6, 9, 5, 0, 5, 6, 0 },
			new sbyte[] {0, 3, 8, 5, 6, 10 },
			new sbyte[] {10, 5, 6 },
			new sbyte[] {11, 5, 10, 7, 5, 11 },
			new sbyte[] {11, 5, 10, 11, 7, 5, 8, 3, 0 },
			new sbyte[] {5, 11, 7, 5, 10, 11, 1, 9, 0 },
			new sbyte[] {10, 7, 5, 10, 11, 7, 9, 8, 1, 8, 3, 1 },
			new sbyte[] {11, 1, 2, 11, 7, 1, 7, 5, 1 },
			new sbyte[] {0, 8, 3, 1, 2, 7, 1, 7, 5, 7, 2, 11 },
			new sbyte[] {9, 7, 5, 9, 2, 7, 9, 0, 2, 2, 11, 7 },
			new sbyte[] {7, 5, 2, 7, 2, 11, 5, 9, 2, 3, 2, 8, 9, 8, 2 },
			new sbyte[] {2, 5, 10, 2, 3, 5, 3, 7, 5 },
			new sbyte[] {8, 2, 0, 8, 5, 2, 8, 7, 5, 10, 2, 5 },
			new sbyte[] {9, 0, 1, 5, 10, 3, 5, 3, 7, 3, 10, 2 },
			new sbyte[] {9, 8, 2, 9, 2, 1, 8, 7, 2, 10, 2, 5, 7, 5, 2 },
			new sbyte[] {1, 3, 5, 3, 7, 5 },
			new sbyte[] {0, 8, 7, 0, 7, 1, 1, 7, 5 },
			new sbyte[] {9, 0, 3, 9, 3, 5, 5, 3, 7 },
			new sbyte[] {9, 8, 7, 5, 9, 7 },
			new sbyte[] {5, 8, 4, 5, 10, 8, 10, 11, 8 },
			new sbyte[] {5, 0, 4, 5, 11, 0, 5, 10, 11, 11, 3, 0 },
			new sbyte[] {0, 1, 9, 8, 4, 10, 8, 10, 11, 10, 4, 5 },
			new sbyte[] {10, 11, 4, 10, 4, 5, 11, 3, 4, 9, 4, 1, 3, 1, 4 },
			new sbyte[] {2, 5, 1, 2, 8, 5, 2, 11, 8, 4, 5, 8 },
			new sbyte[] {0, 4, 11, 0, 11, 3, 4, 5, 11, 2, 11, 1, 5, 1, 11 },
			new sbyte[] {0, 2, 5, 0, 5, 9, 2, 11, 5, 4, 5, 8, 11, 8, 5 },
			new sbyte[] {9, 4, 5, 2, 11, 3 },
			new sbyte[] {2, 5, 10, 3, 5, 2, 3, 4, 5, 3, 8, 4 },
			new sbyte[] {5, 10, 2, 5, 2, 4, 4, 2, 0 },
			new sbyte[] {3, 10, 2, 3, 5, 10, 3, 8, 5, 4, 5, 8, 0, 1, 9 },
			new sbyte[] {5, 10, 2, 5, 2, 4, 1, 9, 2, 9, 4, 2 },
			new sbyte[] {8, 4, 5, 8, 5, 3, 3, 5, 1 },
			new sbyte[] {0, 4, 5, 1, 0, 5 },
			new sbyte[] {8, 4, 5, 8, 5, 3, 9, 0, 5, 0, 3, 5 },
			new sbyte[] {9, 4, 5 },
			new sbyte[] {4, 11, 7, 4, 9, 11, 9, 10, 11 },
			new sbyte[] {0, 8, 3, 4, 9, 7, 9, 11, 7, 9, 10, 11 },
			new sbyte[] {1, 10, 11, 1, 11, 4, 1, 4, 0, 7, 4, 11 },
			new sbyte[] {3, 1, 4, 3, 4, 8, 1, 10, 4, 7, 4, 11, 10, 11, 4 },
			new sbyte[] {4, 11, 7, 9, 11, 4, 9, 2, 11, 9, 1, 2 },
			new sbyte[] {9, 7, 4, 9, 11, 7, 9, 1, 11, 2, 11, 1, 0, 8, 3 },
			new sbyte[] {11, 7, 4, 11, 4, 2, 2, 4, 0 },
			new sbyte[] {11, 7, 4, 11, 4, 2, 8, 3, 4, 3, 2, 4 },
			new sbyte[] {2, 9, 10, 2, 7, 9, 2, 3, 7, 7, 4, 9 },
			new sbyte[] {9, 10, 7, 9, 7, 4, 10, 2, 7, 8, 7, 0, 2, 0, 7 },
			new sbyte[] {3, 7, 10, 3, 10, 2, 7, 4, 10, 1, 10, 0, 4, 0, 10 },
			new sbyte[] {1, 10, 2, 8, 7, 4 },
			new sbyte[] {4, 9, 1, 4, 1, 7, 7, 1, 3 },
			new sbyte[] {4, 9, 1, 4, 1, 7, 0, 8, 1, 8, 7, 1 },
			new sbyte[] {4, 0, 3, 7, 4, 3 },
			new sbyte[] {4, 8, 7 },
			new sbyte[] {9, 10, 8, 10, 11, 8 },
			new sbyte[] {3, 0, 9, 3, 9, 11, 11, 9, 10 },
			new sbyte[] {0, 1, 10, 0, 10, 8, 8, 10, 11 },
			new sbyte[] {3, 1, 10, 11, 3, 10 },
			new sbyte[] {1, 2, 11, 1, 11, 9, 9, 11, 8 },
			new sbyte[] {3, 0, 9, 3, 9, 11, 1, 2, 9, 2, 11, 9 },
			new sbyte[] {0, 2, 11, 8, 0, 11 },
			new sbyte[] {3, 2, 11 },
			new sbyte[] {2, 3, 8, 2, 8, 10, 10, 8, 9 },
			new sbyte[] {9, 10, 2, 0, 9, 2 },
			new sbyte[] {2, 3, 8, 2, 8, 10, 0, 1, 8, 1, 10, 8 },
			new sbyte[] {1, 10, 2 },
			new sbyte[] {1, 3, 8, 9, 1, 8 },
			new sbyte[] {0, 9, 1 },
			new sbyte[] {0, 3, 8 },
			new sbyte[] {}
		};
	}
}
