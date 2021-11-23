using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

//my original portal script had a massive bug that I can't fix, so this version will play it safe and stick closer to a tutorial
public class NewPortalRenderer : BooleanSwitch
{
	public NewPortal[] portals = new NewPortal[2];

	public Camera mainCamera;
	public Camera portalCamera;

	RenderTexture portalTexture;

	int cameraPortalIndex = 0;
	int playerPortalIndex = 0;

	public LayerMask portalLayer;
	Matrix4x4 defaultMatrix;

	Vector2Int lastScreenSize;
	bool travelledThisFrame = false;
	private void Awake()
	{
		GameManager.Instance.RegisterWinSwitch(this);

		portalCamera = GetComponent<Camera>();
		portalCamera.enabled = false;

		lastScreenSize.x = Screen.width;
		lastScreenSize.y = Screen.height;
		
	}
	protected override void Start()
	{
		mainCamera = GameManager.Instance.Player.MainCamera.GetComponent<Camera>();
		SetRenderTextures();
		defaultMatrix = mainCamera.projectionMatrix;

		portals[0].OtherPortal = portals[1];
		portals[1].OtherPortal = portals[0];
		
		base.Start();
	}
	private void OnEnable()
	{
		RenderPipelineManager.beginCameraRendering += RenderPipelineManager_beginCameraRendering;
		RenderPipelineManager.endCameraRendering += RenderPipelineManager_endCameraRendering;
		
	}

	private void OnDisable()
	{
		RenderPipelineManager.endCameraRendering -= RenderPipelineManager_endCameraRendering;
		RenderPipelineManager.beginCameraRendering -= RenderPipelineManager_beginCameraRendering;

	}
	private void RenderPipelineManager_beginCameraRendering(ScriptableRenderContext arg1, Camera camera)
	{
		if (!portals[0].Open || !portals[1].Open) return;
		//update camera
		if (cameraPortalIndex == playerPortalIndex)
		{
			if (CameraRayIntersectsPortal(portals[playerPortalIndex]))
			{
				cameraPortalIndex = 1 - playerPortalIndex;

				UpdateCamera();

			}
		}
		else
		{
			if (!CameraRayIntersectsPortal(portals[playerPortalIndex]))
			{
				cameraPortalIndex = playerPortalIndex;

				UpdateCamera();

			}
		}

		travelledThisFrame = portals[cameraPortalIndex].Renderer.isVisible;
		if (travelledThisFrame)
		{
			NewPortal p1 = portals[playerPortalIndex];
			NewPortal p2 = portals[1 - playerPortalIndex];

			Transform portalCamTransform = portalCamera.transform;
			Transform mainCamTransform = mainCamera.transform;

			portalCamTransform.SetPositionAndRotation(p1.TransformPositionToOtherPortal(mainCamTransform.position),
				p1.TransformRotationToOtherPortal(mainCamTransform.rotation));

			if (cameraPortalIndex == playerPortalIndex)
			{
				SetFrustram(mainCamera, portalCamera);

				float sign = Mathf.Sign(Vector3.Dot(mainCamera.transform.position - p1.transform.position, p1.transform.forward));
				Transform rB = p1.GetRenderBox();
				Vector3 rBPos = rB.localPosition;
				rBPos.z = -sign * Mathf.Abs(rBPos.z);
				rB.localPosition = rBPos;
				rB = p2.GetRenderBox();
				rBPos = rB.localPosition;
				rBPos.z = -sign * Mathf.Abs(rBPos.z);
				rB.localPosition = rBPos;

				portalCamera.targetTexture = portalTexture;
				p1.TempTravelStart();
				UniversalRenderPipeline.RenderSingleCamera(arg1, portalCamera);
				p1.TempTravelEnd();
				
				//do a final temp travel that will be reverted later
				p2.TempTravelStart();
			}
			else
			{
				SetFrustram(portalCamera, mainCamera);

				float sign = Mathf.Sign(Vector3.Dot(mainCamera.transform.position - p1.transform.position, p1.transform.forward));
				Transform rB = p1.GetRenderBox();
				Vector3 rBPos = rB.localPosition;
				rBPos.z = sign * Mathf.Abs(rBPos.z);
				rB.localPosition = rBPos;
				rB = p2.GetRenderBox();
				rBPos = rB.localPosition;
				rBPos.z = sign * Mathf.Abs(rBPos.z);
				rB.localPosition = rBPos;

				mainCamera.targetTexture = portalTexture;

				p2.TempTravelStart();
				UniversalRenderPipeline.RenderSingleCamera(arg1, mainCamera);
				p2.TempTravelEnd();

				//do a final temp travel that will be reverted later
				p1.TempTravelStart();
			}
		}

		
	}
	private void RenderPipelineManager_endCameraRendering(ScriptableRenderContext arg1, Camera arg2)
	{
		if (travelledThisFrame)
		{
			if (cameraPortalIndex == playerPortalIndex)
			{
				portals[1 - playerPortalIndex].TempTravelEnd();
			}
			else
			{
				portals[playerPortalIndex].TempTravelEnd();
			}
			travelledThisFrame = false;
		}

		if (portals[0].SwitchValue && portals[1].SwitchValue)
		{
			for (int i = 0; i < 2; i++)
			{
				portals[i].TeleportTravellers();
			}
		}
	}

