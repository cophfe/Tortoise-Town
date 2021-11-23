using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

//this is made from a tutorial found here: https://danielilett.com/2019-12-01-tut4-intro-portals/

public class PortalRenderer : BooleanSwitch
{
	public Portal[] portals = new Portal[2];
	public Camera mainCamera;
	bool firstPortalActive = true;
	Camera portalCamera;
	public LayerMask portalLayer;
	RenderTexture portalTexture;
	Matrix4x4 defaultMatrix;
	CameraPortalTraveller cameraTraveller;
	bool cameraWithPlayer = true;
	bool playerInFirstPortal = true;
	bool cameraJustTeleported = false;
	Portal lastTeleportedThroughPortal;
	private void Awake()
	{
		if (!mainCamera)
			mainCamera = Camera.main;
		cameraTraveller = mainCamera.GetComponent<CameraPortalTraveller>();

		defaultMatrix = mainCamera.projectionMatrix;
		portalCamera = GetComponent<Camera>();
		portalCamera.cullingMask = ~portalLayer;
		portalTexture = new RenderTexture(Screen.width, Screen.height, 24, RenderTextureFormat.ARGB32);
	}

	void Start()
    {
		portals[0].Renderer.material.mainTexture = portalTexture;
		portals[1].Renderer.material.mainTexture = portalTexture;
		portalCamera.targetTexture = portalTexture;
	}

	private void OnEnable()
	{
		RenderPipelineManager.beginCameraRendering += UpdateCamera;
		RenderPipelineManager.endCameraRendering += EndCameraRender;
	}

	private void OnDisable()
	{
		RenderPipelineManager.beginCameraRendering -= UpdateCamera;
		RenderPipelineManager.endCameraRendering -= EndCameraRender;
	}

	private void UpdateCamera(ScriptableRenderContext context, Camera camera)
	{
		if (!portals[0].open || !portals[1].open) return;
		
		if (firstPortalActive)
		{
			RenderCamera(portals[0], portals[1], context);
		}
		else
		{
			RenderCamera(portals[1], portals[0], context);
		}

	}

	void RenderCamera(Portal inPortal, Portal outPortal, ScriptableRenderContext context)
	{
		Camera c1;
		Camera c2;
		Vector3 pos;
		Quaternion rot;
		Portal p1;
		Portal p2;
		float negateRBZ;

		//travel objects before rendering
		//this will be reverted after rendering, except for objects that are perminantly staying on the other side
		lastTeleportedThroughPortal = inPortal;
		
		inPortal.TravelTravellers(outPortal);
		//if (cameraTraveller.CheckIfWillCompleteTeleport(inPortal))
		//{
		//	OnCameraThroughPortal();
		//}
		//cameraTraveller.tempMovedThisTime = false;

		if (cameraWithPlayer)
		{
			negateRBZ = 1;
			c1 = mainCamera;
			c2 = portalCamera;
			p1 = inPortal;
			p2 = outPortal;
			//get position relative to out portal
			pos = p1.TransformPositionToOtherPortal(p2, mainCamera.transform.position);
			rot = p1.TransformRotationToOtherPortal(p2, mainCamera.transform.rotation);
		}
		else
		{
			negateRBZ = -1;
			c1 = portalCamera;
			c2 = mainCamera;
			p1 = outPortal;
			p2 = inPortal;
			//get position relative to in portal
			pos = outPortal.TransformPositionToOtherPortal(inPortal, mainCamera.transform.position);
			rot = outPortal.TransformRotationToOtherPortal(inPortal, mainCamera.transform.rotation);
		}
		transform.SetPositionAndRotation(pos, rot);

		//now set camera frustram to make the near clip plane the same as the portal plane 
		//this has ramifications if the player can see long distances but whatever who cares
		float sign = Mathf.Sign(Vector3.Dot(mainCamera.transform.position - p1.transform.position, p1.transform.forward));
		Vector3 normal = sign * p2.transform.forward;
		Vector4 nearPlane = new Vector4(normal.x, normal.y, normal.z, -Vector3.Dot(normal, p2.transform.position));
		Vector4 nearPlaneCamera = Matrix4x4.Transpose(Matrix4x4.Inverse(portalCamera.worldToCameraMatrix)) * nearPlane;
		c2.projectionMatrix = mainCamera.CalculateObliqueMatrix(nearPlaneCamera);
		c1.projectionMatrix = defaultMatrix;

		//also set position of render box for super smooth rendering reasons
		negateRBZ *= sign;
		Transform rB = inPortal.GetRenderBox();
		Vector3 rBPos = rB.localPosition;
		rBPos.z = -negateRBZ * Mathf.Abs(rBPos.z);
		rB.localPosition = rBPos;
		rB = outPortal.GetRenderBox();
		rBPos = rB.localPosition;
		rBPos.z = -negateRBZ * Mathf.Abs(rBPos.z);
		rB.localPosition = rBPos;

		
		
		UniversalRenderPipeline.RenderSingleCamera(context, c2);
		//this will undo the moving of objects through the portal
		inPortal.UndoTravel(outPortal);
		CheckForCamera();

		lastTeleportedThroughPortal = outPortal;
		outPortal.TravelTravellers(inPortal);
	}

