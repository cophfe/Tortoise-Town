﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.InputSystem.EnhancedTouch;
using TMPro;

[RequireComponent(typeof(Camera)),DefaultExecutionOrder(-1)]
public partial class OldCameraController : MonoBehaviour
{
	//INSPECTOR STUFF
	//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	[Header("Behaviour")]
	[Tooltip("The target to orbit around.")]
	public Transform target;

	[Tooltip("Contains data about the camera. These values cannot be changed at runtime, but the cameraData itself can be changed.")]
	public CameraData defaultCameraData;

	[Header("Control")]
	[Space(5)]
	[Tooltip("Whether the camera accepts input or not.")]
	public bool enableInput = true;
	
	[Tooltip("If input is inverted or not.")]
	public bool inverted = false;
	[Tooltip("The camera sensitivity multiplier.")]
	[Range(0, 1)] public float sensitivity = 0.1f;
	
	public MovementUpdateType movementUpdateType = MovementUpdateType.LATEUPDATE;
	//[Tooltip("The max amount the camera will turn to look away from the floor.")]
	//public float cameraAvoidFloorRotationPower = 15;
	//[Tooltip("The angular distance in which the camera avoids the floor.")]
	//public float cameraAvoidFloorRotationAngleRange = 30;
	
	[Tooltip("Propertional to the speed camera shake deteriorates")]
	public float shakeDeteriorateSpeed = 1;
	[Tooltip("Affects the amount of random movement applied to the screen shake (multiplied by shake magnitude)."), Range(0,1)]
	public float shakeNoiseMag = 0;
	
	[Tooltip("If rotation should be smoothed.")]
	public bool smoothCameraRotation = false;
	[Tooltip("The layers that can obstruct the camera.")]
	public LayerMask obstructionLayers;
	//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	public enum MovementUpdateType
	{
		LATEUPDATE,
		FIXEDUPDATE
	}
	Camera cam;

	//the current cameraData (created in memory only)
	CameraData data;
	//The rotation of the targetQuaternion
	Vector2 rotation;
	//the offset from the target
	Vector3 orbitVector;

	//used for smooth zoom
	float targetDistance;
	float currentDistance = 0;
	//used for smooth rotation
	Quaternion targetOrbit;
	Quaternion currentOrbit = Quaternion.identity;
	Vector3 currentPivotPosition;
	float xRotationAddition = 0;
	float xRotationAdditionCurrent = 0;
	float targetYOffset = 0;
	float yOffset = 0;

	//used to stop camera from clipping into walls
	Vector3 cameraBoxHalfExtents;
	
	//camera shake
	Vector3 cameraShake = Vector3.zero;

	private void OnEnable()
	{
		data = ScriptableObject.CreateInstance<CameraData>();
	}
	private void OnDisable()
	{
		ScriptableObject.Destroy(data);
	}
	void Start()
	{
		SetCameraData(defaultCameraData);

		cam = GetComponent<Camera>();

		//set default values for camera
		rotation = new Vector2(-15, 180 + target.rotation.eulerAngles.y);
		targetOrbit = Quaternion.Euler(rotation);
		currentOrbit = targetOrbit;
		orbitVector = currentOrbit * Vector3.forward;
		currentPivotPosition = target.position;
		SetOrbitDistance();
		orbitVector = orbitVector.normalized * targetDistance;
		currentDistance = targetDistance;
		transform.position = currentPivotPosition + orbitVector;
		transform.forward = -orbitVector;

		//set camera box extents, used for obstruction checking
		float yExtend = Mathf.Tan(cam.fieldOfView * Mathf.Deg2Rad) * cam.nearClipPlane;
		cameraBoxHalfExtents = new Vector3(yExtend * cam.aspect, yExtend, cam.nearClipPlane) / 2;
	}

	void LateUpdate()
	{
		if (movementUpdateType == MovementUpdateType.LATEUPDATE)
		{
			Vector3 pos = data.targetOffset.y * Vector3.up + target.position;
			float distance = Vector3.Distance(currentPivotPosition, pos);
			currentPivotPosition = Vector3.MoveTowards(currentPivotPosition, pos, Time.deltaTime * data.followSpeed * distance);
		}
	}

