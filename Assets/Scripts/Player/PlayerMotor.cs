using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Rigidbody), typeof(CapsuleCollider))]
public class PlayerMotor : MonoBehaviour
{
	//references
	new CapsuleCollider collider;
	new Rigidbody rigidbody;
	
	//movement 
	[Tooltip("Step Height as a percentage of capsule height")]
	[Range(0,1)]public float stepHeightPercent = 0.1f;

	//colliderz
	public float colliderHeight = 2;
	public float colliderRadius = 0.5f;

	//ground detection 
	[SerializeField] bool isGrounded = false;
	[Range(0, 1)] public float groundDetectionModifier = 0.8f;
	public LayerMask ignoredGround;
	Vector3 groundPosition;
	Vector3 groundNormal;
	float groundDistance;
	
	//useful for 'sticking' to ground when grounded, but not sticking when jumping
	public bool extendGroundDetection = false;
	[Range(0, 1)] public float extendGroundDetectionModifier = 0.5f;

	//makes player stay on ground when constantly AND makes 'stepping' work
	[SerializeField] Vector3 groundAvoidanceVelocity;

	void Awake()
    {
		rigidbody = GetComponent<Rigidbody>();
		collider = GetComponent<CapsuleCollider>();
		collider.height = colliderHeight * (1 - stepHeightPercent);
		collider.radius = colliderRadius;
		collider.center = Vector2.up * (colliderHeight/2 + stepHeightPercent * colliderHeight / 2);
    }

	private void OnValidate()
	{
		Awake();
	}

	public bool DetectedGround()
	{
		return isGrounded;
	}

	public void ScanForGround()
	{
		//THERE ARE CURRENTLY PROBLEMS WITH THIS APPROACH
		//resources for fix:
		//http://thehiddensignal.com/unity-angle-of-sloped-ground-under-player/
		//https://forum.unity.com/threads/some-pitfalls-of-an-accurate-groundedness-check.619564/

		Vector3 direction = -transform.up;
		Vector3 origin = transform.TransformPoint(collider.center);
		float radius = collider.radius * groundDetectionModifier * transform.localScale.x;
		float length = collider.center.y + (extendGroundDetection ? 2 * extendGroundDetectionModifier * radius : 0);

		if (Physics.SphereCast(origin, radius, direction, out RaycastHit hit, length - radius, ~ignoredGround.value))
		{
			groundPosition = hit.point;
			groundDistance = hit.distance + radius;// Mathf.Abs(Vector3.Dot(groundPosition - origin, direction));
			isGrounded = true;
			groundAvoidanceVelocity = transform.up * ((collider.center.y - groundDistance) / Time.fixedDeltaTime);

			//the problem with spherecast is the hit normal is not always equal to the surface normal
			//this causes a bunch of annoying behaviour
			//so a raycast is performed towards the hit point to find the surface normal
			if (hit.collider.Raycast(new Ray(hit.point - direction, direction), out hit, 10) && Vector3.Angle(hit.normal, -direction) < 89.5f)
			{
				groundNormal = hit.normal;
			}
		}
		else
		{
			groundAvoidanceVelocity = Vector3.zero;
			isGrounded = false;
		}
	}

	public Vector3 RigidbodyVelocity
	{
		set
		{
			rigidbody.velocity = value + groundAvoidanceVelocity;
		}
	}

	public Vector3 GroundNormal { get { return groundNormal; } }
	public Vector3 GroundPosition { get { return groundPosition; } }
	public float GroundDistance { get { return groundDistance; } }
}
