Shader "MyTerrain/BumpTerrainHeightBlend"
{
   Properties{

	   	[HideInInspector] _TerrainHolesTexture("Holes Map (RGB)", 2D) = "white" {}
		// used in fallback on old cards & base map
		[HideInInspector] _MainTex("BaseMap (RGB) Trans (A)", 2D) = "white" {}
		[HideInInspector] _Color("Main Color", Color) = (1,1,1,1)

		_ControlCount("Control Maps", Range(1,4)) = 1

		[HideInInspector] _Control("Control (RGBA)", 2D) = "red" {}
		_Array1 ("_Array1", 2DArray) = "" {}
		_Array2 ("_Array2", 2DArray) = "" {}
		_Array3 ("_Array3", 2DArray) = "" {}
		_Array4 ("_Array4", 2DArray) = "" {}

		[HideInInspector] _Control2("Control 2 (RGBA)", 2D) = "red" {}
		_Array5 ("_Array5", 2DArray) = "" {}
		_Array6 ("_Array6", 2DArray) = "" {}
		_Array7 ("_Array7", 2DArray) = "" {}
		_Array8 ("_Array8", 2DArray) = "" {}

		[HideInInspector] _Control3("Control 3 (RGBA)", 2D) = "red" {}
		_Array9 ("_Array9", 2DArray) = "" {}
		_Array10 ("_Array10", 2DArray) = "" {}
		_Array11 ("_Array11", 2DArray) = "" {}
		_Array12 ("_Array12", 2DArray) = "" {}

		_TessMultiplier("Tesselation multiplier", Range(5,30)) = 10


		[Header(Terrain config)]
		_TWidth("Width", float) = 1000
		_THeight("Height", float) = 1000

		_TPosX("X position", float) = 0
		_TPosZ("Z position", float) = 0

		_Blending("Blending",  Range(0,0.75)) = 0.15

	}
		SubShader
			{
				CGPROGRAM

				#pragma target 5.0
				#pragma surface surf Standard vertex:vert tessellate:tess addshadow

				#include "UnityCG.cginc"
				#include "Tessellation.cginc"
		
				UNITY_DECLARE_TEX2D(_TerrainHolesTexture);

				uniform sampler2D _Control, _Control2, _Control3;
				float _ControlCount;

				UNITY_DECLARE_TEX2DARRAY(_Array1); 
				UNITY_DECLARE_TEX2DARRAY(_Array2); UNITY_DECLARE_TEX2DARRAY_NOSAMPLER(_Array3); UNITY_DECLARE_TEX2DARRAY_NOSAMPLER(_Array4);
				UNITY_DECLARE_TEX2DARRAY_NOSAMPLER(_Array5); UNITY_DECLARE_TEX2DARRAY_NOSAMPLER(_Array6); UNITY_DECLARE_TEX2DARRAY_NOSAMPLER(_Array7); UNITY_DECLARE_TEX2DARRAY_NOSAMPLER(_Array8);
				UNITY_DECLARE_TEX2DARRAY_NOSAMPLER(_Array9); UNITY_DECLARE_TEX2DARRAY_NOSAMPLER(_Array10); UNITY_DECLARE_TEX2DARRAY_NOSAMPLER(_Array11); UNITY_DECLARE_TEX2DARRAY_NOSAMPLER(_Array12);

				float _NormalScaleArray[12];
				float _BumpScaleArray[12];
				float4 _TileSizeArray[12];

				float _TWidth, _THeight, _TPosX, _TPosZ;
				float _TessMultiplier, _MinDistTesselation, _MaxDistTesselation;

				float _GlobalSnowAmount, _TerrainSnowBlendStrength, _TerrainSnowBlendPower;

				fixed4 _SnowFadeTiling;
				fixed4 _snowColor1, _snowColor2;
				float _Blending;

				sampler2D _TouchReact_Buffer;
				float4 _TouchReact_Pos;

				float4 _snowColorUpper, _snowColorBottom;

					struct appdata {
						float4 vertex    : POSITION;  // The vertex position in model space.
						float3 normal    : NORMAL;    // The vertex normal in model space.
						float4 texcoord  : TEXCOORD0; // The first UV coordinate.
						float4 texcoord1 : TEXCOORD1; // The second UV coordinate.
						float4 texcoord2 : TEXCOORD2; // The third UV coordinate.
						float4 tangent   : TANGENT;   // The tangent vector in Model Space (used for normal mapping).
						float4 color     : COLOR;     // Per-vertex color.
					};

					struct Input {
						float2 uv_TerrainHolesTexture;
						float2 uv_Control;
						float2 uv_Control2;
						float2 uv_Control3;
						float3 viewDir;
						float3 worldPos;
						float3 worldRefl;
						float3 worldNormal;
						float4 screenPos;

						float4 color : COLOR;
						INTERNAL_DATA
					};

					float4 tess(appdata v0, appdata v1, appdata v2) {
						return UnityDistanceBasedTess(v0.vertex, v1.vertex, v2.vertex, _MinDistTesselation, _MaxDistTesselation, _TessMultiplier);
					}

					float invLerp(float from, float to, float value) {
						return (value - from) / (to - from);
					}

					float remap(float origFrom, float origTo, float targetFrom, float targetTo, float value) {
						float rel = invLerp(origFrom, origTo, value);
						return lerp(targetFrom, targetTo, rel);
					}

					void vert(inout appdata v)
					{
						fixed4 splat_control = tex2Dlod(_Control, float4(v.texcoord.xy, 0, 0));
						float2 uv = v.texcoord.xy * fixed2(_TWidth, _THeight);
				
						float2 vertPos = uv + fixed2(_TPosX, _TPosZ);
						float2 tbPos = (float2(vertPos.x, -vertPos.y) - _TouchReact_Pos.xz) / _TouchReact_Pos.w;

						fixed4 touchBend = tex2Dlod(_TouchReact_Buffer, float4(tbPos.xy, 0, 0));

						float _snowDispMap = 0;		//SNOW TEXTURE DISPLACEMENT
						float _terrainDispMap = 0;	//TEXTURES DISPLACEMENT

						if (splat_control.r > touchBend.r) {

							//FIRST SPLAT RED CHANNEL IS SNOW
							_snowDispMap = (splat_control.r - touchBend.r) * _GlobalSnowAmount * UNITY_SAMPLE_TEX2DARRAY_LOD(_Array1, float3(uv / float2(_TileSizeArray[0].x, _TileSizeArray[0].y) + float2(_TileSizeArray[0].z, _TileSizeArray[0].w), 0), 3).r * _BumpScaleArray[0];
						}

						float mult = (1 - splat_control.r);
						if (mult > 0) {
							mult = 1 / mult;
						}

						//if 8 textures
						if (_ControlCount > 1) {
							float4 splat_control2 = tex2Dlod(_Control2, float4(v.texcoord.xy, 0, 0));

							//if 12 textures
							if (_ControlCount > 2) {
								float4 splat_control3 = tex2Dlod(_Control3, float4(v.texcoord.xy, 0, 0));

								_terrainDispMap += mult * splat_control3.r * UNITY_SAMPLE_TEX2DARRAY_SAMPLER_LOD(_Array9, _Array2, float3(uv / float2(_TileSizeArray[8].x, _TileSizeArray[8].y) + float2(_TileSizeArray[8].z, _TileSizeArray[8].w), 0), 3).r * _BumpScaleArray[8];
								_terrainDispMap += mult * splat_control3.g * UNITY_SAMPLE_TEX2DARRAY_SAMPLER_LOD(_Array10, _Array2, float3(uv / float2(_TileSizeArray[9].x, _TileSizeArray[9].y) + float2(_TileSizeArray[9].z, _TileSizeArray[9].w), 0), 3).r * _BumpScaleArray[9];
								_terrainDispMap += mult * splat_control3.b * UNITY_SAMPLE_TEX2DARRAY_SAMPLER_LOD(_Array11, _Array2, float3(uv / float2(_TileSizeArray[10].x, _TileSizeArray[10].y) + float2(_TileSizeArray[10].z, _TileSizeArray[10].w), 0), 3).r * _BumpScaleArray[10];
								_terrainDispMap += mult * splat_control3.a * UNITY_SAMPLE_TEX2DARRAY_SAMPLER_LOD(_Array12, _Array2, float3(uv / float2(_TileSizeArray[11].x, _TileSizeArray[11].y) + float2(_TileSizeArray[11].z, _TileSizeArray[11].w), 0), 3).r * _BumpScaleArray[11];
							}

							_terrainDispMap += mult * splat_control2.r * UNITY_SAMPLE_TEX2DARRAY_SAMPLER_LOD(_Array5, _Array2, float3(uv / float2(_TileSizeArray[4].x, _TileSizeArray[4].y) + float2(_TileSizeArray[4].z, _TileSizeArray[4].w), 0), 3).r * _BumpScaleArray[4];
							_terrainDispMap += mult * splat_control2.g * UNITY_SAMPLE_TEX2DARRAY_SAMPLER_LOD(_Array6, _Array2, float3(uv / float2(_TileSizeArray[5].x, _TileSizeArray[5].y) + float2(_TileSizeArray[5].z, _TileSizeArray[5].w), 0), 3).r * _BumpScaleArray[5];
							_terrainDispMap += mult * splat_control2.b * UNITY_SAMPLE_TEX2DARRAY_SAMPLER_LOD(_Array7, _Array2, float3(uv / float2(_TileSizeArray[6].x, _TileSizeArray[6].y) + float2(_TileSizeArray[6].z, _TileSizeArray[6].w), 0), 3).r * _BumpScaleArray[6];
							_terrainDispMap += mult * splat_control2.a * UNITY_SAMPLE_TEX2DARRAY_SAMPLER_LOD(_Array8, _Array2, float3(uv / float2(_TileSizeArray[7].x, _TileSizeArray[7].y) + float2(_TileSizeArray[7].z, _TileSizeArray[7].w), 0), 3).r * _BumpScaleArray[7];
						}

						_terrainDispMap += mult * splat_control.g * UNITY_SAMPLE_TEX2DARRAY_LOD(_Array2, float3(uv / float2(_TileSizeArray[1].x, _TileSizeArray[1].y) + float2(_TileSizeArray[1].z, _TileSizeArray[1].w), 0), 3).r * _BumpScaleArray[1];
						_terrainDispMap += mult * splat_control.b * UNITY_SAMPLE_TEX2DARRAY_SAMPLER_LOD(_Array3, _Array2, float3(uv / float2(_TileSizeArray[2].x, _TileSizeArray[2].y) + float2(_TileSizeArray[2].z, _TileSizeArray[2].w), 0), 3).r * _BumpScaleArray[2];
						_terrainDispMap += mult * splat_control.a * UNITY_SAMPLE_TEX2DARRAY_SAMPLER_LOD(_Array4, _Array2, float3(uv / float2(_TileSizeArray[3].x, _TileSizeArray[3].y) + float2(_TileSizeArray[3].z, _TileSizeArray[3].w), 0), 3).r * _BumpScaleArray[3];

						if (_terrainDispMap > _snowDispMap) {
							v.vertex.xyz += v.normal * _terrainDispMap;
						}
						else {
							v.vertex.xyz += v.normal * _snowDispMap;
						}

						v.color = float4 (_snowDispMap, _terrainDispMap, 0, 0);
					}

					void surf(Input IN, inout SurfaceOutputStandard o)
					{
						//HOLE 
						clip(UNITY_SAMPLE_TEX2D(_TerrainHolesTexture, IN.uv_TerrainHolesTexture).r == 0.0f ? -1 : 1);

						float2 tbPos = (float2(IN.worldPos.x, -IN.worldPos.z) - (_TouchReact_Pos.xz)) / _TouchReact_Pos.w;
						fixed4 touchBend = tex2D(_TouchReact_Buffer, tbPos);

						fixed4 snowHue = lerp(_snowColorUpper, _snowColorBottom, touchBend.r);

						fixed4 splat_control = tex2D(_Control, IN.uv_Control);
						fixed4 splat_control2 = tex2D(_Control2, IN.uv_Control2);
						fixed4 splat_control3 = tex2D(_Control3, IN.uv_Control3);

						float2 uv = IN.worldPos.xz;

						float _snowDispMap = IN.color.r;
						float _terrainDispMap = IN.color.g;

						fixed4 terrainSnowColor;
						fixed3 terrainSnowNormal;
						fixed4 terrainDataColor = fixed4(0,0,0,0);
						fixed3 terrainDataNormal = fixed3(0, 0, 0);

						//sum of splat must be 1
						float mult = (1 - splat_control.r);
						if (mult > 0) {
							mult = 1 / mult;
						}

						//Albedo
						terrainDataColor = mult * splat_control.g * UNITY_SAMPLE_TEX2DARRAY(_Array2, float3(uv / float2(_TileSizeArray[1].x, _TileSizeArray[1].y) + float2(_TileSizeArray[1].z, _TileSizeArray[1].w), 0));
						terrainDataColor += mult * splat_control.b * UNITY_SAMPLE_TEX2DARRAY_SAMPLER(_Array3, _Array2, float3(uv / float2(_TileSizeArray[2].x, _TileSizeArray[2].y) + float2(_TileSizeArray[2].z, _TileSizeArray[2].w), 0));
						terrainDataColor += mult * splat_control.a * UNITY_SAMPLE_TEX2DARRAY_SAMPLER(_Array4, _Array2, float3(uv / float2(_TileSizeArray[3].x, _TileSizeArray[3].y) + float2(_TileSizeArray[3].z, _TileSizeArray[3].w), 0));

						//Normal
						terrainDataNormal = mult * splat_control.g * UnpackScaleNormal(UNITY_SAMPLE_TEX2DARRAY_SAMPLER(_Array2, _Array2, float3(uv / float2(_TileSizeArray[1].x, _TileSizeArray[1].y) + float2(_TileSizeArray[1].z, _TileSizeArray[1].w), 1)), _NormalScaleArray[1]);
						terrainDataNormal += mult * splat_control.b * UnpackScaleNormal(UNITY_SAMPLE_TEX2DARRAY_SAMPLER(_Array3, _Array2, float3(uv / float2(_TileSizeArray[2].x, _TileSizeArray[2].y) + float2(_TileSizeArray[2].z, _TileSizeArray[2].w), 1)), _NormalScaleArray[2]);
						terrainDataNormal += mult * splat_control.a * UnpackScaleNormal(UNITY_SAMPLE_TEX2DARRAY_SAMPLER(_Array4, _Array2, float3(uv / float2(_TileSizeArray[3].x, _TileSizeArray[3].y) + float2(_TileSizeArray[3].z, _TileSizeArray[3].w), 1)), _NormalScaleArray[3]);


						if (_ControlCount > 1) {
							//Albedo
							terrainDataColor += mult * splat_control2.r * UNITY_SAMPLE_TEX2DARRAY_SAMPLER(_Array5, _Array2, float3(uv / float2(_TileSizeArray[4].x, _TileSizeArray[4].y) + float2(_TileSizeArray[4].z, _TileSizeArray[4].w), 0));
							terrainDataColor += mult * splat_control2.g * UNITY_SAMPLE_TEX2DARRAY_SAMPLER(_Array6, _Array2, float3(uv / float2(_TileSizeArray[5].x, _TileSizeArray[5].y) + float2(_TileSizeArray[5].z, _TileSizeArray[5].w), 0));
							terrainDataColor += mult * splat_control2.b * UNITY_SAMPLE_TEX2DARRAY_SAMPLER(_Array7, _Array2, float3(uv / float2(_TileSizeArray[6].x, _TileSizeArray[6].y) + float2(_TileSizeArray[6].z, _TileSizeArray[6].w), 0));
							terrainDataColor += mult * splat_control2.a * UNITY_SAMPLE_TEX2DARRAY_SAMPLER(_Array8, _Array2, float3(uv / float2(_TileSizeArray[7].x, _TileSizeArray[7].y) + float2(_TileSizeArray[7].z, _TileSizeArray[7].w), 0));

							//Normal
							terrainDataNormal += mult * splat_control2.r * UnpackScaleNormal(UNITY_SAMPLE_TEX2DARRAY_SAMPLER(_Array5, _Array2, float3(uv / float2(_TileSizeArray[4].x, _TileSizeArray[4].y) + float2(_TileSizeArray[4].z, _TileSizeArray[4].w), 1)), _NormalScaleArray[4]);
							terrainDataNormal += mult * splat_control2.g * UnpackScaleNormal(UNITY_SAMPLE_TEX2DARRAY_SAMPLER(_Array6, _Array2, float3(uv / float2(_TileSizeArray[5].x, _TileSizeArray[5].y) + float2(_TileSizeArray[5].z, _TileSizeArray[5].w), 1)), _NormalScaleArray[5]);
							terrainDataNormal += mult * splat_control2.b * UnpackScaleNormal(UNITY_SAMPLE_TEX2DARRAY_SAMPLER(_Array7, _Array2, float3(uv / float2(_TileSizeArray[6].x, _TileSizeArray[6].y) + float2(_TileSizeArray[6].z, _TileSizeArray[6].w), 1)), _NormalScaleArray[6]);
							terrainDataNormal += mult * splat_control2.a * UnpackScaleNormal(UNITY_SAMPLE_TEX2DARRAY_SAMPLER(_Array8, _Array2, float3(uv / float2(_TileSizeArray[7].x, _TileSizeArray[7].y) + float2(_TileSizeArray[7].z, _TileSizeArray[7].w), 1)), _NormalScaleArray[7]);
						
							if (_ControlCount > 2) {
								//Albedo
								terrainDataColor += mult * splat_control3.r * UNITY_SAMPLE_TEX2DARRAY_SAMPLER(_Array9, _Array2, float3(uv / float2(_TileSizeArray[8].x, _TileSizeArray[8].y) + float2(_TileSizeArray[8].z, _TileSizeArray[8].w), 0));
								terrainDataColor += mult * splat_control3.g * UNITY_SAMPLE_TEX2DARRAY_SAMPLER(_Array10, _Array2, float3(uv / float2(_TileSizeArray[9].x, _TileSizeArray[9].y) + float2(_TileSizeArray[9].z, _TileSizeArray[9].w), 0));
								terrainDataColor += mult * splat_control3.b * UNITY_SAMPLE_TEX2DARRAY_SAMPLER(_Array11, _Array2, float3(uv / float2(_TileSizeArray[10].x, _TileSizeArray[10].y) + float2(_TileSizeArray[10].z, _TileSizeArray[10].w), 0));
								terrainDataColor += mult * splat_control3.a * UNITY_SAMPLE_TEX2DARRAY_SAMPLER(_Array12, _Array2, float3(uv / float2(_TileSizeArray[11].x, _TileSizeArray[11].y) + float2(_TileSizeArray[11].z, _TileSizeArray[11].w), 0));

								//Normal
								terrainDataNormal += mult * splat_control3.r * UnpackScaleNormal(UNITY_SAMPLE_TEX2DARRAY_SAMPLER(_Array9, _Array2, float3(uv / float2(_TileSizeArray[8].x, _TileSizeArray[8].y) + float2(_TileSizeArray[8].z, _TileSizeArray[8].w), 1)), _NormalScaleArray[8]);
								terrainDataNormal += mult * splat_control3.g * UnpackScaleNormal(UNITY_SAMPLE_TEX2DARRAY_SAMPLER(_Array10, _Array2, float3(uv / float2(_TileSizeArray[9].x, _TileSizeArray[9].y) + float2(_TileSizeArray[9].z, _TileSizeArray[9].w), 1)), _NormalScaleArray[9]);
								terrainDataNormal += mult * splat_control3.b * UnpackScaleNormal(UNITY_SAMPLE_TEX2DARRAY_SAMPLER(_Array11, _Array2, float3(uv / float2(_TileSizeArray[10].x, _TileSizeArray[10].y) + float2(_TileSizeArray[10].z, _TileSizeArray[10].w), 1)), _NormalScaleArray[10]);
								terrainDataNormal += mult * splat_control3.a * UnpackScaleNormal(UNITY_SAMPLE_TEX2DARRAY_SAMPLER(_Array12, _Array2, float3(uv / float2(_TileSizeArray[11].x, _TileSizeArray[11].y) + float2(_TileSizeArray[11].z, _TileSizeArray[11].w), 1)), _NormalScaleArray[11]);
							}
						}

						//Albedo
						terrainSnowColor = UNITY_SAMPLE_TEX2DARRAY_SAMPLER(_Array1, _Array1, float3(uv / float2(_TileSizeArray[0].x, _TileSizeArray[0].y) + float2(_TileSizeArray[0].z, _TileSizeArray[0].w), 0));
						terrainSnowColor *= snowHue;
						//Normal
						terrainSnowNormal = UnpackScaleNormal(UNITY_SAMPLE_TEX2DARRAY_SAMPLER(_Array1, _Array2, float3(uv / float2(_TileSizeArray[0].x, _TileSizeArray[0].y) + float2(_TileSizeArray[0].z, _TileSizeArray[0].w), 1)), _NormalScaleArray[0]);
				
						if (_terrainDispMap > _snowDispMap) {
							float difference = abs(log(clamp(0.1, 1, (_terrainDispMap - _snowDispMap) / (splat_control.r + 0.1) / (_TerrainSnowBlendStrength + 0.25))));

							o.Albedo = lerp(terrainDataColor, terrainSnowColor, clamp(0, 1, difference));
							o.Normal = lerp(terrainDataNormal, terrainSnowNormal, clamp(0, 1, difference));
						}
						else {
							o.Albedo = terrainSnowColor;
							o.Normal = terrainSnowNormal;
						}
					}
					ENDCG
			}

		Dependency "BaseMapShader" = "Diffuse"

		FallBack "Diffuse"
}
