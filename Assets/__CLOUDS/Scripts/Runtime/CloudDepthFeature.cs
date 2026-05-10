using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class CloudDepthFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    {
        public RenderPassEvent passEvent = RenderPassEvent.BeforeRenderingOpaques;
        public int resolution = 512;
        public LayerMask layerMask = -1;
        public float sunOrthoSize = 50f;
        public float sunDepthRange = 200f;
    }

    public Settings settings = new Settings();
    private CloudDepthPass _pass;

    public override void Create()
    {
        _pass = new CloudDepthPass(settings);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        _pass.Setup();
        renderer.EnqueuePass(_pass);
    }

    protected override void Dispose(bool disposing)
    {
        _pass?.Dispose();
    }
}

public class CloudDepthPass : ScriptableRenderPass
{
    private CloudDepthFeature.Settings _s;

    static readonly ShaderTagId _tagFront = new ShaderTagId("DepthFront");
    static readonly ShaderTagId _tagBack = new ShaderTagId("DepthBack");

    static readonly int _camFrontID = Shader.PropertyToID("_TempCamFront");
    static readonly int _camBackID = Shader.PropertyToID("_TempCamBack");
    static readonly int _sunFrontID = Shader.PropertyToID("_TempSunFront");
    static readonly int _sunBackID = Shader.PropertyToID("_TempSunBack");
    static readonly int _lightVPID = Shader.PropertyToID("_LightViewProj");

    public CloudDepthPass(CloudDepthFeature.Settings settings)
    {
        _s = settings;
        renderPassEvent = settings.passEvent;
    }

    public void Setup() { }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        CommandBuffer cmd = CommandBufferPool.Get("Cloud Depth");

        var desc = new RenderTextureDescriptor(_s.resolution, _s.resolution, RenderTextureFormat.RFloat, 0);
        cmd.GetTemporaryRT(_camFrontID, desc);
        cmd.GetTemporaryRT(_camBackID, desc);
        cmd.GetTemporaryRT(_sunFrontID, desc);
        cmd.GetTemporaryRT(_sunBackID, desc);

        var cam = renderingData.cameraData.camera;
        var sort = new SortingSettings(cam);
        var filter = new FilteringSettings(RenderQueueRange.all, _s.layerMask);
        var drawFront = new DrawingSettings(_tagFront, sort);
        var drawBack = new DrawingSettings(_tagBack, sort);

        // Camera front depth (nearest, BlendOp Min in shader)
        cmd.SetRenderTarget(_camFrontID);
        cmd.ClearRenderTarget(false, true, new Color(9999f, 0, 0, 0));
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
        context.DrawRenderers(renderingData.cullResults, ref drawFront, ref filter);

        // Camera back depth (farthest, BlendOp Max in shader)
        cmd.SetRenderTarget(_camBackID);
        cmd.ClearRenderTarget(false, true, new Color(0, 0, 0, 0));
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
        context.DrawRenderers(renderingData.cullResults, ref drawBack, ref filter);

        // Sun depth
        Light sun = RenderSettings.sun;
        if (sun != null && sun.type == LightType.Directional)
        {
            Vector3 dir = sun.transform.forward;
            Vector3 up = Vector3.up;
            if (Mathf.Abs(Vector3.Dot(dir, up)) > 0.99f) up = Vector3.right;
            Vector3 pos = -dir * _s.sunDepthRange * 0.5f;

            Matrix4x4 view = Matrix4x4.LookAt(pos, pos + dir, up);
            Matrix4x4 proj = Matrix4x4.Ortho(
                -_s.sunOrthoSize, _s.sunOrthoSize,
                -_s.sunOrthoSize, _s.sunOrthoSize,
                0.1f, _s.sunDepthRange);

            cmd.SetGlobalMatrix(_lightVPID, proj * view);
            cmd.SetViewProjectionMatrices(view, proj);

            cmd.SetRenderTarget(_sunFrontID);
            cmd.ClearRenderTarget(false, true, new Color(9999f, 0, 0, 0));
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            context.DrawRenderers(renderingData.cullResults, ref drawFront, ref filter);

            cmd.SetRenderTarget(_sunBackID);
            cmd.ClearRenderTarget(false, true, new Color(0, 0, 0, 0));
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            context.DrawRenderers(renderingData.cullResults, ref drawBack, ref filter);

            cmd.SetViewProjectionMatrices(cam.worldToCameraMatrix, cam.projectionMatrix);
        }

        cmd.SetGlobalTexture("_CameraFrontDepth", _camFrontID);
        cmd.SetGlobalTexture("_CameraBackDepth", _camBackID);
        cmd.SetGlobalTexture("_SunFrontDepth", _sunFrontID);
        cmd.SetGlobalTexture("_SunBackDepth", _sunBackID);

        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }

    public override void OnCameraCleanup(CommandBuffer cmd)
    {
        cmd.ReleaseTemporaryRT(_camFrontID);
        cmd.ReleaseTemporaryRT(_camBackID);
        cmd.ReleaseTemporaryRT(_sunFrontID);
        cmd.ReleaseTemporaryRT(_sunBackID);
    }

    public override void FrameCleanup(CommandBuffer cmd)
    {
        cmd.ReleaseTemporaryRT(_camFrontID);
        cmd.ReleaseTemporaryRT(_camBackID);
        cmd.ReleaseTemporaryRT(_sunFrontID);
        cmd.ReleaseTemporaryRT(_sunBackID);
    }

    public void Dispose() { }
}
