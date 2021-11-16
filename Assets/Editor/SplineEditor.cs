using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(Spline))]
public class SplineEditor : Editor
{
	Spline spline;
	Transform splineTransform;
	SerializedProperty controlPoints;
	SerializedProperty loop;
	SerializedProperty restrainType;
	int selectedHandle = 0;
	bool dragMode = false;

	private void OnEnable()
	{
		spline = target as Spline;
		controlPoints = serializedObject.FindProperty("controlPoints");
		loop = serializedObject.FindProperty("loop");
		restrainType = serializedObject.FindProperty("restrainType");
		splineTransform = spline.transform;
	}

	public override void OnInspectorGUI()
	{
		GUI.enabled = false;
		//draw the script reference
		EditorGUILayout.ObjectField("Script", MonoScript.FromMonoBehaviour(spline), typeof(Spline), false);
		GUI.enabled = true;

		serializedObject.Update();

		//draw loop toggle
		bool loopValue = loop.boolValue;
		if (EditorGUILayout.Toggle("Looping:", loopValue) != loopValue)
		{
			loop.boolValue = !loopValue;
			//if just was looping, remove the last curve
			if (loopValue)
			{
				controlPoints.DeleteArrayElementAtIndex(controlPoints.arraySize - 1);
				controlPoints.DeleteArrayElementAtIndex(controlPoints.arraySize - 1);
				controlPoints.DeleteArrayElementAtIndex(controlPoints.arraySize - 1);
			}
			//if just became looping, add curve where last point is end point 
			else
			{
				AddCurve();
				//end point is at start to complete loop
				controlPoints.GetArrayElementAtIndex(controlPoints.arraySize - 1).vector3Value = Vector3.zero;
				//intermediate is same as index 1 but inversed
				controlPoints.GetArrayElementAtIndex(controlPoints.arraySize - 2).vector3Value = -controlPoints.GetArrayElementAtIndex(1).vector3Value;
			}
		}

		//draw restrain type
		EditorGUI.BeginChangeCheck();
		Spline.RestrainType newMode = (Spline.RestrainType)EditorGUILayout.EnumPopup(restrainType.displayName, (MovingPlatform.IntermediateControlPointType)restrainType.enumValueIndex);
		if (EditorGUI.EndChangeCheck() && newMode != (Spline.RestrainType)restrainType.enumValueIndex)
		{
			restrainType.enumValueIndex = (int)newMode;
			//restrain everything
			for (int i = 0; i < controlPoints.arraySize - 1; i += 3)
			{
				RestrainOtherIntermediate(i + 1);
			}
		}
		//Draw information about the selected point
		if (selectedHandle > 0)
		{
			EditorGUILayout.BeginHorizontal();
			{
				EditorGUILayout.PropertyField(controlPoints.GetArrayElementAtIndex(selectedHandle), new GUIContent("Selected Control Point:"));
				//there cannot be any less points than 4
				if (controlPoints.arraySize <= 4)
				{
					GUI.enabled = false;
					//draw disabled option to delete point (with different description)
					if (GUILayout.Button(new GUIContent("-", "You cannot have any less than 4 points."), GUILayout.Width(25)))
					{
						controlPoints.DeleteArrayElementAtIndex(selectedHandle);
					}
					GUI.enabled = true;

				}
				else
				{
					//draw option to delete point
					if (GUILayout.Button(new GUIContent("-", "Remove Curve"), GUILayout.Width(25)))
					{
						controlPoints.DeleteArrayElementAtIndex(selectedHandle);
					}
				}

			}
			EditorGUILayout.EndHorizontal();
		}
		else
		{
			EditorGUILayout.LabelField("Select a point for additional information");
		}

		bool newDragMode = EditorGUILayout.Toggle("Enable Dragging:", dragMode);
		if (newDragMode != dragMode)
		{
			dragMode = newDragMode;

			if (newDragMode)
			{
				SceneView.RepaintAll();
				selectedHandle = 0;
			}
		}

		EditorGUILayout.BeginHorizontal();
		//Draw button for adding a new curve
		if (GUILayout.Button(new GUIContent("Add Curve", "Adds three control points")))
		{
			AddCurve();
		}
		//draw a button to reset the curve
		if (GUILayout.Button(new GUIContent("Reset All", "Resets to the 4 initial points")))
		{
			int size = controlPoints.arraySize;

			loop.boolValue = false;
			for (int i = 4; i < size; i++)
			{
				controlPoints.DeleteArrayElementAtIndex(4);
			}
			//reset initial values
			controlPoints.GetArrayElementAtIndex(0).vector3Value = Vector3.zero;
			controlPoints.GetArrayElementAtIndex(1).vector3Value = Vector3.forward * 0.25f;
			controlPoints.GetArrayElementAtIndex(2).vector3Value = Vector3.forward * 0.75f;
			controlPoints.GetArrayElementAtIndex(3).vector3Value = Vector3.forward * 1;
			selectedHandle = 0;
		}
		EditorGUILayout.EndHorizontal();

		//apply changes
		serializedObject.ApplyModifiedProperties();
	}

