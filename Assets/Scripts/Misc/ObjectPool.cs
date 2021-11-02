using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;

public class ObjectPool
{
	//Poolable objectPrefab;
	int amount;
	int notifyDistance;
	Transform poolParent;

	List<Poolable> pool;

	int currentIndex = 0;
	public ObjectPool(int amount, int notifyDistance, Poolable objectPrefab, Transform poolParent = null)
	{
		this.notifyDistance = notifyDistance;
		this.amount = amount;
		this.poolParent = poolParent;

		pool = new List<Poolable>(amount);

		for (int i = 0; i < amount; i++)
		{
			pool.Add(GameObject.Instantiate(objectPrefab.gameObject, poolParent).GetComponent<Poolable>());
			pool[i].gameObject.SetActive(false);
		}
	}
	public Poolable GetPooledObject(Transform parent = null)
	{
		//setup pool object
		pool[currentIndex].transform.parent = parent;
		pool[currentIndex].transform.SetPositionAndRotation(Vector3.zero, Quaternion.identity);
		pool[currentIndex].gameObject.SetActive(true);
		pool[currentIndex].OnReset();

		int notifyIndex;
		int returnedIndex = currentIndex;
		int initialNextIndex = (currentIndex + 1) % amount;
		currentIndex = initialNextIndex;
		
		//check for the next index that doesn't want to be ignored
		while (pool[currentIndex].ignoredInPool)
		{
			//overload ignore after looping through entire array
			if (initialNextIndex == currentIndex)
			{
				currentIndex = initialNextIndex;
				pool[currentIndex].ignoredInPool = false;
				break;
			}
			currentIndex = (currentIndex + 1) % amount;
		}

		notifyIndex = (currentIndex + notifyDistance - 1) % amount;
		if (notifyDistance != 0 && notifyIndex != returnedIndex && pool[notifyIndex].gameObject.activeSelf)
		{
			pool[notifyIndex].BeforeReset();
		}

		return pool[returnedIndex];
	}

	public void ReturnPooledObject(Poolable poolable)
	{
		poolable.ignoredInPool = false;
		poolable.transform.parent = poolParent;
		poolable.gameObject.SetActive(false);
	}

	public void ResetToDefault()
	{
		//Reset everything to how it was right after creation
		for (int i = 0; i < pool.Count; i++)
		{
			ReturnPooledObject(pool[i]);
		}
		currentIndex = 0;
	}
}
