using System.Collections;
using System.Collections.Generic;
using System;
using System.IO;
using UnityEngine;
using UnityEngine.SceneManagement;

public class SaveManager
{
	public bool saveDataToFile;
	int checkpointIndex = -1;
	List<Checkpoint> checkpoints = new List<Checkpoint>();
	List<Health> savedHealths = new List<Health>();
	List<IBooleanSaveable> saveables = new List<IBooleanSaveable>();

	SceneSaveData saveData = null;
	public SceneSaveData CurrentSaveData { get { return saveData; } }
	public delegate void ResetEvent();

	public event ResetEvent onResetScene;


	public SaveManager(bool saveDataToFile)
	{
		this.saveDataToFile = saveDataToFile;
	}

	public void RegisterSaveable(IBooleanSaveable saveable)
	{
		saveables.Add(saveable);
	}

	public void RegisterCheckpoint(Checkpoint checkpoint)
	{
		checkpoints.Add(checkpoint);
	}

	public void RegisterHealth(Health savedHealth)
	{
		savedHealths.Add(savedHealth);
	}
	public List<Health> GetHealths() { return savedHealths; }

	public void Start()
	{
		//sort so it is guaranteed consistant between versions
		//it will sort by both name and index, which will hopefully stop any name collisions from ruining the point of it
		//it doesn't matter what it is sorted like as long as it is consistant
		Comparison<MonoBehaviour> func = (a,b) => {
			int val = a.name.CompareTo(b.name); 
			if (val == 0)
			{
				var aIndex = a.transform.GetSiblingIndex();
				var bIndex = b.transform.GetSiblingIndex();
				if (aIndex > bIndex) return 1;
				else if (aIndex == bIndex) return 0;
				else return -1;
			}
			return val;
		};

		savedHealths.Sort(func);
		checkpoints.Sort(func);
		saveables.Sort((a,b) => { return func(a.GetMonoBehaviour(), b.GetMonoBehaviour()); });

		if (saveDataToFile)
			LoadSaveDataFromFile();
		else
			ClearSaveData();

		ResetScene();
	}

	public bool SetCurrentCheckpoint(Checkpoint checkpoint)
	{
		if (checkpoint == GetCurrentCheckpoint())
		{
			UpdateSaveData();
			return false;
		}
		else
		{
			var current = GetCurrentCheckpoint();
			if (current != null)
			{
				if (current.passive != null)
					current.passive.Stop(false, ParticleSystemStopBehavior.StopEmitting);
				current.Mat?.DisableKeyword("_EMISSION");
			}
			for (int i = 0; i < checkpoints.Count; i++)
			{
				if (checkpoint == checkpoints[i])
				{
					checkpointIndex = i;
					UpdateSaveData();
					return true;
				}
			}
			return false;
		}
	}

	public Checkpoint GetCurrentCheckpoint()
	{
		if (checkpointIndex < 0 || checkpointIndex > checkpoints.Count) return null;
		else return checkpoints[checkpointIndex];
	}

	void UpdateSaveData()
	{
		saveData.checkpointIndex = checkpointIndex;
		saveData.savedHealths = new float[savedHealths.Count];
		for (int i = 0; i < savedHealths.Count; i++)
		{
			saveData.savedHealths[i] = savedHealths[i].CurrentHealth;
		}

		saveData.saveableStates = new bool[saveables.Count];
		for (int i = 0; i < saveables.Count; i++)
		{
			saveData.saveableStates[i] = saveables[i].GetCurrentState();
		}
	}

