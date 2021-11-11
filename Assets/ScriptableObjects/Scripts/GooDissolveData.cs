using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "GooDissolveData", menuName = "ScriptableObjects/GooDissolveData", order = 1)]

public class GooDissolveData : ScriptableObject
{
	public Shader[] dissolveShader = null;
	public bool easeIn = true;
}