	void EndCameraRender(ScriptableRenderContext context, Camera camera)
	{
		if (firstPortalActive)
		{
			portals[0].RevertJustTravelled(portals[1]);
			portals[1].UndoTravel(portals[0]);
		}
		else if (!firstPortalActive)
		{
			portals[1].RevertJustTravelled(portals[0]);
			portals[0].UndoTravel(portals[1]);
		}
	}

	public void OnPlayerThroughPortal()
	{


		Debug.Log("Player teleporting");
		//if the player is going to be joining the camera that is already on the other side
		if (playerInFirstPortal == firstPortalActive)
		{
			if (cameraWithPlayer)
			{

				playerInFirstPortal = lastTeleportedThroughPortal != portals[0];
				cameraWithPlayer = false;
				OnSwitchCamera();

			}
			else
			{
				if (cameraState != -1)
				{
					portals[cameraState].GetTravellers().Remove(cameraTraveller);
					//portals[cameraState].travIndex--;
				}
				cameraWithPlayer = true;
				playerInFirstPortal = lastTeleportedThroughPortal != portals[0];
				cameraState = -1;
				OnSwitchCamera();
			}
				
		}
		else
		{
			playerInFirstPortal = lastTeleportedThroughPortal != portals[0];
			cameraWithPlayer = playerInFirstPortal == firstPortalActive;
			if (cameraState != -1)
			{
				portals[cameraState].GetTravellers().Remove(cameraTraveller);
				//portals[cameraState].travIndex--;
			}
			cameraState = cameraWithPlayer ? -1  : firstPortalActive ? 0 : 1;
			OnSwitchCamera();
		}
		

		//if (!portals[cameraState].GetTravellers().Contains(cameraTraveller))
		//	portals[cameraState].GetTravellers().Add(cameraTraveller);


		//if (playerInFirstPortal == firstPortalActive)
		//{
		//	cameraWithPlayer = true;
		//	OnSwitchCamera();
		//}
	}



	public void OnCameraThroughPortal()
	{
		cameraWithPlayer = playerInFirstPortal == firstPortalActive;
		OnSwitchCamera();

		//Transform rB = portals[0].GetRenderBox();
		//Vector3 rBPos = rB.localPosition;
		//rBPos.z *= -1;
		//rB.localPosition = rBPos;
		//rB = portals[1].GetRenderBox();
		//rBPos = rB.localPosition;
		//rBPos.z *= -1;
		//rB.localPosition = rBPos;
	}

	void OnSwitchCamera()
	{
		if (cameraWithPlayer)
		{
			Debug.Log("TELEPORTING CAMERA TO PLAYER");

			mainCamera.GetComponent<UniversalAdditionalCameraData>().renderPostProcessing = true;
			portalCamera.GetComponent<UniversalAdditionalCameraData>().renderPostProcessing = false;
			mainCamera.enabled = true;
			portalCamera.enabled = false;
			mainCamera.targetTexture = null;
			portalCamera.targetTexture = portalTexture;
			portalCamera.cullingMask = ~portalLayer;
			mainCamera.cullingMask = 0xFFFF;
		}
		else
		{
			Debug.Log("TELEPORTING CAMERA AWAY FROM PLAYER");
			mainCamera.GetComponent<UniversalAdditionalCameraData>().renderPostProcessing = false;
			portalCamera.GetComponent<UniversalAdditionalCameraData>().renderPostProcessing = true;
			mainCamera.enabled = false;
			portalCamera.enabled = true;
			mainCamera.targetTexture = portalTexture;
			portalCamera.targetTexture = null;
			portalCamera.cullingMask = 0xFFFF;
			mainCamera.cullingMask = ~portalLayer;
		}

	}

