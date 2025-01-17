﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Arrow : Poolable
{
	protected ArrowData data;
	protected Vector3 velocity = Vector3.zero;
	protected float disappearTimer = float.MaxValue;
	protected bool shooting = false;
	TrailRenderer trailRenderer;
	MeshRenderer meshRenderer;
	float trailTime;
	NewArrowPortalTraveller pTraveller;
	public Vector3 Velocity { get => velocity; set => velocity = value; }

	public override bool BeforeReset()
	{
		enabled = true;
		disappearTimer = 0;
		shooting = false;

		return base.BeforeReset();
	}

	public override void OnReset()
	{
		transform.localScale = Vector3.one;
		enabled = false;
		meshRenderer.enabled = true;

		if (trailRenderer)
		{
			trailRenderer.Clear();
			trailRenderer.emitting = false;
		}
		if (pTraveller)
		{
			pTraveller.enabled = false;

		}

	}

	private void Awake()
	{
		pTraveller = GetComponent<NewArrowPortalTraveller>();

		meshRenderer = GetComponentInChildren<MeshRenderer>();
		enabled = false;
		trailRenderer = GetComponent<TrailRenderer>();
		if (trailRenderer)
		{
			trailTime = trailRenderer.time; 
			trailRenderer.emitting = false;
		}
	}

	public void Shoot(Vector3 initialVelocity, ArrowData data)
	{
		enabled = true;
		shooting = true;
		this.data = data;
		transform.forward = initialVelocity;
		velocity = initialVelocity;
		
		if (trailRenderer)
		{
			trailRenderer.Clear();
			trailRenderer.emitting = true;
			trailRenderer.time = trailTime;
		}
		if (pTraveller)
			pTraveller.enabled = false;
		if (pTraveller)
			pTraveller.enabled = true;
	}

	public void SetRendering(bool rendering)
	{
		meshRenderer.enabled = rendering;
	}
	void FixedUpdate()   
    {
		if (shooting)
		{
			//gravity
			velocity -= Vector3.up * data.gravity * Time.deltaTime;

			float vMag = velocity.magnitude;
			Vector3 vDirection = velocity / vMag;
			transform.forward = Vector3.RotateTowards(transform.forward, vDirection, Time.deltaTime * data.rotateSpeed, 0);

			//detect collisions
			if (Physics.CapsuleCast(transform.position - transform.forward * data.arrowLength / 2, transform.position + transform.forward * data.arrowLength / 2, data.radius, vDirection, out var hit, vMag * Time.deltaTime, ~data.ignoreCollisionLayers, QueryTriggerInteraction.Ignore))
			{
				enabled = false;
				transform.position = hit.point - transform.forward * (data.arrowLength / 2 * data.arrowPenetratePercent);
				

				var health = hit.transform.GetComponent<Health>();
				if (health)
				{
					transform.parent = hit.transform;
					health.Damage(data.damage);
				}
				else if (hit.transform.GetComponent<Rigidbody>())
					transform.parent = hit.transform;


				if (trailRenderer)
				{
					trailRenderer.emitting = false;
					trailRenderer.time = trailTime * 0.8f;
				}

				OnCollide(hit.collider);
			}
			else
			{
				transform.position += velocity * Time.deltaTime;
			}
		}
    }

	protected virtual void OnCollide(Collider collider)
	{

	}
	private void Update()
	{
		if (!shooting)
		{
			disappearTimer += Time.deltaTime;
			if (disappearTimer < data.disappearTime)
			{
				transform.localScale = Vector3.one * Ease.EaseInQuad((1 - disappearTimer / data.disappearTime));
			}
			else
			{
				gameObject.SetActive(false);
			}
		}
	}

	Vector3 GetTipPos()
	{
		return transform.position + transform.forward * ((data.arrowLength / 2 + data.radius) * (1-data.arrowPenetratePercent));
	}

	void OnDrawGizmosSelected()
	{
		if (!data) return;
		Gizmos.color = new Color(0, 0.8f, 0.1f, 0.8f);
		Gizmos.matrix = Matrix4x4.TRS(transform.position, transform.rotation, transform.lossyScale);
		Vector3 circleCentre1 = Vector3.forward * data.arrowLength / 2;
		Vector3 circleCentre2 = -Vector3.forward * data.arrowLength / 2;
		Gizmos.DrawWireSphere(circleCentre1, data.radius);
		Gizmos.DrawWireSphere(circleCentre2, data.radius);
		Gizmos.DrawLine(circleCentre1 + Vector3.up * data.radius, circleCentre2 + Vector3.up * data.radius);
		Gizmos.DrawLine(circleCentre1 - Vector3.up * data.radius, circleCentre2 - Vector3.up * data.radius);
		Gizmos.DrawLine(circleCentre1 + Vector3.right * data.radius, circleCentre2 + Vector3.right * data.radius);
		Gizmos.DrawLine(circleCentre1 - Vector3.right * data.radius, circleCentre2 - Vector3.right * data.radius);
	}
}
