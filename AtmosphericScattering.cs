//
// AtmosphericScattering.cs
//
// Author(s):
//       Baptiste Dupy <baptiste.dupy@gmail.com>
//
// Copyright (c) 2014
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class AtmosphericScattering : MonoBehaviour 
{ 
	/// <summary>
	/// Current camera
	/// </summary>
	public Camera m_currentCamera;

	/// <summary>
	/// Position of current light in camera view port
	/// </summary>
	public Vector4 m_vpLightPos;

	public bool m_lightOnScreen;

	public RenderTexture m_coordinatesTexture;
	public RenderTexture m_depthTexture;
	public RenderTexture m_interpolationTexture;
    public RenderTexture m_raymarchTexture;

	// Materials
	public Material _debugMat;

	public Material m_coordinatesMat;
	public Material m_interpolationMat;
    public Material m_raymarchMat;

	// Shader
	public Shader m_coordinateShader;
	public Shader m_interpolationTextureShader;
    public Shader m_raymarchShader;

	// Shader Properties
	public int m_lightPosShaderProperty;
	public int m_coordTexSizeShaderProperty;
	public int m_screenSizeShaderProperty;
	public int m_depthTextureShaderProperty;
	public int m_raymarchStepShaderProperty;
	public int m_depthThresholdShaderProperty;

	// Tweaking vars
	public float _depthThreshold = 0.1f;

	// Number of samples on an epiline
	public int _samplingAlongEpipolarLine = 256;

	// Minimum number of raymarch sampling along an epiline
	public int _raymarchSamplesAlongEpipolarLine = 32;
	public int _hEpipolarLines = 16;
	public int _vEpipolarLines = 16;

	// Debug Buffer

	public RenderTexture _debugTexture;
	public Material _debugCam;
	public Material _clearMat;

	void Awake()
	{
		int epipolarLineCount = 2*(_hEpipolarLines + _vEpipolarLines);

		// Buffers

		// Coordinates
		m_coordinatesTexture = new RenderTexture(_samplingAlongEpipolarLine,epipolarLineCount,0,
		                                         RenderTextureFormat.RGFloat);

		m_coordinatesTexture.filterMode = FilterMode.Point;
		m_coordinatesTexture.Create();

		// Depth
		m_depthTexture = new RenderTexture(_samplingAlongEpipolarLine,epipolarLineCount,0,
										   RenderTextureFormat.RFloat);
		
		m_depthTexture.filterMode = FilterMode.Point;
		m_depthTexture.Create();

		
		// Interpolation
		m_interpolationTexture = new RenderTexture(_samplingAlongEpipolarLine,epipolarLineCount,0,
		                                   		   RenderTextureFormat.RGFloat);
		
		m_interpolationTexture.filterMode = FilterMode.Point;
		m_interpolationTexture.Create();

        // Raymarch
        m_raymarchTexture = new RenderTexture(_samplingAlongEpipolarLine, epipolarLineCount, 24,
                                              RenderTextureFormat.ARGBFloat);

        m_raymarchTexture.filterMode = FilterMode.Bilinear;
        m_raymarchTexture.Create();

		// Materials

		m_coordinatesMat   = new Material(m_coordinateShader);
		m_interpolationMat = new Material(m_interpolationTextureShader);
        m_raymarchMat      = new Material(m_raymarchShader);

		_debugMat.SetTexture("_MainTex",m_coordinatesTexture);

		// Shader Properties Baking

		m_lightPosShaderProperty       = Shader.PropertyToID("_LightPos");
		m_coordTexSizeShaderProperty   = Shader.PropertyToID("_CoordTexSize");
		m_screenSizeShaderProperty     = Shader.PropertyToID("_ScreenSize");
		m_depthTextureShaderProperty   = Shader.PropertyToID("_DepthEpipolarTex");
		m_raymarchStepShaderProperty   = Shader.PropertyToID("_RaymarchStep");
		m_depthThresholdShaderProperty = Shader.PropertyToID("_DepthThreshold");

		// Debug

		_debugTexture = new RenderTexture(Screen.width, Screen.height,0,RenderTextureFormat.ARGBFloat);
		_debugTexture.enableRandomWrite = true;
		_debugTexture.filterMode = FilterMode.Point;
		_debugTexture.Create();

		_debugCam.SetTexture("_DebugTex",_debugTexture);
	}

	void OnRenderObject()
	{
		// Save current render target
		RenderBuffer depthBuffer = Graphics.activeDepthBuffer;
		RenderBuffer colorBuffer = Graphics.activeColorBuffer;

		m_coordinatesTexture.DiscardContents();
	
		// Clear Debug texture

		Graphics.SetRenderTarget(_debugTexture);
		_clearMat.SetPass(0);
		RenderQuad();

		//

		m_currentCamera = Camera.main;

		ComputeViewportLightPos();

		RenderCoordinatesEpipolar();
		RenderInterpolationTexture();
        Raymarch();

		Graphics.SetRenderTarget(colorBuffer,depthBuffer);
	}

	void ComputeViewportLightPos()
	{
		Vector3 vpLightPos = m_currentCamera.WorldToViewportPoint(this.transform.position);

		m_vpLightPos = vpLightPos;// new Vector4(vpLightPos.x*2.0f - 1.0f, vpLightPos.y*2.0f - 1.0f, 0.0f, 0.0f);

		m_lightOnScreen = (m_vpLightPos.x >= 0f && m_vpLightPos.x <= 1.0f &&
		                   m_vpLightPos.y >= 0f && m_vpLightPos.y <= 1.0f);

		SetKeyword(m_lightOnScreen, "AS_LIGHT_ON_SCREEN", "AS_LIGHT_OFF_SCREEN");
	}


	/// <summary>
	/// Renders the coordinate texture of epipolar samplings
	/// </summary>
	void RenderCoordinatesEpipolar()
	{
		// Update Coordinate Material

		Vector4 coordSize = new Vector4(m_coordinatesTexture.width, m_coordinatesTexture.height,
		                                _hEpipolarLines, _vEpipolarLines);

		Vector4 screenSize = new Vector4(Screen.width, Screen.height , 1.0f/Screen.width, 1.0f/Screen.height);

		m_coordinatesMat.SetVector(m_lightPosShaderProperty,m_vpLightPos);
		m_coordinatesMat.SetVector(m_coordTexSizeShaderProperty,coordSize);
		m_coordinatesMat.SetVector(m_screenSizeShaderProperty,screenSize);

		RenderBuffer[] colorBuffers = {m_coordinatesTexture.colorBuffer, m_depthTexture.colorBuffer};

		Graphics.SetRenderTarget(colorBuffers,m_depthTexture.depthBuffer);
		m_coordinatesMat.SetPass(0);

		RenderQuad();
	}

	void RenderInterpolationTexture()
	{
		Vector4 coordSize = new Vector4(m_interpolationTexture.width, m_interpolationTexture.height,
		                                _hEpipolarLines, _vEpipolarLines);
		
		Vector4 screenSize = new Vector4(Screen.width, Screen.height , 1.0f/Screen.width, 1.0f/Screen.height);
		
		m_interpolationMat.SetVector(m_lightPosShaderProperty,m_vpLightPos);
		m_interpolationMat.SetVector(m_coordTexSizeShaderProperty,coordSize);
		m_interpolationMat.SetVector(m_screenSizeShaderProperty,screenSize);
		m_interpolationMat.SetTexture(m_depthTextureShaderProperty, m_depthTexture);
		m_interpolationMat.SetInt(m_raymarchStepShaderProperty, _samplingAlongEpipolarLine/_raymarchSamplesAlongEpipolarLine);
		m_interpolationMat.SetFloat(m_depthThresholdShaderProperty,_depthThreshold);

		// Debug uniform
		m_interpolationMat.SetTexture("_DebugTex",_debugTexture);
		m_interpolationMat.SetVector("_DebugTexSize",new Vector4(_debugTexture.width,_debugTexture.height,
		                                                         1.0f/_debugTexture.width, 1.0f/_debugTexture.height ));
		m_interpolationMat.SetTexture("_CoordsTex",m_coordinatesTexture);

		// Debug
		Graphics.ClearRandomWriteTargets();
		Graphics.SetRandomWriteTarget(1, _debugTexture);

		Graphics.SetRenderTarget(m_interpolationTexture.colorBuffer,m_raymarchTexture.depthBuffer);

		// Call Clear pass to clear interpolation texture
		m_interpolationMat.SetPass(1);
		RenderQuad();

		// Generate interpolation texture
		m_interpolationMat.SetPass(0);
		RenderQuad();

		Graphics.ClearRandomWriteTargets();
	}

    void Raymarch()
    {
        Graphics.SetRenderTarget(m_raymarchTexture.colorBuffer,m_raymarchTexture.depthBuffer);

        // Clear Raymarch texture pass
        // Useful only for debug
        m_raymarchMat.SetPass(1);
        RenderQuad();
        
        m_raymarchMat.SetPass(0);
        RenderQuad();
    }

	void RenderQuad()
	{
		GL.Begin(GL.QUADS);
		GL.TexCoord2( 0, 0);
		GL.Vertex3	(-1,-1, 0);
		GL.TexCoord2( 0, 1);
		GL.Vertex3	(-1, 1, 0);
		GL.TexCoord2( 1, 1);
		GL.Vertex3	( 1, 1, 0);
		GL.TexCoord2( 1, 0);
		GL.Vertex3	( 1,-1, 0);
		GL.End();
	}

	void SetKeyword(bool firstOn, string firstKeyword, string secondKeyword)
	{
		Shader.EnableKeyword(firstOn ? firstKeyword : secondKeyword);
		Shader.DisableKeyword(firstOn ? secondKeyword : firstKeyword);
	}
}
