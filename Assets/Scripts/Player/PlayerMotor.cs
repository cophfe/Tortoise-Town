using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

[RequireComponent(typeof(CharacterController), typeof(PlayerInputController))]
public class PlayerMotor : MonoBehaviour
{
	CharacterController controller;
	public Transform cameraTransform;

	//VELOCITY
	Vector3 totalVelocity;	
	Vector3 inputVelocity;
	Vector3 forcesVelocity;

	//FORCES
	public float acceleration = 10;
	public float maxSpeed = 10;
	public Vector3 upDirection = Vector3.up;
	public float gravity = 10;
	public float additionalSlideGravity = 3;
	[Range(0, 1)] public float bounciness = 0;

	//FRICTION
	public float airFriction = 0.5f;
	public float groundFriction = 0.5f;
	public float slideFriction = 0.5f;

	//JUMPING
	public float jumpSpeed = 4;
	public float jumpDuration = 0.3f;
	public float airJumps = 0;
	public float jumpBufferTime = 0.1f;
	public float jumpCoyoteTime = 0.1f;

	float jumpBufferTimer = 0;
	float jumpCoyoteTimer = 0;
	float jumpTimer = 0;
	float airJumpsLeft = 0;

	//CONTROL
	[Range(0, 1)] public float airControlModifier = 0.5f;
	[Range(0, 90)] public float slideSlopeLimit = 45f;
	
	//INPUT
	PlayerInputController input;

	//GROUND DETECTION 
	[Range(0, 1)] public float groundDetectionRadiusModifier = 0.8f;
	[Range(0, 0.1f)] public float groundDetectionAdditionalOffset = 0.01f;
	[Range(0, 1)] public float groundMagnetDistanceModifier = 0.5f;
	public LayerMask ignoredGround;
	bool isGrounded = false;
	Vector3 groundPosition;
	Vector3 groundNormal;
	float groundDistance;
	bool enableGroundMagnet = false;
	float groundMagnetOffset;
	bool collisionGroundDetected = false;

	//ROTATION
	public float turnSpeed = 2;
	Quaternion targetRotation;

	//EVENTS
	public UnityEvent onLeaveGround;
	public UnityEvent onEnterGround;

	//OTHER
	public bool drawDebug = false;
	MovementState state = MovementState.FALLING;
	Vector3 inputForward;

	public enum MovementState
	{
		GROUNDED,
		FALLING,
		RISING,
		JUMPING //jumping is seperate from rising for variable jump height reasons
	}

	private void Awake()
	{
		controller = GetComponent<CharacterController>();
		input = GetComponent<PlayerInputController>();
	}

	private void Update()
	{
		Run();

		jumpTimer -= Time.deltaTime;
		jumpCoyoteTimer -= Time.deltaTime;
		jumpBufferTimer -= Time.deltaTime;

		if (drawDebug && isGrounded)
		{
			Debug.DrawRay(groundPosition, groundNormal, Color.blue, Time.deltaTime);
		}
	}

	void Run()
	{
		ScanForGround();
		SetState();
		EvaluateJump();
		UpdateMovementVector();
		UpdateForcesVector();

		enableGroundMagnet = state == MovementState.GROUNDED || collisionGroundDetected;

		totalVelocity = inputVelocity + forcesVelocity;
		UpdateRotation();

		controller.Move(totalVelocity * Time.deltaTime + groundMagnetOffset * upDirection);
	}

