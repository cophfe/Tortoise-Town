using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.InputSystem;
using TMPro;
using System.IO;
using System;
using System.Globalization;
using UnityEngine.Audio;

public class OptionsMenu : MonoBehaviour
{
	[Header("are you sure popup")]
	public GameWindowManager windowManager = null;
	public GameWindow areYouSure;
	public TextMeshProUGUI areYouSureText;
	public Button areYouSureConfirm;

	[Header("General Options")]
	public Slider fov;
	public Slider screenShake;
	public Button resetSaveData;

	[Header("Controls Options")]
	public Slider cameraSensitivity;
	public Toggle invertedCameraX, invertedCameraY;

	[Header("Video Options")]
	public TMP_Dropdown resolution;
	public TMP_Dropdown windowMode;
	public TMP_Dropdown vSyncMode;
	public TMP_Dropdown graphicsQuality;

	[Header("Audio Options")]
	public Slider masterVolume;
	public Slider sFXVolume;
	public Slider musicVolume;

	[Header("Keybind Stuff")]
	public GameWindow keybindWindow;
	public Keybinding keybindingPrefab;
	public RectTransform keybindContent;

	[Header("Audio Mixer Stuff")]
	public AudioMixer mixer;
	[Tooltip("The exposed paramater on the mixer that controls master volume.")]
	public string masterParameterName = "Master Volume";
	[Tooltip("The exposed paramater on the mixer that controls music volume.")]
	public string musicParameterName = "Music Volume";
	[Tooltip("The exposed paramater on the mixer that controls music volume.")]
	public string sfxParameterName = "SFX Volume";

	[Header("Other")]
	public Button applyButton;
	public OptionsData defaultOptions;
	public MainMenuUI mainMenu;
	public PlayerInput backupInput;
	public Camera mainCameraPrefab;

	//Internal
	List<Vector2Int> resolutions;
	int resolutionIndex = 0;
	bool isChanged = false;
	List<Keybinding> bindings;

	bool IsChanged
	{
		get
		{
			return isChanged;
		}
		set
		{
			isChanged = value;
			applyButton.interactable = value;
		}
	}

	public void Initiate()
	{
		//START RESOLUTIONS
		Resolution currentRes = Screen.currentResolution;
		resolutionIndex = 0;
		var allResolutions = Screen.resolutions;
		resolutions = new List<Vector2Int>();

		resolutions.Add(new Vector2Int(allResolutions[0].width, allResolutions[0].height));
		for (int i = 1; i < allResolutions.Length; i++)
		{
			if (allResolutions[i].width == allResolutions[i - 1].width && allResolutions[i].height == allResolutions[i - 1].height)
				continue;

			resolutions.Add(new Vector2Int(allResolutions[i].width, allResolutions[i].height));

			if (currentRes.width == allResolutions[i].width && currentRes.height == allResolutions[i].height)
				resolutionIndex = resolutions.Count - 1;
		}

		List<string> resolutionStrings = new List<string>(resolutions.Count);
		for (int i = resolutions.Count - 1; i >= 0; i--)
		{
			resolutionStrings.Add($"{resolutions[i].x}x{resolutions[i].y}");
		}
		resolution.AddOptions(resolutionStrings);
		resolution.value = resolutionStrings.Count - 1 - resolutionIndex;
		//END RESOLUTIONS

		//make sure defaultoptions is correct on some things
		ValidateDefaults();

		//EVERYTHING ELSE
		ApplyFromFile();
		if (File.Exists(GetKeybindsPath()))
		{
			try
			{
				string keybindSaved = File.ReadAllText(GetKeybindsPath());
				if (GameManager.Instance)
					GameManager.Instance.Player.PlayerInput.actions.LoadBindingOverridesFromJson(keybindSaved);
				else
					backupInput.actions.LoadBindingOverridesFromJson(keybindSaved);
			}
			catch
			{
				Debug.LogWarning("There were no keybinds to load.");
			}
		}
		ApplyUIToGame();
		//END EVERYTHING ELSE

		//KEYBINDINGS
		bindings = new List<Keybinding>();
		int count = 0;
		InputActionMap inputActionMap;
		if (GameManager.Instance)
		{
			inputActionMap = GameManager.Instance.Player.PlayerInput.currentActionMap;
		}
		else
		{
			inputActionMap = backupInput.currentActionMap;
		}

		foreach (var action in inputActionMap.actions)
		{
			if (action.bindings[0].isComposite)
			{
				for (int i = 1; i < 5; i++)
				{
					var keybind = Instantiate(keybindingPrefab.gameObject, keybindContent).GetComponent<Keybinding>();
					string controlName = action.bindings[i].name;
					keybind.Set(controlName[0].ToString().ToUpper() + controlName.Substring(1),
						action.bindings[i].ToDisplayString(),
						action,
						this,
						i,
						GameManager.Instance != null);
					bindings.Add(keybind);
					count++;
				}
			}
			else
			{
				var keybind = Instantiate(keybindingPrefab.gameObject, keybindContent).GetComponent<Keybinding>();
				keybind.Set(action.name,
					action.controls[0].displayName,
					action,
					this, 
					0,
					GameManager.Instance != null);
				bindings.Add(keybind);
				count++;
			}
		}
		var rect = keybindContent.sizeDelta;
		rect.y += count * (keybindingPrefab.GetComponent<RectTransform>().sizeDelta.y + 8);
		keybindContent.sizeDelta = rect;
		//END KEYBINDINGS

		IsChanged = false;
	}