	void WriteSaveDataToFile()
	{
		if (!saveDataToFile)
			return;

		if (saveData == null || saveData.checkpointIndex == -1) return;

		//idk how to do serialization so we'll do it the old fashioned way
		//on the bright side this is way faster
		using (FileStream fs = new FileStream(GetPath(), FileMode.OpenOrCreate, FileAccess.ReadWrite))
		{
			if (fs.Length > 0)
			{
				//remove this scene data that is already there (if it is already there)
				if (!ClearStoredSceneData(fs))
				{
					fs.SetLength(0);
				}
			}

			using (var writer = new BinaryWriter(fs))
			{
				fs.Seek(0, SeekOrigin.End);
				//write build index
				writer.Write(SceneManager.GetActiveScene().buildIndex);
				//write size of scene data
				writer.Write(sizeof(int) * 5 + sizeof(float) * saveData.savedHealths.Length + sizeof(bool) * saveData.saveableStates.Length);
				//write checkpoint info
				writer.Write(saveData.checkpointIndex);
				//write health info
				writer.Write(saveData.savedHealths.Length);
				for (int i = 0; i < saveData.savedHealths.Length; i++)
				{
					writer.Write(saveData.savedHealths[i]);
				}
				//write boolean switch info
				writer.Write(saveData.saveableStates.Length);
				for (int i = 0; i < saveData.saveableStates.Length; i++)
				{
					writer.Write(saveData.saveableStates[i]);
				}
			}
		}
	}

	bool ClearStoredSceneData(FileStream fs)
	{
		BinaryReader reader = new BinaryReader(fs);
		
		//read through to find the correct build index.
		//if it cannot be found, assume the scene has not been saved previously.
		//if it can be found, overwrite the data with a new file not including the save data for this scene.

		//if file is empty return success
		if (fs.Length == 0) return true;

		try
		{
			//read the build index
			int buildIndex = reader.ReadInt32();
			//check if build index is the current build index
			while (buildIndex != SceneManager.GetActiveScene().buildIndex)
			{
				//this is not the correct scene data, so skip over it (next int should contain the size of the scene data in bytes)
				fs.Seek(reader.ReadInt32() - sizeof(int) * 2, SeekOrigin.Current);

				//if reached the end of file, it did not find the scene and there is nothing to clear.
				if (fs.Position >= fs.Length)
				{
					return true;
				}
				//else there should be another scene saved
				buildIndex = reader.ReadInt32();
			}
			// if reached this point, it has found the correct build index. set the start and end cut points and read everything else into a byte array!
			int startCutPoint = (int)fs.Position - sizeof(int);
			int endCutPoint = startCutPoint + reader.ReadInt32();
			byte[] data = new byte[fs.Length - (endCutPoint - startCutPoint)];
			fs.Seek(0, SeekOrigin.Begin);
			fs.Read(data, 0, startCutPoint);
			if (fs.Length >= endCutPoint + 1)
			{
				fs.Seek(endCutPoint, SeekOrigin.Begin);
				fs.Read(data, startCutPoint, (int)fs.Length - endCutPoint);
			}

			fs.SetLength(data.Length);
			fs.Seek(0, SeekOrigin.Begin);
			fs.Write(data, 0, data.Length);
			return true;
		}
		catch (Exception e)
		{
			Debug.LogWarning("Could not clear scene data:\n" +
				e.Message
				+ "\nClearing entire file instead.");
			return false;
		}
	}

	void LoadSaveDataFromFile()
	{
		if (!saveDataToFile)
		{
			DeleteSceneData();
			ClearSaveData();
			return;
		}

		try
		{
			using (FileStream fs = new FileStream(Application.persistentDataPath + "/save.tt", FileMode.Open))
			{
				SceneSaveData newSaveData = new SceneSaveData();
				var reader = new BinaryReader(fs);

				//read build index
				int buildIndex = reader.ReadInt32();
				//check if it is correct
				while (buildIndex != SceneManager.GetActiveScene().buildIndex)
				{
					//this is not the correct scene data, so skip over it (next int should contain the size of the scene data in bytes)
					fs.Seek(reader.ReadInt32() - sizeof(int) * 2, SeekOrigin.Current);

					//if reached the end of file, it did not find the scene and there is nothing to clear.
					if (fs.Position >= fs.Length)
					{
						ClearSaveData();
						return;
					}
					//else there should be another scene saved
					buildIndex = reader.ReadInt32();
				}
				// if reached this point, it has found the correct scene data
				
				fs.Seek(sizeof(int), SeekOrigin.Current);
				newSaveData.checkpointIndex = reader.ReadInt32();

				//read saved health info
				newSaveData.savedHealths = new float[reader.ReadInt32()];
				if (newSaveData.savedHealths.Length != savedHealths.Count)
				{
					throw new Exception("Save data contained incorrect number of goo targets");
				}
				for (int i = 0; i < newSaveData.savedHealths.Length; i++)
				{
					newSaveData.savedHealths[i] = reader.ReadSingle();
				}

				//read saved boolean saveable info
				newSaveData.saveableStates = new bool[reader.ReadInt32()];
				if (newSaveData.saveableStates.Length != saveables.Count)
				{
					throw new Exception("Save data contained incorrect number of IBooleanSaveable states");
				}
				for (int i = 0; i < newSaveData.saveableStates.Length; i++)
				{
					newSaveData.saveableStates[i] = reader.ReadBoolean();
				}
				saveData = newSaveData;
			}
		}
		catch (Exception e)
		{
			Debug.LogWarning("Failed to load save data:\n" 
				+ e.Message 
				+"\nResetting save data...");
			ClearSaveData();
			DeleteSceneData();
			//delete save data instead
		}
	}

