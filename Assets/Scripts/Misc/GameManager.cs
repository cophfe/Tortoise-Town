using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

[DefaultExecutionOrder(-1)]
public class GameManager : MonoBehaviour
{
	static GameManager instance;
	public static GameManager Instance { get { return instance; } set { instance = value; } }

	[Header("General Stuff")]
	[SerializeField] float deathTime = 6;
	[SerializeField] float winWaitTime = 3;
	[SerializeField] string menuSceneName = "Main_Menu";

	[Header("References")]
	[SerializeField] PlayerController player = null;

	[Header("Debug Settings")]
	[SerializeField] bool enableCursorRestriction = false;
	[SerializeField] int targetFrameRate = -1;

	[Header("Arrow Pool")]
	[Tooltip("The poolable component attached to the arrow prefab")]
	[SerializeField] Poolable arrowPrefab = null;
	[Tooltip("The amount of arrows in the pool")]
	[SerializeField] int arrowPoolAmount = 20;
	[Tooltip("Used to give arrows time to fade away")]
	[SerializeField] int arrowPoolNotifyDistance = 4;
	public ObjectPool ArrowPool { get; private set; }
	public PlayerController Player { get { return player; } }
	public SaveManager SaveManager { get; private set; } = new SaveManager();
	public bool WonGame { get; private set; } = false;

	Vector3 initialPlayerPosition;
	Quaternion initialPlayerRotation;
	int currentDissolverCount;
	int totalDissolverCount;

	void Awake()
    {
		if (instance)
		{
			Debug.LogWarning("There should only ever be one instance of the GameManager in each scene.");
			Destroy(this);
		}
		else
		{
			instance = this;
			IsCursorRestricted = true;
			ArrowPool = new ObjectPool(arrowPoolAmount, arrowPoolNotifyDistance, arrowPrefab, transform);
			Application.targetFrameRate = targetFrameRate;
			if (!player) player = FindObjectOfType<PlayerController>();

			initialPlayerPosition = player.transform.position;
			initialPlayerRotation = player.transform.rotation;
		}
	}

	private void Start()
	{
		SaveManager.Start();
		var checkpoint = SaveManager.GetCurrentCheckpoint();
		if (checkpoint != null)
		{
			player.transform.position = checkpoint.GetSpawnPosition();
			player.RotateChild.localRotation = checkpoint.GetSpawnRotation();
		}
		else
		{
			player.transform.position = initialPlayerPosition;
			player.RotateChild.localRotation = initialPlayerRotation;
		}
		CalculateTotalDissolvers();
		currentDissolverCount = totalDissolverCount;
	}

	public void OnPlayerDeath()
	{
		player.InputIsEnabled = false;
		player.Animator.AnimateDeath(true);
		if (player.Motor.IsRolling)
		{
			player.Motor.CancelRoll();
		}
		StartCoroutine(ResetScene());
	}

	IEnumerator ResetScene()
	{
		yield return new WaitForSeconds(deathTime);
		player.GUI.Fade(true);
		yield return new WaitForSeconds(player.GUI.fadeTime);
		SetSceneFromSavedData();
	}

	public void ReloadScene()
	{
		SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex);
	}

	public IEnumerator ResetSceneFromMenu()
	{
		player.GUI.Fade(true);
		yield return new WaitForSeconds(player.GUI.fadeTime);
		
	}

	public void SetSceneFromSavedData()
	{
		SaveManager.SetSceneFromSaveData();
		var checkpoint = SaveManager.GetCurrentCheckpoint();
		if (checkpoint != null)
		{
			player.transform.position = checkpoint.GetSpawnPosition();
			player.RotateChild.localRotation = checkpoint.GetSpawnRotation();
		}
		else
		{
			player.transform.position = initialPlayerPosition;
			player.RotateChild.localRotation = initialPlayerRotation;
		}
		player.ResetPlayerToDefault();
		player.MainCamera.ResetCameraData();
		player.MainCamera.MoveToTarget();
		ArrowPool.ResetToDefault();
		player.GUI.Fade(false);
	}

	public void ExitToMenu()
	{
		try
		{
			SceneManager.LoadScene(menuSceneName);
		}
		catch (Exception e)
		{
			Debug.LogWarning("Error loading scene:\n"+ e.Message);
		}
	}

	public void CalculateTotalDissolvers()
	{
		totalDissolverCount = 0;
		foreach (var dissolver in SaveManager.GetGooDissolverList())
		{
			if (dissolver.requiredForWin) totalDissolverCount++;
		}
	}
	public void CalculateCurrentDissolverCount()
	{
		currentDissolverCount = 0;
		foreach(var dissolver in SaveManager.GetGooDissolverList())
		{
			if (dissolver.requiredForWin && !dissolver.Dissolved) currentDissolverCount++;
		}
		if (currentDissolverCount <= 0) OnWin();
	}
	public void OnGooDissolve()
	{
		currentDissolverCount--;
		if (currentDissolverCount <= 0) OnWin();
	}
	public void OnWin()
	{
		WonGame = true;
		StartCoroutine(WinGame());
	}

	IEnumerator WinGame()
	{
		yield return new WaitForSecondsRealtime(winWaitTime);
		IsCursorRestricted = false;
		Time.timeScale = 0;
		Player.GUI.WindowManager.SetCurrentWindow("Win");
	}

	private void OnValidate()
	{
		if (Application.isPlaying)
			Application.targetFrameRate = targetFrameRate;
	}

	public bool IsCursorRestricted
	{
		get
		{
			return Cursor.lockState == CursorLockMode.Locked;
		}
		set
		{
			if (value && enableCursorRestriction)
			{
				Cursor.lockState = CursorLockMode.Locked;
				Cursor.visible = false;
			}
			else
			{
				Cursor.lockState = CursorLockMode.None;
				Cursor.visible = true;
			}
		}
	}

	private void OnDestroy()
	{
		if (instance == this)
		{
			instance = null;
			if (Application.isEditor)
				SaveManager.ClearSaveData();
			Time.timeScale = 1;
			enableCursorRestriction = false;
		}
	}
}