	void ValidateDefaults()
	{
		defaultOptions.windowMode = (int)Screen.fullScreenMode;
		defaultOptions.vSyncMode = QualitySettings.vSyncCount;
		defaultOptions.graphicsQuality = QualitySettings.GetQualityLevel();
	}

	public void OpenKeybindingMenu()
	{
		windowManager.AddToQueue(keybindWindow);
	}

	public void CloseMenu()
	{
		windowManager.RemoveFromQueue();
	}

	public void OnApply()
	{
		IsChanged = false;
		ApplyUIToGame();
		Save();
	}

	public void OnChangedValue()
	{
		IsChanged = true;
	}

	private void OnEnable()
	{
		if (backupInput)
			backupInput.enabled = false;
	}

	public void ApplyFromFile()
	{
		OptionsData options;
		if (File.Exists(GetOptionsPath()))
		{
			try
			{
				string saved = File.ReadAllText(GetOptionsPath());
				options = (OptionsData)JsonUtility.FromJson(saved, typeof(OptionsData));
				ApplyDataToUI(options);
			}
			catch (Exception e)
			{
				Debug.LogWarning("Failed to load options data:\n" + e.Message + "\nSetting to default instead.");
				File.Delete(GetOptionsPath());
				ApplyDataToUI(defaultOptions);
				return;
			}
		}
		else
		{
			Debug.LogWarning("Options data does not exist on device. Setting to default.");
			ApplyDataToUI(defaultOptions);
		}
	}

	void ApplyDataToUI(OptionsData options)
	{
		//first apply the changes to the UI
		fov.value = options.fov;
		screenShake.value = options.screenShake;
		
		cameraSensitivity.value = options.sensitivity;
		invertedCameraX.isOn = options.invertX;
		invertedCameraY.isOn = options.invertY;

		windowMode.value = options.windowMode;
		vSyncMode.value = options.vSyncMode;
		graphicsQuality.value = options.graphicsQuality;

		masterVolume.value = options.masterVolume;
		sFXVolume.value = options.sfxVolume;
		musicVolume.value = options.musicVolume;
	}

	void ApplyUIToGame()
	{
		GameManager gameManager = GameManager.Instance;
		if (gameManager)
		{
			var player = gameManager.Player;
			if (player)
			{
				CameraController cameraController = player.MainCamera;
				cameraController.GetComponent<Camera>().fieldOfView = fov.value;
				cameraController.screenShakeModifier = screenShake.value;
				cameraController.sensitivityModifier = cameraSensitivity.value;
				cameraController.invertX = invertedCameraX.isOn;
				cameraController.invertY = invertedCameraY.isOn;
			}
		}

		QualitySettings.vSyncCount = vSyncMode.value;
		QualitySettings.SetQualityLevel(graphicsQuality.value);

		int resIndex = resolutions.Count - 1 - resolution.value;
		if (!(resIndex >= 0 && resIndex < resolutions.Count))
			resIndex = resolutions.Count - 1;
		Vector2Int res = resolutions[resIndex];

		Screen.SetResolution(res.x, res.y, (FullScreenMode)windowMode.value);

		mixer.SetFloat(masterParameterName, LinearToDecibels(masterVolume.value));
		mixer.SetFloat(musicParameterName, LinearToDecibels(musicVolume.value));
		mixer.SetFloat(sfxParameterName, LinearToDecibels(sFXVolume.value));
	}

