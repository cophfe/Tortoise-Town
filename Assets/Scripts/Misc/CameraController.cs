using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.InputSystem.EnhancedTouch;
using TMPro;

[RequireComponent(typeof(Camera)),DefaultExecutionOrder(11)]
public partial class CameraController : MonoBehaviour
{
	//INSPECTOR STUFF
	//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	[Header("Behaviour")]
	[Tooltip("The target to orbit around.")]
	public Transform target;
	public bool globalOffset = true;
	[Tooltip("Contains data about the camera. These values cannot be changed at runtime, but the cameraData itself can be changed.")]
	public CameraData defaultCameraData;

	[Header("Control")]
	[Space(5)]
	
	[Tooltip("If input is inverted or not.")]
	public bool invertX = false;
	[Tooltip("If input is inverted or not.")]
	public bool invertY = false;
	[Tooltip("The camera sensitivity multiplier.")]
	[Range(0, 1)] public float sensitivity = 0.1f;
	
	public MovementUpdateType movementUpdateType = MovementUpdateType.UPDATE;
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

	[System.NonSerialized] public float screenShakeModifier = 1;
	[System.NonSerialized] public float sensitivityModifier = 1;

	//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	bool isControllerInput = false;
	Vector2 controllerVector = Vector2.zero;

	public bool EnableInput
	{
		get { return controls.asset.enabled; }
		set
		{
			if (controls == null) return;
			if (value)
			{
				controls.Enable();
			}
			else
			{
				controls.Disable();
				targetOrbit = currentOrbit;
				rotation = targetOrbit.eulerAngles;
				if (rotation.x > 90)
					rotation.x -= 360;
			}
		}
	}
	public enum MovementUpdateType
	{
		UPDATE,
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

	//Input
	InputMaster controls = null;

	private void Awake()
	{
		controls = new InputMaster();
		controls.Camera.Look.performed += OnLook;
		controls.Camera.Look.canceled += val => OnLookCancelled();
	}
	private void OnEnable()
	{
		data = ScriptableObject.CreateInstance<CameraData>();
		if (controls != null)
			controls.Enable();
	}
	private void OnDisable()
	{
		ScriptableObject.Destroy(data);
		if (controls != null)
			controls.Disable();
	}
	void Start()
	{
		SetCameraData(defaultCameraData);

		cam = GetComponent<Camera>();

		//set default values for camera
		MoveToTarget();

		//set camera box extents, used for obstruction checking
		float yExtend = 2 * Mathf.Tan(cam.fieldOfView * Mathf.Deg2Rad * 0.5f) * cam.nearClipPlane;
		cameraBoxHalfExtents = new Vector3(yExtend * cam.aspect, yExtend, cam.nearClipPlane);
	}

	void LateUpdate()
	{
		//move toward pivot
		if (movementUpdateType == MovementUpdateType.UPDATE)
		{
			Vector3 pos = data.targetOffset.y * Vector3.up + target.position;
			float distance = Vector3.Distance(currentPivotPosition, pos);
			currentPivotPosition = Vector3.MoveTowards(currentPivotPosition, pos, Time.deltaTime * data.followSpeed * distance);
		}
		//set camera position
		transform.position = currentPivotPosition + orbitVector;

		//add camera shake
		float m = UpdateCameraShake();
		if (m > 0.001f)
		{
			Vector3 shakeVector = cameraShake + cameraShake.magnitude * Random.insideUnitSphere * shakeNoiseMag;
			if (!Physics.BoxCast(transform.position, cameraBoxHalfExtents, shakeVector.normalized, transform.rotation, shakeVector.magnitude, obstructionLayers.value, QueryTriggerInteraction.Ignore))
			{
				transform.position += screenShakeModifier * shakeVector;
			}
		}

		//add offsets
		Vector3 offset;
		if (globalOffset)
		{
			offset = data.targetOffset;
			offset.y = 0;
			offset = target.InverseTransformDirection(offset);
		}
		else
		{
			offset = data.targetOffset;
			offset.y = 0;
		}

		if (offset != Vector3.zero && yOffset != 0)
		{
			float additionMagnitude = offset.magnitude;
			Vector3 additionDirection = target.TransformDirection(offset / additionMagnitude);
			offset.y += yOffset * data.yOffsetMagnitude;

			if (Physics.BoxCast(transform.position, cameraBoxHalfExtents, additionDirection, out RaycastHit hit, transform.rotation, additionMagnitude, obstructionLayers.value, QueryTriggerInteraction.Ignore))
			{
				transform.position += additionDirection * hit.distance;
			}
			else
			{
				transform.position += additionDirection * additionMagnitude;
			}
		}
	}

