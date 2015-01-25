Shader "AtmosphericScattering/Debug" 
{
	Properties
	{
		_MainTex ("Base (RGB)", 2D) = "white" {}
	}
	SubShader {
    //Tags { "RenderType"="Opaque" }
    
    ZTest Always Cull Off ZWrite Off Fog { Mode Off }

	    Pass 
	    {
	        Fog { Mode Off }
			Cull Off
			
			CGPROGRAM
			
			#pragma target 3.0
			#pragma glsl
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "ASCommon.cginc"

			struct v2f 
			{
			    float4 pos : SV_POSITION;
			    float2 uv : TEXCOORD0;
			};

			uniform float4 _LightPos;
			
			// Size Coordinate Texture
			// (width , height, Number of Horizontal samples, Number of Vertial Samples)
			uniform float4 _CoordTexSize;
			uniform float4 _ScreenSize;

			sampler2D _MainTex;
			sampler2D_float _CameraDepthTexture;
			
			v2f vert( appdata_img v )
			{
			    v2f o;
			    o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
			    o.uv =  v.texcoord.xy;
			    return o;
			}    
			 
			half4 frag (v2f i) : COLOR
			{      
			    half4 color = tex2D(_MainTex, i.uv);
			    
			    return color;
			}
			
			ENDCG
	    }
	}
}