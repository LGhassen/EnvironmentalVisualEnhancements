using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

namespace Utils
{
    public static class TextureOnDemandLoader
    {
        private static Dictionary<string, TextureOnDemand> textureOnDemandDictionary = new Dictionary<string, TextureOnDemand>();

        public static Texture2D GetTexture(string textureName)
        {
            if (string.IsNullOrEmpty(textureName)) return null;

            var gameDatabaseTexture = GameDatabase.Instance.GetTextureInfo(textureName);

            if (gameDatabaseTexture != null)
            {
                return gameDatabaseTexture.texture;
            }

            if (textureOnDemandDictionary.TryGetValue(textureName, out TextureOnDemand existingTexture))
            {
                return existingTexture.UseTexture();
            }
            else
            {
                var newTexture = TextureOnDemand.Load(textureName);

                if(newTexture != null)
                {
                    textureOnDemandDictionary.Add(textureName, newTexture);
                    Log("Texture " + textureName + " successfully loaded");
                    return newTexture.UseTexture();
                }
                else
                {
                    Log("Texture " + textureName + " not found");
                    return null;
                }
            }
        }

        public static void NotifyUnload(string textureName)
        {
            if (textureOnDemandDictionary.TryGetValue(textureName, out TextureOnDemand existingTexture))
            {
                if (existingTexture.UnloadIfNeeded())
                {
                    textureOnDemandDictionary.Remove(textureName);
                    Log("Texture " + textureName + " unloaded");
                }
            }
        }

        private static void Log(string log)
        {
            Debug.Log("[EVE OnDemand] " + log);
        }

        // TODO: make this prettier
        public static bool ExistsTexture(string textureName)
        {
            bool exists = GameDatabase.Instance.ExistsTexture(textureName);

            if (!exists) exists = textureOnDemandDictionary.ContainsKey(textureName);

            var gameDataPath = System.IO.Path.Combine(KSPUtil.ApplicationRootPath, "GameData");

            var pngPath = System.IO.Path.Combine(gameDataPath, textureName + ".png");
            var truecolorPath = System.IO.Path.Combine(gameDataPath, textureName + ".truecolor");
            var ddsPath = System.IO.Path.Combine(gameDataPath, textureName + ".dds");

            if (!exists) exists = System.IO.File.Exists(pngPath);
            if (!exists) exists = System.IO.File.Exists(truecolorPath);
            if (!exists) exists = System.IO.File.Exists(ddsPath);

            if (!exists) Debug.LogError("[EVE OnDemand] " + textureName + " not found.");

            return exists;
        }
    }

    public class TextureOnDemand
    {
        int usageCount = 0;
        Texture2D texture;

        public Texture2D UseTexture()
        {
            usageCount++;
            return texture;
        }

        public bool UnloadIfNeeded()
        {
            usageCount--;

            if (usageCount == 0)
            {
                GameObject.DestroyImmediate(texture);
                return true;
            }

            return false;
        }

        public static TextureOnDemand Load(string textureName)
        {
            var gameDataPath = System.IO.Path.Combine(KSPUtil.ApplicationRootPath, "GameData");

            var pngPath = System.IO.Path.Combine(gameDataPath, textureName + ".png");
            var truecolorPath = System.IO.Path.Combine(gameDataPath, textureName + ".truecolor");
            var ddsPath = System.IO.Path.Combine(gameDataPath, textureName + ".dds");

            var texture = new Texture2D(1, 1);

            if (System.IO.File.Exists(ddsPath))
            {
                Log("Loading texture " + textureName + " from DDS file");
                var textureInfo =new GameDatabase.TextureInfo(new UrlDir.UrlFile(new UrlDir(new UrlDir.ConfigDirectory[0], new UrlDir.ConfigFileType[0]), new System.IO.FileInfo(ddsPath)), texture, false, true, false);
                TextureConverter.DDSToTexture(textureInfo, false, default(Vector2));
                return new TextureOnDemand(textureInfo.texture);
            }
            else if (System.IO.File.Exists(pngPath))
            {
                Log("Loading texture " + textureName + " from PNG file");
                texture.LoadImage(System.IO.File.ReadAllBytes(pngPath));
                return new TextureOnDemand(texture);
            }
            else if (System.IO.File.Exists(truecolorPath))
            {
                Log("Loading texture " + textureName + " from truecolor file");
                texture.LoadImage(System.IO.File.ReadAllBytes(truecolorPath));
                return new TextureOnDemand(texture);
            }

            GameObject.DestroyImmediate(texture);
            return null;
        }

        protected TextureOnDemand(Texture2D texture2D)
        {
            texture = texture2D;
        }

        private static void Log(string log)
        {
            Debug.Log("[EVE OnDemand] " + log);
        }
    }
}
