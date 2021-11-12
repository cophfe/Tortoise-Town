using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.InputSystem;

[RequireComponent(typeof(GameWindowManager))]
public class GameplayUIManager : MonoBehaviour
{
	[SerializeField]
	bool disableMenuInput = false;

	public Image crosshair;
	public Animator fadeAnimator;
	public float fadeTime = 1;

	public GameWindowManager WindowManager { get; private set; }
	InputMaster input;

	private void Awake()
	{
		input = new InputMaster();
		input.UI.Menu.performed += _ => OnMenuButton();
		WindowManager = GetComponent<GameWindowManager>();
	}

	private void Start()
	{
		Fade(false);
	}
	public void OnEnable()
	{
		if (input != null)
			input.Enable();
	}
	public void OnDisable()
	{
		if (input != null)
			input.Disable();
	}

	public void EnableCrossHair(bool enable)
	{
		crosshair.enabled = enable;
	}

	void OnMenuButton()
	{
		if (!disableMenuInput && !GameManager.Instance.Player.Health.IsDead && !GameManager.Instance.WonGame)
			WindowManager.ToggleWindows();
	}

	public void OnRestartButtonPressed()
	{
		StartCoroutine(RestartGame());
	}

	IEnumerator RestartGame()
	{
		Fade(true);
		fadeAnimator.updateMode = AnimatorUpdateMode.UnscaledTime;
		yield return new WaitForSecondsRealtime(fadeTime);
		if (GameManager.Instance.WonGame)
		{
			Time.timeScale = 1;
			GameManager.Instance.SaveManager.ClearSaveData();
			GameManager.Instance.ReloadScene();
		}
		else
		{
			WindowManager.InstantCloseAll();
			Time.timeScale = 1;
			GameManager.Instance.SetSceneFromSavedData();
			GameManager.Instance.Player.Animator.ResetPlayerAnimation();
		}
	}

	public void OnExitButtonPressed()
	{
		StartCoroutine(ExitGame());
	}

	IEnumerator ExitGame()
	{
		Fade(true);
		fadeAnimator.updateMode = AnimatorUpdateMode.UnscaledTime;
		yield return new WaitForSecondsRealtime(fadeTime);
		if (GameManager.Instance.WonGame)
			GameManager.Instance.SaveManager.ClearSaveData();
		GameManager.Instance.ExitToMenu();
	}
	public void Fade(bool fadeIn)
	{
		fadeAnimator.SetBool("FadeIn", fadeIn);
	}
}
