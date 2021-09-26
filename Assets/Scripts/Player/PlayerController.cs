using System.Collections;
using System.Collections.Generic;
using System.Threading.Tasks;
using UnityEngine;
using UnityEngine.InputSystem;

public class PlayerController : MonoBehaviour
{
	//REFERENCES
	public Transform cameraTransform;
	PlayerMotor motor;

	//MOVEMENT
	[SerializeField] Vector3 totalVelocity;
	[SerializeField] Vector3 inputVelocity;
	[SerializeField] Vector3 gravityVelocity;
	
	public float gravity = 10;
	public Vector3 upDirection = Vector3.up;
	[Range(0, 90)] public float maxSlopeAngle = 45;
	public float targetSpeed = 10;
	public float acceleration = 10;
	[Range(0,1)] public float airControlModifier = 0.5f;
	[Range(0,1)] public float slideControlModifier = 0.5f;
	float currentAcceleration;
	
	//JUMPING
	public float jumpSpeed = 10f;
	public float jumpDuration = 0.5f;
	
	public float jumpBufferTime = 0.1f;
	[SerializeField] float jumpBufferTimer = 0;

	public float coyoteTime = 0.1f;
	[SerializeField]  float coyoteTimer = 0;

	public int airJumps = 0;
	[SerializeField]  int airJumpsLeft = 0;

	//OTHER
	public float slopeLimit;

	//INPUT
	bool pressedJump;
	bool cancelledJump;
	Vector2 inputVector;

	[SerializeField] MovementState state = MovementState.FALLING;
	enum MovementState
	{
		GROUNDED,
		FALLING,
		SLIDING,
		JUMPING
	}

	private void Awake()
	{
		motor = GetComponent<PlayerMotor>();
	}

	private void FixedUpdate()
	{
		if (ScanForGround())
		{
			if (Vector3.Angle(motor.GroundNormal, upDirection) > maxSlopeAngle)
			{
				gravityVelocity -= upDirection * gravity * Time.deltaTime;
				gravityVelocity = Vector3.ProjectOnPlane(gravityVelocity, motor.GroundNormal);

				//if newly sliding
				if (state != MovementState.SLIDING)
				{
					StartSlide();
				}

			}
			else
			{
				float upGravity = Vector3.Dot(gravityVelocity, upDirection);
				if (upGravity < 0)
				{
					gravityVelocity = Vector3.zero;
				}

				//if newly grounded
				if (state != MovementState.GROUNDED)
				{
					Land();
				}
			}
		}
		else
		{
			//apply gravity if not grounded. if grounded, motor will keep player on the ground.
			gravityVelocity -= upDirection * gravity * Time.deltaTime;

			//if just left ground
			if (state == MovementState.GROUNDED)
			{
				StartFall();
			}
		}

		CheckJump();

		//get target velocity
		Vector3 targetVelocity = GetVelocityFromInput();
		//set acceleration
		currentAcceleration = acceleration;
		if (state == MovementState.JUMPING || state == MovementState.FALLING)
		{
			currentAcceleration = airControlModifier * acceleration;
		}
		else if (state == MovementState.SLIDING)
		{
			currentAcceleration = slideControlModifier * acceleration;
		}
		else if (Vector3.Dot(targetVelocity, inputVelocity) < 0)
		{
			//if opposing, accelerate faster
			currentAcceleration = 3 * acceleration;
		}
		//set velocity and cache values
		Vector3 currentVelocity = Vector3.MoveTowards(inputVelocity, targetVelocity, currentAcceleration * Time.fixedDeltaTime);

		//if sliding, remove velocity going into the slide plane
		if (state == MovementState.SLIDING)
		{
			//remove input velocity that is going into plane
			Vector3 groundUpDirection = Vector3.ProjectOnPlane(motor.GroundNormal, upDirection).normalized;
			float upVelocityOnGround = Vector3.Dot(currentVelocity, groundUpDirection);
			Debug.DrawRay(motor.GroundPosition, groundUpDirection, Color.magenta, Time.fixedDeltaTime);
			Debug.Log("upVelocityOnGround is " + upVelocityOnGround);
			//completely remove velocity going up the slope
			if (upVelocityOnGround < 0)
			{
				currentVelocity -= upVelocityOnGround * groundUpDirection;
			}
			//only half remove velocity going down the slope
			else
			{
				currentVelocity -= (upVelocityOnGround /2)* groundUpDirection;
			}
		}
		inputVelocity = currentVelocity;
		currentVelocity += gravityVelocity;
		totalVelocity = currentVelocity;

		motor.RigidbodyVelocity = currentVelocity;
		motor.extendGroundDetection = (state == MovementState.GROUNDED || state == MovementState.SLIDING) && Vector3.Dot(gravityVelocity, upDirection) <= 0;
	}

	private void Update()
	{
		//iterate timers
		coyoteTimer -= Time.deltaTime;
		jumpBufferTimer -= Time.deltaTime;
	}

	private void LateUpdate()
	{
		if (motor.DetectedGround())
		{
			Debug.DrawRay(motor.GroundPosition, motor.GroundNormal, Color.blue, Time.deltaTime);
		}
	}

	Vector3 GetVelocityFromInput()
	{
		Vector3 movementVector = Vector3.ProjectOnPlane(cameraTransform.right, upDirection).normalized * inputVector.x
			+ Vector3.ProjectOnPlane(cameraTransform.forward, upDirection).normalized * inputVector.y;
		movementVector = Vector3.ClampMagnitude(movementVector, 1) * targetSpeed;

		return movementVector;
	}

	void CheckJump()
	{
		if (pressedJump)
		{
			pressedJump = false;

			if (state == MovementState.GROUNDED)
			{
				StartJump();
			}
			else
			{
				if (airJumpsLeft > 0)
				{
					airJumpsLeft--;
					StartJump();
				}
				else if (coyoteTimer > 0)
				{
					coyoteTimer = 0; 
					StartJump();
				}
				else
				{
					jumpBufferTimer = jumpBufferTime;
				}
			}
		}
		
	}

	bool ScanForGround()
	{
		//bool scanned = Physics.SphereCast(transform.position + controller.center, controller.radius * groundRadiusPercent, Vector3.down, out hit, groundDistance, groundLayers);
		motor.ScanForGround();
		return motor.DetectedGround();
	}

	void Land()
	{
		state = MovementState.GROUNDED;
		airJumpsLeft = airJumps;

		if (jumpBufferTimer > 0)
		{
			jumpBufferTimer = 0;
			StartJump();
		}
	}

	void StartJump()
	{
		state = MovementState.JUMPING;
		gravityVelocity += upDirection * jumpSpeed;
	}

	void StartFall()
	{
		state = MovementState.FALLING;
		coyoteTimer = coyoteTime;
	}

	void StartSlide()
	{
		state = MovementState.SLIDING;
	}

	#region Input

	public void OnMoveInput(InputAction.CallbackContext obj)
	{
		inputVector = obj.ReadValue<Vector2>();
	}

	public void OnJumpInput(InputAction.CallbackContext obj)
	{
		switch (obj.phase)
		{
			case InputActionPhase.Started:
				pressedJump = true;
				cancelledJump = false;
				break;
			case InputActionPhase.Canceled:
				if (pressedJump)
				{
					cancelledJump = true;
				}
				break;
		}
	}

	public void OnSprintInput(InputAction.CallbackContext obj)
	{

	}

	public void OnCrouchInput(InputAction.CallbackContext obj)
	{

	}
	#endregion
}