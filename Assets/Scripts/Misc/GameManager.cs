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

	Vector3 initialPlayerPosition;
	Quaternion initialPlayerRotation;

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
		SetSceneFromSavedData();
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

	public IEnumerator ResetScene()
	{
		yield return new WaitForSeconds(deathTime);
		player.GUI.Fade(true);
		yield return new WaitForSeconds(player.GUI.fadeTime);
		SetSceneFromSavedData();
		player.ResetPlayerToDefault();
		player.MainCamera.ResetCameraData();
		player.MainCamera.MoveToTarget();
		ArrowPool.ResetToDefault();
		player.GUI.Fade(false);
	}

	void SetSceneFromSavedData()
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
	}

	public void OnPlayerEnterCheckPoint()
	{
		//save current cleared areas
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
		}
	}
}
