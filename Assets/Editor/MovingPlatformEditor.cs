using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

//used https://catlikecoding.com/unity/tutorials/curves-and-splines/ for an idea of implementation
//it is quite a bit different though
//this is probably the messiest thing I have ever made

[CustomEditor(typeof(MovingPlatform))]
public class MovingPlatformEditor : Editor
{
	MovingPlatform movingPlatform;
	SerializedProperty startPosition;
	SerializedProperty tangents;
	SerializedProperty points;
	SerializedProperty bezier;
	SerializedProperty loopType;
	SerializedProperty tangentMode;
	
	private void OnEnable()
	{
		startPosition = serializedObject.FindProperty("startPosition");
		tangents = serializedObject.FindProperty("tangents");
		points = serializedObject.FindProperty("points");
		bezier = serializedObject.FindProperty("useBezier");
		loopType = serializedObject.FindProperty("loopType");
		tangentMode = serializedObject.FindProperty("bezierTangentMode");
	}

	public override void OnInspectorGUI()
	{
		base.OnInspectorGUI();
		movingPlatform = target as MovingPlatform;
		
		//Add hidden value if just became loop
		EditorGUI.BeginChangeCheck();
		MovingPlatform.LoopType newType = (MovingPlatform.LoopType)EditorGUILayout.EnumPopup(loopType.displayName, (MovingPlatform.LoopType)loopType.enumValueIndex); ;
		if (EditorGUI.EndChangeCheck() && newType != (MovingPlatform.LoopType)loopType.enumValueIndex)
		{
			if (newType == MovingPlatform.LoopType.LOOP)
			{
				if (points.arraySize == 0)
				{
					Debug.LogWarning("Cannot set platform to loop");
					return;
				}
				points.InsertArrayElementAtIndex(points.arraySize);
				points.GetArrayElementAtIndex(points.arraySize - 1).vector3Value = Vector3.zero;
				tangents.InsertArrayElementAtIndex(tangents.arraySize);
				tangents.GetArrayElementAtIndex(tangents.arraySize - 1).vector3Value = -points.GetArrayElementAtIndex(points.arraySize - 2).vector3Value / 4;
				tangents.InsertArrayElementAtIndex(tangents.arraySize);
				tangents.GetArrayElementAtIndex(tangents.arraySize - 1).vector3Value = points.GetArrayElementAtIndex(points.arraySize - 2).vector3Value / 4;
				RestrainPairedTangent(tangents.arraySize - 3);
				RestrainPairedTangent(0, tangents.arraySize - 1);
			}
			else if ((MovingPlatform.LoopType)loopType.enumValueIndex == MovingPlatform.LoopType.LOOP)
			{
				points.DeleteArrayElementAtIndex(points.arraySize - 1);
				tangents.DeleteArrayElementAtIndex(tangents.arraySize - 1);
				tangents.DeleteArrayElementAtIndex(tangents.arraySize - 1);
			}
			loopType.enumValueIndex = (int)newType;
		}

		//check if useBeziers changed
		EditorGUI.BeginChangeCheck();
		EditorGUILayout.PropertyField(bezier);
		bool bezChanged = EditorGUI.EndChangeCheck();
		
		if (bezier.boolValue)
		{
			//check if tangent mode has changed
			EditorGUI.BeginChangeCheck();
			MovingPlatform.BezierTangentMode newMode = (MovingPlatform.BezierTangentMode)EditorGUILayout.EnumPopup(tangentMode.displayName, (MovingPlatform.BezierTangentMode)tangentMode.enumValueIndex);
			if (EditorGUI.EndChangeCheck() && newMode != (MovingPlatform.BezierTangentMode)tangentMode.enumValueIndex)
			{
				tangentMode.enumValueIndex = (int)newMode;
				for (int i = 1; i < tangents.arraySize - 1; i += 2)
				{
					RestrainPairedTangent(i);
				}
				if ((MovingPlatform.LoopType)loopType.enumValueIndex == MovingPlatform.LoopType.LOOP)
					RestrainPairedTangent(0, tangents.arraySize - 1);
			}
			if (GUILayout.Button(new GUIContent("Reset Curves To Default")) || (bezChanged && tangents.arraySize == 0 && points.arraySize != 0))
			{
				ResetBezierValues();
				SceneView.RepaintAll();
			}
		}
		
		//DRAW POINT ARRAY
		points.isExpanded = EditorGUILayout.Foldout(points.isExpanded, points.displayName);
		if (points.isExpanded)
		{
			EditorGUI.indentLevel += 1;
			int pointDisplayOffset = movingPlatform.loopType == MovingPlatform.LoopType.LOOP ?  - 1: 0; //CHANGE IF LOOPING
			int size = points.arraySize + pointDisplayOffset;
			for (int i = 0; i < size; i++)
			{
				EditorGUILayout.BeginHorizontal();
				EditorGUILayout.PropertyField(points.GetArrayElementAtIndex(i), new GUIContent("Point " + i));

				//REMOVE POINT
				if (GUILayout.Button(new GUIContent("-", "Remove Element"), GUILayout.Width(25)))
				{
					points.DeleteArrayElementAtIndex(i);
					int bezierIndex = 2 * i;
					if (i != tangents.arraySize - 1) bezierIndex++;
					tangents.DeleteArrayElementAtIndex(bezierIndex);
					if (tangents.arraySize > bezierIndex)
						tangents.DeleteArrayElementAtIndex(bezierIndex);
					i--;
					size--;
				}
				EditorGUILayout.EndHorizontal();
			}
			//ADD POINT
			EditorGUILayout.BeginHorizontal();
			GUILayout.Space(15);
			if (GUILayout.Button(new GUIContent("Add New Point", "Add New Element")))
			{
				tangents.InsertArrayElementAtIndex(tangents.arraySize + pointDisplayOffset);
				tangents.GetArrayElementAtIndex(tangents.arraySize + pointDisplayOffset - 1).vector3Value = Vector3.zero;
				tangents.InsertArrayElementAtIndex(tangents.arraySize + pointDisplayOffset);
				tangents.GetArrayElementAtIndex(tangents.arraySize + pointDisplayOffset - 1).vector3Value = Vector3.zero;
				points.InsertArrayElementAtIndex(size);
				if (size - 1 < 0)
				{
					points.GetArrayElementAtIndex(size).vector3Value = Vector3.up * 2;
				}
				else
					points.GetArrayElementAtIndex(size).vector3Value = points.GetArrayElementAtIndex(size -1).vector3Value;
				selectedBezier = false;
				selectedHandle = size;
			}
			EditorGUILayout.EndHorizontal();
			EditorGUI.indentLevel -= 1;
		}
		serializedObject.ApplyModifiedProperties();

	}

