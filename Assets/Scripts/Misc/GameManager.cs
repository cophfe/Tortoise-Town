using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GameManager : MonoBehaviour
{
	public bool enableCursorRestriction = false;
	public int targetFrameRate = -1;

	[Header("Arrow Pool")]
	[Tooltip("The poolable component attached to the arrow prefab")]
	public Poolable arrowPrefab;
	[Tooltip("The amount of arrows in the pool")]
	public int arrowPoolAmount = 20;
	[Tooltip("Used to give arrows time to fade away")]
	public int arrowPoolNotifyDistance = 4;

	public ObjectPool ArrowPool { get; private set; }
    void Awake()
    {
		IsCursorRestricted = true;
		ArrowPool = new ObjectPool(arrowPoolAmount, arrowPoolNotifyDistance, arrowPrefab, transform);
		Application.targetFrameRate = targetFrameRate;
	}

	private void OnValidate()
	{
		if (Application.isPlaying)
			Application.targetFrameRate = targetFrameRate;
	}

	public bool IsCursorRestricted
	{
		get
		{
			return Cursor.lockState == CursorLockMode.Locked;
		}
		set
		{
			if (value && enableCursorRestriction)
			{
				Cursor.lockState = CursorLockMode.Locked;
				Cursor.visible = false;
			}
			else
			{
				Cursor.lockState = CursorLockMode.None;
				Cursor.visible = true;
			}
		}
	}
}
