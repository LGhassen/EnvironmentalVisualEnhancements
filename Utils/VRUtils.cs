﻿using UnityEngine;
using UnityEngine.Rendering;
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

        public static FlipFlop<FlipFlop<RenderTexture>> CreateVRFlipFlopRT(bool supportVR, int width, int height, RenderTextureFormat format, FilterMode filterMode, TextureDimension dimension = TextureDimension.Tex2D, int depth = 0, bool randomReadWrite = false, TextureWrapMode wrapMode = TextureWrapMode.Clamp)
        {
            return new FlipFlop<FlipFlop<RenderTexture>>(
                supportVR ? RenderTextureUtils.CreateFlipFlopRT(width, height, format, filterMode, dimension, depth, randomReadWrite, wrapMode) : new FlipFlop<RenderTexture>(null, null),
                RenderTextureUtils.CreateFlipFlopRT(width, height, format, filterMode, dimension, depth, randomReadWrite, wrapMode));
        }

        public static void ReleaseVRFlipFlopRT(ref FlipFlop<FlipFlop<RenderTexture>> flipFlop)
        {
            var ff = flipFlop[false];
            RenderTextureUtils.ReleaseFlipFlopRT(ref ff);
            ff = flipFlop[true];
            RenderTextureUtils.ReleaseFlipFlopRT(ref ff);

            flipFlop = new FlipFlop<FlipFlop<RenderTexture>>(ff, ff);
        }

        public static void ResizeVRFlipFlopRT(ref FlipFlop<FlipFlop<RenderTexture>> flipFlop, int newWidth, int newHeight)
        {
            var leftEyeFlipFlop = flipFlop[false];
            var rightEyeFlipFlop = flipFlop[true];

            if (leftEyeFlipFlop[true] != null)
                RenderTextureUtils.ResizeFlipFlopRT(ref leftEyeFlipFlop, newWidth, newHeight);

            if (rightEyeFlipFlop[true] != null)
                RenderTextureUtils.ResizeFlipFlopRT(ref rightEyeFlipFlop, newWidth, newHeight);
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
