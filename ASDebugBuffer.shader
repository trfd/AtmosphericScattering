Shader "AtmosphericScattering/DebugBuffer"
{
	SubShader 
	{
		Pass 
		{
			CGPROGRAM
			#pragma target 5.0
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			
			struct Point
			{
				float3 position;
				float3 color;
			};
			
			struct PS_INPUT
			{
				float4 position : SV_POSITION;
				float4 color : COLOR;
			};
			
			StructuredBuffer<Point> pointBuffer;
			
			PS_INPUT vert(uint vertex_id : SV_VertexID, uint instance_id : SV_InstanceID)
			{
				PS_INPUT o = (PS_INPUT)0;

				o.position = float4(pointBuffer[instance_id].position,1.0);
				o.color = float4(pointBuffer[instance_id].color,1.0);

				return o;
			}
			
			float4 frag(PS_INPUT i) : COLOR
			{
				return i.color;
			}
			
			ENDCG
		}
	}

	Fallback Off
}