	int selectedHandle = 0;
	bool selectedBezier = false;
	private void OnSceneGUI()
	{
		movingPlatform = target as MovingPlatform;
		Transform transform = movingPlatform.transform;
		serializedObject.Update();
		
		Vector3 startPosition;
		if (!Application.isPlaying)
			startPosition = transform.position;
		else
			startPosition = this.startPosition.vector3Value;

		Handles.color = Color.white;

		//DRAW LINES
		if (points.arraySize <= 0) return;

		if (bezier.boolValue)
		{
			//first point
			Vector3 nextPoint = points.GetArrayElementAtIndex(0).vector3Value;
			Handles.DrawBezier(startPosition, startPosition + nextPoint, startPosition + tangents.GetArrayElementAtIndex(0).vector3Value, startPosition + nextPoint+ tangents.GetArrayElementAtIndex(1).vector3Value, Color.white, null, 1);
			//last point
			Vector3 lastPoint = points.arraySize > 1 ? points.GetArrayElementAtIndex(points.arraySize - 2).vector3Value : Vector3.zero;
			nextPoint = points.GetArrayElementAtIndex(points.arraySize - 1).vector3Value;
			Handles.DrawBezier(startPosition + lastPoint, startPosition + nextPoint, startPosition + lastPoint + tangents.GetArrayElementAtIndex(tangents.arraySize - 2).vector3Value, startPosition + nextPoint + tangents.GetArrayElementAtIndex(tangents.arraySize - 1).vector3Value, Color.white, null, 1);
			//middle points
			for (int i = 1; i < movingPlatform.points.Length - 1; i ++)
			{
				lastPoint = points.GetArrayElementAtIndex(i - 1).vector3Value;
				nextPoint = points.GetArrayElementAtIndex(i).vector3Value;
				Handles.DrawBezier(startPosition + lastPoint, startPosition + nextPoint, startPosition + lastPoint + tangents.GetArrayElementAtIndex(2 * i ).vector3Value, startPosition + nextPoint + tangents.GetArrayElementAtIndex(2 * (i) + 1).vector3Value, Color.white, null, 1);
			}
		}
		else
		{
			Handles.DrawLine(startPosition, startPosition + points.GetArrayElementAtIndex(0).vector3Value);
			for (int i = 1; i < movingPlatform.points.Length; i++)
			{
				Handles.DrawLine(startPosition + points.GetArrayElementAtIndex(i - 1).vector3Value, startPosition + points.GetArrayElementAtIndex(i).vector3Value);
			}
		}

		Handles.color = Color.green;
		//DRAW HANDLES
		int length = movingPlatform.loopType == MovingPlatform.LoopType.LOOP ? points.arraySize - 1 : points.arraySize;
		for (int i = 0; i < length; i++)
		{
			float handleSizeModifier = HandleUtility.GetHandleSize(points.GetArrayElementAtIndex(i).vector3Value + startPosition);
			if ((selectedHandle != i || selectedBezier) && Handles.Button(points.GetArrayElementAtIndex(i).vector3Value + startPosition, Quaternion.identity, handleSizeModifier * 0.05f, handleSizeModifier* 0.1f, Handles.DotHandleCap))
			{
				selectedHandle = i;
				selectedBezier = false;
			}

			if (!selectedBezier && selectedHandle == i)
			{
				EditorGUI.BeginChangeCheck();
				Vector3 point = Handles.PositionHandle(points.GetArrayElementAtIndex(i).vector3Value + startPosition, Quaternion.identity);
				if (EditorGUI.EndChangeCheck())
				{
					points.GetArrayElementAtIndex(i).vector3Value = point - startPosition;
				}
			}
		}
		if (bezier.boolValue)
		{
			//DRAW HANDLES & HANDLE LINES
			for (int i = 0; i < tangents.arraySize; i++)
			{
				int controlPointIndex = GetPointIndexFromBezierTangentIndex(i);
				Vector3 controlPoint = controlPointIndex >= 0 ? points.GetArrayElementAtIndex(controlPointIndex).vector3Value : Vector3.zero;
				Vector3 worldPoint = tangents.GetArrayElementAtIndex(i).vector3Value + startPosition + controlPoint;
				Handles.color = Color.green;
				//LINES:
				Handles.DrawLine(controlPoint + startPosition, worldPoint);
				Handles.color = Color.grey;
				//HANDLES:
				float handleSizeModifier = HandleUtility.GetHandleSize(worldPoint);
				if ((selectedHandle != i || !selectedBezier) && Handles.Button(worldPoint, Quaternion.identity, handleSizeModifier * 0.05f, handleSizeModifier * 0.1f, Handles.DotHandleCap))
				{
					selectedHandle = i;
					selectedBezier = true;
				}
				if (selectedBezier && selectedHandle == i)
				{
					EditorGUI.BeginChangeCheck();
					Vector3 point = Handles.PositionHandle(worldPoint, Quaternion.identity);
					if (EditorGUI.EndChangeCheck())
					{
						tangents.GetArrayElementAtIndex(i).vector3Value = point - startPosition - controlPoint;
						if (i >= tangents.arraySize - 1)
						{
							RestrainPairedTangent(tangents.arraySize - 1, 0);
						}
						else if (i == 0)
						{
							RestrainPairedTangent(0, tangents.arraySize - 1);
						}
						else
							RestrainPairedTangent(i);
					}
				}
			}
		}

		serializedObject.ApplyModifiedProperties();
	}

