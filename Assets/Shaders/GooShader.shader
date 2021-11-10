// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "GooShader"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[ASEBegin]_AlphaClip("Alpha Clip", Float) = 0.5
		[HideInInspector][PerRendererData]_CutoffHeight("CutoffHeight", Float) = 1000
		_EdgeWidth("EdgeWidth", Float) = 0.05
		_NoiseScale("NoiseScale", Float) = 50
		_NoiseStrength("NoiseStrength", Float) = 1
		[HDR]_EmissionColour("EmissionColour", Color) = (0,0,0,0)
		[HDR]_GooSlimeColor("GooSlimeColor", Color) = (0.1603774,0.1603774,0.1603774,0)
		_MainColor("MainColor", Color) = (0,0,0,0)
		_ScrollSpeed("ScrollSpeed", Float) = 0.05
		_AngleChangeSpeed("AngleChangeSpeed", Float) = 3
		_Smoothness("Smoothness", Float) = 0
		_Metallic("Metallic", Float) = 0
		_SlimeScale("SlimeScale", Float) = 5
		_SlimeShapness("SlimeShapness", Vector) = (0,0,0,0)
		_Stretch("Stretch", Vector) = (1,1,0,0)
		_TwirlSpeed("TwirlSpeed", Float) = 0.1
		_TwirlStrength("TwirlStrength", Float) = 20
		_DisplacementSpeed("DisplacementSpeed", Float) = 5
		[ASEEnd]_AnimationScale("AnimationScale", Range( 0 , 1)) = 1

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

		

		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" }
		Cull Off
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
			
			Blend One Zero, One Zero
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
			

			HLSLPROGRAM
			
			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define _EMISSION
			#define _ALPHATEST_ON 1
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 90000

			
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

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#pragma multi_compile_instancing


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord : TEXCOORD0;
				
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
			UNITY_INSTANCING_BUFFER_START(GooShader)
				UNITY_DEFINE_INSTANCED_PROP(float4, _EmissionColour)
				UNITY_DEFINE_INSTANCED_PROP(float4, _MainColor)
				UNITY_DEFINE_INSTANCED_PROP(float4, _GooSlimeColor)
				UNITY_DEFINE_INSTANCED_PROP(float2, _SlimeShapness)
				UNITY_DEFINE_INSTANCED_PROP(float2, _Stretch)
				UNITY_DEFINE_INSTANCED_PROP(float, _Metallic)
				UNITY_DEFINE_INSTANCED_PROP(float, _EdgeWidth)
				UNITY_DEFINE_INSTANCED_PROP(float, _CutoffHeight)
				UNITY_DEFINE_INSTANCED_PROP(float, _NoiseStrength)
				UNITY_DEFINE_INSTANCED_PROP(float, _NoiseScale)
				UNITY_DEFINE_INSTANCED_PROP(float, _DisplacementSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _AnimationScale)
				UNITY_DEFINE_INSTANCED_PROP(float, _SlimeScale)
				UNITY_DEFINE_INSTANCED_PROP(float, _AngleChangeSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _ScrollSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _TwirlStrength)
				UNITY_DEFINE_INSTANCED_PROP(float, _TwirlSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _Smoothness)
				UNITY_DEFINE_INSTANCED_PROP(float, _AlphaClip)
			UNITY_INSTANCING_BUFFER_END(GooShader)


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
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float _DisplacementSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_DisplacementSpeed);
				float2 texCoord188 = v.texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float _TwirlSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_TwirlSpeed);
				float temp_output_218_0 = ( _TimeParameters.x * _TwirlSpeed_Instance );
				float2 temp_cast_0 = (temp_output_218_0).xx;
				float2 center45_g11 = temp_cast_0;
				float2 delta6_g11 = ( texCoord188 - center45_g11 );
				float _TwirlStrength_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_TwirlStrength);
				float angle10_g11 = ( length( delta6_g11 ) * _TwirlStrength_Instance );
				float x23_g11 = ( ( cos( angle10_g11 ) * delta6_g11.x ) - ( sin( angle10_g11 ) * delta6_g11.y ) );
				float2 break40_g11 = center45_g11;
				float2 break41_g11 = float2( 0,0 );
				float y35_g11 = ( ( sin( angle10_g11 ) * delta6_g11.x ) + ( cos( angle10_g11 ) * delta6_g11.y ) );
				float2 appendResult44_g11 = (float2(( x23_g11 + break40_g11.x + break41_g11.x ) , ( break40_g11.y + break41_g11.y + y35_g11 )));
				float grayscale222 = dot(float3( appendResult44_g11 ,  0.0 ), float3(0.299,0.587,0.114));
				float smoothstepResult214 = smoothstep( 0.0 , 30.36 , grayscale222);
				float _ScrollSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_ScrollSpeed);
				float temp_output_49_0 = ( _TimeParameters.x * _ScrollSpeed_Instance );
				float2 _Stretch_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_Stretch);
				float2 texCoord55 = v.texcoord.xy * _Stretch_Instance + float2( 0,0 );
				float2 panner46 = ( temp_output_49_0 * float2( 1,1 ) + texCoord55);
				float3 objToWorld160 = mul( GetObjectToWorldMatrix(), float4( float3( 1,1,1 ), 1 ) ).xyz;
				float _AngleChangeSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_AngleChangeSpeed);
				float temp_output_159_0 = ( ( ( objToWorld160.x + objToWorld160.y ) + objToWorld160.z ) * ( _TimeParameters.x * ( _AngleChangeSpeed_Instance / 100.0 ) ) );
				float _SlimeScale_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_SlimeScale);
				float2 uv53 = 0;
				float3 unityVoronoy53 = UnityVoronoi(panner46,temp_output_159_0,_SlimeScale_Instance,uv53);
				float smoothstepResult48 = smoothstep( 0.63 , 1.0 , unityVoronoy53.x);
				float smoothstepResult44 = smoothstep( 0.76 , 1.0 , 0.0);
				float temp_output_190_0 = ( smoothstepResult214 * ( smoothstepResult48 + smoothstepResult44 ) );
				float smoothstepResult261 = smoothstep( 0.0 , 5.0 , temp_output_190_0);
				float2 temp_cast_2 = (smoothstepResult261).xx;
				float2 texCoord259 = v.texcoord.xy * float2( 1,1 ) + temp_cast_2;
				float simplePerlin2D252 = snoise( ( ( v.ase_normal + ( _DisplacementSpeed_Instance * ( _TimeParameters.x * 0.05 ) ) ) + float3( texCoord259 ,  0.0 ) ).xy );
				float _AnimationScale_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_AnimationScale);
				float3 temp_cast_5 = ((( _AnimationScale_Instance * -1.0 ) + (simplePerlin2D252 - 0.0) * (_AnimationScale_Instance - ( _AnimationScale_Instance * -1.0 )) / (1.0 - 0.0))).xxx;
				
				o.ase_texcoord7.xy = v.texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord7.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = temp_cast_5;
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

				float4 _MainColor_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_MainColor);
				float2 texCoord188 = IN.ase_texcoord7.xy * float2( 1,1 ) + float2( 0,0 );
				float _TwirlSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_TwirlSpeed);
				float temp_output_218_0 = ( _TimeParameters.x * _TwirlSpeed_Instance );
				float2 temp_cast_0 = (temp_output_218_0).xx;
				float2 center45_g11 = temp_cast_0;
				float2 delta6_g11 = ( texCoord188 - center45_g11 );
				float _TwirlStrength_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_TwirlStrength);
				float angle10_g11 = ( length( delta6_g11 ) * _TwirlStrength_Instance );
				float x23_g11 = ( ( cos( angle10_g11 ) * delta6_g11.x ) - ( sin( angle10_g11 ) * delta6_g11.y ) );
				float2 break40_g11 = center45_g11;
				float2 break41_g11 = float2( 0,0 );
				float y35_g11 = ( ( sin( angle10_g11 ) * delta6_g11.x ) + ( cos( angle10_g11 ) * delta6_g11.y ) );
				float2 appendResult44_g11 = (float2(( x23_g11 + break40_g11.x + break41_g11.x ) , ( break40_g11.y + break41_g11.y + y35_g11 )));
				float grayscale222 = dot(float3( appendResult44_g11 ,  0.0 ), float3(0.299,0.587,0.114));
				float smoothstepResult214 = smoothstep( 0.0 , 30.36 , grayscale222);
				float _ScrollSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_ScrollSpeed);
				float temp_output_49_0 = ( _TimeParameters.x * _ScrollSpeed_Instance );
				float2 _Stretch_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_Stretch);
				float2 texCoord55 = IN.ase_texcoord7.xy * _Stretch_Instance + float2( 0,0 );
				float2 panner46 = ( temp_output_49_0 * float2( 1,1 ) + texCoord55);
				float3 objToWorld160 = mul( GetObjectToWorldMatrix(), float4( float3( 1,1,1 ), 1 ) ).xyz;
				float _AngleChangeSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_AngleChangeSpeed);
				float temp_output_159_0 = ( ( ( objToWorld160.x + objToWorld160.y ) + objToWorld160.z ) * ( _TimeParameters.x * ( _AngleChangeSpeed_Instance / 100.0 ) ) );
				float _SlimeScale_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_SlimeScale);
				float2 uv53 = 0;
				float3 unityVoronoy53 = UnityVoronoi(panner46,temp_output_159_0,_SlimeScale_Instance,uv53);
				float smoothstepResult48 = smoothstep( 0.63 , 1.0 , unityVoronoy53.x);
				float smoothstepResult44 = smoothstep( 0.76 , 1.0 , 0.0);
				float temp_output_190_0 = ( smoothstepResult214 * ( smoothstepResult48 + smoothstepResult44 ) );
				float2 _SlimeShapness_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_SlimeShapness);
				float smoothstepResult128 = smoothstep( _SlimeShapness_Instance.x , _SlimeShapness_Instance.y , temp_output_190_0);
				float4 _GooSlimeColor_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_GooSlimeColor);
				float4 temp_output_81_0 = ( smoothstepResult128 * _GooSlimeColor_Instance );
				float2 texCoord10 = IN.ase_texcoord7.xy * float2( 1,1 ) + float2( 0,0 );
				float _NoiseScale_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_NoiseScale);
				float simpleNoise16 = SimpleNoise( texCoord10*_NoiseScale_Instance );
				float _NoiseStrength_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_NoiseStrength);
				float _CutoffHeight_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_CutoffHeight);
				float temp_output_24_0 = ( (0.0 + (simpleNoise16 - _NoiseStrength_Instance) * (1.0 - 0.0) / (-_NoiseStrength_Instance - _NoiseStrength_Instance)) + _CutoffHeight_Instance );
				float temp_output_29_0 = step( WorldPosition.y , temp_output_24_0 );
				float _EdgeWidth_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_EdgeWidth);
				float temp_output_32_0 = ( temp_output_29_0 - step( ( WorldPosition.y + _EdgeWidth_Instance ) , temp_output_24_0 ) );
				
				float4 temp_cast_3 = (temp_output_190_0).xxxx;
				float3 unpack101 = UnpackNormalScale( temp_cast_3, 0.75 );
				unpack101.z = lerp( 1, unpack101.z, saturate(0.75) );
				
				float4 temp_cast_4 = (( 1.0 - temp_output_29_0 )).xxxx;
				float4 _EmissionColour_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_EmissionColour);
				
				float _Metallic_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_Metallic);
				
				float _Smoothness_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_Smoothness);
				
				float _AlphaClip_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_AlphaClip);
				
				float3 Albedo = ( ( ( _MainColor_Instance * ( 1.0 - temp_output_190_0 ) ) + temp_output_81_0 ) * ( temp_output_29_0 - temp_output_32_0 ) ).rgb;
				float3 Normal = unpack101;
				float3 Emission = ( ( temp_output_81_0 - temp_cast_4 ) + ( _EmissionColour_Instance * temp_output_32_0 ) ).rgb;
				float3 Specular = 0.5;
				float Metallic = _Metallic_Instance;
				float Smoothness = _Smoothness_Instance;
				float Occlusion = 1;
				float Alpha = temp_output_29_0;
				float AlphaClipThreshold = _AlphaClip_Instance;
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
			#define _EMISSION
			#define _ALPHATEST_ON 1
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 90000

			
			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS_SHADOWCASTER

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#pragma multi_compile_instancing


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
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
			UNITY_INSTANCING_BUFFER_START(GooShader)
				UNITY_DEFINE_INSTANCED_PROP(float2, _Stretch)
				UNITY_DEFINE_INSTANCED_PROP(float, _DisplacementSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _TwirlSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _TwirlStrength)
				UNITY_DEFINE_INSTANCED_PROP(float, _ScrollSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _AngleChangeSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _SlimeScale)
				UNITY_DEFINE_INSTANCED_PROP(float, _AnimationScale)
				UNITY_DEFINE_INSTANCED_PROP(float, _NoiseScale)
				UNITY_DEFINE_INSTANCED_PROP(float, _NoiseStrength)
				UNITY_DEFINE_INSTANCED_PROP(float, _CutoffHeight)
				UNITY_DEFINE_INSTANCED_PROP(float, _AlphaClip)
			UNITY_INSTANCING_BUFFER_END(GooShader)


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
			

			float3 _LightDirection;

			VertexOutput VertexFunction( VertexInput v )
			{
				VertexOutput o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				float _DisplacementSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_DisplacementSpeed);
				float2 texCoord188 = v.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float _TwirlSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_TwirlSpeed);
				float temp_output_218_0 = ( _TimeParameters.x * _TwirlSpeed_Instance );
				float2 temp_cast_0 = (temp_output_218_0).xx;
				float2 center45_g11 = temp_cast_0;
				float2 delta6_g11 = ( texCoord188 - center45_g11 );
				float _TwirlStrength_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_TwirlStrength);
				float angle10_g11 = ( length( delta6_g11 ) * _TwirlStrength_Instance );
				float x23_g11 = ( ( cos( angle10_g11 ) * delta6_g11.x ) - ( sin( angle10_g11 ) * delta6_g11.y ) );
				float2 break40_g11 = center45_g11;
				float2 break41_g11 = float2( 0,0 );
				float y35_g11 = ( ( sin( angle10_g11 ) * delta6_g11.x ) + ( cos( angle10_g11 ) * delta6_g11.y ) );
				float2 appendResult44_g11 = (float2(( x23_g11 + break40_g11.x + break41_g11.x ) , ( break40_g11.y + break41_g11.y + y35_g11 )));
				float grayscale222 = dot(float3( appendResult44_g11 ,  0.0 ), float3(0.299,0.587,0.114));
				float smoothstepResult214 = smoothstep( 0.0 , 30.36 , grayscale222);
				float _ScrollSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_ScrollSpeed);
				float temp_output_49_0 = ( _TimeParameters.x * _ScrollSpeed_Instance );
				float2 _Stretch_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_Stretch);
				float2 texCoord55 = v.ase_texcoord.xy * _Stretch_Instance + float2( 0,0 );
				float2 panner46 = ( temp_output_49_0 * float2( 1,1 ) + texCoord55);
				float3 objToWorld160 = mul( GetObjectToWorldMatrix(), float4( float3( 1,1,1 ), 1 ) ).xyz;
				float _AngleChangeSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_AngleChangeSpeed);
				float temp_output_159_0 = ( ( ( objToWorld160.x + objToWorld160.y ) + objToWorld160.z ) * ( _TimeParameters.x * ( _AngleChangeSpeed_Instance / 100.0 ) ) );
				float _SlimeScale_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_SlimeScale);
				float2 uv53 = 0;
				float3 unityVoronoy53 = UnityVoronoi(panner46,temp_output_159_0,_SlimeScale_Instance,uv53);
				float smoothstepResult48 = smoothstep( 0.63 , 1.0 , unityVoronoy53.x);
				float smoothstepResult44 = smoothstep( 0.76 , 1.0 , 0.0);
				float temp_output_190_0 = ( smoothstepResult214 * ( smoothstepResult48 + smoothstepResult44 ) );
				float smoothstepResult261 = smoothstep( 0.0 , 5.0 , temp_output_190_0);
				float2 temp_cast_2 = (smoothstepResult261).xx;
				float2 texCoord259 = v.ase_texcoord.xy * float2( 1,1 ) + temp_cast_2;
				float simplePerlin2D252 = snoise( ( ( v.ase_normal + ( _DisplacementSpeed_Instance * ( _TimeParameters.x * 0.05 ) ) ) + float3( texCoord259 ,  0.0 ) ).xy );
				float _AnimationScale_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_AnimationScale);
				float3 temp_cast_5 = ((( _AnimationScale_Instance * -1.0 ) + (simplePerlin2D252 - 0.0) * (_AnimationScale_Instance - ( _AnimationScale_Instance * -1.0 )) / (1.0 - 0.0))).xxx;
				
				o.ase_texcoord2.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = temp_cast_5;
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

				float2 texCoord10 = IN.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				float _NoiseScale_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_NoiseScale);
				float simpleNoise16 = SimpleNoise( texCoord10*_NoiseScale_Instance );
				float _NoiseStrength_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_NoiseStrength);
				float _CutoffHeight_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_CutoffHeight);
				float temp_output_24_0 = ( (0.0 + (simpleNoise16 - _NoiseStrength_Instance) * (1.0 - 0.0) / (-_NoiseStrength_Instance - _NoiseStrength_Instance)) + _CutoffHeight_Instance );
				float temp_output_29_0 = step( WorldPosition.y , temp_output_24_0 );
				
				float _AlphaClip_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_AlphaClip);
				
				float Alpha = temp_output_29_0;
				float AlphaClipThreshold = _AlphaClip_Instance;
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
			#define _EMISSION
			#define _ALPHATEST_ON 1
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 90000

			
			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#pragma multi_compile_instancing


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
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
			UNITY_INSTANCING_BUFFER_START(GooShader)
				UNITY_DEFINE_INSTANCED_PROP(float2, _Stretch)
				UNITY_DEFINE_INSTANCED_PROP(float, _DisplacementSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _TwirlSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _TwirlStrength)
				UNITY_DEFINE_INSTANCED_PROP(float, _ScrollSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _AngleChangeSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _SlimeScale)
				UNITY_DEFINE_INSTANCED_PROP(float, _AnimationScale)
				UNITY_DEFINE_INSTANCED_PROP(float, _NoiseScale)
				UNITY_DEFINE_INSTANCED_PROP(float, _NoiseStrength)
				UNITY_DEFINE_INSTANCED_PROP(float, _CutoffHeight)
				UNITY_DEFINE_INSTANCED_PROP(float, _AlphaClip)
			UNITY_INSTANCING_BUFFER_END(GooShader)


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
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float _DisplacementSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_DisplacementSpeed);
				float2 texCoord188 = v.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float _TwirlSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_TwirlSpeed);
				float temp_output_218_0 = ( _TimeParameters.x * _TwirlSpeed_Instance );
				float2 temp_cast_0 = (temp_output_218_0).xx;
				float2 center45_g11 = temp_cast_0;
				float2 delta6_g11 = ( texCoord188 - center45_g11 );
				float _TwirlStrength_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_TwirlStrength);
				float angle10_g11 = ( length( delta6_g11 ) * _TwirlStrength_Instance );
				float x23_g11 = ( ( cos( angle10_g11 ) * delta6_g11.x ) - ( sin( angle10_g11 ) * delta6_g11.y ) );
				float2 break40_g11 = center45_g11;
				float2 break41_g11 = float2( 0,0 );
				float y35_g11 = ( ( sin( angle10_g11 ) * delta6_g11.x ) + ( cos( angle10_g11 ) * delta6_g11.y ) );
				float2 appendResult44_g11 = (float2(( x23_g11 + break40_g11.x + break41_g11.x ) , ( break40_g11.y + break41_g11.y + y35_g11 )));
				float grayscale222 = dot(float3( appendResult44_g11 ,  0.0 ), float3(0.299,0.587,0.114));
				float smoothstepResult214 = smoothstep( 0.0 , 30.36 , grayscale222);
				float _ScrollSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_ScrollSpeed);
				float temp_output_49_0 = ( _TimeParameters.x * _ScrollSpeed_Instance );
				float2 _Stretch_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_Stretch);
				float2 texCoord55 = v.ase_texcoord.xy * _Stretch_Instance + float2( 0,0 );
				float2 panner46 = ( temp_output_49_0 * float2( 1,1 ) + texCoord55);
				float3 objToWorld160 = mul( GetObjectToWorldMatrix(), float4( float3( 1,1,1 ), 1 ) ).xyz;
				float _AngleChangeSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_AngleChangeSpeed);
				float temp_output_159_0 = ( ( ( objToWorld160.x + objToWorld160.y ) + objToWorld160.z ) * ( _TimeParameters.x * ( _AngleChangeSpeed_Instance / 100.0 ) ) );
				float _SlimeScale_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_SlimeScale);
				float2 uv53 = 0;
				float3 unityVoronoy53 = UnityVoronoi(panner46,temp_output_159_0,_SlimeScale_Instance,uv53);
				float smoothstepResult48 = smoothstep( 0.63 , 1.0 , unityVoronoy53.x);
				float smoothstepResult44 = smoothstep( 0.76 , 1.0 , 0.0);
				float temp_output_190_0 = ( smoothstepResult214 * ( smoothstepResult48 + smoothstepResult44 ) );
				float smoothstepResult261 = smoothstep( 0.0 , 5.0 , temp_output_190_0);
				float2 temp_cast_2 = (smoothstepResult261).xx;
				float2 texCoord259 = v.ase_texcoord.xy * float2( 1,1 ) + temp_cast_2;
				float simplePerlin2D252 = snoise( ( ( v.ase_normal + ( _DisplacementSpeed_Instance * ( _TimeParameters.x * 0.05 ) ) ) + float3( texCoord259 ,  0.0 ) ).xy );
				float _AnimationScale_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_AnimationScale);
				float3 temp_cast_5 = ((( _AnimationScale_Instance * -1.0 ) + (simplePerlin2D252 - 0.0) * (_AnimationScale_Instance - ( _AnimationScale_Instance * -1.0 )) / (1.0 - 0.0))).xxx;
				
				o.ase_texcoord2.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = temp_cast_5;
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

				float2 texCoord10 = IN.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				float _NoiseScale_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_NoiseScale);
				float simpleNoise16 = SimpleNoise( texCoord10*_NoiseScale_Instance );
				float _NoiseStrength_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_NoiseStrength);
				float _CutoffHeight_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_CutoffHeight);
				float temp_output_24_0 = ( (0.0 + (simpleNoise16 - _NoiseStrength_Instance) * (1.0 - 0.0) / (-_NoiseStrength_Instance - _NoiseStrength_Instance)) + _CutoffHeight_Instance );
				float temp_output_29_0 = step( WorldPosition.y , temp_output_24_0 );
				
				float _AlphaClip_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_AlphaClip);
				
				float Alpha = temp_output_29_0;
				float AlphaClipThreshold = _AlphaClip_Instance;
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
			#define _EMISSION
			#define _ALPHATEST_ON 1
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 90000

			
			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS_META

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#pragma multi_compile_instancing


			#pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_texcoord : TEXCOORD0;
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
			UNITY_INSTANCING_BUFFER_START(GooShader)
				UNITY_DEFINE_INSTANCED_PROP(float4, _MainColor)
				UNITY_DEFINE_INSTANCED_PROP(float4, _GooSlimeColor)
				UNITY_DEFINE_INSTANCED_PROP(float4, _EmissionColour)
				UNITY_DEFINE_INSTANCED_PROP(float2, _Stretch)
				UNITY_DEFINE_INSTANCED_PROP(float2, _SlimeShapness)
				UNITY_DEFINE_INSTANCED_PROP(float, _EdgeWidth)
				UNITY_DEFINE_INSTANCED_PROP(float, _CutoffHeight)
				UNITY_DEFINE_INSTANCED_PROP(float, _NoiseStrength)
				UNITY_DEFINE_INSTANCED_PROP(float, _NoiseScale)
				UNITY_DEFINE_INSTANCED_PROP(float, _DisplacementSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _SlimeScale)
				UNITY_DEFINE_INSTANCED_PROP(float, _AngleChangeSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _ScrollSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _TwirlStrength)
				UNITY_DEFINE_INSTANCED_PROP(float, _TwirlSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _AnimationScale)
				UNITY_DEFINE_INSTANCED_PROP(float, _AlphaClip)
			UNITY_INSTANCING_BUFFER_END(GooShader)


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
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float _DisplacementSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_DisplacementSpeed);
				float2 texCoord188 = v.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float _TwirlSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_TwirlSpeed);
				float temp_output_218_0 = ( _TimeParameters.x * _TwirlSpeed_Instance );
				float2 temp_cast_0 = (temp_output_218_0).xx;
				float2 center45_g11 = temp_cast_0;
				float2 delta6_g11 = ( texCoord188 - center45_g11 );
				float _TwirlStrength_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_TwirlStrength);
				float angle10_g11 = ( length( delta6_g11 ) * _TwirlStrength_Instance );
				float x23_g11 = ( ( cos( angle10_g11 ) * delta6_g11.x ) - ( sin( angle10_g11 ) * delta6_g11.y ) );
				float2 break40_g11 = center45_g11;
				float2 break41_g11 = float2( 0,0 );
				float y35_g11 = ( ( sin( angle10_g11 ) * delta6_g11.x ) + ( cos( angle10_g11 ) * delta6_g11.y ) );
				float2 appendResult44_g11 = (float2(( x23_g11 + break40_g11.x + break41_g11.x ) , ( break40_g11.y + break41_g11.y + y35_g11 )));
				float grayscale222 = dot(float3( appendResult44_g11 ,  0.0 ), float3(0.299,0.587,0.114));
				float smoothstepResult214 = smoothstep( 0.0 , 30.36 , grayscale222);
				float _ScrollSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_ScrollSpeed);
				float temp_output_49_0 = ( _TimeParameters.x * _ScrollSpeed_Instance );
				float2 _Stretch_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_Stretch);
				float2 texCoord55 = v.ase_texcoord.xy * _Stretch_Instance + float2( 0,0 );
				float2 panner46 = ( temp_output_49_0 * float2( 1,1 ) + texCoord55);
				float3 objToWorld160 = mul( GetObjectToWorldMatrix(), float4( float3( 1,1,1 ), 1 ) ).xyz;
				float _AngleChangeSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_AngleChangeSpeed);
				float temp_output_159_0 = ( ( ( objToWorld160.x + objToWorld160.y ) + objToWorld160.z ) * ( _TimeParameters.x * ( _AngleChangeSpeed_Instance / 100.0 ) ) );
				float _SlimeScale_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_SlimeScale);
				float2 uv53 = 0;
				float3 unityVoronoy53 = UnityVoronoi(panner46,temp_output_159_0,_SlimeScale_Instance,uv53);
				float smoothstepResult48 = smoothstep( 0.63 , 1.0 , unityVoronoy53.x);
				float smoothstepResult44 = smoothstep( 0.76 , 1.0 , 0.0);
				float temp_output_190_0 = ( smoothstepResult214 * ( smoothstepResult48 + smoothstepResult44 ) );
				float smoothstepResult261 = smoothstep( 0.0 , 5.0 , temp_output_190_0);
				float2 temp_cast_2 = (smoothstepResult261).xx;
				float2 texCoord259 = v.ase_texcoord.xy * float2( 1,1 ) + temp_cast_2;
				float simplePerlin2D252 = snoise( ( ( v.ase_normal + ( _DisplacementSpeed_Instance * ( _TimeParameters.x * 0.05 ) ) ) + float3( texCoord259 ,  0.0 ) ).xy );
				float _AnimationScale_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_AnimationScale);
				float3 temp_cast_5 = ((( _AnimationScale_Instance * -1.0 ) + (simplePerlin2D252 - 0.0) * (_AnimationScale_Instance - ( _AnimationScale_Instance * -1.0 )) / (1.0 - 0.0))).xxx;
				
				o.ase_texcoord2.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.zw = 0;
				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = temp_cast_5;
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

				float4 _MainColor_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_MainColor);
				float2 texCoord188 = IN.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				float _TwirlSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_TwirlSpeed);
				float temp_output_218_0 = ( _TimeParameters.x * _TwirlSpeed_Instance );
				float2 temp_cast_0 = (temp_output_218_0).xx;
				float2 center45_g11 = temp_cast_0;
				float2 delta6_g11 = ( texCoord188 - center45_g11 );
				float _TwirlStrength_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_TwirlStrength);
				float angle10_g11 = ( length( delta6_g11 ) * _TwirlStrength_Instance );
				float x23_g11 = ( ( cos( angle10_g11 ) * delta6_g11.x ) - ( sin( angle10_g11 ) * delta6_g11.y ) );
				float2 break40_g11 = center45_g11;
				float2 break41_g11 = float2( 0,0 );
				float y35_g11 = ( ( sin( angle10_g11 ) * delta6_g11.x ) + ( cos( angle10_g11 ) * delta6_g11.y ) );
				float2 appendResult44_g11 = (float2(( x23_g11 + break40_g11.x + break41_g11.x ) , ( break40_g11.y + break41_g11.y + y35_g11 )));
				float grayscale222 = dot(float3( appendResult44_g11 ,  0.0 ), float3(0.299,0.587,0.114));
				float smoothstepResult214 = smoothstep( 0.0 , 30.36 , grayscale222);
				float _ScrollSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_ScrollSpeed);
				float temp_output_49_0 = ( _TimeParameters.x * _ScrollSpeed_Instance );
				float2 _Stretch_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_Stretch);
				float2 texCoord55 = IN.ase_texcoord2.xy * _Stretch_Instance + float2( 0,0 );
				float2 panner46 = ( temp_output_49_0 * float2( 1,1 ) + texCoord55);
				float3 objToWorld160 = mul( GetObjectToWorldMatrix(), float4( float3( 1,1,1 ), 1 ) ).xyz;
				float _AngleChangeSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_AngleChangeSpeed);
				float temp_output_159_0 = ( ( ( objToWorld160.x + objToWorld160.y ) + objToWorld160.z ) * ( _TimeParameters.x * ( _AngleChangeSpeed_Instance / 100.0 ) ) );
				float _SlimeScale_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_SlimeScale);
				float2 uv53 = 0;
				float3 unityVoronoy53 = UnityVoronoi(panner46,temp_output_159_0,_SlimeScale_Instance,uv53);
				float smoothstepResult48 = smoothstep( 0.63 , 1.0 , unityVoronoy53.x);
				float smoothstepResult44 = smoothstep( 0.76 , 1.0 , 0.0);
				float temp_output_190_0 = ( smoothstepResult214 * ( smoothstepResult48 + smoothstepResult44 ) );
				float2 _SlimeShapness_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_SlimeShapness);
				float smoothstepResult128 = smoothstep( _SlimeShapness_Instance.x , _SlimeShapness_Instance.y , temp_output_190_0);
				float4 _GooSlimeColor_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_GooSlimeColor);
				float4 temp_output_81_0 = ( smoothstepResult128 * _GooSlimeColor_Instance );
				float2 texCoord10 = IN.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				float _NoiseScale_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_NoiseScale);
				float simpleNoise16 = SimpleNoise( texCoord10*_NoiseScale_Instance );
				float _NoiseStrength_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_NoiseStrength);
				float _CutoffHeight_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_CutoffHeight);
				float temp_output_24_0 = ( (0.0 + (simpleNoise16 - _NoiseStrength_Instance) * (1.0 - 0.0) / (-_NoiseStrength_Instance - _NoiseStrength_Instance)) + _CutoffHeight_Instance );
				float temp_output_29_0 = step( WorldPosition.y , temp_output_24_0 );
				float _EdgeWidth_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_EdgeWidth);
				float temp_output_32_0 = ( temp_output_29_0 - step( ( WorldPosition.y + _EdgeWidth_Instance ) , temp_output_24_0 ) );
				
				float4 temp_cast_3 = (( 1.0 - temp_output_29_0 )).xxxx;
				float4 _EmissionColour_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_EmissionColour);
				
				float _AlphaClip_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_AlphaClip);
				
				
				float3 Albedo = ( ( ( _MainColor_Instance * ( 1.0 - temp_output_190_0 ) ) + temp_output_81_0 ) * ( temp_output_29_0 - temp_output_32_0 ) ).rgb;
				float3 Emission = ( ( temp_output_81_0 - temp_cast_3 ) + ( _EmissionColour_Instance * temp_output_32_0 ) ).rgb;
				float Alpha = temp_output_29_0;
				float AlphaClipThreshold = _AlphaClip_Instance;

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

			Blend One Zero, One Zero
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA

			HLSLPROGRAM
			
			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define _EMISSION
			#define _ALPHATEST_ON 1
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 90000

			
			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS_2D

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			
			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#pragma multi_compile_instancing


			#pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
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
			UNITY_INSTANCING_BUFFER_START(GooShader)
				UNITY_DEFINE_INSTANCED_PROP(float4, _MainColor)
				UNITY_DEFINE_INSTANCED_PROP(float4, _GooSlimeColor)
				UNITY_DEFINE_INSTANCED_PROP(float2, _Stretch)
				UNITY_DEFINE_INSTANCED_PROP(float2, _SlimeShapness)
				UNITY_DEFINE_INSTANCED_PROP(float, _DisplacementSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _TwirlSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _TwirlStrength)
				UNITY_DEFINE_INSTANCED_PROP(float, _ScrollSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _AngleChangeSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _SlimeScale)
				UNITY_DEFINE_INSTANCED_PROP(float, _AnimationScale)
				UNITY_DEFINE_INSTANCED_PROP(float, _NoiseScale)
				UNITY_DEFINE_INSTANCED_PROP(float, _NoiseStrength)
				UNITY_DEFINE_INSTANCED_PROP(float, _CutoffHeight)
				UNITY_DEFINE_INSTANCED_PROP(float, _EdgeWidth)
				UNITY_DEFINE_INSTANCED_PROP(float, _AlphaClip)
			UNITY_INSTANCING_BUFFER_END(GooShader)


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
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				float _DisplacementSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_DisplacementSpeed);
				float2 texCoord188 = v.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float _TwirlSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_TwirlSpeed);
				float temp_output_218_0 = ( _TimeParameters.x * _TwirlSpeed_Instance );
				float2 temp_cast_0 = (temp_output_218_0).xx;
				float2 center45_g11 = temp_cast_0;
				float2 delta6_g11 = ( texCoord188 - center45_g11 );
				float _TwirlStrength_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_TwirlStrength);
				float angle10_g11 = ( length( delta6_g11 ) * _TwirlStrength_Instance );
				float x23_g11 = ( ( cos( angle10_g11 ) * delta6_g11.x ) - ( sin( angle10_g11 ) * delta6_g11.y ) );
				float2 break40_g11 = center45_g11;
				float2 break41_g11 = float2( 0,0 );
				float y35_g11 = ( ( sin( angle10_g11 ) * delta6_g11.x ) + ( cos( angle10_g11 ) * delta6_g11.y ) );
				float2 appendResult44_g11 = (float2(( x23_g11 + break40_g11.x + break41_g11.x ) , ( break40_g11.y + break41_g11.y + y35_g11 )));
				float grayscale222 = dot(float3( appendResult44_g11 ,  0.0 ), float3(0.299,0.587,0.114));
				float smoothstepResult214 = smoothstep( 0.0 , 30.36 , grayscale222);
				float _ScrollSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_ScrollSpeed);
				float temp_output_49_0 = ( _TimeParameters.x * _ScrollSpeed_Instance );
				float2 _Stretch_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_Stretch);
				float2 texCoord55 = v.ase_texcoord.xy * _Stretch_Instance + float2( 0,0 );
				float2 panner46 = ( temp_output_49_0 * float2( 1,1 ) + texCoord55);
				float3 objToWorld160 = mul( GetObjectToWorldMatrix(), float4( float3( 1,1,1 ), 1 ) ).xyz;
				float _AngleChangeSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_AngleChangeSpeed);
				float temp_output_159_0 = ( ( ( objToWorld160.x + objToWorld160.y ) + objToWorld160.z ) * ( _TimeParameters.x * ( _AngleChangeSpeed_Instance / 100.0 ) ) );
				float _SlimeScale_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_SlimeScale);
				float2 uv53 = 0;
				float3 unityVoronoy53 = UnityVoronoi(panner46,temp_output_159_0,_SlimeScale_Instance,uv53);
				float smoothstepResult48 = smoothstep( 0.63 , 1.0 , unityVoronoy53.x);
				float smoothstepResult44 = smoothstep( 0.76 , 1.0 , 0.0);
				float temp_output_190_0 = ( smoothstepResult214 * ( smoothstepResult48 + smoothstepResult44 ) );
				float smoothstepResult261 = smoothstep( 0.0 , 5.0 , temp_output_190_0);
				float2 temp_cast_2 = (smoothstepResult261).xx;
				float2 texCoord259 = v.ase_texcoord.xy * float2( 1,1 ) + temp_cast_2;
				float simplePerlin2D252 = snoise( ( ( v.ase_normal + ( _DisplacementSpeed_Instance * ( _TimeParameters.x * 0.05 ) ) ) + float3( texCoord259 ,  0.0 ) ).xy );
				float _AnimationScale_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_AnimationScale);
				float3 temp_cast_5 = ((( _AnimationScale_Instance * -1.0 ) + (simplePerlin2D252 - 0.0) * (_AnimationScale_Instance - ( _AnimationScale_Instance * -1.0 )) / (1.0 - 0.0))).xxx;
				
				o.ase_texcoord2.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.zw = 0;
				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = temp_cast_5;
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

				float4 _MainColor_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_MainColor);
				float2 texCoord188 = IN.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				float _TwirlSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_TwirlSpeed);
				float temp_output_218_0 = ( _TimeParameters.x * _TwirlSpeed_Instance );
				float2 temp_cast_0 = (temp_output_218_0).xx;
				float2 center45_g11 = temp_cast_0;
				float2 delta6_g11 = ( texCoord188 - center45_g11 );
				float _TwirlStrength_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_TwirlStrength);
				float angle10_g11 = ( length( delta6_g11 ) * _TwirlStrength_Instance );
				float x23_g11 = ( ( cos( angle10_g11 ) * delta6_g11.x ) - ( sin( angle10_g11 ) * delta6_g11.y ) );
				float2 break40_g11 = center45_g11;
				float2 break41_g11 = float2( 0,0 );
				float y35_g11 = ( ( sin( angle10_g11 ) * delta6_g11.x ) + ( cos( angle10_g11 ) * delta6_g11.y ) );
				float2 appendResult44_g11 = (float2(( x23_g11 + break40_g11.x + break41_g11.x ) , ( break40_g11.y + break41_g11.y + y35_g11 )));
				float grayscale222 = dot(float3( appendResult44_g11 ,  0.0 ), float3(0.299,0.587,0.114));
				float smoothstepResult214 = smoothstep( 0.0 , 30.36 , grayscale222);
				float _ScrollSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_ScrollSpeed);
				float temp_output_49_0 = ( _TimeParameters.x * _ScrollSpeed_Instance );
				float2 _Stretch_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_Stretch);
				float2 texCoord55 = IN.ase_texcoord2.xy * _Stretch_Instance + float2( 0,0 );
				float2 panner46 = ( temp_output_49_0 * float2( 1,1 ) + texCoord55);
				float3 objToWorld160 = mul( GetObjectToWorldMatrix(), float4( float3( 1,1,1 ), 1 ) ).xyz;
				float _AngleChangeSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_AngleChangeSpeed);
				float temp_output_159_0 = ( ( ( objToWorld160.x + objToWorld160.y ) + objToWorld160.z ) * ( _TimeParameters.x * ( _AngleChangeSpeed_Instance / 100.0 ) ) );
				float _SlimeScale_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_SlimeScale);
				float2 uv53 = 0;
				float3 unityVoronoy53 = UnityVoronoi(panner46,temp_output_159_0,_SlimeScale_Instance,uv53);
				float smoothstepResult48 = smoothstep( 0.63 , 1.0 , unityVoronoy53.x);
				float smoothstepResult44 = smoothstep( 0.76 , 1.0 , 0.0);
				float temp_output_190_0 = ( smoothstepResult214 * ( smoothstepResult48 + smoothstepResult44 ) );
				float2 _SlimeShapness_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_SlimeShapness);
				float smoothstepResult128 = smoothstep( _SlimeShapness_Instance.x , _SlimeShapness_Instance.y , temp_output_190_0);
				float4 _GooSlimeColor_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_GooSlimeColor);
				float4 temp_output_81_0 = ( smoothstepResult128 * _GooSlimeColor_Instance );
				float2 texCoord10 = IN.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				float _NoiseScale_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_NoiseScale);
				float simpleNoise16 = SimpleNoise( texCoord10*_NoiseScale_Instance );
				float _NoiseStrength_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_NoiseStrength);
				float _CutoffHeight_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_CutoffHeight);
				float temp_output_24_0 = ( (0.0 + (simpleNoise16 - _NoiseStrength_Instance) * (1.0 - 0.0) / (-_NoiseStrength_Instance - _NoiseStrength_Instance)) + _CutoffHeight_Instance );
				float temp_output_29_0 = step( WorldPosition.y , temp_output_24_0 );
				float _EdgeWidth_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_EdgeWidth);
				float temp_output_32_0 = ( temp_output_29_0 - step( ( WorldPosition.y + _EdgeWidth_Instance ) , temp_output_24_0 ) );
				
				float _AlphaClip_Instance = UNITY_ACCESS_INSTANCED_PROP(GooShader,_AlphaClip);
				
				
				float3 Albedo = ( ( ( _MainColor_Instance * ( 1.0 - temp_output_190_0 ) ) + temp_output_81_0 ) * ( temp_output_29_0 - temp_output_32_0 ) ).rgb;
				float Alpha = temp_output_29_0;
				float AlphaClipThreshold = _AlphaClip_Instance;

				half4 color = half4( Albedo, Alpha );

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				return color;
			}
			ENDHLSL
		}
		
	}
	
	CustomEditor "UnityEditor.ShaderGraph.PBRMasterGUI"
	Fallback "Hidden/InternalErrorShader"
	
}
/*ASEBEGIN
Version=18921
2306;77;1920;1007;4668.572;2893.764;1;True;False
Node;AmplifyShaderEditor.RangedFloatNode;67;-5123.375,-1728.195;Inherit;False;InstancedProperty;_AngleChangeSpeed;AngleChangeSpeed;9;0;Create;True;0;0;0;False;0;False;3;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TransformPositionNode;160;-5102.466,-2020.361;Inherit;False;Object;World;False;Fast;True;1;0;FLOAT3;1,1,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleAddOpNode;157;-4838.213,-1989.193;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;50;-5672.958,-1910.764;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;161;-4869.465,-1643.361;Inherit;False;2;0;FLOAT;100;False;1;FLOAT;100;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;179;-5612.772,-2176.388;Inherit;False;InstancedProperty;_Stretch;Stretch;15;0;Create;True;0;0;0;False;0;False;1,1;1,1;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleTimeNode;51;-5113.688,-1813.595;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;78;-5490.25,-1847.466;Inherit;False;InstancedProperty;_ScrollSpeed;ScrollSpeed;8;0;Create;True;0;0;0;False;0;False;0.05;0.01;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;49;-5261.688,-1831.144;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;54;-4867.518,-1776.875;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;215;-3895.141,-2054.687;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;47;-5044.664,-2185.454;Inherit;False;Constant;_Vector0;Vector 0;18;0;Create;True;0;0;0;False;0;False;1,1;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleAddOpNode;158;-4700.213,-1923.193;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;217;-3937.141,-1934.687;Inherit;False;InstancedProperty;_TwirlSpeed;TwirlSpeed;16;0;Create;True;0;0;0;False;0;False;0.1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;55;-5271.275,-2320.636;Inherit;True;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;107;-4424.569,-1822.283;Inherit;False;InstancedProperty;_SlimeScale;SlimeScale;13;0;Create;True;0;0;0;False;0;False;5;1.26;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;218;-3683.141,-1996.687;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;159;-4554.212,-1833.193;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;189;-3717.035,-2241.358;Inherit;False;InstancedProperty;_TwirlStrength;TwirlStrength;17;0;Create;True;0;0;0;False;0;False;20;20;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;188;-3504.245,-2467.132;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PannerNode;46;-4783.666,-2250.455;Inherit;True;3;0;FLOAT2;1,1;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.FunctionNode;187;-3211.643,-2449.544;Inherit;True;Twirl;-1;;11;90936742ac32db8449cd21ab6dd337c8;0;4;1;FLOAT2;0,0;False;2;FLOAT2;0,0;False;3;FLOAT;0;False;4;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.VoronoiNode;53;-4391.081,-2263.736;Inherit;True;2;4;1;1;8;False;1;True;False;False;4;0;FLOAT2;0,0;False;1;FLOAT;15.71;False;2;FLOAT;18.4;False;3;FLOAT;0;False;3;FLOAT;0;FLOAT2;1;FLOAT2;2
Node;AmplifyShaderEditor.SmoothstepOpNode;48;-4149.671,-2283.456;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0.63;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;12;-3933.978,-327.5782;Inherit;False;InstancedProperty;_NoiseScale;NoiseScale;3;0;Create;True;0;0;0;False;0;False;50;50;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;10;-4012.304,-546.4789;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;11;-3852.828,-48.8461;Inherit;False;InstancedProperty;_NoiseStrength;NoiseStrength;4;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCGrayscale;222;-2717.367,-2672.839;Inherit;True;1;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;44;-4183.659,-1484.843;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0.76;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;214;-2436.141,-2576.687;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;30.36;False;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;16;-3663.435,-413.8752;Inherit;True;Simple;True;False;2;0;FLOAT2;1,1;False;1;FLOAT;11.29;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;41;-3060.039,-1932.931;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;14;-3507.108,57.12595;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;9;-3105.752,284.712;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;190;-2691.516,-2112.229;Inherit;True;2;2;0;FLOAT;1;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;23;-3233.099,-289.9342;Inherit;True;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;22;-2755.423,316.493;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.RangedFloatNode;20;-2483.793,418.2672;Inherit;True;InstancedProperty;_EdgeWidth;EdgeWidth;2;0;Create;True;0;0;0;False;0;False;0.05;0.05;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TimeNode;248;-1778.374,-2784.8;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;15;-3165.333,101.7851;Inherit;False;InstancedProperty;_CutoffHeight;CutoffHeight;1;2;[HideInInspector];[PerRendererData];Create;True;0;0;0;False;0;False;1000;1000;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;250;-1915.915,-2862.423;Inherit;False;InstancedProperty;_DisplacementSpeed;DisplacementSpeed;18;0;Create;True;0;0;0;False;0;False;5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;249;-1529.167,-2920.979;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;261;-1885.152,-2451.825;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;129;-2645.901,-1592.407;Inherit;False;InstancedProperty;_SlimeShapness;SlimeShapness;14;0;Create;True;0;0;0;False;0;False;0,0;0,1;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleAddOpNode;24;-2932.07,-256.263;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;27;-2243.293,335.1423;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalVertexDataNode;247;-1825.198,-3021.258;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.StepOpNode;28;-1975.265,-124.4736;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;259;-1457.028,-2632.718;Inherit;True;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;83;-2073.165,-2188.641;Inherit;False;InstancedProperty;_MainColor;MainColor;7;0;Create;True;0;0;0;False;0;False;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;251;-1399.301,-2982.109;Inherit;True;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ColorNode;80;-2754.89,-1400.567;Inherit;False;InstancedProperty;_GooSlimeColor;GooSlimeColor;6;1;[HDR];Create;True;0;0;0;False;0;False;0.1603774,0.1603774,0.1603774,0;8.47419,0,7.098798,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.OneMinusNode;79;-2294.822,-1912.375;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;128;-2385.901,-1638.407;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;29;-2337.483,-279.2191;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;32;-1794.137,-186.5108;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;260;-1176.368,-2718.154;Inherit;True;2;2;0;FLOAT3;0,0,0;False;1;FLOAT2;0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;82;-1794.482,-1842.174;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;81;-2307.896,-1432.879;Inherit;True;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;255;-1348.581,-2348.224;Inherit;False;InstancedProperty;_AnimationScale;AnimationScale;19;0;Create;True;0;0;0;False;0;False;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;37;-1601.073,-713.8936;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;84;-1757.217,-1380.768;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.CommentaryNode;246;-749.6146,-3616.277;Inherit;False;1706.322;1691.507;Comment;15;117;114;113;118;115;116;244;119;120;124;106;223;122;121;254;;1,1,1,1;0;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;252;-1152.926,-3015.155;Inherit;True;Simplex2D;False;False;2;0;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;256;-974.5811,-2475.224;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;-1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;119;178.074,-2987.872;Inherit;True;3;3;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;63;-1360.35,-781.5297;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;127;-685.0375,-381.7288;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;72;-742.4322,-103.1583;Inherit;True;InstancedProperty;_AlphaClip;Alpha Clip;0;0;Create;True;0;0;0;False;0;False;0.5;0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldTransformParams;114;-668.5145,-2995.487;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VoronoiNode;52;-4421.166,-1466.424;Inherit;True;2;4;1;1;8;False;1;True;False;False;4;0;FLOAT2;0,0;False;1;FLOAT;15.71;False;2;FLOAT;18.4;False;3;FLOAT;0;False;3;FLOAT;0;FLOAT2;1;FLOAT2;2
Node;AmplifyShaderEditor.SimpleAddOpNode;221;-3242.141,-2121.687;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ProjectionMatrixNode;264;-4183.572,-2703.764;Inherit;False;0;1;FLOAT4x4;0
Node;AmplifyShaderEditor.OneMinusNode;126;-2254.837,-628.5288;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;45;-5321.36,-1518.126;Inherit;True;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SinOpNode;216;-3407.141,-2014.687;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;193;-4149.671,-2283.456;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0.27;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;121;721.7073,-2671.095;Inherit;True;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ColorNode;56;-1293.169,-476.0995;Inherit;False;InstancedProperty;_EmissionColour;EmissionColour;5;1;[HDR];Create;True;0;0;0;False;0;False;0,0,0,0;6.498301,0.702519,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TFHCRemapNode;254;-713.5811,-2578.224;Inherit;True;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;42;-4817.653,-1451.843;Inherit;True;3;0;FLOAT2;1,1;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;43;-5078.65,-1386.847;Inherit;False;Constant;_Vector1;Vector 1;18;0;Create;True;0;0;0;False;0;False;-1,1;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.RangedFloatNode;89;-843.9932,-528.1311;Inherit;False;InstancedProperty;_Smoothness;Smoothness;10;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;209;-3376.105,-2202.058;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;223;266.981,-2090.125;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;100;False;1;FLOAT;0
Node;AmplifyShaderEditor.UnpackScaleNormalNode;101;-1063.608,-1450.192;Inherit;True;Tangent;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;0.75;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TextureCoordinatesNode;120;410.1577,-3118.381;Inherit;True;0;-1;3;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;122;531.11,-2178.77;Inherit;True;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;125;-1927.638,-955.5291;Inherit;True;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.WorldNormalVector;117;-674.2347,-3566.277;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;106;-109.4421,-2222.718;Inherit;False;InstancedProperty;_MoveStength;MoveStength;12;0;Create;True;0;0;0;False;0;False;0.1;6;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;73;-1015.064,-356.1381;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.CrossProductOpNode;116;-192.936,-3265.908;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;115;-195.4272,-2889.619;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;124;114.8925,-2405.025;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;-0.55;False;2;FLOAT;0.38;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;194;-4183.659,-1484.843;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0.76;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TangentVertexDataNode;113;-617.699,-2816.557;Inherit;False;1;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PosVertexDataNode;244;-67.34724,-3050.333;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VertexTangentNode;118;-699.6146,-3204.646;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;90;-833.6083,-627.192;Inherit;False;InstancedProperty;_Metallic;Metallic;11;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;2;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;2;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=ShadowCaster;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;198;-450.4673,-570.8272;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;2;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;Universal2D;0;5;Universal2D;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;1;False;-1;0;False;-1;1;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=Universal2D;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;-450.4673,-620.8272;Float;False;True;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;2;GooShader;94348b07e5e8bab40bd6c8a1e3df54cd;True;Forward;0;1;Forward;18;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;2;False;-1;False;False;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;1;False;-1;0;False;-1;1;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=UniversalForward;False;False;0;Hidden/InternalErrorShader;0;0;Standard;38;Workflow;1;Surface;0;  Refraction Model;0;  Blend;0;Two Sided;0;Fragment Normal Space,InvertActionOnDeselection;0;Transmission;0;  Transmission Shadow;0.5,False,-1;Translucency;0;  Translucency Strength;1,False,-1;  Normal Distortion;0.5,False,-1;  Scattering;2,False,-1;  Direct;0.9,False,-1;  Ambient;0.1,False,-1;  Shadow;0.5,False,-1;Cast Shadows;1;  Use Shadow Threshold;0;Receive Shadows;1;GPU Instancing;1;LOD CrossFade;1;Built-in Fog;1;_FinalColorxAlpha;0;Meta Pass;1;Override Baked GI;0;Extra Pre Pass;0;DOTS Instancing;0;Tessellation;0;  Phong;0;  Strength;0.5,False,-1;  Type;0;  Tess;16,False,-1;  Min;10,False,-1;  Max;25,False,-1;  Edge Length;16,False,-1;  Max Displacement;25,False,-1;Write Depth;0;  Early Z;1;Vertex Position,InvertActionOnDeselection;1;0;6;False;True;True;True;True;True;False;;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;3;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;2;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;True;False;False;False;False;0;False;-1;False;False;False;False;False;False;False;False;False;True;1;False;-1;False;False;True;1;LightMode=DepthOnly;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;0;-698.549,38.59387;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;2;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;0;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;4;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;2;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
WireConnection;157;0;160;1
WireConnection;157;1;160;2
WireConnection;161;0;67;0
WireConnection;49;0;50;0
WireConnection;49;1;78;0
WireConnection;54;0;51;0
WireConnection;54;1;161;0
WireConnection;158;0;157;0
WireConnection;158;1;160;3
WireConnection;55;0;179;0
WireConnection;218;0;215;0
WireConnection;218;1;217;0
WireConnection;159;0;158;0
WireConnection;159;1;54;0
WireConnection;46;0;55;0
WireConnection;46;2;47;0
WireConnection;46;1;49;0
WireConnection;187;1;188;0
WireConnection;187;2;218;0
WireConnection;187;3;189;0
WireConnection;53;0;46;0
WireConnection;53;1;159;0
WireConnection;53;2;107;0
WireConnection;48;0;53;0
WireConnection;222;0;187;0
WireConnection;214;0;222;0
WireConnection;16;0;10;0
WireConnection;16;1;12;0
WireConnection;41;0;48;0
WireConnection;41;1;44;0
WireConnection;14;0;11;0
WireConnection;190;0;214;0
WireConnection;190;1;41;0
WireConnection;23;0;16;0
WireConnection;23;1;11;0
WireConnection;23;2;14;0
WireConnection;22;0;9;0
WireConnection;249;0;250;0
WireConnection;249;1;248;1
WireConnection;261;0;190;0
WireConnection;24;0;23;0
WireConnection;24;1;15;0
WireConnection;27;0;22;1
WireConnection;27;1;20;0
WireConnection;28;0;27;0
WireConnection;28;1;24;0
WireConnection;259;1;261;0
WireConnection;251;0;247;0
WireConnection;251;1;249;0
WireConnection;79;0;190;0
WireConnection;128;0;190;0
WireConnection;128;1;129;1
WireConnection;128;2;129;2
WireConnection;29;0;22;1
WireConnection;29;1;24;0
WireConnection;32;0;29;0
WireConnection;32;1;28;0
WireConnection;260;0;251;0
WireConnection;260;1;259;0
WireConnection;82;0;83;0
WireConnection;82;1;79;0
WireConnection;81;0;128;0
WireConnection;81;1;80;0
WireConnection;37;0;29;0
WireConnection;37;1;32;0
WireConnection;84;0;82;0
WireConnection;84;1;81;0
WireConnection;252;0;260;0
WireConnection;256;0;255;0
WireConnection;119;0;116;0
WireConnection;119;1;115;0
WireConnection;119;2;244;0
WireConnection;63;0;84;0
WireConnection;63;1;37;0
WireConnection;127;0;125;0
WireConnection;127;1;73;0
WireConnection;52;0;42;0
WireConnection;52;1;159;0
WireConnection;52;2;107;0
WireConnection;221;0;209;0
WireConnection;126;0;29;0
WireConnection;45;0;179;0
WireConnection;216;0;218;0
WireConnection;121;0;120;0
WireConnection;121;1;124;0
WireConnection;254;0;252;0
WireConnection;254;3;256;0
WireConnection;254;4;255;0
WireConnection;42;0;45;0
WireConnection;42;2;43;0
WireConnection;42;1;49;0
WireConnection;209;0;189;0
WireConnection;209;1;215;0
WireConnection;223;0;106;0
WireConnection;101;0;190;0
WireConnection;120;1;119;0
WireConnection;122;0;121;0
WireConnection;122;1;223;0
WireConnection;125;0;81;0
WireConnection;125;1;126;0
WireConnection;73;0;56;0
WireConnection;73;1;32;0
WireConnection;116;0;117;0
WireConnection;116;1;118;0
WireConnection;115;0;114;4
WireConnection;115;1;113;4
WireConnection;124;0;190;0
WireConnection;194;0;52;0
WireConnection;1;0;63;0
WireConnection;1;1;101;0
WireConnection;1;2;127;0
WireConnection;1;3;90;0
WireConnection;1;4;89;0
WireConnection;1;6;29;0
WireConnection;1;7;72;0
WireConnection;1;8;254;0
ASEEND*/
//CHKSM=FED5B1819CFAB955F03D312B5924E3713995ED3D