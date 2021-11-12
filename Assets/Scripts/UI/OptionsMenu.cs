using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.InputSystem;
using TMPro;
using System.IO;
using System;

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
	public Toggle playTutorial;
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

	[Header("Other")]
	public Button applyButton;
	public GameWindow keybindWindow;
	public Keybinding keybindingPrefab;
	public RectTransform keyBindingParent;
	public OptionsData defaultOptions;

	//Internal
	bool isChanged = false;
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
		foreach(var action in GameManager.Instance.Player.PlayerInput.actions)
		{
			var keybind = Instantiate(keybindingPrefab.gameObject, keyBindingParent).GetComponent<Keybinding>();
			keybind.SetText(action.name);
			keybind.SetBind(InputControlPath.ToHumanReadableString(action.bindings[0].effectivePath, InputControlPath.HumanReadableStringOptions.OmitDevice));
			keybind.SetAction(action);
		}
	}

	public void OpenKeybindingMenu()
	{
		windowManager.AddToQueue(keybindWindow);
	}

	public void CloseMenu()
	{
		windowManager.RemoveFromQueue();
	}

	void OnApply()
	{
		isChanged = false;
		Save();

		//GetComponent<PlayerInput>().actions.SaveBindingOverridesAsJson();
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
		//OptionsData options = new OptionsData
		//{
		//	fov = fov.value,
		//	screenShake = screenShake.value,
		//	playTutorial = playTutorial.isOn,

		//	sensitivity = cameraSensitivity.value,
		//	invertX = invertedCameraX.isOn,
		//	invertY = invertedCameraY.isOn,
		//	rebinds = overrides,

		//	windowMode = windowMode.value,
		//	vSyncMode = vSyncMode.value,
		//	graphicsQuality = graphicsQuality.value,

		//	masterVolume = masterVolume.value,
		//	sfxVolume = sFXVolume.value,
		//	musicVolume = musicVolume.value
		//};

		//first apply the changes to the UI
		fov.value = options.fov;
		screenShake.value = options.screenShake;
		playTutorial.isOn = options.playTutorial;
		
		cameraSensitivity.value = options.sensitivity;
		invertedCameraX.isOn = options.invertX;
		invertedCameraY.isOn = options.invertY;
		//rebinds

		windowMode.value = options.windowMode;
		vSyncMode.value = options.vSyncMode;
		graphicsQuality.value = options.graphicsQuality;
	}

	void ApplyUIToGame()
	{

	}

	public void Save()
	{
		string overrides = GameManager.Instance.Player.PlayerInput.actions.SaveBindingOverridesAsJson();

		OptionsData options = new OptionsData
		{
			fov = fov.value,
			screenShake = screenShake.value,
			playTutorial = playTutorial.isOn,

			sensitivity = cameraSensitivity.value,
			invertX = invertedCameraX.isOn,
			invertY = invertedCameraY.isOn,
			rebinds = overrides,

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

	string GetOptionsPath()
	{
		return Application.persistentDataPath + "/options.json";
	}

	public enum AreYouSureState
	{
		DEFAULT,
		BACK,
		RESETSAVEDATA
	}

	public void SetAreYouSure(int state)
	{
		switch ((AreYouSureState)state)
		{
			case AreYouSureState.DEFAULT:
				if (isChanged)
				{
					areYouSureText.text = "Are you sure you want to reset your settings to default? This will only affect the current tab.";
					areYouSureConfirm.onClick.RemoveAllListeners();
					//areYouSureConfirm.onClick.AddListener();
					windowManager.AddToQueue(areYouSure);
				}
				break;
			case AreYouSureState.BACK:
				if (isChanged)
				{
					areYouSureText.text = "Are you sure you want to leave? There are unsaved changes.";
					areYouSureConfirm.onClick.RemoveAllListeners();
					//areYouSureConfirm.onClick.AddListener();
					windowManager.AddToQueue(areYouSure);
				}
				else
				{
					windowManager.RemoveFromQueue();
				}
				break;
			case AreYouSureState.RESETSAVEDATA:
				areYouSureText.text = "Resetting save data cannot be undone. Do you want to continue?";
				areYouSureConfirm.onClick.RemoveAllListeners();
				//areYouSureConfirm.onClick.AddListener();
				windowManager.AddToQueue(areYouSure);
				break;
		}
	}

	[System.Serializable]
	public class OptionsData
	{
		//all floats are 0 to 1


		//general
		public float fov;
		public float screenShake;
		public bool playTutorial;

		//controls
		public float sensitivity;
		public bool invertX, invertY;
		public string rebinds; //json inception

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