	int cameraState = -1;
	void CheckForCamera()
	{
		if (!cameraTraveller) return;
		for (int i = 0; i < 2; i++)
		{
			//this shit makes no sense, needs fixed
			if (CameraRayIntersectsPortal(portals[i]))
			{
				if (cameraState != i)
				{
					if (cameraState != -1)
					{
						int otherIndex = (i + 1) % 2;
						if (portals[otherIndex].GetTravellers().Contains(cameraTraveller))
						{
							Debug.Log("removed camera from portal " + i);
							portals[otherIndex].GetTravellers().Remove(cameraTraveller);
							lastTeleportedThroughPortal = portals[otherIndex];
							firstPortalActive = i == 1;
							cameraTraveller.OnExit(portals[otherIndex]);
						}
					}
					cameraState = i;
					if (!portals[i].GetTravellers().Contains(cameraTraveller))
					{
						Debug.Log("added camera to portal " + i);
						portals[i].GetTravellers().Add(cameraTraveller);
						lastTeleportedThroughPortal = portals[i];
						firstPortalActive = i == 1;
						cameraTraveller.OnEnter(portals[i]);
					}
				}
			}
			else if (cameraState == i)
			{
				cameraState = -1;
				if (portals[i].GetTravellers().Contains(cameraTraveller))
				{
					Debug.Log("removed camera from portal " + i);
					portals[i].GetTravellers().Remove(cameraTraveller);
					firstPortalActive = i == 0;
					cameraTraveller.OnExit(portals[i]);
				}
			}
		}
		return;
		//int aPortal = playerInFirstPortal ? 0 : 1;
		//Vector3 newPosition = cameraTraveller.transform.position;

		//Vector3 lineStart = GameManager.Instance.Player.MainCamera.GetTargetPivotPosition();
		////if the camera and the player are both next to the same portal
		//if (playerInFirstPortal == firstPortalActive)
		//{
		//	//if player and camera are on opposite sides of the portal
		//	//AND if the ray intersects the portal
		//	//teleport the camera
		//	Vector3 planeNormal = portals[aPortal].transform.forward;
		//	Vector3 planePosition = portals[aPortal].transform.position;
		//	if (Vector3.Dot(planeNormal, planePosition - lineStart) > 0 != Vector3.Dot(planeNormal, planePosition - newPosition) > 0)
		//	{
		//		Vector3 lineDirection = (newPosition - lineStart).normalized;

		//		float planeDistance = Vector3.Dot((planePosition - lineStart), lineDirection);
		//		float dirDot = Vector3.Dot(lineDirection, planeNormal);

		//		if (!(planeDistance == 0 && dirDot != 0) && portals[aPortal].CheckPointInBounds2D(lineDirection * planeDistance/dirDot + lineStart))
		//		{
		//			OnCameraThroughPortal();
		//		}
		//	}
		//}
		//else
		//{
		//	//if player and camera are on the same side of the portal
		//	//or if the ray does not intersect the portal
		//	//teleport the camera
		//	Vector3 planeNormal = portals[aPortal].transform.forward;
		//	Vector3 planePosition = portals[aPortal].transform.position;
		//	if (Vector3.Dot(planeNormal, planePosition - lineStart) > 0 != Vector3.Dot(planeNormal, planePosition - newPosition) > 0)
		//	{
		//		Vector3 lineDirection = (newPosition - lineStart).normalized;

		//		float planeDistance = Vector3.Dot((planePosition - lineStart), lineDirection);
		//		float dirDot = Vector3.Dot(lineDirection, planeNormal);

		//		//switch camera
		//		if (!(!(planeDistance == 0 && dirDot != 0) && portals[aPortal].CheckPointInBounds2D(lineDirection * planeDistance + lineStart)))
		//		{
		//			OnCameraThroughPortal();
		//		}

		//	}
		//	else
		//	{
		//		OnCameraThroughPortal();
		//	}
		//}
		//previousCameraPosition = cameraTraveller.transform.position;
	}

	public bool CameraRayIntersectsPortal(Portal portal)
	{
		Vector3 cameraPosition = cameraTraveller.transform.position;
		Vector3 lineStart = GameManager.Instance.Player.MainCamera.GetTargetPivotPosition();
		Vector3 planeNormal = portal.transform.forward;
		Vector3 planePosition = portal.transform.position;
		if (Vector3.Dot(planeNormal, planePosition - lineStart) > 0 != Vector3.Dot(planeNormal, planePosition - cameraPosition) > 0)
		{
			Vector3 lineDirection = (cameraPosition - lineStart).normalized;

			float planeDistance = Vector3.Dot((planePosition - lineStart), planeNormal);
			float dirDot = Vector3.Dot(lineDirection, planeNormal);

			if (!(planeDistance == 0 && dirDot != 0) && portal.CheckPointInBounds2D(lineDirection * planeDistance / dirDot + lineStart))
			{
				return true;
			}
			return false;
		}
		return false;
	}
	public override bool SwitchValue { get => base.SwitchValue;
		protected set 
		{
			on = value;
		}
	}

}