	void UpdateMovementVector()
	{
		if (state == MovementState.GROUNDED)
		{
			Vector3 targetVelocity = GetTargetVelocity();

			float currentAcceleration = acceleration;

			//make it turn around fast
			if (Vector3.Dot(targetVelocity, inputVelocity) < 0)
			{
				currentAcceleration *= 2;
			}
			inputVelocity = Vector3.MoveTowards(inputVelocity, targetVelocity, currentAcceleration * Time.deltaTime);			
		}
		else
		{
			if (input.inputVector != Vector2.zero)
			{
				Vector3 targetVelocity = GetTargetVelocity();

				inputVelocity = Vector3.MoveTowards(inputVelocity, targetVelocity, airControlModifier * acceleration * Time.deltaTime);
			}

			//FRICTION
			inputVelocity = Vector3.MoveTowards(inputVelocity, Vector3.zero, airFriction * Time.deltaTime);
		}

		Vector3 GetTargetVelocity()
		{
			inputForward = Vector3.ProjectOnPlane(cameraTransform.forward, groundNormal).normalized;
			Vector3 targetVelocity = Vector3.Cross(inputForward, groundNormal) * -input.inputVector.x
				+ inputForward * input.inputVector.y;
			targetVelocity = Vector3.ClampMagnitude(targetVelocity, 1) * maxSpeed;
			return targetVelocity;
		}
	}

	

	void UpdateForcesVector()
	{
		Vector3 frictionApplied;
		if (state == MovementState.GROUNDED)
		{
			//GRAVITY
			if (Vector3.Dot(forcesVelocity, upDirection) < 0)
			{
				forcesVelocity = Vector3.ProjectOnPlane(forcesVelocity, upDirection);
			}

			//FRICTION
			frictionApplied = Vector3.MoveTowards(Vector3.ProjectOnPlane(forcesVelocity, upDirection), Vector3.zero, groundFriction * Time.deltaTime);
		}
		else
		{
			//GRAVITY
			forcesVelocity -= upDirection * (gravity * Time.deltaTime);

			//FRICTION
			frictionApplied = Vector3.MoveTowards(Vector3.ProjectOnPlane(forcesVelocity, upDirection), Vector3.zero, airFriction * Time.deltaTime);
		}

		//apply friciton
		float up = Vector3.Dot(forcesVelocity, upDirection);
		forcesVelocity = frictionApplied + up * upDirection;
	}

	void UpdateRotation()
	{
		Vector3 rotVec;
		if (state == MovementState.GROUNDED)
		{
			rotVec = Vector3.ProjectOnPlane(inputVelocity, upDirection);
			if (rotVec.magnitude >= maxSpeed / 6)
			{
				Quaternion targetRotation = Quaternion.LookRotation(rotVec, upDirection);
				transform.rotation = Quaternion.RotateTowards(transform.rotation, targetRotation, Quaternion.Angle(transform.rotation, targetRotation) * Time.deltaTime * turnSpeed);
			}
		}
		else
		{
			rotVec = Vector3.ProjectOnPlane(totalVelocity, upDirection);
			if (rotVec.magnitude >= maxSpeed / 6)
			{
				Quaternion targetRotation = Quaternion.LookRotation(rotVec, upDirection);
				transform.rotation = Quaternion.RotateTowards(transform.rotation, targetRotation, Quaternion.Angle(transform.rotation, targetRotation) * Time.deltaTime * turnSpeed);
			}
		}
	}

	void SetState()
	{
		bool movingUp = Vector3.Dot(upDirection, forcesVelocity) > 0.0001f;
		bool groundTooSteep = Vector3.Angle(groundNormal, upDirection) > slideSlopeLimit;

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
					state = MovementState.FALLING;
					OnLeaveGround();
				}
				break;

