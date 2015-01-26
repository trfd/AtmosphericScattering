Shader "AtmosphericScattering/Interpolation Texture" 
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
		
			#include "UnityCG.cginc"
			
			#include "ASCommon.cginc"

			sampler2D _CoordsTex;
			sampler2D _DepthEpipolarTex;
			sampler2D_float _CameraDepthTexture;
			
			float _DepthThreshold;
			
			// Number of Epipolar samples between to raymarch
			int _RaymarchStep;
			
			// Position of Light in viewport
			float4 _LightPos;
			
			// Size Coordinate Texture
			// (width , height, Number of Horizontal samples, Number of Vertial Samples)
			float4 _CoordTexSize;
			float4 _ScreenSize;
			
			// Debug
			
			RWTexture2D<float4> _DebugTex;
			float4 _DebugTexSize;
			
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
		
			inline float SampleDepth(int x, int y)
			{
				return tex2Dlod(_DepthEpipolarTex,float4(x/_CoordTexSize.x,y/_CoordTexSize.y,0,0)).x;
			}
		
			/// Coordinate texture is setup as follow:
			/// 
			/// Left edge epipolar lines from y=0 to y=_CoordTexSize.w-1
			/// Right edge epipolar lines from y=_CoordTexSize.w to y=2*_CoordTexSize.w-1
			/// Top edge epipolar lines from y=2*_CoordTexSize.w to y=2*_CoordTexSize.w+_CoordTexSize.z-1
			/// Bottom edge epipolar lines from y=2*_CoordTexSize.w+_CoordTexSize.z-1 to y=2*(_CoordTexSize.w+_CoordTexSize.z)
			
			float4 frag (v2f IN) : COLOR
			{   
				int x = floor(IN.uv.x * _CoordTexSize.x);
				int y = IN.uv.y * _CoordTexSize.y;
				 
				if(x%_RaymarchStep == 0)
				{
					_DebugTex[tex2D(_CoordsTex,IN.uv)*_DebugTexSize.xy] = float4(1,0,1,1);
					return float4(0,0,0,0);
				}
				
				float invSize = 1.0 / _CoordTexSize.x;
				
				int prevStep = x - (x%_RaymarchStep);
				int nextStep =prevStep + _RaymarchStep;
				
				int left, right;
				
				
				left = right = x;
				
				while(left > prevStep)
				{
					if(abs(SampleDepth(left,y) - SampleDepth(left-1,y)) > _DepthThreshold)
						break;
					left--;
				}
				
				while(right < nextStep)
				{
					if(abs(SampleDepth(right,y) - SampleDepth(right+1,y)) > _DepthThreshold)
						break;
					right++;
				}
				
				// Normalized
				float nl = x-left;
				float nr = right-x;

				if(nl*nr == 0)
					return float4(0,0,0,0);
				
				_DebugTex[tex2D(_CoordsTex,float2(left*invSize,IN.uv.y))*_DebugTexSize.xy] = SampleDepth(x,y).xxxx;
								
				return float4(nl*invSize,nr*invSize,0,0);
			}
			
			ENDCG
		}
	} 
}
