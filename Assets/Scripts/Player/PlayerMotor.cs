﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.SceneManagement;

[DefaultExecutionOrder(10)]
[RequireComponent(typeof(CharacterController), typeof(PlayerController))]
//Controls all player movement
public class PlayerMotor : MonoBehaviour
{
	#region Exposed Variables
	//FORCES
	[Header("Walking")]
	[Tooltip("The acceleration applied to the player's input.")]
	public float acceleration = 10;
	[Tooltip("The target speed of a player's input")]
	public float targetSpeed = 10;
	[Tooltip("The vertical gravity amount.")]
	public float gravity = 10;
	[Tooltip("The maximum velocity overall.")]
	public float maxVelocity = 1000;
	[Tooltip("The percent of acceleration applied to input while in the air")]
	[Range(0, 1)] public float airControlModifier = 0.5f;

	//FRICTION
	[Tooltip("The magnitude of velocity removed every second when in the air")]
	public float airFriction = 0.5f;
	[Tooltip("The magnitude of velocity removed every second when grounded")]
	public float groundFriction = 0.5f;

	//JUMPING
	[Header("Jumping")]
	[Tooltip("The amount of upward velocity applied when jumping")]
	[Min(0)]
	public float jumpSpeed = 4;
	[Tooltip("The maximum length of time the jumpspeed is applied")]
	[Min(0)]
	public float jumpDuration = 0.3f;
	[Tooltip("The amount of jumps the player can do in the air")]
	[Min(0)]
	public float airJumps = 0;
	[Tooltip("If the player tries to jump before they have touched the ground, it will be processed if less than this amount of time has past")]
	[Min(0)]
	public float jumpBufferTime = 0.1f;
	[Tooltip("If the player tries to jump after they have left the ground, it will be processed if less than this amount of time has past")]
	[Min(0)]
	public float jumpCoyoteTime = 0.1f;

	[Header("Dash")]
	[Tooltip("The curve that dictates the players speed while dashing. Player only samples from 0 to 1")]
	public AnimationCurve dashCurve;
	[Tooltip("The target speed of the dash at a y value of one on the dash curve")]
	public float dashSpeed = 4;
	[Tooltip("The acceration of the player for getting to that speed")]
	public float dashAcceleration = 200;
	[Tooltip("The length of time a dash takes place over")]
	public float dashDuration = 0.2f;
	[Tooltip("How long after one dash you can do another one")]
	public float dashCooldown = 2;
	[Tooltip("How fast the players model turns to point in the direction of the dash")]
	public float dashTurnSpeed = 40;

	//COLLISION
	[Header("Collision Response")]
	[Tooltip("The minimum velocity into a collision before the input velocity is modified")]
	public float minCollisionVelocity = 0.1f;
	[Tooltip("The mass used for rigidbody collision")]
	public float mass = 1;
	[Tooltip("The restitution value used for rigidbody collision")]
	[Range(0,1)] public float bounciness = 0;
	[Tooltip("The layers that do not affect input velocity when colliding")]
	public LayerMask ignoredCollision;
	[Tooltip("The maximum dot product magnitdude of a collision normal and velocity before a dash is cancelled")]
	public float dashCancelDot = 0.5f;
	[Tooltip("The maximum dot product magnitdude of a collision normal and velocity before a jump is cancelled (only applies for ceiling collisions)")]
	public float ceilingCancelDot = 0.5f;

	//GROUND DETECTION 
	[Header("Ground Detection")]
	[Tooltip("The percentage of the character controller's radius that will be used for ground check spherecasts")]
	[Range(0, 1)] public float groundDetectionRadiusModifier = 0.8f;
	[Tooltip("The amount that the ground detection sphere is offset from the bottom of the character controller capsule")]
	[Range(0, 0.1f)] public float groundDetectionAdditionalOffset = 0.01f;
	[Tooltip("Affects the distance that will be added to the ground detection distance when the ground magnet is enabled")]
	[Range(0, 1)] public float groundMagnetDistanceModifier = 0.5f;
	[Tooltip("The layers that aren't checked against when raycasting")]
	public LayerMask ignoredGround;

	//ROTATION
	[Header("Rotation")]
	[Tooltip("Whether the player is locked looking away from the camera or looks toward input")]
	public bool alwaysLookAway = false;
	[Tooltip("The speed of rotation")]
	public float turnSpeed = 2;
	[Tooltip("The speed of rotation when in air")]
	public float airTurnSpeed = 2;
	[Tooltip("The minimum movement before the player rotates")]
	[Min(0)]
	public float minPlayerRotation = 0.3f;
	[Tooltip("The speed of roll rotation")]
	[Min(0)]
	public float fixRotationSpeed = 1000;
	[Range(0,45)]
	public float bodyMaxGroundAlignAngle = 10;
	public float walkAlignSpeed = 7;