	private void FixedUpdate()
	{
		if (movementUpdateType == MovementUpdateType.FIXEDUPDATE)
		{
			Vector3 pos = data.targetOffset.y * Vector3.up + target.position;
			float distance = Vector3.Distance(currentPivotPosition, pos);
			currentPivotPosition = Vector3.MoveTowards(currentPivotPosition, pos, Time.deltaTime * data.followSpeed * distance);
		}
	}

	private void Update()
	{
		//smoothed camera movement
		if (smoothCameraRotation)
		{
			float sphericalDistance = Quaternion.Angle(currentOrbit, targetOrbit);

			currentOrbit = Quaternion.RotateTowards(currentOrbit, targetOrbit, sphericalDistance * Time.deltaTime * data.rotateSpeed);
			xRotationAdditionCurrent = Mathf.MoveTowardsAngle(xRotationAdditionCurrent, xRotationAddition, Mathf.Abs(xRotationAdditionCurrent - xRotationAddition) * Time.deltaTime * data.rotateSpeed);
			//set the orbit vector 
			orbitVector = currentOrbit * Vector3.forward;
			//the camera will look in the opposite direction of the orbit vector, toward the target position
			transform.forward = -orbitVector;
			transform.Rotate(new Vector3(-xRotationAdditionCurrent, 0, 0));
		}

		SetOrbitDistance();
		//set camera position
		transform.position = currentPivotPosition + orbitVector;

		//add camera shake
		float m = UpdateCameraShake();
		if (m > 0.001f)
		{
			Vector3 shakeVector = cameraShake + cameraShake.magnitude * Random.insideUnitSphere * shakeNoiseMag;
			if (!Physics.BoxCast(transform.position, cameraBoxHalfExtents, shakeVector.normalized, transform.rotation, shakeVector.magnitude, obstructionLayers.value))
			{
				transform.position += shakeVector;
			}
		}

		//add offsets
		Vector3 offset = data.targetOffset;
		offset.y = yOffset * data.yOffsetMagnitude;
		if (offset != Vector3.zero)
		{
			float additionMagnitude = offset.magnitude;
			Vector3 additionDirection = target.TransformDirection(offset / additionMagnitude);
			if (Physics.BoxCast(transform.position, cameraBoxHalfExtents, additionDirection, out RaycastHit hit, transform.rotation, additionMagnitude, obstructionLayers.value))
			{
				transform.position += additionDirection * hit.distance;
			}
			else
			{
				transform.position += additionDirection * additionMagnitude;
			}
		}

		//if (Physics.BoxCast(transform.position, cameraBoxHalfExtents, Vector3.up, out hit, transform.rotation, yOffset * data.yOffsetMagnitude, obstructionLayers.value))
		//{
		//	transform.position += Vector3.up * hit.distance;
		//}
		//else
		//{
		//	transform.position += Vector3.up * (yOffset * data.yOffsetMagnitude);
		//}
	}

	//Called through unity input system
	/// <summary>
	/// Updates input based on a 2d input vector
	/// </summary>
	/// <param name="value">Information describing the input event</param>
	public void OnLook(InputValue value)
	{
		Vector2 input = value.Get<Vector2>();
		//get input from look axis
		InputMove(input);
	}

	/// <summary>
	/// Updates the camera movement based on an input vector
	/// </summary>
	/// <param name="input">A 2d vector representing a rotational movement on the x and y axis</param>
	public void InputMove(Vector2 input)
	{
		if (!enableInput) return;

		input *= inverted ? -sensitivity : sensitivity;
		rotation += new Vector2(input.y, input.x);

		//clamp x rotation
		rotation.y = Mathf.Repeat(rotation.y, 360);

		rotation.x = Mathf.Clamp(rotation.x, -data.maximumUpRotation, -data.minimumUpRotation);

		////this is used to push camera away from floor when on ground so you can see more upward
		//float rotationFromMin = -(rotation.x - (data.minimumUpRotation));
		//if (rotationFromMin < cameraAvoidFloorRotationAngleRange)
		//{
		//	xRotationAddition = cameraAvoidFloorRotationPower * (1 - rotationFromMin / cameraAvoidFloorRotationAngleRange);
		//}
		//else
		//	xRotationAddition = 0;
		
		//set target quaternion
		targetOrbit = Quaternion.Euler(rotation);

		//do everything here if not smoothing rotation
		if (!smoothCameraRotation)
		{
			currentOrbit = targetOrbit;
			orbitVector = currentOrbit * Vector3.forward;
			transform.forward = -orbitVector;
			transform.Rotate(new Vector3(-xRotationAddition, 0, 0));
		}
	}

