using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Checkpoint : MonoBehaviour
{
	public LayerMask playerMask;
	public Transform spawnPositionRotation;
	public ParticleSystem onActivate;

	private void Awake()
	{
		GameManager.Instance.SaveManager.RegisterCheckpoint(this);
	}

	private void OnTriggerEnter(Collider other)
	{
		if (((1 << other.gameObject.layer) & playerMask) != 0)
		{
			if (GameManager.Instance.SaveManager.SetCurrentCheckpoint(this))
			{
				if (onActivate)
					onActivate.Play();
			}
		}
	}

	public Vector3 GetSpawnPosition()
	{
		if (spawnPositionRotation)
			return spawnPositionRotation.position;
		else 
			return transform.position;
	}

	public Quaternion GetSpawnRotation()
	{
		if (spawnPositionRotation)
			return Quaternion.LookRotation(Vector3.ProjectOnPlane(spawnPositionRotation.forward, Vector3.up).normalized, Vector3.up);
		else 
			return Quaternion.LookRotation(Vector3.ProjectOnPlane(transform.forward, Vector3.up).normalized, Vector3.up);
	}
}
