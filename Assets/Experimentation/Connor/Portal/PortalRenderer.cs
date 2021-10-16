using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

//this is made from a tutorial found here: https://danielilett.com/2019-12-01-tut4-intro-portals/

public class PortalRenderer : MonoBehaviour
{
	public Portal[] portals = new Portal[2];
	public Camera mainCamera;
	public bool firstPortalActive = true;
	Camera portalCamera;
	public LayerMask portalLayer;
	RenderTexture portalTexture;
	Matrix4x4 defaultMatrix;
	CameraPortalTraveller cameraTraveller;
	bool cameraWithPlayer = true;

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
		else if (!firstPortalActive)
		{
			RenderCamera(portals[1], portals[0], context);
		}

	}

	void RenderCamera(Portal inPortal, Portal outPortal, ScriptableRenderContext context)
	{
		CheckForCamera();
		Camera c1;
		Camera c2;
		Vector3 pos;
		Quaternion rot;
		Portal p1;
		Portal p2;
		float negateRBZ;
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

		//travel objects before rendering
		//this will temporarilly travel objects that are just partially through the portal
		//it will also teleport objects that are fully through the portal
		inPortal.TravelTravellers(outPortal);
		UniversalRenderPipeline.RenderSingleCamera(context, c2);
		inPortal.UndoTravel(outPortal);

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

	[System.NonSerialized]
	public bool cameraIsSwitched = false;
	public void OnPlayerThroughPortal()
	{
		cameraWithPlayer = !cameraWithPlayer;
		OnSwitchCamera();

	}

	public void OnCameraThroughPortal()
	{
		firstPortalActive = !firstPortalActive;
		cameraWithPlayer = !cameraWithPlayer;
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
			mainCamera.enabled = true;
			portalCamera.enabled = false;
			mainCamera.targetTexture = null;
			portalCamera.targetTexture = portalTexture;
			portalCamera.cullingMask = ~portalLayer;
			mainCamera.cullingMask = 0xFFFF;
		}
		else
		{
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
			if (portals[i].CheckPointInBounds(mainCamera.transform.position))
			{
				if (cameraState != i)
				{
					cameraState = i;
					portals[i].GetTravellers().Add(cameraTraveller);
					cameraTraveller.OnEnter(portals[i]);
				}
			}
			else if (cameraState == i)
			{
				cameraState = -1;
				portals[i].GetTravellers().Remove(cameraTraveller);
				cameraTraveller.OnExit(portals[i]);
			}
		}
	}
}
