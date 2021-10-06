using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(PlayerMotor)), RequireComponent(typeof(PlayerAnimator)), RequireComponent(typeof(PlayerInputController)), RequireComponent(typeof(PlayerHealth))]
public class PlayerController : MonoBehaviour
{
	[SerializeField] OldCameraController cameraController = null;
	[SerializeField] float rollColliderRadius = 0.5f;
	[SerializeField] Vector3 additionalRollColliderOffset;
	[SerializeField] Vector3 rollCameraOffset;
	[SerializeField] private Transform rotatableChild = null;
	Vector3 rollColliderOffset;

	#region Properties
	public PlayerMotor Motor { get; private set; }
	public PlayerAnimator Animator { get; private set; }
	public PlayerInputController Input { get; private set; }
	public CharacterController CharacterController { get; private set; }
	public PlayerHealth Health { get; private set; }
	public OldCameraController MainCamera { get { return cameraController; } private set { cameraController = value; } }
	public Transform RotateChild { get { return rotatableChild; } }
	public float InitialColliderHeight { get; private set; }
	public float InitialColliderRadius { get; private set; }
	public Vector3 InitialColliderOffset { get; private set; }

	public Vector3 InitialCameraOffset { get; private set; }
	public float RollColliderRadius { get { return rollColliderRadius; } }
	public Vector3 RollColliderOffset { get { return rollColliderOffset + additionalRollColliderOffset; } }
	public Vector3 RollCameraOffset { get { return rollCameraOffset; } }
	#endregion

	void Awake()
    {
		Motor = GetComponent<PlayerMotor>();
		Animator = GetComponent<PlayerAnimator>();
		Input = GetComponent<PlayerInputController>();
		CharacterController = GetComponent<CharacterController>();
		Health = GetComponent<PlayerHealth>();
		

		if (MainCamera == null)
		{
			MainCamera = FindObjectOfType<OldCameraController>();
		}
		if (rotatableChild == null)
		{
			if (transform.childCount > 0)
				rotatableChild = transform.GetChild(0);
			else
			{
				rotatableChild = transform;
			}
		}
			
		InitialColliderHeight = CharacterController.height;
		InitialColliderRadius = CharacterController.radius;
		InitialColliderOffset = CharacterController.center;
		rollColliderOffset = CharacterController.center + new Vector3(0, (rollColliderRadius - CharacterController.height)/2, 0);
		InitialCameraOffset = MainCamera.targetOffset;
	}
}
