  using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//Used for any player 'animation', including any transition (e.g. rollcollidertransition)
public class PlayerAnimator : MonoBehaviour
{
	#region Inspector Fields
	public Animator animator = null;
	public MeshRenderer ball;
	public SkinnedMeshRenderer player;
	public float speedChangeMultiplier = 1;
	public float verticalSpeedChangeMultiplier = 1;
	public float verticalMaxMultiplier = 2.5f;
	//needs to be less then cooldown
	public float rollColliderTransitionTimeIn = 0.1f;
	public float rollColliderTransitionTimeOut = 0.3f;

	[Header("IK")]
	public bool enableFootIK = true;
	public bool enableLookIK = true;
	public float lookDistance = 20;
	[Range(0, 1)] public float turnPercent = 0.5f;
	[Range(0, 1)] public float lookBodyWeight = 0.2f;
	[Range(0, 1)] public float lookHeadWeight = 1;
	[Range(0, 0.3f)] public float distanceToGround = 0f;
	[Range(0, 0.5f)] public float extendDistance = 0f;
	[Range(0, 1)] public float footRotationWeight = 0.2f;
	[Range(0, 1)] public float footPositionWeight = 0.5f;
	public float footMoveSpeed = 10;
	public float footRotateSpeed = 10;
	public LayerMask ignoredGroundLayers;

	#endregion

	#region Other Fields
	PlayerController playerController;
	//Animator IDs
	int speedId;
	int verticalSpeedId;
	int groundedId;
	int jumpId;
	int rollId;
	int chargeId;
	int attackId;
	int equipId;
	
	//hold the smoothened values for current speed
	float currentSpeed = 0;
	float currentVerticalSpeed = 0;
	//Collider transition
	float rollColliderTransitionTime = 0;
	float rollColliderTransitionTimer = 0;
	bool switchingColliderSize = false;
	bool switchingIntoRoll;

	//IK transition
	Quaternion currentLeftRot;
	Quaternion currentRightRot;
	Vector3 currentLeftPos;
	Vector3 currentRightPos;
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
		chargeId = Animator.StringToHash("Charge");
		attackId = Animator.StringToHash("Attack");
		equipId = Animator.StringToHash("Equipped");

		playerController = GetComponentInParent<PlayerController>();
		if (playerController == null)
			playerController = FindObjectOfType<PlayerController>();

		playerController.Motor.onEnterGround.AddListener(AnimateEnterGround);
		playerController.Motor.onLeaveGround.AddListener(AnimateLeaveGround);
		playerController.Motor.onChangeRoll.AddListener(AnimateChangeRoll);

