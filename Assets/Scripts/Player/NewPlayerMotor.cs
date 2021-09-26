using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(CharacterController))]
public class NewPlayerMotor : MonoBehaviour
{
	CharacterController controller;
	public Transform cameraTransform;

	//VELOCITY
	Vector3 inputVelocity;
	Vector3 lastInputVelocity;
	Vector3 forcesVelocity;
	Vector3 lastForcesVelocity;

	//FORCES
	public float acceleration = 10;
	public float maxSpeed = 10;
	public Vector3 upDirection = Vector3.up;
	public float gravity = 10;

	//JUMPING
	public float jumpSpeed = 4;
	public float jumpDuration = 0.3f;
	public float airJumps = 0;
	public float jumpBufferTime = 0.1f;
	public float coyoteTime = 0.1f;

	float jumpBufferTimer = 0;
	float coyoteTimer = 0;
	float jumpTimer = 0;
	float airJumpsLeft = 0;

	//CONTROL
	[Range(0, 1)] public float airControlModifier = 0.5f;
	[Range(0, 1)] public float slideControlModifier = 0.5f;

	//INPUT
	PlayerInputController input;

	//GROUND DETECTION 
	bool isGrounded = false;
	[Range(0, 1)] public float groundDetectionRadiusModifier = 0.8f;
	public LayerMask ignoredGround;
	Vector3 groundPosition;
	Vector3 groundNormal;
	float groundDistance;
	public bool enableGroundMagnet = false;
	float groundMagnetOffset;

	//OTHER
	[SerializeField] MovementState state = MovementState.FALLING;
	enum MovementState
	{
		GROUNDED,
		FALLING,
		SLIDING,
		RISING,
		JUMPING //jumping is seperate from rising for variable jump height reasons
	}

	private void Awake()
	{
		controller = GetComponent<CharacterController>();
		input = new PlayerInputController();
	}

	private void OnEnable()
	{
		input.EnableInput();	
	}

	private void OnDisable()
	{
		input.DisableInput();
	}

	private void FixedUpdate()
	{
		Run();

		if (isGrounded)
		{
			Debug.DrawRay(groundPosition, groundNormal, Color.blue, Time.fixedDeltaTime);
		}
	}

	private void Update()
	{
		jumpTimer -= Time.deltaTime;
		coyoteTimer -= Time.deltaTime;
		jumpBufferTimer -= Time.deltaTime;
	}

	void Run()
	{
		ScanForGround();
		SetState();
		EvaluateJump();
		UpdateMovementVector();
		UpdateForcesVector();

		enableGroundMagnet = state == MovementState.GROUNDED || state == MovementState.SLIDING;

		Vector3 totalVelocity = inputVelocity + forcesVelocity;
		controller.Move(totalVelocity * Time.fixedDeltaTime + groundMagnetOffset * upDirection);
	}

	void UpdateMovementVector()
	{
		Vector3 targetVelocity = Vector3.ProjectOnPlane(cameraTransform.right, upDirection).normalized * input.inputVector.x
			+ Vector3.ProjectOnPlane(cameraTransform.forward, upDirection).normalized * input.inputVector.y;
		targetVelocity = Vector3.ClampMagnitude(targetVelocity, 1) * maxSpeed;

		inputVelocity = Vector3.MoveTowards(inputVelocity, targetVelocity, acceleration * Time.fixedDeltaTime);
	}

	void UpdateForcesVector()
	{
		if (state == MovementState.GROUNDED)
		{
			forcesVelocity = upDirection * -0.01f;
		}
		else
		{
			forcesVelocity -= upDirection * (gravity * Time.fixedDeltaTime);
		}
	}

