Shader "Custom/Clouds" {
	Properties {
		_PermTexture ("Noise", 2D) = "white" {}
		_T ("Time (used for animation)", Float) = 1
		_Tint ("Tint", Color) = (1, 1, 1, 1)
		_R1 ("Random (First Octave)", Float) = 1
		_R2 ("Random (Second Octave)", Float) = 1
		_R3 ("Random (Third Octave)", Float) = 1
		_R4 ("Random (Fourth Octave)", Float) = 1
		_R5 ("Random (Fifth Octave)", Float) = 1
		_R6 ("Random (Sixth Octave)", Float) = 1
	}
	SubShader {
		Tags { "Queue" = "Transparent" }
		Pass {
			Alphatest Greater 0
			Blend SrcColor OneMinusSrcColor
CGPROGRAM
#pragma target 3.0
#pragma vertex vert
#pragma fragment frag
#include "UnityCG.cginc"

sampler2D _PermTexture;
float4 _PermTexture_ST;
uniform float4 _Tint;
uniform float _T;
uniform float _R1;
uniform float _R2;
uniform float _R3;
uniform float _R4;
uniform float _R5;
uniform float _R6;

// 1 / 256 and 1 / 512
#define ONE 0.00390625
#define ONEHALF 0.001953125

float fade(float t) {
	return t*t*t*(t*(t*6.0-15.0)+10.0); // Improved fade, yields C2-continuous noise
}

// Note that these texture samples can be replaced with a noise function!
float noise(float2 P) {
	float2 Pi = ONE * floor(P) + ONEHALF;		// Integer part, scaled and offset for texture lookup
	float2 Pf = frac(P);						// Fractional part for interpolation

	// Noise contribution from lower left corner
	float2 grad00 = tex2D(_PermTexture, Pi).rg * 4.0 - 1.0;
	float n00 = dot(grad00, Pf);

	// Noise contribution from lower right corner
	float2 grad10 = tex2D(_PermTexture, Pi + float2(ONE, 0.0)).rg * 4.0 - 1.0;
	float n10 = dot(grad10, Pf - float2(1.0, 0.0));

	// Noise contribution from upper left corner
	float2 grad01 = tex2D(_PermTexture, Pi + float2(0.0, ONE)).rg * 4.0 - 1.0;
	float n01 = dot(grad01, Pf - float2(0.0, 1.0));

	// Noise contribution from upper right corner
	float2 grad11 = tex2D(_PermTexture, Pi + float2(ONE, ONE)).rg * 4.0 - 1.0;
	float n11 = dot(grad11, Pf - float2(1.0, 1.0));

	// Blend contributions along x
	float2 n_x = lerp(float2(n00, n01), float2(n10, n11), fade(Pf.x));

	// Blend contributions along y
	float n_xy = lerp(n_x.x, n_x.y, fade(Pf.y));

	// We're done, return the final noise value.
	return n_xy;
}

float fractalSum(float2 Q) {
	float value = 0;
	
	// add frequencies
	value += noise(Q / 4 + _R1) * 4;
	value += noise(Q + _R2);
	value += noise(Q * 2 + _R3) / 2;
	value += noise(Q * 4 + _R4) / 4;
	value += noise(Q * 8 + _R5) / 8;
	value += noise(Q * 16 + _R6) / 16;

	return value;
}

struct v2f {
	float4 pos : SV_POSITION;
	float2 uv : TEXCOORD0;
};

v2f vert(appdata_base v) {
	v2f o;
	o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
	o.uv = TRANSFORM_TEX(v.texcoord, _PermTexture);
	return o;
}

half4 frag(v2f i) : COLOR {
	float value = fractalSum((i.uv + float2(_T, _T))* 32 + 240);
	return half4(value, value, value, value) * _Tint;
}

ENDCG
		}
	} 
}
