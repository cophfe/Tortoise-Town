using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GooDissolve : MonoBehaviour
{
	[SerializeField] GooDissolveData data = null;
	[SerializeField] float dissolveSpeed = 10;
	[SerializeField] float minimumCutOffHeight = 0;
	[SerializeField] float maximumCutOffHeight = 100;
	public bool requiredForWin = true;
	List<Renderer> renderersToDissolve = new List<Renderer>();

	HealthTarget[] targets = null;
	GooDamager[] damagers = null;
	GooActivator[] activators = null;
	int cutOffHeightId = 0;
	float currentCutOffHeight = 0;
	bool dissolving = false;
	MaterialPropertyBlock block = null;
	public bool Dissolved { get; private set; }
	int aliveTargetCount;

	protected virtual void Awake()
	{
		GameManager.Instance.RegisterGooDissolver(this);
		cutOffHeightId = Shader.PropertyToID("_CutoffHeight");
		currentCutOffHeight = maximumCutOffHeight;

		//Get targets
		targets = GetComponentsInChildren<HealthTarget>();

		aliveTargetCount = targets.Length;
		for (int i = 0; i < targets.Length; i++)
		{
			targets[i].deathlegate += OnTargetKilled;
		}
		//Get renderers
		Renderer[] renderers = GetComponentsInChildren<Renderer>();
		//add to lists
		for (int i = 0; i < renderers.Length; i++)
		{
			for (int j = 0; j < data.dissolveShader.Length; j++)
			{
				if (renderers[i].sharedMaterial != null && renderers[i].sharedMaterial.shader == data.dissolveShader[j])
					renderersToDissolve.Add(renderers[i]);
			}
		}
		damagers = GetComponentsInChildren<GooDamager>();
		activators = GetComponentsInChildren<GooActivator>();

		//make the property block
		block = new MaterialPropertyBlock();
		SetCutoffHeight(currentCutOffHeight);

		if (targets.Length > 0)
			GameManager.Instance.SaveManager.onResetScene += OnResetScene;
	}

	private void Start()
	{
	}

	private void OnTargetKilled()
	{
		aliveTargetCount--;
		if (aliveTargetCount == 0)
		{
			StartDissolving();
		}
	}

	protected virtual void StartDissolving()
	{
		currentCutOffHeight = maximumCutOffHeight;
		dissolving = true;
		for (int i = 0; i < damagers.Length; i++)
		{
			damagers[i].Dissolve();
		}
		for (int i = 0; i < activators.Length; i++)
		{
			activators[i].Dissolve();
		}
		Dissolved = true;
		if (requiredForWin)
			GameManager.Instance.OnGooDissolve();
	}

	public void OnResetScene()
	{
		aliveTargetCount = 0;
		for (int i = 0; i < targets.Length; i++)
		{
			if (!targets[i].IsDead)
			{
				aliveTargetCount++;
			}
		}
		if (aliveTargetCount == 0)
		{
			SetAlreadyDissolved();
		}
		else
		{
			ResetDissolve();
		}
	}

	public void SetAlreadyDissolved()
	{
		for (int i = 0; i < damagers.Length; i++)
		{
			damagers[i].Dissolve();
		}
		for (int i = 0; i < activators.Length; i++)
		{
			activators[i].Dissolve();
		}
		Dissolved = true;
		currentCutOffHeight = minimumCutOffHeight;
		SetCutoffHeight(currentCutOffHeight);
		enabled = false;
		dissolving = false;

	}

	public void ResetDissolve()
	{
		for (int i = 0; i < damagers.Length; i++)
		{
			damagers[i].Undissolve();
		}
		for (int i = 0; i < activators.Length; i++)
		{
			activators[i].Undissolve();
		}
		Dissolved = false;
		currentCutOffHeight = maximumCutOffHeight;
		SetCutoffHeight(currentCutOffHeight);
		enabled = true;
		dissolving = false;

	}

	private void Update()
	{
		if (dissolving)
		{
			if (data.easeIn)
			{
				float t = (currentCutOffHeight - minimumCutOffHeight) / (maximumCutOffHeight);
				currentCutOffHeight -= Time.deltaTime * dissolveSpeed * (2 * t * t + .25f);
			}
			else
			{
				currentCutOffHeight -= Time.deltaTime * dissolveSpeed;
			}

			if (currentCutOffHeight <= minimumCutOffHeight)
			{
				currentCutOffHeight = minimumCutOffHeight;
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
	}

	public void ForceDissolve()
	{
		for (int i = 0; i < damagers.Length; i++)
		{
			damagers[i].Undissolve();
		}
		for (int i = 0; i < activators.Length; i++)
		{
			activators[i].Undissolve();
		}
		enabled = true;

		currentCutOffHeight = maximumCutOffHeight;
		dissolving = true;
		for (int i = 0; i < damagers.Length; i++)
		{
			damagers[i].Dissolve();
		}
		for (int i = 0; i < activators.Length; i++)
		{
			activators[i].Dissolve();
		}
		Dissolved = true;
		if (requiredForWin)
			GameManager.Instance.OnGooDissolve();
	}

	private void OnDrawGizmosSelected()
	{
		Vector3 pos = transform.position;
		Vector3 scale = new Vector3(2, 0.02f, 2);
		Gizmos.color = Color.blue;
		Gizmos.DrawCube(new Vector3(pos.x, minimumCutOffHeight, pos.z), scale);
		Gizmos.color = Color.magenta;
		Gizmos.DrawCube(new Vector3(pos.x, maximumCutOffHeight, pos.z), scale);
		Gizmos.color = Color.red;
		Gizmos.DrawWireCube(new Vector3(pos.x, (minimumCutOffHeight + maximumCutOffHeight)/2, pos.z), new Vector3(scale.x, maximumCutOffHeight - minimumCutOffHeight, scale.z));
		if (Application.isPlaying)
			Gizmos.DrawCube(new Vector3(pos.x, currentCutOffHeight, pos.z), scale);

	}
}
