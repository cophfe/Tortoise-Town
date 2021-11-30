using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.SceneManagement;

public class LoadingBar : MonoBehaviour
{
	public Animator loadAnimation;
	public GameObject loadingStuff;
	public float loadFadeTime = 1;
	public float loadBarTime = 0.1f;

	public IEnumerator LoadLevel(string name)
	{
		if (loadAnimation == null)
			yield break;

		loadAnimation.SetBool("FadeIn", true);
		yield return new WaitForSeconds(loadFadeTime);
		SceneManager.LoadScene(name);

		//loadAnimation.updateMode = AnimatorUpdateMode.UnscaledTime;
		//loadAnimation.SetTrigger("Load");
		//loadingStuff.SetActive(true);
		//AsyncOperation operation = SceneManager.LoadSceneAsync(name);
		////operation.allowSceneActivation = false;

		//while (!operation.isDone)
		//{
		//	Debug.Log(operation.progress);
		//	yield return null;
		//}
	}

	public IEnumerator RestartLevel(string name)
	{
		if (loadAnimation == null)
			yield break;

		loadAnimation.SetBool("FadeIn", true);
		yield return new WaitForSeconds(loadFadeTime);
		Time.timeScale = 1;
		GameManager.Instance.SaveManager.ClearSaveData();
		GameManager.Instance.ReloadScene();
		SceneManager.LoadScene(name);

		//loadAnimation.updateMode = AnimatorUpdateMode.UnscaledTime;
		//loadAnimation.SetTrigger("Load");
		//loadingStuff.SetActive(true);
		//AsyncOperation operation = SceneManager.LoadSceneAsync(name);
		////operation.allowSceneActivation = false;

		//while (!operation.isDone)
		//{
		//	Debug.Log(operation.progress);
		//	yield return null;
		//}


	}


	public IEnumerator LoadLevelWithoutLoadBar(string name)
	{
		loadAnimation.SetBool("FadeIn", false);
		yield return new WaitForSeconds(loadFadeTime);
		SceneManager.LoadScene(name);
	}
}
