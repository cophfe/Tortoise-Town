using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class ReloadChecker : MonoBehaviour
{
	private void Awake()
	{
		Debug.Log("Scene called Awake (scene " + SceneManager.GetActiveScene().buildIndex + ")");
	}

	private void OnDestroy()
	{
		Debug.Log("Scene called OnDestroy (scene " + SceneManager.GetActiveScene().buildIndex + ")");
	}
}