			case MovementState.RISING:
				if (!movingUp)
				{
					if (isGrounded)
					{
						if (groundTooSteep)
						{
							state = MovementState.FALLING;
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
						state = MovementState.FALLING;
					}
					else
					{
						state = MovementState.GROUNDED;
						OnLand();
					}
				}
				break;
		}
	}

	void ScanForGround()
	{
		Vector3 direction = -upDirection;
		Vector3 origin = transform.TransformPoint(controller.center);
		float length = controller.height / 2 + controller.skinWidth;
		if (enableGroundMagnet)
		{
			length *= (1+ groundMagnetDistanceModifier);
		}
		else
		{
			groundMagnetOffset = 0;
		}

		float radius = controller.radius * groundDetectionRadiusModifier;
		isGrounded = Physics.SphereCast(origin, radius, direction, out var hit, length * (1 + groundDetectionAdditionalOffset) - radius, ~ignoredGround);
		if (isGrounded)
		{
			groundPosition = hit.point;
			groundDistance = Mathf.Abs(Vector3.Dot(groundPosition - origin, direction));
			groundNormal = hit.normal;
			//if we need surface normal instead of collision normal:
			//if (hit.collider.Raycast(new Ray(hit.point - direction, direction), out hit, 10) && Vector3.Angle(hit.normal, -direction) < 89.5f)
			//{
			//	groundNormal = hit.normal;
			//}

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
				OnLeaveGround();
			}
			else
			{
				if (airJumpsLeft > 0)
				{
					airJumpsLeft--;
					OnJump();
				}
				else if (jumpCoyoteTimer > 0)
				{
					jumpCoyoteTimer = 0;
					OnJump();
				}
				else
				{
					jumpBufferTimer = jumpBufferTime;
				}
			}
		}

		if (state == MovementState.JUMPING)
		{
			//add jump force
			forcesVelocity = Vector3.ProjectOnPlane(forcesVelocity, upDirection);
			forcesVelocity += upDirection * jumpSpeed;

			//check jump cancel
			if (input.EvaluateJumpCancelled() || jumpTimer <= 0)
			{
				state = MovementState.RISING;
			}
		}

		//check for jump cancel when grounded (sets jump cancel to false)
		_ = state == MovementState.GROUNDED && input.EvaluateJumpCancelled();
	}

	void OnJump()
	{
		//set state
		state = MovementState.JUMPING;
		//set the jump timer
		jumpTimer = jumpDuration;
		//add force
		forcesVelocity = Vector3.ProjectOnPlane(forcesVelocity, upDirection);
		forcesVelocity += upDirection * jumpSpeed;
	}

	void OnLand()
	{
		onEnterGround.Invoke();
		airJumpsLeft = airJumps;

		if (jumpBufferTimer > 0)
		{
			jumpBufferTimer = 0;
			OnJump();
			OnLeaveGround();
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
		onLeaveGround.Invoke();
		jumpCoyoteTimer = jumpCoyoteTime;
		collisionGroundDetected = false;
	}

	private void OnControllerColliderHit(ControllerColliderHit hit)
	{
		//cancel input velocity going into collision
		float inputHitAmount = Vector3.Dot(hit.normal, inputVelocity);
		if (inputHitAmount < -0.2f)
		{
			//input gets bounce
			inputVelocity -= ((1 + bounciness - 0.2f) * inputHitAmount) * hit.normal;
		}

		if (state == MovementState.FALLING)
		{
			float forcesHitAmount = Vector3.Dot(hit.normal, forcesVelocity);
			if (forcesHitAmount < 0)
			{
				forcesVelocity -= forcesHitAmount * hit.normal;
			}
		}
		//check if collision is on bottom part of sphere and is under the controller slope limit (and therefore can be detected as onground)
		//if it is, the groundmagnet will be enabled, leading to better ground detection
		//this is disabled while jumping
		collisionGroundDetected = state != MovementState.JUMPING && Vector3.Angle(hit.normal, upDirection) < controller.slopeLimit && hit.point.y - transform.position.y < controller.radius;
			
	}

	#region Properties
	public MovementState State { get { return state; } }
	public Vector3 TotalVelocity { get { return totalVelocity; } }
	#endregion

	private void OnDrawGizmosSelected()
	{
		if (drawDebug && Application.isPlaying)
		{
			float radius = controller.radius * groundDetectionRadiusModifier;

			float length = controller.height / 2 + controller.skinWidth;
			if (enableGroundMagnet)
				length *= (1+ groundMagnetDistanceModifier);

			Gizmos.color = Color.magenta;
			Gizmos.DrawWireSphere(transform.TransformPoint(controller.center) + (length * (1 + groundDetectionAdditionalOffset) - radius) * -upDirection, radius);
		}
	}
}