	void SetState()
	{
		bool movingUp = Vector3.Dot(upDirection, forcesVelocity) > 0.0001f;
		bool groundTooSteep = Vector3.Angle(groundNormal, upDirection) > controller.slopeLimit;

		switch (state)
		{
			case MovementState.GROUNDED:
				if (movingUp)
				{
					state = MovementState.RISING;
					OnLeaveGround();
				}
				else if (!isGrounded)
				{
					state = MovementState.FALLING;
					OnLeaveGround();
				}
				else if (groundTooSteep)
				{
					state = MovementState.SLIDING;
					OnLeaveGround();
				}
				break;

			case MovementState.SLIDING:
				if (movingUp)
				{
					state = MovementState.RISING;
					OnLeaveGround();
				}
				else if (!isGrounded)
				{
					state = MovementState.FALLING;
					OnLeaveGround();
				}
				else if (groundTooSteep)
				{
					state = MovementState.GROUNDED;
					OnLand();
				}
				break;

			case MovementState.RISING:
				if (!movingUp)
				{
					if (isGrounded)
					{
						if (groundTooSteep)
						{
							state = MovementState.SLIDING;
						}
						else
						{
							state = MovementState.GROUNDED;
							OnLand();
						}
					}
					else
					{
						state = MovementState.FALLING;
					}
				}
				break;

			case MovementState.FALLING:
				if (movingUp)
				{
					state = MovementState.RISING;
				}
				else if (isGrounded)
				{
					if (groundTooSteep)
					{
						state = MovementState.SLIDING;
					}
					else
					{
						state = MovementState.GROUNDED;
						OnLand();
					}
				}
				break;

			case MovementState.JUMPING:
				if (input.EvaluateJumpCancelled() || jumpTimer <= 0)
				{
					state = MovementState.RISING;
				}
				break;
		}
		
		if (isGrounded)
		{
			float upForces = Vector3.Dot(forcesVelocity, upDirection);
			if (upForces < 0)
			{
				forcesVelocity = Vector3.zero;
			}

			if (state != MovementState.GROUNDED)
			{
				OnLand();
			}
		}
	}

	void ScanForGround()
	{
		Vector3 direction = -upDirection;
		Vector3 origin = transform.TransformPoint(controller.center);
		float length = controller.height / 2 + controller.skinWidth;
		if (enableGroundMagnet)
		{
			length *= 1.5f;
		}
		else
		{
			groundMagnetOffset = 0;
		}

		isGrounded = Physics.Raycast(origin, direction, out var hit, length, ~ignoredGround);
		if (isGrounded)
		{
			groundPosition = hit.point;
			groundNormal = hit.normal;
			groundDistance = hit.distance;

			float offset = (controller.height / 2 - groundDistance);
			if (enableGroundMagnet && offset < 0)
			{
				groundMagnetOffset = offset;
			}
		}
	}

	void EvaluateJump()
	{
		//start jump
		if (input.EvaluateJumpPressed())
		{
			if (state == MovementState.GROUNDED)
			{
				OnJump();
			}
			else
			{
				if (airJumpsLeft > 0)
				{
					airJumpsLeft--;
					OnJump();
				}
				else if (coyoteTimer > 0)
				{
					coyoteTimer = 0;
					OnJump();
				}
				else
				{
					jumpBufferTimer = jumpBufferTime;
				}
			}
		}

		//add jump force
		if (state == MovementState.JUMPING)
		{
			forcesVelocity = Vector3.ProjectOnPlane(forcesVelocity, upDirection);
			forcesVelocity += upDirection * jumpSpeed;
		}
	}

	void OnJump()
	{
		//set state
		state = MovementState.JUMPING;
		//call leave ground
		OnLeaveGround();
		//set the jump timer
		jumpTimer = jumpDuration;
		//add force
		forcesVelocity = Vector3.ProjectOnPlane(forcesVelocity, upDirection);
		forcesVelocity += upDirection * jumpSpeed;
	}

	void OnLand()
	{
		airJumpsLeft = airJumps;

		if (jumpBufferTimer > 0)
		{
			jumpBufferTimer = 0;
			OnJump();
			//cancel jump immediatly if player let go of button
			if (input.EvaluateJumpCancelled())
			{
				state = MovementState.RISING;
			}
		}
		else
		{
			//set cancel jump to false
			input.EvaluateJumpCancelled();
		}
	}

	void OnLeaveGround()
	{

	}

	void OnCeilingHit()
	{

	}
}