	//ROLLING
	//radius of rollCollider
	[Header("Rolling")]
	[Tooltip("Percentage of collider radius used for rotation")]
	public float rollRadiusModifier = 0.5f;
	[Tooltip("Percentage of target speed used when rolling")]
	public float rollTargetSpeedModifier = 1;
	[Tooltip("Percentage of acceleration used when rolling")]
	public float rollAccelerationModifier = 1;
	public float rollAirAccelerationModifier = 1;
	[Tooltip("The speed of turning while rolling")]
	public float rollTurnSpeed = 2;
	[Tooltip("The speed at which the player rotation aligns to the movement direction while rolling"), Min(0)]
	public float ballAlignSpeed = 1;
	[Tooltip("The cooldown time after rolling before the player can switch out of roll")]
	public float rollCooldownTime = 0;
	[Min(0)]
	[Tooltip("The amount of upwards force applied to the player when leaving roll")]
	public float leaveRollHopSpeed = 0;
	[Tooltip("The amount of friction applied per second while rolling (proportional to total velocity)")]
	[Range(0, 3)] public float rollFriction = 0.5f;
	[Tooltip("The speed at which the ball no longer attaches to the floor")]
	public float ignoreGroundMagnetSpeed = 9;

	[Header("Other")]
	public float movingPlatformForceMultiplier = 2;

	//EVENTS
	[Header("Events")]
	[Tooltip("The event called when leaving the grounded state")]
	public UnityEvent onLeaveGround;
	[Tooltip("The event called when entering the grounded state")]
	public UnityEvent onEnterGround;
	[Tooltip("The event called when entering or leaving a roll")]
	public UnityEvent onChangeRoll;
	[Tooltip("The event called when dashing")]
	public UnityEvent onDash;

	[Header("Particle Effects")]
	public ParticleSystem dashParticles;
	#endregion

	#region Private Variables
	//~~~~~~~~~PRIVATE~~~~~~~~~
	//REFERENCES
	PlayerController playerController;
	//VELOCITY
	Vector3 inputVelocity;
	Vector3 lastNonZeroInputVelocity;
	Vector3 targetVelocity;
	Vector3 forcesVelocity;
	//JUMP
	float jumpBufferTimer = 0;
	float jumpCoyoteTimer = 0;
	float jumpTimer = 0;
	float airJumpsLeft = 0;
	//dash
	float currentDashDuration;
	float currentDashVelocity;
	Vector3 currentDashDirection;
	[System.NonSerialized] public AnimationCurve currentDashCurve;
	float dashCooldownTimer = 0;
	float dashTimer = 0;
	bool dashing = false;
	bool dashedInThisJump = false;
	//GROUND DETECTION
	bool isGrounded = false;
	Vector3 groundPosition;
	Vector3 groundNormal;
	float groundDistance;
	float groundAngle;
	Collider groundCollider;
	bool enableGroundMagnet = false;
	float groundMagnetOffset;
	bool collisionGroundDetected = false;
	//ROTATION
	Quaternion targetRotation;
	//ROLLING
	bool isRolling = false;
	float rollCooldownTimer = 0;
	//MOVING PLATFORM
	MovingPlatform movingPlatform = null;
	//OTHER
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

	private void Start()
	{
		playerController = GetComponent<PlayerController>();
		TargetSpeedManipulator = 1;
		lastNonZeroInputVelocity = Vector3.ProjectOnPlane(playerController.RotateChild.forward, Vector3.up).normalized;
	
		if (transform.rotation != Quaternion.identity)
		{
			Quaternion rot = playerController.RotateChild.rotation;
			transform.rotation = Quaternion.identity;
			playerController.RotateChild.rotation = rot;
		}
	}

	private void Update()
	{
		UpdateRotation();

		if (playerController.DrawDebug && isGrounded)
		{
			Debug.DrawRay(groundPosition, groundNormal, Color.blue, Time.deltaTime);
		}
	}

	private void FixedUpdate()
	{
		Run();
	}

	void Run()
	{
		ScanForGround();
		SetState();
		EvaluateJump();
		EvaluateRoll();
		EvaluateDash();
		UpdateMovementVector();
		UpdateForcesVector();

		//set ground magnet enabled/disabled
		enableGroundMagnet = state == MovementState.GROUNDED || collisionGroundDetected;
		
		//move player
		playerController.CharacterController.Move(TotalVelocity * Time.deltaTime 
			+ groundMagnetOffset * Vector3.up);
		lastCollider = null;
		//Set all timers
		jumpTimer -= Time.deltaTime;
		jumpCoyoteTimer -= Time.deltaTime;
		jumpBufferTimer -= Time.deltaTime;
		rollCooldownTimer -= Time.deltaTime;
		dashCooldownTimer -= Time.deltaTime;
		dashTimer -= Time.deltaTime;
		TargetSpeedManipulator = 1;
	}

