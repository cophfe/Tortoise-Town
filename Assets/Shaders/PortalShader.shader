// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "PortalShader"
{
	Properties
	{
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[ASEBegin]_OutlineDetailScale("OutlineDetailScale", Float) = 101.95
		_OutlineColor("OutlineColor", Color) = (0.08962262,0.5587614,1,0)
		_RotationSpeed("RotationSpeed", Float) = 0.5
		_ZoomAmount("ZoomAmount", Float) = 1
		_ScaleSize("ScaleSize", Float) = 10
		_MainColor("MainColor", Color) = (0.3537736,0.7963476,1,0)
		_SecondColor("SecondColor", Color) = (0,0.6476085,1,0)
		_Alpha("Alpha", Range( 0 , 1)) = 0
		_Offset("Offset", Float) = 4
		_TwistAmount("TwistAmount", Float) = 73.3
		_WaveLength("WaveLength", Float) = 0
		_Amplitude("Amplitude", Float) = 0
		_Center("Center", Vector) = (0,0,0,0)
		[ASEEnd]_ScaleAmount("ScaleAmount", Float) = 0.41

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

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_SCREEN_POSITION
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
			uniform float4 _CameraDepthTexture_TexelSize;
			UNITY_INSTANCING_BUFFER_START(PortalShader)
				UNITY_DEFINE_INSTANCED_PROP(float4, _MainColor)
				UNITY_DEFINE_INSTANCED_PROP(float4, _SecondColor)
				UNITY_DEFINE_INSTANCED_PROP(float4, _OutlineColor)
				UNITY_DEFINE_INSTANCED_PROP(float2, _Center)
				UNITY_DEFINE_INSTANCED_PROP(float, _ScaleSize)
				UNITY_DEFINE_INSTANCED_PROP(float, _ZoomAmount)
				UNITY_DEFINE_INSTANCED_PROP(float, _RotationSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _TwistAmount)
				UNITY_DEFINE_INSTANCED_PROP(float, _Amplitude)
				UNITY_DEFINE_INSTANCED_PROP(float, _WaveLength)
				UNITY_DEFINE_INSTANCED_PROP(float, _ScaleAmount)
				UNITY_DEFINE_INSTANCED_PROP(float, _Offset)
				UNITY_DEFINE_INSTANCED_PROP(float, _OutlineDetailScale)
				UNITY_DEFINE_INSTANCED_PROP(float, _Alpha)
			UNITY_INSTANCING_BUFFER_END(PortalShader)


					float2 voronoihash16( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi16( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash16( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						
						 		}
						 	}
						}
						return F1;
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

				float4 _MainColor_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_MainColor);
				float _ScaleSize_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_ScaleSize);
				float _ZoomAmount_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_ZoomAmount);
				float _RotationSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_RotationSpeed);
				float time16 = ( _TimeParameters.x * _RotationSpeed_Instance );
				float2 voronoiSmoothId0 = 0;
				float2 coords16 = v.texcoord.xy * ( _ScaleSize_Instance + ( _TimeParameters.z * _ZoomAmount_Instance ) );
				float2 id16 = 0;
				float2 uv16 = 0;
				float fade16 = 0.5;
				float voroi16 = 0;
				float rest16 = 0;
				for( int it16 = 0; it16 <8; it16++ ){
				voroi16 += fade16 * voronoi16( coords16, time16, id16, uv16, 0,voronoiSmoothId0 );
				rest16 += fade16;
				coords16 *= 2;
				fade16 *= 0.5;
				}//Voronoi16
				voroi16 /= rest16;
				float4 _SecondColor_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_SecondColor);
				float4 temp_output_31_0 = ( ( _MainColor_Instance * ( 1.0 - voroi16 ) ) + ( voroi16 * _SecondColor_Instance ) );
				float2 texCoord47_g1 = v.texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 _Center_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_Center);
				float2 center45_g1 = _Center_Instance;
				float2 delta6_g1 = ( texCoord47_g1 - center45_g1 );
				float _TwistAmount_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_TwistAmount);
				float angle10_g1 = ( length( delta6_g1 ) * _TwistAmount_Instance );
				float x23_g1 = ( ( cos( angle10_g1 ) * delta6_g1.x ) - ( sin( angle10_g1 ) * delta6_g1.y ) );
				float2 break40_g1 = center45_g1;
				float2 break41_g1 = float2( 0,0 );
				float y35_g1 = ( ( sin( angle10_g1 ) * delta6_g1.x ) + ( cos( angle10_g1 ) * delta6_g1.y ) );
				float2 appendResult44_g1 = (float2(( x23_g1 + break40_g1.x + break41_g1.x ) , ( break40_g1.y + break41_g1.y + y35_g1 )));
				float2 temp_output_60_0 = appendResult44_g1;
				float cos72 = cos( _TimeParameters.x );
				float sin72 = sin( _TimeParameters.x );
				float2 rotator72 = mul( temp_output_60_0 - float2( 0.5,0.5 ) , float2x2( cos72 , -sin72 , sin72 , cos72 )) + float2( 0.5,0.5 );
				float grayscale80 = Luminance(float3( temp_output_60_0 ,  0.0 ));
				float smoothstepResult82 = smoothstep( 0.0 , 0.11 , grayscale80);
				float2 break22_g3 = ( v.texcoord.xy * ( temp_output_31_0 * float4( rotator72, 0.0 , 0.0 ) * smoothstepResult82 ).rg );
				float _Amplitude_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_Amplitude);
				float _WaveLength_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_WaveLength);
				float temp_output_9_0_g3 = ( ( break22_g3.y / _Amplitude_Instance ) - (sin( ( ( break22_g3.x / _WaveLength_Instance ) * TWO_PI ) )*0.5 + 0.5) );
				float temp_output_5_0_g3 = ( abs( ( temp_output_9_0_g3 - round( temp_output_9_0_g3 ) ) ) * 2.0 );
				float smoothstepResult1_g3 = smoothstep( 0.5 , 0.55 , temp_output_5_0_g3);
				float temp_output_67_0 = smoothstepResult1_g3;
				float temp_output_65_0 = ( 1.0 - temp_output_67_0 );
				float3 smoothstepResult93 = smoothstep( float3( 0.5,0.5,0.5 ) , float3( 1,1,1 ) , ( temp_output_67_0 * v.ase_normal ));
				float _ScaleAmount_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_ScaleAmount);
				
				o.ase_texcoord7.xy = v.texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord7.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = ( ( ( temp_output_65_0 * v.ase_normal ) + smoothstepResult93 ) * _ScaleAmount_Instance );
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

				float4 ase_screenPosNorm = ScreenPos / ScreenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float eyeDepth36 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float _Offset_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_Offset);
				float smoothstepResult52 = smoothstep( 0.0 , 1.0 , ( 1.0 - ( eyeDepth36 - ( ScreenPos.w + _Offset_Instance ) ) ));
				float2 texCoord11 = IN.ase_texcoord7.xy * float2( 1,1 ) + float2( 0,0 );
				float _OutlineDetailScale_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_OutlineDetailScale);
				float simpleNoise10 = SimpleNoise( texCoord11*_OutlineDetailScale_Instance );
				float4 _OutlineColor_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_OutlineColor);
				float4 temp_output_57_0 = ( simpleNoise10 * _OutlineColor_Instance );
				float4 Outline14 = ( smoothstepResult52 * temp_output_57_0 );
				float4 _MainColor_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_MainColor);
				float _ScaleSize_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_ScaleSize);
				float _ZoomAmount_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_ZoomAmount);
				float _RotationSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_RotationSpeed);
				float time16 = ( _TimeParameters.x * _RotationSpeed_Instance );
				float2 voronoiSmoothId0 = 0;
				float2 coords16 = IN.ase_texcoord7.xy * ( _ScaleSize_Instance + ( _TimeParameters.z * _ZoomAmount_Instance ) );
				float2 id16 = 0;
				float2 uv16 = 0;
				float fade16 = 0.5;
				float voroi16 = 0;
				float rest16 = 0;
				for( int it16 = 0; it16 <8; it16++ ){
				voroi16 += fade16 * voronoi16( coords16, time16, id16, uv16, 0,voronoiSmoothId0 );
				rest16 += fade16;
				coords16 *= 2;
				fade16 *= 0.5;
				}//Voronoi16
				voroi16 /= rest16;
				float4 _SecondColor_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_SecondColor);
				float4 temp_output_31_0 = ( ( _MainColor_Instance * ( 1.0 - voroi16 ) ) + ( voroi16 * _SecondColor_Instance ) );
				float2 texCoord47_g1 = IN.ase_texcoord7.xy * float2( 1,1 ) + float2( 0,0 );
				float2 _Center_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_Center);
				float2 center45_g1 = _Center_Instance;
				float2 delta6_g1 = ( texCoord47_g1 - center45_g1 );
				float _TwistAmount_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_TwistAmount);
				float angle10_g1 = ( length( delta6_g1 ) * _TwistAmount_Instance );
				float x23_g1 = ( ( cos( angle10_g1 ) * delta6_g1.x ) - ( sin( angle10_g1 ) * delta6_g1.y ) );
				float2 break40_g1 = center45_g1;
				float2 break41_g1 = float2( 0,0 );
				float y35_g1 = ( ( sin( angle10_g1 ) * delta6_g1.x ) + ( cos( angle10_g1 ) * delta6_g1.y ) );
				float2 appendResult44_g1 = (float2(( x23_g1 + break40_g1.x + break41_g1.x ) , ( break40_g1.y + break41_g1.y + y35_g1 )));
				float2 temp_output_60_0 = appendResult44_g1;
				float cos72 = cos( _TimeParameters.x );
				float sin72 = sin( _TimeParameters.x );
				float2 rotator72 = mul( temp_output_60_0 - float2( 0.5,0.5 ) , float2x2( cos72 , -sin72 , sin72 , cos72 )) + float2( 0.5,0.5 );
				float grayscale80 = Luminance(float3( temp_output_60_0 ,  0.0 ));
				float smoothstepResult82 = smoothstep( 0.0 , 0.11 , grayscale80);
				float2 break22_g3 = ( IN.ase_texcoord7.xy * ( temp_output_31_0 * float4( rotator72, 0.0 , 0.0 ) * smoothstepResult82 ).rg );
				float _Amplitude_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_Amplitude);
				float _WaveLength_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_WaveLength);
				float temp_output_9_0_g3 = ( ( break22_g3.y / _Amplitude_Instance ) - (sin( ( ( break22_g3.x / _WaveLength_Instance ) * TWO_PI ) )*0.5 + 0.5) );
				float temp_output_5_0_g3 = ( abs( ( temp_output_9_0_g3 - round( temp_output_9_0_g3 ) ) ) * 2.0 );
				float smoothstepResult1_g3 = smoothstep( 0.5 , 0.55 , temp_output_5_0_g3);
				float temp_output_67_0 = smoothstepResult1_g3;
				float temp_output_65_0 = ( 1.0 - temp_output_67_0 );
				
				float _Alpha_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_Alpha);
				
				float3 Albedo = ( Outline14 + ( temp_output_31_0 + ( temp_output_31_0 * temp_output_65_0 ) ) ).rgb;
				float3 Normal = float3(0, 0, 1);
				float3 Emission = 0;
				float3 Specular = 0.5;
				float Metallic = 0;
				float Smoothness = 0.5;
				float Occlusion = 1;
				float Alpha = _Alpha_Instance;
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

			#define ASE_NEEDS_VERT_NORMAL
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
			UNITY_INSTANCING_BUFFER_START(PortalShader)
				UNITY_DEFINE_INSTANCED_PROP(float4, _MainColor)
				UNITY_DEFINE_INSTANCED_PROP(float4, _SecondColor)
				UNITY_DEFINE_INSTANCED_PROP(float2, _Center)
				UNITY_DEFINE_INSTANCED_PROP(float, _ScaleSize)
				UNITY_DEFINE_INSTANCED_PROP(float, _ZoomAmount)
				UNITY_DEFINE_INSTANCED_PROP(float, _RotationSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _TwistAmount)
				UNITY_DEFINE_INSTANCED_PROP(float, _Amplitude)
				UNITY_DEFINE_INSTANCED_PROP(float, _WaveLength)
				UNITY_DEFINE_INSTANCED_PROP(float, _ScaleAmount)
				UNITY_DEFINE_INSTANCED_PROP(float, _Alpha)
			UNITY_INSTANCING_BUFFER_END(PortalShader)


					float2 voronoihash16( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi16( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash16( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						
						 		}
						 	}
						}
						return F1;
					}
			

			float3 _LightDirection;

			VertexOutput VertexFunction( VertexInput v )
			{
				VertexOutput o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				float4 _MainColor_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_MainColor);
				float _ScaleSize_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_ScaleSize);
				float _ZoomAmount_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_ZoomAmount);
				float _RotationSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_RotationSpeed);
				float time16 = ( _TimeParameters.x * _RotationSpeed_Instance );
				float2 voronoiSmoothId0 = 0;
				float2 coords16 = v.ase_texcoord.xy * ( _ScaleSize_Instance + ( _TimeParameters.z * _ZoomAmount_Instance ) );
				float2 id16 = 0;
				float2 uv16 = 0;
				float fade16 = 0.5;
				float voroi16 = 0;
				float rest16 = 0;
				for( int it16 = 0; it16 <8; it16++ ){
				voroi16 += fade16 * voronoi16( coords16, time16, id16, uv16, 0,voronoiSmoothId0 );
				rest16 += fade16;
				coords16 *= 2;
				fade16 *= 0.5;
				}//Voronoi16
				voroi16 /= rest16;
				float4 _SecondColor_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_SecondColor);
				float4 temp_output_31_0 = ( ( _MainColor_Instance * ( 1.0 - voroi16 ) ) + ( voroi16 * _SecondColor_Instance ) );
				float2 texCoord47_g1 = v.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 _Center_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_Center);
				float2 center45_g1 = _Center_Instance;
				float2 delta6_g1 = ( texCoord47_g1 - center45_g1 );
				float _TwistAmount_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_TwistAmount);
				float angle10_g1 = ( length( delta6_g1 ) * _TwistAmount_Instance );
				float x23_g1 = ( ( cos( angle10_g1 ) * delta6_g1.x ) - ( sin( angle10_g1 ) * delta6_g1.y ) );
				float2 break40_g1 = center45_g1;
				float2 break41_g1 = float2( 0,0 );
				float y35_g1 = ( ( sin( angle10_g1 ) * delta6_g1.x ) + ( cos( angle10_g1 ) * delta6_g1.y ) );
				float2 appendResult44_g1 = (float2(( x23_g1 + break40_g1.x + break41_g1.x ) , ( break40_g1.y + break41_g1.y + y35_g1 )));
				float2 temp_output_60_0 = appendResult44_g1;
				float cos72 = cos( _TimeParameters.x );
				float sin72 = sin( _TimeParameters.x );
				float2 rotator72 = mul( temp_output_60_0 - float2( 0.5,0.5 ) , float2x2( cos72 , -sin72 , sin72 , cos72 )) + float2( 0.5,0.5 );
				float grayscale80 = Luminance(float3( temp_output_60_0 ,  0.0 ));
				float smoothstepResult82 = smoothstep( 0.0 , 0.11 , grayscale80);
				float2 break22_g3 = ( v.ase_texcoord.xy * ( temp_output_31_0 * float4( rotator72, 0.0 , 0.0 ) * smoothstepResult82 ).rg );
				float _Amplitude_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_Amplitude);
				float _WaveLength_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_WaveLength);
				float temp_output_9_0_g3 = ( ( break22_g3.y / _Amplitude_Instance ) - (sin( ( ( break22_g3.x / _WaveLength_Instance ) * TWO_PI ) )*0.5 + 0.5) );
				float temp_output_5_0_g3 = ( abs( ( temp_output_9_0_g3 - round( temp_output_9_0_g3 ) ) ) * 2.0 );
				float smoothstepResult1_g3 = smoothstep( 0.5 , 0.55 , temp_output_5_0_g3);
				float temp_output_67_0 = smoothstepResult1_g3;
				float temp_output_65_0 = ( 1.0 - temp_output_67_0 );
				float3 smoothstepResult93 = smoothstep( float3( 0.5,0.5,0.5 ) , float3( 1,1,1 ) , ( temp_output_67_0 * v.ase_normal ));
				float _ScaleAmount_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_ScaleAmount);
				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = ( ( ( temp_output_65_0 * v.ase_normal ) + smoothstepResult93 ) * _ScaleAmount_Instance );
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

				float _Alpha_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_Alpha);
				
				float Alpha = _Alpha_Instance;
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

			#define ASE_NEEDS_VERT_NORMAL
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
			UNITY_INSTANCING_BUFFER_START(PortalShader)
				UNITY_DEFINE_INSTANCED_PROP(float4, _MainColor)
				UNITY_DEFINE_INSTANCED_PROP(float4, _SecondColor)
				UNITY_DEFINE_INSTANCED_PROP(float2, _Center)
				UNITY_DEFINE_INSTANCED_PROP(float, _ScaleSize)
				UNITY_DEFINE_INSTANCED_PROP(float, _ZoomAmount)
				UNITY_DEFINE_INSTANCED_PROP(float, _RotationSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _TwistAmount)
				UNITY_DEFINE_INSTANCED_PROP(float, _Amplitude)
				UNITY_DEFINE_INSTANCED_PROP(float, _WaveLength)
				UNITY_DEFINE_INSTANCED_PROP(float, _ScaleAmount)
				UNITY_DEFINE_INSTANCED_PROP(float, _Alpha)
			UNITY_INSTANCING_BUFFER_END(PortalShader)


					float2 voronoihash16( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi16( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash16( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						
						 		}
						 	}
						}
						return F1;
					}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 _MainColor_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_MainColor);
				float _ScaleSize_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_ScaleSize);
				float _ZoomAmount_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_ZoomAmount);
				float _RotationSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_RotationSpeed);
				float time16 = ( _TimeParameters.x * _RotationSpeed_Instance );
				float2 voronoiSmoothId0 = 0;
				float2 coords16 = v.ase_texcoord.xy * ( _ScaleSize_Instance + ( _TimeParameters.z * _ZoomAmount_Instance ) );
				float2 id16 = 0;
				float2 uv16 = 0;
				float fade16 = 0.5;
				float voroi16 = 0;
				float rest16 = 0;
				for( int it16 = 0; it16 <8; it16++ ){
				voroi16 += fade16 * voronoi16( coords16, time16, id16, uv16, 0,voronoiSmoothId0 );
				rest16 += fade16;
				coords16 *= 2;
				fade16 *= 0.5;
				}//Voronoi16
				voroi16 /= rest16;
				float4 _SecondColor_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_SecondColor);
				float4 temp_output_31_0 = ( ( _MainColor_Instance * ( 1.0 - voroi16 ) ) + ( voroi16 * _SecondColor_Instance ) );
				float2 texCoord47_g1 = v.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 _Center_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_Center);
				float2 center45_g1 = _Center_Instance;
				float2 delta6_g1 = ( texCoord47_g1 - center45_g1 );
				float _TwistAmount_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_TwistAmount);
				float angle10_g1 = ( length( delta6_g1 ) * _TwistAmount_Instance );
				float x23_g1 = ( ( cos( angle10_g1 ) * delta6_g1.x ) - ( sin( angle10_g1 ) * delta6_g1.y ) );
				float2 break40_g1 = center45_g1;
				float2 break41_g1 = float2( 0,0 );
				float y35_g1 = ( ( sin( angle10_g1 ) * delta6_g1.x ) + ( cos( angle10_g1 ) * delta6_g1.y ) );
				float2 appendResult44_g1 = (float2(( x23_g1 + break40_g1.x + break41_g1.x ) , ( break40_g1.y + break41_g1.y + y35_g1 )));
				float2 temp_output_60_0 = appendResult44_g1;
				float cos72 = cos( _TimeParameters.x );
				float sin72 = sin( _TimeParameters.x );
				float2 rotator72 = mul( temp_output_60_0 - float2( 0.5,0.5 ) , float2x2( cos72 , -sin72 , sin72 , cos72 )) + float2( 0.5,0.5 );
				float grayscale80 = Luminance(float3( temp_output_60_0 ,  0.0 ));
				float smoothstepResult82 = smoothstep( 0.0 , 0.11 , grayscale80);
				float2 break22_g3 = ( v.ase_texcoord.xy * ( temp_output_31_0 * float4( rotator72, 0.0 , 0.0 ) * smoothstepResult82 ).rg );
				float _Amplitude_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_Amplitude);
				float _WaveLength_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_WaveLength);
				float temp_output_9_0_g3 = ( ( break22_g3.y / _Amplitude_Instance ) - (sin( ( ( break22_g3.x / _WaveLength_Instance ) * TWO_PI ) )*0.5 + 0.5) );
				float temp_output_5_0_g3 = ( abs( ( temp_output_9_0_g3 - round( temp_output_9_0_g3 ) ) ) * 2.0 );
				float smoothstepResult1_g3 = smoothstep( 0.5 , 0.55 , temp_output_5_0_g3);
				float temp_output_67_0 = smoothstepResult1_g3;
				float temp_output_65_0 = ( 1.0 - temp_output_67_0 );
				float3 smoothstepResult93 = smoothstep( float3( 0.5,0.5,0.5 ) , float3( 1,1,1 ) , ( temp_output_67_0 * v.ase_normal ));
				float _ScaleAmount_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_ScaleAmount);
				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = ( ( ( temp_output_65_0 * v.ase_normal ) + smoothstepResult93 ) * _ScaleAmount_Instance );
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

				float _Alpha_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_Alpha);
				
				float Alpha = _Alpha_Instance;
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

			#define ASE_NEEDS_VERT_NORMAL
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
				float4 ase_texcoord3 : TEXCOORD3;
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
			UNITY_INSTANCING_BUFFER_START(PortalShader)
				UNITY_DEFINE_INSTANCED_PROP(float4, _MainColor)
				UNITY_DEFINE_INSTANCED_PROP(float4, _SecondColor)
				UNITY_DEFINE_INSTANCED_PROP(float4, _OutlineColor)
				UNITY_DEFINE_INSTANCED_PROP(float2, _Center)
				UNITY_DEFINE_INSTANCED_PROP(float, _ScaleSize)
				UNITY_DEFINE_INSTANCED_PROP(float, _ZoomAmount)
				UNITY_DEFINE_INSTANCED_PROP(float, _RotationSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _TwistAmount)
				UNITY_DEFINE_INSTANCED_PROP(float, _Amplitude)
				UNITY_DEFINE_INSTANCED_PROP(float, _WaveLength)
				UNITY_DEFINE_INSTANCED_PROP(float, _ScaleAmount)
				UNITY_DEFINE_INSTANCED_PROP(float, _Offset)
				UNITY_DEFINE_INSTANCED_PROP(float, _OutlineDetailScale)
				UNITY_DEFINE_INSTANCED_PROP(float, _Alpha)
			UNITY_INSTANCING_BUFFER_END(PortalShader)


					float2 voronoihash16( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi16( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash16( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						
						 		}
						 	}
						}
						return F1;
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

				float4 _MainColor_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_MainColor);
				float _ScaleSize_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_ScaleSize);
				float _ZoomAmount_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_ZoomAmount);
				float _RotationSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_RotationSpeed);
				float time16 = ( _TimeParameters.x * _RotationSpeed_Instance );
				float2 voronoiSmoothId0 = 0;
				float2 coords16 = v.ase_texcoord.xy * ( _ScaleSize_Instance + ( _TimeParameters.z * _ZoomAmount_Instance ) );
				float2 id16 = 0;
				float2 uv16 = 0;
				float fade16 = 0.5;
				float voroi16 = 0;
				float rest16 = 0;
				for( int it16 = 0; it16 <8; it16++ ){
				voroi16 += fade16 * voronoi16( coords16, time16, id16, uv16, 0,voronoiSmoothId0 );
				rest16 += fade16;
				coords16 *= 2;
				fade16 *= 0.5;
				}//Voronoi16
				voroi16 /= rest16;
				float4 _SecondColor_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_SecondColor);
				float4 temp_output_31_0 = ( ( _MainColor_Instance * ( 1.0 - voroi16 ) ) + ( voroi16 * _SecondColor_Instance ) );
				float2 texCoord47_g1 = v.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 _Center_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_Center);
				float2 center45_g1 = _Center_Instance;
				float2 delta6_g1 = ( texCoord47_g1 - center45_g1 );
				float _TwistAmount_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_TwistAmount);
				float angle10_g1 = ( length( delta6_g1 ) * _TwistAmount_Instance );
				float x23_g1 = ( ( cos( angle10_g1 ) * delta6_g1.x ) - ( sin( angle10_g1 ) * delta6_g1.y ) );
				float2 break40_g1 = center45_g1;
				float2 break41_g1 = float2( 0,0 );
				float y35_g1 = ( ( sin( angle10_g1 ) * delta6_g1.x ) + ( cos( angle10_g1 ) * delta6_g1.y ) );
				float2 appendResult44_g1 = (float2(( x23_g1 + break40_g1.x + break41_g1.x ) , ( break40_g1.y + break41_g1.y + y35_g1 )));
				float2 temp_output_60_0 = appendResult44_g1;
				float cos72 = cos( _TimeParameters.x );
				float sin72 = sin( _TimeParameters.x );
				float2 rotator72 = mul( temp_output_60_0 - float2( 0.5,0.5 ) , float2x2( cos72 , -sin72 , sin72 , cos72 )) + float2( 0.5,0.5 );
				float grayscale80 = Luminance(float3( temp_output_60_0 ,  0.0 ));
				float smoothstepResult82 = smoothstep( 0.0 , 0.11 , grayscale80);
				float2 break22_g3 = ( v.ase_texcoord.xy * ( temp_output_31_0 * float4( rotator72, 0.0 , 0.0 ) * smoothstepResult82 ).rg );
				float _Amplitude_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_Amplitude);
				float _WaveLength_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_WaveLength);
				float temp_output_9_0_g3 = ( ( break22_g3.y / _Amplitude_Instance ) - (sin( ( ( break22_g3.x / _WaveLength_Instance ) * TWO_PI ) )*0.5 + 0.5) );
				float temp_output_5_0_g3 = ( abs( ( temp_output_9_0_g3 - round( temp_output_9_0_g3 ) ) ) * 2.0 );
				float smoothstepResult1_g3 = smoothstep( 0.5 , 0.55 , temp_output_5_0_g3);
				float temp_output_67_0 = smoothstepResult1_g3;
				float temp_output_65_0 = ( 1.0 - temp_output_67_0 );
				float3 smoothstepResult93 = smoothstep( float3( 0.5,0.5,0.5 ) , float3( 1,1,1 ) , ( temp_output_67_0 * v.ase_normal ));
				float _ScaleAmount_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_ScaleAmount);
				
				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord2 = screenPos;
				
				o.ase_texcoord3.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.zw = 0;
				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = ( ( ( temp_output_65_0 * v.ase_normal ) + smoothstepResult93 ) * _ScaleAmount_Instance );
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

				float4 screenPos = IN.ase_texcoord2;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float eyeDepth36 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float _Offset_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_Offset);
				float smoothstepResult52 = smoothstep( 0.0 , 1.0 , ( 1.0 - ( eyeDepth36 - ( screenPos.w + _Offset_Instance ) ) ));
				float2 texCoord11 = IN.ase_texcoord3.xy * float2( 1,1 ) + float2( 0,0 );
				float _OutlineDetailScale_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_OutlineDetailScale);
				float simpleNoise10 = SimpleNoise( texCoord11*_OutlineDetailScale_Instance );
				float4 _OutlineColor_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_OutlineColor);
				float4 temp_output_57_0 = ( simpleNoise10 * _OutlineColor_Instance );
				float4 Outline14 = ( smoothstepResult52 * temp_output_57_0 );
				float4 _MainColor_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_MainColor);
				float _ScaleSize_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_ScaleSize);
				float _ZoomAmount_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_ZoomAmount);
				float _RotationSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_RotationSpeed);
				float time16 = ( _TimeParameters.x * _RotationSpeed_Instance );
				float2 voronoiSmoothId0 = 0;
				float2 coords16 = IN.ase_texcoord3.xy * ( _ScaleSize_Instance + ( _TimeParameters.z * _ZoomAmount_Instance ) );
				float2 id16 = 0;
				float2 uv16 = 0;
				float fade16 = 0.5;
				float voroi16 = 0;
				float rest16 = 0;
				for( int it16 = 0; it16 <8; it16++ ){
				voroi16 += fade16 * voronoi16( coords16, time16, id16, uv16, 0,voronoiSmoothId0 );
				rest16 += fade16;
				coords16 *= 2;
				fade16 *= 0.5;
				}//Voronoi16
				voroi16 /= rest16;
				float4 _SecondColor_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_SecondColor);
				float4 temp_output_31_0 = ( ( _MainColor_Instance * ( 1.0 - voroi16 ) ) + ( voroi16 * _SecondColor_Instance ) );
				float2 texCoord47_g1 = IN.ase_texcoord3.xy * float2( 1,1 ) + float2( 0,0 );
				float2 _Center_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_Center);
				float2 center45_g1 = _Center_Instance;
				float2 delta6_g1 = ( texCoord47_g1 - center45_g1 );
				float _TwistAmount_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_TwistAmount);
				float angle10_g1 = ( length( delta6_g1 ) * _TwistAmount_Instance );
				float x23_g1 = ( ( cos( angle10_g1 ) * delta6_g1.x ) - ( sin( angle10_g1 ) * delta6_g1.y ) );
				float2 break40_g1 = center45_g1;
				float2 break41_g1 = float2( 0,0 );
				float y35_g1 = ( ( sin( angle10_g1 ) * delta6_g1.x ) + ( cos( angle10_g1 ) * delta6_g1.y ) );
				float2 appendResult44_g1 = (float2(( x23_g1 + break40_g1.x + break41_g1.x ) , ( break40_g1.y + break41_g1.y + y35_g1 )));
				float2 temp_output_60_0 = appendResult44_g1;
				float cos72 = cos( _TimeParameters.x );
				float sin72 = sin( _TimeParameters.x );
				float2 rotator72 = mul( temp_output_60_0 - float2( 0.5,0.5 ) , float2x2( cos72 , -sin72 , sin72 , cos72 )) + float2( 0.5,0.5 );
				float grayscale80 = Luminance(float3( temp_output_60_0 ,  0.0 ));
				float smoothstepResult82 = smoothstep( 0.0 , 0.11 , grayscale80);
				float2 break22_g3 = ( IN.ase_texcoord3.xy * ( temp_output_31_0 * float4( rotator72, 0.0 , 0.0 ) * smoothstepResult82 ).rg );
				float _Amplitude_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_Amplitude);
				float _WaveLength_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_WaveLength);
				float temp_output_9_0_g3 = ( ( break22_g3.y / _Amplitude_Instance ) - (sin( ( ( break22_g3.x / _WaveLength_Instance ) * TWO_PI ) )*0.5 + 0.5) );
				float temp_output_5_0_g3 = ( abs( ( temp_output_9_0_g3 - round( temp_output_9_0_g3 ) ) ) * 2.0 );
				float smoothstepResult1_g3 = smoothstep( 0.5 , 0.55 , temp_output_5_0_g3);
				float temp_output_67_0 = smoothstepResult1_g3;
				float temp_output_65_0 = ( 1.0 - temp_output_67_0 );
				
				float _Alpha_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_Alpha);
				
				
				float3 Albedo = ( Outline14 + ( temp_output_31_0 + ( temp_output_31_0 * temp_output_65_0 ) ) ).rgb;
				float3 Emission = 0;
				float Alpha = _Alpha_Instance;
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
			
			#define ASE_NEEDS_VERT_NORMAL
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
				float4 ase_texcoord3 : TEXCOORD3;
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
			UNITY_INSTANCING_BUFFER_START(PortalShader)
				UNITY_DEFINE_INSTANCED_PROP(float4, _MainColor)
				UNITY_DEFINE_INSTANCED_PROP(float4, _SecondColor)
				UNITY_DEFINE_INSTANCED_PROP(float4, _OutlineColor)
				UNITY_DEFINE_INSTANCED_PROP(float2, _Center)
				UNITY_DEFINE_INSTANCED_PROP(float, _ScaleSize)
				UNITY_DEFINE_INSTANCED_PROP(float, _ZoomAmount)
				UNITY_DEFINE_INSTANCED_PROP(float, _RotationSpeed)
				UNITY_DEFINE_INSTANCED_PROP(float, _TwistAmount)
				UNITY_DEFINE_INSTANCED_PROP(float, _Amplitude)
				UNITY_DEFINE_INSTANCED_PROP(float, _WaveLength)
				UNITY_DEFINE_INSTANCED_PROP(float, _ScaleAmount)
				UNITY_DEFINE_INSTANCED_PROP(float, _Offset)
				UNITY_DEFINE_INSTANCED_PROP(float, _OutlineDetailScale)
				UNITY_DEFINE_INSTANCED_PROP(float, _Alpha)
			UNITY_INSTANCING_BUFFER_END(PortalShader)


					float2 voronoihash16( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi16( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash16( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						
						 		}
						 	}
						}
						return F1;
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

				float4 _MainColor_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_MainColor);
				float _ScaleSize_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_ScaleSize);
				float _ZoomAmount_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_ZoomAmount);
				float _RotationSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_RotationSpeed);
				float time16 = ( _TimeParameters.x * _RotationSpeed_Instance );
				float2 voronoiSmoothId0 = 0;
				float2 coords16 = v.ase_texcoord.xy * ( _ScaleSize_Instance + ( _TimeParameters.z * _ZoomAmount_Instance ) );
				float2 id16 = 0;
				float2 uv16 = 0;
				float fade16 = 0.5;
				float voroi16 = 0;
				float rest16 = 0;
				for( int it16 = 0; it16 <8; it16++ ){
				voroi16 += fade16 * voronoi16( coords16, time16, id16, uv16, 0,voronoiSmoothId0 );
				rest16 += fade16;
				coords16 *= 2;
				fade16 *= 0.5;
				}//Voronoi16
				voroi16 /= rest16;
				float4 _SecondColor_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_SecondColor);
				float4 temp_output_31_0 = ( ( _MainColor_Instance * ( 1.0 - voroi16 ) ) + ( voroi16 * _SecondColor_Instance ) );
				float2 texCoord47_g1 = v.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 _Center_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_Center);
				float2 center45_g1 = _Center_Instance;
				float2 delta6_g1 = ( texCoord47_g1 - center45_g1 );
				float _TwistAmount_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_TwistAmount);
				float angle10_g1 = ( length( delta6_g1 ) * _TwistAmount_Instance );
				float x23_g1 = ( ( cos( angle10_g1 ) * delta6_g1.x ) - ( sin( angle10_g1 ) * delta6_g1.y ) );
				float2 break40_g1 = center45_g1;
				float2 break41_g1 = float2( 0,0 );
				float y35_g1 = ( ( sin( angle10_g1 ) * delta6_g1.x ) + ( cos( angle10_g1 ) * delta6_g1.y ) );
				float2 appendResult44_g1 = (float2(( x23_g1 + break40_g1.x + break41_g1.x ) , ( break40_g1.y + break41_g1.y + y35_g1 )));
				float2 temp_output_60_0 = appendResult44_g1;
				float cos72 = cos( _TimeParameters.x );
				float sin72 = sin( _TimeParameters.x );
				float2 rotator72 = mul( temp_output_60_0 - float2( 0.5,0.5 ) , float2x2( cos72 , -sin72 , sin72 , cos72 )) + float2( 0.5,0.5 );
				float grayscale80 = Luminance(float3( temp_output_60_0 ,  0.0 ));
				float smoothstepResult82 = smoothstep( 0.0 , 0.11 , grayscale80);
				float2 break22_g3 = ( v.ase_texcoord.xy * ( temp_output_31_0 * float4( rotator72, 0.0 , 0.0 ) * smoothstepResult82 ).rg );
				float _Amplitude_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_Amplitude);
				float _WaveLength_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_WaveLength);
				float temp_output_9_0_g3 = ( ( break22_g3.y / _Amplitude_Instance ) - (sin( ( ( break22_g3.x / _WaveLength_Instance ) * TWO_PI ) )*0.5 + 0.5) );
				float temp_output_5_0_g3 = ( abs( ( temp_output_9_0_g3 - round( temp_output_9_0_g3 ) ) ) * 2.0 );
				float smoothstepResult1_g3 = smoothstep( 0.5 , 0.55 , temp_output_5_0_g3);
				float temp_output_67_0 = smoothstepResult1_g3;
				float temp_output_65_0 = ( 1.0 - temp_output_67_0 );
				float3 smoothstepResult93 = smoothstep( float3( 0.5,0.5,0.5 ) , float3( 1,1,1 ) , ( temp_output_67_0 * v.ase_normal ));
				float _ScaleAmount_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_ScaleAmount);
				
				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord2 = screenPos;
				
				o.ase_texcoord3.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.zw = 0;
				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = ( ( ( temp_output_65_0 * v.ase_normal ) + smoothstepResult93 ) * _ScaleAmount_Instance );
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

				float4 screenPos = IN.ase_texcoord2;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float eyeDepth36 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float _Offset_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_Offset);
				float smoothstepResult52 = smoothstep( 0.0 , 1.0 , ( 1.0 - ( eyeDepth36 - ( screenPos.w + _Offset_Instance ) ) ));
				float2 texCoord11 = IN.ase_texcoord3.xy * float2( 1,1 ) + float2( 0,0 );
				float _OutlineDetailScale_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_OutlineDetailScale);
				float simpleNoise10 = SimpleNoise( texCoord11*_OutlineDetailScale_Instance );
				float4 _OutlineColor_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_OutlineColor);
				float4 temp_output_57_0 = ( simpleNoise10 * _OutlineColor_Instance );
				float4 Outline14 = ( smoothstepResult52 * temp_output_57_0 );
				float4 _MainColor_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_MainColor);
				float _ScaleSize_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_ScaleSize);
				float _ZoomAmount_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_ZoomAmount);
				float _RotationSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_RotationSpeed);
				float time16 = ( _TimeParameters.x * _RotationSpeed_Instance );
				float2 voronoiSmoothId0 = 0;
				float2 coords16 = IN.ase_texcoord3.xy * ( _ScaleSize_Instance + ( _TimeParameters.z * _ZoomAmount_Instance ) );
				float2 id16 = 0;
				float2 uv16 = 0;
				float fade16 = 0.5;
				float voroi16 = 0;
				float rest16 = 0;
				for( int it16 = 0; it16 <8; it16++ ){
				voroi16 += fade16 * voronoi16( coords16, time16, id16, uv16, 0,voronoiSmoothId0 );
				rest16 += fade16;
				coords16 *= 2;
				fade16 *= 0.5;
				}//Voronoi16
				voroi16 /= rest16;
				float4 _SecondColor_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_SecondColor);
				float4 temp_output_31_0 = ( ( _MainColor_Instance * ( 1.0 - voroi16 ) ) + ( voroi16 * _SecondColor_Instance ) );
				float2 texCoord47_g1 = IN.ase_texcoord3.xy * float2( 1,1 ) + float2( 0,0 );
				float2 _Center_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_Center);
				float2 center45_g1 = _Center_Instance;
				float2 delta6_g1 = ( texCoord47_g1 - center45_g1 );
				float _TwistAmount_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_TwistAmount);
				float angle10_g1 = ( length( delta6_g1 ) * _TwistAmount_Instance );
				float x23_g1 = ( ( cos( angle10_g1 ) * delta6_g1.x ) - ( sin( angle10_g1 ) * delta6_g1.y ) );
				float2 break40_g1 = center45_g1;
				float2 break41_g1 = float2( 0,0 );
				float y35_g1 = ( ( sin( angle10_g1 ) * delta6_g1.x ) + ( cos( angle10_g1 ) * delta6_g1.y ) );
				float2 appendResult44_g1 = (float2(( x23_g1 + break40_g1.x + break41_g1.x ) , ( break40_g1.y + break41_g1.y + y35_g1 )));
				float2 temp_output_60_0 = appendResult44_g1;
				float cos72 = cos( _TimeParameters.x );
				float sin72 = sin( _TimeParameters.x );
				float2 rotator72 = mul( temp_output_60_0 - float2( 0.5,0.5 ) , float2x2( cos72 , -sin72 , sin72 , cos72 )) + float2( 0.5,0.5 );
				float grayscale80 = Luminance(float3( temp_output_60_0 ,  0.0 ));
				float smoothstepResult82 = smoothstep( 0.0 , 0.11 , grayscale80);
				float2 break22_g3 = ( IN.ase_texcoord3.xy * ( temp_output_31_0 * float4( rotator72, 0.0 , 0.0 ) * smoothstepResult82 ).rg );
				float _Amplitude_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_Amplitude);
				float _WaveLength_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_WaveLength);
				float temp_output_9_0_g3 = ( ( break22_g3.y / _Amplitude_Instance ) - (sin( ( ( break22_g3.x / _WaveLength_Instance ) * TWO_PI ) )*0.5 + 0.5) );
				float temp_output_5_0_g3 = ( abs( ( temp_output_9_0_g3 - round( temp_output_9_0_g3 ) ) ) * 2.0 );
				float smoothstepResult1_g3 = smoothstep( 0.5 , 0.55 , temp_output_5_0_g3);
				float temp_output_67_0 = smoothstepResult1_g3;
				float temp_output_65_0 = ( 1.0 - temp_output_67_0 );
				
				float _Alpha_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShader,_Alpha);
				
				
				float3 Albedo = ( Outline14 + ( temp_output_31_0 + ( temp_output_31_0 * temp_output_65_0 ) ) ).rgb;
				float Alpha = _Alpha_Instance;
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
0;0;1920;1059;705.5254;272.5103;1.6;True;True
Node;AmplifyShaderEditor.CosTime;21;-2495.719,174.6281;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;23;-2513.719,380.6281;Inherit;False;InstancedProperty;_ZoomAmount;ZoomAmount;4;0;Create;True;0;0;0;False;0;False;1;0.1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;25;-2258.719,81.62805;Inherit;False;InstancedProperty;_ScaleSize;ScaleSize;5;0;Create;True;0;0;0;False;0;False;10;10;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;22;-2279.719,265.6281;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;20;-2465.719,73.62805;Inherit;False;InstancedProperty;_RotationSpeed;RotationSpeed;3;0;Create;True;0;0;0;False;0;False;0.5;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;18;-2446.719,-130.3719;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;24;-2097.719,127.6281;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;19;-2273.719,-32.37195;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;63;-2558.048,995.394;Inherit;False;InstancedProperty;_TwistAmount;TwistAmount;10;0;Create;True;0;0;0;False;0;False;73.3;30;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.VoronoiNode;16;-1945.778,-30.45538;Inherit;True;0;0;1;0;8;False;4;False;False;False;4;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;10;False;3;FLOAT;0;False;3;FLOAT;0;FLOAT2;1;FLOAT2;2
Node;AmplifyShaderEditor.Vector2Node;71;-2597.485,830.7455;Inherit;False;InstancedProperty;_Center;Center;13;0;Create;True;0;0;0;False;0;False;0,0;0,0.5;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.ColorNode;30;-1796.51,326.8281;Inherit;False;InstancedProperty;_SecondColor;SecondColor;7;0;Create;True;0;0;0;False;0;False;0,0.6476085,1,0;1,1,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FunctionNode;60;-2340.115,780.3591;Inherit;True;Twirl;-1;;1;90936742ac32db8449cd21ab6dd337c8;0;4;1;FLOAT2;0,0;False;2;FLOAT2;0,0;False;3;FLOAT;0;False;4;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.OneMinusNode;26;-1664,-128;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;27;-1664,-320;Inherit;False;InstancedProperty;_MainColor;MainColor;6;0;Create;True;0;0;0;False;0;False;0.3537736,0.7963476,1,0;0,0.2177578,0.509434,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;50;-2847.753,-1124.413;Inherit;False;InstancedProperty;_Offset;Offset;9;0;Create;True;0;0;0;False;0;False;4;2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenPosInputsNode;42;-2864.364,-1346.413;Float;True;1;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;15;-2925.246,-998.4926;Inherit;False;1832.945;623.0085;;11;12;7;6;9;8;11;13;10;57;58;59;Outline;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleAddOpNode;51;-2510.21,-1262.477;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;29;-1582.01,213.7282;Inherit;True;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ScreenDepthNode;36;-3171.783,-1543.217;Inherit;False;0;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCGrayscale;80;-2059.085,587.5629;Inherit;True;0;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;74;-1851.838,1046.457;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;28;-1398.719,-199.3719;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;41;-2392.364,-1550.413;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;11;-2820.618,-726.1052;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;13;-2843.969,-545.1923;Inherit;False;InstancedProperty;_OutlineDetailScale;OutlineDetailScale;1;0;Create;True;0;0;0;False;0;False;101.95;27.48;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;31;-1143.946,137.1375;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SmoothstepOpNode;82;-1803.085,585.5629;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0.11;False;1;FLOAT;0
Node;AmplifyShaderEditor.RotatorNode;72;-1479.335,676.2749;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT2;0.5,0.5;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;62;-916.8438,568.5495;Inherit;True;3;3;0;COLOR;0,0,0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;70;-947.4564,1138.386;Inherit;False;InstancedProperty;_Amplitude;Amplitude;12;0;Create;True;0;0;0;False;0;False;0;0.1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;69;-997.5366,985.7608;Inherit;False;InstancedProperty;_WaveLength;WaveLength;11;0;Create;True;0;0;0;False;0;False;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;10;-2543.618,-648.1049;Inherit;True;Simple;True;False;2;0;FLOAT2;1,1;False;1;FLOAT;58.61;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;8;-2318.157,-409.9318;Inherit;False;InstancedProperty;_OutlineColor;OutlineColor;2;0;Create;True;0;0;0;False;0;False;0.08962262,0.5587614,1,0;0,1,0.9686274,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.OneMinusNode;46;-2009.258,-1487.725;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;67;-664.4663,936.0791;Inherit;True;Smooth Wave;-1;;3;45d5b33902fbc0848a1166b32106db74;1,3,1;3;17;FLOAT2;1,1;False;16;FLOAT;21.06;False;18;FLOAT;0.06;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;52;-1781.897,-1474.821;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;57;-2033.575,-531.6982;Inherit;True;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.NormalVertexDataNode;85;-149.9293,982.199;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;9;-1510.981,-834.1772;Inherit;True;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;91;61.31166,1267.332;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.OneMinusNode;65;-356.872,860.0883;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;93;340.9167,1256.735;Inherit;True;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0.5,0.5,0.5;False;2;FLOAT3;1,1,1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;86;112.7952,832.1705;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;64;-173.7018,552.2273;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;14;-280.4328,-908.5092;Inherit;False;Outline;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;88;654.7822,1046.414;Inherit;False;InstancedProperty;_ScaleAmount;ScaleAmount;14;0;Create;True;0;0;0;False;0;False;0.41;0.12;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;94;571.8229,777.8557;Inherit;True;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;68;124.8356,266.0379;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;32;10.42657,-87.51681;Inherit;False;14;Outline;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;12;-2142.642,-879.418;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;7;-2875.246,-884.4932;Inherit;False;InstancedProperty;_FresnelScale;FresnelScale;0;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;34;339.5229,-13.75414;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;89;934.8103,720.9302;Inherit;True;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FresnelNode;6;-2587.246,-948.4926;Inherit;True;Standard;WorldNormal;ViewDir;False;False;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;59;-1796.213,-877.7878;Inherit;True;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;35;785.5306,97.28979;Inherit;False;InstancedProperty;_Alpha;Alpha;8;0;Create;True;0;0;0;False;0;False;0;0.613;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;58;-2153.864,-645.6548;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;0;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;0;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;2;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=ShadowCaster;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;3;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;True;False;False;False;False;0;False;-1;False;False;False;False;False;False;False;False;False;True;1;False;-1;False;False;True;1;LightMode=DepthOnly;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;4;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;5;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;Universal2D;0;5;Universal2D;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;5;False;-1;10;False;-1;1;1;False;-1;10;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=Universal2D;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;1426.435,-26.81216;Float;False;True;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;2;PortalShader;94348b07e5e8bab40bd6c8a1e3df54cd;True;Forward;0;1;Forward;18;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;5;False;-1;10;False;-1;1;1;False;-1;10;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=UniversalForward;False;False;0;Hidden/InternalErrorShader;0;0;Standard;38;Workflow;1;Surface;1;  Refraction Model;0;  Blend;0;Two Sided;1;Fragment Normal Space,InvertActionOnDeselection;0;Transmission;0;  Transmission Shadow;0.5,False,-1;Translucency;0;  Translucency Strength;1,False,-1;  Normal Distortion;0.5,False,-1;  Scattering;2,False,-1;  Direct;0.9,False,-1;  Ambient;0.1,False,-1;  Shadow;0.5,False,-1;Cast Shadows;1;  Use Shadow Threshold;0;Receive Shadows;1;GPU Instancing;1;LOD CrossFade;1;Built-in Fog;1;_FinalColorxAlpha;0;Meta Pass;1;Override Baked GI;0;Extra Pre Pass;0;DOTS Instancing;0;Tessellation;0;  Phong;0;  Strength;0.5,False,-1;  Type;0;  Tess;16,False,-1;  Min;10,False,-1;  Max;25,False,-1;  Edge Length;16,False,-1;  Max Displacement;25,False,-1;Write Depth;0;  Early Z;0;Vertex Position,InvertActionOnDeselection;1;0;6;False;True;True;True;True;True;False;;False;0
WireConnection;22;0;21;4
WireConnection;22;1;23;0
WireConnection;24;0;25;0
WireConnection;24;1;22;0
WireConnection;19;0;18;0
WireConnection;19;1;20;0
WireConnection;16;1;19;0
WireConnection;16;2;24;0
WireConnection;60;2;71;0
WireConnection;60;3;63;0
WireConnection;26;0;16;0
WireConnection;51;0;42;4
WireConnection;51;1;50;0
WireConnection;29;0;16;0
WireConnection;29;1;30;0
WireConnection;80;0;60;0
WireConnection;28;0;27;0
WireConnection;28;1;26;0
WireConnection;41;0;36;0
WireConnection;41;1;51;0
WireConnection;31;0;28;0
WireConnection;31;1;29;0
WireConnection;82;0;80;0
WireConnection;72;0;60;0
WireConnection;72;2;74;0
WireConnection;62;0;31;0
WireConnection;62;1;72;0
WireConnection;62;2;82;0
WireConnection;10;0;11;0
WireConnection;10;1;13;0
WireConnection;46;0;41;0
WireConnection;67;17;62;0
WireConnection;67;16;69;0
WireConnection;67;18;70;0
WireConnection;52;0;46;0
WireConnection;57;0;10;0
WireConnection;57;1;8;0
WireConnection;9;0;52;0
WireConnection;9;1;57;0
WireConnection;91;0;67;0
WireConnection;91;1;85;0
WireConnection;65;0;67;0
WireConnection;93;0;91;0
WireConnection;86;0;65;0
WireConnection;86;1;85;0
WireConnection;64;0;31;0
WireConnection;64;1;65;0
WireConnection;14;0;9;0
WireConnection;94;0;86;0
WireConnection;94;1;93;0
WireConnection;68;0;31;0
WireConnection;68;1;64;0
WireConnection;12;0;6;0
WireConnection;12;1;10;0
WireConnection;34;0;32;0
WireConnection;34;1;68;0
WireConnection;89;0;94;0
WireConnection;89;1;88;0
WireConnection;6;2;7;0
WireConnection;59;0;58;0
WireConnection;59;1;57;0
WireConnection;58;0;10;0
WireConnection;1;0;34;0
WireConnection;1;6;35;0
WireConnection;1;8;89;0
ASEEND*/
//CHKSM=6F86E7096CEA05FD070AEDCCF55A959A0FF96D03