using UnityEngine;
using UnityEditor;
using System.IO;

public class CloudNoiseGenerator : EditorWindow
{
    [MenuItem("Tools/Cloud/Generate 3D Noise Textures")]
    public static void ShowWindow()
    {
        GetWindow<CloudNoiseGenerator>("Cloud Noise Gen");
    }

    void OnGUI()
    {
        EditorGUILayout.LabelField("Generate 3D Noise Textures for Cloud Shader", EditorStyles.wordWrappedLabel);
        EditorGUILayout.Space();
        EditorGUILayout.LabelField("PerlinWorley_128: 128³ RGBAHalf, ~4MB");
        EditorGUILayout.LabelField("Worley_32: 32³ RGBHalf, ~0.5MB");
        EditorGUILayout.Space();

        if (GUILayout.Button("Generate Both", GUILayout.Height(40)))
        {
            GeneratePerlinWorley();
            GenerateWorleyDetail();
            AssetDatabase.Refresh();
            EditorUtility.DisplayDialog("Done", "3D noise textures generated.\nCheck Assets/__CLOUDS/Textures3D/", "OK");
        }

        if (GUILayout.Button("Generate Perlin-Worley Only"))
            GeneratePerlinWorley();

        if (GUILayout.Button("Generate Worley Detail Only"))
            GenerateWorleyDetail();
    }

    // ============================================================
    // Permutation table (Ken Perlin's original, doubled to 512)
    // ============================================================
    static readonly int[] _perm = {
        151,160,137, 91, 90, 15,131, 13,201, 95, 96, 53,194,233,  7,225,
        140, 36,103, 30, 69,142,  8, 99, 37,240, 21, 10, 23,190,  6,148,
        247,120,234, 75,  0, 26,197, 62, 94,252,219,203,117, 35, 11, 32,
         57,177, 33, 88,237,149, 56, 87,174, 20,125,136,171,168, 68,175,
         74,165, 71,134,139, 48, 27,166, 77,146,158,231, 83,111,229,122,
         60,211,133,230,220,105, 92, 41, 55, 46,245, 40,244,102,143, 54,
         65, 25, 63,161,  1,216, 80, 73,209, 76,132,187,208, 89, 18,169,
        200,196,135,130,116,188,159, 86,164,100,109,198,173,186,  3, 64,
         52,217,226,250,124,123,  5,202, 38,147,118,126,255, 82, 85,212,
        207,206, 59,227, 47, 16, 58, 17,182,189, 28, 42,223,183,170,213,
        119,248,152,  2, 44,154,163, 70,221,153,101,155,167, 43,172,  9,
        129, 22, 39,253, 19, 98,108,110, 79,113,224,232,178,185,112,104,
        218,246, 97,228,251, 34,242,193,238,210,144, 12,191,179,162,241,
         81, 51,145,235,249, 14,239,107, 49,192,214, 31,181,199,106,157,
        184, 84,204,176,115,121, 50, 45,127,  4,150,254,138,236,205, 93,
        222,114, 67, 29, 24, 72,243,141,128,195, 78, 66,215, 61,156,180
    };

    static int[] _perm512;

    static void InitPerm()
    {
        if (_perm512 != null) return;
        _perm512 = new int[512];
        for (int i = 0; i < 512; i++)
            _perm512[i] = _perm[i & 255];
    }

    // ============================================================
    // 3D Perlin Noise — returns [-1, 1]
    // ============================================================
    static float Fade(float t) { return t * t * t * (t * (t * 6f - 15f) + 10f); }

