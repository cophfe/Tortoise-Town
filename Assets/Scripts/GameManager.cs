using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GameManager : MonoBehaviour
{
	public bool enableCursorRestriction = false;
	
    void Start()
    {
		IsCursorRestricted = true;
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
