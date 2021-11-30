using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "OtherAudioData", menuName = "ScriptableObjects/OtherAudioData", order = 1)]

public class OtherAudioData : ScriptableObject
{
	public AudioClipList targetPopSounds;
	public AudioClipList lastBreath;
	public AudioClipList chime;
}