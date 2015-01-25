Shader "AtmosphericScattering/Clear Target" 
{
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
			};
			
			v2f vert( appdata_img v )
			{
			    v2f o;
			    o.pos = v.vertex;
			    return o;
			}    
			 
			half4 frag (v2f i) : COLOR
			{      			
				return (half4) 0;
			}
			
			ENDCG
	    }
	}
}