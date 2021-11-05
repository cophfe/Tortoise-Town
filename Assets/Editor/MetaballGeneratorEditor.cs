using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(MetaballGenerator))]
public class MetaballGeneratorEditor : Editor
{
	MetaballGenerator generator;
	SerializedProperty threshold;
	SerializedProperty resolution;

	private void Awake()
	{
		generator = (MetaballGenerator)target;
		threshold = serializedObject.FindProperty("threshold");
		resolution = serializedObject.FindProperty("resolution");
	}

	public override void OnInspectorGUI()
	{
		serializedObject.Update();

		EditorGUILayout.PropertyField(threshold);
		EditorGUILayout.PropertyField(resolution);
		EditorGUI.BeginChangeCheck();
		var newExtents = EditorGUILayout.Vector3Field("Extents", generator.meshBounds.extents);
		if (EditorGUI.EndChangeCheck())
		{
			generator.meshBounds.extents = newExtents;
		}

		if (GUILayout.Button("Add Mesh Sphere"))
		{
			GameObject newGameObject = new GameObject("MetaSphere");
			newGameObject.transform.parent = generator.transform;
			newGameObject.transform.localPosition = Vector3.zero;
			newGameObject.AddComponent<Metaball>();
		}

		GUILayout.BeginHorizontal();
			if (GUILayout.Button("Generate Mesh"))
			{
				if (generator.metaShapes.Count > 0)
				{
					generator.GenerateMeta();
					generator.GenerateMesh();
				}
			}
			if (GUILayout.Button("Clear Mesh"))
			{
				if (generator.metaShapes.Count > 0)
				{
					generator.GenerateMeta();
					generator.GenerateMesh();
				}
			}
		GUILayout.EndHorizontal();
		serializedObject.ApplyModifiedProperties();
	}
}