	void UpdateMovementVector()
	{
		if (inputVelocity != Vector3.zero)
			lastNonZeroInputVelocity = inputVelocity;
		if (isRolling)
		{
			targetVelocity = GetTargetDirection() * rollTargetSpeedModifier;
			if (playerController.inputVector != Vector2.zero)
			{
				float acc = acceleration * rollAccelerationModifier;
				if (state != MovementState.GROUNDED)
					acc *= rollAirAccelerationModifier;

				inputVelocity += Vector3.ClampMagnitude(targetVelocity, acc * Time.deltaTime);
			}

			if (state == MovementState.GROUNDED)
			{
				//add friction
				inputVelocity = inputVelocity + -Mathf.Clamp(Time.deltaTime * rollFriction, 0, 1) * inputVelocity;//Vector3.MoveTowards(Vector3.ProjectOnPlane(forcesVelocity, Vector3.up), Vector3.zero, groundFriction * Time.deltaTime);
																												  //remove vertical force to prevent unwanted accumulation
				float verticalForce = Vector3.Dot(groundNormal, inputVelocity);
				inputVelocity = Vector3.ProjectOnPlane(inputVelocity, groundNormal) + groundNormal * Mathf.MoveTowards(verticalForce, 0, acceleration * Time.deltaTime);
				
				//LINEAR FRICTION
				//inputVelocity -= Vector3.MoveTowards(Vector3.ProjectOnPlane(inputVelocity, groundNormal), Vector3.zero, groundFriction * Time.deltaTime *0.0000001f);

				//do not magnet to ground if going fast enough
				if (Vector3.Dot(groundMagnetOffset * Vector3.up, groundNormal) < 0 && Vector3.ProjectOnPlane(inputVelocity, groundNormal).sqrMagnitude > ignoreGroundMagnetSpeed * ignoreGroundMagnetSpeed)
				{
					groundMagnetOffset = 0;
					state = TotalVelocity.y > 0 ? MovementState.RISING : MovementState.FALLING;
				}
			}
			else
			{
				//FRICTION
				inputVelocity = Vector3.MoveTowards(inputVelocity, Vector3.zero, airFriction * Time.deltaTime);
			}
			//clamp to target speed
			inputVelocity = Vector3.ClampMagnitude(inputVelocity, targetSpeed * rollTargetSpeedModifier);
		}
		else
		{
			if (state == MovementState.GROUNDED)
			{
				targetVelocity = GetTargetDirection() * targetSpeed * TargetSpeedManipulator;

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
				if (playerController.inputVector != Vector2.zero)
				{
					targetVelocity = GetTargetDirection() * targetSpeed * TargetSpeedManipulator;

					inputVelocity = Vector3.MoveTowards(inputVelocity, targetVelocity, airControlModifier * acceleration * Time.deltaTime * (isRolling ? rollTargetSpeedModifier : 1));
				}

				//FRICTION
				inputVelocity = Vector3.MoveTowards(inputVelocity, Vector3.zero, airFriction * Time.deltaTime);
			}

			
		}

		if (dashing)
		{
			float t = currentDashCurve.Evaluate(1 - dashTimer / dashDuration);
			targetVelocity = currentDashDirection * currentDashVelocity * t;

			//transition between the two velocities
			targetVelocity = Vector3.Lerp(inputVelocity, targetVelocity, t);
			inputVelocity = Vector3.MoveTowards(inputVelocity, targetVelocity, dashAcceleration * Time.deltaTime);

			if (dashTimer <= 0)
			{
				dashing = false;
			}
		}

		Vector3 GetTargetDirection()
		{
			inputForward = Vector3.ProjectOnPlane(playerController.MainCamera.transform.forward, Vector3.up).normalized;
			if (groundNormal.y != 0)
			{
				inputForward += Vector3.up * -(groundNormal.x * inputForward.x + groundNormal.z * inputForward.z)/groundNormal.y;
				inputForward.Normalize();
			}

			Vector3 targetVelocity = Vector3.Cross(inputForward, groundNormal) * -playerController.inputVector.x
				+ inputForward * playerController.inputVector.y;
			targetVelocity = Vector3.ClampMagnitude(targetVelocity, 1);

			if (playerController.DrawDebug)
			{
				Debug.DrawRay(groundPosition, Vector3.Cross(inputForward, groundNormal), Color.red, Time.deltaTime, false);
				Debug.DrawRay(groundPosition, inputForward, Color.red, Time.deltaTime, false);
			}
			
			return targetVelocity;
		}
	}

