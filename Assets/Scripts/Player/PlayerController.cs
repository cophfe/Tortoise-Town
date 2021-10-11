﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(PlayerMotor)), RequireComponent(typeof(PlayerHealth))]
public class PlayerController : MonoBehaviour
{
	[SerializeField] OldCameraController cameraController = null;
	[SerializeField] float rollColliderRadius = 0.5f;
	[SerializeField] Vector3 additionalRollColliderOffset = Vector3.zero;
	[SerializeField] Vector3 rollCameraOffset = Vector3.zero;
	[SerializeField] private Transform rotatableChild = null;
	[SerializeField] InterpolateChild visualInterpolator = null;
	[SerializeField] GameManager gameManager = null;
	Vector3 rollColliderOffset;

	//INPUT
	public Vector2 inputVector { get; private set; }
	bool jumpPressed;
	bool jumpCancelled;
	bool crouchPressed;
	bool sprintPressed;
	bool attackPressed;
	InputMaster controls;

	#region Properties
	public PlayerMotor Motor { get; private set; }
	public PlayerAnimator Animator { get; private set; }
	public CharacterController CharacterController { get; private set; }
	public PlayerCombat Combat { get; private set; }
	public PlayerHealth Health { get; private set; }
	public OldCameraController MainCamera { get { return cameraController; }}
	public Transform RotateChild { get { return rotatableChild; } }
	public GameManager GameManager { get { return gameManager; } }
	public float InitialColliderHeight { get; private set; }
	public float InitialColliderRadius { get; private set; }
	public Vector3 InitialColliderOffset { get; private set; }

	public Vector3 InitialCameraOffset { get; private set; }
	public float RollColliderRadius { get { return rollColliderRadius; } }
	public Vector3 RollColliderOffset { get { return rollColliderOffset + additionalRollColliderOffset; } }
	public Vector3 RollCameraOffset { get { return rollCameraOffset; } }
	public bool InterpolateVisuals {
		get
		{
			return visualInterpolator && visualInterpolator.enabled;
		}
		set
		{
			if (visualInterpolator)
			{
				visualInterpolator.enabled = value;
				MainCamera.movementUpdateType = value ? OldCameraController.MovementUpdateType.LATEUPDATE : OldCameraController.MovementUpdateType.FIXEDUPDATE;
			}
		}
	}
	#endregion

	void Awake()
    {
		Motor = GetComponent<PlayerMotor>();
		Animator = GetComponentInChildren<PlayerAnimator>();
		if (Animator == null)
			Animator = FindObjectOfType<PlayerAnimator>();
		CharacterController = GetComponent<CharacterController>();
		Health = GetComponent<PlayerHealth>();
		Combat = GetComponent<PlayerCombat>();
		visualInterpolator = GetComponentInChildren<InterpolateChild>();
		
		if (MainCamera == null)
		{
			cameraController = FindObjectOfType<OldCameraController>();
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

		//INPUT
		controls = new InputMaster();
		//Move
		controls.Player.Move.performed += val => OnMoveInput(val.ReadValue<Vector2>());
		controls.Player.Move.canceled += val => OnMoveInput(val.ReadValue<Vector2>());
		//Jump
		controls.Player.Jump.performed += _ => OnJumpPressed();
		controls.Player.Jump.canceled += _ => OnJumpCancelled();
		//Sprint
		controls.Player.Sprint.performed += _ => OnSprintInput();
		//Crouch
		controls.Player.Crouch.performed += _ => OnCrouchInput();
		//Attacking
		controls.Player.Attack.performed += _ => OnAttackInput();
		//Aiming
		controls.Player.Aim.performed += _ => OnAimPressed();
		controls.Player.Aim.canceled += _ => OnAimCancelled();
	}

	public void OnEnable()
	{
		controls.Enable();
	}
	public void OnDisable()
	{
		controls.Disable();
	}

	#region Evaluate Functions

	public bool EvaluateJumpPressed()
	{
		bool val = jumpPressed;
		jumpPressed = false;
		return val;
	}

	public bool EvaluateCrouchPressed()
	{
		bool val = crouchPressed;
		crouchPressed = false;
		return val;
	}

	public bool EvaluateSprintPressed()
	{
		bool val = sprintPressed;
		sprintPressed = false;
		return val;
	}

	public bool EvaluateJumpCancelled()
	{
		bool val = jumpCancelled;
		jumpCancelled = false;
		return val;
	}

	public bool EvaluateAttackPressed()
	{
		bool val = attackPressed;
		attackPressed = false;
		return val;
	}

	#endregion

	#region Input Functions

	void OnMoveInput(Vector2 val)
	{
		inputVector = val;
	}

	void OnJumpPressed()
	{
		jumpPressed = true;
	}

	void OnJumpCancelled()
	{
		jumpCancelled = true;
	}

	void OnSprintInput()
	{
		sprintPressed = true;
	}

	void OnCrouchInput()
	{
		crouchPressed = true;
	}

	void OnAimPressed()
	{
		Combat.StartChargeUp();
	}

	void OnAimCancelled()
	{
		Combat.EndChargeUp();
	}

	void OnAttackInput()
	{
		attackPressed = true;
	}
	#endregion
}
