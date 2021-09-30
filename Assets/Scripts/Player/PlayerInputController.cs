using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.InputSystem;

public class PlayerInputController : MonoBehaviour
{
	//input values
	public Vector2 inputVector { get; private set; }
	public Vector2 lastNonZeroInputVector { get; private set; }
	bool jumpPressed;
	bool jumpCancelled;
	bool crouchPressed;
	bool sprintPressed;

	//control
	InputMaster controls;

	#region init
	public void Awake()
	{
		controls = new InputMaster();
		//Move
		controls.Player.Move.performed += val => OnMoveInput(val.ReadValue<Vector2>());
		controls.Player.Move.canceled += val => OnMoveInput(val.ReadValue<Vector2>());
		//Jump
		controls.Player.Jump.performed += _ => OnJumpPressed();
		controls.Player.Jump.canceled += _ => OnJumpCancelled();
		//Sprint
		controls.Player.Sprint.performed += _ => OnSprintInput();
		controls.Player.Crouch.performed += _ => OnCrouchInput();
	}

	public void OnEnable()
	{
		controls.Enable();
	}
	public void OnDisable()
	{
		controls.Disable();
	}
	#endregion

	#region Evaluate Functions

	public bool EvaluateJumpPressed()
	{
		bool v = jumpPressed;
		jumpPressed = false;
		return v;
	}

	public bool EvaluateCrouchPressed()
	{
		bool v = crouchPressed;
		crouchPressed = false;
		return v;
	}

	public bool EvaluateSprintPressed()
	{
		bool v = sprintPressed;
		sprintPressed = false;
		return v;
	}

	public bool EvaluateJumpCancelled()
	{
		bool v = jumpCancelled;
		jumpCancelled = false;
		return v;
	}

	#endregion

	#region Input Functions
	
	void OnMoveInput(Vector2 val)
	{
		inputVector = val;
		if (inputVector != Vector2.zero)
		{
			lastNonZeroInputVector = inputVector;
		}
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

	#endregion
}