	public void Save()
	{
		OptionsData options = new OptionsData
		{
			fov = fov.value,
			screenShake = screenShake.value,

			sensitivity = cameraSensitivity.value,
			invertX = invertedCameraX.isOn,
			invertY = invertedCameraY.isOn,

			windowMode = windowMode.value,
			vSyncMode = vSyncMode.value,
			graphicsQuality = graphicsQuality.value,

			masterVolume = masterVolume.value,
			sfxVolume = sFXVolume.value,
			musicVolume = musicVolume.value
		};


		string optionsJson = JsonUtility.ToJson(options);
		try
		{
			File.WriteAllText(GetOptionsPath(), optionsJson);
		}
		catch (Exception e)
		{
			Debug.LogWarning($"Failed to save options data:\n" + e.Message);
		}
	}

	public void SaveKeybinds()
	{
		PlayerInput input;
		if (GameManager.Instance)
			input = GameManager.Instance.Player.PlayerInput;
		else
			input = backupInput;

		string overrides = input.actions.SaveBindingOverridesAsJson();
		File.WriteAllText(GetKeybindsPath(), overrides);
	}

	string GetOptionsPath()
	{
		return Application.persistentDataPath + "/options.json";
	}

	string GetKeybindsPath()
	{
		return Application.persistentDataPath + "/keybinds.json";
	}

	public enum AreYouSureState
	{
		DEFAULT,
		BACK,
		RESETSAVEDATA,
		DEFAULTKEYBINDS
	}

	public void SetAreYouSure(int state)
	{
		switch ((AreYouSureState)state)
		{
			case AreYouSureState.DEFAULT:
					
				areYouSureText.text = "Are you sure you want to reset your settings to default?";
				areYouSureConfirm.onClick.RemoveAllListeners();
				areYouSureConfirm.onClick.AddListener(ApplyDefault);
				windowManager.AddToQueue(areYouSure);
				break;
			case AreYouSureState.BACK:
				if (IsChanged)
				{
					areYouSureText.text = "Are you sure you want to exit? There are unsaved changes.";
					areYouSureConfirm.onClick.RemoveAllListeners();
					areYouSureConfirm.onClick.AddListener(LeaveMenu);
					windowManager.AddToQueue(areYouSure);
				}
				else
				{
					windowManager.RemoveFromQueue();
					ApplyFromFile();
					IsChanged = false;
				}
				break;
			case AreYouSureState.RESETSAVEDATA:
				areYouSureText.text = "Resetting save data cannot be undone. Do you want to continue?";
				areYouSureConfirm.onClick.RemoveAllListeners();
				areYouSureConfirm.onClick.AddListener(DeleteSave);
				windowManager.AddToQueue(areYouSure);
				break;
			case AreYouSureState.DEFAULTKEYBINDS:
				areYouSureText.text = "Are you sure you want to reset the keybinds?";
				areYouSureConfirm.onClick.RemoveAllListeners();
				areYouSureConfirm.onClick.AddListener(ResetKeybindings);
				windowManager.AddToQueue(areYouSure);
				break;
		}
	}

	public void LeaveMenu()
	{
		windowManager.RemoveFromQueue(); 
		windowManager.RemoveFromQueue(true);
		ApplyFromFile();
		IsChanged = false;
	}
	public void ApplyDefault()
	{
		ApplyDataToUI(defaultOptions);
		windowManager.RemoveFromQueue();
	}
	public void DeleteSave()
	{
		if (File.Exists(SaveManager.GetPath()))
		{
			File.WriteAllText(SaveManager.GetPath(), "");
		}
		windowManager.RemoveFromQueue();
		if (mainMenu)
		{
			mainMenu.continueButton.interactable = false;
		}
	}

	public void PopWindow()
	{
		windowManager.RemoveFromQueue();
	}

	public void ResetKeybindings()
	{
		if (GameManager.Instance)
			GameManager.Instance.Player.PlayerInput.actions.RemoveAllBindingOverrides();
		else
			backupInput.actions.RemoveAllBindingOverrides();
		
		SaveKeybinds();
		windowManager.RemoveFromQueue();
		foreach (var keybind in bindings)
		{
			keybind.SetBind();
		}
	}

	public static float DecibelsToLinear(float db)
	{
		return Mathf.Pow(10.0f, db / 20.0f);
	}

	public static float LinearToDecibels(float linear)
	{
		return 20.0f * Mathf.Log10(linear);
	}

	[System.Serializable]
	public class OptionsData
	{
		//all floats are 0 to 1


		//general
		public float fov;
		public float screenShake;

		//controls
		public float sensitivity;
		public bool invertX, invertY;

		//video
		public int windowMode;
		public int vSyncMode;
		public int graphicsQuality;

		//audio
		public float masterVolume;
		public float sfxVolume;
		public float musicVolume;
	}

}
