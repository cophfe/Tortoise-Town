﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.InputSystem;

//An input manager
//warning: only one script can use any specific input at any one time (because button input is stored as 'has this button been pressed since last evaluated')
//make another input controller if you want multiple scripts to read inputs at once
public class PlayerInputController : MonoBehaviour
{
	//input values
	public Vector2 inputVector { get; private set; }
	bool jumpPressed;
	bool jumpCancelled;
	bool crouchPressed;
	bool sprintPressed;

	//control
	InputMaster controls;

	#region Unity
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
		//Crouch
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
	public void LateUpdate()
	{
		jumpPressed = false;
		jumpCancelled = false;
		crouchPressed = false;
		sprintPressed = false;
	}
	#endregion

	#region Evaluate Functions

	public bool EvaluateJumpPressed()
	{
		return jumpPressed;
	}

	public bool EvaluateCrouchPressed()
	{
		return crouchPressed;
	}

	public bool EvaluateSprintPressed()
	{
		return sprintPressed;
	}

	public bool EvaluateJumpCancelled()
	{
		return jumpCancelled;
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

	#endregion
}