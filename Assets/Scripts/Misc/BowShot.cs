 using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;
public class BowShot : MonoBehaviour
{

    public ArrowPhysics arrowphysio;
    public Transform ArrowPos;
    public GameObject Arrow;
    public InputMaster controls;
    public float ArrowCharge = 0f;
    public float Begincharge = 0;
    public bool Charging = false;
    public float Speed = 0f;
    public float DamageIncre = 0f;
    public Transform ArrowLocation;
    // Start is called before the first frame update



    void Awake()
    {
        controls = new InputMaster();
        controls.Player.Enable();
        //controls.Player.Bow.performed += ctx => Begincharge = 1;
        //controls.Player.Bow.canceled += ctx => Begincharge = 0;
        arrowphysio = ArrowLocation.GetComponent<ArrowPhysics>();
    }

    
    // Update is called once per frame
    void Update()
    {
        if (Begincharge > 0)
        {
            ArrowCharge += Time.deltaTime;

        }
        if (ArrowCharge > 0.5)
        {
            Charging = true;


            if (Charging == true)
            {
                Speed += 100f;
                DamageIncre += 10f;
                ArrowCharge = 0f;

                Charging = false;
            }
        }
        if (Speed >= 1500)
        {
            Speed = 1500;
        }

        if (Speed >= 100)
        {



            if (Begincharge <= 0)
            {


                GameObject ArrowInstat = Instantiate(Arrow, ArrowPos.transform.position, Quaternion.identity) as GameObject;
                // ArrowInstat = ArrowRB.AddForce(ArrowPos.forward * 500f);
                // ArrowRB.AddForce(ArrowPos.forward * 500f);


                ArrowInstat.GetComponent<Rigidbody>().AddForce(transform.forward * Speed);
                arrowphysio.DamageMultiplier(DamageIncre);

                Speed = 0f;
                DamageIncre = 0f;
            }
        }
    }

}




