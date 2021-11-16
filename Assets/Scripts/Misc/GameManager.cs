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
	[SerializeField] bool saveDataToFile = true;
	[SerializeField] bool isTutorial = false;

	[Header("References")]
	[SerializeField] PlayerController player = null;
	[SerializeField] GameplayUIManager gUI = null;

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
	public SaveManager SaveManager { get; private set; }
	public GameplayUIManager GUI { get { return gUI; } }
	public bool IsTutorial {get {return isTutorial; } }
	public bool WonGame { get; private set; } = false;

	Vector3 initialPlayerPosition;
	Quaternion initialPlayerRotation;
	int currentDissolverCount;
	int totalDissolverCount;
	List<GooDissolve> gooDissolvers;
	List<BooleanSwitch> winSwitches = null;

	void Awake()
    {
		if (instance)
		{
			Debug.LogWarning("There should only ever be one instance of the GameManager in each scene.");
			Destroy(this);
		}
		else
		{
			if (!gUI)
				gUI = FindObjectOfType<GameplayUIManager>();
			SaveManager = new SaveManager(saveDataToFile);
			instance = this;
			IsCursorRestricted = true;
			ArrowPool = new ObjectPool(arrowPoolAmount, arrowPoolNotifyDistance, arrowPrefab, transform);
			Application.targetFrameRate = targetFrameRate;
			if (!player) player = FindObjectOfType<PlayerController>();

			initialPlayerPosition = player.transform.position;
			initialPlayerRotation = player.transform.rotation;
			gooDissolvers = new List<GooDissolve>();
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
		CalculateCurrentDissolverCount();
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
		GUI.Fade(true);
		yield return new WaitForSeconds(GUI.fadeTime);
		SetSceneFromSavedData();
	}

	public void ReloadScene()
	{
		SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex);
	}

	public void SetSceneFromSavedData()
	{
		SaveManager.ResetScene();
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
		GUI.Fade(false);
		CalculateCurrentDissolverCount();
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

	public void RegisterGooDissolver(GooDissolve dissolver)
	{
		gooDissolvers.Add(dissolver);
	}

	public void RegisterWinSwitch(BooleanSwitch winSwitch)
	{
		if (winSwitches == null) winSwitches = new List<BooleanSwitch>();

		winSwitches.Add(winSwitch);
	}

	public void CalculateTotalDissolvers()
	{
		totalDissolverCount = 0;
		foreach (var dissolver in gooDissolvers)
		{
			if (dissolver.requiredForWin) totalDissolverCount++;
		}
	}
	public void CalculateCurrentDissolverCount()
	{
		currentDissolverCount = 0;
		foreach(var dissolver in gooDissolvers)
		{
			if (dissolver.requiredForWin && !dissolver.Dissolved) currentDissolverCount++;
		}
		//Debug.Log($"current: {currentDissolverCount}. total: {totalDissolverCount}");

		if (currentDissolverCount <= 0) OnWin();
	}
	public void OnGooDissolve()
	{
		CalculateCurrentDissolverCount();
	}
	public void OnWin()
	{
		WonGame = true;
		StartCoroutine(WinGame());
	}

	IEnumerator WinGame()
	{
		yield return new WaitForSecondsRealtime(winWaitTime);
		

		if (winSwitches != null)
			foreach (var wSwitch in winSwitches)
			{
				wSwitch.Switch(true);
			}

		//GameManager.Instance.Player.InputIsEnabled = false;
		//IsCursorRestricted = false;
		//Time.timeScale = 0;
	}

	public void OnTutorialContinue()
	{

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
			Time.timeScale = 1;
			IsCursorRestricted = false;
			SaveManager.OnDestroy();
		}
	}
}
