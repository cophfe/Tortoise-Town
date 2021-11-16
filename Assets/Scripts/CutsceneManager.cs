using Cinemachine;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Playables;

[RequireComponent(typeof(PlayableDirector)), DefaultExecutionOrder(1000)]
public class CutsceneManager : BooleanSwitch
{
	PlayableDirector director;
	bool ended = false;
	public Camera cutsceneCamera;

	private void Awake()
	{
		director = GetComponent<PlayableDirector>();
		cutsceneCamera.enabled = false;
		cutsceneCamera.GetComponent<AudioListener>().enabled = false;
		cutsceneCamera.GetComponent<CinemachineBrain>().enabled = false;
	}

	public override bool SwitchValue { get => base.SwitchValue; 
		protected set 
		{
			if (on == value) return;

			if (value)
			{
				StartCutscene();
			}
			else
			{
				EndCutscene();
			}
			on = value;
		} }

	protected override void Start()
	{
		base.Start();
	}

	private void StartCutscene()
	{
		GameManager.Instance.InCutscene = true;
		director.Play();
		director.time = 0;
		cutsceneCamera.enabled = true;
		cutsceneCamera.GetComponent<AudioListener>().enabled = true;
		cutsceneCamera.GetComponent<CinemachineBrain>().enabled = true;
		director.stopped += Director_stopped;
		GameManager.Instance.GUI.onCutsceneSkipped += SwitchFalse;

		ended = false;
	}

	private void Director_stopped(PlayableDirector obj)
	{
		Switch(false);
	}

	private void EndCutscene()
	{
		if (!ended)
		{
			ended = true;
			GameManager.Instance.GUI.onCutsceneSkipped -= SwitchFalse;
			StartCoroutine(GameManager.Instance.GUI.EndCutscene(this));
		}
	}

	public void OnCompleteStop()
	{
		gameObject.SetActive(false);
		cutsceneCamera.enabled = false;
		cutsceneCamera.GetComponent<AudioListener>().enabled = false;
		cutsceneCamera.GetComponent<CinemachineBrain>().enabled = false;
	}

	void SwitchFalse()
	{
		Switch(false);
	}

	public override void ResetSwitchTo(bool on)
	{
		throw new System.NotImplementedException();
	}
}
