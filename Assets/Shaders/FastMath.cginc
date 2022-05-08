#define HALF_PI		1.57079632679
#define INV_TWO_PI	0.15915494309

//source: https://github.com/Patapom/GodComplex/blob/master/Tests/TestHBIL/Shaders/FastMath.hlsl#L301
float fastAtan(float x) {
	return x * (-0.1784 * x - 0.0663 * x * x + 1.0301);
}

float fastAtan2(float y, float x) {
	// atan approximations are usually only reliable over [-1, 1], or, in our case, [0, 1] due to modifications.
	// So range-reduce using abs and by flipping whether x or y is on top.
	//float t = abs(x); // t used as swap and atan result
	float t = abs(x); // t used as swap and atan result.
	float opposite = abs(y);
	float adjacent = max(t, opposite);
	opposite = min(t, opposite);

	t = fastAtan(opposite / adjacent);

	// Undo range reduction
	t = abs(y) > abs(x) ? HALF_PI - t: t;
	t = x < 0.0 ? PI - t : t;
	t = y < 0.0 ? -t : t;
	return t;
}

//source: https://github.com/Patapom/GodComplex/blob/master/Tests/TestHBIL/Shaders/FastMath.hlsl#L269
float fastAcos(float inX)
{
	float x1 = abs(inX);
	float x2 = x1 * x1;
	float x3 = x2 * x1;
	float s;

	s = -0.2121144f * x1 + 1.5707288f;
	s = 0.0742610f * x2 + s;
	s = -0.0187293f * x3 + s;
	s = sqrt(1.0f - x1) * s;

	// acos function mirroring
	// check per platform if compiles to a selector - no branch neeeded
	return inX >= 0.0f ? s : PI - s;
}