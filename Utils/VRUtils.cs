using UnityEngine;
using UnityEngine.XR;

namespace Utils
{
    public static class VRUtils
    {
        public static bool VREnabled()
        {
            return XRSettings.loadedDeviceName != string.Empty;
        }

        public static void GetEyeTextureResolution(out int width, out int height)
        {
            width = XRSettings.eyeTextureWidth;
            height = XRSettings.eyeTextureHeight;
        }

        public static Matrix4x4 GetNonJitteredProjectionMatrixForCamera(Camera cam)
        {
            if (cam.stereoActiveEye == Camera.MonoOrStereoscopicEye.Mono)
            {
                return cam.nonJitteredProjectionMatrix;
            }
            else
            {
                return cam.GetStereoNonJitteredProjectionMatrix(cam.stereoActiveEye == Camera.MonoOrStereoscopicEye.Left ? Camera.StereoscopicEye.Left : Camera.StereoscopicEye.Right);
            }
        }

        public static Matrix4x4 GetViewMatrixForCamera(Camera cam)
        {
            if (cam.stereoActiveEye == Camera.MonoOrStereoscopicEye.Mono)
            {
                return cam.worldToCameraMatrix;
            }
            else
            {
                return cam.GetStereoViewMatrix(cam.stereoActiveEye == Camera.MonoOrStereoscopicEye.Left ? Camera.StereoscopicEye.Left : Camera.StereoscopicEye.Right);
            }
        }
    }
}
