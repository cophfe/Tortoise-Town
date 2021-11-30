using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Checkpoint : MonoBehaviour
{
	public LayerMask playerMask;
	public Transform spawnPositionRotation;
	public ParticleSystem onActivate;
	public ParticleSystem passive;
	AudioSource saveSoundSource;
	public Material Mat { get; private set; }
	private void Awake()
	{
		Mat = GetComponentInChildren<MeshRenderer>()?.material;
		GameManager.Instance.SaveManager.RegisterCheckpoint(this);
		saveSoundSource = GetComponent<AudioSource>();
	}

	private void OnTriggerEnter(Collider other)
	{
		if (((1 << other.gameObject.layer) & playerMask) != 0)
		{
			if (GameManager.Instance.SaveManager.SetCurrentCheckpoint(this))
			{
				if (onActivate != null)
					onActivate.Play();
				if (saveSoundSource != null)
					saveSoundSource.Play();
				if (passive != null)
					passive.Play();
				if (Mat != null)
					StartCoroutine(LightEyes());
			}
			
		}
	}

	public void SetAsCurrent()
	{
		if (GameManager.Instance.SaveManager.SetCurrentCheckpoint(this))
		{
			if (onActivate != null)
				onActivate.Play();
			if (saveSoundSource != null)
				saveSoundSource.Play();
			if (passive != null)
				passive.Play();
			if (Mat != null)
				StartCoroutine(LightEyes());
		}
	}

	IEnumerator LightEyes()
	{
		yield return new WaitForSecondsRealtime(0.2f);
		Mat.EnableKeyword("_EMISSION");
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
