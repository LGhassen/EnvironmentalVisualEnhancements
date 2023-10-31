#ifndef SOFTWARE_ALPHA_MAP_CG_INC
#define SOFTWARE_ALPHA_MAP_CG_INC

inline half vectorSum(half4 v) 
{
	return (v.x + v.y + v.z + v.w);
}

half useAlphaMask1;
half useAlphaMask2;
half useAlphaMask3;

half4 alphaMask1;
half4 alphaMask2;
half4 alphaMask3;

#define ALPHA_VALUE_1(color) \
	vectorSum( color * alphaMask1 )

#define ALPHA_VALUE_2(color) \
	vectorSum( color * alphaMask2 )

#define ALPHA_VALUE_3(color) \
	vectorSum( color * alphaMask3 )

#define ALPHA_COLOR_1(color) (useAlphaMask1 > 0.5) ? half4(1, 1, 1, ALPHA_VALUE_1(color)) : color
#define ALPHA_VECTOR_1(color) (useAlphaMask1 > 0.5) ? ALPHA_VALUE_1(color).xxxx : color


#define ALPHA_COLOR_2(color) (useAlphaMask2 > 0.5) ? half4(1, 1, 1, ALPHA_VALUE_2(color)) : color
#define ALPHA_VECTOR_2(color) (useAlphaMask2 > 0.5) ? ALPHA_VALUE_2(color).xxxx : color

#define ALPHA_COLOR_3(color) (useAlphaMask3 > 0.5) ? half4(1, 1, 1, ALPHA_VALUE_3(color)) : color
#define ALPHA_VECTOR_3(color) (useAlphaMask3 > 0.5) ? ALPHA_VALUE_3(color).xxxx : color


#endif
