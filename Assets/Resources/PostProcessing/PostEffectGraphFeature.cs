using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

#if UNITY_EDITOR
using UnityEditor;
#endif

//----------------------------------------------------------------------
//----------------------------------------------------------------------
public class PostEffectGraphFeature : ScriptableRendererFeature
{
	private PostEffectGraphPass m_pass = null;
	private Material[] m_postEffectList = null;

	//----------------------------------------------------------------------
	//----------------------------------------------------------------------
	public void SetPostEffects(Material[] postEffectList)
	{
		m_postEffectList = postEffectList;
		if(m_pass != null)
			m_pass.SetPostEffects(m_postEffectList);
	}

	//----------------------------------------------------------------------
	//----------------------------------------------------------------------
	public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
	{
#if UNITY_EDITOR
		if (renderingData.cameraData.camera == SceneView.lastActiveSceneView.camera)
			return;
#endif

		m_pass.SetRenderSource(renderer.cameraColorTarget);
		m_pass.SetPostEffects(m_postEffectList);
		renderer.EnqueuePass(m_pass);
	}

	//----------------------------------------------------------------------
	//----------------------------------------------------------------------
	public override void Create()
	{
		m_pass = new PostEffectGraphPass();
		m_pass.renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
	}
}

//----------------------------------------------------------------------
//----------------------------------------------------------------------
public class PostEffectGraphPass : ScriptableRenderPass
{
	private RenderTargetIdentifier m_renderSource;
	private Material[] m_postEffectList = null;

	//----------------------------------------------------------------------
	//----------------------------------------------------------------------
	public PostEffectGraphPass()
	{
	}

	//----------------------------------------------------------------------
	//----------------------------------------------------------------------
	public void SetRenderSource(RenderTargetIdentifier source)
	{
		m_renderSource = source;
	}

	//----------------------------------------------------------------------
	//----------------------------------------------------------------------
	public void SetPostEffects(Material[] postEffectList)
	{
		m_postEffectList = postEffectList;
	}

	//----------------------------------------------------------------------
	//----------------------------------------------------------------------
	public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
	{
#if UNITY_EDITOR
		if (renderingData.cameraData.camera == SceneView.lastActiveSceneView.camera)
			return;
#endif

		if (m_postEffectList == null || m_postEffectList.Length == 0)
			return;

		CommandBuffer cmd = CommandBufferPool.Get();

		//Material material = new Material(Shader.Find("Hidden/CustomPostEffect"));
		//Material material = new Material(Shader.Find("Shader Graphs/PostEffectGraph"));

		using (new ProfilingScope(cmd, new ProfilingSampler("Custom Pass")))
		{
			//cmd.Blit(m_renderSource, m_renderSource, material);

			for (int i = 0; i < m_postEffectList.Length; ++i)
			{
				cmd.Blit(m_renderSource, m_renderSource, m_postEffectList[i]);
			}
		}

		context.ExecuteCommandBuffer(cmd);
		CommandBufferPool.Release(cmd);
	}
}
