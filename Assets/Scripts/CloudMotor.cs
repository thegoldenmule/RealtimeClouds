using UnityEngine;

using System.Collections;

namespace TheGoldenMule.Cloud
{
    /// <summary>
    /// This script animates shader values for gpu generated clouds.
    /// </summary>
    public class CloudMotor : MonoBehaviour
    {
        /// <summary>
        /// The generated Texture2D instance, uploaded to the GPU for noise
        /// values.
        /// </summary>
        private Texture2D _texture;

        /// <summary>
        /// Refers to how quickly the clouds scroll across the plane.
        /// </summary>
        [SerializeField]
        private float _translationSpeed = 0.0001f;

        /// <summary>
        /// Refers to how quickly the clouds change shape.
        /// </summary>
        [SerializeField]
        private float _morphSpeed = 0.001f;

        /// <summary>
        /// A flag for enabling and disabling cloud scrolling.
        /// </summary>
        [SerializeField]
        private bool _translationEnabled = true;

        /// <summary>
        /// A flag for enabling and disabling cloud shape changing.
        /// </summary>
        [SerializeField]
        private bool _morphEnabled = true;

        /// <summary>
        /// A PRNG for each octave of noise used by the shader.
        /// </summary>
        private System.Random[] _prngs = new System.Random[6]
        {
            new System.Random(8887),
            new System.Random(1109),
            new System.Random(400157),
            new System.Random(200159),
            new System.Random(299807),
            new System.Random(499787)
        };

        /// <summary>
        /// For keeping track of random number values for each octave.
        /// </summary>
        private float[] _rs = new float[6];

        /// <summary>
        /// For keeping track of cloud sim time.
        /// </summary>
        private float _t = 1;

        /// <summary>
        /// Called as part of Unity's MonoBehaviour lifecycle.
        /// </summary>
        private void Start()
        {
            // generate a new texture
            _texture = TextureProvider.GenerateValueNoiseTexture(Random.Range(int.MinValue, int.MaxValue));

            // set the texture on the Material
            gameObject.GetComponent<MeshRenderer>().material.SetTexture("_PermTexture", _texture);
        }

        /// <summary>
        /// Called as part of Unity's MonoBehaviour lifecycle.
        /// </summary>
        private void Update()
        {
            MeshRenderer renderer = gameObject.GetComponent<MeshRenderer>();

            // translate
            if (_translationEnabled)
            {
                _t += _translationSpeed;

                renderer.material.SetFloat("_T", _t);
            }

            // change shape
            if (_morphEnabled)
            {
                for (int i = 1; i < _prngs.Length + 1; i++)
                {
                    // upload a new random value for this octave
                    _rs[i - 1] += (float) _prngs[i - 1].NextDouble() * _morphSpeed;
                    renderer.material.SetFloat("_R" + i.ToString(), _rs[i - 1]);
                }
            }
        }
    }
}