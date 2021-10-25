using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

public class TriggerEvent : MonoBehaviour
{
   public UnityEvent triggerEvent;

    void Start()
    {
        if (triggerEvent == null)
            triggerEvent = new UnityEvent();

        triggerEvent.AddListener(Ping);
    }


    private void OnTriggerEnter(Collider other)
    {
        if (other.transform.tag == "Player")
        {
            triggerEvent.Invoke();
        }
    }

    void Ping()
    {
        Debug.Log("Ping");
    }
}
