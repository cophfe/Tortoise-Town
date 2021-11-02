using System.Collections;
using UnityEngine;
using UnityEngine.SceneManagement;
#if UNITY_EDITOR
using UnityEditor;
#endif

public class MainMenuUI : MonoBehaviour
{
	public string gameplaySceneName = "Main";
	public Animator panel = null;
	public float fadeTime = 1;

	public void OnPlayButtonPressed()
	{
		StartCoroutine(LoadGame());
	}

	IEnumerator LoadGame()
	{
		panel.SetBool("FadeIn", true);
		yield return new WaitForSeconds(fadeTime);

		try
		{
			SceneManager.LoadScene(gameplaySceneName);
		}
		catch (System.Exception e)
		{
			Debug.LogWarning("Error loading scene:\n" + e.Message);
		}
	}

	public void OnExitButtonPressed()
	{
		StartCoroutine(ExitGame());
	}
	
	IEnumerator ExitGame()
	{
		panel.SetBool("FadeIn", true);
		yield return new WaitForSeconds(fadeTime);
#if UNITY_EDITOR
		EditorApplication.isPlaying = false;
#else
		Application.Quit();
#endif
	}
	
}