	void UpdateForcesVector()
	{
		Vector3 planeVelocity = Vector3.ProjectOnPlane(forcesVelocity, Vector3.up);

		if (state == MovementState.GROUNDED)
		{
			//GRAVITY
			if (Vector3.Dot(forcesVelocity, Vector3.up) < 0)
			{
				forcesVelocity = planeVelocity;
			}

			//FRICTION
			planeVelocity = Vector3.MoveTowards(planeVelocity, Vector3.zero, groundFriction * Time.deltaTime);
		}
		else
		{
			//GRAVITY
			forcesVelocity -= Vector3.up * (gravity * Time.deltaTime);

			//FRICTION
			planeVelocity = Vector3.MoveTowards(planeVelocity, Vector3.zero, airFriction * Time.deltaTime);
		}

		//apply friction
		float up = Vector3.Dot(forcesVelocity, Vector3.up);
		forcesVelocity = planeVelocity + up * Vector3.up;

		//clamp magnitude
		Vector3.ClampMagnitude(forcesVelocity, maxVelocity);
	}

	public void UpdateRotation()
	{
		float turnSpeed;
		
		if (isRolling)
		{
			float distance = TotalVelocity.magnitude * Time.deltaTime;
			if (distance < 0.001f)
				return;
			
			float angle = distance * Mathf.Rad2Deg / (rollRadiusModifier * (playerController.RollColliderRadius + playerController.CharacterController.skinWidth));
			Vector3 axis = Vector3.Cross(groundNormal, TotalVelocity).normalized;
			targetRotation = Quaternion.Euler(axis * angle) * playerController.RotateChild.localRotation;

			if (ballAlignSpeed > 0)
			{
				//align to input velocity direction
				Quaternion aligned = Quaternion.FromToRotation(playerController.RotateChild.right, axis) * targetRotation;
				float alignedAngle = Mathf.Acos(Mathf.Clamp(Vector3.Dot(playerController.RotateChild.up, axis), -1f, 1f)) * Mathf.Rad2Deg;
				float frameMaxAlignedAngle = ballAlignSpeed * distance * Time.deltaTime;
				if (alignedAngle <= frameMaxAlignedAngle)
					targetRotation = aligned;
				else
					targetRotation = Quaternion.SlerpUnclamped(targetRotation, aligned, frameMaxAlignedAngle / angle);
			}

			playerController.RotateChild.localRotation = targetRotation;// Quaternion.RotateTowards(playerController.RotateChild.rotation, targetRotation, Quaternion.Angle(playerController.RotateChild.rotation, targetRotation) * fixRotationSpeed * Time.deltaTime);
			
			Transform modelTransform = playerController.Animator.transform;
			modelTransform.localRotation = Quaternion.RotateTowards(modelTransform.localRotation, Quaternion.identity,
				Quaternion.Angle(modelTransform.localRotation, Quaternion.identity) * walkAlignSpeed * Time.deltaTime);
		}
		else
		{
			Vector3 rotVec;

			if (alwaysLookAway)
			{
				rotVec = Vector3.ProjectOnPlane(playerController.MainCamera.transform.forward, Vector3.up);
				turnSpeed = this.turnSpeed * 4;
			}
			else if (dashing)
			{
				rotVec = Vector3.ProjectOnPlane(targetVelocity, Vector3.up);
				turnSpeed = dashTurnSpeed;
			}
			else if (state == MovementState.GROUNDED)
			{
				if (targetVelocity != Vector3.zero)
					rotVec = Vector3.ProjectOnPlane(targetVelocity, Vector3.up);
				else
					rotVec = Vector3.ProjectOnPlane(playerController.RotateChild.forward, Vector3.up);
				turnSpeed = this.turnSpeed;
			}
			else
			{
				rotVec = Vector3.ProjectOnPlane(TotalVelocity, Vector3.up);
				turnSpeed = airTurnSpeed;
			}
			
			if (rotVec.magnitude >= minPlayerRotation)
			{
				targetRotation = Quaternion.LookRotation(rotVec, Vector3.up);
				playerController.RotateChild.localRotation = Quaternion.RotateTowards(playerController.RotateChild.localRotation, targetRotation,
				   Quaternion.Angle(playerController.RotateChild.localRotation, targetRotation) * Time.deltaTime * turnSpeed);
			}
			else
			{
				playerController.RotateChild.localRotation = Quaternion.RotateTowards(playerController.RotateChild.localRotation, targetRotation,
				   Quaternion.Angle(playerController.RotateChild.localRotation, targetRotation) * Time.deltaTime * turnSpeed);
			}

			Transform modelTransform = playerController.Animator.transform;
			Vector3 clampedGroundNormal = Vector3.RotateTowards(Vector3.up, groundNormal, Mathf.Max(groundAngle / playerController.CharacterController.slopeLimit, 1) * bodyMaxGroundAlignAngle * Mathf.Deg2Rad, 1);
			var target = Quaternion.FromToRotation(Vector3.up, Quaternion.Inverse(playerController.RotateChild.rotation) * clampedGroundNormal);
			modelTransform.localRotation = Quaternion.RotateTowards(modelTransform.localRotation, target,
				Quaternion.Angle(modelTransform.localRotation, target) *  walkAlignSpeed * Time.deltaTime);
		}
	}

