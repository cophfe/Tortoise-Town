using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ArrowPhysics : MonoBehaviour
{ 
    public Rigidbody ArrowRB;
    public float EnemyDamage = 20f;
    private EnemyHealth enemyhealther;
    public float Damage = 0f;
    public bool Kim = false;
    public SphereCollider ArrowSC;
    // Start is called before the first frame update
    void Start()
    {
        ArrowRB = GetComponent<Rigidbody>();
    }

    // Update is called once per frame
    void Update()
    {

        //Vector3 Rotation = ArrowRB.velocity;

        //float angle = Mathf.Atan2(Rotation.y, Rotation.x) * Mathf.Rad2Deg;
        ///  transform.LookAt(transform.position, ArrowRB.velocity);
        if (Kim == true)
        {
            ArrowSC.enabled = false;
        }


    }

    public void DamageMultiplier(float amount)
    {
        Damage += amount;
    }


    private void OnCollisionEnter(Collision collision)
    {
        if (collision.transform.CompareTag("Enemy"))
        {
           // enemyhealther = collision.gameObject.GetComponentInParent<EnemyHealth>();
            Debug.Log("We hit Enemy");
           // enemyhealther.EnemyDamaged(Damage);
        }
        Damage = 0f;
        ArrowRB.constraints = RigidbodyConstraints.FreezeAll;
        Kim = true;


    }

}


