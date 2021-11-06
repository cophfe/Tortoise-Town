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
	SerializedProperty smooth;
	SerializedProperty meshBounds;
	SerializedProperty autoGenerateBounds;
	SerializedProperty addWallsAtBounds;

	bool areYouSure = false;
	public override void OnInspectorGUI()
	{
		generator = (MetaballGenerator)target;
		GUI.enabled = false;
		//draw the script reference
		EditorGUILayout.ObjectField("Script", MonoScript.FromMonoBehaviour(generator), typeof(MetaballGenerator), false);
		GUI.enabled = true;

		threshold = serializedObject.FindProperty("threshold");
		resolution = serializedObject.FindProperty("resolution");
		smooth = serializedObject.FindProperty("smooth");
		meshBounds = serializedObject.FindProperty("meshBounds");
		autoGenerateBounds = serializedObject.FindProperty("autoGenerateBounds");
		addWallsAtBounds = serializedObject.FindProperty("addWallsAtBounds");
		serializedObject.Update();

		EditorGUILayout.PropertyField(threshold);
		EditorGUILayout.PropertyField(resolution);
		EditorGUILayout.PropertyField(smooth);
		EditorGUILayout.PropertyField(addWallsAtBounds);
		EditorGUILayout.PropertyField(autoGenerateBounds);
		if (generator.autoGenerateBounds)
		{
			GUI.enabled = false;
			EditorGUILayout.PropertyField(meshBounds);
			GUI.enabled = true;
		}
		else
		{
			EditorGUILayout.PropertyField(meshBounds);
		}


		GUILayout.BeginHorizontal();
			if (GUILayout.Button("Add Meta Sphere"))
			{
				GameObject newGameObject = new GameObject("MetaSphere");
				newGameObject.transform.parent = generator.transform;
				newGameObject.transform.localPosition = Vector3.zero;
				newGameObject.AddComponent<Metaball>();
			}
			if (GUILayout.Button("Add Meta Rectangle"))
			{
				GameObject newGameObject = new GameObject("MetaRectangle");
				newGameObject.transform.parent = generator.transform;
				newGameObject.transform.localPosition = Vector3.zero;
				newGameObject.AddComponent<MetaRect>();
			}
		GUILayout.EndHorizontal();

		GUILayout.BeginHorizontal();
			if (GUILayout.Button("Generate Mesh"))
			{
				generator.Generate();
			}
			if (GUILayout.Button("Clear Mesh"))
			{
				generator.GetComponent<MeshFilter>().sharedMesh = null;
			}

		GUILayout.EndHorizontal();

		var before = GUI.backgroundColor;
		GUI.backgroundColor = new Color(0.8f,0.2f,0.2f);
		GUIStyle style = new GUIStyle(GUI.skin.button);
		style.richText = true;

		if (areYouSure)
		{
			if (GUILayout.Button(new GUIContent("<color=yellow><b>Are You Sure?</b></color>"), style))
			{
				var shapes = generator.GetComponentsInChildren<MetaShape>();
				for (int i = 0; i < shapes.Length; i++)
				{
					DestroyImmediate(shapes[i]);
				}
				DestroyImmediate(generator);
				return;
			}
		}
		else
		{
			if (GUILayout.Button(new GUIContent("<color=yellow><b>Remove Generator Permanently</b></color>"), style))
			{
				areYouSure = true;
			}
		}
		
		GUI.backgroundColor = before;

		serializedObject.ApplyModifiedProperties();
	}
}
