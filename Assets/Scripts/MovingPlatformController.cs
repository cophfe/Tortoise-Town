using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MovingPlatformController : MonoBehaviour
{
	public float stopTime = 0;
	public float speed = 5;
	Vector3 startPosition;
	//relative to startPosition
	public Vector3[] points;
	public bool loop = false;
	public EaseMode ease = EaseMode.NONE;

	public enum EaseMode
	{
		NONE,
		INOUT
	}

	void Start()
    {
		startPosition = transform.position;
	}

    void Update()
    {
        
    }
}