	//requires orbitVector to be normalised first
	/// <summary>
	/// Sets the orbitVector's magnitude to the correct value, taking into account obstructions
	/// </summary>
	void SetOrbitDistance()
	{		
		//check if camera is obstructed

		Collider[] c = Physics.OverlapBox(((cam.nearClipPlane) / 2) * orbitVector + currentPivotPosition, cameraBoxHalfExtents, transform.rotation, obstructionLayers.value);

		//check if obstructing object is inside box used for raycast (if this is the case the raycast does not detect it)
		//if so, do not change target distance
		if (c.Length == 0)
		{
			if (Physics.BoxCast(((cam.nearClipPlane) / 2) * orbitVector + currentPivotPosition, cameraBoxHalfExtents, orbitVector,
			out RaycastHit boxHit, transform.rotation, data.maxFollowDistance, obstructionLayers.value))
			{
				targetDistance = boxHit.distance;
			}
			else
			{
				//if box cast doesn't detect it, it might still be obstructed
				//this should fix most cases of that happening
				//will not fix if raycast origin is inside of obstruction collider
				Ray ray = new Ray(currentPivotPosition, orbitVector);
				if (Physics.Raycast(ray, out RaycastHit rayHit, data.maxFollowDistance, obstructionLayers.value))
				{
					targetDistance = rayHit.distance;
				}
				else
				{
					targetDistance = data.maxFollowDistance;
				}

			}
		}

		//magnitude changes differently depending if zooming in or out
		//need to move currentdistance toward targetdistance
		if (currentDistance < targetDistance)
		{
			currentDistance = Mathf.MoveTowards(currentDistance, targetDistance, Time.deltaTime * data.zoomOutSpeed * (targetDistance - currentDistance));
		}
		else
		{
			currentDistance = targetDistance;
		}
		orbitVector.Normalize();
		//now set orbit vec
		orbitVector *= currentDistance;

		//now set y offset based on distance
		if (currentDistance < data.yOffsetStartDistance + data.yOffsetDistance)
		{
			float t = 1 - Mathf.Max(0, currentDistance - data.yOffsetStartDistance) / data.yOffsetDistance;
			targetYOffset = t;
		}
		else
		{
			targetYOffset = 0;
		}

		yOffset = Mathf.MoveTowards(yOffset, targetYOffset, Time.deltaTime * data.yOffsetChangeSpeed * Mathf.Abs(targetYOffset - yOffset));
	}

	public void SetPositionAndRotation(Vector3 position, Quaternion rotation)
	{
		currentPivotPosition -= transform.position;
		currentPivotPosition += position;
		transform.position = position;
		transform.rotation = rotation;
	}

	/// <summary>
	/// Adds a vector to the camera shake vector
	/// </summary>
	/// <param name="shake">A world space displacement for the camera</param>
	public void AddCameraShake(Vector3 shake)
	{
		cameraShake += shake;
	}

	/// <summary>
	/// updates the camera shake vector using delta time 
	/// </summary>
	/// <returns>returns the magnitude of camera shake</returns>
	float UpdateCameraShake()
	{
		float magnitude = cameraShake.magnitude;
		cameraShake = Vector3.MoveTowards(cameraShake, Vector3.zero, magnitude * Time.unscaledDeltaTime * shakeDeteriorateSpeed);
		return magnitude;
	}

	public void SetCameraData(CameraData newData)
	{
		data.followSpeed = newData.followSpeed;
		data.maxFollowDistance = newData.maxFollowDistance;
		data.maximumUpRotation = newData.maximumUpRotation;
		data.minimumUpRotation = newData.minimumUpRotation;
		data.rotateSpeed = newData.rotateSpeed;
		data.targetOffset = newData.targetOffset;
		data.yOffsetChangeSpeed = newData.yOffsetChangeSpeed;
		data.yOffsetDistance = newData.zoomOutSpeed;
		data.yOffsetMagnitude = newData.yOffsetMagnitude;
		data.yOffsetStartDistance = newData.yOffsetStartDistance;
		data.zoomOutSpeed = newData.zoomOutSpeed;
	}

	public void ResetCameraData()
	{
		SetCameraData(defaultCameraData);
	}

	public CameraData GetCameraData()
	{
		return data;
	}
}
