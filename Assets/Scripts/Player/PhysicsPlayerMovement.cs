using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;

public class PhysicsPlayerMovement : MonoBehaviour
{
	//references
	public Transform cameraTransform;
	Transform selfTransform;
	Rigidbody selfRigidbody;

	//movement settings
	public float slopeLimit = 30;

	//physics movement
	public float gravity = 10;
	public float maxAcceleration = 10;
	public float maxSpeed = 10;

	//jump stuff
	public float jumpHeight = 2;
	public int jumpCount = 1;
	int currentJumps = 0;

	//input
	Vector2 inputVector = Vector2.zero;
	bool jumpPressed = false;
	bool jumpCancelled = false;
	bool crouchPressed = false;
	bool sprintPressed = false;

	//other
	Vector3 inputPlaneNormal = Vector3.up;
	bool isGrounded = false;
	bool previousIsGrounded = false;

	private void Awake()
	{
		selfTransform = transform;
		selfRigidbody = GetComponent<Rigidbody>();
	}

	private void FixedUpdate()
	{
		ResolveInput();
		Move();
		previousIsGrounded = isGrounded;
		isGrounded = false;
	}

	void Move()
	{
		Vector3 currentVelocity = selfRigidbody.velocity;
		Vector3 targetVelocity;

		if (inputVector.sqrMagnitude > 0)
		{
			//forward is camera-ward
			Vector3 relativeInput = cameraTransform.right * inputVector.x + cameraTransform.forward * inputVector.y;
			relativeInput = Vector3.ProjectOnPlane(relativeInput, inputPlaneNormal).normalized;
			targetVelocity = relativeInput * maxSpeed;
		}
		else
		{
			targetVelocity = Vector3.zero;
		}

		Vector3 nonInputPlaneVelocity = Vector3.Dot(currentVelocity, inputPlaneNormal) * inputPlaneNormal;
		Vector3 inputPlaneVelocity = currentVelocity - nonInputPlaneVelocity;
		inputPlaneVelocity = Vector3.MoveTowards(inputPlaneVelocity, targetVelocity, Time.fixedDeltaTime * maxAcceleration);
		currentVelocity = inputPlaneVelocity + nonInputPlaneVelocity;

		selfRigidbody.velocity = currentVelocity;
	}

	void ResolveInput()
	{

		if (jumpPressed)
		{
			if (currentJumps > 0)
			{
				StartJump();
			}

			jumpPressed = false;
			
		}

		if (isGrounded)
		{
			currentJumps = jumpCount;
			if (!previousIsGrounded)
			{
				Land();
			}
		}

	}

	void StartJump()
	{
		currentJumps--;
		Vector3 currentVelocity = selfRigidbody.velocity;

		float u = Mathf.Sqrt(2 * -Physics.gravity.y * jumpHeight);
		currentVelocity.y += u;

		selfRigidbody.velocity = currentVelocity;
	}

	void Land()
	{
	}

	private void OnCollisionStay(Collision collision)
	{
		CheckIfCollisionIsGround(collision);
	}

	private void OnCollisionEnter(Collision collision)
	{
		CheckIfCollisionIsGround(collision);
	}

	void CheckIfCollisionIsGround(Collision collision)
	{
		for (int i = 0; i < collision.contactCount; i++)
		{
			Vector3 normal = collision.contacts[i].normal;
			float angle = Vector3.Angle(Vector3.up, normal);
			Debug.Log(angle);
			isGrounded = isGrounded || angle < slopeLimit;
		}
	}

	#region Input
	public void OnMoveAxis(InputAction.CallbackContext obj)
	{
		inputVector = obj.ReadValue<Vector2>();
	}

	public void OnJumpInput(InputAction.CallbackContext obj)
	{
		switch (obj.phase)
		{
			case InputActionPhase.Started:
				jumpPressed = true;
				break;
			case InputActionPhase.Canceled:
				jumpCancelled = true;
				break;
		}
	}

	public void OnSprintInput(InputAction.CallbackContext obj)
	{
		if (obj.started)
			sprintPressed = true;
	}

	public void OnCrouchInput(InputAction.CallbackContext obj)
	{
		if (obj.started)
			crouchPressed = true;
	}
	#endregion
}
