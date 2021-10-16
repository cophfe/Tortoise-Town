Shader "Custom/Portal"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
		Tags 
		{
			"RenderType" = "Opaque"
			"Queue" = "Geometry"
		}
		Cull off

        Pass
        {

			/*Stencil {
			Ref 1
			Pass replace
			}*/

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 position : SV_POSITION;
				float4 screenPosition : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.position = UnityObjectToClipPos(v.vertex);
                //o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.screenPosition = ComputeScreenPos(o.position);
				return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				float2 textureCoordinate = i.screenPosition.xy / i.screenPosition.w;
                fixed4 col = tex2D(_MainTex, textureCoordinate);
                return col;
            }
            ENDCG
        }
    }
}
