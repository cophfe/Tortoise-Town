using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "CameraData", menuName = "ScriptableObjects/CameraData", order = 1)]
public class CameraData : ScriptableObject
{
	[Header("Behaviour")]
	[Tooltip("The offset from the target. the y value is world, the horizontal plane is local")]
	public Vector3 targetOffset;
	[Tooltip("The maximum distance the camera can be away from the target.")]
	[Min(0)] public float maxFollowDistance = 10;

	[Header("Control")]
	[Tooltip("Up rotation cannot be higher than this value.")]
	[Range(-90, 90)] public float maximumUpRotation = 87;
	[Tooltip("Up rotation cannot be less than this value.")]
	[Range(-90, 90)] public float minimumUpRotation = -87;

	[Header("Movement")]
	[Space(5)]
	[Tooltip("Camera movement speed.")]
	public float followSpeed = 15;
	[Tooltip("The speed the camera zooms out.")]
	public float zoomOutSpeed = 15;
	[Tooltip("The distance at which a y offset starts to be applied.")]
	public float yOffsetStartDistance = 0;
	[Tooltip("The distance at which the y offset is applied over.")]
	public float yOffsetDistance = 3;
	[Tooltip("The amount of y offset.")]
	public float yOffsetMagnitude = 1;
	[Tooltip("Affects the speed of change of the y offset.")]
	public float yOffsetChangeSpeed = 1;
	[Tooltip("Camera orbit speed.")]
	[Min(0)] public float rotateSpeed = 1;

	private void OnValidate()
	{
		if (maximumUpRotation < minimumUpRotation)
		{
			maximumUpRotation = minimumUpRotation;
		}
	}

}