	private void FixedUpdate()
	{
		if (movementUpdateType == MovementUpdateType.FIXEDUPDATE)
		{
			Vector3 pos = data.targetOffset.y * Vector3.up + target.position;
			float distance = Vector3.Distance(currentPivotPosition, pos);
			currentPivotPosition = Vector3.MoveTowards(currentPivotPosition, pos, Time.deltaTime * data.followSpeed * distance);
			SetOrbitDistance();
		}
	}

	private void Update()
	{
		if (isControllerInput && controllerVector != Vector2.zero)
			InputMove(controllerVector * Time.deltaTime);

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
	}

	//Called through unity input system
	/// <summary>
	/// Updates input based on a 2d input vector
	/// </summary>
	/// <param name="value">Information describing the input event</param>
	public void OnLook(InputAction.CallbackContext ctx)
	{
		Vector2 input = ctx.ReadValue<Vector2>();
		if (isControllerInput)
		{
			controllerVector = input;
		}
		else
		{
			//get input from look axis
			InputMove(input);
		}
	}

	public void OnLookCancelled()
	{
		if (isControllerInput)
		{
			controllerVector = Vector2.zero;
		}
	}

	/// <summary>
	/// Updates the camera movement based on an input vector
	/// </summary>
	/// <param name="input">A 2d vector representing a rotational movement on the x and y axis</param>
	public void InputMove(Vector2 input)
	{
		input *= sensitivityModifier * data.sensitivityMultiplier * sensitivity;
		if (invertX)
			input.y *= -1;
		if (invertY)
			input.x *= -1;

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

		Collider[] c = Physics.OverlapBox(((cam.nearClipPlane) / 2) * orbitVector + currentPivotPosition, cameraBoxHalfExtents, transform.rotation, obstructionLayers.value, QueryTriggerInteraction.Ignore);

		//check if obstructing object is inside box used for raycast (if this is the case the raycast does not detect it)
		//if so, do not change target distance
		if (c.Length == 0)
		{
			if (Physics.BoxCast(((cam.nearClipPlane) / 2) * orbitVector + currentPivotPosition, cameraBoxHalfExtents, orbitVector,
			out RaycastHit boxHit, transform.rotation, data.maxFollowDistance, obstructionLayers.value, QueryTriggerInteraction.Ignore))
			{
				targetDistance = boxHit.distance;
			}
			else
			{
				//if box cast doesn't detect it, it might still be obstructed
				//this should fix most cases of that happening
				//will not fix if raycast origin is inside of obstruction collider
				Ray ray = new Ray(currentPivotPosition, orbitVector);
				if (Physics.Raycast(ray, out RaycastHit rayHit, data.maxFollowDistance, obstructionLayers.value, QueryTriggerInteraction.Ignore))
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


	public void SetControllerInput(bool val)
	{
		isControllerInput = val;
	}

	public void SetPositionAndRotation(Vector3 position, Quaternion rotation)
	{
		currentPivotPosition  -= transform.position;
		currentPivotPosition += position;
		transform.position = position;
		transform.rotation = rotation;

		//orbitVector = currentOrbit * Vector3.forward;
		////the camera will look in the opposite direction of the orbit vector, toward the target position
		//transform.forward = -orbitVector;
		var euler = rotation.eulerAngles;
		this.rotation.x = Mathf.PingPong(-euler.x + 90, 180) - 90;
		this.rotation.y = euler.y + 180;
		if (this.rotation.x > 90)
			this.rotation.x -= 360;
		currentOrbit = targetOrbit * Quaternion.Inverse(currentOrbit);
		targetOrbit = Quaternion.Euler(this.rotation);
		currentOrbit = targetOrbit;
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
		data.sensitivityMultiplier = newData.sensitivityMultiplier;
	}

	public void MoveToTarget()
	{
		if (!target) return;
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
	}

	public void ResetCameraData()
	{
		SetCameraData(defaultCameraData);
	}

	public CameraData GetCameraData()
	{
		return data;
	}

	public Vector3 GetCurrentPivotPosition()
	{
		return currentPivotPosition;
	}

	public Vector3 GetTargetPivotPosition()
	{
		return data.targetOffset.y * Vector3.up + target.position;
	}
}
