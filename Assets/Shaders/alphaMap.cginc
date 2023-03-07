#ifndef ALPHA_MAP_CG_INC
#define ALPHA_MAP_CG_INC

inline half vectorSum(half4 v) 
{
	return (v.x + v.y + v.z + v.w);
}

half4 alphaMask1;
half4 alphaMask2;
half4 alphaMask3;

#define ALPHA_VALUE_1(color) \
	vectorSum( color * alphaMask1 )

#define ALPHA_VALUE_2(color) \
	vectorSum( color * alphaMask2 )

#define ALPHA_VALUE_3(color) \
	vectorSum( color * alphaMask3 )

#ifdef ALPHAMAP_1
	#define ALPHA_COLOR_1(color) half4(1, 1, 1, ALPHA_VALUE_1(color))
	#define ALPHA_VECTOR_1(color) ALPHA_VALUE_1(color).xxxx
#else
	#define ALPHA_COLOR_1(color) color
	#define ALPHA_VECTOR_1(color) color
#endif

#ifdef ALPHAMAP_2
	#define ALPHA_COLOR_2(color) half4(1, 1, 1, ALPHA_VALUE_2(color))
	#define ALPHA_VECTOR_2(color) ALPHA_VALUE_2(color).xxxx
#else
	#define ALPHA_COLOR_2(color) color
	#define ALPHA_VECTOR_2(color) color
#endif

#ifdef ALPHAMAP_3
	#define ALPHA_COLOR_3(color) half4(1, 1, 1, ALPHA_VALUE_3(color))
	#define ALPHA_VECTOR_3(color) ALPHA_VALUE_3(color).xxxx
#else
	#define ALPHA_COLOR_3(color) color
	#define ALPHA_VECTOR_3(color) color
#endif

#endif