using System.Collections;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;
using System.IO;
using TMPro;
using UnityEngine.EventSystems;
using UnityEngine.Audio;
#if UNITY_EDITOR
using UnityEditor;
#endif

public class MainMenuUI : MonoBehaviour
{
	public string gameplaySceneName = "Main";
	public string tutorialSceneName = "Tutorial_Level";
	public Animator panel = null;
	public LoadingBar loadingManager = null;
	public float fadeTime = 1;
	public Button continueButton;
	public GameWindow areYouSure;
	public TextMeshProUGUI areYouSureText;
	public Button areYouSureConfirm;
	public Button playTutorialButton;
	public OptionsMenu optionsMenu;
	public GameWindow optionsWindow;
	InputMaster input;
	GameWindowManager windowManager;
	public AudioMixerSnapshot defaultSnapshot;
	public AudioMixerSnapshot fadeOutSnapshot;
	public AudioSource buttonSound;
	private void Awake()
	{
		defaultSnapshot.TransitionTo(0);
		input = new InputMaster();
		input.UI.Menu.performed += _ => OnMenuButton();
		input.UI.Back.performed += _ => OnBackButton();
		input.UI.ChangeTabs.performed += _ => OnShoulderButton(_.ReadValue<float>());
		windowManager = GetComponent<GameWindowManager>();

		if (!PlayerPrefs.HasKey("Hey you! stop poking around in the registry!"))
			PlayerPrefs.SetString("Hey you! stop poking around in the registry!", ">:(");
	}
	private void Start()
	{
		if (optionsMenu)
			optionsMenu.Initiate();

		playTutorialButton.gameObject.SetActive(PlayerPrefs.GetInt("TutorialCompleted", 0) == 1);

		if (File.Exists(SaveManager.GetPath()))
		{
			using (FileStream fs = new FileStream(SaveManager.GetPath(), FileMode.Open))
			{
				if (fs.Length > 0)
				{
					continueButton.interactable = true;
				}
				else
				{
					continueButton.interactable = false;
				}
			}
		}
		else
		{
			continueButton.interactable = false;
		}
		var buttons = GetComponentsInChildren<Button>(true);
		if (buttons != null)
		{
			foreach (var button in buttons)
			{
				button.onClick.AddListener(PlayButtonSound);
			}
		}
	}

	public void PlayButtonSound()
	{
		buttonSound.Play();
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

	public void OnShoulderButton(float value)
	{
		if (optionsWindow == windowManager.GetCurrentWindow() && optionsWindow != null)
		{
			optionsMenu.tabController.ChangeTabs(value);
		}
	}
	public void OnBackButton()
	{
		var window = windowManager.GetCurrentWindow();
		if (window != null)
		{
			if (window.onBackPressedSelectable != null && window.onBackPressedSelectable.gameObject != EventSystem.current.currentSelectedGameObject)
			{
				window.onBackPressedSelectable.Select();
			}
			else if (optionsWindow == window)
			{
				optionsMenu.SetAreYouSure(1);
			}
			else
				windowManager.RemoveFromQueue();
		}
	}

	public void OnMenuButton()
	{
		if (windowManager.GetCurrentWindow() == optionsWindow)
		{
			optionsMenu.SetAreYouSure(1);
		}
		else
			windowManager.RemoveFromQueue();
	}
	public void OnPlayButtonPressed()
	{
		if (continueButton.interactable)
		{
			areYouSureConfirm.onClick.RemoveAllListeners();
			areYouSureConfirm.onClick.AddListener(LoadNewGame);
			areYouSureText.text = "Are you sure you want to continue? This will erase all of your save data.";
			GetComponent<GameWindowManager>().AddToQueue(areYouSure);
		}
		else
		{
			LoadNewGame();

		}
	}

	void LoadNewGame()
	{
		if (File.Exists(SaveManager.GetPath()))
			File.Delete(SaveManager.GetPath());

		if (PlayerPrefs.GetInt("TutorialCompleted", 0) == 0)
		{
			fadeOutSnapshot.TransitionTo(fadeTime / 2);
			StartCoroutine(loadingManager.LoadLevel(tutorialSceneName));

		}
		else
		{
			fadeOutSnapshot.TransitionTo(fadeTime / 2);
			StartCoroutine(loadingManager.LoadLevel(gameplaySceneName));
		}

	}

	public void LoadTutorialStart()
	{
		fadeOutSnapshot.TransitionTo(fadeTime / 2);
		StartCoroutine(loadingManager.LoadLevel(tutorialSceneName));
	}

	public void OnContinueButtonPressed()
	{
		fadeOutSnapshot.TransitionTo(fadeTime / 2);
		StartCoroutine(loadingManager.LoadLevel(gameplaySceneName));
	}

	public void OnExitButtonPressed()
	{
		StartCoroutine(ExitGame());
	}
	
	IEnumerator ExitGame()
	{
		panel.SetBool("FadeIn", true);
		defaultSnapshot.TransitionTo(fadeTime/2);

		yield return new WaitForSeconds(fadeTime);
#if UNITY_EDITOR
		EditorApplication.isPlaying = false;
#else
		Application.Quit();
#endif
	}
	
}
