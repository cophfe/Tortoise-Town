using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.InputSystem;
using TMPro;

[RequireComponent(typeof(GameWindowManager))]
public class GameplayUIManager : MonoBehaviour
{
	[SerializeField]
	bool disableMenuInput = false;

	public Image crosshair;
	public Animator fadeAnimator;
	public float fadeTime = 1;
	public GameWindow pauseMenu;
	public GameWindow winMenu;
	public GameWindow areYouSure;
	public TextMeshProUGUI areYouSureText;
	public Button areYouSureConfirm;
	public OptionsMenu options;

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
		if (options == null)
		{
			options = GetComponentInChildren<OptionsMenu>();
		}
		options.Initiate();
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
		{
			if (WindowManager.GetCurrentWindow() == null)
			{
				WindowManager.AddToQueue(pauseMenu);
			}
			else
			{
				WindowManager.RemoveFromQueue();
			}
		}
	}

	public void OnRestartButtonPressed(bool reloadSceneCompletely)
	{
		StartCoroutine(RestartGame(reloadSceneCompletely));
	}

	IEnumerator RestartGame(bool reloadSceneCompletely)
	{
		Fade(true);
		fadeAnimator.updateMode = AnimatorUpdateMode.UnscaledTime;
		yield return new WaitForSecondsRealtime(fadeTime);
		if (reloadSceneCompletely)
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

	public enum AreYouSureState
	{
		QUIT,
		RESTART,
	}

	public void SetAreYouSure(int state)
	{
		switch ((AreYouSureState)state)
		{
			case AreYouSureState.QUIT:
				areYouSureText.text = "Are you sure you want to quit? Progress up to the last checkpoint will be saved.";
				areYouSureConfirm.onClick.RemoveAllListeners();
				areYouSureConfirm.onClick.AddListener(OnExitButtonPressed);
				WindowManager.AddToQueue(areYouSure);
				break;
			case AreYouSureState.RESTART:
				areYouSureText.text = "Are you sure you want to restart? This will erase your save data.";
				areYouSureConfirm.onClick.RemoveAllListeners();
				areYouSureConfirm.onClick.AddListener(() => OnRestartButtonPressed(true));
				WindowManager.AddToQueue(areYouSure);
				break;
			default:
				break;
		}
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
