Shader "AtmosphericScattering/EpipolarCoordinate" 
{
	SubShader 
	{
		Tags { "RenderType"="Opaque" }
   		ZTest Always Cull Off ZWrite Off Fog { Mode Off }
   		
		Pass
		{
			CGPROGRAM
			
			#pragma target 5.0
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile AS_LIGHT_ON_SCREEN AS_LIGHT_OFF_SCREEN
			
			#include "UnityCG.cginc"
			
			#include "ASCommon.cginc"

			sampler2D_float _CameraDepthTexture;
			
			// Position of Light in viewport
			uniform float4 _LightPos;
			
			// Size Coordinate Texture
			// (width , height, Number of Horizontal samples, Number of Vertial Samples)
			uniform float4 _CoordTexSize;
			uniform float4 _ScreenSize;
			
			struct v2f 
			{
			    float4 pos : SV_POSITION;
			    float2 uv : TEXCOORD0;
			};
			
			// End Debug


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
			 
			void frag (v2f IN, out float4 coord : COLOR0 , out float4 depth : COLOR1)
			{   
			
				// Index of row in the Coordinate texture
				float row = IN.uv.y * _CoordTexSize.y;
				
				// Index of row starting for top and bottom edges
				float rowY = row - 2 * _CoordTexSize.w;
				
				float isHorizontalRow = step(2*_CoordTexSize.w,row);
				
				// for left and right edges
				float2 edgeX = (1-isHorizontalRow) * float2(fmod(row,_CoordTexSize.w)/_CoordTexSize.w , floor(row /  _CoordTexSize.w));
				
				// for top and bottom edges
				float2 edgeY = isHorizontalRow * float2(floor( rowY /  _CoordTexSize.z),fmod(rowY , _CoordTexSize.z)/_CoordTexSize.z);
				
				float2 startPoint = edgeX + edgeY;
				
				float2 endPoint = GetEpipolarLineEndPoint(startPoint,_LightPos.xy);
			
				coord = float4(lerp(startPoint,endPoint,IN.uv.x),0,0);
				
				depth = Linear01Depth(tex2D(_CameraDepthTexture, coord.xy).x).xxxx;
			}
			
			ENDCG
		}
	} 
}
