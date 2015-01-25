
inline float2 GetEpipolarLineEndPoint(float2 startPoint, float2 lightPos)
{
#if defined(AS_LIGHT_ON_SCREEN)
	
	return lightPos;
	
#else
	
	float2 dir = lightPos - startPoint;
	
	bool4 border = bool4(0,0,1,1);
	
	float4 compactBorder = startPoint.xyxy + dir.xyxy * (border - startPoint.yxyx) / dir.yxyx;

	float2 bottom = float2(compactBorder.x ,border.x);
	float2 top = float2(compactBorder.z ,border.z);

	float2 left = float2(border.y, compactBorder.y);
	float2 right = float2(border.w, compactBorder.w);

	float4 mags = float4(length(bottom - startPoint) * (dot(bottom - startPoint,dir)>0),
						 length(top    - startPoint) * (dot(top    - startPoint,dir)>0),
						 length(left   - startPoint) * (dot(left   - startPoint,dir)>0),
						 length(right  - startPoint) * (dot(right  - startPoint,dir)>0));
	
	mags = (mags < 1e-3) * 10000 + mags;
	
	float mag = 10000;
	mag = min(mag, mags.x);
	mag = min(mag, mags.y);
	mag = min(mag, mags.z);
	mag = min(mag, mags.w);

	return mag * normalize(dir) + startPoint;
#endif
}  
 