  using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//Used for any player 'animation', including any transition (e.g. rollcollidertransition)
public class PlayerAnimator : MonoBehaviour
{
	#region Inspector Fields
	public Animator animator = null;
	public float speedChangeMultiplier = 1;
	public float verticalSpeedChangeMultiplier = 1;
	public float verticalMaxMultiplier = 2.5f;
	//needs to be less then cooldown
	public float rollColliderTransitionTimeIn = 0.1f;
	public float rollColliderTransitionTimeOut = 0.3f;

	public float lookDistance = 20;
	public Transform headBone = null;
	public Transform upperChestBone = null;
	#endregion

	#region Other Fields
	PlayerController playerController;
	//Animator IDs
	int speedId;
	int verticalSpeedId;
	int groundedId;
	int jumpId;
	int rollId;
	
	//hold the smoothened values for current speed
	float currentSpeed = 0;
	float currentVerticalSpeed = 0;
	//Collider transition
	float rollColliderTransitionTime = 0;
	float rollColliderTransitionTimer = 0;
	bool switchingColliderSize = false;
	bool switchingIntoRoll;
	#endregion

    void Start()
    {
		if (animator == null)
			animator = GetComponentInChildren<Animator>();

		speedId = Animator.StringToHash("Forward Speed");
		verticalSpeedId = Animator.StringToHash("Vertical Speed");
		groundedId = Animator.StringToHash("Grounded");
		jumpId = Animator.StringToHash("Jump");
		rollId = Animator.StringToHash("Rolling");

		playerController = GetComponentInParent<PlayerController>();
		playerController.Motor.onEnterGround.AddListener(AnimateEnterGround);
		playerController.Motor.onLeaveGround.AddListener(AnimateLeaveGround);
		playerController.Motor.onChangeRoll.AddListener(AnimateChangeRoll);
	}

    void Update()
    {
		if (playerController.Motor.enabled)
		{
			//Update animator values
			float verticalSpeed = Vector3.Dot(playerController.Motor.TotalVelocity, Vector3.up);
			//Set forward speed
			float target = (Mathf.Max(playerController.Motor.minCollisionVelocity, Vector3.ProjectOnPlane(playerController.Motor.TotalVelocity, playerController.Motor.GroundNormal).magnitude)- playerController.Motor.minCollisionVelocity) / playerController.Motor.targetSpeed;
			currentSpeed = Mathf.MoveTowards(currentSpeed, target, Time.deltaTime * speedChangeMultiplier * Mathf.Abs(target - currentSpeed));
			animator.SetFloat(speedId, currentSpeed);
			//set vertical speed
			target = Mathf.Clamp01(verticalSpeed/(playerController.Motor.jumpSpeed * verticalMaxMultiplier) + 0.5f);
			currentVerticalSpeed = Mathf.MoveTowards(currentVerticalSpeed, target, Time.deltaTime * verticalSpeedChangeMultiplier * Mathf.Abs(target - currentVerticalSpeed));
			animator.SetFloat(verticalSpeedId, currentVerticalSpeed);
			
			//change collider when transitioning to roll so that it is a sphere
			if (switchingColliderSize)
			{
				rollColliderTransitionTimer += Time.deltaTime;
				//IF CHANGING TO ROLL
				if (switchingIntoRoll)
				{
					if (rollColliderTransitionTimer >= rollColliderTransitionTime)
					{
						playerController.CharacterController.radius = playerController.RollColliderRadius;
						playerController.CharacterController.height = playerController.RollColliderRadius * 2;
						playerController.CharacterController.center = playerController.RollColliderOffset;
						playerController.MainCamera.targetOffset = playerController.RollCameraOffset;
						switchingColliderSize = false;
					}
					else
					{
						float t = rollColliderTransitionTimer / rollColliderTransitionTime;
						playerController.CharacterController.radius = Mathf.Lerp(playerController.InitialColliderRadius, playerController.RollColliderRadius, t);
						playerController.CharacterController.height = Mathf.Lerp(playerController.InitialColliderHeight, playerController.RollColliderRadius * 2, t);
						playerController.CharacterController.center = Vector3.Lerp(playerController.InitialColliderOffset, playerController.RollColliderOffset, t);
						playerController.MainCamera.targetOffset = Vector3.Lerp(playerController.InitialCameraOffset, playerController.RollCameraOffset, t);
					}
				}
				//IF CHANGING OUT OF ROLL
				else
				{
					if (rollColliderTransitionTimer >= rollColliderTransitionTime)
					{
						playerController.CharacterController.radius = playerController.InitialColliderRadius;
						playerController.CharacterController.height = playerController.InitialColliderHeight;
						playerController.CharacterController.center = playerController.InitialColliderOffset;
						playerController.MainCamera.targetOffset = playerController.InitialCameraOffset;
						switchingColliderSize = false;
					}
					else
					{
						float t = 1 - rollColliderTransitionTimer / rollColliderTransitionTime;
						playerController.CharacterController.radius = Mathf.Lerp(playerController.InitialColliderRadius, playerController.RollColliderRadius, t);
						playerController.CharacterController.height = Mathf.Lerp(playerController.InitialColliderHeight, playerController.RollColliderRadius*2, t);
						playerController.CharacterController.center = Vector3.Lerp(playerController.InitialColliderOffset, playerController.RollColliderOffset, t);
						playerController.MainCamera.targetOffset = Vector3.Lerp(playerController.InitialCameraOffset, playerController.RollCameraOffset, t);
					}
				}
			}
		}
    }

	//Called for animator inverse kinematics
	private void OnAnimatorIK(int layerIndex)
	{
		if (playerController.Motor.IsRolling)
		{
			animator.SetLookAtWeight(0);
		}
		else
		{
			animator.SetLookAtWeight(1, .2f, 1, 0, .5f);
			animator.SetLookAtPosition(transform.position + Vector3.ProjectOnPlane(playerController.MainCamera.transform.forward, Vector3.up) * lookDistance);
		}
	}

	#region Listeners
	public void AnimateEnterGround()
	{
		if (playerController.Motor.enabled)
		{
			animator.SetBool(groundedId, true);
		}
	}

	public void AnimateLeaveGround()
	{
		if (playerController.Motor.enabled)
		{
			animator.SetBool(groundedId, false);
			if (playerController.Motor.State == PlayerMotor.MovementState.JUMPING)
			{
				animator.SetTrigger(jumpId);
			}
		}
	}

	public void AnimateChangeRoll()
	{
		animator.SetBool(rollId, playerController.Motor.IsRolling);
		rollColliderTransitionTimer = 0;
		switchingIntoRoll = playerController.Motor.IsRolling;
		switchingColliderSize = true;
		rollColliderTransitionTime = switchingIntoRoll ? rollColliderTransitionTimeIn : rollColliderTransitionTimeOut;
	}
	#endregion
}