	private void OnSceneGUI()
	{
		serializedObject.Update();

		//draw the bezier curves themselves
		for (int i = 0; i < controlPoints.arraySize - 1; i += 3)
		{
			Vector3 start = splineTransform.TransformPoint(controlPoints.GetArrayElementAtIndex(i).vector3Value);
			Vector3 end = splineTransform.TransformPoint(controlPoints.GetArrayElementAtIndex(i + 3).vector3Value);
			Vector3 startTangent = splineTransform.TransformPoint(controlPoints.GetArrayElementAtIndex(i + 1).vector3Value);
			Vector3 endTangent = splineTransform.TransformPoint(controlPoints.GetArrayElementAtIndex(i + 2).vector3Value);
			Handles.DrawBezier(start, end, startTangent, endTangent, Color.white, null, 3);
		}
		//draw lines from through point to intermediate point
		Handles.color = Color.green;
		for (int i = 1; i < controlPoints.arraySize - 1; i += 3)
		{
			var throughPoint = controlPoints.GetArrayElementAtIndex(i - 1);
			var intermediatePoint = controlPoints.GetArrayElementAtIndex(i);
			Handles.DrawLine(spline.transform.TransformPoint(intermediatePoint.vector3Value), spline.transform.TransformPoint(throughPoint.vector3Value));

			throughPoint = controlPoints.GetArrayElementAtIndex(i + 2);
			intermediatePoint = controlPoints.GetArrayElementAtIndex(i + 1);
			Handles.DrawLine(spline.transform.TransformPoint(intermediatePoint.vector3Value), spline.transform.TransformPoint(throughPoint.vector3Value));
		}

		//draw the handles to the screen. The first point is controlled by the gameObject handle
		int loopingSize = controlPoints.arraySize;
		if (loop.boolValue) loopingSize--;
		for (int i = 1; i < loopingSize; i++)
		{
			var controlPoint = controlPoints.GetArrayElementAtIndex(i);
			Vector3 controlPointValue = controlPoint.vector3Value;
			Vector3 globalPointValue = spline.transform.TransformPoint(controlPointValue);

			float handleSizeModifier = HandleUtility.GetHandleSize(globalPointValue);
			if (i == selectedHandle)
			{
				//Draw the current selected handle
				EditorGUI.BeginChangeCheck();
				Vector3 point = Handles.PositionHandle(globalPointValue, Quaternion.identity);
				if (EditorGUI.EndChangeCheck())
				{
					Vector3 newValue = spline.transform.InverseTransformPoint(point);
					controlPoint.vector3Value = newValue;
					//if it is a through point move the intermediate points 'attached' to it
					if (!IsIntermediate(i))
					{
						Vector3 changeInValue = newValue - controlPointValue;
						controlPoints.GetArrayElementAtIndex(i - 1).vector3Value = controlPoints.GetArrayElementAtIndex(i - 1).vector3Value + changeInValue;


						//if it is the last one there is only one attached point
						if (i != controlPoints.arraySize - 1)
						{
							controlPoints.GetArrayElementAtIndex(i + 1).vector3Value = controlPoints.GetArrayElementAtIndex(i + 1).vector3Value + changeInValue;
						}
					}
					//if it is an intermediate restrain the second point
					else
					{
						RestrainOtherIntermediate(i);
					}
					Repaint();
				}
			}
			else
			{
				if (IsIntermediate(i))
					Handles.color = Color.green;
				else
					Handles.color = Color.white;

				
				if (dragMode)
				{
					EditorGUI.BeginChangeCheck();
					Vector3 point = Handles.FreeMoveHandle(globalPointValue, Quaternion.identity, handleSizeModifier * 0.05f, Vector3.one * 0.25f, Handles.DotHandleCap);
					if (EditorGUI.EndChangeCheck())
					{
						Vector3 newValue = spline.transform.InverseTransformPoint(point);
						controlPoint.vector3Value = newValue;
						//if it is a through point move the intermediate points 'attached' to it
						if (!IsIntermediate(i))
						{
							Vector3 changeInValue = newValue - controlPointValue;
							controlPoints.GetArrayElementAtIndex(i - 1).vector3Value = controlPoints.GetArrayElementAtIndex(i - 1).vector3Value + changeInValue;


							//if it is the last one there is only one attached point
							if (i != controlPoints.arraySize - 1)
							{
								controlPoints.GetArrayElementAtIndex(i + 1).vector3Value = controlPoints.GetArrayElementAtIndex(i + 1).vector3Value + changeInValue;
							}
						}
						//if it is an intermediate restrain the second point
						else
						{
							RestrainOtherIntermediate(i);
						}
						Repaint();
					}
				}
				else if (Handles.Button(globalPointValue, Quaternion.identity, handleSizeModifier * 0.05f, handleSizeModifier * 0.1f, Handles.DotHandleCap))
				{
					selectedHandle = i;
					Repaint();
				}
			}
		}
		serializedObject.ApplyModifiedProperties();
	}