	private void Update()
	{
		if (!portals[0].Open || !portals[1].Open) return;

		Vector2Int newScreenSize = new Vector2Int(Screen.width, Screen.height);
		if (newScreenSize != lastScreenSize)
		{
			Debug.Log("Screen size change detected");
			SetRenderTextures();
			lastScreenSize = newScreenSize;
		}
	}
	void SetFrustram(Camera c1, Camera c2)
	{
		NewPortal p1 = portals[playerPortalIndex];
		NewPortal p2 = portals[1 - playerPortalIndex];
		//now set camera frustram to make the near clip plane the same as the portal plane 
		//this has ramifications if the player can see long distances but whatever who cares
		float sign = Mathf.Sign(Vector3.Dot(mainCamera.transform.position - p1.transform.position, p1.transform.forward));
		Vector3 normal = sign * p2.transform.forward;
		Vector4 nearPlane = new Vector4(normal.x, normal.y, normal.z, -Vector3.Dot(normal, p2.transform.position));
		Vector4 nearPlaneCamera = Matrix4x4.Transpose(Matrix4x4.Inverse(portalCamera.worldToCameraMatrix)) * nearPlane;
		c2.projectionMatrix = mainCamera.CalculateObliqueMatrix(nearPlaneCamera);
		c1.projectionMatrix = defaultMatrix;
	}
	public bool CameraRayIntersectsPortal(NewPortal portal)
	{
		Vector3 cameraPosition = mainCamera.transform.position;
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
	public void OnCameraThroughPortal()
	{
		cameraPortalIndex = 1 - cameraPortalIndex;
		UpdateCamera();
	}

	public void OnPlayerThroughPortal(NewPortal inPortal)
	{
		CalculatePlayerPortal();
		//playerPortalIndex = inPortal == portals[0] ? 1 : 0;

		UpdateCamera();
	}

	private void FixedUpdate()
	{
		CalculatePlayerPortal();
	}

	public void UpdateCamera()
	{
		if (cameraPortalIndex == playerPortalIndex)
		{
			mainCamera.GetComponent<UniversalAdditionalCameraData>().renderPostProcessing = true;
			portalCamera.GetComponent<UniversalAdditionalCameraData>().renderPostProcessing = false;
			mainCamera.enabled = true;
			portalCamera.enabled = false;
			mainCamera.targetTexture = null;
			portalCamera.cullingMask = ~portalLayer;
			mainCamera.cullingMask = 0xFFFF;
		}
		else
		{
			mainCamera.GetComponent<UniversalAdditionalCameraData>().renderPostProcessing = false;
			portalCamera.GetComponent<UniversalAdditionalCameraData>().renderPostProcessing = true;
			mainCamera.enabled = false;
			portalCamera.enabled = true;
			portalCamera.targetTexture = null;
			portalCamera.cullingMask = 0xFFFF;
			mainCamera.cullingMask = ~portalLayer;
		}
	}

	public override bool SwitchValue { get => base.SwitchValue; protected set 
		{
			on = value;

			SetRenderTextures();
			portals[0].Switch(on);
			portals[1].Switch(on);
		} }


	public void SetRenderTextures()
	{
		portalTexture?.Release();
		portalTexture = new RenderTexture(Screen.width, Screen.height, 24, RenderTextureFormat.DefaultHDR);
		portals[0].Renderer.material.mainTexture = portalTexture;
		portals[1].Renderer.material.mainTexture = portalTexture;
	}

	public void CalculatePlayerPortal()
	{
		if (Vector3.SqrMagnitude(portals[0].transform.position - GameManager.Instance.Player.transform.position) <
			Vector3.SqrMagnitude(portals[1].transform.position - GameManager.Instance.Player.transform.position))
		{
			if (playerPortalIndex != 0)
			{
				playerPortalIndex = 0;
				UpdateCamera();
			}
			
		}
		else
		{
			if (playerPortalIndex != 1)
			{
				playerPortalIndex = 1;
				UpdateCamera();
			}
		}
	}

}