	void SetState()
	{
		bool movingUp = Vector3.Dot(Vector3.up, forcesVelocity) > 0.0001f;
		bool groundTooSteep = groundAngle > playerController.CharacterController.slopeLimit;

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
		Vector3 origin = transform.TransformPoint(playerController.CharacterController.center);
		float length = playerController.CharacterController.height / 2 
			+ playerController.CharacterController.skinWidth;

		if (enableGroundMagnet)
		{
			length *= (1+ groundMagnetDistanceModifier);
		}
		else
		{
			groundMagnetOffset = 0;
		}
		float radius = playerController.CharacterController.radius * groundDetectionRadiusModifier;

		isGrounded = Physics.SphereCast(origin, radius, direction, out var hit,
			length * (1 + groundDetectionAdditionalOffset) - radius, ~ignoredGround, QueryTriggerInteraction.Ignore);

		var rb = hit.rigidbody;
		//in a very specific case rigidbodies can cause the player to not detect the ground, this should fix that
		groundAngle = Vector3.Angle(hit.normal, Vector3.up);
		if (rb && !rb.isKinematic && groundAngle > playerController.CharacterController.slopeLimit)
		{
			//make collider undetectable
			GameObject hitObject = hit.collider.gameObject;
			int layer = hitObject.layer;
			int newLayer = 0;
			//find 
			while ((ignoredGround & (1 <<newLayer)) == 0 && newLayer < 32)
				newLayer++;

			if (newLayer < 32)
			{
				hitObject.layer = newLayer;
				isGrounded = Physics.SphereCast(origin, radius, direction, out hit,
					length * (1 + groundDetectionAdditionalOffset) - radius, ~ignoredGround);
				hitObject.layer = layer;
			}
		}

		if (isGrounded)
		{
			groundPosition = hit.point;
			groundDistance = Mathf.Abs(Vector3.Dot(groundPosition - origin, direction));
			groundNormal = hit.normal;
			groundAngle = Vector3.Angle(groundNormal, Vector3.up);
			//if onChangedCollider needs to be called, and 
			if (hit.collider != groundCollider && !OnChangedCollider(hit.collider))
			{
				groundNormal = Vector3.up;
				groundAngle = 0;
				groundCollider = null;
				isGrounded = false;
				enableGroundMagnet = false;
				return;
			}
			groundCollider = hit.collider;
			//if we need surface normal instead of collision normal:
			//if (hit.collider.Raycast(new Ray(hit.point - direction, direction), out hit, 10) && Vector3.Angle(hit.normal, -direction) < 89.5f)
			//{
			//	groundNormal = hit.normal;
			//}

			float offset = (playerController.CharacterController.height / 2 + playerController.CharacterController.skinWidth - groundDistance );
			if (enableGroundMagnet && (offset < 0 || movingPlatform != null))
			{
				groundMagnetOffset = offset;
			}
		}
		else
		{
			if (groundCollider != null)
				OnChangedCollider(null);

			groundNormal = Vector3.up;
			groundAngle = 0;
			groundCollider = null;

			////move input velocity into force velocity
			//float fDot = Vector3.Dot(inputVelocity, groundNormal);
			//forcesVelocity += fDot * groundNormal;
			//inputVelocity -= fDot * groundNormal;
		}
	}

	public void RefreshDash()
	{
		dashedInThisJump = false;
		dashing = false;
		dashTimer = 0;
		dashCooldownTimer = 0;
	}

