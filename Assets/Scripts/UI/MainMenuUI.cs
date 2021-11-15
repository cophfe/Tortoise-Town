using System.Collections;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;
using System.IO;
using TMPro;
#if UNITY_EDITOR
using UnityEditor;
#endif

public class MainMenuUI : MonoBehaviour
{
	public string gameplaySceneName = "Main";
	public Animator panel = null;
	public float fadeTime = 1;
	public Button continueButton;
	public GameWindow areYouSure;
	public TextMeshProUGUI areYouSureText;
	public Button areYouSureConfirm;
	public OptionsMenu optionsMenu;
	public GameWindow optionsWindow;
	InputMaster input;
	GameWindowManager windowManager;

	private void Awake()
	{
		if (File.Exists(SaveManager.GetPath()))
		{
			using (FileStream fs = new FileStream(SaveManager.GetPath(), FileMode.Open))
			{
				if (fs.Length > 0)
				{
					continueButton.interactable = true;
				}
			}
		}
		input = new InputMaster();
		input.UI.Menu.performed += _ => OnMenuButton();
		windowManager = GetComponent<GameWindowManager>();
	}
	private void Start()
	{
		if (optionsMenu)
			optionsMenu.Initiate();

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
			areYouSureConfirm.onClick.AddListener(() => StartCoroutine(LoadNewGame()));
			areYouSureText.text = "Are you sure you want to continue? This will erase all of your save data.";
			GetComponent<GameWindowManager>().AddToQueue(areYouSure);
		}
		else
		{
			StartCoroutine(LoadNewGame());
		}
	}

	IEnumerator LoadNewGame()
	{
		panel.SetBool("FadeIn", true);
		yield return new WaitForSeconds(fadeTime);

		try
		{
			if (File.Exists(SaveManager.GetPath()))
				File.Delete(SaveManager.GetPath());
			SceneManager.LoadScene(gameplaySceneName);
		}
		catch (System.Exception e)
		{
			Debug.LogWarning("Error loading scene:\n" + e.Message);
		}
	}

	public void OnContinueButtonPressed()
	{
		StartCoroutine(LoadGame());
	}

	IEnumerator LoadGame()
	{
		panel.SetBool("FadeIn", true);
		yield return new WaitForSeconds(fadeTime);

		try
		{
			SceneManager.LoadScene(gameplaySceneName);
		}
		catch (System.Exception e)
		{
			Debug.LogWarning("Error loading scene:\n" + e.Message);
		}
	}

	public void OnExitButtonPressed()
	{
		StartCoroutine(ExitGame());
	}
	
	IEnumerator ExitGame()
	{
		panel.SetBool("FadeIn", true);
		yield return new WaitForSeconds(fadeTime);
#if UNITY_EDITOR
		EditorApplication.isPlaying = false;
#else
		Application.Quit();
#endif
	}
	
}
