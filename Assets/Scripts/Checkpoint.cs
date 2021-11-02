using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Checkpoint : MonoBehaviour
{
	public LayerMask playerMask;

	private void Awake()
	{
		GameManager.Instance.SaveManager.RegisterCheckpoint(this);
	}

	private void OnTriggerEnter(Collider other)
	{
		if (((1 << other.gameObject.layer) & playerMask) != 0)
		{
			GameManager.Instance.SaveManager.SetCurrentCheckpoint(this);
		}
	}

	public Vector3 GetSpawnPosition()
	{
		return transform.position;
	}

	public Quaternion GetSpawnRotation()
	{
		return Quaternion.identity;
	}
}
