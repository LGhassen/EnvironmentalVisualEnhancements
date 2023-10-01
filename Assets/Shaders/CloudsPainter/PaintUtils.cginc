#define PIE 3.1415926535897932384626
#define TWOPIE (2.0*PIE) 

float3 brushPosition;
float4x4 cloudRotationMatrix;
int cubemapFace;

float3 GetDirectionFromEquiRectangularUV(float2 uv)
{
	float 	phi = (uv.x - 0.5) * TWOPIE;
	float 	theta = (uv.y) * PIE;

	float 	sintheta = sin(theta);

	return float3(sin(phi)*sintheta, cos(theta), cos(phi)*sintheta);
}

float3 GetDirectionFromCubemapFaceUV(float2 uv, int face)
{
	// How cubemaps work: The largest abs(component) determines the faces (x, y, z)
	// Then check if the sign of the component is positive or negative to determine if it's face or -face
	// The uv is then just the remaining two directions divided by the largest component (including sign)
	// Then scale and bias the uv from -1 1 to 0 1
	// See readable algorithm here https://www.gamedev.net/forums/topic/692761-manual-cubemap-lookupfiltering-in-hlsl/5359801/

	// To reverse it start by reverting the scale and bias
	uv = uv * 2.0 - 1.0.xx;

	// Then rebuild directions from their components before normalizing
	float3 direction;
	switch (face)
	{
		case 0: direction = float3( 1, -uv.y, -uv.x); break; // +X face
		case 1: direction = float3(-1, -uv.y,  uv.x); break; // -X face

		case 2: direction = float3(uv.x,  1,  uv.y); break; // +Y face
		case 3: direction = float3(uv.x, -1, -uv.y); break; // -Y face

		case 4: direction = float3( uv.x, -uv.y,  1); break; // +Z face
		case 5: direction = float3(-uv.x, -uv.y, -1); break; // -Z face

		default: direction = float3(0, 0, 0); break; // Invalid face index
	}
	
	return normalize(direction);
}

float3 GetBrushAndWorldPositions(float2 uv, out float3 worldPos)
{
	// now you have the uv, use it to calculate a worldspace raydirection
#if defined(PAINT_CUBEMAP_ON)
	float3 rayDir = GetDirectionFromCubemapFaceUV(uv, cubemapFace);
#else
	float3 rayDir = GetDirectionFromEquiRectangularUV(uv); // note the y and x here may be inverted
#endif

	// compute the current world position
	worldPos =  rayDir * innerSphereRadius;

	float4 brushDirection = mul(cloudRotationMatrix, float4(brushPosition,1.0)); // transform the world pos to a planet space direction
	brushDirection.xyz /= brushDirection.w;
	brushDirection.xyz = normalize(brushDirection.xyz);

	float3 planetBrushPosition = brushDirection.xyz*innerSphereRadius; // convert back to point on the surface of planet

	return planetBrushPosition;
}