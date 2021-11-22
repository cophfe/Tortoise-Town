// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "WaterShader"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[ASEBegin]_WaterAlpha("WaterAlpha", Float) = 1
		_LargeWaveRotationZ("LargeWaveRotationZ", Float) = 1
		_LargeWaveRotationX("LargeWaveRotationX", Float) = 0.85
		_MediumWaveRotationX("MediumWaveRotationX", Float) = 0.85
		_MediumWaveRotationZ("MediumWaveRotationZ", Float) = 1
		_SmallWaveRotationZ("SmallWaveRotationZ", Float) = 1
		_SmallWaveRotationX("SmallWaveRotationX", Float) = 0.85
		_MediumWaveSpeed("MediumWaveSpeed", Float) = 1
		_LargeWaveSpeed("LargeWaveSpeed", Float) = 1
		_SmallWaveSpeed("SmallWaveSpeed", Float) = 1
		_SmallWavePower("SmallWavePower", Float) = 2
		_LargeWavePower("LargeWavePower", Float) = 2
		_MediumWavePower("MediumWavePower", Float) = 2
		_GradientScale("GradientScale", Float) = 1
		_GradientSpeed("GradientSpeed", Vector) = (0.1,0.1,0,0)
		_SmallWaveHeight("SmallWaveHeight", Float) = 0.2
		_MediumWaveHeight("MediumWaveHeight", Float) = 0.4
		_LargeWaveHeight("LargeWaveHeight", Float) = 0.6
		_MediumWaveColourBlend("MediumWaveColourBlend", Color) = (0.5754717,0.5754717,0.5754717,0)
		_TopColourContrast("TopColourContrast", Float) = 1
		_TopDarkColour("TopDarkColour", Color) = (0,1,0.9999998,0)
		_BottomDarkColour("Bottom Dark Colour", Color) = (0,0,0,0)
		_BottomLightColour("Bottom Light Colour", Color) = (0.6745283,0.918313,1,0)
		_RefractionScale("RefractionScale", Float) = 25
		_TopLightColour("TopLightColour", Color) = (0.8915094,1,0.992375,0)
		_FrothSpeed("FrothSpeed", Float) = 0.07
		_FrothScaleSmall("FrothScaleSmall", Float) = 4.37
		_FrothScaleBig("FrothScaleBig", Float) = 2.61
		_RefractionBlend("RefractionBlend", Float) = 5
		_RefractionStrength("RefractionStrength", Float) = 0.09
		_FrothStep("FrothStep", Float) = 0.8
		_FrothBlend("FrothBlend", Float) = 1
		_Metallic("Metallic", Float) = 0
		_Smoothness("Smoothness", Float) = 0
		[HDR]_RefractionColour("RefractionColour", Color) = (1,1,1,0)
		_RefractionSize("RefractionSize", Float) = 0.4
		_FrothDirection("FrothDirection", Vector) = (1,1,0,0)
		_FrothStretch("FrothStretch", Vector) = (0,0,0,0)
		_Offset("Offset", Float) = 0
		_FresenelPower("FresenelPower", Float) = 0
		[ASEEnd]_RefractionStretch("RefractionStretch", Vector) = (2,2,0,0)

		//_TransmissionShadow( "Transmission Shadow", Range( 0, 1 ) ) = 0.5
		//_TransStrength( "Trans Strength", Range( 0, 50 ) ) = 1
		//_TransNormal( "Trans Normal Distortion", Range( 0, 1 ) ) = 0.5
		//_TransScattering( "Trans Scattering", Range( 1, 50 ) ) = 2
		//_TransDirect( "Trans Direct", Range( 0, 1 ) ) = 0.9
		//_TransAmbient( "Trans Ambient", Range( 0, 1 ) ) = 0.1
		//_TransShadow( "Trans Shadow", Range( 0, 1 ) ) = 0.5
		//_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		//_TessValue( "Tess Max Tessellation", Range( 1, 32 ) ) = 16
		//_TessMin( "Tess Min Distance", Float ) = 10
		//_TessMax( "Tess Max Distance", Float ) = 25
		//_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		//_TessMaxDisp( "Tess Max Displacement", Float ) = 25
	}

	SubShader
	{
		LOD 0

		

		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" }
		Cull Back
		AlphaToMask Off
		HLSLINCLUDE
		#pragma target 2.0

		#pragma prefer_hlslcc gles
		#pragma exclude_renderers d3d11_9x 


		#ifndef ASE_TESS_FUNCS
		#define ASE_TESS_FUNCS
		float4 FixedTess( float tessValue )
		{
			return tessValue;
		}
		
		float CalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess, float4x4 o2w, float3 cameraPos )
		{
			float3 wpos = mul(o2w,vertex).xyz;
			float dist = distance (wpos, cameraPos);
			float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
			return f;
		}

		float4 CalcTriEdgeTessFactors (float3 triVertexFactors)
		{
			float4 tess;
			tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
			tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
			tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
			tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
			return tess;
		}

		float CalcEdgeTessFactor (float3 wpos0, float3 wpos1, float edgeLen, float3 cameraPos, float4 scParams )
		{
			float dist = distance (0.5 * (wpos0+wpos1), cameraPos);
			float len = distance(wpos0, wpos1);
			float f = max(len * scParams.y / (edgeLen * dist), 1.0);
			return f;
		}

		float DistanceFromPlane (float3 pos, float4 plane)
		{
			float d = dot (float4(pos,1.0f), plane);
			return d;
		}

		bool WorldViewFrustumCull (float3 wpos0, float3 wpos1, float3 wpos2, float cullEps, float4 planes[6] )
		{
			float4 planeTest;
			planeTest.x = (( DistanceFromPlane(wpos0, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[0]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.y = (( DistanceFromPlane(wpos0, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[1]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.z = (( DistanceFromPlane(wpos0, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[2]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.w = (( DistanceFromPlane(wpos0, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[3]) > -cullEps) ? 1.0f : 0.0f );
			return !all (planeTest);
		}

		float4 DistanceBasedTess( float4 v0, float4 v1, float4 v2, float tess, float minDist, float maxDist, float4x4 o2w, float3 cameraPos )
		{
			float3 f;
			f.x = CalcDistanceTessFactor (v0,minDist,maxDist,tess,o2w,cameraPos);
			f.y = CalcDistanceTessFactor (v1,minDist,maxDist,tess,o2w,cameraPos);
			f.z = CalcDistanceTessFactor (v2,minDist,maxDist,tess,o2w,cameraPos);

			return CalcTriEdgeTessFactors (f);
		}

		float4 EdgeLengthBasedTess( float4 v0, float4 v1, float4 v2, float edgeLength, float4x4 o2w, float3 cameraPos, float4 scParams )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;
			tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
			tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
			tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
			tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			return tess;
		}

		float4 EdgeLengthBasedTessCull( float4 v0, float4 v1, float4 v2, float edgeLength, float maxDisplacement, float4x4 o2w, float3 cameraPos, float4 scParams, float4 planes[6] )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;

			if (WorldViewFrustumCull(pos0, pos1, pos2, maxDisplacement, planes))
			{
				tess = 0.0f;
			}
			else
			{
				tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
				tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
				tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
				tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			}
			return tess;
		}
		#endif //ASE_TESS_FUNCS
		ENDHLSL

		
		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForward" }
			
			Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
			ZWrite Off
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
			

			HLSLPROGRAM
			
			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define ASE_SRP_VERSION 80200
			#define REQUIRE_DEPTH_TEXTURE 1

			
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile _ _SHADOWS_SOFT
			#pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
			
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile _ LIGHTMAP_ON

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS_FORWARD

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			
			#if ASE_SRP_VERSION <= 70108
			#define REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
			#endif

			#if defined(UNITY_INSTANCING_ENABLED) && defined(_TERRAIN_INSTANCED_PERPIXEL_NORMAL)
			    #define ENABLE_TERRAIN_PERPIXEL_NORMAL
			#endif

			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_FRAG_WORLD_VIEW_DIR
			#define ASE_NEEDS_FRAG_WORLD_NORMAL
			#define ASE_NEEDS_FRAG_SCREEN_POSITION
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_FRAG_COLOR
			#pragma multi_compile_instancing


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord : TEXCOORD0;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float4 lightmapUVOrVertexSH : TEXCOORD0;
				half4 fogFactorAndVertexLight : TEXCOORD1;
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				float4 shadowCoord : TEXCOORD2;
				#endif
				float4 tSpace0 : TEXCOORD3;
				float4 tSpace1 : TEXCOORD4;
				float4 tSpace2 : TEXCOORD5;
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				float4 screenPos : TEXCOORD6;
				#endif
				float4 ase_texcoord7 : TEXCOORD7;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
						#ifdef _TRANSMISSION_ASE
				float _TransmissionShadow;
			#endif
			#ifdef _TRANSLUCENCY_ASE
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			uniform float4 _CameraDepthTexture_TexelSize;
			UNITY_INSTANCING_BUFFER_START(WaterShader)
				UNITY_DEFINE_INSTANCED_PROP(float4, _MediumWaveColourBlend)
				UNITY_DEFINE_INSTANCED_PROP(float4, _BottomDarkColour)
				UNITY_DEFINE_INSTANCED_PROP(float4, _BottomLightColour)
				UNITY_DEFINE_INSTANCED_PROP(float4, _RefractionColour)
				UNITY_DEFINE_INSTANCED_PROP(float4, _TopDarkColour)
				UNITY_DEFINE_INSTANCED_PROP(float4, _TopLightColour)
				UNITY_DEFINE_INSTANCED_PROP(float2, _GradientSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float2, _FrothStretch)
				UNITY_DEFINE_INSTANCED_PROP(float2, _RefractionStretch)
				UNITY_DEFINE_INSTANCED_PROP(float2, _FrothDirection)
				UNITY_DEFINE_INSTANCED_PROP(float, _RefractionScale)
				UNITY_DEFINE_INSTANCED_PROP(float, _FrothSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _TopColourContrast)
				UNITY_DEFINE_INSTANCED_PROP(float, _RefractionStrength)
				UNITY_DEFINE_INSTANCED_PROP(float, _RefractionSize)
				UNITY_DEFINE_INSTANCED_PROP(float, _RefractionBlend)
				UNITY_DEFINE_INSTANCED_PROP(float, _Metallic)
				UNITY_DEFINE_INSTANCED_PROP(float, _FrothBlend)
				UNITY_DEFINE_INSTANCED_PROP(float, _FrothScaleSmall)
				UNITY_DEFINE_INSTANCED_PROP(float, _FrothScaleBig)
				UNITY_DEFINE_INSTANCED_PROP(float, _SmallWaveRotationX)
				UNITY_DEFINE_INSTANCED_PROP(float, _FrothStep)
				UNITY_DEFINE_INSTANCED_PROP(float, _SmallWaveRotationZ)
				UNITY_DEFINE_INSTANCED_PROP(float, _SmallWaveSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _SmallWavePower)
				UNITY_DEFINE_INSTANCED_PROP(float, _SmallWaveHeight)
				UNITY_DEFINE_INSTANCED_PROP(float, _MediumWaveRotationX)
				UNITY_DEFINE_INSTANCED_PROP(float, _MediumWaveRotationZ)
				UNITY_DEFINE_INSTANCED_PROP(float, _MediumWaveSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _GradientScale)
				UNITY_DEFINE_INSTANCED_PROP(float, _MediumWavePower)
				UNITY_DEFINE_INSTANCED_PROP(float, _MediumWaveHeight)
				UNITY_DEFINE_INSTANCED_PROP(float, _LargeWaveRotationX)
				UNITY_DEFINE_INSTANCED_PROP(float, _LargeWaveRotationZ)
				UNITY_DEFINE_INSTANCED_PROP(float, _LargeWaveSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _LargeWavePower)
				UNITY_DEFINE_INSTANCED_PROP(float, _LargeWaveHeight)
				UNITY_DEFINE_INSTANCED_PROP(float, _FresenelPower)
				UNITY_DEFINE_INSTANCED_PROP(float, _Offset)
				UNITY_DEFINE_INSTANCED_PROP(float, _Smoothness)
				UNITY_DEFINE_INSTANCED_PROP(float, _WaterAlpha)
			UNITY_INSTANCING_BUFFER_END(WaterShader)


			//https://www.shadertoy.com/view/XdXGW8
			float2 GradientNoiseDir( float2 x )
			{
				const float2 k = float2( 0.3183099, 0.3678794 );
				x = x * k + k.yx;
				return -1.0 + 2.0 * frac( 16.0 * k * frac( x.x * x.y * ( x.x + x.y ) ) );
			}
			
			float GradientNoise( float2 UV, float Scale )
			{
				float2 p = UV * Scale;
				float2 i = floor( p );
				float2 f = frac( p );
				float2 u = f * f * ( 3.0 - 2.0 * f );
				return lerp( lerp( dot( GradientNoiseDir( i + float2( 0.0, 0.0 ) ), f - float2( 0.0, 0.0 ) ),
						dot( GradientNoiseDir( i + float2( 1.0, 0.0 ) ), f - float2( 1.0, 0.0 ) ), u.x ),
						lerp( dot( GradientNoiseDir( i + float2( 0.0, 1.0 ) ), f - float2( 0.0, 1.0 ) ),
						dot( GradientNoiseDir( i + float2( 1.0, 1.0 ) ), f - float2( 1.0, 1.0 ) ), u.x ), u.y );
			}
			
			inline float noise_randomValue (float2 uv) { return frac(sin(dot(uv, float2(12.9898, 78.233)))*43758.5453); }
			inline float noise_interpolate (float a, float b, float t) { return (1.0-t)*a + (t*b); }
			inline float valueNoise (float2 uv)
			{
				float2 i = floor(uv);
				float2 f = frac( uv );
				f = f* f * (3.0 - 2.0 * f);
				uv = abs( frac(uv) - 0.5);
				float2 c0 = i + float2( 0.0, 0.0 );
				float2 c1 = i + float2( 1.0, 0.0 );
				float2 c2 = i + float2( 0.0, 1.0 );
				float2 c3 = i + float2( 1.0, 1.0 );
				float r0 = noise_randomValue( c0 );
				float r1 = noise_randomValue( c1 );
				float r2 = noise_randomValue( c2 );
				float r3 = noise_randomValue( c3 );
				float bottomOfGrid = noise_interpolate( r0, r1, f.x );
				float topOfGrid = noise_interpolate( r2, r3, f.x );
				float t = noise_interpolate( bottomOfGrid, topOfGrid, f.y );
				return t;
			}
			
			float SimpleNoise(float2 UV)
			{
				float t = 0.0;
				float freq = pow( 2.0, float( 0 ) );
				float amp = pow( 0.5, float( 3 - 0 ) );
				t += valueNoise( UV/freq )*amp;
				freq = pow(2.0, float(1));
				amp = pow(0.5, float(3-1));
				t += valueNoise( UV/freq )*amp;
				freq = pow(2.0, float(2));
				amp = pow(0.5, float(3-2));
				t += valueNoise( UV/freq )*amp;
				return t;
			}
			
			float4 CalculateContrast( float contrastValue, float4 colorTarget )
			{
				float t = 0.5 * ( 1.0 - contrastValue );
				return mul( float4x4( contrastValue,0,0,t, 0,contrastValue,0,t, 0,0,contrastValue,t, 0,0,0,1 ), colorTarget );
			}
			inline float2 UnityVoronoiRandomVector( float2 UV, float offset )
			{
				float2x2 m = float2x2( 15.27, 47.63, 99.41, 89.98 );
				UV = frac( sin(mul(UV, m) ) * 46839.32 );
				return float2( sin(UV.y* +offset ) * 0.5 + 0.5, cos( UV.x* offset ) * 0.5 + 0.5 );
			}
			
			//x - Out y - Cells
			float3 UnityVoronoi( float2 UV, float AngleOffset, float CellDensity, inout float2 mr )
			{
				float2 g = floor( UV * CellDensity );
				float2 f = frac( UV * CellDensity );
				float t = 8.0;
				float3 res = float3( 8.0, 0.0, 0.0 );
			
				for( int y = -1; y <= 1; y++ )
				{
					for( int x = -1; x <= 1; x++ )
					{
						float2 lattice = float2( x, y );
						float2 offset = UnityVoronoiRandomVector( lattice + g, AngleOffset );
						float d = distance( lattice + offset, f );
			
						if( d < res.x )
						{
							mr = f - lattice - offset;
							res = float3( d, offset.x, offset.y );
						}
					}
				}
				return res;
			}
			
			float3 mod2D289( float3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float2 mod2D289( float2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float3 permute( float3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }
			float snoise( float2 v )
			{
				const float4 C = float4( 0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439 );
				float2 i = floor( v + dot( v, C.yy ) );
				float2 x0 = v - i + dot( i, C.xx );
				float2 i1;
				i1 = ( x0.x > x0.y ) ? float2( 1.0, 0.0 ) : float2( 0.0, 1.0 );
				float4 x12 = x0.xyxy + C.xxzz;
				x12.xy -= i1;
				i = mod2D289( i );
				float3 p = permute( permute( i.y + float3( 0.0, i1.y, 1.0 ) ) + i.x + float3( 0.0, i1.x, 1.0 ) );
				float3 m = max( 0.5 - float3( dot( x0, x0 ), dot( x12.xy, x12.xy ), dot( x12.zw, x12.zw ) ), 0.0 );
				m = m * m;
				m = m * m;
				float3 x = 2.0 * frac( p * C.www ) - 1.0;
				float3 h = abs( x ) - 0.5;
				float3 ox = floor( x + 0.5 );
				float3 a0 = x - ox;
				m *= 1.79284291400159 - 0.85373472095314 * ( a0 * a0 + h * h );
				float3 g;
				g.x = a0.x * x0.x + h.x * x0.y;
				g.yz = a0.yz * x12.xz + h.yz * x12.yw;
				return 130.0 * dot( m, g );
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float _SmallWaveRotationX_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_SmallWaveRotationX);
				float3 ase_worldPos = mul(GetObjectToWorldMatrix(), v.vertex).xyz;
				float _SmallWaveRotationZ_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_SmallWaveRotationZ);
				float _SmallWaveSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_SmallWaveSpeed);
				float _SmallWavePower_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_SmallWavePower);
				float SmallWave120 = pow( ( 1.0 - abs( sin( ( ( ( ( _SmallWaveRotationX_Instance * ase_worldPos.x ) + ( ase_worldPos.z * _SmallWaveRotationZ_Instance ) ) * 4.0 ) + ( _SmallWaveSpeed_Instance * _TimeParameters.x ) ) ) ) ) , _SmallWavePower_Instance );
				float _SmallWaveHeight_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_SmallWaveHeight);
				float _MediumWaveRotationX_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWaveRotationX);
				float _MediumWaveRotationZ_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWaveRotationZ);
				float MediumWaveScaleVar300 = 2.0;
				float _MediumWaveSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWaveSpeed);
				float2 appendResult156 = (float2(ase_worldPos.x , ase_worldPos.z));
				float2 _GradientSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_GradientSpeed);
				float2 GradientSpeedVar250 = _GradientSpeed_Instance;
				float2 texCoord146 = v.texcoord.xy * appendResult156 + ( _TimeParameters.x * ( GradientSpeedVar250 * float2( 1.2,1.2 ) ) );
				float _GradientScale_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_GradientScale);
				float GradientScaleVar251 = _GradientScale_Instance;
				float gradientNoise143 = GradientNoise(texCoord146,( GradientScaleVar251 * 1.2 ));
				gradientNoise143 = gradientNoise143*0.5 + 0.5;
				float _MediumWavePower_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWavePower);
				float MediumWave140 = pow( ( 1.0 - abs( sin( ( ( ( ( _MediumWaveRotationX_Instance * ase_worldPos.x ) + ( ase_worldPos.z * _MediumWaveRotationZ_Instance ) ) * MediumWaveScaleVar300 ) + ( ( _MediumWaveSpeed_Instance * _TimeParameters.x ) + gradientNoise143 ) ) ) ) ) , _MediumWavePower_Instance );
				float _MediumWaveHeight_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWaveHeight);
				float _LargeWaveRotationX_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_LargeWaveRotationX);
				float _LargeWaveRotationZ_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_LargeWaveRotationZ);
				float LargeWaveScaleVar301 = 0.5;
				float _LargeWaveSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_LargeWaveSpeed);
				float2 appendResult187 = (float2(ase_worldPos.x , ase_worldPos.z));
				float2 texCoord192 = v.texcoord.xy * appendResult187 + ( _TimeParameters.x * GradientSpeedVar250 );
				float gradientNoise193 = GradientNoise(texCoord192,GradientScaleVar251);
				gradientNoise193 = gradientNoise193*0.5 + 0.5;
				float _LargeWavePower_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_LargeWavePower);
				float LargeWave199 = pow( ( 1.0 - abs( sin( ( ( ( ( _LargeWaveRotationX_Instance * ase_worldPos.x ) + ( ase_worldPos.z * _LargeWaveRotationZ_Instance ) ) * LargeWaveScaleVar301 ) + ( ( _LargeWaveSpeed_Instance * _TimeParameters.x ) + gradientNoise193 ) ) ) ) ) , _LargeWavePower_Instance );
				float _LargeWaveHeight_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_LargeWaveHeight);
				float4 appendResult219 = (float4(ase_worldPos.x , ase_worldPos.z , 0.0 , 0.0));
				float2 texCoord220 = v.texcoord.xy * appendResult219.xy + ( _TimeParameters.x * GradientSpeedVar250 );
				float gradientNoise226 = GradientNoise(texCoord220,GradientScaleVar251);
				gradientNoise226 = gradientNoise226*0.5 + 0.5;
				float WorldScale233 = gradientNoise226;
				float4 break258 = ( float4(1,1,1,1) * ( ( ( SmallWave120 * _SmallWaveHeight_Instance ) + ( MediumWave140 * _MediumWaveHeight_Instance ) + ( LargeWave199 * _LargeWaveHeight_Instance ) ) * WorldScale233 ) );
				float4 appendResult246 = (float4(v.vertex.xyz.x , ( ( break258.x + break258.z ) + v.vertex.xyz.y ) , v.vertex.xyz.z , 0.0));
				float4 lerpResult263 = lerp( float4( ( v.vertex.xyz / float3( 2,2,2 ) ) , 0.0 ) , appendResult246 , v.ase_color.r);
				float3 temp_output_278_0 = v.vertex.xyz;
				float4 lerpResult266 = lerp( lerpResult263 , float4( ( temp_output_278_0 / ( 1.1 * 10.0 ) ) , 0.0 ) , ( v.ase_color.g * 1.1 ));
				
				o.ase_texcoord7.xyz = v.texcoord.xyz;
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord7.w = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = lerpResult266.xyz;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float3 positionVS = TransformWorldToView( positionWS );
				float4 positionCS = TransformWorldToHClip( positionWS );

				VertexNormalInputs normalInput = GetVertexNormalInputs( v.ase_normal, v.ase_tangent );

				o.tSpace0 = float4( normalInput.normalWS, positionWS.x);
				o.tSpace1 = float4( normalInput.tangentWS, positionWS.y);
				o.tSpace2 = float4( normalInput.bitangentWS, positionWS.z);

				OUTPUT_LIGHTMAP_UV( v.texcoord1, unity_LightmapST, o.lightmapUVOrVertexSH.xy );
				OUTPUT_SH( normalInput.normalWS.xyz, o.lightmapUVOrVertexSH.xyz );

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					o.lightmapUVOrVertexSH.zw = v.texcoord;
					o.lightmapUVOrVertexSH.xy = v.texcoord * unity_LightmapST.xy + unity_LightmapST.zw;
				#endif

				half3 vertexLight = VertexLighting( positionWS, normalInput.normalWS );
				#ifdef ASE_FOG
					half fogFactor = ComputeFogFactor( positionCS.z );
				#else
					half fogFactor = 0;
				#endif
				o.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
				
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				VertexPositionInputs vertexInput = (VertexPositionInputs)0;
				vertexInput.positionWS = positionWS;
				vertexInput.positionCS = positionCS;
				o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				
				o.clipPos = positionCS;
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				o.screenPos = ComputeScreenPos(positionCS);
				#endif
				return o;
			}
			
			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 ase_color : COLOR;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_tangent = v.ase_tangent;
				o.texcoord = v.texcoord;
				o.texcoord1 = v.texcoord1;
				o.ase_color = v.ase_color;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				o.texcoord = patch[0].texcoord * bary.x + patch[1].texcoord * bary.y + patch[2].texcoord * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE)
				#define ASE_SV_DEPTH SV_DepthLessEqual  
			#else
				#define ASE_SV_DEPTH SV_Depth
			#endif

			half4 frag ( VertexOutput IN 
						#ifdef ASE_DEPTH_WRITE_ON
						,out float outputDepth : ASE_SV_DEPTH
						#endif
						 ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					float2 sampleCoords = (IN.lightmapUVOrVertexSH.zw / _TerrainHeightmapRecipSize.zw + 0.5f) * _TerrainHeightmapRecipSize.xy;
					float3 WorldNormal = TransformObjectToWorldNormal(normalize(SAMPLE_TEXTURE2D(_TerrainNormalmapTexture, sampler_TerrainNormalmapTexture, sampleCoords).rgb * 2 - 1));
					float3 WorldTangent = -cross(GetObjectToWorldMatrix()._13_23_33, WorldNormal);
					float3 WorldBiTangent = cross(WorldNormal, -WorldTangent);
				#else
					float3 WorldNormal = normalize( IN.tSpace0.xyz );
					float3 WorldTangent = IN.tSpace1.xyz;
					float3 WorldBiTangent = IN.tSpace2.xyz;
				#endif
				float3 WorldPosition = float3(IN.tSpace0.w,IN.tSpace1.w,IN.tSpace2.w);
				float3 WorldViewDirection = _WorldSpaceCameraPos.xyz  - WorldPosition;
				float4 ShadowCoords = float4( 0, 0, 0, 0 );
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				float4 ScreenPos = IN.screenPos;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					ShadowCoords = IN.shadowCoord;
				#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
					ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
				#endif
	
				WorldViewDirection = SafeNormalize( WorldViewDirection );

				float _FresenelPower_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_FresenelPower);
				float fresnelNdotV395 = dot( WorldNormal, WorldViewDirection );
				float fresnelNode395 = ( 0.0 + 1.0 * pow( 1.0 - fresnelNdotV395, _FresenelPower_Instance ) );
				float4 ase_screenPosNorm = ScreenPos / ScreenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float eyeDepth390 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float _Offset_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_Offset);
				float smoothstepResult393 = smoothstep( 0.0 , 1.0 , ( 1.0 - ( eyeDepth390 - ( ScreenPos.w - _Offset_Instance ) ) ));
				float _FrothStep_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_FrothStep);
				float2 _FrothStretch_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_FrothStretch);
				float2 _FrothDirection_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_FrothDirection);
				float _FrothSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_FrothSpeed);
				float2 texCoord350 = IN.ase_texcoord7.xyz.xy * float2( 1,1 ) + ( _FrothDirection_Instance * ( _TimeParameters.x * _FrothSpeed_Instance ) );
				float _FrothScaleBig_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_FrothScaleBig);
				float simpleNoise352 = SimpleNoise( ( ( IN.ase_texcoord7.xyz * float3( _FrothStretch_Instance ,  0.0 ) ) + float3( texCoord350 ,  0.0 ) ).xy*_FrothScaleBig_Instance );
				float4 appendResult349 = (float4(WorldPosition.x , WorldPosition.z , 0.0 , 0.0));
				float _FrothScaleSmall_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_FrothScaleSmall);
				float simpleNoise358 = SimpleNoise( appendResult349.xy*_FrothScaleSmall_Instance );
				float temp_output_360_0 = step( _FrothStep_Instance , ( simpleNoise352 + ( simpleNoise358 * 0.2 ) ) );
				float _FrothBlend_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_FrothBlend);
				float4 _BottomDarkColour_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_BottomDarkColour);
				float4 _BottomLightColour_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_BottomLightColour);
				float2 texCoord318 = IN.ase_texcoord7.xyz.xy * float2( 1,1 ) + float2( 0,0 );
				float4 lerpResult319 = lerp( _BottomDarkColour_Instance , _BottomLightColour_Instance , texCoord318.y);
				float4 _TopDarkColour_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_TopDarkColour);
				float4 _TopLightColour_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_TopLightColour);
				float _TopColourContrast_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_TopColourContrast);
				float4 _MediumWaveColourBlend_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWaveColourBlend);
				float _MediumWaveRotationX_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWaveRotationX);
				float _MediumWaveRotationZ_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWaveRotationZ);
				float MediumWaveScaleVar300 = 2.0;
				float _MediumWaveSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWaveSpeed);
				float2 appendResult156 = (float2(WorldPosition.x , WorldPosition.z));
				float2 _GradientSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_GradientSpeed);
				float2 GradientSpeedVar250 = _GradientSpeed_Instance;
				float2 texCoord146 = IN.ase_texcoord7.xyz.xy * appendResult156 + ( _TimeParameters.x * ( GradientSpeedVar250 * float2( 1.2,1.2 ) ) );
				float _GradientScale_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_GradientScale);
				float GradientScaleVar251 = _GradientScale_Instance;
				float gradientNoise143 = GradientNoise(texCoord146,( GradientScaleVar251 * 1.2 ));
				gradientNoise143 = gradientNoise143*0.5 + 0.5;
				float _MediumWavePower_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWavePower);
				float MediumWave140 = pow( ( 1.0 - abs( sin( ( ( ( ( _MediumWaveRotationX_Instance * WorldPosition.x ) + ( WorldPosition.z * _MediumWaveRotationZ_Instance ) ) * MediumWaveScaleVar300 ) + ( ( _MediumWaveSpeed_Instance * _TimeParameters.x ) + gradientNoise143 ) ) ) ) ) , _MediumWavePower_Instance );
				float _LargeWaveRotationX_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_LargeWaveRotationX);
				float _LargeWaveRotationZ_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_LargeWaveRotationZ);
				float LargeWaveScaleVar301 = 0.5;
				float _LargeWaveSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_LargeWaveSpeed);
				float2 appendResult187 = (float2(WorldPosition.x , WorldPosition.z));
				float2 texCoord192 = IN.ase_texcoord7.xyz.xy * appendResult187 + ( _TimeParameters.x * GradientSpeedVar250 );
				float gradientNoise193 = GradientNoise(texCoord192,GradientScaleVar251);
				gradientNoise193 = gradientNoise193*0.5 + 0.5;
				float _LargeWavePower_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_LargeWavePower);
				float LargeWave199 = pow( ( 1.0 - abs( sin( ( ( ( ( _LargeWaveRotationX_Instance * WorldPosition.x ) + ( WorldPosition.z * _LargeWaveRotationZ_Instance ) ) * LargeWaveScaleVar301 ) + ( ( _LargeWaveSpeed_Instance * _TimeParameters.x ) + gradientNoise193 ) ) ) ) ) , _LargeWavePower_Instance );
				float2 break308 = ( float2( 0,1 ) * ( ( MediumWaveScaleVar300 + LargeWaveScaleVar301 ) + 1.0 ) );
				float4 temp_cast_4 = (break308.x).xxxx;
				float4 temp_cast_5 = (break308.y).xxxx;
				float4 lerpResult315 = lerp( _TopDarkColour_Instance , _TopLightColour_Instance , ( CalculateContrast(_TopColourContrast_Instance,(float4( 0,0,0,0 ) + (( ( _MediumWaveColourBlend_Instance * ( float4(1,1,1,1) * MediumWave140 ).x ) + ( float4(1,1,1,1) * LargeWave199 ).x ) - temp_cast_4) * (float4( 1,1,1,1 ) - float4( 0,0,0,0 )) / (temp_cast_5 - temp_cast_4))) * IN.ase_color.g ));
				float4 lerpResult322 = lerp( lerpResult319 , lerpResult315 , pow( IN.ase_color.r , 40.0 ));
				float2 _RefractionStretch_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_RefractionStretch);
				float2 temp_output_419_0 = ( IN.ase_texcoord7.xyz.xy * _RefractionStretch_Instance );
				float2 uv411 = 0;
				float3 unityVoronoy411 = UnityVoronoi(temp_output_419_0,67.64,3.3,uv411);
				float simplePerlin2D406 = snoise( temp_output_419_0 );
				simplePerlin2D406 = simplePerlin2D406*0.5 + 0.5;
				float _RefractionScale_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_RefractionScale);
				float simpleNoise325 = SimpleNoise( IN.ase_texcoord7.xyz.xy*_RefractionScale_Instance );
				float _RefractionStrength_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_RefractionStrength);
				float temp_output_329_0 = ( ( simpleNoise325 - 0.7 ) * _RefractionStrength_Instance );
				float2 temp_cast_6 = (( ( unityVoronoy411.x + ( 1.0 - simplePerlin2D406 ) ) * temp_output_329_0 )).xx;
				float2 texCoord414 = IN.ase_texcoord7.xyz.xy * temp_cast_6 + float2( 0,0 );
				float _RefractionSize_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_RefractionSize);
				float2 temp_cast_8 = (temp_output_329_0).xx;
				float2 texCoord333 = IN.ase_texcoord7.xyz.xy * ( ScreenPos * _RefractionSize_Instance ).xy + temp_cast_8;
				float4 _RefractionColour_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_RefractionColour);
				float grayscale372 = (( float4( ( texCoord414 * ( 1.0 - texCoord333 ) ), 0.0 , 0.0 ) * _RefractionColour_Instance ).rgb.r + ( float4( ( texCoord414 * ( 1.0 - texCoord333 ) ), 0.0 , 0.0 ) * _RefractionColour_Instance ).rgb.g + ( float4( ( texCoord414 * ( 1.0 - texCoord333 ) ), 0.0 , 0.0 ) * _RefractionColour_Instance ).rgb.b) / 3;
				float4 temp_cast_11 = (grayscale372).xxxx;
				float4 blendOpSrc410 = lerpResult322;
				float4 blendOpDest410 = temp_cast_11;
				float _RefractionBlend_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_RefractionBlend);
				float4 lerpBlendMode410 = lerp(blendOpDest410,(( blendOpDest410 > 0.5 ) ? ( 1.0 - 2.0 * ( 1.0 - blendOpDest410 ) * ( 1.0 - blendOpSrc410 ) ) : ( 2.0 * blendOpDest410 * blendOpSrc410 ) ),_RefractionBlend_Instance);
				float4 RefractionAndColour344 = ( lerpResult322 + ( saturate( lerpBlendMode410 )) );
				
				float _Metallic_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_Metallic);
				
				float _Smoothness_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_Smoothness);
				
				float _WaterAlpha_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_WaterAlpha);
				
				float3 Albedo = ( ( fresnelNode395 + smoothstepResult393 ) * ( ( temp_output_360_0 * _FrothBlend_Instance ) + RefractionAndColour344 ) ).rgb;
				float3 Normal = float3(0, 0, 1);
				float3 Emission = 0;
				float3 Specular = 0.5;
				float Metallic = _Metallic_Instance;
				float Smoothness = _Smoothness_Instance;
				float Occlusion = 1;
				float Alpha = _WaterAlpha_Instance;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;
				float3 BakedGI = 0;
				float3 RefractionColor = 1;
				float RefractionIndex = 1;
				float3 Transmission = 1;
				float3 Translucency = 1;
				#ifdef ASE_DEPTH_WRITE_ON
				float DepthValue = 0;
				#endif

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				InputData inputData;
				inputData.positionWS = WorldPosition;
				inputData.viewDirectionWS = WorldViewDirection;
				inputData.shadowCoord = ShadowCoords;

				#ifdef _NORMALMAP
					#if _NORMAL_DROPOFF_TS
					inputData.normalWS = TransformTangentToWorld(Normal, half3x3( WorldTangent, WorldBiTangent, WorldNormal ));
					#elif _NORMAL_DROPOFF_OS
					inputData.normalWS = TransformObjectToWorldNormal(Normal);
					#elif _NORMAL_DROPOFF_WS
					inputData.normalWS = Normal;
					#endif
					inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
				#else
					inputData.normalWS = WorldNormal;
				#endif

				#ifdef ASE_FOG
					inputData.fogCoord = IN.fogFactorAndVertexLight.x;
				#endif

				inputData.vertexLighting = IN.fogFactorAndVertexLight.yzw;
				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					float3 SH = SampleSH(inputData.normalWS.xyz);
				#else
					float3 SH = IN.lightmapUVOrVertexSH.xyz;
				#endif

				inputData.bakedGI = SAMPLE_GI( IN.lightmapUVOrVertexSH.xy, SH, inputData.normalWS );
				#ifdef _ASE_BAKEDGI
					inputData.bakedGI = BakedGI;
				#endif
				half4 color = UniversalFragmentPBR(
					inputData, 
					Albedo, 
					Metallic, 
					Specular, 
					Smoothness, 
					Occlusion, 
					Emission, 
					Alpha);

				#ifdef _TRANSMISSION_ASE
				{
					float shadow = _TransmissionShadow;

					Light mainLight = GetMainLight( inputData.shadowCoord );
					float3 mainAtten = mainLight.color * mainLight.distanceAttenuation;
					mainAtten = lerp( mainAtten, mainAtten * mainLight.shadowAttenuation, shadow );
					half3 mainTransmission = max(0 , -dot(inputData.normalWS, mainLight.direction)) * mainAtten * Transmission;
					color.rgb += Albedo * mainTransmission;

					#ifdef _ADDITIONAL_LIGHTS
						int transPixelLightCount = GetAdditionalLightsCount();
						for (int i = 0; i < transPixelLightCount; ++i)
						{
							Light light = GetAdditionalLight(i, inputData.positionWS);
							float3 atten = light.color * light.distanceAttenuation;
							atten = lerp( atten, atten * light.shadowAttenuation, shadow );

							half3 transmission = max(0 , -dot(inputData.normalWS, light.direction)) * atten * Transmission;
							color.rgb += Albedo * transmission;
						}
					#endif
				}
				#endif

				#ifdef _TRANSLUCENCY_ASE
				{
					float shadow = _TransShadow;
					float normal = _TransNormal;
					float scattering = _TransScattering;
					float direct = _TransDirect;
					float ambient = _TransAmbient;
					float strength = _TransStrength;

					Light mainLight = GetMainLight( inputData.shadowCoord );
					float3 mainAtten = mainLight.color * mainLight.distanceAttenuation;
					mainAtten = lerp( mainAtten, mainAtten * mainLight.shadowAttenuation, shadow );

					half3 mainLightDir = mainLight.direction + inputData.normalWS * normal;
					half mainVdotL = pow( saturate( dot( inputData.viewDirectionWS, -mainLightDir ) ), scattering );
					half3 mainTranslucency = mainAtten * ( mainVdotL * direct + inputData.bakedGI * ambient ) * Translucency;
					color.rgb += Albedo * mainTranslucency * strength;

					#ifdef _ADDITIONAL_LIGHTS
						int transPixelLightCount = GetAdditionalLightsCount();
						for (int i = 0; i < transPixelLightCount; ++i)
						{
							Light light = GetAdditionalLight(i, inputData.positionWS);
							float3 atten = light.color * light.distanceAttenuation;
							atten = lerp( atten, atten * light.shadowAttenuation, shadow );

							half3 lightDir = light.direction + inputData.normalWS * normal;
							half VdotL = pow( saturate( dot( inputData.viewDirectionWS, -lightDir ) ), scattering );
							half3 translucency = atten * ( VdotL * direct + inputData.bakedGI * ambient ) * Translucency;
							color.rgb += Albedo * translucency * strength;
						}
					#endif
				}
				#endif

				#ifdef _REFRACTION_ASE
					float4 projScreenPos = ScreenPos / ScreenPos.w;
					float3 refractionOffset = ( RefractionIndex - 1.0 ) * mul( UNITY_MATRIX_V, float4( WorldNormal, 0 ) ).xyz * ( 1.0 - dot( WorldNormal, WorldViewDirection ) );
					projScreenPos.xy += refractionOffset.xy;
					float3 refraction = SHADERGRAPH_SAMPLE_SCENE_COLOR( projScreenPos.xy ) * RefractionColor;
					color.rgb = lerp( refraction, color.rgb, color.a );
					color.a = 1;
				#endif

				#ifdef ASE_FINAL_COLOR_ALPHA_MULTIPLY
					color.rgb *= color.a;
				#endif

				#ifdef ASE_FOG
					#ifdef TERRAIN_SPLAT_ADDPASS
						color.rgb = MixFogColor(color.rgb, half3( 0, 0, 0 ), IN.fogFactorAndVertexLight.x );
					#else
						color.rgb = MixFog(color.rgb, IN.fogFactorAndVertexLight.x);
					#endif
				#endif
				
				#ifdef ASE_DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif

				return color;
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" }

			ZWrite On
			ZTest LEqual
			AlphaToMask Off

			HLSLPROGRAM
			
			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define ASE_SRP_VERSION 80200

			
			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS_SHADOWCASTER

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			#define ASE_NEEDS_VERT_POSITION
			#pragma multi_compile_instancing


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
						#ifdef _TRANSMISSION_ASE
				float _TransmissionShadow;
			#endif
			#ifdef _TRANSLUCENCY_ASE
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			UNITY_INSTANCING_BUFFER_START(WaterShader)
				UNITY_DEFINE_INSTANCED_PROP(float2, _GradientSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _LargeWavePower)
				UNITY_DEFINE_INSTANCED_PROP(float, _LargeWaveSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _LargeWaveRotationZ)
				UNITY_DEFINE_INSTANCED_PROP(float, _LargeWaveRotationX)
				UNITY_DEFINE_INSTANCED_PROP(float, _MediumWaveHeight)
				UNITY_DEFINE_INSTANCED_PROP(float, _MediumWavePower)
				UNITY_DEFINE_INSTANCED_PROP(float, _GradientScale)
				UNITY_DEFINE_INSTANCED_PROP(float, _SmallWaveRotationX)
				UNITY_DEFINE_INSTANCED_PROP(float, _MediumWaveSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _MediumWaveRotationZ)
				UNITY_DEFINE_INSTANCED_PROP(float, _MediumWaveRotationX)
				UNITY_DEFINE_INSTANCED_PROP(float, _SmallWaveHeight)
				UNITY_DEFINE_INSTANCED_PROP(float, _SmallWavePower)
				UNITY_DEFINE_INSTANCED_PROP(float, _SmallWaveSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _SmallWaveRotationZ)
				UNITY_DEFINE_INSTANCED_PROP(float, _LargeWaveHeight)
				UNITY_DEFINE_INSTANCED_PROP(float, _WaterAlpha)
			UNITY_INSTANCING_BUFFER_END(WaterShader)


			//https://www.shadertoy.com/view/XdXGW8
			float2 GradientNoiseDir( float2 x )
			{
				const float2 k = float2( 0.3183099, 0.3678794 );
				x = x * k + k.yx;
				return -1.0 + 2.0 * frac( 16.0 * k * frac( x.x * x.y * ( x.x + x.y ) ) );
			}
			
			float GradientNoise( float2 UV, float Scale )
			{
				float2 p = UV * Scale;
				float2 i = floor( p );
				float2 f = frac( p );
				float2 u = f * f * ( 3.0 - 2.0 * f );
				return lerp( lerp( dot( GradientNoiseDir( i + float2( 0.0, 0.0 ) ), f - float2( 0.0, 0.0 ) ),
						dot( GradientNoiseDir( i + float2( 1.0, 0.0 ) ), f - float2( 1.0, 0.0 ) ), u.x ),
						lerp( dot( GradientNoiseDir( i + float2( 0.0, 1.0 ) ), f - float2( 0.0, 1.0 ) ),
						dot( GradientNoiseDir( i + float2( 1.0, 1.0 ) ), f - float2( 1.0, 1.0 ) ), u.x ), u.y );
			}
			

			float3 _LightDirection;

			VertexOutput VertexFunction( VertexInput v )
			{
				VertexOutput o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				float _SmallWaveRotationX_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_SmallWaveRotationX);
				float3 ase_worldPos = mul(GetObjectToWorldMatrix(), v.vertex).xyz;
				float _SmallWaveRotationZ_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_SmallWaveRotationZ);
				float _SmallWaveSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_SmallWaveSpeed);
				float _SmallWavePower_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_SmallWavePower);
				float SmallWave120 = pow( ( 1.0 - abs( sin( ( ( ( ( _SmallWaveRotationX_Instance * ase_worldPos.x ) + ( ase_worldPos.z * _SmallWaveRotationZ_Instance ) ) * 4.0 ) + ( _SmallWaveSpeed_Instance * _TimeParameters.x ) ) ) ) ) , _SmallWavePower_Instance );
				float _SmallWaveHeight_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_SmallWaveHeight);
				float _MediumWaveRotationX_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWaveRotationX);
				float _MediumWaveRotationZ_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWaveRotationZ);
				float MediumWaveScaleVar300 = 2.0;
				float _MediumWaveSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWaveSpeed);
				float2 appendResult156 = (float2(ase_worldPos.x , ase_worldPos.z));
				float2 _GradientSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_GradientSpeed);
				float2 GradientSpeedVar250 = _GradientSpeed_Instance;
				float2 texCoord146 = v.ase_texcoord.xy * appendResult156 + ( _TimeParameters.x * ( GradientSpeedVar250 * float2( 1.2,1.2 ) ) );
				float _GradientScale_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_GradientScale);
				float GradientScaleVar251 = _GradientScale_Instance;
				float gradientNoise143 = GradientNoise(texCoord146,( GradientScaleVar251 * 1.2 ));
				gradientNoise143 = gradientNoise143*0.5 + 0.5;
				float _MediumWavePower_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWavePower);
				float MediumWave140 = pow( ( 1.0 - abs( sin( ( ( ( ( _MediumWaveRotationX_Instance * ase_worldPos.x ) + ( ase_worldPos.z * _MediumWaveRotationZ_Instance ) ) * MediumWaveScaleVar300 ) + ( ( _MediumWaveSpeed_Instance * _TimeParameters.x ) + gradientNoise143 ) ) ) ) ) , _MediumWavePower_Instance );
				float _MediumWaveHeight_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWaveHeight);
				float _LargeWaveRotationX_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_LargeWaveRotationX);
				float _LargeWaveRotationZ_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_LargeWaveRotationZ);
				float LargeWaveScaleVar301 = 0.5;
				float _LargeWaveSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_LargeWaveSpeed);
				float2 appendResult187 = (float2(ase_worldPos.x , ase_worldPos.z));
				float2 texCoord192 = v.ase_texcoord.xy * appendResult187 + ( _TimeParameters.x * GradientSpeedVar250 );
				float gradientNoise193 = GradientNoise(texCoord192,GradientScaleVar251);
				gradientNoise193 = gradientNoise193*0.5 + 0.5;
				float _LargeWavePower_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_LargeWavePower);
				float LargeWave199 = pow( ( 1.0 - abs( sin( ( ( ( ( _LargeWaveRotationX_Instance * ase_worldPos.x ) + ( ase_worldPos.z * _LargeWaveRotationZ_Instance ) ) * LargeWaveScaleVar301 ) + ( ( _LargeWaveSpeed_Instance * _TimeParameters.x ) + gradientNoise193 ) ) ) ) ) , _LargeWavePower_Instance );
				float _LargeWaveHeight_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_LargeWaveHeight);
				float4 appendResult219 = (float4(ase_worldPos.x , ase_worldPos.z , 0.0 , 0.0));
				float2 texCoord220 = v.ase_texcoord.xy * appendResult219.xy + ( _TimeParameters.x * GradientSpeedVar250 );
				float gradientNoise226 = GradientNoise(texCoord220,GradientScaleVar251);
				gradientNoise226 = gradientNoise226*0.5 + 0.5;
				float WorldScale233 = gradientNoise226;
				float4 break258 = ( float4(1,1,1,1) * ( ( ( SmallWave120 * _SmallWaveHeight_Instance ) + ( MediumWave140 * _MediumWaveHeight_Instance ) + ( LargeWave199 * _LargeWaveHeight_Instance ) ) * WorldScale233 ) );
				float4 appendResult246 = (float4(v.vertex.xyz.x , ( ( break258.x + break258.z ) + v.vertex.xyz.y ) , v.vertex.xyz.z , 0.0));
				float4 lerpResult263 = lerp( float4( ( v.vertex.xyz / float3( 2,2,2 ) ) , 0.0 ) , appendResult246 , v.ase_color.r);
				float3 temp_output_278_0 = v.vertex.xyz;
				float4 lerpResult266 = lerp( lerpResult263 , float4( ( temp_output_278_0 / ( 1.1 * 10.0 ) ) , 0.0 ) , ( v.ase_color.g * 1.1 ));
				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = lerpResult266.xyz;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif
				float3 normalWS = TransformObjectToWorldDir(v.ase_normal);

				float4 clipPos = TransformWorldToHClip( ApplyShadowBias( positionWS, normalWS, _LightDirection ) );

				#if UNITY_REVERSED_Z
					clipPos.z = min(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
				#else
					clipPos.z = max(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = clipPos;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				o.clipPos = clipPos;
				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_color : COLOR;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_color = v.ase_color;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE)
				#define ASE_SV_DEPTH SV_DepthLessEqual  
			#else
				#define ASE_SV_DEPTH SV_Depth
			#endif

			half4 frag(	VertexOutput IN 
						#ifdef ASE_DEPTH_WRITE_ON
						,out float outputDepth : ASE_SV_DEPTH
						#endif
						 ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );
				
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float _WaterAlpha_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_WaterAlpha);
				
				float Alpha = _WaterAlpha_Instance;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;
				#ifdef ASE_DEPTH_WRITE_ON
				float DepthValue = 0;
				#endif

				#ifdef _ALPHATEST_ON
					#ifdef _ALPHATEST_SHADOW_ON
						clip(Alpha - AlphaClipThresholdShadow);
					#else
						clip(Alpha - AlphaClipThreshold);
					#endif
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif
				#ifdef ASE_DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif
				return 0;
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthOnly"
			Tags { "LightMode"="DepthOnly" }

			ZWrite On
			ColorMask 0
			AlphaToMask Off

			HLSLPROGRAM
			
			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define ASE_SRP_VERSION 80200

			
			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			#define ASE_NEEDS_VERT_POSITION
			#pragma multi_compile_instancing


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
						#ifdef _TRANSMISSION_ASE
				float _TransmissionShadow;
			#endif
			#ifdef _TRANSLUCENCY_ASE
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			UNITY_INSTANCING_BUFFER_START(WaterShader)
				UNITY_DEFINE_INSTANCED_PROP(float2, _GradientSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _LargeWavePower)
				UNITY_DEFINE_INSTANCED_PROP(float, _LargeWaveSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _LargeWaveRotationZ)
				UNITY_DEFINE_INSTANCED_PROP(float, _LargeWaveRotationX)
				UNITY_DEFINE_INSTANCED_PROP(float, _MediumWaveHeight)
				UNITY_DEFINE_INSTANCED_PROP(float, _MediumWavePower)
				UNITY_DEFINE_INSTANCED_PROP(float, _GradientScale)
				UNITY_DEFINE_INSTANCED_PROP(float, _SmallWaveRotationX)
				UNITY_DEFINE_INSTANCED_PROP(float, _MediumWaveSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _MediumWaveRotationZ)
				UNITY_DEFINE_INSTANCED_PROP(float, _MediumWaveRotationX)
				UNITY_DEFINE_INSTANCED_PROP(float, _SmallWaveHeight)
				UNITY_DEFINE_INSTANCED_PROP(float, _SmallWavePower)
				UNITY_DEFINE_INSTANCED_PROP(float, _SmallWaveSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _SmallWaveRotationZ)
				UNITY_DEFINE_INSTANCED_PROP(float, _LargeWaveHeight)
				UNITY_DEFINE_INSTANCED_PROP(float, _WaterAlpha)
			UNITY_INSTANCING_BUFFER_END(WaterShader)


			//https://www.shadertoy.com/view/XdXGW8
			float2 GradientNoiseDir( float2 x )
			{
				const float2 k = float2( 0.3183099, 0.3678794 );
				x = x * k + k.yx;
				return -1.0 + 2.0 * frac( 16.0 * k * frac( x.x * x.y * ( x.x + x.y ) ) );
			}
			
			float GradientNoise( float2 UV, float Scale )
			{
				float2 p = UV * Scale;
				float2 i = floor( p );
				float2 f = frac( p );
				float2 u = f * f * ( 3.0 - 2.0 * f );
				return lerp( lerp( dot( GradientNoiseDir( i + float2( 0.0, 0.0 ) ), f - float2( 0.0, 0.0 ) ),
						dot( GradientNoiseDir( i + float2( 1.0, 0.0 ) ), f - float2( 1.0, 0.0 ) ), u.x ),
						lerp( dot( GradientNoiseDir( i + float2( 0.0, 1.0 ) ), f - float2( 0.0, 1.0 ) ),
						dot( GradientNoiseDir( i + float2( 1.0, 1.0 ) ), f - float2( 1.0, 1.0 ) ), u.x ), u.y );
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float _SmallWaveRotationX_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_SmallWaveRotationX);
				float3 ase_worldPos = mul(GetObjectToWorldMatrix(), v.vertex).xyz;
				float _SmallWaveRotationZ_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_SmallWaveRotationZ);
				float _SmallWaveSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_SmallWaveSpeed);
				float _SmallWavePower_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_SmallWavePower);
				float SmallWave120 = pow( ( 1.0 - abs( sin( ( ( ( ( _SmallWaveRotationX_Instance * ase_worldPos.x ) + ( ase_worldPos.z * _SmallWaveRotationZ_Instance ) ) * 4.0 ) + ( _SmallWaveSpeed_Instance * _TimeParameters.x ) ) ) ) ) , _SmallWavePower_Instance );
				float _SmallWaveHeight_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_SmallWaveHeight);
				float _MediumWaveRotationX_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWaveRotationX);
				float _MediumWaveRotationZ_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWaveRotationZ);
				float MediumWaveScaleVar300 = 2.0;
				float _MediumWaveSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWaveSpeed);
				float2 appendResult156 = (float2(ase_worldPos.x , ase_worldPos.z));
				float2 _GradientSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_GradientSpeed);
				float2 GradientSpeedVar250 = _GradientSpeed_Instance;
				float2 texCoord146 = v.ase_texcoord.xy * appendResult156 + ( _TimeParameters.x * ( GradientSpeedVar250 * float2( 1.2,1.2 ) ) );
				float _GradientScale_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_GradientScale);
				float GradientScaleVar251 = _GradientScale_Instance;
				float gradientNoise143 = GradientNoise(texCoord146,( GradientScaleVar251 * 1.2 ));
				gradientNoise143 = gradientNoise143*0.5 + 0.5;
				float _MediumWavePower_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWavePower);
				float MediumWave140 = pow( ( 1.0 - abs( sin( ( ( ( ( _MediumWaveRotationX_Instance * ase_worldPos.x ) + ( ase_worldPos.z * _MediumWaveRotationZ_Instance ) ) * MediumWaveScaleVar300 ) + ( ( _MediumWaveSpeed_Instance * _TimeParameters.x ) + gradientNoise143 ) ) ) ) ) , _MediumWavePower_Instance );
				float _MediumWaveHeight_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWaveHeight);
				float _LargeWaveRotationX_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_LargeWaveRotationX);
				float _LargeWaveRotationZ_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_LargeWaveRotationZ);
				float LargeWaveScaleVar301 = 0.5;
				float _LargeWaveSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_LargeWaveSpeed);
				float2 appendResult187 = (float2(ase_worldPos.x , ase_worldPos.z));
				float2 texCoord192 = v.ase_texcoord.xy * appendResult187 + ( _TimeParameters.x * GradientSpeedVar250 );
				float gradientNoise193 = GradientNoise(texCoord192,GradientScaleVar251);
				gradientNoise193 = gradientNoise193*0.5 + 0.5;
				float _LargeWavePower_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_LargeWavePower);
				float LargeWave199 = pow( ( 1.0 - abs( sin( ( ( ( ( _LargeWaveRotationX_Instance * ase_worldPos.x ) + ( ase_worldPos.z * _LargeWaveRotationZ_Instance ) ) * LargeWaveScaleVar301 ) + ( ( _LargeWaveSpeed_Instance * _TimeParameters.x ) + gradientNoise193 ) ) ) ) ) , _LargeWavePower_Instance );
				float _LargeWaveHeight_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_LargeWaveHeight);
				float4 appendResult219 = (float4(ase_worldPos.x , ase_worldPos.z , 0.0 , 0.0));
				float2 texCoord220 = v.ase_texcoord.xy * appendResult219.xy + ( _TimeParameters.x * GradientSpeedVar250 );
				float gradientNoise226 = GradientNoise(texCoord220,GradientScaleVar251);
				gradientNoise226 = gradientNoise226*0.5 + 0.5;
				float WorldScale233 = gradientNoise226;
				float4 break258 = ( float4(1,1,1,1) * ( ( ( SmallWave120 * _SmallWaveHeight_Instance ) + ( MediumWave140 * _MediumWaveHeight_Instance ) + ( LargeWave199 * _LargeWaveHeight_Instance ) ) * WorldScale233 ) );
				float4 appendResult246 = (float4(v.vertex.xyz.x , ( ( break258.x + break258.z ) + v.vertex.xyz.y ) , v.vertex.xyz.z , 0.0));
				float4 lerpResult263 = lerp( float4( ( v.vertex.xyz / float3( 2,2,2 ) ) , 0.0 ) , appendResult246 , v.ase_color.r);
				float3 temp_output_278_0 = v.vertex.xyz;
				float4 lerpResult266 = lerp( lerpResult263 , float4( ( temp_output_278_0 / ( 1.1 * 10.0 ) ) , 0.0 ) , ( v.ase_color.g * 1.1 ));
				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = lerpResult266.xyz;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;
				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				o.clipPos = positionCS;
				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_color : COLOR;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_color = v.ase_color;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE)
				#define ASE_SV_DEPTH SV_DepthLessEqual  
			#else
				#define ASE_SV_DEPTH SV_Depth
			#endif
			half4 frag(	VertexOutput IN 
						#ifdef ASE_DEPTH_WRITE_ON
						,out float outputDepth : ASE_SV_DEPTH
						#endif
						 ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float _WaterAlpha_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_WaterAlpha);
				
				float Alpha = _WaterAlpha_Instance;
				float AlphaClipThreshold = 0.5;
				#ifdef ASE_DEPTH_WRITE_ON
				float DepthValue = 0;
				#endif

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif
				#ifdef ASE_DEPTH_WRITE_ON
				outputDepth = DepthValue;
				#endif
				return 0;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "Meta"
			Tags { "LightMode"="Meta" }

			Cull Off

			HLSLPROGRAM
			
			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define ASE_SRP_VERSION 80200
			#define REQUIRE_DEPTH_TEXTURE 1

			
			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS_META

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_COLOR
			#pragma multi_compile_instancing


			#pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
						#ifdef _TRANSMISSION_ASE
				float _TransmissionShadow;
			#endif
			#ifdef _TRANSLUCENCY_ASE
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			uniform float4 _CameraDepthTexture_TexelSize;
			UNITY_INSTANCING_BUFFER_START(WaterShader)
				UNITY_DEFINE_INSTANCED_PROP(float4, _TopLightColour)
				UNITY_DEFINE_INSTANCED_PROP(float4, _RefractionColour)
				UNITY_DEFINE_INSTANCED_PROP(float4, _BottomDarkColour)
				UNITY_DEFINE_INSTANCED_PROP(float4, _BottomLightColour)
				UNITY_DEFINE_INSTANCED_PROP(float4, _TopDarkColour)
				UNITY_DEFINE_INSTANCED_PROP(float4, _MediumWaveColourBlend)
				UNITY_DEFINE_INSTANCED_PROP(float2, _FrothDirection)
				UNITY_DEFINE_INSTANCED_PROP(float2, _GradientSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float2, _FrothStretch)
				UNITY_DEFINE_INSTANCED_PROP(float2, _RefractionStretch)
				UNITY_DEFINE_INSTANCED_PROP(float, _RefractionScale)
				UNITY_DEFINE_INSTANCED_PROP(float, _RefractionStrength)
				UNITY_DEFINE_INSTANCED_PROP(float, _RefractionSize)
				UNITY_DEFINE_INSTANCED_PROP(float, _FrothBlend)
				UNITY_DEFINE_INSTANCED_PROP(float, _FrothScaleSmall)
				UNITY_DEFINE_INSTANCED_PROP(float, _FrothScaleBig)
				UNITY_DEFINE_INSTANCED_PROP(float, _FrothSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _TopColourContrast)
				UNITY_DEFINE_INSTANCED_PROP(float, _SmallWaveRotationX)
				UNITY_DEFINE_INSTANCED_PROP(float, _FrothStep)
				UNITY_DEFINE_INSTANCED_PROP(float, _Offset)
				UNITY_DEFINE_INSTANCED_PROP(float, _SmallWaveRotationZ)
				UNITY_DEFINE_INSTANCED_PROP(float, _SmallWaveSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _SmallWavePower)
				UNITY_DEFINE_INSTANCED_PROP(float, _SmallWaveHeight)
				UNITY_DEFINE_INSTANCED_PROP(float, _MediumWaveRotationX)
				UNITY_DEFINE_INSTANCED_PROP(float, _MediumWaveRotationZ)
				UNITY_DEFINE_INSTANCED_PROP(float, _MediumWaveSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _RefractionBlend)
				UNITY_DEFINE_INSTANCED_PROP(float, _GradientScale)
				UNITY_DEFINE_INSTANCED_PROP(float, _MediumWaveHeight)
				UNITY_DEFINE_INSTANCED_PROP(float, _LargeWaveRotationX)
				UNITY_DEFINE_INSTANCED_PROP(float, _LargeWaveRotationZ)
				UNITY_DEFINE_INSTANCED_PROP(float, _LargeWaveSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _LargeWavePower)
				UNITY_DEFINE_INSTANCED_PROP(float, _LargeWaveHeight)
				UNITY_DEFINE_INSTANCED_PROP(float, _FresenelPower)
				UNITY_DEFINE_INSTANCED_PROP(float, _MediumWavePower)
				UNITY_DEFINE_INSTANCED_PROP(float, _WaterAlpha)
			UNITY_INSTANCING_BUFFER_END(WaterShader)


			//https://www.shadertoy.com/view/XdXGW8
			float2 GradientNoiseDir( float2 x )
			{
				const float2 k = float2( 0.3183099, 0.3678794 );
				x = x * k + k.yx;
				return -1.0 + 2.0 * frac( 16.0 * k * frac( x.x * x.y * ( x.x + x.y ) ) );
			}
			
			float GradientNoise( float2 UV, float Scale )
			{
				float2 p = UV * Scale;
				float2 i = floor( p );
				float2 f = frac( p );
				float2 u = f * f * ( 3.0 - 2.0 * f );
				return lerp( lerp( dot( GradientNoiseDir( i + float2( 0.0, 0.0 ) ), f - float2( 0.0, 0.0 ) ),
						dot( GradientNoiseDir( i + float2( 1.0, 0.0 ) ), f - float2( 1.0, 0.0 ) ), u.x ),
						lerp( dot( GradientNoiseDir( i + float2( 0.0, 1.0 ) ), f - float2( 0.0, 1.0 ) ),
						dot( GradientNoiseDir( i + float2( 1.0, 1.0 ) ), f - float2( 1.0, 1.0 ) ), u.x ), u.y );
			}
			
			inline float noise_randomValue (float2 uv) { return frac(sin(dot(uv, float2(12.9898, 78.233)))*43758.5453); }
			inline float noise_interpolate (float a, float b, float t) { return (1.0-t)*a + (t*b); }
			inline float valueNoise (float2 uv)
			{
				float2 i = floor(uv);
				float2 f = frac( uv );
				f = f* f * (3.0 - 2.0 * f);
				uv = abs( frac(uv) - 0.5);
				float2 c0 = i + float2( 0.0, 0.0 );
				float2 c1 = i + float2( 1.0, 0.0 );
				float2 c2 = i + float2( 0.0, 1.0 );
				float2 c3 = i + float2( 1.0, 1.0 );
				float r0 = noise_randomValue( c0 );
				float r1 = noise_randomValue( c1 );
				float r2 = noise_randomValue( c2 );
				float r3 = noise_randomValue( c3 );
				float bottomOfGrid = noise_interpolate( r0, r1, f.x );
				float topOfGrid = noise_interpolate( r2, r3, f.x );
				float t = noise_interpolate( bottomOfGrid, topOfGrid, f.y );
				return t;
			}
			
			float SimpleNoise(float2 UV)
			{
				float t = 0.0;
				float freq = pow( 2.0, float( 0 ) );
				float amp = pow( 0.5, float( 3 - 0 ) );
				t += valueNoise( UV/freq )*amp;
				freq = pow(2.0, float(1));
				amp = pow(0.5, float(3-1));
				t += valueNoise( UV/freq )*amp;
				freq = pow(2.0, float(2));
				amp = pow(0.5, float(3-2));
				t += valueNoise( UV/freq )*amp;
				return t;
			}
			
			float4 CalculateContrast( float contrastValue, float4 colorTarget )
			{
				float t = 0.5 * ( 1.0 - contrastValue );
				return mul( float4x4( contrastValue,0,0,t, 0,contrastValue,0,t, 0,0,contrastValue,t, 0,0,0,1 ), colorTarget );
			}
			inline float2 UnityVoronoiRandomVector( float2 UV, float offset )
			{
				float2x2 m = float2x2( 15.27, 47.63, 99.41, 89.98 );
				UV = frac( sin(mul(UV, m) ) * 46839.32 );
				return float2( sin(UV.y* +offset ) * 0.5 + 0.5, cos( UV.x* offset ) * 0.5 + 0.5 );
			}
			
			//x - Out y - Cells
			float3 UnityVoronoi( float2 UV, float AngleOffset, float CellDensity, inout float2 mr )
			{
				float2 g = floor( UV * CellDensity );
				float2 f = frac( UV * CellDensity );
				float t = 8.0;
				float3 res = float3( 8.0, 0.0, 0.0 );
			
				for( int y = -1; y <= 1; y++ )
				{
					for( int x = -1; x <= 1; x++ )
					{
						float2 lattice = float2( x, y );
						float2 offset = UnityVoronoiRandomVector( lattice + g, AngleOffset );
						float d = distance( lattice + offset, f );
			
						if( d < res.x )
						{
							mr = f - lattice - offset;
							res = float3( d, offset.x, offset.y );
						}
					}
				}
				return res;
			}
			
			float3 mod2D289( float3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float2 mod2D289( float2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float3 permute( float3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }
			float snoise( float2 v )
			{
				const float4 C = float4( 0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439 );
				float2 i = floor( v + dot( v, C.yy ) );
				float2 x0 = v - i + dot( i, C.xx );
				float2 i1;
				i1 = ( x0.x > x0.y ) ? float2( 1.0, 0.0 ) : float2( 0.0, 1.0 );
				float4 x12 = x0.xyxy + C.xxzz;
				x12.xy -= i1;
				i = mod2D289( i );
				float3 p = permute( permute( i.y + float3( 0.0, i1.y, 1.0 ) ) + i.x + float3( 0.0, i1.x, 1.0 ) );
				float3 m = max( 0.5 - float3( dot( x0, x0 ), dot( x12.xy, x12.xy ), dot( x12.zw, x12.zw ) ), 0.0 );
				m = m * m;
				m = m * m;
				float3 x = 2.0 * frac( p * C.www ) - 1.0;
				float3 h = abs( x ) - 0.5;
				float3 ox = floor( x + 0.5 );
				float3 a0 = x - ox;
				m *= 1.79284291400159 - 0.85373472095314 * ( a0 * a0 + h * h );
				float3 g;
				g.x = a0.x * x0.x + h.x * x0.y;
				g.yz = a0.yz * x12.xz + h.yz * x12.yw;
				return 130.0 * dot( m, g );
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float _SmallWaveRotationX_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_SmallWaveRotationX);
				float3 ase_worldPos = mul(GetObjectToWorldMatrix(), v.vertex).xyz;
				float _SmallWaveRotationZ_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_SmallWaveRotationZ);
				float _SmallWaveSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_SmallWaveSpeed);
				float _SmallWavePower_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_SmallWavePower);
				float SmallWave120 = pow( ( 1.0 - abs( sin( ( ( ( ( _SmallWaveRotationX_Instance * ase_worldPos.x ) + ( ase_worldPos.z * _SmallWaveRotationZ_Instance ) ) * 4.0 ) + ( _SmallWaveSpeed_Instance * _TimeParameters.x ) ) ) ) ) , _SmallWavePower_Instance );
				float _SmallWaveHeight_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_SmallWaveHeight);
				float _MediumWaveRotationX_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWaveRotationX);
				float _MediumWaveRotationZ_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWaveRotationZ);
				float MediumWaveScaleVar300 = 2.0;
				float _MediumWaveSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWaveSpeed);
				float2 appendResult156 = (float2(ase_worldPos.x , ase_worldPos.z));
				float2 _GradientSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_GradientSpeed);
				float2 GradientSpeedVar250 = _GradientSpeed_Instance;
				float2 texCoord146 = v.ase_texcoord.xyz * appendResult156 + ( _TimeParameters.x * ( GradientSpeedVar250 * float2( 1.2,1.2 ) ) );
				float _GradientScale_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_GradientScale);
				float GradientScaleVar251 = _GradientScale_Instance;
				float gradientNoise143 = GradientNoise(texCoord146,( GradientScaleVar251 * 1.2 ));
				gradientNoise143 = gradientNoise143*0.5 + 0.5;
				float _MediumWavePower_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWavePower);
				float MediumWave140 = pow( ( 1.0 - abs( sin( ( ( ( ( _MediumWaveRotationX_Instance * ase_worldPos.x ) + ( ase_worldPos.z * _MediumWaveRotationZ_Instance ) ) * MediumWaveScaleVar300 ) + ( ( _MediumWaveSpeed_Instance * _TimeParameters.x ) + gradientNoise143 ) ) ) ) ) , _MediumWavePower_Instance );
				float _MediumWaveHeight_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWaveHeight);
				float _LargeWaveRotationX_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_LargeWaveRotationX);
				float _LargeWaveRotationZ_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_LargeWaveRotationZ);
				float LargeWaveScaleVar301 = 0.5;
				float _LargeWaveSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_LargeWaveSpeed);
				float2 appendResult187 = (float2(ase_worldPos.x , ase_worldPos.z));
				float2 texCoord192 = v.ase_texcoord.xy * appendResult187 + ( _TimeParameters.x * GradientSpeedVar250 );
				float gradientNoise193 = GradientNoise(texCoord192,GradientScaleVar251);
				gradientNoise193 = gradientNoise193*0.5 + 0.5;
				float _LargeWavePower_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_LargeWavePower);
				float LargeWave199 = pow( ( 1.0 - abs( sin( ( ( ( ( _LargeWaveRotationX_Instance * ase_worldPos.x ) + ( ase_worldPos.z * _LargeWaveRotationZ_Instance ) ) * LargeWaveScaleVar301 ) + ( ( _LargeWaveSpeed_Instance * _TimeParameters.x ) + gradientNoise193 ) ) ) ) ) , _LargeWavePower_Instance );
				float _LargeWaveHeight_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_LargeWaveHeight);
				float4 appendResult219 = (float4(ase_worldPos.x , ase_worldPos.z , 0.0 , 0.0));
				float2 texCoord220 = v.ase_texcoord.xy * appendResult219.xy + ( _TimeParameters.x * GradientSpeedVar250 );
				float gradientNoise226 = GradientNoise(texCoord220,GradientScaleVar251);
				gradientNoise226 = gradientNoise226*0.5 + 0.5;
				float WorldScale233 = gradientNoise226;
				float4 break258 = ( float4(1,1,1,1) * ( ( ( SmallWave120 * _SmallWaveHeight_Instance ) + ( MediumWave140 * _MediumWaveHeight_Instance ) + ( LargeWave199 * _LargeWaveHeight_Instance ) ) * WorldScale233 ) );
				float4 appendResult246 = (float4(v.vertex.xyz.x , ( ( break258.x + break258.z ) + v.vertex.xyz.y ) , v.vertex.xyz.z , 0.0));
				float4 lerpResult263 = lerp( float4( ( v.vertex.xyz / float3( 2,2,2 ) ) , 0.0 ) , appendResult246 , v.ase_color.r);
				float3 temp_output_278_0 = v.vertex.xyz;
				float4 lerpResult266 = lerp( lerpResult263 , float4( ( temp_output_278_0 / ( 1.1 * 10.0 ) ) , 0.0 ) , ( v.ase_color.g * 1.1 ));
				
				float3 ase_worldNormal = TransformObjectToWorldNormal(v.ase_normal);
				o.ase_texcoord2.xyz = ase_worldNormal;
				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord3 = screenPos;
				
				o.ase_texcoord4.xyz = v.ase_texcoord.xyz;
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.w = 0;
				o.ase_texcoord4.w = 0;
				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = lerpResult266.xyz;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif

				o.clipPos = MetaVertexPosition( v.vertex, v.texcoord1.xy, v.texcoord1.xy, unity_LightmapST, unity_DynamicLightmapST );
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = o.clipPos;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_color : COLOR;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.texcoord1 = v.texcoord1;
				o.texcoord2 = v.texcoord2;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_color = v.ase_color;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float3 ase_worldViewDir = ( _WorldSpaceCameraPos.xyz - WorldPosition );
				ase_worldViewDir = normalize(ase_worldViewDir);
				float3 ase_worldNormal = IN.ase_texcoord2.xyz;
				float _FresenelPower_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_FresenelPower);
				float fresnelNdotV395 = dot( ase_worldNormal, ase_worldViewDir );
				float fresnelNode395 = ( 0.0 + 1.0 * pow( 1.0 - fresnelNdotV395, _FresenelPower_Instance ) );
				float4 screenPos = IN.ase_texcoord3;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float eyeDepth390 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float _Offset_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_Offset);
				float smoothstepResult393 = smoothstep( 0.0 , 1.0 , ( 1.0 - ( eyeDepth390 - ( screenPos.w - _Offset_Instance ) ) ));
				float _FrothStep_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_FrothStep);
				float2 _FrothStretch_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_FrothStretch);
				float2 _FrothDirection_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_FrothDirection);
				float _FrothSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_FrothSpeed);
				float2 texCoord350 = IN.ase_texcoord4.xyz.xy * float2( 1,1 ) + ( _FrothDirection_Instance * ( _TimeParameters.x * _FrothSpeed_Instance ) );
				float _FrothScaleBig_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_FrothScaleBig);
				float simpleNoise352 = SimpleNoise( ( ( IN.ase_texcoord4.xyz * float3( _FrothStretch_Instance ,  0.0 ) ) + float3( texCoord350 ,  0.0 ) ).xy*_FrothScaleBig_Instance );
				float4 appendResult349 = (float4(WorldPosition.x , WorldPosition.z , 0.0 , 0.0));
				float _FrothScaleSmall_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_FrothScaleSmall);
				float simpleNoise358 = SimpleNoise( appendResult349.xy*_FrothScaleSmall_Instance );
				float temp_output_360_0 = step( _FrothStep_Instance , ( simpleNoise352 + ( simpleNoise358 * 0.2 ) ) );
				float _FrothBlend_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_FrothBlend);
				float4 _BottomDarkColour_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_BottomDarkColour);
				float4 _BottomLightColour_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_BottomLightColour);
				float2 texCoord318 = IN.ase_texcoord4.xyz.xy * float2( 1,1 ) + float2( 0,0 );
				float4 lerpResult319 = lerp( _BottomDarkColour_Instance , _BottomLightColour_Instance , texCoord318.y);
				float4 _TopDarkColour_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_TopDarkColour);
				float4 _TopLightColour_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_TopLightColour);
				float _TopColourContrast_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_TopColourContrast);
				float4 _MediumWaveColourBlend_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWaveColourBlend);
				float _MediumWaveRotationX_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWaveRotationX);
				float _MediumWaveRotationZ_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWaveRotationZ);
				float MediumWaveScaleVar300 = 2.0;
				float _MediumWaveSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWaveSpeed);
				float2 appendResult156 = (float2(WorldPosition.x , WorldPosition.z));
				float2 _GradientSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_GradientSpeed);
				float2 GradientSpeedVar250 = _GradientSpeed_Instance;
				float2 texCoord146 = IN.ase_texcoord4.xyz.xy * appendResult156 + ( _TimeParameters.x * ( GradientSpeedVar250 * float2( 1.2,1.2 ) ) );
				float _GradientScale_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_GradientScale);
				float GradientScaleVar251 = _GradientScale_Instance;
				float gradientNoise143 = GradientNoise(texCoord146,( GradientScaleVar251 * 1.2 ));
				gradientNoise143 = gradientNoise143*0.5 + 0.5;
				float _MediumWavePower_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWavePower);
				float MediumWave140 = pow( ( 1.0 - abs( sin( ( ( ( ( _MediumWaveRotationX_Instance * WorldPosition.x ) + ( WorldPosition.z * _MediumWaveRotationZ_Instance ) ) * MediumWaveScaleVar300 ) + ( ( _MediumWaveSpeed_Instance * _TimeParameters.x ) + gradientNoise143 ) ) ) ) ) , _MediumWavePower_Instance );
				float _LargeWaveRotationX_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_LargeWaveRotationX);
				float _LargeWaveRotationZ_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_LargeWaveRotationZ);
				float LargeWaveScaleVar301 = 0.5;
				float _LargeWaveSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_LargeWaveSpeed);
				float2 appendResult187 = (float2(WorldPosition.x , WorldPosition.z));
				float2 texCoord192 = IN.ase_texcoord4.xyz.xy * appendResult187 + ( _TimeParameters.x * GradientSpeedVar250 );
				float gradientNoise193 = GradientNoise(texCoord192,GradientScaleVar251);
				gradientNoise193 = gradientNoise193*0.5 + 0.5;
				float _LargeWavePower_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_LargeWavePower);
				float LargeWave199 = pow( ( 1.0 - abs( sin( ( ( ( ( _LargeWaveRotationX_Instance * WorldPosition.x ) + ( WorldPosition.z * _LargeWaveRotationZ_Instance ) ) * LargeWaveScaleVar301 ) + ( ( _LargeWaveSpeed_Instance * _TimeParameters.x ) + gradientNoise193 ) ) ) ) ) , _LargeWavePower_Instance );
				float2 break308 = ( float2( 0,1 ) * ( ( MediumWaveScaleVar300 + LargeWaveScaleVar301 ) + 1.0 ) );
				float4 temp_cast_4 = (break308.x).xxxx;
				float4 temp_cast_5 = (break308.y).xxxx;
				float4 lerpResult315 = lerp( _TopDarkColour_Instance , _TopLightColour_Instance , ( CalculateContrast(_TopColourContrast_Instance,(float4( 0,0,0,0 ) + (( ( _MediumWaveColourBlend_Instance * ( float4(1,1,1,1) * MediumWave140 ).x ) + ( float4(1,1,1,1) * LargeWave199 ).x ) - temp_cast_4) * (float4( 1,1,1,1 ) - float4( 0,0,0,0 )) / (temp_cast_5 - temp_cast_4))) * IN.ase_color.g ));
				float4 lerpResult322 = lerp( lerpResult319 , lerpResult315 , pow( IN.ase_color.r , 40.0 ));
				float2 _RefractionStretch_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_RefractionStretch);
				float2 temp_output_419_0 = ( IN.ase_texcoord4.xyz.xy * _RefractionStretch_Instance );
				float2 uv411 = 0;
				float3 unityVoronoy411 = UnityVoronoi(temp_output_419_0,67.64,3.3,uv411);
				float simplePerlin2D406 = snoise( temp_output_419_0 );
				simplePerlin2D406 = simplePerlin2D406*0.5 + 0.5;
				float _RefractionScale_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_RefractionScale);
				float simpleNoise325 = SimpleNoise( IN.ase_texcoord4.xyz.xy*_RefractionScale_Instance );
				float _RefractionStrength_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_RefractionStrength);
				float temp_output_329_0 = ( ( simpleNoise325 - 0.7 ) * _RefractionStrength_Instance );
				float2 temp_cast_6 = (( ( unityVoronoy411.x + ( 1.0 - simplePerlin2D406 ) ) * temp_output_329_0 )).xx;
				float2 texCoord414 = IN.ase_texcoord4.xyz.xy * temp_cast_6 + float2( 0,0 );
				float _RefractionSize_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_RefractionSize);
				float2 temp_cast_8 = (temp_output_329_0).xx;
				float2 texCoord333 = IN.ase_texcoord4.xyz.xy * ( screenPos * _RefractionSize_Instance ).xy + temp_cast_8;
				float4 _RefractionColour_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_RefractionColour);
				float grayscale372 = (( float4( ( texCoord414 * ( 1.0 - texCoord333 ) ), 0.0 , 0.0 ) * _RefractionColour_Instance ).rgb.r + ( float4( ( texCoord414 * ( 1.0 - texCoord333 ) ), 0.0 , 0.0 ) * _RefractionColour_Instance ).rgb.g + ( float4( ( texCoord414 * ( 1.0 - texCoord333 ) ), 0.0 , 0.0 ) * _RefractionColour_Instance ).rgb.b) / 3;
				float4 temp_cast_11 = (grayscale372).xxxx;
				float4 blendOpSrc410 = lerpResult322;
				float4 blendOpDest410 = temp_cast_11;
				float _RefractionBlend_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_RefractionBlend);
				float4 lerpBlendMode410 = lerp(blendOpDest410,(( blendOpDest410 > 0.5 ) ? ( 1.0 - 2.0 * ( 1.0 - blendOpDest410 ) * ( 1.0 - blendOpSrc410 ) ) : ( 2.0 * blendOpDest410 * blendOpSrc410 ) ),_RefractionBlend_Instance);
				float4 RefractionAndColour344 = ( lerpResult322 + ( saturate( lerpBlendMode410 )) );
				
				float _WaterAlpha_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_WaterAlpha);
				
				
				float3 Albedo = ( ( fresnelNode395 + smoothstepResult393 ) * ( ( temp_output_360_0 * _FrothBlend_Instance ) + RefractionAndColour344 ) ).rgb;
				float3 Emission = 0;
				float Alpha = _WaterAlpha_Instance;
				float AlphaClipThreshold = 0.5;

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				MetaInput metaInput = (MetaInput)0;
				metaInput.Albedo = Albedo;
				metaInput.Emission = Emission;
				
				return MetaFragment(metaInput);
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "Universal2D"
			Tags { "LightMode"="Universal2D" }

			Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
			ZWrite Off
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA

			HLSLPROGRAM
			
			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define ASE_SRP_VERSION 80200
			#define REQUIRE_DEPTH_TEXTURE 1

			
			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS_2D

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			
			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_COLOR
			#pragma multi_compile_instancing


			#pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
						#ifdef _TRANSMISSION_ASE
				float _TransmissionShadow;
			#endif
			#ifdef _TRANSLUCENCY_ASE
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			uniform float4 _CameraDepthTexture_TexelSize;
			UNITY_INSTANCING_BUFFER_START(WaterShader)
				UNITY_DEFINE_INSTANCED_PROP(float4, _TopLightColour)
				UNITY_DEFINE_INSTANCED_PROP(float4, _RefractionColour)
				UNITY_DEFINE_INSTANCED_PROP(float4, _BottomDarkColour)
				UNITY_DEFINE_INSTANCED_PROP(float4, _BottomLightColour)
				UNITY_DEFINE_INSTANCED_PROP(float4, _TopDarkColour)
				UNITY_DEFINE_INSTANCED_PROP(float4, _MediumWaveColourBlend)
				UNITY_DEFINE_INSTANCED_PROP(float2, _FrothDirection)
				UNITY_DEFINE_INSTANCED_PROP(float2, _GradientSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float2, _FrothStretch)
				UNITY_DEFINE_INSTANCED_PROP(float2, _RefractionStretch)
				UNITY_DEFINE_INSTANCED_PROP(float, _RefractionScale)
				UNITY_DEFINE_INSTANCED_PROP(float, _RefractionStrength)
				UNITY_DEFINE_INSTANCED_PROP(float, _RefractionSize)
				UNITY_DEFINE_INSTANCED_PROP(float, _FrothBlend)
				UNITY_DEFINE_INSTANCED_PROP(float, _FrothScaleSmall)
				UNITY_DEFINE_INSTANCED_PROP(float, _FrothScaleBig)
				UNITY_DEFINE_INSTANCED_PROP(float, _FrothSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _TopColourContrast)
				UNITY_DEFINE_INSTANCED_PROP(float, _SmallWaveRotationX)
				UNITY_DEFINE_INSTANCED_PROP(float, _FrothStep)
				UNITY_DEFINE_INSTANCED_PROP(float, _Offset)
				UNITY_DEFINE_INSTANCED_PROP(float, _SmallWaveRotationZ)
				UNITY_DEFINE_INSTANCED_PROP(float, _SmallWaveSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _SmallWavePower)
				UNITY_DEFINE_INSTANCED_PROP(float, _SmallWaveHeight)
				UNITY_DEFINE_INSTANCED_PROP(float, _MediumWaveRotationX)
				UNITY_DEFINE_INSTANCED_PROP(float, _MediumWaveRotationZ)
				UNITY_DEFINE_INSTANCED_PROP(float, _MediumWaveSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _RefractionBlend)
				UNITY_DEFINE_INSTANCED_PROP(float, _GradientScale)
				UNITY_DEFINE_INSTANCED_PROP(float, _MediumWaveHeight)
				UNITY_DEFINE_INSTANCED_PROP(float, _LargeWaveRotationX)
				UNITY_DEFINE_INSTANCED_PROP(float, _LargeWaveRotationZ)
				UNITY_DEFINE_INSTANCED_PROP(float, _LargeWaveSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _LargeWavePower)
				UNITY_DEFINE_INSTANCED_PROP(float, _LargeWaveHeight)
				UNITY_DEFINE_INSTANCED_PROP(float, _FresenelPower)
				UNITY_DEFINE_INSTANCED_PROP(float, _MediumWavePower)
				UNITY_DEFINE_INSTANCED_PROP(float, _WaterAlpha)
			UNITY_INSTANCING_BUFFER_END(WaterShader)


			//https://www.shadertoy.com/view/XdXGW8
			float2 GradientNoiseDir( float2 x )
			{
				const float2 k = float2( 0.3183099, 0.3678794 );
				x = x * k + k.yx;
				return -1.0 + 2.0 * frac( 16.0 * k * frac( x.x * x.y * ( x.x + x.y ) ) );
			}
			
			float GradientNoise( float2 UV, float Scale )
			{
				float2 p = UV * Scale;
				float2 i = floor( p );
				float2 f = frac( p );
				float2 u = f * f * ( 3.0 - 2.0 * f );
				return lerp( lerp( dot( GradientNoiseDir( i + float2( 0.0, 0.0 ) ), f - float2( 0.0, 0.0 ) ),
						dot( GradientNoiseDir( i + float2( 1.0, 0.0 ) ), f - float2( 1.0, 0.0 ) ), u.x ),
						lerp( dot( GradientNoiseDir( i + float2( 0.0, 1.0 ) ), f - float2( 0.0, 1.0 ) ),
						dot( GradientNoiseDir( i + float2( 1.0, 1.0 ) ), f - float2( 1.0, 1.0 ) ), u.x ), u.y );
			}
			
			inline float noise_randomValue (float2 uv) { return frac(sin(dot(uv, float2(12.9898, 78.233)))*43758.5453); }
			inline float noise_interpolate (float a, float b, float t) { return (1.0-t)*a + (t*b); }
			inline float valueNoise (float2 uv)
			{
				float2 i = floor(uv);
				float2 f = frac( uv );
				f = f* f * (3.0 - 2.0 * f);
				uv = abs( frac(uv) - 0.5);
				float2 c0 = i + float2( 0.0, 0.0 );
				float2 c1 = i + float2( 1.0, 0.0 );
				float2 c2 = i + float2( 0.0, 1.0 );
				float2 c3 = i + float2( 1.0, 1.0 );
				float r0 = noise_randomValue( c0 );
				float r1 = noise_randomValue( c1 );
				float r2 = noise_randomValue( c2 );
				float r3 = noise_randomValue( c3 );
				float bottomOfGrid = noise_interpolate( r0, r1, f.x );
				float topOfGrid = noise_interpolate( r2, r3, f.x );
				float t = noise_interpolate( bottomOfGrid, topOfGrid, f.y );
				return t;
			}
			
			float SimpleNoise(float2 UV)
			{
				float t = 0.0;
				float freq = pow( 2.0, float( 0 ) );
				float amp = pow( 0.5, float( 3 - 0 ) );
				t += valueNoise( UV/freq )*amp;
				freq = pow(2.0, float(1));
				amp = pow(0.5, float(3-1));
				t += valueNoise( UV/freq )*amp;
				freq = pow(2.0, float(2));
				amp = pow(0.5, float(3-2));
				t += valueNoise( UV/freq )*amp;
				return t;
			}
			
			float4 CalculateContrast( float contrastValue, float4 colorTarget )
			{
				float t = 0.5 * ( 1.0 - contrastValue );
				return mul( float4x4( contrastValue,0,0,t, 0,contrastValue,0,t, 0,0,contrastValue,t, 0,0,0,1 ), colorTarget );
			}
			inline float2 UnityVoronoiRandomVector( float2 UV, float offset )
			{
				float2x2 m = float2x2( 15.27, 47.63, 99.41, 89.98 );
				UV = frac( sin(mul(UV, m) ) * 46839.32 );
				return float2( sin(UV.y* +offset ) * 0.5 + 0.5, cos( UV.x* offset ) * 0.5 + 0.5 );
			}
			
			//x - Out y - Cells
			float3 UnityVoronoi( float2 UV, float AngleOffset, float CellDensity, inout float2 mr )
			{
				float2 g = floor( UV * CellDensity );
				float2 f = frac( UV * CellDensity );
				float t = 8.0;
				float3 res = float3( 8.0, 0.0, 0.0 );
			
				for( int y = -1; y <= 1; y++ )
				{
					for( int x = -1; x <= 1; x++ )
					{
						float2 lattice = float2( x, y );
						float2 offset = UnityVoronoiRandomVector( lattice + g, AngleOffset );
						float d = distance( lattice + offset, f );
			
						if( d < res.x )
						{
							mr = f - lattice - offset;
							res = float3( d, offset.x, offset.y );
						}
					}
				}
				return res;
			}
			
			float3 mod2D289( float3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float2 mod2D289( float2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float3 permute( float3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }
			float snoise( float2 v )
			{
				const float4 C = float4( 0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439 );
				float2 i = floor( v + dot( v, C.yy ) );
				float2 x0 = v - i + dot( i, C.xx );
				float2 i1;
				i1 = ( x0.x > x0.y ) ? float2( 1.0, 0.0 ) : float2( 0.0, 1.0 );
				float4 x12 = x0.xyxy + C.xxzz;
				x12.xy -= i1;
				i = mod2D289( i );
				float3 p = permute( permute( i.y + float3( 0.0, i1.y, 1.0 ) ) + i.x + float3( 0.0, i1.x, 1.0 ) );
				float3 m = max( 0.5 - float3( dot( x0, x0 ), dot( x12.xy, x12.xy ), dot( x12.zw, x12.zw ) ), 0.0 );
				m = m * m;
				m = m * m;
				float3 x = 2.0 * frac( p * C.www ) - 1.0;
				float3 h = abs( x ) - 0.5;
				float3 ox = floor( x + 0.5 );
				float3 a0 = x - ox;
				m *= 1.79284291400159 - 0.85373472095314 * ( a0 * a0 + h * h );
				float3 g;
				g.x = a0.x * x0.x + h.x * x0.y;
				g.yz = a0.yz * x12.xz + h.yz * x12.yw;
				return 130.0 * dot( m, g );
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				float _SmallWaveRotationX_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_SmallWaveRotationX);
				float3 ase_worldPos = mul(GetObjectToWorldMatrix(), v.vertex).xyz;
				float _SmallWaveRotationZ_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_SmallWaveRotationZ);
				float _SmallWaveSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_SmallWaveSpeed);
				float _SmallWavePower_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_SmallWavePower);
				float SmallWave120 = pow( ( 1.0 - abs( sin( ( ( ( ( _SmallWaveRotationX_Instance * ase_worldPos.x ) + ( ase_worldPos.z * _SmallWaveRotationZ_Instance ) ) * 4.0 ) + ( _SmallWaveSpeed_Instance * _TimeParameters.x ) ) ) ) ) , _SmallWavePower_Instance );
				float _SmallWaveHeight_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_SmallWaveHeight);
				float _MediumWaveRotationX_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWaveRotationX);
				float _MediumWaveRotationZ_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWaveRotationZ);
				float MediumWaveScaleVar300 = 2.0;
				float _MediumWaveSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWaveSpeed);
				float2 appendResult156 = (float2(ase_worldPos.x , ase_worldPos.z));
				float2 _GradientSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_GradientSpeed);
				float2 GradientSpeedVar250 = _GradientSpeed_Instance;
				float2 texCoord146 = v.ase_texcoord.xyz * appendResult156 + ( _TimeParameters.x * ( GradientSpeedVar250 * float2( 1.2,1.2 ) ) );
				float _GradientScale_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_GradientScale);
				float GradientScaleVar251 = _GradientScale_Instance;
				float gradientNoise143 = GradientNoise(texCoord146,( GradientScaleVar251 * 1.2 ));
				gradientNoise143 = gradientNoise143*0.5 + 0.5;
				float _MediumWavePower_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWavePower);
				float MediumWave140 = pow( ( 1.0 - abs( sin( ( ( ( ( _MediumWaveRotationX_Instance * ase_worldPos.x ) + ( ase_worldPos.z * _MediumWaveRotationZ_Instance ) ) * MediumWaveScaleVar300 ) + ( ( _MediumWaveSpeed_Instance * _TimeParameters.x ) + gradientNoise143 ) ) ) ) ) , _MediumWavePower_Instance );
				float _MediumWaveHeight_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWaveHeight);
				float _LargeWaveRotationX_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_LargeWaveRotationX);
				float _LargeWaveRotationZ_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_LargeWaveRotationZ);
				float LargeWaveScaleVar301 = 0.5;
				float _LargeWaveSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_LargeWaveSpeed);
				float2 appendResult187 = (float2(ase_worldPos.x , ase_worldPos.z));
				float2 texCoord192 = v.ase_texcoord.xy * appendResult187 + ( _TimeParameters.x * GradientSpeedVar250 );
				float gradientNoise193 = GradientNoise(texCoord192,GradientScaleVar251);
				gradientNoise193 = gradientNoise193*0.5 + 0.5;
				float _LargeWavePower_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_LargeWavePower);
				float LargeWave199 = pow( ( 1.0 - abs( sin( ( ( ( ( _LargeWaveRotationX_Instance * ase_worldPos.x ) + ( ase_worldPos.z * _LargeWaveRotationZ_Instance ) ) * LargeWaveScaleVar301 ) + ( ( _LargeWaveSpeed_Instance * _TimeParameters.x ) + gradientNoise193 ) ) ) ) ) , _LargeWavePower_Instance );
				float _LargeWaveHeight_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_LargeWaveHeight);
				float4 appendResult219 = (float4(ase_worldPos.x , ase_worldPos.z , 0.0 , 0.0));
				float2 texCoord220 = v.ase_texcoord.xy * appendResult219.xy + ( _TimeParameters.x * GradientSpeedVar250 );
				float gradientNoise226 = GradientNoise(texCoord220,GradientScaleVar251);
				gradientNoise226 = gradientNoise226*0.5 + 0.5;
				float WorldScale233 = gradientNoise226;
				float4 break258 = ( float4(1,1,1,1) * ( ( ( SmallWave120 * _SmallWaveHeight_Instance ) + ( MediumWave140 * _MediumWaveHeight_Instance ) + ( LargeWave199 * _LargeWaveHeight_Instance ) ) * WorldScale233 ) );
				float4 appendResult246 = (float4(v.vertex.xyz.x , ( ( break258.x + break258.z ) + v.vertex.xyz.y ) , v.vertex.xyz.z , 0.0));
				float4 lerpResult263 = lerp( float4( ( v.vertex.xyz / float3( 2,2,2 ) ) , 0.0 ) , appendResult246 , v.ase_color.r);
				float3 temp_output_278_0 = v.vertex.xyz;
				float4 lerpResult266 = lerp( lerpResult263 , float4( ( temp_output_278_0 / ( 1.1 * 10.0 ) ) , 0.0 ) , ( v.ase_color.g * 1.1 ));
				
				float3 ase_worldNormal = TransformObjectToWorldNormal(v.ase_normal);
				o.ase_texcoord2.xyz = ase_worldNormal;
				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord3 = screenPos;
				
				o.ase_texcoord4.xyz = v.ase_texcoord.xyz;
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.w = 0;
				o.ase_texcoord4.w = 0;
				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = lerpResult266.xyz;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				o.clipPos = positionCS;
				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_color : COLOR;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_color = v.ase_color;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float3 ase_worldViewDir = ( _WorldSpaceCameraPos.xyz - WorldPosition );
				ase_worldViewDir = normalize(ase_worldViewDir);
				float3 ase_worldNormal = IN.ase_texcoord2.xyz;
				float _FresenelPower_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_FresenelPower);
				float fresnelNdotV395 = dot( ase_worldNormal, ase_worldViewDir );
				float fresnelNode395 = ( 0.0 + 1.0 * pow( 1.0 - fresnelNdotV395, _FresenelPower_Instance ) );
				float4 screenPos = IN.ase_texcoord3;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float eyeDepth390 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float _Offset_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_Offset);
				float smoothstepResult393 = smoothstep( 0.0 , 1.0 , ( 1.0 - ( eyeDepth390 - ( screenPos.w - _Offset_Instance ) ) ));
				float _FrothStep_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_FrothStep);
				float2 _FrothStretch_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_FrothStretch);
				float2 _FrothDirection_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_FrothDirection);
				float _FrothSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_FrothSpeed);
				float2 texCoord350 = IN.ase_texcoord4.xyz.xy * float2( 1,1 ) + ( _FrothDirection_Instance * ( _TimeParameters.x * _FrothSpeed_Instance ) );
				float _FrothScaleBig_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_FrothScaleBig);
				float simpleNoise352 = SimpleNoise( ( ( IN.ase_texcoord4.xyz * float3( _FrothStretch_Instance ,  0.0 ) ) + float3( texCoord350 ,  0.0 ) ).xy*_FrothScaleBig_Instance );
				float4 appendResult349 = (float4(WorldPosition.x , WorldPosition.z , 0.0 , 0.0));
				float _FrothScaleSmall_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_FrothScaleSmall);
				float simpleNoise358 = SimpleNoise( appendResult349.xy*_FrothScaleSmall_Instance );
				float temp_output_360_0 = step( _FrothStep_Instance , ( simpleNoise352 + ( simpleNoise358 * 0.2 ) ) );
				float _FrothBlend_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_FrothBlend);
				float4 _BottomDarkColour_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_BottomDarkColour);
				float4 _BottomLightColour_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_BottomLightColour);
				float2 texCoord318 = IN.ase_texcoord4.xyz.xy * float2( 1,1 ) + float2( 0,0 );
				float4 lerpResult319 = lerp( _BottomDarkColour_Instance , _BottomLightColour_Instance , texCoord318.y);
				float4 _TopDarkColour_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_TopDarkColour);
				float4 _TopLightColour_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_TopLightColour);
				float _TopColourContrast_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_TopColourContrast);
				float4 _MediumWaveColourBlend_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWaveColourBlend);
				float _MediumWaveRotationX_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWaveRotationX);
				float _MediumWaveRotationZ_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWaveRotationZ);
				float MediumWaveScaleVar300 = 2.0;
				float _MediumWaveSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWaveSpeed);
				float2 appendResult156 = (float2(WorldPosition.x , WorldPosition.z));
				float2 _GradientSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_GradientSpeed);
				float2 GradientSpeedVar250 = _GradientSpeed_Instance;
				float2 texCoord146 = IN.ase_texcoord4.xyz.xy * appendResult156 + ( _TimeParameters.x * ( GradientSpeedVar250 * float2( 1.2,1.2 ) ) );
				float _GradientScale_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_GradientScale);
				float GradientScaleVar251 = _GradientScale_Instance;
				float gradientNoise143 = GradientNoise(texCoord146,( GradientScaleVar251 * 1.2 ));
				gradientNoise143 = gradientNoise143*0.5 + 0.5;
				float _MediumWavePower_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_MediumWavePower);
				float MediumWave140 = pow( ( 1.0 - abs( sin( ( ( ( ( _MediumWaveRotationX_Instance * WorldPosition.x ) + ( WorldPosition.z * _MediumWaveRotationZ_Instance ) ) * MediumWaveScaleVar300 ) + ( ( _MediumWaveSpeed_Instance * _TimeParameters.x ) + gradientNoise143 ) ) ) ) ) , _MediumWavePower_Instance );
				float _LargeWaveRotationX_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_LargeWaveRotationX);
				float _LargeWaveRotationZ_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_LargeWaveRotationZ);
				float LargeWaveScaleVar301 = 0.5;
				float _LargeWaveSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_LargeWaveSpeed);
				float2 appendResult187 = (float2(WorldPosition.x , WorldPosition.z));
				float2 texCoord192 = IN.ase_texcoord4.xyz.xy * appendResult187 + ( _TimeParameters.x * GradientSpeedVar250 );
				float gradientNoise193 = GradientNoise(texCoord192,GradientScaleVar251);
				gradientNoise193 = gradientNoise193*0.5 + 0.5;
				float _LargeWavePower_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_LargeWavePower);
				float LargeWave199 = pow( ( 1.0 - abs( sin( ( ( ( ( _LargeWaveRotationX_Instance * WorldPosition.x ) + ( WorldPosition.z * _LargeWaveRotationZ_Instance ) ) * LargeWaveScaleVar301 ) + ( ( _LargeWaveSpeed_Instance * _TimeParameters.x ) + gradientNoise193 ) ) ) ) ) , _LargeWavePower_Instance );
				float2 break308 = ( float2( 0,1 ) * ( ( MediumWaveScaleVar300 + LargeWaveScaleVar301 ) + 1.0 ) );
				float4 temp_cast_4 = (break308.x).xxxx;
				float4 temp_cast_5 = (break308.y).xxxx;
				float4 lerpResult315 = lerp( _TopDarkColour_Instance , _TopLightColour_Instance , ( CalculateContrast(_TopColourContrast_Instance,(float4( 0,0,0,0 ) + (( ( _MediumWaveColourBlend_Instance * ( float4(1,1,1,1) * MediumWave140 ).x ) + ( float4(1,1,1,1) * LargeWave199 ).x ) - temp_cast_4) * (float4( 1,1,1,1 ) - float4( 0,0,0,0 )) / (temp_cast_5 - temp_cast_4))) * IN.ase_color.g ));
				float4 lerpResult322 = lerp( lerpResult319 , lerpResult315 , pow( IN.ase_color.r , 40.0 ));
				float2 _RefractionStretch_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_RefractionStretch);
				float2 temp_output_419_0 = ( IN.ase_texcoord4.xyz.xy * _RefractionStretch_Instance );
				float2 uv411 = 0;
				float3 unityVoronoy411 = UnityVoronoi(temp_output_419_0,67.64,3.3,uv411);
				float simplePerlin2D406 = snoise( temp_output_419_0 );
				simplePerlin2D406 = simplePerlin2D406*0.5 + 0.5;
				float _RefractionScale_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_RefractionScale);
				float simpleNoise325 = SimpleNoise( IN.ase_texcoord4.xyz.xy*_RefractionScale_Instance );
				float _RefractionStrength_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_RefractionStrength);
				float temp_output_329_0 = ( ( simpleNoise325 - 0.7 ) * _RefractionStrength_Instance );
				float2 temp_cast_6 = (( ( unityVoronoy411.x + ( 1.0 - simplePerlin2D406 ) ) * temp_output_329_0 )).xx;
				float2 texCoord414 = IN.ase_texcoord4.xyz.xy * temp_cast_6 + float2( 0,0 );
				float _RefractionSize_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_RefractionSize);
				float2 temp_cast_8 = (temp_output_329_0).xx;
				float2 texCoord333 = IN.ase_texcoord4.xyz.xy * ( screenPos * _RefractionSize_Instance ).xy + temp_cast_8;
				float4 _RefractionColour_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_RefractionColour);
				float grayscale372 = (( float4( ( texCoord414 * ( 1.0 - texCoord333 ) ), 0.0 , 0.0 ) * _RefractionColour_Instance ).rgb.r + ( float4( ( texCoord414 * ( 1.0 - texCoord333 ) ), 0.0 , 0.0 ) * _RefractionColour_Instance ).rgb.g + ( float4( ( texCoord414 * ( 1.0 - texCoord333 ) ), 0.0 , 0.0 ) * _RefractionColour_Instance ).rgb.b) / 3;
				float4 temp_cast_11 = (grayscale372).xxxx;
				float4 blendOpSrc410 = lerpResult322;
				float4 blendOpDest410 = temp_cast_11;
				float _RefractionBlend_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_RefractionBlend);
				float4 lerpBlendMode410 = lerp(blendOpDest410,(( blendOpDest410 > 0.5 ) ? ( 1.0 - 2.0 * ( 1.0 - blendOpDest410 ) * ( 1.0 - blendOpSrc410 ) ) : ( 2.0 * blendOpDest410 * blendOpSrc410 ) ),_RefractionBlend_Instance);
				float4 RefractionAndColour344 = ( lerpResult322 + ( saturate( lerpBlendMode410 )) );
				
				float _WaterAlpha_Instance = UNITY_ACCESS_INSTANCED_PROP(WaterShader,_WaterAlpha);
				
				
				float3 Albedo = ( ( fresnelNode395 + smoothstepResult393 ) * ( ( temp_output_360_0 * _FrothBlend_Instance ) + RefractionAndColour344 ) ).rgb;
				float Alpha = _WaterAlpha_Instance;
				float AlphaClipThreshold = 0.5;

				half4 color = half4( Albedo, Alpha );

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				return color;
			}
			ENDHLSL
		}
		
	}
	/*ase_lod*/
	CustomEditor "UnityEditor.ShaderGraph.PBRMasterGUI"
	Fallback "Hidden/InternalErrorShader"
	
}
/*ASEBEGIN
Version=18912
0;0;1920;1059;-3767.407;-168.0651;1;True;False
Node;AmplifyShaderEditor.CommentaryNode;209;-4889.056,551.58;Inherit;False;3194.75;4609.234;Comment;3;119;175;122;Sine wave;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;122;-4810.251,2092.632;Inherit;False;2992.948;1347.658;Comment;32;140;139;138;137;136;135;134;141;143;146;144;145;160;159;158;157;156;155;133;132;131;123;130;128;129;127;126;125;124;250;251;300;MediumWave;1,1,1,1;0;0
Node;AmplifyShaderEditor.Vector2Node;160;-4772.644,3167.995;Inherit;False;InstancedProperty;_GradientSpeed;GradientSpeed;14;0;Create;True;0;0;0;False;0;False;0.1,0.1;0.1,0.1;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.RegisterLocalVarNode;250;-4558.501,3162.572;Inherit;False;GradientSpeedVar;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;159;-4280.647,3132.494;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;1.2,1.2;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;145;-4422.578,3327.34;Inherit;False;InstancedProperty;_GradientScale;GradientScale;13;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;158;-4577.647,3028.995;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;175;-4819.147,3782.918;Inherit;False;2992.948;1347.658;Comment;28;203;202;200;199;198;197;196;195;194;193;192;190;189;187;186;185;184;183;182;181;180;179;178;177;176;252;253;301;LargeWave;1,1,1,1;0;0
Node;AmplifyShaderEditor.WorldPosInputsNode;155;-4806.942,2641.813;Inherit;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;129;-4657.352,2142.632;Inherit;False;InstancedProperty;_MediumWaveRotationX;MediumWaveRotationX;3;0;Create;True;0;0;0;False;0;False;0.85;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;186;-4815.838,4332.099;Inherit;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldPosInputsNode;123;-4760.251,2298.464;Inherit;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;128;-4640.452,2556.032;Inherit;False;InstancedProperty;_MediumWaveRotationZ;MediumWaveRotationZ;4;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;251;-4157.252,3339.166;Inherit;False;GradientScaleVar;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;156;-4494.988,2806.126;Inherit;True;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;157;-4126.876,3059.415;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleTimeNode;190;-4613.543,4733.281;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;252;-4660.89,4976.915;Inherit;False;250;GradientSpeedVar;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;180;-4666.247,3832.918;Inherit;False;InstancedProperty;_LargeWaveRotationX;LargeWaveRotationX;2;0;Create;True;0;0;0;False;0;False;0.85;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;187;-4503.884,4496.412;Inherit;True;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;146;-3922.955,2911.889;Inherit;True;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;144;-3917.572,3339.479;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;1.2;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;127;-4390.883,2400.914;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;133;-4392.715,2628.675;Inherit;False;InstancedProperty;_MediumWaveSpeed;MediumWaveSpeed;7;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;182;-4769.147,3988.75;Inherit;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;189;-4379.772,4776.7;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;124;-4405.883,2174.914;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;131;-4407.018,2727.474;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;130;-4344.452,2513.633;Inherit;False;Constant;_MediumWaveScale;MediumWaveScale;11;0;Create;True;0;0;0;False;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;181;-4649.348,4246.318;Inherit;False;InstancedProperty;_LargeWaveRotationZ;LargeWaveRotationZ;1;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;132;-3985.818,2600.073;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;176;-4414.779,3865.2;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;125;-4178.95,2267.432;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;192;-3931.85,4602.175;Inherit;True;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;185;-4401.611,4318.96;Inherit;False;InstancedProperty;_LargeWaveSpeed;LargeWaveSpeed;8;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;202;-4335.244,4221.919;Inherit;False;Constant;_LargeWaveScale;LargeWaveScale;11;0;Create;True;0;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;183;-4415.914,4417.759;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;300;-4118.47,2501.902;Inherit;False;MediumWaveScaleVar;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;179;-4399.779,4091.199;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;143;-3643.487,3093.806;Inherit;True;Gradient;True;False;2;0;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;253;-3944.89,5001.915;Inherit;False;251;GradientScaleVar;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;141;-3368.154,2849.038;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;177;-4187.846,3957.718;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;301;-4099.769,4206.732;Inherit;False;LargeWaveScaleVar;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;184;-3994.713,4290.358;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;126;-3829.256,2374.032;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;193;-3664.02,4703.605;Inherit;True;Gradient;True;False;2;0;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;135;-3187.083,2810.565;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;178;-3838.151,4064.317;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;119;-4803.824,900.207;Inherit;False;2913.439;830.1683;Comment;18;120;117;116;115;114;110;118;112;113;111;109;106;105;104;108;107;103;102;SmallWave;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleAddOpNode;194;-3377.049,4539.324;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;200;-3195.978,4500.852;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;102;-4753.824,1106.038;Inherit;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SinOpNode;136;-2927.463,2561.056;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;105;-4634.025,1363.606;Inherit;False;InstancedProperty;_SmallWaveRotationZ;SmallWaveRotationZ;5;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;106;-4650.924,950.207;Inherit;False;InstancedProperty;_SmallWaveRotationX;SmallWaveRotationX;6;0;Create;True;0;0;0;False;0;False;0.85;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;104;-4384.456,1208.488;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;103;-4399.456,982.4883;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.AbsOpNode;137;-2680.759,2898.385;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;195;-2936.358,4251.342;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;109;-4179.025,1340.207;Inherit;False;Constant;_SmallWaveScale;SmallWaveScale;11;0;Create;True;0;0;0;False;0;False;4;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.AbsOpNode;196;-2689.654,4588.672;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;138;-2439.075,2506.81;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;112;-4402.624,1526.107;Inherit;False;InstancedProperty;_SmallWaveSpeed;SmallWaveSpeed;9;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;134;-2669.678,3204.303;Inherit;False;InstancedProperty;_MediumWavePower;MediumWavePower;12;0;Create;True;0;0;0;False;0;False;2;2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;111;-4416.926,1624.906;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;107;-4172.523,1075.006;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;113;-3995.725,1497.505;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;139;-2259.89,2816.941;Inherit;True;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;197;-2447.971,4197.095;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;108;-3822.826,1181.606;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;203;-2678.573,4894.588;Inherit;False;InstancedProperty;_LargeWavePower;LargeWavePower;11;0;Create;True;0;0;0;False;0;False;2;2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;110;-3442.659,1313.672;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;343;-1636.944,2738.069;Inherit;False;5959.929;2422.295;Comment;52;344;408;409;338;372;370;322;315;323;319;324;312;318;321;316;317;368;320;311;314;406;310;297;308;294;291;293;307;304;296;292;306;288;285;305;298;290;337;289;303;287;302;286;410;411;412;414;415;416;419;420;424;;1,1,1,1;0;0
Node;AmplifyShaderEditor.PowerNode;198;-2268.785,4507.228;Inherit;True;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;140;-2007.643,2823.896;Inherit;False;MediumWave;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexCoordVertexDataNode;424;646.7156,4263.041;Inherit;False;0;2;0;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;199;-2016.539,4514.182;Inherit;False;LargeWave;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;303;-592.3481,3912.672;Inherit;False;301;LargeWaveScaleVar;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;114;-3153.489,1314.006;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;302;-471.348,3790.673;Inherit;False;300;MediumWaveScaleVar;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;337;380.0856,4511.928;Inherit;False;2514.246;644.2131;;11;330;333;329;326;325;328;369;373;421;422;423;Refaction;1,1,1,1;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;287;-1559.801,3522.575;Inherit;False;140;MediumWave;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;420;712.3097,4445.255;Inherit;False;InstancedProperty;_RefractionStretch;RefractionStretch;40;0;Create;True;0;0;0;False;0;False;2,2;2,2;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector4Node;286;-1546.801,3319.575;Inherit;False;Constant;_Vector1;Vector 1;28;0;Create;True;0;0;0;False;0;False;1,1,1,1;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;285;-1299.373,3437.185;Inherit;True;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;305;120.652,3984.672;Inherit;False;Constant;_1;1;29;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;290;-1586.944,3870.705;Inherit;False;199;LargeWave;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexCoordVertexDataNode;423;448.7156,4662.041;Inherit;False;0;2;0;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector4Node;289;-1573.944,3667.705;Inherit;False;Constant;_Vector2;Vector 2;28;0;Create;True;0;0;0;False;0;False;1,1,1,1;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;419;946.6097,4327.262;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;326;431.0854,4812.736;Inherit;False;InstancedProperty;_RefractionScale;RefractionScale;23;0;Create;True;0;0;0;False;0;False;25;25;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.AbsOpNode;115;-2924.691,1313.618;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;232;-1681.139,1727.511;Inherit;False;1401.035;693.4812;;9;233;226;254;220;221;219;255;218;222;World Scale;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleAddOpNode;298;-156.6024,3834.233;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;406;1151.979,4369.975;Inherit;True;Simplex2D;True;False;2;0;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;288;-1326.516,3785.315;Inherit;True;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.BreakToComponentsNode;292;-885.8268,3451.994;Inherit;False;FLOAT4;1;0;FLOAT4;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.ColorNode;296;-1049.901,3227.546;Inherit;False;InstancedProperty;_MediumWaveColourBlend;MediumWaveColourBlend;18;0;Create;True;0;0;0;False;0;False;0.5754717,0.5754717,0.5754717,0;0,0.6754477,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.NoiseGeneratorNode;325;739.7161,4766.377;Inherit;True;Simple;True;False;2;0;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;116;-2678.69,1315.285;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;306;213.4274,3670.764;Inherit;False;Constant;_Vector3;Vector 3;29;0;Create;True;0;0;0;False;0;False;0,1;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.RangedFloatNode;118;-2689.357,1622.614;Inherit;False;InstancedProperty;_SmallWavePower;SmallWavePower;10;0;Create;True;0;0;0;False;0;False;2;2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;304;204.6519,3853.673;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;222;-1576.784,2110.892;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;255;-1622.203,2263.318;Inherit;False;250;GradientSpeedVar;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.WorldPosInputsNode;218;-1631.139,1785.411;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.BreakToComponentsNode;291;-878.801,3813.575;Inherit;False;FLOAT4;1;0;FLOAT4;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.VoronoiNode;411;1419.483,4228.782;Inherit;False;2;0;1;0;6;False;1;True;False;False;4;0;FLOAT2;0,0;False;1;FLOAT;67.64;False;2;FLOAT;3.3;False;3;FLOAT;0;False;3;FLOAT;0;FLOAT2;1;FLOAT2;2
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;293;-717.9011,3357.546;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;328;1272.086,4761.734;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0.7;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;219;-1369.139,1777.511;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.OneMinusNode;416;1457.309,4426.255;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;117;-2378.358,1314.958;Inherit;True;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;374;1577.197,5264.121;Inherit;False;InstancedProperty;_RefractionSize;RefractionSize;35;0;Create;True;0;0;0;False;0;False;0.4;1.31;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenPosInputsNode;422;1531.717,4974.066;Float;False;1;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;307;413.652,3823.673;Inherit;True;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;330;1515.053,4870.497;Inherit;False;InstancedProperty;_RefractionStrength;RefractionStrength;29;0;Create;True;0;0;0;False;0;False;0.09;0.03;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;221;-1362.784,2150.892;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;120;-2079.61,1309.16;Inherit;False;SmallWave;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;308;621.6519,3860.673;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.TextureCoordinatesNode;220;-1191.784,1964.892;Inherit;True;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;329;1832.447,4670.278;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;294;-285.901,3529.546;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;373;2096.404,5064.836;Inherit;True;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;1;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;254;-1115.203,2310.318;Inherit;False;251;GradientScaleVar;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;283;-1697.146,530.5723;Inherit;False;3071.492;1191.209;Comment;19;208;213;214;207;215;206;211;210;212;234;216;217;256;257;258;260;262;244;246;CombineSineWaveOffset;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleAddOpNode;412;1731.485,4363.856;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;213;-1647.146,858.6447;Inherit;False;InstancedProperty;_SmallWaveHeight;SmallWaveHeight;15;0;Create;True;0;0;0;False;0;False;0.2;0.2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;206;-1647.146,762.6447;Inherit;False;120;SmallWave;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;208;-1647.146,1274.645;Inherit;False;199;LargeWave;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;214;-1647.146,1146.645;Inherit;False;InstancedProperty;_MediumWaveHeight;MediumWaveHeight;16;0;Create;True;0;0;0;False;0;False;0.4;0.4;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;215;-1647.146,1402.645;Inherit;False;InstancedProperty;_LargeWaveHeight;LargeWaveHeight;17;0;Create;True;0;0;0;False;0;False;0.6;0.6;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;310;869.6519,3988.672;Inherit;False;InstancedProperty;_TopColourContrast;TopColourContrast;19;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;347;17.42961,2151.934;Inherit;False;InstancedProperty;_FrothSpeed;FrothSpeed;25;0;Create;True;0;0;0;False;0;False;0.07;5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;415;2218.758,4356.128;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0.05;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;345;27.68481,2007.854;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;333;2375.976,4812.377;Inherit;True;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;207;-1647.146,1018.645;Inherit;False;140;MediumWave;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;297;849.3975,3561.233;Inherit;True;5;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;1,1,1,1;False;3;COLOR;0,0,0,0;False;4;COLOR;1,1,1,1;False;1;COLOR;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;226;-815.3441,1957.925;Inherit;True;Gradient;True;False;2;0;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;346;689.8835,1979.73;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;383;697.2029,1801.82;Inherit;False;InstancedProperty;_FrothDirection;FrothDirection;36;0;Create;True;0;0;0;False;0;False;1,1;0,1;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.VertexColorNode;314;893.6519,4098.672;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;212;-1263.146,1274.645;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;233;-494.4939,1957.211;Inherit;True;WorldScale;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;421;2628.694,4773.722;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;210;-1263.146,762.6447;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;414;2438.762,4348.446;Inherit;True;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;211;-1263.146,1018.645;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleContrastOpNode;311;1300.652,3690.673;Inherit;True;2;1;COLOR;0,0,0,0;False;0;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;318;1634.766,3141.275;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;316;1637.652,3696.973;Inherit;False;InstancedProperty;_TopLightColour;TopLightColour;24;0;Create;True;0;0;0;False;0;False;0.8915094,1,0.992375,0;0.1811587,0.5566037,0.5315741,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TexCoordVertexDataNode;354;948.0759,1753.123;Inherit;False;0;3;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;369;2598.499,4962.397;Inherit;False;InstancedProperty;_RefractionColour;RefractionColour;34;1;[HDR];Create;True;0;0;0;False;0;False;1,1,1,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;386;1076.76,1926.948;Inherit;False;InstancedProperty;_FrothStretch;FrothStretch;37;0;Create;True;0;0;0;False;0;False;0,0;0,10.48;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.WorldPosInputsNode;348;-57.68798,2379.003;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ColorNode;317;1625.652,3467.673;Inherit;False;InstancedProperty;_TopDarkColour;TopDarkColour;20;0;Create;True;0;0;0;False;0;False;0,1,0.9999998,0;0.2877358,0.8185909,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;384;923.2029,1972.82;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.VertexColorNode;324;1921.985,3955.254;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;321;1377.807,2872.569;Inherit;False;InstancedProperty;_BottomLightColour;Bottom Light Colour;22;0;Create;True;0;0;0;False;0;False;0.6745283,0.918313,1,0;0.2085705,0.3563879,0.4056603,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;312;1618.652,3884.673;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;368;2814.499,4708.397;Inherit;True;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;234;-725.7291,1309.371;Inherit;False;233;WorldScale;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;216;-751.1469,1018.645;Inherit;True;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;320;1708.924,2792.352;Inherit;False;InstancedProperty;_BottomDarkColour;Bottom Dark Colour;21;0;Create;True;0;0;0;False;0;False;0,0,0,0;0,0.4932407,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;349;272.1437,2350.064;Inherit;True;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;217;-361.2296,1016.278;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;350;1072.353,2108.149;Inherit;True;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;359;1006.344,2593.405;Inherit;False;InstancedProperty;_FrothScaleSmall;FrothScaleSmall;26;0;Create;True;0;0;0;False;0;False;4.37;4.37;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;256;-507.7941,580.5723;Inherit;False;Constant;_Vector0;Vector 0;29;0;Create;True;0;0;0;False;0;False;1,1,1,1;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;315;2012.652,3637.673;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;385;1245.76,1832.948;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT2;0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;370;3055.257,4909.779;Inherit;True;2;2;0;FLOAT2;0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.PowerNode;323;2161.44,3946.814;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;40;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;319;2101.907,3115.669;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;389;2138.445,383.5815;Inherit;False;InstancedProperty;_Offset;Offset;38;0;Create;True;0;0;0;False;0;False;0;-2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCGrayscale;372;3323.692,4765.058;Inherit;True;2;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;355;1364.145,2011.204;Inherit;True;2;2;0;FLOAT3;0,0,0;False;1;FLOAT2;0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;257;-130.7941,755.5723;Inherit;True;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;353;1050.034,2427.897;Inherit;False;InstancedProperty;_FrothScaleBig;FrothScaleBig;27;0;Create;True;0;0;0;False;0;False;2.61;2.61;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;358;1348.689,2484.657;Inherit;True;Simple;True;False;2;0;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenPosInputsNode;387;2066.742,85.98206;Float;True;1;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;322;2595.265,3588.381;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;338;3484.463,5029.869;Inherit;False;InstancedProperty;_RefractionBlend;RefractionBlend;28;0;Create;True;0;0;0;False;0;False;5;5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenDepthNode;390;2456.039,185.5823;Inherit;False;0;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;258;217.2059,966.5723;Inherit;False;FLOAT4;1;0;FLOAT4;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SimpleSubtractOpNode;388;2521.04,371.4817;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;357;1622.984,2488.202;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0.2;False;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;352;1627.034,2203.897;Inherit;True;Simple;True;False;2;0;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.BlendOpsNode;410;3576.963,4466.417;Inherit;True;Overlay;True;3;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;260;434.1827,920.152;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;356;1978.807,2318.768;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;408;3868.884,4297.931;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.PosVertexDataNode;262;663.699,1026.218;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;361;2138.344,2187.405;Inherit;False;InstancedProperty;_FrothStep;FrothStep;30;0;Create;True;0;0;0;False;0;False;0.8;0.71;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;391;2755.44,350.9818;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;284;1385.245,737.142;Inherit;False;1422.4;977.413;Comment;12;264;282;266;263;268;280;269;265;278;267;270;401;ColourMask;1,1,1,1;0;0
Node;AmplifyShaderEditor.PosVertexDataNode;267;2022.566,1163.031;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;363;2621.344,2563.405;Inherit;False;InstancedProperty;_FrothBlend;FrothBlend;31;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;392;3002.641,355.2822;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;244;898.0598,861.4504;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;270;1973.62,1621.955;Inherit;False;Constant;_FrothFlatness;Froth Flatness;18;0;Create;True;0;0;0;False;0;False;1.1;1.1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;360;2464.344,2288.405;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;397;2860.583,139.1365;Inherit;False;InstancedProperty;_FresenelPower;FresenelPower;39;0;Create;True;0;0;0;False;0;False;0;2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;344;4099.803,4662.035;Inherit;False;RefractionAndColour;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.PosVertexDataNode;264;1382.889,779.8997;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FresnelNode;395;3198.523,60.22885;Inherit;False;Standard;WorldNormal;ViewDir;False;False;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;393;3231.327,337.3287;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;365;3284.516,2604.001;Inherit;False;344;RefractionAndColour;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.DynamicAppendNode;246;1144.477,1041.868;Inherit;True;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;362;2937.344,2430.405;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;282;1799.154,810.7252;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;2,2,2;False;1;FLOAT3;0
Node;AmplifyShaderEditor.VertexColorNode;265;1549.645,1302.521;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TransformPositionNode;278;2219.178,1216.376;Inherit;False;Object;Object;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.VertexColorNode;269;1960.62,1346.955;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;401;2293.329,1595.474;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;10;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;280;2438.154,1447.726;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;11;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;268;2203.621,1483.955;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;263;1964.053,933.7919;Inherit;True;3;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleAddOpNode;394;3498.817,343.2291;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;364;3644.625,2264.162;Inherit;True;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;26;4559.007,498.3897;Inherit;False;InstancedProperty;_WaterAlpha;WaterAlpha;0;0;Create;True;0;0;0;False;0;False;1;0.99;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;409;3697.559,4883.834;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;396;4551.752,817.5389;Inherit;True;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;367;4597.331,420.3797;Inherit;False;InstancedProperty;_Smoothness;Smoothness;33;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;266;2542.646,1174.52;Inherit;True;3;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;366;4675.331,312.3797;Inherit;False;InstancedProperty;_Metallic;Metallic;32;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RotateAboutAxisNode;378;2696.833,2039.668;Inherit;False;False;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;3;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;2;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;True;False;False;False;False;0;False;-1;False;False;False;False;False;False;False;False;False;True;1;False;-1;False;False;True;1;LightMode=DepthOnly;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;0;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;2;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;0;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;5009.279,304.5078;Float;False;True;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;2;WaterShader;94348b07e5e8bab40bd6c8a1e3df54cd;True;Forward;0;1;Forward;18;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;5;False;-1;10;False;-1;1;1;False;-1;10;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=UniversalForward;False;False;0;Hidden/InternalErrorShader;0;0;Standard;38;Workflow;1;Surface;1;  Refraction Model;0;  Blend;0;Two Sided;1;Fragment Normal Space,InvertActionOnDeselection;0;Transmission;0;  Transmission Shadow;0.5,False,-1;Translucency;0;  Translucency Strength;1,False,-1;  Normal Distortion;0.5,False,-1;  Scattering;2,False,-1;  Direct;0.9,False,-1;  Ambient;0.1,False,-1;  Shadow;0.5,False,-1;Cast Shadows;1;  Use Shadow Threshold;0;Receive Shadows;1;GPU Instancing;1;LOD CrossFade;1;Built-in Fog;1;_FinalColorxAlpha;0;Meta Pass;1;Override Baked GI;0;Extra Pre Pass;0;DOTS Instancing;0;Tessellation;0;  Phong;0;  Strength;0.5,False,-1;  Type;0;  Tess;16,False,-1;  Min;10,False,-1;  Max;25,False,-1;  Edge Length;16,False,-1;  Max Displacement;25,False,-1;Write Depth;0;  Early Z;0;Vertex Position,InvertActionOnDeselection;1;0;6;False;True;True;True;True;True;False;;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;5;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;2;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;Universal2D;0;5;Universal2D;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;5;False;-1;10;False;-1;1;1;False;-1;10;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=Universal2D;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;4;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;2;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;2;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;2;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=ShadowCaster;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
WireConnection;250;0;160;0
WireConnection;159;0;250;0
WireConnection;251;0;145;0
WireConnection;156;0;155;1
WireConnection;156;1;155;3
WireConnection;157;0;158;0
WireConnection;157;1;159;0
WireConnection;187;0;186;1
WireConnection;187;1;186;3
WireConnection;146;0;156;0
WireConnection;146;1;157;0
WireConnection;144;0;251;0
WireConnection;127;0;123;3
WireConnection;127;1;128;0
WireConnection;189;0;190;0
WireConnection;189;1;252;0
WireConnection;124;0;129;0
WireConnection;124;1;123;1
WireConnection;132;0;133;0
WireConnection;132;1;131;0
WireConnection;176;0;180;0
WireConnection;176;1;182;1
WireConnection;125;0;124;0
WireConnection;125;1;127;0
WireConnection;192;0;187;0
WireConnection;192;1;189;0
WireConnection;300;0;130;0
WireConnection;179;0;182;3
WireConnection;179;1;181;0
WireConnection;143;0;146;0
WireConnection;143;1;144;0
WireConnection;141;0;132;0
WireConnection;141;1;143;0
WireConnection;177;0;176;0
WireConnection;177;1;179;0
WireConnection;301;0;202;0
WireConnection;184;0;185;0
WireConnection;184;1;183;0
WireConnection;126;0;125;0
WireConnection;126;1;300;0
WireConnection;193;0;192;0
WireConnection;193;1;253;0
WireConnection;135;0;126;0
WireConnection;135;1;141;0
WireConnection;178;0;177;0
WireConnection;178;1;301;0
WireConnection;194;0;184;0
WireConnection;194;1;193;0
WireConnection;200;0;178;0
WireConnection;200;1;194;0
WireConnection;136;0;135;0
WireConnection;104;0;102;3
WireConnection;104;1;105;0
WireConnection;103;0;106;0
WireConnection;103;1;102;1
WireConnection;137;0;136;0
WireConnection;195;0;200;0
WireConnection;196;0;195;0
WireConnection;138;0;137;0
WireConnection;107;0;103;0
WireConnection;107;1;104;0
WireConnection;113;0;112;0
WireConnection;113;1;111;0
WireConnection;139;0;138;0
WireConnection;139;1;134;0
WireConnection;197;0;196;0
WireConnection;108;0;107;0
WireConnection;108;1;109;0
WireConnection;110;0;108;0
WireConnection;110;1;113;0
WireConnection;198;0;197;0
WireConnection;198;1;203;0
WireConnection;140;0;139;0
WireConnection;199;0;198;0
WireConnection;114;0;110;0
WireConnection;285;0;286;0
WireConnection;285;1;287;0
WireConnection;419;0;424;0
WireConnection;419;1;420;0
WireConnection;115;0;114;0
WireConnection;298;0;302;0
WireConnection;298;1;303;0
WireConnection;406;0;419;0
WireConnection;288;0;289;0
WireConnection;288;1;290;0
WireConnection;292;0;285;0
WireConnection;325;0;423;0
WireConnection;325;1;326;0
WireConnection;116;0;115;0
WireConnection;304;0;298;0
WireConnection;304;1;305;0
WireConnection;291;0;288;0
WireConnection;411;0;419;0
WireConnection;293;0;296;0
WireConnection;293;1;292;0
WireConnection;328;0;325;0
WireConnection;219;0;218;1
WireConnection;219;1;218;3
WireConnection;416;0;406;0
WireConnection;117;0;116;0
WireConnection;117;1;118;0
WireConnection;307;0;306;0
WireConnection;307;1;304;0
WireConnection;221;0;222;0
WireConnection;221;1;255;0
WireConnection;120;0;117;0
WireConnection;308;0;307;0
WireConnection;220;0;219;0
WireConnection;220;1;221;0
WireConnection;329;0;328;0
WireConnection;329;1;330;0
WireConnection;294;0;293;0
WireConnection;294;1;291;0
WireConnection;373;0;422;0
WireConnection;373;1;374;0
WireConnection;412;0;411;0
WireConnection;412;1;416;0
WireConnection;415;0;412;0
WireConnection;415;1;329;0
WireConnection;333;0;373;0
WireConnection;333;1;329;0
WireConnection;297;0;294;0
WireConnection;297;1;308;0
WireConnection;297;2;308;1
WireConnection;226;0;220;0
WireConnection;226;1;254;0
WireConnection;346;0;345;0
WireConnection;346;1;347;0
WireConnection;212;0;208;0
WireConnection;212;1;215;0
WireConnection;233;0;226;0
WireConnection;421;0;333;0
WireConnection;210;0;206;0
WireConnection;210;1;213;0
WireConnection;414;0;415;0
WireConnection;211;0;207;0
WireConnection;211;1;214;0
WireConnection;311;1;297;0
WireConnection;311;0;310;0
WireConnection;384;0;383;0
WireConnection;384;1;346;0
WireConnection;312;0;311;0
WireConnection;312;1;314;2
WireConnection;368;0;414;0
WireConnection;368;1;421;0
WireConnection;216;0;210;0
WireConnection;216;1;211;0
WireConnection;216;2;212;0
WireConnection;349;0;348;1
WireConnection;349;1;348;3
WireConnection;217;0;216;0
WireConnection;217;1;234;0
WireConnection;350;1;384;0
WireConnection;315;0;317;0
WireConnection;315;1;316;0
WireConnection;315;2;312;0
WireConnection;385;0;354;0
WireConnection;385;1;386;0
WireConnection;370;0;368;0
WireConnection;370;1;369;0
WireConnection;323;0;324;1
WireConnection;319;0;320;0
WireConnection;319;1;321;0
WireConnection;319;2;318;2
WireConnection;372;0;370;0
WireConnection;355;0;385;0
WireConnection;355;1;350;0
WireConnection;257;0;256;0
WireConnection;257;1;217;0
WireConnection;358;0;349;0
WireConnection;358;1;359;0
WireConnection;322;0;319;0
WireConnection;322;1;315;0
WireConnection;322;2;323;0
WireConnection;258;0;257;0
WireConnection;388;0;387;4
WireConnection;388;1;389;0
WireConnection;357;0;358;0
WireConnection;352;0;355;0
WireConnection;352;1;353;0
WireConnection;410;0;322;0
WireConnection;410;1;372;0
WireConnection;410;2;338;0
WireConnection;260;0;258;0
WireConnection;260;1;258;2
WireConnection;356;0;352;0
WireConnection;356;1;357;0
WireConnection;408;0;322;0
WireConnection;408;1;410;0
WireConnection;391;0;390;0
WireConnection;391;1;388;0
WireConnection;392;0;391;0
WireConnection;244;0;260;0
WireConnection;244;1;262;2
WireConnection;360;0;361;0
WireConnection;360;1;356;0
WireConnection;344;0;408;0
WireConnection;395;3;397;0
WireConnection;393;0;392;0
WireConnection;246;0;262;1
WireConnection;246;1;244;0
WireConnection;246;2;262;3
WireConnection;362;0;360;0
WireConnection;362;1;363;0
WireConnection;282;0;264;0
WireConnection;278;0;267;0
WireConnection;401;0;270;0
WireConnection;280;0;278;0
WireConnection;280;1;401;0
WireConnection;268;0;269;2
WireConnection;268;1;270;0
WireConnection;263;0;282;0
WireConnection;263;1;246;0
WireConnection;263;2;265;1
WireConnection;394;0;395;0
WireConnection;394;1;393;0
WireConnection;364;0;362;0
WireConnection;364;1;365;0
WireConnection;409;0;372;0
WireConnection;409;1;338;0
WireConnection;396;0;394;0
WireConnection;396;1;364;0
WireConnection;266;0;263;0
WireConnection;266;1;280;0
WireConnection;266;2;268;0
WireConnection;378;0;360;0
WireConnection;1;0;396;0
WireConnection;1;3;366;0
WireConnection;1;4;367;0
WireConnection;1;6;26;0
WireConnection;1;8;266;0
ASEEND*/
//CHKSM=D21795D847C6FFE087218FDF5586DA65B6BD2506