using UnityEngine;

namespace Utils
{
    // When reflection probe cameras render, no indication is given via the API for which face is being rendered
    // and the transform doesn't change to reflect the different orientation of the face.
    // The CameraToWorldMatrix is set manually for each face and the faces are axis-aligned
    // therefore we can extract the camera's forward direction and use it to detect which face is being rendered
    public static class ReflectionProbeUtils
    {
        public static CubemapFace GetCurrentReflectionProbeCameraCubemapFace(Camera cam)
        {
            Vector3 cameraForward = cam.cameraToWorldMatrix.GetColumn(2);

            return GetCubemapFace(cameraForward);
        }

        public static CubemapFace GetCubemapFace(Vector3 forward)
        {
            if (forward.x == -1) return CubemapFace.PositiveX;
            if (forward.x == 1) return CubemapFace.NegativeX;
            if (forward.y == -1) return CubemapFace.PositiveY;
            if (forward.y == 1) return CubemapFace.NegativeY;
            if (forward.z == -1) return CubemapFace.PositiveZ;
            if (forward.z == 1) return CubemapFace.NegativeZ;

            return CubemapFace.Unknown;
        }
    }
}