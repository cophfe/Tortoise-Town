using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Audio;

[CreateAssetMenu(fileName = "PlayerAudioData", menuName = "ScriptableObjects/PlayerAudioData", order = 1)]

public class PlayerAudioData : ScriptableObject
{
	[Header("Movement")]
	public AudioClipList jumpSounds;
	//public AudioClip[] footstepSounds;
	//public AudioClip[] hitWall;
	public AudioClipList dash;
	public AudioClipList land;
	

	[Header("Rolling")]
	public AudioClipList rollTuck;
	public AudioClipList rollPop;
	public AudioClipList jumpRollPop;
	public AudioClipList ballRoll;
	public AudioClipList hitWallRolling;
	public AudioClipList ballBounce;
	
	[Header("Combat")]
	public AudioClipList arrowCharge;
	public AudioClipList arrowShoot;
	
	[Header("Health")]
	//public AudioClip[] hit;
	public AudioClipList death;
}

[System.Serializable]
public class AudioClipList
{
	public AudioClip[] clips;

	public bool CanBePlayed()
	{
		return clips != null && clips.Length > 0;
	}
	public AudioClip GetRandom()
	{
		if (clips == null || clips.Length == 0) return null;
		return clips[Random.Range(0, clips.Length)];
	}
}
