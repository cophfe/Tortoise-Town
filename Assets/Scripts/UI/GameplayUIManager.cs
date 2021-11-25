using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
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
	public GameWindow optionsWindow;
	public TextMeshProUGUI areYouSureText;
	public Button areYouSureConfirm;
	public OptionsMenu options;
	public TextMeshProUGUI cutsceneNotifyText;
	public Animator cutsceneNotify;

	public delegate void VoidEvent();
	public event VoidEvent onCutsceneSkipped;

	public GameWindowManager WindowManager { get; private set; }
	InputMaster input;

	public bool InputIsEnabled { 
		set 
		{
			if (input == null) return;

			if (value)
				input.Enable();
			else
				input.Disable();
		}
	}

	private void Awake()
	{
		input = new InputMaster();
		input.UI.Menu.performed += _ => OnMenuButton();
		input.UI.Back.performed += _ => OnBackButton();
		input.UI.ChangeTabs.performed += _ => OnShoulderButton(_.ReadValue<float>());
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

	public void OnShoulderButton(float value)
	{
		if (optionsWindow == WindowManager.GetCurrentWindow() && optionsWindow != null)
		{
			options.tabController.ChangeTabs(value);
		}
	}
	public void OnBackButton()
	{
		if (GameManager.Instance.InCutscene)
		{
			if (cutsceneNotifyText.alpha > 0)
			{
				onCutsceneSkipped?.Invoke();
			}
			else
				cutsceneNotify.SetTrigger("Start");
		}
		else if (!disableMenuInput)
		{
			var window = WindowManager.GetCurrentWindow();
			if (window != null)
			{
				if (window.onBackPressedSelectable != null && window.onBackPressedSelectable.gameObject != EventSystem.current.currentSelectedGameObject)
				{
					window.onBackPressedSelectable.Select();
				}
				else if (optionsWindow == window)
				{
					options.SetAreYouSure(1);
				}
				else
					WindowManager.RemoveFromQueue();
			}
		}
	}

	public void OnMenuButton()
	{
		if (GameManager.Instance.InCutscene)
		{
			if (cutsceneNotifyText.alpha > 0)
			{
				onCutsceneSkipped?.Invoke();
			}
			else
				cutsceneNotify.SetTrigger("Start");


		}
		else if (!disableMenuInput && !GameManager.Instance.Player.Health.IsDead)
		{
			fadeAnimator.updateMode = AnimatorUpdateMode.UnscaledTime;

			if (WindowManager.GetCurrentWindow() == null)
			{
				WindowManager.AddToQueue(pauseMenu);
			}
			else
			{
				if (optionsWindow == WindowManager.GetCurrentWindow())
				{
					options.SetAreYouSure(1);
				}
				else
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

	public void OnTutorialContinueButtonPressed()
	{
		PlayerPrefs.SetInt("TutorialCompleted", 1);
		StartCoroutine(ContinueToMain());
	}

	public enum AreYouSureState
	{
		QUIT,
		RESTART,
		SKIPTUTORIAL
	}

	public void SetAreYouSure(int state)
	{
		switch ((AreYouSureState)state)
		{
			case AreYouSureState.QUIT:
				areYouSureText.text = "Progress up to the last checkpoint will be saved.";
				areYouSureConfirm.onClick.RemoveAllListeners();
				areYouSureConfirm.onClick.AddListener(OnExitButtonPressed);
				WindowManager.AddToQueue(areYouSure);
				break;
			case AreYouSureState.RESTART:
				areYouSureText.text = "This will perminantly erase your save data.";
				areYouSureConfirm.onClick.RemoveAllListeners();
				areYouSureConfirm.onClick.AddListener(() => OnRestartButtonPressed(true));
				WindowManager.AddToQueue(areYouSure);
				break;
			case AreYouSureState.SKIPTUTORIAL:
				areYouSureText.text = "The tutorial can be replayed at any time.";
				areYouSureConfirm.onClick.RemoveAllListeners();
				areYouSureConfirm.onClick.AddListener(OnTutorialContinueButtonPressed);
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
		GameManager.Instance.ExitToMenu();
	}

	IEnumerator ContinueToMain()
	{
		Fade(true);
		fadeAnimator.updateMode = AnimatorUpdateMode.UnscaledTime;
		yield return new WaitForSecondsRealtime(fadeTime);
		GameManager.Instance.OnTutorialContinue();
	}

	public IEnumerator StartCutscene(CutsceneManager cutscene)
	{
		Fade(true);
		fadeAnimator.updateMode = AnimatorUpdateMode.UnscaledTime;
		yield return new WaitForSecondsRealtime(fadeTime);
		InputIsEnabled = true;
		Fade(false);
		cutscene.Switch(true);
	}

	public IEnumerator EndCutscene(CutsceneManager cutscene)
	{
		Fade(true);
		fadeAnimator.updateMode = AnimatorUpdateMode.UnscaledTime;
		yield return new WaitForSecondsRealtime(fadeTime);
		GameManager.Instance.InCutscene = false;
		cutscene?.OnCompleteStop();
		Fade(false);
	}

	public IEnumerator OpenWinMenu()
	{
		Fade(true);
		fadeAnimator.updateMode = AnimatorUpdateMode.UnscaledTime;
		yield return new WaitForSecondsRealtime(fadeTime);
		WindowManager.AddToQueue(winMenu);
	}
	public void Fade(bool fadeIn)
	{
		fadeAnimator.SetBool("FadeIn", fadeIn);
	}
}
