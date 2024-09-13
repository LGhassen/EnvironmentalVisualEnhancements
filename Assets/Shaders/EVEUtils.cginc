#ifndef EVE_UTILS_CG_INCLUDED
#define EVE_UTILS_CG_INCLUDED

	
	#include "UnityCG.cginc"
	#include "AutoLight.cginc"
	#include "Lighting.cginc"
	#define PI 3.1415926535897932384626
	#define INV_PI (1.0/PI)
	#define TWOPI (2.0*PI) 
	#define INV_2PI (1.0/TWOPI)
	#define SQRT_2 (1.41421356237)
	#pragma fragmentoption ARB_precision_hint_fastest

#ifdef DIRLIGHT_ONLY
#define DIRECTIONAL 1
#define SHADOWS_OFF 1
#define LIGHTMAP_OFF 1
#define DIRLIGHTMAP_OFF 1
#endif

#pragma skip_variants DIRLIGHTMAP_COMBINED DIRLIGHTMAP_SEPARATE DYNAMICLIGHTMAP_ON LIGHTMAP_ON VERTEXLIGHT_ON


	uniform float4x4 _MainRotation;
	uniform float4x4 _DetailRotation;
	uniform float4x4 _ShadowBodies = float4x4
	(	0, 0, 0, 0,
		0, 0, 0, 0,
		0, 0, 0, 0,
		0, 0, 0, 0);

	float _SunRadius = 1;
	float3 _SunPos;

	float4 _UniversalTime;

	/*=========================================================================*
	* R A N D _ R O T A T I O N Author: Jim Arvo, 1991 *
	* *
	* This routine maps three values (x[0], x[1], x[2]) in the range [0,1] *
	* into a 3x3 rotation matrix, M. Uniformly distributed random variables *
	* x0, x1, and x2 create uniformly distributed random rotation matrices. *
	* To create small uniformly distributed "perturbations", supply *
	* samples in the following ranges *
	* *
	* x[0] in [ 0, d ] *
	* x[1] in [ 0, 1 ] *
	* x[2] in [ 0, d ] *
	* *
	* where 0 < d < 1 controls the size of the perturbation. Any of the *
	* random variables may be stratified (or "jittered") for a slightly more *
	* even distribution. *
	* *
	*=========================================================================*/
	float4x4 rand_rotation(float3 x, float scale, float3 trans)
	{
		float theta = x[0] * TWOPI; /* Rotation about the pole (Z). */
		float phi = x[1] * TWOPI; /* For direction of pole deflection. */
		float z = x[2] * 2.0; /* For magnitude of pole deflection. */

							  /* Compute a vector V used for distributing points over the sphere */
							  /* via the reflection I - V Transpose(V). This formulation of V */
							  /* will guarantee that if x[1] and x[2] are uniformly distributed, */
							  /* the reflected points will be uniform on the sphere. Note that V */
							  /* has length sqrt(2) to eliminate the 2 in the Householder matrix. */

		float r = sqrt(z);
		float Vx = sin(phi) * r;
		float Vy = cos(phi) * r;
		float Vz = sqrt(2.0 - z);

		/* Compute the row vector S = Transpose(V) * R, where R is a simple */
		/* rotation by theta about the z-axis. No need to compute Sz since */
		/* it's just Vz. */

		float st = sin(theta);
		float ct = cos(theta);
		float Sx = Vx * ct - Vy * st;
		float Sy = Vx * st + Vy * ct;

		/* Construct the rotation matrix ( V Transpose(V) - I ) R, which */
		/* is equivalent to V S - R. */


		float4x4 M = float4x4(
			scale*(Vx * Sx - ct), Vy * Sx + st, Vz * Sx, trans.x,
			Vx * Sy - st, scale*(Vy * Sy - ct), Vz * Sy, trans.y,
			Vx * Vz, Vy * Vz, scale*(1.0 - z), trans.z,
			0, 0, 0, 1);

		return M;
	}

	inline float3 hash( float3 val )
	{
		return frac(sin(val)*1232.53);
	}

	inline float GetDistanceFade( float dist, float fade, float fadeVert )
	{
		float fadeDist = fade*dist;
		float distVert = 1-(fadeVert*dist);
		return saturate(fadeDist) * saturate(distVert);
	}
			
	inline half4 GetLighting(half3 worldNorm, half3 lightDir, fixed atten, fixed ambient)
	{
		half3 ambientLighting = ambient * UNITY_LIGHTMODEL_AMBIENT;
		half NdotL = dot (worldNorm, lightDir);
		half lightIntensity = saturate(_LightColor0.a * NdotL * 2 * atten);
		half4 light;
		light.rgb = max(ambientLighting + (_LightColor0.rgb * lightIntensity), 0);
		light.a = max(ambientLighting + lightIntensity, 0);
		
		return light;
	}
	
	// Calculates Blinn-Phong (specular) lighting model
	inline half4 SpecularColorLight( half3 lightDir, half3 viewDir, half3 normal, half4 color, half4 specColor, float specK, half atten )
	{
	    
	    lightDir = normalize(lightDir);
	    viewDir = normalize(viewDir);
	    normal = normalize(normal);
	    half3 h = normalize( lightDir + viewDir );
	    
	    half diffuse = dot( normal, lightDir );
	    
	    float nh = saturate( dot( h, normal ) );
	    float spec = pow( nh, specK ) * specColor.a;
	    
	    half4 c;
	    c.rgb = _LightColor0.rgb*((color.rgb * diffuse )+ (specColor.rgb * spec)) * (atten * 2);
	    c.a = diffuse*(atten * 2);//_LightColor0.a * specColor.a * spec * atten; // specular passes by default put highlights to overbright
	    return c;
	}

	inline half4 ScatterColorLight(half3 lightDir, half3 viewDir, half3 normal, half4 color, float min, float opacity, half atten)
	{

		lightDir = normalize(lightDir);
		viewDir = normalize(viewDir);
		normal = normalize(normal);


		half diffuse = max( dot(normal, lightDir),0);

		float h = .5+(.5*dot(viewDir, lightDir));
		float scatter = (min-(opacity*color.a))*(1-(dot(normal,viewDir)))*h;
		scatter = saturate(scatter);

		half4 c;
		c.rgb = _LightColor0*((color.rgb * diffuse) + scatter) * (atten * 2);
		c.a = diffuse*(atten * 2);//_LightColor0.a * specColor.a * spec * atten; // specular passes by default put highlights to overbright
		return c;
	}
	
	inline half Terminator(half3 lightDir, half3 normal)
	{
		half NdotL = dot( normal, lightDir );
		half termlerp = saturate(10*-NdotL);
		half terminator = lerp(1,saturate(floor(1.01+NdotL)), termlerp);
		return terminator;
	}

	//V is worldVertex
	//R is radius of the sun	
	//r is radius of body
	//P is sunPos
	//p is pos of body
	//Original EVE eclipse function, looks less natural than EclipseShadow below
	inline half BodyShadow(float3 v, float R, float r, float3 P, float3 p)
	{		
		float3 D = P - v;

		float a = PI*(r*r);
		float3 d = p - v;

		float tc = dot(d, normalize(D));
		float tc2 = (tc*tc);
		float L = sqrt(dot(d, d) - tc2);

		float scale = tc / length(D); //Scaled Sun Area to match plane of intersecting body
		float Rs = R * scale;
		float A = PI*(Rs*Rs);

		float s = saturate((r + Rs - L) / (2 * min(r, Rs)));
		s = (INV_PI*asin((2 * s) - 1)) + .5;
		return lerp(1, saturate((A - (s*a)) / A), step(r, tc)*saturate(a));
	}

	//Same eclipse function from scatterer
	half EclipseShadow(float3 worldPos, float lightSourceRadius, float occluderSphereRadius, float3 worldLightPos,float3 occluderSpherePosition)		
	{											
		float3 lightDirection = float3(worldLightPos - worldPos);
		float3 lightDistance = length(lightDirection);
		lightDirection = lightDirection / lightDistance;

		// computation of level of shadowing w  
		float3 sphereDirection = float3(occluderSpherePosition - worldPos);  //occluder planet
		float sphereDistance = length(sphereDirection);
		sphereDirection = sphereDirection / sphereDistance;

		float dd = lightDistance * (asin(min(1.0, length(cross(lightDirection, sphereDirection)))) 
			- asin(min(1.0, occluderSphereRadius / sphereDistance)));

		float w = smoothstep(-1.0, 1.0, -dd / lightSourceRadius);
		w = w * smoothstep(0.0, 0.2, dot(lightDirection, sphereDirection));

		return (1-w);
	}
	
	inline half MultiBodyShadow(float3 worldPos, float sunRadius, float3 sunPos, float4x4 m)
	{
		half shadowTerm = 1.0;
		
		for (int i=0; i<4;i++)
		{
			if (m[i].w == 0.0) break;

			shadowTerm*= EclipseShadow(worldPos, sunRadius, m[i].w, sunPos, m[i].xyz);
		}

		return shadowTerm;
	}

	//hybrid method using the depth from the ray method and the direction from the invprojection method
	//from scatterer
	float3 getPreciseWorldPosFromDepth(float2 uv, float zdepth, float4x4 CameraToWorld)
	{
		float depth = Linear01Depth(zdepth);

	#ifdef SHADER_API_D3D11
		zdepth = 1 - zdepth;
	#endif

		float4 clipPos = float4(uv, zdepth, 1.0);
		clipPos.xyz = 2.0f * clipPos.xyz - 1.0f;
		float4 camPos = mul(unity_CameraInvProjection, clipPos);
		camPos.xyz /= camPos.w;

		float3 rayDirection = normalize(camPos.xyz);

		float3 cameraForwardDir = float3(0,0,-1);
		float aa = dot(rayDirection, cameraForwardDir);

		camPos.xyz = rayDirection * depth/aa * _ProjectionParams.z;

		float4 worldPos = mul(CameraToWorld,float4(camPos.xyz,1.0));
		return (worldPos.xyz/worldPos.w);
	}
	
	float3 getPreciseWorldPosFromDepth(float2 uv, float zdepth)
	{
		float depth = Linear01Depth(zdepth);

	#if defined(UNITY_REVERSED_Z)
		zdepth = 1 - zdepth;
	#endif

		float4 clipPos = float4(uv, zdepth, 1.0);
		clipPos.xyz = 2.0f * clipPos.xyz - 1.0f;

		float4 camPos = mul(unity_CameraInvProjection, clipPos);
		camPos.xyz /= camPos.w;

		float3 rayDirection = normalize(camPos.xyz);

		float3 cameraForwardDir = float3(0.0, 0.0, -1.0);
		float aa = dot(rayDirection, cameraForwardDir);

		camPos.xyz = rayDirection * depth/aa * _ProjectionParams.z;
		camPos.z = -camPos.z;

		float4 worldPos = mul(unity_CameraToWorld,float4(camPos.xyz, 1.0));
		return (worldPos.xyz/worldPos.w);
	}

	float3 getPreciseViewPosFromDepth(float2 uv, float zdepth)
	{
		float depth = Linear01Depth(zdepth);

	#ifdef SHADER_API_D3D11
		zdepth = 1 - zdepth;
	#endif

		float4 clipPos = float4(uv, zdepth, 1.0);
		clipPos.xyz = 2.0f * clipPos.xyz - 1.0f;
		float4 camPos = mul(unity_CameraInvProjection, clipPos);
		camPos.xyz /= camPos.w;

		float3 rayDirection = normalize(camPos.xyz);

		float3 cameraForwardDir = float3(0,0,-1);
		float aa = dot(rayDirection, cameraForwardDir);

		camPos.xyz = rayDirection * depth/aa * _ProjectionParams.z;

		return camPos.xyz;
	}
#endif