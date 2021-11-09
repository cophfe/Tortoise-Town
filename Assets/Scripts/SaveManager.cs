using System.Collections;
using System.Collections.Generic;
using System;
using System.IO;
using UnityEngine;

public class SaveManager
{
	int checkpointIndex = -1;
	List<Checkpoint> checkpoints = new List<Checkpoint>();
	List<Health> savedHealths = new List<Health>();
	List<IBooleanSaveable> saveables = new List<IBooleanSaveable>();

	SaveData saveData = null;
	public SaveData CurrentSaveData { get { return saveData; } }
	public delegate void ResetEvent();

	public event ResetEvent onResetScene;

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
		if (Application.isEditor)
			ClearSaveData();
		else
		{
			LoadSaveData();
		}

		ResetScene(false);
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
		WriteSaveData();
	}

	void WriteSaveData()
	{
		//idk how to do serialization so we'll do it the old fashioned way
		//on the bright side it is probably way faster
		using (FileStream fs = new FileStream(Application.persistentDataPath + "\\save.tt", FileMode.Create))
		{
			var writer = new BinaryWriter(fs);
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

	void LoadSaveData()
	{
		try
		{
			using (FileStream fs = new FileStream(Application.persistentDataPath + "/save.tt", FileMode.Open))
			{
				SaveData newSaveData = new SaveData();
				var reader = new BinaryReader(fs);

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
		}
	}

	public void ResetScene(bool callDelegate = true)
	{
		for (int i = 0; i < savedHealths.Count; i++)
		{
			savedHealths[i].ResetTo(saveData.savedHealths[i]);
		}
		for (int i = 0; i < savedHealths.Count; i++)
		{
			saveables[i].SetToState(saveData.saveableStates[i]);
		}
		GameManager.Instance.CalculateCurrentDissolverCount();
		checkpointIndex = saveData.checkpointIndex;
		
		if (onResetScene != null && callDelegate)
			onResetScene.Invoke(); 
	}

	public void ClearSaveData()
	{
		saveData = new SaveData();
		saveData.checkpointIndex = -1;
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
		if (File.Exists(Application.persistentDataPath + "/save.tt"))
			File.Delete(Application.persistentDataPath + "/save.tt");
	}

	public SaveData GetSaveData() { return saveData; }

	public class SaveData
	{
		public int checkpointIndex;
		public float[] savedHealths;
		public bool[] saveableStates;
	}
}
