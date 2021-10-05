using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

[DefaultExecutionOrder(10)]
[RequireComponent(typeof(CharacterController), typeof(PlayerInputController))]
//Controls all player movement
public class PlayerMotor : MonoBehaviour
{
	#region Exposed Variables
	[Tooltip("The transform of the gameobject whose forward is in the direction of forward input.")]
	public Transform cameraTransform;

	//FORCES
	[Tooltip("The acceleration applied to the player's input.")]
	public float acceleration = 10;
	[Tooltip("The target speed of a player's input")]
	public float targetSpeed = 10;
	[Tooltip("The vertical gravity amount.")]
	public float gravity = 10;
	[Tooltip("The maximum velocity overall.")]
	public float maxVelocity = 1000;

	//FRICTION
	[Tooltip("The magnitude of velocity removed every second when in the air")]
	public float airFriction = 0.5f;
	[Tooltip("The magnitude of velocity removed every second when grounded")]
	public float groundFriction = 0.5f;

	//JUMPING
	[Tooltip("The amount of upward velocity applied when jumping")]
	public float jumpSpeed = 4;
	[Tooltip("The maximum length of time the jumpspeed is applied")]
	public float jumpDuration = 0.3f;
	[Tooltip("The amount of jumps the player can do in the air")]
	public float airJumps = 0;
	[Tooltip("If the player tries to jump before they have touched the ground, it will be processed if less than this amount of time has past")]
	public float jumpBufferTime = 0.1f;
	[Tooltip("If the player tries to jump after they have left the ground, it will be processed if less than this amount of time has past")]
	public float jumpCoyoteTime = 0.1f;

	//COLLISION
	[Tooltip("The amount the player's input bounces from a collision.")]
	[Range(0, 1)] public float bounciness = 0;
	[Tooltip("The minimum velocity into a collision before the input velocity is modified")]
	public float minCollisionVelocity = 0.1f;
	[Tooltip("The layers that do not affect input velocity when colliding")]
	public LayerMask ignoredCollision;

	//CONTROL
	[Tooltip("The percent of acceleration applied to input while in the air")]
	[Range(0, 1)] public float airControlModifier = 0.5f;

	//GROUND DETECTION 
	[Tooltip("The percentage of the character controller's radius that will be used for ground check spherecasts")]
	[Range(0, 1)] public float groundDetectionRadiusModifier = 0.8f;
	[Tooltip("The amount that the ground detection sphere is offset from the bottom of the character controller capsule")]
	[Range(0, 0.1f)] public float groundDetectionAdditionalOffset = 0.01f;
	[Tooltip("Affects the distance that will be added to the ground detection distance when the ground magnet is enabled")]
	[Range(0, 1)] public float groundMagnetDistanceModifier = 0.5f;
	[Tooltip("The layers that aren't checked against when raycasting")]
	public LayerMask ignoredGround;

	//ROTATION
	[Tooltip("The speed of rotation")]
	public float turnSpeed = 2;
	[Tooltip("The speed of rotation when in air")]
	public float airTurnSpeed = 2;
	[Tooltip("The minimum movement before the player rotates")]
	public float minPlayerRotation = 0.3f;

	//ROLLING
	//radius of rollCollider
	float rollColliderRadius = 0.5f;

	//EVENTS
	[Tooltip("The event called when leaving the grounded state")]
	public UnityEvent onLeaveGround;
	[Tooltip("The event called when entering the grounded state")]
	public UnityEvent onEnterGround;

	//OTHER
	[Tooltip("Whether or not to draw additional debug information")]
	public bool drawDebug = false;
	#endregion

	#region Private Variables
	//~~~~~~~~~PRIVATE~~~~~~~~~
	//INPUT
	PlayerInputController input;
	//VELOCITY
	Vector3 totalVelocity;
	Vector3 inputVelocity;
	Vector3 targetVelocity;
	Vector3 forcesVelocity;
	//JUMP
	float jumpBufferTimer = 0;
	float jumpCoyoteTimer = 0;
	float jumpTimer = 0;
	float airJumpsLeft = 0;
	//GROUND DETECTION
	bool isGrounded = false;
	Vector3 groundPosition;
	Vector3 groundNormal;
	float groundDistance;
	Collider groundCollider;
	bool enableGroundMagnet = false;
	float groundMagnetOffset;
	bool collisionGroundDetected = false;
	//ROTATION
	Quaternion targetRotation;
	//COLLIDER SIZE
	float colliderHeight;
	float collierRadius;
	//ROLLING
	bool isRolling = false;
	//MOVING PLATFORM
	MovingPlatform movingPlatform = null;
	Vector3 movingPlatformOffset = Vector3.zero;
	//OTHER
	CharacterController controller;
	MovementState state = MovementState.FALLING;
	Vector3 inputForward;
	#endregion

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

