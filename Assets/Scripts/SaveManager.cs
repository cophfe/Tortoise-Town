using System.Collections;
using System.Collections.Generic;
using System;
using System.IO;
using UnityEngine;

public class SaveManager
{
	int checkpointIndex = -1;
	List<Checkpoint> checkpoints = new List<Checkpoint>();
	List<GooDissolve> gooDissolvers = new List<GooDissolve>();
	SaveData saveData = null;

	public void RegisterCheckpoint(Checkpoint checkpoint)
	{
		checkpoints.Add(checkpoint);
	}

	public void RegisterGooDissolver(GooDissolve gooDissolve)
	{
		gooDissolvers.Add(gooDissolve);
	}

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

		gooDissolvers.Sort(func);
		checkpoints.Sort(func);
		if (Application.isEditor)
			ClearSaveData();
		else
			LoadSaveData();
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
		saveData.currentCheckpointIndex = checkpointIndex;
		saveData.gooDissolverStates = new bool[gooDissolvers.Count];
		for (int i = 0; i < gooDissolvers.Count; i++)
		{
			saveData.gooDissolverStates[i] = gooDissolvers[i].Dissolved;
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
			writer.Write(saveData.currentCheckpointIndex);
			writer.Write(saveData.gooDissolverStates.Length);
			for (int i = 0; i < saveData.gooDissolverStates.Length; i++)
			{
				writer.Write(gooDissolvers[i].Dissolved);
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

				newSaveData.currentCheckpointIndex = reader.ReadInt32();
				newSaveData.gooDissolverStates = new bool[reader.ReadInt32()];
				for (int i = 0; i < newSaveData.gooDissolverStates.Length; i++)
				{
					newSaveData.gooDissolverStates[i] = reader.ReadBoolean();
				}
				saveData = newSaveData;
			}
		}
		catch (Exception e)
		{
			Debug.LogWarning("Failed to load save data:\n" 
				+ e.Message 
				+"\nResetting save data to default state...");
			ClearSaveData();
		}
		
	}

	public void SetSceneFromSaveData()
	{
		for (int i = 0; i < gooDissolvers.Count; i++)
		{
			if (saveData.gooDissolverStates[i])
				gooDissolvers[i].SetAlreadyDissolved();
			else
				gooDissolvers[i].ResetDissolve();

		}
		checkpointIndex = saveData.currentCheckpointIndex;
	}

	public void ClearSaveData()
	{
		saveData = new SaveData();
		saveData.currentCheckpointIndex = -1;
		saveData.gooDissolverStates = new bool[gooDissolvers.Count];
		WriteSaveData();
	}

	public SaveData GetSaveData() { return saveData; }

	public class SaveData
	{
		public int currentCheckpointIndex;
		public bool[] gooDissolverStates;
	}
}