	void ResetBezierValues()
	{
		tangents.arraySize = 2 * (points.arraySize + 1) - 2;
		tangents.GetArrayElementAtIndex(0).vector3Value = points.GetArrayElementAtIndex(0).vector3Value / 4;
		Vector3 lastPoint = points.arraySize > 1 ? points.GetArrayElementAtIndex(points.arraySize - 2).vector3Value : Vector3.zero;
		tangents.GetArrayElementAtIndex(tangents.arraySize - 1).vector3Value = (lastPoint - points.GetArrayElementAtIndex(points.arraySize - 1).vector3Value) / 4;
		int tIndex = 1;
		for (int i = 0; i < points.arraySize - 1; i++)
		{
			lastPoint = i > 0 ? points.GetArrayElementAtIndex(i - 1).vector3Value : Vector3.zero;
			tangents.GetArrayElementAtIndex(tIndex).vector3Value = (lastPoint - points.GetArrayElementAtIndex(i).vector3Value) / 4;
			tangents.GetArrayElementAtIndex(tIndex + 1).vector3Value = (points.GetArrayElementAtIndex(i + 1).vector3Value - points.GetArrayElementAtIndex(i).vector3Value) / 4;
			tIndex += 2;
		}
		RestrainAllTangents();
	}

	int GetPointIndexFromBezierTangentIndex(int index)
	{
		if (index == 0)
		{
			return -1;
		}
		else if (index == tangents.arraySize - 1)
		{
			return points.arraySize - 1;
		}
		else
		{
			return Mathf.FloorToInt((float)(index + 2) / 2 - 1.5f);
		}
	}

