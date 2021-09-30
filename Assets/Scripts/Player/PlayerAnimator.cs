  using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(PlayerMotor))]
public class PlayerAnimator : MonoBehaviour
{
	PlayerMotor playerMotor;
	public Animator playerAnimator = null;
	public float speedChangeMultiplier = 1;
	public float verticalSpeedChangeMultiplier = 1;
	public float verticalMax = 20;
	public float verticalMin = 2;

	int speedId;
	int verticalSpeedId;
	int groundedId;
	int jumpId;

	//between 0 and 1
	float currentSpeed = 0;
	float currentVerticalSpeed = 0;

    void Start()
    {
		speedId = Animator.StringToHash("Forward Speed");
		verticalSpeedId = Animator.StringToHash("Vertical Speed");
		groundedId = Animator.StringToHash("Grounded");
		jumpId = Animator.StringToHash("Jump");

		playerMotor = GetComponent<PlayerMotor>();
	}

    void Update()
    {
		if (playerMotor.enabled)
		{
			float verticalSpeed = Vector3.Dot(playerMotor.TotalVelocity, Vector3.up);
			//Set forward speed
			float target = (playerMotor.TotalVelocity - verticalSpeed * Vector3.up).magnitude / playerMotor.maxSpeed;
			currentSpeed = Mathf.MoveTowards(currentSpeed, target, Time.deltaTime * speedChangeMultiplier * Mathf.Abs(target - currentSpeed));
			playerAnimator.SetFloat(speedId, currentSpeed);
			//set vertical speed
			target = Mathf.Clamp01(-(verticalSpeed + verticalMin)/verticalMax);
			currentVerticalSpeed = Mathf.MoveTowards(currentVerticalSpeed, target, Time.deltaTime * verticalSpeedChangeMultiplier * Mathf.Abs(target - currentVerticalSpeed));
			playerAnimator.SetFloat(verticalSpeedId, currentVerticalSpeed);
		}
    }

	public void AnimateEnterGround()
	{
		if (playerMotor.enabled)
		{
			playerAnimator.SetBool(groundedId, true);
		}
	}

	public void AnimateLeaveGround()
	{
		if (playerMotor.enabled)
		{
			playerAnimator.SetBool(groundedId, false);
			if (playerMotor.State == PlayerMotor.MovementState.JUMPING)
			{
				playerAnimator.SetTrigger(jumpId);
			}
		}
	}


}
