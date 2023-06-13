﻿using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using UnityEngine;
using Utils;
using KSPAssets;

namespace ShaderLoader
{
    [KSPAddon(KSPAddon.Startup.Instantly, true)]
    public class ShaderLoaderClass : MonoBehaviour
    {
        static Dictionary<string, Shader> shaderDictionary = null;

        public static Vector3Int stbnDimensions = new Vector3Int(128, 128, 64);
        public static Texture2D stbn;

        public static bool loaded = false;

        private void Start()
        {
            LoadShaders();
        }

        private void LoadShaders()
        {
            if (shaderDictionary == null) {
                shaderDictionary = new Dictionary<string, Shader>();

                // Add all other shaders
                Shader[] shaders = Resources.FindObjectsOfTypeAll<Shader>();
                foreach (Shader shader in shaders) {
                    shaderDictionary[shader.name] = shader;
                }

                using (WWW www = new WWW("file://" + KSPUtil.ApplicationRootPath + "GameData/EnvironmentalVisualEnhancements/eveshaders.bundle")) {
                    if (www.error != null) {
                        KSPLog.print("[EVE] eveshaders.bundle not found!");
                        return;
                    }

                    AssetBundle bundle = www.assetBundle;

                    shaders = bundle.LoadAllAssets<Shader>();

                    foreach (Shader shader in shaders) {
                        KSPLog.print("[EVE] Shader " + shader.name + " loaded");
                        shaderDictionary.Add(shader.name, shader);
                    }

                    bundle.Unload(false);
                    www.Dispose();
                }

                // Load Stbn
                stbn = new Texture2D((int)stbnDimensions.x, (int) (stbnDimensions.y * stbnDimensions.z), TextureFormat.R8, false);
                stbn.filterMode = FilterMode.Point;
                stbn.wrapMode = TextureWrapMode.Repeat;
                stbn.LoadRawTextureData(System.IO.File.ReadAllBytes(KSPUtil.ApplicationRootPath + "GameData/EnvironmentalVisualEnhancements/stbn.R8"));
                stbn.Apply();

                Debug.Log("Stbn loaded");

                loaded = true;
            }
        }

        public static Shader FindShader(string name)
        {
            if (shaderDictionary == null) {
                KSPLog.print("[EVE] Trying to find shader before assets loaded");
                return null;
            }
            if (shaderDictionary.ContainsKey(name))
            {
                return shaderDictionary[name];
            }
            KSPLog.print("[EVE] Could not find shader " + name);
            return null;
        }
    }
}
