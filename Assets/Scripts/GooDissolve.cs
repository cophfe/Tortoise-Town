using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GooDissolve : MonoBehaviour
{
	[SerializeField] Shader dissolveShader = null;
	[SerializeField] Shader vineShader = null;
	[SerializeField] float dissolveSpeed = 10;
	[SerializeField] float startCutoffHeight = 0;
	[SerializeField] float endCutoffHeight = 100;
	[SerializeField] bool easeIn = true;
	List<MeshRenderer> renderersToDissolve = new List<MeshRenderer>();
	List<MeshRenderer> renderersToDissappear = new List<MeshRenderer>();

	HealthTarget[] targets = null;
	int cutOffHeightId = 0;
	float currentCutOffHeight = 0;
	bool dissolving = false;
	MaterialPropertyBlock block = null;

	public bool startDissolving = false;
	int aliveTargetCount;

	private void Start()
	{
		cutOffHeightId = Shader.PropertyToID("_CutoffHeight");
		currentCutOffHeight = startCutoffHeight;

		//Get targets
		targets = GetComponentsInChildren<HealthTarget>();
		aliveTargetCount = targets.Length;
		for (int i = 0; i < targets.Length; i++)
		{
			targets[i].deathlegate += OnTargetKilled;
		}
		//Get renderers
		MeshRenderer[] renderers = GetComponentsInChildren<MeshRenderer>();
		//add to lists
		for (int i = 0; i < renderers.Length; i++)
		{
			if (renderers[i].sharedMaterial.shader == dissolveShader)
				renderersToDissolve.Add(renderers[i]);
			else if (renderers[i].sharedMaterial.shader == vineShader)
				renderersToDissappear.Add(renderers[i]);
		}

		//make the property block
		block = new MaterialPropertyBlock();
		SetCutoffHeight(currentCutOffHeight);
	}

	private void OnTargetKilled()
	{
		aliveTargetCount--;
		if (aliveTargetCount == 0)
		{
			StartDissolving();
		}
	}

	void StartDissolving()
	{
		currentCutOffHeight = startCutoffHeight;
		dissolving = true;
	}

	private void Update()
	{
		if (dissolving)
		{
			if (easeIn)
			{
				float t = (currentCutOffHeight - startCutoffHeight) / (endCutoffHeight);
				currentCutOffHeight += Time.deltaTime * dissolveSpeed * (2 * t * t + .25f);
			}
			else
			{
				currentCutOffHeight += Time.deltaTime * dissolveSpeed;
			}
			if (currentCutOffHeight >= endCutoffHeight)
			{
				currentCutOffHeight = endCutoffHeight;
				SetCutoffHeight(currentCutOffHeight);
				enabled = false;
			}
			else SetCutoffHeight(currentCutOffHeight);
		}
	}

	void SetCutoffHeight(float height)
	{
		block.SetFloat(cutOffHeightId, height);

		for (int i = 0; i < renderersToDissolve.Count; i++)
		{
			renderersToDissolve[i].SetPropertyBlock(block);
		}
		for (int i = 0; i < renderersToDissappear.Count; i++)
		{
			renderersToDissappear[i].SetPropertyBlock(block);
		}
	}

	private void OnDestroy()
	{
		//if (block != null)
		//block.SetFloat(cutOffHeightId, endCutoffHeight);
	}

	private void OnDrawGizmosSelected()
	{
		Vector3 pos = transform.position;
		Vector3 scale = new Vector3(2, 0.02f, 2);
		Gizmos.color = Color.blue;
		Gizmos.DrawCube(new Vector3(pos.x, startCutoffHeight, pos.z), scale);
		Gizmos.color = Color.magenta;
		Gizmos.DrawCube(new Vector3(pos.x, endCutoffHeight, pos.z), scale);
		Gizmos.color = Color.red;
		Gizmos.DrawWireCube(new Vector3(pos.x, (startCutoffHeight + endCutoffHeight)/2, pos.z), new Vector3(scale.x, endCutoffHeight - startCutoffHeight, scale.z));
		if (Application.isPlaying)
			Gizmos.DrawCube(new Vector3(pos.x, currentCutOffHeight, pos.z), scale);

	}
}