		controller.Move(totalVelocity * Time.deltaTime + groundMagnetOffset * Vector3.up + movingPlatformOffset);
	}

	void UpdateMovementVector()
	{
		if (state == MovementState.GROUNDED)
		{
			targetVelocity = GetTargetVelocity();

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
				targetVelocity = GetTargetVelocity();

				inputVelocity = Vector3.MoveTowards(inputVelocity, targetVelocity, airControlModifier * acceleration * Time.deltaTime);
			}

			//FRICTION
			inputVelocity = Vector3.MoveTowards(inputVelocity, Vector3.zero, airFriction * Time.deltaTime);
		}

		Vector3 GetTargetVelocity()
		{
			inputForward = Vector3.ProjectOnPlane(cameraTransform.forward, Vector3.up).normalized;
			if (groundNormal.y != 0)
				inputForward += Vector3.up * -(groundNormal.x * inputForward.x + groundNormal.z * inputForward.z)/groundNormal.y;

			Vector3 targetVelocity = Vector3.Cross(inputForward, groundNormal) * -input.inputVector.x
				+ inputForward * input.inputVector.y;
			targetVelocity = Vector3.ClampMagnitude(targetVelocity, 1) * targetSpeed;

			if (drawDebug)
			{
				Debug.DrawRay(groundPosition, Vector3.Cross(inputForward, groundNormal), Color.red, Time.deltaTime, false);
				Debug.DrawRay(groundPosition, inputForward, Color.red, Time.deltaTime, false);
			}
			
			return targetVelocity;
		}
	}

	void UpdateForcesVector()
	{
		Vector3 frictionApplied;
		if (state == MovementState.GROUNDED)
		{
			//GRAVITY
			if (Vector3.Dot(forcesVelocity, Vector3.up) < 0)
			{
				forcesVelocity = Vector3.ProjectOnPlane(forcesVelocity, Vector3.up);
			}

			//FRICTION
			frictionApplied = Vector3.MoveTowards(Vector3.ProjectOnPlane(forcesVelocity, Vector3.up), Vector3.zero, groundFriction * Time.deltaTime);
		}
		else
		{
			//GRAVITY
			forcesVelocity -= Vector3.up * (gravity * Time.deltaTime);

			//FRICTION
			frictionApplied = Vector3.MoveTowards(Vector3.ProjectOnPlane(forcesVelocity, Vector3.up), Vector3.zero, airFriction * Time.deltaTime);
		}

		//apply friction
		float up = Vector3.Dot(forcesVelocity, Vector3.up);
		forcesVelocity = frictionApplied + up * Vector3.up;

		//clamp magnitude
		Vector3.ClampMagnitude(forcesVelocity, maxVelocity);
	}

	public void UpdateRotation()
	{
		Vector3 rotVec;
		float turnSpeed;
		if (state == MovementState.GROUNDED)
		{
			rotVec = Vector3.ProjectOnPlane(inputVelocity, Vector3.up);
			turnSpeed = this.turnSpeed;
		}
		else
		{
			rotVec = Vector3.ProjectOnPlane(totalVelocity, Vector3.up);
			turnSpeed = airTurnSpeed;
		}

		if (rotVec.magnitude >= minPlayerRotation)
		{
			Quaternion targetRotation = Quaternion.LookRotation(rotVec, Vector3.up);
			transform.rotation = Quaternion.RotateTowards(transform.rotation, targetRotation, Quaternion.Angle(transform.rotation, targetRotation) * Time.deltaTime * turnSpeed);
		}
	}

	void SetState()
	{
		bool movingUp = Vector3.Dot(Vector3.up, forcesVelocity) > 0.0001f;
		bool groundTooSteep = Vector3.Angle(groundNormal, Vector3.up) > controller.slopeLimit;

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
		Vector3 direction = -Vector3.up;
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
			if (hit.collider != groundCollider)
			{
				OnChangedCollider(hit.collider);
			}
			groundCollider = hit.collider;
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
		else
		{
			if (groundCollider != null)
				OnChangedCollider(null);

			groundNormal = Vector3.up;
			groundCollider = null;
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
			forcesVelocity = Vector3.ProjectOnPlane(forcesVelocity, Vector3.up);
			forcesVelocity += Vector3.up * jumpSpeed;

			//check jump cancel
			if (input.EvaluateJumpCancelled() || jumpTimer <= 0)
			{
				state = MovementState.RISING;
			}
		}
		else if (state != MovementState.GROUNDED && input.EvaluateJumpCancelled())
		{
		}
	}

	void OnJump()
	{
		//set state
		state = MovementState.JUMPING;
		//set the jump timer
		jumpTimer = jumpDuration;
		//add force
		forcesVelocity = Vector3.ProjectOnPlane(forcesVelocity, Vector3.up);
		forcesVelocity += Vector3.up * jumpSpeed;
		//remove inputvelocity going upward
		float upVel = Vector3.Dot(Vector3.up, inputVelocity);
		if (upVel > 0)
		{
			inputVelocity -= Vector3.up * upVel;
		}
		
		input.EvaluateJumpCancelled();
	}

	void OnLand()
	{
		//call land event
		onEnterGround.Invoke();
		//refresh air jumps
		airJumpsLeft = airJumps;

		//if there is a jump buffered
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
			input.EvaluateJumpCancelled();
		}
	}

	void OnLeaveGround()
	{
		onLeaveGround.Invoke();
		jumpCoyoteTimer = jumpCoyoteTime;
		collisionGroundDetected = false;
	}

	void OnChangedCollider(Collider newCollider)
	{
		if (newCollider == null)
		{
			//Disconnect from platform if no new collider
			if (movingPlatform != null)
			{
				//calculate velocity gained from leaving
				float time = Time.timeScale == 0 ? Mathf.Infinity : Time.fixedDeltaTime;
				Vector3 vel = movingPlatformOffset / time;
				forcesVelocity += new Vector3(vel.x, 0, vel.z);

				movingPlatform.SetConnectedPlayer(null);
				movingPlatformOffset = Vector3.zero;
				movingPlatform = null;
			}
		}
		else
		{
			var mp = newCollider.GetComponent<MovingPlatform>();
			if (mp != null)
			{
				movingPlatform = mp;
				movingPlatform.SetConnectedPlayer(this);
			}
			else
			{
				//Disconnect from platform if new collider has no moving platform component
				if (movingPlatform)
				{
					//calculate velocity gained from leaving
					float time = Time.timeScale == 0 ? Mathf.Infinity : Time.fixedDeltaTime;
					Vector3 vel = movingPlatformOffset / time;
					forcesVelocity += new Vector3(vel.x, 0, vel.z);

					movingPlatform.SetConnectedPlayer(null);
					movingPlatform = null;
					movingPlatformOffset = Vector3.zero;
				}
			}
		}
	}

	private void OnControllerColliderHit(ControllerColliderHit hit)
	{
		//cancel input velocity going into collision
		float inputHitAmount = Vector3.Dot(hit.normal, inputVelocity);
		if ((hit.gameObject.layer & ignoredCollision) == 0 && inputHitAmount < -minCollisionVelocity)
		{
			//input gets bounce
			inputVelocity -= ((1 + bounciness - minCollisionVelocity) * inputHitAmount) * hit.normal;
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
		collisionGroundDetected = state != MovementState.JUMPING && Vector3.Angle(hit.normal, Vector3.up) < controller.slopeLimit && hit.point.y - transform.position.y < controller.radius;
	}

	#region Properties
	public MovementState State { get { return state; } }
	public Vector3 TotalVelocity { get { return totalVelocity; } }
	public Vector3 TargetVelocity { get { return targetVelocity; } }
	public Vector3 GroundNormal { get { return groundNormal; } }
	public Vector3 MovingPlatformOffset { get { return movingPlatformOffset; } set { movingPlatformOffset = value; } }
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
			Gizmos.DrawWireSphere(transform.TransformPoint(controller.center) + (length * (1 + groundDetectionAdditionalOffset) - radius) * -Vector3.up, radius);
		}
	}
}