		currentLeftRot = transform.rotation;
		currentRightRot = transform.rotation;
	}

    void Update()
    {
		if (playerController.Motor)
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
						playerController.MainCamera.GetCameraData().targetOffset.y = playerController.RollCameraOffset;
						switchingColliderSize = false;
						ball.enabled = true;
						player.enabled = false;
					}
					else
					{
						float t = rollColliderTransitionTimer / rollColliderTransitionTime;
						playerController.CharacterController.radius = Mathf.Lerp(playerController.InitialColliderRadius, playerController.RollColliderRadius, t);
						playerController.CharacterController.height = Mathf.Lerp(playerController.InitialColliderHeight, playerController.RollColliderRadius * 2, t);
						playerController.CharacterController.center = Vector3.Lerp(playerController.InitialColliderOffset, playerController.RollColliderOffset, t);
						playerController.MainCamera.GetCameraData().targetOffset.y = Mathf.Lerp(playerController.MainCamera.defaultCameraData.targetOffset.y, playerController.RollCameraOffset, t);
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
						playerController.MainCamera.GetCameraData().targetOffset = playerController.MainCamera.defaultCameraData.targetOffset;
						switchingColliderSize = false;
					}
					else
					{
						float t = 1 - rollColliderTransitionTimer / rollColliderTransitionTime;
						playerController.CharacterController.radius = Mathf.Lerp(playerController.InitialColliderRadius, playerController.RollColliderRadius, t);
						playerController.CharacterController.height = Mathf.Lerp(playerController.InitialColliderHeight, playerController.RollColliderRadius*2, t);
						playerController.CharacterController.center = Vector3.Lerp(playerController.InitialColliderOffset, playerController.RollColliderOffset, t);
						playerController.MainCamera.GetCameraData().targetOffset.y = Mathf.Lerp(playerController.MainCamera.defaultCameraData.targetOffset.y, playerController.RollCameraOffset, t);
					}
				}
			}
		}
		if (playerController.Combat)
		{
			animator.SetFloat(chargeId, playerController.Combat.ChargePercentage);
		}
    }

	//Called for animator inverse kinematics
	private void OnAnimatorIK(int layerIndex)
	{
		if (!playerController.Motor.IsRolling)
		{
			if (enableLookIK)
			{
				//look toward camera
				animator.SetLookAtWeight(1, lookBodyWeight, lookHeadWeight, 0, turnPercent);
				Vector3 lookPosition = transform.position + Vector3.ProjectOnPlane(playerController.MainCamera.transform.forward, Vector3.up) * lookDistance;
				//if (playerController.Combat && playerController.Combat.ChargePercentage > 0)
				//{
				//	lookPosition = Vector3.Lerp(lookPosition, playerController.Combat.ArrowAimPoint, playerController.Combat.ChargePercentage);
				//}
				animator.SetLookAtPosition(lookPosition);
			}

			//now make feet move to position
			if (enableFootIK && playerController.Motor.State == PlayerMotor.MovementState.GROUNDED)
			{
				if (currentLeftPos == Vector3.zero)
				{
					currentLeftPos = animator.GetIKPosition(AvatarIKGoal.LeftFoot) - transform.position;
					currentRightPos = animator.GetIKPosition(AvatarIKGoal.RightFoot) - transform.position;
				}

				animator.SetIKPositionWeight(AvatarIKGoal.LeftFoot, footPositionWeight);
				animator.SetIKRotationWeight(AvatarIKGoal.LeftFoot, footRotationWeight);
				animator.SetIKPositionWeight(AvatarIKGoal.RightFoot, footPositionWeight);
				animator.SetIKRotationWeight(AvatarIKGoal.RightFoot, footRotationWeight);

				if (Physics.Raycast(animator.GetIKPosition(AvatarIKGoal.LeftFoot) + Vector3.up, Vector3.down, out var hit, distanceToGround + 1 + extendDistance, ~ignoredGroundLayers, QueryTriggerInteraction.Ignore))
				{
					//get position
					var targetPosition = hit.point + Vector3.up * distanceToGround - transform.position;
					currentLeftPos = Vector3.MoveTowards(currentLeftPos, targetPosition, Time.deltaTime * footMoveSpeed);
					
					//Get rotation
					Vector3 forwardFlat = transform.forward;
					forwardFlat.y = 0;
					forwardFlat.Normalize();
					Vector3 forwardDirection = (forwardFlat + Vector3.up * -(hit.normal.x * forwardFlat.x + hit.normal.z * forwardFlat.z) / hit.normal.y).normalized;
					Quaternion targetRotation = Quaternion.LookRotation(forwardDirection, hit.normal);
					currentLeftRot = Quaternion.RotateTowards(currentLeftRot, targetRotation, Time.deltaTime * footRotateSpeed);
				}
				else
				{
					currentLeftPos = Vector3.MoveTowards(currentLeftPos, animator.GetIKPosition(AvatarIKGoal.LeftFoot) - transform.position, Time.deltaTime * footMoveSpeed);
					currentLeftRot = Quaternion.RotateTowards(currentLeftRot, animator.GetIKRotation(AvatarIKGoal.LeftFoot), Time.deltaTime * footRotateSpeed);
				}
				animator.SetIKPosition(AvatarIKGoal.LeftFoot, currentLeftPos + transform.position);
				animator.SetIKRotation(AvatarIKGoal.LeftFoot, currentLeftRot);

				if (Physics.Raycast(animator.GetIKPosition(AvatarIKGoal.RightFoot) + Vector3.up, Vector3.down, out hit, distanceToGround + 1 + extendDistance, ~ignoredGroundLayers, QueryTriggerInteraction.Ignore))
				{
					//get position
					var targetPosition = hit.point + Vector3.up * distanceToGround - transform.position;
					currentRightPos = Vector3.MoveTowards(currentRightPos, targetPosition, Time.deltaTime * footMoveSpeed);

					//Get rotation
					Vector3 forwardFlat = transform.forward;
					forwardFlat.y = 0;
					forwardFlat.Normalize();
					Vector3 forwardDirection = (forwardFlat + Vector3.up * -(hit.normal.x * forwardFlat.x + hit.normal.z * forwardFlat.z) / hit.normal.y).normalized;
					Quaternion targetRotation = Quaternion.LookRotation(forwardDirection, hit.normal);
					currentRightRot = Quaternion.RotateTowards(currentRightRot, targetRotation, Time.deltaTime * footRotateSpeed);
				}
				else
				{
					currentRightPos = Vector3.MoveTowards(currentRightPos, animator.GetIKPosition(AvatarIKGoal.RightFoot) - transform.position, Time.deltaTime * footMoveSpeed);
					currentRightRot = Quaternion.RotateTowards(currentRightRot, animator.GetIKRotation(AvatarIKGoal.RightFoot), Time.deltaTime * footRotateSpeed);
				}
				animator.SetIKPosition(AvatarIKGoal.RightFoot, currentRightPos + transform.position);
				animator.SetIKRotation(AvatarIKGoal.RightFoot, currentRightRot);
			}
			
			//animator.SetIKPosition(AvatarIKGoal.LeftFoot, )
		}
	}

	#region Listeners
	public void AnimateEnterGround()
	{
		if (playerController.Motor.enabled)
		{
			animator.SetBool(groundedId, true);
			currentLeftRot = transform.rotation;
			currentRightRot = transform.rotation;
			currentLeftPos = Vector3.zero;
			currentRightPos = Vector3.zero;
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
		if (switchingIntoRoll)
			rollColliderTransitionTime = rollColliderTransitionTimeIn;
		else
		{
			rollColliderTransitionTime = rollColliderTransitionTimeOut;
			ball.enabled = false;
			player.enabled = true;
		}
	}
 
	public void AnimateAttack()
	{
		animator.SetTrigger(attackId);
	}

	public void AnimateEquip(bool equip)
	{
		animator.SetBool(equipId, equip);
	}

	public void AnimateDeath(bool isDead)
	{
		animator.SetBool("Dead", isDead);
	}

	public void ResetPlayerAnimation()
	{
		animator.Play("IdleWalkRun", -1, 0);
		playerController.CharacterController.radius = playerController.RollColliderRadius;
		playerController.CharacterController.height = playerController.RollColliderRadius * 2;
		playerController.CharacterController.center = playerController.RollColliderOffset;
		playerController.MainCamera.GetCameraData().targetOffset.y =  playerController.RollCameraOffset;
	}
	#endregion
}
