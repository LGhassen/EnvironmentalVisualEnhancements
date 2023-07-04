#define PIE 3.1415926535897932384626
#define TWOPIE (2.0*PIE) 

float3 brushPosition;
float4x4 cloudRotationMatrix;

float3 GetDirectionFromEquiRectangularUV(float2 uv)
{
	float 	phi = (uv.x - 0.5) * TWOPIE;
	float 	theta = (uv.y) * PIE;

	float 	sintheta = sin(theta);

	return float3(sin(phi)*sintheta, cos(theta), cos(phi)*sintheta);
}

float3 GetBrushAndWorldPositions(float2 uv, out float3 worldPos)
{
	// now you have the uv, use it to calculate a worldspace raydirection
	float3 rayDir = GetDirectionFromEquiRectangularUV(uv); // note the y and x here may be inverted

	// compute the current world position
	worldPos =  rayDir * innerSphereRadius;

	float4 brushDirection = mul(cloudRotationMatrix, float4(brushPosition,1.0)); // transform the world pos to a planet space direction
	brushDirection.xyz /= brushDirection.w;
	brushDirection.xyz = normalize(brushDirection.xyz);

	float3 planetBrushPosition = brushDirection.xyz*innerSphereRadius; // convert back to point on the surface of planet

	return planetBrushPosition;
}