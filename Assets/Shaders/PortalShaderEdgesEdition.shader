// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "PortalShaderEdgesEdition"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[ASEBegin]_OutlineDetailScale("OutlineDetailScale", Float) = 101.95
		_OutlineColor("OutlineColor", Color) = (0.08962262,0.5587614,1,0)
		_RotationSpeed("RotationSpeed", Float) = 0.5
		_ZoomAmount("ZoomAmount", Float) = 1
		_ScaleSize("ScaleSize", Float) = 10
		_MainColor("MainColor", Color) = (0.3537736,0.7963476,1,0)
		_SecondColor("SecondColor", Color) = (0,0.6476085,1,0)
		_Offset("Offset", Float) = 4
		_TwistAmount("TwistAmount", Float) = 73.3
		_WaveLength("WaveLength", Float) = 0
		_Amplitude("Amplitude", Float) = 0
		_Center("Center", Vector) = (0,0,0,0)
		_ScaleAmount("ScaleAmount", Float) = 0.41
		_MainTex("Main Texture", 2D) = "white" {}
		_NearDistance("Near Distance", Float) = 0
		_FadeDistance("Fade Distance", Float) = 0
		[HDR]_MaxBrightness("Max Brightness", Color) = (1,1,1,0)
		_PortalStrength("Portal Strength", Float) = 1
		_OutlineOffset("Outline Offset", Float) = 0
		[ASEEnd]_Outline("Outline", Color) = (0,0,0,0)

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
			ZWrite On
			ZTest LEqual
			Offset 0,0
			ColorMask RGBA
			Stencil
			{
				Ref 255
				Comp Always
				Pass Replace
				Fail Keep
				ZFail Keep
			}

			HLSLPROGRAM
			
			#define ASE_SRP_VERSION 90000
			#define REQUIRE_DEPTH_TEXTURE 1

			
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

			#if ASE_SRP_VERSION <= 70108
			#define REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
			#endif

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
				#ifdef ASE_FOG
				float fogFactor : TEXCOORD2;
				#endif
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _MaxBrightness;
			float4 _Outline;
			float _NearDistance;
			float _FadeDistance;
			float _PortalStrength;
			float _OutlineOffset;
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			sampler2D _MainTex;
			uniform float4 _CameraDepthTexture_TexelSize;
			UNITY_INSTANCING_BUFFER_START(PortalShaderEdgesEdition)
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
			UNITY_INSTANCING_BUFFER_END(PortalShaderEdgesEdition)


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
			
			inline float4 ASE_ComputeGrabScreenPos( float4 pos )
			{
				#if UNITY_UV_STARTS_AT_TOP
				float scale = -1.0;
				#else
				float scale = 1.0;
				#endif
				float4 o = pos;
				o.y = pos.w * 0.5f;
				o.y = ( pos.y - o.y ) * _ProjectionParams.x * scale + o.y;
				return o;
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
			
			
			VertexOutput VertexFunction ( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 unityObjectToViewPos124 = TransformWorldToView( TransformObjectToWorld( float3( 0,0,0 )) );
				float smoothstepResult150 = smoothstep( 0.0 , 1.0 , ( ( abs( unityObjectToViewPos124.z ) - _NearDistance ) / _FadeDistance ));
				float4 _MainColor_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_MainColor);
				float _ScaleSize_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_ScaleSize);
				float _ZoomAmount_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_ZoomAmount);
				float _RotationSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_RotationSpeed);
				float time16 = ( _TimeParameters.x * _RotationSpeed_Instance );
				float2 voronoiSmoothId16 = 0;
				float2 coords16 = v.ase_texcoord.xy * ( _ScaleSize_Instance + ( _TimeParameters.z * _ZoomAmount_Instance ) );
				float2 id16 = 0;
				float2 uv16 = 0;
				float fade16 = 0.5;
				float voroi16 = 0;
				float rest16 = 0;
				for( int it16 = 0; it16 <8; it16++ ){
				voroi16 += fade16 * voronoi16( coords16, time16, id16, uv16, 0,voronoiSmoothId16 );
				rest16 += fade16;
				coords16 *= 2;
				fade16 *= 0.5;
				}//Voronoi16
				voroi16 /= rest16;
				float4 _SecondColor_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_SecondColor);
				float4 temp_output_31_0 = ( ( _MainColor_Instance * ( 1.0 - voroi16 ) ) + ( voroi16 * _SecondColor_Instance ) );
				float2 texCoord47_g1 = v.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 _Center_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_Center);
				float2 center45_g1 = _Center_Instance;
				float2 delta6_g1 = ( texCoord47_g1 - center45_g1 );
				float _TwistAmount_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_TwistAmount);
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
				float _Amplitude_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_Amplitude);
				float _WaveLength_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_WaveLength);
				float temp_output_9_0_g3 = ( ( break22_g3.y / _Amplitude_Instance ) - (sin( ( ( break22_g3.x / _WaveLength_Instance ) * TWO_PI ) )*0.5 + 0.5) );
				float temp_output_5_0_g3 = ( abs( ( temp_output_9_0_g3 - round( temp_output_9_0_g3 ) ) ) * 2.0 );
				float smoothstepResult1_g3 = smoothstep( 0.5 , 0.55 , temp_output_5_0_g3);
				float temp_output_67_0 = smoothstepResult1_g3;
				float temp_output_65_0 = ( 1.0 - temp_output_67_0 );
				float3 smoothstepResult93 = smoothstep( float3( 0.5,0.5,0.5 ) , float3( 1,1,1 ) , ( temp_output_67_0 * v.ase_normal ));
				float _ScaleAmount_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_ScaleAmount);
				
				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord3 = screenPos;
				
				o.ase_texcoord4.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord4.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = ( smoothstepResult150 * ( ( ( temp_output_65_0 * v.ase_normal ) + smoothstepResult93 ) * _ScaleAmount_Instance ) );
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
				#ifdef ASE_FOG
				o.fogFactor = ComputeFogFactor( positionCS.z );
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

			half4 frag ( VertexOutput IN  ) : SV_Target
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
				float4 screenPos = IN.ase_texcoord3;
				float4 ase_grabScreenPos = ASE_ComputeGrabScreenPos( screenPos );
				float4 ase_grabScreenPosNorm = ase_grabScreenPos / ase_grabScreenPos.w;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float eyeDepth36 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float _Offset_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_Offset);
				float smoothstepResult52 = smoothstep( 0.0 , 1.0 , ( 1.0 - ( eyeDepth36 - ( screenPos.w + _Offset_Instance ) ) ));
				float2 texCoord11 = IN.ase_texcoord4.xy * float2( 1,1 ) + float2( 0,0 );
				float _OutlineDetailScale_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_OutlineDetailScale);
				float simpleNoise10 = SimpleNoise( texCoord11*_OutlineDetailScale_Instance );
				float4 _OutlineColor_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_OutlineColor);
				float4 temp_output_57_0 = ( simpleNoise10 * _OutlineColor_Instance );
				float4 Outline14 = ( smoothstepResult52 * temp_output_57_0 );
				float4 _MainColor_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_MainColor);
				float _ScaleSize_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_ScaleSize);
				float _ZoomAmount_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_ZoomAmount);
				float _RotationSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_RotationSpeed);
				float time16 = ( _TimeParameters.x * _RotationSpeed_Instance );
				float2 voronoiSmoothId16 = 0;
				float2 coords16 = IN.ase_texcoord4.xy * ( _ScaleSize_Instance + ( _TimeParameters.z * _ZoomAmount_Instance ) );
				float2 id16 = 0;
				float2 uv16 = 0;
				float fade16 = 0.5;
				float voroi16 = 0;
				float rest16 = 0;
				for( int it16 = 0; it16 <8; it16++ ){
				voroi16 += fade16 * voronoi16( coords16, time16, id16, uv16, 0,voronoiSmoothId16 );
				rest16 += fade16;
				coords16 *= 2;
				fade16 *= 0.5;
				}//Voronoi16
				voroi16 /= rest16;
				float4 _SecondColor_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_SecondColor);
				float4 temp_output_31_0 = ( ( _MainColor_Instance * ( 1.0 - voroi16 ) ) + ( voroi16 * _SecondColor_Instance ) );
				float2 texCoord47_g1 = IN.ase_texcoord4.xy * float2( 1,1 ) + float2( 0,0 );
				float2 _Center_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_Center);
				float2 center45_g1 = _Center_Instance;
				float2 delta6_g1 = ( texCoord47_g1 - center45_g1 );
				float _TwistAmount_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_TwistAmount);
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
				float2 break22_g3 = ( IN.ase_texcoord4.xy * ( temp_output_31_0 * float4( rotator72, 0.0 , 0.0 ) * smoothstepResult82 ).rg );
				float _Amplitude_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_Amplitude);
				float _WaveLength_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_WaveLength);
				float temp_output_9_0_g3 = ( ( break22_g3.y / _Amplitude_Instance ) - (sin( ( ( break22_g3.x / _WaveLength_Instance ) * TWO_PI ) )*0.5 + 0.5) );
				float temp_output_5_0_g3 = ( abs( ( temp_output_9_0_g3 - round( temp_output_9_0_g3 ) ) ) * 2.0 );
				float smoothstepResult1_g3 = smoothstep( 0.5 , 0.55 , temp_output_5_0_g3);
				float temp_output_67_0 = smoothstepResult1_g3;
				float temp_output_65_0 = ( 1.0 - temp_output_67_0 );
				float3 unityObjectToViewPos124 = TransformWorldToView( TransformObjectToWorld( float3( 0,0,0 )) );
				float smoothstepResult150 = smoothstep( 0.0 , 1.0 , ( ( abs( unityObjectToViewPos124.z ) - _NearDistance ) / _FadeDistance ));
				float eyeDepth145 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy ),_ZBufferParams);
				float smoothstepResult148 = smoothstep( 0.0 , 1.0 , ( 1.0 - ( eyeDepth145 - ( screenPos.w - _OutlineOffset ) ) ));
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = ( tex2D( _MainTex, ase_grabScreenPosNorm.xy ) + min( ( ( Outline14 + ( temp_output_31_0 + ( temp_output_31_0 * temp_output_65_0 ) ) ) * ( smoothstepResult150 * _PortalStrength ) ) , _MaxBrightness ) + ( smoothstepResult148 * _Outline ) ).rgb;
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef _ALPHATEST_ON
					clip( Alpha - AlphaClipThreshold );
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				#ifdef ASE_FOG
					Color = MixFog( Color, IN.fogFactor );
				#endif

				return half4( Color, Alpha );
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
			
			#define ASE_SRP_VERSION 90000

			
			#pragma vertex vert
			#pragma fragment frag

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
			float4 _MaxBrightness;
			float4 _Outline;
			float _NearDistance;
			float _FadeDistance;
			float _PortalStrength;
			float _OutlineOffset;
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			UNITY_INSTANCING_BUFFER_START(PortalShaderEdgesEdition)
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
			UNITY_INSTANCING_BUFFER_END(PortalShaderEdgesEdition)


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

				float3 unityObjectToViewPos124 = TransformWorldToView( TransformObjectToWorld( float3( 0,0,0 )) );
				float smoothstepResult150 = smoothstep( 0.0 , 1.0 , ( ( abs( unityObjectToViewPos124.z ) - _NearDistance ) / _FadeDistance ));
				float4 _MainColor_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_MainColor);
				float _ScaleSize_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_ScaleSize);
				float _ZoomAmount_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_ZoomAmount);
				float _RotationSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_RotationSpeed);
				float time16 = ( _TimeParameters.x * _RotationSpeed_Instance );
				float2 voronoiSmoothId16 = 0;
				float2 coords16 = v.ase_texcoord.xy * ( _ScaleSize_Instance + ( _TimeParameters.z * _ZoomAmount_Instance ) );
				float2 id16 = 0;
				float2 uv16 = 0;
				float fade16 = 0.5;
				float voroi16 = 0;
				float rest16 = 0;
				for( int it16 = 0; it16 <8; it16++ ){
				voroi16 += fade16 * voronoi16( coords16, time16, id16, uv16, 0,voronoiSmoothId16 );
				rest16 += fade16;
				coords16 *= 2;
				fade16 *= 0.5;
				}//Voronoi16
				voroi16 /= rest16;
				float4 _SecondColor_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_SecondColor);
				float4 temp_output_31_0 = ( ( _MainColor_Instance * ( 1.0 - voroi16 ) ) + ( voroi16 * _SecondColor_Instance ) );
				float2 texCoord47_g1 = v.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 _Center_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_Center);
				float2 center45_g1 = _Center_Instance;
				float2 delta6_g1 = ( texCoord47_g1 - center45_g1 );
				float _TwistAmount_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_TwistAmount);
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
				float _Amplitude_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_Amplitude);
				float _WaveLength_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_WaveLength);
				float temp_output_9_0_g3 = ( ( break22_g3.y / _Amplitude_Instance ) - (sin( ( ( break22_g3.x / _WaveLength_Instance ) * TWO_PI ) )*0.5 + 0.5) );
				float temp_output_5_0_g3 = ( abs( ( temp_output_9_0_g3 - round( temp_output_9_0_g3 ) ) ) * 2.0 );
				float smoothstepResult1_g3 = smoothstep( 0.5 , 0.55 , temp_output_5_0_g3);
				float temp_output_67_0 = smoothstepResult1_g3;
				float temp_output_65_0 = ( 1.0 - temp_output_67_0 );
				float3 smoothstepResult93 = smoothstep( float3( 0.5,0.5,0.5 ) , float3( 1,1,1 ) , ( temp_output_67_0 * v.ase_normal ));
				float _ScaleAmount_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_ScaleAmount);
				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = ( smoothstepResult150 * ( ( ( temp_output_65_0 * v.ase_normal ) + smoothstepResult93 ) * _ScaleAmount_Instance ) );
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

				float3 normalWS = TransformObjectToWorldDir( v.ase_normal );

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

				
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;

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
			
			#define ASE_SRP_VERSION 90000

			
			#pragma vertex vert
			#pragma fragment frag

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
			float4 _MaxBrightness;
			float4 _Outline;
			float _NearDistance;
			float _FadeDistance;
			float _PortalStrength;
			float _OutlineOffset;
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			UNITY_INSTANCING_BUFFER_START(PortalShaderEdgesEdition)
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
			UNITY_INSTANCING_BUFFER_END(PortalShaderEdgesEdition)


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

				float3 unityObjectToViewPos124 = TransformWorldToView( TransformObjectToWorld( float3( 0,0,0 )) );
				float smoothstepResult150 = smoothstep( 0.0 , 1.0 , ( ( abs( unityObjectToViewPos124.z ) - _NearDistance ) / _FadeDistance ));
				float4 _MainColor_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_MainColor);
				float _ScaleSize_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_ScaleSize);
				float _ZoomAmount_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_ZoomAmount);
				float _RotationSpeed_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_RotationSpeed);
				float time16 = ( _TimeParameters.x * _RotationSpeed_Instance );
				float2 voronoiSmoothId16 = 0;
				float2 coords16 = v.ase_texcoord.xy * ( _ScaleSize_Instance + ( _TimeParameters.z * _ZoomAmount_Instance ) );
				float2 id16 = 0;
				float2 uv16 = 0;
				float fade16 = 0.5;
				float voroi16 = 0;
				float rest16 = 0;
				for( int it16 = 0; it16 <8; it16++ ){
				voroi16 += fade16 * voronoi16( coords16, time16, id16, uv16, 0,voronoiSmoothId16 );
				rest16 += fade16;
				coords16 *= 2;
				fade16 *= 0.5;
				}//Voronoi16
				voroi16 /= rest16;
				float4 _SecondColor_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_SecondColor);
				float4 temp_output_31_0 = ( ( _MainColor_Instance * ( 1.0 - voroi16 ) ) + ( voroi16 * _SecondColor_Instance ) );
				float2 texCoord47_g1 = v.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 _Center_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_Center);
				float2 center45_g1 = _Center_Instance;
				float2 delta6_g1 = ( texCoord47_g1 - center45_g1 );
				float _TwistAmount_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_TwistAmount);
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
				float _Amplitude_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_Amplitude);
				float _WaveLength_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_WaveLength);
				float temp_output_9_0_g3 = ( ( break22_g3.y / _Amplitude_Instance ) - (sin( ( ( break22_g3.x / _WaveLength_Instance ) * TWO_PI ) )*0.5 + 0.5) );
				float temp_output_5_0_g3 = ( abs( ( temp_output_9_0_g3 - round( temp_output_9_0_g3 ) ) ) * 2.0 );
				float smoothstepResult1_g3 = smoothstep( 0.5 , 0.55 , temp_output_5_0_g3);
				float temp_output_67_0 = smoothstepResult1_g3;
				float temp_output_65_0 = ( 1.0 - temp_output_67_0 );
				float3 smoothstepResult93 = smoothstep( float3( 0.5,0.5,0.5 ) , float3( 1,1,1 ) , ( temp_output_67_0 * v.ase_normal ));
				float _ScaleAmount_Instance = UNITY_ACCESS_INSTANCED_PROP(PortalShaderEdgesEdition,_ScaleAmount);
				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = ( smoothstepResult150 * ( ( ( temp_output_65_0 * v.ase_normal ) + smoothstepResult93 ) * _ScaleAmount_Instance ) );
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

				o.clipPos = TransformWorldToHClip( positionWS );
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

				
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif
				return 0;
			}
			ENDHLSL
		}

	
	}
	CustomEditor "UnityEditor.ShaderGraph.PBRMasterGUI"
	Fallback "Hidden/InternalErrorShader"
	
}
/*ASEBEGIN
Version=18921
884;238;851;540;-940.1003;496.0075;1.417244;True;False
Node;AmplifyShaderEditor.CosTime;21;-2495.719,174.6281;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;23;-2513.719,380.6281;Inherit;False;InstancedProperty;_ZoomAmount;ZoomAmount;4;0;Create;True;0;0;0;False;0;False;1;0.1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;25;-2258.719,81.62805;Inherit;False;InstancedProperty;_ScaleSize;ScaleSize;5;0;Create;True;0;0;0;False;0;False;10;10;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;22;-2279.719,265.6281;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;20;-2465.719,73.62805;Inherit;False;InstancedProperty;_RotationSpeed;RotationSpeed;3;0;Create;True;0;0;0;False;0;False;0.5;2.17;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;18;-2446.719,-130.3719;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;24;-2097.719,127.6281;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;19;-2273.719,-32.37195;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;71;-2597.485,830.7455;Inherit;False;InstancedProperty;_Center;Center;12;0;Create;True;0;0;0;False;0;False;0,0;0,-0.04;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.RangedFloatNode;63;-2558.048,995.394;Inherit;False;InstancedProperty;_TwistAmount;TwistAmount;9;0;Create;True;0;0;0;False;0;False;73.3;30;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.VoronoiNode;16;-1945.778,-30.45538;Inherit;True;0;0;1;0;8;False;4;False;False;False;4;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;10;False;3;FLOAT;0;False;3;FLOAT;0;FLOAT2;1;FLOAT2;2
Node;AmplifyShaderEditor.ColorNode;27;-1664,-320;Inherit;False;InstancedProperty;_MainColor;MainColor;6;0;Create;True;0;0;0;False;0;False;0.3537736,0.7963476,1,0;0.08330358,0.3050194,0.45283,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FunctionNode;60;-2340.115,780.3591;Inherit;True;Twirl;-1;;1;90936742ac32db8449cd21ab6dd337c8;0;4;1;FLOAT2;0,0;False;2;FLOAT2;0,0;False;3;FLOAT;0;False;4;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.OneMinusNode;26;-1664,-128;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;30;-1796.51,326.8281;Inherit;False;InstancedProperty;_SecondColor;SecondColor;7;0;Create;True;0;0;0;False;0;False;0,0.6476085,1,0;0,0.6829066,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleTimeNode;74;-1851.838,1046.457;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCGrayscale;80;-2059.085,587.5629;Inherit;True;0;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;29;-1582.01,213.7282;Inherit;True;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;28;-1398.719,-199.3719;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SmoothstepOpNode;82;-1803.085,585.5629;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0.11;False;1;FLOAT;0
Node;AmplifyShaderEditor.RotatorNode;72;-1479.335,676.2749;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT2;0.5,0.5;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;31;-1143.946,137.1375;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;69;-997.5366,985.7608;Inherit;False;InstancedProperty;_WaveLength;WaveLength;10;0;Create;True;0;0;0;False;0;False;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;70;-947.4564,1138.386;Inherit;False;InstancedProperty;_Amplitude;Amplitude;11;0;Create;True;0;0;0;False;0;False;0;0.1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;62;-916.8438,568.5495;Inherit;True;3;3;0;COLOR;0,0,0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.FunctionNode;67;-664.4663,936.0791;Inherit;True;Smooth Wave;-1;;3;45d5b33902fbc0848a1166b32106db74;1,3,1;3;17;FLOAT2;1,1;False;16;FLOAT;21.06;False;18;FLOAT;0.06;False;1;FLOAT;0
Node;AmplifyShaderEditor.UnityObjToViewPosHlpNode;124;274.7002,-1102.901;Inherit;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.NormalVertexDataNode;85;-149.9293,982.199;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;119;354.7001,-990.9012;Inherit;False;Property;_NearDistance;Near Distance;16;0;Create;True;0;0;0;False;0;False;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.AbsOpNode;125;498.7001,-1150.902;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;91;61.31166,1267.332;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.OneMinusNode;65;-356.872,860.0883;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;126;674.6992,-1166.902;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;127;690.6992,-1054.901;Inherit;False;Property;_FadeDistance;Fade Distance;17;0;Create;True;0;0;0;False;0;False;0;3.06;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;93;340.9167,1256.735;Inherit;True;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0.5,0.5,0.5;False;2;FLOAT3;1,1,1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;86;112.7952,832.1705;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;88;654.7822,1046.414;Inherit;False;InstancedProperty;_ScaleAmount;ScaleAmount;13;0;Create;True;0;0;0;False;0;False;0.41;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;129;882.6992,-1294.902;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;94;571.8229,777.8557;Inherit;True;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;15;-2925.246,-998.4926;Inherit;False;1832.945;623.0085;;11;12;7;6;9;8;11;13;10;57;58;59;Outline;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;89;934.8103,720.9302;Inherit;True;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SmoothstepOpNode;150;1074.7,-1278.902;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;13;-2843.969,-545.1923;Inherit;False;InstancedProperty;_OutlineDetailScale;OutlineDetailScale;1;0;Create;True;0;0;0;False;0;False;101.95;27.48;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;140;1401.24,213.3866;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ColorNode;134;890.5131,78.64421;Inherit;False;Property;_MaxBrightness;Max Brightness;18;1;[HDR];Create;True;0;0;0;False;0;False;1,1,1,0;1,1,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScreenPosInputsNode;42;-2864.364,-1346.413;Float;True;1;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;7;-2875.246,-884.4932;Inherit;False;InstancedProperty;_FresnelScale;FresnelScale;0;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;34;597.5103,-106.6295;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;50;-2847.753,-1124.413;Inherit;False;InstancedProperty;_Offset;Offset;8;0;Create;True;0;0;0;False;0;False;4;2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;144;315.0205,-632.2839;Inherit;False;Property;_OutlineOffset;Outline Offset;20;0;Create;True;0;0;0;False;0;False;0;0.54;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;104;332.2757,-321.9945;Inherit;True;Property;_MainTex;Main Texture;15;0;Create;False;0;0;0;False;0;False;None;f4a4a0dcb38e58a45900ae36c5b68421;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.TextureCoordinatesNode;11;-2820.618,-726.1052;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleSubtractOpNode;12;-2142.642,-879.418;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;156;1109.93,-599.8671;Inherit;False;2;2;0;FLOAT;1;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.OneMinusNode;46;-2009.258,-1487.725;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenDepthNode;145;448.959,-792.5664;Inherit;False;0;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;118;1356.159,-638.6268;Inherit;False;2;2;0;FLOAT;1;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FresnelNode;6;-2587.246,-948.4926;Inherit;True;Standard;WorldNormal;ViewDir;False;False;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;41;-2392.364,-1550.413;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenPosInputsNode;142;122.1226,-780.5554;Float;False;1;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;68;124.8356,266.0379;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;14;-280.4328,-908.5092;Inherit;False;Outline;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;146;670.9569,-714.567;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenDepthNode;36;-3171.783,-1543.217;Inherit;False;0;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;52;-1781.897,-1474.821;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;148;946.0186,-720.4745;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;59;-1796.213,-877.7878;Inherit;True;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.FresnelNode;96;1815.838,-782.293;Inherit;False;Standard;WorldNormal;ViewDir;False;False;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;105;1367.368,-48.90512;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.OneMinusNode;147;811.8982,-784.8571;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;32;10.42657,-87.51681;Inherit;False;14;Outline;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;95;2038.572,-741.4518;Inherit;False;Property;_FresnelPower;FresnelPower;14;0;Create;True;0;0;0;False;0;False;1;0.16;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMinOpNode;133;1173.41,87.07697;Inherit;False;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;64;-173.7018,552.2273;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;143;487.9647,-700.7709;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;8;-2318.157,-409.9318;Inherit;False;InstancedProperty;_OutlineColor;OutlineColor;2;0;Create;True;0;0;0;False;0;False;0.08962262,0.5587614,1,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;103;1000.122,-319.1513;Inherit;True;Property;_TextureSample0;Texture Sample 0;16;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GrabScreenPosition;101;776.6746,-405.1227;Inherit;False;0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.OneMinusNode;58;-2153.864,-645.6548;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;9;-1510.981,-834.1772;Inherit;True;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;10;-2543.618,-648.1049;Inherit;True;Simple;True;False;2;0;FLOAT2;1,1;False;1;FLOAT;58.61;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;57;-2033.575,-531.6982;Inherit;True;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;51;-2510.21,-1262.477;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;155;881.241,-580.4352;Inherit;False;Property;_Outline;Outline;21;0;Create;True;0;0;0;False;0;False;0,0,0,0;0,0.3975719,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;100;1099.32,-78.6468;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;141;1021.2,-894.1951;Inherit;False;Property;_PortalStrength;Portal Strength;19;0;Create;True;0;0;0;False;0;False;1;0.66;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;139;1545.143,-45.15471;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;138;1545.143,-45.15471;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;True;False;False;False;False;0;False;-1;False;False;False;False;False;False;False;False;False;True;1;False;-1;False;False;True;1;LightMode=DepthOnly;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;135;1545.143,-45.15471;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;0;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;137;1545.143,-45.15471;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=ShadowCaster;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;136;1615.484,-30.32825;Float;False;True;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;PortalShaderEdgesEdition;2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;8;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;5;False;-1;10;False;-1;1;1;False;-1;10;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;True;True;True;255;False;-1;255;False;-1;255;False;-1;7;False;-1;3;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;True;1;False;-1;True;3;False;-1;True;False;1;True;-1;0;False;-1;True;1;LightMode=UniversalForward;False;False;0;Hidden/InternalErrorShader;0;0;Standard;22;Surface;1;  Blend;0;Two Sided;1;Cast Shadows;1;  Use Shadow Threshold;0;Receive Shadows;1;GPU Instancing;1;LOD CrossFade;0;Built-in Fog;0;DOTS Instancing;0;Meta Pass;0;Extra Pre Pass;0;Tessellation;0;  Phong;0;  Strength;0.5,False,-1;  Type;0;  Tess;16,False,-1;  Min;10,False,-1;  Max;25,False,-1;  Edge Length;16,False,-1;  Max Displacement;25,False,-1;Vertex Position,InvertActionOnDeselection;1;0;5;False;True;True;True;False;False;;False;0
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
WireConnection;80;0;60;0
WireConnection;29;0;16;0
WireConnection;29;1;30;0
WireConnection;28;0;27;0
WireConnection;28;1;26;0
WireConnection;82;0;80;0
WireConnection;72;0;60;0
WireConnection;72;2;74;0
WireConnection;31;0;28;0
WireConnection;31;1;29;0
WireConnection;62;0;31;0
WireConnection;62;1;72;0
WireConnection;62;2;82;0
WireConnection;67;17;62;0
WireConnection;67;16;69;0
WireConnection;67;18;70;0
WireConnection;125;0;124;3
WireConnection;91;0;67;0
WireConnection;91;1;85;0
WireConnection;65;0;67;0
WireConnection;126;0;125;0
WireConnection;126;1;119;0
WireConnection;93;0;91;0
WireConnection;86;0;65;0
WireConnection;86;1;85;0
WireConnection;129;0;126;0
WireConnection;129;1;127;0
WireConnection;94;0;86;0
WireConnection;94;1;93;0
WireConnection;89;0;94;0
WireConnection;89;1;88;0
WireConnection;150;0;129;0
WireConnection;140;0;150;0
WireConnection;140;1;89;0
WireConnection;34;0;32;0
WireConnection;34;1;68;0
WireConnection;12;0;6;0
WireConnection;12;1;10;0
WireConnection;156;0;148;0
WireConnection;156;1;155;0
WireConnection;46;0;41;0
WireConnection;118;0;150;0
WireConnection;118;1;141;0
WireConnection;6;2;7;0
WireConnection;41;0;36;0
WireConnection;41;1;51;0
WireConnection;68;0;31;0
WireConnection;68;1;64;0
WireConnection;14;0;9;0
WireConnection;146;0;145;0
WireConnection;146;1;143;0
WireConnection;52;0;46;0
WireConnection;148;0;147;0
WireConnection;59;0;58;0
WireConnection;59;1;57;0
WireConnection;96;3;95;0
WireConnection;105;0;103;0
WireConnection;105;1;133;0
WireConnection;105;2;156;0
WireConnection;147;0;146;0
WireConnection;133;0;100;0
WireConnection;133;1;134;0
WireConnection;64;0;31;0
WireConnection;64;1;65;0
WireConnection;143;0;142;4
WireConnection;143;1;144;0
WireConnection;103;0;104;0
WireConnection;103;1;101;0
WireConnection;58;0;10;0
WireConnection;9;0;52;0
WireConnection;9;1;57;0
WireConnection;10;0;11;0
WireConnection;10;1;13;0
WireConnection;57;0;10;0
WireConnection;57;1;8;0
WireConnection;51;0;42;4
WireConnection;51;1;50;0
WireConnection;100;0;34;0
WireConnection;100;1;118;0
WireConnection;136;2;105;0
WireConnection;136;5;140;0
ASEEND*/
//CHKSM=B576F40E9701583E5D718653E906429CF41BE47B