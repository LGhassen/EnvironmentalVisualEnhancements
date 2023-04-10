using Utils;
using UnityEngine;

namespace Atmosphere
{
    public class AmbientSound
    {
        [ConfigItem]
        string soundName = "path here";

        //[ConfigItem, Optional]
        //string ivaSoundName = null;

        public string SoundName { get => soundName; }

        //public string IvaSoundName { get => ivaSoundName; }

        GameObject ambientSoundGameObject;
        AudioSource audioSource;

        public bool Apply()
        {
            if (!GameDatabase.Instance.ExistsAudioClip(soundName))// || (IvaSoundName != null && !GameDatabase.Instance.ExistsAudioClip(IvaSoundName)))
                return false;

            ambientSoundGameObject = new GameObject();

            if (FlightCamera.fetch != null)
                ambientSoundGameObject.transform.parent = FlightCamera.fetch.transform;

            audioSource = ambientSoundGameObject.AddComponent<AudioSource>();

            audioSource.clip = GameDatabase.Instance.GetAudioClip(soundName);
            audioSource.loop = true;

            audioSource.Play();
            audioSource.Pause();

            GameEvents.onGameSceneLoadRequested.Add(GameSceneLoadStarted);

            return true;
        }

        public void Remove()
        {
            if (audioSource != null)
                audioSource.Stop();

            if (ambientSoundGameObject != null)
                GameObject.Destroy(ambientSoundGameObject);

            GameEvents.onGameSceneLoadRequested.Remove(GameSceneLoadStarted);
        }

        public void Update(float coverage)
        {
            if (coverage < 0.05)
                audioSource.Pause();
            else
            {
                audioSource.volume = coverage;
                audioSource.UnPause();
            }

        }

        public void SetEnabled(bool value)
        {
            if (ambientSoundGameObject != null)
            {
                ambientSoundGameObject.SetActive(value);

                if (!value)
                    audioSource.Pause();
            }
        }

        private void GameSceneLoadStarted(GameScenes scene)
        {
            Update(0f);
        }
    }
}