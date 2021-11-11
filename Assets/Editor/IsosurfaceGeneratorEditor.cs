using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(IsosurfaceGenerator))]
public class IsosurfaceGeneratorEditor : Editor
{
	IsosurfaceGenerator generator;
	SerializedProperty threshold;
	SerializedProperty resolution;
	SerializedProperty smooth;
	SerializedProperty meshBounds;
	SerializedProperty autoGenerateBounds;
	SerializedProperty addWallsAtBounds;
	SerializedProperty UVtiling;

	bool areYouSure = false;
	public override void OnInspectorGUI()
	{
		generator = (IsosurfaceGenerator)target;
		GUI.enabled = false;
		//draw the script reference
		EditorGUILayout.ObjectField("Script", MonoScript.FromMonoBehaviour(generator), typeof(IsosurfaceGenerator), false);
		GUI.enabled = true;

		threshold = serializedObject.FindProperty("threshold");
		resolution = serializedObject.FindProperty("resolution");
		smooth = serializedObject.FindProperty("smooth");
		meshBounds = serializedObject.FindProperty("meshBounds");
		autoGenerateBounds = serializedObject.FindProperty("autoGenerateBounds");
		addWallsAtBounds = serializedObject.FindProperty("addWallsAtBounds");
		UVtiling = serializedObject.FindProperty("UVtiling");
		serializedObject.Update();

		EditorGUI.BeginChangeCheck();
			EditorGUILayout.PropertyField(threshold);
			EditorGUILayout.PropertyField(resolution);
		if (EditorGUI.EndChangeCheck())
		{
			generator.GenerateBounds();
		}
		EditorGUILayout.PropertyField(smooth);
		EditorGUILayout.PropertyField(addWallsAtBounds);
		EditorGUILayout.PropertyField(autoGenerateBounds);
		EditorGUILayout.PropertyField(UVtiling, new GUIContent("UV Tiling"));
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
				GameObject newGameObject = new GameObject("IsoSphere");
				newGameObject.transform.parent = generator.transform;
				newGameObject.transform.localPosition = Vector3.zero;
				newGameObject.AddComponent<IsoSphere>();
				Undo.RegisterCreatedObjectUndo(newGameObject, "Undo Create Iso Shape");
			}
			if (GUILayout.Button("Add Meta Rectangle"))
			{
				GameObject newGameObject = new GameObject("IsoRectangle");
				newGameObject.transform.parent = generator.transform;
				newGameObject.transform.localPosition = Vector3.zero;
				newGameObject.AddComponent<IsoRect>();
				Undo.RegisterCreatedObjectUndo(newGameObject, "Undo Create Iso Shape");
			}
		GUILayout.EndHorizontal();

		GUILayout.BeginHorizontal();
			if (GUILayout.Button("Generate Mesh"))
			{
				Undo.RecordObject(generator.GetComponent<MeshFilter>(), "Undo Generate Mesh");
				generator.Generate();
				Undo.FlushUndoRecordObjects();
			}
			if (GUILayout.Button("Clear Mesh"))
			{
				Undo.RecordObject(generator.GetComponent<MeshFilter>(), "Undo Clear Mesh");
				generator.GetComponent<MeshFilter>().sharedMesh = null;
				Undo.FlushUndoRecordObjects();
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
				Undo.IncrementCurrentGroup();
				Undo.SetCurrentGroupName("Undo Remove Generator");
				var undoGroupIndex = Undo.GetCurrentGroup();

				var shapes = generator.GetComponentsInChildren<IsoShape>();
				for (int i = 0; i < shapes.Length; i++)
				{
					Undo.DestroyObjectImmediate(shapes[i]);
				}
				Undo.DestroyObjectImmediate(generator);

				Undo.CollapseUndoOperations(undoGroupIndex);
				return;
			}
		}
		else
		{
			if (GUILayout.Button(new GUIContent("<color=yellow><b>Remove Generator</b></color>"), style))
			{
				areYouSure = true;
			}
		}

		int totalPoints = Mathf.CeilToInt(generator.meshBounds.size.x * generator.resolution) * Mathf.CeilToInt(generator.meshBounds.size.y * generator.resolution) * Mathf.CeilToInt(generator.meshBounds.size.z * generator.resolution);
		if (totalPoints > 100000)
			EditorGUILayout.HelpBox($"Careful! This may take a while to generate (there are {totalPoints} points to sample)", MessageType.Warning);

		GUI.backgroundColor = before;

		serializedObject.ApplyModifiedProperties();
	}
}
