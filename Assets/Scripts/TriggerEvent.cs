using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

public class TriggerEvent : MonoBehaviour
{
   public UnityEvent triggerEvent;
    public string triggerTag;
    void Start()
    {
        if (triggerEvent == null)
            triggerEvent = new UnityEvent();

        triggerEvent.AddListener(Ping);
    }


    private void OnTriggerEnter(Collider other)
    {
    
        if (other.transform.tag == triggerTag)
        {
            triggerEvent.Invoke();
        }
    }

    void Ping()
    {
        Debug.Log("Ping");
    }
}
