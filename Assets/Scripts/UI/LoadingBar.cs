using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.SceneManagement;

public class LoadingBar : MonoBehaviour
{
	public Animator loadAnimation;
	public Image loadBar;
	public GameObject loadingStuff;
	public float loadFadeTime = 1;
	public float loadBarTime = 0.1f;

	public IEnumerator LoadLevel(string name)
	{
		if (loadAnimation == null || loadBar == null)
			yield break;

		loadAnimation.SetBool("FadeIn", true);
		yield return new WaitForSeconds(loadFadeTime);
		SceneManager.LoadScene(name);

		//loadAnimation.updateMode = AnimatorUpdateMode.UnscaledTime;
		//loadAnimation.SetTrigger("Load");
		//loadingStuff.SetActive(true);
		//yield return new WaitForSeconds(loadBarTime);
		//AsyncOperation operation = SceneManager.LoadSceneAsync(name);
		////operation.allowSceneActivation = false;

		//while (!operation.isDone)
		//{
		//	loadBar.fillAmount = Mathf.Clamp01(operation.progress / 0.9f);
		//	Debug.Log(loadBar.fillAmount);

		//	//if (operation.progress >= 0.9f)
		//	//{
		//	//	operation.allowSceneActivation = true;
		//	//}
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