	bool IsIntermediate(int index)
	{
		int size = controlPoints.arraySize;
		return index % 3 != 0;
	}

	int GetAttachedThroughPointIndex(int intermediateIndex)
	{
		if (IsIntermediate(intermediateIndex))
		{
			if (intermediateIndex % 2 == 1)
				return intermediateIndex - 1;
			else
				return intermediateIndex + 1;
		}
		else
		{
			return intermediateIndex;
		}
	}

	void AddCurve()
	{
		int size = controlPoints.arraySize;
		//add intermediate points
		controlPoints.InsertArrayElementAtIndex(size);
		controlPoints.InsertArrayElementAtIndex(size + 1);
		//add end points
		controlPoints.InsertArrayElementAtIndex(size + 2);
		//set values
		Vector3 valueOfLastControl = controlPoints.GetArrayElementAtIndex(size - 1).vector3Value;
		Vector3 relativeValueOfLastIntermediate = controlPoints.GetArrayElementAtIndex(size - 2).vector3Value - valueOfLastControl;
		Vector3 newValueOfIntermediate1 = valueOfLastControl - relativeValueOfLastIntermediate;
		Vector3 newValueOfControl = valueOfLastControl - relativeValueOfLastIntermediate.normalized * 5;
		controlPoints.GetArrayElementAtIndex(size).vector3Value = newValueOfIntermediate1;
		controlPoints.GetArrayElementAtIndex(size + 1).vector3Value = newValueOfControl + relativeValueOfLastIntermediate;
		controlPoints.GetArrayElementAtIndex(size + 2).vector3Value = newValueOfControl;
	}


	//Restrain a point based on the value of another point
	void RestrainOtherIntermediate(int intermediateIndex)
	{
		if (!IsIntermediate(intermediateIndex) || restrainType.enumValueIndex == (int)Spline.RestrainType.NONE) return;

		int otherIndex;
		int attachedThroughPointIndex;
		//regular cases
		if (intermediateIndex % 3 == 1)
		{
			otherIndex = intermediateIndex - 2;
			attachedThroughPointIndex = intermediateIndex - 1;
		}
		else
		{
			otherIndex = intermediateIndex + 2;
			attachedThroughPointIndex = intermediateIndex + 1;
		}
		//special cases for looping
		if (loop.boolValue)
		{
			if (intermediateIndex == controlPoints.arraySize - 2)
			{
				attachedThroughPointIndex = 0;
				otherIndex = 1;
			}
			else if (intermediateIndex == 1)
			{
				attachedThroughPointIndex = 0;
				otherIndex = controlPoints.arraySize - 2;
			}
		}
		else if (intermediateIndex == 1 || intermediateIndex == controlPoints.arraySize - 2)
			return;
		
		

		Vector3 valueOfControl = controlPoints.GetArrayElementAtIndex(attachedThroughPointIndex).vector3Value;
		Vector3 relativeValueOfIntermediate = controlPoints.GetArrayElementAtIndex(intermediateIndex).vector3Value - valueOfControl;

		switch ((Spline.RestrainType)restrainType.enumValueIndex)
		{
			case Spline.RestrainType.NONE:
				//do nothing
				return;
			case Spline.RestrainType.ALIGNED:
				//set it to have the same direction
				Vector3 aligned = relativeValueOfIntermediate.normalized * (controlPoints.GetArrayElementAtIndex(otherIndex).vector3Value - valueOfControl).magnitude;
				controlPoints.GetArrayElementAtIndex(otherIndex).vector3Value = valueOfControl - aligned;
				break;
			case Spline.RestrainType.MIRRORED:
				//set it to have the same direction and magnitude
				controlPoints.GetArrayElementAtIndex(otherIndex).vector3Value = valueOfControl - relativeValueOfIntermediate;
				break;
		}
		
	}
}
