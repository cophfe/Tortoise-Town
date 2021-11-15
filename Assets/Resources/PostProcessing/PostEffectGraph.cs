using System.Collections;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;
using UnityEngine.Rendering.Universal;

//------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------
[ExecuteAlways]
public class PostEffectGraph : MonoBehaviour
{
	private PostEffectGraphFeature m_postEffect = null;

	public Material[] m_postEffectList = null;

	//------------------------------------------------------------------------------------
	//------------------------------------------------------------------------------------
#if UNITY_EDITOR
	void OnValidate()
	{
		ApplyPostEffects();
	}
#endif

	//------------------------------------------------------------------------------------
	//------------------------------------------------------------------------------------
	void OnEnable()
	{
		ApplyPostEffects();
	}

	//------------------------------------------------------------------------------------
	//------------------------------------------------------------------------------------
	void OnDisable()
	{
		RemovePostEffects();
	}

	//------------------------------------------------------------------------------------
	//------------------------------------------------------------------------------------
	private void ApplyPostEffects() 
	{
		//Create custom post effect system if it doesn't already exist
		if (m_postEffect == null) 
		{
			m_postEffect = ScriptableObject.CreateInstance<PostEffectGraphFeature>();
		}
		m_postEffect.SetPostEffects(m_postEffectList);

		//Find the renderer
		ScriptableRendererData renderer = GetDefaultRenderer();
		if(renderer == null)
		{
			Debug.LogError("No scriptable render data found");
			return;
		}

		//Make sure the post effect system has been applied to the renderer
		renderer.rendererFeatures.Clear();
		renderer.rendererFeatures.Add(m_postEffect);
		renderer.SetDirty();
	}

	//------------------------------------------------------------------------------------
	//------------------------------------------------------------------------------------
	private void RemovePostEffects()
	{
		//Find the renderer
		ScriptableRendererData renderer = GetDefaultRenderer();
		if (renderer == null)
		{
			Debug.LogError("No scriptable render data found");
			return;
		}

		//Make sure the post effect system has been applied to the renderer
		renderer.rendererFeatures.Clear();
		renderer.SetDirty();
	}

	//------------------------------------------------------------------------------------
	// System for getting the ScriptableRendererData by StaggartCreations
	// https://forum.unity.com/threads/urp-adding-a-renderfeature-from-script.1117060/
	//------------------------------------------------------------------------------------
	private static int GetDefaultRendererIndex(UniversalRenderPipelineAsset asset)
	{
		return (int)typeof(UniversalRenderPipelineAsset).GetField("m_DefaultRendererIndex", BindingFlags.NonPublic | BindingFlags.Instance).GetValue(asset);
	}

	//------------------------------------------------------------------------------------
	//------------------------------------------------------------------------------------
	public static ScriptableRendererData GetDefaultRenderer()
	{
		if (UniversalRenderPipeline.asset)
		{
			ScriptableRendererData[] rendererDataList = (ScriptableRendererData[])typeof(UniversalRenderPipelineAsset)
					.GetField("m_RendererDataList", BindingFlags.NonPublic | BindingFlags.Instance)
					.GetValue(UniversalRenderPipeline.asset);
			int defaultRendererIndex = GetDefaultRendererIndex(UniversalRenderPipeline.asset);

			return rendererDataList[defaultRendererIndex];
		}
		else
		{
			Debug.LogError("No Universal Render Pipeline is currently active.");
			return null;
		}
	}

}
