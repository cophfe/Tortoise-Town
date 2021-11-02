using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "GooDissolveData", menuName = "ScriptableObjects/GooDissolveData", order = 1)]

public class GooDissolveData : ScriptableObject
{
	public Shader dissolveShader = null;
	public Shader vineShader = null;
	public float dissolveSpeed = 10;
	public bool easeIn = true;
}
