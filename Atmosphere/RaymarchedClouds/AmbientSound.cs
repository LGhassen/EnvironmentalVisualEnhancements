using Utils;
using UnityEngine;

namespace Atmosphere
{
    public class AmbientSound
    {
        [ConfigItem]
        string soundName = "path here";

        [ConfigItem, Optional]
        string ivaSoundName = null;

        GameObject ambientSoundGameObject;
        AudioSource audioSource = null;
        AudioSource ivaAudioSource = null;

        bool ivaPlaying = false;

        public bool Apply()
        {
            if (!GameDatabase.Instance.ExistsAudioClip(soundName))
                return false;

            ambientSoundGameObject = new GameObject();

            if (FlightCamera.fetch != null)
                ambientSoundGameObject.transform.parent = FlightCamera.fetch.transform;

            audioSource = ambientSoundGameObject.AddComponent<AudioSource>();
            audioSource.clip = GameDatabase.Instance.GetAudioClip(soundName);
            audioSource.loop = true;

            audioSource.Play();
            audioSource.Pause();

            if (GameDatabase.Instance.ExistsAudioClip(ivaSoundName))
            {
                ivaAudioSource = ambientSoundGameObject.AddComponent<AudioSource>();
                ivaAudioSource.clip = GameDatabase.Instance.GetAudioClip(ivaSoundName);
                ivaAudioSource.loop = true;

                ivaAudioSource.Play();
                ivaAudioSource.Pause();
            }

            GameEvents.onGameSceneLoadRequested.Add(GameSceneLoadStarted);
            GameEvents.OnCameraChange.Add(CameraChanged);

            return true;
        }

        public void Remove()
        {
            if (audioSource != null)
                audioSource.Stop();

            if (ivaAudioSource != null)
                ivaAudioSource.Stop();

            if (ambientSoundGameObject != null)
                GameObject.Destroy(ambientSoundGameObject);

            GameEvents.onGameSceneLoadRequested.Remove(GameSceneLoadStarted);
            GameEvents.OnCameraChange.Remove(CameraChanged);
        }

        public void Update(float coverage)
        {
            if (coverage < 0.05)
            {
                audioSource.volume = 0f;
                audioSource.Pause();

                if (ivaAudioSource != null)
                {
                    ivaAudioSource.volume = 0f;
                    ivaAudioSource.Pause();
                }
            }
            else
            {
                smoothVolumeChange(audioSource, coverage * (ivaPlaying ? 0.8f : 1f));
                audioSource.UnPause();

                if (ivaAudioSource != null && ivaPlaying)
                {
                    smoothVolumeChange(ivaAudioSource, coverage);
                    ivaAudioSource.UnPause();
                }
            }

        }

        public void SetEnabled(bool value)
        {
            if (ambientSoundGameObject != null)
            {
                ambientSoundGameObject.SetActive(value);

                if (!value)
                {
                    audioSource.Pause();
                    audioSource.volume = 0f;

                    if (ivaAudioSource != null)
                    {
                        ivaAudioSource.volume = 0f;
                        ivaAudioSource.Pause();
                    }
                }
                    
            }
        }

        private void GameSceneLoadStarted(GameScenes scene)
        {
            Update(0f);
        }

        private void CameraChanged(CameraManager.CameraMode cameraMode)
        {
            if (ivaAudioSource != null && (cameraMode == CameraManager.CameraMode.IVA || cameraMode == CameraManager.CameraMode.Internal))
            {
                ivaPlaying = true;
            }
            else
            { 
                ivaPlaying = false;
                ivaAudioSource.volume = 0f;
                ivaAudioSource.Pause();
            }
        }

        private static void smoothVolumeChange(AudioSource audiosource, float targetVolume)
        {
            audiosource.volume = Mathf.Lerp(audiosource.volume, targetVolume, 0.02f);
        }
    }
}