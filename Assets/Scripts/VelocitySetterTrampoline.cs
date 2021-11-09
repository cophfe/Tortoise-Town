using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(AudioSource))]
public class VelocitySetterTrampoline : PlayerCollision
{
	[Tooltip("The percentage of velocity that will be added in the opposite direction of the trampoline direction")]
	[SerializeField, Min(0)] float velocityMagnitude = 15;
	[Tooltip("Whether the trampoline direction is defined as the gameobjects up direction or as the collision normal")]
	[SerializeField] bool useTransformUp = true;
	[Tooltip("The minimum velocity into the trampoline before it bounces")]
	[SerializeField, Min(0)] float minBounceVelocity = 1;
	[SerializeField] AudioClipList launchSounds = null;
	AudioSource source;

	private void Start()
	{
		source = GetComponent<AudioSource>();
	}
	public override bool OnCollideWithPlayer(PlayerController player, ControllerColliderHit hit)
	{
		Vector3 trampolineUp = useTransformUp ? transform.up : hit.normal;
		
		if (Vector3.Dot(player.Motor.TotalVelocity, trampolineUp) < -minBounceVelocity)
		{
			player.Motor.ForcesVelocity = velocityMagnitude * trampolineUp;
			player.Motor.InputVelocity = Vector3.zero;
			if (launchSounds.CanBePlayed())
			{
				source.clip = launchSounds.GetRandom();
				source.Play();
			}
			player.Motor.RefreshDash();
		}
		
		//dont implement collision just cuz
		return false;
	}

	public override bool OnPlayerGrounded(PlayerController player)
	{
		Vector3 trampolineUp = transform.up;
		float tDot = Vector3.Dot(player.Motor.TotalVelocity, trampolineUp);
		if (tDot < -minBounceVelocity)
		{
			player.Motor.ForcesVelocity = velocityMagnitude * trampolineUp;
			player.Motor.InputVelocity = Vector3.zero;
			if (launchSounds.CanBePlayed())
			{
				source.clip = launchSounds.GetRandom();
				source.Play();
			}
			player.Motor.RefreshDash();
		}

		return false;
	}
}