	void EvaluateJump()
	{
		//start jump
		if (playerController.EvaluateJumpPressed())
		{
			//if rolling
			if (isRolling)
			{
				if (rollCooldownTimer <= 0)
				{
					OnLeaveRoll(true);
				}
				else
					return;
			}

			if (state == MovementState.GROUNDED)
			{
				playerController.PlayAudioOnce(playerController.AudioData.jumpSounds, false, 0.3f);
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
					playerController.EvaluateJumpCancelled();
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
			if (playerController.EvaluateJumpCancelled() || jumpTimer <= 0)
			{
				state = MovementState.RISING;
			}
		}
		else if (state == MovementState.GROUNDED)
		{
			playerController.EvaluateJumpCancelled();
		}
	}

	void EvaluateDash()
	{
		if (playerController.EvaluateSprintPressed() && !isRolling && dashCooldownTimer <= 0 && !dashing)
		{
			OnStartDash();
		}
	}

	void EvaluateRoll()
	{
		//start roll
		if (playerController.EvaluateCrouchPressed() && rollCooldownTimer <= 0)
		{
			if (isRolling)
			{
				OnLeaveRoll();	
			}
			else
			{
				OnRoll();
			}
		}
	}

	void OnRoll()
	{
		//playerController.FootstepAudio.clip = playerController.AudioData.ballRoll.GetRandom();
		rollCooldownTimer = rollCooldownTime;
		isRolling = true;
		onChangeRoll.Invoke();
		targetRotation = Quaternion.identity;
		if (!dashing)
			playerController.PlayAudioOnce(playerController.AudioData.rollTuck, false, 0.1f);
	}

	void OnLeaveRoll(bool fromJump = false)
	{
		rollCooldownTimer = rollCooldownTime;
		isRolling = false;
		onChangeRoll.Invoke();
		if (leaveRollHopSpeed > 0 && !fromJump && state == MovementState.GROUNDED)
		{
			state = MovementState.RISING;
			forcesVelocity += Vector3.up * leaveRollHopSpeed;
			OnLeaveGround();
		}
		targetRotation = Quaternion.LookRotation(Vector3.ProjectOnPlane(lastNonZeroInputVelocity, Vector3.up), Vector3.up);

		if (fromJump)
			playerController.PlayAudioOnce(playerController.AudioData.jumpRollPop, false, 0.1f);
		else if (InputVelocity.sqrMagnitude > 9)
			playerController.PlayAudioOnce(playerController.AudioData.rollPop, false, 0.1f);
		else
			playerController.PlayAudioOnce(playerController.AudioData.rollPopNotMoving, false, 0.1f);
	}

	public void CancelRoll()
	{
		OnLeaveRoll(false);
	}

	void OnJump()
	{
		//set state
		state = MovementState.JUMPING;
		groundMagnetOffset = 0;
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
		if (playerController.EvaluateJumpCancelled())
			state = MovementState.RISING;

		if (dashing)
		{
			dashing = false;
			dashedInThisJump = false;
			inputVelocity = Vector3.ClampMagnitude(inputVelocity, inputVelocity.magnitude - jumpSpeed);
		}

	}

	void OnStartDash()
	{
		currentDashVelocity = dashSpeed;
		currentDashDuration = dashDuration;
		currentDashCurve = dashCurve;
		playerController.PlayAudioOnce(playerController.AudioData.dash, false, 0.3f);

		if (state != MovementState.GROUNDED)
		{
			if (dashedInThisJump)
			{
				return;
			}
			else
			{
				dashedInThisJump = true;
			}
		}
		dashing = true;
		dashCooldownTimer = dashCooldown;
		dashTimer = currentDashDuration;
		if (playerController.inputVector == Vector2.zero)
		{
			inputForward = Vector3.ProjectOnPlane(playerController.MainCamera.transform.forward, Vector3.up).normalized;
			if (groundNormal.y != 0)
			{
				inputForward += Vector3.up * -(groundNormal.x * inputForward.x + groundNormal.z * inputForward.z) / groundNormal.y;
				inputForward.Normalize();
			}
			currentDashDirection = inputForward;
		}
		else
		{
			inputForward = Vector3.ProjectOnPlane(playerController.MainCamera.transform.forward, Vector3.up).normalized;
			if (groundNormal.y != 0)
			{
				inputForward += Vector3.up * -(groundNormal.x * inputForward.x + groundNormal.z * inputForward.z) / groundNormal.y;
				inputForward.Normalize();
			}
			currentDashDirection = Vector3.Cross(inputForward, groundNormal) * -playerController.inputVector.x
				+ inputForward * playerController.inputVector.y;
			currentDashDirection.Normalize();
		}
		OnRoll();
		onDash.Invoke();

		if (dashParticles != null)
		{
			dashParticles.transform.forward = -currentDashDirection;
			dashParticles.Play(true);
		}
		IsExternalDash = false;
	}

	//a dash called by an external script
	public void StartExternalDash(float dashSpeed, float dashDuration, Vector3 dashDirection, AnimationCurve dashCurve = null, bool considerCooldown = false)
	{
		if (dashCurve == null)
			currentDashCurve = this.dashCurve;
		else 
			currentDashCurve = dashCurve;
		
		if (considerCooldown)
		{
			if (dashCooldownTimer > 0) return; 
			dashCooldownTimer = dashCooldown;
		}
		currentDashDirection = dashDirection;
		currentDashDuration = dashDuration;
		currentDashVelocity = dashSpeed;
		dashing = true;

		dashTimer = currentDashDuration;
		currentDashDirection = dashDirection;
		onDash.Invoke();
		IsExternalDash = true;
	}

	public void AddKnockback(float dashSpeed, float dashDuration, Vector3 dashDirection, AnimationCurve knockbackCurve = null)
	{
		//WILL START AN EXTERNAL DASH, BUT WILL ALSO DO SPECIFIC KNOCKBACK STUFF LIKE BREAKING OUT OF ROLL
		StartExternalDash(dashSpeed, dashDuration, dashDirection, dashCurve, false);
	}

	void OnLand()
	{
		//call land event
		onEnterGround.Invoke();
		//refresh air jumps
		airJumpsLeft = airJumps;
		dashedInThisJump = false;

		//if there is a jump buffered
		if (jumpBufferTimer > 0)
		{
			jumpBufferTimer = 0;
			OnJump();
			OnLeaveGround();
			//cancel jump immediatly if player let go of button
			if (playerController.EvaluateJumpCancelled())
			{
				state = MovementState.RISING;
			}
		}
	}

	void OnLeaveGround()
	{
		onLeaveGround.Invoke();
		jumpCoyoteTimer = jumpCoyoteTime;
		collisionGroundDetected = false;
		groundMagnetOffset = 0;
		OnChangedCollider(null);
		groundCollider = null;

		if (inputVelocity.y > 0)
		{
			forcesVelocity.y += inputVelocity.y;
			inputVelocity.y = 0;
		}
	}

	public void CancelGroundMagnet()
	{
		groundMagnetOffset = 0;
		collisionGroundDetected = false;
	}

	bool OnChangedCollider(Collider newCollider)
	{
		if (newCollider == null)
		{
			//leave the platform if no new collider && was on platform
			if (movingPlatform != null)
			{
				//disconnect from platform
				movingPlatform.AssignPlayer(null);
				movingPlatform = null;
				playerController.InterpolateVisuals = true;
			}
		}
		else
		{
			//check for a player collider 
			var pC = newCollider.GetComponent<PlayerCollision>();
			if (pC && pC.enabled && !playerController.Health.IsDead && !pC.OnPlayerGrounded(playerController))
			{
				return false;
			}

			//connect to moving platform if there is a moving platform component
			var mp = newCollider.GetComponent<MovingPlatform>();
			if (mp != null)
			{
				//connect
				movingPlatform = mp;
				movingPlatform.AssignPlayer(playerController);
				playerController.InterpolateVisuals = false;
			}
			else
			{
				//Disconnect from platform if new collider has no moving platform component
				if (movingPlatform)
				{
					//disconnect from platform
					movingPlatform.AssignPlayer(null);
					movingPlatform = null;
					playerController.InterpolateVisuals = true;
				}
			}

			
		}
		return true;
	}


	public void ResetMotor()
	{
		OnChangedCollider(null);
		dashing = false;
		if (isRolling)
		{
			OnLeaveRoll();
		}
		if (state != MovementState.GROUNDED)
		{
			state = MovementState.GROUNDED;
			OnLand();
		}

		forcesVelocity = Vector3.zero;
		inputVelocity = Vector3.zero;

	}
	Collider lastCollider = null;

	private void OnControllerColliderHit(ControllerColliderHit hit)
	{
		if (hit.collider.isTrigger || (hit.gameObject.layer & ignoredCollision) != 0) return;

		//prevent multiple collision responses per gameobject (usually only happens when there is one collider)
		if (lastCollider == hit.collider)
		{
			return;
		}
		lastCollider = hit.collider;
		
		if (playerController.DrawDebug)
		{
			Debug.DrawRay(hit.point, hit.normal, Color.red, 1);
		}

		float angle = Vector3.Angle(hit.normal, Vector3.up);
		Rigidbody rb = hit.rigidbody;

		//if it doesn't have a collision react component or is dead or something, do not collide
		var playerCollision = hit.gameObject.GetComponent<PlayerCollision>();
		if (!playerCollision || !playerCollision.enabled || playerController.Health.IsDead || playerCollision.OnCollideWithPlayer(playerController, hit))
		{
			float inputHitAmount = Vector3.Dot(hit.normal, inputVelocity);

			//cancel dash & play smack into stuff audio
			float dotAmount = Vector3.Dot(-inputVelocity.normalized, hit.normal);
			if (dashing && dotAmount > dashCancelDot)
			{
				//cancel dash if going into wall
				dashing = false;
				if (dashParticles)
					dashParticles.Stop(true, ParticleSystemStopBehavior.StopEmitting);
			}

			//play collide audio
			if (isRolling)
			{
				if (inputHitAmount < -3 && dotAmount > 0.5f)
					playerController.PlayAudioOnce(playerController.AudioData.hitWallRolling);
			}
			else if (inputHitAmount < -6 && dotAmount > 0.8f)
			{
				playerController.PlayAudioOnce(playerController.AudioData.land);
			}

			if (rb && !rb.isKinematic)
			{
				Vector3 rv = inputVelocity - rb.GetPointVelocity(hit.point);
				float projRV = Vector3.Dot(rv, hit.normal);
				if (projRV < 0)
				{
					float impulseMag = ((1 + bounciness) * projRV) / (1 / mass + 1 / rb.mass);

					inputVelocity -= impulseMag * hit.normal / mass;
					rb.AddForceAtPosition(impulseMag * hit.normal, hit.point, ForceMode.Impulse);
				}
			}
			else
			{
				//cancel input velocity going into collision
				if ((hit.gameObject.layer & ignoredCollision) == 0 && inputHitAmount < -minCollisionVelocity)
				{
					inputVelocity -= ((1 - minCollisionVelocity) * inputHitAmount) * hit.normal;


					if (playerController.DrawDebug)
					{
						Debug.DrawRay(hit.point, hit.normal, Color.red, 1);
					}
				}
			}

			if (state == MovementState.FALLING || isRolling)
			{
				float forcesHitAmount = Vector3.Dot(hit.normal, forcesVelocity + inputVelocity);
				if (forcesHitAmount < 0)
				{
					forcesVelocity -= forcesHitAmount * hit.normal;
					inputVelocity = Vector3.ProjectOnPlane(inputVelocity, hit.normal);
					if (forcesHitAmount < -5)
						playerController.PlayAudioOnce(playerController.AudioData.land);

				}
			}
		}

		//if top of head hit the ceiling cancel jump
		if (!IsRolling && (state == MovementState.JUMPING || state == MovementState.RISING) && Vector3.Dot(hit.normal, forcesVelocity.normalized) < -ceilingCancelDot && hit.point.y - transform.position.y > playerController.CharacterController.height - playerController.CharacterController.radius) 
		{
			state = MovementState.FALLING;
			forcesVelocity.y = 0;
		}
		//check if collision is on bottom part of sphere and is under the controller slope limit (and therefore can be detected as onground)
		//if it is, the groundmagnet will be enabled, leading to better ground detection
		//this is disabled while jumping
		collisionGroundDetected = state != MovementState.JUMPING 
			&& angle < playerController.CharacterController.slopeLimit 
			&& hit.point.y - transform.position.y < playerController.CharacterController.radius;
	}

	#region Properties
	public MovementState State { get { return state; } }
	public Vector3 TotalVelocity { get { return forcesVelocity + inputVelocity; } }
	public Vector3 TargetVelocity { get { return targetVelocity; } set { targetVelocity = value; } }

	public Vector3 InputVelocity { get { return inputVelocity; } set { inputVelocity = value; } }
	public Vector3 ForcesVelocity { get { return forcesVelocity; } set { forcesVelocity = value; } }
	public Vector3 GroundNormal { get { return groundNormal; } }
	public Vector3 DashDirection { get { return currentDashDirection; } set { currentDashDirection = value; dashParticles.transform.forward = -currentDashDirection; } }
	public Quaternion TargetRotation { get { return targetRotation; } set { targetRotation = value; } }
	public bool IsRolling { get { return isRolling; } }
	public bool IsDashing { get { return dashing; } }
	public bool IsExternalDash { get; private set; }
	public float TargetSpeedManipulator { get; set; }
	#endregion

	private void OnDrawGizmosSelected()
	{
		if (Application.isPlaying && playerController.DrawDebug)
		{
			float radius = playerController.CharacterController.radius * groundDetectionRadiusModifier;

			float length = playerController.CharacterController.height / 2 + playerController.CharacterController.skinWidth;
			if (enableGroundMagnet)
				length *= (1+ groundMagnetDistanceModifier);

			Gizmos.color = Color.magenta;
			Gizmos.DrawWireSphere(transform.TransformPoint(playerController.CharacterController.center) 
				+ (length * (1 + groundDetectionAdditionalOffset) - radius) * -Vector3.up, radius);
		}
	}
}