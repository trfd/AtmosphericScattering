Shader "AtmosphericScattering/DebugCamera" 
{
	Properties
	{
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_DebugTex ("Debug Texture", 2D) = "white" {}
	}
	SubShader {
    Tags { "RenderType"="Opaque" }
	    Pass 
	    {
	        Fog { Mode Off }
			Cull Off
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct v2f 
			{
			    float4 pos : SV_POSITION;
			    float2 uv : TEXCOORD0;
			};

			sampler2D _MainTex;
			sampler2D _DebugTex;
			
			v2f vert( appdata_img v )
			{
			    v2f o;
			    o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
			    o.uv =  v.texcoord.xy;
			    return o;
			}    
			 
			half4 frag (v2f i) : COLOR
			{      			
				float4 debugColor = tex2D(_DebugTex, i.uv);	
			    return (1-debugColor.a) * tex2D(_MainTex,i.uv) + debugColor;
			}
			
			ENDCG
	    }
	}
}