    static float Grad(int hash, float x, float y, float z)
    {
        int h = hash & 15;
        float u = h < 8 ? x : y;
        float v = h < 4 ? y : (h == 12 || h == 14 ? x : z);
        return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v);
    }

    static float Perlin3D(float x, float y, float z)
    {
        InitPerm();
        int X = (int)Mathf.Floor(x) & 255;
        int Y = (int)Mathf.Floor(y) & 255;
        int Z = (int)Mathf.Floor(z) & 255;
        x -= Mathf.Floor(x);
        y -= Mathf.Floor(y);
        z -= Mathf.Floor(z);
        float u = Fade(x), v = Fade(y), w = Fade(z);

        int A  = _perm512[X] + Y;
        int AA = _perm512[A] + Z;
        int AB = _perm512[A + 1] + Z;
        int B  = _perm512[X + 1] + Y;
        int BA = _perm512[B] + Z;
        int BB = _perm512[B + 1] + Z;

        return Mathf.Lerp(
            Mathf.Lerp(
                Mathf.Lerp(Grad(_perm512[AA], x, y, z), Grad(_perm512[BA], x - 1, y, z), u),
                Mathf.Lerp(Grad(_perm512[AB], x, y - 1, z), Grad(_perm512[BB], x - 1, y - 1, z), u), v),
            Mathf.Lerp(
                Mathf.Lerp(Grad(_perm512[AA + 1], x, y, z - 1), Grad(_perm512[BA + 1], x - 1, y, z - 1), u),
                Mathf.Lerp(Grad(_perm512[AB + 1], x, y - 1, z - 1), Grad(_perm512[BB + 1], x - 1, y - 1, z - 1), u), v),
            w);
    }

    // ============================================================
    // 3D Worley (Cellular) Noise — F1 distance normalized to [0, 1]
    // ============================================================
    static float HashToFloat(int x, int y, int z)
    {
        InitPerm();
        int h = _perm512[(_perm512[(_perm512[x & 255] + y) & 255] + z) & 255];
        return (float)h / 255f;
    }

    static Vector3 WorleyFeaturePoint(int x, int y, int z, int seed)
    {
        InitPerm();
        // Generate a pseudo-random point in [0,1)³ for cell (x,y,z)
        int h = _perm512[(_perm512[(_perm512[x & 255] + y) & 255] + z) & 255];
        h = (h + seed) & 255;
        float fx = (_perm512[h] & 255) / 256f;
        float fy = (_perm512[(h + 37) & 255] & 255) / 256f;
        float fz = (_perm512[(h + 73) & 255] & 255) / 256f;
        return new Vector3(fx, fy, fz);
    }

    static float WorleyF1_3D(float x, float y, float z, int seed)
    {
        int cx = (int)Mathf.Floor(x);
        int cy = (int)Mathf.Floor(y);
        int cz = (int)Mathf.Floor(z);
        float minDist = float.MaxValue;

        // Check 3x3x3 neighborhood
        for (int dx = -1; dx <= 1; dx++)
        {
            for (int dy = -1; dy <= 1; dy++)
            {
                for (int dz = -1; dz <= 1; dz++)
                {
                    Vector3 fp = WorleyFeaturePoint(cx + dx, cy + dy, cz + dz, seed);
                    float px = (cx + dx) + fp.x;
                    float py = (cy + dy) + fp.y;
                    float pz = (cz + dz) + fp.z;
                    float dist = Mathf.Sqrt(
                        (x - px) * (x - px) +
                        (y - py) * (y - py) +
                        (z - pz) * (z - pz));
                    if (dist < minDist) minDist = dist;
                }
            }
        }
        // Normalize: max possible distance in 3³ neighborhood is ~sqrt(3) ≈ 1.732
        return Mathf.Clamp01(minDist / 1.732f);
    }

    // ============================================================
    // Texture Generators
    // ============================================================

    void GeneratePerlinWorley()
    {
        int res = 128;
        Texture3D tex = new Texture3D(res, res, res, UnityEngine.Experimental.Rendering.DefaultFormat.HDR, UnityEngine.Experimental.Rendering.TextureCreationFlags.None);
        tex.wrapMode = TextureWrapMode.Repeat;
        tex.filterMode = FilterMode.Bilinear;
        Color[] pixels = new Color[res * res * res];

        for (int z = 0; z < res; z++)
        {
            float nz = (float)z / res;
            for (int y = 0; y < res; y++)
            {
                float ny = (float)y / res;
                for (int x = 0; x < res; x++)
                {
                    float nx = (float)x / res;
                    int idx = x + y * res + z * res * res;

                    // R: Perlin noise at base frequency 4
                    float perlin = Perlin3D(nx * 4f, ny * 4f, nz * 4f);

                    // G: Worley F1 at frequency 8
                    float worley2 = WorleyF1_3D(nx * 8f, ny * 8f, nz * 8f, 0);

                    // B: Worley F1 at frequency 16
                    float worley4 = WorleyF1_3D(nx * 16f, ny * 16f, nz * 16f, 1);

                    // A: Worley F1 at frequency 32
                    float worley8 = WorleyF1_3D(nx * 32f, ny * 32f, nz * 32f, 2);

                    // Remap Perlin from [-1,1] to [0,1] for texture storage
                    pixels[idx] = new Color(
                        perlin * 0.5f + 0.5f,
                        worley2,
                        worley4,
                        worley8);
                }
            }
            float progress = (float)(z + 1) / res;
            if (z % 16 == 0)
                EditorUtility.DisplayProgressBar("Generating Perlin-Worley 128³",
                    $"{(int)(progress * 100)}%", progress);
        }

        tex.SetPixels(pixels);
        tex.Apply();
        SaveTexture(tex, "PerlinWorley_128.asset");
        EditorUtility.ClearProgressBar();
        Debug.Log("PerlinWorley_128.asset generated successfully.");
    }

    void GenerateWorleyDetail()
    {
        int res = 32;
        Texture3D tex = new Texture3D(res, res, res, UnityEngine.Experimental.Rendering.DefaultFormat.HDR, UnityEngine.Experimental.Rendering.TextureCreationFlags.None);
        tex.wrapMode = TextureWrapMode.Repeat;
        tex.filterMode = FilterMode.Bilinear;
        Color[] pixels = new Color[res * res * res];

        for (int z = 0; z < res; z++)
        {
            float nz = (float)z / res;
            for (int y = 0; y < res; y++)
            {
                float ny = (float)y / res;
                for (int x = 0; x < res; x++)
                {
                    float nx = (float)x / res;
                    int idx = x + y * res + z * res * res;

                    // R: Worley F1 at frequency 4
                    float w2 = WorleyF1_3D(nx * 4f, ny * 4f, nz * 4f, 10);

                    // G: Worley F1 at frequency 8
                    float w4 = WorleyF1_3D(nx * 8f, ny * 8f, nz * 8f, 11);

                    // B: Worley F1 at frequency 16
                    float w8 = WorleyF1_3D(nx * 16f, ny * 16f, nz * 16f, 12);

                    pixels[idx] = new Color(w2, w4, w8, 0);
                }
            }
            if (z % 8 == 0)
                EditorUtility.DisplayProgressBar("Generating Worley Detail 32³",
                    $"{(int)((z + 1f) / res * 100)}%", (float)z / res);
        }

        tex.SetPixels(pixels);
        tex.Apply();
        SaveTexture(tex, "Worley_32.asset");
        EditorUtility.ClearProgressBar();
        Debug.Log("Worley_32.asset generated successfully.");
    }

    void SaveTexture(Texture3D tex, string filename)
    {
        string dir = "Assets/__CLOUDS/Textures3D";
        if (!Directory.Exists(dir))
            Directory.CreateDirectory(dir);

        string path = Path.Combine(dir, filename);
        // Delete existing asset if present
        if (File.Exists(path))
            AssetDatabase.DeleteAsset(path);

        AssetDatabase.CreateAsset(tex, path);
        AssetDatabase.SaveAssets();
    }
}
