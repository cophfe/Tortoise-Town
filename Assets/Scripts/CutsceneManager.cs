using Cinemachine;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.Playables;

[RequireComponent(typeof(PlayableDirector)), DefaultExecutionOrder(1000)]
public class CutsceneManager : BooleanSwitch
{
	PlayableDirector director;
	bool ended = false;
	public Camera cutsceneCamera;
	public bool goBackOnStop = true;
	public UnityEvent onStartCutscene;
	public UnityEvent onEndCutscene;
	public UnityEventTime[] timedEvents;
	bool playing = false;

	[System.Serializable]
	public class UnityEventTime
	{
		public float time;
		public UnityEvent @event;
		[System.NonSerialized] public bool played = false;
	}

	private void OnValidate()
	{
		if (!director)
			director = GetComponent<PlayableDirector>();

		foreach (var e in timedEvents)
		{
			if (e != null && e.time > director.duration)
			{
				e.time = (float)director.duration;
			}
		}
	}
	private void Awake()
	{
		director = GetComponent<PlayableDirector>();
		cutsceneCamera.enabled = false;
		cutsceneCamera.GetComponent<AudioListener>().enabled = false;
		cutsceneCamera.GetComponent<CinemachineBrain>().enabled = false;
		director.played += d => { playing = true; };
		director.stopped += d => { playing = false; };
	}

	private void Update()
	{
		if (playing)
		{
			double time = director.time;

			foreach (var e in timedEvents)
			{
				if (e != null && !e.played && time >= e.time)
				{
					e.played = true;
					e.@event?.Invoke();
				}
			}
		}
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
		foreach (var e in timedEvents)
		{
			if (e != null)
				e.played = false;
		}

		gameObject.SetActive(true);
		var gm = GameManager.Instance;
		gm.InCutscene = true;
		gm.Player.MainCamera.GetComponent<AudioListener>().enabled = false;
		gm.Player.MainCamera.GetComponent<Camera>().enabled = false;
		gm.Player.gameObject.SetActive(false);
		director.Play();
		director.time = 0;
		cutsceneCamera.enabled = true;
		cutsceneCamera.GetComponent<AudioListener>().enabled = true;
		cutsceneCamera.GetComponent<CinemachineBrain>().enabled = true;
		director.stopped += OnCutsceneEnded;
		GameManager.Instance.GUI.onCutsceneSkipped += SwitchFalse;
		onStartCutscene?.Invoke();
		

		ended = false;
	}

	public void OnCutsceneEnded(PlayableDirector obj)
	{
		if (goBackOnStop)
			Switch(false);
		else
			onEndCutscene?.Invoke();
	}

	private void EndCutscene()
	{
		if (!ended)
		{
			ended = true;
			if (GameManager.Instance && gameObject.activeInHierarchy)
			{
				GameManager.Instance.GUI.onCutsceneSkipped -= SwitchFalse;
				StartCoroutine(GameManager.Instance.GUI.EndCutscene(this));
			}
		}
	}

	public void OnCompleteStop()
	{
		gameObject.SetActive(false);
		cutsceneCamera.enabled = false;
		cutsceneCamera.GetComponent<AudioListener>().enabled = false;
		cutsceneCamera.GetComponent<CinemachineBrain>().enabled = false;
		var gm = GameManager.Instance;
		gm.Player.MainCamera.GetComponent<AudioListener>().enabled = true;
		gm.Player.MainCamera.GetComponent<Camera>().enabled = true;
		gm.Player.gameObject.SetActive(true);
		if (goBackOnStop)
			onEndCutscene?.Invoke();
	}

	void SwitchFalse()
	{
		OnCutsceneEnded(null);
	}

	public override void ResetSwitchTo(bool on)
	{
		throw new System.NotImplementedException();
	}
}