	public void ResetScene()
	{
		if (saveData == null)
			LoadSaveDataFromFile();

		for (int i = 0; i < savedHealths.Count; i++)
		{
			savedHealths[i].ResetTo(saveData.savedHealths[i]);
		}
		for (int i = 0; i < saveables.Count; i++)
		{
			saveables[i].SetToState(saveData.saveableStates[i]);
		}
		GameManager.Instance.CalculateCurrentDissolverCount();
		checkpointIndex = saveData.checkpointIndex;
		if (checkpointIndex != -1)
		{
			foreach (var checkpoint in checkpoints)
			{
				if (checkpoint.passive != null && !checkpoint.passive.isStopped)
					checkpoint.passive.Stop(false, ParticleSystemStopBehavior.StopEmittingAndClear);
				checkpoint.Mat?.DisableKeyword("_EMISSION");
			}
			if (checkpoints[checkpointIndex].passive)
				checkpoints[checkpointIndex].passive.Play();
			checkpoints[checkpointIndex].Mat?.EnableKeyword("_EMISSION");
		}
		
		if (onResetScene != null)
			onResetScene.Invoke(); 
	}
	
	public bool CheckIfTutorialCompleted()
	{
		try
		{
			if (File.Exists(GetPath()))
			{
				using (var fs = new FileStream(GetPath(), FileMode.Open, FileAccess.Read))
				{
					if (fs.Length == 0)
						return false;
					else if (fs.ReadByte() == 0)
						return false;
					else return true;
				}
			}
			else
				return false;
		}
		catch (Exception e)
		{
			Debug.LogWarning("Something went wrong when reading the save file:\n" + 
				e.Message);
			return false;
		}
	}

	public void ClearSaveData()
	{
		saveData = new SceneSaveData();
		saveData.checkpointIndex = -1;
		saveData.buildIndex = SceneManager.GetActiveScene().buildIndex;
		saveData.savedHealths = new float[savedHealths.Count];
		saveData.saveableStates = new bool[saveables.Count];
		for (int i = 0; i < saveData.savedHealths.Length; i++)
		{
			saveData.savedHealths[i] = savedHealths[i].MaxHealth;
		}
		for (int i = 0; i < saveData.saveableStates.Length; i++)
		{
			saveData.saveableStates[i] = saveables[i].InitialSaveState;
		}
	}

	public void DeleteSceneData()
	{
		if (File.Exists(GetPath()))
		{
			using (FileStream fs = new FileStream(Application.persistentDataPath + "/save.tt", FileMode.Open))
			{
				//if deleting scene data fails, the data must be messed up, so delete all data
				if (!ClearStoredSceneData(fs))
				{
					fs.SetLength(0);
				}
			}
		}
	}

	public void DeleteAllData()
	{
		if (File.Exists(Application.persistentDataPath + "/save.tt"))
		{
			using (FileStream fs = new FileStream(Application.persistentDataPath + "/save.tt", FileMode.Open))
			{
				fs.SetLength(0);
			}
		}
	}

	public void OnDestroy()
	{
		if (saveDataToFile && saveData != null)
		{
			WriteSaveDataToFile();
		}
	}

	public SceneSaveData GetSaveData() { return saveData; }

	public class SceneSaveData
	{
		public int buildIndex;
		public int checkpointIndex;
		public float[] savedHealths;
		public bool[] saveableStates;
	}

	public static string GetPath() { return Application.persistentDataPath + "\\save.tt"; }
}
