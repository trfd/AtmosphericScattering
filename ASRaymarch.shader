Shader "AtmosphericScattering/Interpolation Texture" 
{
	SubShader 
	{
		Tags { "RenderType"="Opaque" }
   		ZTest Always Cull Off ZWrite Off Fog { Mode Off }
   	
   		CGINCLUDE

   		struct v2f 
		{
		    float4 pos : SV_POSITION;
		    float2 uv : TEXCOORD0;
		};

   		ENDCG

		Pass
		{
			Blend Off

			Stencil
			{
				Ref 0
				Comp equal
				Pass keep
			}
	
			CGPROGRAM
			
			#pragma target 5.0
			#pragma vertex vert
			#pragma fragment frag
		
			#include "UnityCG.cginc"
			#include "ASCommon.cginc"

			v2f vert( appdata_img v )
			{
			    v2f o;
			    o.pos = v.vertex;
			    o.uv =  v.texcoord;
			    return o;
			}  
		
			/// Coordinate texture is setup as follow:
			/// 
			/// Left edge epipolar lines from y=0 to y=_CoordTexSize.w-1
			/// Right edge epipolar lines from y=_CoordTexSize.w to y=2*_CoordTexSize.w-1
			/// Top edge epipolar lines from y=2*_CoordTexSize.w to y=2*_CoordTexSize.w+_CoordTexSize.z-1
			/// Bottom edge epipolar lines from y=2*_CoordTexSize.w+_CoordTexSize.z-1 to y=2*(_CoordTexSize.w+_CoordTexSize.z)
			
			float4 frag (v2f IN) : COLOR
			{   
				return float4(1,1,0,1);
			}
			
			ENDCG
		}

	
		Pass
		{
			Blend Off

			CGPROGRAM
			
			#pragma target 5.0
			#pragma vertex vert
			#pragma fragment frag
		
			#include "UnityCG.cginc"
			#include "ASCommon.cginc"

			v2f vert( appdata_img v )
			{
			    v2f o;
			    o.pos = v.vertex;
			    o.uv =  v.texcoord;
			    return o;
			}  
	
			float4 frag (v2f IN) : COLOR
			{   
				return 0;
			}
			
			ENDCG
		}
	} 
}
