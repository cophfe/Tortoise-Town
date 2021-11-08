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
	SerializedProperty UVtiling;
	SerializedProperty useParallel;

	bool areYouSure = false;

	private void OnEnable()
	{
		threshold = serializedObject.FindProperty("threshold");
		resolution = serializedObject.FindProperty("resolution");
		smooth = serializedObject.FindProperty("smooth");
		meshBounds = serializedObject.FindProperty("meshBounds");
		autoGenerateBounds = serializedObject.FindProperty("autoGenerateBounds");
		UVtiling = serializedObject.FindProperty("UVtiling");
		useParallel = serializedObject.FindProperty("useParallel");
		generator = (IsosurfaceGenerator)target;
		generator.GenerateBounds();
	}
	public override void OnInspectorGUI()
	{
		GUI.enabled = false;
		//draw the script reference
		EditorGUILayout.ObjectField("Script", MonoScript.FromMonoBehaviour(generator), typeof(IsosurfaceGenerator), false);
		GUI.enabled = true;

		
		serializedObject.Update();

		EditorGUI.BeginChangeCheck();
			EditorGUILayout.PropertyField(threshold);
			EditorGUILayout.PropertyField(resolution);
		if (EditorGUI.EndChangeCheck())
		{
			generator.GenerateBounds();
		}
		EditorGUILayout.PropertyField(smooth);
		EditorGUILayout.PropertyField(autoGenerateBounds);
		EditorGUILayout.PropertyField(UVtiling, new GUIContent("UV Tiling"));
		EditorGUILayout.PropertyField(useParallel);
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

		Vector3Int extents = new Vector3Int(Mathf.CeilToInt(generator.meshBounds.size.x * generator.resolution), Mathf.CeilToInt(generator.meshBounds.size.y * generator.resolution), Mathf.CeilToInt(generator.meshBounds.size.z * generator.resolution));
		int totalPoints = extents.x * extents.y * extents.z;
		if (totalPoints > 100000)
			EditorGUILayout.HelpBox($"Careful! This may take a while to generate.\n" +
				$"The estimated sample amount is {totalPoints} (x: {extents.x} y: {extents.y} z: {extents.z}", MessageType.Warning);
		else
			EditorGUILayout.HelpBox($"The estimated sample amount is {totalPoints} (x: {extents.x} y: {extents.y} z: {extents.z})", MessageType.Info);

		GUI.backgroundColor = before;

		serializedObject.ApplyModifiedProperties();
	}
}
