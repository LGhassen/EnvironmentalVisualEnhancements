float2 FindNearestDepthUV(float2 uv, float fullResolutionRawDepth, sampler2D lowResolutionDepthTexture, float4 lowResolutionTexelSize)
{
	float fullResolutionLinearDepth = Linear01Depth(fullResolutionRawDepth);

	float smallestDepthDifference = 1.0;
	float2 nearestDepthUv = uv;
	bool bilinearInterpolation = true;

	[unroll(2)]
	for (float u = -0.5; u <= 0.5; u += 1.0)
	{
		[unroll(2)]
		for (float v = -0.5; v <= 0.5; v += 1.0)
		{
			// Move the uv to be within one of the neighbouring low-res texture pixels
			float2 currentUV = uv + float2(u, v) * lowResolutionTexelSize.xy;

			// Move it to be exactly at the low-res texture pixel's coordinates, so that it's point-filtered even with a bilinear sampler
			currentUV = (floor(currentUV * lowResolutionTexelSize.zw) + 0.5.xx) * lowResolutionTexelSize.xy;

			float currentDepth = Linear01Depth(tex2Dlod(lowResolutionDepthTexture, float4(currentUV, 0.0,0.0)));

			float depthDifference = abs(currentDepth - fullResolutionLinearDepth);
			if (depthDifference < smallestDepthDifference)
			{
				smallestDepthDifference = depthDifference;
				nearestDepthUv = currentUV;
			}

			if (depthDifference > 0.1 * fullResolutionLinearDepth ||
				depthDifference > 0.1 * currentDepth)
			{
				bilinearInterpolation = false;
			}
		}
	}

	return bilinearInterpolation ? uv : nearestDepthUv;
}