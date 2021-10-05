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
	SerializedProperty intermediates;
	SerializedProperty points;
	SerializedProperty bezier;
	SerializedProperty loopType;
	SerializedProperty intermediateType;
	SerializedProperty automaticallyCalculateBezierCurve;
	bool intermediatePointsFoldedOut = true;

	private void OnEnable()
	{
		startPosition = serializedObject.FindProperty("startPosition");
		intermediates = serializedObject.FindProperty("intermediates");
		points = serializedObject.FindProperty("points");
		bezier = serializedObject.FindProperty("useBezier");
		loopType = serializedObject.FindProperty("loopType");
		intermediateType = serializedObject.FindProperty("intermediateType");
		automaticallyCalculateBezierCurve = serializedObject.FindProperty("automaticallyCalculateBezierCurve");
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
				intermediates.InsertArrayElementAtIndex(intermediates.arraySize);
				intermediates.GetArrayElementAtIndex(intermediates.arraySize - 1).vector3Value = -points.GetArrayElementAtIndex(points.arraySize - 2).vector3Value / 4;
				intermediates.InsertArrayElementAtIndex(intermediates.arraySize);
				intermediates.GetArrayElementAtIndex(intermediates.arraySize - 1).vector3Value = points.GetArrayElementAtIndex(points.arraySize - 2).vector3Value / 4;
				if (automaticallyCalculateBezierCurve.boolValue)
				{
					ResetBezierValues();
				}
				else
				{
					RestrainPairedPoint(intermediates.arraySize - 3);
					RestrainPairedPoint(0, intermediates.arraySize - 1);
				}
			}
			else if ((MovingPlatform.LoopType)loopType.enumValueIndex == MovingPlatform.LoopType.LOOP)
			{
				points.DeleteArrayElementAtIndex(points.arraySize - 1);
				intermediates.DeleteArrayElementAtIndex(intermediates.arraySize - 1);
				intermediates.DeleteArrayElementAtIndex(intermediates.arraySize - 1);
			}
			loopType.enumValueIndex = (int)newType;
		}

		//DRAW POINT ARRAY
		points.isExpanded = EditorGUILayout.Foldout(points.isExpanded, points.displayName);
		if (points.isExpanded)
		{
			EditorGUI.indentLevel += 1;
			int pointDisplayOffset = movingPlatform.loopType == MovingPlatform.LoopType.LOOP ? -1 : 0; //CHANGE IF LOOPING
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
					if (i != intermediates.arraySize - 1) bezierIndex++;
					intermediates.DeleteArrayElementAtIndex(bezierIndex);
					if (intermediates.arraySize > bezierIndex)
						intermediates.DeleteArrayElementAtIndex(bezierIndex);
					else
						intermediates.DeleteArrayElementAtIndex(bezierIndex - 1);
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
				intermediates.InsertArrayElementAtIndex(intermediates.arraySize + pointDisplayOffset);
				intermediates.GetArrayElementAtIndex(intermediates.arraySize + pointDisplayOffset - 1).vector3Value = Vector3.zero;
				intermediates.InsertArrayElementAtIndex(intermediates.arraySize + pointDisplayOffset);
				intermediates.GetArrayElementAtIndex(intermediates.arraySize + pointDisplayOffset - 1).vector3Value = Vector3.zero;
				points.InsertArrayElementAtIndex(size);
				if (size - 1 < 0)
				{
					points.GetArrayElementAtIndex(size).vector3Value = Vector3.up * 2;
				}
				else
					points.GetArrayElementAtIndex(size).vector3Value = points.GetArrayElementAtIndex(size - 1).vector3Value;
				selectedBezier = false;
				selectedHandle = size;
			}
			EditorGUILayout.EndHorizontal();
			EditorGUI.indentLevel -= 1;
		}

		//check if useBeziers changed
		EditorGUILayout.LabelField("Curve Settings:", EditorStyles.boldLabel);
		EditorGUI.BeginChangeCheck();
		EditorGUILayout.PropertyField(bezier);
		bool bezChanged = EditorGUI.EndChangeCheck();
		if (bezier.boolValue)
		{
			EditorGUI.BeginChangeCheck();
			EditorGUILayout.PropertyField(automaticallyCalculateBezierCurve);
			if (EditorGUI.EndChangeCheck())
			{
				if (automaticallyCalculateBezierCurve.boolValue)
				{
					ResetBezierValues();
				}
				Repaint();
			}
			//DRAW INTERMEDIATE MODE
			EditorGUI.BeginChangeCheck();
			MovingPlatform.IntermediateControlPointType newMode = (MovingPlatform.IntermediateControlPointType)EditorGUILayout.EnumPopup(intermediateType.displayName, (MovingPlatform.IntermediateControlPointType)intermediateType.enumValueIndex);
			if (EditorGUI.EndChangeCheck() && newMode != (MovingPlatform.IntermediateControlPointType)intermediateType.enumValueIndex)
			{
				intermediateType.enumValueIndex = (int)newMode;
				for (int i = 1; i < intermediates.arraySize - 1; i += 2)
				{
					RestrainPairedPoint(i);
				}
				if ((MovingPlatform.LoopType)loopType.enumValueIndex == MovingPlatform.LoopType.LOOP)
					RestrainPairedPoint(0, intermediates.arraySize - 1);
			}
			//DRAW SELECTED VECTOR
			if (intermediates.arraySize > 0 && !automaticallyCalculateBezierCurve.boolValue)
			{
				if (selectedBezier)
				{
					var selected = intermediates.GetArrayElementAtIndex(selectedHandle);

					EditorGUI.BeginChangeCheck();
					var newValue = EditorGUILayout.Vector3Field(new GUIContent("Selected Intermediate Point", "Currently selected control point (relative to attached point)"), selected.vector3Value);
					if (EditorGUI.EndChangeCheck())
					{
						selected.vector3Value = newValue;
						if (selectedHandle >= intermediates.arraySize - 1 && (MovingPlatform.LoopType)loopType.enumValueIndex == MovingPlatform.LoopType.LOOP)
						{
							RestrainPairedPoint(intermediates.arraySize - 1, 0);
						}
						else if (selectedHandle == 0 && (MovingPlatform.LoopType)loopType.enumValueIndex == MovingPlatform.LoopType.LOOP)
						{
							RestrainPairedPoint(0, intermediates.arraySize - 1);
						}
						else
							RestrainPairedPoint(selectedHandle);
					}
				}
				else
				{
					intermediatePointsFoldedOut = EditorGUILayout.BeginFoldoutHeaderGroup(intermediatePointsFoldedOut, "Attached Intermediate Points: ");
					if (intermediatePointsFoldedOut)
					{
						EditorGUI.indentLevel += 1;
						if (intermediates.arraySize > 2 * selectedHandle + 1)
						{
							int index = 2 * selectedHandle + 1;
							EditorGUI.BeginChangeCheck();
							var newValue = EditorGUILayout.Vector3Field(new GUIContent("Intermediate Point"), intermediates.GetArrayElementAtIndex(index).vector3Value);
							if (EditorGUI.EndChangeCheck())
							{
								intermediates.GetArrayElementAtIndex(index).vector3Value = newValue;
								RestrainPairedPoint(index);
							}
						}
						if (intermediates.arraySize > 2 * selectedHandle + 2)
						{
							int index = 2 * selectedHandle + 2;
							EditorGUI.BeginChangeCheck();
							var newValue = EditorGUILayout.Vector3Field(new GUIContent("Intermediate Point"), intermediates.GetArrayElementAtIndex(index).vector3Value);
							if (EditorGUI.EndChangeCheck())
							{
								intermediates.GetArrayElementAtIndex(index).vector3Value = newValue;
								RestrainPairedPoint(index);
							}
						}
						EditorGUI.indentLevel -= 1;
					}
					
					EditorGUILayout.EndFoldoutHeaderGroup();
				}
			}
			
			if (!automaticallyCalculateBezierCurve.boolValue && GUILayout.Button(new GUIContent("Set Curves To Default")) || (bezChanged && intermediates.arraySize == 0 && points.arraySize != 0))
			{
				ResetBezierValues();
				selectedHandle = 0;
				SceneView.RepaintAll();
			}
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

		if (bezier.boolValue && intermediates.arraySize > 0)
		{
			//first point
			Vector3 nextPoint = points.GetArrayElementAtIndex(0).vector3Value;
			Handles.DrawBezier(startPosition, startPosition + nextPoint, startPosition + intermediates.GetArrayElementAtIndex(0).vector3Value, startPosition + nextPoint+ intermediates.GetArrayElementAtIndex(1).vector3Value, Color.white, null, 1);
			//last point
			Vector3 lastPoint = points.arraySize > 1 ? points.GetArrayElementAtIndex(points.arraySize - 2).vector3Value : Vector3.zero;
			nextPoint = points.GetArrayElementAtIndex(points.arraySize - 1).vector3Value;
			Handles.DrawBezier(startPosition + lastPoint, startPosition + nextPoint, startPosition + lastPoint + intermediates.GetArrayElementAtIndex(intermediates.arraySize - 2).vector3Value, startPosition + nextPoint + intermediates.GetArrayElementAtIndex(intermediates.arraySize - 1).vector3Value, Color.white, null, 1);
			//middle points
			for (int i = 1; i < movingPlatform.points.Length - 1; i ++)
			{
				lastPoint = points.GetArrayElementAtIndex(i - 1).vector3Value;
				nextPoint = points.GetArrayElementAtIndex(i).vector3Value;
				Handles.DrawBezier(startPosition + lastPoint, startPosition + nextPoint, startPosition + lastPoint + intermediates.GetArrayElementAtIndex(2 * i ).vector3Value, startPosition + nextPoint + intermediates.GetArrayElementAtIndex(2 * (i) + 1).vector3Value, Color.white, null, 1);
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
				Repaint();
			}

			if (!selectedBezier && selectedHandle == i)
			{
				EditorGUI.BeginChangeCheck();
				Vector3 point = Handles.PositionHandle(points.GetArrayElementAtIndex(i).vector3Value + startPosition, Quaternion.identity);
				if (EditorGUI.EndChangeCheck())
				{
					points.GetArrayElementAtIndex(i).vector3Value = point - startPosition;
					if (automaticallyCalculateBezierCurve.boolValue)
						ResetBezierValues();
				}
			}
		}
		if (bezier.boolValue)
		{
			//DRAW HANDLE LINES
			for (int i = 0; i < intermediates.arraySize; i++)
			{
				int controlPointIndex = GetPointIndexFromIntermediateIndex(i);
				Vector3 controlPoint = controlPointIndex >= 0 ? points.GetArrayElementAtIndex(controlPointIndex).vector3Value : Vector3.zero;
				Vector3 worldPoint = intermediates.GetArrayElementAtIndex(i).vector3Value + startPosition + controlPoint;
				Handles.color = Color.green;
				//LINES:
				Handles.DrawLine(controlPoint + startPosition, worldPoint);
			}

			//HANDLES:
			if (!automaticallyCalculateBezierCurve.boolValue)
			{
				for (int i = 0; i < intermediates.arraySize; i++)
				{
					int controlPointIndex = GetPointIndexFromIntermediateIndex(i);
					Vector3 controlPoint = controlPointIndex >= 0 ? points.GetArrayElementAtIndex(controlPointIndex).vector3Value : Vector3.zero;
					Vector3 worldPoint = intermediates.GetArrayElementAtIndex(i).vector3Value + startPosition + controlPoint;
					Handles.color = Color.grey;
					float handleSizeModifier = HandleUtility.GetHandleSize(worldPoint);
					if ((selectedHandle != i || !selectedBezier) && Handles.Button(worldPoint, Quaternion.identity, handleSizeModifier * 0.05f, handleSizeModifier * 0.1f, Handles.DotHandleCap))
					{
						selectedHandle = i;
						selectedBezier = true;
						Repaint();
					}
					if (selectedBezier && selectedHandle == i)
					{
						EditorGUI.BeginChangeCheck();
						Vector3 point = Handles.PositionHandle(worldPoint, Quaternion.identity);
						if (EditorGUI.EndChangeCheck())
						{
							intermediates.GetArrayElementAtIndex(i).vector3Value = point - startPosition - controlPoint;

							if (i >= intermediates.arraySize - 1 && (MovingPlatform.LoopType)loopType.enumValueIndex == MovingPlatform.LoopType.LOOP)
							{
								RestrainPairedPoint(intermediates.arraySize - 1, 0);
							}
							else if (i == 0 && (MovingPlatform.LoopType)loopType.enumValueIndex == MovingPlatform.LoopType.LOOP)
							{
								RestrainPairedPoint(0, intermediates.arraySize - 1);
							}
							else
								RestrainPairedPoint(i);
						}
					}
				}
			}			
		}

		serializedObject.ApplyModifiedProperties();
	}

	void ResetBezierValues()
	{
		intermediates.arraySize = 2 * (points.arraySize + 1) - 2;
		intermediates.GetArrayElementAtIndex(0).vector3Value = points.GetArrayElementAtIndex(0).vector3Value / 4;
		Vector3 lastPoint = points.arraySize > 1 ? points.GetArrayElementAtIndex(points.arraySize - 2).vector3Value : Vector3.zero;
		intermediates.GetArrayElementAtIndex(intermediates.arraySize - 1).vector3Value = (lastPoint - points.GetArrayElementAtIndex(points.arraySize - 1).vector3Value) / 4;
		int tIndex = 1;
		for (int i = 0; i < points.arraySize - 1; i++)
		{
			lastPoint = i > 0 ? points.GetArrayElementAtIndex(i - 1).vector3Value : Vector3.zero;
			intermediates.GetArrayElementAtIndex(tIndex).vector3Value = (lastPoint - points.GetArrayElementAtIndex(i).vector3Value) / 4;
			intermediates.GetArrayElementAtIndex(tIndex + 1).vector3Value = (points.GetArrayElementAtIndex(i + 1).vector3Value - points.GetArrayElementAtIndex(i).vector3Value) / 4;
			tIndex += 2;
		}
		RestrainAllIntermediates();
	}

	int GetPointIndexFromIntermediateIndex(int index)
	{
		if (index == 0)
		{
			return -1;
		}
		else if (index == intermediates.arraySize - 1)
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
	void RestrainAllIntermediates()
	{
		MovingPlatform.IntermediateControlPointType mode = (MovingPlatform.IntermediateControlPointType)intermediateType.enumValueIndex;
		if (mode == MovingPlatform.IntermediateControlPointType.Free) return;

		//if loop, restrain start and end
		if ((MovingPlatform.LoopType)loopType.enumValueIndex == MovingPlatform.LoopType.LOOP)
		{
			RestrainPair(0, intermediates.arraySize - 1);
		}

		//restrains all tangents at once
		for (int i = 1; i < intermediates.arraySize - 1; i += 2)
		{
			RestrainPair(i, i + 1);
		}

		void RestrainPair(int index1, int index2)
		{
			//get target direction
			Vector3 firstVector = intermediates.GetArrayElementAtIndex(index1).vector3Value;
			Vector3 secondVector = intermediates.GetArrayElementAtIndex(index2).vector3Value;
			float firstMag = firstVector.magnitude;
			float secondMag = secondVector.magnitude;

			Vector3 direction = Vector3.ProjectOnPlane(firstVector, Vector3.Lerp(firstVector, secondVector, 0.5f)).normalized;
			switch (mode)
			{
				case MovingPlatform.IntermediateControlPointType.Aligned:
					intermediates.GetArrayElementAtIndex(index1).vector3Value = direction * firstMag;
					intermediates.GetArrayElementAtIndex(index2).vector3Value = -direction * secondMag;
					break;
				case MovingPlatform.IntermediateControlPointType.Mirrored:
					intermediates.GetArrayElementAtIndex(index1).vector3Value = direction * (firstMag + secondMag) / 2;
					intermediates.GetArrayElementAtIndex(index2).vector3Value = -direction * (firstMag + secondMag) / 2;
					break;
			}
		}
	}

	void RestrainPairedPoint(int controlTangentIndex)
	{
		//do not need to constrain first and last
		if (controlTangentIndex >= intermediates.arraySize - 1 || controlTangentIndex <= 0) return;

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

		switch ((MovingPlatform.IntermediateControlPointType)intermediateType.enumValueIndex)
		{
			case MovingPlatform.IntermediateControlPointType.Aligned:
				intermediates.GetArrayElementAtIndex(modifyIndex).vector3Value = -intermediates.GetArrayElementAtIndex(controlTangentIndex).vector3Value.normalized 
					* intermediates.GetArrayElementAtIndex(modifyIndex).vector3Value.magnitude;
				break;
			case MovingPlatform.IntermediateControlPointType.Mirrored:
				intermediates.GetArrayElementAtIndex(modifyIndex).vector3Value = -intermediates.GetArrayElementAtIndex(controlTangentIndex).vector3Value;
				break;
		}
	}

	void RestrainPairedPoint(int controlTangentIndex, int modifyTangentIndex)
	{
		switch ((MovingPlatform.IntermediateControlPointType)intermediateType.enumValueIndex)
		{
			case MovingPlatform.IntermediateControlPointType.Aligned:
				intermediates.GetArrayElementAtIndex(modifyTangentIndex).vector3Value = -intermediates.GetArrayElementAtIndex(controlTangentIndex).vector3Value.normalized
					* intermediates.GetArrayElementAtIndex(modifyTangentIndex).vector3Value.magnitude;
				break;
			case MovingPlatform.IntermediateControlPointType.Mirrored:
				intermediates.GetArrayElementAtIndex(modifyTangentIndex).vector3Value = -intermediates.GetArrayElementAtIndex(controlTangentIndex).vector3Value;
				break;
		}
	}
}