	int GetFirstBezierTangentIndexFromPointIndex(int index)
	{
		if (index < 0)
			return 0;
		else
			return 2 * index + 1;
		
	}

	//only works after reset
	void RestrainAllTangents()
	{
		MovingPlatform.BezierTangentMode mode = (MovingPlatform.BezierTangentMode)tangentMode.enumValueIndex;
		if (mode == MovingPlatform.BezierTangentMode.Free) return;

		//if loop, restrain start and end
		if ((MovingPlatform.LoopType)loopType.enumValueIndex == MovingPlatform.LoopType.LOOP)
		{
			RestrainPair(0, tangents.arraySize - 1);
		}

		//restrains all tangents at once
		for (int i = 1; i < tangents.arraySize - 1; i += 2)
		{
			RestrainPair(i, i + 1);
		}

		void RestrainPair(int index1, int index2)
		{
			//get target direction
			Vector3 firstVector = tangents.GetArrayElementAtIndex(index1).vector3Value;
			Vector3 secondVector = tangents.GetArrayElementAtIndex(index2).vector3Value;
			float firstMag = firstVector.magnitude;
			float secondMag = secondVector.magnitude;

			Vector3 direction = Vector3.ProjectOnPlane(firstVector, Vector3.Lerp(firstVector, secondVector, 0.5f)).normalized;
			switch (mode)
			{
				case MovingPlatform.BezierTangentMode.Aligned:
					tangents.GetArrayElementAtIndex(index1).vector3Value = direction * firstMag;
					tangents.GetArrayElementAtIndex(index2).vector3Value = -direction * secondMag;
					break;
				case MovingPlatform.BezierTangentMode.Mirrored:
					tangents.GetArrayElementAtIndex(index1).vector3Value = direction * (firstMag + secondMag) / 2;
					tangents.GetArrayElementAtIndex(index2).vector3Value = -direction * (firstMag + secondMag) / 2;
					break;
			}
		}
	}

	void RestrainPairedTangent(int controlTangentIndex)
	{
		//do not need to constrain first and last
		if (controlTangentIndex >= tangents.arraySize - 1 || controlTangentIndex <= 0) return;

		//Restrain the other tangent on this point based on the control tangent's value
		int modifyIndex;
		//if even, the control index is second
		if (controlTangentIndex % 2 == 0) 
		{ 
			modifyIndex = controlTangentIndex - 1;
		}
		else
		{
			modifyIndex = controlTangentIndex + 1;
		}

		switch ((MovingPlatform.BezierTangentMode)tangentMode.enumValueIndex)
		{
			case MovingPlatform.BezierTangentMode.Aligned:
				tangents.GetArrayElementAtIndex(modifyIndex).vector3Value = -tangents.GetArrayElementAtIndex(controlTangentIndex).vector3Value.normalized 
					* tangents.GetArrayElementAtIndex(modifyIndex).vector3Value.magnitude;
				break;
			case MovingPlatform.BezierTangentMode.Mirrored:
				tangents.GetArrayElementAtIndex(modifyIndex).vector3Value = -tangents.GetArrayElementAtIndex(controlTangentIndex).vector3Value;
				break;
		}
	}

	void RestrainPairedTangent(int controlTangentIndex, int modifyTangentIndex)
	{
		switch ((MovingPlatform.BezierTangentMode)tangentMode.enumValueIndex)
		{
			case MovingPlatform.BezierTangentMode.Aligned:
				tangents.GetArrayElementAtIndex(modifyTangentIndex).vector3Value = -tangents.GetArrayElementAtIndex(controlTangentIndex).vector3Value.normalized
					* tangents.GetArrayElementAtIndex(modifyTangentIndex).vector3Value.magnitude;
				break;
			case MovingPlatform.BezierTangentMode.Mirrored:
				tangents.GetArrayElementAtIndex(modifyTangentIndex).vector3Value = -tangents.GetArrayElementAtIndex(controlTangentIndex).vector3Value;
				break;
		}
	}
}
