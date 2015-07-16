﻿Shader "EVE/Ocean" {
	Properties {
		_SurfaceColor ("Color Tint", Color) = (1,1,1,1)
		_SpecColor ("Specular tint", Color) = (1,1,1,1)
		_Shininess ("Shininess", Float) = 10
		_MainTex ("Main (RGB)", 2D) = "white" {}
		_DetailTex ("Detail (RGB)", 2D) = "white" {}
		_DetailScale ("Detail Scale", Range(0,1000)) = 200
		_DetailDist ("Detail Distance", Range(0,1)) = 0.00875
		_MinLight ("Minimum Light", Range(0,1)) = .5
		_LightPower ("LightPower", Float) = 1.75
		_PlanetOpacity ("PlanetOpacity", Float) = 1
		_PlanetOrigin ("Planet Center", Vector) = (0,0,0,1)
	}
	
SubShader {

Tags { "Queue"="AlphaTest" "RenderType"="TransparentCutout"}
	Blend SrcAlpha OneMinusSrcAlpha
	Fog { Mode Global}
	AlphaTest Greater 0
	ColorMask RGB
	Cull Back Lighting On
		
		//surface
		Pass {
		Lighting On
		ZWrite On
		Tags { "LightMode"="ForwardBase"}
		
		Program "vp" {
// Vertex combos: 15
//   d3d9 - ALU: 19 to 29
SubProgram "opengl " {
Keywords { "POINT" "SHADOWS_OFF" }
"!!GLSL
#ifdef VERTEX
varying vec3 xlv_TEXCOORD5;
varying vec3 xlv_TEXCOORD3;
varying vec3 xlv_TEXCOORD2;
varying vec3 xlv_TEXCOORD1;
varying float xlv_TEXCOORD0;
uniform mat4 _LightMatrix0;
uniform mat4 _Object2World;

uniform vec3 _WorldSpaceCameraPos;
void main ()
{
  vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * gl_Vertex).xyz;
  vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  vec4 tmpvar_3;
  tmpvar_3.x = gl_MultiTexCoord0.x;
  tmpvar_3.y = gl_MultiTexCoord0.y;
  tmpvar_3.z = gl_MultiTexCoord1.x;
  tmpvar_3.w = gl_MultiTexCoord1.y;
  gl_Position = (gl_ModelViewProjectionMatrix * gl_Vertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * gl_Vertex)).xyz;
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}


#endif
#ifdef FRAGMENT
#extension GL_ARB_shader_texture_lod : enable
varying vec3 xlv_TEXCOORD5;
varying vec3 xlv_TEXCOORD3;
varying vec3 xlv_TEXCOORD2;
varying vec3 xlv_TEXCOORD1;
varying float xlv_TEXCOORD0;
uniform vec3 _PlanetOrigin;
uniform float _PlanetOpacity;
uniform float _DetailDist;
uniform float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform float _Shininess;
uniform vec4 _SurfaceColor;
uniform vec4 _SpecColor;
uniform vec4 _LightColor0;
uniform sampler2D _LightTexture0;
uniform vec4 _WorldSpaceLightPos0;
void main ()
{
  vec4 main_1;
  vec4 color_2;
  vec3 tmpvar_3;
  tmpvar_3 = normalize(xlv_TEXCOORD5);
  vec2 uv_4;
  float r_5;
  if ((abs(tmpvar_3.z) > (1e-08 * abs(tmpvar_3.x)))) {
    float y_over_x_6;
    y_over_x_6 = (tmpvar_3.x / tmpvar_3.z);
    float s_7;
    float x_8;
    x_8 = (y_over_x_6 * inversesqrt(((y_over_x_6 * y_over_x_6) + 1.0)));
    s_7 = (sign(x_8) * (1.5708 - (sqrt((1.0 - abs(x_8))) * (1.5708 + (abs(x_8) * (-0.214602 + (abs(x_8) * (0.0865667 + (abs(x_8) * -0.0310296)))))))));
    r_5 = s_7;
    if ((tmpvar_3.z < 0.0)) {
      if ((tmpvar_3.x >= 0.0)) {
        r_5 = (s_7 + 3.14159);
      } else {
        r_5 = (r_5 - 3.14159);
      };
    };
  } else {
    r_5 = (sign(tmpvar_3.x) * 1.5708);
  };
  uv_4.x = (0.5 + (0.159155 * r_5));
  uv_4.y = (0.31831 * (1.5708 - (sign(tmpvar_3.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_3.y))) * (1.5708 + (abs(tmpvar_3.y) * (-0.214602 + (abs(tmpvar_3.y) * (0.0865667 + (abs(tmpvar_3.y) * -0.0310296)))))))))));
  vec2 tmpvar_9;
  tmpvar_9 = dFdx(tmpvar_3.xz);
  vec2 tmpvar_10;
  tmpvar_10 = dFdy(tmpvar_3.xz);
  vec4 tmpvar_11;
  tmpvar_11.x = (0.159155 * sqrt(dot (tmpvar_9, tmpvar_9)));
  tmpvar_11.y = dFdx(uv_4.y);
  tmpvar_11.z = (0.159155 * sqrt(dot (tmpvar_10, tmpvar_10)));
  tmpvar_11.w = dFdy(uv_4.y);
  main_1 = texture2DGradARB (_MainTex, uv_4, tmpvar_11.xy, tmpvar_11.zw);
  vec3 tmpvar_12;
  tmpvar_12 = normalize(xlv_TEXCOORD5);
  vec2 uv_13;
  float r_14;
  if ((abs(tmpvar_12.z) > (1e-08 * abs(tmpvar_12.x)))) {
    float y_over_x_15;
    y_over_x_15 = (tmpvar_12.x / tmpvar_12.z);
    float s_16;
    float x_17;
    x_17 = (y_over_x_15 * inversesqrt(((y_over_x_15 * y_over_x_15) + 1.0)));
    s_16 = (sign(x_17) * (1.5708 - (sqrt((1.0 - abs(x_17))) * (1.5708 + (abs(x_17) * (-0.214602 + (abs(x_17) * (0.0865667 + (abs(x_17) * -0.0310296)))))))));
    r_14 = s_16;
    if ((tmpvar_12.z < 0.0)) {
      if ((tmpvar_12.x >= 0.0)) {
        r_14 = (s_16 + 3.14159);
      } else {
        r_14 = (r_14 - 3.14159);
      };
    };
  } else {
    r_14 = (sign(tmpvar_12.x) * 1.5708);
  };
  uv_13.x = (0.5 + (0.159155 * r_14));
  uv_13.y = (0.31831 * (1.5708 - (sign(tmpvar_12.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_12.y))) * (1.5708 + (abs(tmpvar_12.y) * (-0.214602 + (abs(tmpvar_12.y) * (0.0865667 + (abs(tmpvar_12.y) * -0.0310296)))))))))));
  vec2 tmpvar_18;
  tmpvar_18 = ((uv_13 * 4.0) * _DetailScale);
  vec2 tmpvar_19;
  tmpvar_19 = dFdx(tmpvar_12.xz);
  vec2 tmpvar_20;
  tmpvar_20 = dFdy(tmpvar_12.xz);
  vec4 tmpvar_21;
  tmpvar_21.x = (0.159155 * sqrt(dot (tmpvar_19, tmpvar_19)));
  tmpvar_21.y = dFdx(tmpvar_18.y);
  tmpvar_21.z = (0.159155 * sqrt(dot (tmpvar_20, tmpvar_20)));
  tmpvar_21.w = dFdy(tmpvar_18.y);
  vec3 tmpvar_22;
  tmpvar_22 = abs(tmpvar_12);
  float tmpvar_23;
  tmpvar_23 = float((tmpvar_22.z >= tmpvar_22.x));
  vec3 tmpvar_24;
  tmpvar_24 = mix (tmpvar_22.yxz, mix (tmpvar_22, tmpvar_22.zxy, vec3(tmpvar_23)), vec3(float((mix (tmpvar_22.x, tmpvar_22.z, tmpvar_23) >= tmpvar_22.y))));
  color_2.w = _SurfaceColor.w;
  color_2.xyz = (_SurfaceColor.xyz + (0.5 * mix ((texture2DGradARB (_DetailTex, (((0.5 * tmpvar_24.zy) / abs(tmpvar_24.x)) * _DetailScale), tmpvar_21.xy, tmpvar_21.zw).xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0)))));
  float tmpvar_25;
  tmpvar_25 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  color_2.xyz = mix (color_2.xyz, main_1.xyz, vec3(tmpvar_25));
  vec3 tmpvar_26;
  tmpvar_26 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  float atten_27;
  atten_27 = texture2D (_LightTexture0, vec2(dot (xlv_TEXCOORD3, xlv_TEXCOORD3))).w;
  vec4 c_28;
  vec3 tmpvar_29;
  tmpvar_29 = normalize(normalize(_WorldSpaceLightPos0).xyz);
  float tmpvar_30;
  tmpvar_30 = dot (tmpvar_26, tmpvar_29);
  c_28.xyz = ((((color_2.xyz * _LightColor0.xyz) * tmpvar_30) + ((_LightColor0.xyz * _SpecColor.xyz) * (pow (clamp (dot (normalize((tmpvar_29 + normalize(xlv_TEXCOORD1))), tmpvar_26), 0.0, 1.0), (_Shininess * 128.0)) * _SurfaceColor.w))) * (atten_27 * 4.0));
  c_28.w = (tmpvar_30 * (atten_27 * 4.0));
  color_2.w = mix (1.0, _SurfaceColor.w, clamp ((c_28.w * 4.0), 0.0, 1.0));
  vec3 arg0_31;
  arg0_31 = (2.0 * color_2.xyz);
  color_2.w = mix (color_2.w, 1.0, clamp ((sqrt(dot (c_28.xyz, c_28.xyz)) - sqrt(dot (arg0_31, arg0_31))), 0.0, 1.0));
  color_2.w = mix (color_2.w, 1.0, tmpvar_25);
  color_2.xyz = c_28.xyz;
  gl_FragData[0] = color_2;
}


#endif
"
}

SubProgram "d3d9 " {
Keywords { "POINT" "SHADOWS_OFF" }
Bind "vertex" Vertex
Bind "texcoord" TexCoord0
Bind "texcoord1" TexCoord1
Matrix 0 [glstate_matrix_mvp]
Vector 12 [_WorldSpaceCameraPos]
Matrix 4 [_Object2World]
Matrix 8 [_LightMatrix0]
"vs_3_0
; 24 ALU
dcl_position o0
dcl_texcoord0 o1
dcl_texcoord1 o2
dcl_texcoord2 o3
dcl_texcoord3 o4
dcl_texcoord5 o5
dcl_position0 v0
dcl_texcoord0 v1
dcl_texcoord1 v2
mov r1.zw, v2.xyxy
mov r1.xy, v1
dp4 r0.w, r1, r1
rsq r1.w, r0.w
mul r1.xyz, r1.w, r1
dp4 r0.z, v0, c6
dp4 r0.x, v0, c4
dp4 r0.y, v0, c5
add r2.xyz, -r0, c12
dp3 r0.w, r2, r2
rsq r0.w, r0.w
mov o5.xyz, -r1
mov r1.xyz, r0
dp4 r1.w, v0, c7
mul o2.xyz, r0.w, r2
dp4 o4.z, r1, c10
dp4 o4.y, r1, c9
dp4 o4.x, r1, c8
rcp o1.x, r0.w
mov o3.xyz, r0
dp4 o0.w, v0, c3
dp4 o0.z, v0, c2
dp4 o0.y, v0, c1
dp4 o0.x, v0, c0
"
}

SubProgram "gles " {
Keywords { "POINT" "SHADOWS_OFF" }
"!!GLES


#ifdef VERTEX

varying highp vec3 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp mat4 _LightMatrix0;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_mvp;
uniform highp vec3 _WorldSpaceCameraPos;
attribute vec4 _glesMultiTexCoord1;
attribute vec4 _glesMultiTexCoord0;
attribute vec4 _glesVertex;
void main ()
{
  highp vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * _glesVertex).xyz;
  highp vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  highp vec4 tmpvar_3;
  tmpvar_3.x = _glesMultiTexCoord0.x;
  tmpvar_3.y = _glesMultiTexCoord0.y;
  tmpvar_3.z = _glesMultiTexCoord1.x;
  tmpvar_3.w = _glesMultiTexCoord1.y;
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * _glesVertex)).xyz;
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}



#endif
#ifdef FRAGMENT

#extension GL_EXT_shader_texture_lod : enable
#extension GL_OES_standard_derivatives : enable
varying highp vec3 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp vec3 _PlanetOrigin;
uniform highp float _PlanetOpacity;
uniform highp float _DetailDist;
uniform highp float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform highp float _Shininess;
uniform lowp vec4 _SurfaceColor;
uniform lowp vec4 _SpecColor;
uniform lowp vec4 _LightColor0;
uniform sampler2D _LightTexture0;
uniform highp vec4 _WorldSpaceLightPos0;
void main ()
{
  lowp vec4 tmpvar_1;
  mediump vec4 specColor_2;
  mediump float handoff_3;
  mediump float detailLevel_4;
  mediump vec4 color_5;
  mediump vec4 tex_6;
  highp vec3 tmpvar_7;
  tmpvar_7 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_8;
  highp float r_9;
  if ((abs(tmpvar_7.z) > (1e-08 * abs(tmpvar_7.x)))) {
    highp float y_over_x_10;
    y_over_x_10 = (tmpvar_7.x / tmpvar_7.z);
    highp float s_11;
    highp float x_12;
    x_12 = (y_over_x_10 * inversesqrt(((y_over_x_10 * y_over_x_10) + 1.0)));
    s_11 = (sign(x_12) * (1.5708 - (sqrt((1.0 - abs(x_12))) * (1.5708 + (abs(x_12) * (-0.214602 + (abs(x_12) * (0.0865667 + (abs(x_12) * -0.0310296)))))))));
    r_9 = s_11;
    if ((tmpvar_7.z < 0.0)) {
      if ((tmpvar_7.x >= 0.0)) {
        r_9 = (s_11 + 3.14159);
      } else {
        r_9 = (r_9 - 3.14159);
      };
    };
  } else {
    r_9 = (sign(tmpvar_7.x) * 1.5708);
  };
  uv_8.x = (0.5 + (0.159155 * r_9));
  uv_8.y = (0.31831 * (1.5708 - (sign(tmpvar_7.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_7.y))) * (1.5708 + (abs(tmpvar_7.y) * (-0.214602 + (abs(tmpvar_7.y) * (0.0865667 + (abs(tmpvar_7.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_13;
  tmpvar_13 = dFdx(tmpvar_7.xz);
  highp vec2 tmpvar_14;
  tmpvar_14 = dFdy(tmpvar_7.xz);
  highp vec4 tmpvar_15;
  tmpvar_15.x = (0.159155 * sqrt(dot (tmpvar_13, tmpvar_13)));
  tmpvar_15.y = dFdx(uv_8.y);
  tmpvar_15.z = (0.159155 * sqrt(dot (tmpvar_14, tmpvar_14)));
  tmpvar_15.w = dFdy(uv_8.y);
  lowp vec4 tmpvar_16;
  tmpvar_16 = texture2DGradEXT (_MainTex, uv_8, tmpvar_15.xy, tmpvar_15.zw);
  tex_6 = tmpvar_16;
  mediump vec4 tmpvar_17;
  mediump vec3 detailCoords_18;
  mediump float nylerp_19;
  mediump float zxlerp_20;
  highp vec3 tmpvar_21;
  tmpvar_21 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_22;
  highp float r_23;
  if ((abs(tmpvar_21.z) > (1e-08 * abs(tmpvar_21.x)))) {
    highp float y_over_x_24;
    y_over_x_24 = (tmpvar_21.x / tmpvar_21.z);
    highp float s_25;
    highp float x_26;
    x_26 = (y_over_x_24 * inversesqrt(((y_over_x_24 * y_over_x_24) + 1.0)));
    s_25 = (sign(x_26) * (1.5708 - (sqrt((1.0 - abs(x_26))) * (1.5708 + (abs(x_26) * (-0.214602 + (abs(x_26) * (0.0865667 + (abs(x_26) * -0.0310296)))))))));
    r_23 = s_25;
    if ((tmpvar_21.z < 0.0)) {
      if ((tmpvar_21.x >= 0.0)) {
        r_23 = (s_25 + 3.14159);
      } else {
        r_23 = (r_23 - 3.14159);
      };
    };
  } else {
    r_23 = (sign(tmpvar_21.x) * 1.5708);
  };
  uv_22.x = (0.5 + (0.159155 * r_23));
  uv_22.y = (0.31831 * (1.5708 - (sign(tmpvar_21.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_21.y))) * (1.5708 + (abs(tmpvar_21.y) * (-0.214602 + (abs(tmpvar_21.y) * (0.0865667 + (abs(tmpvar_21.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_27;
  tmpvar_27 = ((uv_22 * 4.0) * _DetailScale);
  highp vec2 tmpvar_28;
  tmpvar_28 = dFdx(tmpvar_21.xz);
  highp vec2 tmpvar_29;
  tmpvar_29 = dFdy(tmpvar_21.xz);
  highp vec4 tmpvar_30;
  tmpvar_30.x = (0.159155 * sqrt(dot (tmpvar_28, tmpvar_28)));
  tmpvar_30.y = dFdx(tmpvar_27.y);
  tmpvar_30.z = (0.159155 * sqrt(dot (tmpvar_29, tmpvar_29)));
  tmpvar_30.w = dFdy(tmpvar_27.y);
  highp vec3 tmpvar_31;
  tmpvar_31 = abs(tmpvar_21);
  highp float tmpvar_32;
  tmpvar_32 = float((tmpvar_31.z >= tmpvar_31.x));
  zxlerp_20 = tmpvar_32;
  highp float tmpvar_33;
  tmpvar_33 = float((mix (tmpvar_31.x, tmpvar_31.z, zxlerp_20) >= tmpvar_31.y));
  nylerp_19 = tmpvar_33;
  highp vec3 tmpvar_34;
  tmpvar_34 = mix (tmpvar_31, tmpvar_31.zxy, vec3(zxlerp_20));
  detailCoords_18 = tmpvar_34;
  highp vec3 tmpvar_35;
  tmpvar_35 = mix (tmpvar_31.yxz, detailCoords_18, vec3(nylerp_19));
  detailCoords_18 = tmpvar_35;
  mediump float tmpvar_36;
  tmpvar_36 = abs(detailCoords_18.x);
  highp vec2 coord_37;
  coord_37 = (((0.5 * detailCoords_18.zy) / tmpvar_36) * _DetailScale);
  lowp vec4 tmpvar_38;
  tmpvar_38 = texture2DGradEXT (_DetailTex, coord_37, tmpvar_30.xy, tmpvar_30.zw);
  tmpvar_17 = tmpvar_38;
  color_5 = _SurfaceColor;
  highp float tmpvar_39;
  tmpvar_39 = clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0);
  detailLevel_4 = tmpvar_39;
  color_5.xyz = (color_5.xyz + (0.5 * mix ((tmpvar_17.xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(detailLevel_4))));
  highp float tmpvar_40;
  tmpvar_40 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  handoff_3 = tmpvar_40;
  color_5.xyz = mix (color_5.xyz, tex_6.xyz, vec3(handoff_3));
  specColor_2.xyz = _SpecColor.xyz;
  specColor_2.w = mix (1.0, tex_6.w, handoff_3);
  highp vec3 tmpvar_41;
  tmpvar_41 = normalize(_WorldSpaceLightPos0).xyz;
  highp vec3 tmpvar_42;
  tmpvar_42 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  highp float tmpvar_43;
  tmpvar_43 = dot (xlv_TEXCOORD3, xlv_TEXCOORD3);
  lowp vec4 tmpvar_44;
  tmpvar_44 = texture2D (_LightTexture0, vec2(tmpvar_43));
  mediump vec3 lightDir_45;
  lightDir_45 = tmpvar_41;
  mediump vec3 viewDir_46;
  viewDir_46 = xlv_TEXCOORD1;
  mediump vec3 normal_47;
  normal_47 = tmpvar_42;
  mediump float atten_48;
  atten_48 = tmpvar_44.w;
  mediump vec4 c_49;
  highp float nh_50;
  mediump vec3 tmpvar_51;
  tmpvar_51 = normalize(lightDir_45);
  lightDir_45 = tmpvar_51;
  mediump vec3 tmpvar_52;
  tmpvar_52 = normalize(viewDir_46);
  viewDir_46 = tmpvar_52;
  mediump float tmpvar_53;
  tmpvar_53 = dot (normal_47, tmpvar_51);
  mediump float tmpvar_54;
  tmpvar_54 = clamp (dot (normalize((tmpvar_51 + tmpvar_52)), normal_47), 0.0, 1.0);
  nh_50 = tmpvar_54;
  highp vec3 tmpvar_55;
  tmpvar_55 = ((((color_5.xyz * _LightColor0.xyz) * tmpvar_53) + ((_LightColor0.xyz * specColor_2.xyz) * (pow (nh_50, (_Shininess * 128.0)) * color_5.w))) * (atten_48 * 4.0));
  c_49.xyz = tmpvar_55;
  c_49.w = (tmpvar_53 * (atten_48 * 4.0));
  color_5.w = mix (1.0, color_5.w, clamp ((c_49.w * 4.0), 0.0, 1.0));
  mediump vec3 arg0_56;
  arg0_56 = (2.0 * color_5.xyz);
  color_5.w = mix (color_5.w, 1.0, clamp ((sqrt(dot (c_49.xyz, c_49.xyz)) - sqrt(dot (arg0_56, arg0_56))), 0.0, 1.0));
  color_5.w = mix (color_5.w, 1.0, handoff_3);
  color_5.xyz = c_49.xyz;
  tmpvar_1 = color_5;
  gl_FragData[0] = tmpvar_1;
}



#endif"
}

SubProgram "glesdesktop " {
Keywords { "POINT" "SHADOWS_OFF" }
"!!GLES


#ifdef VERTEX

varying highp vec3 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp mat4 _LightMatrix0;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_mvp;
uniform highp vec3 _WorldSpaceCameraPos;
attribute vec4 _glesMultiTexCoord1;
attribute vec4 _glesMultiTexCoord0;
attribute vec4 _glesVertex;
void main ()
{
  highp vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * _glesVertex).xyz;
  highp vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  highp vec4 tmpvar_3;
  tmpvar_3.x = _glesMultiTexCoord0.x;
  tmpvar_3.y = _glesMultiTexCoord0.y;
  tmpvar_3.z = _glesMultiTexCoord1.x;
  tmpvar_3.w = _glesMultiTexCoord1.y;
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * _glesVertex)).xyz;
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}



#endif
#ifdef FRAGMENT

#extension GL_EXT_shader_texture_lod : enable
#extension GL_OES_standard_derivatives : enable
varying highp vec3 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp vec3 _PlanetOrigin;
uniform highp float _PlanetOpacity;
uniform highp float _DetailDist;
uniform highp float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform highp float _Shininess;
uniform lowp vec4 _SurfaceColor;
uniform lowp vec4 _SpecColor;
uniform lowp vec4 _LightColor0;
uniform sampler2D _LightTexture0;
uniform highp vec4 _WorldSpaceLightPos0;
void main ()
{
  lowp vec4 tmpvar_1;
  mediump vec4 specColor_2;
  mediump float handoff_3;
  mediump float detailLevel_4;
  mediump vec4 color_5;
  mediump vec4 tex_6;
  highp vec3 tmpvar_7;
  tmpvar_7 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_8;
  highp float r_9;
  if ((abs(tmpvar_7.z) > (1e-08 * abs(tmpvar_7.x)))) {
    highp float y_over_x_10;
    y_over_x_10 = (tmpvar_7.x / tmpvar_7.z);
    highp float s_11;
    highp float x_12;
    x_12 = (y_over_x_10 * inversesqrt(((y_over_x_10 * y_over_x_10) + 1.0)));
    s_11 = (sign(x_12) * (1.5708 - (sqrt((1.0 - abs(x_12))) * (1.5708 + (abs(x_12) * (-0.214602 + (abs(x_12) * (0.0865667 + (abs(x_12) * -0.0310296)))))))));
    r_9 = s_11;
    if ((tmpvar_7.z < 0.0)) {
      if ((tmpvar_7.x >= 0.0)) {
        r_9 = (s_11 + 3.14159);
      } else {
        r_9 = (r_9 - 3.14159);
      };
    };
  } else {
    r_9 = (sign(tmpvar_7.x) * 1.5708);
  };
  uv_8.x = (0.5 + (0.159155 * r_9));
  uv_8.y = (0.31831 * (1.5708 - (sign(tmpvar_7.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_7.y))) * (1.5708 + (abs(tmpvar_7.y) * (-0.214602 + (abs(tmpvar_7.y) * (0.0865667 + (abs(tmpvar_7.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_13;
  tmpvar_13 = dFdx(tmpvar_7.xz);
  highp vec2 tmpvar_14;
  tmpvar_14 = dFdy(tmpvar_7.xz);
  highp vec4 tmpvar_15;
  tmpvar_15.x = (0.159155 * sqrt(dot (tmpvar_13, tmpvar_13)));
  tmpvar_15.y = dFdx(uv_8.y);
  tmpvar_15.z = (0.159155 * sqrt(dot (tmpvar_14, tmpvar_14)));
  tmpvar_15.w = dFdy(uv_8.y);
  lowp vec4 tmpvar_16;
  tmpvar_16 = texture2DGradEXT (_MainTex, uv_8, tmpvar_15.xy, tmpvar_15.zw);
  tex_6 = tmpvar_16;
  mediump vec4 tmpvar_17;
  mediump vec3 detailCoords_18;
  mediump float nylerp_19;
  mediump float zxlerp_20;
  highp vec3 tmpvar_21;
  tmpvar_21 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_22;
  highp float r_23;
  if ((abs(tmpvar_21.z) > (1e-08 * abs(tmpvar_21.x)))) {
    highp float y_over_x_24;
    y_over_x_24 = (tmpvar_21.x / tmpvar_21.z);
    highp float s_25;
    highp float x_26;
    x_26 = (y_over_x_24 * inversesqrt(((y_over_x_24 * y_over_x_24) + 1.0)));
    s_25 = (sign(x_26) * (1.5708 - (sqrt((1.0 - abs(x_26))) * (1.5708 + (abs(x_26) * (-0.214602 + (abs(x_26) * (0.0865667 + (abs(x_26) * -0.0310296)))))))));
    r_23 = s_25;
    if ((tmpvar_21.z < 0.0)) {
      if ((tmpvar_21.x >= 0.0)) {
        r_23 = (s_25 + 3.14159);
      } else {
        r_23 = (r_23 - 3.14159);
      };
    };
  } else {
    r_23 = (sign(tmpvar_21.x) * 1.5708);
  };
  uv_22.x = (0.5 + (0.159155 * r_23));
  uv_22.y = (0.31831 * (1.5708 - (sign(tmpvar_21.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_21.y))) * (1.5708 + (abs(tmpvar_21.y) * (-0.214602 + (abs(tmpvar_21.y) * (0.0865667 + (abs(tmpvar_21.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_27;
  tmpvar_27 = ((uv_22 * 4.0) * _DetailScale);
  highp vec2 tmpvar_28;
  tmpvar_28 = dFdx(tmpvar_21.xz);
  highp vec2 tmpvar_29;
  tmpvar_29 = dFdy(tmpvar_21.xz);
  highp vec4 tmpvar_30;
  tmpvar_30.x = (0.159155 * sqrt(dot (tmpvar_28, tmpvar_28)));
  tmpvar_30.y = dFdx(tmpvar_27.y);
  tmpvar_30.z = (0.159155 * sqrt(dot (tmpvar_29, tmpvar_29)));
  tmpvar_30.w = dFdy(tmpvar_27.y);
  highp vec3 tmpvar_31;
  tmpvar_31 = abs(tmpvar_21);
  highp float tmpvar_32;
  tmpvar_32 = float((tmpvar_31.z >= tmpvar_31.x));
  zxlerp_20 = tmpvar_32;
  highp float tmpvar_33;
  tmpvar_33 = float((mix (tmpvar_31.x, tmpvar_31.z, zxlerp_20) >= tmpvar_31.y));
  nylerp_19 = tmpvar_33;
  highp vec3 tmpvar_34;
  tmpvar_34 = mix (tmpvar_31, tmpvar_31.zxy, vec3(zxlerp_20));
  detailCoords_18 = tmpvar_34;
  highp vec3 tmpvar_35;
  tmpvar_35 = mix (tmpvar_31.yxz, detailCoords_18, vec3(nylerp_19));
  detailCoords_18 = tmpvar_35;
  mediump float tmpvar_36;
  tmpvar_36 = abs(detailCoords_18.x);
  highp vec2 coord_37;
  coord_37 = (((0.5 * detailCoords_18.zy) / tmpvar_36) * _DetailScale);
  lowp vec4 tmpvar_38;
  tmpvar_38 = texture2DGradEXT (_DetailTex, coord_37, tmpvar_30.xy, tmpvar_30.zw);
  tmpvar_17 = tmpvar_38;
  color_5 = _SurfaceColor;
  highp float tmpvar_39;
  tmpvar_39 = clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0);
  detailLevel_4 = tmpvar_39;
  color_5.xyz = (color_5.xyz + (0.5 * mix ((tmpvar_17.xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(detailLevel_4))));
  highp float tmpvar_40;
  tmpvar_40 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  handoff_3 = tmpvar_40;
  color_5.xyz = mix (color_5.xyz, tex_6.xyz, vec3(handoff_3));
  specColor_2.xyz = _SpecColor.xyz;
  specColor_2.w = mix (1.0, tex_6.w, handoff_3);
  highp vec3 tmpvar_41;
  tmpvar_41 = normalize(_WorldSpaceLightPos0).xyz;
  highp vec3 tmpvar_42;
  tmpvar_42 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  highp float tmpvar_43;
  tmpvar_43 = dot (xlv_TEXCOORD3, xlv_TEXCOORD3);
  lowp vec4 tmpvar_44;
  tmpvar_44 = texture2D (_LightTexture0, vec2(tmpvar_43));
  mediump vec3 lightDir_45;
  lightDir_45 = tmpvar_41;
  mediump vec3 viewDir_46;
  viewDir_46 = xlv_TEXCOORD1;
  mediump vec3 normal_47;
  normal_47 = tmpvar_42;
  mediump float atten_48;
  atten_48 = tmpvar_44.w;
  mediump vec4 c_49;
  highp float nh_50;
  mediump vec3 tmpvar_51;
  tmpvar_51 = normalize(lightDir_45);
  lightDir_45 = tmpvar_51;
  mediump vec3 tmpvar_52;
  tmpvar_52 = normalize(viewDir_46);
  viewDir_46 = tmpvar_52;
  mediump float tmpvar_53;
  tmpvar_53 = dot (normal_47, tmpvar_51);
  mediump float tmpvar_54;
  tmpvar_54 = clamp (dot (normalize((tmpvar_51 + tmpvar_52)), normal_47), 0.0, 1.0);
  nh_50 = tmpvar_54;
  highp vec3 tmpvar_55;
  tmpvar_55 = ((((color_5.xyz * _LightColor0.xyz) * tmpvar_53) + ((_LightColor0.xyz * specColor_2.xyz) * (pow (nh_50, (_Shininess * 128.0)) * color_5.w))) * (atten_48 * 4.0));
  c_49.xyz = tmpvar_55;
  c_49.w = (tmpvar_53 * (atten_48 * 4.0));
  color_5.w = mix (1.0, color_5.w, clamp ((c_49.w * 4.0), 0.0, 1.0));
  mediump vec3 arg0_56;
  arg0_56 = (2.0 * color_5.xyz);
  color_5.w = mix (color_5.w, 1.0, clamp ((sqrt(dot (c_49.xyz, c_49.xyz)) - sqrt(dot (arg0_56, arg0_56))), 0.0, 1.0));
  color_5.w = mix (color_5.w, 1.0, handoff_3);
  color_5.xyz = c_49.xyz;
  tmpvar_1 = color_5;
  gl_FragData[0] = tmpvar_1;
}



#endif"
}

SubProgram "gles3 " {
Keywords { "POINT" "SHADOWS_OFF" }
"!!GLES3#version 300 es


#ifdef VERTEX

#define gl_Vertex _glesVertex
in vec4 _glesVertex;
#define gl_Normal (normalize(_glesNormal))
in vec3 _glesNormal;
#define gl_MultiTexCoord0 _glesMultiTexCoord0
in vec4 _glesMultiTexCoord0;
#define gl_MultiTexCoord1 _glesMultiTexCoord1
in vec4 _glesMultiTexCoord1;

#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 317
struct SurfaceOutput {
    lowp vec3 Albedo;
    lowp vec3 Normal;
    lowp vec3 Emission;
    mediump float Specular;
    lowp float Gloss;
    lowp float Alpha;
};
#line 514
struct v2f {
    highp vec4 pos;
    highp float viewDist;
    highp vec3 viewDir;
    highp vec3 worldPos;
    highp vec3 _LightCoord;
    highp vec3 sphereNormal;
};
#line 506
struct appdata_t {
    highp vec4 vertex;
    highp vec3 normal;
    highp vec4 texcoord;
    highp vec4 texcoord2;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform highp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform sampler2D _LightTexture0;
uniform highp mat4 _LightMatrix0;
#line 327
uniform lowp vec4 _LightColor0;
uniform lowp vec4 _SpecColor;
#line 340
#line 348
#line 362
uniform highp mat4 _MainRotation;
uniform highp mat4 _DetailRotation;
#line 395
#line 399
#line 408
#line 416
#line 425
#line 433
#line 446
#line 458
#line 474
#line 487
uniform lowp vec4 _SurfaceColor;
#line 495
uniform highp float _Shininess;
uniform sampler2D _MainTex;
uniform sampler2D _DetailTex;
uniform highp float _DetailScale;
#line 499
uniform highp float _DetailDist;
uniform highp float _MinLight;
uniform sampler2D _CameraDepthTexture;
uniform highp mat4 _CameraToWorld;
#line 503
uniform highp float _LightPower;
uniform highp float _PlanetOpacity;
uniform highp vec3 _PlanetOrigin;
#line 524
#line 524
v2f vert( in appdata_t v ) {
    v2f o;
    highp vec4 vertex = v.vertex;
    #line 528
    o.pos = (glstate_matrix_mvp * vertex).xyzw;
    highp vec3 vertexPos = (_Object2World * vertex).xyz;
    o.viewDist = distance( vertexPos, _WorldSpaceCameraPos);
    o.worldPos = vertexPos;
    #line 532
    o.sphereNormal = (-normalize(vec4( v.texcoord.x, v.texcoord.y, v.texcoord2.x, v.texcoord2.y)).xyz);
    o.viewDir = normalize((_WorldSpaceCameraPos.xyz - vertexPos));
    o._LightCoord = (_LightMatrix0 * (_Object2World * v.vertex)).xyz;
    #line 536
    return o;
}
out highp float xlv_TEXCOORD0;
out highp vec3 xlv_TEXCOORD1;
out highp vec3 xlv_TEXCOORD2;
out highp vec3 xlv_TEXCOORD3;
out highp vec3 xlv_TEXCOORD5;
void main() {
    v2f xl_retval;
    appdata_t xlt_v;
    xlt_v.vertex = vec4(gl_Vertex);
    xlt_v.normal = vec3(gl_Normal);
    xlt_v.texcoord = vec4(gl_MultiTexCoord0);
    xlt_v.texcoord2 = vec4(gl_MultiTexCoord1);
    xl_retval = vert( xlt_v);
    gl_Position = vec4(xl_retval.pos);
    xlv_TEXCOORD0 = float(xl_retval.viewDist);
    xlv_TEXCOORD1 = vec3(xl_retval.viewDir);
    xlv_TEXCOORD2 = vec3(xl_retval.worldPos);
    xlv_TEXCOORD3 = vec3(xl_retval._LightCoord);
    xlv_TEXCOORD5 = vec3(xl_retval.sphereNormal);
}


#endif
#ifdef FRAGMENT

#define gl_FragData _glesFragData
layout(location = 0) out mediump vec4 _glesFragData[4];
float xll_dFdx_f(float f) {
  return dFdx(f);
}
vec2 xll_dFdx_vf2(vec2 v) {
  return dFdx(v);
}
vec3 xll_dFdx_vf3(vec3 v) {
  return dFdx(v);
}
vec4 xll_dFdx_vf4(vec4 v) {
  return dFdx(v);
}
mat2 xll_dFdx_mf2x2(mat2 m) {
  return mat2( dFdx(m[0]), dFdx(m[1]));
}
mat3 xll_dFdx_mf3x3(mat3 m) {
  return mat3( dFdx(m[0]), dFdx(m[1]), dFdx(m[2]));
}
mat4 xll_dFdx_mf4x4(mat4 m) {
  return mat4( dFdx(m[0]), dFdx(m[1]), dFdx(m[2]), dFdx(m[3]));
}
float xll_dFdy_f(float f) {
  return dFdy(f);
}
vec2 xll_dFdy_vf2(vec2 v) {
  return dFdy(v);
}
vec3 xll_dFdy_vf3(vec3 v) {
  return dFdy(v);
}
vec4 xll_dFdy_vf4(vec4 v) {
  return dFdy(v);
}
mat2 xll_dFdy_mf2x2(mat2 m) {
  return mat2( dFdy(m[0]), dFdy(m[1]));
}
mat3 xll_dFdy_mf3x3(mat3 m) {
  return mat3( dFdy(m[0]), dFdy(m[1]), dFdy(m[2]));
}
mat4 xll_dFdy_mf4x4(mat4 m) {
  return mat4( dFdy(m[0]), dFdy(m[1]), dFdy(m[2]), dFdy(m[3]));
}
vec4 xll_tex2Dgrad(sampler2D s, vec2 coord, vec2 ddx, vec2 ddy) {
   return textureGrad( s, coord, ddx, ddy);
}
float xll_saturate_f( float x) {
  return clamp( x, 0.0, 1.0);
}
vec2 xll_saturate_vf2( vec2 x) {
  return clamp( x, 0.0, 1.0);
}
vec3 xll_saturate_vf3( vec3 x) {
  return clamp( x, 0.0, 1.0);
}
vec4 xll_saturate_vf4( vec4 x) {
  return clamp( x, 0.0, 1.0);
}
mat2 xll_saturate_mf2x2(mat2 m) {
  return mat2( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0));
}
mat3 xll_saturate_mf3x3(mat3 m) {
  return mat3( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0));
}
mat4 xll_saturate_mf4x4(mat4 m) {
  return mat4( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0), clamp(m[3], 0.0, 1.0));
}
#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 317
struct SurfaceOutput {
    lowp vec3 Albedo;
    lowp vec3 Normal;
    lowp vec3 Emission;
    mediump float Specular;
    lowp float Gloss;
    lowp float Alpha;
};
#line 514
struct v2f {
    highp vec4 pos;
    highp float viewDist;
    highp vec3 viewDir;
    highp vec3 worldPos;
    highp vec3 _LightCoord;
    highp vec3 sphereNormal;
};
#line 506
struct appdata_t {
    highp vec4 vertex;
    highp vec3 normal;
    highp vec4 texcoord;
    highp vec4 texcoord2;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform highp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform sampler2D _LightTexture0;
uniform highp mat4 _LightMatrix0;
#line 327
uniform lowp vec4 _LightColor0;
uniform lowp vec4 _SpecColor;
#line 340
#line 348
#line 362
uniform highp mat4 _MainRotation;
uniform highp mat4 _DetailRotation;
#line 395
#line 399
#line 408
#line 416
#line 425
#line 433
#line 446
#line 458
#line 474
#line 487
uniform lowp vec4 _SurfaceColor;
#line 495
uniform highp float _Shininess;
uniform sampler2D _MainTex;
uniform sampler2D _DetailTex;
uniform highp float _DetailScale;
#line 499
uniform highp float _DetailDist;
uniform highp float _MinLight;
uniform sampler2D _CameraDepthTexture;
uniform highp mat4 _CameraToWorld;
#line 503
uniform highp float _LightPower;
uniform highp float _PlanetOpacity;
uniform highp vec3 _PlanetOrigin;
#line 524
#line 399
highp vec4 Derivatives( in highp float lat, in highp float lon, in highp vec3 pos ) {
    highp vec2 latLong = vec2( lat, lon);
    highp float latDdx = (0.159155 * length(xll_dFdx_vf2(pos.xz)));
    #line 403
    highp float latDdy = (0.159155 * length(xll_dFdy_vf2(pos.xz)));
    highp float longDdx = xll_dFdx_f(lon);
    highp float longDdy = xll_dFdy_f(lon);
    return vec4( latDdx, longDdx, latDdy, longDdy);
}
#line 408
highp vec2 GetSphereUV( in highp vec3 sphereVect, in highp vec2 uvOffset ) {
    highp vec2 uv;
    uv.x = (0.5 + (0.159155 * atan( sphereVect.x, sphereVect.z)));
    #line 412
    uv.y = (0.31831 * acos(sphereVect.y));
    uv += uvOffset;
    return uv;
}
#line 446
mediump vec4 GetShereDetailMap( in sampler2D texSampler, in highp vec3 sphereVect, in highp float detailScale ) {
    highp vec3 sphereVectNorm = normalize(sphereVect);
    highp vec2 uv = ((GetSphereUV( sphereVectNorm, vec2( 0.0, 0.0)) * 4.0) * detailScale);
    #line 450
    highp vec4 uvdd = Derivatives( (uv.x - 0.5), uv.y, sphereVectNorm);
    sphereVectNorm = abs(sphereVectNorm);
    mediump float zxlerp = step( sphereVectNorm.x, sphereVectNorm.z);
    mediump float nylerp = step( sphereVectNorm.y, mix( sphereVectNorm.x, sphereVectNorm.z, zxlerp));
    #line 454
    mediump vec3 detailCoords = mix( sphereVectNorm.xyz, sphereVectNorm.zxy, vec3( zxlerp));
    detailCoords = mix( sphereVectNorm.yxz, detailCoords, vec3( nylerp));
    return xll_tex2Dgrad( texSampler, (((0.5 * detailCoords.zy) / abs(detailCoords.x)) * detailScale), uvdd.xy, uvdd.zw);
}
#line 425
mediump vec4 GetSphereMap( in sampler2D texSampler, in highp vec3 sphereVect ) {
    highp vec3 sphereVectNorm = normalize(sphereVect);
    highp vec2 uv = GetSphereUV( sphereVectNorm, vec2( 0.0, 0.0));
    #line 429
    highp vec4 uvdd = Derivatives( (uv.x - 0.5), uv.y, sphereVectNorm);
    mediump vec4 tex = xll_tex2Dgrad( texSampler, uv, uvdd.xy, uvdd.zw);
    return tex;
}
#line 474
mediump vec4 SpecularColorLight( in mediump vec3 lightDir, in mediump vec3 viewDir, in mediump vec3 normal, in mediump vec4 color, in mediump vec4 specColor, in highp float specK, in mediump float atten ) {
    lightDir = normalize(lightDir);
    viewDir = normalize(viewDir);
    #line 478
    mediump vec3 h = normalize((lightDir + viewDir));
    mediump float diffuse = dot( normal, lightDir);
    highp float nh = xll_saturate_f(dot( h, normal));
    highp float spec = (pow( nh, specK) * color.w);
    #line 482
    mediump vec4 c;
    c.xyz = ((((color.xyz * _LightColor0.xyz) * diffuse) + ((_LightColor0.xyz * specColor.xyz) * spec)) * (atten * 4.0));
    c.w = (diffuse * (atten * 4.0));
    return c;
}
#line 538
lowp vec4 frag( in v2f IN ) {
    #line 540
    mediump vec4 color;
    highp vec3 sphereNrm = IN.sphereNormal;
    mediump vec4 main = GetSphereMap( _MainTex, sphereNrm);
    mediump vec4 detail = GetShereDetailMap( _DetailTex, sphereNrm, _DetailScale);
    #line 544
    color = _SurfaceColor;
    mediump float detailLevel = xll_saturate_f(((2.0 * _DetailDist) * IN.viewDist));
    color.xyz += (0.5 * mix( (detail.xyz - 0.5), vec3( 0.0), vec3( detailLevel)));
    mediump float handoff = xll_saturate_f(pow( _PlanetOpacity, 2.0));
    #line 548
    color.xyz = mix( color.xyz, main.xyz, vec3( handoff));
    mediump vec4 specColor = _SpecColor;
    specColor.w = mix( 1.0, main.w, handoff);
    mediump vec4 colorLight = SpecularColorLight( vec3( normalize(_WorldSpaceLightPos0)), IN.viewDir, normalize((IN.worldPos - _PlanetOrigin)), color, specColor, (_Shininess * 128.0), (texture( _LightTexture0, vec2( dot( IN._LightCoord, IN._LightCoord))).w * 1.0));
    #line 552
    color.w = mix( 1.0, color.w, xll_saturate_f((colorLight.w * 4.0)));
    color.w = mix( color.w, 1.0, xll_saturate_f((length(colorLight.xyz) - length((2.0 * color.xyz)))));
    color.w = mix( color.w, 1.0, handoff);
    color.xyz = colorLight.xyz;
    #line 556
    return color;
}
in highp float xlv_TEXCOORD0;
in highp vec3 xlv_TEXCOORD1;
in highp vec3 xlv_TEXCOORD2;
in highp vec3 xlv_TEXCOORD3;
in highp vec3 xlv_TEXCOORD5;
void main() {
    lowp vec4 xl_retval;
    v2f xlt_IN;
    xlt_IN.pos = vec4(0.0);
    xlt_IN.viewDist = float(xlv_TEXCOORD0);
    xlt_IN.viewDir = vec3(xlv_TEXCOORD1);
    xlt_IN.worldPos = vec3(xlv_TEXCOORD2);
    xlt_IN._LightCoord = vec3(xlv_TEXCOORD3);
    xlt_IN.sphereNormal = vec3(xlv_TEXCOORD5);
    xl_retval = frag( xlt_IN);
    gl_FragData[0] = vec4(xl_retval);
}


#endif"
}

SubProgram "opengl " {
Keywords { "DIRECTIONAL" "SHADOWS_OFF" }
"!!GLSL
#ifdef VERTEX
varying vec3 xlv_TEXCOORD5;
varying vec3 xlv_TEXCOORD2;
varying vec3 xlv_TEXCOORD1;
varying float xlv_TEXCOORD0;
uniform mat4 _Object2World;

uniform vec3 _WorldSpaceCameraPos;
void main ()
{
  vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * gl_Vertex).xyz;
  vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  vec4 tmpvar_3;
  tmpvar_3.x = gl_MultiTexCoord0.x;
  tmpvar_3.y = gl_MultiTexCoord0.y;
  tmpvar_3.z = gl_MultiTexCoord1.x;
  tmpvar_3.w = gl_MultiTexCoord1.y;
  gl_Position = (gl_ModelViewProjectionMatrix * gl_Vertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}


#endif
#ifdef FRAGMENT
#extension GL_ARB_shader_texture_lod : enable
varying vec3 xlv_TEXCOORD5;
varying vec3 xlv_TEXCOORD2;
varying vec3 xlv_TEXCOORD1;
varying float xlv_TEXCOORD0;
uniform vec3 _PlanetOrigin;
uniform float _PlanetOpacity;
uniform float _DetailDist;
uniform float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform float _Shininess;
uniform vec4 _SurfaceColor;
uniform vec4 _SpecColor;
uniform vec4 _LightColor0;
uniform vec4 _WorldSpaceLightPos0;
void main ()
{
  vec4 main_1;
  vec4 color_2;
  vec3 tmpvar_3;
  tmpvar_3 = normalize(xlv_TEXCOORD5);
  vec2 uv_4;
  float r_5;
  if ((abs(tmpvar_3.z) > (1e-08 * abs(tmpvar_3.x)))) {
    float y_over_x_6;
    y_over_x_6 = (tmpvar_3.x / tmpvar_3.z);
    float s_7;
    float x_8;
    x_8 = (y_over_x_6 * inversesqrt(((y_over_x_6 * y_over_x_6) + 1.0)));
    s_7 = (sign(x_8) * (1.5708 - (sqrt((1.0 - abs(x_8))) * (1.5708 + (abs(x_8) * (-0.214602 + (abs(x_8) * (0.0865667 + (abs(x_8) * -0.0310296)))))))));
    r_5 = s_7;
    if ((tmpvar_3.z < 0.0)) {
      if ((tmpvar_3.x >= 0.0)) {
        r_5 = (s_7 + 3.14159);
      } else {
        r_5 = (r_5 - 3.14159);
      };
    };
  } else {
    r_5 = (sign(tmpvar_3.x) * 1.5708);
  };
  uv_4.x = (0.5 + (0.159155 * r_5));
  uv_4.y = (0.31831 * (1.5708 - (sign(tmpvar_3.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_3.y))) * (1.5708 + (abs(tmpvar_3.y) * (-0.214602 + (abs(tmpvar_3.y) * (0.0865667 + (abs(tmpvar_3.y) * -0.0310296)))))))))));
  vec2 tmpvar_9;
  tmpvar_9 = dFdx(tmpvar_3.xz);
  vec2 tmpvar_10;
  tmpvar_10 = dFdy(tmpvar_3.xz);
  vec4 tmpvar_11;
  tmpvar_11.x = (0.159155 * sqrt(dot (tmpvar_9, tmpvar_9)));
  tmpvar_11.y = dFdx(uv_4.y);
  tmpvar_11.z = (0.159155 * sqrt(dot (tmpvar_10, tmpvar_10)));
  tmpvar_11.w = dFdy(uv_4.y);
  main_1 = texture2DGradARB (_MainTex, uv_4, tmpvar_11.xy, tmpvar_11.zw);
  vec3 tmpvar_12;
  tmpvar_12 = normalize(xlv_TEXCOORD5);
  vec2 uv_13;
  float r_14;
  if ((abs(tmpvar_12.z) > (1e-08 * abs(tmpvar_12.x)))) {
    float y_over_x_15;
    y_over_x_15 = (tmpvar_12.x / tmpvar_12.z);
    float s_16;
    float x_17;
    x_17 = (y_over_x_15 * inversesqrt(((y_over_x_15 * y_over_x_15) + 1.0)));
    s_16 = (sign(x_17) * (1.5708 - (sqrt((1.0 - abs(x_17))) * (1.5708 + (abs(x_17) * (-0.214602 + (abs(x_17) * (0.0865667 + (abs(x_17) * -0.0310296)))))))));
    r_14 = s_16;
    if ((tmpvar_12.z < 0.0)) {
      if ((tmpvar_12.x >= 0.0)) {
        r_14 = (s_16 + 3.14159);
      } else {
        r_14 = (r_14 - 3.14159);
      };
    };
  } else {
    r_14 = (sign(tmpvar_12.x) * 1.5708);
  };
  uv_13.x = (0.5 + (0.159155 * r_14));
  uv_13.y = (0.31831 * (1.5708 - (sign(tmpvar_12.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_12.y))) * (1.5708 + (abs(tmpvar_12.y) * (-0.214602 + (abs(tmpvar_12.y) * (0.0865667 + (abs(tmpvar_12.y) * -0.0310296)))))))))));
  vec2 tmpvar_18;
  tmpvar_18 = ((uv_13 * 4.0) * _DetailScale);
  vec2 tmpvar_19;
  tmpvar_19 = dFdx(tmpvar_12.xz);
  vec2 tmpvar_20;
  tmpvar_20 = dFdy(tmpvar_12.xz);
  vec4 tmpvar_21;
  tmpvar_21.x = (0.159155 * sqrt(dot (tmpvar_19, tmpvar_19)));
  tmpvar_21.y = dFdx(tmpvar_18.y);
  tmpvar_21.z = (0.159155 * sqrt(dot (tmpvar_20, tmpvar_20)));
  tmpvar_21.w = dFdy(tmpvar_18.y);
  vec3 tmpvar_22;
  tmpvar_22 = abs(tmpvar_12);
  float tmpvar_23;
  tmpvar_23 = float((tmpvar_22.z >= tmpvar_22.x));
  vec3 tmpvar_24;
  tmpvar_24 = mix (tmpvar_22.yxz, mix (tmpvar_22, tmpvar_22.zxy, vec3(tmpvar_23)), vec3(float((mix (tmpvar_22.x, tmpvar_22.z, tmpvar_23) >= tmpvar_22.y))));
  color_2.w = _SurfaceColor.w;
  color_2.xyz = (_SurfaceColor.xyz + (0.5 * mix ((texture2DGradARB (_DetailTex, (((0.5 * tmpvar_24.zy) / abs(tmpvar_24.x)) * _DetailScale), tmpvar_21.xy, tmpvar_21.zw).xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0)))));
  float tmpvar_25;
  tmpvar_25 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  color_2.xyz = mix (color_2.xyz, main_1.xyz, vec3(tmpvar_25));
  vec4 tmpvar_26;
  tmpvar_26 = normalize(_WorldSpaceLightPos0);
  vec3 tmpvar_27;
  tmpvar_27 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  vec4 c_28;
  float tmpvar_29;
  tmpvar_29 = dot (tmpvar_27, tmpvar_26.xyz);
  c_28.xyz = ((((color_2.xyz * _LightColor0.xyz) * tmpvar_29) + ((_LightColor0.xyz * _SpecColor.xyz) * (pow (clamp (dot (normalize((tmpvar_26.xyz + normalize(xlv_TEXCOORD1))), tmpvar_27), 0.0, 1.0), (_Shininess * 128.0)) * _SurfaceColor.w))) * 4.0);
  c_28.w = (tmpvar_29 * 4.0);
  color_2.w = mix (1.0, _SurfaceColor.w, clamp ((c_28.w * 4.0), 0.0, 1.0));
  vec3 arg0_30;
  arg0_30 = (2.0 * color_2.xyz);
  color_2.w = mix (color_2.w, 1.0, clamp ((sqrt(dot (c_28.xyz, c_28.xyz)) - sqrt(dot (arg0_30, arg0_30))), 0.0, 1.0));
  color_2.w = mix (color_2.w, 1.0, tmpvar_25);
  color_2.xyz = c_28.xyz;
  gl_FragData[0] = color_2;
}


#endif
"
}

SubProgram "d3d9 " {
Keywords { "DIRECTIONAL" "SHADOWS_OFF" }
Bind "vertex" Vertex
Bind "texcoord" TexCoord0
Bind "texcoord1" TexCoord1
Matrix 0 [glstate_matrix_mvp]
Vector 8 [_WorldSpaceCameraPos]
Matrix 4 [_Object2World]
"vs_3_0
; 19 ALU
dcl_position o0
dcl_texcoord0 o1
dcl_texcoord1 o2
dcl_texcoord2 o3
dcl_texcoord5 o4
dcl_position0 v0
dcl_texcoord0 v1
dcl_texcoord1 v2
mov r1.zw, v2.xyxy
mov r1.xy, v1
dp4 r0.w, r1, r1
rsq r1.w, r0.w
mul r1.xyz, r1.w, r1
dp4 r0.z, v0, c6
dp4 r0.x, v0, c4
dp4 r0.y, v0, c5
add r2.xyz, -r0, c8
dp3 r0.w, r2, r2
rsq r0.w, r0.w
mov o4.xyz, -r1
mul o2.xyz, r0.w, r2
rcp o1.x, r0.w
mov o3.xyz, r0
dp4 o0.w, v0, c3
dp4 o0.z, v0, c2
dp4 o0.y, v0, c1
dp4 o0.x, v0, c0
"
}

SubProgram "gles " {
Keywords { "DIRECTIONAL" "SHADOWS_OFF" }
"!!GLES


#ifdef VERTEX

varying highp vec3 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_mvp;
uniform highp vec3 _WorldSpaceCameraPos;
attribute vec4 _glesMultiTexCoord1;
attribute vec4 _glesMultiTexCoord0;
attribute vec4 _glesVertex;
void main ()
{
  highp vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * _glesVertex).xyz;
  highp vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  highp vec4 tmpvar_3;
  tmpvar_3.x = _glesMultiTexCoord0.x;
  tmpvar_3.y = _glesMultiTexCoord0.y;
  tmpvar_3.z = _glesMultiTexCoord1.x;
  tmpvar_3.w = _glesMultiTexCoord1.y;
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}



#endif
#ifdef FRAGMENT

#extension GL_EXT_shader_texture_lod : enable
#extension GL_OES_standard_derivatives : enable
varying highp vec3 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp vec3 _PlanetOrigin;
uniform highp float _PlanetOpacity;
uniform highp float _DetailDist;
uniform highp float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform highp float _Shininess;
uniform lowp vec4 _SurfaceColor;
uniform lowp vec4 _SpecColor;
uniform lowp vec4 _LightColor0;
uniform lowp vec4 _WorldSpaceLightPos0;
void main ()
{
  lowp vec4 tmpvar_1;
  mediump vec4 specColor_2;
  mediump float handoff_3;
  mediump float detailLevel_4;
  mediump vec4 color_5;
  mediump vec4 tex_6;
  highp vec3 tmpvar_7;
  tmpvar_7 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_8;
  highp float r_9;
  if ((abs(tmpvar_7.z) > (1e-08 * abs(tmpvar_7.x)))) {
    highp float y_over_x_10;
    y_over_x_10 = (tmpvar_7.x / tmpvar_7.z);
    highp float s_11;
    highp float x_12;
    x_12 = (y_over_x_10 * inversesqrt(((y_over_x_10 * y_over_x_10) + 1.0)));
    s_11 = (sign(x_12) * (1.5708 - (sqrt((1.0 - abs(x_12))) * (1.5708 + (abs(x_12) * (-0.214602 + (abs(x_12) * (0.0865667 + (abs(x_12) * -0.0310296)))))))));
    r_9 = s_11;
    if ((tmpvar_7.z < 0.0)) {
      if ((tmpvar_7.x >= 0.0)) {
        r_9 = (s_11 + 3.14159);
      } else {
        r_9 = (r_9 - 3.14159);
      };
    };
  } else {
    r_9 = (sign(tmpvar_7.x) * 1.5708);
  };
  uv_8.x = (0.5 + (0.159155 * r_9));
  uv_8.y = (0.31831 * (1.5708 - (sign(tmpvar_7.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_7.y))) * (1.5708 + (abs(tmpvar_7.y) * (-0.214602 + (abs(tmpvar_7.y) * (0.0865667 + (abs(tmpvar_7.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_13;
  tmpvar_13 = dFdx(tmpvar_7.xz);
  highp vec2 tmpvar_14;
  tmpvar_14 = dFdy(tmpvar_7.xz);
  highp vec4 tmpvar_15;
  tmpvar_15.x = (0.159155 * sqrt(dot (tmpvar_13, tmpvar_13)));
  tmpvar_15.y = dFdx(uv_8.y);
  tmpvar_15.z = (0.159155 * sqrt(dot (tmpvar_14, tmpvar_14)));
  tmpvar_15.w = dFdy(uv_8.y);
  lowp vec4 tmpvar_16;
  tmpvar_16 = texture2DGradEXT (_MainTex, uv_8, tmpvar_15.xy, tmpvar_15.zw);
  tex_6 = tmpvar_16;
  mediump vec4 tmpvar_17;
  mediump vec3 detailCoords_18;
  mediump float nylerp_19;
  mediump float zxlerp_20;
  highp vec3 tmpvar_21;
  tmpvar_21 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_22;
  highp float r_23;
  if ((abs(tmpvar_21.z) > (1e-08 * abs(tmpvar_21.x)))) {
    highp float y_over_x_24;
    y_over_x_24 = (tmpvar_21.x / tmpvar_21.z);
    highp float s_25;
    highp float x_26;
    x_26 = (y_over_x_24 * inversesqrt(((y_over_x_24 * y_over_x_24) + 1.0)));
    s_25 = (sign(x_26) * (1.5708 - (sqrt((1.0 - abs(x_26))) * (1.5708 + (abs(x_26) * (-0.214602 + (abs(x_26) * (0.0865667 + (abs(x_26) * -0.0310296)))))))));
    r_23 = s_25;
    if ((tmpvar_21.z < 0.0)) {
      if ((tmpvar_21.x >= 0.0)) {
        r_23 = (s_25 + 3.14159);
      } else {
        r_23 = (r_23 - 3.14159);
      };
    };
  } else {
    r_23 = (sign(tmpvar_21.x) * 1.5708);
  };
  uv_22.x = (0.5 + (0.159155 * r_23));
  uv_22.y = (0.31831 * (1.5708 - (sign(tmpvar_21.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_21.y))) * (1.5708 + (abs(tmpvar_21.y) * (-0.214602 + (abs(tmpvar_21.y) * (0.0865667 + (abs(tmpvar_21.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_27;
  tmpvar_27 = ((uv_22 * 4.0) * _DetailScale);
  highp vec2 tmpvar_28;
  tmpvar_28 = dFdx(tmpvar_21.xz);
  highp vec2 tmpvar_29;
  tmpvar_29 = dFdy(tmpvar_21.xz);
  highp vec4 tmpvar_30;
  tmpvar_30.x = (0.159155 * sqrt(dot (tmpvar_28, tmpvar_28)));
  tmpvar_30.y = dFdx(tmpvar_27.y);
  tmpvar_30.z = (0.159155 * sqrt(dot (tmpvar_29, tmpvar_29)));
  tmpvar_30.w = dFdy(tmpvar_27.y);
  highp vec3 tmpvar_31;
  tmpvar_31 = abs(tmpvar_21);
  highp float tmpvar_32;
  tmpvar_32 = float((tmpvar_31.z >= tmpvar_31.x));
  zxlerp_20 = tmpvar_32;
  highp float tmpvar_33;
  tmpvar_33 = float((mix (tmpvar_31.x, tmpvar_31.z, zxlerp_20) >= tmpvar_31.y));
  nylerp_19 = tmpvar_33;
  highp vec3 tmpvar_34;
  tmpvar_34 = mix (tmpvar_31, tmpvar_31.zxy, vec3(zxlerp_20));
  detailCoords_18 = tmpvar_34;
  highp vec3 tmpvar_35;
  tmpvar_35 = mix (tmpvar_31.yxz, detailCoords_18, vec3(nylerp_19));
  detailCoords_18 = tmpvar_35;
  mediump float tmpvar_36;
  tmpvar_36 = abs(detailCoords_18.x);
  highp vec2 coord_37;
  coord_37 = (((0.5 * detailCoords_18.zy) / tmpvar_36) * _DetailScale);
  lowp vec4 tmpvar_38;
  tmpvar_38 = texture2DGradEXT (_DetailTex, coord_37, tmpvar_30.xy, tmpvar_30.zw);
  tmpvar_17 = tmpvar_38;
  color_5 = _SurfaceColor;
  highp float tmpvar_39;
  tmpvar_39 = clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0);
  detailLevel_4 = tmpvar_39;
  color_5.xyz = (color_5.xyz + (0.5 * mix ((tmpvar_17.xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(detailLevel_4))));
  highp float tmpvar_40;
  tmpvar_40 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  handoff_3 = tmpvar_40;
  color_5.xyz = mix (color_5.xyz, tex_6.xyz, vec3(handoff_3));
  specColor_2.xyz = _SpecColor.xyz;
  specColor_2.w = mix (1.0, tex_6.w, handoff_3);
  lowp vec3 tmpvar_41;
  tmpvar_41 = normalize(_WorldSpaceLightPos0).xyz;
  highp vec3 tmpvar_42;
  tmpvar_42 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  mediump vec3 lightDir_43;
  lightDir_43 = tmpvar_41;
  mediump vec3 viewDir_44;
  viewDir_44 = xlv_TEXCOORD1;
  mediump vec3 normal_45;
  normal_45 = tmpvar_42;
  mediump vec4 c_46;
  highp float nh_47;
  mediump vec3 tmpvar_48;
  tmpvar_48 = normalize(viewDir_44);
  viewDir_44 = tmpvar_48;
  mediump float tmpvar_49;
  tmpvar_49 = dot (normal_45, lightDir_43);
  mediump float tmpvar_50;
  tmpvar_50 = clamp (dot (normalize((lightDir_43 + tmpvar_48)), normal_45), 0.0, 1.0);
  nh_47 = tmpvar_50;
  highp vec3 tmpvar_51;
  tmpvar_51 = ((((color_5.xyz * _LightColor0.xyz) * tmpvar_49) + ((_LightColor0.xyz * specColor_2.xyz) * (pow (nh_47, (_Shininess * 128.0)) * color_5.w))) * 4.0);
  c_46.xyz = tmpvar_51;
  c_46.w = (tmpvar_49 * 4.0);
  color_5.w = mix (1.0, color_5.w, clamp ((c_46.w * 4.0), 0.0, 1.0));
  mediump vec3 arg0_52;
  arg0_52 = (2.0 * color_5.xyz);
  color_5.w = mix (color_5.w, 1.0, clamp ((sqrt(dot (c_46.xyz, c_46.xyz)) - sqrt(dot (arg0_52, arg0_52))), 0.0, 1.0));
  color_5.w = mix (color_5.w, 1.0, handoff_3);
  color_5.xyz = c_46.xyz;
  tmpvar_1 = color_5;
  gl_FragData[0] = tmpvar_1;
}



#endif"
}

SubProgram "glesdesktop " {
Keywords { "DIRECTIONAL" "SHADOWS_OFF" }
"!!GLES


#ifdef VERTEX

varying highp vec3 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_mvp;
uniform highp vec3 _WorldSpaceCameraPos;
attribute vec4 _glesMultiTexCoord1;
attribute vec4 _glesMultiTexCoord0;
attribute vec4 _glesVertex;
void main ()
{
  highp vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * _glesVertex).xyz;
  highp vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  highp vec4 tmpvar_3;
  tmpvar_3.x = _glesMultiTexCoord0.x;
  tmpvar_3.y = _glesMultiTexCoord0.y;
  tmpvar_3.z = _glesMultiTexCoord1.x;
  tmpvar_3.w = _glesMultiTexCoord1.y;
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}



#endif
#ifdef FRAGMENT

#extension GL_EXT_shader_texture_lod : enable
#extension GL_OES_standard_derivatives : enable
varying highp vec3 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp vec3 _PlanetOrigin;
uniform highp float _PlanetOpacity;
uniform highp float _DetailDist;
uniform highp float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform highp float _Shininess;
uniform lowp vec4 _SurfaceColor;
uniform lowp vec4 _SpecColor;
uniform lowp vec4 _LightColor0;
uniform lowp vec4 _WorldSpaceLightPos0;
void main ()
{
  lowp vec4 tmpvar_1;
  mediump vec4 specColor_2;
  mediump float handoff_3;
  mediump float detailLevel_4;
  mediump vec4 color_5;
  mediump vec4 tex_6;
  highp vec3 tmpvar_7;
  tmpvar_7 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_8;
  highp float r_9;
  if ((abs(tmpvar_7.z) > (1e-08 * abs(tmpvar_7.x)))) {
    highp float y_over_x_10;
    y_over_x_10 = (tmpvar_7.x / tmpvar_7.z);
    highp float s_11;
    highp float x_12;
    x_12 = (y_over_x_10 * inversesqrt(((y_over_x_10 * y_over_x_10) + 1.0)));
    s_11 = (sign(x_12) * (1.5708 - (sqrt((1.0 - abs(x_12))) * (1.5708 + (abs(x_12) * (-0.214602 + (abs(x_12) * (0.0865667 + (abs(x_12) * -0.0310296)))))))));
    r_9 = s_11;
    if ((tmpvar_7.z < 0.0)) {
      if ((tmpvar_7.x >= 0.0)) {
        r_9 = (s_11 + 3.14159);
      } else {
        r_9 = (r_9 - 3.14159);
      };
    };
  } else {
    r_9 = (sign(tmpvar_7.x) * 1.5708);
  };
  uv_8.x = (0.5 + (0.159155 * r_9));
  uv_8.y = (0.31831 * (1.5708 - (sign(tmpvar_7.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_7.y))) * (1.5708 + (abs(tmpvar_7.y) * (-0.214602 + (abs(tmpvar_7.y) * (0.0865667 + (abs(tmpvar_7.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_13;
  tmpvar_13 = dFdx(tmpvar_7.xz);
  highp vec2 tmpvar_14;
  tmpvar_14 = dFdy(tmpvar_7.xz);
  highp vec4 tmpvar_15;
  tmpvar_15.x = (0.159155 * sqrt(dot (tmpvar_13, tmpvar_13)));
  tmpvar_15.y = dFdx(uv_8.y);
  tmpvar_15.z = (0.159155 * sqrt(dot (tmpvar_14, tmpvar_14)));
  tmpvar_15.w = dFdy(uv_8.y);
  lowp vec4 tmpvar_16;
  tmpvar_16 = texture2DGradEXT (_MainTex, uv_8, tmpvar_15.xy, tmpvar_15.zw);
  tex_6 = tmpvar_16;
  mediump vec4 tmpvar_17;
  mediump vec3 detailCoords_18;
  mediump float nylerp_19;
  mediump float zxlerp_20;
  highp vec3 tmpvar_21;
  tmpvar_21 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_22;
  highp float r_23;
  if ((abs(tmpvar_21.z) > (1e-08 * abs(tmpvar_21.x)))) {
    highp float y_over_x_24;
    y_over_x_24 = (tmpvar_21.x / tmpvar_21.z);
    highp float s_25;
    highp float x_26;
    x_26 = (y_over_x_24 * inversesqrt(((y_over_x_24 * y_over_x_24) + 1.0)));
    s_25 = (sign(x_26) * (1.5708 - (sqrt((1.0 - abs(x_26))) * (1.5708 + (abs(x_26) * (-0.214602 + (abs(x_26) * (0.0865667 + (abs(x_26) * -0.0310296)))))))));
    r_23 = s_25;
    if ((tmpvar_21.z < 0.0)) {
      if ((tmpvar_21.x >= 0.0)) {
        r_23 = (s_25 + 3.14159);
      } else {
        r_23 = (r_23 - 3.14159);
      };
    };
  } else {
    r_23 = (sign(tmpvar_21.x) * 1.5708);
  };
  uv_22.x = (0.5 + (0.159155 * r_23));
  uv_22.y = (0.31831 * (1.5708 - (sign(tmpvar_21.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_21.y))) * (1.5708 + (abs(tmpvar_21.y) * (-0.214602 + (abs(tmpvar_21.y) * (0.0865667 + (abs(tmpvar_21.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_27;
  tmpvar_27 = ((uv_22 * 4.0) * _DetailScale);
  highp vec2 tmpvar_28;
  tmpvar_28 = dFdx(tmpvar_21.xz);
  highp vec2 tmpvar_29;
  tmpvar_29 = dFdy(tmpvar_21.xz);
  highp vec4 tmpvar_30;
  tmpvar_30.x = (0.159155 * sqrt(dot (tmpvar_28, tmpvar_28)));
  tmpvar_30.y = dFdx(tmpvar_27.y);
  tmpvar_30.z = (0.159155 * sqrt(dot (tmpvar_29, tmpvar_29)));
  tmpvar_30.w = dFdy(tmpvar_27.y);
  highp vec3 tmpvar_31;
  tmpvar_31 = abs(tmpvar_21);
  highp float tmpvar_32;
  tmpvar_32 = float((tmpvar_31.z >= tmpvar_31.x));
  zxlerp_20 = tmpvar_32;
  highp float tmpvar_33;
  tmpvar_33 = float((mix (tmpvar_31.x, tmpvar_31.z, zxlerp_20) >= tmpvar_31.y));
  nylerp_19 = tmpvar_33;
  highp vec3 tmpvar_34;
  tmpvar_34 = mix (tmpvar_31, tmpvar_31.zxy, vec3(zxlerp_20));
  detailCoords_18 = tmpvar_34;
  highp vec3 tmpvar_35;
  tmpvar_35 = mix (tmpvar_31.yxz, detailCoords_18, vec3(nylerp_19));
  detailCoords_18 = tmpvar_35;
  mediump float tmpvar_36;
  tmpvar_36 = abs(detailCoords_18.x);
  highp vec2 coord_37;
  coord_37 = (((0.5 * detailCoords_18.zy) / tmpvar_36) * _DetailScale);
  lowp vec4 tmpvar_38;
  tmpvar_38 = texture2DGradEXT (_DetailTex, coord_37, tmpvar_30.xy, tmpvar_30.zw);
  tmpvar_17 = tmpvar_38;
  color_5 = _SurfaceColor;
  highp float tmpvar_39;
  tmpvar_39 = clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0);
  detailLevel_4 = tmpvar_39;
  color_5.xyz = (color_5.xyz + (0.5 * mix ((tmpvar_17.xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(detailLevel_4))));
  highp float tmpvar_40;
  tmpvar_40 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  handoff_3 = tmpvar_40;
  color_5.xyz = mix (color_5.xyz, tex_6.xyz, vec3(handoff_3));
  specColor_2.xyz = _SpecColor.xyz;
  specColor_2.w = mix (1.0, tex_6.w, handoff_3);
  lowp vec3 tmpvar_41;
  tmpvar_41 = normalize(_WorldSpaceLightPos0).xyz;
  highp vec3 tmpvar_42;
  tmpvar_42 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  mediump vec3 lightDir_43;
  lightDir_43 = tmpvar_41;
  mediump vec3 viewDir_44;
  viewDir_44 = xlv_TEXCOORD1;
  mediump vec3 normal_45;
  normal_45 = tmpvar_42;
  mediump vec4 c_46;
  highp float nh_47;
  mediump vec3 tmpvar_48;
  tmpvar_48 = normalize(viewDir_44);
  viewDir_44 = tmpvar_48;
  mediump float tmpvar_49;
  tmpvar_49 = dot (normal_45, lightDir_43);
  mediump float tmpvar_50;
  tmpvar_50 = clamp (dot (normalize((lightDir_43 + tmpvar_48)), normal_45), 0.0, 1.0);
  nh_47 = tmpvar_50;
  highp vec3 tmpvar_51;
  tmpvar_51 = ((((color_5.xyz * _LightColor0.xyz) * tmpvar_49) + ((_LightColor0.xyz * specColor_2.xyz) * (pow (nh_47, (_Shininess * 128.0)) * color_5.w))) * 4.0);
  c_46.xyz = tmpvar_51;
  c_46.w = (tmpvar_49 * 4.0);
  color_5.w = mix (1.0, color_5.w, clamp ((c_46.w * 4.0), 0.0, 1.0));
  mediump vec3 arg0_52;
  arg0_52 = (2.0 * color_5.xyz);
  color_5.w = mix (color_5.w, 1.0, clamp ((sqrt(dot (c_46.xyz, c_46.xyz)) - sqrt(dot (arg0_52, arg0_52))), 0.0, 1.0));
  color_5.w = mix (color_5.w, 1.0, handoff_3);
  color_5.xyz = c_46.xyz;
  tmpvar_1 = color_5;
  gl_FragData[0] = tmpvar_1;
}



#endif"
}

SubProgram "gles3 " {
Keywords { "DIRECTIONAL" "SHADOWS_OFF" }
"!!GLES3#version 300 es


#ifdef VERTEX

#define gl_Vertex _glesVertex
in vec4 _glesVertex;
#define gl_Normal (normalize(_glesNormal))
in vec3 _glesNormal;
#define gl_MultiTexCoord0 _glesMultiTexCoord0
in vec4 _glesMultiTexCoord0;
#define gl_MultiTexCoord1 _glesMultiTexCoord1
in vec4 _glesMultiTexCoord1;

#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 315
struct SurfaceOutput {
    lowp vec3 Albedo;
    lowp vec3 Normal;
    lowp vec3 Emission;
    mediump float Specular;
    lowp float Gloss;
    lowp float Alpha;
};
#line 511
struct v2f {
    highp vec4 pos;
    highp float viewDist;
    highp vec3 viewDir;
    highp vec3 worldPos;
    highp vec3 sphereNormal;
};
#line 503
struct appdata_t {
    highp vec4 vertex;
    highp vec3 normal;
    highp vec4 texcoord;
    highp vec4 texcoord2;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform lowp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 325
uniform lowp vec4 _LightColor0;
uniform lowp vec4 _SpecColor;
#line 338
#line 346
#line 360
uniform highp mat4 _MainRotation;
uniform highp mat4 _DetailRotation;
#line 393
#line 397
#line 406
#line 414
#line 423
#line 431
#line 444
#line 456
#line 472
#line 484
uniform lowp vec4 _SurfaceColor;
#line 492
uniform highp float _Shininess;
uniform sampler2D _MainTex;
uniform sampler2D _DetailTex;
uniform highp float _DetailScale;
#line 496
uniform highp float _DetailDist;
uniform highp float _MinLight;
uniform sampler2D _CameraDepthTexture;
uniform highp mat4 _CameraToWorld;
#line 500
uniform highp float _LightPower;
uniform highp float _PlanetOpacity;
uniform highp vec3 _PlanetOrigin;
#line 520
#line 533
#line 520
v2f vert( in appdata_t v ) {
    v2f o;
    highp vec4 vertex = v.vertex;
    #line 524
    o.pos = (glstate_matrix_mvp * vertex).xyzw;
    highp vec3 vertexPos = (_Object2World * vertex).xyz;
    o.viewDist = distance( vertexPos, _WorldSpaceCameraPos);
    o.worldPos = vertexPos;
    #line 528
    o.sphereNormal = (-normalize(vec4( v.texcoord.x, v.texcoord.y, v.texcoord2.x, v.texcoord2.y)).xyz);
    o.viewDir = normalize((_WorldSpaceCameraPos.xyz - vertexPos));
    return o;
}
out highp float xlv_TEXCOORD0;
out highp vec3 xlv_TEXCOORD1;
out highp vec3 xlv_TEXCOORD2;
out highp vec3 xlv_TEXCOORD5;
void main() {
    v2f xl_retval;
    appdata_t xlt_v;
    xlt_v.vertex = vec4(gl_Vertex);
    xlt_v.normal = vec3(gl_Normal);
    xlt_v.texcoord = vec4(gl_MultiTexCoord0);
    xlt_v.texcoord2 = vec4(gl_MultiTexCoord1);
    xl_retval = vert( xlt_v);
    gl_Position = vec4(xl_retval.pos);
    xlv_TEXCOORD0 = float(xl_retval.viewDist);
    xlv_TEXCOORD1 = vec3(xl_retval.viewDir);
    xlv_TEXCOORD2 = vec3(xl_retval.worldPos);
    xlv_TEXCOORD5 = vec3(xl_retval.sphereNormal);
}


#endif
#ifdef FRAGMENT

#define gl_FragData _glesFragData
layout(location = 0) out mediump vec4 _glesFragData[4];
float xll_dFdx_f(float f) {
  return dFdx(f);
}
vec2 xll_dFdx_vf2(vec2 v) {
  return dFdx(v);
}
vec3 xll_dFdx_vf3(vec3 v) {
  return dFdx(v);
}
vec4 xll_dFdx_vf4(vec4 v) {
  return dFdx(v);
}
mat2 xll_dFdx_mf2x2(mat2 m) {
  return mat2( dFdx(m[0]), dFdx(m[1]));
}
mat3 xll_dFdx_mf3x3(mat3 m) {
  return mat3( dFdx(m[0]), dFdx(m[1]), dFdx(m[2]));
}
mat4 xll_dFdx_mf4x4(mat4 m) {
  return mat4( dFdx(m[0]), dFdx(m[1]), dFdx(m[2]), dFdx(m[3]));
}
float xll_dFdy_f(float f) {
  return dFdy(f);
}
vec2 xll_dFdy_vf2(vec2 v) {
  return dFdy(v);
}
vec3 xll_dFdy_vf3(vec3 v) {
  return dFdy(v);
}
vec4 xll_dFdy_vf4(vec4 v) {
  return dFdy(v);
}
mat2 xll_dFdy_mf2x2(mat2 m) {
  return mat2( dFdy(m[0]), dFdy(m[1]));
}
mat3 xll_dFdy_mf3x3(mat3 m) {
  return mat3( dFdy(m[0]), dFdy(m[1]), dFdy(m[2]));
}
mat4 xll_dFdy_mf4x4(mat4 m) {
  return mat4( dFdy(m[0]), dFdy(m[1]), dFdy(m[2]), dFdy(m[3]));
}
vec4 xll_tex2Dgrad(sampler2D s, vec2 coord, vec2 ddx, vec2 ddy) {
   return textureGrad( s, coord, ddx, ddy);
}
float xll_saturate_f( float x) {
  return clamp( x, 0.0, 1.0);
}
vec2 xll_saturate_vf2( vec2 x) {
  return clamp( x, 0.0, 1.0);
}
vec3 xll_saturate_vf3( vec3 x) {
  return clamp( x, 0.0, 1.0);
}
vec4 xll_saturate_vf4( vec4 x) {
  return clamp( x, 0.0, 1.0);
}
mat2 xll_saturate_mf2x2(mat2 m) {
  return mat2( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0));
}
mat3 xll_saturate_mf3x3(mat3 m) {
  return mat3( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0));
}
mat4 xll_saturate_mf4x4(mat4 m) {
  return mat4( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0), clamp(m[3], 0.0, 1.0));
}
#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 315
struct SurfaceOutput {
    lowp vec3 Albedo;
    lowp vec3 Normal;
    lowp vec3 Emission;
    mediump float Specular;
    lowp float Gloss;
    lowp float Alpha;
};
#line 511
struct v2f {
    highp vec4 pos;
    highp float viewDist;
    highp vec3 viewDir;
    highp vec3 worldPos;
    highp vec3 sphereNormal;
};
#line 503
struct appdata_t {
    highp vec4 vertex;
    highp vec3 normal;
    highp vec4 texcoord;
    highp vec4 texcoord2;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform lowp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 325
uniform lowp vec4 _LightColor0;
uniform lowp vec4 _SpecColor;
#line 338
#line 346
#line 360
uniform highp mat4 _MainRotation;
uniform highp mat4 _DetailRotation;
#line 393
#line 397
#line 406
#line 414
#line 423
#line 431
#line 444
#line 456
#line 472
#line 484
uniform lowp vec4 _SurfaceColor;
#line 492
uniform highp float _Shininess;
uniform sampler2D _MainTex;
uniform sampler2D _DetailTex;
uniform highp float _DetailScale;
#line 496
uniform highp float _DetailDist;
uniform highp float _MinLight;
uniform sampler2D _CameraDepthTexture;
uniform highp mat4 _CameraToWorld;
#line 500
uniform highp float _LightPower;
uniform highp float _PlanetOpacity;
uniform highp vec3 _PlanetOrigin;
#line 520
#line 533
#line 397
highp vec4 Derivatives( in highp float lat, in highp float lon, in highp vec3 pos ) {
    highp vec2 latLong = vec2( lat, lon);
    highp float latDdx = (0.159155 * length(xll_dFdx_vf2(pos.xz)));
    #line 401
    highp float latDdy = (0.159155 * length(xll_dFdy_vf2(pos.xz)));
    highp float longDdx = xll_dFdx_f(lon);
    highp float longDdy = xll_dFdy_f(lon);
    return vec4( latDdx, longDdx, latDdy, longDdy);
}
#line 406
highp vec2 GetSphereUV( in highp vec3 sphereVect, in highp vec2 uvOffset ) {
    highp vec2 uv;
    uv.x = (0.5 + (0.159155 * atan( sphereVect.x, sphereVect.z)));
    #line 410
    uv.y = (0.31831 * acos(sphereVect.y));
    uv += uvOffset;
    return uv;
}
#line 444
mediump vec4 GetShereDetailMap( in sampler2D texSampler, in highp vec3 sphereVect, in highp float detailScale ) {
    highp vec3 sphereVectNorm = normalize(sphereVect);
    highp vec2 uv = ((GetSphereUV( sphereVectNorm, vec2( 0.0, 0.0)) * 4.0) * detailScale);
    #line 448
    highp vec4 uvdd = Derivatives( (uv.x - 0.5), uv.y, sphereVectNorm);
    sphereVectNorm = abs(sphereVectNorm);
    mediump float zxlerp = step( sphereVectNorm.x, sphereVectNorm.z);
    mediump float nylerp = step( sphereVectNorm.y, mix( sphereVectNorm.x, sphereVectNorm.z, zxlerp));
    #line 452
    mediump vec3 detailCoords = mix( sphereVectNorm.xyz, sphereVectNorm.zxy, vec3( zxlerp));
    detailCoords = mix( sphereVectNorm.yxz, detailCoords, vec3( nylerp));
    return xll_tex2Dgrad( texSampler, (((0.5 * detailCoords.zy) / abs(detailCoords.x)) * detailScale), uvdd.xy, uvdd.zw);
}
#line 423
mediump vec4 GetSphereMap( in sampler2D texSampler, in highp vec3 sphereVect ) {
    highp vec3 sphereVectNorm = normalize(sphereVect);
    highp vec2 uv = GetSphereUV( sphereVectNorm, vec2( 0.0, 0.0));
    #line 427
    highp vec4 uvdd = Derivatives( (uv.x - 0.5), uv.y, sphereVectNorm);
    mediump vec4 tex = xll_tex2Dgrad( texSampler, uv, uvdd.xy, uvdd.zw);
    return tex;
}
#line 472
mediump vec4 SpecularColorLight( in mediump vec3 lightDir, in mediump vec3 viewDir, in mediump vec3 normal, in mediump vec4 color, in mediump vec4 specColor, in highp float specK, in mediump float atten ) {
    viewDir = normalize(viewDir);
    mediump vec3 h = normalize((lightDir + viewDir));
    #line 476
    mediump float diffuse = dot( normal, lightDir);
    highp float nh = xll_saturate_f(dot( h, normal));
    highp float spec = (pow( nh, specK) * color.w);
    mediump vec4 c;
    #line 480
    c.xyz = ((((color.xyz * _LightColor0.xyz) * diffuse) + ((_LightColor0.xyz * specColor.xyz) * spec)) * (atten * 4.0));
    c.w = (diffuse * (atten * 4.0));
    return c;
}
#line 533
lowp vec4 frag( in v2f IN ) {
    mediump vec4 color;
    highp vec3 sphereNrm = IN.sphereNormal;
    #line 537
    mediump vec4 main = GetSphereMap( _MainTex, sphereNrm);
    mediump vec4 detail = GetShereDetailMap( _DetailTex, sphereNrm, _DetailScale);
    color = _SurfaceColor;
    mediump float detailLevel = xll_saturate_f(((2.0 * _DetailDist) * IN.viewDist));
    #line 541
    color.xyz += (0.5 * mix( (detail.xyz - 0.5), vec3( 0.0), vec3( detailLevel)));
    mediump float handoff = xll_saturate_f(pow( _PlanetOpacity, 2.0));
    color.xyz = mix( color.xyz, main.xyz, vec3( handoff));
    mediump vec4 specColor = _SpecColor;
    #line 545
    specColor.w = mix( 1.0, main.w, handoff);
    mediump vec4 colorLight = SpecularColorLight( vec3( normalize(_WorldSpaceLightPos0)), IN.viewDir, normalize((IN.worldPos - _PlanetOrigin)), color, specColor, (_Shininess * 128.0), 1.0);
    color.w = mix( 1.0, color.w, xll_saturate_f((colorLight.w * 4.0)));
    color.w = mix( color.w, 1.0, xll_saturate_f((length(colorLight.xyz) - length((2.0 * color.xyz)))));
    #line 549
    color.w = mix( color.w, 1.0, handoff);
    color.xyz = colorLight.xyz;
    return color;
}
in highp float xlv_TEXCOORD0;
in highp vec3 xlv_TEXCOORD1;
in highp vec3 xlv_TEXCOORD2;
in highp vec3 xlv_TEXCOORD5;
void main() {
    lowp vec4 xl_retval;
    v2f xlt_IN;
    xlt_IN.pos = vec4(0.0);
    xlt_IN.viewDist = float(xlv_TEXCOORD0);
    xlt_IN.viewDir = vec3(xlv_TEXCOORD1);
    xlt_IN.worldPos = vec3(xlv_TEXCOORD2);
    xlt_IN.sphereNormal = vec3(xlv_TEXCOORD5);
    xl_retval = frag( xlt_IN);
    gl_FragData[0] = vec4(xl_retval);
}


#endif"
}

SubProgram "opengl " {
Keywords { "SPOT" "SHADOWS_OFF" }
"!!GLSL
#ifdef VERTEX
varying vec3 xlv_TEXCOORD5;
varying vec4 xlv_TEXCOORD3;
varying vec3 xlv_TEXCOORD2;
varying vec3 xlv_TEXCOORD1;
varying float xlv_TEXCOORD0;
uniform mat4 _LightMatrix0;
uniform mat4 _Object2World;

uniform vec3 _WorldSpaceCameraPos;
void main ()
{
  vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * gl_Vertex).xyz;
  vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  vec4 tmpvar_3;
  tmpvar_3.x = gl_MultiTexCoord0.x;
  tmpvar_3.y = gl_MultiTexCoord0.y;
  tmpvar_3.z = gl_MultiTexCoord1.x;
  tmpvar_3.w = gl_MultiTexCoord1.y;
  gl_Position = (gl_ModelViewProjectionMatrix * gl_Vertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * gl_Vertex));
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}


#endif
#ifdef FRAGMENT
#extension GL_ARB_shader_texture_lod : enable
varying vec3 xlv_TEXCOORD5;
varying vec4 xlv_TEXCOORD3;
varying vec3 xlv_TEXCOORD2;
varying vec3 xlv_TEXCOORD1;
varying float xlv_TEXCOORD0;
uniform vec3 _PlanetOrigin;
uniform float _PlanetOpacity;
uniform float _DetailDist;
uniform float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform float _Shininess;
uniform vec4 _SurfaceColor;
uniform vec4 _SpecColor;
uniform vec4 _LightColor0;
uniform sampler2D _LightTextureB0;
uniform sampler2D _LightTexture0;
uniform vec4 _WorldSpaceLightPos0;
void main ()
{
  vec4 main_1;
  vec4 color_2;
  vec3 tmpvar_3;
  tmpvar_3 = normalize(xlv_TEXCOORD5);
  vec2 uv_4;
  float r_5;
  if ((abs(tmpvar_3.z) > (1e-08 * abs(tmpvar_3.x)))) {
    float y_over_x_6;
    y_over_x_6 = (tmpvar_3.x / tmpvar_3.z);
    float s_7;
    float x_8;
    x_8 = (y_over_x_6 * inversesqrt(((y_over_x_6 * y_over_x_6) + 1.0)));
    s_7 = (sign(x_8) * (1.5708 - (sqrt((1.0 - abs(x_8))) * (1.5708 + (abs(x_8) * (-0.214602 + (abs(x_8) * (0.0865667 + (abs(x_8) * -0.0310296)))))))));
    r_5 = s_7;
    if ((tmpvar_3.z < 0.0)) {
      if ((tmpvar_3.x >= 0.0)) {
        r_5 = (s_7 + 3.14159);
      } else {
        r_5 = (r_5 - 3.14159);
      };
    };
  } else {
    r_5 = (sign(tmpvar_3.x) * 1.5708);
  };
  uv_4.x = (0.5 + (0.159155 * r_5));
  uv_4.y = (0.31831 * (1.5708 - (sign(tmpvar_3.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_3.y))) * (1.5708 + (abs(tmpvar_3.y) * (-0.214602 + (abs(tmpvar_3.y) * (0.0865667 + (abs(tmpvar_3.y) * -0.0310296)))))))))));
  vec2 tmpvar_9;
  tmpvar_9 = dFdx(tmpvar_3.xz);
  vec2 tmpvar_10;
  tmpvar_10 = dFdy(tmpvar_3.xz);
  vec4 tmpvar_11;
  tmpvar_11.x = (0.159155 * sqrt(dot (tmpvar_9, tmpvar_9)));
  tmpvar_11.y = dFdx(uv_4.y);
  tmpvar_11.z = (0.159155 * sqrt(dot (tmpvar_10, tmpvar_10)));
  tmpvar_11.w = dFdy(uv_4.y);
  main_1 = texture2DGradARB (_MainTex, uv_4, tmpvar_11.xy, tmpvar_11.zw);
  vec3 tmpvar_12;
  tmpvar_12 = normalize(xlv_TEXCOORD5);
  vec2 uv_13;
  float r_14;
  if ((abs(tmpvar_12.z) > (1e-08 * abs(tmpvar_12.x)))) {
    float y_over_x_15;
    y_over_x_15 = (tmpvar_12.x / tmpvar_12.z);
    float s_16;
    float x_17;
    x_17 = (y_over_x_15 * inversesqrt(((y_over_x_15 * y_over_x_15) + 1.0)));
    s_16 = (sign(x_17) * (1.5708 - (sqrt((1.0 - abs(x_17))) * (1.5708 + (abs(x_17) * (-0.214602 + (abs(x_17) * (0.0865667 + (abs(x_17) * -0.0310296)))))))));
    r_14 = s_16;
    if ((tmpvar_12.z < 0.0)) {
      if ((tmpvar_12.x >= 0.0)) {
        r_14 = (s_16 + 3.14159);
      } else {
        r_14 = (r_14 - 3.14159);
      };
    };
  } else {
    r_14 = (sign(tmpvar_12.x) * 1.5708);
  };
  uv_13.x = (0.5 + (0.159155 * r_14));
  uv_13.y = (0.31831 * (1.5708 - (sign(tmpvar_12.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_12.y))) * (1.5708 + (abs(tmpvar_12.y) * (-0.214602 + (abs(tmpvar_12.y) * (0.0865667 + (abs(tmpvar_12.y) * -0.0310296)))))))))));
  vec2 tmpvar_18;
  tmpvar_18 = ((uv_13 * 4.0) * _DetailScale);
  vec2 tmpvar_19;
  tmpvar_19 = dFdx(tmpvar_12.xz);
  vec2 tmpvar_20;
  tmpvar_20 = dFdy(tmpvar_12.xz);
  vec4 tmpvar_21;
  tmpvar_21.x = (0.159155 * sqrt(dot (tmpvar_19, tmpvar_19)));
  tmpvar_21.y = dFdx(tmpvar_18.y);
  tmpvar_21.z = (0.159155 * sqrt(dot (tmpvar_20, tmpvar_20)));
  tmpvar_21.w = dFdy(tmpvar_18.y);
  vec3 tmpvar_22;
  tmpvar_22 = abs(tmpvar_12);
  float tmpvar_23;
  tmpvar_23 = float((tmpvar_22.z >= tmpvar_22.x));
  vec3 tmpvar_24;
  tmpvar_24 = mix (tmpvar_22.yxz, mix (tmpvar_22, tmpvar_22.zxy, vec3(tmpvar_23)), vec3(float((mix (tmpvar_22.x, tmpvar_22.z, tmpvar_23) >= tmpvar_22.y))));
  color_2.w = _SurfaceColor.w;
  color_2.xyz = (_SurfaceColor.xyz + (0.5 * mix ((texture2DGradARB (_DetailTex, (((0.5 * tmpvar_24.zy) / abs(tmpvar_24.x)) * _DetailScale), tmpvar_21.xy, tmpvar_21.zw).xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0)))));
  float tmpvar_25;
  tmpvar_25 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  color_2.xyz = mix (color_2.xyz, main_1.xyz, vec3(tmpvar_25));
  vec3 tmpvar_26;
  tmpvar_26 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  float atten_27;
  atten_27 = ((float((xlv_TEXCOORD3.z > 0.0)) * texture2D (_LightTexture0, ((xlv_TEXCOORD3.xy / xlv_TEXCOORD3.w) + 0.5)).w) * texture2D (_LightTextureB0, vec2(dot (xlv_TEXCOORD3.xyz, xlv_TEXCOORD3.xyz))).w);
  vec4 c_28;
  vec3 tmpvar_29;
  tmpvar_29 = normalize(normalize(_WorldSpaceLightPos0).xyz);
  float tmpvar_30;
  tmpvar_30 = dot (tmpvar_26, tmpvar_29);
  c_28.xyz = ((((color_2.xyz * _LightColor0.xyz) * tmpvar_30) + ((_LightColor0.xyz * _SpecColor.xyz) * (pow (clamp (dot (normalize((tmpvar_29 + normalize(xlv_TEXCOORD1))), tmpvar_26), 0.0, 1.0), (_Shininess * 128.0)) * _SurfaceColor.w))) * (atten_27 * 4.0));
  c_28.w = (tmpvar_30 * (atten_27 * 4.0));
  color_2.w = mix (1.0, _SurfaceColor.w, clamp ((c_28.w * 4.0), 0.0, 1.0));
  vec3 arg0_31;
  arg0_31 = (2.0 * color_2.xyz);
  color_2.w = mix (color_2.w, 1.0, clamp ((sqrt(dot (c_28.xyz, c_28.xyz)) - sqrt(dot (arg0_31, arg0_31))), 0.0, 1.0));
  color_2.w = mix (color_2.w, 1.0, tmpvar_25);
  color_2.xyz = c_28.xyz;
  gl_FragData[0] = color_2;
}


#endif
"
}

SubProgram "d3d9 " {
Keywords { "SPOT" "SHADOWS_OFF" }
Bind "vertex" Vertex
Bind "texcoord" TexCoord0
Bind "texcoord1" TexCoord1
Matrix 0 [glstate_matrix_mvp]
Vector 12 [_WorldSpaceCameraPos]
Matrix 4 [_Object2World]
Matrix 8 [_LightMatrix0]
"vs_3_0
; 25 ALU
dcl_position o0
dcl_texcoord0 o1
dcl_texcoord1 o2
dcl_texcoord2 o3
dcl_texcoord3 o4
dcl_texcoord5 o5
dcl_position0 v0
dcl_texcoord0 v1
dcl_texcoord1 v2
mov r1.zw, v2.xyxy
mov r1.xy, v1
dp4 r0.w, r1, r1
rsq r1.w, r0.w
mul r1.xyz, r1.w, r1
dp4 r1.w, v0, c7
dp4 r0.z, v0, c6
dp4 r0.x, v0, c4
dp4 r0.y, v0, c5
add r2.xyz, -r0, c12
dp3 r0.w, r2, r2
rsq r0.w, r0.w
mov o5.xyz, -r1
mov r1.xyz, r0
mul o2.xyz, r0.w, r2
dp4 o4.w, r1, c11
dp4 o4.z, r1, c10
dp4 o4.y, r1, c9
dp4 o4.x, r1, c8
rcp o1.x, r0.w
mov o3.xyz, r0
dp4 o0.w, v0, c3
dp4 o0.z, v0, c2
dp4 o0.y, v0, c1
dp4 o0.x, v0, c0
"
}

SubProgram "gles " {
Keywords { "SPOT" "SHADOWS_OFF" }
"!!GLES


#ifdef VERTEX

varying highp vec3 xlv_TEXCOORD5;
varying highp vec4 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp mat4 _LightMatrix0;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_mvp;
uniform highp vec3 _WorldSpaceCameraPos;
attribute vec4 _glesMultiTexCoord1;
attribute vec4 _glesMultiTexCoord0;
attribute vec4 _glesVertex;
void main ()
{
  highp vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * _glesVertex).xyz;
  highp vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  highp vec4 tmpvar_3;
  tmpvar_3.x = _glesMultiTexCoord0.x;
  tmpvar_3.y = _glesMultiTexCoord0.y;
  tmpvar_3.z = _glesMultiTexCoord1.x;
  tmpvar_3.w = _glesMultiTexCoord1.y;
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * _glesVertex));
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}



#endif
#ifdef FRAGMENT

#extension GL_EXT_shader_texture_lod : enable
#extension GL_OES_standard_derivatives : enable
varying highp vec3 xlv_TEXCOORD5;
varying highp vec4 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp vec3 _PlanetOrigin;
uniform highp float _PlanetOpacity;
uniform highp float _DetailDist;
uniform highp float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform highp float _Shininess;
uniform lowp vec4 _SurfaceColor;
uniform lowp vec4 _SpecColor;
uniform lowp vec4 _LightColor0;
uniform sampler2D _LightTextureB0;
uniform sampler2D _LightTexture0;
uniform highp vec4 _WorldSpaceLightPos0;
void main ()
{
  lowp vec4 tmpvar_1;
  mediump vec4 specColor_2;
  mediump float handoff_3;
  mediump float detailLevel_4;
  mediump vec4 color_5;
  mediump vec4 tex_6;
  highp vec3 tmpvar_7;
  tmpvar_7 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_8;
  highp float r_9;
  if ((abs(tmpvar_7.z) > (1e-08 * abs(tmpvar_7.x)))) {
    highp float y_over_x_10;
    y_over_x_10 = (tmpvar_7.x / tmpvar_7.z);
    highp float s_11;
    highp float x_12;
    x_12 = (y_over_x_10 * inversesqrt(((y_over_x_10 * y_over_x_10) + 1.0)));
    s_11 = (sign(x_12) * (1.5708 - (sqrt((1.0 - abs(x_12))) * (1.5708 + (abs(x_12) * (-0.214602 + (abs(x_12) * (0.0865667 + (abs(x_12) * -0.0310296)))))))));
    r_9 = s_11;
    if ((tmpvar_7.z < 0.0)) {
      if ((tmpvar_7.x >= 0.0)) {
        r_9 = (s_11 + 3.14159);
      } else {
        r_9 = (r_9 - 3.14159);
      };
    };
  } else {
    r_9 = (sign(tmpvar_7.x) * 1.5708);
  };
  uv_8.x = (0.5 + (0.159155 * r_9));
  uv_8.y = (0.31831 * (1.5708 - (sign(tmpvar_7.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_7.y))) * (1.5708 + (abs(tmpvar_7.y) * (-0.214602 + (abs(tmpvar_7.y) * (0.0865667 + (abs(tmpvar_7.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_13;
  tmpvar_13 = dFdx(tmpvar_7.xz);
  highp vec2 tmpvar_14;
  tmpvar_14 = dFdy(tmpvar_7.xz);
  highp vec4 tmpvar_15;
  tmpvar_15.x = (0.159155 * sqrt(dot (tmpvar_13, tmpvar_13)));
  tmpvar_15.y = dFdx(uv_8.y);
  tmpvar_15.z = (0.159155 * sqrt(dot (tmpvar_14, tmpvar_14)));
  tmpvar_15.w = dFdy(uv_8.y);
  lowp vec4 tmpvar_16;
  tmpvar_16 = texture2DGradEXT (_MainTex, uv_8, tmpvar_15.xy, tmpvar_15.zw);
  tex_6 = tmpvar_16;
  mediump vec4 tmpvar_17;
  mediump vec3 detailCoords_18;
  mediump float nylerp_19;
  mediump float zxlerp_20;
  highp vec3 tmpvar_21;
  tmpvar_21 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_22;
  highp float r_23;
  if ((abs(tmpvar_21.z) > (1e-08 * abs(tmpvar_21.x)))) {
    highp float y_over_x_24;
    y_over_x_24 = (tmpvar_21.x / tmpvar_21.z);
    highp float s_25;
    highp float x_26;
    x_26 = (y_over_x_24 * inversesqrt(((y_over_x_24 * y_over_x_24) + 1.0)));
    s_25 = (sign(x_26) * (1.5708 - (sqrt((1.0 - abs(x_26))) * (1.5708 + (abs(x_26) * (-0.214602 + (abs(x_26) * (0.0865667 + (abs(x_26) * -0.0310296)))))))));
    r_23 = s_25;
    if ((tmpvar_21.z < 0.0)) {
      if ((tmpvar_21.x >= 0.0)) {
        r_23 = (s_25 + 3.14159);
      } else {
        r_23 = (r_23 - 3.14159);
      };
    };
  } else {
    r_23 = (sign(tmpvar_21.x) * 1.5708);
  };
  uv_22.x = (0.5 + (0.159155 * r_23));
  uv_22.y = (0.31831 * (1.5708 - (sign(tmpvar_21.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_21.y))) * (1.5708 + (abs(tmpvar_21.y) * (-0.214602 + (abs(tmpvar_21.y) * (0.0865667 + (abs(tmpvar_21.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_27;
  tmpvar_27 = ((uv_22 * 4.0) * _DetailScale);
  highp vec2 tmpvar_28;
  tmpvar_28 = dFdx(tmpvar_21.xz);
  highp vec2 tmpvar_29;
  tmpvar_29 = dFdy(tmpvar_21.xz);
  highp vec4 tmpvar_30;
  tmpvar_30.x = (0.159155 * sqrt(dot (tmpvar_28, tmpvar_28)));
  tmpvar_30.y = dFdx(tmpvar_27.y);
  tmpvar_30.z = (0.159155 * sqrt(dot (tmpvar_29, tmpvar_29)));
  tmpvar_30.w = dFdy(tmpvar_27.y);
  highp vec3 tmpvar_31;
  tmpvar_31 = abs(tmpvar_21);
  highp float tmpvar_32;
  tmpvar_32 = float((tmpvar_31.z >= tmpvar_31.x));
  zxlerp_20 = tmpvar_32;
  highp float tmpvar_33;
  tmpvar_33 = float((mix (tmpvar_31.x, tmpvar_31.z, zxlerp_20) >= tmpvar_31.y));
  nylerp_19 = tmpvar_33;
  highp vec3 tmpvar_34;
  tmpvar_34 = mix (tmpvar_31, tmpvar_31.zxy, vec3(zxlerp_20));
  detailCoords_18 = tmpvar_34;
  highp vec3 tmpvar_35;
  tmpvar_35 = mix (tmpvar_31.yxz, detailCoords_18, vec3(nylerp_19));
  detailCoords_18 = tmpvar_35;
  mediump float tmpvar_36;
  tmpvar_36 = abs(detailCoords_18.x);
  highp vec2 coord_37;
  coord_37 = (((0.5 * detailCoords_18.zy) / tmpvar_36) * _DetailScale);
  lowp vec4 tmpvar_38;
  tmpvar_38 = texture2DGradEXT (_DetailTex, coord_37, tmpvar_30.xy, tmpvar_30.zw);
  tmpvar_17 = tmpvar_38;
  color_5 = _SurfaceColor;
  highp float tmpvar_39;
  tmpvar_39 = clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0);
  detailLevel_4 = tmpvar_39;
  color_5.xyz = (color_5.xyz + (0.5 * mix ((tmpvar_17.xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(detailLevel_4))));
  highp float tmpvar_40;
  tmpvar_40 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  handoff_3 = tmpvar_40;
  color_5.xyz = mix (color_5.xyz, tex_6.xyz, vec3(handoff_3));
  specColor_2.xyz = _SpecColor.xyz;
  specColor_2.w = mix (1.0, tex_6.w, handoff_3);
  highp vec3 tmpvar_41;
  tmpvar_41 = normalize(_WorldSpaceLightPos0).xyz;
  highp vec3 tmpvar_42;
  tmpvar_42 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  lowp vec4 tmpvar_43;
  highp vec2 P_44;
  P_44 = ((xlv_TEXCOORD3.xy / xlv_TEXCOORD3.w) + 0.5);
  tmpvar_43 = texture2D (_LightTexture0, P_44);
  highp float tmpvar_45;
  tmpvar_45 = dot (xlv_TEXCOORD3.xyz, xlv_TEXCOORD3.xyz);
  lowp vec4 tmpvar_46;
  tmpvar_46 = texture2D (_LightTextureB0, vec2(tmpvar_45));
  mediump vec3 lightDir_47;
  lightDir_47 = tmpvar_41;
  mediump vec3 viewDir_48;
  viewDir_48 = xlv_TEXCOORD1;
  mediump vec3 normal_49;
  normal_49 = tmpvar_42;
  mediump float atten_50;
  atten_50 = ((float((xlv_TEXCOORD3.z > 0.0)) * tmpvar_43.w) * tmpvar_46.w);
  mediump vec4 c_51;
  highp float nh_52;
  mediump vec3 tmpvar_53;
  tmpvar_53 = normalize(lightDir_47);
  lightDir_47 = tmpvar_53;
  mediump vec3 tmpvar_54;
  tmpvar_54 = normalize(viewDir_48);
  viewDir_48 = tmpvar_54;
  mediump float tmpvar_55;
  tmpvar_55 = dot (normal_49, tmpvar_53);
  mediump float tmpvar_56;
  tmpvar_56 = clamp (dot (normalize((tmpvar_53 + tmpvar_54)), normal_49), 0.0, 1.0);
  nh_52 = tmpvar_56;
  highp vec3 tmpvar_57;
  tmpvar_57 = ((((color_5.xyz * _LightColor0.xyz) * tmpvar_55) + ((_LightColor0.xyz * specColor_2.xyz) * (pow (nh_52, (_Shininess * 128.0)) * color_5.w))) * (atten_50 * 4.0));
  c_51.xyz = tmpvar_57;
  c_51.w = (tmpvar_55 * (atten_50 * 4.0));
  color_5.w = mix (1.0, color_5.w, clamp ((c_51.w * 4.0), 0.0, 1.0));
  mediump vec3 arg0_58;
  arg0_58 = (2.0 * color_5.xyz);
  color_5.w = mix (color_5.w, 1.0, clamp ((sqrt(dot (c_51.xyz, c_51.xyz)) - sqrt(dot (arg0_58, arg0_58))), 0.0, 1.0));
  color_5.w = mix (color_5.w, 1.0, handoff_3);
  color_5.xyz = c_51.xyz;
  tmpvar_1 = color_5;
  gl_FragData[0] = tmpvar_1;
}



#endif"
}

SubProgram "glesdesktop " {
Keywords { "SPOT" "SHADOWS_OFF" }
"!!GLES


#ifdef VERTEX

varying highp vec3 xlv_TEXCOORD5;
varying highp vec4 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp mat4 _LightMatrix0;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_mvp;
uniform highp vec3 _WorldSpaceCameraPos;
attribute vec4 _glesMultiTexCoord1;
attribute vec4 _glesMultiTexCoord0;
attribute vec4 _glesVertex;
void main ()
{
  highp vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * _glesVertex).xyz;
  highp vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  highp vec4 tmpvar_3;
  tmpvar_3.x = _glesMultiTexCoord0.x;
  tmpvar_3.y = _glesMultiTexCoord0.y;
  tmpvar_3.z = _glesMultiTexCoord1.x;
  tmpvar_3.w = _glesMultiTexCoord1.y;
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * _glesVertex));
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}



#endif
#ifdef FRAGMENT

#extension GL_EXT_shader_texture_lod : enable
#extension GL_OES_standard_derivatives : enable
varying highp vec3 xlv_TEXCOORD5;
varying highp vec4 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp vec3 _PlanetOrigin;
uniform highp float _PlanetOpacity;
uniform highp float _DetailDist;
uniform highp float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform highp float _Shininess;
uniform lowp vec4 _SurfaceColor;
uniform lowp vec4 _SpecColor;
uniform lowp vec4 _LightColor0;
uniform sampler2D _LightTextureB0;
uniform sampler2D _LightTexture0;
uniform highp vec4 _WorldSpaceLightPos0;
void main ()
{
  lowp vec4 tmpvar_1;
  mediump vec4 specColor_2;
  mediump float handoff_3;
  mediump float detailLevel_4;
  mediump vec4 color_5;
  mediump vec4 tex_6;
  highp vec3 tmpvar_7;
  tmpvar_7 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_8;
  highp float r_9;
  if ((abs(tmpvar_7.z) > (1e-08 * abs(tmpvar_7.x)))) {
    highp float y_over_x_10;
    y_over_x_10 = (tmpvar_7.x / tmpvar_7.z);
    highp float s_11;
    highp float x_12;
    x_12 = (y_over_x_10 * inversesqrt(((y_over_x_10 * y_over_x_10) + 1.0)));
    s_11 = (sign(x_12) * (1.5708 - (sqrt((1.0 - abs(x_12))) * (1.5708 + (abs(x_12) * (-0.214602 + (abs(x_12) * (0.0865667 + (abs(x_12) * -0.0310296)))))))));
    r_9 = s_11;
    if ((tmpvar_7.z < 0.0)) {
      if ((tmpvar_7.x >= 0.0)) {
        r_9 = (s_11 + 3.14159);
      } else {
        r_9 = (r_9 - 3.14159);
      };
    };
  } else {
    r_9 = (sign(tmpvar_7.x) * 1.5708);
  };
  uv_8.x = (0.5 + (0.159155 * r_9));
  uv_8.y = (0.31831 * (1.5708 - (sign(tmpvar_7.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_7.y))) * (1.5708 + (abs(tmpvar_7.y) * (-0.214602 + (abs(tmpvar_7.y) * (0.0865667 + (abs(tmpvar_7.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_13;
  tmpvar_13 = dFdx(tmpvar_7.xz);
  highp vec2 tmpvar_14;
  tmpvar_14 = dFdy(tmpvar_7.xz);
  highp vec4 tmpvar_15;
  tmpvar_15.x = (0.159155 * sqrt(dot (tmpvar_13, tmpvar_13)));
  tmpvar_15.y = dFdx(uv_8.y);
  tmpvar_15.z = (0.159155 * sqrt(dot (tmpvar_14, tmpvar_14)));
  tmpvar_15.w = dFdy(uv_8.y);
  lowp vec4 tmpvar_16;
  tmpvar_16 = texture2DGradEXT (_MainTex, uv_8, tmpvar_15.xy, tmpvar_15.zw);
  tex_6 = tmpvar_16;
  mediump vec4 tmpvar_17;
  mediump vec3 detailCoords_18;
  mediump float nylerp_19;
  mediump float zxlerp_20;
  highp vec3 tmpvar_21;
  tmpvar_21 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_22;
  highp float r_23;
  if ((abs(tmpvar_21.z) > (1e-08 * abs(tmpvar_21.x)))) {
    highp float y_over_x_24;
    y_over_x_24 = (tmpvar_21.x / tmpvar_21.z);
    highp float s_25;
    highp float x_26;
    x_26 = (y_over_x_24 * inversesqrt(((y_over_x_24 * y_over_x_24) + 1.0)));
    s_25 = (sign(x_26) * (1.5708 - (sqrt((1.0 - abs(x_26))) * (1.5708 + (abs(x_26) * (-0.214602 + (abs(x_26) * (0.0865667 + (abs(x_26) * -0.0310296)))))))));
    r_23 = s_25;
    if ((tmpvar_21.z < 0.0)) {
      if ((tmpvar_21.x >= 0.0)) {
        r_23 = (s_25 + 3.14159);
      } else {
        r_23 = (r_23 - 3.14159);
      };
    };
  } else {
    r_23 = (sign(tmpvar_21.x) * 1.5708);
  };
  uv_22.x = (0.5 + (0.159155 * r_23));
  uv_22.y = (0.31831 * (1.5708 - (sign(tmpvar_21.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_21.y))) * (1.5708 + (abs(tmpvar_21.y) * (-0.214602 + (abs(tmpvar_21.y) * (0.0865667 + (abs(tmpvar_21.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_27;
  tmpvar_27 = ((uv_22 * 4.0) * _DetailScale);
  highp vec2 tmpvar_28;
  tmpvar_28 = dFdx(tmpvar_21.xz);
  highp vec2 tmpvar_29;
  tmpvar_29 = dFdy(tmpvar_21.xz);
  highp vec4 tmpvar_30;
  tmpvar_30.x = (0.159155 * sqrt(dot (tmpvar_28, tmpvar_28)));
  tmpvar_30.y = dFdx(tmpvar_27.y);
  tmpvar_30.z = (0.159155 * sqrt(dot (tmpvar_29, tmpvar_29)));
  tmpvar_30.w = dFdy(tmpvar_27.y);
  highp vec3 tmpvar_31;
  tmpvar_31 = abs(tmpvar_21);
  highp float tmpvar_32;
  tmpvar_32 = float((tmpvar_31.z >= tmpvar_31.x));
  zxlerp_20 = tmpvar_32;
  highp float tmpvar_33;
  tmpvar_33 = float((mix (tmpvar_31.x, tmpvar_31.z, zxlerp_20) >= tmpvar_31.y));
  nylerp_19 = tmpvar_33;
  highp vec3 tmpvar_34;
  tmpvar_34 = mix (tmpvar_31, tmpvar_31.zxy, vec3(zxlerp_20));
  detailCoords_18 = tmpvar_34;
  highp vec3 tmpvar_35;
  tmpvar_35 = mix (tmpvar_31.yxz, detailCoords_18, vec3(nylerp_19));
  detailCoords_18 = tmpvar_35;
  mediump float tmpvar_36;
  tmpvar_36 = abs(detailCoords_18.x);
  highp vec2 coord_37;
  coord_37 = (((0.5 * detailCoords_18.zy) / tmpvar_36) * _DetailScale);
  lowp vec4 tmpvar_38;
  tmpvar_38 = texture2DGradEXT (_DetailTex, coord_37, tmpvar_30.xy, tmpvar_30.zw);
  tmpvar_17 = tmpvar_38;
  color_5 = _SurfaceColor;
  highp float tmpvar_39;
  tmpvar_39 = clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0);
  detailLevel_4 = tmpvar_39;
  color_5.xyz = (color_5.xyz + (0.5 * mix ((tmpvar_17.xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(detailLevel_4))));
  highp float tmpvar_40;
  tmpvar_40 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  handoff_3 = tmpvar_40;
  color_5.xyz = mix (color_5.xyz, tex_6.xyz, vec3(handoff_3));
  specColor_2.xyz = _SpecColor.xyz;
  specColor_2.w = mix (1.0, tex_6.w, handoff_3);
  highp vec3 tmpvar_41;
  tmpvar_41 = normalize(_WorldSpaceLightPos0).xyz;
  highp vec3 tmpvar_42;
  tmpvar_42 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  lowp vec4 tmpvar_43;
  highp vec2 P_44;
  P_44 = ((xlv_TEXCOORD3.xy / xlv_TEXCOORD3.w) + 0.5);
  tmpvar_43 = texture2D (_LightTexture0, P_44);
  highp float tmpvar_45;
  tmpvar_45 = dot (xlv_TEXCOORD3.xyz, xlv_TEXCOORD3.xyz);
  lowp vec4 tmpvar_46;
  tmpvar_46 = texture2D (_LightTextureB0, vec2(tmpvar_45));
  mediump vec3 lightDir_47;
  lightDir_47 = tmpvar_41;
  mediump vec3 viewDir_48;
  viewDir_48 = xlv_TEXCOORD1;
  mediump vec3 normal_49;
  normal_49 = tmpvar_42;
  mediump float atten_50;
  atten_50 = ((float((xlv_TEXCOORD3.z > 0.0)) * tmpvar_43.w) * tmpvar_46.w);
  mediump vec4 c_51;
  highp float nh_52;
  mediump vec3 tmpvar_53;
  tmpvar_53 = normalize(lightDir_47);
  lightDir_47 = tmpvar_53;
  mediump vec3 tmpvar_54;
  tmpvar_54 = normalize(viewDir_48);
  viewDir_48 = tmpvar_54;
  mediump float tmpvar_55;
  tmpvar_55 = dot (normal_49, tmpvar_53);
  mediump float tmpvar_56;
  tmpvar_56 = clamp (dot (normalize((tmpvar_53 + tmpvar_54)), normal_49), 0.0, 1.0);
  nh_52 = tmpvar_56;
  highp vec3 tmpvar_57;
  tmpvar_57 = ((((color_5.xyz * _LightColor0.xyz) * tmpvar_55) + ((_LightColor0.xyz * specColor_2.xyz) * (pow (nh_52, (_Shininess * 128.0)) * color_5.w))) * (atten_50 * 4.0));
  c_51.xyz = tmpvar_57;
  c_51.w = (tmpvar_55 * (atten_50 * 4.0));
  color_5.w = mix (1.0, color_5.w, clamp ((c_51.w * 4.0), 0.0, 1.0));
  mediump vec3 arg0_58;
  arg0_58 = (2.0 * color_5.xyz);
  color_5.w = mix (color_5.w, 1.0, clamp ((sqrt(dot (c_51.xyz, c_51.xyz)) - sqrt(dot (arg0_58, arg0_58))), 0.0, 1.0));
  color_5.w = mix (color_5.w, 1.0, handoff_3);
  color_5.xyz = c_51.xyz;
  tmpvar_1 = color_5;
  gl_FragData[0] = tmpvar_1;
}



#endif"
}

SubProgram "gles3 " {
Keywords { "SPOT" "SHADOWS_OFF" }
"!!GLES3#version 300 es


#ifdef VERTEX

#define gl_Vertex _glesVertex
in vec4 _glesVertex;
#define gl_Normal (normalize(_glesNormal))
in vec3 _glesNormal;
#define gl_MultiTexCoord0 _glesMultiTexCoord0
in vec4 _glesMultiTexCoord0;
#define gl_MultiTexCoord1 _glesMultiTexCoord1
in vec4 _glesMultiTexCoord1;

#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 326
struct SurfaceOutput {
    lowp vec3 Albedo;
    lowp vec3 Normal;
    lowp vec3 Emission;
    mediump float Specular;
    lowp float Gloss;
    lowp float Alpha;
};
#line 523
struct v2f {
    highp vec4 pos;
    highp float viewDist;
    highp vec3 viewDir;
    highp vec3 worldPos;
    highp vec4 _LightCoord;
    highp vec3 sphereNormal;
};
#line 515
struct appdata_t {
    highp vec4 vertex;
    highp vec3 normal;
    highp vec4 texcoord;
    highp vec4 texcoord2;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform highp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform sampler2D _LightTexture0;
uniform highp mat4 _LightMatrix0;
uniform sampler2D _LightTextureB0;
#line 336
uniform lowp vec4 _LightColor0;
uniform lowp vec4 _SpecColor;
#line 349
#line 357
#line 371
uniform highp mat4 _MainRotation;
uniform highp mat4 _DetailRotation;
#line 404
#line 408
#line 417
#line 425
#line 434
#line 442
#line 455
#line 467
#line 483
#line 496
uniform lowp vec4 _SurfaceColor;
#line 504
uniform highp float _Shininess;
uniform sampler2D _MainTex;
uniform sampler2D _DetailTex;
uniform highp float _DetailScale;
#line 508
uniform highp float _DetailDist;
uniform highp float _MinLight;
uniform sampler2D _CameraDepthTexture;
uniform highp mat4 _CameraToWorld;
#line 512
uniform highp float _LightPower;
uniform highp float _PlanetOpacity;
uniform highp vec3 _PlanetOrigin;
#line 533
#line 533
v2f vert( in appdata_t v ) {
    v2f o;
    highp vec4 vertex = v.vertex;
    #line 537
    o.pos = (glstate_matrix_mvp * vertex).xyzw;
    highp vec3 vertexPos = (_Object2World * vertex).xyz;
    o.viewDist = distance( vertexPos, _WorldSpaceCameraPos);
    o.worldPos = vertexPos;
    #line 541
    o.sphereNormal = (-normalize(vec4( v.texcoord.x, v.texcoord.y, v.texcoord2.x, v.texcoord2.y)).xyz);
    o.viewDir = normalize((_WorldSpaceCameraPos.xyz - vertexPos));
    o._LightCoord = (_LightMatrix0 * (_Object2World * v.vertex));
    #line 545
    return o;
}
out highp float xlv_TEXCOORD0;
out highp vec3 xlv_TEXCOORD1;
out highp vec3 xlv_TEXCOORD2;
out highp vec4 xlv_TEXCOORD3;
out highp vec3 xlv_TEXCOORD5;
void main() {
    v2f xl_retval;
    appdata_t xlt_v;
    xlt_v.vertex = vec4(gl_Vertex);
    xlt_v.normal = vec3(gl_Normal);
    xlt_v.texcoord = vec4(gl_MultiTexCoord0);
    xlt_v.texcoord2 = vec4(gl_MultiTexCoord1);
    xl_retval = vert( xlt_v);
    gl_Position = vec4(xl_retval.pos);
    xlv_TEXCOORD0 = float(xl_retval.viewDist);
    xlv_TEXCOORD1 = vec3(xl_retval.viewDir);
    xlv_TEXCOORD2 = vec3(xl_retval.worldPos);
    xlv_TEXCOORD3 = vec4(xl_retval._LightCoord);
    xlv_TEXCOORD5 = vec3(xl_retval.sphereNormal);
}


#endif
#ifdef FRAGMENT

#define gl_FragData _glesFragData
layout(location = 0) out mediump vec4 _glesFragData[4];
float xll_dFdx_f(float f) {
  return dFdx(f);
}
vec2 xll_dFdx_vf2(vec2 v) {
  return dFdx(v);
}
vec3 xll_dFdx_vf3(vec3 v) {
  return dFdx(v);
}
vec4 xll_dFdx_vf4(vec4 v) {
  return dFdx(v);
}
mat2 xll_dFdx_mf2x2(mat2 m) {
  return mat2( dFdx(m[0]), dFdx(m[1]));
}
mat3 xll_dFdx_mf3x3(mat3 m) {
  return mat3( dFdx(m[0]), dFdx(m[1]), dFdx(m[2]));
}
mat4 xll_dFdx_mf4x4(mat4 m) {
  return mat4( dFdx(m[0]), dFdx(m[1]), dFdx(m[2]), dFdx(m[3]));
}
float xll_dFdy_f(float f) {
  return dFdy(f);
}
vec2 xll_dFdy_vf2(vec2 v) {
  return dFdy(v);
}
vec3 xll_dFdy_vf3(vec3 v) {
  return dFdy(v);
}
vec4 xll_dFdy_vf4(vec4 v) {
  return dFdy(v);
}
mat2 xll_dFdy_mf2x2(mat2 m) {
  return mat2( dFdy(m[0]), dFdy(m[1]));
}
mat3 xll_dFdy_mf3x3(mat3 m) {
  return mat3( dFdy(m[0]), dFdy(m[1]), dFdy(m[2]));
}
mat4 xll_dFdy_mf4x4(mat4 m) {
  return mat4( dFdy(m[0]), dFdy(m[1]), dFdy(m[2]), dFdy(m[3]));
}
vec4 xll_tex2Dgrad(sampler2D s, vec2 coord, vec2 ddx, vec2 ddy) {
   return textureGrad( s, coord, ddx, ddy);
}
float xll_saturate_f( float x) {
  return clamp( x, 0.0, 1.0);
}
vec2 xll_saturate_vf2( vec2 x) {
  return clamp( x, 0.0, 1.0);
}
vec3 xll_saturate_vf3( vec3 x) {
  return clamp( x, 0.0, 1.0);
}
vec4 xll_saturate_vf4( vec4 x) {
  return clamp( x, 0.0, 1.0);
}
mat2 xll_saturate_mf2x2(mat2 m) {
  return mat2( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0));
}
mat3 xll_saturate_mf3x3(mat3 m) {
  return mat3( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0));
}
mat4 xll_saturate_mf4x4(mat4 m) {
  return mat4( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0), clamp(m[3], 0.0, 1.0));
}
#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 326
struct SurfaceOutput {
    lowp vec3 Albedo;
    lowp vec3 Normal;
    lowp vec3 Emission;
    mediump float Specular;
    lowp float Gloss;
    lowp float Alpha;
};
#line 523
struct v2f {
    highp vec4 pos;
    highp float viewDist;
    highp vec3 viewDir;
    highp vec3 worldPos;
    highp vec4 _LightCoord;
    highp vec3 sphereNormal;
};
#line 515
struct appdata_t {
    highp vec4 vertex;
    highp vec3 normal;
    highp vec4 texcoord;
    highp vec4 texcoord2;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform highp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform sampler2D _LightTexture0;
uniform highp mat4 _LightMatrix0;
uniform sampler2D _LightTextureB0;
#line 336
uniform lowp vec4 _LightColor0;
uniform lowp vec4 _SpecColor;
#line 349
#line 357
#line 371
uniform highp mat4 _MainRotation;
uniform highp mat4 _DetailRotation;
#line 404
#line 408
#line 417
#line 425
#line 434
#line 442
#line 455
#line 467
#line 483
#line 496
uniform lowp vec4 _SurfaceColor;
#line 504
uniform highp float _Shininess;
uniform sampler2D _MainTex;
uniform sampler2D _DetailTex;
uniform highp float _DetailScale;
#line 508
uniform highp float _DetailDist;
uniform highp float _MinLight;
uniform sampler2D _CameraDepthTexture;
uniform highp mat4 _CameraToWorld;
#line 512
uniform highp float _LightPower;
uniform highp float _PlanetOpacity;
uniform highp vec3 _PlanetOrigin;
#line 533
#line 408
highp vec4 Derivatives( in highp float lat, in highp float lon, in highp vec3 pos ) {
    highp vec2 latLong = vec2( lat, lon);
    highp float latDdx = (0.159155 * length(xll_dFdx_vf2(pos.xz)));
    #line 412
    highp float latDdy = (0.159155 * length(xll_dFdy_vf2(pos.xz)));
    highp float longDdx = xll_dFdx_f(lon);
    highp float longDdy = xll_dFdy_f(lon);
    return vec4( latDdx, longDdx, latDdy, longDdy);
}
#line 417
highp vec2 GetSphereUV( in highp vec3 sphereVect, in highp vec2 uvOffset ) {
    highp vec2 uv;
    uv.x = (0.5 + (0.159155 * atan( sphereVect.x, sphereVect.z)));
    #line 421
    uv.y = (0.31831 * acos(sphereVect.y));
    uv += uvOffset;
    return uv;
}
#line 455
mediump vec4 GetShereDetailMap( in sampler2D texSampler, in highp vec3 sphereVect, in highp float detailScale ) {
    highp vec3 sphereVectNorm = normalize(sphereVect);
    highp vec2 uv = ((GetSphereUV( sphereVectNorm, vec2( 0.0, 0.0)) * 4.0) * detailScale);
    #line 459
    highp vec4 uvdd = Derivatives( (uv.x - 0.5), uv.y, sphereVectNorm);
    sphereVectNorm = abs(sphereVectNorm);
    mediump float zxlerp = step( sphereVectNorm.x, sphereVectNorm.z);
    mediump float nylerp = step( sphereVectNorm.y, mix( sphereVectNorm.x, sphereVectNorm.z, zxlerp));
    #line 463
    mediump vec3 detailCoords = mix( sphereVectNorm.xyz, sphereVectNorm.zxy, vec3( zxlerp));
    detailCoords = mix( sphereVectNorm.yxz, detailCoords, vec3( nylerp));
    return xll_tex2Dgrad( texSampler, (((0.5 * detailCoords.zy) / abs(detailCoords.x)) * detailScale), uvdd.xy, uvdd.zw);
}
#line 434
mediump vec4 GetSphereMap( in sampler2D texSampler, in highp vec3 sphereVect ) {
    highp vec3 sphereVectNorm = normalize(sphereVect);
    highp vec2 uv = GetSphereUV( sphereVectNorm, vec2( 0.0, 0.0));
    #line 438
    highp vec4 uvdd = Derivatives( (uv.x - 0.5), uv.y, sphereVectNorm);
    mediump vec4 tex = xll_tex2Dgrad( texSampler, uv, uvdd.xy, uvdd.zw);
    return tex;
}
#line 483
mediump vec4 SpecularColorLight( in mediump vec3 lightDir, in mediump vec3 viewDir, in mediump vec3 normal, in mediump vec4 color, in mediump vec4 specColor, in highp float specK, in mediump float atten ) {
    lightDir = normalize(lightDir);
    viewDir = normalize(viewDir);
    #line 487
    mediump vec3 h = normalize((lightDir + viewDir));
    mediump float diffuse = dot( normal, lightDir);
    highp float nh = xll_saturate_f(dot( h, normal));
    highp float spec = (pow( nh, specK) * color.w);
    #line 491
    mediump vec4 c;
    c.xyz = ((((color.xyz * _LightColor0.xyz) * diffuse) + ((_LightColor0.xyz * specColor.xyz) * spec)) * (atten * 4.0));
    c.w = (diffuse * (atten * 4.0));
    return c;
}
#line 322
lowp float UnitySpotAttenuate( in highp vec3 LightCoord ) {
    #line 324
    return texture( _LightTextureB0, vec2( dot( LightCoord, LightCoord))).w;
}
#line 318
lowp float UnitySpotCookie( in highp vec4 LightCoord ) {
    #line 320
    return texture( _LightTexture0, ((LightCoord.xy / LightCoord.w) + 0.5)).w;
}
#line 547
lowp vec4 frag( in v2f IN ) {
    #line 549
    mediump vec4 color;
    highp vec3 sphereNrm = IN.sphereNormal;
    mediump vec4 main = GetSphereMap( _MainTex, sphereNrm);
    mediump vec4 detail = GetShereDetailMap( _DetailTex, sphereNrm, _DetailScale);
    #line 553
    color = _SurfaceColor;
    mediump float detailLevel = xll_saturate_f(((2.0 * _DetailDist) * IN.viewDist));
    color.xyz += (0.5 * mix( (detail.xyz - 0.5), vec3( 0.0), vec3( detailLevel)));
    mediump float handoff = xll_saturate_f(pow( _PlanetOpacity, 2.0));
    #line 557
    color.xyz = mix( color.xyz, main.xyz, vec3( handoff));
    mediump vec4 specColor = _SpecColor;
    specColor.w = mix( 1.0, main.w, handoff);
    mediump vec4 colorLight = SpecularColorLight( vec3( normalize(_WorldSpaceLightPos0)), IN.viewDir, normalize((IN.worldPos - _PlanetOrigin)), color, specColor, (_Shininess * 128.0), (((float((IN._LightCoord.z > 0.0)) * UnitySpotCookie( IN._LightCoord)) * UnitySpotAttenuate( IN._LightCoord.xyz)) * 1.0));
    #line 561
    color.w = mix( 1.0, color.w, xll_saturate_f((colorLight.w * 4.0)));
    color.w = mix( color.w, 1.0, xll_saturate_f((length(colorLight.xyz) - length((2.0 * color.xyz)))));
    color.w = mix( color.w, 1.0, handoff);
    color.xyz = colorLight.xyz;
    #line 565
    return color;
}
in highp float xlv_TEXCOORD0;
in highp vec3 xlv_TEXCOORD1;
in highp vec3 xlv_TEXCOORD2;
in highp vec4 xlv_TEXCOORD3;
in highp vec3 xlv_TEXCOORD5;
void main() {
    lowp vec4 xl_retval;
    v2f xlt_IN;
    xlt_IN.pos = vec4(0.0);
    xlt_IN.viewDist = float(xlv_TEXCOORD0);
    xlt_IN.viewDir = vec3(xlv_TEXCOORD1);
    xlt_IN.worldPos = vec3(xlv_TEXCOORD2);
    xlt_IN._LightCoord = vec4(xlv_TEXCOORD3);
    xlt_IN.sphereNormal = vec3(xlv_TEXCOORD5);
    xl_retval = frag( xlt_IN);
    gl_FragData[0] = vec4(xl_retval);
}


#endif"
}

SubProgram "opengl " {
Keywords { "POINT_COOKIE" "SHADOWS_OFF" }
"!!GLSL
#ifdef VERTEX
varying vec3 xlv_TEXCOORD5;
varying vec3 xlv_TEXCOORD3;
varying vec3 xlv_TEXCOORD2;
varying vec3 xlv_TEXCOORD1;
varying float xlv_TEXCOORD0;
uniform mat4 _LightMatrix0;
uniform mat4 _Object2World;

uniform vec3 _WorldSpaceCameraPos;
void main ()
{
  vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * gl_Vertex).xyz;
  vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  vec4 tmpvar_3;
  tmpvar_3.x = gl_MultiTexCoord0.x;
  tmpvar_3.y = gl_MultiTexCoord0.y;
  tmpvar_3.z = gl_MultiTexCoord1.x;
  tmpvar_3.w = gl_MultiTexCoord1.y;
  gl_Position = (gl_ModelViewProjectionMatrix * gl_Vertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * gl_Vertex)).xyz;
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}


#endif
#ifdef FRAGMENT
#extension GL_ARB_shader_texture_lod : enable
varying vec3 xlv_TEXCOORD5;
varying vec3 xlv_TEXCOORD3;
varying vec3 xlv_TEXCOORD2;
varying vec3 xlv_TEXCOORD1;
varying float xlv_TEXCOORD0;
uniform vec3 _PlanetOrigin;
uniform float _PlanetOpacity;
uniform float _DetailDist;
uniform float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform float _Shininess;
uniform vec4 _SurfaceColor;
uniform vec4 _SpecColor;
uniform vec4 _LightColor0;
uniform sampler2D _LightTextureB0;
uniform samplerCube _LightTexture0;
uniform vec4 _WorldSpaceLightPos0;
void main ()
{
  vec4 main_1;
  vec4 color_2;
  vec3 tmpvar_3;
  tmpvar_3 = normalize(xlv_TEXCOORD5);
  vec2 uv_4;
  float r_5;
  if ((abs(tmpvar_3.z) > (1e-08 * abs(tmpvar_3.x)))) {
    float y_over_x_6;
    y_over_x_6 = (tmpvar_3.x / tmpvar_3.z);
    float s_7;
    float x_8;
    x_8 = (y_over_x_6 * inversesqrt(((y_over_x_6 * y_over_x_6) + 1.0)));
    s_7 = (sign(x_8) * (1.5708 - (sqrt((1.0 - abs(x_8))) * (1.5708 + (abs(x_8) * (-0.214602 + (abs(x_8) * (0.0865667 + (abs(x_8) * -0.0310296)))))))));
    r_5 = s_7;
    if ((tmpvar_3.z < 0.0)) {
      if ((tmpvar_3.x >= 0.0)) {
        r_5 = (s_7 + 3.14159);
      } else {
        r_5 = (r_5 - 3.14159);
      };
    };
  } else {
    r_5 = (sign(tmpvar_3.x) * 1.5708);
  };
  uv_4.x = (0.5 + (0.159155 * r_5));
  uv_4.y = (0.31831 * (1.5708 - (sign(tmpvar_3.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_3.y))) * (1.5708 + (abs(tmpvar_3.y) * (-0.214602 + (abs(tmpvar_3.y) * (0.0865667 + (abs(tmpvar_3.y) * -0.0310296)))))))))));
  vec2 tmpvar_9;
  tmpvar_9 = dFdx(tmpvar_3.xz);
  vec2 tmpvar_10;
  tmpvar_10 = dFdy(tmpvar_3.xz);
  vec4 tmpvar_11;
  tmpvar_11.x = (0.159155 * sqrt(dot (tmpvar_9, tmpvar_9)));
  tmpvar_11.y = dFdx(uv_4.y);
  tmpvar_11.z = (0.159155 * sqrt(dot (tmpvar_10, tmpvar_10)));
  tmpvar_11.w = dFdy(uv_4.y);
  main_1 = texture2DGradARB (_MainTex, uv_4, tmpvar_11.xy, tmpvar_11.zw);
  vec3 tmpvar_12;
  tmpvar_12 = normalize(xlv_TEXCOORD5);
  vec2 uv_13;
  float r_14;
  if ((abs(tmpvar_12.z) > (1e-08 * abs(tmpvar_12.x)))) {
    float y_over_x_15;
    y_over_x_15 = (tmpvar_12.x / tmpvar_12.z);
    float s_16;
    float x_17;
    x_17 = (y_over_x_15 * inversesqrt(((y_over_x_15 * y_over_x_15) + 1.0)));
    s_16 = (sign(x_17) * (1.5708 - (sqrt((1.0 - abs(x_17))) * (1.5708 + (abs(x_17) * (-0.214602 + (abs(x_17) * (0.0865667 + (abs(x_17) * -0.0310296)))))))));
    r_14 = s_16;
    if ((tmpvar_12.z < 0.0)) {
      if ((tmpvar_12.x >= 0.0)) {
        r_14 = (s_16 + 3.14159);
      } else {
        r_14 = (r_14 - 3.14159);
      };
    };
  } else {
    r_14 = (sign(tmpvar_12.x) * 1.5708);
  };
  uv_13.x = (0.5 + (0.159155 * r_14));
  uv_13.y = (0.31831 * (1.5708 - (sign(tmpvar_12.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_12.y))) * (1.5708 + (abs(tmpvar_12.y) * (-0.214602 + (abs(tmpvar_12.y) * (0.0865667 + (abs(tmpvar_12.y) * -0.0310296)))))))))));
  vec2 tmpvar_18;
  tmpvar_18 = ((uv_13 * 4.0) * _DetailScale);
  vec2 tmpvar_19;
  tmpvar_19 = dFdx(tmpvar_12.xz);
  vec2 tmpvar_20;
  tmpvar_20 = dFdy(tmpvar_12.xz);
  vec4 tmpvar_21;
  tmpvar_21.x = (0.159155 * sqrt(dot (tmpvar_19, tmpvar_19)));
  tmpvar_21.y = dFdx(tmpvar_18.y);
  tmpvar_21.z = (0.159155 * sqrt(dot (tmpvar_20, tmpvar_20)));
  tmpvar_21.w = dFdy(tmpvar_18.y);
  vec3 tmpvar_22;
  tmpvar_22 = abs(tmpvar_12);
  float tmpvar_23;
  tmpvar_23 = float((tmpvar_22.z >= tmpvar_22.x));
  vec3 tmpvar_24;
  tmpvar_24 = mix (tmpvar_22.yxz, mix (tmpvar_22, tmpvar_22.zxy, vec3(tmpvar_23)), vec3(float((mix (tmpvar_22.x, tmpvar_22.z, tmpvar_23) >= tmpvar_22.y))));
  color_2.w = _SurfaceColor.w;
  color_2.xyz = (_SurfaceColor.xyz + (0.5 * mix ((texture2DGradARB (_DetailTex, (((0.5 * tmpvar_24.zy) / abs(tmpvar_24.x)) * _DetailScale), tmpvar_21.xy, tmpvar_21.zw).xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0)))));
  float tmpvar_25;
  tmpvar_25 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  color_2.xyz = mix (color_2.xyz, main_1.xyz, vec3(tmpvar_25));
  vec3 tmpvar_26;
  tmpvar_26 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  float atten_27;
  atten_27 = (texture2D (_LightTextureB0, vec2(dot (xlv_TEXCOORD3, xlv_TEXCOORD3))).w * textureCube (_LightTexture0, xlv_TEXCOORD3).w);
  vec4 c_28;
  vec3 tmpvar_29;
  tmpvar_29 = normalize(normalize(_WorldSpaceLightPos0).xyz);
  float tmpvar_30;
  tmpvar_30 = dot (tmpvar_26, tmpvar_29);
  c_28.xyz = ((((color_2.xyz * _LightColor0.xyz) * tmpvar_30) + ((_LightColor0.xyz * _SpecColor.xyz) * (pow (clamp (dot (normalize((tmpvar_29 + normalize(xlv_TEXCOORD1))), tmpvar_26), 0.0, 1.0), (_Shininess * 128.0)) * _SurfaceColor.w))) * (atten_27 * 4.0));
  c_28.w = (tmpvar_30 * (atten_27 * 4.0));
  color_2.w = mix (1.0, _SurfaceColor.w, clamp ((c_28.w * 4.0), 0.0, 1.0));
  vec3 arg0_31;
  arg0_31 = (2.0 * color_2.xyz);
  color_2.w = mix (color_2.w, 1.0, clamp ((sqrt(dot (c_28.xyz, c_28.xyz)) - sqrt(dot (arg0_31, arg0_31))), 0.0, 1.0));
  color_2.w = mix (color_2.w, 1.0, tmpvar_25);
  color_2.xyz = c_28.xyz;
  gl_FragData[0] = color_2;
}


#endif
"
}

SubProgram "d3d9 " {
Keywords { "POINT_COOKIE" "SHADOWS_OFF" }
Bind "vertex" Vertex
Bind "texcoord" TexCoord0
Bind "texcoord1" TexCoord1
Matrix 0 [glstate_matrix_mvp]
Vector 12 [_WorldSpaceCameraPos]
Matrix 4 [_Object2World]
Matrix 8 [_LightMatrix0]
"vs_3_0
; 24 ALU
dcl_position o0
dcl_texcoord0 o1
dcl_texcoord1 o2
dcl_texcoord2 o3
dcl_texcoord3 o4
dcl_texcoord5 o5
dcl_position0 v0
dcl_texcoord0 v1
dcl_texcoord1 v2
mov r1.zw, v2.xyxy
mov r1.xy, v1
dp4 r0.w, r1, r1
rsq r1.w, r0.w
mul r1.xyz, r1.w, r1
dp4 r0.z, v0, c6
dp4 r0.x, v0, c4
dp4 r0.y, v0, c5
add r2.xyz, -r0, c12
dp3 r0.w, r2, r2
rsq r0.w, r0.w
mov o5.xyz, -r1
mov r1.xyz, r0
dp4 r1.w, v0, c7
mul o2.xyz, r0.w, r2
dp4 o4.z, r1, c10
dp4 o4.y, r1, c9
dp4 o4.x, r1, c8
rcp o1.x, r0.w
mov o3.xyz, r0
dp4 o0.w, v0, c3
dp4 o0.z, v0, c2
dp4 o0.y, v0, c1
dp4 o0.x, v0, c0
"
}

SubProgram "gles " {
Keywords { "POINT_COOKIE" "SHADOWS_OFF" }
"!!GLES


#ifdef VERTEX

varying highp vec3 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp mat4 _LightMatrix0;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_mvp;
uniform highp vec3 _WorldSpaceCameraPos;
attribute vec4 _glesMultiTexCoord1;
attribute vec4 _glesMultiTexCoord0;
attribute vec4 _glesVertex;
void main ()
{
  highp vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * _glesVertex).xyz;
  highp vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  highp vec4 tmpvar_3;
  tmpvar_3.x = _glesMultiTexCoord0.x;
  tmpvar_3.y = _glesMultiTexCoord0.y;
  tmpvar_3.z = _glesMultiTexCoord1.x;
  tmpvar_3.w = _glesMultiTexCoord1.y;
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * _glesVertex)).xyz;
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}



#endif
#ifdef FRAGMENT

#extension GL_EXT_shader_texture_lod : enable
#extension GL_OES_standard_derivatives : enable
varying highp vec3 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp vec3 _PlanetOrigin;
uniform highp float _PlanetOpacity;
uniform highp float _DetailDist;
uniform highp float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform highp float _Shininess;
uniform lowp vec4 _SurfaceColor;
uniform lowp vec4 _SpecColor;
uniform lowp vec4 _LightColor0;
uniform sampler2D _LightTextureB0;
uniform samplerCube _LightTexture0;
uniform highp vec4 _WorldSpaceLightPos0;
void main ()
{
  lowp vec4 tmpvar_1;
  mediump vec4 specColor_2;
  mediump float handoff_3;
  mediump float detailLevel_4;
  mediump vec4 color_5;
  mediump vec4 tex_6;
  highp vec3 tmpvar_7;
  tmpvar_7 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_8;
  highp float r_9;
  if ((abs(tmpvar_7.z) > (1e-08 * abs(tmpvar_7.x)))) {
    highp float y_over_x_10;
    y_over_x_10 = (tmpvar_7.x / tmpvar_7.z);
    highp float s_11;
    highp float x_12;
    x_12 = (y_over_x_10 * inversesqrt(((y_over_x_10 * y_over_x_10) + 1.0)));
    s_11 = (sign(x_12) * (1.5708 - (sqrt((1.0 - abs(x_12))) * (1.5708 + (abs(x_12) * (-0.214602 + (abs(x_12) * (0.0865667 + (abs(x_12) * -0.0310296)))))))));
    r_9 = s_11;
    if ((tmpvar_7.z < 0.0)) {
      if ((tmpvar_7.x >= 0.0)) {
        r_9 = (s_11 + 3.14159);
      } else {
        r_9 = (r_9 - 3.14159);
      };
    };
  } else {
    r_9 = (sign(tmpvar_7.x) * 1.5708);
  };
  uv_8.x = (0.5 + (0.159155 * r_9));
  uv_8.y = (0.31831 * (1.5708 - (sign(tmpvar_7.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_7.y))) * (1.5708 + (abs(tmpvar_7.y) * (-0.214602 + (abs(tmpvar_7.y) * (0.0865667 + (abs(tmpvar_7.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_13;
  tmpvar_13 = dFdx(tmpvar_7.xz);
  highp vec2 tmpvar_14;
  tmpvar_14 = dFdy(tmpvar_7.xz);
  highp vec4 tmpvar_15;
  tmpvar_15.x = (0.159155 * sqrt(dot (tmpvar_13, tmpvar_13)));
  tmpvar_15.y = dFdx(uv_8.y);
  tmpvar_15.z = (0.159155 * sqrt(dot (tmpvar_14, tmpvar_14)));
  tmpvar_15.w = dFdy(uv_8.y);
  lowp vec4 tmpvar_16;
  tmpvar_16 = texture2DGradEXT (_MainTex, uv_8, tmpvar_15.xy, tmpvar_15.zw);
  tex_6 = tmpvar_16;
  mediump vec4 tmpvar_17;
  mediump vec3 detailCoords_18;
  mediump float nylerp_19;
  mediump float zxlerp_20;
  highp vec3 tmpvar_21;
  tmpvar_21 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_22;
  highp float r_23;
  if ((abs(tmpvar_21.z) > (1e-08 * abs(tmpvar_21.x)))) {
    highp float y_over_x_24;
    y_over_x_24 = (tmpvar_21.x / tmpvar_21.z);
    highp float s_25;
    highp float x_26;
    x_26 = (y_over_x_24 * inversesqrt(((y_over_x_24 * y_over_x_24) + 1.0)));
    s_25 = (sign(x_26) * (1.5708 - (sqrt((1.0 - abs(x_26))) * (1.5708 + (abs(x_26) * (-0.214602 + (abs(x_26) * (0.0865667 + (abs(x_26) * -0.0310296)))))))));
    r_23 = s_25;
    if ((tmpvar_21.z < 0.0)) {
      if ((tmpvar_21.x >= 0.0)) {
        r_23 = (s_25 + 3.14159);
      } else {
        r_23 = (r_23 - 3.14159);
      };
    };
  } else {
    r_23 = (sign(tmpvar_21.x) * 1.5708);
  };
  uv_22.x = (0.5 + (0.159155 * r_23));
  uv_22.y = (0.31831 * (1.5708 - (sign(tmpvar_21.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_21.y))) * (1.5708 + (abs(tmpvar_21.y) * (-0.214602 + (abs(tmpvar_21.y) * (0.0865667 + (abs(tmpvar_21.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_27;
  tmpvar_27 = ((uv_22 * 4.0) * _DetailScale);
  highp vec2 tmpvar_28;
  tmpvar_28 = dFdx(tmpvar_21.xz);
  highp vec2 tmpvar_29;
  tmpvar_29 = dFdy(tmpvar_21.xz);
  highp vec4 tmpvar_30;
  tmpvar_30.x = (0.159155 * sqrt(dot (tmpvar_28, tmpvar_28)));
  tmpvar_30.y = dFdx(tmpvar_27.y);
  tmpvar_30.z = (0.159155 * sqrt(dot (tmpvar_29, tmpvar_29)));
  tmpvar_30.w = dFdy(tmpvar_27.y);
  highp vec3 tmpvar_31;
  tmpvar_31 = abs(tmpvar_21);
  highp float tmpvar_32;
  tmpvar_32 = float((tmpvar_31.z >= tmpvar_31.x));
  zxlerp_20 = tmpvar_32;
  highp float tmpvar_33;
  tmpvar_33 = float((mix (tmpvar_31.x, tmpvar_31.z, zxlerp_20) >= tmpvar_31.y));
  nylerp_19 = tmpvar_33;
  highp vec3 tmpvar_34;
  tmpvar_34 = mix (tmpvar_31, tmpvar_31.zxy, vec3(zxlerp_20));
  detailCoords_18 = tmpvar_34;
  highp vec3 tmpvar_35;
  tmpvar_35 = mix (tmpvar_31.yxz, detailCoords_18, vec3(nylerp_19));
  detailCoords_18 = tmpvar_35;
  mediump float tmpvar_36;
  tmpvar_36 = abs(detailCoords_18.x);
  highp vec2 coord_37;
  coord_37 = (((0.5 * detailCoords_18.zy) / tmpvar_36) * _DetailScale);
  lowp vec4 tmpvar_38;
  tmpvar_38 = texture2DGradEXT (_DetailTex, coord_37, tmpvar_30.xy, tmpvar_30.zw);
  tmpvar_17 = tmpvar_38;
  color_5 = _SurfaceColor;
  highp float tmpvar_39;
  tmpvar_39 = clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0);
  detailLevel_4 = tmpvar_39;
  color_5.xyz = (color_5.xyz + (0.5 * mix ((tmpvar_17.xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(detailLevel_4))));
  highp float tmpvar_40;
  tmpvar_40 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  handoff_3 = tmpvar_40;
  color_5.xyz = mix (color_5.xyz, tex_6.xyz, vec3(handoff_3));
  specColor_2.xyz = _SpecColor.xyz;
  specColor_2.w = mix (1.0, tex_6.w, handoff_3);
  highp vec3 tmpvar_41;
  tmpvar_41 = normalize(_WorldSpaceLightPos0).xyz;
  highp vec3 tmpvar_42;
  tmpvar_42 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  highp float tmpvar_43;
  tmpvar_43 = dot (xlv_TEXCOORD3, xlv_TEXCOORD3);
  lowp vec4 tmpvar_44;
  tmpvar_44 = texture2D (_LightTextureB0, vec2(tmpvar_43));
  lowp vec4 tmpvar_45;
  tmpvar_45 = textureCube (_LightTexture0, xlv_TEXCOORD3);
  mediump vec3 lightDir_46;
  lightDir_46 = tmpvar_41;
  mediump vec3 viewDir_47;
  viewDir_47 = xlv_TEXCOORD1;
  mediump vec3 normal_48;
  normal_48 = tmpvar_42;
  mediump float atten_49;
  atten_49 = (tmpvar_44.w * tmpvar_45.w);
  mediump vec4 c_50;
  highp float nh_51;
  mediump vec3 tmpvar_52;
  tmpvar_52 = normalize(lightDir_46);
  lightDir_46 = tmpvar_52;
  mediump vec3 tmpvar_53;
  tmpvar_53 = normalize(viewDir_47);
  viewDir_47 = tmpvar_53;
  mediump float tmpvar_54;
  tmpvar_54 = dot (normal_48, tmpvar_52);
  mediump float tmpvar_55;
  tmpvar_55 = clamp (dot (normalize((tmpvar_52 + tmpvar_53)), normal_48), 0.0, 1.0);
  nh_51 = tmpvar_55;
  highp vec3 tmpvar_56;
  tmpvar_56 = ((((color_5.xyz * _LightColor0.xyz) * tmpvar_54) + ((_LightColor0.xyz * specColor_2.xyz) * (pow (nh_51, (_Shininess * 128.0)) * color_5.w))) * (atten_49 * 4.0));
  c_50.xyz = tmpvar_56;
  c_50.w = (tmpvar_54 * (atten_49 * 4.0));
  color_5.w = mix (1.0, color_5.w, clamp ((c_50.w * 4.0), 0.0, 1.0));
  mediump vec3 arg0_57;
  arg0_57 = (2.0 * color_5.xyz);
  color_5.w = mix (color_5.w, 1.0, clamp ((sqrt(dot (c_50.xyz, c_50.xyz)) - sqrt(dot (arg0_57, arg0_57))), 0.0, 1.0));
  color_5.w = mix (color_5.w, 1.0, handoff_3);
  color_5.xyz = c_50.xyz;
  tmpvar_1 = color_5;
  gl_FragData[0] = tmpvar_1;
}



#endif"
}

SubProgram "glesdesktop " {
Keywords { "POINT_COOKIE" "SHADOWS_OFF" }
"!!GLES


#ifdef VERTEX

varying highp vec3 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp mat4 _LightMatrix0;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_mvp;
uniform highp vec3 _WorldSpaceCameraPos;
attribute vec4 _glesMultiTexCoord1;
attribute vec4 _glesMultiTexCoord0;
attribute vec4 _glesVertex;
void main ()
{
  highp vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * _glesVertex).xyz;
  highp vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  highp vec4 tmpvar_3;
  tmpvar_3.x = _glesMultiTexCoord0.x;
  tmpvar_3.y = _glesMultiTexCoord0.y;
  tmpvar_3.z = _glesMultiTexCoord1.x;
  tmpvar_3.w = _glesMultiTexCoord1.y;
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * _glesVertex)).xyz;
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}



#endif
#ifdef FRAGMENT

#extension GL_EXT_shader_texture_lod : enable
#extension GL_OES_standard_derivatives : enable
varying highp vec3 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp vec3 _PlanetOrigin;
uniform highp float _PlanetOpacity;
uniform highp float _DetailDist;
uniform highp float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform highp float _Shininess;
uniform lowp vec4 _SurfaceColor;
uniform lowp vec4 _SpecColor;
uniform lowp vec4 _LightColor0;
uniform sampler2D _LightTextureB0;
uniform samplerCube _LightTexture0;
uniform highp vec4 _WorldSpaceLightPos0;
void main ()
{
  lowp vec4 tmpvar_1;
  mediump vec4 specColor_2;
  mediump float handoff_3;
  mediump float detailLevel_4;
  mediump vec4 color_5;
  mediump vec4 tex_6;
  highp vec3 tmpvar_7;
  tmpvar_7 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_8;
  highp float r_9;
  if ((abs(tmpvar_7.z) > (1e-08 * abs(tmpvar_7.x)))) {
    highp float y_over_x_10;
    y_over_x_10 = (tmpvar_7.x / tmpvar_7.z);
    highp float s_11;
    highp float x_12;
    x_12 = (y_over_x_10 * inversesqrt(((y_over_x_10 * y_over_x_10) + 1.0)));
    s_11 = (sign(x_12) * (1.5708 - (sqrt((1.0 - abs(x_12))) * (1.5708 + (abs(x_12) * (-0.214602 + (abs(x_12) * (0.0865667 + (abs(x_12) * -0.0310296)))))))));
    r_9 = s_11;
    if ((tmpvar_7.z < 0.0)) {
      if ((tmpvar_7.x >= 0.0)) {
        r_9 = (s_11 + 3.14159);
      } else {
        r_9 = (r_9 - 3.14159);
      };
    };
  } else {
    r_9 = (sign(tmpvar_7.x) * 1.5708);
  };
  uv_8.x = (0.5 + (0.159155 * r_9));
  uv_8.y = (0.31831 * (1.5708 - (sign(tmpvar_7.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_7.y))) * (1.5708 + (abs(tmpvar_7.y) * (-0.214602 + (abs(tmpvar_7.y) * (0.0865667 + (abs(tmpvar_7.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_13;
  tmpvar_13 = dFdx(tmpvar_7.xz);
  highp vec2 tmpvar_14;
  tmpvar_14 = dFdy(tmpvar_7.xz);
  highp vec4 tmpvar_15;
  tmpvar_15.x = (0.159155 * sqrt(dot (tmpvar_13, tmpvar_13)));
  tmpvar_15.y = dFdx(uv_8.y);
  tmpvar_15.z = (0.159155 * sqrt(dot (tmpvar_14, tmpvar_14)));
  tmpvar_15.w = dFdy(uv_8.y);
  lowp vec4 tmpvar_16;
  tmpvar_16 = texture2DGradEXT (_MainTex, uv_8, tmpvar_15.xy, tmpvar_15.zw);
  tex_6 = tmpvar_16;
  mediump vec4 tmpvar_17;
  mediump vec3 detailCoords_18;
  mediump float nylerp_19;
  mediump float zxlerp_20;
  highp vec3 tmpvar_21;
  tmpvar_21 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_22;
  highp float r_23;
  if ((abs(tmpvar_21.z) > (1e-08 * abs(tmpvar_21.x)))) {
    highp float y_over_x_24;
    y_over_x_24 = (tmpvar_21.x / tmpvar_21.z);
    highp float s_25;
    highp float x_26;
    x_26 = (y_over_x_24 * inversesqrt(((y_over_x_24 * y_over_x_24) + 1.0)));
    s_25 = (sign(x_26) * (1.5708 - (sqrt((1.0 - abs(x_26))) * (1.5708 + (abs(x_26) * (-0.214602 + (abs(x_26) * (0.0865667 + (abs(x_26) * -0.0310296)))))))));
    r_23 = s_25;
    if ((tmpvar_21.z < 0.0)) {
      if ((tmpvar_21.x >= 0.0)) {
        r_23 = (s_25 + 3.14159);
      } else {
        r_23 = (r_23 - 3.14159);
      };
    };
  } else {
    r_23 = (sign(tmpvar_21.x) * 1.5708);
  };
  uv_22.x = (0.5 + (0.159155 * r_23));
  uv_22.y = (0.31831 * (1.5708 - (sign(tmpvar_21.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_21.y))) * (1.5708 + (abs(tmpvar_21.y) * (-0.214602 + (abs(tmpvar_21.y) * (0.0865667 + (abs(tmpvar_21.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_27;
  tmpvar_27 = ((uv_22 * 4.0) * _DetailScale);
  highp vec2 tmpvar_28;
  tmpvar_28 = dFdx(tmpvar_21.xz);
  highp vec2 tmpvar_29;
  tmpvar_29 = dFdy(tmpvar_21.xz);
  highp vec4 tmpvar_30;
  tmpvar_30.x = (0.159155 * sqrt(dot (tmpvar_28, tmpvar_28)));
  tmpvar_30.y = dFdx(tmpvar_27.y);
  tmpvar_30.z = (0.159155 * sqrt(dot (tmpvar_29, tmpvar_29)));
  tmpvar_30.w = dFdy(tmpvar_27.y);
  highp vec3 tmpvar_31;
  tmpvar_31 = abs(tmpvar_21);
  highp float tmpvar_32;
  tmpvar_32 = float((tmpvar_31.z >= tmpvar_31.x));
  zxlerp_20 = tmpvar_32;
  highp float tmpvar_33;
  tmpvar_33 = float((mix (tmpvar_31.x, tmpvar_31.z, zxlerp_20) >= tmpvar_31.y));
  nylerp_19 = tmpvar_33;
  highp vec3 tmpvar_34;
  tmpvar_34 = mix (tmpvar_31, tmpvar_31.zxy, vec3(zxlerp_20));
  detailCoords_18 = tmpvar_34;
  highp vec3 tmpvar_35;
  tmpvar_35 = mix (tmpvar_31.yxz, detailCoords_18, vec3(nylerp_19));
  detailCoords_18 = tmpvar_35;
  mediump float tmpvar_36;
  tmpvar_36 = abs(detailCoords_18.x);
  highp vec2 coord_37;
  coord_37 = (((0.5 * detailCoords_18.zy) / tmpvar_36) * _DetailScale);
  lowp vec4 tmpvar_38;
  tmpvar_38 = texture2DGradEXT (_DetailTex, coord_37, tmpvar_30.xy, tmpvar_30.zw);
  tmpvar_17 = tmpvar_38;
  color_5 = _SurfaceColor;
  highp float tmpvar_39;
  tmpvar_39 = clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0);
  detailLevel_4 = tmpvar_39;
  color_5.xyz = (color_5.xyz + (0.5 * mix ((tmpvar_17.xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(detailLevel_4))));
  highp float tmpvar_40;
  tmpvar_40 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  handoff_3 = tmpvar_40;
  color_5.xyz = mix (color_5.xyz, tex_6.xyz, vec3(handoff_3));
  specColor_2.xyz = _SpecColor.xyz;
  specColor_2.w = mix (1.0, tex_6.w, handoff_3);
  highp vec3 tmpvar_41;
  tmpvar_41 = normalize(_WorldSpaceLightPos0).xyz;
  highp vec3 tmpvar_42;
  tmpvar_42 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  highp float tmpvar_43;
  tmpvar_43 = dot (xlv_TEXCOORD3, xlv_TEXCOORD3);
  lowp vec4 tmpvar_44;
  tmpvar_44 = texture2D (_LightTextureB0, vec2(tmpvar_43));
  lowp vec4 tmpvar_45;
  tmpvar_45 = textureCube (_LightTexture0, xlv_TEXCOORD3);
  mediump vec3 lightDir_46;
  lightDir_46 = tmpvar_41;
  mediump vec3 viewDir_47;
  viewDir_47 = xlv_TEXCOORD1;
  mediump vec3 normal_48;
  normal_48 = tmpvar_42;
  mediump float atten_49;
  atten_49 = (tmpvar_44.w * tmpvar_45.w);
  mediump vec4 c_50;
  highp float nh_51;
  mediump vec3 tmpvar_52;
  tmpvar_52 = normalize(lightDir_46);
  lightDir_46 = tmpvar_52;
  mediump vec3 tmpvar_53;
  tmpvar_53 = normalize(viewDir_47);
  viewDir_47 = tmpvar_53;
  mediump float tmpvar_54;
  tmpvar_54 = dot (normal_48, tmpvar_52);
  mediump float tmpvar_55;
  tmpvar_55 = clamp (dot (normalize((tmpvar_52 + tmpvar_53)), normal_48), 0.0, 1.0);
  nh_51 = tmpvar_55;
  highp vec3 tmpvar_56;
  tmpvar_56 = ((((color_5.xyz * _LightColor0.xyz) * tmpvar_54) + ((_LightColor0.xyz * specColor_2.xyz) * (pow (nh_51, (_Shininess * 128.0)) * color_5.w))) * (atten_49 * 4.0));
  c_50.xyz = tmpvar_56;
  c_50.w = (tmpvar_54 * (atten_49 * 4.0));
  color_5.w = mix (1.0, color_5.w, clamp ((c_50.w * 4.0), 0.0, 1.0));
  mediump vec3 arg0_57;
  arg0_57 = (2.0 * color_5.xyz);
  color_5.w = mix (color_5.w, 1.0, clamp ((sqrt(dot (c_50.xyz, c_50.xyz)) - sqrt(dot (arg0_57, arg0_57))), 0.0, 1.0));
  color_5.w = mix (color_5.w, 1.0, handoff_3);
  color_5.xyz = c_50.xyz;
  tmpvar_1 = color_5;
  gl_FragData[0] = tmpvar_1;
}



#endif"
}

SubProgram "gles3 " {
Keywords { "POINT_COOKIE" "SHADOWS_OFF" }
"!!GLES3#version 300 es


#ifdef VERTEX

#define gl_Vertex _glesVertex
in vec4 _glesVertex;
#define gl_Normal (normalize(_glesNormal))
in vec3 _glesNormal;
#define gl_MultiTexCoord0 _glesMultiTexCoord0
in vec4 _glesMultiTexCoord0;
#define gl_MultiTexCoord1 _glesMultiTexCoord1
in vec4 _glesMultiTexCoord1;

#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 318
struct SurfaceOutput {
    lowp vec3 Albedo;
    lowp vec3 Normal;
    lowp vec3 Emission;
    mediump float Specular;
    lowp float Gloss;
    lowp float Alpha;
};
#line 515
struct v2f {
    highp vec4 pos;
    highp float viewDist;
    highp vec3 viewDir;
    highp vec3 worldPos;
    highp vec3 _LightCoord;
    highp vec3 sphereNormal;
};
#line 507
struct appdata_t {
    highp vec4 vertex;
    highp vec3 normal;
    highp vec4 texcoord;
    highp vec4 texcoord2;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform highp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform samplerCube _LightTexture0;
uniform highp mat4 _LightMatrix0;
uniform sampler2D _LightTextureB0;
#line 328
uniform lowp vec4 _LightColor0;
uniform lowp vec4 _SpecColor;
#line 341
#line 349
#line 363
uniform highp mat4 _MainRotation;
uniform highp mat4 _DetailRotation;
#line 396
#line 400
#line 409
#line 417
#line 426
#line 434
#line 447
#line 459
#line 475
#line 488
uniform lowp vec4 _SurfaceColor;
#line 496
uniform highp float _Shininess;
uniform sampler2D _MainTex;
uniform sampler2D _DetailTex;
uniform highp float _DetailScale;
#line 500
uniform highp float _DetailDist;
uniform highp float _MinLight;
uniform sampler2D _CameraDepthTexture;
uniform highp mat4 _CameraToWorld;
#line 504
uniform highp float _LightPower;
uniform highp float _PlanetOpacity;
uniform highp vec3 _PlanetOrigin;
#line 525
#line 525
v2f vert( in appdata_t v ) {
    v2f o;
    highp vec4 vertex = v.vertex;
    #line 529
    o.pos = (glstate_matrix_mvp * vertex).xyzw;
    highp vec3 vertexPos = (_Object2World * vertex).xyz;
    o.viewDist = distance( vertexPos, _WorldSpaceCameraPos);
    o.worldPos = vertexPos;
    #line 533
    o.sphereNormal = (-normalize(vec4( v.texcoord.x, v.texcoord.y, v.texcoord2.x, v.texcoord2.y)).xyz);
    o.viewDir = normalize((_WorldSpaceCameraPos.xyz - vertexPos));
    o._LightCoord = (_LightMatrix0 * (_Object2World * v.vertex)).xyz;
    #line 537
    return o;
}
out highp float xlv_TEXCOORD0;
out highp vec3 xlv_TEXCOORD1;
out highp vec3 xlv_TEXCOORD2;
out highp vec3 xlv_TEXCOORD3;
out highp vec3 xlv_TEXCOORD5;
void main() {
    v2f xl_retval;
    appdata_t xlt_v;
    xlt_v.vertex = vec4(gl_Vertex);
    xlt_v.normal = vec3(gl_Normal);
    xlt_v.texcoord = vec4(gl_MultiTexCoord0);
    xlt_v.texcoord2 = vec4(gl_MultiTexCoord1);
    xl_retval = vert( xlt_v);
    gl_Position = vec4(xl_retval.pos);
    xlv_TEXCOORD0 = float(xl_retval.viewDist);
    xlv_TEXCOORD1 = vec3(xl_retval.viewDir);
    xlv_TEXCOORD2 = vec3(xl_retval.worldPos);
    xlv_TEXCOORD3 = vec3(xl_retval._LightCoord);
    xlv_TEXCOORD5 = vec3(xl_retval.sphereNormal);
}


#endif
#ifdef FRAGMENT

#define gl_FragData _glesFragData
layout(location = 0) out mediump vec4 _glesFragData[4];
float xll_dFdx_f(float f) {
  return dFdx(f);
}
vec2 xll_dFdx_vf2(vec2 v) {
  return dFdx(v);
}
vec3 xll_dFdx_vf3(vec3 v) {
  return dFdx(v);
}
vec4 xll_dFdx_vf4(vec4 v) {
  return dFdx(v);
}
mat2 xll_dFdx_mf2x2(mat2 m) {
  return mat2( dFdx(m[0]), dFdx(m[1]));
}
mat3 xll_dFdx_mf3x3(mat3 m) {
  return mat3( dFdx(m[0]), dFdx(m[1]), dFdx(m[2]));
}
mat4 xll_dFdx_mf4x4(mat4 m) {
  return mat4( dFdx(m[0]), dFdx(m[1]), dFdx(m[2]), dFdx(m[3]));
}
float xll_dFdy_f(float f) {
  return dFdy(f);
}
vec2 xll_dFdy_vf2(vec2 v) {
  return dFdy(v);
}
vec3 xll_dFdy_vf3(vec3 v) {
  return dFdy(v);
}
vec4 xll_dFdy_vf4(vec4 v) {
  return dFdy(v);
}
mat2 xll_dFdy_mf2x2(mat2 m) {
  return mat2( dFdy(m[0]), dFdy(m[1]));
}
mat3 xll_dFdy_mf3x3(mat3 m) {
  return mat3( dFdy(m[0]), dFdy(m[1]), dFdy(m[2]));
}
mat4 xll_dFdy_mf4x4(mat4 m) {
  return mat4( dFdy(m[0]), dFdy(m[1]), dFdy(m[2]), dFdy(m[3]));
}
vec4 xll_tex2Dgrad(sampler2D s, vec2 coord, vec2 ddx, vec2 ddy) {
   return textureGrad( s, coord, ddx, ddy);
}
float xll_saturate_f( float x) {
  return clamp( x, 0.0, 1.0);
}
vec2 xll_saturate_vf2( vec2 x) {
  return clamp( x, 0.0, 1.0);
}
vec3 xll_saturate_vf3( vec3 x) {
  return clamp( x, 0.0, 1.0);
}
vec4 xll_saturate_vf4( vec4 x) {
  return clamp( x, 0.0, 1.0);
}
mat2 xll_saturate_mf2x2(mat2 m) {
  return mat2( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0));
}
mat3 xll_saturate_mf3x3(mat3 m) {
  return mat3( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0));
}
mat4 xll_saturate_mf4x4(mat4 m) {
  return mat4( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0), clamp(m[3], 0.0, 1.0));
}
#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 318
struct SurfaceOutput {
    lowp vec3 Albedo;
    lowp vec3 Normal;
    lowp vec3 Emission;
    mediump float Specular;
    lowp float Gloss;
    lowp float Alpha;
};
#line 515
struct v2f {
    highp vec4 pos;
    highp float viewDist;
    highp vec3 viewDir;
    highp vec3 worldPos;
    highp vec3 _LightCoord;
    highp vec3 sphereNormal;
};
#line 507
struct appdata_t {
    highp vec4 vertex;
    highp vec3 normal;
    highp vec4 texcoord;
    highp vec4 texcoord2;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform highp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform samplerCube _LightTexture0;
uniform highp mat4 _LightMatrix0;
uniform sampler2D _LightTextureB0;
#line 328
uniform lowp vec4 _LightColor0;
uniform lowp vec4 _SpecColor;
#line 341
#line 349
#line 363
uniform highp mat4 _MainRotation;
uniform highp mat4 _DetailRotation;
#line 396
#line 400
#line 409
#line 417
#line 426
#line 434
#line 447
#line 459
#line 475
#line 488
uniform lowp vec4 _SurfaceColor;
#line 496
uniform highp float _Shininess;
uniform sampler2D _MainTex;
uniform sampler2D _DetailTex;
uniform highp float _DetailScale;
#line 500
uniform highp float _DetailDist;
uniform highp float _MinLight;
uniform sampler2D _CameraDepthTexture;
uniform highp mat4 _CameraToWorld;
#line 504
uniform highp float _LightPower;
uniform highp float _PlanetOpacity;
uniform highp vec3 _PlanetOrigin;
#line 525
#line 400
highp vec4 Derivatives( in highp float lat, in highp float lon, in highp vec3 pos ) {
    highp vec2 latLong = vec2( lat, lon);
    highp float latDdx = (0.159155 * length(xll_dFdx_vf2(pos.xz)));
    #line 404
    highp float latDdy = (0.159155 * length(xll_dFdy_vf2(pos.xz)));
    highp float longDdx = xll_dFdx_f(lon);
    highp float longDdy = xll_dFdy_f(lon);
    return vec4( latDdx, longDdx, latDdy, longDdy);
}
#line 409
highp vec2 GetSphereUV( in highp vec3 sphereVect, in highp vec2 uvOffset ) {
    highp vec2 uv;
    uv.x = (0.5 + (0.159155 * atan( sphereVect.x, sphereVect.z)));
    #line 413
    uv.y = (0.31831 * acos(sphereVect.y));
    uv += uvOffset;
    return uv;
}
#line 447
mediump vec4 GetShereDetailMap( in sampler2D texSampler, in highp vec3 sphereVect, in highp float detailScale ) {
    highp vec3 sphereVectNorm = normalize(sphereVect);
    highp vec2 uv = ((GetSphereUV( sphereVectNorm, vec2( 0.0, 0.0)) * 4.0) * detailScale);
    #line 451
    highp vec4 uvdd = Derivatives( (uv.x - 0.5), uv.y, sphereVectNorm);
    sphereVectNorm = abs(sphereVectNorm);
    mediump float zxlerp = step( sphereVectNorm.x, sphereVectNorm.z);
    mediump float nylerp = step( sphereVectNorm.y, mix( sphereVectNorm.x, sphereVectNorm.z, zxlerp));
    #line 455
    mediump vec3 detailCoords = mix( sphereVectNorm.xyz, sphereVectNorm.zxy, vec3( zxlerp));
    detailCoords = mix( sphereVectNorm.yxz, detailCoords, vec3( nylerp));
    return xll_tex2Dgrad( texSampler, (((0.5 * detailCoords.zy) / abs(detailCoords.x)) * detailScale), uvdd.xy, uvdd.zw);
}
#line 426
mediump vec4 GetSphereMap( in sampler2D texSampler, in highp vec3 sphereVect ) {
    highp vec3 sphereVectNorm = normalize(sphereVect);
    highp vec2 uv = GetSphereUV( sphereVectNorm, vec2( 0.0, 0.0));
    #line 430
    highp vec4 uvdd = Derivatives( (uv.x - 0.5), uv.y, sphereVectNorm);
    mediump vec4 tex = xll_tex2Dgrad( texSampler, uv, uvdd.xy, uvdd.zw);
    return tex;
}
#line 475
mediump vec4 SpecularColorLight( in mediump vec3 lightDir, in mediump vec3 viewDir, in mediump vec3 normal, in mediump vec4 color, in mediump vec4 specColor, in highp float specK, in mediump float atten ) {
    lightDir = normalize(lightDir);
    viewDir = normalize(viewDir);
    #line 479
    mediump vec3 h = normalize((lightDir + viewDir));
    mediump float diffuse = dot( normal, lightDir);
    highp float nh = xll_saturate_f(dot( h, normal));
    highp float spec = (pow( nh, specK) * color.w);
    #line 483
    mediump vec4 c;
    c.xyz = ((((color.xyz * _LightColor0.xyz) * diffuse) + ((_LightColor0.xyz * specColor.xyz) * spec)) * (atten * 4.0));
    c.w = (diffuse * (atten * 4.0));
    return c;
}
#line 539
lowp vec4 frag( in v2f IN ) {
    #line 541
    mediump vec4 color;
    highp vec3 sphereNrm = IN.sphereNormal;
    mediump vec4 main = GetSphereMap( _MainTex, sphereNrm);
    mediump vec4 detail = GetShereDetailMap( _DetailTex, sphereNrm, _DetailScale);
    #line 545
    color = _SurfaceColor;
    mediump float detailLevel = xll_saturate_f(((2.0 * _DetailDist) * IN.viewDist));
    color.xyz += (0.5 * mix( (detail.xyz - 0.5), vec3( 0.0), vec3( detailLevel)));
    mediump float handoff = xll_saturate_f(pow( _PlanetOpacity, 2.0));
    #line 549
    color.xyz = mix( color.xyz, main.xyz, vec3( handoff));
    mediump vec4 specColor = _SpecColor;
    specColor.w = mix( 1.0, main.w, handoff);
    mediump vec4 colorLight = SpecularColorLight( vec3( normalize(_WorldSpaceLightPos0)), IN.viewDir, normalize((IN.worldPos - _PlanetOrigin)), color, specColor, (_Shininess * 128.0), ((texture( _LightTextureB0, vec2( dot( IN._LightCoord, IN._LightCoord))).w * texture( _LightTexture0, IN._LightCoord).w) * 1.0));
    #line 553
    color.w = mix( 1.0, color.w, xll_saturate_f((colorLight.w * 4.0)));
    color.w = mix( color.w, 1.0, xll_saturate_f((length(colorLight.xyz) - length((2.0 * color.xyz)))));
    color.w = mix( color.w, 1.0, handoff);
    color.xyz = colorLight.xyz;
    #line 557
    return color;
}
in highp float xlv_TEXCOORD0;
in highp vec3 xlv_TEXCOORD1;
in highp vec3 xlv_TEXCOORD2;
in highp vec3 xlv_TEXCOORD3;
in highp vec3 xlv_TEXCOORD5;
void main() {
    lowp vec4 xl_retval;
    v2f xlt_IN;
    xlt_IN.pos = vec4(0.0);
    xlt_IN.viewDist = float(xlv_TEXCOORD0);
    xlt_IN.viewDir = vec3(xlv_TEXCOORD1);
    xlt_IN.worldPos = vec3(xlv_TEXCOORD2);
    xlt_IN._LightCoord = vec3(xlv_TEXCOORD3);
    xlt_IN.sphereNormal = vec3(xlv_TEXCOORD5);
    xl_retval = frag( xlt_IN);
    gl_FragData[0] = vec4(xl_retval);
}


#endif"
}

SubProgram "opengl " {
Keywords { "DIRECTIONAL_COOKIE" "SHADOWS_OFF" }
"!!GLSL
#ifdef VERTEX
varying vec3 xlv_TEXCOORD5;
varying vec2 xlv_TEXCOORD3;
varying vec3 xlv_TEXCOORD2;
varying vec3 xlv_TEXCOORD1;
varying float xlv_TEXCOORD0;
uniform mat4 _LightMatrix0;
uniform mat4 _Object2World;

uniform vec3 _WorldSpaceCameraPos;
void main ()
{
  vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * gl_Vertex).xyz;
  vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  vec4 tmpvar_3;
  tmpvar_3.x = gl_MultiTexCoord0.x;
  tmpvar_3.y = gl_MultiTexCoord0.y;
  tmpvar_3.z = gl_MultiTexCoord1.x;
  tmpvar_3.w = gl_MultiTexCoord1.y;
  gl_Position = (gl_ModelViewProjectionMatrix * gl_Vertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * gl_Vertex)).xy;
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}


#endif
#ifdef FRAGMENT
#extension GL_ARB_shader_texture_lod : enable
varying vec3 xlv_TEXCOORD5;
varying vec2 xlv_TEXCOORD3;
varying vec3 xlv_TEXCOORD2;
varying vec3 xlv_TEXCOORD1;
varying float xlv_TEXCOORD0;
uniform vec3 _PlanetOrigin;
uniform float _PlanetOpacity;
uniform float _DetailDist;
uniform float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform float _Shininess;
uniform vec4 _SurfaceColor;
uniform vec4 _SpecColor;
uniform vec4 _LightColor0;
uniform sampler2D _LightTexture0;
uniform vec4 _WorldSpaceLightPos0;
void main ()
{
  vec4 main_1;
  vec4 color_2;
  vec3 tmpvar_3;
  tmpvar_3 = normalize(xlv_TEXCOORD5);
  vec2 uv_4;
  float r_5;
  if ((abs(tmpvar_3.z) > (1e-08 * abs(tmpvar_3.x)))) {
    float y_over_x_6;
    y_over_x_6 = (tmpvar_3.x / tmpvar_3.z);
    float s_7;
    float x_8;
    x_8 = (y_over_x_6 * inversesqrt(((y_over_x_6 * y_over_x_6) + 1.0)));
    s_7 = (sign(x_8) * (1.5708 - (sqrt((1.0 - abs(x_8))) * (1.5708 + (abs(x_8) * (-0.214602 + (abs(x_8) * (0.0865667 + (abs(x_8) * -0.0310296)))))))));
    r_5 = s_7;
    if ((tmpvar_3.z < 0.0)) {
      if ((tmpvar_3.x >= 0.0)) {
        r_5 = (s_7 + 3.14159);
      } else {
        r_5 = (r_5 - 3.14159);
      };
    };
  } else {
    r_5 = (sign(tmpvar_3.x) * 1.5708);
  };
  uv_4.x = (0.5 + (0.159155 * r_5));
  uv_4.y = (0.31831 * (1.5708 - (sign(tmpvar_3.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_3.y))) * (1.5708 + (abs(tmpvar_3.y) * (-0.214602 + (abs(tmpvar_3.y) * (0.0865667 + (abs(tmpvar_3.y) * -0.0310296)))))))))));
  vec2 tmpvar_9;
  tmpvar_9 = dFdx(tmpvar_3.xz);
  vec2 tmpvar_10;
  tmpvar_10 = dFdy(tmpvar_3.xz);
  vec4 tmpvar_11;
  tmpvar_11.x = (0.159155 * sqrt(dot (tmpvar_9, tmpvar_9)));
  tmpvar_11.y = dFdx(uv_4.y);
  tmpvar_11.z = (0.159155 * sqrt(dot (tmpvar_10, tmpvar_10)));
  tmpvar_11.w = dFdy(uv_4.y);
  main_1 = texture2DGradARB (_MainTex, uv_4, tmpvar_11.xy, tmpvar_11.zw);
  vec3 tmpvar_12;
  tmpvar_12 = normalize(xlv_TEXCOORD5);
  vec2 uv_13;
  float r_14;
  if ((abs(tmpvar_12.z) > (1e-08 * abs(tmpvar_12.x)))) {
    float y_over_x_15;
    y_over_x_15 = (tmpvar_12.x / tmpvar_12.z);
    float s_16;
    float x_17;
    x_17 = (y_over_x_15 * inversesqrt(((y_over_x_15 * y_over_x_15) + 1.0)));
    s_16 = (sign(x_17) * (1.5708 - (sqrt((1.0 - abs(x_17))) * (1.5708 + (abs(x_17) * (-0.214602 + (abs(x_17) * (0.0865667 + (abs(x_17) * -0.0310296)))))))));
    r_14 = s_16;
    if ((tmpvar_12.z < 0.0)) {
      if ((tmpvar_12.x >= 0.0)) {
        r_14 = (s_16 + 3.14159);
      } else {
        r_14 = (r_14 - 3.14159);
      };
    };
  } else {
    r_14 = (sign(tmpvar_12.x) * 1.5708);
  };
  uv_13.x = (0.5 + (0.159155 * r_14));
  uv_13.y = (0.31831 * (1.5708 - (sign(tmpvar_12.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_12.y))) * (1.5708 + (abs(tmpvar_12.y) * (-0.214602 + (abs(tmpvar_12.y) * (0.0865667 + (abs(tmpvar_12.y) * -0.0310296)))))))))));
  vec2 tmpvar_18;
  tmpvar_18 = ((uv_13 * 4.0) * _DetailScale);
  vec2 tmpvar_19;
  tmpvar_19 = dFdx(tmpvar_12.xz);
  vec2 tmpvar_20;
  tmpvar_20 = dFdy(tmpvar_12.xz);
  vec4 tmpvar_21;
  tmpvar_21.x = (0.159155 * sqrt(dot (tmpvar_19, tmpvar_19)));
  tmpvar_21.y = dFdx(tmpvar_18.y);
  tmpvar_21.z = (0.159155 * sqrt(dot (tmpvar_20, tmpvar_20)));
  tmpvar_21.w = dFdy(tmpvar_18.y);
  vec3 tmpvar_22;
  tmpvar_22 = abs(tmpvar_12);
  float tmpvar_23;
  tmpvar_23 = float((tmpvar_22.z >= tmpvar_22.x));
  vec3 tmpvar_24;
  tmpvar_24 = mix (tmpvar_22.yxz, mix (tmpvar_22, tmpvar_22.zxy, vec3(tmpvar_23)), vec3(float((mix (tmpvar_22.x, tmpvar_22.z, tmpvar_23) >= tmpvar_22.y))));
  color_2.w = _SurfaceColor.w;
  color_2.xyz = (_SurfaceColor.xyz + (0.5 * mix ((texture2DGradARB (_DetailTex, (((0.5 * tmpvar_24.zy) / abs(tmpvar_24.x)) * _DetailScale), tmpvar_21.xy, tmpvar_21.zw).xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0)))));
  float tmpvar_25;
  tmpvar_25 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  color_2.xyz = mix (color_2.xyz, main_1.xyz, vec3(tmpvar_25));
  vec4 tmpvar_26;
  tmpvar_26 = normalize(_WorldSpaceLightPos0);
  vec3 tmpvar_27;
  tmpvar_27 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  float atten_28;
  atten_28 = texture2D (_LightTexture0, xlv_TEXCOORD3).w;
  vec4 c_29;
  float tmpvar_30;
  tmpvar_30 = dot (tmpvar_27, tmpvar_26.xyz);
  c_29.xyz = ((((color_2.xyz * _LightColor0.xyz) * tmpvar_30) + ((_LightColor0.xyz * _SpecColor.xyz) * (pow (clamp (dot (normalize((tmpvar_26.xyz + normalize(xlv_TEXCOORD1))), tmpvar_27), 0.0, 1.0), (_Shininess * 128.0)) * _SurfaceColor.w))) * (atten_28 * 4.0));
  c_29.w = (tmpvar_30 * (atten_28 * 4.0));
  color_2.w = mix (1.0, _SurfaceColor.w, clamp ((c_29.w * 4.0), 0.0, 1.0));
  vec3 arg0_31;
  arg0_31 = (2.0 * color_2.xyz);
  color_2.w = mix (color_2.w, 1.0, clamp ((sqrt(dot (c_29.xyz, c_29.xyz)) - sqrt(dot (arg0_31, arg0_31))), 0.0, 1.0));
  color_2.w = mix (color_2.w, 1.0, tmpvar_25);
  color_2.xyz = c_29.xyz;
  gl_FragData[0] = color_2;
}


#endif
"
}

SubProgram "d3d9 " {
Keywords { "DIRECTIONAL_COOKIE" "SHADOWS_OFF" }
Bind "vertex" Vertex
Bind "texcoord" TexCoord0
Bind "texcoord1" TexCoord1
Matrix 0 [glstate_matrix_mvp]
Vector 12 [_WorldSpaceCameraPos]
Matrix 4 [_Object2World]
Matrix 8 [_LightMatrix0]
"vs_3_0
; 23 ALU
dcl_position o0
dcl_texcoord0 o1
dcl_texcoord1 o2
dcl_texcoord2 o3
dcl_texcoord3 o4
dcl_texcoord5 o5
dcl_position0 v0
dcl_texcoord0 v1
dcl_texcoord1 v2
mov r1.zw, v2.xyxy
mov r1.xy, v1
dp4 r0.w, r1, r1
rsq r1.w, r0.w
mul r1.xyz, r1.w, r1
dp4 r0.z, v0, c6
dp4 r0.x, v0, c4
dp4 r0.y, v0, c5
add r2.xyz, -r0, c12
dp3 r0.w, r2, r2
rsq r0.w, r0.w
mov o5.xyz, -r1
mov r1.xyz, r0
dp4 r1.w, v0, c7
mul o2.xyz, r0.w, r2
dp4 o4.y, r1, c9
dp4 o4.x, r1, c8
rcp o1.x, r0.w
mov o3.xyz, r0
dp4 o0.w, v0, c3
dp4 o0.z, v0, c2
dp4 o0.y, v0, c1
dp4 o0.x, v0, c0
"
}

SubProgram "gles " {
Keywords { "DIRECTIONAL_COOKIE" "SHADOWS_OFF" }
"!!GLES


#ifdef VERTEX

varying highp vec3 xlv_TEXCOORD5;
varying highp vec2 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp mat4 _LightMatrix0;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_mvp;
uniform highp vec3 _WorldSpaceCameraPos;
attribute vec4 _glesMultiTexCoord1;
attribute vec4 _glesMultiTexCoord0;
attribute vec4 _glesVertex;
void main ()
{
  highp vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * _glesVertex).xyz;
  highp vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  highp vec4 tmpvar_3;
  tmpvar_3.x = _glesMultiTexCoord0.x;
  tmpvar_3.y = _glesMultiTexCoord0.y;
  tmpvar_3.z = _glesMultiTexCoord1.x;
  tmpvar_3.w = _glesMultiTexCoord1.y;
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * _glesVertex)).xy;
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}



#endif
#ifdef FRAGMENT

#extension GL_EXT_shader_texture_lod : enable
#extension GL_OES_standard_derivatives : enable
varying highp vec3 xlv_TEXCOORD5;
varying highp vec2 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp vec3 _PlanetOrigin;
uniform highp float _PlanetOpacity;
uniform highp float _DetailDist;
uniform highp float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform highp float _Shininess;
uniform lowp vec4 _SurfaceColor;
uniform lowp vec4 _SpecColor;
uniform lowp vec4 _LightColor0;
uniform sampler2D _LightTexture0;
uniform lowp vec4 _WorldSpaceLightPos0;
void main ()
{
  lowp vec4 tmpvar_1;
  mediump vec4 specColor_2;
  mediump float handoff_3;
  mediump float detailLevel_4;
  mediump vec4 color_5;
  mediump vec4 tex_6;
  highp vec3 tmpvar_7;
  tmpvar_7 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_8;
  highp float r_9;
  if ((abs(tmpvar_7.z) > (1e-08 * abs(tmpvar_7.x)))) {
    highp float y_over_x_10;
    y_over_x_10 = (tmpvar_7.x / tmpvar_7.z);
    highp float s_11;
    highp float x_12;
    x_12 = (y_over_x_10 * inversesqrt(((y_over_x_10 * y_over_x_10) + 1.0)));
    s_11 = (sign(x_12) * (1.5708 - (sqrt((1.0 - abs(x_12))) * (1.5708 + (abs(x_12) * (-0.214602 + (abs(x_12) * (0.0865667 + (abs(x_12) * -0.0310296)))))))));
    r_9 = s_11;
    if ((tmpvar_7.z < 0.0)) {
      if ((tmpvar_7.x >= 0.0)) {
        r_9 = (s_11 + 3.14159);
      } else {
        r_9 = (r_9 - 3.14159);
      };
    };
  } else {
    r_9 = (sign(tmpvar_7.x) * 1.5708);
  };
  uv_8.x = (0.5 + (0.159155 * r_9));
  uv_8.y = (0.31831 * (1.5708 - (sign(tmpvar_7.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_7.y))) * (1.5708 + (abs(tmpvar_7.y) * (-0.214602 + (abs(tmpvar_7.y) * (0.0865667 + (abs(tmpvar_7.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_13;
  tmpvar_13 = dFdx(tmpvar_7.xz);
  highp vec2 tmpvar_14;
  tmpvar_14 = dFdy(tmpvar_7.xz);
  highp vec4 tmpvar_15;
  tmpvar_15.x = (0.159155 * sqrt(dot (tmpvar_13, tmpvar_13)));
  tmpvar_15.y = dFdx(uv_8.y);
  tmpvar_15.z = (0.159155 * sqrt(dot (tmpvar_14, tmpvar_14)));
  tmpvar_15.w = dFdy(uv_8.y);
  lowp vec4 tmpvar_16;
  tmpvar_16 = texture2DGradEXT (_MainTex, uv_8, tmpvar_15.xy, tmpvar_15.zw);
  tex_6 = tmpvar_16;
  mediump vec4 tmpvar_17;
  mediump vec3 detailCoords_18;
  mediump float nylerp_19;
  mediump float zxlerp_20;
  highp vec3 tmpvar_21;
  tmpvar_21 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_22;
  highp float r_23;
  if ((abs(tmpvar_21.z) > (1e-08 * abs(tmpvar_21.x)))) {
    highp float y_over_x_24;
    y_over_x_24 = (tmpvar_21.x / tmpvar_21.z);
    highp float s_25;
    highp float x_26;
    x_26 = (y_over_x_24 * inversesqrt(((y_over_x_24 * y_over_x_24) + 1.0)));
    s_25 = (sign(x_26) * (1.5708 - (sqrt((1.0 - abs(x_26))) * (1.5708 + (abs(x_26) * (-0.214602 + (abs(x_26) * (0.0865667 + (abs(x_26) * -0.0310296)))))))));
    r_23 = s_25;
    if ((tmpvar_21.z < 0.0)) {
      if ((tmpvar_21.x >= 0.0)) {
        r_23 = (s_25 + 3.14159);
      } else {
        r_23 = (r_23 - 3.14159);
      };
    };
  } else {
    r_23 = (sign(tmpvar_21.x) * 1.5708);
  };
  uv_22.x = (0.5 + (0.159155 * r_23));
  uv_22.y = (0.31831 * (1.5708 - (sign(tmpvar_21.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_21.y))) * (1.5708 + (abs(tmpvar_21.y) * (-0.214602 + (abs(tmpvar_21.y) * (0.0865667 + (abs(tmpvar_21.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_27;
  tmpvar_27 = ((uv_22 * 4.0) * _DetailScale);
  highp vec2 tmpvar_28;
  tmpvar_28 = dFdx(tmpvar_21.xz);
  highp vec2 tmpvar_29;
  tmpvar_29 = dFdy(tmpvar_21.xz);
  highp vec4 tmpvar_30;
  tmpvar_30.x = (0.159155 * sqrt(dot (tmpvar_28, tmpvar_28)));
  tmpvar_30.y = dFdx(tmpvar_27.y);
  tmpvar_30.z = (0.159155 * sqrt(dot (tmpvar_29, tmpvar_29)));
  tmpvar_30.w = dFdy(tmpvar_27.y);
  highp vec3 tmpvar_31;
  tmpvar_31 = abs(tmpvar_21);
  highp float tmpvar_32;
  tmpvar_32 = float((tmpvar_31.z >= tmpvar_31.x));
  zxlerp_20 = tmpvar_32;
  highp float tmpvar_33;
  tmpvar_33 = float((mix (tmpvar_31.x, tmpvar_31.z, zxlerp_20) >= tmpvar_31.y));
  nylerp_19 = tmpvar_33;
  highp vec3 tmpvar_34;
  tmpvar_34 = mix (tmpvar_31, tmpvar_31.zxy, vec3(zxlerp_20));
  detailCoords_18 = tmpvar_34;
  highp vec3 tmpvar_35;
  tmpvar_35 = mix (tmpvar_31.yxz, detailCoords_18, vec3(nylerp_19));
  detailCoords_18 = tmpvar_35;
  mediump float tmpvar_36;
  tmpvar_36 = abs(detailCoords_18.x);
  highp vec2 coord_37;
  coord_37 = (((0.5 * detailCoords_18.zy) / tmpvar_36) * _DetailScale);
  lowp vec4 tmpvar_38;
  tmpvar_38 = texture2DGradEXT (_DetailTex, coord_37, tmpvar_30.xy, tmpvar_30.zw);
  tmpvar_17 = tmpvar_38;
  color_5 = _SurfaceColor;
  highp float tmpvar_39;
  tmpvar_39 = clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0);
  detailLevel_4 = tmpvar_39;
  color_5.xyz = (color_5.xyz + (0.5 * mix ((tmpvar_17.xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(detailLevel_4))));
  highp float tmpvar_40;
  tmpvar_40 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  handoff_3 = tmpvar_40;
  color_5.xyz = mix (color_5.xyz, tex_6.xyz, vec3(handoff_3));
  specColor_2.xyz = _SpecColor.xyz;
  specColor_2.w = mix (1.0, tex_6.w, handoff_3);
  lowp vec3 tmpvar_41;
  tmpvar_41 = normalize(_WorldSpaceLightPos0).xyz;
  highp vec3 tmpvar_42;
  tmpvar_42 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  lowp vec4 tmpvar_43;
  tmpvar_43 = texture2D (_LightTexture0, xlv_TEXCOORD3);
  mediump vec3 lightDir_44;
  lightDir_44 = tmpvar_41;
  mediump vec3 viewDir_45;
  viewDir_45 = xlv_TEXCOORD1;
  mediump vec3 normal_46;
  normal_46 = tmpvar_42;
  mediump float atten_47;
  atten_47 = tmpvar_43.w;
  mediump vec4 c_48;
  highp float nh_49;
  mediump vec3 tmpvar_50;
  tmpvar_50 = normalize(viewDir_45);
  viewDir_45 = tmpvar_50;
  mediump float tmpvar_51;
  tmpvar_51 = dot (normal_46, lightDir_44);
  mediump float tmpvar_52;
  tmpvar_52 = clamp (dot (normalize((lightDir_44 + tmpvar_50)), normal_46), 0.0, 1.0);
  nh_49 = tmpvar_52;
  highp vec3 tmpvar_53;
  tmpvar_53 = ((((color_5.xyz * _LightColor0.xyz) * tmpvar_51) + ((_LightColor0.xyz * specColor_2.xyz) * (pow (nh_49, (_Shininess * 128.0)) * color_5.w))) * (atten_47 * 4.0));
  c_48.xyz = tmpvar_53;
  c_48.w = (tmpvar_51 * (atten_47 * 4.0));
  color_5.w = mix (1.0, color_5.w, clamp ((c_48.w * 4.0), 0.0, 1.0));
  mediump vec3 arg0_54;
  arg0_54 = (2.0 * color_5.xyz);
  color_5.w = mix (color_5.w, 1.0, clamp ((sqrt(dot (c_48.xyz, c_48.xyz)) - sqrt(dot (arg0_54, arg0_54))), 0.0, 1.0));
  color_5.w = mix (color_5.w, 1.0, handoff_3);
  color_5.xyz = c_48.xyz;
  tmpvar_1 = color_5;
  gl_FragData[0] = tmpvar_1;
}



#endif"
}

SubProgram "glesdesktop " {
Keywords { "DIRECTIONAL_COOKIE" "SHADOWS_OFF" }
"!!GLES


#ifdef VERTEX

varying highp vec3 xlv_TEXCOORD5;
varying highp vec2 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp mat4 _LightMatrix0;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_mvp;
uniform highp vec3 _WorldSpaceCameraPos;
attribute vec4 _glesMultiTexCoord1;
attribute vec4 _glesMultiTexCoord0;
attribute vec4 _glesVertex;
void main ()
{
  highp vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * _glesVertex).xyz;
  highp vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  highp vec4 tmpvar_3;
  tmpvar_3.x = _glesMultiTexCoord0.x;
  tmpvar_3.y = _glesMultiTexCoord0.y;
  tmpvar_3.z = _glesMultiTexCoord1.x;
  tmpvar_3.w = _glesMultiTexCoord1.y;
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * _glesVertex)).xy;
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}



#endif
#ifdef FRAGMENT

#extension GL_EXT_shader_texture_lod : enable
#extension GL_OES_standard_derivatives : enable
varying highp vec3 xlv_TEXCOORD5;
varying highp vec2 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp vec3 _PlanetOrigin;
uniform highp float _PlanetOpacity;
uniform highp float _DetailDist;
uniform highp float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform highp float _Shininess;
uniform lowp vec4 _SurfaceColor;
uniform lowp vec4 _SpecColor;
uniform lowp vec4 _LightColor0;
uniform sampler2D _LightTexture0;
uniform lowp vec4 _WorldSpaceLightPos0;
void main ()
{
  lowp vec4 tmpvar_1;
  mediump vec4 specColor_2;
  mediump float handoff_3;
  mediump float detailLevel_4;
  mediump vec4 color_5;
  mediump vec4 tex_6;
  highp vec3 tmpvar_7;
  tmpvar_7 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_8;
  highp float r_9;
  if ((abs(tmpvar_7.z) > (1e-08 * abs(tmpvar_7.x)))) {
    highp float y_over_x_10;
    y_over_x_10 = (tmpvar_7.x / tmpvar_7.z);
    highp float s_11;
    highp float x_12;
    x_12 = (y_over_x_10 * inversesqrt(((y_over_x_10 * y_over_x_10) + 1.0)));
    s_11 = (sign(x_12) * (1.5708 - (sqrt((1.0 - abs(x_12))) * (1.5708 + (abs(x_12) * (-0.214602 + (abs(x_12) * (0.0865667 + (abs(x_12) * -0.0310296)))))))));
    r_9 = s_11;
    if ((tmpvar_7.z < 0.0)) {
      if ((tmpvar_7.x >= 0.0)) {
        r_9 = (s_11 + 3.14159);
      } else {
        r_9 = (r_9 - 3.14159);
      };
    };
  } else {
    r_9 = (sign(tmpvar_7.x) * 1.5708);
  };
  uv_8.x = (0.5 + (0.159155 * r_9));
  uv_8.y = (0.31831 * (1.5708 - (sign(tmpvar_7.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_7.y))) * (1.5708 + (abs(tmpvar_7.y) * (-0.214602 + (abs(tmpvar_7.y) * (0.0865667 + (abs(tmpvar_7.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_13;
  tmpvar_13 = dFdx(tmpvar_7.xz);
  highp vec2 tmpvar_14;
  tmpvar_14 = dFdy(tmpvar_7.xz);
  highp vec4 tmpvar_15;
  tmpvar_15.x = (0.159155 * sqrt(dot (tmpvar_13, tmpvar_13)));
  tmpvar_15.y = dFdx(uv_8.y);
  tmpvar_15.z = (0.159155 * sqrt(dot (tmpvar_14, tmpvar_14)));
  tmpvar_15.w = dFdy(uv_8.y);
  lowp vec4 tmpvar_16;
  tmpvar_16 = texture2DGradEXT (_MainTex, uv_8, tmpvar_15.xy, tmpvar_15.zw);
  tex_6 = tmpvar_16;
  mediump vec4 tmpvar_17;
  mediump vec3 detailCoords_18;
  mediump float nylerp_19;
  mediump float zxlerp_20;
  highp vec3 tmpvar_21;
  tmpvar_21 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_22;
  highp float r_23;
  if ((abs(tmpvar_21.z) > (1e-08 * abs(tmpvar_21.x)))) {
    highp float y_over_x_24;
    y_over_x_24 = (tmpvar_21.x / tmpvar_21.z);
    highp float s_25;
    highp float x_26;
    x_26 = (y_over_x_24 * inversesqrt(((y_over_x_24 * y_over_x_24) + 1.0)));
    s_25 = (sign(x_26) * (1.5708 - (sqrt((1.0 - abs(x_26))) * (1.5708 + (abs(x_26) * (-0.214602 + (abs(x_26) * (0.0865667 + (abs(x_26) * -0.0310296)))))))));
    r_23 = s_25;
    if ((tmpvar_21.z < 0.0)) {
      if ((tmpvar_21.x >= 0.0)) {
        r_23 = (s_25 + 3.14159);
      } else {
        r_23 = (r_23 - 3.14159);
      };
    };
  } else {
    r_23 = (sign(tmpvar_21.x) * 1.5708);
  };
  uv_22.x = (0.5 + (0.159155 * r_23));
  uv_22.y = (0.31831 * (1.5708 - (sign(tmpvar_21.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_21.y))) * (1.5708 + (abs(tmpvar_21.y) * (-0.214602 + (abs(tmpvar_21.y) * (0.0865667 + (abs(tmpvar_21.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_27;
  tmpvar_27 = ((uv_22 * 4.0) * _DetailScale);
  highp vec2 tmpvar_28;
  tmpvar_28 = dFdx(tmpvar_21.xz);
  highp vec2 tmpvar_29;
  tmpvar_29 = dFdy(tmpvar_21.xz);
  highp vec4 tmpvar_30;
  tmpvar_30.x = (0.159155 * sqrt(dot (tmpvar_28, tmpvar_28)));
  tmpvar_30.y = dFdx(tmpvar_27.y);
  tmpvar_30.z = (0.159155 * sqrt(dot (tmpvar_29, tmpvar_29)));
  tmpvar_30.w = dFdy(tmpvar_27.y);
  highp vec3 tmpvar_31;
  tmpvar_31 = abs(tmpvar_21);
  highp float tmpvar_32;
  tmpvar_32 = float((tmpvar_31.z >= tmpvar_31.x));
  zxlerp_20 = tmpvar_32;
  highp float tmpvar_33;
  tmpvar_33 = float((mix (tmpvar_31.x, tmpvar_31.z, zxlerp_20) >= tmpvar_31.y));
  nylerp_19 = tmpvar_33;
  highp vec3 tmpvar_34;
  tmpvar_34 = mix (tmpvar_31, tmpvar_31.zxy, vec3(zxlerp_20));
  detailCoords_18 = tmpvar_34;
  highp vec3 tmpvar_35;
  tmpvar_35 = mix (tmpvar_31.yxz, detailCoords_18, vec3(nylerp_19));
  detailCoords_18 = tmpvar_35;
  mediump float tmpvar_36;
  tmpvar_36 = abs(detailCoords_18.x);
  highp vec2 coord_37;
  coord_37 = (((0.5 * detailCoords_18.zy) / tmpvar_36) * _DetailScale);
  lowp vec4 tmpvar_38;
  tmpvar_38 = texture2DGradEXT (_DetailTex, coord_37, tmpvar_30.xy, tmpvar_30.zw);
  tmpvar_17 = tmpvar_38;
  color_5 = _SurfaceColor;
  highp float tmpvar_39;
  tmpvar_39 = clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0);
  detailLevel_4 = tmpvar_39;
  color_5.xyz = (color_5.xyz + (0.5 * mix ((tmpvar_17.xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(detailLevel_4))));
  highp float tmpvar_40;
  tmpvar_40 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  handoff_3 = tmpvar_40;
  color_5.xyz = mix (color_5.xyz, tex_6.xyz, vec3(handoff_3));
  specColor_2.xyz = _SpecColor.xyz;
  specColor_2.w = mix (1.0, tex_6.w, handoff_3);
  lowp vec3 tmpvar_41;
  tmpvar_41 = normalize(_WorldSpaceLightPos0).xyz;
  highp vec3 tmpvar_42;
  tmpvar_42 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  lowp vec4 tmpvar_43;
  tmpvar_43 = texture2D (_LightTexture0, xlv_TEXCOORD3);
  mediump vec3 lightDir_44;
  lightDir_44 = tmpvar_41;
  mediump vec3 viewDir_45;
  viewDir_45 = xlv_TEXCOORD1;
  mediump vec3 normal_46;
  normal_46 = tmpvar_42;
  mediump float atten_47;
  atten_47 = tmpvar_43.w;
  mediump vec4 c_48;
  highp float nh_49;
  mediump vec3 tmpvar_50;
  tmpvar_50 = normalize(viewDir_45);
  viewDir_45 = tmpvar_50;
  mediump float tmpvar_51;
  tmpvar_51 = dot (normal_46, lightDir_44);
  mediump float tmpvar_52;
  tmpvar_52 = clamp (dot (normalize((lightDir_44 + tmpvar_50)), normal_46), 0.0, 1.0);
  nh_49 = tmpvar_52;
  highp vec3 tmpvar_53;
  tmpvar_53 = ((((color_5.xyz * _LightColor0.xyz) * tmpvar_51) + ((_LightColor0.xyz * specColor_2.xyz) * (pow (nh_49, (_Shininess * 128.0)) * color_5.w))) * (atten_47 * 4.0));
  c_48.xyz = tmpvar_53;
  c_48.w = (tmpvar_51 * (atten_47 * 4.0));
  color_5.w = mix (1.0, color_5.w, clamp ((c_48.w * 4.0), 0.0, 1.0));
  mediump vec3 arg0_54;
  arg0_54 = (2.0 * color_5.xyz);
  color_5.w = mix (color_5.w, 1.0, clamp ((sqrt(dot (c_48.xyz, c_48.xyz)) - sqrt(dot (arg0_54, arg0_54))), 0.0, 1.0));
  color_5.w = mix (color_5.w, 1.0, handoff_3);
  color_5.xyz = c_48.xyz;
  tmpvar_1 = color_5;
  gl_FragData[0] = tmpvar_1;
}



#endif"
}

SubProgram "gles3 " {
Keywords { "DIRECTIONAL_COOKIE" "SHADOWS_OFF" }
"!!GLES3#version 300 es


#ifdef VERTEX

#define gl_Vertex _glesVertex
in vec4 _glesVertex;
#define gl_Normal (normalize(_glesNormal))
in vec3 _glesNormal;
#define gl_MultiTexCoord0 _glesMultiTexCoord0
in vec4 _glesMultiTexCoord0;
#define gl_MultiTexCoord1 _glesMultiTexCoord1
in vec4 _glesMultiTexCoord1;

#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 317
struct SurfaceOutput {
    lowp vec3 Albedo;
    lowp vec3 Normal;
    lowp vec3 Emission;
    mediump float Specular;
    lowp float Gloss;
    lowp float Alpha;
};
#line 513
struct v2f {
    highp vec4 pos;
    highp float viewDist;
    highp vec3 viewDir;
    highp vec3 worldPos;
    highp vec2 _LightCoord;
    highp vec3 sphereNormal;
};
#line 505
struct appdata_t {
    highp vec4 vertex;
    highp vec3 normal;
    highp vec4 texcoord;
    highp vec4 texcoord2;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform lowp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform sampler2D _LightTexture0;
uniform highp mat4 _LightMatrix0;
#line 327
uniform lowp vec4 _LightColor0;
uniform lowp vec4 _SpecColor;
#line 340
#line 348
#line 362
uniform highp mat4 _MainRotation;
uniform highp mat4 _DetailRotation;
#line 395
#line 399
#line 408
#line 416
#line 425
#line 433
#line 446
#line 458
#line 474
#line 486
uniform lowp vec4 _SurfaceColor;
#line 494
uniform highp float _Shininess;
uniform sampler2D _MainTex;
uniform sampler2D _DetailTex;
uniform highp float _DetailScale;
#line 498
uniform highp float _DetailDist;
uniform highp float _MinLight;
uniform sampler2D _CameraDepthTexture;
uniform highp mat4 _CameraToWorld;
#line 502
uniform highp float _LightPower;
uniform highp float _PlanetOpacity;
uniform highp vec3 _PlanetOrigin;
#line 523
#line 523
v2f vert( in appdata_t v ) {
    v2f o;
    highp vec4 vertex = v.vertex;
    #line 527
    o.pos = (glstate_matrix_mvp * vertex).xyzw;
    highp vec3 vertexPos = (_Object2World * vertex).xyz;
    o.viewDist = distance( vertexPos, _WorldSpaceCameraPos);
    o.worldPos = vertexPos;
    #line 531
    o.sphereNormal = (-normalize(vec4( v.texcoord.x, v.texcoord.y, v.texcoord2.x, v.texcoord2.y)).xyz);
    o.viewDir = normalize((_WorldSpaceCameraPos.xyz - vertexPos));
    o._LightCoord = (_LightMatrix0 * (_Object2World * v.vertex)).xy;
    #line 535
    return o;
}
out highp float xlv_TEXCOORD0;
out highp vec3 xlv_TEXCOORD1;
out highp vec3 xlv_TEXCOORD2;
out highp vec2 xlv_TEXCOORD3;
out highp vec3 xlv_TEXCOORD5;
void main() {
    v2f xl_retval;
    appdata_t xlt_v;
    xlt_v.vertex = vec4(gl_Vertex);
    xlt_v.normal = vec3(gl_Normal);
    xlt_v.texcoord = vec4(gl_MultiTexCoord0);
    xlt_v.texcoord2 = vec4(gl_MultiTexCoord1);
    xl_retval = vert( xlt_v);
    gl_Position = vec4(xl_retval.pos);
    xlv_TEXCOORD0 = float(xl_retval.viewDist);
    xlv_TEXCOORD1 = vec3(xl_retval.viewDir);
    xlv_TEXCOORD2 = vec3(xl_retval.worldPos);
    xlv_TEXCOORD3 = vec2(xl_retval._LightCoord);
    xlv_TEXCOORD5 = vec3(xl_retval.sphereNormal);
}


#endif
#ifdef FRAGMENT

#define gl_FragData _glesFragData
layout(location = 0) out mediump vec4 _glesFragData[4];
float xll_dFdx_f(float f) {
  return dFdx(f);
}
vec2 xll_dFdx_vf2(vec2 v) {
  return dFdx(v);
}
vec3 xll_dFdx_vf3(vec3 v) {
  return dFdx(v);
}
vec4 xll_dFdx_vf4(vec4 v) {
  return dFdx(v);
}
mat2 xll_dFdx_mf2x2(mat2 m) {
  return mat2( dFdx(m[0]), dFdx(m[1]));
}
mat3 xll_dFdx_mf3x3(mat3 m) {
  return mat3( dFdx(m[0]), dFdx(m[1]), dFdx(m[2]));
}
mat4 xll_dFdx_mf4x4(mat4 m) {
  return mat4( dFdx(m[0]), dFdx(m[1]), dFdx(m[2]), dFdx(m[3]));
}
float xll_dFdy_f(float f) {
  return dFdy(f);
}
vec2 xll_dFdy_vf2(vec2 v) {
  return dFdy(v);
}
vec3 xll_dFdy_vf3(vec3 v) {
  return dFdy(v);
}
vec4 xll_dFdy_vf4(vec4 v) {
  return dFdy(v);
}
mat2 xll_dFdy_mf2x2(mat2 m) {
  return mat2( dFdy(m[0]), dFdy(m[1]));
}
mat3 xll_dFdy_mf3x3(mat3 m) {
  return mat3( dFdy(m[0]), dFdy(m[1]), dFdy(m[2]));
}
mat4 xll_dFdy_mf4x4(mat4 m) {
  return mat4( dFdy(m[0]), dFdy(m[1]), dFdy(m[2]), dFdy(m[3]));
}
vec4 xll_tex2Dgrad(sampler2D s, vec2 coord, vec2 ddx, vec2 ddy) {
   return textureGrad( s, coord, ddx, ddy);
}
float xll_saturate_f( float x) {
  return clamp( x, 0.0, 1.0);
}
vec2 xll_saturate_vf2( vec2 x) {
  return clamp( x, 0.0, 1.0);
}
vec3 xll_saturate_vf3( vec3 x) {
  return clamp( x, 0.0, 1.0);
}
vec4 xll_saturate_vf4( vec4 x) {
  return clamp( x, 0.0, 1.0);
}
mat2 xll_saturate_mf2x2(mat2 m) {
  return mat2( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0));
}
mat3 xll_saturate_mf3x3(mat3 m) {
  return mat3( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0));
}
mat4 xll_saturate_mf4x4(mat4 m) {
  return mat4( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0), clamp(m[3], 0.0, 1.0));
}
#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 317
struct SurfaceOutput {
    lowp vec3 Albedo;
    lowp vec3 Normal;
    lowp vec3 Emission;
    mediump float Specular;
    lowp float Gloss;
    lowp float Alpha;
};
#line 513
struct v2f {
    highp vec4 pos;
    highp float viewDist;
    highp vec3 viewDir;
    highp vec3 worldPos;
    highp vec2 _LightCoord;
    highp vec3 sphereNormal;
};
#line 505
struct appdata_t {
    highp vec4 vertex;
    highp vec3 normal;
    highp vec4 texcoord;
    highp vec4 texcoord2;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform lowp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform sampler2D _LightTexture0;
uniform highp mat4 _LightMatrix0;
#line 327
uniform lowp vec4 _LightColor0;
uniform lowp vec4 _SpecColor;
#line 340
#line 348
#line 362
uniform highp mat4 _MainRotation;
uniform highp mat4 _DetailRotation;
#line 395
#line 399
#line 408
#line 416
#line 425
#line 433
#line 446
#line 458
#line 474
#line 486
uniform lowp vec4 _SurfaceColor;
#line 494
uniform highp float _Shininess;
uniform sampler2D _MainTex;
uniform sampler2D _DetailTex;
uniform highp float _DetailScale;
#line 498
uniform highp float _DetailDist;
uniform highp float _MinLight;
uniform sampler2D _CameraDepthTexture;
uniform highp mat4 _CameraToWorld;
#line 502
uniform highp float _LightPower;
uniform highp float _PlanetOpacity;
uniform highp vec3 _PlanetOrigin;
#line 523
#line 399
highp vec4 Derivatives( in highp float lat, in highp float lon, in highp vec3 pos ) {
    highp vec2 latLong = vec2( lat, lon);
    highp float latDdx = (0.159155 * length(xll_dFdx_vf2(pos.xz)));
    #line 403
    highp float latDdy = (0.159155 * length(xll_dFdy_vf2(pos.xz)));
    highp float longDdx = xll_dFdx_f(lon);
    highp float longDdy = xll_dFdy_f(lon);
    return vec4( latDdx, longDdx, latDdy, longDdy);
}
#line 408
highp vec2 GetSphereUV( in highp vec3 sphereVect, in highp vec2 uvOffset ) {
    highp vec2 uv;
    uv.x = (0.5 + (0.159155 * atan( sphereVect.x, sphereVect.z)));
    #line 412
    uv.y = (0.31831 * acos(sphereVect.y));
    uv += uvOffset;
    return uv;
}
#line 446
mediump vec4 GetShereDetailMap( in sampler2D texSampler, in highp vec3 sphereVect, in highp float detailScale ) {
    highp vec3 sphereVectNorm = normalize(sphereVect);
    highp vec2 uv = ((GetSphereUV( sphereVectNorm, vec2( 0.0, 0.0)) * 4.0) * detailScale);
    #line 450
    highp vec4 uvdd = Derivatives( (uv.x - 0.5), uv.y, sphereVectNorm);
    sphereVectNorm = abs(sphereVectNorm);
    mediump float zxlerp = step( sphereVectNorm.x, sphereVectNorm.z);
    mediump float nylerp = step( sphereVectNorm.y, mix( sphereVectNorm.x, sphereVectNorm.z, zxlerp));
    #line 454
    mediump vec3 detailCoords = mix( sphereVectNorm.xyz, sphereVectNorm.zxy, vec3( zxlerp));
    detailCoords = mix( sphereVectNorm.yxz, detailCoords, vec3( nylerp));
    return xll_tex2Dgrad( texSampler, (((0.5 * detailCoords.zy) / abs(detailCoords.x)) * detailScale), uvdd.xy, uvdd.zw);
}
#line 425
mediump vec4 GetSphereMap( in sampler2D texSampler, in highp vec3 sphereVect ) {
    highp vec3 sphereVectNorm = normalize(sphereVect);
    highp vec2 uv = GetSphereUV( sphereVectNorm, vec2( 0.0, 0.0));
    #line 429
    highp vec4 uvdd = Derivatives( (uv.x - 0.5), uv.y, sphereVectNorm);
    mediump vec4 tex = xll_tex2Dgrad( texSampler, uv, uvdd.xy, uvdd.zw);
    return tex;
}
#line 474
mediump vec4 SpecularColorLight( in mediump vec3 lightDir, in mediump vec3 viewDir, in mediump vec3 normal, in mediump vec4 color, in mediump vec4 specColor, in highp float specK, in mediump float atten ) {
    viewDir = normalize(viewDir);
    mediump vec3 h = normalize((lightDir + viewDir));
    #line 478
    mediump float diffuse = dot( normal, lightDir);
    highp float nh = xll_saturate_f(dot( h, normal));
    highp float spec = (pow( nh, specK) * color.w);
    mediump vec4 c;
    #line 482
    c.xyz = ((((color.xyz * _LightColor0.xyz) * diffuse) + ((_LightColor0.xyz * specColor.xyz) * spec)) * (atten * 4.0));
    c.w = (diffuse * (atten * 4.0));
    return c;
}
#line 537
lowp vec4 frag( in v2f IN ) {
    #line 539
    mediump vec4 color;
    highp vec3 sphereNrm = IN.sphereNormal;
    mediump vec4 main = GetSphereMap( _MainTex, sphereNrm);
    mediump vec4 detail = GetShereDetailMap( _DetailTex, sphereNrm, _DetailScale);
    #line 543
    color = _SurfaceColor;
    mediump float detailLevel = xll_saturate_f(((2.0 * _DetailDist) * IN.viewDist));
    color.xyz += (0.5 * mix( (detail.xyz - 0.5), vec3( 0.0), vec3( detailLevel)));
    mediump float handoff = xll_saturate_f(pow( _PlanetOpacity, 2.0));
    #line 547
    color.xyz = mix( color.xyz, main.xyz, vec3( handoff));
    mediump vec4 specColor = _SpecColor;
    specColor.w = mix( 1.0, main.w, handoff);
    mediump vec4 colorLight = SpecularColorLight( vec3( normalize(_WorldSpaceLightPos0)), IN.viewDir, normalize((IN.worldPos - _PlanetOrigin)), color, specColor, (_Shininess * 128.0), (texture( _LightTexture0, IN._LightCoord).w * 1.0));
    #line 551
    color.w = mix( 1.0, color.w, xll_saturate_f((colorLight.w * 4.0)));
    color.w = mix( color.w, 1.0, xll_saturate_f((length(colorLight.xyz) - length((2.0 * color.xyz)))));
    color.w = mix( color.w, 1.0, handoff);
    color.xyz = colorLight.xyz;
    #line 555
    return color;
}
in highp float xlv_TEXCOORD0;
in highp vec3 xlv_TEXCOORD1;
in highp vec3 xlv_TEXCOORD2;
in highp vec2 xlv_TEXCOORD3;
in highp vec3 xlv_TEXCOORD5;
void main() {
    lowp vec4 xl_retval;
    v2f xlt_IN;
    xlt_IN.pos = vec4(0.0);
    xlt_IN.viewDist = float(xlv_TEXCOORD0);
    xlt_IN.viewDir = vec3(xlv_TEXCOORD1);
    xlt_IN.worldPos = vec3(xlv_TEXCOORD2);
    xlt_IN._LightCoord = vec2(xlv_TEXCOORD3);
    xlt_IN.sphereNormal = vec3(xlv_TEXCOORD5);
    xl_retval = frag( xlt_IN);
    gl_FragData[0] = vec4(xl_retval);
}


#endif"
}

SubProgram "opengl " {
Keywords { "SPOT" "SHADOWS_DEPTH" }
"!!GLSL
#ifdef VERTEX
varying vec3 xlv_TEXCOORD5;
varying vec4 xlv_TEXCOORD4;
varying vec4 xlv_TEXCOORD3;
varying vec3 xlv_TEXCOORD2;
varying vec3 xlv_TEXCOORD1;
varying float xlv_TEXCOORD0;
uniform mat4 _LightMatrix0;
uniform mat4 _Object2World;

uniform mat4 unity_World2Shadow[4];
uniform vec3 _WorldSpaceCameraPos;
void main ()
{
  vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * gl_Vertex).xyz;
  vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  vec4 tmpvar_3;
  tmpvar_3.x = gl_MultiTexCoord0.x;
  tmpvar_3.y = gl_MultiTexCoord0.y;
  tmpvar_3.z = gl_MultiTexCoord1.x;
  tmpvar_3.w = gl_MultiTexCoord1.y;
  gl_Position = (gl_ModelViewProjectionMatrix * gl_Vertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * gl_Vertex));
  xlv_TEXCOORD4 = (unity_World2Shadow[0] * (_Object2World * gl_Vertex));
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}


#endif
#ifdef FRAGMENT
#extension GL_ARB_shader_texture_lod : enable
varying vec3 xlv_TEXCOORD5;
varying vec4 xlv_TEXCOORD4;
varying vec4 xlv_TEXCOORD3;
varying vec3 xlv_TEXCOORD2;
varying vec3 xlv_TEXCOORD1;
varying float xlv_TEXCOORD0;
uniform vec3 _PlanetOrigin;
uniform float _PlanetOpacity;
uniform float _DetailDist;
uniform float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform float _Shininess;
uniform vec4 _SurfaceColor;
uniform vec4 _SpecColor;
uniform vec4 _LightColor0;
uniform sampler2D _LightTextureB0;
uniform sampler2D _LightTexture0;
uniform sampler2D _ShadowMapTexture;
uniform vec4 _LightShadowData;
uniform vec4 _WorldSpaceLightPos0;
void main ()
{
  vec4 main_1;
  vec4 color_2;
  vec3 tmpvar_3;
  tmpvar_3 = normalize(xlv_TEXCOORD5);
  vec2 uv_4;
  float r_5;
  if ((abs(tmpvar_3.z) > (1e-08 * abs(tmpvar_3.x)))) {
    float y_over_x_6;
    y_over_x_6 = (tmpvar_3.x / tmpvar_3.z);
    float s_7;
    float x_8;
    x_8 = (y_over_x_6 * inversesqrt(((y_over_x_6 * y_over_x_6) + 1.0)));
    s_7 = (sign(x_8) * (1.5708 - (sqrt((1.0 - abs(x_8))) * (1.5708 + (abs(x_8) * (-0.214602 + (abs(x_8) * (0.0865667 + (abs(x_8) * -0.0310296)))))))));
    r_5 = s_7;
    if ((tmpvar_3.z < 0.0)) {
      if ((tmpvar_3.x >= 0.0)) {
        r_5 = (s_7 + 3.14159);
      } else {
        r_5 = (r_5 - 3.14159);
      };
    };
  } else {
    r_5 = (sign(tmpvar_3.x) * 1.5708);
  };
  uv_4.x = (0.5 + (0.159155 * r_5));
  uv_4.y = (0.31831 * (1.5708 - (sign(tmpvar_3.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_3.y))) * (1.5708 + (abs(tmpvar_3.y) * (-0.214602 + (abs(tmpvar_3.y) * (0.0865667 + (abs(tmpvar_3.y) * -0.0310296)))))))))));
  vec2 tmpvar_9;
  tmpvar_9 = dFdx(tmpvar_3.xz);
  vec2 tmpvar_10;
  tmpvar_10 = dFdy(tmpvar_3.xz);
  vec4 tmpvar_11;
  tmpvar_11.x = (0.159155 * sqrt(dot (tmpvar_9, tmpvar_9)));
  tmpvar_11.y = dFdx(uv_4.y);
  tmpvar_11.z = (0.159155 * sqrt(dot (tmpvar_10, tmpvar_10)));
  tmpvar_11.w = dFdy(uv_4.y);
  main_1 = texture2DGradARB (_MainTex, uv_4, tmpvar_11.xy, tmpvar_11.zw);
  vec3 tmpvar_12;
  tmpvar_12 = normalize(xlv_TEXCOORD5);
  vec2 uv_13;
  float r_14;
  if ((abs(tmpvar_12.z) > (1e-08 * abs(tmpvar_12.x)))) {
    float y_over_x_15;
    y_over_x_15 = (tmpvar_12.x / tmpvar_12.z);
    float s_16;
    float x_17;
    x_17 = (y_over_x_15 * inversesqrt(((y_over_x_15 * y_over_x_15) + 1.0)));
    s_16 = (sign(x_17) * (1.5708 - (sqrt((1.0 - abs(x_17))) * (1.5708 + (abs(x_17) * (-0.214602 + (abs(x_17) * (0.0865667 + (abs(x_17) * -0.0310296)))))))));
    r_14 = s_16;
    if ((tmpvar_12.z < 0.0)) {
      if ((tmpvar_12.x >= 0.0)) {
        r_14 = (s_16 + 3.14159);
      } else {
        r_14 = (r_14 - 3.14159);
      };
    };
  } else {
    r_14 = (sign(tmpvar_12.x) * 1.5708);
  };
  uv_13.x = (0.5 + (0.159155 * r_14));
  uv_13.y = (0.31831 * (1.5708 - (sign(tmpvar_12.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_12.y))) * (1.5708 + (abs(tmpvar_12.y) * (-0.214602 + (abs(tmpvar_12.y) * (0.0865667 + (abs(tmpvar_12.y) * -0.0310296)))))))))));
  vec2 tmpvar_18;
  tmpvar_18 = ((uv_13 * 4.0) * _DetailScale);
  vec2 tmpvar_19;
  tmpvar_19 = dFdx(tmpvar_12.xz);
  vec2 tmpvar_20;
  tmpvar_20 = dFdy(tmpvar_12.xz);
  vec4 tmpvar_21;
  tmpvar_21.x = (0.159155 * sqrt(dot (tmpvar_19, tmpvar_19)));
  tmpvar_21.y = dFdx(tmpvar_18.y);
  tmpvar_21.z = (0.159155 * sqrt(dot (tmpvar_20, tmpvar_20)));
  tmpvar_21.w = dFdy(tmpvar_18.y);
  vec3 tmpvar_22;
  tmpvar_22 = abs(tmpvar_12);
  float tmpvar_23;
  tmpvar_23 = float((tmpvar_22.z >= tmpvar_22.x));
  vec3 tmpvar_24;
  tmpvar_24 = mix (tmpvar_22.yxz, mix (tmpvar_22, tmpvar_22.zxy, vec3(tmpvar_23)), vec3(float((mix (tmpvar_22.x, tmpvar_22.z, tmpvar_23) >= tmpvar_22.y))));
  color_2.w = _SurfaceColor.w;
  color_2.xyz = (_SurfaceColor.xyz + (0.5 * mix ((texture2DGradARB (_DetailTex, (((0.5 * tmpvar_24.zy) / abs(tmpvar_24.x)) * _DetailScale), tmpvar_21.xy, tmpvar_21.zw).xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0)))));
  float tmpvar_25;
  tmpvar_25 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  color_2.xyz = mix (color_2.xyz, main_1.xyz, vec3(tmpvar_25));
  vec4 tmpvar_26;
  tmpvar_26 = normalize(_WorldSpaceLightPos0);
  vec3 tmpvar_27;
  tmpvar_27 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  vec4 tmpvar_28;
  tmpvar_28 = texture2D (_LightTexture0, ((xlv_TEXCOORD3.xy / xlv_TEXCOORD3.w) + 0.5));
  vec4 tmpvar_29;
  tmpvar_29 = texture2D (_LightTextureB0, vec2(dot (xlv_TEXCOORD3.xyz, xlv_TEXCOORD3.xyz)));
  vec4 tmpvar_30;
  tmpvar_30 = texture2DProj (_ShadowMapTexture, xlv_TEXCOORD4);
  float tmpvar_31;
  if ((tmpvar_30.x < (xlv_TEXCOORD4.z / xlv_TEXCOORD4.w))) {
    tmpvar_31 = _LightShadowData.x;
  } else {
    tmpvar_31 = 1.0;
  };
  float atten_32;
  atten_32 = (((float((xlv_TEXCOORD3.z > 0.0)) * tmpvar_28.w) * tmpvar_29.w) * tmpvar_31);
  vec4 c_33;
  vec3 tmpvar_34;
  tmpvar_34 = normalize(tmpvar_26.xyz);
  float tmpvar_35;
  tmpvar_35 = dot (tmpvar_27, tmpvar_34);
  c_33.xyz = ((((color_2.xyz * _LightColor0.xyz) * tmpvar_35) + ((_LightColor0.xyz * _SpecColor.xyz) * (pow (clamp (dot (normalize((tmpvar_34 + normalize(xlv_TEXCOORD1))), tmpvar_27), 0.0, 1.0), (_Shininess * 128.0)) * _SurfaceColor.w))) * (atten_32 * 4.0));
  c_33.w = (tmpvar_35 * (atten_32 * 4.0));
  color_2.w = mix (1.0, _SurfaceColor.w, clamp ((c_33.w * 4.0), 0.0, 1.0));
  vec3 arg0_36;
  arg0_36 = (2.0 * color_2.xyz);
  color_2.w = mix (color_2.w, 1.0, clamp ((sqrt(dot (c_33.xyz, c_33.xyz)) - sqrt(dot (arg0_36, arg0_36))), 0.0, 1.0));
  color_2.w = mix (color_2.w, 1.0, tmpvar_25);
  color_2.xyz = c_33.xyz;
  gl_FragData[0] = color_2;
}


#endif
"
}

SubProgram "d3d9 " {
Keywords { "SPOT" "SHADOWS_DEPTH" }
Bind "vertex" Vertex
Bind "texcoord" TexCoord0
Bind "texcoord1" TexCoord1
Matrix 0 [glstate_matrix_mvp]
Vector 16 [_WorldSpaceCameraPos]
Matrix 4 [unity_World2Shadow0]
Matrix 8 [_Object2World]
Matrix 12 [_LightMatrix0]
"vs_3_0
; 29 ALU
dcl_position o0
dcl_texcoord0 o1
dcl_texcoord1 o2
dcl_texcoord2 o3
dcl_texcoord3 o4
dcl_texcoord4 o5
dcl_texcoord5 o6
dcl_position0 v0
dcl_texcoord0 v1
dcl_texcoord1 v2
mov r1.zw, v2.xyxy
mov r1.xy, v1
dp4 r0.w, r1, r1
rsq r1.w, r0.w
mul r1.xyz, r1.w, r1
dp4 r1.w, v0, c11
dp4 r0.z, v0, c10
dp4 r0.x, v0, c8
dp4 r0.y, v0, c9
add r2.xyz, -r0, c16
dp3 r0.w, r2, r2
rsq r0.w, r0.w
mov o6.xyz, -r1
mov r1.xyz, r0
mul o2.xyz, r0.w, r2
dp4 o4.w, r1, c15
dp4 o4.z, r1, c14
dp4 o4.y, r1, c13
dp4 o4.x, r1, c12
dp4 o5.w, r1, c7
dp4 o5.z, r1, c6
dp4 o5.y, r1, c5
dp4 o5.x, r1, c4
rcp o1.x, r0.w
mov o3.xyz, r0
dp4 o0.w, v0, c3
dp4 o0.z, v0, c2
dp4 o0.y, v0, c1
dp4 o0.x, v0, c0
"
}

SubProgram "gles " {
Keywords { "SPOT" "SHADOWS_DEPTH" }
"!!GLES


#ifdef VERTEX

varying highp vec3 xlv_TEXCOORD5;
varying highp vec4 xlv_TEXCOORD4;
varying highp vec4 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp mat4 _LightMatrix0;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec3 _WorldSpaceCameraPos;
attribute vec4 _glesMultiTexCoord1;
attribute vec4 _glesMultiTexCoord0;
attribute vec4 _glesVertex;
void main ()
{
  highp vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * _glesVertex).xyz;
  highp vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  highp vec4 tmpvar_3;
  tmpvar_3.x = _glesMultiTexCoord0.x;
  tmpvar_3.y = _glesMultiTexCoord0.y;
  tmpvar_3.z = _glesMultiTexCoord1.x;
  tmpvar_3.w = _glesMultiTexCoord1.y;
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * _glesVertex));
  xlv_TEXCOORD4 = (unity_World2Shadow[0] * (_Object2World * _glesVertex));
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}



#endif
#ifdef FRAGMENT

#extension GL_EXT_shader_texture_lod : enable
#extension GL_OES_standard_derivatives : enable
varying highp vec3 xlv_TEXCOORD5;
varying highp vec4 xlv_TEXCOORD4;
varying highp vec4 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp vec3 _PlanetOrigin;
uniform highp float _PlanetOpacity;
uniform highp float _DetailDist;
uniform highp float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform highp float _Shininess;
uniform lowp vec4 _SurfaceColor;
uniform lowp vec4 _SpecColor;
uniform lowp vec4 _LightColor0;
uniform sampler2D _LightTextureB0;
uniform sampler2D _LightTexture0;
uniform sampler2D _ShadowMapTexture;
uniform highp vec4 _LightShadowData;
uniform highp vec4 _WorldSpaceLightPos0;
void main ()
{
  lowp vec4 tmpvar_1;
  mediump vec4 specColor_2;
  mediump float handoff_3;
  mediump float detailLevel_4;
  mediump vec4 color_5;
  mediump vec4 tex_6;
  highp vec3 tmpvar_7;
  tmpvar_7 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_8;
  highp float r_9;
  if ((abs(tmpvar_7.z) > (1e-08 * abs(tmpvar_7.x)))) {
    highp float y_over_x_10;
    y_over_x_10 = (tmpvar_7.x / tmpvar_7.z);
    highp float s_11;
    highp float x_12;
    x_12 = (y_over_x_10 * inversesqrt(((y_over_x_10 * y_over_x_10) + 1.0)));
    s_11 = (sign(x_12) * (1.5708 - (sqrt((1.0 - abs(x_12))) * (1.5708 + (abs(x_12) * (-0.214602 + (abs(x_12) * (0.0865667 + (abs(x_12) * -0.0310296)))))))));
    r_9 = s_11;
    if ((tmpvar_7.z < 0.0)) {
      if ((tmpvar_7.x >= 0.0)) {
        r_9 = (s_11 + 3.14159);
      } else {
        r_9 = (r_9 - 3.14159);
      };
    };
  } else {
    r_9 = (sign(tmpvar_7.x) * 1.5708);
  };
  uv_8.x = (0.5 + (0.159155 * r_9));
  uv_8.y = (0.31831 * (1.5708 - (sign(tmpvar_7.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_7.y))) * (1.5708 + (abs(tmpvar_7.y) * (-0.214602 + (abs(tmpvar_7.y) * (0.0865667 + (abs(tmpvar_7.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_13;
  tmpvar_13 = dFdx(tmpvar_7.xz);
  highp vec2 tmpvar_14;
  tmpvar_14 = dFdy(tmpvar_7.xz);
  highp vec4 tmpvar_15;
  tmpvar_15.x = (0.159155 * sqrt(dot (tmpvar_13, tmpvar_13)));
  tmpvar_15.y = dFdx(uv_8.y);
  tmpvar_15.z = (0.159155 * sqrt(dot (tmpvar_14, tmpvar_14)));
  tmpvar_15.w = dFdy(uv_8.y);
  lowp vec4 tmpvar_16;
  tmpvar_16 = texture2DGradEXT (_MainTex, uv_8, tmpvar_15.xy, tmpvar_15.zw);
  tex_6 = tmpvar_16;
  mediump vec4 tmpvar_17;
  mediump vec3 detailCoords_18;
  mediump float nylerp_19;
  mediump float zxlerp_20;
  highp vec3 tmpvar_21;
  tmpvar_21 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_22;
  highp float r_23;
  if ((abs(tmpvar_21.z) > (1e-08 * abs(tmpvar_21.x)))) {
    highp float y_over_x_24;
    y_over_x_24 = (tmpvar_21.x / tmpvar_21.z);
    highp float s_25;
    highp float x_26;
    x_26 = (y_over_x_24 * inversesqrt(((y_over_x_24 * y_over_x_24) + 1.0)));
    s_25 = (sign(x_26) * (1.5708 - (sqrt((1.0 - abs(x_26))) * (1.5708 + (abs(x_26) * (-0.214602 + (abs(x_26) * (0.0865667 + (abs(x_26) * -0.0310296)))))))));
    r_23 = s_25;
    if ((tmpvar_21.z < 0.0)) {
      if ((tmpvar_21.x >= 0.0)) {
        r_23 = (s_25 + 3.14159);
      } else {
        r_23 = (r_23 - 3.14159);
      };
    };
  } else {
    r_23 = (sign(tmpvar_21.x) * 1.5708);
  };
  uv_22.x = (0.5 + (0.159155 * r_23));
  uv_22.y = (0.31831 * (1.5708 - (sign(tmpvar_21.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_21.y))) * (1.5708 + (abs(tmpvar_21.y) * (-0.214602 + (abs(tmpvar_21.y) * (0.0865667 + (abs(tmpvar_21.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_27;
  tmpvar_27 = ((uv_22 * 4.0) * _DetailScale);
  highp vec2 tmpvar_28;
  tmpvar_28 = dFdx(tmpvar_21.xz);
  highp vec2 tmpvar_29;
  tmpvar_29 = dFdy(tmpvar_21.xz);
  highp vec4 tmpvar_30;
  tmpvar_30.x = (0.159155 * sqrt(dot (tmpvar_28, tmpvar_28)));
  tmpvar_30.y = dFdx(tmpvar_27.y);
  tmpvar_30.z = (0.159155 * sqrt(dot (tmpvar_29, tmpvar_29)));
  tmpvar_30.w = dFdy(tmpvar_27.y);
  highp vec3 tmpvar_31;
  tmpvar_31 = abs(tmpvar_21);
  highp float tmpvar_32;
  tmpvar_32 = float((tmpvar_31.z >= tmpvar_31.x));
  zxlerp_20 = tmpvar_32;
  highp float tmpvar_33;
  tmpvar_33 = float((mix (tmpvar_31.x, tmpvar_31.z, zxlerp_20) >= tmpvar_31.y));
  nylerp_19 = tmpvar_33;
  highp vec3 tmpvar_34;
  tmpvar_34 = mix (tmpvar_31, tmpvar_31.zxy, vec3(zxlerp_20));
  detailCoords_18 = tmpvar_34;
  highp vec3 tmpvar_35;
  tmpvar_35 = mix (tmpvar_31.yxz, detailCoords_18, vec3(nylerp_19));
  detailCoords_18 = tmpvar_35;
  mediump float tmpvar_36;
  tmpvar_36 = abs(detailCoords_18.x);
  highp vec2 coord_37;
  coord_37 = (((0.5 * detailCoords_18.zy) / tmpvar_36) * _DetailScale);
  lowp vec4 tmpvar_38;
  tmpvar_38 = texture2DGradEXT (_DetailTex, coord_37, tmpvar_30.xy, tmpvar_30.zw);
  tmpvar_17 = tmpvar_38;
  color_5 = _SurfaceColor;
  highp float tmpvar_39;
  tmpvar_39 = clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0);
  detailLevel_4 = tmpvar_39;
  color_5.xyz = (color_5.xyz + (0.5 * mix ((tmpvar_17.xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(detailLevel_4))));
  highp float tmpvar_40;
  tmpvar_40 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  handoff_3 = tmpvar_40;
  color_5.xyz = mix (color_5.xyz, tex_6.xyz, vec3(handoff_3));
  specColor_2.xyz = _SpecColor.xyz;
  specColor_2.w = mix (1.0, tex_6.w, handoff_3);
  highp vec3 tmpvar_41;
  tmpvar_41 = normalize(_WorldSpaceLightPos0).xyz;
  highp vec3 tmpvar_42;
  tmpvar_42 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  lowp vec4 tmpvar_43;
  highp vec2 P_44;
  P_44 = ((xlv_TEXCOORD3.xy / xlv_TEXCOORD3.w) + 0.5);
  tmpvar_43 = texture2D (_LightTexture0, P_44);
  highp float tmpvar_45;
  tmpvar_45 = dot (xlv_TEXCOORD3.xyz, xlv_TEXCOORD3.xyz);
  lowp vec4 tmpvar_46;
  tmpvar_46 = texture2D (_LightTextureB0, vec2(tmpvar_45));
  lowp float tmpvar_47;
  mediump float shadow_48;
  lowp vec4 tmpvar_49;
  tmpvar_49 = texture2DProj (_ShadowMapTexture, xlv_TEXCOORD4);
  highp float tmpvar_50;
  if ((tmpvar_49.x < (xlv_TEXCOORD4.z / xlv_TEXCOORD4.w))) {
    tmpvar_50 = _LightShadowData.x;
  } else {
    tmpvar_50 = 1.0;
  };
  shadow_48 = tmpvar_50;
  tmpvar_47 = shadow_48;
  mediump vec3 lightDir_51;
  lightDir_51 = tmpvar_41;
  mediump vec3 viewDir_52;
  viewDir_52 = xlv_TEXCOORD1;
  mediump vec3 normal_53;
  normal_53 = tmpvar_42;
  mediump float atten_54;
  atten_54 = (((float((xlv_TEXCOORD3.z > 0.0)) * tmpvar_43.w) * tmpvar_46.w) * tmpvar_47);
  mediump vec4 c_55;
  highp float nh_56;
  mediump vec3 tmpvar_57;
  tmpvar_57 = normalize(lightDir_51);
  lightDir_51 = tmpvar_57;
  mediump vec3 tmpvar_58;
  tmpvar_58 = normalize(viewDir_52);
  viewDir_52 = tmpvar_58;
  mediump float tmpvar_59;
  tmpvar_59 = dot (normal_53, tmpvar_57);
  mediump float tmpvar_60;
  tmpvar_60 = clamp (dot (normalize((tmpvar_57 + tmpvar_58)), normal_53), 0.0, 1.0);
  nh_56 = tmpvar_60;
  highp vec3 tmpvar_61;
  tmpvar_61 = ((((color_5.xyz * _LightColor0.xyz) * tmpvar_59) + ((_LightColor0.xyz * specColor_2.xyz) * (pow (nh_56, (_Shininess * 128.0)) * color_5.w))) * (atten_54 * 4.0));
  c_55.xyz = tmpvar_61;
  c_55.w = (tmpvar_59 * (atten_54 * 4.0));
  color_5.w = mix (1.0, color_5.w, clamp ((c_55.w * 4.0), 0.0, 1.0));
  mediump vec3 arg0_62;
  arg0_62 = (2.0 * color_5.xyz);
  color_5.w = mix (color_5.w, 1.0, clamp ((sqrt(dot (c_55.xyz, c_55.xyz)) - sqrt(dot (arg0_62, arg0_62))), 0.0, 1.0));
  color_5.w = mix (color_5.w, 1.0, handoff_3);
  color_5.xyz = c_55.xyz;
  tmpvar_1 = color_5;
  gl_FragData[0] = tmpvar_1;
}



#endif"
}

SubProgram "glesdesktop " {
Keywords { "SPOT" "SHADOWS_DEPTH" }
"!!GLES


#ifdef VERTEX

varying highp vec3 xlv_TEXCOORD5;
varying highp vec4 xlv_TEXCOORD4;
varying highp vec4 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp mat4 _LightMatrix0;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec3 _WorldSpaceCameraPos;
attribute vec4 _glesMultiTexCoord1;
attribute vec4 _glesMultiTexCoord0;
attribute vec4 _glesVertex;
void main ()
{
  highp vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * _glesVertex).xyz;
  highp vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  highp vec4 tmpvar_3;
  tmpvar_3.x = _glesMultiTexCoord0.x;
  tmpvar_3.y = _glesMultiTexCoord0.y;
  tmpvar_3.z = _glesMultiTexCoord1.x;
  tmpvar_3.w = _glesMultiTexCoord1.y;
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * _glesVertex));
  xlv_TEXCOORD4 = (unity_World2Shadow[0] * (_Object2World * _glesVertex));
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}



#endif
#ifdef FRAGMENT

#extension GL_EXT_shader_texture_lod : enable
#extension GL_OES_standard_derivatives : enable
varying highp vec3 xlv_TEXCOORD5;
varying highp vec4 xlv_TEXCOORD4;
varying highp vec4 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp vec3 _PlanetOrigin;
uniform highp float _PlanetOpacity;
uniform highp float _DetailDist;
uniform highp float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform highp float _Shininess;
uniform lowp vec4 _SurfaceColor;
uniform lowp vec4 _SpecColor;
uniform lowp vec4 _LightColor0;
uniform sampler2D _LightTextureB0;
uniform sampler2D _LightTexture0;
uniform sampler2D _ShadowMapTexture;
uniform highp vec4 _LightShadowData;
uniform highp vec4 _WorldSpaceLightPos0;
void main ()
{
  lowp vec4 tmpvar_1;
  mediump vec4 specColor_2;
  mediump float handoff_3;
  mediump float detailLevel_4;
  mediump vec4 color_5;
  mediump vec4 tex_6;
  highp vec3 tmpvar_7;
  tmpvar_7 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_8;
  highp float r_9;
  if ((abs(tmpvar_7.z) > (1e-08 * abs(tmpvar_7.x)))) {
    highp float y_over_x_10;
    y_over_x_10 = (tmpvar_7.x / tmpvar_7.z);
    highp float s_11;
    highp float x_12;
    x_12 = (y_over_x_10 * inversesqrt(((y_over_x_10 * y_over_x_10) + 1.0)));
    s_11 = (sign(x_12) * (1.5708 - (sqrt((1.0 - abs(x_12))) * (1.5708 + (abs(x_12) * (-0.214602 + (abs(x_12) * (0.0865667 + (abs(x_12) * -0.0310296)))))))));
    r_9 = s_11;
    if ((tmpvar_7.z < 0.0)) {
      if ((tmpvar_7.x >= 0.0)) {
        r_9 = (s_11 + 3.14159);
      } else {
        r_9 = (r_9 - 3.14159);
      };
    };
  } else {
    r_9 = (sign(tmpvar_7.x) * 1.5708);
  };
  uv_8.x = (0.5 + (0.159155 * r_9));
  uv_8.y = (0.31831 * (1.5708 - (sign(tmpvar_7.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_7.y))) * (1.5708 + (abs(tmpvar_7.y) * (-0.214602 + (abs(tmpvar_7.y) * (0.0865667 + (abs(tmpvar_7.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_13;
  tmpvar_13 = dFdx(tmpvar_7.xz);
  highp vec2 tmpvar_14;
  tmpvar_14 = dFdy(tmpvar_7.xz);
  highp vec4 tmpvar_15;
  tmpvar_15.x = (0.159155 * sqrt(dot (tmpvar_13, tmpvar_13)));
  tmpvar_15.y = dFdx(uv_8.y);
  tmpvar_15.z = (0.159155 * sqrt(dot (tmpvar_14, tmpvar_14)));
  tmpvar_15.w = dFdy(uv_8.y);
  lowp vec4 tmpvar_16;
  tmpvar_16 = texture2DGradEXT (_MainTex, uv_8, tmpvar_15.xy, tmpvar_15.zw);
  tex_6 = tmpvar_16;
  mediump vec4 tmpvar_17;
  mediump vec3 detailCoords_18;
  mediump float nylerp_19;
  mediump float zxlerp_20;
  highp vec3 tmpvar_21;
  tmpvar_21 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_22;
  highp float r_23;
  if ((abs(tmpvar_21.z) > (1e-08 * abs(tmpvar_21.x)))) {
    highp float y_over_x_24;
    y_over_x_24 = (tmpvar_21.x / tmpvar_21.z);
    highp float s_25;
    highp float x_26;
    x_26 = (y_over_x_24 * inversesqrt(((y_over_x_24 * y_over_x_24) + 1.0)));
    s_25 = (sign(x_26) * (1.5708 - (sqrt((1.0 - abs(x_26))) * (1.5708 + (abs(x_26) * (-0.214602 + (abs(x_26) * (0.0865667 + (abs(x_26) * -0.0310296)))))))));
    r_23 = s_25;
    if ((tmpvar_21.z < 0.0)) {
      if ((tmpvar_21.x >= 0.0)) {
        r_23 = (s_25 + 3.14159);
      } else {
        r_23 = (r_23 - 3.14159);
      };
    };
  } else {
    r_23 = (sign(tmpvar_21.x) * 1.5708);
  };
  uv_22.x = (0.5 + (0.159155 * r_23));
  uv_22.y = (0.31831 * (1.5708 - (sign(tmpvar_21.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_21.y))) * (1.5708 + (abs(tmpvar_21.y) * (-0.214602 + (abs(tmpvar_21.y) * (0.0865667 + (abs(tmpvar_21.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_27;
  tmpvar_27 = ((uv_22 * 4.0) * _DetailScale);
  highp vec2 tmpvar_28;
  tmpvar_28 = dFdx(tmpvar_21.xz);
  highp vec2 tmpvar_29;
  tmpvar_29 = dFdy(tmpvar_21.xz);
  highp vec4 tmpvar_30;
  tmpvar_30.x = (0.159155 * sqrt(dot (tmpvar_28, tmpvar_28)));
  tmpvar_30.y = dFdx(tmpvar_27.y);
  tmpvar_30.z = (0.159155 * sqrt(dot (tmpvar_29, tmpvar_29)));
  tmpvar_30.w = dFdy(tmpvar_27.y);
  highp vec3 tmpvar_31;
  tmpvar_31 = abs(tmpvar_21);
  highp float tmpvar_32;
  tmpvar_32 = float((tmpvar_31.z >= tmpvar_31.x));
  zxlerp_20 = tmpvar_32;
  highp float tmpvar_33;
  tmpvar_33 = float((mix (tmpvar_31.x, tmpvar_31.z, zxlerp_20) >= tmpvar_31.y));
  nylerp_19 = tmpvar_33;
  highp vec3 tmpvar_34;
  tmpvar_34 = mix (tmpvar_31, tmpvar_31.zxy, vec3(zxlerp_20));
  detailCoords_18 = tmpvar_34;
  highp vec3 tmpvar_35;
  tmpvar_35 = mix (tmpvar_31.yxz, detailCoords_18, vec3(nylerp_19));
  detailCoords_18 = tmpvar_35;
  mediump float tmpvar_36;
  tmpvar_36 = abs(detailCoords_18.x);
  highp vec2 coord_37;
  coord_37 = (((0.5 * detailCoords_18.zy) / tmpvar_36) * _DetailScale);
  lowp vec4 tmpvar_38;
  tmpvar_38 = texture2DGradEXT (_DetailTex, coord_37, tmpvar_30.xy, tmpvar_30.zw);
  tmpvar_17 = tmpvar_38;
  color_5 = _SurfaceColor;
  highp float tmpvar_39;
  tmpvar_39 = clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0);
  detailLevel_4 = tmpvar_39;
  color_5.xyz = (color_5.xyz + (0.5 * mix ((tmpvar_17.xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(detailLevel_4))));
  highp float tmpvar_40;
  tmpvar_40 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  handoff_3 = tmpvar_40;
  color_5.xyz = mix (color_5.xyz, tex_6.xyz, vec3(handoff_3));
  specColor_2.xyz = _SpecColor.xyz;
  specColor_2.w = mix (1.0, tex_6.w, handoff_3);
  highp vec3 tmpvar_41;
  tmpvar_41 = normalize(_WorldSpaceLightPos0).xyz;
  highp vec3 tmpvar_42;
  tmpvar_42 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  lowp vec4 tmpvar_43;
  highp vec2 P_44;
  P_44 = ((xlv_TEXCOORD3.xy / xlv_TEXCOORD3.w) + 0.5);
  tmpvar_43 = texture2D (_LightTexture0, P_44);
  highp float tmpvar_45;
  tmpvar_45 = dot (xlv_TEXCOORD3.xyz, xlv_TEXCOORD3.xyz);
  lowp vec4 tmpvar_46;
  tmpvar_46 = texture2D (_LightTextureB0, vec2(tmpvar_45));
  lowp float tmpvar_47;
  mediump float shadow_48;
  lowp vec4 tmpvar_49;
  tmpvar_49 = texture2DProj (_ShadowMapTexture, xlv_TEXCOORD4);
  highp float tmpvar_50;
  if ((tmpvar_49.x < (xlv_TEXCOORD4.z / xlv_TEXCOORD4.w))) {
    tmpvar_50 = _LightShadowData.x;
  } else {
    tmpvar_50 = 1.0;
  };
  shadow_48 = tmpvar_50;
  tmpvar_47 = shadow_48;
  mediump vec3 lightDir_51;
  lightDir_51 = tmpvar_41;
  mediump vec3 viewDir_52;
  viewDir_52 = xlv_TEXCOORD1;
  mediump vec3 normal_53;
  normal_53 = tmpvar_42;
  mediump float atten_54;
  atten_54 = (((float((xlv_TEXCOORD3.z > 0.0)) * tmpvar_43.w) * tmpvar_46.w) * tmpvar_47);
  mediump vec4 c_55;
  highp float nh_56;
  mediump vec3 tmpvar_57;
  tmpvar_57 = normalize(lightDir_51);
  lightDir_51 = tmpvar_57;
  mediump vec3 tmpvar_58;
  tmpvar_58 = normalize(viewDir_52);
  viewDir_52 = tmpvar_58;
  mediump float tmpvar_59;
  tmpvar_59 = dot (normal_53, tmpvar_57);
  mediump float tmpvar_60;
  tmpvar_60 = clamp (dot (normalize((tmpvar_57 + tmpvar_58)), normal_53), 0.0, 1.0);
  nh_56 = tmpvar_60;
  highp vec3 tmpvar_61;
  tmpvar_61 = ((((color_5.xyz * _LightColor0.xyz) * tmpvar_59) + ((_LightColor0.xyz * specColor_2.xyz) * (pow (nh_56, (_Shininess * 128.0)) * color_5.w))) * (atten_54 * 4.0));
  c_55.xyz = tmpvar_61;
  c_55.w = (tmpvar_59 * (atten_54 * 4.0));
  color_5.w = mix (1.0, color_5.w, clamp ((c_55.w * 4.0), 0.0, 1.0));
  mediump vec3 arg0_62;
  arg0_62 = (2.0 * color_5.xyz);
  color_5.w = mix (color_5.w, 1.0, clamp ((sqrt(dot (c_55.xyz, c_55.xyz)) - sqrt(dot (arg0_62, arg0_62))), 0.0, 1.0));
  color_5.w = mix (color_5.w, 1.0, handoff_3);
  color_5.xyz = c_55.xyz;
  tmpvar_1 = color_5;
  gl_FragData[0] = tmpvar_1;
}



#endif"
}

SubProgram "gles3 " {
Keywords { "SPOT" "SHADOWS_DEPTH" }
"!!GLES3#version 300 es


#ifdef VERTEX

#define gl_Vertex _glesVertex
in vec4 _glesVertex;
#define gl_Normal (normalize(_glesNormal))
in vec3 _glesNormal;
#define gl_MultiTexCoord0 _glesMultiTexCoord0
in vec4 _glesMultiTexCoord0;
#define gl_MultiTexCoord1 _glesMultiTexCoord1
in vec4 _glesMultiTexCoord1;

#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 332
struct SurfaceOutput {
    lowp vec3 Albedo;
    lowp vec3 Normal;
    lowp vec3 Emission;
    mediump float Specular;
    lowp float Gloss;
    lowp float Alpha;
};
#line 529
struct v2f {
    highp vec4 pos;
    highp float viewDist;
    highp vec3 viewDir;
    highp vec3 worldPos;
    highp vec4 _LightCoord;
    highp vec4 _ShadowCoord;
    highp vec3 sphereNormal;
};
#line 521
struct appdata_t {
    highp vec4 vertex;
    highp vec3 normal;
    highp vec4 texcoord;
    highp vec4 texcoord2;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform highp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform sampler2D _ShadowMapTexture;
uniform sampler2D _LightTexture0;
uniform highp mat4 _LightMatrix0;
#line 323
uniform sampler2D _LightTextureB0;
#line 328
#line 342
uniform lowp vec4 _LightColor0;
uniform lowp vec4 _SpecColor;
#line 355
#line 363
#line 377
uniform highp mat4 _MainRotation;
uniform highp mat4 _DetailRotation;
#line 410
#line 414
#line 423
#line 431
#line 440
#line 448
#line 461
#line 473
#line 489
#line 502
uniform lowp vec4 _SurfaceColor;
#line 510
uniform highp float _Shininess;
uniform sampler2D _MainTex;
uniform sampler2D _DetailTex;
uniform highp float _DetailScale;
#line 514
uniform highp float _DetailDist;
uniform highp float _MinLight;
uniform sampler2D _CameraDepthTexture;
uniform highp mat4 _CameraToWorld;
#line 518
uniform highp float _LightPower;
uniform highp float _PlanetOpacity;
uniform highp vec3 _PlanetOrigin;
#line 540
#line 540
v2f vert( in appdata_t v ) {
    v2f o;
    highp vec4 vertex = v.vertex;
    #line 544
    o.pos = (glstate_matrix_mvp * vertex).xyzw;
    highp vec3 vertexPos = (_Object2World * vertex).xyz;
    o.viewDist = distance( vertexPos, _WorldSpaceCameraPos);
    o.worldPos = vertexPos;
    #line 548
    o.sphereNormal = (-normalize(vec4( v.texcoord.x, v.texcoord.y, v.texcoord2.x, v.texcoord2.y)).xyz);
    o.viewDir = normalize((_WorldSpaceCameraPos.xyz - vertexPos));
    o._LightCoord = (_LightMatrix0 * (_Object2World * v.vertex));
    o._ShadowCoord = (unity_World2Shadow[0] * (_Object2World * v.vertex));
    #line 553
    return o;
}
out highp float xlv_TEXCOORD0;
out highp vec3 xlv_TEXCOORD1;
out highp vec3 xlv_TEXCOORD2;
out highp vec4 xlv_TEXCOORD3;
out highp vec4 xlv_TEXCOORD4;
out highp vec3 xlv_TEXCOORD5;
void main() {
    v2f xl_retval;
    appdata_t xlt_v;
    xlt_v.vertex = vec4(gl_Vertex);
    xlt_v.normal = vec3(gl_Normal);
    xlt_v.texcoord = vec4(gl_MultiTexCoord0);
    xlt_v.texcoord2 = vec4(gl_MultiTexCoord1);
    xl_retval = vert( xlt_v);
    gl_Position = vec4(xl_retval.pos);
    xlv_TEXCOORD0 = float(xl_retval.viewDist);
    xlv_TEXCOORD1 = vec3(xl_retval.viewDir);
    xlv_TEXCOORD2 = vec3(xl_retval.worldPos);
    xlv_TEXCOORD3 = vec4(xl_retval._LightCoord);
    xlv_TEXCOORD4 = vec4(xl_retval._ShadowCoord);
    xlv_TEXCOORD5 = vec3(xl_retval.sphereNormal);
}


#endif
#ifdef FRAGMENT

#define gl_FragData _glesFragData
layout(location = 0) out mediump vec4 _glesFragData[4];
float xll_dFdx_f(float f) {
  return dFdx(f);
}
vec2 xll_dFdx_vf2(vec2 v) {
  return dFdx(v);
}
vec3 xll_dFdx_vf3(vec3 v) {
  return dFdx(v);
}
vec4 xll_dFdx_vf4(vec4 v) {
  return dFdx(v);
}
mat2 xll_dFdx_mf2x2(mat2 m) {
  return mat2( dFdx(m[0]), dFdx(m[1]));
}
mat3 xll_dFdx_mf3x3(mat3 m) {
  return mat3( dFdx(m[0]), dFdx(m[1]), dFdx(m[2]));
}
mat4 xll_dFdx_mf4x4(mat4 m) {
  return mat4( dFdx(m[0]), dFdx(m[1]), dFdx(m[2]), dFdx(m[3]));
}
float xll_dFdy_f(float f) {
  return dFdy(f);
}
vec2 xll_dFdy_vf2(vec2 v) {
  return dFdy(v);
}
vec3 xll_dFdy_vf3(vec3 v) {
  return dFdy(v);
}
vec4 xll_dFdy_vf4(vec4 v) {
  return dFdy(v);
}
mat2 xll_dFdy_mf2x2(mat2 m) {
  return mat2( dFdy(m[0]), dFdy(m[1]));
}
mat3 xll_dFdy_mf3x3(mat3 m) {
  return mat3( dFdy(m[0]), dFdy(m[1]), dFdy(m[2]));
}
mat4 xll_dFdy_mf4x4(mat4 m) {
  return mat4( dFdy(m[0]), dFdy(m[1]), dFdy(m[2]), dFdy(m[3]));
}
vec4 xll_tex2Dgrad(sampler2D s, vec2 coord, vec2 ddx, vec2 ddy) {
   return textureGrad( s, coord, ddx, ddy);
}
float xll_saturate_f( float x) {
  return clamp( x, 0.0, 1.0);
}
vec2 xll_saturate_vf2( vec2 x) {
  return clamp( x, 0.0, 1.0);
}
vec3 xll_saturate_vf3( vec3 x) {
  return clamp( x, 0.0, 1.0);
}
vec4 xll_saturate_vf4( vec4 x) {
  return clamp( x, 0.0, 1.0);
}
mat2 xll_saturate_mf2x2(mat2 m) {
  return mat2( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0));
}
mat3 xll_saturate_mf3x3(mat3 m) {
  return mat3( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0));
}
mat4 xll_saturate_mf4x4(mat4 m) {
  return mat4( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0), clamp(m[3], 0.0, 1.0));
}
#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 332
struct SurfaceOutput {
    lowp vec3 Albedo;
    lowp vec3 Normal;
    lowp vec3 Emission;
    mediump float Specular;
    lowp float Gloss;
    lowp float Alpha;
};
#line 529
struct v2f {
    highp vec4 pos;
    highp float viewDist;
    highp vec3 viewDir;
    highp vec3 worldPos;
    highp vec4 _LightCoord;
    highp vec4 _ShadowCoord;
    highp vec3 sphereNormal;
};
#line 521
struct appdata_t {
    highp vec4 vertex;
    highp vec3 normal;
    highp vec4 texcoord;
    highp vec4 texcoord2;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform highp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform sampler2D _ShadowMapTexture;
uniform sampler2D _LightTexture0;
uniform highp mat4 _LightMatrix0;
#line 323
uniform sampler2D _LightTextureB0;
#line 328
#line 342
uniform lowp vec4 _LightColor0;
uniform lowp vec4 _SpecColor;
#line 355
#line 363
#line 377
uniform highp mat4 _MainRotation;
uniform highp mat4 _DetailRotation;
#line 410
#line 414
#line 423
#line 431
#line 440
#line 448
#line 461
#line 473
#line 489
#line 502
uniform lowp vec4 _SurfaceColor;
#line 510
uniform highp float _Shininess;
uniform sampler2D _MainTex;
uniform sampler2D _DetailTex;
uniform highp float _DetailScale;
#line 514
uniform highp float _DetailDist;
uniform highp float _MinLight;
uniform sampler2D _CameraDepthTexture;
uniform highp mat4 _CameraToWorld;
#line 518
uniform highp float _LightPower;
uniform highp float _PlanetOpacity;
uniform highp vec3 _PlanetOrigin;
#line 540
#line 414
highp vec4 Derivatives( in highp float lat, in highp float lon, in highp vec3 pos ) {
    highp vec2 latLong = vec2( lat, lon);
    highp float latDdx = (0.159155 * length(xll_dFdx_vf2(pos.xz)));
    #line 418
    highp float latDdy = (0.159155 * length(xll_dFdy_vf2(pos.xz)));
    highp float longDdx = xll_dFdx_f(lon);
    highp float longDdy = xll_dFdy_f(lon);
    return vec4( latDdx, longDdx, latDdy, longDdy);
}
#line 423
highp vec2 GetSphereUV( in highp vec3 sphereVect, in highp vec2 uvOffset ) {
    highp vec2 uv;
    uv.x = (0.5 + (0.159155 * atan( sphereVect.x, sphereVect.z)));
    #line 427
    uv.y = (0.31831 * acos(sphereVect.y));
    uv += uvOffset;
    return uv;
}
#line 461
mediump vec4 GetShereDetailMap( in sampler2D texSampler, in highp vec3 sphereVect, in highp float detailScale ) {
    highp vec3 sphereVectNorm = normalize(sphereVect);
    highp vec2 uv = ((GetSphereUV( sphereVectNorm, vec2( 0.0, 0.0)) * 4.0) * detailScale);
    #line 465
    highp vec4 uvdd = Derivatives( (uv.x - 0.5), uv.y, sphereVectNorm);
    sphereVectNorm = abs(sphereVectNorm);
    mediump float zxlerp = step( sphereVectNorm.x, sphereVectNorm.z);
    mediump float nylerp = step( sphereVectNorm.y, mix( sphereVectNorm.x, sphereVectNorm.z, zxlerp));
    #line 469
    mediump vec3 detailCoords = mix( sphereVectNorm.xyz, sphereVectNorm.zxy, vec3( zxlerp));
    detailCoords = mix( sphereVectNorm.yxz, detailCoords, vec3( nylerp));
    return xll_tex2Dgrad( texSampler, (((0.5 * detailCoords.zy) / abs(detailCoords.x)) * detailScale), uvdd.xy, uvdd.zw);
}
#line 440
mediump vec4 GetSphereMap( in sampler2D texSampler, in highp vec3 sphereVect ) {
    highp vec3 sphereVectNorm = normalize(sphereVect);
    highp vec2 uv = GetSphereUV( sphereVectNorm, vec2( 0.0, 0.0));
    #line 444
    highp vec4 uvdd = Derivatives( (uv.x - 0.5), uv.y, sphereVectNorm);
    mediump vec4 tex = xll_tex2Dgrad( texSampler, uv, uvdd.xy, uvdd.zw);
    return tex;
}
#line 489
mediump vec4 SpecularColorLight( in mediump vec3 lightDir, in mediump vec3 viewDir, in mediump vec3 normal, in mediump vec4 color, in mediump vec4 specColor, in highp float specK, in mediump float atten ) {
    lightDir = normalize(lightDir);
    viewDir = normalize(viewDir);
    #line 493
    mediump vec3 h = normalize((lightDir + viewDir));
    mediump float diffuse = dot( normal, lightDir);
    highp float nh = xll_saturate_f(dot( h, normal));
    highp float spec = (pow( nh, specK) * color.w);
    #line 497
    mediump vec4 c;
    c.xyz = ((((color.xyz * _LightColor0.xyz) * diffuse) + ((_LightColor0.xyz * specColor.xyz) * spec)) * (atten * 4.0));
    c.w = (diffuse * (atten * 4.0));
    return c;
}
#line 328
lowp float UnitySpotAttenuate( in highp vec3 LightCoord ) {
    return texture( _LightTextureB0, vec2( dot( LightCoord, LightCoord))).w;
}
#line 324
lowp float UnitySpotCookie( in highp vec4 LightCoord ) {
    return texture( _LightTexture0, ((LightCoord.xy / LightCoord.w) + 0.5)).w;
}
#line 316
lowp float unitySampleShadow( in highp vec4 shadowCoord ) {
    mediump float shadow = (( (textureProj( _ShadowMapTexture, shadowCoord).x < (shadowCoord.z / shadowCoord.w)) ) ? ( _LightShadowData.x ) : ( 1.0 ));
    #line 319
    return shadow;
}
#line 555
lowp vec4 frag( in v2f IN ) {
    #line 557
    mediump vec4 color;
    highp vec3 sphereNrm = IN.sphereNormal;
    mediump vec4 main = GetSphereMap( _MainTex, sphereNrm);
    mediump vec4 detail = GetShereDetailMap( _DetailTex, sphereNrm, _DetailScale);
    #line 561
    color = _SurfaceColor;
    mediump float detailLevel = xll_saturate_f(((2.0 * _DetailDist) * IN.viewDist));
    color.xyz += (0.5 * mix( (detail.xyz - 0.5), vec3( 0.0), vec3( detailLevel)));
    mediump float handoff = xll_saturate_f(pow( _PlanetOpacity, 2.0));
    #line 565
    color.xyz = mix( color.xyz, main.xyz, vec3( handoff));
    mediump vec4 specColor = _SpecColor;
    specColor.w = mix( 1.0, main.w, handoff);
    mediump vec4 colorLight = SpecularColorLight( vec3( normalize(_WorldSpaceLightPos0)), IN.viewDir, normalize((IN.worldPos - _PlanetOrigin)), color, specColor, (_Shininess * 128.0), (((float((IN._LightCoord.z > 0.0)) * UnitySpotCookie( IN._LightCoord)) * UnitySpotAttenuate( IN._LightCoord.xyz)) * unitySampleShadow( IN._ShadowCoord)));
    #line 569
    color.w = mix( 1.0, color.w, xll_saturate_f((colorLight.w * 4.0)));
    color.w = mix( color.w, 1.0, xll_saturate_f((length(colorLight.xyz) - length((2.0 * color.xyz)))));
    color.w = mix( color.w, 1.0, handoff);
    color.xyz = colorLight.xyz;
    #line 573
    return color;
}
in highp float xlv_TEXCOORD0;
in highp vec3 xlv_TEXCOORD1;
in highp vec3 xlv_TEXCOORD2;
in highp vec4 xlv_TEXCOORD3;
in highp vec4 xlv_TEXCOORD4;
in highp vec3 xlv_TEXCOORD5;
void main() {
    lowp vec4 xl_retval;
    v2f xlt_IN;
    xlt_IN.pos = vec4(0.0);
    xlt_IN.viewDist = float(xlv_TEXCOORD0);
    xlt_IN.viewDir = vec3(xlv_TEXCOORD1);
    xlt_IN.worldPos = vec3(xlv_TEXCOORD2);
    xlt_IN._LightCoord = vec4(xlv_TEXCOORD3);
    xlt_IN._ShadowCoord = vec4(xlv_TEXCOORD4);
    xlt_IN.sphereNormal = vec3(xlv_TEXCOORD5);
    xl_retval = frag( xlt_IN);
    gl_FragData[0] = vec4(xl_retval);
}


#endif"
}

SubProgram "opengl " {
Keywords { "SPOT" "SHADOWS_DEPTH" "SHADOWS_NATIVE" }
"!!GLSL
#ifdef VERTEX
varying vec3 xlv_TEXCOORD5;
varying vec4 xlv_TEXCOORD4;
varying vec4 xlv_TEXCOORD3;
varying vec3 xlv_TEXCOORD2;
varying vec3 xlv_TEXCOORD1;
varying float xlv_TEXCOORD0;
uniform mat4 _LightMatrix0;
uniform mat4 _Object2World;

uniform mat4 unity_World2Shadow[4];
uniform vec3 _WorldSpaceCameraPos;
void main ()
{
  vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * gl_Vertex).xyz;
  vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  vec4 tmpvar_3;
  tmpvar_3.x = gl_MultiTexCoord0.x;
  tmpvar_3.y = gl_MultiTexCoord0.y;
  tmpvar_3.z = gl_MultiTexCoord1.x;
  tmpvar_3.w = gl_MultiTexCoord1.y;
  gl_Position = (gl_ModelViewProjectionMatrix * gl_Vertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * gl_Vertex));
  xlv_TEXCOORD4 = (unity_World2Shadow[0] * (_Object2World * gl_Vertex));
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}


#endif
#ifdef FRAGMENT
#extension GL_ARB_shader_texture_lod : enable
varying vec3 xlv_TEXCOORD5;
varying vec4 xlv_TEXCOORD4;
varying vec4 xlv_TEXCOORD3;
varying vec3 xlv_TEXCOORD2;
varying vec3 xlv_TEXCOORD1;
varying float xlv_TEXCOORD0;
uniform vec3 _PlanetOrigin;
uniform float _PlanetOpacity;
uniform float _DetailDist;
uniform float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform float _Shininess;
uniform vec4 _SurfaceColor;
uniform vec4 _SpecColor;
uniform vec4 _LightColor0;
uniform sampler2D _LightTextureB0;
uniform sampler2D _LightTexture0;
uniform sampler2DShadow _ShadowMapTexture;
uniform vec4 _LightShadowData;
uniform vec4 _WorldSpaceLightPos0;
void main ()
{
  vec4 main_1;
  vec4 color_2;
  vec3 tmpvar_3;
  tmpvar_3 = normalize(xlv_TEXCOORD5);
  vec2 uv_4;
  float r_5;
  if ((abs(tmpvar_3.z) > (1e-08 * abs(tmpvar_3.x)))) {
    float y_over_x_6;
    y_over_x_6 = (tmpvar_3.x / tmpvar_3.z);
    float s_7;
    float x_8;
    x_8 = (y_over_x_6 * inversesqrt(((y_over_x_6 * y_over_x_6) + 1.0)));
    s_7 = (sign(x_8) * (1.5708 - (sqrt((1.0 - abs(x_8))) * (1.5708 + (abs(x_8) * (-0.214602 + (abs(x_8) * (0.0865667 + (abs(x_8) * -0.0310296)))))))));
    r_5 = s_7;
    if ((tmpvar_3.z < 0.0)) {
      if ((tmpvar_3.x >= 0.0)) {
        r_5 = (s_7 + 3.14159);
      } else {
        r_5 = (r_5 - 3.14159);
      };
    };
  } else {
    r_5 = (sign(tmpvar_3.x) * 1.5708);
  };
  uv_4.x = (0.5 + (0.159155 * r_5));
  uv_4.y = (0.31831 * (1.5708 - (sign(tmpvar_3.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_3.y))) * (1.5708 + (abs(tmpvar_3.y) * (-0.214602 + (abs(tmpvar_3.y) * (0.0865667 + (abs(tmpvar_3.y) * -0.0310296)))))))))));
  vec2 tmpvar_9;
  tmpvar_9 = dFdx(tmpvar_3.xz);
  vec2 tmpvar_10;
  tmpvar_10 = dFdy(tmpvar_3.xz);
  vec4 tmpvar_11;
  tmpvar_11.x = (0.159155 * sqrt(dot (tmpvar_9, tmpvar_9)));
  tmpvar_11.y = dFdx(uv_4.y);
  tmpvar_11.z = (0.159155 * sqrt(dot (tmpvar_10, tmpvar_10)));
  tmpvar_11.w = dFdy(uv_4.y);
  main_1 = texture2DGradARB (_MainTex, uv_4, tmpvar_11.xy, tmpvar_11.zw);
  vec3 tmpvar_12;
  tmpvar_12 = normalize(xlv_TEXCOORD5);
  vec2 uv_13;
  float r_14;
  if ((abs(tmpvar_12.z) > (1e-08 * abs(tmpvar_12.x)))) {
    float y_over_x_15;
    y_over_x_15 = (tmpvar_12.x / tmpvar_12.z);
    float s_16;
    float x_17;
    x_17 = (y_over_x_15 * inversesqrt(((y_over_x_15 * y_over_x_15) + 1.0)));
    s_16 = (sign(x_17) * (1.5708 - (sqrt((1.0 - abs(x_17))) * (1.5708 + (abs(x_17) * (-0.214602 + (abs(x_17) * (0.0865667 + (abs(x_17) * -0.0310296)))))))));
    r_14 = s_16;
    if ((tmpvar_12.z < 0.0)) {
      if ((tmpvar_12.x >= 0.0)) {
        r_14 = (s_16 + 3.14159);
      } else {
        r_14 = (r_14 - 3.14159);
      };
    };
  } else {
    r_14 = (sign(tmpvar_12.x) * 1.5708);
  };
  uv_13.x = (0.5 + (0.159155 * r_14));
  uv_13.y = (0.31831 * (1.5708 - (sign(tmpvar_12.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_12.y))) * (1.5708 + (abs(tmpvar_12.y) * (-0.214602 + (abs(tmpvar_12.y) * (0.0865667 + (abs(tmpvar_12.y) * -0.0310296)))))))))));
  vec2 tmpvar_18;
  tmpvar_18 = ((uv_13 * 4.0) * _DetailScale);
  vec2 tmpvar_19;
  tmpvar_19 = dFdx(tmpvar_12.xz);
  vec2 tmpvar_20;
  tmpvar_20 = dFdy(tmpvar_12.xz);
  vec4 tmpvar_21;
  tmpvar_21.x = (0.159155 * sqrt(dot (tmpvar_19, tmpvar_19)));
  tmpvar_21.y = dFdx(tmpvar_18.y);
  tmpvar_21.z = (0.159155 * sqrt(dot (tmpvar_20, tmpvar_20)));
  tmpvar_21.w = dFdy(tmpvar_18.y);
  vec3 tmpvar_22;
  tmpvar_22 = abs(tmpvar_12);
  float tmpvar_23;
  tmpvar_23 = float((tmpvar_22.z >= tmpvar_22.x));
  vec3 tmpvar_24;
  tmpvar_24 = mix (tmpvar_22.yxz, mix (tmpvar_22, tmpvar_22.zxy, vec3(tmpvar_23)), vec3(float((mix (tmpvar_22.x, tmpvar_22.z, tmpvar_23) >= tmpvar_22.y))));
  color_2.w = _SurfaceColor.w;
  color_2.xyz = (_SurfaceColor.xyz + (0.5 * mix ((texture2DGradARB (_DetailTex, (((0.5 * tmpvar_24.zy) / abs(tmpvar_24.x)) * _DetailScale), tmpvar_21.xy, tmpvar_21.zw).xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0)))));
  float tmpvar_25;
  tmpvar_25 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  color_2.xyz = mix (color_2.xyz, main_1.xyz, vec3(tmpvar_25));
  vec3 tmpvar_26;
  tmpvar_26 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  float atten_27;
  atten_27 = (((float((xlv_TEXCOORD3.z > 0.0)) * texture2D (_LightTexture0, ((xlv_TEXCOORD3.xy / xlv_TEXCOORD3.w) + 0.5)).w) * texture2D (_LightTextureB0, vec2(dot (xlv_TEXCOORD3.xyz, xlv_TEXCOORD3.xyz))).w) * (_LightShadowData.x + (shadow2DProj (_ShadowMapTexture, xlv_TEXCOORD4).x * (1.0 - _LightShadowData.x))));
  vec4 c_28;
  vec3 tmpvar_29;
  tmpvar_29 = normalize(normalize(_WorldSpaceLightPos0).xyz);
  float tmpvar_30;
  tmpvar_30 = dot (tmpvar_26, tmpvar_29);
  c_28.xyz = ((((color_2.xyz * _LightColor0.xyz) * tmpvar_30) + ((_LightColor0.xyz * _SpecColor.xyz) * (pow (clamp (dot (normalize((tmpvar_29 + normalize(xlv_TEXCOORD1))), tmpvar_26), 0.0, 1.0), (_Shininess * 128.0)) * _SurfaceColor.w))) * (atten_27 * 4.0));
  c_28.w = (tmpvar_30 * (atten_27 * 4.0));
  color_2.w = mix (1.0, _SurfaceColor.w, clamp ((c_28.w * 4.0), 0.0, 1.0));
  vec3 arg0_31;
  arg0_31 = (2.0 * color_2.xyz);
  color_2.w = mix (color_2.w, 1.0, clamp ((sqrt(dot (c_28.xyz, c_28.xyz)) - sqrt(dot (arg0_31, arg0_31))), 0.0, 1.0));
  color_2.w = mix (color_2.w, 1.0, tmpvar_25);
  color_2.xyz = c_28.xyz;
  gl_FragData[0] = color_2;
}


#endif
"
}

SubProgram "d3d9 " {
Keywords { "SPOT" "SHADOWS_DEPTH" "SHADOWS_NATIVE" }
Bind "vertex" Vertex
Bind "texcoord" TexCoord0
Bind "texcoord1" TexCoord1
Matrix 0 [glstate_matrix_mvp]
Vector 16 [_WorldSpaceCameraPos]
Matrix 4 [unity_World2Shadow0]
Matrix 8 [_Object2World]
Matrix 12 [_LightMatrix0]
"vs_3_0
; 29 ALU
dcl_position o0
dcl_texcoord0 o1
dcl_texcoord1 o2
dcl_texcoord2 o3
dcl_texcoord3 o4
dcl_texcoord4 o5
dcl_texcoord5 o6
dcl_position0 v0
dcl_texcoord0 v1
dcl_texcoord1 v2
mov r1.zw, v2.xyxy
mov r1.xy, v1
dp4 r0.w, r1, r1
rsq r1.w, r0.w
mul r1.xyz, r1.w, r1
dp4 r1.w, v0, c11
dp4 r0.z, v0, c10
dp4 r0.x, v0, c8
dp4 r0.y, v0, c9
add r2.xyz, -r0, c16
dp3 r0.w, r2, r2
rsq r0.w, r0.w
mov o6.xyz, -r1
mov r1.xyz, r0
mul o2.xyz, r0.w, r2
dp4 o4.w, r1, c15
dp4 o4.z, r1, c14
dp4 o4.y, r1, c13
dp4 o4.x, r1, c12
dp4 o5.w, r1, c7
dp4 o5.z, r1, c6
dp4 o5.y, r1, c5
dp4 o5.x, r1, c4
rcp o1.x, r0.w
mov o3.xyz, r0
dp4 o0.w, v0, c3
dp4 o0.z, v0, c2
dp4 o0.y, v0, c1
dp4 o0.x, v0, c0
"
}

SubProgram "gles " {
Keywords { "SPOT" "SHADOWS_DEPTH" "SHADOWS_NATIVE" }
"!!GLES


#ifdef VERTEX

#extension GL_EXT_shadow_samplers : enable
varying highp vec3 xlv_TEXCOORD5;
varying highp vec4 xlv_TEXCOORD4;
varying highp vec4 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp mat4 _LightMatrix0;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec3 _WorldSpaceCameraPos;
attribute vec4 _glesMultiTexCoord1;
attribute vec4 _glesMultiTexCoord0;
attribute vec4 _glesVertex;
void main ()
{
  highp vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * _glesVertex).xyz;
  highp vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  highp vec4 tmpvar_3;
  tmpvar_3.x = _glesMultiTexCoord0.x;
  tmpvar_3.y = _glesMultiTexCoord0.y;
  tmpvar_3.z = _glesMultiTexCoord1.x;
  tmpvar_3.w = _glesMultiTexCoord1.y;
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * _glesVertex));
  xlv_TEXCOORD4 = (unity_World2Shadow[0] * (_Object2World * _glesVertex));
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}



#endif
#ifdef FRAGMENT

#extension GL_EXT_shader_texture_lod : enable
#extension GL_OES_standard_derivatives : enable
#extension GL_EXT_shadow_samplers : enable
varying highp vec3 xlv_TEXCOORD5;
varying highp vec4 xlv_TEXCOORD4;
varying highp vec4 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp vec3 _PlanetOrigin;
uniform highp float _PlanetOpacity;
uniform highp float _DetailDist;
uniform highp float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform highp float _Shininess;
uniform lowp vec4 _SurfaceColor;
uniform lowp vec4 _SpecColor;
uniform lowp vec4 _LightColor0;
uniform sampler2D _LightTextureB0;
uniform sampler2D _LightTexture0;
uniform lowp sampler2DShadow _ShadowMapTexture;
uniform highp vec4 _LightShadowData;
uniform highp vec4 _WorldSpaceLightPos0;
void main ()
{
  lowp vec4 tmpvar_1;
  mediump vec4 specColor_2;
  mediump float handoff_3;
  mediump float detailLevel_4;
  mediump vec4 color_5;
  mediump vec4 tex_6;
  highp vec3 tmpvar_7;
  tmpvar_7 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_8;
  highp float r_9;
  if ((abs(tmpvar_7.z) > (1e-08 * abs(tmpvar_7.x)))) {
    highp float y_over_x_10;
    y_over_x_10 = (tmpvar_7.x / tmpvar_7.z);
    highp float s_11;
    highp float x_12;
    x_12 = (y_over_x_10 * inversesqrt(((y_over_x_10 * y_over_x_10) + 1.0)));
    s_11 = (sign(x_12) * (1.5708 - (sqrt((1.0 - abs(x_12))) * (1.5708 + (abs(x_12) * (-0.214602 + (abs(x_12) * (0.0865667 + (abs(x_12) * -0.0310296)))))))));
    r_9 = s_11;
    if ((tmpvar_7.z < 0.0)) {
      if ((tmpvar_7.x >= 0.0)) {
        r_9 = (s_11 + 3.14159);
      } else {
        r_9 = (r_9 - 3.14159);
      };
    };
  } else {
    r_9 = (sign(tmpvar_7.x) * 1.5708);
  };
  uv_8.x = (0.5 + (0.159155 * r_9));
  uv_8.y = (0.31831 * (1.5708 - (sign(tmpvar_7.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_7.y))) * (1.5708 + (abs(tmpvar_7.y) * (-0.214602 + (abs(tmpvar_7.y) * (0.0865667 + (abs(tmpvar_7.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_13;
  tmpvar_13 = dFdx(tmpvar_7.xz);
  highp vec2 tmpvar_14;
  tmpvar_14 = dFdy(tmpvar_7.xz);
  highp vec4 tmpvar_15;
  tmpvar_15.x = (0.159155 * sqrt(dot (tmpvar_13, tmpvar_13)));
  tmpvar_15.y = dFdx(uv_8.y);
  tmpvar_15.z = (0.159155 * sqrt(dot (tmpvar_14, tmpvar_14)));
  tmpvar_15.w = dFdy(uv_8.y);
  lowp vec4 tmpvar_16;
  tmpvar_16 = texture2DGradEXT (_MainTex, uv_8, tmpvar_15.xy, tmpvar_15.zw);
  tex_6 = tmpvar_16;
  mediump vec4 tmpvar_17;
  mediump vec3 detailCoords_18;
  mediump float nylerp_19;
  mediump float zxlerp_20;
  highp vec3 tmpvar_21;
  tmpvar_21 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_22;
  highp float r_23;
  if ((abs(tmpvar_21.z) > (1e-08 * abs(tmpvar_21.x)))) {
    highp float y_over_x_24;
    y_over_x_24 = (tmpvar_21.x / tmpvar_21.z);
    highp float s_25;
    highp float x_26;
    x_26 = (y_over_x_24 * inversesqrt(((y_over_x_24 * y_over_x_24) + 1.0)));
    s_25 = (sign(x_26) * (1.5708 - (sqrt((1.0 - abs(x_26))) * (1.5708 + (abs(x_26) * (-0.214602 + (abs(x_26) * (0.0865667 + (abs(x_26) * -0.0310296)))))))));
    r_23 = s_25;
    if ((tmpvar_21.z < 0.0)) {
      if ((tmpvar_21.x >= 0.0)) {
        r_23 = (s_25 + 3.14159);
      } else {
        r_23 = (r_23 - 3.14159);
      };
    };
  } else {
    r_23 = (sign(tmpvar_21.x) * 1.5708);
  };
  uv_22.x = (0.5 + (0.159155 * r_23));
  uv_22.y = (0.31831 * (1.5708 - (sign(tmpvar_21.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_21.y))) * (1.5708 + (abs(tmpvar_21.y) * (-0.214602 + (abs(tmpvar_21.y) * (0.0865667 + (abs(tmpvar_21.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_27;
  tmpvar_27 = ((uv_22 * 4.0) * _DetailScale);
  highp vec2 tmpvar_28;
  tmpvar_28 = dFdx(tmpvar_21.xz);
  highp vec2 tmpvar_29;
  tmpvar_29 = dFdy(tmpvar_21.xz);
  highp vec4 tmpvar_30;
  tmpvar_30.x = (0.159155 * sqrt(dot (tmpvar_28, tmpvar_28)));
  tmpvar_30.y = dFdx(tmpvar_27.y);
  tmpvar_30.z = (0.159155 * sqrt(dot (tmpvar_29, tmpvar_29)));
  tmpvar_30.w = dFdy(tmpvar_27.y);
  highp vec3 tmpvar_31;
  tmpvar_31 = abs(tmpvar_21);
  highp float tmpvar_32;
  tmpvar_32 = float((tmpvar_31.z >= tmpvar_31.x));
  zxlerp_20 = tmpvar_32;
  highp float tmpvar_33;
  tmpvar_33 = float((mix (tmpvar_31.x, tmpvar_31.z, zxlerp_20) >= tmpvar_31.y));
  nylerp_19 = tmpvar_33;
  highp vec3 tmpvar_34;
  tmpvar_34 = mix (tmpvar_31, tmpvar_31.zxy, vec3(zxlerp_20));
  detailCoords_18 = tmpvar_34;
  highp vec3 tmpvar_35;
  tmpvar_35 = mix (tmpvar_31.yxz, detailCoords_18, vec3(nylerp_19));
  detailCoords_18 = tmpvar_35;
  mediump float tmpvar_36;
  tmpvar_36 = abs(detailCoords_18.x);
  highp vec2 coord_37;
  coord_37 = (((0.5 * detailCoords_18.zy) / tmpvar_36) * _DetailScale);
  lowp vec4 tmpvar_38;
  tmpvar_38 = texture2DGradEXT (_DetailTex, coord_37, tmpvar_30.xy, tmpvar_30.zw);
  tmpvar_17 = tmpvar_38;
  color_5 = _SurfaceColor;
  highp float tmpvar_39;
  tmpvar_39 = clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0);
  detailLevel_4 = tmpvar_39;
  color_5.xyz = (color_5.xyz + (0.5 * mix ((tmpvar_17.xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(detailLevel_4))));
  highp float tmpvar_40;
  tmpvar_40 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  handoff_3 = tmpvar_40;
  color_5.xyz = mix (color_5.xyz, tex_6.xyz, vec3(handoff_3));
  specColor_2.xyz = _SpecColor.xyz;
  specColor_2.w = mix (1.0, tex_6.w, handoff_3);
  highp vec3 tmpvar_41;
  tmpvar_41 = normalize(_WorldSpaceLightPos0).xyz;
  highp vec3 tmpvar_42;
  tmpvar_42 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  lowp vec4 tmpvar_43;
  highp vec2 P_44;
  P_44 = ((xlv_TEXCOORD3.xy / xlv_TEXCOORD3.w) + 0.5);
  tmpvar_43 = texture2D (_LightTexture0, P_44);
  highp float tmpvar_45;
  tmpvar_45 = dot (xlv_TEXCOORD3.xyz, xlv_TEXCOORD3.xyz);
  lowp vec4 tmpvar_46;
  tmpvar_46 = texture2D (_LightTextureB0, vec2(tmpvar_45));
  lowp float tmpvar_47;
  mediump float shadow_48;
  lowp float tmpvar_49;
  tmpvar_49 = shadow2DProjEXT (_ShadowMapTexture, xlv_TEXCOORD4);
  shadow_48 = tmpvar_49;
  highp float tmpvar_50;
  tmpvar_50 = (_LightShadowData.x + (shadow_48 * (1.0 - _LightShadowData.x)));
  shadow_48 = tmpvar_50;
  tmpvar_47 = shadow_48;
  mediump vec3 lightDir_51;
  lightDir_51 = tmpvar_41;
  mediump vec3 viewDir_52;
  viewDir_52 = xlv_TEXCOORD1;
  mediump vec3 normal_53;
  normal_53 = tmpvar_42;
  mediump float atten_54;
  atten_54 = (((float((xlv_TEXCOORD3.z > 0.0)) * tmpvar_43.w) * tmpvar_46.w) * tmpvar_47);
  mediump vec4 c_55;
  highp float nh_56;
  mediump vec3 tmpvar_57;
  tmpvar_57 = normalize(lightDir_51);
  lightDir_51 = tmpvar_57;
  mediump vec3 tmpvar_58;
  tmpvar_58 = normalize(viewDir_52);
  viewDir_52 = tmpvar_58;
  mediump float tmpvar_59;
  tmpvar_59 = dot (normal_53, tmpvar_57);
  mediump float tmpvar_60;
  tmpvar_60 = clamp (dot (normalize((tmpvar_57 + tmpvar_58)), normal_53), 0.0, 1.0);
  nh_56 = tmpvar_60;
  highp vec3 tmpvar_61;
  tmpvar_61 = ((((color_5.xyz * _LightColor0.xyz) * tmpvar_59) + ((_LightColor0.xyz * specColor_2.xyz) * (pow (nh_56, (_Shininess * 128.0)) * color_5.w))) * (atten_54 * 4.0));
  c_55.xyz = tmpvar_61;
  c_55.w = (tmpvar_59 * (atten_54 * 4.0));
  color_5.w = mix (1.0, color_5.w, clamp ((c_55.w * 4.0), 0.0, 1.0));
  mediump vec3 arg0_62;
  arg0_62 = (2.0 * color_5.xyz);
  color_5.w = mix (color_5.w, 1.0, clamp ((sqrt(dot (c_55.xyz, c_55.xyz)) - sqrt(dot (arg0_62, arg0_62))), 0.0, 1.0));
  color_5.w = mix (color_5.w, 1.0, handoff_3);
  color_5.xyz = c_55.xyz;
  tmpvar_1 = color_5;
  gl_FragData[0] = tmpvar_1;
}



#endif"
}

SubProgram "gles3 " {
Keywords { "SPOT" "SHADOWS_DEPTH" "SHADOWS_NATIVE" }
"!!GLES3#version 300 es


#ifdef VERTEX

#define gl_Vertex _glesVertex
in vec4 _glesVertex;
#define gl_Normal (normalize(_glesNormal))
in vec3 _glesNormal;
#define gl_MultiTexCoord0 _glesMultiTexCoord0
in vec4 _glesMultiTexCoord0;
#define gl_MultiTexCoord1 _glesMultiTexCoord1
in vec4 _glesMultiTexCoord1;

#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 333
struct SurfaceOutput {
    lowp vec3 Albedo;
    lowp vec3 Normal;
    lowp vec3 Emission;
    mediump float Specular;
    lowp float Gloss;
    lowp float Alpha;
};
#line 530
struct v2f {
    highp vec4 pos;
    highp float viewDist;
    highp vec3 viewDir;
    highp vec3 worldPos;
    highp vec4 _LightCoord;
    highp vec4 _ShadowCoord;
    highp vec3 sphereNormal;
};
#line 522
struct appdata_t {
    highp vec4 vertex;
    highp vec3 normal;
    highp vec4 texcoord;
    highp vec4 texcoord2;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform highp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform lowp sampler2DShadow _ShadowMapTexture;
uniform sampler2D _LightTexture0;
#line 323
uniform highp mat4 _LightMatrix0;
uniform sampler2D _LightTextureB0;
#line 343
uniform lowp vec4 _LightColor0;
uniform lowp vec4 _SpecColor;
#line 356
#line 364
#line 378
uniform highp mat4 _MainRotation;
uniform highp mat4 _DetailRotation;
#line 411
#line 415
#line 424
#line 432
#line 441
#line 449
#line 462
#line 474
#line 490
#line 503
uniform lowp vec4 _SurfaceColor;
#line 511
uniform highp float _Shininess;
uniform sampler2D _MainTex;
uniform sampler2D _DetailTex;
uniform highp float _DetailScale;
#line 515
uniform highp float _DetailDist;
uniform highp float _MinLight;
uniform sampler2D _CameraDepthTexture;
uniform highp mat4 _CameraToWorld;
#line 519
uniform highp float _LightPower;
uniform highp float _PlanetOpacity;
uniform highp vec3 _PlanetOrigin;
#line 541
#line 541
v2f vert( in appdata_t v ) {
    v2f o;
    highp vec4 vertex = v.vertex;
    #line 545
    o.pos = (glstate_matrix_mvp * vertex).xyzw;
    highp vec3 vertexPos = (_Object2World * vertex).xyz;
    o.viewDist = distance( vertexPos, _WorldSpaceCameraPos);
    o.worldPos = vertexPos;
    #line 549
    o.sphereNormal = (-normalize(vec4( v.texcoord.x, v.texcoord.y, v.texcoord2.x, v.texcoord2.y)).xyz);
    o.viewDir = normalize((_WorldSpaceCameraPos.xyz - vertexPos));
    o._LightCoord = (_LightMatrix0 * (_Object2World * v.vertex));
    o._ShadowCoord = (unity_World2Shadow[0] * (_Object2World * v.vertex));
    #line 554
    return o;
}
out highp float xlv_TEXCOORD0;
out highp vec3 xlv_TEXCOORD1;
out highp vec3 xlv_TEXCOORD2;
out highp vec4 xlv_TEXCOORD3;
out highp vec4 xlv_TEXCOORD4;
out highp vec3 xlv_TEXCOORD5;
void main() {
    v2f xl_retval;
    appdata_t xlt_v;
    xlt_v.vertex = vec4(gl_Vertex);
    xlt_v.normal = vec3(gl_Normal);
    xlt_v.texcoord = vec4(gl_MultiTexCoord0);
    xlt_v.texcoord2 = vec4(gl_MultiTexCoord1);
    xl_retval = vert( xlt_v);
    gl_Position = vec4(xl_retval.pos);
    xlv_TEXCOORD0 = float(xl_retval.viewDist);
    xlv_TEXCOORD1 = vec3(xl_retval.viewDir);
    xlv_TEXCOORD2 = vec3(xl_retval.worldPos);
    xlv_TEXCOORD3 = vec4(xl_retval._LightCoord);
    xlv_TEXCOORD4 = vec4(xl_retval._ShadowCoord);
    xlv_TEXCOORD5 = vec3(xl_retval.sphereNormal);
}


#endif
#ifdef FRAGMENT

#define gl_FragData _glesFragData
layout(location = 0) out mediump vec4 _glesFragData[4];
float xll_dFdx_f(float f) {
  return dFdx(f);
}
vec2 xll_dFdx_vf2(vec2 v) {
  return dFdx(v);
}
vec3 xll_dFdx_vf3(vec3 v) {
  return dFdx(v);
}
vec4 xll_dFdx_vf4(vec4 v) {
  return dFdx(v);
}
mat2 xll_dFdx_mf2x2(mat2 m) {
  return mat2( dFdx(m[0]), dFdx(m[1]));
}
mat3 xll_dFdx_mf3x3(mat3 m) {
  return mat3( dFdx(m[0]), dFdx(m[1]), dFdx(m[2]));
}
mat4 xll_dFdx_mf4x4(mat4 m) {
  return mat4( dFdx(m[0]), dFdx(m[1]), dFdx(m[2]), dFdx(m[3]));
}
float xll_dFdy_f(float f) {
  return dFdy(f);
}
vec2 xll_dFdy_vf2(vec2 v) {
  return dFdy(v);
}
vec3 xll_dFdy_vf3(vec3 v) {
  return dFdy(v);
}
vec4 xll_dFdy_vf4(vec4 v) {
  return dFdy(v);
}
mat2 xll_dFdy_mf2x2(mat2 m) {
  return mat2( dFdy(m[0]), dFdy(m[1]));
}
mat3 xll_dFdy_mf3x3(mat3 m) {
  return mat3( dFdy(m[0]), dFdy(m[1]), dFdy(m[2]));
}
mat4 xll_dFdy_mf4x4(mat4 m) {
  return mat4( dFdy(m[0]), dFdy(m[1]), dFdy(m[2]), dFdy(m[3]));
}
vec4 xll_tex2Dgrad(sampler2D s, vec2 coord, vec2 ddx, vec2 ddy) {
   return textureGrad( s, coord, ddx, ddy);
}
float xll_shadow2Dproj(mediump sampler2DShadow s, vec4 coord) { return textureProj (s, coord); }
float xll_saturate_f( float x) {
  return clamp( x, 0.0, 1.0);
}
vec2 xll_saturate_vf2( vec2 x) {
  return clamp( x, 0.0, 1.0);
}
vec3 xll_saturate_vf3( vec3 x) {
  return clamp( x, 0.0, 1.0);
}
vec4 xll_saturate_vf4( vec4 x) {
  return clamp( x, 0.0, 1.0);
}
mat2 xll_saturate_mf2x2(mat2 m) {
  return mat2( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0));
}
mat3 xll_saturate_mf3x3(mat3 m) {
  return mat3( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0));
}
mat4 xll_saturate_mf4x4(mat4 m) {
  return mat4( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0), clamp(m[3], 0.0, 1.0));
}
#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 333
struct SurfaceOutput {
    lowp vec3 Albedo;
    lowp vec3 Normal;
    lowp vec3 Emission;
    mediump float Specular;
    lowp float Gloss;
    lowp float Alpha;
};
#line 530
struct v2f {
    highp vec4 pos;
    highp float viewDist;
    highp vec3 viewDir;
    highp vec3 worldPos;
    highp vec4 _LightCoord;
    highp vec4 _ShadowCoord;
    highp vec3 sphereNormal;
};
#line 522
struct appdata_t {
    highp vec4 vertex;
    highp vec3 normal;
    highp vec4 texcoord;
    highp vec4 texcoord2;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform highp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform lowp sampler2DShadow _ShadowMapTexture;
uniform sampler2D _LightTexture0;
#line 323
uniform highp mat4 _LightMatrix0;
uniform sampler2D _LightTextureB0;
#line 343
uniform lowp vec4 _LightColor0;
uniform lowp vec4 _SpecColor;
#line 356
#line 364
#line 378
uniform highp mat4 _MainRotation;
uniform highp mat4 _DetailRotation;
#line 411
#line 415
#line 424
#line 432
#line 441
#line 449
#line 462
#line 474
#line 490
#line 503
uniform lowp vec4 _SurfaceColor;
#line 511
uniform highp float _Shininess;
uniform sampler2D _MainTex;
uniform sampler2D _DetailTex;
uniform highp float _DetailScale;
#line 515
uniform highp float _DetailDist;
uniform highp float _MinLight;
uniform sampler2D _CameraDepthTexture;
uniform highp mat4 _CameraToWorld;
#line 519
uniform highp float _LightPower;
uniform highp float _PlanetOpacity;
uniform highp vec3 _PlanetOrigin;
#line 541
#line 415
highp vec4 Derivatives( in highp float lat, in highp float lon, in highp vec3 pos ) {
    highp vec2 latLong = vec2( lat, lon);
    highp float latDdx = (0.159155 * length(xll_dFdx_vf2(pos.xz)));
    #line 419
    highp float latDdy = (0.159155 * length(xll_dFdy_vf2(pos.xz)));
    highp float longDdx = xll_dFdx_f(lon);
    highp float longDdy = xll_dFdy_f(lon);
    return vec4( latDdx, longDdx, latDdy, longDdy);
}
#line 424
highp vec2 GetSphereUV( in highp vec3 sphereVect, in highp vec2 uvOffset ) {
    highp vec2 uv;
    uv.x = (0.5 + (0.159155 * atan( sphereVect.x, sphereVect.z)));
    #line 428
    uv.y = (0.31831 * acos(sphereVect.y));
    uv += uvOffset;
    return uv;
}
#line 462
mediump vec4 GetShereDetailMap( in sampler2D texSampler, in highp vec3 sphereVect, in highp float detailScale ) {
    highp vec3 sphereVectNorm = normalize(sphereVect);
    highp vec2 uv = ((GetSphereUV( sphereVectNorm, vec2( 0.0, 0.0)) * 4.0) * detailScale);
    #line 466
    highp vec4 uvdd = Derivatives( (uv.x - 0.5), uv.y, sphereVectNorm);
    sphereVectNorm = abs(sphereVectNorm);
    mediump float zxlerp = step( sphereVectNorm.x, sphereVectNorm.z);
    mediump float nylerp = step( sphereVectNorm.y, mix( sphereVectNorm.x, sphereVectNorm.z, zxlerp));
    #line 470
    mediump vec3 detailCoords = mix( sphereVectNorm.xyz, sphereVectNorm.zxy, vec3( zxlerp));
    detailCoords = mix( sphereVectNorm.yxz, detailCoords, vec3( nylerp));
    return xll_tex2Dgrad( texSampler, (((0.5 * detailCoords.zy) / abs(detailCoords.x)) * detailScale), uvdd.xy, uvdd.zw);
}
#line 441
mediump vec4 GetSphereMap( in sampler2D texSampler, in highp vec3 sphereVect ) {
    highp vec3 sphereVectNorm = normalize(sphereVect);
    highp vec2 uv = GetSphereUV( sphereVectNorm, vec2( 0.0, 0.0));
    #line 445
    highp vec4 uvdd = Derivatives( (uv.x - 0.5), uv.y, sphereVectNorm);
    mediump vec4 tex = xll_tex2Dgrad( texSampler, uv, uvdd.xy, uvdd.zw);
    return tex;
}
#line 490
mediump vec4 SpecularColorLight( in mediump vec3 lightDir, in mediump vec3 viewDir, in mediump vec3 normal, in mediump vec4 color, in mediump vec4 specColor, in highp float specK, in mediump float atten ) {
    lightDir = normalize(lightDir);
    viewDir = normalize(viewDir);
    #line 494
    mediump vec3 h = normalize((lightDir + viewDir));
    mediump float diffuse = dot( normal, lightDir);
    highp float nh = xll_saturate_f(dot( h, normal));
    highp float spec = (pow( nh, specK) * color.w);
    #line 498
    mediump vec4 c;
    c.xyz = ((((color.xyz * _LightColor0.xyz) * diffuse) + ((_LightColor0.xyz * specColor.xyz) * spec)) * (atten * 4.0));
    c.w = (diffuse * (atten * 4.0));
    return c;
}
#line 329
lowp float UnitySpotAttenuate( in highp vec3 LightCoord ) {
    #line 331
    return texture( _LightTextureB0, vec2( dot( LightCoord, LightCoord))).w;
}
#line 325
lowp float UnitySpotCookie( in highp vec4 LightCoord ) {
    #line 327
    return texture( _LightTexture0, ((LightCoord.xy / LightCoord.w) + 0.5)).w;
}
#line 316
lowp float unitySampleShadow( in highp vec4 shadowCoord ) {
    mediump float shadow = xll_shadow2Dproj( _ShadowMapTexture, shadowCoord);
    #line 319
    shadow = (_LightShadowData.x + (shadow * (1.0 - _LightShadowData.x)));
    return shadow;
}
#line 556
lowp vec4 frag( in v2f IN ) {
    #line 558
    mediump vec4 color;
    highp vec3 sphereNrm = IN.sphereNormal;
    mediump vec4 main = GetSphereMap( _MainTex, sphereNrm);
    mediump vec4 detail = GetShereDetailMap( _DetailTex, sphereNrm, _DetailScale);
    #line 562
    color = _SurfaceColor;
    mediump float detailLevel = xll_saturate_f(((2.0 * _DetailDist) * IN.viewDist));
    color.xyz += (0.5 * mix( (detail.xyz - 0.5), vec3( 0.0), vec3( detailLevel)));
    mediump float handoff = xll_saturate_f(pow( _PlanetOpacity, 2.0));
    #line 566
    color.xyz = mix( color.xyz, main.xyz, vec3( handoff));
    mediump vec4 specColor = _SpecColor;
    specColor.w = mix( 1.0, main.w, handoff);
    mediump vec4 colorLight = SpecularColorLight( vec3( normalize(_WorldSpaceLightPos0)), IN.viewDir, normalize((IN.worldPos - _PlanetOrigin)), color, specColor, (_Shininess * 128.0), (((float((IN._LightCoord.z > 0.0)) * UnitySpotCookie( IN._LightCoord)) * UnitySpotAttenuate( IN._LightCoord.xyz)) * unitySampleShadow( IN._ShadowCoord)));
    #line 570
    color.w = mix( 1.0, color.w, xll_saturate_f((colorLight.w * 4.0)));
    color.w = mix( color.w, 1.0, xll_saturate_f((length(colorLight.xyz) - length((2.0 * color.xyz)))));
    color.w = mix( color.w, 1.0, handoff);
    color.xyz = colorLight.xyz;
    #line 574
    return color;
}
in highp float xlv_TEXCOORD0;
in highp vec3 xlv_TEXCOORD1;
in highp vec3 xlv_TEXCOORD2;
in highp vec4 xlv_TEXCOORD3;
in highp vec4 xlv_TEXCOORD4;
in highp vec3 xlv_TEXCOORD5;
void main() {
    lowp vec4 xl_retval;
    v2f xlt_IN;
    xlt_IN.pos = vec4(0.0);
    xlt_IN.viewDist = float(xlv_TEXCOORD0);
    xlt_IN.viewDir = vec3(xlv_TEXCOORD1);
    xlt_IN.worldPos = vec3(xlv_TEXCOORD2);
    xlt_IN._LightCoord = vec4(xlv_TEXCOORD3);
    xlt_IN._ShadowCoord = vec4(xlv_TEXCOORD4);
    xlt_IN.sphereNormal = vec3(xlv_TEXCOORD5);
    xl_retval = frag( xlt_IN);
    gl_FragData[0] = vec4(xl_retval);
}


#endif"
}

SubProgram "opengl " {
Keywords { "DIRECTIONAL" "SHADOWS_SCREEN" }
"!!GLSL
#ifdef VERTEX
varying vec3 xlv_TEXCOORD5;
varying vec4 xlv_TEXCOORD3;
varying vec3 xlv_TEXCOORD2;
varying vec3 xlv_TEXCOORD1;
varying float xlv_TEXCOORD0;
uniform mat4 _Object2World;

uniform vec4 _ProjectionParams;
uniform vec3 _WorldSpaceCameraPos;
void main ()
{
  vec4 tmpvar_1;
  tmpvar_1 = (gl_ModelViewProjectionMatrix * gl_Vertex);
  vec3 tmpvar_2;
  tmpvar_2 = (_Object2World * gl_Vertex).xyz;
  vec3 p_3;
  p_3 = (tmpvar_2 - _WorldSpaceCameraPos);
  vec4 tmpvar_4;
  tmpvar_4.x = gl_MultiTexCoord0.x;
  tmpvar_4.y = gl_MultiTexCoord0.y;
  tmpvar_4.z = gl_MultiTexCoord1.x;
  tmpvar_4.w = gl_MultiTexCoord1.y;
  vec4 o_5;
  vec4 tmpvar_6;
  tmpvar_6 = (tmpvar_1 * 0.5);
  vec2 tmpvar_7;
  tmpvar_7.x = tmpvar_6.x;
  tmpvar_7.y = (tmpvar_6.y * _ProjectionParams.x);
  o_5.xy = (tmpvar_7 + tmpvar_6.w);
  o_5.zw = tmpvar_1.zw;
  gl_Position = tmpvar_1;
  xlv_TEXCOORD0 = sqrt(dot (p_3, p_3));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_2));
  xlv_TEXCOORD2 = tmpvar_2;
  xlv_TEXCOORD3 = o_5;
  xlv_TEXCOORD5 = -(normalize(tmpvar_4).xyz);
}


#endif
#ifdef FRAGMENT
#extension GL_ARB_shader_texture_lod : enable
varying vec3 xlv_TEXCOORD5;
varying vec4 xlv_TEXCOORD3;
varying vec3 xlv_TEXCOORD2;
varying vec3 xlv_TEXCOORD1;
varying float xlv_TEXCOORD0;
uniform vec3 _PlanetOrigin;
uniform float _PlanetOpacity;
uniform float _DetailDist;
uniform float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform float _Shininess;
uniform vec4 _SurfaceColor;
uniform vec4 _SpecColor;
uniform vec4 _LightColor0;
uniform sampler2D _ShadowMapTexture;
uniform vec4 _WorldSpaceLightPos0;
void main ()
{
  vec4 main_1;
  vec4 color_2;
  vec3 tmpvar_3;
  tmpvar_3 = normalize(xlv_TEXCOORD5);
  vec2 uv_4;
  float r_5;
  if ((abs(tmpvar_3.z) > (1e-08 * abs(tmpvar_3.x)))) {
    float y_over_x_6;
    y_over_x_6 = (tmpvar_3.x / tmpvar_3.z);
    float s_7;
    float x_8;
    x_8 = (y_over_x_6 * inversesqrt(((y_over_x_6 * y_over_x_6) + 1.0)));
    s_7 = (sign(x_8) * (1.5708 - (sqrt((1.0 - abs(x_8))) * (1.5708 + (abs(x_8) * (-0.214602 + (abs(x_8) * (0.0865667 + (abs(x_8) * -0.0310296)))))))));
    r_5 = s_7;
    if ((tmpvar_3.z < 0.0)) {
      if ((tmpvar_3.x >= 0.0)) {
        r_5 = (s_7 + 3.14159);
      } else {
        r_5 = (r_5 - 3.14159);
      };
    };
  } else {
    r_5 = (sign(tmpvar_3.x) * 1.5708);
  };
  uv_4.x = (0.5 + (0.159155 * r_5));
  uv_4.y = (0.31831 * (1.5708 - (sign(tmpvar_3.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_3.y))) * (1.5708 + (abs(tmpvar_3.y) * (-0.214602 + (abs(tmpvar_3.y) * (0.0865667 + (abs(tmpvar_3.y) * -0.0310296)))))))))));
  vec2 tmpvar_9;
  tmpvar_9 = dFdx(tmpvar_3.xz);
  vec2 tmpvar_10;
  tmpvar_10 = dFdy(tmpvar_3.xz);
  vec4 tmpvar_11;
  tmpvar_11.x = (0.159155 * sqrt(dot (tmpvar_9, tmpvar_9)));
  tmpvar_11.y = dFdx(uv_4.y);
  tmpvar_11.z = (0.159155 * sqrt(dot (tmpvar_10, tmpvar_10)));
  tmpvar_11.w = dFdy(uv_4.y);
  main_1 = texture2DGradARB (_MainTex, uv_4, tmpvar_11.xy, tmpvar_11.zw);
  vec3 tmpvar_12;
  tmpvar_12 = normalize(xlv_TEXCOORD5);
  vec2 uv_13;
  float r_14;
  if ((abs(tmpvar_12.z) > (1e-08 * abs(tmpvar_12.x)))) {
    float y_over_x_15;
    y_over_x_15 = (tmpvar_12.x / tmpvar_12.z);
    float s_16;
    float x_17;
    x_17 = (y_over_x_15 * inversesqrt(((y_over_x_15 * y_over_x_15) + 1.0)));
    s_16 = (sign(x_17) * (1.5708 - (sqrt((1.0 - abs(x_17))) * (1.5708 + (abs(x_17) * (-0.214602 + (abs(x_17) * (0.0865667 + (abs(x_17) * -0.0310296)))))))));
    r_14 = s_16;
    if ((tmpvar_12.z < 0.0)) {
      if ((tmpvar_12.x >= 0.0)) {
        r_14 = (s_16 + 3.14159);
      } else {
        r_14 = (r_14 - 3.14159);
      };
    };
  } else {
    r_14 = (sign(tmpvar_12.x) * 1.5708);
  };
  uv_13.x = (0.5 + (0.159155 * r_14));
  uv_13.y = (0.31831 * (1.5708 - (sign(tmpvar_12.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_12.y))) * (1.5708 + (abs(tmpvar_12.y) * (-0.214602 + (abs(tmpvar_12.y) * (0.0865667 + (abs(tmpvar_12.y) * -0.0310296)))))))))));
  vec2 tmpvar_18;
  tmpvar_18 = ((uv_13 * 4.0) * _DetailScale);
  vec2 tmpvar_19;
  tmpvar_19 = dFdx(tmpvar_12.xz);
  vec2 tmpvar_20;
  tmpvar_20 = dFdy(tmpvar_12.xz);
  vec4 tmpvar_21;
  tmpvar_21.x = (0.159155 * sqrt(dot (tmpvar_19, tmpvar_19)));
  tmpvar_21.y = dFdx(tmpvar_18.y);
  tmpvar_21.z = (0.159155 * sqrt(dot (tmpvar_20, tmpvar_20)));
  tmpvar_21.w = dFdy(tmpvar_18.y);
  vec3 tmpvar_22;
  tmpvar_22 = abs(tmpvar_12);
  float tmpvar_23;
  tmpvar_23 = float((tmpvar_22.z >= tmpvar_22.x));
  vec3 tmpvar_24;
  tmpvar_24 = mix (tmpvar_22.yxz, mix (tmpvar_22, tmpvar_22.zxy, vec3(tmpvar_23)), vec3(float((mix (tmpvar_22.x, tmpvar_22.z, tmpvar_23) >= tmpvar_22.y))));
  color_2.w = _SurfaceColor.w;
  color_2.xyz = (_SurfaceColor.xyz + (0.5 * mix ((texture2DGradARB (_DetailTex, (((0.5 * tmpvar_24.zy) / abs(tmpvar_24.x)) * _DetailScale), tmpvar_21.xy, tmpvar_21.zw).xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0)))));
  float tmpvar_25;
  tmpvar_25 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  color_2.xyz = mix (color_2.xyz, main_1.xyz, vec3(tmpvar_25));
  vec4 tmpvar_26;
  tmpvar_26 = normalize(_WorldSpaceLightPos0);
  vec3 tmpvar_27;
  tmpvar_27 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  vec4 tmpvar_28;
  tmpvar_28 = texture2DProj (_ShadowMapTexture, xlv_TEXCOORD3);
  vec4 c_29;
  float tmpvar_30;
  tmpvar_30 = dot (tmpvar_27, tmpvar_26.xyz);
  c_29.xyz = ((((color_2.xyz * _LightColor0.xyz) * tmpvar_30) + ((_LightColor0.xyz * _SpecColor.xyz) * (pow (clamp (dot (normalize((tmpvar_26.xyz + normalize(xlv_TEXCOORD1))), tmpvar_27), 0.0, 1.0), (_Shininess * 128.0)) * _SurfaceColor.w))) * (tmpvar_28.x * 4.0));
  c_29.w = (tmpvar_30 * (tmpvar_28.x * 4.0));
  color_2.w = mix (1.0, _SurfaceColor.w, clamp ((c_29.w * 4.0), 0.0, 1.0));
  vec3 arg0_31;
  arg0_31 = (2.0 * color_2.xyz);
  color_2.w = mix (color_2.w, 1.0, clamp ((sqrt(dot (c_29.xyz, c_29.xyz)) - sqrt(dot (arg0_31, arg0_31))), 0.0, 1.0));
  color_2.w = mix (color_2.w, 1.0, tmpvar_25);
  color_2.xyz = c_29.xyz;
  gl_FragData[0] = color_2;
}


#endif
"
}

SubProgram "d3d9 " {
Keywords { "DIRECTIONAL" "SHADOWS_SCREEN" }
Bind "vertex" Vertex
Bind "texcoord" TexCoord0
Bind "texcoord1" TexCoord1
Matrix 0 [glstate_matrix_mvp]
Vector 8 [_WorldSpaceCameraPos]
Vector 9 [_ProjectionParams]
Vector 10 [_ScreenParams]
Matrix 4 [_Object2World]
"vs_3_0
; 24 ALU
dcl_position o0
dcl_texcoord0 o1
dcl_texcoord1 o2
dcl_texcoord2 o3
dcl_texcoord3 o4
dcl_texcoord5 o5
def c11, 0.50000000, 0, 0, 0
dcl_position0 v0
dcl_texcoord0 v1
dcl_texcoord1 v2
mov r0.xy, v1
mov r0.zw, v2.xyxy
dp4 r0.w, r0, r0
rsq r0.w, r0.w
mul r3.xyz, r0.w, r0
dp4 r1.w, v0, c3
dp4 r1.z, v0, c2
dp4 r1.x, v0, c0
dp4 r1.y, v0, c1
mul r2.xyz, r1.xyww, c11.x
mul r2.y, r2, c9.x
dp4 r0.z, v0, c6
dp4 r0.x, v0, c4
dp4 r0.y, v0, c5
mad o4.xy, r2.z, c10.zwzw, r2
add r2.xyz, -r0, c8
dp3 r0.w, r2, r2
rsq r0.w, r0.w
mov o5.xyz, -r3
mov o0, r1
mul o2.xyz, r0.w, r2
mov o4.zw, r1
rcp o1.x, r0.w
mov o3.xyz, r0
"
}

SubProgram "gles " {
Keywords { "DIRECTIONAL" "SHADOWS_SCREEN" }
"!!GLES


#ifdef VERTEX

varying highp vec3 xlv_TEXCOORD5;
varying highp vec4 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec3 _WorldSpaceCameraPos;
attribute vec4 _glesMultiTexCoord1;
attribute vec4 _glesMultiTexCoord0;
attribute vec4 _glesVertex;
void main ()
{
  highp vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * _glesVertex).xyz;
  highp vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  highp vec4 tmpvar_3;
  tmpvar_3.x = _glesMultiTexCoord0.x;
  tmpvar_3.y = _glesMultiTexCoord0.y;
  tmpvar_3.z = _glesMultiTexCoord1.x;
  tmpvar_3.w = _glesMultiTexCoord1.y;
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD3 = (unity_World2Shadow[0] * (_Object2World * _glesVertex));
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}



#endif
#ifdef FRAGMENT

#extension GL_EXT_shader_texture_lod : enable
#extension GL_OES_standard_derivatives : enable
varying highp vec3 xlv_TEXCOORD5;
varying highp vec4 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp vec3 _PlanetOrigin;
uniform highp float _PlanetOpacity;
uniform highp float _DetailDist;
uniform highp float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform highp float _Shininess;
uniform lowp vec4 _SurfaceColor;
uniform lowp vec4 _SpecColor;
uniform lowp vec4 _LightColor0;
uniform sampler2D _ShadowMapTexture;
uniform highp vec4 _LightShadowData;
uniform lowp vec4 _WorldSpaceLightPos0;
void main ()
{
  lowp vec4 tmpvar_1;
  mediump vec4 specColor_2;
  mediump float handoff_3;
  mediump float detailLevel_4;
  mediump vec4 color_5;
  mediump vec4 tex_6;
  highp vec3 tmpvar_7;
  tmpvar_7 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_8;
  highp float r_9;
  if ((abs(tmpvar_7.z) > (1e-08 * abs(tmpvar_7.x)))) {
    highp float y_over_x_10;
    y_over_x_10 = (tmpvar_7.x / tmpvar_7.z);
    highp float s_11;
    highp float x_12;
    x_12 = (y_over_x_10 * inversesqrt(((y_over_x_10 * y_over_x_10) + 1.0)));
    s_11 = (sign(x_12) * (1.5708 - (sqrt((1.0 - abs(x_12))) * (1.5708 + (abs(x_12) * (-0.214602 + (abs(x_12) * (0.0865667 + (abs(x_12) * -0.0310296)))))))));
    r_9 = s_11;
    if ((tmpvar_7.z < 0.0)) {
      if ((tmpvar_7.x >= 0.0)) {
        r_9 = (s_11 + 3.14159);
      } else {
        r_9 = (r_9 - 3.14159);
      };
    };
  } else {
    r_9 = (sign(tmpvar_7.x) * 1.5708);
  };
  uv_8.x = (0.5 + (0.159155 * r_9));
  uv_8.y = (0.31831 * (1.5708 - (sign(tmpvar_7.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_7.y))) * (1.5708 + (abs(tmpvar_7.y) * (-0.214602 + (abs(tmpvar_7.y) * (0.0865667 + (abs(tmpvar_7.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_13;
  tmpvar_13 = dFdx(tmpvar_7.xz);
  highp vec2 tmpvar_14;
  tmpvar_14 = dFdy(tmpvar_7.xz);
  highp vec4 tmpvar_15;
  tmpvar_15.x = (0.159155 * sqrt(dot (tmpvar_13, tmpvar_13)));
  tmpvar_15.y = dFdx(uv_8.y);
  tmpvar_15.z = (0.159155 * sqrt(dot (tmpvar_14, tmpvar_14)));
  tmpvar_15.w = dFdy(uv_8.y);
  lowp vec4 tmpvar_16;
  tmpvar_16 = texture2DGradEXT (_MainTex, uv_8, tmpvar_15.xy, tmpvar_15.zw);
  tex_6 = tmpvar_16;
  mediump vec4 tmpvar_17;
  mediump vec3 detailCoords_18;
  mediump float nylerp_19;
  mediump float zxlerp_20;
  highp vec3 tmpvar_21;
  tmpvar_21 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_22;
  highp float r_23;
  if ((abs(tmpvar_21.z) > (1e-08 * abs(tmpvar_21.x)))) {
    highp float y_over_x_24;
    y_over_x_24 = (tmpvar_21.x / tmpvar_21.z);
    highp float s_25;
    highp float x_26;
    x_26 = (y_over_x_24 * inversesqrt(((y_over_x_24 * y_over_x_24) + 1.0)));
    s_25 = (sign(x_26) * (1.5708 - (sqrt((1.0 - abs(x_26))) * (1.5708 + (abs(x_26) * (-0.214602 + (abs(x_26) * (0.0865667 + (abs(x_26) * -0.0310296)))))))));
    r_23 = s_25;
    if ((tmpvar_21.z < 0.0)) {
      if ((tmpvar_21.x >= 0.0)) {
        r_23 = (s_25 + 3.14159);
      } else {
        r_23 = (r_23 - 3.14159);
      };
    };
  } else {
    r_23 = (sign(tmpvar_21.x) * 1.5708);
  };
  uv_22.x = (0.5 + (0.159155 * r_23));
  uv_22.y = (0.31831 * (1.5708 - (sign(tmpvar_21.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_21.y))) * (1.5708 + (abs(tmpvar_21.y) * (-0.214602 + (abs(tmpvar_21.y) * (0.0865667 + (abs(tmpvar_21.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_27;
  tmpvar_27 = ((uv_22 * 4.0) * _DetailScale);
  highp vec2 tmpvar_28;
  tmpvar_28 = dFdx(tmpvar_21.xz);
  highp vec2 tmpvar_29;
  tmpvar_29 = dFdy(tmpvar_21.xz);
  highp vec4 tmpvar_30;
  tmpvar_30.x = (0.159155 * sqrt(dot (tmpvar_28, tmpvar_28)));
  tmpvar_30.y = dFdx(tmpvar_27.y);
  tmpvar_30.z = (0.159155 * sqrt(dot (tmpvar_29, tmpvar_29)));
  tmpvar_30.w = dFdy(tmpvar_27.y);
  highp vec3 tmpvar_31;
  tmpvar_31 = abs(tmpvar_21);
  highp float tmpvar_32;
  tmpvar_32 = float((tmpvar_31.z >= tmpvar_31.x));
  zxlerp_20 = tmpvar_32;
  highp float tmpvar_33;
  tmpvar_33 = float((mix (tmpvar_31.x, tmpvar_31.z, zxlerp_20) >= tmpvar_31.y));
  nylerp_19 = tmpvar_33;
  highp vec3 tmpvar_34;
  tmpvar_34 = mix (tmpvar_31, tmpvar_31.zxy, vec3(zxlerp_20));
  detailCoords_18 = tmpvar_34;
  highp vec3 tmpvar_35;
  tmpvar_35 = mix (tmpvar_31.yxz, detailCoords_18, vec3(nylerp_19));
  detailCoords_18 = tmpvar_35;
  mediump float tmpvar_36;
  tmpvar_36 = abs(detailCoords_18.x);
  highp vec2 coord_37;
  coord_37 = (((0.5 * detailCoords_18.zy) / tmpvar_36) * _DetailScale);
  lowp vec4 tmpvar_38;
  tmpvar_38 = texture2DGradEXT (_DetailTex, coord_37, tmpvar_30.xy, tmpvar_30.zw);
  tmpvar_17 = tmpvar_38;
  color_5 = _SurfaceColor;
  highp float tmpvar_39;
  tmpvar_39 = clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0);
  detailLevel_4 = tmpvar_39;
  color_5.xyz = (color_5.xyz + (0.5 * mix ((tmpvar_17.xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(detailLevel_4))));
  highp float tmpvar_40;
  tmpvar_40 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  handoff_3 = tmpvar_40;
  color_5.xyz = mix (color_5.xyz, tex_6.xyz, vec3(handoff_3));
  specColor_2.xyz = _SpecColor.xyz;
  specColor_2.w = mix (1.0, tex_6.w, handoff_3);
  lowp vec3 tmpvar_41;
  tmpvar_41 = normalize(_WorldSpaceLightPos0).xyz;
  highp vec3 tmpvar_42;
  tmpvar_42 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  lowp float tmpvar_43;
  mediump float lightShadowDataX_44;
  highp float dist_45;
  lowp float tmpvar_46;
  tmpvar_46 = texture2DProj (_ShadowMapTexture, xlv_TEXCOORD3).x;
  dist_45 = tmpvar_46;
  highp float tmpvar_47;
  tmpvar_47 = _LightShadowData.x;
  lightShadowDataX_44 = tmpvar_47;
  highp float tmpvar_48;
  tmpvar_48 = max (float((dist_45 > (xlv_TEXCOORD3.z / xlv_TEXCOORD3.w))), lightShadowDataX_44);
  tmpvar_43 = tmpvar_48;
  mediump vec3 lightDir_49;
  lightDir_49 = tmpvar_41;
  mediump vec3 viewDir_50;
  viewDir_50 = xlv_TEXCOORD1;
  mediump vec3 normal_51;
  normal_51 = tmpvar_42;
  mediump float atten_52;
  atten_52 = tmpvar_43;
  mediump vec4 c_53;
  highp float nh_54;
  mediump vec3 tmpvar_55;
  tmpvar_55 = normalize(viewDir_50);
  viewDir_50 = tmpvar_55;
  mediump float tmpvar_56;
  tmpvar_56 = dot (normal_51, lightDir_49);
  mediump float tmpvar_57;
  tmpvar_57 = clamp (dot (normalize((lightDir_49 + tmpvar_55)), normal_51), 0.0, 1.0);
  nh_54 = tmpvar_57;
  highp vec3 tmpvar_58;
  tmpvar_58 = ((((color_5.xyz * _LightColor0.xyz) * tmpvar_56) + ((_LightColor0.xyz * specColor_2.xyz) * (pow (nh_54, (_Shininess * 128.0)) * color_5.w))) * (atten_52 * 4.0));
  c_53.xyz = tmpvar_58;
  c_53.w = (tmpvar_56 * (atten_52 * 4.0));
  color_5.w = mix (1.0, color_5.w, clamp ((c_53.w * 4.0), 0.0, 1.0));
  mediump vec3 arg0_59;
  arg0_59 = (2.0 * color_5.xyz);
  color_5.w = mix (color_5.w, 1.0, clamp ((sqrt(dot (c_53.xyz, c_53.xyz)) - sqrt(dot (arg0_59, arg0_59))), 0.0, 1.0));
  color_5.w = mix (color_5.w, 1.0, handoff_3);
  color_5.xyz = c_53.xyz;
  tmpvar_1 = color_5;
  gl_FragData[0] = tmpvar_1;
}



#endif"
}

SubProgram "glesdesktop " {
Keywords { "DIRECTIONAL" "SHADOWS_SCREEN" }
"!!GLES


#ifdef VERTEX

varying highp vec3 xlv_TEXCOORD5;
varying highp vec4 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_mvp;
uniform highp vec4 _ProjectionParams;
uniform highp vec3 _WorldSpaceCameraPos;
attribute vec4 _glesMultiTexCoord1;
attribute vec4 _glesMultiTexCoord0;
attribute vec4 _glesVertex;
void main ()
{
  highp vec4 tmpvar_1;
  tmpvar_1 = (glstate_matrix_mvp * _glesVertex);
  highp vec3 tmpvar_2;
  tmpvar_2 = (_Object2World * _glesVertex).xyz;
  highp vec3 p_3;
  p_3 = (tmpvar_2 - _WorldSpaceCameraPos);
  highp vec4 tmpvar_4;
  tmpvar_4.x = _glesMultiTexCoord0.x;
  tmpvar_4.y = _glesMultiTexCoord0.y;
  tmpvar_4.z = _glesMultiTexCoord1.x;
  tmpvar_4.w = _glesMultiTexCoord1.y;
  highp vec4 o_5;
  highp vec4 tmpvar_6;
  tmpvar_6 = (tmpvar_1 * 0.5);
  highp vec2 tmpvar_7;
  tmpvar_7.x = tmpvar_6.x;
  tmpvar_7.y = (tmpvar_6.y * _ProjectionParams.x);
  o_5.xy = (tmpvar_7 + tmpvar_6.w);
  o_5.zw = tmpvar_1.zw;
  gl_Position = tmpvar_1;
  xlv_TEXCOORD0 = sqrt(dot (p_3, p_3));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_2));
  xlv_TEXCOORD2 = tmpvar_2;
  xlv_TEXCOORD3 = o_5;
  xlv_TEXCOORD5 = -(normalize(tmpvar_4).xyz);
}



#endif
#ifdef FRAGMENT

#extension GL_EXT_shader_texture_lod : enable
#extension GL_OES_standard_derivatives : enable
varying highp vec3 xlv_TEXCOORD5;
varying highp vec4 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp vec3 _PlanetOrigin;
uniform highp float _PlanetOpacity;
uniform highp float _DetailDist;
uniform highp float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform highp float _Shininess;
uniform lowp vec4 _SurfaceColor;
uniform lowp vec4 _SpecColor;
uniform lowp vec4 _LightColor0;
uniform sampler2D _ShadowMapTexture;
uniform lowp vec4 _WorldSpaceLightPos0;
void main ()
{
  lowp vec4 tmpvar_1;
  mediump vec4 specColor_2;
  mediump float handoff_3;
  mediump float detailLevel_4;
  mediump vec4 color_5;
  mediump vec4 tex_6;
  highp vec3 tmpvar_7;
  tmpvar_7 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_8;
  highp float r_9;
  if ((abs(tmpvar_7.z) > (1e-08 * abs(tmpvar_7.x)))) {
    highp float y_over_x_10;
    y_over_x_10 = (tmpvar_7.x / tmpvar_7.z);
    highp float s_11;
    highp float x_12;
    x_12 = (y_over_x_10 * inversesqrt(((y_over_x_10 * y_over_x_10) + 1.0)));
    s_11 = (sign(x_12) * (1.5708 - (sqrt((1.0 - abs(x_12))) * (1.5708 + (abs(x_12) * (-0.214602 + (abs(x_12) * (0.0865667 + (abs(x_12) * -0.0310296)))))))));
    r_9 = s_11;
    if ((tmpvar_7.z < 0.0)) {
      if ((tmpvar_7.x >= 0.0)) {
        r_9 = (s_11 + 3.14159);
      } else {
        r_9 = (r_9 - 3.14159);
      };
    };
  } else {
    r_9 = (sign(tmpvar_7.x) * 1.5708);
  };
  uv_8.x = (0.5 + (0.159155 * r_9));
  uv_8.y = (0.31831 * (1.5708 - (sign(tmpvar_7.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_7.y))) * (1.5708 + (abs(tmpvar_7.y) * (-0.214602 + (abs(tmpvar_7.y) * (0.0865667 + (abs(tmpvar_7.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_13;
  tmpvar_13 = dFdx(tmpvar_7.xz);
  highp vec2 tmpvar_14;
  tmpvar_14 = dFdy(tmpvar_7.xz);
  highp vec4 tmpvar_15;
  tmpvar_15.x = (0.159155 * sqrt(dot (tmpvar_13, tmpvar_13)));
  tmpvar_15.y = dFdx(uv_8.y);
  tmpvar_15.z = (0.159155 * sqrt(dot (tmpvar_14, tmpvar_14)));
  tmpvar_15.w = dFdy(uv_8.y);
  lowp vec4 tmpvar_16;
  tmpvar_16 = texture2DGradEXT (_MainTex, uv_8, tmpvar_15.xy, tmpvar_15.zw);
  tex_6 = tmpvar_16;
  mediump vec4 tmpvar_17;
  mediump vec3 detailCoords_18;
  mediump float nylerp_19;
  mediump float zxlerp_20;
  highp vec3 tmpvar_21;
  tmpvar_21 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_22;
  highp float r_23;
  if ((abs(tmpvar_21.z) > (1e-08 * abs(tmpvar_21.x)))) {
    highp float y_over_x_24;
    y_over_x_24 = (tmpvar_21.x / tmpvar_21.z);
    highp float s_25;
    highp float x_26;
    x_26 = (y_over_x_24 * inversesqrt(((y_over_x_24 * y_over_x_24) + 1.0)));
    s_25 = (sign(x_26) * (1.5708 - (sqrt((1.0 - abs(x_26))) * (1.5708 + (abs(x_26) * (-0.214602 + (abs(x_26) * (0.0865667 + (abs(x_26) * -0.0310296)))))))));
    r_23 = s_25;
    if ((tmpvar_21.z < 0.0)) {
      if ((tmpvar_21.x >= 0.0)) {
        r_23 = (s_25 + 3.14159);
      } else {
        r_23 = (r_23 - 3.14159);
      };
    };
  } else {
    r_23 = (sign(tmpvar_21.x) * 1.5708);
  };
  uv_22.x = (0.5 + (0.159155 * r_23));
  uv_22.y = (0.31831 * (1.5708 - (sign(tmpvar_21.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_21.y))) * (1.5708 + (abs(tmpvar_21.y) * (-0.214602 + (abs(tmpvar_21.y) * (0.0865667 + (abs(tmpvar_21.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_27;
  tmpvar_27 = ((uv_22 * 4.0) * _DetailScale);
  highp vec2 tmpvar_28;
  tmpvar_28 = dFdx(tmpvar_21.xz);
  highp vec2 tmpvar_29;
  tmpvar_29 = dFdy(tmpvar_21.xz);
  highp vec4 tmpvar_30;
  tmpvar_30.x = (0.159155 * sqrt(dot (tmpvar_28, tmpvar_28)));
  tmpvar_30.y = dFdx(tmpvar_27.y);
  tmpvar_30.z = (0.159155 * sqrt(dot (tmpvar_29, tmpvar_29)));
  tmpvar_30.w = dFdy(tmpvar_27.y);
  highp vec3 tmpvar_31;
  tmpvar_31 = abs(tmpvar_21);
  highp float tmpvar_32;
  tmpvar_32 = float((tmpvar_31.z >= tmpvar_31.x));
  zxlerp_20 = tmpvar_32;
  highp float tmpvar_33;
  tmpvar_33 = float((mix (tmpvar_31.x, tmpvar_31.z, zxlerp_20) >= tmpvar_31.y));
  nylerp_19 = tmpvar_33;
  highp vec3 tmpvar_34;
  tmpvar_34 = mix (tmpvar_31, tmpvar_31.zxy, vec3(zxlerp_20));
  detailCoords_18 = tmpvar_34;
  highp vec3 tmpvar_35;
  tmpvar_35 = mix (tmpvar_31.yxz, detailCoords_18, vec3(nylerp_19));
  detailCoords_18 = tmpvar_35;
  mediump float tmpvar_36;
  tmpvar_36 = abs(detailCoords_18.x);
  highp vec2 coord_37;
  coord_37 = (((0.5 * detailCoords_18.zy) / tmpvar_36) * _DetailScale);
  lowp vec4 tmpvar_38;
  tmpvar_38 = texture2DGradEXT (_DetailTex, coord_37, tmpvar_30.xy, tmpvar_30.zw);
  tmpvar_17 = tmpvar_38;
  color_5 = _SurfaceColor;
  highp float tmpvar_39;
  tmpvar_39 = clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0);
  detailLevel_4 = tmpvar_39;
  color_5.xyz = (color_5.xyz + (0.5 * mix ((tmpvar_17.xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(detailLevel_4))));
  highp float tmpvar_40;
  tmpvar_40 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  handoff_3 = tmpvar_40;
  color_5.xyz = mix (color_5.xyz, tex_6.xyz, vec3(handoff_3));
  specColor_2.xyz = _SpecColor.xyz;
  specColor_2.w = mix (1.0, tex_6.w, handoff_3);
  lowp vec3 tmpvar_41;
  tmpvar_41 = normalize(_WorldSpaceLightPos0).xyz;
  highp vec3 tmpvar_42;
  tmpvar_42 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  lowp float tmpvar_43;
  tmpvar_43 = texture2DProj (_ShadowMapTexture, xlv_TEXCOORD3).x;
  mediump vec3 lightDir_44;
  lightDir_44 = tmpvar_41;
  mediump vec3 viewDir_45;
  viewDir_45 = xlv_TEXCOORD1;
  mediump vec3 normal_46;
  normal_46 = tmpvar_42;
  mediump float atten_47;
  atten_47 = tmpvar_43;
  mediump vec4 c_48;
  highp float nh_49;
  mediump vec3 tmpvar_50;
  tmpvar_50 = normalize(viewDir_45);
  viewDir_45 = tmpvar_50;
  mediump float tmpvar_51;
  tmpvar_51 = dot (normal_46, lightDir_44);
  mediump float tmpvar_52;
  tmpvar_52 = clamp (dot (normalize((lightDir_44 + tmpvar_50)), normal_46), 0.0, 1.0);
  nh_49 = tmpvar_52;
  highp vec3 tmpvar_53;
  tmpvar_53 = ((((color_5.xyz * _LightColor0.xyz) * tmpvar_51) + ((_LightColor0.xyz * specColor_2.xyz) * (pow (nh_49, (_Shininess * 128.0)) * color_5.w))) * (atten_47 * 4.0));
  c_48.xyz = tmpvar_53;
  c_48.w = (tmpvar_51 * (atten_47 * 4.0));
  color_5.w = mix (1.0, color_5.w, clamp ((c_48.w * 4.0), 0.0, 1.0));
  mediump vec3 arg0_54;
  arg0_54 = (2.0 * color_5.xyz);
  color_5.w = mix (color_5.w, 1.0, clamp ((sqrt(dot (c_48.xyz, c_48.xyz)) - sqrt(dot (arg0_54, arg0_54))), 0.0, 1.0));
  color_5.w = mix (color_5.w, 1.0, handoff_3);
  color_5.xyz = c_48.xyz;
  tmpvar_1 = color_5;
  gl_FragData[0] = tmpvar_1;
}



#endif"
}

SubProgram "gles3 " {
Keywords { "DIRECTIONAL" "SHADOWS_SCREEN" }
"!!GLES3#version 300 es


#ifdef VERTEX

#define gl_Vertex _glesVertex
in vec4 _glesVertex;
#define gl_Normal (normalize(_glesNormal))
in vec3 _glesNormal;
#define gl_MultiTexCoord0 _glesMultiTexCoord0
in vec4 _glesMultiTexCoord0;
#define gl_MultiTexCoord1 _glesMultiTexCoord1
in vec4 _glesMultiTexCoord1;

#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 323
struct SurfaceOutput {
    lowp vec3 Albedo;
    lowp vec3 Normal;
    lowp vec3 Emission;
    mediump float Specular;
    lowp float Gloss;
    lowp float Alpha;
};
#line 519
struct v2f {
    highp vec4 pos;
    highp float viewDist;
    highp vec3 viewDir;
    highp vec3 worldPos;
    highp vec4 _ShadowCoord;
    highp vec3 sphereNormal;
};
#line 511
struct appdata_t {
    highp vec4 vertex;
    highp vec3 normal;
    highp vec4 texcoord;
    highp vec4 texcoord2;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform lowp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform highp vec4 _ShadowOffsets[4];
uniform sampler2D _ShadowMapTexture;
#line 333
uniform lowp vec4 _LightColor0;
uniform lowp vec4 _SpecColor;
#line 346
#line 354
#line 368
uniform highp mat4 _MainRotation;
uniform highp mat4 _DetailRotation;
#line 401
#line 405
#line 414
#line 422
#line 431
#line 439
#line 452
#line 464
#line 480
#line 492
uniform lowp vec4 _SurfaceColor;
#line 500
uniform highp float _Shininess;
uniform sampler2D _MainTex;
uniform sampler2D _DetailTex;
uniform highp float _DetailScale;
#line 504
uniform highp float _DetailDist;
uniform highp float _MinLight;
uniform sampler2D _CameraDepthTexture;
uniform highp mat4 _CameraToWorld;
#line 508
uniform highp float _LightPower;
uniform highp float _PlanetOpacity;
uniform highp vec3 _PlanetOrigin;
#line 529
#line 529
v2f vert( in appdata_t v ) {
    v2f o;
    highp vec4 vertex = v.vertex;
    #line 533
    o.pos = (glstate_matrix_mvp * vertex).xyzw;
    highp vec3 vertexPos = (_Object2World * vertex).xyz;
    o.viewDist = distance( vertexPos, _WorldSpaceCameraPos);
    o.worldPos = vertexPos;
    #line 537
    o.sphereNormal = (-normalize(vec4( v.texcoord.x, v.texcoord.y, v.texcoord2.x, v.texcoord2.y)).xyz);
    o.viewDir = normalize((_WorldSpaceCameraPos.xyz - vertexPos));
    o._ShadowCoord = (unity_World2Shadow[0] * (_Object2World * v.vertex));
    #line 541
    return o;
}
out highp float xlv_TEXCOORD0;
out highp vec3 xlv_TEXCOORD1;
out highp vec3 xlv_TEXCOORD2;
out highp vec4 xlv_TEXCOORD3;
out highp vec3 xlv_TEXCOORD5;
void main() {
    v2f xl_retval;
    appdata_t xlt_v;
    xlt_v.vertex = vec4(gl_Vertex);
    xlt_v.normal = vec3(gl_Normal);
    xlt_v.texcoord = vec4(gl_MultiTexCoord0);
    xlt_v.texcoord2 = vec4(gl_MultiTexCoord1);
    xl_retval = vert( xlt_v);
    gl_Position = vec4(xl_retval.pos);
    xlv_TEXCOORD0 = float(xl_retval.viewDist);
    xlv_TEXCOORD1 = vec3(xl_retval.viewDir);
    xlv_TEXCOORD2 = vec3(xl_retval.worldPos);
    xlv_TEXCOORD3 = vec4(xl_retval._ShadowCoord);
    xlv_TEXCOORD5 = vec3(xl_retval.sphereNormal);
}


#endif
#ifdef FRAGMENT

#define gl_FragData _glesFragData
layout(location = 0) out mediump vec4 _glesFragData[4];
float xll_dFdx_f(float f) {
  return dFdx(f);
}
vec2 xll_dFdx_vf2(vec2 v) {
  return dFdx(v);
}
vec3 xll_dFdx_vf3(vec3 v) {
  return dFdx(v);
}
vec4 xll_dFdx_vf4(vec4 v) {
  return dFdx(v);
}
mat2 xll_dFdx_mf2x2(mat2 m) {
  return mat2( dFdx(m[0]), dFdx(m[1]));
}
mat3 xll_dFdx_mf3x3(mat3 m) {
  return mat3( dFdx(m[0]), dFdx(m[1]), dFdx(m[2]));
}
mat4 xll_dFdx_mf4x4(mat4 m) {
  return mat4( dFdx(m[0]), dFdx(m[1]), dFdx(m[2]), dFdx(m[3]));
}
float xll_dFdy_f(float f) {
  return dFdy(f);
}
vec2 xll_dFdy_vf2(vec2 v) {
  return dFdy(v);
}
vec3 xll_dFdy_vf3(vec3 v) {
  return dFdy(v);
}
vec4 xll_dFdy_vf4(vec4 v) {
  return dFdy(v);
}
mat2 xll_dFdy_mf2x2(mat2 m) {
  return mat2( dFdy(m[0]), dFdy(m[1]));
}
mat3 xll_dFdy_mf3x3(mat3 m) {
  return mat3( dFdy(m[0]), dFdy(m[1]), dFdy(m[2]));
}
mat4 xll_dFdy_mf4x4(mat4 m) {
  return mat4( dFdy(m[0]), dFdy(m[1]), dFdy(m[2]), dFdy(m[3]));
}
vec4 xll_tex2Dgrad(sampler2D s, vec2 coord, vec2 ddx, vec2 ddy) {
   return textureGrad( s, coord, ddx, ddy);
}
float xll_saturate_f( float x) {
  return clamp( x, 0.0, 1.0);
}
vec2 xll_saturate_vf2( vec2 x) {
  return clamp( x, 0.0, 1.0);
}
vec3 xll_saturate_vf3( vec3 x) {
  return clamp( x, 0.0, 1.0);
}
vec4 xll_saturate_vf4( vec4 x) {
  return clamp( x, 0.0, 1.0);
}
mat2 xll_saturate_mf2x2(mat2 m) {
  return mat2( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0));
}
mat3 xll_saturate_mf3x3(mat3 m) {
  return mat3( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0));
}
mat4 xll_saturate_mf4x4(mat4 m) {
  return mat4( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0), clamp(m[3], 0.0, 1.0));
}
#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 323
struct SurfaceOutput {
    lowp vec3 Albedo;
    lowp vec3 Normal;
    lowp vec3 Emission;
    mediump float Specular;
    lowp float Gloss;
    lowp float Alpha;
};
#line 519
struct v2f {
    highp vec4 pos;
    highp float viewDist;
    highp vec3 viewDir;
    highp vec3 worldPos;
    highp vec4 _ShadowCoord;
    highp vec3 sphereNormal;
};
#line 511
struct appdata_t {
    highp vec4 vertex;
    highp vec3 normal;
    highp vec4 texcoord;
    highp vec4 texcoord2;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform lowp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform highp vec4 _ShadowOffsets[4];
uniform sampler2D _ShadowMapTexture;
#line 333
uniform lowp vec4 _LightColor0;
uniform lowp vec4 _SpecColor;
#line 346
#line 354
#line 368
uniform highp mat4 _MainRotation;
uniform highp mat4 _DetailRotation;
#line 401
#line 405
#line 414
#line 422
#line 431
#line 439
#line 452
#line 464
#line 480
#line 492
uniform lowp vec4 _SurfaceColor;
#line 500
uniform highp float _Shininess;
uniform sampler2D _MainTex;
uniform sampler2D _DetailTex;
uniform highp float _DetailScale;
#line 504
uniform highp float _DetailDist;
uniform highp float _MinLight;
uniform sampler2D _CameraDepthTexture;
uniform highp mat4 _CameraToWorld;
#line 508
uniform highp float _LightPower;
uniform highp float _PlanetOpacity;
uniform highp vec3 _PlanetOrigin;
#line 529
#line 405
highp vec4 Derivatives( in highp float lat, in highp float lon, in highp vec3 pos ) {
    highp vec2 latLong = vec2( lat, lon);
    highp float latDdx = (0.159155 * length(xll_dFdx_vf2(pos.xz)));
    #line 409
    highp float latDdy = (0.159155 * length(xll_dFdy_vf2(pos.xz)));
    highp float longDdx = xll_dFdx_f(lon);
    highp float longDdy = xll_dFdy_f(lon);
    return vec4( latDdx, longDdx, latDdy, longDdy);
}
#line 414
highp vec2 GetSphereUV( in highp vec3 sphereVect, in highp vec2 uvOffset ) {
    highp vec2 uv;
    uv.x = (0.5 + (0.159155 * atan( sphereVect.x, sphereVect.z)));
    #line 418
    uv.y = (0.31831 * acos(sphereVect.y));
    uv += uvOffset;
    return uv;
}
#line 452
mediump vec4 GetShereDetailMap( in sampler2D texSampler, in highp vec3 sphereVect, in highp float detailScale ) {
    highp vec3 sphereVectNorm = normalize(sphereVect);
    highp vec2 uv = ((GetSphereUV( sphereVectNorm, vec2( 0.0, 0.0)) * 4.0) * detailScale);
    #line 456
    highp vec4 uvdd = Derivatives( (uv.x - 0.5), uv.y, sphereVectNorm);
    sphereVectNorm = abs(sphereVectNorm);
    mediump float zxlerp = step( sphereVectNorm.x, sphereVectNorm.z);
    mediump float nylerp = step( sphereVectNorm.y, mix( sphereVectNorm.x, sphereVectNorm.z, zxlerp));
    #line 460
    mediump vec3 detailCoords = mix( sphereVectNorm.xyz, sphereVectNorm.zxy, vec3( zxlerp));
    detailCoords = mix( sphereVectNorm.yxz, detailCoords, vec3( nylerp));
    return xll_tex2Dgrad( texSampler, (((0.5 * detailCoords.zy) / abs(detailCoords.x)) * detailScale), uvdd.xy, uvdd.zw);
}
#line 431
mediump vec4 GetSphereMap( in sampler2D texSampler, in highp vec3 sphereVect ) {
    highp vec3 sphereVectNorm = normalize(sphereVect);
    highp vec2 uv = GetSphereUV( sphereVectNorm, vec2( 0.0, 0.0));
    #line 435
    highp vec4 uvdd = Derivatives( (uv.x - 0.5), uv.y, sphereVectNorm);
    mediump vec4 tex = xll_tex2Dgrad( texSampler, uv, uvdd.xy, uvdd.zw);
    return tex;
}
#line 480
mediump vec4 SpecularColorLight( in mediump vec3 lightDir, in mediump vec3 viewDir, in mediump vec3 normal, in mediump vec4 color, in mediump vec4 specColor, in highp float specK, in mediump float atten ) {
    viewDir = normalize(viewDir);
    mediump vec3 h = normalize((lightDir + viewDir));
    #line 484
    mediump float diffuse = dot( normal, lightDir);
    highp float nh = xll_saturate_f(dot( h, normal));
    highp float spec = (pow( nh, specK) * color.w);
    mediump vec4 c;
    #line 488
    c.xyz = ((((color.xyz * _LightColor0.xyz) * diffuse) + ((_LightColor0.xyz * specColor.xyz) * spec)) * (atten * 4.0));
    c.w = (diffuse * (atten * 4.0));
    return c;
}
#line 317
lowp float unitySampleShadow( in highp vec4 shadowCoord ) {
    #line 319
    highp float dist = textureProj( _ShadowMapTexture, shadowCoord).x;
    mediump float lightShadowDataX = _LightShadowData.x;
    return max( float((dist > (shadowCoord.z / shadowCoord.w))), lightShadowDataX);
}
#line 543
lowp vec4 frag( in v2f IN ) {
    #line 545
    mediump vec4 color;
    highp vec3 sphereNrm = IN.sphereNormal;
    mediump vec4 main = GetSphereMap( _MainTex, sphereNrm);
    mediump vec4 detail = GetShereDetailMap( _DetailTex, sphereNrm, _DetailScale);
    #line 549
    color = _SurfaceColor;
    mediump float detailLevel = xll_saturate_f(((2.0 * _DetailDist) * IN.viewDist));
    color.xyz += (0.5 * mix( (detail.xyz - 0.5), vec3( 0.0), vec3( detailLevel)));
    mediump float handoff = xll_saturate_f(pow( _PlanetOpacity, 2.0));
    #line 553
    color.xyz = mix( color.xyz, main.xyz, vec3( handoff));
    mediump vec4 specColor = _SpecColor;
    specColor.w = mix( 1.0, main.w, handoff);
    mediump vec4 colorLight = SpecularColorLight( vec3( normalize(_WorldSpaceLightPos0)), IN.viewDir, normalize((IN.worldPos - _PlanetOrigin)), color, specColor, (_Shininess * 128.0), unitySampleShadow( IN._ShadowCoord));
    #line 557
    color.w = mix( 1.0, color.w, xll_saturate_f((colorLight.w * 4.0)));
    color.w = mix( color.w, 1.0, xll_saturate_f((length(colorLight.xyz) - length((2.0 * color.xyz)))));
    color.w = mix( color.w, 1.0, handoff);
    color.xyz = colorLight.xyz;
    #line 561
    return color;
}
in highp float xlv_TEXCOORD0;
in highp vec3 xlv_TEXCOORD1;
in highp vec3 xlv_TEXCOORD2;
in highp vec4 xlv_TEXCOORD3;
in highp vec3 xlv_TEXCOORD5;
void main() {
    lowp vec4 xl_retval;
    v2f xlt_IN;
    xlt_IN.pos = vec4(0.0);
    xlt_IN.viewDist = float(xlv_TEXCOORD0);
    xlt_IN.viewDir = vec3(xlv_TEXCOORD1);
    xlt_IN.worldPos = vec3(xlv_TEXCOORD2);
    xlt_IN._ShadowCoord = vec4(xlv_TEXCOORD3);
    xlt_IN.sphereNormal = vec3(xlv_TEXCOORD5);
    xl_retval = frag( xlt_IN);
    gl_FragData[0] = vec4(xl_retval);
}


#endif"
}

SubProgram "opengl " {
Keywords { "DIRECTIONAL_COOKIE" "SHADOWS_SCREEN" }
"!!GLSL
#ifdef VERTEX
varying vec3 xlv_TEXCOORD5;
varying vec4 xlv_TEXCOORD4;
varying vec2 xlv_TEXCOORD3;
varying vec3 xlv_TEXCOORD2;
varying vec3 xlv_TEXCOORD1;
varying float xlv_TEXCOORD0;
uniform mat4 _LightMatrix0;
uniform mat4 _Object2World;

uniform vec4 _ProjectionParams;
uniform vec3 _WorldSpaceCameraPos;
void main ()
{
  vec4 tmpvar_1;
  tmpvar_1 = (gl_ModelViewProjectionMatrix * gl_Vertex);
  vec3 tmpvar_2;
  tmpvar_2 = (_Object2World * gl_Vertex).xyz;
  vec3 p_3;
  p_3 = (tmpvar_2 - _WorldSpaceCameraPos);
  vec4 tmpvar_4;
  tmpvar_4.x = gl_MultiTexCoord0.x;
  tmpvar_4.y = gl_MultiTexCoord0.y;
  tmpvar_4.z = gl_MultiTexCoord1.x;
  tmpvar_4.w = gl_MultiTexCoord1.y;
  vec4 o_5;
  vec4 tmpvar_6;
  tmpvar_6 = (tmpvar_1 * 0.5);
  vec2 tmpvar_7;
  tmpvar_7.x = tmpvar_6.x;
  tmpvar_7.y = (tmpvar_6.y * _ProjectionParams.x);
  o_5.xy = (tmpvar_7 + tmpvar_6.w);
  o_5.zw = tmpvar_1.zw;
  gl_Position = tmpvar_1;
  xlv_TEXCOORD0 = sqrt(dot (p_3, p_3));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_2));
  xlv_TEXCOORD2 = tmpvar_2;
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * gl_Vertex)).xy;
  xlv_TEXCOORD4 = o_5;
  xlv_TEXCOORD5 = -(normalize(tmpvar_4).xyz);
}


#endif
#ifdef FRAGMENT
#extension GL_ARB_shader_texture_lod : enable
varying vec3 xlv_TEXCOORD5;
varying vec4 xlv_TEXCOORD4;
varying vec2 xlv_TEXCOORD3;
varying vec3 xlv_TEXCOORD2;
varying vec3 xlv_TEXCOORD1;
varying float xlv_TEXCOORD0;
uniform vec3 _PlanetOrigin;
uniform float _PlanetOpacity;
uniform float _DetailDist;
uniform float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform float _Shininess;
uniform vec4 _SurfaceColor;
uniform vec4 _SpecColor;
uniform vec4 _LightColor0;
uniform sampler2D _LightTexture0;
uniform sampler2D _ShadowMapTexture;
uniform vec4 _WorldSpaceLightPos0;
void main ()
{
  vec4 main_1;
  vec4 color_2;
  vec3 tmpvar_3;
  tmpvar_3 = normalize(xlv_TEXCOORD5);
  vec2 uv_4;
  float r_5;
  if ((abs(tmpvar_3.z) > (1e-08 * abs(tmpvar_3.x)))) {
    float y_over_x_6;
    y_over_x_6 = (tmpvar_3.x / tmpvar_3.z);
    float s_7;
    float x_8;
    x_8 = (y_over_x_6 * inversesqrt(((y_over_x_6 * y_over_x_6) + 1.0)));
    s_7 = (sign(x_8) * (1.5708 - (sqrt((1.0 - abs(x_8))) * (1.5708 + (abs(x_8) * (-0.214602 + (abs(x_8) * (0.0865667 + (abs(x_8) * -0.0310296)))))))));
    r_5 = s_7;
    if ((tmpvar_3.z < 0.0)) {
      if ((tmpvar_3.x >= 0.0)) {
        r_5 = (s_7 + 3.14159);
      } else {
        r_5 = (r_5 - 3.14159);
      };
    };
  } else {
    r_5 = (sign(tmpvar_3.x) * 1.5708);
  };
  uv_4.x = (0.5 + (0.159155 * r_5));
  uv_4.y = (0.31831 * (1.5708 - (sign(tmpvar_3.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_3.y))) * (1.5708 + (abs(tmpvar_3.y) * (-0.214602 + (abs(tmpvar_3.y) * (0.0865667 + (abs(tmpvar_3.y) * -0.0310296)))))))))));
  vec2 tmpvar_9;
  tmpvar_9 = dFdx(tmpvar_3.xz);
  vec2 tmpvar_10;
  tmpvar_10 = dFdy(tmpvar_3.xz);
  vec4 tmpvar_11;
  tmpvar_11.x = (0.159155 * sqrt(dot (tmpvar_9, tmpvar_9)));
  tmpvar_11.y = dFdx(uv_4.y);
  tmpvar_11.z = (0.159155 * sqrt(dot (tmpvar_10, tmpvar_10)));
  tmpvar_11.w = dFdy(uv_4.y);
  main_1 = texture2DGradARB (_MainTex, uv_4, tmpvar_11.xy, tmpvar_11.zw);
  vec3 tmpvar_12;
  tmpvar_12 = normalize(xlv_TEXCOORD5);
  vec2 uv_13;
  float r_14;
  if ((abs(tmpvar_12.z) > (1e-08 * abs(tmpvar_12.x)))) {
    float y_over_x_15;
    y_over_x_15 = (tmpvar_12.x / tmpvar_12.z);
    float s_16;
    float x_17;
    x_17 = (y_over_x_15 * inversesqrt(((y_over_x_15 * y_over_x_15) + 1.0)));
    s_16 = (sign(x_17) * (1.5708 - (sqrt((1.0 - abs(x_17))) * (1.5708 + (abs(x_17) * (-0.214602 + (abs(x_17) * (0.0865667 + (abs(x_17) * -0.0310296)))))))));
    r_14 = s_16;
    if ((tmpvar_12.z < 0.0)) {
      if ((tmpvar_12.x >= 0.0)) {
        r_14 = (s_16 + 3.14159);
      } else {
        r_14 = (r_14 - 3.14159);
      };
    };
  } else {
    r_14 = (sign(tmpvar_12.x) * 1.5708);
  };
  uv_13.x = (0.5 + (0.159155 * r_14));
  uv_13.y = (0.31831 * (1.5708 - (sign(tmpvar_12.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_12.y))) * (1.5708 + (abs(tmpvar_12.y) * (-0.214602 + (abs(tmpvar_12.y) * (0.0865667 + (abs(tmpvar_12.y) * -0.0310296)))))))))));
  vec2 tmpvar_18;
  tmpvar_18 = ((uv_13 * 4.0) * _DetailScale);
  vec2 tmpvar_19;
  tmpvar_19 = dFdx(tmpvar_12.xz);
  vec2 tmpvar_20;
  tmpvar_20 = dFdy(tmpvar_12.xz);
  vec4 tmpvar_21;
  tmpvar_21.x = (0.159155 * sqrt(dot (tmpvar_19, tmpvar_19)));
  tmpvar_21.y = dFdx(tmpvar_18.y);
  tmpvar_21.z = (0.159155 * sqrt(dot (tmpvar_20, tmpvar_20)));
  tmpvar_21.w = dFdy(tmpvar_18.y);
  vec3 tmpvar_22;
  tmpvar_22 = abs(tmpvar_12);
  float tmpvar_23;
  tmpvar_23 = float((tmpvar_22.z >= tmpvar_22.x));
  vec3 tmpvar_24;
  tmpvar_24 = mix (tmpvar_22.yxz, mix (tmpvar_22, tmpvar_22.zxy, vec3(tmpvar_23)), vec3(float((mix (tmpvar_22.x, tmpvar_22.z, tmpvar_23) >= tmpvar_22.y))));
  color_2.w = _SurfaceColor.w;
  color_2.xyz = (_SurfaceColor.xyz + (0.5 * mix ((texture2DGradARB (_DetailTex, (((0.5 * tmpvar_24.zy) / abs(tmpvar_24.x)) * _DetailScale), tmpvar_21.xy, tmpvar_21.zw).xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0)))));
  float tmpvar_25;
  tmpvar_25 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  color_2.xyz = mix (color_2.xyz, main_1.xyz, vec3(tmpvar_25));
  vec4 tmpvar_26;
  tmpvar_26 = normalize(_WorldSpaceLightPos0);
  vec3 tmpvar_27;
  tmpvar_27 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  float atten_28;
  atten_28 = (texture2D (_LightTexture0, xlv_TEXCOORD3).w * texture2DProj (_ShadowMapTexture, xlv_TEXCOORD4).x);
  vec4 c_29;
  float tmpvar_30;
  tmpvar_30 = dot (tmpvar_27, tmpvar_26.xyz);
  c_29.xyz = ((((color_2.xyz * _LightColor0.xyz) * tmpvar_30) + ((_LightColor0.xyz * _SpecColor.xyz) * (pow (clamp (dot (normalize((tmpvar_26.xyz + normalize(xlv_TEXCOORD1))), tmpvar_27), 0.0, 1.0), (_Shininess * 128.0)) * _SurfaceColor.w))) * (atten_28 * 4.0));
  c_29.w = (tmpvar_30 * (atten_28 * 4.0));
  color_2.w = mix (1.0, _SurfaceColor.w, clamp ((c_29.w * 4.0), 0.0, 1.0));
  vec3 arg0_31;
  arg0_31 = (2.0 * color_2.xyz);
  color_2.w = mix (color_2.w, 1.0, clamp ((sqrt(dot (c_29.xyz, c_29.xyz)) - sqrt(dot (arg0_31, arg0_31))), 0.0, 1.0));
  color_2.w = mix (color_2.w, 1.0, tmpvar_25);
  color_2.xyz = c_29.xyz;
  gl_FragData[0] = color_2;
}


#endif
"
}

SubProgram "d3d9 " {
Keywords { "DIRECTIONAL_COOKIE" "SHADOWS_SCREEN" }
Bind "vertex" Vertex
Bind "texcoord" TexCoord0
Bind "texcoord1" TexCoord1
Matrix 0 [glstate_matrix_mvp]
Vector 12 [_WorldSpaceCameraPos]
Vector 13 [_ProjectionParams]
Vector 14 [_ScreenParams]
Matrix 4 [_Object2World]
Matrix 8 [_LightMatrix0]
"vs_3_0
; 28 ALU
dcl_position o0
dcl_texcoord0 o1
dcl_texcoord1 o2
dcl_texcoord2 o3
dcl_texcoord3 o4
dcl_texcoord4 o5
dcl_texcoord5 o6
def c15, 0.50000000, 0, 0, 0
dcl_position0 v0
dcl_texcoord0 v1
dcl_texcoord1 v2
mov r0.xy, v1
mov r0.zw, v2.xyxy
dp4 r0.w, r0, r0
rsq r0.w, r0.w
mul r3.xyz, r0.w, r0
dp4 r1.w, v0, c3
dp4 r1.z, v0, c2
dp4 r0.z, v0, c6
dp4 r0.x, v0, c4
dp4 r0.y, v0, c5
dp4 r1.x, v0, c0
dp4 r1.y, v0, c1
mul r2.xyz, r1.xyww, c15.x
mul r2.y, r2, c13.x
mad o5.xy, r2.z, c14.zwzw, r2
add r2.xyz, -r0, c12
dp3 r0.w, r2, r2
rsq r0.w, r0.w
mul o2.xyz, r0.w, r2
mov r2.xyz, r0
dp4 r2.w, v0, c7
mov o6.xyz, -r3
mov o0, r1
dp4 o4.y, r2, c9
dp4 o4.x, r2, c8
mov o5.zw, r1
rcp o1.x, r0.w
mov o3.xyz, r0
"
}

SubProgram "gles " {
Keywords { "DIRECTIONAL_COOKIE" "SHADOWS_SCREEN" }
"!!GLES


#ifdef VERTEX

varying highp vec3 xlv_TEXCOORD5;
varying highp vec4 xlv_TEXCOORD4;
varying highp vec2 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp mat4 _LightMatrix0;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec3 _WorldSpaceCameraPos;
attribute vec4 _glesMultiTexCoord1;
attribute vec4 _glesMultiTexCoord0;
attribute vec4 _glesVertex;
void main ()
{
  highp vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * _glesVertex).xyz;
  highp vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  highp vec4 tmpvar_3;
  tmpvar_3.x = _glesMultiTexCoord0.x;
  tmpvar_3.y = _glesMultiTexCoord0.y;
  tmpvar_3.z = _glesMultiTexCoord1.x;
  tmpvar_3.w = _glesMultiTexCoord1.y;
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * _glesVertex)).xy;
  xlv_TEXCOORD4 = (unity_World2Shadow[0] * (_Object2World * _glesVertex));
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}



#endif
#ifdef FRAGMENT

#extension GL_EXT_shader_texture_lod : enable
#extension GL_OES_standard_derivatives : enable
varying highp vec3 xlv_TEXCOORD5;
varying highp vec4 xlv_TEXCOORD4;
varying highp vec2 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp vec3 _PlanetOrigin;
uniform highp float _PlanetOpacity;
uniform highp float _DetailDist;
uniform highp float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform highp float _Shininess;
uniform lowp vec4 _SurfaceColor;
uniform lowp vec4 _SpecColor;
uniform lowp vec4 _LightColor0;
uniform sampler2D _LightTexture0;
uniform sampler2D _ShadowMapTexture;
uniform highp vec4 _LightShadowData;
uniform lowp vec4 _WorldSpaceLightPos0;
void main ()
{
  lowp vec4 tmpvar_1;
  mediump vec4 specColor_2;
  mediump float handoff_3;
  mediump float detailLevel_4;
  mediump vec4 color_5;
  mediump vec4 tex_6;
  highp vec3 tmpvar_7;
  tmpvar_7 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_8;
  highp float r_9;
  if ((abs(tmpvar_7.z) > (1e-08 * abs(tmpvar_7.x)))) {
    highp float y_over_x_10;
    y_over_x_10 = (tmpvar_7.x / tmpvar_7.z);
    highp float s_11;
    highp float x_12;
    x_12 = (y_over_x_10 * inversesqrt(((y_over_x_10 * y_over_x_10) + 1.0)));
    s_11 = (sign(x_12) * (1.5708 - (sqrt((1.0 - abs(x_12))) * (1.5708 + (abs(x_12) * (-0.214602 + (abs(x_12) * (0.0865667 + (abs(x_12) * -0.0310296)))))))));
    r_9 = s_11;
    if ((tmpvar_7.z < 0.0)) {
      if ((tmpvar_7.x >= 0.0)) {
        r_9 = (s_11 + 3.14159);
      } else {
        r_9 = (r_9 - 3.14159);
      };
    };
  } else {
    r_9 = (sign(tmpvar_7.x) * 1.5708);
  };
  uv_8.x = (0.5 + (0.159155 * r_9));
  uv_8.y = (0.31831 * (1.5708 - (sign(tmpvar_7.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_7.y))) * (1.5708 + (abs(tmpvar_7.y) * (-0.214602 + (abs(tmpvar_7.y) * (0.0865667 + (abs(tmpvar_7.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_13;
  tmpvar_13 = dFdx(tmpvar_7.xz);
  highp vec2 tmpvar_14;
  tmpvar_14 = dFdy(tmpvar_7.xz);
  highp vec4 tmpvar_15;
  tmpvar_15.x = (0.159155 * sqrt(dot (tmpvar_13, tmpvar_13)));
  tmpvar_15.y = dFdx(uv_8.y);
  tmpvar_15.z = (0.159155 * sqrt(dot (tmpvar_14, tmpvar_14)));
  tmpvar_15.w = dFdy(uv_8.y);
  lowp vec4 tmpvar_16;
  tmpvar_16 = texture2DGradEXT (_MainTex, uv_8, tmpvar_15.xy, tmpvar_15.zw);
  tex_6 = tmpvar_16;
  mediump vec4 tmpvar_17;
  mediump vec3 detailCoords_18;
  mediump float nylerp_19;
  mediump float zxlerp_20;
  highp vec3 tmpvar_21;
  tmpvar_21 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_22;
  highp float r_23;
  if ((abs(tmpvar_21.z) > (1e-08 * abs(tmpvar_21.x)))) {
    highp float y_over_x_24;
    y_over_x_24 = (tmpvar_21.x / tmpvar_21.z);
    highp float s_25;
    highp float x_26;
    x_26 = (y_over_x_24 * inversesqrt(((y_over_x_24 * y_over_x_24) + 1.0)));
    s_25 = (sign(x_26) * (1.5708 - (sqrt((1.0 - abs(x_26))) * (1.5708 + (abs(x_26) * (-0.214602 + (abs(x_26) * (0.0865667 + (abs(x_26) * -0.0310296)))))))));
    r_23 = s_25;
    if ((tmpvar_21.z < 0.0)) {
      if ((tmpvar_21.x >= 0.0)) {
        r_23 = (s_25 + 3.14159);
      } else {
        r_23 = (r_23 - 3.14159);
      };
    };
  } else {
    r_23 = (sign(tmpvar_21.x) * 1.5708);
  };
  uv_22.x = (0.5 + (0.159155 * r_23));
  uv_22.y = (0.31831 * (1.5708 - (sign(tmpvar_21.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_21.y))) * (1.5708 + (abs(tmpvar_21.y) * (-0.214602 + (abs(tmpvar_21.y) * (0.0865667 + (abs(tmpvar_21.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_27;
  tmpvar_27 = ((uv_22 * 4.0) * _DetailScale);
  highp vec2 tmpvar_28;
  tmpvar_28 = dFdx(tmpvar_21.xz);
  highp vec2 tmpvar_29;
  tmpvar_29 = dFdy(tmpvar_21.xz);
  highp vec4 tmpvar_30;
  tmpvar_30.x = (0.159155 * sqrt(dot (tmpvar_28, tmpvar_28)));
  tmpvar_30.y = dFdx(tmpvar_27.y);
  tmpvar_30.z = (0.159155 * sqrt(dot (tmpvar_29, tmpvar_29)));
  tmpvar_30.w = dFdy(tmpvar_27.y);
  highp vec3 tmpvar_31;
  tmpvar_31 = abs(tmpvar_21);
  highp float tmpvar_32;
  tmpvar_32 = float((tmpvar_31.z >= tmpvar_31.x));
  zxlerp_20 = tmpvar_32;
  highp float tmpvar_33;
  tmpvar_33 = float((mix (tmpvar_31.x, tmpvar_31.z, zxlerp_20) >= tmpvar_31.y));
  nylerp_19 = tmpvar_33;
  highp vec3 tmpvar_34;
  tmpvar_34 = mix (tmpvar_31, tmpvar_31.zxy, vec3(zxlerp_20));
  detailCoords_18 = tmpvar_34;
  highp vec3 tmpvar_35;
  tmpvar_35 = mix (tmpvar_31.yxz, detailCoords_18, vec3(nylerp_19));
  detailCoords_18 = tmpvar_35;
  mediump float tmpvar_36;
  tmpvar_36 = abs(detailCoords_18.x);
  highp vec2 coord_37;
  coord_37 = (((0.5 * detailCoords_18.zy) / tmpvar_36) * _DetailScale);
  lowp vec4 tmpvar_38;
  tmpvar_38 = texture2DGradEXT (_DetailTex, coord_37, tmpvar_30.xy, tmpvar_30.zw);
  tmpvar_17 = tmpvar_38;
  color_5 = _SurfaceColor;
  highp float tmpvar_39;
  tmpvar_39 = clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0);
  detailLevel_4 = tmpvar_39;
  color_5.xyz = (color_5.xyz + (0.5 * mix ((tmpvar_17.xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(detailLevel_4))));
  highp float tmpvar_40;
  tmpvar_40 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  handoff_3 = tmpvar_40;
  color_5.xyz = mix (color_5.xyz, tex_6.xyz, vec3(handoff_3));
  specColor_2.xyz = _SpecColor.xyz;
  specColor_2.w = mix (1.0, tex_6.w, handoff_3);
  lowp vec3 tmpvar_41;
  tmpvar_41 = normalize(_WorldSpaceLightPos0).xyz;
  highp vec3 tmpvar_42;
  tmpvar_42 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  lowp vec4 tmpvar_43;
  tmpvar_43 = texture2D (_LightTexture0, xlv_TEXCOORD3);
  lowp float tmpvar_44;
  mediump float lightShadowDataX_45;
  highp float dist_46;
  lowp float tmpvar_47;
  tmpvar_47 = texture2DProj (_ShadowMapTexture, xlv_TEXCOORD4).x;
  dist_46 = tmpvar_47;
  highp float tmpvar_48;
  tmpvar_48 = _LightShadowData.x;
  lightShadowDataX_45 = tmpvar_48;
  highp float tmpvar_49;
  tmpvar_49 = max (float((dist_46 > (xlv_TEXCOORD4.z / xlv_TEXCOORD4.w))), lightShadowDataX_45);
  tmpvar_44 = tmpvar_49;
  mediump vec3 lightDir_50;
  lightDir_50 = tmpvar_41;
  mediump vec3 viewDir_51;
  viewDir_51 = xlv_TEXCOORD1;
  mediump vec3 normal_52;
  normal_52 = tmpvar_42;
  mediump float atten_53;
  atten_53 = (tmpvar_43.w * tmpvar_44);
  mediump vec4 c_54;
  highp float nh_55;
  mediump vec3 tmpvar_56;
  tmpvar_56 = normalize(viewDir_51);
  viewDir_51 = tmpvar_56;
  mediump float tmpvar_57;
  tmpvar_57 = dot (normal_52, lightDir_50);
  mediump float tmpvar_58;
  tmpvar_58 = clamp (dot (normalize((lightDir_50 + tmpvar_56)), normal_52), 0.0, 1.0);
  nh_55 = tmpvar_58;
  highp vec3 tmpvar_59;
  tmpvar_59 = ((((color_5.xyz * _LightColor0.xyz) * tmpvar_57) + ((_LightColor0.xyz * specColor_2.xyz) * (pow (nh_55, (_Shininess * 128.0)) * color_5.w))) * (atten_53 * 4.0));
  c_54.xyz = tmpvar_59;
  c_54.w = (tmpvar_57 * (atten_53 * 4.0));
  color_5.w = mix (1.0, color_5.w, clamp ((c_54.w * 4.0), 0.0, 1.0));
  mediump vec3 arg0_60;
  arg0_60 = (2.0 * color_5.xyz);
  color_5.w = mix (color_5.w, 1.0, clamp ((sqrt(dot (c_54.xyz, c_54.xyz)) - sqrt(dot (arg0_60, arg0_60))), 0.0, 1.0));
  color_5.w = mix (color_5.w, 1.0, handoff_3);
  color_5.xyz = c_54.xyz;
  tmpvar_1 = color_5;
  gl_FragData[0] = tmpvar_1;
}



#endif"
}

SubProgram "glesdesktop " {
Keywords { "DIRECTIONAL_COOKIE" "SHADOWS_SCREEN" }
"!!GLES


#ifdef VERTEX

varying highp vec3 xlv_TEXCOORD5;
varying highp vec4 xlv_TEXCOORD4;
varying highp vec2 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp mat4 _LightMatrix0;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_mvp;
uniform highp vec4 _ProjectionParams;
uniform highp vec3 _WorldSpaceCameraPos;
attribute vec4 _glesMultiTexCoord1;
attribute vec4 _glesMultiTexCoord0;
attribute vec4 _glesVertex;
void main ()
{
  highp vec4 tmpvar_1;
  tmpvar_1 = (glstate_matrix_mvp * _glesVertex);
  highp vec3 tmpvar_2;
  tmpvar_2 = (_Object2World * _glesVertex).xyz;
  highp vec3 p_3;
  p_3 = (tmpvar_2 - _WorldSpaceCameraPos);
  highp vec4 tmpvar_4;
  tmpvar_4.x = _glesMultiTexCoord0.x;
  tmpvar_4.y = _glesMultiTexCoord0.y;
  tmpvar_4.z = _glesMultiTexCoord1.x;
  tmpvar_4.w = _glesMultiTexCoord1.y;
  highp vec4 o_5;
  highp vec4 tmpvar_6;
  tmpvar_6 = (tmpvar_1 * 0.5);
  highp vec2 tmpvar_7;
  tmpvar_7.x = tmpvar_6.x;
  tmpvar_7.y = (tmpvar_6.y * _ProjectionParams.x);
  o_5.xy = (tmpvar_7 + tmpvar_6.w);
  o_5.zw = tmpvar_1.zw;
  gl_Position = tmpvar_1;
  xlv_TEXCOORD0 = sqrt(dot (p_3, p_3));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_2));
  xlv_TEXCOORD2 = tmpvar_2;
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * _glesVertex)).xy;
  xlv_TEXCOORD4 = o_5;
  xlv_TEXCOORD5 = -(normalize(tmpvar_4).xyz);
}



#endif
#ifdef FRAGMENT

#extension GL_EXT_shader_texture_lod : enable
#extension GL_OES_standard_derivatives : enable
varying highp vec3 xlv_TEXCOORD5;
varying highp vec4 xlv_TEXCOORD4;
varying highp vec2 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp vec3 _PlanetOrigin;
uniform highp float _PlanetOpacity;
uniform highp float _DetailDist;
uniform highp float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform highp float _Shininess;
uniform lowp vec4 _SurfaceColor;
uniform lowp vec4 _SpecColor;
uniform lowp vec4 _LightColor0;
uniform sampler2D _LightTexture0;
uniform sampler2D _ShadowMapTexture;
uniform lowp vec4 _WorldSpaceLightPos0;
void main ()
{
  lowp vec4 tmpvar_1;
  mediump vec4 specColor_2;
  mediump float handoff_3;
  mediump float detailLevel_4;
  mediump vec4 color_5;
  mediump vec4 tex_6;
  highp vec3 tmpvar_7;
  tmpvar_7 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_8;
  highp float r_9;
  if ((abs(tmpvar_7.z) > (1e-08 * abs(tmpvar_7.x)))) {
    highp float y_over_x_10;
    y_over_x_10 = (tmpvar_7.x / tmpvar_7.z);
    highp float s_11;
    highp float x_12;
    x_12 = (y_over_x_10 * inversesqrt(((y_over_x_10 * y_over_x_10) + 1.0)));
    s_11 = (sign(x_12) * (1.5708 - (sqrt((1.0 - abs(x_12))) * (1.5708 + (abs(x_12) * (-0.214602 + (abs(x_12) * (0.0865667 + (abs(x_12) * -0.0310296)))))))));
    r_9 = s_11;
    if ((tmpvar_7.z < 0.0)) {
      if ((tmpvar_7.x >= 0.0)) {
        r_9 = (s_11 + 3.14159);
      } else {
        r_9 = (r_9 - 3.14159);
      };
    };
  } else {
    r_9 = (sign(tmpvar_7.x) * 1.5708);
  };
  uv_8.x = (0.5 + (0.159155 * r_9));
  uv_8.y = (0.31831 * (1.5708 - (sign(tmpvar_7.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_7.y))) * (1.5708 + (abs(tmpvar_7.y) * (-0.214602 + (abs(tmpvar_7.y) * (0.0865667 + (abs(tmpvar_7.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_13;
  tmpvar_13 = dFdx(tmpvar_7.xz);
  highp vec2 tmpvar_14;
  tmpvar_14 = dFdy(tmpvar_7.xz);
  highp vec4 tmpvar_15;
  tmpvar_15.x = (0.159155 * sqrt(dot (tmpvar_13, tmpvar_13)));
  tmpvar_15.y = dFdx(uv_8.y);
  tmpvar_15.z = (0.159155 * sqrt(dot (tmpvar_14, tmpvar_14)));
  tmpvar_15.w = dFdy(uv_8.y);
  lowp vec4 tmpvar_16;
  tmpvar_16 = texture2DGradEXT (_MainTex, uv_8, tmpvar_15.xy, tmpvar_15.zw);
  tex_6 = tmpvar_16;
  mediump vec4 tmpvar_17;
  mediump vec3 detailCoords_18;
  mediump float nylerp_19;
  mediump float zxlerp_20;
  highp vec3 tmpvar_21;
  tmpvar_21 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_22;
  highp float r_23;
  if ((abs(tmpvar_21.z) > (1e-08 * abs(tmpvar_21.x)))) {
    highp float y_over_x_24;
    y_over_x_24 = (tmpvar_21.x / tmpvar_21.z);
    highp float s_25;
    highp float x_26;
    x_26 = (y_over_x_24 * inversesqrt(((y_over_x_24 * y_over_x_24) + 1.0)));
    s_25 = (sign(x_26) * (1.5708 - (sqrt((1.0 - abs(x_26))) * (1.5708 + (abs(x_26) * (-0.214602 + (abs(x_26) * (0.0865667 + (abs(x_26) * -0.0310296)))))))));
    r_23 = s_25;
    if ((tmpvar_21.z < 0.0)) {
      if ((tmpvar_21.x >= 0.0)) {
        r_23 = (s_25 + 3.14159);
      } else {
        r_23 = (r_23 - 3.14159);
      };
    };
  } else {
    r_23 = (sign(tmpvar_21.x) * 1.5708);
  };
  uv_22.x = (0.5 + (0.159155 * r_23));
  uv_22.y = (0.31831 * (1.5708 - (sign(tmpvar_21.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_21.y))) * (1.5708 + (abs(tmpvar_21.y) * (-0.214602 + (abs(tmpvar_21.y) * (0.0865667 + (abs(tmpvar_21.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_27;
  tmpvar_27 = ((uv_22 * 4.0) * _DetailScale);
  highp vec2 tmpvar_28;
  tmpvar_28 = dFdx(tmpvar_21.xz);
  highp vec2 tmpvar_29;
  tmpvar_29 = dFdy(tmpvar_21.xz);
  highp vec4 tmpvar_30;
  tmpvar_30.x = (0.159155 * sqrt(dot (tmpvar_28, tmpvar_28)));
  tmpvar_30.y = dFdx(tmpvar_27.y);
  tmpvar_30.z = (0.159155 * sqrt(dot (tmpvar_29, tmpvar_29)));
  tmpvar_30.w = dFdy(tmpvar_27.y);
  highp vec3 tmpvar_31;
  tmpvar_31 = abs(tmpvar_21);
  highp float tmpvar_32;
  tmpvar_32 = float((tmpvar_31.z >= tmpvar_31.x));
  zxlerp_20 = tmpvar_32;
  highp float tmpvar_33;
  tmpvar_33 = float((mix (tmpvar_31.x, tmpvar_31.z, zxlerp_20) >= tmpvar_31.y));
  nylerp_19 = tmpvar_33;
  highp vec3 tmpvar_34;
  tmpvar_34 = mix (tmpvar_31, tmpvar_31.zxy, vec3(zxlerp_20));
  detailCoords_18 = tmpvar_34;
  highp vec3 tmpvar_35;
  tmpvar_35 = mix (tmpvar_31.yxz, detailCoords_18, vec3(nylerp_19));
  detailCoords_18 = tmpvar_35;
  mediump float tmpvar_36;
  tmpvar_36 = abs(detailCoords_18.x);
  highp vec2 coord_37;
  coord_37 = (((0.5 * detailCoords_18.zy) / tmpvar_36) * _DetailScale);
  lowp vec4 tmpvar_38;
  tmpvar_38 = texture2DGradEXT (_DetailTex, coord_37, tmpvar_30.xy, tmpvar_30.zw);
  tmpvar_17 = tmpvar_38;
  color_5 = _SurfaceColor;
  highp float tmpvar_39;
  tmpvar_39 = clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0);
  detailLevel_4 = tmpvar_39;
  color_5.xyz = (color_5.xyz + (0.5 * mix ((tmpvar_17.xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(detailLevel_4))));
  highp float tmpvar_40;
  tmpvar_40 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  handoff_3 = tmpvar_40;
  color_5.xyz = mix (color_5.xyz, tex_6.xyz, vec3(handoff_3));
  specColor_2.xyz = _SpecColor.xyz;
  specColor_2.w = mix (1.0, tex_6.w, handoff_3);
  lowp vec3 tmpvar_41;
  tmpvar_41 = normalize(_WorldSpaceLightPos0).xyz;
  highp vec3 tmpvar_42;
  tmpvar_42 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  lowp vec4 tmpvar_43;
  tmpvar_43 = texture2D (_LightTexture0, xlv_TEXCOORD3);
  lowp vec4 tmpvar_44;
  tmpvar_44 = texture2DProj (_ShadowMapTexture, xlv_TEXCOORD4);
  mediump vec3 lightDir_45;
  lightDir_45 = tmpvar_41;
  mediump vec3 viewDir_46;
  viewDir_46 = xlv_TEXCOORD1;
  mediump vec3 normal_47;
  normal_47 = tmpvar_42;
  mediump float atten_48;
  atten_48 = (tmpvar_43.w * tmpvar_44.x);
  mediump vec4 c_49;
  highp float nh_50;
  mediump vec3 tmpvar_51;
  tmpvar_51 = normalize(viewDir_46);
  viewDir_46 = tmpvar_51;
  mediump float tmpvar_52;
  tmpvar_52 = dot (normal_47, lightDir_45);
  mediump float tmpvar_53;
  tmpvar_53 = clamp (dot (normalize((lightDir_45 + tmpvar_51)), normal_47), 0.0, 1.0);
  nh_50 = tmpvar_53;
  highp vec3 tmpvar_54;
  tmpvar_54 = ((((color_5.xyz * _LightColor0.xyz) * tmpvar_52) + ((_LightColor0.xyz * specColor_2.xyz) * (pow (nh_50, (_Shininess * 128.0)) * color_5.w))) * (atten_48 * 4.0));
  c_49.xyz = tmpvar_54;
  c_49.w = (tmpvar_52 * (atten_48 * 4.0));
  color_5.w = mix (1.0, color_5.w, clamp ((c_49.w * 4.0), 0.0, 1.0));
  mediump vec3 arg0_55;
  arg0_55 = (2.0 * color_5.xyz);
  color_5.w = mix (color_5.w, 1.0, clamp ((sqrt(dot (c_49.xyz, c_49.xyz)) - sqrt(dot (arg0_55, arg0_55))), 0.0, 1.0));
  color_5.w = mix (color_5.w, 1.0, handoff_3);
  color_5.xyz = c_49.xyz;
  tmpvar_1 = color_5;
  gl_FragData[0] = tmpvar_1;
}



#endif"
}

SubProgram "gles3 " {
Keywords { "DIRECTIONAL_COOKIE" "SHADOWS_SCREEN" }
"!!GLES3#version 300 es


#ifdef VERTEX

#define gl_Vertex _glesVertex
in vec4 _glesVertex;
#define gl_Normal (normalize(_glesNormal))
in vec3 _glesNormal;
#define gl_MultiTexCoord0 _glesMultiTexCoord0
in vec4 _glesMultiTexCoord0;
#define gl_MultiTexCoord1 _glesMultiTexCoord1
in vec4 _glesMultiTexCoord1;

#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 325
struct SurfaceOutput {
    lowp vec3 Albedo;
    lowp vec3 Normal;
    lowp vec3 Emission;
    mediump float Specular;
    lowp float Gloss;
    lowp float Alpha;
};
#line 521
struct v2f {
    highp vec4 pos;
    highp float viewDist;
    highp vec3 viewDir;
    highp vec3 worldPos;
    highp vec2 _LightCoord;
    highp vec4 _ShadowCoord;
    highp vec3 sphereNormal;
};
#line 513
struct appdata_t {
    highp vec4 vertex;
    highp vec3 normal;
    highp vec4 texcoord;
    highp vec4 texcoord2;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform lowp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform highp vec4 _ShadowOffsets[4];
uniform sampler2D _ShadowMapTexture;
#line 323
uniform sampler2D _LightTexture0;
uniform highp mat4 _LightMatrix0;
#line 335
uniform lowp vec4 _LightColor0;
uniform lowp vec4 _SpecColor;
#line 348
#line 356
#line 370
uniform highp mat4 _MainRotation;
uniform highp mat4 _DetailRotation;
#line 403
#line 407
#line 416
#line 424
#line 433
#line 441
#line 454
#line 466
#line 482
#line 494
uniform lowp vec4 _SurfaceColor;
#line 502
uniform highp float _Shininess;
uniform sampler2D _MainTex;
uniform sampler2D _DetailTex;
uniform highp float _DetailScale;
#line 506
uniform highp float _DetailDist;
uniform highp float _MinLight;
uniform sampler2D _CameraDepthTexture;
uniform highp mat4 _CameraToWorld;
#line 510
uniform highp float _LightPower;
uniform highp float _PlanetOpacity;
uniform highp vec3 _PlanetOrigin;
#line 532
#line 532
v2f vert( in appdata_t v ) {
    v2f o;
    highp vec4 vertex = v.vertex;
    #line 536
    o.pos = (glstate_matrix_mvp * vertex).xyzw;
    highp vec3 vertexPos = (_Object2World * vertex).xyz;
    o.viewDist = distance( vertexPos, _WorldSpaceCameraPos);
    o.worldPos = vertexPos;
    #line 540
    o.sphereNormal = (-normalize(vec4( v.texcoord.x, v.texcoord.y, v.texcoord2.x, v.texcoord2.y)).xyz);
    o.viewDir = normalize((_WorldSpaceCameraPos.xyz - vertexPos));
    o._LightCoord = (_LightMatrix0 * (_Object2World * v.vertex)).xy;
    o._ShadowCoord = (unity_World2Shadow[0] * (_Object2World * v.vertex));
    #line 545
    return o;
}
out highp float xlv_TEXCOORD0;
out highp vec3 xlv_TEXCOORD1;
out highp vec3 xlv_TEXCOORD2;
out highp vec2 xlv_TEXCOORD3;
out highp vec4 xlv_TEXCOORD4;
out highp vec3 xlv_TEXCOORD5;
void main() {
    v2f xl_retval;
    appdata_t xlt_v;
    xlt_v.vertex = vec4(gl_Vertex);
    xlt_v.normal = vec3(gl_Normal);
    xlt_v.texcoord = vec4(gl_MultiTexCoord0);
    xlt_v.texcoord2 = vec4(gl_MultiTexCoord1);
    xl_retval = vert( xlt_v);
    gl_Position = vec4(xl_retval.pos);
    xlv_TEXCOORD0 = float(xl_retval.viewDist);
    xlv_TEXCOORD1 = vec3(xl_retval.viewDir);
    xlv_TEXCOORD2 = vec3(xl_retval.worldPos);
    xlv_TEXCOORD3 = vec2(xl_retval._LightCoord);
    xlv_TEXCOORD4 = vec4(xl_retval._ShadowCoord);
    xlv_TEXCOORD5 = vec3(xl_retval.sphereNormal);
}


#endif
#ifdef FRAGMENT

#define gl_FragData _glesFragData
layout(location = 0) out mediump vec4 _glesFragData[4];
float xll_dFdx_f(float f) {
  return dFdx(f);
}
vec2 xll_dFdx_vf2(vec2 v) {
  return dFdx(v);
}
vec3 xll_dFdx_vf3(vec3 v) {
  return dFdx(v);
}
vec4 xll_dFdx_vf4(vec4 v) {
  return dFdx(v);
}
mat2 xll_dFdx_mf2x2(mat2 m) {
  return mat2( dFdx(m[0]), dFdx(m[1]));
}
mat3 xll_dFdx_mf3x3(mat3 m) {
  return mat3( dFdx(m[0]), dFdx(m[1]), dFdx(m[2]));
}
mat4 xll_dFdx_mf4x4(mat4 m) {
  return mat4( dFdx(m[0]), dFdx(m[1]), dFdx(m[2]), dFdx(m[3]));
}
float xll_dFdy_f(float f) {
  return dFdy(f);
}
vec2 xll_dFdy_vf2(vec2 v) {
  return dFdy(v);
}
vec3 xll_dFdy_vf3(vec3 v) {
  return dFdy(v);
}
vec4 xll_dFdy_vf4(vec4 v) {
  return dFdy(v);
}
mat2 xll_dFdy_mf2x2(mat2 m) {
  return mat2( dFdy(m[0]), dFdy(m[1]));
}
mat3 xll_dFdy_mf3x3(mat3 m) {
  return mat3( dFdy(m[0]), dFdy(m[1]), dFdy(m[2]));
}
mat4 xll_dFdy_mf4x4(mat4 m) {
  return mat4( dFdy(m[0]), dFdy(m[1]), dFdy(m[2]), dFdy(m[3]));
}
vec4 xll_tex2Dgrad(sampler2D s, vec2 coord, vec2 ddx, vec2 ddy) {
   return textureGrad( s, coord, ddx, ddy);
}
float xll_saturate_f( float x) {
  return clamp( x, 0.0, 1.0);
}
vec2 xll_saturate_vf2( vec2 x) {
  return clamp( x, 0.0, 1.0);
}
vec3 xll_saturate_vf3( vec3 x) {
  return clamp( x, 0.0, 1.0);
}
vec4 xll_saturate_vf4( vec4 x) {
  return clamp( x, 0.0, 1.0);
}
mat2 xll_saturate_mf2x2(mat2 m) {
  return mat2( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0));
}
mat3 xll_saturate_mf3x3(mat3 m) {
  return mat3( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0));
}
mat4 xll_saturate_mf4x4(mat4 m) {
  return mat4( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0), clamp(m[3], 0.0, 1.0));
}
#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 325
struct SurfaceOutput {
    lowp vec3 Albedo;
    lowp vec3 Normal;
    lowp vec3 Emission;
    mediump float Specular;
    lowp float Gloss;
    lowp float Alpha;
};
#line 521
struct v2f {
    highp vec4 pos;
    highp float viewDist;
    highp vec3 viewDir;
    highp vec3 worldPos;
    highp vec2 _LightCoord;
    highp vec4 _ShadowCoord;
    highp vec3 sphereNormal;
};
#line 513
struct appdata_t {
    highp vec4 vertex;
    highp vec3 normal;
    highp vec4 texcoord;
    highp vec4 texcoord2;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform lowp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform highp vec4 _ShadowOffsets[4];
uniform sampler2D _ShadowMapTexture;
#line 323
uniform sampler2D _LightTexture0;
uniform highp mat4 _LightMatrix0;
#line 335
uniform lowp vec4 _LightColor0;
uniform lowp vec4 _SpecColor;
#line 348
#line 356
#line 370
uniform highp mat4 _MainRotation;
uniform highp mat4 _DetailRotation;
#line 403
#line 407
#line 416
#line 424
#line 433
#line 441
#line 454
#line 466
#line 482
#line 494
uniform lowp vec4 _SurfaceColor;
#line 502
uniform highp float _Shininess;
uniform sampler2D _MainTex;
uniform sampler2D _DetailTex;
uniform highp float _DetailScale;
#line 506
uniform highp float _DetailDist;
uniform highp float _MinLight;
uniform sampler2D _CameraDepthTexture;
uniform highp mat4 _CameraToWorld;
#line 510
uniform highp float _LightPower;
uniform highp float _PlanetOpacity;
uniform highp vec3 _PlanetOrigin;
#line 532
#line 407
highp vec4 Derivatives( in highp float lat, in highp float lon, in highp vec3 pos ) {
    highp vec2 latLong = vec2( lat, lon);
    highp float latDdx = (0.159155 * length(xll_dFdx_vf2(pos.xz)));
    #line 411
    highp float latDdy = (0.159155 * length(xll_dFdy_vf2(pos.xz)));
    highp float longDdx = xll_dFdx_f(lon);
    highp float longDdy = xll_dFdy_f(lon);
    return vec4( latDdx, longDdx, latDdy, longDdy);
}
#line 416
highp vec2 GetSphereUV( in highp vec3 sphereVect, in highp vec2 uvOffset ) {
    highp vec2 uv;
    uv.x = (0.5 + (0.159155 * atan( sphereVect.x, sphereVect.z)));
    #line 420
    uv.y = (0.31831 * acos(sphereVect.y));
    uv += uvOffset;
    return uv;
}
#line 454
mediump vec4 GetShereDetailMap( in sampler2D texSampler, in highp vec3 sphereVect, in highp float detailScale ) {
    highp vec3 sphereVectNorm = normalize(sphereVect);
    highp vec2 uv = ((GetSphereUV( sphereVectNorm, vec2( 0.0, 0.0)) * 4.0) * detailScale);
    #line 458
    highp vec4 uvdd = Derivatives( (uv.x - 0.5), uv.y, sphereVectNorm);
    sphereVectNorm = abs(sphereVectNorm);
    mediump float zxlerp = step( sphereVectNorm.x, sphereVectNorm.z);
    mediump float nylerp = step( sphereVectNorm.y, mix( sphereVectNorm.x, sphereVectNorm.z, zxlerp));
    #line 462
    mediump vec3 detailCoords = mix( sphereVectNorm.xyz, sphereVectNorm.zxy, vec3( zxlerp));
    detailCoords = mix( sphereVectNorm.yxz, detailCoords, vec3( nylerp));
    return xll_tex2Dgrad( texSampler, (((0.5 * detailCoords.zy) / abs(detailCoords.x)) * detailScale), uvdd.xy, uvdd.zw);
}
#line 433
mediump vec4 GetSphereMap( in sampler2D texSampler, in highp vec3 sphereVect ) {
    highp vec3 sphereVectNorm = normalize(sphereVect);
    highp vec2 uv = GetSphereUV( sphereVectNorm, vec2( 0.0, 0.0));
    #line 437
    highp vec4 uvdd = Derivatives( (uv.x - 0.5), uv.y, sphereVectNorm);
    mediump vec4 tex = xll_tex2Dgrad( texSampler, uv, uvdd.xy, uvdd.zw);
    return tex;
}
#line 482
mediump vec4 SpecularColorLight( in mediump vec3 lightDir, in mediump vec3 viewDir, in mediump vec3 normal, in mediump vec4 color, in mediump vec4 specColor, in highp float specK, in mediump float atten ) {
    viewDir = normalize(viewDir);
    mediump vec3 h = normalize((lightDir + viewDir));
    #line 486
    mediump float diffuse = dot( normal, lightDir);
    highp float nh = xll_saturate_f(dot( h, normal));
    highp float spec = (pow( nh, specK) * color.w);
    mediump vec4 c;
    #line 490
    c.xyz = ((((color.xyz * _LightColor0.xyz) * diffuse) + ((_LightColor0.xyz * specColor.xyz) * spec)) * (atten * 4.0));
    c.w = (diffuse * (atten * 4.0));
    return c;
}
#line 317
lowp float unitySampleShadow( in highp vec4 shadowCoord ) {
    #line 319
    highp float dist = textureProj( _ShadowMapTexture, shadowCoord).x;
    mediump float lightShadowDataX = _LightShadowData.x;
    return max( float((dist > (shadowCoord.z / shadowCoord.w))), lightShadowDataX);
}
#line 547
lowp vec4 frag( in v2f IN ) {
    #line 549
    mediump vec4 color;
    highp vec3 sphereNrm = IN.sphereNormal;
    mediump vec4 main = GetSphereMap( _MainTex, sphereNrm);
    mediump vec4 detail = GetShereDetailMap( _DetailTex, sphereNrm, _DetailScale);
    #line 553
    color = _SurfaceColor;
    mediump float detailLevel = xll_saturate_f(((2.0 * _DetailDist) * IN.viewDist));
    color.xyz += (0.5 * mix( (detail.xyz - 0.5), vec3( 0.0), vec3( detailLevel)));
    mediump float handoff = xll_saturate_f(pow( _PlanetOpacity, 2.0));
    #line 557
    color.xyz = mix( color.xyz, main.xyz, vec3( handoff));
    mediump vec4 specColor = _SpecColor;
    specColor.w = mix( 1.0, main.w, handoff);
    mediump vec4 colorLight = SpecularColorLight( vec3( normalize(_WorldSpaceLightPos0)), IN.viewDir, normalize((IN.worldPos - _PlanetOrigin)), color, specColor, (_Shininess * 128.0), (texture( _LightTexture0, IN._LightCoord).w * unitySampleShadow( IN._ShadowCoord)));
    #line 561
    color.w = mix( 1.0, color.w, xll_saturate_f((colorLight.w * 4.0)));
    color.w = mix( color.w, 1.0, xll_saturate_f((length(colorLight.xyz) - length((2.0 * color.xyz)))));
    color.w = mix( color.w, 1.0, handoff);
    color.xyz = colorLight.xyz;
    #line 565
    return color;
}
in highp float xlv_TEXCOORD0;
in highp vec3 xlv_TEXCOORD1;
in highp vec3 xlv_TEXCOORD2;
in highp vec2 xlv_TEXCOORD3;
in highp vec4 xlv_TEXCOORD4;
in highp vec3 xlv_TEXCOORD5;
void main() {
    lowp vec4 xl_retval;
    v2f xlt_IN;
    xlt_IN.pos = vec4(0.0);
    xlt_IN.viewDist = float(xlv_TEXCOORD0);
    xlt_IN.viewDir = vec3(xlv_TEXCOORD1);
    xlt_IN.worldPos = vec3(xlv_TEXCOORD2);
    xlt_IN._LightCoord = vec2(xlv_TEXCOORD3);
    xlt_IN._ShadowCoord = vec4(xlv_TEXCOORD4);
    xlt_IN.sphereNormal = vec3(xlv_TEXCOORD5);
    xl_retval = frag( xlt_IN);
    gl_FragData[0] = vec4(xl_retval);
}


#endif"
}

SubProgram "opengl " {
Keywords { "POINT" "SHADOWS_CUBE" }
"!!GLSL
#ifdef VERTEX
varying vec3 xlv_TEXCOORD5;
varying vec3 xlv_TEXCOORD4;
varying vec3 xlv_TEXCOORD3;
varying vec3 xlv_TEXCOORD2;
varying vec3 xlv_TEXCOORD1;
varying float xlv_TEXCOORD0;
uniform mat4 _LightMatrix0;
uniform mat4 _Object2World;

uniform vec4 _LightPositionRange;
uniform vec3 _WorldSpaceCameraPos;
void main ()
{
  vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * gl_Vertex).xyz;
  vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  vec4 tmpvar_3;
  tmpvar_3.x = gl_MultiTexCoord0.x;
  tmpvar_3.y = gl_MultiTexCoord0.y;
  tmpvar_3.z = gl_MultiTexCoord1.x;
  tmpvar_3.w = gl_MultiTexCoord1.y;
  gl_Position = (gl_ModelViewProjectionMatrix * gl_Vertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * gl_Vertex)).xyz;
  xlv_TEXCOORD4 = ((_Object2World * gl_Vertex).xyz - _LightPositionRange.xyz);
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}


#endif
#ifdef FRAGMENT
#extension GL_ARB_shader_texture_lod : enable
varying vec3 xlv_TEXCOORD5;
varying vec3 xlv_TEXCOORD4;
varying vec3 xlv_TEXCOORD3;
varying vec3 xlv_TEXCOORD2;
varying vec3 xlv_TEXCOORD1;
varying float xlv_TEXCOORD0;
uniform vec3 _PlanetOrigin;
uniform float _PlanetOpacity;
uniform float _DetailDist;
uniform float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform float _Shininess;
uniform vec4 _SurfaceColor;
uniform vec4 _SpecColor;
uniform vec4 _LightColor0;
uniform sampler2D _LightTexture0;
uniform samplerCube _ShadowMapTexture;
uniform vec4 _LightShadowData;
uniform vec4 _LightPositionRange;
uniform vec4 _WorldSpaceLightPos0;
void main ()
{
  vec4 main_1;
  vec4 color_2;
  vec3 tmpvar_3;
  tmpvar_3 = normalize(xlv_TEXCOORD5);
  vec2 uv_4;
  float r_5;
  if ((abs(tmpvar_3.z) > (1e-08 * abs(tmpvar_3.x)))) {
    float y_over_x_6;
    y_over_x_6 = (tmpvar_3.x / tmpvar_3.z);
    float s_7;
    float x_8;
    x_8 = (y_over_x_6 * inversesqrt(((y_over_x_6 * y_over_x_6) + 1.0)));
    s_7 = (sign(x_8) * (1.5708 - (sqrt((1.0 - abs(x_8))) * (1.5708 + (abs(x_8) * (-0.214602 + (abs(x_8) * (0.0865667 + (abs(x_8) * -0.0310296)))))))));
    r_5 = s_7;
    if ((tmpvar_3.z < 0.0)) {
      if ((tmpvar_3.x >= 0.0)) {
        r_5 = (s_7 + 3.14159);
      } else {
        r_5 = (r_5 - 3.14159);
      };
    };
  } else {
    r_5 = (sign(tmpvar_3.x) * 1.5708);
  };
  uv_4.x = (0.5 + (0.159155 * r_5));
  uv_4.y = (0.31831 * (1.5708 - (sign(tmpvar_3.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_3.y))) * (1.5708 + (abs(tmpvar_3.y) * (-0.214602 + (abs(tmpvar_3.y) * (0.0865667 + (abs(tmpvar_3.y) * -0.0310296)))))))))));
  vec2 tmpvar_9;
  tmpvar_9 = dFdx(tmpvar_3.xz);
  vec2 tmpvar_10;
  tmpvar_10 = dFdy(tmpvar_3.xz);
  vec4 tmpvar_11;
  tmpvar_11.x = (0.159155 * sqrt(dot (tmpvar_9, tmpvar_9)));
  tmpvar_11.y = dFdx(uv_4.y);
  tmpvar_11.z = (0.159155 * sqrt(dot (tmpvar_10, tmpvar_10)));
  tmpvar_11.w = dFdy(uv_4.y);
  main_1 = texture2DGradARB (_MainTex, uv_4, tmpvar_11.xy, tmpvar_11.zw);
  vec3 tmpvar_12;
  tmpvar_12 = normalize(xlv_TEXCOORD5);
  vec2 uv_13;
  float r_14;
  if ((abs(tmpvar_12.z) > (1e-08 * abs(tmpvar_12.x)))) {
    float y_over_x_15;
    y_over_x_15 = (tmpvar_12.x / tmpvar_12.z);
    float s_16;
    float x_17;
    x_17 = (y_over_x_15 * inversesqrt(((y_over_x_15 * y_over_x_15) + 1.0)));
    s_16 = (sign(x_17) * (1.5708 - (sqrt((1.0 - abs(x_17))) * (1.5708 + (abs(x_17) * (-0.214602 + (abs(x_17) * (0.0865667 + (abs(x_17) * -0.0310296)))))))));
    r_14 = s_16;
    if ((tmpvar_12.z < 0.0)) {
      if ((tmpvar_12.x >= 0.0)) {
        r_14 = (s_16 + 3.14159);
      } else {
        r_14 = (r_14 - 3.14159);
      };
    };
  } else {
    r_14 = (sign(tmpvar_12.x) * 1.5708);
  };
  uv_13.x = (0.5 + (0.159155 * r_14));
  uv_13.y = (0.31831 * (1.5708 - (sign(tmpvar_12.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_12.y))) * (1.5708 + (abs(tmpvar_12.y) * (-0.214602 + (abs(tmpvar_12.y) * (0.0865667 + (abs(tmpvar_12.y) * -0.0310296)))))))))));
  vec2 tmpvar_18;
  tmpvar_18 = ((uv_13 * 4.0) * _DetailScale);
  vec2 tmpvar_19;
  tmpvar_19 = dFdx(tmpvar_12.xz);
  vec2 tmpvar_20;
  tmpvar_20 = dFdy(tmpvar_12.xz);
  vec4 tmpvar_21;
  tmpvar_21.x = (0.159155 * sqrt(dot (tmpvar_19, tmpvar_19)));
  tmpvar_21.y = dFdx(tmpvar_18.y);
  tmpvar_21.z = (0.159155 * sqrt(dot (tmpvar_20, tmpvar_20)));
  tmpvar_21.w = dFdy(tmpvar_18.y);
  vec3 tmpvar_22;
  tmpvar_22 = abs(tmpvar_12);
  float tmpvar_23;
  tmpvar_23 = float((tmpvar_22.z >= tmpvar_22.x));
  vec3 tmpvar_24;
  tmpvar_24 = mix (tmpvar_22.yxz, mix (tmpvar_22, tmpvar_22.zxy, vec3(tmpvar_23)), vec3(float((mix (tmpvar_22.x, tmpvar_22.z, tmpvar_23) >= tmpvar_22.y))));
  color_2.w = _SurfaceColor.w;
  color_2.xyz = (_SurfaceColor.xyz + (0.5 * mix ((texture2DGradARB (_DetailTex, (((0.5 * tmpvar_24.zy) / abs(tmpvar_24.x)) * _DetailScale), tmpvar_21.xy, tmpvar_21.zw).xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0)))));
  float tmpvar_25;
  tmpvar_25 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  color_2.xyz = mix (color_2.xyz, main_1.xyz, vec3(tmpvar_25));
  vec4 tmpvar_26;
  tmpvar_26 = normalize(_WorldSpaceLightPos0);
  vec3 tmpvar_27;
  tmpvar_27 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  vec4 tmpvar_28;
  tmpvar_28 = texture2D (_LightTexture0, vec2(dot (xlv_TEXCOORD3, xlv_TEXCOORD3)));
  float tmpvar_29;
  tmpvar_29 = ((sqrt(dot (xlv_TEXCOORD4, xlv_TEXCOORD4)) * _LightPositionRange.w) * 0.97);
  float tmpvar_30;
  tmpvar_30 = dot (textureCube (_ShadowMapTexture, xlv_TEXCOORD4), vec4(1.0, 0.00392157, 1.53787e-05, 6.22737e-09));
  float tmpvar_31;
  if ((tmpvar_30 < tmpvar_29)) {
    tmpvar_31 = _LightShadowData.x;
  } else {
    tmpvar_31 = 1.0;
  };
  float atten_32;
  atten_32 = (tmpvar_28.w * tmpvar_31);
  vec4 c_33;
  vec3 tmpvar_34;
  tmpvar_34 = normalize(tmpvar_26.xyz);
  float tmpvar_35;
  tmpvar_35 = dot (tmpvar_27, tmpvar_34);
  c_33.xyz = ((((color_2.xyz * _LightColor0.xyz) * tmpvar_35) + ((_LightColor0.xyz * _SpecColor.xyz) * (pow (clamp (dot (normalize((tmpvar_34 + normalize(xlv_TEXCOORD1))), tmpvar_27), 0.0, 1.0), (_Shininess * 128.0)) * _SurfaceColor.w))) * (atten_32 * 4.0));
  c_33.w = (tmpvar_35 * (atten_32 * 4.0));
  color_2.w = mix (1.0, _SurfaceColor.w, clamp ((c_33.w * 4.0), 0.0, 1.0));
  vec3 arg0_36;
  arg0_36 = (2.0 * color_2.xyz);
  color_2.w = mix (color_2.w, 1.0, clamp ((sqrt(dot (c_33.xyz, c_33.xyz)) - sqrt(dot (arg0_36, arg0_36))), 0.0, 1.0));
  color_2.w = mix (color_2.w, 1.0, tmpvar_25);
  color_2.xyz = c_33.xyz;
  gl_FragData[0] = color_2;
}


#endif
"
}

SubProgram "d3d9 " {
Keywords { "POINT" "SHADOWS_CUBE" }
Bind "vertex" Vertex
Bind "texcoord" TexCoord0
Bind "texcoord1" TexCoord1
Matrix 0 [glstate_matrix_mvp]
Vector 12 [_WorldSpaceCameraPos]
Vector 13 [_LightPositionRange]
Matrix 4 [_Object2World]
Matrix 8 [_LightMatrix0]
"vs_3_0
; 25 ALU
dcl_position o0
dcl_texcoord0 o1
dcl_texcoord1 o2
dcl_texcoord2 o3
dcl_texcoord3 o4
dcl_texcoord4 o5
dcl_texcoord5 o6
dcl_position0 v0
dcl_texcoord0 v1
dcl_texcoord1 v2
dp4 r1.z, v0, c6
dp4 r1.x, v0, c4
dp4 r1.y, v0, c5
mov r0.zw, v2.xyxy
mov r0.xy, v1
dp4 r0.w, r0, r0
rsq r1.w, r0.w
mul r0.xyz, r1.w, r0
add r2.xyz, -r1, c12
dp3 r0.w, r2, r2
rsq r1.w, r0.w
mov o6.xyz, -r0
mov r0.xyz, r1
dp4 r0.w, v0, c7
mul o2.xyz, r1.w, r2
dp4 o4.z, r0, c10
dp4 o4.y, r0, c9
dp4 o4.x, r0, c8
rcp o1.x, r1.w
mov o3.xyz, r1
add o5.xyz, r1, -c13
dp4 o0.w, v0, c3
dp4 o0.z, v0, c2
dp4 o0.y, v0, c1
dp4 o0.x, v0, c0
"
}

SubProgram "gles " {
Keywords { "POINT" "SHADOWS_CUBE" }
"!!GLES


#ifdef VERTEX

varying highp vec3 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD4;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp mat4 _LightMatrix0;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_mvp;
uniform highp vec4 _LightPositionRange;
uniform highp vec3 _WorldSpaceCameraPos;
attribute vec4 _glesMultiTexCoord1;
attribute vec4 _glesMultiTexCoord0;
attribute vec4 _glesVertex;
void main ()
{
  highp vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * _glesVertex).xyz;
  highp vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  highp vec4 tmpvar_3;
  tmpvar_3.x = _glesMultiTexCoord0.x;
  tmpvar_3.y = _glesMultiTexCoord0.y;
  tmpvar_3.z = _glesMultiTexCoord1.x;
  tmpvar_3.w = _glesMultiTexCoord1.y;
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * _glesVertex)).xyz;
  xlv_TEXCOORD4 = ((_Object2World * _glesVertex).xyz - _LightPositionRange.xyz);
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}



#endif
#ifdef FRAGMENT

#extension GL_EXT_shader_texture_lod : enable
#extension GL_OES_standard_derivatives : enable
varying highp vec3 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD4;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp vec3 _PlanetOrigin;
uniform highp float _PlanetOpacity;
uniform highp float _DetailDist;
uniform highp float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform highp float _Shininess;
uniform lowp vec4 _SurfaceColor;
uniform lowp vec4 _SpecColor;
uniform lowp vec4 _LightColor0;
uniform sampler2D _LightTexture0;
uniform samplerCube _ShadowMapTexture;
uniform highp vec4 _LightShadowData;
uniform highp vec4 _LightPositionRange;
uniform highp vec4 _WorldSpaceLightPos0;
void main ()
{
  lowp vec4 tmpvar_1;
  mediump vec4 specColor_2;
  mediump float handoff_3;
  mediump float detailLevel_4;
  mediump vec4 color_5;
  mediump vec4 tex_6;
  highp vec3 tmpvar_7;
  tmpvar_7 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_8;
  highp float r_9;
  if ((abs(tmpvar_7.z) > (1e-08 * abs(tmpvar_7.x)))) {
    highp float y_over_x_10;
    y_over_x_10 = (tmpvar_7.x / tmpvar_7.z);
    highp float s_11;
    highp float x_12;
    x_12 = (y_over_x_10 * inversesqrt(((y_over_x_10 * y_over_x_10) + 1.0)));
    s_11 = (sign(x_12) * (1.5708 - (sqrt((1.0 - abs(x_12))) * (1.5708 + (abs(x_12) * (-0.214602 + (abs(x_12) * (0.0865667 + (abs(x_12) * -0.0310296)))))))));
    r_9 = s_11;
    if ((tmpvar_7.z < 0.0)) {
      if ((tmpvar_7.x >= 0.0)) {
        r_9 = (s_11 + 3.14159);
      } else {
        r_9 = (r_9 - 3.14159);
      };
    };
  } else {
    r_9 = (sign(tmpvar_7.x) * 1.5708);
  };
  uv_8.x = (0.5 + (0.159155 * r_9));
  uv_8.y = (0.31831 * (1.5708 - (sign(tmpvar_7.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_7.y))) * (1.5708 + (abs(tmpvar_7.y) * (-0.214602 + (abs(tmpvar_7.y) * (0.0865667 + (abs(tmpvar_7.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_13;
  tmpvar_13 = dFdx(tmpvar_7.xz);
  highp vec2 tmpvar_14;
  tmpvar_14 = dFdy(tmpvar_7.xz);
  highp vec4 tmpvar_15;
  tmpvar_15.x = (0.159155 * sqrt(dot (tmpvar_13, tmpvar_13)));
  tmpvar_15.y = dFdx(uv_8.y);
  tmpvar_15.z = (0.159155 * sqrt(dot (tmpvar_14, tmpvar_14)));
  tmpvar_15.w = dFdy(uv_8.y);
  lowp vec4 tmpvar_16;
  tmpvar_16 = texture2DGradEXT (_MainTex, uv_8, tmpvar_15.xy, tmpvar_15.zw);
  tex_6 = tmpvar_16;
  mediump vec4 tmpvar_17;
  mediump vec3 detailCoords_18;
  mediump float nylerp_19;
  mediump float zxlerp_20;
  highp vec3 tmpvar_21;
  tmpvar_21 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_22;
  highp float r_23;
  if ((abs(tmpvar_21.z) > (1e-08 * abs(tmpvar_21.x)))) {
    highp float y_over_x_24;
    y_over_x_24 = (tmpvar_21.x / tmpvar_21.z);
    highp float s_25;
    highp float x_26;
    x_26 = (y_over_x_24 * inversesqrt(((y_over_x_24 * y_over_x_24) + 1.0)));
    s_25 = (sign(x_26) * (1.5708 - (sqrt((1.0 - abs(x_26))) * (1.5708 + (abs(x_26) * (-0.214602 + (abs(x_26) * (0.0865667 + (abs(x_26) * -0.0310296)))))))));
    r_23 = s_25;
    if ((tmpvar_21.z < 0.0)) {
      if ((tmpvar_21.x >= 0.0)) {
        r_23 = (s_25 + 3.14159);
      } else {
        r_23 = (r_23 - 3.14159);
      };
    };
  } else {
    r_23 = (sign(tmpvar_21.x) * 1.5708);
  };
  uv_22.x = (0.5 + (0.159155 * r_23));
  uv_22.y = (0.31831 * (1.5708 - (sign(tmpvar_21.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_21.y))) * (1.5708 + (abs(tmpvar_21.y) * (-0.214602 + (abs(tmpvar_21.y) * (0.0865667 + (abs(tmpvar_21.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_27;
  tmpvar_27 = ((uv_22 * 4.0) * _DetailScale);
  highp vec2 tmpvar_28;
  tmpvar_28 = dFdx(tmpvar_21.xz);
  highp vec2 tmpvar_29;
  tmpvar_29 = dFdy(tmpvar_21.xz);
  highp vec4 tmpvar_30;
  tmpvar_30.x = (0.159155 * sqrt(dot (tmpvar_28, tmpvar_28)));
  tmpvar_30.y = dFdx(tmpvar_27.y);
  tmpvar_30.z = (0.159155 * sqrt(dot (tmpvar_29, tmpvar_29)));
  tmpvar_30.w = dFdy(tmpvar_27.y);
  highp vec3 tmpvar_31;
  tmpvar_31 = abs(tmpvar_21);
  highp float tmpvar_32;
  tmpvar_32 = float((tmpvar_31.z >= tmpvar_31.x));
  zxlerp_20 = tmpvar_32;
  highp float tmpvar_33;
  tmpvar_33 = float((mix (tmpvar_31.x, tmpvar_31.z, zxlerp_20) >= tmpvar_31.y));
  nylerp_19 = tmpvar_33;
  highp vec3 tmpvar_34;
  tmpvar_34 = mix (tmpvar_31, tmpvar_31.zxy, vec3(zxlerp_20));
  detailCoords_18 = tmpvar_34;
  highp vec3 tmpvar_35;
  tmpvar_35 = mix (tmpvar_31.yxz, detailCoords_18, vec3(nylerp_19));
  detailCoords_18 = tmpvar_35;
  mediump float tmpvar_36;
  tmpvar_36 = abs(detailCoords_18.x);
  highp vec2 coord_37;
  coord_37 = (((0.5 * detailCoords_18.zy) / tmpvar_36) * _DetailScale);
  lowp vec4 tmpvar_38;
  tmpvar_38 = texture2DGradEXT (_DetailTex, coord_37, tmpvar_30.xy, tmpvar_30.zw);
  tmpvar_17 = tmpvar_38;
  color_5 = _SurfaceColor;
  highp float tmpvar_39;
  tmpvar_39 = clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0);
  detailLevel_4 = tmpvar_39;
  color_5.xyz = (color_5.xyz + (0.5 * mix ((tmpvar_17.xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(detailLevel_4))));
  highp float tmpvar_40;
  tmpvar_40 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  handoff_3 = tmpvar_40;
  color_5.xyz = mix (color_5.xyz, tex_6.xyz, vec3(handoff_3));
  specColor_2.xyz = _SpecColor.xyz;
  specColor_2.w = mix (1.0, tex_6.w, handoff_3);
  highp vec3 tmpvar_41;
  tmpvar_41 = normalize(_WorldSpaceLightPos0).xyz;
  highp vec3 tmpvar_42;
  tmpvar_42 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  highp float tmpvar_43;
  tmpvar_43 = dot (xlv_TEXCOORD3, xlv_TEXCOORD3);
  lowp vec4 tmpvar_44;
  tmpvar_44 = texture2D (_LightTexture0, vec2(tmpvar_43));
  highp float tmpvar_45;
  tmpvar_45 = ((sqrt(dot (xlv_TEXCOORD4, xlv_TEXCOORD4)) * _LightPositionRange.w) * 0.97);
  highp vec4 packDist_46;
  lowp vec4 tmpvar_47;
  tmpvar_47 = textureCube (_ShadowMapTexture, xlv_TEXCOORD4);
  packDist_46 = tmpvar_47;
  highp float tmpvar_48;
  tmpvar_48 = dot (packDist_46, vec4(1.0, 0.00392157, 1.53787e-05, 6.22737e-09));
  highp float tmpvar_49;
  if ((tmpvar_48 < tmpvar_45)) {
    tmpvar_49 = _LightShadowData.x;
  } else {
    tmpvar_49 = 1.0;
  };
  mediump vec3 lightDir_50;
  lightDir_50 = tmpvar_41;
  mediump vec3 viewDir_51;
  viewDir_51 = xlv_TEXCOORD1;
  mediump vec3 normal_52;
  normal_52 = tmpvar_42;
  mediump float atten_53;
  atten_53 = (tmpvar_44.w * tmpvar_49);
  mediump vec4 c_54;
  highp float nh_55;
  mediump vec3 tmpvar_56;
  tmpvar_56 = normalize(lightDir_50);
  lightDir_50 = tmpvar_56;
  mediump vec3 tmpvar_57;
  tmpvar_57 = normalize(viewDir_51);
  viewDir_51 = tmpvar_57;
  mediump float tmpvar_58;
  tmpvar_58 = dot (normal_52, tmpvar_56);
  mediump float tmpvar_59;
  tmpvar_59 = clamp (dot (normalize((tmpvar_56 + tmpvar_57)), normal_52), 0.0, 1.0);
  nh_55 = tmpvar_59;
  highp vec3 tmpvar_60;
  tmpvar_60 = ((((color_5.xyz * _LightColor0.xyz) * tmpvar_58) + ((_LightColor0.xyz * specColor_2.xyz) * (pow (nh_55, (_Shininess * 128.0)) * color_5.w))) * (atten_53 * 4.0));
  c_54.xyz = tmpvar_60;
  c_54.w = (tmpvar_58 * (atten_53 * 4.0));
  color_5.w = mix (1.0, color_5.w, clamp ((c_54.w * 4.0), 0.0, 1.0));
  mediump vec3 arg0_61;
  arg0_61 = (2.0 * color_5.xyz);
  color_5.w = mix (color_5.w, 1.0, clamp ((sqrt(dot (c_54.xyz, c_54.xyz)) - sqrt(dot (arg0_61, arg0_61))), 0.0, 1.0));
  color_5.w = mix (color_5.w, 1.0, handoff_3);
  color_5.xyz = c_54.xyz;
  tmpvar_1 = color_5;
  gl_FragData[0] = tmpvar_1;
}



#endif"
}

SubProgram "glesdesktop " {
Keywords { "POINT" "SHADOWS_CUBE" }
"!!GLES


#ifdef VERTEX

varying highp vec3 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD4;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp mat4 _LightMatrix0;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_mvp;
uniform highp vec4 _LightPositionRange;
uniform highp vec3 _WorldSpaceCameraPos;
attribute vec4 _glesMultiTexCoord1;
attribute vec4 _glesMultiTexCoord0;
attribute vec4 _glesVertex;
void main ()
{
  highp vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * _glesVertex).xyz;
  highp vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  highp vec4 tmpvar_3;
  tmpvar_3.x = _glesMultiTexCoord0.x;
  tmpvar_3.y = _glesMultiTexCoord0.y;
  tmpvar_3.z = _glesMultiTexCoord1.x;
  tmpvar_3.w = _glesMultiTexCoord1.y;
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * _glesVertex)).xyz;
  xlv_TEXCOORD4 = ((_Object2World * _glesVertex).xyz - _LightPositionRange.xyz);
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}



#endif
#ifdef FRAGMENT

#extension GL_EXT_shader_texture_lod : enable
#extension GL_OES_standard_derivatives : enable
varying highp vec3 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD4;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp vec3 _PlanetOrigin;
uniform highp float _PlanetOpacity;
uniform highp float _DetailDist;
uniform highp float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform highp float _Shininess;
uniform lowp vec4 _SurfaceColor;
uniform lowp vec4 _SpecColor;
uniform lowp vec4 _LightColor0;
uniform sampler2D _LightTexture0;
uniform samplerCube _ShadowMapTexture;
uniform highp vec4 _LightShadowData;
uniform highp vec4 _LightPositionRange;
uniform highp vec4 _WorldSpaceLightPos0;
void main ()
{
  lowp vec4 tmpvar_1;
  mediump vec4 specColor_2;
  mediump float handoff_3;
  mediump float detailLevel_4;
  mediump vec4 color_5;
  mediump vec4 tex_6;
  highp vec3 tmpvar_7;
  tmpvar_7 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_8;
  highp float r_9;
  if ((abs(tmpvar_7.z) > (1e-08 * abs(tmpvar_7.x)))) {
    highp float y_over_x_10;
    y_over_x_10 = (tmpvar_7.x / tmpvar_7.z);
    highp float s_11;
    highp float x_12;
    x_12 = (y_over_x_10 * inversesqrt(((y_over_x_10 * y_over_x_10) + 1.0)));
    s_11 = (sign(x_12) * (1.5708 - (sqrt((1.0 - abs(x_12))) * (1.5708 + (abs(x_12) * (-0.214602 + (abs(x_12) * (0.0865667 + (abs(x_12) * -0.0310296)))))))));
    r_9 = s_11;
    if ((tmpvar_7.z < 0.0)) {
      if ((tmpvar_7.x >= 0.0)) {
        r_9 = (s_11 + 3.14159);
      } else {
        r_9 = (r_9 - 3.14159);
      };
    };
  } else {
    r_9 = (sign(tmpvar_7.x) * 1.5708);
  };
  uv_8.x = (0.5 + (0.159155 * r_9));
  uv_8.y = (0.31831 * (1.5708 - (sign(tmpvar_7.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_7.y))) * (1.5708 + (abs(tmpvar_7.y) * (-0.214602 + (abs(tmpvar_7.y) * (0.0865667 + (abs(tmpvar_7.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_13;
  tmpvar_13 = dFdx(tmpvar_7.xz);
  highp vec2 tmpvar_14;
  tmpvar_14 = dFdy(tmpvar_7.xz);
  highp vec4 tmpvar_15;
  tmpvar_15.x = (0.159155 * sqrt(dot (tmpvar_13, tmpvar_13)));
  tmpvar_15.y = dFdx(uv_8.y);
  tmpvar_15.z = (0.159155 * sqrt(dot (tmpvar_14, tmpvar_14)));
  tmpvar_15.w = dFdy(uv_8.y);
  lowp vec4 tmpvar_16;
  tmpvar_16 = texture2DGradEXT (_MainTex, uv_8, tmpvar_15.xy, tmpvar_15.zw);
  tex_6 = tmpvar_16;
  mediump vec4 tmpvar_17;
  mediump vec3 detailCoords_18;
  mediump float nylerp_19;
  mediump float zxlerp_20;
  highp vec3 tmpvar_21;
  tmpvar_21 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_22;
  highp float r_23;
  if ((abs(tmpvar_21.z) > (1e-08 * abs(tmpvar_21.x)))) {
    highp float y_over_x_24;
    y_over_x_24 = (tmpvar_21.x / tmpvar_21.z);
    highp float s_25;
    highp float x_26;
    x_26 = (y_over_x_24 * inversesqrt(((y_over_x_24 * y_over_x_24) + 1.0)));
    s_25 = (sign(x_26) * (1.5708 - (sqrt((1.0 - abs(x_26))) * (1.5708 + (abs(x_26) * (-0.214602 + (abs(x_26) * (0.0865667 + (abs(x_26) * -0.0310296)))))))));
    r_23 = s_25;
    if ((tmpvar_21.z < 0.0)) {
      if ((tmpvar_21.x >= 0.0)) {
        r_23 = (s_25 + 3.14159);
      } else {
        r_23 = (r_23 - 3.14159);
      };
    };
  } else {
    r_23 = (sign(tmpvar_21.x) * 1.5708);
  };
  uv_22.x = (0.5 + (0.159155 * r_23));
  uv_22.y = (0.31831 * (1.5708 - (sign(tmpvar_21.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_21.y))) * (1.5708 + (abs(tmpvar_21.y) * (-0.214602 + (abs(tmpvar_21.y) * (0.0865667 + (abs(tmpvar_21.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_27;
  tmpvar_27 = ((uv_22 * 4.0) * _DetailScale);
  highp vec2 tmpvar_28;
  tmpvar_28 = dFdx(tmpvar_21.xz);
  highp vec2 tmpvar_29;
  tmpvar_29 = dFdy(tmpvar_21.xz);
  highp vec4 tmpvar_30;
  tmpvar_30.x = (0.159155 * sqrt(dot (tmpvar_28, tmpvar_28)));
  tmpvar_30.y = dFdx(tmpvar_27.y);
  tmpvar_30.z = (0.159155 * sqrt(dot (tmpvar_29, tmpvar_29)));
  tmpvar_30.w = dFdy(tmpvar_27.y);
  highp vec3 tmpvar_31;
  tmpvar_31 = abs(tmpvar_21);
  highp float tmpvar_32;
  tmpvar_32 = float((tmpvar_31.z >= tmpvar_31.x));
  zxlerp_20 = tmpvar_32;
  highp float tmpvar_33;
  tmpvar_33 = float((mix (tmpvar_31.x, tmpvar_31.z, zxlerp_20) >= tmpvar_31.y));
  nylerp_19 = tmpvar_33;
  highp vec3 tmpvar_34;
  tmpvar_34 = mix (tmpvar_31, tmpvar_31.zxy, vec3(zxlerp_20));
  detailCoords_18 = tmpvar_34;
  highp vec3 tmpvar_35;
  tmpvar_35 = mix (tmpvar_31.yxz, detailCoords_18, vec3(nylerp_19));
  detailCoords_18 = tmpvar_35;
  mediump float tmpvar_36;
  tmpvar_36 = abs(detailCoords_18.x);
  highp vec2 coord_37;
  coord_37 = (((0.5 * detailCoords_18.zy) / tmpvar_36) * _DetailScale);
  lowp vec4 tmpvar_38;
  tmpvar_38 = texture2DGradEXT (_DetailTex, coord_37, tmpvar_30.xy, tmpvar_30.zw);
  tmpvar_17 = tmpvar_38;
  color_5 = _SurfaceColor;
  highp float tmpvar_39;
  tmpvar_39 = clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0);
  detailLevel_4 = tmpvar_39;
  color_5.xyz = (color_5.xyz + (0.5 * mix ((tmpvar_17.xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(detailLevel_4))));
  highp float tmpvar_40;
  tmpvar_40 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  handoff_3 = tmpvar_40;
  color_5.xyz = mix (color_5.xyz, tex_6.xyz, vec3(handoff_3));
  specColor_2.xyz = _SpecColor.xyz;
  specColor_2.w = mix (1.0, tex_6.w, handoff_3);
  highp vec3 tmpvar_41;
  tmpvar_41 = normalize(_WorldSpaceLightPos0).xyz;
  highp vec3 tmpvar_42;
  tmpvar_42 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  highp float tmpvar_43;
  tmpvar_43 = dot (xlv_TEXCOORD3, xlv_TEXCOORD3);
  lowp vec4 tmpvar_44;
  tmpvar_44 = texture2D (_LightTexture0, vec2(tmpvar_43));
  highp float tmpvar_45;
  tmpvar_45 = ((sqrt(dot (xlv_TEXCOORD4, xlv_TEXCOORD4)) * _LightPositionRange.w) * 0.97);
  highp vec4 packDist_46;
  lowp vec4 tmpvar_47;
  tmpvar_47 = textureCube (_ShadowMapTexture, xlv_TEXCOORD4);
  packDist_46 = tmpvar_47;
  highp float tmpvar_48;
  tmpvar_48 = dot (packDist_46, vec4(1.0, 0.00392157, 1.53787e-05, 6.22737e-09));
  highp float tmpvar_49;
  if ((tmpvar_48 < tmpvar_45)) {
    tmpvar_49 = _LightShadowData.x;
  } else {
    tmpvar_49 = 1.0;
  };
  mediump vec3 lightDir_50;
  lightDir_50 = tmpvar_41;
  mediump vec3 viewDir_51;
  viewDir_51 = xlv_TEXCOORD1;
  mediump vec3 normal_52;
  normal_52 = tmpvar_42;
  mediump float atten_53;
  atten_53 = (tmpvar_44.w * tmpvar_49);
  mediump vec4 c_54;
  highp float nh_55;
  mediump vec3 tmpvar_56;
  tmpvar_56 = normalize(lightDir_50);
  lightDir_50 = tmpvar_56;
  mediump vec3 tmpvar_57;
  tmpvar_57 = normalize(viewDir_51);
  viewDir_51 = tmpvar_57;
  mediump float tmpvar_58;
  tmpvar_58 = dot (normal_52, tmpvar_56);
  mediump float tmpvar_59;
  tmpvar_59 = clamp (dot (normalize((tmpvar_56 + tmpvar_57)), normal_52), 0.0, 1.0);
  nh_55 = tmpvar_59;
  highp vec3 tmpvar_60;
  tmpvar_60 = ((((color_5.xyz * _LightColor0.xyz) * tmpvar_58) + ((_LightColor0.xyz * specColor_2.xyz) * (pow (nh_55, (_Shininess * 128.0)) * color_5.w))) * (atten_53 * 4.0));
  c_54.xyz = tmpvar_60;
  c_54.w = (tmpvar_58 * (atten_53 * 4.0));
  color_5.w = mix (1.0, color_5.w, clamp ((c_54.w * 4.0), 0.0, 1.0));
  mediump vec3 arg0_61;
  arg0_61 = (2.0 * color_5.xyz);
  color_5.w = mix (color_5.w, 1.0, clamp ((sqrt(dot (c_54.xyz, c_54.xyz)) - sqrt(dot (arg0_61, arg0_61))), 0.0, 1.0));
  color_5.w = mix (color_5.w, 1.0, handoff_3);
  color_5.xyz = c_54.xyz;
  tmpvar_1 = color_5;
  gl_FragData[0] = tmpvar_1;
}



#endif"
}

SubProgram "gles3 " {
Keywords { "POINT" "SHADOWS_CUBE" }
"!!GLES3#version 300 es


#ifdef VERTEX

#define gl_Vertex _glesVertex
in vec4 _glesVertex;
#define gl_Normal (normalize(_glesNormal))
in vec3 _glesNormal;
#define gl_MultiTexCoord0 _glesMultiTexCoord0
in vec4 _glesMultiTexCoord0;
#define gl_MultiTexCoord1 _glesMultiTexCoord1
in vec4 _glesMultiTexCoord1;

#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 330
struct SurfaceOutput {
    lowp vec3 Albedo;
    lowp vec3 Normal;
    lowp vec3 Emission;
    mediump float Specular;
    lowp float Gloss;
    lowp float Alpha;
};
#line 527
struct v2f {
    highp vec4 pos;
    highp float viewDist;
    highp vec3 viewDir;
    highp vec3 worldPos;
    highp vec3 _LightCoord;
    highp vec3 _ShadowCoord;
    highp vec3 sphereNormal;
};
#line 519
struct appdata_t {
    highp vec4 vertex;
    highp vec3 normal;
    highp vec4 texcoord;
    highp vec4 texcoord2;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform highp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform samplerCube _ShadowMapTexture;
#line 328
uniform sampler2D _LightTexture0;
uniform highp mat4 _LightMatrix0;
#line 340
uniform lowp vec4 _LightColor0;
uniform lowp vec4 _SpecColor;
#line 353
#line 361
#line 375
uniform highp mat4 _MainRotation;
uniform highp mat4 _DetailRotation;
#line 408
#line 412
#line 421
#line 429
#line 438
#line 446
#line 459
#line 471
#line 487
#line 500
uniform lowp vec4 _SurfaceColor;
#line 508
uniform highp float _Shininess;
uniform sampler2D _MainTex;
uniform sampler2D _DetailTex;
uniform highp float _DetailScale;
#line 512
uniform highp float _DetailDist;
uniform highp float _MinLight;
uniform sampler2D _CameraDepthTexture;
uniform highp mat4 _CameraToWorld;
#line 516
uniform highp float _LightPower;
uniform highp float _PlanetOpacity;
uniform highp vec3 _PlanetOrigin;
#line 538
#line 538
v2f vert( in appdata_t v ) {
    v2f o;
    highp vec4 vertex = v.vertex;
    #line 542
    o.pos = (glstate_matrix_mvp * vertex).xyzw;
    highp vec3 vertexPos = (_Object2World * vertex).xyz;
    o.viewDist = distance( vertexPos, _WorldSpaceCameraPos);
    o.worldPos = vertexPos;
    #line 546
    o.sphereNormal = (-normalize(vec4( v.texcoord.x, v.texcoord.y, v.texcoord2.x, v.texcoord2.y)).xyz);
    o.viewDir = normalize((_WorldSpaceCameraPos.xyz - vertexPos));
    o._LightCoord = (_LightMatrix0 * (_Object2World * v.vertex)).xyz;
    o._ShadowCoord = ((_Object2World * v.vertex).xyz - _LightPositionRange.xyz);
    #line 551
    return o;
}
out highp float xlv_TEXCOORD0;
out highp vec3 xlv_TEXCOORD1;
out highp vec3 xlv_TEXCOORD2;
out highp vec3 xlv_TEXCOORD3;
out highp vec3 xlv_TEXCOORD4;
out highp vec3 xlv_TEXCOORD5;
void main() {
    v2f xl_retval;
    appdata_t xlt_v;
    xlt_v.vertex = vec4(gl_Vertex);
    xlt_v.normal = vec3(gl_Normal);
    xlt_v.texcoord = vec4(gl_MultiTexCoord0);
    xlt_v.texcoord2 = vec4(gl_MultiTexCoord1);
    xl_retval = vert( xlt_v);
    gl_Position = vec4(xl_retval.pos);
    xlv_TEXCOORD0 = float(xl_retval.viewDist);
    xlv_TEXCOORD1 = vec3(xl_retval.viewDir);
    xlv_TEXCOORD2 = vec3(xl_retval.worldPos);
    xlv_TEXCOORD3 = vec3(xl_retval._LightCoord);
    xlv_TEXCOORD4 = vec3(xl_retval._ShadowCoord);
    xlv_TEXCOORD5 = vec3(xl_retval.sphereNormal);
}


#endif
#ifdef FRAGMENT

#define gl_FragData _glesFragData
layout(location = 0) out mediump vec4 _glesFragData[4];
float xll_dFdx_f(float f) {
  return dFdx(f);
}
vec2 xll_dFdx_vf2(vec2 v) {
  return dFdx(v);
}
vec3 xll_dFdx_vf3(vec3 v) {
  return dFdx(v);
}
vec4 xll_dFdx_vf4(vec4 v) {
  return dFdx(v);
}
mat2 xll_dFdx_mf2x2(mat2 m) {
  return mat2( dFdx(m[0]), dFdx(m[1]));
}
mat3 xll_dFdx_mf3x3(mat3 m) {
  return mat3( dFdx(m[0]), dFdx(m[1]), dFdx(m[2]));
}
mat4 xll_dFdx_mf4x4(mat4 m) {
  return mat4( dFdx(m[0]), dFdx(m[1]), dFdx(m[2]), dFdx(m[3]));
}
float xll_dFdy_f(float f) {
  return dFdy(f);
}
vec2 xll_dFdy_vf2(vec2 v) {
  return dFdy(v);
}
vec3 xll_dFdy_vf3(vec3 v) {
  return dFdy(v);
}
vec4 xll_dFdy_vf4(vec4 v) {
  return dFdy(v);
}
mat2 xll_dFdy_mf2x2(mat2 m) {
  return mat2( dFdy(m[0]), dFdy(m[1]));
}
mat3 xll_dFdy_mf3x3(mat3 m) {
  return mat3( dFdy(m[0]), dFdy(m[1]), dFdy(m[2]));
}
mat4 xll_dFdy_mf4x4(mat4 m) {
  return mat4( dFdy(m[0]), dFdy(m[1]), dFdy(m[2]), dFdy(m[3]));
}
vec4 xll_tex2Dgrad(sampler2D s, vec2 coord, vec2 ddx, vec2 ddy) {
   return textureGrad( s, coord, ddx, ddy);
}
float xll_saturate_f( float x) {
  return clamp( x, 0.0, 1.0);
}
vec2 xll_saturate_vf2( vec2 x) {
  return clamp( x, 0.0, 1.0);
}
vec3 xll_saturate_vf3( vec3 x) {
  return clamp( x, 0.0, 1.0);
}
vec4 xll_saturate_vf4( vec4 x) {
  return clamp( x, 0.0, 1.0);
}
mat2 xll_saturate_mf2x2(mat2 m) {
  return mat2( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0));
}
mat3 xll_saturate_mf3x3(mat3 m) {
  return mat3( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0));
}
mat4 xll_saturate_mf4x4(mat4 m) {
  return mat4( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0), clamp(m[3], 0.0, 1.0));
}
#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 330
struct SurfaceOutput {
    lowp vec3 Albedo;
    lowp vec3 Normal;
    lowp vec3 Emission;
    mediump float Specular;
    lowp float Gloss;
    lowp float Alpha;
};
#line 527
struct v2f {
    highp vec4 pos;
    highp float viewDist;
    highp vec3 viewDir;
    highp vec3 worldPos;
    highp vec3 _LightCoord;
    highp vec3 _ShadowCoord;
    highp vec3 sphereNormal;
};
#line 519
struct appdata_t {
    highp vec4 vertex;
    highp vec3 normal;
    highp vec4 texcoord;
    highp vec4 texcoord2;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform highp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform samplerCube _ShadowMapTexture;
#line 328
uniform sampler2D _LightTexture0;
uniform highp mat4 _LightMatrix0;
#line 340
uniform lowp vec4 _LightColor0;
uniform lowp vec4 _SpecColor;
#line 353
#line 361
#line 375
uniform highp mat4 _MainRotation;
uniform highp mat4 _DetailRotation;
#line 408
#line 412
#line 421
#line 429
#line 438
#line 446
#line 459
#line 471
#line 487
#line 500
uniform lowp vec4 _SurfaceColor;
#line 508
uniform highp float _Shininess;
uniform sampler2D _MainTex;
uniform sampler2D _DetailTex;
uniform highp float _DetailScale;
#line 512
uniform highp float _DetailDist;
uniform highp float _MinLight;
uniform sampler2D _CameraDepthTexture;
uniform highp mat4 _CameraToWorld;
#line 516
uniform highp float _LightPower;
uniform highp float _PlanetOpacity;
uniform highp vec3 _PlanetOrigin;
#line 538
#line 412
highp vec4 Derivatives( in highp float lat, in highp float lon, in highp vec3 pos ) {
    highp vec2 latLong = vec2( lat, lon);
    highp float latDdx = (0.159155 * length(xll_dFdx_vf2(pos.xz)));
    #line 416
    highp float latDdy = (0.159155 * length(xll_dFdy_vf2(pos.xz)));
    highp float longDdx = xll_dFdx_f(lon);
    highp float longDdy = xll_dFdy_f(lon);
    return vec4( latDdx, longDdx, latDdy, longDdy);
}
#line 421
highp vec2 GetSphereUV( in highp vec3 sphereVect, in highp vec2 uvOffset ) {
    highp vec2 uv;
    uv.x = (0.5 + (0.159155 * atan( sphereVect.x, sphereVect.z)));
    #line 425
    uv.y = (0.31831 * acos(sphereVect.y));
    uv += uvOffset;
    return uv;
}
#line 459
mediump vec4 GetShereDetailMap( in sampler2D texSampler, in highp vec3 sphereVect, in highp float detailScale ) {
    highp vec3 sphereVectNorm = normalize(sphereVect);
    highp vec2 uv = ((GetSphereUV( sphereVectNorm, vec2( 0.0, 0.0)) * 4.0) * detailScale);
    #line 463
    highp vec4 uvdd = Derivatives( (uv.x - 0.5), uv.y, sphereVectNorm);
    sphereVectNorm = abs(sphereVectNorm);
    mediump float zxlerp = step( sphereVectNorm.x, sphereVectNorm.z);
    mediump float nylerp = step( sphereVectNorm.y, mix( sphereVectNorm.x, sphereVectNorm.z, zxlerp));
    #line 467
    mediump vec3 detailCoords = mix( sphereVectNorm.xyz, sphereVectNorm.zxy, vec3( zxlerp));
    detailCoords = mix( sphereVectNorm.yxz, detailCoords, vec3( nylerp));
    return xll_tex2Dgrad( texSampler, (((0.5 * detailCoords.zy) / abs(detailCoords.x)) * detailScale), uvdd.xy, uvdd.zw);
}
#line 438
mediump vec4 GetSphereMap( in sampler2D texSampler, in highp vec3 sphereVect ) {
    highp vec3 sphereVectNorm = normalize(sphereVect);
    highp vec2 uv = GetSphereUV( sphereVectNorm, vec2( 0.0, 0.0));
    #line 442
    highp vec4 uvdd = Derivatives( (uv.x - 0.5), uv.y, sphereVectNorm);
    mediump vec4 tex = xll_tex2Dgrad( texSampler, uv, uvdd.xy, uvdd.zw);
    return tex;
}
#line 487
mediump vec4 SpecularColorLight( in mediump vec3 lightDir, in mediump vec3 viewDir, in mediump vec3 normal, in mediump vec4 color, in mediump vec4 specColor, in highp float specK, in mediump float atten ) {
    lightDir = normalize(lightDir);
    viewDir = normalize(viewDir);
    #line 491
    mediump vec3 h = normalize((lightDir + viewDir));
    mediump float diffuse = dot( normal, lightDir);
    highp float nh = xll_saturate_f(dot( h, normal));
    highp float spec = (pow( nh, specK) * color.w);
    #line 495
    mediump vec4 c;
    c.xyz = ((((color.xyz * _LightColor0.xyz) * diffuse) + ((_LightColor0.xyz * specColor.xyz) * spec)) * (atten * 4.0));
    c.w = (diffuse * (atten * 4.0));
    return c;
}
#line 215
highp float DecodeFloatRGBA( in highp vec4 enc ) {
    highp vec4 kDecodeDot = vec4( 1.0, 0.00392157, 1.53787e-05, 6.22737e-09);
    return dot( enc, kDecodeDot);
}
#line 316
highp float SampleCubeDistance( in highp vec3 vec ) {
    highp vec4 packDist = texture( _ShadowMapTexture, vec);
    #line 319
    return DecodeFloatRGBA( packDist);
}
#line 321
highp float unityCubeShadow( in highp vec3 vec ) {
    #line 323
    highp float mydist = (length(vec) * _LightPositionRange.w);
    mydist *= 0.97;
    highp float dist = SampleCubeDistance( vec);
    return (( (dist < mydist) ) ? ( _LightShadowData.x ) : ( 1.0 ));
}
#line 553
lowp vec4 frag( in v2f IN ) {
    #line 555
    mediump vec4 color;
    highp vec3 sphereNrm = IN.sphereNormal;
    mediump vec4 main = GetSphereMap( _MainTex, sphereNrm);
    mediump vec4 detail = GetShereDetailMap( _DetailTex, sphereNrm, _DetailScale);
    #line 559
    color = _SurfaceColor;
    mediump float detailLevel = xll_saturate_f(((2.0 * _DetailDist) * IN.viewDist));
    color.xyz += (0.5 * mix( (detail.xyz - 0.5), vec3( 0.0), vec3( detailLevel)));
    mediump float handoff = xll_saturate_f(pow( _PlanetOpacity, 2.0));
    #line 563
    color.xyz = mix( color.xyz, main.xyz, vec3( handoff));
    mediump vec4 specColor = _SpecColor;
    specColor.w = mix( 1.0, main.w, handoff);
    mediump vec4 colorLight = SpecularColorLight( vec3( normalize(_WorldSpaceLightPos0)), IN.viewDir, normalize((IN.worldPos - _PlanetOrigin)), color, specColor, (_Shininess * 128.0), (texture( _LightTexture0, vec2( dot( IN._LightCoord, IN._LightCoord))).w * unityCubeShadow( IN._ShadowCoord)));
    #line 567
    color.w = mix( 1.0, color.w, xll_saturate_f((colorLight.w * 4.0)));
    color.w = mix( color.w, 1.0, xll_saturate_f((length(colorLight.xyz) - length((2.0 * color.xyz)))));
    color.w = mix( color.w, 1.0, handoff);
    color.xyz = colorLight.xyz;
    #line 571
    return color;
}
in highp float xlv_TEXCOORD0;
in highp vec3 xlv_TEXCOORD1;
in highp vec3 xlv_TEXCOORD2;
in highp vec3 xlv_TEXCOORD3;
in highp vec3 xlv_TEXCOORD4;
in highp vec3 xlv_TEXCOORD5;
void main() {
    lowp vec4 xl_retval;
    v2f xlt_IN;
    xlt_IN.pos = vec4(0.0);
    xlt_IN.viewDist = float(xlv_TEXCOORD0);
    xlt_IN.viewDir = vec3(xlv_TEXCOORD1);
    xlt_IN.worldPos = vec3(xlv_TEXCOORD2);
    xlt_IN._LightCoord = vec3(xlv_TEXCOORD3);
    xlt_IN._ShadowCoord = vec3(xlv_TEXCOORD4);
    xlt_IN.sphereNormal = vec3(xlv_TEXCOORD5);
    xl_retval = frag( xlt_IN);
    gl_FragData[0] = vec4(xl_retval);
}


#endif"
}

SubProgram "opengl " {
Keywords { "POINT_COOKIE" "SHADOWS_CUBE" }
"!!GLSL
#ifdef VERTEX
varying vec3 xlv_TEXCOORD5;
varying vec3 xlv_TEXCOORD4;
varying vec3 xlv_TEXCOORD3;
varying vec3 xlv_TEXCOORD2;
varying vec3 xlv_TEXCOORD1;
varying float xlv_TEXCOORD0;
uniform mat4 _LightMatrix0;
uniform mat4 _Object2World;

uniform vec4 _LightPositionRange;
uniform vec3 _WorldSpaceCameraPos;
void main ()
{
  vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * gl_Vertex).xyz;
  vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  vec4 tmpvar_3;
  tmpvar_3.x = gl_MultiTexCoord0.x;
  tmpvar_3.y = gl_MultiTexCoord0.y;
  tmpvar_3.z = gl_MultiTexCoord1.x;
  tmpvar_3.w = gl_MultiTexCoord1.y;
  gl_Position = (gl_ModelViewProjectionMatrix * gl_Vertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * gl_Vertex)).xyz;
  xlv_TEXCOORD4 = ((_Object2World * gl_Vertex).xyz - _LightPositionRange.xyz);
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}


#endif
#ifdef FRAGMENT
#extension GL_ARB_shader_texture_lod : enable
varying vec3 xlv_TEXCOORD5;
varying vec3 xlv_TEXCOORD4;
varying vec3 xlv_TEXCOORD3;
varying vec3 xlv_TEXCOORD2;
varying vec3 xlv_TEXCOORD1;
varying float xlv_TEXCOORD0;
uniform vec3 _PlanetOrigin;
uniform float _PlanetOpacity;
uniform float _DetailDist;
uniform float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform float _Shininess;
uniform vec4 _SurfaceColor;
uniform vec4 _SpecColor;
uniform vec4 _LightColor0;
uniform sampler2D _LightTextureB0;
uniform samplerCube _LightTexture0;
uniform samplerCube _ShadowMapTexture;
uniform vec4 _LightShadowData;
uniform vec4 _LightPositionRange;
uniform vec4 _WorldSpaceLightPos0;
void main ()
{
  vec4 main_1;
  vec4 color_2;
  vec3 tmpvar_3;
  tmpvar_3 = normalize(xlv_TEXCOORD5);
  vec2 uv_4;
  float r_5;
  if ((abs(tmpvar_3.z) > (1e-08 * abs(tmpvar_3.x)))) {
    float y_over_x_6;
    y_over_x_6 = (tmpvar_3.x / tmpvar_3.z);
    float s_7;
    float x_8;
    x_8 = (y_over_x_6 * inversesqrt(((y_over_x_6 * y_over_x_6) + 1.0)));
    s_7 = (sign(x_8) * (1.5708 - (sqrt((1.0 - abs(x_8))) * (1.5708 + (abs(x_8) * (-0.214602 + (abs(x_8) * (0.0865667 + (abs(x_8) * -0.0310296)))))))));
    r_5 = s_7;
    if ((tmpvar_3.z < 0.0)) {
      if ((tmpvar_3.x >= 0.0)) {
        r_5 = (s_7 + 3.14159);
      } else {
        r_5 = (r_5 - 3.14159);
      };
    };
  } else {
    r_5 = (sign(tmpvar_3.x) * 1.5708);
  };
  uv_4.x = (0.5 + (0.159155 * r_5));
  uv_4.y = (0.31831 * (1.5708 - (sign(tmpvar_3.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_3.y))) * (1.5708 + (abs(tmpvar_3.y) * (-0.214602 + (abs(tmpvar_3.y) * (0.0865667 + (abs(tmpvar_3.y) * -0.0310296)))))))))));
  vec2 tmpvar_9;
  tmpvar_9 = dFdx(tmpvar_3.xz);
  vec2 tmpvar_10;
  tmpvar_10 = dFdy(tmpvar_3.xz);
  vec4 tmpvar_11;
  tmpvar_11.x = (0.159155 * sqrt(dot (tmpvar_9, tmpvar_9)));
  tmpvar_11.y = dFdx(uv_4.y);
  tmpvar_11.z = (0.159155 * sqrt(dot (tmpvar_10, tmpvar_10)));
  tmpvar_11.w = dFdy(uv_4.y);
  main_1 = texture2DGradARB (_MainTex, uv_4, tmpvar_11.xy, tmpvar_11.zw);
  vec3 tmpvar_12;
  tmpvar_12 = normalize(xlv_TEXCOORD5);
  vec2 uv_13;
  float r_14;
  if ((abs(tmpvar_12.z) > (1e-08 * abs(tmpvar_12.x)))) {
    float y_over_x_15;
    y_over_x_15 = (tmpvar_12.x / tmpvar_12.z);
    float s_16;
    float x_17;
    x_17 = (y_over_x_15 * inversesqrt(((y_over_x_15 * y_over_x_15) + 1.0)));
    s_16 = (sign(x_17) * (1.5708 - (sqrt((1.0 - abs(x_17))) * (1.5708 + (abs(x_17) * (-0.214602 + (abs(x_17) * (0.0865667 + (abs(x_17) * -0.0310296)))))))));
    r_14 = s_16;
    if ((tmpvar_12.z < 0.0)) {
      if ((tmpvar_12.x >= 0.0)) {
        r_14 = (s_16 + 3.14159);
      } else {
        r_14 = (r_14 - 3.14159);
      };
    };
  } else {
    r_14 = (sign(tmpvar_12.x) * 1.5708);
  };
  uv_13.x = (0.5 + (0.159155 * r_14));
  uv_13.y = (0.31831 * (1.5708 - (sign(tmpvar_12.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_12.y))) * (1.5708 + (abs(tmpvar_12.y) * (-0.214602 + (abs(tmpvar_12.y) * (0.0865667 + (abs(tmpvar_12.y) * -0.0310296)))))))))));
  vec2 tmpvar_18;
  tmpvar_18 = ((uv_13 * 4.0) * _DetailScale);
  vec2 tmpvar_19;
  tmpvar_19 = dFdx(tmpvar_12.xz);
  vec2 tmpvar_20;
  tmpvar_20 = dFdy(tmpvar_12.xz);
  vec4 tmpvar_21;
  tmpvar_21.x = (0.159155 * sqrt(dot (tmpvar_19, tmpvar_19)));
  tmpvar_21.y = dFdx(tmpvar_18.y);
  tmpvar_21.z = (0.159155 * sqrt(dot (tmpvar_20, tmpvar_20)));
  tmpvar_21.w = dFdy(tmpvar_18.y);
  vec3 tmpvar_22;
  tmpvar_22 = abs(tmpvar_12);
  float tmpvar_23;
  tmpvar_23 = float((tmpvar_22.z >= tmpvar_22.x));
  vec3 tmpvar_24;
  tmpvar_24 = mix (tmpvar_22.yxz, mix (tmpvar_22, tmpvar_22.zxy, vec3(tmpvar_23)), vec3(float((mix (tmpvar_22.x, tmpvar_22.z, tmpvar_23) >= tmpvar_22.y))));
  color_2.w = _SurfaceColor.w;
  color_2.xyz = (_SurfaceColor.xyz + (0.5 * mix ((texture2DGradARB (_DetailTex, (((0.5 * tmpvar_24.zy) / abs(tmpvar_24.x)) * _DetailScale), tmpvar_21.xy, tmpvar_21.zw).xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0)))));
  float tmpvar_25;
  tmpvar_25 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  color_2.xyz = mix (color_2.xyz, main_1.xyz, vec3(tmpvar_25));
  vec4 tmpvar_26;
  tmpvar_26 = normalize(_WorldSpaceLightPos0);
  vec3 tmpvar_27;
  tmpvar_27 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  vec4 tmpvar_28;
  tmpvar_28 = texture2D (_LightTextureB0, vec2(dot (xlv_TEXCOORD3, xlv_TEXCOORD3)));
  vec4 tmpvar_29;
  tmpvar_29 = textureCube (_LightTexture0, xlv_TEXCOORD3);
  float tmpvar_30;
  tmpvar_30 = ((sqrt(dot (xlv_TEXCOORD4, xlv_TEXCOORD4)) * _LightPositionRange.w) * 0.97);
  float tmpvar_31;
  tmpvar_31 = dot (textureCube (_ShadowMapTexture, xlv_TEXCOORD4), vec4(1.0, 0.00392157, 1.53787e-05, 6.22737e-09));
  float tmpvar_32;
  if ((tmpvar_31 < tmpvar_30)) {
    tmpvar_32 = _LightShadowData.x;
  } else {
    tmpvar_32 = 1.0;
  };
  float atten_33;
  atten_33 = ((tmpvar_28.w * tmpvar_29.w) * tmpvar_32);
  vec4 c_34;
  vec3 tmpvar_35;
  tmpvar_35 = normalize(tmpvar_26.xyz);
  float tmpvar_36;
  tmpvar_36 = dot (tmpvar_27, tmpvar_35);
  c_34.xyz = ((((color_2.xyz * _LightColor0.xyz) * tmpvar_36) + ((_LightColor0.xyz * _SpecColor.xyz) * (pow (clamp (dot (normalize((tmpvar_35 + normalize(xlv_TEXCOORD1))), tmpvar_27), 0.0, 1.0), (_Shininess * 128.0)) * _SurfaceColor.w))) * (atten_33 * 4.0));
  c_34.w = (tmpvar_36 * (atten_33 * 4.0));
  color_2.w = mix (1.0, _SurfaceColor.w, clamp ((c_34.w * 4.0), 0.0, 1.0));
  vec3 arg0_37;
  arg0_37 = (2.0 * color_2.xyz);
  color_2.w = mix (color_2.w, 1.0, clamp ((sqrt(dot (c_34.xyz, c_34.xyz)) - sqrt(dot (arg0_37, arg0_37))), 0.0, 1.0));
  color_2.w = mix (color_2.w, 1.0, tmpvar_25);
  color_2.xyz = c_34.xyz;
  gl_FragData[0] = color_2;
}


#endif
"
}

SubProgram "d3d9 " {
Keywords { "POINT_COOKIE" "SHADOWS_CUBE" }
Bind "vertex" Vertex
Bind "texcoord" TexCoord0
Bind "texcoord1" TexCoord1
Matrix 0 [glstate_matrix_mvp]
Vector 12 [_WorldSpaceCameraPos]
Vector 13 [_LightPositionRange]
Matrix 4 [_Object2World]
Matrix 8 [_LightMatrix0]
"vs_3_0
; 25 ALU
dcl_position o0
dcl_texcoord0 o1
dcl_texcoord1 o2
dcl_texcoord2 o3
dcl_texcoord3 o4
dcl_texcoord4 o5
dcl_texcoord5 o6
dcl_position0 v0
dcl_texcoord0 v1
dcl_texcoord1 v2
dp4 r1.z, v0, c6
dp4 r1.x, v0, c4
dp4 r1.y, v0, c5
mov r0.zw, v2.xyxy
mov r0.xy, v1
dp4 r0.w, r0, r0
rsq r1.w, r0.w
mul r0.xyz, r1.w, r0
add r2.xyz, -r1, c12
dp3 r0.w, r2, r2
rsq r1.w, r0.w
mov o6.xyz, -r0
mov r0.xyz, r1
dp4 r0.w, v0, c7
mul o2.xyz, r1.w, r2
dp4 o4.z, r0, c10
dp4 o4.y, r0, c9
dp4 o4.x, r0, c8
rcp o1.x, r1.w
mov o3.xyz, r1
add o5.xyz, r1, -c13
dp4 o0.w, v0, c3
dp4 o0.z, v0, c2
dp4 o0.y, v0, c1
dp4 o0.x, v0, c0
"
}

SubProgram "gles " {
Keywords { "POINT_COOKIE" "SHADOWS_CUBE" }
"!!GLES


#ifdef VERTEX

varying highp vec3 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD4;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp mat4 _LightMatrix0;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_mvp;
uniform highp vec4 _LightPositionRange;
uniform highp vec3 _WorldSpaceCameraPos;
attribute vec4 _glesMultiTexCoord1;
attribute vec4 _glesMultiTexCoord0;
attribute vec4 _glesVertex;
void main ()
{
  highp vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * _glesVertex).xyz;
  highp vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  highp vec4 tmpvar_3;
  tmpvar_3.x = _glesMultiTexCoord0.x;
  tmpvar_3.y = _glesMultiTexCoord0.y;
  tmpvar_3.z = _glesMultiTexCoord1.x;
  tmpvar_3.w = _glesMultiTexCoord1.y;
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * _glesVertex)).xyz;
  xlv_TEXCOORD4 = ((_Object2World * _glesVertex).xyz - _LightPositionRange.xyz);
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}



#endif
#ifdef FRAGMENT

#extension GL_EXT_shader_texture_lod : enable
#extension GL_OES_standard_derivatives : enable
varying highp vec3 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD4;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp vec3 _PlanetOrigin;
uniform highp float _PlanetOpacity;
uniform highp float _DetailDist;
uniform highp float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform highp float _Shininess;
uniform lowp vec4 _SurfaceColor;
uniform lowp vec4 _SpecColor;
uniform lowp vec4 _LightColor0;
uniform sampler2D _LightTextureB0;
uniform samplerCube _LightTexture0;
uniform samplerCube _ShadowMapTexture;
uniform highp vec4 _LightShadowData;
uniform highp vec4 _LightPositionRange;
uniform highp vec4 _WorldSpaceLightPos0;
void main ()
{
  lowp vec4 tmpvar_1;
  mediump vec4 specColor_2;
  mediump float handoff_3;
  mediump float detailLevel_4;
  mediump vec4 color_5;
  mediump vec4 tex_6;
  highp vec3 tmpvar_7;
  tmpvar_7 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_8;
  highp float r_9;
  if ((abs(tmpvar_7.z) > (1e-08 * abs(tmpvar_7.x)))) {
    highp float y_over_x_10;
    y_over_x_10 = (tmpvar_7.x / tmpvar_7.z);
    highp float s_11;
    highp float x_12;
    x_12 = (y_over_x_10 * inversesqrt(((y_over_x_10 * y_over_x_10) + 1.0)));
    s_11 = (sign(x_12) * (1.5708 - (sqrt((1.0 - abs(x_12))) * (1.5708 + (abs(x_12) * (-0.214602 + (abs(x_12) * (0.0865667 + (abs(x_12) * -0.0310296)))))))));
    r_9 = s_11;
    if ((tmpvar_7.z < 0.0)) {
      if ((tmpvar_7.x >= 0.0)) {
        r_9 = (s_11 + 3.14159);
      } else {
        r_9 = (r_9 - 3.14159);
      };
    };
  } else {
    r_9 = (sign(tmpvar_7.x) * 1.5708);
  };
  uv_8.x = (0.5 + (0.159155 * r_9));
  uv_8.y = (0.31831 * (1.5708 - (sign(tmpvar_7.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_7.y))) * (1.5708 + (abs(tmpvar_7.y) * (-0.214602 + (abs(tmpvar_7.y) * (0.0865667 + (abs(tmpvar_7.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_13;
  tmpvar_13 = dFdx(tmpvar_7.xz);
  highp vec2 tmpvar_14;
  tmpvar_14 = dFdy(tmpvar_7.xz);
  highp vec4 tmpvar_15;
  tmpvar_15.x = (0.159155 * sqrt(dot (tmpvar_13, tmpvar_13)));
  tmpvar_15.y = dFdx(uv_8.y);
  tmpvar_15.z = (0.159155 * sqrt(dot (tmpvar_14, tmpvar_14)));
  tmpvar_15.w = dFdy(uv_8.y);
  lowp vec4 tmpvar_16;
  tmpvar_16 = texture2DGradEXT (_MainTex, uv_8, tmpvar_15.xy, tmpvar_15.zw);
  tex_6 = tmpvar_16;
  mediump vec4 tmpvar_17;
  mediump vec3 detailCoords_18;
  mediump float nylerp_19;
  mediump float zxlerp_20;
  highp vec3 tmpvar_21;
  tmpvar_21 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_22;
  highp float r_23;
  if ((abs(tmpvar_21.z) > (1e-08 * abs(tmpvar_21.x)))) {
    highp float y_over_x_24;
    y_over_x_24 = (tmpvar_21.x / tmpvar_21.z);
    highp float s_25;
    highp float x_26;
    x_26 = (y_over_x_24 * inversesqrt(((y_over_x_24 * y_over_x_24) + 1.0)));
    s_25 = (sign(x_26) * (1.5708 - (sqrt((1.0 - abs(x_26))) * (1.5708 + (abs(x_26) * (-0.214602 + (abs(x_26) * (0.0865667 + (abs(x_26) * -0.0310296)))))))));
    r_23 = s_25;
    if ((tmpvar_21.z < 0.0)) {
      if ((tmpvar_21.x >= 0.0)) {
        r_23 = (s_25 + 3.14159);
      } else {
        r_23 = (r_23 - 3.14159);
      };
    };
  } else {
    r_23 = (sign(tmpvar_21.x) * 1.5708);
  };
  uv_22.x = (0.5 + (0.159155 * r_23));
  uv_22.y = (0.31831 * (1.5708 - (sign(tmpvar_21.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_21.y))) * (1.5708 + (abs(tmpvar_21.y) * (-0.214602 + (abs(tmpvar_21.y) * (0.0865667 + (abs(tmpvar_21.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_27;
  tmpvar_27 = ((uv_22 * 4.0) * _DetailScale);
  highp vec2 tmpvar_28;
  tmpvar_28 = dFdx(tmpvar_21.xz);
  highp vec2 tmpvar_29;
  tmpvar_29 = dFdy(tmpvar_21.xz);
  highp vec4 tmpvar_30;
  tmpvar_30.x = (0.159155 * sqrt(dot (tmpvar_28, tmpvar_28)));
  tmpvar_30.y = dFdx(tmpvar_27.y);
  tmpvar_30.z = (0.159155 * sqrt(dot (tmpvar_29, tmpvar_29)));
  tmpvar_30.w = dFdy(tmpvar_27.y);
  highp vec3 tmpvar_31;
  tmpvar_31 = abs(tmpvar_21);
  highp float tmpvar_32;
  tmpvar_32 = float((tmpvar_31.z >= tmpvar_31.x));
  zxlerp_20 = tmpvar_32;
  highp float tmpvar_33;
  tmpvar_33 = float((mix (tmpvar_31.x, tmpvar_31.z, zxlerp_20) >= tmpvar_31.y));
  nylerp_19 = tmpvar_33;
  highp vec3 tmpvar_34;
  tmpvar_34 = mix (tmpvar_31, tmpvar_31.zxy, vec3(zxlerp_20));
  detailCoords_18 = tmpvar_34;
  highp vec3 tmpvar_35;
  tmpvar_35 = mix (tmpvar_31.yxz, detailCoords_18, vec3(nylerp_19));
  detailCoords_18 = tmpvar_35;
  mediump float tmpvar_36;
  tmpvar_36 = abs(detailCoords_18.x);
  highp vec2 coord_37;
  coord_37 = (((0.5 * detailCoords_18.zy) / tmpvar_36) * _DetailScale);
  lowp vec4 tmpvar_38;
  tmpvar_38 = texture2DGradEXT (_DetailTex, coord_37, tmpvar_30.xy, tmpvar_30.zw);
  tmpvar_17 = tmpvar_38;
  color_5 = _SurfaceColor;
  highp float tmpvar_39;
  tmpvar_39 = clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0);
  detailLevel_4 = tmpvar_39;
  color_5.xyz = (color_5.xyz + (0.5 * mix ((tmpvar_17.xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(detailLevel_4))));
  highp float tmpvar_40;
  tmpvar_40 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  handoff_3 = tmpvar_40;
  color_5.xyz = mix (color_5.xyz, tex_6.xyz, vec3(handoff_3));
  specColor_2.xyz = _SpecColor.xyz;
  specColor_2.w = mix (1.0, tex_6.w, handoff_3);
  highp vec3 tmpvar_41;
  tmpvar_41 = normalize(_WorldSpaceLightPos0).xyz;
  highp vec3 tmpvar_42;
  tmpvar_42 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  highp float tmpvar_43;
  tmpvar_43 = dot (xlv_TEXCOORD3, xlv_TEXCOORD3);
  lowp vec4 tmpvar_44;
  tmpvar_44 = texture2D (_LightTextureB0, vec2(tmpvar_43));
  lowp vec4 tmpvar_45;
  tmpvar_45 = textureCube (_LightTexture0, xlv_TEXCOORD3);
  highp float tmpvar_46;
  tmpvar_46 = ((sqrt(dot (xlv_TEXCOORD4, xlv_TEXCOORD4)) * _LightPositionRange.w) * 0.97);
  highp vec4 packDist_47;
  lowp vec4 tmpvar_48;
  tmpvar_48 = textureCube (_ShadowMapTexture, xlv_TEXCOORD4);
  packDist_47 = tmpvar_48;
  highp float tmpvar_49;
  tmpvar_49 = dot (packDist_47, vec4(1.0, 0.00392157, 1.53787e-05, 6.22737e-09));
  highp float tmpvar_50;
  if ((tmpvar_49 < tmpvar_46)) {
    tmpvar_50 = _LightShadowData.x;
  } else {
    tmpvar_50 = 1.0;
  };
  mediump vec3 lightDir_51;
  lightDir_51 = tmpvar_41;
  mediump vec3 viewDir_52;
  viewDir_52 = xlv_TEXCOORD1;
  mediump vec3 normal_53;
  normal_53 = tmpvar_42;
  mediump float atten_54;
  atten_54 = ((tmpvar_44.w * tmpvar_45.w) * tmpvar_50);
  mediump vec4 c_55;
  highp float nh_56;
  mediump vec3 tmpvar_57;
  tmpvar_57 = normalize(lightDir_51);
  lightDir_51 = tmpvar_57;
  mediump vec3 tmpvar_58;
  tmpvar_58 = normalize(viewDir_52);
  viewDir_52 = tmpvar_58;
  mediump float tmpvar_59;
  tmpvar_59 = dot (normal_53, tmpvar_57);
  mediump float tmpvar_60;
  tmpvar_60 = clamp (dot (normalize((tmpvar_57 + tmpvar_58)), normal_53), 0.0, 1.0);
  nh_56 = tmpvar_60;
  highp vec3 tmpvar_61;
  tmpvar_61 = ((((color_5.xyz * _LightColor0.xyz) * tmpvar_59) + ((_LightColor0.xyz * specColor_2.xyz) * (pow (nh_56, (_Shininess * 128.0)) * color_5.w))) * (atten_54 * 4.0));
  c_55.xyz = tmpvar_61;
  c_55.w = (tmpvar_59 * (atten_54 * 4.0));
  color_5.w = mix (1.0, color_5.w, clamp ((c_55.w * 4.0), 0.0, 1.0));
  mediump vec3 arg0_62;
  arg0_62 = (2.0 * color_5.xyz);
  color_5.w = mix (color_5.w, 1.0, clamp ((sqrt(dot (c_55.xyz, c_55.xyz)) - sqrt(dot (arg0_62, arg0_62))), 0.0, 1.0));
  color_5.w = mix (color_5.w, 1.0, handoff_3);
  color_5.xyz = c_55.xyz;
  tmpvar_1 = color_5;
  gl_FragData[0] = tmpvar_1;
}



#endif"
}

SubProgram "glesdesktop " {
Keywords { "POINT_COOKIE" "SHADOWS_CUBE" }
"!!GLES


#ifdef VERTEX

varying highp vec3 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD4;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp mat4 _LightMatrix0;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_mvp;
uniform highp vec4 _LightPositionRange;
uniform highp vec3 _WorldSpaceCameraPos;
attribute vec4 _glesMultiTexCoord1;
attribute vec4 _glesMultiTexCoord0;
attribute vec4 _glesVertex;
void main ()
{
  highp vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * _glesVertex).xyz;
  highp vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  highp vec4 tmpvar_3;
  tmpvar_3.x = _glesMultiTexCoord0.x;
  tmpvar_3.y = _glesMultiTexCoord0.y;
  tmpvar_3.z = _glesMultiTexCoord1.x;
  tmpvar_3.w = _glesMultiTexCoord1.y;
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * _glesVertex)).xyz;
  xlv_TEXCOORD4 = ((_Object2World * _glesVertex).xyz - _LightPositionRange.xyz);
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}



#endif
#ifdef FRAGMENT

#extension GL_EXT_shader_texture_lod : enable
#extension GL_OES_standard_derivatives : enable
varying highp vec3 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD4;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp vec3 _PlanetOrigin;
uniform highp float _PlanetOpacity;
uniform highp float _DetailDist;
uniform highp float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform highp float _Shininess;
uniform lowp vec4 _SurfaceColor;
uniform lowp vec4 _SpecColor;
uniform lowp vec4 _LightColor0;
uniform sampler2D _LightTextureB0;
uniform samplerCube _LightTexture0;
uniform samplerCube _ShadowMapTexture;
uniform highp vec4 _LightShadowData;
uniform highp vec4 _LightPositionRange;
uniform highp vec4 _WorldSpaceLightPos0;
void main ()
{
  lowp vec4 tmpvar_1;
  mediump vec4 specColor_2;
  mediump float handoff_3;
  mediump float detailLevel_4;
  mediump vec4 color_5;
  mediump vec4 tex_6;
  highp vec3 tmpvar_7;
  tmpvar_7 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_8;
  highp float r_9;
  if ((abs(tmpvar_7.z) > (1e-08 * abs(tmpvar_7.x)))) {
    highp float y_over_x_10;
    y_over_x_10 = (tmpvar_7.x / tmpvar_7.z);
    highp float s_11;
    highp float x_12;
    x_12 = (y_over_x_10 * inversesqrt(((y_over_x_10 * y_over_x_10) + 1.0)));
    s_11 = (sign(x_12) * (1.5708 - (sqrt((1.0 - abs(x_12))) * (1.5708 + (abs(x_12) * (-0.214602 + (abs(x_12) * (0.0865667 + (abs(x_12) * -0.0310296)))))))));
    r_9 = s_11;
    if ((tmpvar_7.z < 0.0)) {
      if ((tmpvar_7.x >= 0.0)) {
        r_9 = (s_11 + 3.14159);
      } else {
        r_9 = (r_9 - 3.14159);
      };
    };
  } else {
    r_9 = (sign(tmpvar_7.x) * 1.5708);
  };
  uv_8.x = (0.5 + (0.159155 * r_9));
  uv_8.y = (0.31831 * (1.5708 - (sign(tmpvar_7.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_7.y))) * (1.5708 + (abs(tmpvar_7.y) * (-0.214602 + (abs(tmpvar_7.y) * (0.0865667 + (abs(tmpvar_7.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_13;
  tmpvar_13 = dFdx(tmpvar_7.xz);
  highp vec2 tmpvar_14;
  tmpvar_14 = dFdy(tmpvar_7.xz);
  highp vec4 tmpvar_15;
  tmpvar_15.x = (0.159155 * sqrt(dot (tmpvar_13, tmpvar_13)));
  tmpvar_15.y = dFdx(uv_8.y);
  tmpvar_15.z = (0.159155 * sqrt(dot (tmpvar_14, tmpvar_14)));
  tmpvar_15.w = dFdy(uv_8.y);
  lowp vec4 tmpvar_16;
  tmpvar_16 = texture2DGradEXT (_MainTex, uv_8, tmpvar_15.xy, tmpvar_15.zw);
  tex_6 = tmpvar_16;
  mediump vec4 tmpvar_17;
  mediump vec3 detailCoords_18;
  mediump float nylerp_19;
  mediump float zxlerp_20;
  highp vec3 tmpvar_21;
  tmpvar_21 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_22;
  highp float r_23;
  if ((abs(tmpvar_21.z) > (1e-08 * abs(tmpvar_21.x)))) {
    highp float y_over_x_24;
    y_over_x_24 = (tmpvar_21.x / tmpvar_21.z);
    highp float s_25;
    highp float x_26;
    x_26 = (y_over_x_24 * inversesqrt(((y_over_x_24 * y_over_x_24) + 1.0)));
    s_25 = (sign(x_26) * (1.5708 - (sqrt((1.0 - abs(x_26))) * (1.5708 + (abs(x_26) * (-0.214602 + (abs(x_26) * (0.0865667 + (abs(x_26) * -0.0310296)))))))));
    r_23 = s_25;
    if ((tmpvar_21.z < 0.0)) {
      if ((tmpvar_21.x >= 0.0)) {
        r_23 = (s_25 + 3.14159);
      } else {
        r_23 = (r_23 - 3.14159);
      };
    };
  } else {
    r_23 = (sign(tmpvar_21.x) * 1.5708);
  };
  uv_22.x = (0.5 + (0.159155 * r_23));
  uv_22.y = (0.31831 * (1.5708 - (sign(tmpvar_21.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_21.y))) * (1.5708 + (abs(tmpvar_21.y) * (-0.214602 + (abs(tmpvar_21.y) * (0.0865667 + (abs(tmpvar_21.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_27;
  tmpvar_27 = ((uv_22 * 4.0) * _DetailScale);
  highp vec2 tmpvar_28;
  tmpvar_28 = dFdx(tmpvar_21.xz);
  highp vec2 tmpvar_29;
  tmpvar_29 = dFdy(tmpvar_21.xz);
  highp vec4 tmpvar_30;
  tmpvar_30.x = (0.159155 * sqrt(dot (tmpvar_28, tmpvar_28)));
  tmpvar_30.y = dFdx(tmpvar_27.y);
  tmpvar_30.z = (0.159155 * sqrt(dot (tmpvar_29, tmpvar_29)));
  tmpvar_30.w = dFdy(tmpvar_27.y);
  highp vec3 tmpvar_31;
  tmpvar_31 = abs(tmpvar_21);
  highp float tmpvar_32;
  tmpvar_32 = float((tmpvar_31.z >= tmpvar_31.x));
  zxlerp_20 = tmpvar_32;
  highp float tmpvar_33;
  tmpvar_33 = float((mix (tmpvar_31.x, tmpvar_31.z, zxlerp_20) >= tmpvar_31.y));
  nylerp_19 = tmpvar_33;
  highp vec3 tmpvar_34;
  tmpvar_34 = mix (tmpvar_31, tmpvar_31.zxy, vec3(zxlerp_20));
  detailCoords_18 = tmpvar_34;
  highp vec3 tmpvar_35;
  tmpvar_35 = mix (tmpvar_31.yxz, detailCoords_18, vec3(nylerp_19));
  detailCoords_18 = tmpvar_35;
  mediump float tmpvar_36;
  tmpvar_36 = abs(detailCoords_18.x);
  highp vec2 coord_37;
  coord_37 = (((0.5 * detailCoords_18.zy) / tmpvar_36) * _DetailScale);
  lowp vec4 tmpvar_38;
  tmpvar_38 = texture2DGradEXT (_DetailTex, coord_37, tmpvar_30.xy, tmpvar_30.zw);
  tmpvar_17 = tmpvar_38;
  color_5 = _SurfaceColor;
  highp float tmpvar_39;
  tmpvar_39 = clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0);
  detailLevel_4 = tmpvar_39;
  color_5.xyz = (color_5.xyz + (0.5 * mix ((tmpvar_17.xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(detailLevel_4))));
  highp float tmpvar_40;
  tmpvar_40 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  handoff_3 = tmpvar_40;
  color_5.xyz = mix (color_5.xyz, tex_6.xyz, vec3(handoff_3));
  specColor_2.xyz = _SpecColor.xyz;
  specColor_2.w = mix (1.0, tex_6.w, handoff_3);
  highp vec3 tmpvar_41;
  tmpvar_41 = normalize(_WorldSpaceLightPos0).xyz;
  highp vec3 tmpvar_42;
  tmpvar_42 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  highp float tmpvar_43;
  tmpvar_43 = dot (xlv_TEXCOORD3, xlv_TEXCOORD3);
  lowp vec4 tmpvar_44;
  tmpvar_44 = texture2D (_LightTextureB0, vec2(tmpvar_43));
  lowp vec4 tmpvar_45;
  tmpvar_45 = textureCube (_LightTexture0, xlv_TEXCOORD3);
  highp float tmpvar_46;
  tmpvar_46 = ((sqrt(dot (xlv_TEXCOORD4, xlv_TEXCOORD4)) * _LightPositionRange.w) * 0.97);
  highp vec4 packDist_47;
  lowp vec4 tmpvar_48;
  tmpvar_48 = textureCube (_ShadowMapTexture, xlv_TEXCOORD4);
  packDist_47 = tmpvar_48;
  highp float tmpvar_49;
  tmpvar_49 = dot (packDist_47, vec4(1.0, 0.00392157, 1.53787e-05, 6.22737e-09));
  highp float tmpvar_50;
  if ((tmpvar_49 < tmpvar_46)) {
    tmpvar_50 = _LightShadowData.x;
  } else {
    tmpvar_50 = 1.0;
  };
  mediump vec3 lightDir_51;
  lightDir_51 = tmpvar_41;
  mediump vec3 viewDir_52;
  viewDir_52 = xlv_TEXCOORD1;
  mediump vec3 normal_53;
  normal_53 = tmpvar_42;
  mediump float atten_54;
  atten_54 = ((tmpvar_44.w * tmpvar_45.w) * tmpvar_50);
  mediump vec4 c_55;
  highp float nh_56;
  mediump vec3 tmpvar_57;
  tmpvar_57 = normalize(lightDir_51);
  lightDir_51 = tmpvar_57;
  mediump vec3 tmpvar_58;
  tmpvar_58 = normalize(viewDir_52);
  viewDir_52 = tmpvar_58;
  mediump float tmpvar_59;
  tmpvar_59 = dot (normal_53, tmpvar_57);
  mediump float tmpvar_60;
  tmpvar_60 = clamp (dot (normalize((tmpvar_57 + tmpvar_58)), normal_53), 0.0, 1.0);
  nh_56 = tmpvar_60;
  highp vec3 tmpvar_61;
  tmpvar_61 = ((((color_5.xyz * _LightColor0.xyz) * tmpvar_59) + ((_LightColor0.xyz * specColor_2.xyz) * (pow (nh_56, (_Shininess * 128.0)) * color_5.w))) * (atten_54 * 4.0));
  c_55.xyz = tmpvar_61;
  c_55.w = (tmpvar_59 * (atten_54 * 4.0));
  color_5.w = mix (1.0, color_5.w, clamp ((c_55.w * 4.0), 0.0, 1.0));
  mediump vec3 arg0_62;
  arg0_62 = (2.0 * color_5.xyz);
  color_5.w = mix (color_5.w, 1.0, clamp ((sqrt(dot (c_55.xyz, c_55.xyz)) - sqrt(dot (arg0_62, arg0_62))), 0.0, 1.0));
  color_5.w = mix (color_5.w, 1.0, handoff_3);
  color_5.xyz = c_55.xyz;
  tmpvar_1 = color_5;
  gl_FragData[0] = tmpvar_1;
}



#endif"
}

SubProgram "gles3 " {
Keywords { "POINT_COOKIE" "SHADOWS_CUBE" }
"!!GLES3#version 300 es


#ifdef VERTEX

#define gl_Vertex _glesVertex
in vec4 _glesVertex;
#define gl_Normal (normalize(_glesNormal))
in vec3 _glesNormal;
#define gl_MultiTexCoord0 _glesMultiTexCoord0
in vec4 _glesMultiTexCoord0;
#define gl_MultiTexCoord1 _glesMultiTexCoord1
in vec4 _glesMultiTexCoord1;

#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 331
struct SurfaceOutput {
    lowp vec3 Albedo;
    lowp vec3 Normal;
    lowp vec3 Emission;
    mediump float Specular;
    lowp float Gloss;
    lowp float Alpha;
};
#line 528
struct v2f {
    highp vec4 pos;
    highp float viewDist;
    highp vec3 viewDir;
    highp vec3 worldPos;
    highp vec3 _LightCoord;
    highp vec3 _ShadowCoord;
    highp vec3 sphereNormal;
};
#line 520
struct appdata_t {
    highp vec4 vertex;
    highp vec3 normal;
    highp vec4 texcoord;
    highp vec4 texcoord2;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform highp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform samplerCube _ShadowMapTexture;
#line 328
uniform samplerCube _LightTexture0;
uniform highp mat4 _LightMatrix0;
uniform sampler2D _LightTextureB0;
#line 341
uniform lowp vec4 _LightColor0;
uniform lowp vec4 _SpecColor;
#line 354
#line 362
#line 376
uniform highp mat4 _MainRotation;
uniform highp mat4 _DetailRotation;
#line 409
#line 413
#line 422
#line 430
#line 439
#line 447
#line 460
#line 472
#line 488
#line 501
uniform lowp vec4 _SurfaceColor;
#line 509
uniform highp float _Shininess;
uniform sampler2D _MainTex;
uniform sampler2D _DetailTex;
uniform highp float _DetailScale;
#line 513
uniform highp float _DetailDist;
uniform highp float _MinLight;
uniform sampler2D _CameraDepthTexture;
uniform highp mat4 _CameraToWorld;
#line 517
uniform highp float _LightPower;
uniform highp float _PlanetOpacity;
uniform highp vec3 _PlanetOrigin;
#line 539
#line 539
v2f vert( in appdata_t v ) {
    v2f o;
    highp vec4 vertex = v.vertex;
    #line 543
    o.pos = (glstate_matrix_mvp * vertex).xyzw;
    highp vec3 vertexPos = (_Object2World * vertex).xyz;
    o.viewDist = distance( vertexPos, _WorldSpaceCameraPos);
    o.worldPos = vertexPos;
    #line 547
    o.sphereNormal = (-normalize(vec4( v.texcoord.x, v.texcoord.y, v.texcoord2.x, v.texcoord2.y)).xyz);
    o.viewDir = normalize((_WorldSpaceCameraPos.xyz - vertexPos));
    o._LightCoord = (_LightMatrix0 * (_Object2World * v.vertex)).xyz;
    o._ShadowCoord = ((_Object2World * v.vertex).xyz - _LightPositionRange.xyz);
    #line 552
    return o;
}
out highp float xlv_TEXCOORD0;
out highp vec3 xlv_TEXCOORD1;
out highp vec3 xlv_TEXCOORD2;
out highp vec3 xlv_TEXCOORD3;
out highp vec3 xlv_TEXCOORD4;
out highp vec3 xlv_TEXCOORD5;
void main() {
    v2f xl_retval;
    appdata_t xlt_v;
    xlt_v.vertex = vec4(gl_Vertex);
    xlt_v.normal = vec3(gl_Normal);
    xlt_v.texcoord = vec4(gl_MultiTexCoord0);
    xlt_v.texcoord2 = vec4(gl_MultiTexCoord1);
    xl_retval = vert( xlt_v);
    gl_Position = vec4(xl_retval.pos);
    xlv_TEXCOORD0 = float(xl_retval.viewDist);
    xlv_TEXCOORD1 = vec3(xl_retval.viewDir);
    xlv_TEXCOORD2 = vec3(xl_retval.worldPos);
    xlv_TEXCOORD3 = vec3(xl_retval._LightCoord);
    xlv_TEXCOORD4 = vec3(xl_retval._ShadowCoord);
    xlv_TEXCOORD5 = vec3(xl_retval.sphereNormal);
}


#endif
#ifdef FRAGMENT

#define gl_FragData _glesFragData
layout(location = 0) out mediump vec4 _glesFragData[4];
float xll_dFdx_f(float f) {
  return dFdx(f);
}
vec2 xll_dFdx_vf2(vec2 v) {
  return dFdx(v);
}
vec3 xll_dFdx_vf3(vec3 v) {
  return dFdx(v);
}
vec4 xll_dFdx_vf4(vec4 v) {
  return dFdx(v);
}
mat2 xll_dFdx_mf2x2(mat2 m) {
  return mat2( dFdx(m[0]), dFdx(m[1]));
}
mat3 xll_dFdx_mf3x3(mat3 m) {
  return mat3( dFdx(m[0]), dFdx(m[1]), dFdx(m[2]));
}
mat4 xll_dFdx_mf4x4(mat4 m) {
  return mat4( dFdx(m[0]), dFdx(m[1]), dFdx(m[2]), dFdx(m[3]));
}
float xll_dFdy_f(float f) {
  return dFdy(f);
}
vec2 xll_dFdy_vf2(vec2 v) {
  return dFdy(v);
}
vec3 xll_dFdy_vf3(vec3 v) {
  return dFdy(v);
}
vec4 xll_dFdy_vf4(vec4 v) {
  return dFdy(v);
}
mat2 xll_dFdy_mf2x2(mat2 m) {
  return mat2( dFdy(m[0]), dFdy(m[1]));
}
mat3 xll_dFdy_mf3x3(mat3 m) {
  return mat3( dFdy(m[0]), dFdy(m[1]), dFdy(m[2]));
}
mat4 xll_dFdy_mf4x4(mat4 m) {
  return mat4( dFdy(m[0]), dFdy(m[1]), dFdy(m[2]), dFdy(m[3]));
}
vec4 xll_tex2Dgrad(sampler2D s, vec2 coord, vec2 ddx, vec2 ddy) {
   return textureGrad( s, coord, ddx, ddy);
}
float xll_saturate_f( float x) {
  return clamp( x, 0.0, 1.0);
}
vec2 xll_saturate_vf2( vec2 x) {
  return clamp( x, 0.0, 1.0);
}
vec3 xll_saturate_vf3( vec3 x) {
  return clamp( x, 0.0, 1.0);
}
vec4 xll_saturate_vf4( vec4 x) {
  return clamp( x, 0.0, 1.0);
}
mat2 xll_saturate_mf2x2(mat2 m) {
  return mat2( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0));
}
mat3 xll_saturate_mf3x3(mat3 m) {
  return mat3( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0));
}
mat4 xll_saturate_mf4x4(mat4 m) {
  return mat4( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0), clamp(m[3], 0.0, 1.0));
}
#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 331
struct SurfaceOutput {
    lowp vec3 Albedo;
    lowp vec3 Normal;
    lowp vec3 Emission;
    mediump float Specular;
    lowp float Gloss;
    lowp float Alpha;
};
#line 528
struct v2f {
    highp vec4 pos;
    highp float viewDist;
    highp vec3 viewDir;
    highp vec3 worldPos;
    highp vec3 _LightCoord;
    highp vec3 _ShadowCoord;
    highp vec3 sphereNormal;
};
#line 520
struct appdata_t {
    highp vec4 vertex;
    highp vec3 normal;
    highp vec4 texcoord;
    highp vec4 texcoord2;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform highp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform samplerCube _ShadowMapTexture;
#line 328
uniform samplerCube _LightTexture0;
uniform highp mat4 _LightMatrix0;
uniform sampler2D _LightTextureB0;
#line 341
uniform lowp vec4 _LightColor0;
uniform lowp vec4 _SpecColor;
#line 354
#line 362
#line 376
uniform highp mat4 _MainRotation;
uniform highp mat4 _DetailRotation;
#line 409
#line 413
#line 422
#line 430
#line 439
#line 447
#line 460
#line 472
#line 488
#line 501
uniform lowp vec4 _SurfaceColor;
#line 509
uniform highp float _Shininess;
uniform sampler2D _MainTex;
uniform sampler2D _DetailTex;
uniform highp float _DetailScale;
#line 513
uniform highp float _DetailDist;
uniform highp float _MinLight;
uniform sampler2D _CameraDepthTexture;
uniform highp mat4 _CameraToWorld;
#line 517
uniform highp float _LightPower;
uniform highp float _PlanetOpacity;
uniform highp vec3 _PlanetOrigin;
#line 539
#line 413
highp vec4 Derivatives( in highp float lat, in highp float lon, in highp vec3 pos ) {
    highp vec2 latLong = vec2( lat, lon);
    highp float latDdx = (0.159155 * length(xll_dFdx_vf2(pos.xz)));
    #line 417
    highp float latDdy = (0.159155 * length(xll_dFdy_vf2(pos.xz)));
    highp float longDdx = xll_dFdx_f(lon);
    highp float longDdy = xll_dFdy_f(lon);
    return vec4( latDdx, longDdx, latDdy, longDdy);
}
#line 422
highp vec2 GetSphereUV( in highp vec3 sphereVect, in highp vec2 uvOffset ) {
    highp vec2 uv;
    uv.x = (0.5 + (0.159155 * atan( sphereVect.x, sphereVect.z)));
    #line 426
    uv.y = (0.31831 * acos(sphereVect.y));
    uv += uvOffset;
    return uv;
}
#line 460
mediump vec4 GetShereDetailMap( in sampler2D texSampler, in highp vec3 sphereVect, in highp float detailScale ) {
    highp vec3 sphereVectNorm = normalize(sphereVect);
    highp vec2 uv = ((GetSphereUV( sphereVectNorm, vec2( 0.0, 0.0)) * 4.0) * detailScale);
    #line 464
    highp vec4 uvdd = Derivatives( (uv.x - 0.5), uv.y, sphereVectNorm);
    sphereVectNorm = abs(sphereVectNorm);
    mediump float zxlerp = step( sphereVectNorm.x, sphereVectNorm.z);
    mediump float nylerp = step( sphereVectNorm.y, mix( sphereVectNorm.x, sphereVectNorm.z, zxlerp));
    #line 468
    mediump vec3 detailCoords = mix( sphereVectNorm.xyz, sphereVectNorm.zxy, vec3( zxlerp));
    detailCoords = mix( sphereVectNorm.yxz, detailCoords, vec3( nylerp));
    return xll_tex2Dgrad( texSampler, (((0.5 * detailCoords.zy) / abs(detailCoords.x)) * detailScale), uvdd.xy, uvdd.zw);
}
#line 439
mediump vec4 GetSphereMap( in sampler2D texSampler, in highp vec3 sphereVect ) {
    highp vec3 sphereVectNorm = normalize(sphereVect);
    highp vec2 uv = GetSphereUV( sphereVectNorm, vec2( 0.0, 0.0));
    #line 443
    highp vec4 uvdd = Derivatives( (uv.x - 0.5), uv.y, sphereVectNorm);
    mediump vec4 tex = xll_tex2Dgrad( texSampler, uv, uvdd.xy, uvdd.zw);
    return tex;
}
#line 488
mediump vec4 SpecularColorLight( in mediump vec3 lightDir, in mediump vec3 viewDir, in mediump vec3 normal, in mediump vec4 color, in mediump vec4 specColor, in highp float specK, in mediump float atten ) {
    lightDir = normalize(lightDir);
    viewDir = normalize(viewDir);
    #line 492
    mediump vec3 h = normalize((lightDir + viewDir));
    mediump float diffuse = dot( normal, lightDir);
    highp float nh = xll_saturate_f(dot( h, normal));
    highp float spec = (pow( nh, specK) * color.w);
    #line 496
    mediump vec4 c;
    c.xyz = ((((color.xyz * _LightColor0.xyz) * diffuse) + ((_LightColor0.xyz * specColor.xyz) * spec)) * (atten * 4.0));
    c.w = (diffuse * (atten * 4.0));
    return c;
}
#line 215
highp float DecodeFloatRGBA( in highp vec4 enc ) {
    highp vec4 kDecodeDot = vec4( 1.0, 0.00392157, 1.53787e-05, 6.22737e-09);
    return dot( enc, kDecodeDot);
}
#line 316
highp float SampleCubeDistance( in highp vec3 vec ) {
    highp vec4 packDist = texture( _ShadowMapTexture, vec);
    #line 319
    return DecodeFloatRGBA( packDist);
}
#line 321
highp float unityCubeShadow( in highp vec3 vec ) {
    #line 323
    highp float mydist = (length(vec) * _LightPositionRange.w);
    mydist *= 0.97;
    highp float dist = SampleCubeDistance( vec);
    return (( (dist < mydist) ) ? ( _LightShadowData.x ) : ( 1.0 ));
}
#line 554
lowp vec4 frag( in v2f IN ) {
    #line 556
    mediump vec4 color;
    highp vec3 sphereNrm = IN.sphereNormal;
    mediump vec4 main = GetSphereMap( _MainTex, sphereNrm);
    mediump vec4 detail = GetShereDetailMap( _DetailTex, sphereNrm, _DetailScale);
    #line 560
    color = _SurfaceColor;
    mediump float detailLevel = xll_saturate_f(((2.0 * _DetailDist) * IN.viewDist));
    color.xyz += (0.5 * mix( (detail.xyz - 0.5), vec3( 0.0), vec3( detailLevel)));
    mediump float handoff = xll_saturate_f(pow( _PlanetOpacity, 2.0));
    #line 564
    color.xyz = mix( color.xyz, main.xyz, vec3( handoff));
    mediump vec4 specColor = _SpecColor;
    specColor.w = mix( 1.0, main.w, handoff);
    mediump vec4 colorLight = SpecularColorLight( vec3( normalize(_WorldSpaceLightPos0)), IN.viewDir, normalize((IN.worldPos - _PlanetOrigin)), color, specColor, (_Shininess * 128.0), ((texture( _LightTextureB0, vec2( dot( IN._LightCoord, IN._LightCoord))).w * texture( _LightTexture0, IN._LightCoord).w) * unityCubeShadow( IN._ShadowCoord)));
    #line 568
    color.w = mix( 1.0, color.w, xll_saturate_f((colorLight.w * 4.0)));
    color.w = mix( color.w, 1.0, xll_saturate_f((length(colorLight.xyz) - length((2.0 * color.xyz)))));
    color.w = mix( color.w, 1.0, handoff);
    color.xyz = colorLight.xyz;
    #line 572
    return color;
}
in highp float xlv_TEXCOORD0;
in highp vec3 xlv_TEXCOORD1;
in highp vec3 xlv_TEXCOORD2;
in highp vec3 xlv_TEXCOORD3;
in highp vec3 xlv_TEXCOORD4;
in highp vec3 xlv_TEXCOORD5;
void main() {
    lowp vec4 xl_retval;
    v2f xlt_IN;
    xlt_IN.pos = vec4(0.0);
    xlt_IN.viewDist = float(xlv_TEXCOORD0);
    xlt_IN.viewDir = vec3(xlv_TEXCOORD1);
    xlt_IN.worldPos = vec3(xlv_TEXCOORD2);
    xlt_IN._LightCoord = vec3(xlv_TEXCOORD3);
    xlt_IN._ShadowCoord = vec3(xlv_TEXCOORD4);
    xlt_IN.sphereNormal = vec3(xlv_TEXCOORD5);
    xl_retval = frag( xlt_IN);
    gl_FragData[0] = vec4(xl_retval);
}


#endif"
}

SubProgram "opengl " {
Keywords { "SPOT" "SHADOWS_DEPTH" "SHADOWS_SOFT" }
"!!GLSL
#ifdef VERTEX
varying vec3 xlv_TEXCOORD5;
varying vec4 xlv_TEXCOORD4;
varying vec4 xlv_TEXCOORD3;
varying vec3 xlv_TEXCOORD2;
varying vec3 xlv_TEXCOORD1;
varying float xlv_TEXCOORD0;
uniform mat4 _LightMatrix0;
uniform mat4 _Object2World;

uniform mat4 unity_World2Shadow[4];
uniform vec3 _WorldSpaceCameraPos;
void main ()
{
  vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * gl_Vertex).xyz;
  vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  vec4 tmpvar_3;
  tmpvar_3.x = gl_MultiTexCoord0.x;
  tmpvar_3.y = gl_MultiTexCoord0.y;
  tmpvar_3.z = gl_MultiTexCoord1.x;
  tmpvar_3.w = gl_MultiTexCoord1.y;
  gl_Position = (gl_ModelViewProjectionMatrix * gl_Vertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * gl_Vertex));
  xlv_TEXCOORD4 = (unity_World2Shadow[0] * (_Object2World * gl_Vertex));
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}


#endif
#ifdef FRAGMENT
#extension GL_ARB_shader_texture_lod : enable
varying vec3 xlv_TEXCOORD5;
varying vec4 xlv_TEXCOORD4;
varying vec4 xlv_TEXCOORD3;
varying vec3 xlv_TEXCOORD2;
varying vec3 xlv_TEXCOORD1;
varying float xlv_TEXCOORD0;
uniform vec3 _PlanetOrigin;
uniform float _PlanetOpacity;
uniform float _DetailDist;
uniform float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform float _Shininess;
uniform vec4 _SurfaceColor;
uniform vec4 _SpecColor;
uniform vec4 _LightColor0;
uniform sampler2D _LightTextureB0;
uniform sampler2D _LightTexture0;
uniform vec4 _ShadowOffsets[4];
uniform sampler2D _ShadowMapTexture;
uniform vec4 _LightShadowData;
uniform vec4 _WorldSpaceLightPos0;
void main ()
{
  vec4 main_1;
  vec4 color_2;
  vec3 tmpvar_3;
  tmpvar_3 = normalize(xlv_TEXCOORD5);
  vec2 uv_4;
  float r_5;
  if ((abs(tmpvar_3.z) > (1e-08 * abs(tmpvar_3.x)))) {
    float y_over_x_6;
    y_over_x_6 = (tmpvar_3.x / tmpvar_3.z);
    float s_7;
    float x_8;
    x_8 = (y_over_x_6 * inversesqrt(((y_over_x_6 * y_over_x_6) + 1.0)));
    s_7 = (sign(x_8) * (1.5708 - (sqrt((1.0 - abs(x_8))) * (1.5708 + (abs(x_8) * (-0.214602 + (abs(x_8) * (0.0865667 + (abs(x_8) * -0.0310296)))))))));
    r_5 = s_7;
    if ((tmpvar_3.z < 0.0)) {
      if ((tmpvar_3.x >= 0.0)) {
        r_5 = (s_7 + 3.14159);
      } else {
        r_5 = (r_5 - 3.14159);
      };
    };
  } else {
    r_5 = (sign(tmpvar_3.x) * 1.5708);
  };
  uv_4.x = (0.5 + (0.159155 * r_5));
  uv_4.y = (0.31831 * (1.5708 - (sign(tmpvar_3.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_3.y))) * (1.5708 + (abs(tmpvar_3.y) * (-0.214602 + (abs(tmpvar_3.y) * (0.0865667 + (abs(tmpvar_3.y) * -0.0310296)))))))))));
  vec2 tmpvar_9;
  tmpvar_9 = dFdx(tmpvar_3.xz);
  vec2 tmpvar_10;
  tmpvar_10 = dFdy(tmpvar_3.xz);
  vec4 tmpvar_11;
  tmpvar_11.x = (0.159155 * sqrt(dot (tmpvar_9, tmpvar_9)));
  tmpvar_11.y = dFdx(uv_4.y);
  tmpvar_11.z = (0.159155 * sqrt(dot (tmpvar_10, tmpvar_10)));
  tmpvar_11.w = dFdy(uv_4.y);
  main_1 = texture2DGradARB (_MainTex, uv_4, tmpvar_11.xy, tmpvar_11.zw);
  vec3 tmpvar_12;
  tmpvar_12 = normalize(xlv_TEXCOORD5);
  vec2 uv_13;
  float r_14;
  if ((abs(tmpvar_12.z) > (1e-08 * abs(tmpvar_12.x)))) {
    float y_over_x_15;
    y_over_x_15 = (tmpvar_12.x / tmpvar_12.z);
    float s_16;
    float x_17;
    x_17 = (y_over_x_15 * inversesqrt(((y_over_x_15 * y_over_x_15) + 1.0)));
    s_16 = (sign(x_17) * (1.5708 - (sqrt((1.0 - abs(x_17))) * (1.5708 + (abs(x_17) * (-0.214602 + (abs(x_17) * (0.0865667 + (abs(x_17) * -0.0310296)))))))));
    r_14 = s_16;
    if ((tmpvar_12.z < 0.0)) {
      if ((tmpvar_12.x >= 0.0)) {
        r_14 = (s_16 + 3.14159);
      } else {
        r_14 = (r_14 - 3.14159);
      };
    };
  } else {
    r_14 = (sign(tmpvar_12.x) * 1.5708);
  };
  uv_13.x = (0.5 + (0.159155 * r_14));
  uv_13.y = (0.31831 * (1.5708 - (sign(tmpvar_12.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_12.y))) * (1.5708 + (abs(tmpvar_12.y) * (-0.214602 + (abs(tmpvar_12.y) * (0.0865667 + (abs(tmpvar_12.y) * -0.0310296)))))))))));
  vec2 tmpvar_18;
  tmpvar_18 = ((uv_13 * 4.0) * _DetailScale);
  vec2 tmpvar_19;
  tmpvar_19 = dFdx(tmpvar_12.xz);
  vec2 tmpvar_20;
  tmpvar_20 = dFdy(tmpvar_12.xz);
  vec4 tmpvar_21;
  tmpvar_21.x = (0.159155 * sqrt(dot (tmpvar_19, tmpvar_19)));
  tmpvar_21.y = dFdx(tmpvar_18.y);
  tmpvar_21.z = (0.159155 * sqrt(dot (tmpvar_20, tmpvar_20)));
  tmpvar_21.w = dFdy(tmpvar_18.y);
  vec3 tmpvar_22;
  tmpvar_22 = abs(tmpvar_12);
  float tmpvar_23;
  tmpvar_23 = float((tmpvar_22.z >= tmpvar_22.x));
  vec3 tmpvar_24;
  tmpvar_24 = mix (tmpvar_22.yxz, mix (tmpvar_22, tmpvar_22.zxy, vec3(tmpvar_23)), vec3(float((mix (tmpvar_22.x, tmpvar_22.z, tmpvar_23) >= tmpvar_22.y))));
  color_2.w = _SurfaceColor.w;
  color_2.xyz = (_SurfaceColor.xyz + (0.5 * mix ((texture2DGradARB (_DetailTex, (((0.5 * tmpvar_24.zy) / abs(tmpvar_24.x)) * _DetailScale), tmpvar_21.xy, tmpvar_21.zw).xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0)))));
  float tmpvar_25;
  tmpvar_25 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  color_2.xyz = mix (color_2.xyz, main_1.xyz, vec3(tmpvar_25));
  vec4 tmpvar_26;
  tmpvar_26 = normalize(_WorldSpaceLightPos0);
  vec3 tmpvar_27;
  tmpvar_27 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  vec4 tmpvar_28;
  tmpvar_28 = texture2D (_LightTexture0, ((xlv_TEXCOORD3.xy / xlv_TEXCOORD3.w) + 0.5));
  vec4 tmpvar_29;
  tmpvar_29 = texture2D (_LightTextureB0, vec2(dot (xlv_TEXCOORD3.xyz, xlv_TEXCOORD3.xyz)));
  vec4 shadowVals_30;
  vec3 tmpvar_31;
  tmpvar_31 = (xlv_TEXCOORD4.xyz / xlv_TEXCOORD4.w);
  shadowVals_30.x = texture2D (_ShadowMapTexture, (tmpvar_31.xy + _ShadowOffsets[0].xy)).x;
  shadowVals_30.y = texture2D (_ShadowMapTexture, (tmpvar_31.xy + _ShadowOffsets[1].xy)).x;
  shadowVals_30.z = texture2D (_ShadowMapTexture, (tmpvar_31.xy + _ShadowOffsets[2].xy)).x;
  shadowVals_30.w = texture2D (_ShadowMapTexture, (tmpvar_31.xy + _ShadowOffsets[3].xy)).x;
  bvec4 tmpvar_32;
  tmpvar_32 = lessThan (shadowVals_30, tmpvar_31.zzzz);
  vec4 tmpvar_33;
  tmpvar_33 = _LightShadowData.xxxx;
  float tmpvar_34;
  if (tmpvar_32.x) {
    tmpvar_34 = tmpvar_33.x;
  } else {
    tmpvar_34 = 1.0;
  };
  float tmpvar_35;
  if (tmpvar_32.y) {
    tmpvar_35 = tmpvar_33.y;
  } else {
    tmpvar_35 = 1.0;
  };
  float tmpvar_36;
  if (tmpvar_32.z) {
    tmpvar_36 = tmpvar_33.z;
  } else {
    tmpvar_36 = 1.0;
  };
  float tmpvar_37;
  if (tmpvar_32.w) {
    tmpvar_37 = tmpvar_33.w;
  } else {
    tmpvar_37 = 1.0;
  };
  vec4 tmpvar_38;
  tmpvar_38.x = tmpvar_34;
  tmpvar_38.y = tmpvar_35;
  tmpvar_38.z = tmpvar_36;
  tmpvar_38.w = tmpvar_37;
  float atten_39;
  atten_39 = (((float((xlv_TEXCOORD3.z > 0.0)) * tmpvar_28.w) * tmpvar_29.w) * dot (tmpvar_38, vec4(0.25, 0.25, 0.25, 0.25)));
  vec4 c_40;
  vec3 tmpvar_41;
  tmpvar_41 = normalize(tmpvar_26.xyz);
  float tmpvar_42;
  tmpvar_42 = dot (tmpvar_27, tmpvar_41);
  c_40.xyz = ((((color_2.xyz * _LightColor0.xyz) * tmpvar_42) + ((_LightColor0.xyz * _SpecColor.xyz) * (pow (clamp (dot (normalize((tmpvar_41 + normalize(xlv_TEXCOORD1))), tmpvar_27), 0.0, 1.0), (_Shininess * 128.0)) * _SurfaceColor.w))) * (atten_39 * 4.0));
  c_40.w = (tmpvar_42 * (atten_39 * 4.0));
  color_2.w = mix (1.0, _SurfaceColor.w, clamp ((c_40.w * 4.0), 0.0, 1.0));
  vec3 arg0_43;
  arg0_43 = (2.0 * color_2.xyz);
  color_2.w = mix (color_2.w, 1.0, clamp ((sqrt(dot (c_40.xyz, c_40.xyz)) - sqrt(dot (arg0_43, arg0_43))), 0.0, 1.0));
  color_2.w = mix (color_2.w, 1.0, tmpvar_25);
  color_2.xyz = c_40.xyz;
  gl_FragData[0] = color_2;
}


#endif
"
}

SubProgram "d3d9 " {
Keywords { "SPOT" "SHADOWS_DEPTH" "SHADOWS_SOFT" }
Bind "vertex" Vertex
Bind "texcoord" TexCoord0
Bind "texcoord1" TexCoord1
Matrix 0 [glstate_matrix_mvp]
Vector 16 [_WorldSpaceCameraPos]
Matrix 4 [unity_World2Shadow0]
Matrix 8 [_Object2World]
Matrix 12 [_LightMatrix0]
"vs_3_0
; 29 ALU
dcl_position o0
dcl_texcoord0 o1
dcl_texcoord1 o2
dcl_texcoord2 o3
dcl_texcoord3 o4
dcl_texcoord4 o5
dcl_texcoord5 o6
dcl_position0 v0
dcl_texcoord0 v1
dcl_texcoord1 v2
mov r1.zw, v2.xyxy
mov r1.xy, v1
dp4 r0.w, r1, r1
rsq r1.w, r0.w
mul r1.xyz, r1.w, r1
dp4 r1.w, v0, c11
dp4 r0.z, v0, c10
dp4 r0.x, v0, c8
dp4 r0.y, v0, c9
add r2.xyz, -r0, c16
dp3 r0.w, r2, r2
rsq r0.w, r0.w
mov o6.xyz, -r1
mov r1.xyz, r0
mul o2.xyz, r0.w, r2
dp4 o4.w, r1, c15
dp4 o4.z, r1, c14
dp4 o4.y, r1, c13
dp4 o4.x, r1, c12
dp4 o5.w, r1, c7
dp4 o5.z, r1, c6
dp4 o5.y, r1, c5
dp4 o5.x, r1, c4
rcp o1.x, r0.w
mov o3.xyz, r0
dp4 o0.w, v0, c3
dp4 o0.z, v0, c2
dp4 o0.y, v0, c1
dp4 o0.x, v0, c0
"
}

SubProgram "gles " {
Keywords { "SPOT" "SHADOWS_DEPTH" "SHADOWS_SOFT" }
"!!GLES


#ifdef VERTEX

varying highp vec3 xlv_TEXCOORD5;
varying highp vec4 xlv_TEXCOORD4;
varying highp vec4 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp mat4 _LightMatrix0;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec3 _WorldSpaceCameraPos;
attribute vec4 _glesMultiTexCoord1;
attribute vec4 _glesMultiTexCoord0;
attribute vec4 _glesVertex;
void main ()
{
  highp vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * _glesVertex).xyz;
  highp vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  highp vec4 tmpvar_3;
  tmpvar_3.x = _glesMultiTexCoord0.x;
  tmpvar_3.y = _glesMultiTexCoord0.y;
  tmpvar_3.z = _glesMultiTexCoord1.x;
  tmpvar_3.w = _glesMultiTexCoord1.y;
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * _glesVertex));
  xlv_TEXCOORD4 = (unity_World2Shadow[0] * (_Object2World * _glesVertex));
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}



#endif
#ifdef FRAGMENT

#extension GL_EXT_shader_texture_lod : enable
#extension GL_OES_standard_derivatives : enable
varying highp vec3 xlv_TEXCOORD5;
varying highp vec4 xlv_TEXCOORD4;
varying highp vec4 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp vec3 _PlanetOrigin;
uniform highp float _PlanetOpacity;
uniform highp float _DetailDist;
uniform highp float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform highp float _Shininess;
uniform lowp vec4 _SurfaceColor;
uniform lowp vec4 _SpecColor;
uniform lowp vec4 _LightColor0;
uniform sampler2D _LightTextureB0;
uniform sampler2D _LightTexture0;
uniform highp vec4 _ShadowOffsets[4];
uniform sampler2D _ShadowMapTexture;
uniform highp vec4 _LightShadowData;
uniform highp vec4 _WorldSpaceLightPos0;
void main ()
{
  lowp vec4 tmpvar_1;
  mediump vec4 specColor_2;
  mediump float handoff_3;
  mediump float detailLevel_4;
  mediump vec4 color_5;
  mediump vec4 tex_6;
  highp vec3 tmpvar_7;
  tmpvar_7 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_8;
  highp float r_9;
  if ((abs(tmpvar_7.z) > (1e-08 * abs(tmpvar_7.x)))) {
    highp float y_over_x_10;
    y_over_x_10 = (tmpvar_7.x / tmpvar_7.z);
    highp float s_11;
    highp float x_12;
    x_12 = (y_over_x_10 * inversesqrt(((y_over_x_10 * y_over_x_10) + 1.0)));
    s_11 = (sign(x_12) * (1.5708 - (sqrt((1.0 - abs(x_12))) * (1.5708 + (abs(x_12) * (-0.214602 + (abs(x_12) * (0.0865667 + (abs(x_12) * -0.0310296)))))))));
    r_9 = s_11;
    if ((tmpvar_7.z < 0.0)) {
      if ((tmpvar_7.x >= 0.0)) {
        r_9 = (s_11 + 3.14159);
      } else {
        r_9 = (r_9 - 3.14159);
      };
    };
  } else {
    r_9 = (sign(tmpvar_7.x) * 1.5708);
  };
  uv_8.x = (0.5 + (0.159155 * r_9));
  uv_8.y = (0.31831 * (1.5708 - (sign(tmpvar_7.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_7.y))) * (1.5708 + (abs(tmpvar_7.y) * (-0.214602 + (abs(tmpvar_7.y) * (0.0865667 + (abs(tmpvar_7.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_13;
  tmpvar_13 = dFdx(tmpvar_7.xz);
  highp vec2 tmpvar_14;
  tmpvar_14 = dFdy(tmpvar_7.xz);
  highp vec4 tmpvar_15;
  tmpvar_15.x = (0.159155 * sqrt(dot (tmpvar_13, tmpvar_13)));
  tmpvar_15.y = dFdx(uv_8.y);
  tmpvar_15.z = (0.159155 * sqrt(dot (tmpvar_14, tmpvar_14)));
  tmpvar_15.w = dFdy(uv_8.y);
  lowp vec4 tmpvar_16;
  tmpvar_16 = texture2DGradEXT (_MainTex, uv_8, tmpvar_15.xy, tmpvar_15.zw);
  tex_6 = tmpvar_16;
  mediump vec4 tmpvar_17;
  mediump vec3 detailCoords_18;
  mediump float nylerp_19;
  mediump float zxlerp_20;
  highp vec3 tmpvar_21;
  tmpvar_21 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_22;
  highp float r_23;
  if ((abs(tmpvar_21.z) > (1e-08 * abs(tmpvar_21.x)))) {
    highp float y_over_x_24;
    y_over_x_24 = (tmpvar_21.x / tmpvar_21.z);
    highp float s_25;
    highp float x_26;
    x_26 = (y_over_x_24 * inversesqrt(((y_over_x_24 * y_over_x_24) + 1.0)));
    s_25 = (sign(x_26) * (1.5708 - (sqrt((1.0 - abs(x_26))) * (1.5708 + (abs(x_26) * (-0.214602 + (abs(x_26) * (0.0865667 + (abs(x_26) * -0.0310296)))))))));
    r_23 = s_25;
    if ((tmpvar_21.z < 0.0)) {
      if ((tmpvar_21.x >= 0.0)) {
        r_23 = (s_25 + 3.14159);
      } else {
        r_23 = (r_23 - 3.14159);
      };
    };
  } else {
    r_23 = (sign(tmpvar_21.x) * 1.5708);
  };
  uv_22.x = (0.5 + (0.159155 * r_23));
  uv_22.y = (0.31831 * (1.5708 - (sign(tmpvar_21.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_21.y))) * (1.5708 + (abs(tmpvar_21.y) * (-0.214602 + (abs(tmpvar_21.y) * (0.0865667 + (abs(tmpvar_21.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_27;
  tmpvar_27 = ((uv_22 * 4.0) * _DetailScale);
  highp vec2 tmpvar_28;
  tmpvar_28 = dFdx(tmpvar_21.xz);
  highp vec2 tmpvar_29;
  tmpvar_29 = dFdy(tmpvar_21.xz);
  highp vec4 tmpvar_30;
  tmpvar_30.x = (0.159155 * sqrt(dot (tmpvar_28, tmpvar_28)));
  tmpvar_30.y = dFdx(tmpvar_27.y);
  tmpvar_30.z = (0.159155 * sqrt(dot (tmpvar_29, tmpvar_29)));
  tmpvar_30.w = dFdy(tmpvar_27.y);
  highp vec3 tmpvar_31;
  tmpvar_31 = abs(tmpvar_21);
  highp float tmpvar_32;
  tmpvar_32 = float((tmpvar_31.z >= tmpvar_31.x));
  zxlerp_20 = tmpvar_32;
  highp float tmpvar_33;
  tmpvar_33 = float((mix (tmpvar_31.x, tmpvar_31.z, zxlerp_20) >= tmpvar_31.y));
  nylerp_19 = tmpvar_33;
  highp vec3 tmpvar_34;
  tmpvar_34 = mix (tmpvar_31, tmpvar_31.zxy, vec3(zxlerp_20));
  detailCoords_18 = tmpvar_34;
  highp vec3 tmpvar_35;
  tmpvar_35 = mix (tmpvar_31.yxz, detailCoords_18, vec3(nylerp_19));
  detailCoords_18 = tmpvar_35;
  mediump float tmpvar_36;
  tmpvar_36 = abs(detailCoords_18.x);
  highp vec2 coord_37;
  coord_37 = (((0.5 * detailCoords_18.zy) / tmpvar_36) * _DetailScale);
  lowp vec4 tmpvar_38;
  tmpvar_38 = texture2DGradEXT (_DetailTex, coord_37, tmpvar_30.xy, tmpvar_30.zw);
  tmpvar_17 = tmpvar_38;
  color_5 = _SurfaceColor;
  highp float tmpvar_39;
  tmpvar_39 = clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0);
  detailLevel_4 = tmpvar_39;
  color_5.xyz = (color_5.xyz + (0.5 * mix ((tmpvar_17.xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(detailLevel_4))));
  highp float tmpvar_40;
  tmpvar_40 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  handoff_3 = tmpvar_40;
  color_5.xyz = mix (color_5.xyz, tex_6.xyz, vec3(handoff_3));
  specColor_2.xyz = _SpecColor.xyz;
  specColor_2.w = mix (1.0, tex_6.w, handoff_3);
  highp vec3 tmpvar_41;
  tmpvar_41 = normalize(_WorldSpaceLightPos0).xyz;
  highp vec3 tmpvar_42;
  tmpvar_42 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  lowp vec4 tmpvar_43;
  highp vec2 P_44;
  P_44 = ((xlv_TEXCOORD3.xy / xlv_TEXCOORD3.w) + 0.5);
  tmpvar_43 = texture2D (_LightTexture0, P_44);
  highp float tmpvar_45;
  tmpvar_45 = dot (xlv_TEXCOORD3.xyz, xlv_TEXCOORD3.xyz);
  lowp vec4 tmpvar_46;
  tmpvar_46 = texture2D (_LightTextureB0, vec2(tmpvar_45));
  lowp float tmpvar_47;
  mediump vec4 shadows_48;
  highp vec4 shadowVals_49;
  highp vec3 tmpvar_50;
  tmpvar_50 = (xlv_TEXCOORD4.xyz / xlv_TEXCOORD4.w);
  highp vec2 P_51;
  P_51 = (tmpvar_50.xy + _ShadowOffsets[0].xy);
  lowp float tmpvar_52;
  tmpvar_52 = texture2D (_ShadowMapTexture, P_51).x;
  shadowVals_49.x = tmpvar_52;
  highp vec2 P_53;
  P_53 = (tmpvar_50.xy + _ShadowOffsets[1].xy);
  lowp float tmpvar_54;
  tmpvar_54 = texture2D (_ShadowMapTexture, P_53).x;
  shadowVals_49.y = tmpvar_54;
  highp vec2 P_55;
  P_55 = (tmpvar_50.xy + _ShadowOffsets[2].xy);
  lowp float tmpvar_56;
  tmpvar_56 = texture2D (_ShadowMapTexture, P_55).x;
  shadowVals_49.z = tmpvar_56;
  highp vec2 P_57;
  P_57 = (tmpvar_50.xy + _ShadowOffsets[3].xy);
  lowp float tmpvar_58;
  tmpvar_58 = texture2D (_ShadowMapTexture, P_57).x;
  shadowVals_49.w = tmpvar_58;
  bvec4 tmpvar_59;
  tmpvar_59 = lessThan (shadowVals_49, tmpvar_50.zzzz);
  highp vec4 tmpvar_60;
  tmpvar_60 = _LightShadowData.xxxx;
  highp float tmpvar_61;
  if (tmpvar_59.x) {
    tmpvar_61 = tmpvar_60.x;
  } else {
    tmpvar_61 = 1.0;
  };
  highp float tmpvar_62;
  if (tmpvar_59.y) {
    tmpvar_62 = tmpvar_60.y;
  } else {
    tmpvar_62 = 1.0;
  };
  highp float tmpvar_63;
  if (tmpvar_59.z) {
    tmpvar_63 = tmpvar_60.z;
  } else {
    tmpvar_63 = 1.0;
  };
  highp float tmpvar_64;
  if (tmpvar_59.w) {
    tmpvar_64 = tmpvar_60.w;
  } else {
    tmpvar_64 = 1.0;
  };
  highp vec4 tmpvar_65;
  tmpvar_65.x = tmpvar_61;
  tmpvar_65.y = tmpvar_62;
  tmpvar_65.z = tmpvar_63;
  tmpvar_65.w = tmpvar_64;
  shadows_48 = tmpvar_65;
  mediump float tmpvar_66;
  tmpvar_66 = dot (shadows_48, vec4(0.25, 0.25, 0.25, 0.25));
  tmpvar_47 = tmpvar_66;
  mediump vec3 lightDir_67;
  lightDir_67 = tmpvar_41;
  mediump vec3 viewDir_68;
  viewDir_68 = xlv_TEXCOORD1;
  mediump vec3 normal_69;
  normal_69 = tmpvar_42;
  mediump float atten_70;
  atten_70 = (((float((xlv_TEXCOORD3.z > 0.0)) * tmpvar_43.w) * tmpvar_46.w) * tmpvar_47);
  mediump vec4 c_71;
  highp float nh_72;
  mediump vec3 tmpvar_73;
  tmpvar_73 = normalize(lightDir_67);
  lightDir_67 = tmpvar_73;
  mediump vec3 tmpvar_74;
  tmpvar_74 = normalize(viewDir_68);
  viewDir_68 = tmpvar_74;
  mediump float tmpvar_75;
  tmpvar_75 = dot (normal_69, tmpvar_73);
  mediump float tmpvar_76;
  tmpvar_76 = clamp (dot (normalize((tmpvar_73 + tmpvar_74)), normal_69), 0.0, 1.0);
  nh_72 = tmpvar_76;
  highp vec3 tmpvar_77;
  tmpvar_77 = ((((color_5.xyz * _LightColor0.xyz) * tmpvar_75) + ((_LightColor0.xyz * specColor_2.xyz) * (pow (nh_72, (_Shininess * 128.0)) * color_5.w))) * (atten_70 * 4.0));
  c_71.xyz = tmpvar_77;
  c_71.w = (tmpvar_75 * (atten_70 * 4.0));
  color_5.w = mix (1.0, color_5.w, clamp ((c_71.w * 4.0), 0.0, 1.0));
  mediump vec3 arg0_78;
  arg0_78 = (2.0 * color_5.xyz);
  color_5.w = mix (color_5.w, 1.0, clamp ((sqrt(dot (c_71.xyz, c_71.xyz)) - sqrt(dot (arg0_78, arg0_78))), 0.0, 1.0));
  color_5.w = mix (color_5.w, 1.0, handoff_3);
  color_5.xyz = c_71.xyz;
  tmpvar_1 = color_5;
  gl_FragData[0] = tmpvar_1;
}



#endif"
}

SubProgram "glesdesktop " {
Keywords { "SPOT" "SHADOWS_DEPTH" "SHADOWS_SOFT" }
"!!GLES


#ifdef VERTEX

varying highp vec3 xlv_TEXCOORD5;
varying highp vec4 xlv_TEXCOORD4;
varying highp vec4 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp mat4 _LightMatrix0;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec3 _WorldSpaceCameraPos;
attribute vec4 _glesMultiTexCoord1;
attribute vec4 _glesMultiTexCoord0;
attribute vec4 _glesVertex;
void main ()
{
  highp vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * _glesVertex).xyz;
  highp vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  highp vec4 tmpvar_3;
  tmpvar_3.x = _glesMultiTexCoord0.x;
  tmpvar_3.y = _glesMultiTexCoord0.y;
  tmpvar_3.z = _glesMultiTexCoord1.x;
  tmpvar_3.w = _glesMultiTexCoord1.y;
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * _glesVertex));
  xlv_TEXCOORD4 = (unity_World2Shadow[0] * (_Object2World * _glesVertex));
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}



#endif
#ifdef FRAGMENT

#extension GL_EXT_shader_texture_lod : enable
#extension GL_OES_standard_derivatives : enable
varying highp vec3 xlv_TEXCOORD5;
varying highp vec4 xlv_TEXCOORD4;
varying highp vec4 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp vec3 _PlanetOrigin;
uniform highp float _PlanetOpacity;
uniform highp float _DetailDist;
uniform highp float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform highp float _Shininess;
uniform lowp vec4 _SurfaceColor;
uniform lowp vec4 _SpecColor;
uniform lowp vec4 _LightColor0;
uniform sampler2D _LightTextureB0;
uniform sampler2D _LightTexture0;
uniform highp vec4 _ShadowOffsets[4];
uniform sampler2D _ShadowMapTexture;
uniform highp vec4 _LightShadowData;
uniform highp vec4 _WorldSpaceLightPos0;
void main ()
{
  lowp vec4 tmpvar_1;
  mediump vec4 specColor_2;
  mediump float handoff_3;
  mediump float detailLevel_4;
  mediump vec4 color_5;
  mediump vec4 tex_6;
  highp vec3 tmpvar_7;
  tmpvar_7 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_8;
  highp float r_9;
  if ((abs(tmpvar_7.z) > (1e-08 * abs(tmpvar_7.x)))) {
    highp float y_over_x_10;
    y_over_x_10 = (tmpvar_7.x / tmpvar_7.z);
    highp float s_11;
    highp float x_12;
    x_12 = (y_over_x_10 * inversesqrt(((y_over_x_10 * y_over_x_10) + 1.0)));
    s_11 = (sign(x_12) * (1.5708 - (sqrt((1.0 - abs(x_12))) * (1.5708 + (abs(x_12) * (-0.214602 + (abs(x_12) * (0.0865667 + (abs(x_12) * -0.0310296)))))))));
    r_9 = s_11;
    if ((tmpvar_7.z < 0.0)) {
      if ((tmpvar_7.x >= 0.0)) {
        r_9 = (s_11 + 3.14159);
      } else {
        r_9 = (r_9 - 3.14159);
      };
    };
  } else {
    r_9 = (sign(tmpvar_7.x) * 1.5708);
  };
  uv_8.x = (0.5 + (0.159155 * r_9));
  uv_8.y = (0.31831 * (1.5708 - (sign(tmpvar_7.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_7.y))) * (1.5708 + (abs(tmpvar_7.y) * (-0.214602 + (abs(tmpvar_7.y) * (0.0865667 + (abs(tmpvar_7.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_13;
  tmpvar_13 = dFdx(tmpvar_7.xz);
  highp vec2 tmpvar_14;
  tmpvar_14 = dFdy(tmpvar_7.xz);
  highp vec4 tmpvar_15;
  tmpvar_15.x = (0.159155 * sqrt(dot (tmpvar_13, tmpvar_13)));
  tmpvar_15.y = dFdx(uv_8.y);
  tmpvar_15.z = (0.159155 * sqrt(dot (tmpvar_14, tmpvar_14)));
  tmpvar_15.w = dFdy(uv_8.y);
  lowp vec4 tmpvar_16;
  tmpvar_16 = texture2DGradEXT (_MainTex, uv_8, tmpvar_15.xy, tmpvar_15.zw);
  tex_6 = tmpvar_16;
  mediump vec4 tmpvar_17;
  mediump vec3 detailCoords_18;
  mediump float nylerp_19;
  mediump float zxlerp_20;
  highp vec3 tmpvar_21;
  tmpvar_21 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_22;
  highp float r_23;
  if ((abs(tmpvar_21.z) > (1e-08 * abs(tmpvar_21.x)))) {
    highp float y_over_x_24;
    y_over_x_24 = (tmpvar_21.x / tmpvar_21.z);
    highp float s_25;
    highp float x_26;
    x_26 = (y_over_x_24 * inversesqrt(((y_over_x_24 * y_over_x_24) + 1.0)));
    s_25 = (sign(x_26) * (1.5708 - (sqrt((1.0 - abs(x_26))) * (1.5708 + (abs(x_26) * (-0.214602 + (abs(x_26) * (0.0865667 + (abs(x_26) * -0.0310296)))))))));
    r_23 = s_25;
    if ((tmpvar_21.z < 0.0)) {
      if ((tmpvar_21.x >= 0.0)) {
        r_23 = (s_25 + 3.14159);
      } else {
        r_23 = (r_23 - 3.14159);
      };
    };
  } else {
    r_23 = (sign(tmpvar_21.x) * 1.5708);
  };
  uv_22.x = (0.5 + (0.159155 * r_23));
  uv_22.y = (0.31831 * (1.5708 - (sign(tmpvar_21.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_21.y))) * (1.5708 + (abs(tmpvar_21.y) * (-0.214602 + (abs(tmpvar_21.y) * (0.0865667 + (abs(tmpvar_21.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_27;
  tmpvar_27 = ((uv_22 * 4.0) * _DetailScale);
  highp vec2 tmpvar_28;
  tmpvar_28 = dFdx(tmpvar_21.xz);
  highp vec2 tmpvar_29;
  tmpvar_29 = dFdy(tmpvar_21.xz);
  highp vec4 tmpvar_30;
  tmpvar_30.x = (0.159155 * sqrt(dot (tmpvar_28, tmpvar_28)));
  tmpvar_30.y = dFdx(tmpvar_27.y);
  tmpvar_30.z = (0.159155 * sqrt(dot (tmpvar_29, tmpvar_29)));
  tmpvar_30.w = dFdy(tmpvar_27.y);
  highp vec3 tmpvar_31;
  tmpvar_31 = abs(tmpvar_21);
  highp float tmpvar_32;
  tmpvar_32 = float((tmpvar_31.z >= tmpvar_31.x));
  zxlerp_20 = tmpvar_32;
  highp float tmpvar_33;
  tmpvar_33 = float((mix (tmpvar_31.x, tmpvar_31.z, zxlerp_20) >= tmpvar_31.y));
  nylerp_19 = tmpvar_33;
  highp vec3 tmpvar_34;
  tmpvar_34 = mix (tmpvar_31, tmpvar_31.zxy, vec3(zxlerp_20));
  detailCoords_18 = tmpvar_34;
  highp vec3 tmpvar_35;
  tmpvar_35 = mix (tmpvar_31.yxz, detailCoords_18, vec3(nylerp_19));
  detailCoords_18 = tmpvar_35;
  mediump float tmpvar_36;
  tmpvar_36 = abs(detailCoords_18.x);
  highp vec2 coord_37;
  coord_37 = (((0.5 * detailCoords_18.zy) / tmpvar_36) * _DetailScale);
  lowp vec4 tmpvar_38;
  tmpvar_38 = texture2DGradEXT (_DetailTex, coord_37, tmpvar_30.xy, tmpvar_30.zw);
  tmpvar_17 = tmpvar_38;
  color_5 = _SurfaceColor;
  highp float tmpvar_39;
  tmpvar_39 = clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0);
  detailLevel_4 = tmpvar_39;
  color_5.xyz = (color_5.xyz + (0.5 * mix ((tmpvar_17.xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(detailLevel_4))));
  highp float tmpvar_40;
  tmpvar_40 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  handoff_3 = tmpvar_40;
  color_5.xyz = mix (color_5.xyz, tex_6.xyz, vec3(handoff_3));
  specColor_2.xyz = _SpecColor.xyz;
  specColor_2.w = mix (1.0, tex_6.w, handoff_3);
  highp vec3 tmpvar_41;
  tmpvar_41 = normalize(_WorldSpaceLightPos0).xyz;
  highp vec3 tmpvar_42;
  tmpvar_42 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  lowp vec4 tmpvar_43;
  highp vec2 P_44;
  P_44 = ((xlv_TEXCOORD3.xy / xlv_TEXCOORD3.w) + 0.5);
  tmpvar_43 = texture2D (_LightTexture0, P_44);
  highp float tmpvar_45;
  tmpvar_45 = dot (xlv_TEXCOORD3.xyz, xlv_TEXCOORD3.xyz);
  lowp vec4 tmpvar_46;
  tmpvar_46 = texture2D (_LightTextureB0, vec2(tmpvar_45));
  lowp float tmpvar_47;
  mediump vec4 shadows_48;
  highp vec4 shadowVals_49;
  highp vec3 tmpvar_50;
  tmpvar_50 = (xlv_TEXCOORD4.xyz / xlv_TEXCOORD4.w);
  highp vec2 P_51;
  P_51 = (tmpvar_50.xy + _ShadowOffsets[0].xy);
  lowp float tmpvar_52;
  tmpvar_52 = texture2D (_ShadowMapTexture, P_51).x;
  shadowVals_49.x = tmpvar_52;
  highp vec2 P_53;
  P_53 = (tmpvar_50.xy + _ShadowOffsets[1].xy);
  lowp float tmpvar_54;
  tmpvar_54 = texture2D (_ShadowMapTexture, P_53).x;
  shadowVals_49.y = tmpvar_54;
  highp vec2 P_55;
  P_55 = (tmpvar_50.xy + _ShadowOffsets[2].xy);
  lowp float tmpvar_56;
  tmpvar_56 = texture2D (_ShadowMapTexture, P_55).x;
  shadowVals_49.z = tmpvar_56;
  highp vec2 P_57;
  P_57 = (tmpvar_50.xy + _ShadowOffsets[3].xy);
  lowp float tmpvar_58;
  tmpvar_58 = texture2D (_ShadowMapTexture, P_57).x;
  shadowVals_49.w = tmpvar_58;
  bvec4 tmpvar_59;
  tmpvar_59 = lessThan (shadowVals_49, tmpvar_50.zzzz);
  highp vec4 tmpvar_60;
  tmpvar_60 = _LightShadowData.xxxx;
  highp float tmpvar_61;
  if (tmpvar_59.x) {
    tmpvar_61 = tmpvar_60.x;
  } else {
    tmpvar_61 = 1.0;
  };
  highp float tmpvar_62;
  if (tmpvar_59.y) {
    tmpvar_62 = tmpvar_60.y;
  } else {
    tmpvar_62 = 1.0;
  };
  highp float tmpvar_63;
  if (tmpvar_59.z) {
    tmpvar_63 = tmpvar_60.z;
  } else {
    tmpvar_63 = 1.0;
  };
  highp float tmpvar_64;
  if (tmpvar_59.w) {
    tmpvar_64 = tmpvar_60.w;
  } else {
    tmpvar_64 = 1.0;
  };
  highp vec4 tmpvar_65;
  tmpvar_65.x = tmpvar_61;
  tmpvar_65.y = tmpvar_62;
  tmpvar_65.z = tmpvar_63;
  tmpvar_65.w = tmpvar_64;
  shadows_48 = tmpvar_65;
  mediump float tmpvar_66;
  tmpvar_66 = dot (shadows_48, vec4(0.25, 0.25, 0.25, 0.25));
  tmpvar_47 = tmpvar_66;
  mediump vec3 lightDir_67;
  lightDir_67 = tmpvar_41;
  mediump vec3 viewDir_68;
  viewDir_68 = xlv_TEXCOORD1;
  mediump vec3 normal_69;
  normal_69 = tmpvar_42;
  mediump float atten_70;
  atten_70 = (((float((xlv_TEXCOORD3.z > 0.0)) * tmpvar_43.w) * tmpvar_46.w) * tmpvar_47);
  mediump vec4 c_71;
  highp float nh_72;
  mediump vec3 tmpvar_73;
  tmpvar_73 = normalize(lightDir_67);
  lightDir_67 = tmpvar_73;
  mediump vec3 tmpvar_74;
  tmpvar_74 = normalize(viewDir_68);
  viewDir_68 = tmpvar_74;
  mediump float tmpvar_75;
  tmpvar_75 = dot (normal_69, tmpvar_73);
  mediump float tmpvar_76;
  tmpvar_76 = clamp (dot (normalize((tmpvar_73 + tmpvar_74)), normal_69), 0.0, 1.0);
  nh_72 = tmpvar_76;
  highp vec3 tmpvar_77;
  tmpvar_77 = ((((color_5.xyz * _LightColor0.xyz) * tmpvar_75) + ((_LightColor0.xyz * specColor_2.xyz) * (pow (nh_72, (_Shininess * 128.0)) * color_5.w))) * (atten_70 * 4.0));
  c_71.xyz = tmpvar_77;
  c_71.w = (tmpvar_75 * (atten_70 * 4.0));
  color_5.w = mix (1.0, color_5.w, clamp ((c_71.w * 4.0), 0.0, 1.0));
  mediump vec3 arg0_78;
  arg0_78 = (2.0 * color_5.xyz);
  color_5.w = mix (color_5.w, 1.0, clamp ((sqrt(dot (c_71.xyz, c_71.xyz)) - sqrt(dot (arg0_78, arg0_78))), 0.0, 1.0));
  color_5.w = mix (color_5.w, 1.0, handoff_3);
  color_5.xyz = c_71.xyz;
  tmpvar_1 = color_5;
  gl_FragData[0] = tmpvar_1;
}



#endif"
}

SubProgram "gles3 " {
Keywords { "SPOT" "SHADOWS_DEPTH" "SHADOWS_SOFT" }
"!!GLES3#version 300 es


#ifdef VERTEX

#define gl_Vertex _glesVertex
in vec4 _glesVertex;
#define gl_Normal (normalize(_glesNormal))
in vec3 _glesNormal;
#define gl_MultiTexCoord0 _glesMultiTexCoord0
in vec4 _glesMultiTexCoord0;
#define gl_MultiTexCoord1 _glesMultiTexCoord1
in vec4 _glesMultiTexCoord1;

#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 340
struct SurfaceOutput {
    lowp vec3 Albedo;
    lowp vec3 Normal;
    lowp vec3 Emission;
    mediump float Specular;
    lowp float Gloss;
    lowp float Alpha;
};
#line 537
struct v2f {
    highp vec4 pos;
    highp float viewDist;
    highp vec3 viewDir;
    highp vec3 worldPos;
    highp vec4 _LightCoord;
    highp vec4 _ShadowCoord;
    highp vec3 sphereNormal;
};
#line 529
struct appdata_t {
    highp vec4 vertex;
    highp vec3 normal;
    highp vec4 texcoord;
    highp vec4 texcoord2;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform highp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform sampler2D _ShadowMapTexture;
uniform highp vec4 _ShadowOffsets[4];
uniform sampler2D _LightTexture0;
uniform highp mat4 _LightMatrix0;
#line 331
uniform sampler2D _LightTextureB0;
#line 336
#line 350
uniform lowp vec4 _LightColor0;
uniform lowp vec4 _SpecColor;
#line 363
#line 371
#line 385
uniform highp mat4 _MainRotation;
uniform highp mat4 _DetailRotation;
#line 418
#line 422
#line 431
#line 439
#line 448
#line 456
#line 469
#line 481
#line 497
#line 510
uniform lowp vec4 _SurfaceColor;
#line 518
uniform highp float _Shininess;
uniform sampler2D _MainTex;
uniform sampler2D _DetailTex;
uniform highp float _DetailScale;
#line 522
uniform highp float _DetailDist;
uniform highp float _MinLight;
uniform sampler2D _CameraDepthTexture;
uniform highp mat4 _CameraToWorld;
#line 526
uniform highp float _LightPower;
uniform highp float _PlanetOpacity;
uniform highp vec3 _PlanetOrigin;
#line 548
#line 548
v2f vert( in appdata_t v ) {
    v2f o;
    highp vec4 vertex = v.vertex;
    #line 552
    o.pos = (glstate_matrix_mvp * vertex).xyzw;
    highp vec3 vertexPos = (_Object2World * vertex).xyz;
    o.viewDist = distance( vertexPos, _WorldSpaceCameraPos);
    o.worldPos = vertexPos;
    #line 556
    o.sphereNormal = (-normalize(vec4( v.texcoord.x, v.texcoord.y, v.texcoord2.x, v.texcoord2.y)).xyz);
    o.viewDir = normalize((_WorldSpaceCameraPos.xyz - vertexPos));
    o._LightCoord = (_LightMatrix0 * (_Object2World * v.vertex));
    o._ShadowCoord = (unity_World2Shadow[0] * (_Object2World * v.vertex));
    #line 561
    return o;
}
out highp float xlv_TEXCOORD0;
out highp vec3 xlv_TEXCOORD1;
out highp vec3 xlv_TEXCOORD2;
out highp vec4 xlv_TEXCOORD3;
out highp vec4 xlv_TEXCOORD4;
out highp vec3 xlv_TEXCOORD5;
void main() {
    v2f xl_retval;
    appdata_t xlt_v;
    xlt_v.vertex = vec4(gl_Vertex);
    xlt_v.normal = vec3(gl_Normal);
    xlt_v.texcoord = vec4(gl_MultiTexCoord0);
    xlt_v.texcoord2 = vec4(gl_MultiTexCoord1);
    xl_retval = vert( xlt_v);
    gl_Position = vec4(xl_retval.pos);
    xlv_TEXCOORD0 = float(xl_retval.viewDist);
    xlv_TEXCOORD1 = vec3(xl_retval.viewDir);
    xlv_TEXCOORD2 = vec3(xl_retval.worldPos);
    xlv_TEXCOORD3 = vec4(xl_retval._LightCoord);
    xlv_TEXCOORD4 = vec4(xl_retval._ShadowCoord);
    xlv_TEXCOORD5 = vec3(xl_retval.sphereNormal);
}


#endif
#ifdef FRAGMENT

#define gl_FragData _glesFragData
layout(location = 0) out mediump vec4 _glesFragData[4];
float xll_dFdx_f(float f) {
  return dFdx(f);
}
vec2 xll_dFdx_vf2(vec2 v) {
  return dFdx(v);
}
vec3 xll_dFdx_vf3(vec3 v) {
  return dFdx(v);
}
vec4 xll_dFdx_vf4(vec4 v) {
  return dFdx(v);
}
mat2 xll_dFdx_mf2x2(mat2 m) {
  return mat2( dFdx(m[0]), dFdx(m[1]));
}
mat3 xll_dFdx_mf3x3(mat3 m) {
  return mat3( dFdx(m[0]), dFdx(m[1]), dFdx(m[2]));
}
mat4 xll_dFdx_mf4x4(mat4 m) {
  return mat4( dFdx(m[0]), dFdx(m[1]), dFdx(m[2]), dFdx(m[3]));
}
float xll_dFdy_f(float f) {
  return dFdy(f);
}
vec2 xll_dFdy_vf2(vec2 v) {
  return dFdy(v);
}
vec3 xll_dFdy_vf3(vec3 v) {
  return dFdy(v);
}
vec4 xll_dFdy_vf4(vec4 v) {
  return dFdy(v);
}
mat2 xll_dFdy_mf2x2(mat2 m) {
  return mat2( dFdy(m[0]), dFdy(m[1]));
}
mat3 xll_dFdy_mf3x3(mat3 m) {
  return mat3( dFdy(m[0]), dFdy(m[1]), dFdy(m[2]));
}
mat4 xll_dFdy_mf4x4(mat4 m) {
  return mat4( dFdy(m[0]), dFdy(m[1]), dFdy(m[2]), dFdy(m[3]));
}
vec4 xll_tex2Dgrad(sampler2D s, vec2 coord, vec2 ddx, vec2 ddy) {
   return textureGrad( s, coord, ddx, ddy);
}
float xll_saturate_f( float x) {
  return clamp( x, 0.0, 1.0);
}
vec2 xll_saturate_vf2( vec2 x) {
  return clamp( x, 0.0, 1.0);
}
vec3 xll_saturate_vf3( vec3 x) {
  return clamp( x, 0.0, 1.0);
}
vec4 xll_saturate_vf4( vec4 x) {
  return clamp( x, 0.0, 1.0);
}
mat2 xll_saturate_mf2x2(mat2 m) {
  return mat2( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0));
}
mat3 xll_saturate_mf3x3(mat3 m) {
  return mat3( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0));
}
mat4 xll_saturate_mf4x4(mat4 m) {
  return mat4( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0), clamp(m[3], 0.0, 1.0));
}
vec2 xll_vecTSel_vb2_vf2_vf2 (bvec2 a, vec2 b, vec2 c) {
  return vec2 (a.x ? b.x : c.x, a.y ? b.y : c.y);
}
vec3 xll_vecTSel_vb3_vf3_vf3 (bvec3 a, vec3 b, vec3 c) {
  return vec3 (a.x ? b.x : c.x, a.y ? b.y : c.y, a.z ? b.z : c.z);
}
vec4 xll_vecTSel_vb4_vf4_vf4 (bvec4 a, vec4 b, vec4 c) {
  return vec4 (a.x ? b.x : c.x, a.y ? b.y : c.y, a.z ? b.z : c.z, a.w ? b.w : c.w);
}
#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 340
struct SurfaceOutput {
    lowp vec3 Albedo;
    lowp vec3 Normal;
    lowp vec3 Emission;
    mediump float Specular;
    lowp float Gloss;
    lowp float Alpha;
};
#line 537
struct v2f {
    highp vec4 pos;
    highp float viewDist;
    highp vec3 viewDir;
    highp vec3 worldPos;
    highp vec4 _LightCoord;
    highp vec4 _ShadowCoord;
    highp vec3 sphereNormal;
};
#line 529
struct appdata_t {
    highp vec4 vertex;
    highp vec3 normal;
    highp vec4 texcoord;
    highp vec4 texcoord2;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform highp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform sampler2D _ShadowMapTexture;
uniform highp vec4 _ShadowOffsets[4];
uniform sampler2D _LightTexture0;
uniform highp mat4 _LightMatrix0;
#line 331
uniform sampler2D _LightTextureB0;
#line 336
#line 350
uniform lowp vec4 _LightColor0;
uniform lowp vec4 _SpecColor;
#line 363
#line 371
#line 385
uniform highp mat4 _MainRotation;
uniform highp mat4 _DetailRotation;
#line 418
#line 422
#line 431
#line 439
#line 448
#line 456
#line 469
#line 481
#line 497
#line 510
uniform lowp vec4 _SurfaceColor;
#line 518
uniform highp float _Shininess;
uniform sampler2D _MainTex;
uniform sampler2D _DetailTex;
uniform highp float _DetailScale;
#line 522
uniform highp float _DetailDist;
uniform highp float _MinLight;
uniform sampler2D _CameraDepthTexture;
uniform highp mat4 _CameraToWorld;
#line 526
uniform highp float _LightPower;
uniform highp float _PlanetOpacity;
uniform highp vec3 _PlanetOrigin;
#line 548
#line 422
highp vec4 Derivatives( in highp float lat, in highp float lon, in highp vec3 pos ) {
    highp vec2 latLong = vec2( lat, lon);
    highp float latDdx = (0.159155 * length(xll_dFdx_vf2(pos.xz)));
    #line 426
    highp float latDdy = (0.159155 * length(xll_dFdy_vf2(pos.xz)));
    highp float longDdx = xll_dFdx_f(lon);
    highp float longDdy = xll_dFdy_f(lon);
    return vec4( latDdx, longDdx, latDdy, longDdy);
}
#line 431
highp vec2 GetSphereUV( in highp vec3 sphereVect, in highp vec2 uvOffset ) {
    highp vec2 uv;
    uv.x = (0.5 + (0.159155 * atan( sphereVect.x, sphereVect.z)));
    #line 435
    uv.y = (0.31831 * acos(sphereVect.y));
    uv += uvOffset;
    return uv;
}
#line 469
mediump vec4 GetShereDetailMap( in sampler2D texSampler, in highp vec3 sphereVect, in highp float detailScale ) {
    highp vec3 sphereVectNorm = normalize(sphereVect);
    highp vec2 uv = ((GetSphereUV( sphereVectNorm, vec2( 0.0, 0.0)) * 4.0) * detailScale);
    #line 473
    highp vec4 uvdd = Derivatives( (uv.x - 0.5), uv.y, sphereVectNorm);
    sphereVectNorm = abs(sphereVectNorm);
    mediump float zxlerp = step( sphereVectNorm.x, sphereVectNorm.z);
    mediump float nylerp = step( sphereVectNorm.y, mix( sphereVectNorm.x, sphereVectNorm.z, zxlerp));
    #line 477
    mediump vec3 detailCoords = mix( sphereVectNorm.xyz, sphereVectNorm.zxy, vec3( zxlerp));
    detailCoords = mix( sphereVectNorm.yxz, detailCoords, vec3( nylerp));
    return xll_tex2Dgrad( texSampler, (((0.5 * detailCoords.zy) / abs(detailCoords.x)) * detailScale), uvdd.xy, uvdd.zw);
}
#line 448
mediump vec4 GetSphereMap( in sampler2D texSampler, in highp vec3 sphereVect ) {
    highp vec3 sphereVectNorm = normalize(sphereVect);
    highp vec2 uv = GetSphereUV( sphereVectNorm, vec2( 0.0, 0.0));
    #line 452
    highp vec4 uvdd = Derivatives( (uv.x - 0.5), uv.y, sphereVectNorm);
    mediump vec4 tex = xll_tex2Dgrad( texSampler, uv, uvdd.xy, uvdd.zw);
    return tex;
}
#line 497
mediump vec4 SpecularColorLight( in mediump vec3 lightDir, in mediump vec3 viewDir, in mediump vec3 normal, in mediump vec4 color, in mediump vec4 specColor, in highp float specK, in mediump float atten ) {
    lightDir = normalize(lightDir);
    viewDir = normalize(viewDir);
    #line 501
    mediump vec3 h = normalize((lightDir + viewDir));
    mediump float diffuse = dot( normal, lightDir);
    highp float nh = xll_saturate_f(dot( h, normal));
    highp float spec = (pow( nh, specK) * color.w);
    #line 505
    mediump vec4 c;
    c.xyz = ((((color.xyz * _LightColor0.xyz) * diffuse) + ((_LightColor0.xyz * specColor.xyz) * spec)) * (atten * 4.0));
    c.w = (diffuse * (atten * 4.0));
    return c;
}
#line 336
lowp float UnitySpotAttenuate( in highp vec3 LightCoord ) {
    return texture( _LightTextureB0, vec2( dot( LightCoord, LightCoord))).w;
}
#line 332
lowp float UnitySpotCookie( in highp vec4 LightCoord ) {
    return texture( _LightTexture0, ((LightCoord.xy / LightCoord.w) + 0.5)).w;
}
#line 317
lowp float unitySampleShadow( in highp vec4 shadowCoord ) {
    #line 319
    highp vec3 coord = (shadowCoord.xyz / shadowCoord.w);
    highp vec4 shadowVals;
    shadowVals.x = texture( _ShadowMapTexture, (vec2( coord) + _ShadowOffsets[0].xy)).x;
    shadowVals.y = texture( _ShadowMapTexture, (vec2( coord) + _ShadowOffsets[1].xy)).x;
    #line 323
    shadowVals.z = texture( _ShadowMapTexture, (vec2( coord) + _ShadowOffsets[2].xy)).x;
    shadowVals.w = texture( _ShadowMapTexture, (vec2( coord) + _ShadowOffsets[3].xy)).x;
    mediump vec4 shadows = xll_vecTSel_vb4_vf4_vf4 (lessThan( shadowVals, coord.zzzz), vec4( _LightShadowData.xxxx), vec4( 1.0));
    mediump float shadow = dot( shadows, vec4( 0.25));
    #line 327
    return shadow;
}
#line 563
lowp vec4 frag( in v2f IN ) {
    #line 565
    mediump vec4 color;
    highp vec3 sphereNrm = IN.sphereNormal;
    mediump vec4 main = GetSphereMap( _MainTex, sphereNrm);
    mediump vec4 detail = GetShereDetailMap( _DetailTex, sphereNrm, _DetailScale);
    #line 569
    color = _SurfaceColor;
    mediump float detailLevel = xll_saturate_f(((2.0 * _DetailDist) * IN.viewDist));
    color.xyz += (0.5 * mix( (detail.xyz - 0.5), vec3( 0.0), vec3( detailLevel)));
    mediump float handoff = xll_saturate_f(pow( _PlanetOpacity, 2.0));
    #line 573
    color.xyz = mix( color.xyz, main.xyz, vec3( handoff));
    mediump vec4 specColor = _SpecColor;
    specColor.w = mix( 1.0, main.w, handoff);
    mediump vec4 colorLight = SpecularColorLight( vec3( normalize(_WorldSpaceLightPos0)), IN.viewDir, normalize((IN.worldPos - _PlanetOrigin)), color, specColor, (_Shininess * 128.0), (((float((IN._LightCoord.z > 0.0)) * UnitySpotCookie( IN._LightCoord)) * UnitySpotAttenuate( IN._LightCoord.xyz)) * unitySampleShadow( IN._ShadowCoord)));
    #line 577
    color.w = mix( 1.0, color.w, xll_saturate_f((colorLight.w * 4.0)));
    color.w = mix( color.w, 1.0, xll_saturate_f((length(colorLight.xyz) - length((2.0 * color.xyz)))));
    color.w = mix( color.w, 1.0, handoff);
    color.xyz = colorLight.xyz;
    #line 581
    return color;
}
in highp float xlv_TEXCOORD0;
in highp vec3 xlv_TEXCOORD1;
in highp vec3 xlv_TEXCOORD2;
in highp vec4 xlv_TEXCOORD3;
in highp vec4 xlv_TEXCOORD4;
in highp vec3 xlv_TEXCOORD5;
void main() {
    lowp vec4 xl_retval;
    v2f xlt_IN;
    xlt_IN.pos = vec4(0.0);
    xlt_IN.viewDist = float(xlv_TEXCOORD0);
    xlt_IN.viewDir = vec3(xlv_TEXCOORD1);
    xlt_IN.worldPos = vec3(xlv_TEXCOORD2);
    xlt_IN._LightCoord = vec4(xlv_TEXCOORD3);
    xlt_IN._ShadowCoord = vec4(xlv_TEXCOORD4);
    xlt_IN.sphereNormal = vec3(xlv_TEXCOORD5);
    xl_retval = frag( xlt_IN);
    gl_FragData[0] = vec4(xl_retval);
}


#endif"
}

SubProgram "opengl " {
Keywords { "SPOT" "SHADOWS_DEPTH" "SHADOWS_SOFT" "SHADOWS_NATIVE" }
"!!GLSL
#ifdef VERTEX
varying vec3 xlv_TEXCOORD5;
varying vec4 xlv_TEXCOORD4;
varying vec4 xlv_TEXCOORD3;
varying vec3 xlv_TEXCOORD2;
varying vec3 xlv_TEXCOORD1;
varying float xlv_TEXCOORD0;
uniform mat4 _LightMatrix0;
uniform mat4 _Object2World;

uniform mat4 unity_World2Shadow[4];
uniform vec3 _WorldSpaceCameraPos;
void main ()
{
  vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * gl_Vertex).xyz;
  vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  vec4 tmpvar_3;
  tmpvar_3.x = gl_MultiTexCoord0.x;
  tmpvar_3.y = gl_MultiTexCoord0.y;
  tmpvar_3.z = gl_MultiTexCoord1.x;
  tmpvar_3.w = gl_MultiTexCoord1.y;
  gl_Position = (gl_ModelViewProjectionMatrix * gl_Vertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * gl_Vertex));
  xlv_TEXCOORD4 = (unity_World2Shadow[0] * (_Object2World * gl_Vertex));
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}


#endif
#ifdef FRAGMENT
#extension GL_ARB_shader_texture_lod : enable
varying vec3 xlv_TEXCOORD5;
varying vec4 xlv_TEXCOORD4;
varying vec4 xlv_TEXCOORD3;
varying vec3 xlv_TEXCOORD2;
varying vec3 xlv_TEXCOORD1;
varying float xlv_TEXCOORD0;
uniform vec3 _PlanetOrigin;
uniform float _PlanetOpacity;
uniform float _DetailDist;
uniform float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform float _Shininess;
uniform vec4 _SurfaceColor;
uniform vec4 _SpecColor;
uniform vec4 _LightColor0;
uniform sampler2D _LightTextureB0;
uniform sampler2D _LightTexture0;
uniform vec4 _ShadowOffsets[4];
uniform sampler2DShadow _ShadowMapTexture;
uniform vec4 _LightShadowData;
uniform vec4 _WorldSpaceLightPos0;
void main ()
{
  vec4 main_1;
  vec4 color_2;
  vec3 tmpvar_3;
  tmpvar_3 = normalize(xlv_TEXCOORD5);
  vec2 uv_4;
  float r_5;
  if ((abs(tmpvar_3.z) > (1e-08 * abs(tmpvar_3.x)))) {
    float y_over_x_6;
    y_over_x_6 = (tmpvar_3.x / tmpvar_3.z);
    float s_7;
    float x_8;
    x_8 = (y_over_x_6 * inversesqrt(((y_over_x_6 * y_over_x_6) + 1.0)));
    s_7 = (sign(x_8) * (1.5708 - (sqrt((1.0 - abs(x_8))) * (1.5708 + (abs(x_8) * (-0.214602 + (abs(x_8) * (0.0865667 + (abs(x_8) * -0.0310296)))))))));
    r_5 = s_7;
    if ((tmpvar_3.z < 0.0)) {
      if ((tmpvar_3.x >= 0.0)) {
        r_5 = (s_7 + 3.14159);
      } else {
        r_5 = (r_5 - 3.14159);
      };
    };
  } else {
    r_5 = (sign(tmpvar_3.x) * 1.5708);
  };
  uv_4.x = (0.5 + (0.159155 * r_5));
  uv_4.y = (0.31831 * (1.5708 - (sign(tmpvar_3.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_3.y))) * (1.5708 + (abs(tmpvar_3.y) * (-0.214602 + (abs(tmpvar_3.y) * (0.0865667 + (abs(tmpvar_3.y) * -0.0310296)))))))))));
  vec2 tmpvar_9;
  tmpvar_9 = dFdx(tmpvar_3.xz);
  vec2 tmpvar_10;
  tmpvar_10 = dFdy(tmpvar_3.xz);
  vec4 tmpvar_11;
  tmpvar_11.x = (0.159155 * sqrt(dot (tmpvar_9, tmpvar_9)));
  tmpvar_11.y = dFdx(uv_4.y);
  tmpvar_11.z = (0.159155 * sqrt(dot (tmpvar_10, tmpvar_10)));
  tmpvar_11.w = dFdy(uv_4.y);
  main_1 = texture2DGradARB (_MainTex, uv_4, tmpvar_11.xy, tmpvar_11.zw);
  vec3 tmpvar_12;
  tmpvar_12 = normalize(xlv_TEXCOORD5);
  vec2 uv_13;
  float r_14;
  if ((abs(tmpvar_12.z) > (1e-08 * abs(tmpvar_12.x)))) {
    float y_over_x_15;
    y_over_x_15 = (tmpvar_12.x / tmpvar_12.z);
    float s_16;
    float x_17;
    x_17 = (y_over_x_15 * inversesqrt(((y_over_x_15 * y_over_x_15) + 1.0)));
    s_16 = (sign(x_17) * (1.5708 - (sqrt((1.0 - abs(x_17))) * (1.5708 + (abs(x_17) * (-0.214602 + (abs(x_17) * (0.0865667 + (abs(x_17) * -0.0310296)))))))));
    r_14 = s_16;
    if ((tmpvar_12.z < 0.0)) {
      if ((tmpvar_12.x >= 0.0)) {
        r_14 = (s_16 + 3.14159);
      } else {
        r_14 = (r_14 - 3.14159);
      };
    };
  } else {
    r_14 = (sign(tmpvar_12.x) * 1.5708);
  };
  uv_13.x = (0.5 + (0.159155 * r_14));
  uv_13.y = (0.31831 * (1.5708 - (sign(tmpvar_12.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_12.y))) * (1.5708 + (abs(tmpvar_12.y) * (-0.214602 + (abs(tmpvar_12.y) * (0.0865667 + (abs(tmpvar_12.y) * -0.0310296)))))))))));
  vec2 tmpvar_18;
  tmpvar_18 = ((uv_13 * 4.0) * _DetailScale);
  vec2 tmpvar_19;
  tmpvar_19 = dFdx(tmpvar_12.xz);
  vec2 tmpvar_20;
  tmpvar_20 = dFdy(tmpvar_12.xz);
  vec4 tmpvar_21;
  tmpvar_21.x = (0.159155 * sqrt(dot (tmpvar_19, tmpvar_19)));
  tmpvar_21.y = dFdx(tmpvar_18.y);
  tmpvar_21.z = (0.159155 * sqrt(dot (tmpvar_20, tmpvar_20)));
  tmpvar_21.w = dFdy(tmpvar_18.y);
  vec3 tmpvar_22;
  tmpvar_22 = abs(tmpvar_12);
  float tmpvar_23;
  tmpvar_23 = float((tmpvar_22.z >= tmpvar_22.x));
  vec3 tmpvar_24;
  tmpvar_24 = mix (tmpvar_22.yxz, mix (tmpvar_22, tmpvar_22.zxy, vec3(tmpvar_23)), vec3(float((mix (tmpvar_22.x, tmpvar_22.z, tmpvar_23) >= tmpvar_22.y))));
  color_2.w = _SurfaceColor.w;
  color_2.xyz = (_SurfaceColor.xyz + (0.5 * mix ((texture2DGradARB (_DetailTex, (((0.5 * tmpvar_24.zy) / abs(tmpvar_24.x)) * _DetailScale), tmpvar_21.xy, tmpvar_21.zw).xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0)))));
  float tmpvar_25;
  tmpvar_25 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  color_2.xyz = mix (color_2.xyz, main_1.xyz, vec3(tmpvar_25));
  vec3 tmpvar_26;
  tmpvar_26 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  vec4 shadows_27;
  vec3 tmpvar_28;
  tmpvar_28 = (xlv_TEXCOORD4.xyz / xlv_TEXCOORD4.w);
  shadows_27.x = shadow2D (_ShadowMapTexture, (tmpvar_28 + _ShadowOffsets[0].xyz)).x;
  shadows_27.y = shadow2D (_ShadowMapTexture, (tmpvar_28 + _ShadowOffsets[1].xyz)).x;
  shadows_27.z = shadow2D (_ShadowMapTexture, (tmpvar_28 + _ShadowOffsets[2].xyz)).x;
  shadows_27.w = shadow2D (_ShadowMapTexture, (tmpvar_28 + _ShadowOffsets[3].xyz)).x;
  vec4 tmpvar_29;
  tmpvar_29 = (_LightShadowData.xxxx + (shadows_27 * (1.0 - _LightShadowData.xxxx)));
  shadows_27 = tmpvar_29;
  float atten_30;
  atten_30 = (((float((xlv_TEXCOORD3.z > 0.0)) * texture2D (_LightTexture0, ((xlv_TEXCOORD3.xy / xlv_TEXCOORD3.w) + 0.5)).w) * texture2D (_LightTextureB0, vec2(dot (xlv_TEXCOORD3.xyz, xlv_TEXCOORD3.xyz))).w) * dot (tmpvar_29, vec4(0.25, 0.25, 0.25, 0.25)));
  vec4 c_31;
  vec3 tmpvar_32;
  tmpvar_32 = normalize(normalize(_WorldSpaceLightPos0).xyz);
  float tmpvar_33;
  tmpvar_33 = dot (tmpvar_26, tmpvar_32);
  c_31.xyz = ((((color_2.xyz * _LightColor0.xyz) * tmpvar_33) + ((_LightColor0.xyz * _SpecColor.xyz) * (pow (clamp (dot (normalize((tmpvar_32 + normalize(xlv_TEXCOORD1))), tmpvar_26), 0.0, 1.0), (_Shininess * 128.0)) * _SurfaceColor.w))) * (atten_30 * 4.0));
  c_31.w = (tmpvar_33 * (atten_30 * 4.0));
  color_2.w = mix (1.0, _SurfaceColor.w, clamp ((c_31.w * 4.0), 0.0, 1.0));
  vec3 arg0_34;
  arg0_34 = (2.0 * color_2.xyz);
  color_2.w = mix (color_2.w, 1.0, clamp ((sqrt(dot (c_31.xyz, c_31.xyz)) - sqrt(dot (arg0_34, arg0_34))), 0.0, 1.0));
  color_2.w = mix (color_2.w, 1.0, tmpvar_25);
  color_2.xyz = c_31.xyz;
  gl_FragData[0] = color_2;
}


#endif
"
}

SubProgram "d3d9 " {
Keywords { "SPOT" "SHADOWS_DEPTH" "SHADOWS_SOFT" "SHADOWS_NATIVE" }
Bind "vertex" Vertex
Bind "texcoord" TexCoord0
Bind "texcoord1" TexCoord1
Matrix 0 [glstate_matrix_mvp]
Vector 16 [_WorldSpaceCameraPos]
Matrix 4 [unity_World2Shadow0]
Matrix 8 [_Object2World]
Matrix 12 [_LightMatrix0]
"vs_3_0
; 29 ALU
dcl_position o0
dcl_texcoord0 o1
dcl_texcoord1 o2
dcl_texcoord2 o3
dcl_texcoord3 o4
dcl_texcoord4 o5
dcl_texcoord5 o6
dcl_position0 v0
dcl_texcoord0 v1
dcl_texcoord1 v2
mov r1.zw, v2.xyxy
mov r1.xy, v1
dp4 r0.w, r1, r1
rsq r1.w, r0.w
mul r1.xyz, r1.w, r1
dp4 r1.w, v0, c11
dp4 r0.z, v0, c10
dp4 r0.x, v0, c8
dp4 r0.y, v0, c9
add r2.xyz, -r0, c16
dp3 r0.w, r2, r2
rsq r0.w, r0.w
mov o6.xyz, -r1
mov r1.xyz, r0
mul o2.xyz, r0.w, r2
dp4 o4.w, r1, c15
dp4 o4.z, r1, c14
dp4 o4.y, r1, c13
dp4 o4.x, r1, c12
dp4 o5.w, r1, c7
dp4 o5.z, r1, c6
dp4 o5.y, r1, c5
dp4 o5.x, r1, c4
rcp o1.x, r0.w
mov o3.xyz, r0
dp4 o0.w, v0, c3
dp4 o0.z, v0, c2
dp4 o0.y, v0, c1
dp4 o0.x, v0, c0
"
}

SubProgram "gles " {
Keywords { "SPOT" "SHADOWS_DEPTH" "SHADOWS_SOFT" "SHADOWS_NATIVE" }
"!!GLES


#ifdef VERTEX

#extension GL_EXT_shadow_samplers : enable
varying highp vec3 xlv_TEXCOORD5;
varying highp vec4 xlv_TEXCOORD4;
varying highp vec4 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp mat4 _LightMatrix0;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec3 _WorldSpaceCameraPos;
attribute vec4 _glesMultiTexCoord1;
attribute vec4 _glesMultiTexCoord0;
attribute vec4 _glesVertex;
void main ()
{
  highp vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * _glesVertex).xyz;
  highp vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  highp vec4 tmpvar_3;
  tmpvar_3.x = _glesMultiTexCoord0.x;
  tmpvar_3.y = _glesMultiTexCoord0.y;
  tmpvar_3.z = _glesMultiTexCoord1.x;
  tmpvar_3.w = _glesMultiTexCoord1.y;
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * _glesVertex));
  xlv_TEXCOORD4 = (unity_World2Shadow[0] * (_Object2World * _glesVertex));
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}



#endif
#ifdef FRAGMENT

#extension GL_EXT_shader_texture_lod : enable
#extension GL_OES_standard_derivatives : enable
#extension GL_EXT_shadow_samplers : enable
varying highp vec3 xlv_TEXCOORD5;
varying highp vec4 xlv_TEXCOORD4;
varying highp vec4 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp vec3 _PlanetOrigin;
uniform highp float _PlanetOpacity;
uniform highp float _DetailDist;
uniform highp float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform highp float _Shininess;
uniform lowp vec4 _SurfaceColor;
uniform lowp vec4 _SpecColor;
uniform lowp vec4 _LightColor0;
uniform sampler2D _LightTextureB0;
uniform sampler2D _LightTexture0;
uniform highp vec4 _ShadowOffsets[4];
uniform lowp sampler2DShadow _ShadowMapTexture;
uniform highp vec4 _LightShadowData;
uniform highp vec4 _WorldSpaceLightPos0;
void main ()
{
  lowp vec4 tmpvar_1;
  mediump vec4 specColor_2;
  mediump float handoff_3;
  mediump float detailLevel_4;
  mediump vec4 color_5;
  mediump vec4 tex_6;
  highp vec3 tmpvar_7;
  tmpvar_7 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_8;
  highp float r_9;
  if ((abs(tmpvar_7.z) > (1e-08 * abs(tmpvar_7.x)))) {
    highp float y_over_x_10;
    y_over_x_10 = (tmpvar_7.x / tmpvar_7.z);
    highp float s_11;
    highp float x_12;
    x_12 = (y_over_x_10 * inversesqrt(((y_over_x_10 * y_over_x_10) + 1.0)));
    s_11 = (sign(x_12) * (1.5708 - (sqrt((1.0 - abs(x_12))) * (1.5708 + (abs(x_12) * (-0.214602 + (abs(x_12) * (0.0865667 + (abs(x_12) * -0.0310296)))))))));
    r_9 = s_11;
    if ((tmpvar_7.z < 0.0)) {
      if ((tmpvar_7.x >= 0.0)) {
        r_9 = (s_11 + 3.14159);
      } else {
        r_9 = (r_9 - 3.14159);
      };
    };
  } else {
    r_9 = (sign(tmpvar_7.x) * 1.5708);
  };
  uv_8.x = (0.5 + (0.159155 * r_9));
  uv_8.y = (0.31831 * (1.5708 - (sign(tmpvar_7.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_7.y))) * (1.5708 + (abs(tmpvar_7.y) * (-0.214602 + (abs(tmpvar_7.y) * (0.0865667 + (abs(tmpvar_7.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_13;
  tmpvar_13 = dFdx(tmpvar_7.xz);
  highp vec2 tmpvar_14;
  tmpvar_14 = dFdy(tmpvar_7.xz);
  highp vec4 tmpvar_15;
  tmpvar_15.x = (0.159155 * sqrt(dot (tmpvar_13, tmpvar_13)));
  tmpvar_15.y = dFdx(uv_8.y);
  tmpvar_15.z = (0.159155 * sqrt(dot (tmpvar_14, tmpvar_14)));
  tmpvar_15.w = dFdy(uv_8.y);
  lowp vec4 tmpvar_16;
  tmpvar_16 = texture2DGradEXT (_MainTex, uv_8, tmpvar_15.xy, tmpvar_15.zw);
  tex_6 = tmpvar_16;
  mediump vec4 tmpvar_17;
  mediump vec3 detailCoords_18;
  mediump float nylerp_19;
  mediump float zxlerp_20;
  highp vec3 tmpvar_21;
  tmpvar_21 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_22;
  highp float r_23;
  if ((abs(tmpvar_21.z) > (1e-08 * abs(tmpvar_21.x)))) {
    highp float y_over_x_24;
    y_over_x_24 = (tmpvar_21.x / tmpvar_21.z);
    highp float s_25;
    highp float x_26;
    x_26 = (y_over_x_24 * inversesqrt(((y_over_x_24 * y_over_x_24) + 1.0)));
    s_25 = (sign(x_26) * (1.5708 - (sqrt((1.0 - abs(x_26))) * (1.5708 + (abs(x_26) * (-0.214602 + (abs(x_26) * (0.0865667 + (abs(x_26) * -0.0310296)))))))));
    r_23 = s_25;
    if ((tmpvar_21.z < 0.0)) {
      if ((tmpvar_21.x >= 0.0)) {
        r_23 = (s_25 + 3.14159);
      } else {
        r_23 = (r_23 - 3.14159);
      };
    };
  } else {
    r_23 = (sign(tmpvar_21.x) * 1.5708);
  };
  uv_22.x = (0.5 + (0.159155 * r_23));
  uv_22.y = (0.31831 * (1.5708 - (sign(tmpvar_21.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_21.y))) * (1.5708 + (abs(tmpvar_21.y) * (-0.214602 + (abs(tmpvar_21.y) * (0.0865667 + (abs(tmpvar_21.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_27;
  tmpvar_27 = ((uv_22 * 4.0) * _DetailScale);
  highp vec2 tmpvar_28;
  tmpvar_28 = dFdx(tmpvar_21.xz);
  highp vec2 tmpvar_29;
  tmpvar_29 = dFdy(tmpvar_21.xz);
  highp vec4 tmpvar_30;
  tmpvar_30.x = (0.159155 * sqrt(dot (tmpvar_28, tmpvar_28)));
  tmpvar_30.y = dFdx(tmpvar_27.y);
  tmpvar_30.z = (0.159155 * sqrt(dot (tmpvar_29, tmpvar_29)));
  tmpvar_30.w = dFdy(tmpvar_27.y);
  highp vec3 tmpvar_31;
  tmpvar_31 = abs(tmpvar_21);
  highp float tmpvar_32;
  tmpvar_32 = float((tmpvar_31.z >= tmpvar_31.x));
  zxlerp_20 = tmpvar_32;
  highp float tmpvar_33;
  tmpvar_33 = float((mix (tmpvar_31.x, tmpvar_31.z, zxlerp_20) >= tmpvar_31.y));
  nylerp_19 = tmpvar_33;
  highp vec3 tmpvar_34;
  tmpvar_34 = mix (tmpvar_31, tmpvar_31.zxy, vec3(zxlerp_20));
  detailCoords_18 = tmpvar_34;
  highp vec3 tmpvar_35;
  tmpvar_35 = mix (tmpvar_31.yxz, detailCoords_18, vec3(nylerp_19));
  detailCoords_18 = tmpvar_35;
  mediump float tmpvar_36;
  tmpvar_36 = abs(detailCoords_18.x);
  highp vec2 coord_37;
  coord_37 = (((0.5 * detailCoords_18.zy) / tmpvar_36) * _DetailScale);
  lowp vec4 tmpvar_38;
  tmpvar_38 = texture2DGradEXT (_DetailTex, coord_37, tmpvar_30.xy, tmpvar_30.zw);
  tmpvar_17 = tmpvar_38;
  color_5 = _SurfaceColor;
  highp float tmpvar_39;
  tmpvar_39 = clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0);
  detailLevel_4 = tmpvar_39;
  color_5.xyz = (color_5.xyz + (0.5 * mix ((tmpvar_17.xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(detailLevel_4))));
  highp float tmpvar_40;
  tmpvar_40 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  handoff_3 = tmpvar_40;
  color_5.xyz = mix (color_5.xyz, tex_6.xyz, vec3(handoff_3));
  specColor_2.xyz = _SpecColor.xyz;
  specColor_2.w = mix (1.0, tex_6.w, handoff_3);
  highp vec3 tmpvar_41;
  tmpvar_41 = normalize(_WorldSpaceLightPos0).xyz;
  highp vec3 tmpvar_42;
  tmpvar_42 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  lowp vec4 tmpvar_43;
  highp vec2 P_44;
  P_44 = ((xlv_TEXCOORD3.xy / xlv_TEXCOORD3.w) + 0.5);
  tmpvar_43 = texture2D (_LightTexture0, P_44);
  highp float tmpvar_45;
  tmpvar_45 = dot (xlv_TEXCOORD3.xyz, xlv_TEXCOORD3.xyz);
  lowp vec4 tmpvar_46;
  tmpvar_46 = texture2D (_LightTextureB0, vec2(tmpvar_45));
  lowp float tmpvar_47;
  mediump vec4 shadows_48;
  highp vec3 tmpvar_49;
  tmpvar_49 = (xlv_TEXCOORD4.xyz / xlv_TEXCOORD4.w);
  highp vec3 coord_50;
  coord_50 = (tmpvar_49 + _ShadowOffsets[0].xyz);
  lowp float tmpvar_51;
  tmpvar_51 = shadow2DEXT (_ShadowMapTexture, coord_50);
  shadows_48.x = tmpvar_51;
  highp vec3 coord_52;
  coord_52 = (tmpvar_49 + _ShadowOffsets[1].xyz);
  lowp float tmpvar_53;
  tmpvar_53 = shadow2DEXT (_ShadowMapTexture, coord_52);
  shadows_48.y = tmpvar_53;
  highp vec3 coord_54;
  coord_54 = (tmpvar_49 + _ShadowOffsets[2].xyz);
  lowp float tmpvar_55;
  tmpvar_55 = shadow2DEXT (_ShadowMapTexture, coord_54);
  shadows_48.z = tmpvar_55;
  highp vec3 coord_56;
  coord_56 = (tmpvar_49 + _ShadowOffsets[3].xyz);
  lowp float tmpvar_57;
  tmpvar_57 = shadow2DEXT (_ShadowMapTexture, coord_56);
  shadows_48.w = tmpvar_57;
  highp vec4 tmpvar_58;
  tmpvar_58 = (_LightShadowData.xxxx + (shadows_48 * (1.0 - _LightShadowData.xxxx)));
  shadows_48 = tmpvar_58;
  mediump float tmpvar_59;
  tmpvar_59 = dot (shadows_48, vec4(0.25, 0.25, 0.25, 0.25));
  tmpvar_47 = tmpvar_59;
  mediump vec3 lightDir_60;
  lightDir_60 = tmpvar_41;
  mediump vec3 viewDir_61;
  viewDir_61 = xlv_TEXCOORD1;
  mediump vec3 normal_62;
  normal_62 = tmpvar_42;
  mediump float atten_63;
  atten_63 = (((float((xlv_TEXCOORD3.z > 0.0)) * tmpvar_43.w) * tmpvar_46.w) * tmpvar_47);
  mediump vec4 c_64;
  highp float nh_65;
  mediump vec3 tmpvar_66;
  tmpvar_66 = normalize(lightDir_60);
  lightDir_60 = tmpvar_66;
  mediump vec3 tmpvar_67;
  tmpvar_67 = normalize(viewDir_61);
  viewDir_61 = tmpvar_67;
  mediump float tmpvar_68;
  tmpvar_68 = dot (normal_62, tmpvar_66);
  mediump float tmpvar_69;
  tmpvar_69 = clamp (dot (normalize((tmpvar_66 + tmpvar_67)), normal_62), 0.0, 1.0);
  nh_65 = tmpvar_69;
  highp vec3 tmpvar_70;
  tmpvar_70 = ((((color_5.xyz * _LightColor0.xyz) * tmpvar_68) + ((_LightColor0.xyz * specColor_2.xyz) * (pow (nh_65, (_Shininess * 128.0)) * color_5.w))) * (atten_63 * 4.0));
  c_64.xyz = tmpvar_70;
  c_64.w = (tmpvar_68 * (atten_63 * 4.0));
  color_5.w = mix (1.0, color_5.w, clamp ((c_64.w * 4.0), 0.0, 1.0));
  mediump vec3 arg0_71;
  arg0_71 = (2.0 * color_5.xyz);
  color_5.w = mix (color_5.w, 1.0, clamp ((sqrt(dot (c_64.xyz, c_64.xyz)) - sqrt(dot (arg0_71, arg0_71))), 0.0, 1.0));
  color_5.w = mix (color_5.w, 1.0, handoff_3);
  color_5.xyz = c_64.xyz;
  tmpvar_1 = color_5;
  gl_FragData[0] = tmpvar_1;
}



#endif"
}

SubProgram "gles3 " {
Keywords { "SPOT" "SHADOWS_DEPTH" "SHADOWS_SOFT" "SHADOWS_NATIVE" }
"!!GLES3#version 300 es


#ifdef VERTEX

#define gl_Vertex _glesVertex
in vec4 _glesVertex;
#define gl_Normal (normalize(_glesNormal))
in vec3 _glesNormal;
#define gl_MultiTexCoord0 _glesMultiTexCoord0
in vec4 _glesMultiTexCoord0;
#define gl_MultiTexCoord1 _glesMultiTexCoord1
in vec4 _glesMultiTexCoord1;

#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 340
struct SurfaceOutput {
    lowp vec3 Albedo;
    lowp vec3 Normal;
    lowp vec3 Emission;
    mediump float Specular;
    lowp float Gloss;
    lowp float Alpha;
};
#line 537
struct v2f {
    highp vec4 pos;
    highp float viewDist;
    highp vec3 viewDir;
    highp vec3 worldPos;
    highp vec4 _LightCoord;
    highp vec4 _ShadowCoord;
    highp vec3 sphereNormal;
};
#line 529
struct appdata_t {
    highp vec4 vertex;
    highp vec3 normal;
    highp vec4 texcoord;
    highp vec4 texcoord2;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform highp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform lowp sampler2DShadow _ShadowMapTexture;
uniform highp vec4 _ShadowOffsets[4];
uniform sampler2D _LightTexture0;
uniform highp mat4 _LightMatrix0;
#line 331
uniform sampler2D _LightTextureB0;
#line 336
#line 350
uniform lowp vec4 _LightColor0;
uniform lowp vec4 _SpecColor;
#line 363
#line 371
#line 385
uniform highp mat4 _MainRotation;
uniform highp mat4 _DetailRotation;
#line 418
#line 422
#line 431
#line 439
#line 448
#line 456
#line 469
#line 481
#line 497
#line 510
uniform lowp vec4 _SurfaceColor;
#line 518
uniform highp float _Shininess;
uniform sampler2D _MainTex;
uniform sampler2D _DetailTex;
uniform highp float _DetailScale;
#line 522
uniform highp float _DetailDist;
uniform highp float _MinLight;
uniform sampler2D _CameraDepthTexture;
uniform highp mat4 _CameraToWorld;
#line 526
uniform highp float _LightPower;
uniform highp float _PlanetOpacity;
uniform highp vec3 _PlanetOrigin;
#line 548
#line 548
v2f vert( in appdata_t v ) {
    v2f o;
    highp vec4 vertex = v.vertex;
    #line 552
    o.pos = (glstate_matrix_mvp * vertex).xyzw;
    highp vec3 vertexPos = (_Object2World * vertex).xyz;
    o.viewDist = distance( vertexPos, _WorldSpaceCameraPos);
    o.worldPos = vertexPos;
    #line 556
    o.sphereNormal = (-normalize(vec4( v.texcoord.x, v.texcoord.y, v.texcoord2.x, v.texcoord2.y)).xyz);
    o.viewDir = normalize((_WorldSpaceCameraPos.xyz - vertexPos));
    o._LightCoord = (_LightMatrix0 * (_Object2World * v.vertex));
    o._ShadowCoord = (unity_World2Shadow[0] * (_Object2World * v.vertex));
    #line 561
    return o;
}
out highp float xlv_TEXCOORD0;
out highp vec3 xlv_TEXCOORD1;
out highp vec3 xlv_TEXCOORD2;
out highp vec4 xlv_TEXCOORD3;
out highp vec4 xlv_TEXCOORD4;
out highp vec3 xlv_TEXCOORD5;
void main() {
    v2f xl_retval;
    appdata_t xlt_v;
    xlt_v.vertex = vec4(gl_Vertex);
    xlt_v.normal = vec3(gl_Normal);
    xlt_v.texcoord = vec4(gl_MultiTexCoord0);
    xlt_v.texcoord2 = vec4(gl_MultiTexCoord1);
    xl_retval = vert( xlt_v);
    gl_Position = vec4(xl_retval.pos);
    xlv_TEXCOORD0 = float(xl_retval.viewDist);
    xlv_TEXCOORD1 = vec3(xl_retval.viewDir);
    xlv_TEXCOORD2 = vec3(xl_retval.worldPos);
    xlv_TEXCOORD3 = vec4(xl_retval._LightCoord);
    xlv_TEXCOORD4 = vec4(xl_retval._ShadowCoord);
    xlv_TEXCOORD5 = vec3(xl_retval.sphereNormal);
}


#endif
#ifdef FRAGMENT

#define gl_FragData _glesFragData
layout(location = 0) out mediump vec4 _glesFragData[4];
float xll_dFdx_f(float f) {
  return dFdx(f);
}
vec2 xll_dFdx_vf2(vec2 v) {
  return dFdx(v);
}
vec3 xll_dFdx_vf3(vec3 v) {
  return dFdx(v);
}
vec4 xll_dFdx_vf4(vec4 v) {
  return dFdx(v);
}
mat2 xll_dFdx_mf2x2(mat2 m) {
  return mat2( dFdx(m[0]), dFdx(m[1]));
}
mat3 xll_dFdx_mf3x3(mat3 m) {
  return mat3( dFdx(m[0]), dFdx(m[1]), dFdx(m[2]));
}
mat4 xll_dFdx_mf4x4(mat4 m) {
  return mat4( dFdx(m[0]), dFdx(m[1]), dFdx(m[2]), dFdx(m[3]));
}
float xll_dFdy_f(float f) {
  return dFdy(f);
}
vec2 xll_dFdy_vf2(vec2 v) {
  return dFdy(v);
}
vec3 xll_dFdy_vf3(vec3 v) {
  return dFdy(v);
}
vec4 xll_dFdy_vf4(vec4 v) {
  return dFdy(v);
}
mat2 xll_dFdy_mf2x2(mat2 m) {
  return mat2( dFdy(m[0]), dFdy(m[1]));
}
mat3 xll_dFdy_mf3x3(mat3 m) {
  return mat3( dFdy(m[0]), dFdy(m[1]), dFdy(m[2]));
}
mat4 xll_dFdy_mf4x4(mat4 m) {
  return mat4( dFdy(m[0]), dFdy(m[1]), dFdy(m[2]), dFdy(m[3]));
}
vec4 xll_tex2Dgrad(sampler2D s, vec2 coord, vec2 ddx, vec2 ddy) {
   return textureGrad( s, coord, ddx, ddy);
}
float xll_shadow2D(mediump sampler2DShadow s, vec3 coord) { return texture (s, coord); }
float xll_saturate_f( float x) {
  return clamp( x, 0.0, 1.0);
}
vec2 xll_saturate_vf2( vec2 x) {
  return clamp( x, 0.0, 1.0);
}
vec3 xll_saturate_vf3( vec3 x) {
  return clamp( x, 0.0, 1.0);
}
vec4 xll_saturate_vf4( vec4 x) {
  return clamp( x, 0.0, 1.0);
}
mat2 xll_saturate_mf2x2(mat2 m) {
  return mat2( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0));
}
mat3 xll_saturate_mf3x3(mat3 m) {
  return mat3( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0));
}
mat4 xll_saturate_mf4x4(mat4 m) {
  return mat4( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0), clamp(m[3], 0.0, 1.0));
}
#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 340
struct SurfaceOutput {
    lowp vec3 Albedo;
    lowp vec3 Normal;
    lowp vec3 Emission;
    mediump float Specular;
    lowp float Gloss;
    lowp float Alpha;
};
#line 537
struct v2f {
    highp vec4 pos;
    highp float viewDist;
    highp vec3 viewDir;
    highp vec3 worldPos;
    highp vec4 _LightCoord;
    highp vec4 _ShadowCoord;
    highp vec3 sphereNormal;
};
#line 529
struct appdata_t {
    highp vec4 vertex;
    highp vec3 normal;
    highp vec4 texcoord;
    highp vec4 texcoord2;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform highp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform lowp sampler2DShadow _ShadowMapTexture;
uniform highp vec4 _ShadowOffsets[4];
uniform sampler2D _LightTexture0;
uniform highp mat4 _LightMatrix0;
#line 331
uniform sampler2D _LightTextureB0;
#line 336
#line 350
uniform lowp vec4 _LightColor0;
uniform lowp vec4 _SpecColor;
#line 363
#line 371
#line 385
uniform highp mat4 _MainRotation;
uniform highp mat4 _DetailRotation;
#line 418
#line 422
#line 431
#line 439
#line 448
#line 456
#line 469
#line 481
#line 497
#line 510
uniform lowp vec4 _SurfaceColor;
#line 518
uniform highp float _Shininess;
uniform sampler2D _MainTex;
uniform sampler2D _DetailTex;
uniform highp float _DetailScale;
#line 522
uniform highp float _DetailDist;
uniform highp float _MinLight;
uniform sampler2D _CameraDepthTexture;
uniform highp mat4 _CameraToWorld;
#line 526
uniform highp float _LightPower;
uniform highp float _PlanetOpacity;
uniform highp vec3 _PlanetOrigin;
#line 548
#line 422
highp vec4 Derivatives( in highp float lat, in highp float lon, in highp vec3 pos ) {
    highp vec2 latLong = vec2( lat, lon);
    highp float latDdx = (0.159155 * length(xll_dFdx_vf2(pos.xz)));
    #line 426
    highp float latDdy = (0.159155 * length(xll_dFdy_vf2(pos.xz)));
    highp float longDdx = xll_dFdx_f(lon);
    highp float longDdy = xll_dFdy_f(lon);
    return vec4( latDdx, longDdx, latDdy, longDdy);
}
#line 431
highp vec2 GetSphereUV( in highp vec3 sphereVect, in highp vec2 uvOffset ) {
    highp vec2 uv;
    uv.x = (0.5 + (0.159155 * atan( sphereVect.x, sphereVect.z)));
    #line 435
    uv.y = (0.31831 * acos(sphereVect.y));
    uv += uvOffset;
    return uv;
}
#line 469
mediump vec4 GetShereDetailMap( in sampler2D texSampler, in highp vec3 sphereVect, in highp float detailScale ) {
    highp vec3 sphereVectNorm = normalize(sphereVect);
    highp vec2 uv = ((GetSphereUV( sphereVectNorm, vec2( 0.0, 0.0)) * 4.0) * detailScale);
    #line 473
    highp vec4 uvdd = Derivatives( (uv.x - 0.5), uv.y, sphereVectNorm);
    sphereVectNorm = abs(sphereVectNorm);
    mediump float zxlerp = step( sphereVectNorm.x, sphereVectNorm.z);
    mediump float nylerp = step( sphereVectNorm.y, mix( sphereVectNorm.x, sphereVectNorm.z, zxlerp));
    #line 477
    mediump vec3 detailCoords = mix( sphereVectNorm.xyz, sphereVectNorm.zxy, vec3( zxlerp));
    detailCoords = mix( sphereVectNorm.yxz, detailCoords, vec3( nylerp));
    return xll_tex2Dgrad( texSampler, (((0.5 * detailCoords.zy) / abs(detailCoords.x)) * detailScale), uvdd.xy, uvdd.zw);
}
#line 448
mediump vec4 GetSphereMap( in sampler2D texSampler, in highp vec3 sphereVect ) {
    highp vec3 sphereVectNorm = normalize(sphereVect);
    highp vec2 uv = GetSphereUV( sphereVectNorm, vec2( 0.0, 0.0));
    #line 452
    highp vec4 uvdd = Derivatives( (uv.x - 0.5), uv.y, sphereVectNorm);
    mediump vec4 tex = xll_tex2Dgrad( texSampler, uv, uvdd.xy, uvdd.zw);
    return tex;
}
#line 497
mediump vec4 SpecularColorLight( in mediump vec3 lightDir, in mediump vec3 viewDir, in mediump vec3 normal, in mediump vec4 color, in mediump vec4 specColor, in highp float specK, in mediump float atten ) {
    lightDir = normalize(lightDir);
    viewDir = normalize(viewDir);
    #line 501
    mediump vec3 h = normalize((lightDir + viewDir));
    mediump float diffuse = dot( normal, lightDir);
    highp float nh = xll_saturate_f(dot( h, normal));
    highp float spec = (pow( nh, specK) * color.w);
    #line 505
    mediump vec4 c;
    c.xyz = ((((color.xyz * _LightColor0.xyz) * diffuse) + ((_LightColor0.xyz * specColor.xyz) * spec)) * (atten * 4.0));
    c.w = (diffuse * (atten * 4.0));
    return c;
}
#line 336
lowp float UnitySpotAttenuate( in highp vec3 LightCoord ) {
    return texture( _LightTextureB0, vec2( dot( LightCoord, LightCoord))).w;
}
#line 332
lowp float UnitySpotCookie( in highp vec4 LightCoord ) {
    return texture( _LightTexture0, ((LightCoord.xy / LightCoord.w) + 0.5)).w;
}
#line 317
lowp float unitySampleShadow( in highp vec4 shadowCoord ) {
    #line 319
    highp vec3 coord = (shadowCoord.xyz / shadowCoord.w);
    mediump vec4 shadows;
    shadows.x = xll_shadow2D( _ShadowMapTexture, (coord + vec3( _ShadowOffsets[0])).xyz);
    shadows.y = xll_shadow2D( _ShadowMapTexture, (coord + vec3( _ShadowOffsets[1])).xyz);
    #line 323
    shadows.z = xll_shadow2D( _ShadowMapTexture, (coord + vec3( _ShadowOffsets[2])).xyz);
    shadows.w = xll_shadow2D( _ShadowMapTexture, (coord + vec3( _ShadowOffsets[3])).xyz);
    shadows = (_LightShadowData.xxxx + (shadows * (1.0 - _LightShadowData.xxxx)));
    mediump float shadow = dot( shadows, vec4( 0.25));
    #line 327
    return shadow;
}
#line 563
lowp vec4 frag( in v2f IN ) {
    #line 565
    mediump vec4 color;
    highp vec3 sphereNrm = IN.sphereNormal;
    mediump vec4 main = GetSphereMap( _MainTex, sphereNrm);
    mediump vec4 detail = GetShereDetailMap( _DetailTex, sphereNrm, _DetailScale);
    #line 569
    color = _SurfaceColor;
    mediump float detailLevel = xll_saturate_f(((2.0 * _DetailDist) * IN.viewDist));
    color.xyz += (0.5 * mix( (detail.xyz - 0.5), vec3( 0.0), vec3( detailLevel)));
    mediump float handoff = xll_saturate_f(pow( _PlanetOpacity, 2.0));
    #line 573
    color.xyz = mix( color.xyz, main.xyz, vec3( handoff));
    mediump vec4 specColor = _SpecColor;
    specColor.w = mix( 1.0, main.w, handoff);
    mediump vec4 colorLight = SpecularColorLight( vec3( normalize(_WorldSpaceLightPos0)), IN.viewDir, normalize((IN.worldPos - _PlanetOrigin)), color, specColor, (_Shininess * 128.0), (((float((IN._LightCoord.z > 0.0)) * UnitySpotCookie( IN._LightCoord)) * UnitySpotAttenuate( IN._LightCoord.xyz)) * unitySampleShadow( IN._ShadowCoord)));
    #line 577
    color.w = mix( 1.0, color.w, xll_saturate_f((colorLight.w * 4.0)));
    color.w = mix( color.w, 1.0, xll_saturate_f((length(colorLight.xyz) - length((2.0 * color.xyz)))));
    color.w = mix( color.w, 1.0, handoff);
    color.xyz = colorLight.xyz;
    #line 581
    return color;
}
in highp float xlv_TEXCOORD0;
in highp vec3 xlv_TEXCOORD1;
in highp vec3 xlv_TEXCOORD2;
in highp vec4 xlv_TEXCOORD3;
in highp vec4 xlv_TEXCOORD4;
in highp vec3 xlv_TEXCOORD5;
void main() {
    lowp vec4 xl_retval;
    v2f xlt_IN;
    xlt_IN.pos = vec4(0.0);
    xlt_IN.viewDist = float(xlv_TEXCOORD0);
    xlt_IN.viewDir = vec3(xlv_TEXCOORD1);
    xlt_IN.worldPos = vec3(xlv_TEXCOORD2);
    xlt_IN._LightCoord = vec4(xlv_TEXCOORD3);
    xlt_IN._ShadowCoord = vec4(xlv_TEXCOORD4);
    xlt_IN.sphereNormal = vec3(xlv_TEXCOORD5);
    xl_retval = frag( xlt_IN);
    gl_FragData[0] = vec4(xl_retval);
}


#endif"
}

SubProgram "opengl " {
Keywords { "POINT" "SHADOWS_CUBE" "SHADOWS_SOFT" }
"!!GLSL
#ifdef VERTEX
varying vec3 xlv_TEXCOORD5;
varying vec3 xlv_TEXCOORD4;
varying vec3 xlv_TEXCOORD3;
varying vec3 xlv_TEXCOORD2;
varying vec3 xlv_TEXCOORD1;
varying float xlv_TEXCOORD0;
uniform mat4 _LightMatrix0;
uniform mat4 _Object2World;

uniform vec4 _LightPositionRange;
uniform vec3 _WorldSpaceCameraPos;
void main ()
{
  vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * gl_Vertex).xyz;
  vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  vec4 tmpvar_3;
  tmpvar_3.x = gl_MultiTexCoord0.x;
  tmpvar_3.y = gl_MultiTexCoord0.y;
  tmpvar_3.z = gl_MultiTexCoord1.x;
  tmpvar_3.w = gl_MultiTexCoord1.y;
  gl_Position = (gl_ModelViewProjectionMatrix * gl_Vertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * gl_Vertex)).xyz;
  xlv_TEXCOORD4 = ((_Object2World * gl_Vertex).xyz - _LightPositionRange.xyz);
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}


#endif
#ifdef FRAGMENT
#extension GL_ARB_shader_texture_lod : enable
varying vec3 xlv_TEXCOORD5;
varying vec3 xlv_TEXCOORD4;
varying vec3 xlv_TEXCOORD3;
varying vec3 xlv_TEXCOORD2;
varying vec3 xlv_TEXCOORD1;
varying float xlv_TEXCOORD0;
uniform vec3 _PlanetOrigin;
uniform float _PlanetOpacity;
uniform float _DetailDist;
uniform float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform float _Shininess;
uniform vec4 _SurfaceColor;
uniform vec4 _SpecColor;
uniform vec4 _LightColor0;
uniform sampler2D _LightTexture0;
uniform samplerCube _ShadowMapTexture;
uniform vec4 _LightShadowData;
uniform vec4 _LightPositionRange;
uniform vec4 _WorldSpaceLightPos0;
void main ()
{
  vec4 main_1;
  vec4 color_2;
  vec3 tmpvar_3;
  tmpvar_3 = normalize(xlv_TEXCOORD5);
  vec2 uv_4;
  float r_5;
  if ((abs(tmpvar_3.z) > (1e-08 * abs(tmpvar_3.x)))) {
    float y_over_x_6;
    y_over_x_6 = (tmpvar_3.x / tmpvar_3.z);
    float s_7;
    float x_8;
    x_8 = (y_over_x_6 * inversesqrt(((y_over_x_6 * y_over_x_6) + 1.0)));
    s_7 = (sign(x_8) * (1.5708 - (sqrt((1.0 - abs(x_8))) * (1.5708 + (abs(x_8) * (-0.214602 + (abs(x_8) * (0.0865667 + (abs(x_8) * -0.0310296)))))))));
    r_5 = s_7;
    if ((tmpvar_3.z < 0.0)) {
      if ((tmpvar_3.x >= 0.0)) {
        r_5 = (s_7 + 3.14159);
      } else {
        r_5 = (r_5 - 3.14159);
      };
    };
  } else {
    r_5 = (sign(tmpvar_3.x) * 1.5708);
  };
  uv_4.x = (0.5 + (0.159155 * r_5));
  uv_4.y = (0.31831 * (1.5708 - (sign(tmpvar_3.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_3.y))) * (1.5708 + (abs(tmpvar_3.y) * (-0.214602 + (abs(tmpvar_3.y) * (0.0865667 + (abs(tmpvar_3.y) * -0.0310296)))))))))));
  vec2 tmpvar_9;
  tmpvar_9 = dFdx(tmpvar_3.xz);
  vec2 tmpvar_10;
  tmpvar_10 = dFdy(tmpvar_3.xz);
  vec4 tmpvar_11;
  tmpvar_11.x = (0.159155 * sqrt(dot (tmpvar_9, tmpvar_9)));
  tmpvar_11.y = dFdx(uv_4.y);
  tmpvar_11.z = (0.159155 * sqrt(dot (tmpvar_10, tmpvar_10)));
  tmpvar_11.w = dFdy(uv_4.y);
  main_1 = texture2DGradARB (_MainTex, uv_4, tmpvar_11.xy, tmpvar_11.zw);
  vec3 tmpvar_12;
  tmpvar_12 = normalize(xlv_TEXCOORD5);
  vec2 uv_13;
  float r_14;
  if ((abs(tmpvar_12.z) > (1e-08 * abs(tmpvar_12.x)))) {
    float y_over_x_15;
    y_over_x_15 = (tmpvar_12.x / tmpvar_12.z);
    float s_16;
    float x_17;
    x_17 = (y_over_x_15 * inversesqrt(((y_over_x_15 * y_over_x_15) + 1.0)));
    s_16 = (sign(x_17) * (1.5708 - (sqrt((1.0 - abs(x_17))) * (1.5708 + (abs(x_17) * (-0.214602 + (abs(x_17) * (0.0865667 + (abs(x_17) * -0.0310296)))))))));
    r_14 = s_16;
    if ((tmpvar_12.z < 0.0)) {
      if ((tmpvar_12.x >= 0.0)) {
        r_14 = (s_16 + 3.14159);
      } else {
        r_14 = (r_14 - 3.14159);
      };
    };
  } else {
    r_14 = (sign(tmpvar_12.x) * 1.5708);
  };
  uv_13.x = (0.5 + (0.159155 * r_14));
  uv_13.y = (0.31831 * (1.5708 - (sign(tmpvar_12.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_12.y))) * (1.5708 + (abs(tmpvar_12.y) * (-0.214602 + (abs(tmpvar_12.y) * (0.0865667 + (abs(tmpvar_12.y) * -0.0310296)))))))))));
  vec2 tmpvar_18;
  tmpvar_18 = ((uv_13 * 4.0) * _DetailScale);
  vec2 tmpvar_19;
  tmpvar_19 = dFdx(tmpvar_12.xz);
  vec2 tmpvar_20;
  tmpvar_20 = dFdy(tmpvar_12.xz);
  vec4 tmpvar_21;
  tmpvar_21.x = (0.159155 * sqrt(dot (tmpvar_19, tmpvar_19)));
  tmpvar_21.y = dFdx(tmpvar_18.y);
  tmpvar_21.z = (0.159155 * sqrt(dot (tmpvar_20, tmpvar_20)));
  tmpvar_21.w = dFdy(tmpvar_18.y);
  vec3 tmpvar_22;
  tmpvar_22 = abs(tmpvar_12);
  float tmpvar_23;
  tmpvar_23 = float((tmpvar_22.z >= tmpvar_22.x));
  vec3 tmpvar_24;
  tmpvar_24 = mix (tmpvar_22.yxz, mix (tmpvar_22, tmpvar_22.zxy, vec3(tmpvar_23)), vec3(float((mix (tmpvar_22.x, tmpvar_22.z, tmpvar_23) >= tmpvar_22.y))));
  color_2.w = _SurfaceColor.w;
  color_2.xyz = (_SurfaceColor.xyz + (0.5 * mix ((texture2DGradARB (_DetailTex, (((0.5 * tmpvar_24.zy) / abs(tmpvar_24.x)) * _DetailScale), tmpvar_21.xy, tmpvar_21.zw).xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0)))));
  float tmpvar_25;
  tmpvar_25 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  color_2.xyz = mix (color_2.xyz, main_1.xyz, vec3(tmpvar_25));
  vec4 tmpvar_26;
  tmpvar_26 = normalize(_WorldSpaceLightPos0);
  vec3 tmpvar_27;
  tmpvar_27 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  vec4 tmpvar_28;
  tmpvar_28 = texture2D (_LightTexture0, vec2(dot (xlv_TEXCOORD3, xlv_TEXCOORD3)));
  vec4 shadowVals_29;
  shadowVals_29.x = dot (textureCube (_ShadowMapTexture, (xlv_TEXCOORD4 + vec3(0.0078125, 0.0078125, 0.0078125))), vec4(1.0, 0.00392157, 1.53787e-05, 6.22737e-09));
  shadowVals_29.y = dot (textureCube (_ShadowMapTexture, (xlv_TEXCOORD4 + vec3(-0.0078125, -0.0078125, 0.0078125))), vec4(1.0, 0.00392157, 1.53787e-05, 6.22737e-09));
  shadowVals_29.z = dot (textureCube (_ShadowMapTexture, (xlv_TEXCOORD4 + vec3(-0.0078125, 0.0078125, -0.0078125))), vec4(1.0, 0.00392157, 1.53787e-05, 6.22737e-09));
  shadowVals_29.w = dot (textureCube (_ShadowMapTexture, (xlv_TEXCOORD4 + vec3(0.0078125, -0.0078125, -0.0078125))), vec4(1.0, 0.00392157, 1.53787e-05, 6.22737e-09));
  bvec4 tmpvar_30;
  tmpvar_30 = lessThan (shadowVals_29, vec4(((sqrt(dot (xlv_TEXCOORD4, xlv_TEXCOORD4)) * _LightPositionRange.w) * 0.97)));
  vec4 tmpvar_31;
  tmpvar_31 = _LightShadowData.xxxx;
  float tmpvar_32;
  if (tmpvar_30.x) {
    tmpvar_32 = tmpvar_31.x;
  } else {
    tmpvar_32 = 1.0;
  };
  float tmpvar_33;
  if (tmpvar_30.y) {
    tmpvar_33 = tmpvar_31.y;
  } else {
    tmpvar_33 = 1.0;
  };
  float tmpvar_34;
  if (tmpvar_30.z) {
    tmpvar_34 = tmpvar_31.z;
  } else {
    tmpvar_34 = 1.0;
  };
  float tmpvar_35;
  if (tmpvar_30.w) {
    tmpvar_35 = tmpvar_31.w;
  } else {
    tmpvar_35 = 1.0;
  };
  vec4 tmpvar_36;
  tmpvar_36.x = tmpvar_32;
  tmpvar_36.y = tmpvar_33;
  tmpvar_36.z = tmpvar_34;
  tmpvar_36.w = tmpvar_35;
  float atten_37;
  atten_37 = (tmpvar_28.w * dot (tmpvar_36, vec4(0.25, 0.25, 0.25, 0.25)));
  vec4 c_38;
  vec3 tmpvar_39;
  tmpvar_39 = normalize(tmpvar_26.xyz);
  float tmpvar_40;
  tmpvar_40 = dot (tmpvar_27, tmpvar_39);
  c_38.xyz = ((((color_2.xyz * _LightColor0.xyz) * tmpvar_40) + ((_LightColor0.xyz * _SpecColor.xyz) * (pow (clamp (dot (normalize((tmpvar_39 + normalize(xlv_TEXCOORD1))), tmpvar_27), 0.0, 1.0), (_Shininess * 128.0)) * _SurfaceColor.w))) * (atten_37 * 4.0));
  c_38.w = (tmpvar_40 * (atten_37 * 4.0));
  color_2.w = mix (1.0, _SurfaceColor.w, clamp ((c_38.w * 4.0), 0.0, 1.0));
  vec3 arg0_41;
  arg0_41 = (2.0 * color_2.xyz);
  color_2.w = mix (color_2.w, 1.0, clamp ((sqrt(dot (c_38.xyz, c_38.xyz)) - sqrt(dot (arg0_41, arg0_41))), 0.0, 1.0));
  color_2.w = mix (color_2.w, 1.0, tmpvar_25);
  color_2.xyz = c_38.xyz;
  gl_FragData[0] = color_2;
}


#endif
"
}

SubProgram "d3d9 " {
Keywords { "POINT" "SHADOWS_CUBE" "SHADOWS_SOFT" }
Bind "vertex" Vertex
Bind "texcoord" TexCoord0
Bind "texcoord1" TexCoord1
Matrix 0 [glstate_matrix_mvp]
Vector 12 [_WorldSpaceCameraPos]
Vector 13 [_LightPositionRange]
Matrix 4 [_Object2World]
Matrix 8 [_LightMatrix0]
"vs_3_0
; 25 ALU
dcl_position o0
dcl_texcoord0 o1
dcl_texcoord1 o2
dcl_texcoord2 o3
dcl_texcoord3 o4
dcl_texcoord4 o5
dcl_texcoord5 o6
dcl_position0 v0
dcl_texcoord0 v1
dcl_texcoord1 v2
dp4 r1.z, v0, c6
dp4 r1.x, v0, c4
dp4 r1.y, v0, c5
mov r0.zw, v2.xyxy
mov r0.xy, v1
dp4 r0.w, r0, r0
rsq r1.w, r0.w
mul r0.xyz, r1.w, r0
add r2.xyz, -r1, c12
dp3 r0.w, r2, r2
rsq r1.w, r0.w
mov o6.xyz, -r0
mov r0.xyz, r1
dp4 r0.w, v0, c7
mul o2.xyz, r1.w, r2
dp4 o4.z, r0, c10
dp4 o4.y, r0, c9
dp4 o4.x, r0, c8
rcp o1.x, r1.w
mov o3.xyz, r1
add o5.xyz, r1, -c13
dp4 o0.w, v0, c3
dp4 o0.z, v0, c2
dp4 o0.y, v0, c1
dp4 o0.x, v0, c0
"
}

SubProgram "gles " {
Keywords { "POINT" "SHADOWS_CUBE" "SHADOWS_SOFT" }
"!!GLES


#ifdef VERTEX

varying highp vec3 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD4;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp mat4 _LightMatrix0;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_mvp;
uniform highp vec4 _LightPositionRange;
uniform highp vec3 _WorldSpaceCameraPos;
attribute vec4 _glesMultiTexCoord1;
attribute vec4 _glesMultiTexCoord0;
attribute vec4 _glesVertex;
void main ()
{
  highp vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * _glesVertex).xyz;
  highp vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  highp vec4 tmpvar_3;
  tmpvar_3.x = _glesMultiTexCoord0.x;
  tmpvar_3.y = _glesMultiTexCoord0.y;
  tmpvar_3.z = _glesMultiTexCoord1.x;
  tmpvar_3.w = _glesMultiTexCoord1.y;
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * _glesVertex)).xyz;
  xlv_TEXCOORD4 = ((_Object2World * _glesVertex).xyz - _LightPositionRange.xyz);
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}



#endif
#ifdef FRAGMENT

#extension GL_EXT_shader_texture_lod : enable
#extension GL_OES_standard_derivatives : enable
varying highp vec3 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD4;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp vec3 _PlanetOrigin;
uniform highp float _PlanetOpacity;
uniform highp float _DetailDist;
uniform highp float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform highp float _Shininess;
uniform lowp vec4 _SurfaceColor;
uniform lowp vec4 _SpecColor;
uniform lowp vec4 _LightColor0;
uniform sampler2D _LightTexture0;
uniform samplerCube _ShadowMapTexture;
uniform highp vec4 _LightShadowData;
uniform highp vec4 _LightPositionRange;
uniform highp vec4 _WorldSpaceLightPos0;
void main ()
{
  lowp vec4 tmpvar_1;
  mediump vec4 specColor_2;
  mediump float handoff_3;
  mediump float detailLevel_4;
  mediump vec4 color_5;
  mediump vec4 tex_6;
  highp vec3 tmpvar_7;
  tmpvar_7 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_8;
  highp float r_9;
  if ((abs(tmpvar_7.z) > (1e-08 * abs(tmpvar_7.x)))) {
    highp float y_over_x_10;
    y_over_x_10 = (tmpvar_7.x / tmpvar_7.z);
    highp float s_11;
    highp float x_12;
    x_12 = (y_over_x_10 * inversesqrt(((y_over_x_10 * y_over_x_10) + 1.0)));
    s_11 = (sign(x_12) * (1.5708 - (sqrt((1.0 - abs(x_12))) * (1.5708 + (abs(x_12) * (-0.214602 + (abs(x_12) * (0.0865667 + (abs(x_12) * -0.0310296)))))))));
    r_9 = s_11;
    if ((tmpvar_7.z < 0.0)) {
      if ((tmpvar_7.x >= 0.0)) {
        r_9 = (s_11 + 3.14159);
      } else {
        r_9 = (r_9 - 3.14159);
      };
    };
  } else {
    r_9 = (sign(tmpvar_7.x) * 1.5708);
  };
  uv_8.x = (0.5 + (0.159155 * r_9));
  uv_8.y = (0.31831 * (1.5708 - (sign(tmpvar_7.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_7.y))) * (1.5708 + (abs(tmpvar_7.y) * (-0.214602 + (abs(tmpvar_7.y) * (0.0865667 + (abs(tmpvar_7.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_13;
  tmpvar_13 = dFdx(tmpvar_7.xz);
  highp vec2 tmpvar_14;
  tmpvar_14 = dFdy(tmpvar_7.xz);
  highp vec4 tmpvar_15;
  tmpvar_15.x = (0.159155 * sqrt(dot (tmpvar_13, tmpvar_13)));
  tmpvar_15.y = dFdx(uv_8.y);
  tmpvar_15.z = (0.159155 * sqrt(dot (tmpvar_14, tmpvar_14)));
  tmpvar_15.w = dFdy(uv_8.y);
  lowp vec4 tmpvar_16;
  tmpvar_16 = texture2DGradEXT (_MainTex, uv_8, tmpvar_15.xy, tmpvar_15.zw);
  tex_6 = tmpvar_16;
  mediump vec4 tmpvar_17;
  mediump vec3 detailCoords_18;
  mediump float nylerp_19;
  mediump float zxlerp_20;
  highp vec3 tmpvar_21;
  tmpvar_21 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_22;
  highp float r_23;
  if ((abs(tmpvar_21.z) > (1e-08 * abs(tmpvar_21.x)))) {
    highp float y_over_x_24;
    y_over_x_24 = (tmpvar_21.x / tmpvar_21.z);
    highp float s_25;
    highp float x_26;
    x_26 = (y_over_x_24 * inversesqrt(((y_over_x_24 * y_over_x_24) + 1.0)));
    s_25 = (sign(x_26) * (1.5708 - (sqrt((1.0 - abs(x_26))) * (1.5708 + (abs(x_26) * (-0.214602 + (abs(x_26) * (0.0865667 + (abs(x_26) * -0.0310296)))))))));
    r_23 = s_25;
    if ((tmpvar_21.z < 0.0)) {
      if ((tmpvar_21.x >= 0.0)) {
        r_23 = (s_25 + 3.14159);
      } else {
        r_23 = (r_23 - 3.14159);
      };
    };
  } else {
    r_23 = (sign(tmpvar_21.x) * 1.5708);
  };
  uv_22.x = (0.5 + (0.159155 * r_23));
  uv_22.y = (0.31831 * (1.5708 - (sign(tmpvar_21.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_21.y))) * (1.5708 + (abs(tmpvar_21.y) * (-0.214602 + (abs(tmpvar_21.y) * (0.0865667 + (abs(tmpvar_21.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_27;
  tmpvar_27 = ((uv_22 * 4.0) * _DetailScale);
  highp vec2 tmpvar_28;
  tmpvar_28 = dFdx(tmpvar_21.xz);
  highp vec2 tmpvar_29;
  tmpvar_29 = dFdy(tmpvar_21.xz);
  highp vec4 tmpvar_30;
  tmpvar_30.x = (0.159155 * sqrt(dot (tmpvar_28, tmpvar_28)));
  tmpvar_30.y = dFdx(tmpvar_27.y);
  tmpvar_30.z = (0.159155 * sqrt(dot (tmpvar_29, tmpvar_29)));
  tmpvar_30.w = dFdy(tmpvar_27.y);
  highp vec3 tmpvar_31;
  tmpvar_31 = abs(tmpvar_21);
  highp float tmpvar_32;
  tmpvar_32 = float((tmpvar_31.z >= tmpvar_31.x));
  zxlerp_20 = tmpvar_32;
  highp float tmpvar_33;
  tmpvar_33 = float((mix (tmpvar_31.x, tmpvar_31.z, zxlerp_20) >= tmpvar_31.y));
  nylerp_19 = tmpvar_33;
  highp vec3 tmpvar_34;
  tmpvar_34 = mix (tmpvar_31, tmpvar_31.zxy, vec3(zxlerp_20));
  detailCoords_18 = tmpvar_34;
  highp vec3 tmpvar_35;
  tmpvar_35 = mix (tmpvar_31.yxz, detailCoords_18, vec3(nylerp_19));
  detailCoords_18 = tmpvar_35;
  mediump float tmpvar_36;
  tmpvar_36 = abs(detailCoords_18.x);
  highp vec2 coord_37;
  coord_37 = (((0.5 * detailCoords_18.zy) / tmpvar_36) * _DetailScale);
  lowp vec4 tmpvar_38;
  tmpvar_38 = texture2DGradEXT (_DetailTex, coord_37, tmpvar_30.xy, tmpvar_30.zw);
  tmpvar_17 = tmpvar_38;
  color_5 = _SurfaceColor;
  highp float tmpvar_39;
  tmpvar_39 = clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0);
  detailLevel_4 = tmpvar_39;
  color_5.xyz = (color_5.xyz + (0.5 * mix ((tmpvar_17.xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(detailLevel_4))));
  highp float tmpvar_40;
  tmpvar_40 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  handoff_3 = tmpvar_40;
  color_5.xyz = mix (color_5.xyz, tex_6.xyz, vec3(handoff_3));
  specColor_2.xyz = _SpecColor.xyz;
  specColor_2.w = mix (1.0, tex_6.w, handoff_3);
  highp vec3 tmpvar_41;
  tmpvar_41 = normalize(_WorldSpaceLightPos0).xyz;
  highp vec3 tmpvar_42;
  tmpvar_42 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  highp float tmpvar_43;
  tmpvar_43 = dot (xlv_TEXCOORD3, xlv_TEXCOORD3);
  lowp vec4 tmpvar_44;
  tmpvar_44 = texture2D (_LightTexture0, vec2(tmpvar_43));
  highp float tmpvar_45;
  mediump vec4 shadows_46;
  highp vec4 shadowVals_47;
  highp float tmpvar_48;
  tmpvar_48 = ((sqrt(dot (xlv_TEXCOORD4, xlv_TEXCOORD4)) * _LightPositionRange.w) * 0.97);
  highp vec3 vec_49;
  vec_49 = (xlv_TEXCOORD4 + vec3(0.0078125, 0.0078125, 0.0078125));
  highp vec4 packDist_50;
  lowp vec4 tmpvar_51;
  tmpvar_51 = textureCube (_ShadowMapTexture, vec_49);
  packDist_50 = tmpvar_51;
  shadowVals_47.x = dot (packDist_50, vec4(1.0, 0.00392157, 1.53787e-05, 6.22737e-09));
  highp vec3 vec_52;
  vec_52 = (xlv_TEXCOORD4 + vec3(-0.0078125, -0.0078125, 0.0078125));
  highp vec4 packDist_53;
  lowp vec4 tmpvar_54;
  tmpvar_54 = textureCube (_ShadowMapTexture, vec_52);
  packDist_53 = tmpvar_54;
  shadowVals_47.y = dot (packDist_53, vec4(1.0, 0.00392157, 1.53787e-05, 6.22737e-09));
  highp vec3 vec_55;
  vec_55 = (xlv_TEXCOORD4 + vec3(-0.0078125, 0.0078125, -0.0078125));
  highp vec4 packDist_56;
  lowp vec4 tmpvar_57;
  tmpvar_57 = textureCube (_ShadowMapTexture, vec_55);
  packDist_56 = tmpvar_57;
  shadowVals_47.z = dot (packDist_56, vec4(1.0, 0.00392157, 1.53787e-05, 6.22737e-09));
  highp vec3 vec_58;
  vec_58 = (xlv_TEXCOORD4 + vec3(0.0078125, -0.0078125, -0.0078125));
  highp vec4 packDist_59;
  lowp vec4 tmpvar_60;
  tmpvar_60 = textureCube (_ShadowMapTexture, vec_58);
  packDist_59 = tmpvar_60;
  shadowVals_47.w = dot (packDist_59, vec4(1.0, 0.00392157, 1.53787e-05, 6.22737e-09));
  bvec4 tmpvar_61;
  tmpvar_61 = lessThan (shadowVals_47, vec4(tmpvar_48));
  highp vec4 tmpvar_62;
  tmpvar_62 = _LightShadowData.xxxx;
  highp float tmpvar_63;
  if (tmpvar_61.x) {
    tmpvar_63 = tmpvar_62.x;
  } else {
    tmpvar_63 = 1.0;
  };
  highp float tmpvar_64;
  if (tmpvar_61.y) {
    tmpvar_64 = tmpvar_62.y;
  } else {
    tmpvar_64 = 1.0;
  };
  highp float tmpvar_65;
  if (tmpvar_61.z) {
    tmpvar_65 = tmpvar_62.z;
  } else {
    tmpvar_65 = 1.0;
  };
  highp float tmpvar_66;
  if (tmpvar_61.w) {
    tmpvar_66 = tmpvar_62.w;
  } else {
    tmpvar_66 = 1.0;
  };
  highp vec4 tmpvar_67;
  tmpvar_67.x = tmpvar_63;
  tmpvar_67.y = tmpvar_64;
  tmpvar_67.z = tmpvar_65;
  tmpvar_67.w = tmpvar_66;
  shadows_46 = tmpvar_67;
  mediump float tmpvar_68;
  tmpvar_68 = dot (shadows_46, vec4(0.25, 0.25, 0.25, 0.25));
  tmpvar_45 = tmpvar_68;
  mediump vec3 lightDir_69;
  lightDir_69 = tmpvar_41;
  mediump vec3 viewDir_70;
  viewDir_70 = xlv_TEXCOORD1;
  mediump vec3 normal_71;
  normal_71 = tmpvar_42;
  mediump float atten_72;
  atten_72 = (tmpvar_44.w * tmpvar_45);
  mediump vec4 c_73;
  highp float nh_74;
  mediump vec3 tmpvar_75;
  tmpvar_75 = normalize(lightDir_69);
  lightDir_69 = tmpvar_75;
  mediump vec3 tmpvar_76;
  tmpvar_76 = normalize(viewDir_70);
  viewDir_70 = tmpvar_76;
  mediump float tmpvar_77;
  tmpvar_77 = dot (normal_71, tmpvar_75);
  mediump float tmpvar_78;
  tmpvar_78 = clamp (dot (normalize((tmpvar_75 + tmpvar_76)), normal_71), 0.0, 1.0);
  nh_74 = tmpvar_78;
  highp vec3 tmpvar_79;
  tmpvar_79 = ((((color_5.xyz * _LightColor0.xyz) * tmpvar_77) + ((_LightColor0.xyz * specColor_2.xyz) * (pow (nh_74, (_Shininess * 128.0)) * color_5.w))) * (atten_72 * 4.0));
  c_73.xyz = tmpvar_79;
  c_73.w = (tmpvar_77 * (atten_72 * 4.0));
  color_5.w = mix (1.0, color_5.w, clamp ((c_73.w * 4.0), 0.0, 1.0));
  mediump vec3 arg0_80;
  arg0_80 = (2.0 * color_5.xyz);
  color_5.w = mix (color_5.w, 1.0, clamp ((sqrt(dot (c_73.xyz, c_73.xyz)) - sqrt(dot (arg0_80, arg0_80))), 0.0, 1.0));
  color_5.w = mix (color_5.w, 1.0, handoff_3);
  color_5.xyz = c_73.xyz;
  tmpvar_1 = color_5;
  gl_FragData[0] = tmpvar_1;
}



#endif"
}

SubProgram "glesdesktop " {
Keywords { "POINT" "SHADOWS_CUBE" "SHADOWS_SOFT" }
"!!GLES


#ifdef VERTEX

varying highp vec3 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD4;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp mat4 _LightMatrix0;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_mvp;
uniform highp vec4 _LightPositionRange;
uniform highp vec3 _WorldSpaceCameraPos;
attribute vec4 _glesMultiTexCoord1;
attribute vec4 _glesMultiTexCoord0;
attribute vec4 _glesVertex;
void main ()
{
  highp vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * _glesVertex).xyz;
  highp vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  highp vec4 tmpvar_3;
  tmpvar_3.x = _glesMultiTexCoord0.x;
  tmpvar_3.y = _glesMultiTexCoord0.y;
  tmpvar_3.z = _glesMultiTexCoord1.x;
  tmpvar_3.w = _glesMultiTexCoord1.y;
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * _glesVertex)).xyz;
  xlv_TEXCOORD4 = ((_Object2World * _glesVertex).xyz - _LightPositionRange.xyz);
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}



#endif
#ifdef FRAGMENT

#extension GL_EXT_shader_texture_lod : enable
#extension GL_OES_standard_derivatives : enable
varying highp vec3 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD4;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp vec3 _PlanetOrigin;
uniform highp float _PlanetOpacity;
uniform highp float _DetailDist;
uniform highp float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform highp float _Shininess;
uniform lowp vec4 _SurfaceColor;
uniform lowp vec4 _SpecColor;
uniform lowp vec4 _LightColor0;
uniform sampler2D _LightTexture0;
uniform samplerCube _ShadowMapTexture;
uniform highp vec4 _LightShadowData;
uniform highp vec4 _LightPositionRange;
uniform highp vec4 _WorldSpaceLightPos0;
void main ()
{
  lowp vec4 tmpvar_1;
  mediump vec4 specColor_2;
  mediump float handoff_3;
  mediump float detailLevel_4;
  mediump vec4 color_5;
  mediump vec4 tex_6;
  highp vec3 tmpvar_7;
  tmpvar_7 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_8;
  highp float r_9;
  if ((abs(tmpvar_7.z) > (1e-08 * abs(tmpvar_7.x)))) {
    highp float y_over_x_10;
    y_over_x_10 = (tmpvar_7.x / tmpvar_7.z);
    highp float s_11;
    highp float x_12;
    x_12 = (y_over_x_10 * inversesqrt(((y_over_x_10 * y_over_x_10) + 1.0)));
    s_11 = (sign(x_12) * (1.5708 - (sqrt((1.0 - abs(x_12))) * (1.5708 + (abs(x_12) * (-0.214602 + (abs(x_12) * (0.0865667 + (abs(x_12) * -0.0310296)))))))));
    r_9 = s_11;
    if ((tmpvar_7.z < 0.0)) {
      if ((tmpvar_7.x >= 0.0)) {
        r_9 = (s_11 + 3.14159);
      } else {
        r_9 = (r_9 - 3.14159);
      };
    };
  } else {
    r_9 = (sign(tmpvar_7.x) * 1.5708);
  };
  uv_8.x = (0.5 + (0.159155 * r_9));
  uv_8.y = (0.31831 * (1.5708 - (sign(tmpvar_7.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_7.y))) * (1.5708 + (abs(tmpvar_7.y) * (-0.214602 + (abs(tmpvar_7.y) * (0.0865667 + (abs(tmpvar_7.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_13;
  tmpvar_13 = dFdx(tmpvar_7.xz);
  highp vec2 tmpvar_14;
  tmpvar_14 = dFdy(tmpvar_7.xz);
  highp vec4 tmpvar_15;
  tmpvar_15.x = (0.159155 * sqrt(dot (tmpvar_13, tmpvar_13)));
  tmpvar_15.y = dFdx(uv_8.y);
  tmpvar_15.z = (0.159155 * sqrt(dot (tmpvar_14, tmpvar_14)));
  tmpvar_15.w = dFdy(uv_8.y);
  lowp vec4 tmpvar_16;
  tmpvar_16 = texture2DGradEXT (_MainTex, uv_8, tmpvar_15.xy, tmpvar_15.zw);
  tex_6 = tmpvar_16;
  mediump vec4 tmpvar_17;
  mediump vec3 detailCoords_18;
  mediump float nylerp_19;
  mediump float zxlerp_20;
  highp vec3 tmpvar_21;
  tmpvar_21 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_22;
  highp float r_23;
  if ((abs(tmpvar_21.z) > (1e-08 * abs(tmpvar_21.x)))) {
    highp float y_over_x_24;
    y_over_x_24 = (tmpvar_21.x / tmpvar_21.z);
    highp float s_25;
    highp float x_26;
    x_26 = (y_over_x_24 * inversesqrt(((y_over_x_24 * y_over_x_24) + 1.0)));
    s_25 = (sign(x_26) * (1.5708 - (sqrt((1.0 - abs(x_26))) * (1.5708 + (abs(x_26) * (-0.214602 + (abs(x_26) * (0.0865667 + (abs(x_26) * -0.0310296)))))))));
    r_23 = s_25;
    if ((tmpvar_21.z < 0.0)) {
      if ((tmpvar_21.x >= 0.0)) {
        r_23 = (s_25 + 3.14159);
      } else {
        r_23 = (r_23 - 3.14159);
      };
    };
  } else {
    r_23 = (sign(tmpvar_21.x) * 1.5708);
  };
  uv_22.x = (0.5 + (0.159155 * r_23));
  uv_22.y = (0.31831 * (1.5708 - (sign(tmpvar_21.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_21.y))) * (1.5708 + (abs(tmpvar_21.y) * (-0.214602 + (abs(tmpvar_21.y) * (0.0865667 + (abs(tmpvar_21.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_27;
  tmpvar_27 = ((uv_22 * 4.0) * _DetailScale);
  highp vec2 tmpvar_28;
  tmpvar_28 = dFdx(tmpvar_21.xz);
  highp vec2 tmpvar_29;
  tmpvar_29 = dFdy(tmpvar_21.xz);
  highp vec4 tmpvar_30;
  tmpvar_30.x = (0.159155 * sqrt(dot (tmpvar_28, tmpvar_28)));
  tmpvar_30.y = dFdx(tmpvar_27.y);
  tmpvar_30.z = (0.159155 * sqrt(dot (tmpvar_29, tmpvar_29)));
  tmpvar_30.w = dFdy(tmpvar_27.y);
  highp vec3 tmpvar_31;
  tmpvar_31 = abs(tmpvar_21);
  highp float tmpvar_32;
  tmpvar_32 = float((tmpvar_31.z >= tmpvar_31.x));
  zxlerp_20 = tmpvar_32;
  highp float tmpvar_33;
  tmpvar_33 = float((mix (tmpvar_31.x, tmpvar_31.z, zxlerp_20) >= tmpvar_31.y));
  nylerp_19 = tmpvar_33;
  highp vec3 tmpvar_34;
  tmpvar_34 = mix (tmpvar_31, tmpvar_31.zxy, vec3(zxlerp_20));
  detailCoords_18 = tmpvar_34;
  highp vec3 tmpvar_35;
  tmpvar_35 = mix (tmpvar_31.yxz, detailCoords_18, vec3(nylerp_19));
  detailCoords_18 = tmpvar_35;
  mediump float tmpvar_36;
  tmpvar_36 = abs(detailCoords_18.x);
  highp vec2 coord_37;
  coord_37 = (((0.5 * detailCoords_18.zy) / tmpvar_36) * _DetailScale);
  lowp vec4 tmpvar_38;
  tmpvar_38 = texture2DGradEXT (_DetailTex, coord_37, tmpvar_30.xy, tmpvar_30.zw);
  tmpvar_17 = tmpvar_38;
  color_5 = _SurfaceColor;
  highp float tmpvar_39;
  tmpvar_39 = clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0);
  detailLevel_4 = tmpvar_39;
  color_5.xyz = (color_5.xyz + (0.5 * mix ((tmpvar_17.xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(detailLevel_4))));
  highp float tmpvar_40;
  tmpvar_40 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  handoff_3 = tmpvar_40;
  color_5.xyz = mix (color_5.xyz, tex_6.xyz, vec3(handoff_3));
  specColor_2.xyz = _SpecColor.xyz;
  specColor_2.w = mix (1.0, tex_6.w, handoff_3);
  highp vec3 tmpvar_41;
  tmpvar_41 = normalize(_WorldSpaceLightPos0).xyz;
  highp vec3 tmpvar_42;
  tmpvar_42 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  highp float tmpvar_43;
  tmpvar_43 = dot (xlv_TEXCOORD3, xlv_TEXCOORD3);
  lowp vec4 tmpvar_44;
  tmpvar_44 = texture2D (_LightTexture0, vec2(tmpvar_43));
  highp float tmpvar_45;
  mediump vec4 shadows_46;
  highp vec4 shadowVals_47;
  highp float tmpvar_48;
  tmpvar_48 = ((sqrt(dot (xlv_TEXCOORD4, xlv_TEXCOORD4)) * _LightPositionRange.w) * 0.97);
  highp vec3 vec_49;
  vec_49 = (xlv_TEXCOORD4 + vec3(0.0078125, 0.0078125, 0.0078125));
  highp vec4 packDist_50;
  lowp vec4 tmpvar_51;
  tmpvar_51 = textureCube (_ShadowMapTexture, vec_49);
  packDist_50 = tmpvar_51;
  shadowVals_47.x = dot (packDist_50, vec4(1.0, 0.00392157, 1.53787e-05, 6.22737e-09));
  highp vec3 vec_52;
  vec_52 = (xlv_TEXCOORD4 + vec3(-0.0078125, -0.0078125, 0.0078125));
  highp vec4 packDist_53;
  lowp vec4 tmpvar_54;
  tmpvar_54 = textureCube (_ShadowMapTexture, vec_52);
  packDist_53 = tmpvar_54;
  shadowVals_47.y = dot (packDist_53, vec4(1.0, 0.00392157, 1.53787e-05, 6.22737e-09));
  highp vec3 vec_55;
  vec_55 = (xlv_TEXCOORD4 + vec3(-0.0078125, 0.0078125, -0.0078125));
  highp vec4 packDist_56;
  lowp vec4 tmpvar_57;
  tmpvar_57 = textureCube (_ShadowMapTexture, vec_55);
  packDist_56 = tmpvar_57;
  shadowVals_47.z = dot (packDist_56, vec4(1.0, 0.00392157, 1.53787e-05, 6.22737e-09));
  highp vec3 vec_58;
  vec_58 = (xlv_TEXCOORD4 + vec3(0.0078125, -0.0078125, -0.0078125));
  highp vec4 packDist_59;
  lowp vec4 tmpvar_60;
  tmpvar_60 = textureCube (_ShadowMapTexture, vec_58);
  packDist_59 = tmpvar_60;
  shadowVals_47.w = dot (packDist_59, vec4(1.0, 0.00392157, 1.53787e-05, 6.22737e-09));
  bvec4 tmpvar_61;
  tmpvar_61 = lessThan (shadowVals_47, vec4(tmpvar_48));
  highp vec4 tmpvar_62;
  tmpvar_62 = _LightShadowData.xxxx;
  highp float tmpvar_63;
  if (tmpvar_61.x) {
    tmpvar_63 = tmpvar_62.x;
  } else {
    tmpvar_63 = 1.0;
  };
  highp float tmpvar_64;
  if (tmpvar_61.y) {
    tmpvar_64 = tmpvar_62.y;
  } else {
    tmpvar_64 = 1.0;
  };
  highp float tmpvar_65;
  if (tmpvar_61.z) {
    tmpvar_65 = tmpvar_62.z;
  } else {
    tmpvar_65 = 1.0;
  };
  highp float tmpvar_66;
  if (tmpvar_61.w) {
    tmpvar_66 = tmpvar_62.w;
  } else {
    tmpvar_66 = 1.0;
  };
  highp vec4 tmpvar_67;
  tmpvar_67.x = tmpvar_63;
  tmpvar_67.y = tmpvar_64;
  tmpvar_67.z = tmpvar_65;
  tmpvar_67.w = tmpvar_66;
  shadows_46 = tmpvar_67;
  mediump float tmpvar_68;
  tmpvar_68 = dot (shadows_46, vec4(0.25, 0.25, 0.25, 0.25));
  tmpvar_45 = tmpvar_68;
  mediump vec3 lightDir_69;
  lightDir_69 = tmpvar_41;
  mediump vec3 viewDir_70;
  viewDir_70 = xlv_TEXCOORD1;
  mediump vec3 normal_71;
  normal_71 = tmpvar_42;
  mediump float atten_72;
  atten_72 = (tmpvar_44.w * tmpvar_45);
  mediump vec4 c_73;
  highp float nh_74;
  mediump vec3 tmpvar_75;
  tmpvar_75 = normalize(lightDir_69);
  lightDir_69 = tmpvar_75;
  mediump vec3 tmpvar_76;
  tmpvar_76 = normalize(viewDir_70);
  viewDir_70 = tmpvar_76;
  mediump float tmpvar_77;
  tmpvar_77 = dot (normal_71, tmpvar_75);
  mediump float tmpvar_78;
  tmpvar_78 = clamp (dot (normalize((tmpvar_75 + tmpvar_76)), normal_71), 0.0, 1.0);
  nh_74 = tmpvar_78;
  highp vec3 tmpvar_79;
  tmpvar_79 = ((((color_5.xyz * _LightColor0.xyz) * tmpvar_77) + ((_LightColor0.xyz * specColor_2.xyz) * (pow (nh_74, (_Shininess * 128.0)) * color_5.w))) * (atten_72 * 4.0));
  c_73.xyz = tmpvar_79;
  c_73.w = (tmpvar_77 * (atten_72 * 4.0));
  color_5.w = mix (1.0, color_5.w, clamp ((c_73.w * 4.0), 0.0, 1.0));
  mediump vec3 arg0_80;
  arg0_80 = (2.0 * color_5.xyz);
  color_5.w = mix (color_5.w, 1.0, clamp ((sqrt(dot (c_73.xyz, c_73.xyz)) - sqrt(dot (arg0_80, arg0_80))), 0.0, 1.0));
  color_5.w = mix (color_5.w, 1.0, handoff_3);
  color_5.xyz = c_73.xyz;
  tmpvar_1 = color_5;
  gl_FragData[0] = tmpvar_1;
}



#endif"
}

SubProgram "gles3 " {
Keywords { "POINT" "SHADOWS_CUBE" "SHADOWS_SOFT" }
"!!GLES3#version 300 es


#ifdef VERTEX

#define gl_Vertex _glesVertex
in vec4 _glesVertex;
#define gl_Normal (normalize(_glesNormal))
in vec3 _glesNormal;
#define gl_MultiTexCoord0 _glesMultiTexCoord0
in vec4 _glesMultiTexCoord0;
#define gl_MultiTexCoord1 _glesMultiTexCoord1
in vec4 _glesMultiTexCoord1;

#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 336
struct SurfaceOutput {
    lowp vec3 Albedo;
    lowp vec3 Normal;
    lowp vec3 Emission;
    mediump float Specular;
    lowp float Gloss;
    lowp float Alpha;
};
#line 533
struct v2f {
    highp vec4 pos;
    highp float viewDist;
    highp vec3 viewDir;
    highp vec3 worldPos;
    highp vec3 _LightCoord;
    highp vec3 _ShadowCoord;
    highp vec3 sphereNormal;
};
#line 525
struct appdata_t {
    highp vec4 vertex;
    highp vec3 normal;
    highp vec4 texcoord;
    highp vec4 texcoord2;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform highp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform samplerCube _ShadowMapTexture;
uniform sampler2D _LightTexture0;
#line 335
uniform highp mat4 _LightMatrix0;
#line 346
uniform lowp vec4 _LightColor0;
uniform lowp vec4 _SpecColor;
#line 359
#line 367
#line 381
uniform highp mat4 _MainRotation;
uniform highp mat4 _DetailRotation;
#line 414
#line 418
#line 427
#line 435
#line 444
#line 452
#line 465
#line 477
#line 493
#line 506
uniform lowp vec4 _SurfaceColor;
#line 514
uniform highp float _Shininess;
uniform sampler2D _MainTex;
uniform sampler2D _DetailTex;
uniform highp float _DetailScale;
#line 518
uniform highp float _DetailDist;
uniform highp float _MinLight;
uniform sampler2D _CameraDepthTexture;
uniform highp mat4 _CameraToWorld;
#line 522
uniform highp float _LightPower;
uniform highp float _PlanetOpacity;
uniform highp vec3 _PlanetOrigin;
#line 544
#line 544
v2f vert( in appdata_t v ) {
    v2f o;
    highp vec4 vertex = v.vertex;
    #line 548
    o.pos = (glstate_matrix_mvp * vertex).xyzw;
    highp vec3 vertexPos = (_Object2World * vertex).xyz;
    o.viewDist = distance( vertexPos, _WorldSpaceCameraPos);
    o.worldPos = vertexPos;
    #line 552
    o.sphereNormal = (-normalize(vec4( v.texcoord.x, v.texcoord.y, v.texcoord2.x, v.texcoord2.y)).xyz);
    o.viewDir = normalize((_WorldSpaceCameraPos.xyz - vertexPos));
    o._LightCoord = (_LightMatrix0 * (_Object2World * v.vertex)).xyz;
    o._ShadowCoord = ((_Object2World * v.vertex).xyz - _LightPositionRange.xyz);
    #line 557
    return o;
}
out highp float xlv_TEXCOORD0;
out highp vec3 xlv_TEXCOORD1;
out highp vec3 xlv_TEXCOORD2;
out highp vec3 xlv_TEXCOORD3;
out highp vec3 xlv_TEXCOORD4;
out highp vec3 xlv_TEXCOORD5;
void main() {
    v2f xl_retval;
    appdata_t xlt_v;
    xlt_v.vertex = vec4(gl_Vertex);
    xlt_v.normal = vec3(gl_Normal);
    xlt_v.texcoord = vec4(gl_MultiTexCoord0);
    xlt_v.texcoord2 = vec4(gl_MultiTexCoord1);
    xl_retval = vert( xlt_v);
    gl_Position = vec4(xl_retval.pos);
    xlv_TEXCOORD0 = float(xl_retval.viewDist);
    xlv_TEXCOORD1 = vec3(xl_retval.viewDir);
    xlv_TEXCOORD2 = vec3(xl_retval.worldPos);
    xlv_TEXCOORD3 = vec3(xl_retval._LightCoord);
    xlv_TEXCOORD4 = vec3(xl_retval._ShadowCoord);
    xlv_TEXCOORD5 = vec3(xl_retval.sphereNormal);
}


#endif
#ifdef FRAGMENT

#define gl_FragData _glesFragData
layout(location = 0) out mediump vec4 _glesFragData[4];
float xll_dFdx_f(float f) {
  return dFdx(f);
}
vec2 xll_dFdx_vf2(vec2 v) {
  return dFdx(v);
}
vec3 xll_dFdx_vf3(vec3 v) {
  return dFdx(v);
}
vec4 xll_dFdx_vf4(vec4 v) {
  return dFdx(v);
}
mat2 xll_dFdx_mf2x2(mat2 m) {
  return mat2( dFdx(m[0]), dFdx(m[1]));
}
mat3 xll_dFdx_mf3x3(mat3 m) {
  return mat3( dFdx(m[0]), dFdx(m[1]), dFdx(m[2]));
}
mat4 xll_dFdx_mf4x4(mat4 m) {
  return mat4( dFdx(m[0]), dFdx(m[1]), dFdx(m[2]), dFdx(m[3]));
}
float xll_dFdy_f(float f) {
  return dFdy(f);
}
vec2 xll_dFdy_vf2(vec2 v) {
  return dFdy(v);
}
vec3 xll_dFdy_vf3(vec3 v) {
  return dFdy(v);
}
vec4 xll_dFdy_vf4(vec4 v) {
  return dFdy(v);
}
mat2 xll_dFdy_mf2x2(mat2 m) {
  return mat2( dFdy(m[0]), dFdy(m[1]));
}
mat3 xll_dFdy_mf3x3(mat3 m) {
  return mat3( dFdy(m[0]), dFdy(m[1]), dFdy(m[2]));
}
mat4 xll_dFdy_mf4x4(mat4 m) {
  return mat4( dFdy(m[0]), dFdy(m[1]), dFdy(m[2]), dFdy(m[3]));
}
vec4 xll_tex2Dgrad(sampler2D s, vec2 coord, vec2 ddx, vec2 ddy) {
   return textureGrad( s, coord, ddx, ddy);
}
float xll_saturate_f( float x) {
  return clamp( x, 0.0, 1.0);
}
vec2 xll_saturate_vf2( vec2 x) {
  return clamp( x, 0.0, 1.0);
}
vec3 xll_saturate_vf3( vec3 x) {
  return clamp( x, 0.0, 1.0);
}
vec4 xll_saturate_vf4( vec4 x) {
  return clamp( x, 0.0, 1.0);
}
mat2 xll_saturate_mf2x2(mat2 m) {
  return mat2( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0));
}
mat3 xll_saturate_mf3x3(mat3 m) {
  return mat3( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0));
}
mat4 xll_saturate_mf4x4(mat4 m) {
  return mat4( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0), clamp(m[3], 0.0, 1.0));
}
vec2 xll_vecTSel_vb2_vf2_vf2 (bvec2 a, vec2 b, vec2 c) {
  return vec2 (a.x ? b.x : c.x, a.y ? b.y : c.y);
}
vec3 xll_vecTSel_vb3_vf3_vf3 (bvec3 a, vec3 b, vec3 c) {
  return vec3 (a.x ? b.x : c.x, a.y ? b.y : c.y, a.z ? b.z : c.z);
}
vec4 xll_vecTSel_vb4_vf4_vf4 (bvec4 a, vec4 b, vec4 c) {
  return vec4 (a.x ? b.x : c.x, a.y ? b.y : c.y, a.z ? b.z : c.z, a.w ? b.w : c.w);
}
#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 336
struct SurfaceOutput {
    lowp vec3 Albedo;
    lowp vec3 Normal;
    lowp vec3 Emission;
    mediump float Specular;
    lowp float Gloss;
    lowp float Alpha;
};
#line 533
struct v2f {
    highp vec4 pos;
    highp float viewDist;
    highp vec3 viewDir;
    highp vec3 worldPos;
    highp vec3 _LightCoord;
    highp vec3 _ShadowCoord;
    highp vec3 sphereNormal;
};
#line 525
struct appdata_t {
    highp vec4 vertex;
    highp vec3 normal;
    highp vec4 texcoord;
    highp vec4 texcoord2;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform highp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform samplerCube _ShadowMapTexture;
uniform sampler2D _LightTexture0;
#line 335
uniform highp mat4 _LightMatrix0;
#line 346
uniform lowp vec4 _LightColor0;
uniform lowp vec4 _SpecColor;
#line 359
#line 367
#line 381
uniform highp mat4 _MainRotation;
uniform highp mat4 _DetailRotation;
#line 414
#line 418
#line 427
#line 435
#line 444
#line 452
#line 465
#line 477
#line 493
#line 506
uniform lowp vec4 _SurfaceColor;
#line 514
uniform highp float _Shininess;
uniform sampler2D _MainTex;
uniform sampler2D _DetailTex;
uniform highp float _DetailScale;
#line 518
uniform highp float _DetailDist;
uniform highp float _MinLight;
uniform sampler2D _CameraDepthTexture;
uniform highp mat4 _CameraToWorld;
#line 522
uniform highp float _LightPower;
uniform highp float _PlanetOpacity;
uniform highp vec3 _PlanetOrigin;
#line 544
#line 418
highp vec4 Derivatives( in highp float lat, in highp float lon, in highp vec3 pos ) {
    highp vec2 latLong = vec2( lat, lon);
    highp float latDdx = (0.159155 * length(xll_dFdx_vf2(pos.xz)));
    #line 422
    highp float latDdy = (0.159155 * length(xll_dFdy_vf2(pos.xz)));
    highp float longDdx = xll_dFdx_f(lon);
    highp float longDdy = xll_dFdy_f(lon);
    return vec4( latDdx, longDdx, latDdy, longDdy);
}
#line 427
highp vec2 GetSphereUV( in highp vec3 sphereVect, in highp vec2 uvOffset ) {
    highp vec2 uv;
    uv.x = (0.5 + (0.159155 * atan( sphereVect.x, sphereVect.z)));
    #line 431
    uv.y = (0.31831 * acos(sphereVect.y));
    uv += uvOffset;
    return uv;
}
#line 465
mediump vec4 GetShereDetailMap( in sampler2D texSampler, in highp vec3 sphereVect, in highp float detailScale ) {
    highp vec3 sphereVectNorm = normalize(sphereVect);
    highp vec2 uv = ((GetSphereUV( sphereVectNorm, vec2( 0.0, 0.0)) * 4.0) * detailScale);
    #line 469
    highp vec4 uvdd = Derivatives( (uv.x - 0.5), uv.y, sphereVectNorm);
    sphereVectNorm = abs(sphereVectNorm);
    mediump float zxlerp = step( sphereVectNorm.x, sphereVectNorm.z);
    mediump float nylerp = step( sphereVectNorm.y, mix( sphereVectNorm.x, sphereVectNorm.z, zxlerp));
    #line 473
    mediump vec3 detailCoords = mix( sphereVectNorm.xyz, sphereVectNorm.zxy, vec3( zxlerp));
    detailCoords = mix( sphereVectNorm.yxz, detailCoords, vec3( nylerp));
    return xll_tex2Dgrad( texSampler, (((0.5 * detailCoords.zy) / abs(detailCoords.x)) * detailScale), uvdd.xy, uvdd.zw);
}
#line 444
mediump vec4 GetSphereMap( in sampler2D texSampler, in highp vec3 sphereVect ) {
    highp vec3 sphereVectNorm = normalize(sphereVect);
    highp vec2 uv = GetSphereUV( sphereVectNorm, vec2( 0.0, 0.0));
    #line 448
    highp vec4 uvdd = Derivatives( (uv.x - 0.5), uv.y, sphereVectNorm);
    mediump vec4 tex = xll_tex2Dgrad( texSampler, uv, uvdd.xy, uvdd.zw);
    return tex;
}
#line 493
mediump vec4 SpecularColorLight( in mediump vec3 lightDir, in mediump vec3 viewDir, in mediump vec3 normal, in mediump vec4 color, in mediump vec4 specColor, in highp float specK, in mediump float atten ) {
    lightDir = normalize(lightDir);
    viewDir = normalize(viewDir);
    #line 497
    mediump vec3 h = normalize((lightDir + viewDir));
    mediump float diffuse = dot( normal, lightDir);
    highp float nh = xll_saturate_f(dot( h, normal));
    highp float spec = (pow( nh, specK) * color.w);
    #line 501
    mediump vec4 c;
    c.xyz = ((((color.xyz * _LightColor0.xyz) * diffuse) + ((_LightColor0.xyz * specColor.xyz) * spec)) * (atten * 4.0));
    c.w = (diffuse * (atten * 4.0));
    return c;
}
#line 215
highp float DecodeFloatRGBA( in highp vec4 enc ) {
    highp vec4 kDecodeDot = vec4( 1.0, 0.00392157, 1.53787e-05, 6.22737e-09);
    return dot( enc, kDecodeDot);
}
#line 316
highp float SampleCubeDistance( in highp vec3 vec ) {
    highp vec4 packDist = texture( _ShadowMapTexture, vec);
    #line 319
    return DecodeFloatRGBA( packDist);
}
#line 321
highp float unityCubeShadow( in highp vec3 vec ) {
    #line 323
    highp float mydist = (length(vec) * _LightPositionRange.w);
    mydist *= 0.97;
    highp float z = 0.0078125;
    highp vec4 shadowVals;
    #line 327
    shadowVals.x = SampleCubeDistance( (vec + vec3( z, z, z)));
    shadowVals.y = SampleCubeDistance( (vec + vec3( (-z), (-z), z)));
    shadowVals.z = SampleCubeDistance( (vec + vec3( (-z), z, (-z))));
    shadowVals.w = SampleCubeDistance( (vec + vec3( z, (-z), (-z))));
    #line 331
    mediump vec4 shadows = xll_vecTSel_vb4_vf4_vf4 (lessThan( shadowVals, vec4( mydist)), vec4( _LightShadowData.xxxx), vec4( 1.0));
    return dot( shadows, vec4( 0.25));
}
#line 559
lowp vec4 frag( in v2f IN ) {
    #line 561
    mediump vec4 color;
    highp vec3 sphereNrm = IN.sphereNormal;
    mediump vec4 main = GetSphereMap( _MainTex, sphereNrm);
    mediump vec4 detail = GetShereDetailMap( _DetailTex, sphereNrm, _DetailScale);
    #line 565
    color = _SurfaceColor;
    mediump float detailLevel = xll_saturate_f(((2.0 * _DetailDist) * IN.viewDist));
    color.xyz += (0.5 * mix( (detail.xyz - 0.5), vec3( 0.0), vec3( detailLevel)));
    mediump float handoff = xll_saturate_f(pow( _PlanetOpacity, 2.0));
    #line 569
    color.xyz = mix( color.xyz, main.xyz, vec3( handoff));
    mediump vec4 specColor = _SpecColor;
    specColor.w = mix( 1.0, main.w, handoff);
    mediump vec4 colorLight = SpecularColorLight( vec3( normalize(_WorldSpaceLightPos0)), IN.viewDir, normalize((IN.worldPos - _PlanetOrigin)), color, specColor, (_Shininess * 128.0), (texture( _LightTexture0, vec2( dot( IN._LightCoord, IN._LightCoord))).w * unityCubeShadow( IN._ShadowCoord)));
    #line 573
    color.w = mix( 1.0, color.w, xll_saturate_f((colorLight.w * 4.0)));
    color.w = mix( color.w, 1.0, xll_saturate_f((length(colorLight.xyz) - length((2.0 * color.xyz)))));
    color.w = mix( color.w, 1.0, handoff);
    color.xyz = colorLight.xyz;
    #line 577
    return color;
}
in highp float xlv_TEXCOORD0;
in highp vec3 xlv_TEXCOORD1;
in highp vec3 xlv_TEXCOORD2;
in highp vec3 xlv_TEXCOORD3;
in highp vec3 xlv_TEXCOORD4;
in highp vec3 xlv_TEXCOORD5;
void main() {
    lowp vec4 xl_retval;
    v2f xlt_IN;
    xlt_IN.pos = vec4(0.0);
    xlt_IN.viewDist = float(xlv_TEXCOORD0);
    xlt_IN.viewDir = vec3(xlv_TEXCOORD1);
    xlt_IN.worldPos = vec3(xlv_TEXCOORD2);
    xlt_IN._LightCoord = vec3(xlv_TEXCOORD3);
    xlt_IN._ShadowCoord = vec3(xlv_TEXCOORD4);
    xlt_IN.sphereNormal = vec3(xlv_TEXCOORD5);
    xl_retval = frag( xlt_IN);
    gl_FragData[0] = vec4(xl_retval);
}


#endif"
}

SubProgram "opengl " {
Keywords { "POINT_COOKIE" "SHADOWS_CUBE" "SHADOWS_SOFT" }
"!!GLSL
#ifdef VERTEX
varying vec3 xlv_TEXCOORD5;
varying vec3 xlv_TEXCOORD4;
varying vec3 xlv_TEXCOORD3;
varying vec3 xlv_TEXCOORD2;
varying vec3 xlv_TEXCOORD1;
varying float xlv_TEXCOORD0;
uniform mat4 _LightMatrix0;
uniform mat4 _Object2World;

uniform vec4 _LightPositionRange;
uniform vec3 _WorldSpaceCameraPos;
void main ()
{
  vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * gl_Vertex).xyz;
  vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  vec4 tmpvar_3;
  tmpvar_3.x = gl_MultiTexCoord0.x;
  tmpvar_3.y = gl_MultiTexCoord0.y;
  tmpvar_3.z = gl_MultiTexCoord1.x;
  tmpvar_3.w = gl_MultiTexCoord1.y;
  gl_Position = (gl_ModelViewProjectionMatrix * gl_Vertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * gl_Vertex)).xyz;
  xlv_TEXCOORD4 = ((_Object2World * gl_Vertex).xyz - _LightPositionRange.xyz);
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}


#endif
#ifdef FRAGMENT
#extension GL_ARB_shader_texture_lod : enable
varying vec3 xlv_TEXCOORD5;
varying vec3 xlv_TEXCOORD4;
varying vec3 xlv_TEXCOORD3;
varying vec3 xlv_TEXCOORD2;
varying vec3 xlv_TEXCOORD1;
varying float xlv_TEXCOORD0;
uniform vec3 _PlanetOrigin;
uniform float _PlanetOpacity;
uniform float _DetailDist;
uniform float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform float _Shininess;
uniform vec4 _SurfaceColor;
uniform vec4 _SpecColor;
uniform vec4 _LightColor0;
uniform sampler2D _LightTextureB0;
uniform samplerCube _LightTexture0;
uniform samplerCube _ShadowMapTexture;
uniform vec4 _LightShadowData;
uniform vec4 _LightPositionRange;
uniform vec4 _WorldSpaceLightPos0;
void main ()
{
  vec4 main_1;
  vec4 color_2;
  vec3 tmpvar_3;
  tmpvar_3 = normalize(xlv_TEXCOORD5);
  vec2 uv_4;
  float r_5;
  if ((abs(tmpvar_3.z) > (1e-08 * abs(tmpvar_3.x)))) {
    float y_over_x_6;
    y_over_x_6 = (tmpvar_3.x / tmpvar_3.z);
    float s_7;
    float x_8;
    x_8 = (y_over_x_6 * inversesqrt(((y_over_x_6 * y_over_x_6) + 1.0)));
    s_7 = (sign(x_8) * (1.5708 - (sqrt((1.0 - abs(x_8))) * (1.5708 + (abs(x_8) * (-0.214602 + (abs(x_8) * (0.0865667 + (abs(x_8) * -0.0310296)))))))));
    r_5 = s_7;
    if ((tmpvar_3.z < 0.0)) {
      if ((tmpvar_3.x >= 0.0)) {
        r_5 = (s_7 + 3.14159);
      } else {
        r_5 = (r_5 - 3.14159);
      };
    };
  } else {
    r_5 = (sign(tmpvar_3.x) * 1.5708);
  };
  uv_4.x = (0.5 + (0.159155 * r_5));
  uv_4.y = (0.31831 * (1.5708 - (sign(tmpvar_3.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_3.y))) * (1.5708 + (abs(tmpvar_3.y) * (-0.214602 + (abs(tmpvar_3.y) * (0.0865667 + (abs(tmpvar_3.y) * -0.0310296)))))))))));
  vec2 tmpvar_9;
  tmpvar_9 = dFdx(tmpvar_3.xz);
  vec2 tmpvar_10;
  tmpvar_10 = dFdy(tmpvar_3.xz);
  vec4 tmpvar_11;
  tmpvar_11.x = (0.159155 * sqrt(dot (tmpvar_9, tmpvar_9)));
  tmpvar_11.y = dFdx(uv_4.y);
  tmpvar_11.z = (0.159155 * sqrt(dot (tmpvar_10, tmpvar_10)));
  tmpvar_11.w = dFdy(uv_4.y);
  main_1 = texture2DGradARB (_MainTex, uv_4, tmpvar_11.xy, tmpvar_11.zw);
  vec3 tmpvar_12;
  tmpvar_12 = normalize(xlv_TEXCOORD5);
  vec2 uv_13;
  float r_14;
  if ((abs(tmpvar_12.z) > (1e-08 * abs(tmpvar_12.x)))) {
    float y_over_x_15;
    y_over_x_15 = (tmpvar_12.x / tmpvar_12.z);
    float s_16;
    float x_17;
    x_17 = (y_over_x_15 * inversesqrt(((y_over_x_15 * y_over_x_15) + 1.0)));
    s_16 = (sign(x_17) * (1.5708 - (sqrt((1.0 - abs(x_17))) * (1.5708 + (abs(x_17) * (-0.214602 + (abs(x_17) * (0.0865667 + (abs(x_17) * -0.0310296)))))))));
    r_14 = s_16;
    if ((tmpvar_12.z < 0.0)) {
      if ((tmpvar_12.x >= 0.0)) {
        r_14 = (s_16 + 3.14159);
      } else {
        r_14 = (r_14 - 3.14159);
      };
    };
  } else {
    r_14 = (sign(tmpvar_12.x) * 1.5708);
  };
  uv_13.x = (0.5 + (0.159155 * r_14));
  uv_13.y = (0.31831 * (1.5708 - (sign(tmpvar_12.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_12.y))) * (1.5708 + (abs(tmpvar_12.y) * (-0.214602 + (abs(tmpvar_12.y) * (0.0865667 + (abs(tmpvar_12.y) * -0.0310296)))))))))));
  vec2 tmpvar_18;
  tmpvar_18 = ((uv_13 * 4.0) * _DetailScale);
  vec2 tmpvar_19;
  tmpvar_19 = dFdx(tmpvar_12.xz);
  vec2 tmpvar_20;
  tmpvar_20 = dFdy(tmpvar_12.xz);
  vec4 tmpvar_21;
  tmpvar_21.x = (0.159155 * sqrt(dot (tmpvar_19, tmpvar_19)));
  tmpvar_21.y = dFdx(tmpvar_18.y);
  tmpvar_21.z = (0.159155 * sqrt(dot (tmpvar_20, tmpvar_20)));
  tmpvar_21.w = dFdy(tmpvar_18.y);
  vec3 tmpvar_22;
  tmpvar_22 = abs(tmpvar_12);
  float tmpvar_23;
  tmpvar_23 = float((tmpvar_22.z >= tmpvar_22.x));
  vec3 tmpvar_24;
  tmpvar_24 = mix (tmpvar_22.yxz, mix (tmpvar_22, tmpvar_22.zxy, vec3(tmpvar_23)), vec3(float((mix (tmpvar_22.x, tmpvar_22.z, tmpvar_23) >= tmpvar_22.y))));
  color_2.w = _SurfaceColor.w;
  color_2.xyz = (_SurfaceColor.xyz + (0.5 * mix ((texture2DGradARB (_DetailTex, (((0.5 * tmpvar_24.zy) / abs(tmpvar_24.x)) * _DetailScale), tmpvar_21.xy, tmpvar_21.zw).xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0)))));
  float tmpvar_25;
  tmpvar_25 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  color_2.xyz = mix (color_2.xyz, main_1.xyz, vec3(tmpvar_25));
  vec4 tmpvar_26;
  tmpvar_26 = normalize(_WorldSpaceLightPos0);
  vec3 tmpvar_27;
  tmpvar_27 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  vec4 tmpvar_28;
  tmpvar_28 = texture2D (_LightTextureB0, vec2(dot (xlv_TEXCOORD3, xlv_TEXCOORD3)));
  vec4 tmpvar_29;
  tmpvar_29 = textureCube (_LightTexture0, xlv_TEXCOORD3);
  vec4 shadowVals_30;
  shadowVals_30.x = dot (textureCube (_ShadowMapTexture, (xlv_TEXCOORD4 + vec3(0.0078125, 0.0078125, 0.0078125))), vec4(1.0, 0.00392157, 1.53787e-05, 6.22737e-09));
  shadowVals_30.y = dot (textureCube (_ShadowMapTexture, (xlv_TEXCOORD4 + vec3(-0.0078125, -0.0078125, 0.0078125))), vec4(1.0, 0.00392157, 1.53787e-05, 6.22737e-09));
  shadowVals_30.z = dot (textureCube (_ShadowMapTexture, (xlv_TEXCOORD4 + vec3(-0.0078125, 0.0078125, -0.0078125))), vec4(1.0, 0.00392157, 1.53787e-05, 6.22737e-09));
  shadowVals_30.w = dot (textureCube (_ShadowMapTexture, (xlv_TEXCOORD4 + vec3(0.0078125, -0.0078125, -0.0078125))), vec4(1.0, 0.00392157, 1.53787e-05, 6.22737e-09));
  bvec4 tmpvar_31;
  tmpvar_31 = lessThan (shadowVals_30, vec4(((sqrt(dot (xlv_TEXCOORD4, xlv_TEXCOORD4)) * _LightPositionRange.w) * 0.97)));
  vec4 tmpvar_32;
  tmpvar_32 = _LightShadowData.xxxx;
  float tmpvar_33;
  if (tmpvar_31.x) {
    tmpvar_33 = tmpvar_32.x;
  } else {
    tmpvar_33 = 1.0;
  };
  float tmpvar_34;
  if (tmpvar_31.y) {
    tmpvar_34 = tmpvar_32.y;
  } else {
    tmpvar_34 = 1.0;
  };
  float tmpvar_35;
  if (tmpvar_31.z) {
    tmpvar_35 = tmpvar_32.z;
  } else {
    tmpvar_35 = 1.0;
  };
  float tmpvar_36;
  if (tmpvar_31.w) {
    tmpvar_36 = tmpvar_32.w;
  } else {
    tmpvar_36 = 1.0;
  };
  vec4 tmpvar_37;
  tmpvar_37.x = tmpvar_33;
  tmpvar_37.y = tmpvar_34;
  tmpvar_37.z = tmpvar_35;
  tmpvar_37.w = tmpvar_36;
  float atten_38;
  atten_38 = ((tmpvar_28.w * tmpvar_29.w) * dot (tmpvar_37, vec4(0.25, 0.25, 0.25, 0.25)));
  vec4 c_39;
  vec3 tmpvar_40;
  tmpvar_40 = normalize(tmpvar_26.xyz);
  float tmpvar_41;
  tmpvar_41 = dot (tmpvar_27, tmpvar_40);
  c_39.xyz = ((((color_2.xyz * _LightColor0.xyz) * tmpvar_41) + ((_LightColor0.xyz * _SpecColor.xyz) * (pow (clamp (dot (normalize((tmpvar_40 + normalize(xlv_TEXCOORD1))), tmpvar_27), 0.0, 1.0), (_Shininess * 128.0)) * _SurfaceColor.w))) * (atten_38 * 4.0));
  c_39.w = (tmpvar_41 * (atten_38 * 4.0));
  color_2.w = mix (1.0, _SurfaceColor.w, clamp ((c_39.w * 4.0), 0.0, 1.0));
  vec3 arg0_42;
  arg0_42 = (2.0 * color_2.xyz);
  color_2.w = mix (color_2.w, 1.0, clamp ((sqrt(dot (c_39.xyz, c_39.xyz)) - sqrt(dot (arg0_42, arg0_42))), 0.0, 1.0));
  color_2.w = mix (color_2.w, 1.0, tmpvar_25);
  color_2.xyz = c_39.xyz;
  gl_FragData[0] = color_2;
}


#endif
"
}

SubProgram "d3d9 " {
Keywords { "POINT_COOKIE" "SHADOWS_CUBE" "SHADOWS_SOFT" }
Bind "vertex" Vertex
Bind "texcoord" TexCoord0
Bind "texcoord1" TexCoord1
Matrix 0 [glstate_matrix_mvp]
Vector 12 [_WorldSpaceCameraPos]
Vector 13 [_LightPositionRange]
Matrix 4 [_Object2World]
Matrix 8 [_LightMatrix0]
"vs_3_0
; 25 ALU
dcl_position o0
dcl_texcoord0 o1
dcl_texcoord1 o2
dcl_texcoord2 o3
dcl_texcoord3 o4
dcl_texcoord4 o5
dcl_texcoord5 o6
dcl_position0 v0
dcl_texcoord0 v1
dcl_texcoord1 v2
dp4 r1.z, v0, c6
dp4 r1.x, v0, c4
dp4 r1.y, v0, c5
mov r0.zw, v2.xyxy
mov r0.xy, v1
dp4 r0.w, r0, r0
rsq r1.w, r0.w
mul r0.xyz, r1.w, r0
add r2.xyz, -r1, c12
dp3 r0.w, r2, r2
rsq r1.w, r0.w
mov o6.xyz, -r0
mov r0.xyz, r1
dp4 r0.w, v0, c7
mul o2.xyz, r1.w, r2
dp4 o4.z, r0, c10
dp4 o4.y, r0, c9
dp4 o4.x, r0, c8
rcp o1.x, r1.w
mov o3.xyz, r1
add o5.xyz, r1, -c13
dp4 o0.w, v0, c3
dp4 o0.z, v0, c2
dp4 o0.y, v0, c1
dp4 o0.x, v0, c0
"
}

SubProgram "gles " {
Keywords { "POINT_COOKIE" "SHADOWS_CUBE" "SHADOWS_SOFT" }
"!!GLES


#ifdef VERTEX

varying highp vec3 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD4;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp mat4 _LightMatrix0;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_mvp;
uniform highp vec4 _LightPositionRange;
uniform highp vec3 _WorldSpaceCameraPos;
attribute vec4 _glesMultiTexCoord1;
attribute vec4 _glesMultiTexCoord0;
attribute vec4 _glesVertex;
void main ()
{
  highp vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * _glesVertex).xyz;
  highp vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  highp vec4 tmpvar_3;
  tmpvar_3.x = _glesMultiTexCoord0.x;
  tmpvar_3.y = _glesMultiTexCoord0.y;
  tmpvar_3.z = _glesMultiTexCoord1.x;
  tmpvar_3.w = _glesMultiTexCoord1.y;
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * _glesVertex)).xyz;
  xlv_TEXCOORD4 = ((_Object2World * _glesVertex).xyz - _LightPositionRange.xyz);
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}



#endif
#ifdef FRAGMENT

#extension GL_EXT_shader_texture_lod : enable
#extension GL_OES_standard_derivatives : enable
varying highp vec3 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD4;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp vec3 _PlanetOrigin;
uniform highp float _PlanetOpacity;
uniform highp float _DetailDist;
uniform highp float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform highp float _Shininess;
uniform lowp vec4 _SurfaceColor;
uniform lowp vec4 _SpecColor;
uniform lowp vec4 _LightColor0;
uniform sampler2D _LightTextureB0;
uniform samplerCube _LightTexture0;
uniform samplerCube _ShadowMapTexture;
uniform highp vec4 _LightShadowData;
uniform highp vec4 _LightPositionRange;
uniform highp vec4 _WorldSpaceLightPos0;
void main ()
{
  lowp vec4 tmpvar_1;
  mediump vec4 specColor_2;
  mediump float handoff_3;
  mediump float detailLevel_4;
  mediump vec4 color_5;
  mediump vec4 tex_6;
  highp vec3 tmpvar_7;
  tmpvar_7 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_8;
  highp float r_9;
  if ((abs(tmpvar_7.z) > (1e-08 * abs(tmpvar_7.x)))) {
    highp float y_over_x_10;
    y_over_x_10 = (tmpvar_7.x / tmpvar_7.z);
    highp float s_11;
    highp float x_12;
    x_12 = (y_over_x_10 * inversesqrt(((y_over_x_10 * y_over_x_10) + 1.0)));
    s_11 = (sign(x_12) * (1.5708 - (sqrt((1.0 - abs(x_12))) * (1.5708 + (abs(x_12) * (-0.214602 + (abs(x_12) * (0.0865667 + (abs(x_12) * -0.0310296)))))))));
    r_9 = s_11;
    if ((tmpvar_7.z < 0.0)) {
      if ((tmpvar_7.x >= 0.0)) {
        r_9 = (s_11 + 3.14159);
      } else {
        r_9 = (r_9 - 3.14159);
      };
    };
  } else {
    r_9 = (sign(tmpvar_7.x) * 1.5708);
  };
  uv_8.x = (0.5 + (0.159155 * r_9));
  uv_8.y = (0.31831 * (1.5708 - (sign(tmpvar_7.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_7.y))) * (1.5708 + (abs(tmpvar_7.y) * (-0.214602 + (abs(tmpvar_7.y) * (0.0865667 + (abs(tmpvar_7.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_13;
  tmpvar_13 = dFdx(tmpvar_7.xz);
  highp vec2 tmpvar_14;
  tmpvar_14 = dFdy(tmpvar_7.xz);
  highp vec4 tmpvar_15;
  tmpvar_15.x = (0.159155 * sqrt(dot (tmpvar_13, tmpvar_13)));
  tmpvar_15.y = dFdx(uv_8.y);
  tmpvar_15.z = (0.159155 * sqrt(dot (tmpvar_14, tmpvar_14)));
  tmpvar_15.w = dFdy(uv_8.y);
  lowp vec4 tmpvar_16;
  tmpvar_16 = texture2DGradEXT (_MainTex, uv_8, tmpvar_15.xy, tmpvar_15.zw);
  tex_6 = tmpvar_16;
  mediump vec4 tmpvar_17;
  mediump vec3 detailCoords_18;
  mediump float nylerp_19;
  mediump float zxlerp_20;
  highp vec3 tmpvar_21;
  tmpvar_21 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_22;
  highp float r_23;
  if ((abs(tmpvar_21.z) > (1e-08 * abs(tmpvar_21.x)))) {
    highp float y_over_x_24;
    y_over_x_24 = (tmpvar_21.x / tmpvar_21.z);
    highp float s_25;
    highp float x_26;
    x_26 = (y_over_x_24 * inversesqrt(((y_over_x_24 * y_over_x_24) + 1.0)));
    s_25 = (sign(x_26) * (1.5708 - (sqrt((1.0 - abs(x_26))) * (1.5708 + (abs(x_26) * (-0.214602 + (abs(x_26) * (0.0865667 + (abs(x_26) * -0.0310296)))))))));
    r_23 = s_25;
    if ((tmpvar_21.z < 0.0)) {
      if ((tmpvar_21.x >= 0.0)) {
        r_23 = (s_25 + 3.14159);
      } else {
        r_23 = (r_23 - 3.14159);
      };
    };
  } else {
    r_23 = (sign(tmpvar_21.x) * 1.5708);
  };
  uv_22.x = (0.5 + (0.159155 * r_23));
  uv_22.y = (0.31831 * (1.5708 - (sign(tmpvar_21.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_21.y))) * (1.5708 + (abs(tmpvar_21.y) * (-0.214602 + (abs(tmpvar_21.y) * (0.0865667 + (abs(tmpvar_21.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_27;
  tmpvar_27 = ((uv_22 * 4.0) * _DetailScale);
  highp vec2 tmpvar_28;
  tmpvar_28 = dFdx(tmpvar_21.xz);
  highp vec2 tmpvar_29;
  tmpvar_29 = dFdy(tmpvar_21.xz);
  highp vec4 tmpvar_30;
  tmpvar_30.x = (0.159155 * sqrt(dot (tmpvar_28, tmpvar_28)));
  tmpvar_30.y = dFdx(tmpvar_27.y);
  tmpvar_30.z = (0.159155 * sqrt(dot (tmpvar_29, tmpvar_29)));
  tmpvar_30.w = dFdy(tmpvar_27.y);
  highp vec3 tmpvar_31;
  tmpvar_31 = abs(tmpvar_21);
  highp float tmpvar_32;
  tmpvar_32 = float((tmpvar_31.z >= tmpvar_31.x));
  zxlerp_20 = tmpvar_32;
  highp float tmpvar_33;
  tmpvar_33 = float((mix (tmpvar_31.x, tmpvar_31.z, zxlerp_20) >= tmpvar_31.y));
  nylerp_19 = tmpvar_33;
  highp vec3 tmpvar_34;
  tmpvar_34 = mix (tmpvar_31, tmpvar_31.zxy, vec3(zxlerp_20));
  detailCoords_18 = tmpvar_34;
  highp vec3 tmpvar_35;
  tmpvar_35 = mix (tmpvar_31.yxz, detailCoords_18, vec3(nylerp_19));
  detailCoords_18 = tmpvar_35;
  mediump float tmpvar_36;
  tmpvar_36 = abs(detailCoords_18.x);
  highp vec2 coord_37;
  coord_37 = (((0.5 * detailCoords_18.zy) / tmpvar_36) * _DetailScale);
  lowp vec4 tmpvar_38;
  tmpvar_38 = texture2DGradEXT (_DetailTex, coord_37, tmpvar_30.xy, tmpvar_30.zw);
  tmpvar_17 = tmpvar_38;
  color_5 = _SurfaceColor;
  highp float tmpvar_39;
  tmpvar_39 = clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0);
  detailLevel_4 = tmpvar_39;
  color_5.xyz = (color_5.xyz + (0.5 * mix ((tmpvar_17.xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(detailLevel_4))));
  highp float tmpvar_40;
  tmpvar_40 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  handoff_3 = tmpvar_40;
  color_5.xyz = mix (color_5.xyz, tex_6.xyz, vec3(handoff_3));
  specColor_2.xyz = _SpecColor.xyz;
  specColor_2.w = mix (1.0, tex_6.w, handoff_3);
  highp vec3 tmpvar_41;
  tmpvar_41 = normalize(_WorldSpaceLightPos0).xyz;
  highp vec3 tmpvar_42;
  tmpvar_42 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  highp float tmpvar_43;
  tmpvar_43 = dot (xlv_TEXCOORD3, xlv_TEXCOORD3);
  lowp vec4 tmpvar_44;
  tmpvar_44 = texture2D (_LightTextureB0, vec2(tmpvar_43));
  lowp vec4 tmpvar_45;
  tmpvar_45 = textureCube (_LightTexture0, xlv_TEXCOORD3);
  highp float tmpvar_46;
  mediump vec4 shadows_47;
  highp vec4 shadowVals_48;
  highp float tmpvar_49;
  tmpvar_49 = ((sqrt(dot (xlv_TEXCOORD4, xlv_TEXCOORD4)) * _LightPositionRange.w) * 0.97);
  highp vec3 vec_50;
  vec_50 = (xlv_TEXCOORD4 + vec3(0.0078125, 0.0078125, 0.0078125));
  highp vec4 packDist_51;
  lowp vec4 tmpvar_52;
  tmpvar_52 = textureCube (_ShadowMapTexture, vec_50);
  packDist_51 = tmpvar_52;
  shadowVals_48.x = dot (packDist_51, vec4(1.0, 0.00392157, 1.53787e-05, 6.22737e-09));
  highp vec3 vec_53;
  vec_53 = (xlv_TEXCOORD4 + vec3(-0.0078125, -0.0078125, 0.0078125));
  highp vec4 packDist_54;
  lowp vec4 tmpvar_55;
  tmpvar_55 = textureCube (_ShadowMapTexture, vec_53);
  packDist_54 = tmpvar_55;
  shadowVals_48.y = dot (packDist_54, vec4(1.0, 0.00392157, 1.53787e-05, 6.22737e-09));
  highp vec3 vec_56;
  vec_56 = (xlv_TEXCOORD4 + vec3(-0.0078125, 0.0078125, -0.0078125));
  highp vec4 packDist_57;
  lowp vec4 tmpvar_58;
  tmpvar_58 = textureCube (_ShadowMapTexture, vec_56);
  packDist_57 = tmpvar_58;
  shadowVals_48.z = dot (packDist_57, vec4(1.0, 0.00392157, 1.53787e-05, 6.22737e-09));
  highp vec3 vec_59;
  vec_59 = (xlv_TEXCOORD4 + vec3(0.0078125, -0.0078125, -0.0078125));
  highp vec4 packDist_60;
  lowp vec4 tmpvar_61;
  tmpvar_61 = textureCube (_ShadowMapTexture, vec_59);
  packDist_60 = tmpvar_61;
  shadowVals_48.w = dot (packDist_60, vec4(1.0, 0.00392157, 1.53787e-05, 6.22737e-09));
  bvec4 tmpvar_62;
  tmpvar_62 = lessThan (shadowVals_48, vec4(tmpvar_49));
  highp vec4 tmpvar_63;
  tmpvar_63 = _LightShadowData.xxxx;
  highp float tmpvar_64;
  if (tmpvar_62.x) {
    tmpvar_64 = tmpvar_63.x;
  } else {
    tmpvar_64 = 1.0;
  };
  highp float tmpvar_65;
  if (tmpvar_62.y) {
    tmpvar_65 = tmpvar_63.y;
  } else {
    tmpvar_65 = 1.0;
  };
  highp float tmpvar_66;
  if (tmpvar_62.z) {
    tmpvar_66 = tmpvar_63.z;
  } else {
    tmpvar_66 = 1.0;
  };
  highp float tmpvar_67;
  if (tmpvar_62.w) {
    tmpvar_67 = tmpvar_63.w;
  } else {
    tmpvar_67 = 1.0;
  };
  highp vec4 tmpvar_68;
  tmpvar_68.x = tmpvar_64;
  tmpvar_68.y = tmpvar_65;
  tmpvar_68.z = tmpvar_66;
  tmpvar_68.w = tmpvar_67;
  shadows_47 = tmpvar_68;
  mediump float tmpvar_69;
  tmpvar_69 = dot (shadows_47, vec4(0.25, 0.25, 0.25, 0.25));
  tmpvar_46 = tmpvar_69;
  mediump vec3 lightDir_70;
  lightDir_70 = tmpvar_41;
  mediump vec3 viewDir_71;
  viewDir_71 = xlv_TEXCOORD1;
  mediump vec3 normal_72;
  normal_72 = tmpvar_42;
  mediump float atten_73;
  atten_73 = ((tmpvar_44.w * tmpvar_45.w) * tmpvar_46);
  mediump vec4 c_74;
  highp float nh_75;
  mediump vec3 tmpvar_76;
  tmpvar_76 = normalize(lightDir_70);
  lightDir_70 = tmpvar_76;
  mediump vec3 tmpvar_77;
  tmpvar_77 = normalize(viewDir_71);
  viewDir_71 = tmpvar_77;
  mediump float tmpvar_78;
  tmpvar_78 = dot (normal_72, tmpvar_76);
  mediump float tmpvar_79;
  tmpvar_79 = clamp (dot (normalize((tmpvar_76 + tmpvar_77)), normal_72), 0.0, 1.0);
  nh_75 = tmpvar_79;
  highp vec3 tmpvar_80;
  tmpvar_80 = ((((color_5.xyz * _LightColor0.xyz) * tmpvar_78) + ((_LightColor0.xyz * specColor_2.xyz) * (pow (nh_75, (_Shininess * 128.0)) * color_5.w))) * (atten_73 * 4.0));
  c_74.xyz = tmpvar_80;
  c_74.w = (tmpvar_78 * (atten_73 * 4.0));
  color_5.w = mix (1.0, color_5.w, clamp ((c_74.w * 4.0), 0.0, 1.0));
  mediump vec3 arg0_81;
  arg0_81 = (2.0 * color_5.xyz);
  color_5.w = mix (color_5.w, 1.0, clamp ((sqrt(dot (c_74.xyz, c_74.xyz)) - sqrt(dot (arg0_81, arg0_81))), 0.0, 1.0));
  color_5.w = mix (color_5.w, 1.0, handoff_3);
  color_5.xyz = c_74.xyz;
  tmpvar_1 = color_5;
  gl_FragData[0] = tmpvar_1;
}



#endif"
}

SubProgram "glesdesktop " {
Keywords { "POINT_COOKIE" "SHADOWS_CUBE" "SHADOWS_SOFT" }
"!!GLES


#ifdef VERTEX

varying highp vec3 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD4;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp mat4 _LightMatrix0;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_mvp;
uniform highp vec4 _LightPositionRange;
uniform highp vec3 _WorldSpaceCameraPos;
attribute vec4 _glesMultiTexCoord1;
attribute vec4 _glesMultiTexCoord0;
attribute vec4 _glesVertex;
void main ()
{
  highp vec3 tmpvar_1;
  tmpvar_1 = (_Object2World * _glesVertex).xyz;
  highp vec3 p_2;
  p_2 = (tmpvar_1 - _WorldSpaceCameraPos);
  highp vec4 tmpvar_3;
  tmpvar_3.x = _glesMultiTexCoord0.x;
  tmpvar_3.y = _glesMultiTexCoord0.y;
  tmpvar_3.z = _glesMultiTexCoord1.x;
  tmpvar_3.w = _glesMultiTexCoord1.y;
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = sqrt(dot (p_2, p_2));
  xlv_TEXCOORD1 = normalize((_WorldSpaceCameraPos - tmpvar_1));
  xlv_TEXCOORD2 = tmpvar_1;
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * _glesVertex)).xyz;
  xlv_TEXCOORD4 = ((_Object2World * _glesVertex).xyz - _LightPositionRange.xyz);
  xlv_TEXCOORD5 = -(normalize(tmpvar_3).xyz);
}



#endif
#ifdef FRAGMENT

#extension GL_EXT_shader_texture_lod : enable
#extension GL_OES_standard_derivatives : enable
varying highp vec3 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD4;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp float xlv_TEXCOORD0;
uniform highp vec3 _PlanetOrigin;
uniform highp float _PlanetOpacity;
uniform highp float _DetailDist;
uniform highp float _DetailScale;
uniform sampler2D _DetailTex;
uniform sampler2D _MainTex;
uniform highp float _Shininess;
uniform lowp vec4 _SurfaceColor;
uniform lowp vec4 _SpecColor;
uniform lowp vec4 _LightColor0;
uniform sampler2D _LightTextureB0;
uniform samplerCube _LightTexture0;
uniform samplerCube _ShadowMapTexture;
uniform highp vec4 _LightShadowData;
uniform highp vec4 _LightPositionRange;
uniform highp vec4 _WorldSpaceLightPos0;
void main ()
{
  lowp vec4 tmpvar_1;
  mediump vec4 specColor_2;
  mediump float handoff_3;
  mediump float detailLevel_4;
  mediump vec4 color_5;
  mediump vec4 tex_6;
  highp vec3 tmpvar_7;
  tmpvar_7 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_8;
  highp float r_9;
  if ((abs(tmpvar_7.z) > (1e-08 * abs(tmpvar_7.x)))) {
    highp float y_over_x_10;
    y_over_x_10 = (tmpvar_7.x / tmpvar_7.z);
    highp float s_11;
    highp float x_12;
    x_12 = (y_over_x_10 * inversesqrt(((y_over_x_10 * y_over_x_10) + 1.0)));
    s_11 = (sign(x_12) * (1.5708 - (sqrt((1.0 - abs(x_12))) * (1.5708 + (abs(x_12) * (-0.214602 + (abs(x_12) * (0.0865667 + (abs(x_12) * -0.0310296)))))))));
    r_9 = s_11;
    if ((tmpvar_7.z < 0.0)) {
      if ((tmpvar_7.x >= 0.0)) {
        r_9 = (s_11 + 3.14159);
      } else {
        r_9 = (r_9 - 3.14159);
      };
    };
  } else {
    r_9 = (sign(tmpvar_7.x) * 1.5708);
  };
  uv_8.x = (0.5 + (0.159155 * r_9));
  uv_8.y = (0.31831 * (1.5708 - (sign(tmpvar_7.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_7.y))) * (1.5708 + (abs(tmpvar_7.y) * (-0.214602 + (abs(tmpvar_7.y) * (0.0865667 + (abs(tmpvar_7.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_13;
  tmpvar_13 = dFdx(tmpvar_7.xz);
  highp vec2 tmpvar_14;
  tmpvar_14 = dFdy(tmpvar_7.xz);
  highp vec4 tmpvar_15;
  tmpvar_15.x = (0.159155 * sqrt(dot (tmpvar_13, tmpvar_13)));
  tmpvar_15.y = dFdx(uv_8.y);
  tmpvar_15.z = (0.159155 * sqrt(dot (tmpvar_14, tmpvar_14)));
  tmpvar_15.w = dFdy(uv_8.y);
  lowp vec4 tmpvar_16;
  tmpvar_16 = texture2DGradEXT (_MainTex, uv_8, tmpvar_15.xy, tmpvar_15.zw);
  tex_6 = tmpvar_16;
  mediump vec4 tmpvar_17;
  mediump vec3 detailCoords_18;
  mediump float nylerp_19;
  mediump float zxlerp_20;
  highp vec3 tmpvar_21;
  tmpvar_21 = normalize(xlv_TEXCOORD5);
  highp vec2 uv_22;
  highp float r_23;
  if ((abs(tmpvar_21.z) > (1e-08 * abs(tmpvar_21.x)))) {
    highp float y_over_x_24;
    y_over_x_24 = (tmpvar_21.x / tmpvar_21.z);
    highp float s_25;
    highp float x_26;
    x_26 = (y_over_x_24 * inversesqrt(((y_over_x_24 * y_over_x_24) + 1.0)));
    s_25 = (sign(x_26) * (1.5708 - (sqrt((1.0 - abs(x_26))) * (1.5708 + (abs(x_26) * (-0.214602 + (abs(x_26) * (0.0865667 + (abs(x_26) * -0.0310296)))))))));
    r_23 = s_25;
    if ((tmpvar_21.z < 0.0)) {
      if ((tmpvar_21.x >= 0.0)) {
        r_23 = (s_25 + 3.14159);
      } else {
        r_23 = (r_23 - 3.14159);
      };
    };
  } else {
    r_23 = (sign(tmpvar_21.x) * 1.5708);
  };
  uv_22.x = (0.5 + (0.159155 * r_23));
  uv_22.y = (0.31831 * (1.5708 - (sign(tmpvar_21.y) * (1.5708 - (sqrt((1.0 - abs(tmpvar_21.y))) * (1.5708 + (abs(tmpvar_21.y) * (-0.214602 + (abs(tmpvar_21.y) * (0.0865667 + (abs(tmpvar_21.y) * -0.0310296)))))))))));
  highp vec2 tmpvar_27;
  tmpvar_27 = ((uv_22 * 4.0) * _DetailScale);
  highp vec2 tmpvar_28;
  tmpvar_28 = dFdx(tmpvar_21.xz);
  highp vec2 tmpvar_29;
  tmpvar_29 = dFdy(tmpvar_21.xz);
  highp vec4 tmpvar_30;
  tmpvar_30.x = (0.159155 * sqrt(dot (tmpvar_28, tmpvar_28)));
  tmpvar_30.y = dFdx(tmpvar_27.y);
  tmpvar_30.z = (0.159155 * sqrt(dot (tmpvar_29, tmpvar_29)));
  tmpvar_30.w = dFdy(tmpvar_27.y);
  highp vec3 tmpvar_31;
  tmpvar_31 = abs(tmpvar_21);
  highp float tmpvar_32;
  tmpvar_32 = float((tmpvar_31.z >= tmpvar_31.x));
  zxlerp_20 = tmpvar_32;
  highp float tmpvar_33;
  tmpvar_33 = float((mix (tmpvar_31.x, tmpvar_31.z, zxlerp_20) >= tmpvar_31.y));
  nylerp_19 = tmpvar_33;
  highp vec3 tmpvar_34;
  tmpvar_34 = mix (tmpvar_31, tmpvar_31.zxy, vec3(zxlerp_20));
  detailCoords_18 = tmpvar_34;
  highp vec3 tmpvar_35;
  tmpvar_35 = mix (tmpvar_31.yxz, detailCoords_18, vec3(nylerp_19));
  detailCoords_18 = tmpvar_35;
  mediump float tmpvar_36;
  tmpvar_36 = abs(detailCoords_18.x);
  highp vec2 coord_37;
  coord_37 = (((0.5 * detailCoords_18.zy) / tmpvar_36) * _DetailScale);
  lowp vec4 tmpvar_38;
  tmpvar_38 = texture2DGradEXT (_DetailTex, coord_37, tmpvar_30.xy, tmpvar_30.zw);
  tmpvar_17 = tmpvar_38;
  color_5 = _SurfaceColor;
  highp float tmpvar_39;
  tmpvar_39 = clamp (((2.0 * _DetailDist) * xlv_TEXCOORD0), 0.0, 1.0);
  detailLevel_4 = tmpvar_39;
  color_5.xyz = (color_5.xyz + (0.5 * mix ((tmpvar_17.xyz - 0.5), vec3(0.0, 0.0, 0.0), vec3(detailLevel_4))));
  highp float tmpvar_40;
  tmpvar_40 = clamp (pow (_PlanetOpacity, 2.0), 0.0, 1.0);
  handoff_3 = tmpvar_40;
  color_5.xyz = mix (color_5.xyz, tex_6.xyz, vec3(handoff_3));
  specColor_2.xyz = _SpecColor.xyz;
  specColor_2.w = mix (1.0, tex_6.w, handoff_3);
  highp vec3 tmpvar_41;
  tmpvar_41 = normalize(_WorldSpaceLightPos0).xyz;
  highp vec3 tmpvar_42;
  tmpvar_42 = normalize((xlv_TEXCOORD2 - _PlanetOrigin));
  highp float tmpvar_43;
  tmpvar_43 = dot (xlv_TEXCOORD3, xlv_TEXCOORD3);
  lowp vec4 tmpvar_44;
  tmpvar_44 = texture2D (_LightTextureB0, vec2(tmpvar_43));
  lowp vec4 tmpvar_45;
  tmpvar_45 = textureCube (_LightTexture0, xlv_TEXCOORD3);
  highp float tmpvar_46;
  mediump vec4 shadows_47;
  highp vec4 shadowVals_48;
  highp float tmpvar_49;
  tmpvar_49 = ((sqrt(dot (xlv_TEXCOORD4, xlv_TEXCOORD4)) * _LightPositionRange.w) * 0.97);
  highp vec3 vec_50;
  vec_50 = (xlv_TEXCOORD4 + vec3(0.0078125, 0.0078125, 0.0078125));
  highp vec4 packDist_51;
  lowp vec4 tmpvar_52;
  tmpvar_52 = textureCube (_ShadowMapTexture, vec_50);
  packDist_51 = tmpvar_52;
  shadowVals_48.x = dot (packDist_51, vec4(1.0, 0.00392157, 1.53787e-05, 6.22737e-09));
  highp vec3 vec_53;
  vec_53 = (xlv_TEXCOORD4 + vec3(-0.0078125, -0.0078125, 0.0078125));
  highp vec4 packDist_54;
  lowp vec4 tmpvar_55;
  tmpvar_55 = textureCube (_ShadowMapTexture, vec_53);
  packDist_54 = tmpvar_55;
  shadowVals_48.y = dot (packDist_54, vec4(1.0, 0.00392157, 1.53787e-05, 6.22737e-09));
  highp vec3 vec_56;
  vec_56 = (xlv_TEXCOORD4 + vec3(-0.0078125, 0.0078125, -0.0078125));
  highp vec4 packDist_57;
  lowp vec4 tmpvar_58;
  tmpvar_58 = textureCube (_ShadowMapTexture, vec_56);
  packDist_57 = tmpvar_58;
  shadowVals_48.z = dot (packDist_57, vec4(1.0, 0.00392157, 1.53787e-05, 6.22737e-09));
  highp vec3 vec_59;
  vec_59 = (xlv_TEXCOORD4 + vec3(0.0078125, -0.0078125, -0.0078125));
  highp vec4 packDist_60;
  lowp vec4 tmpvar_61;
  tmpvar_61 = textureCube (_ShadowMapTexture, vec_59);
  packDist_60 = tmpvar_61;
  shadowVals_48.w = dot (packDist_60, vec4(1.0, 0.00392157, 1.53787e-05, 6.22737e-09));
  bvec4 tmpvar_62;
  tmpvar_62 = lessThan (shadowVals_48, vec4(tmpvar_49));
  highp vec4 tmpvar_63;
  tmpvar_63 = _LightShadowData.xxxx;
  highp float tmpvar_64;
  if (tmpvar_62.x) {
    tmpvar_64 = tmpvar_63.x;
  } else {
    tmpvar_64 = 1.0;
  };
  highp float tmpvar_65;
  if (tmpvar_62.y) {
    tmpvar_65 = tmpvar_63.y;
  } else {
    tmpvar_65 = 1.0;
  };
  highp float tmpvar_66;
  if (tmpvar_62.z) {
    tmpvar_66 = tmpvar_63.z;
  } else {
    tmpvar_66 = 1.0;
  };
  highp float tmpvar_67;
  if (tmpvar_62.w) {
    tmpvar_67 = tmpvar_63.w;
  } else {
    tmpvar_67 = 1.0;
  };
  highp vec4 tmpvar_68;
  tmpvar_68.x = tmpvar_64;
  tmpvar_68.y = tmpvar_65;
  tmpvar_68.z = tmpvar_66;
  tmpvar_68.w = tmpvar_67;
  shadows_47 = tmpvar_68;
  mediump float tmpvar_69;
  tmpvar_69 = dot (shadows_47, vec4(0.25, 0.25, 0.25, 0.25));
  tmpvar_46 = tmpvar_69;
  mediump vec3 lightDir_70;
  lightDir_70 = tmpvar_41;
  mediump vec3 viewDir_71;
  viewDir_71 = xlv_TEXCOORD1;
  mediump vec3 normal_72;
  normal_72 = tmpvar_42;
  mediump float atten_73;
  atten_73 = ((tmpvar_44.w * tmpvar_45.w) * tmpvar_46);
  mediump vec4 c_74;
  highp float nh_75;
  mediump vec3 tmpvar_76;
  tmpvar_76 = normalize(lightDir_70);
  lightDir_70 = tmpvar_76;
  mediump vec3 tmpvar_77;
  tmpvar_77 = normalize(viewDir_71);
  viewDir_71 = tmpvar_77;
  mediump float tmpvar_78;
  tmpvar_78 = dot (normal_72, tmpvar_76);
  mediump float tmpvar_79;
  tmpvar_79 = clamp (dot (normalize((tmpvar_76 + tmpvar_77)), normal_72), 0.0, 1.0);
  nh_75 = tmpvar_79;
  highp vec3 tmpvar_80;
  tmpvar_80 = ((((color_5.xyz * _LightColor0.xyz) * tmpvar_78) + ((_LightColor0.xyz * specColor_2.xyz) * (pow (nh_75, (_Shininess * 128.0)) * color_5.w))) * (atten_73 * 4.0));
  c_74.xyz = tmpvar_80;
  c_74.w = (tmpvar_78 * (atten_73 * 4.0));
  color_5.w = mix (1.0, color_5.w, clamp ((c_74.w * 4.0), 0.0, 1.0));
  mediump vec3 arg0_81;
  arg0_81 = (2.0 * color_5.xyz);
  color_5.w = mix (color_5.w, 1.0, clamp ((sqrt(dot (c_74.xyz, c_74.xyz)) - sqrt(dot (arg0_81, arg0_81))), 0.0, 1.0));
  color_5.w = mix (color_5.w, 1.0, handoff_3);
  color_5.xyz = c_74.xyz;
  tmpvar_1 = color_5;
  gl_FragData[0] = tmpvar_1;
}



#endif"
}

SubProgram "gles3 " {
Keywords { "POINT_COOKIE" "SHADOWS_CUBE" "SHADOWS_SOFT" }
"!!GLES3#version 300 es


#ifdef VERTEX

#define gl_Vertex _glesVertex
in vec4 _glesVertex;
#define gl_Normal (normalize(_glesNormal))
in vec3 _glesNormal;
#define gl_MultiTexCoord0 _glesMultiTexCoord0
in vec4 _glesMultiTexCoord0;
#define gl_MultiTexCoord1 _glesMultiTexCoord1
in vec4 _glesMultiTexCoord1;

#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 337
struct SurfaceOutput {
    lowp vec3 Albedo;
    lowp vec3 Normal;
    lowp vec3 Emission;
    mediump float Specular;
    lowp float Gloss;
    lowp float Alpha;
};
#line 534
struct v2f {
    highp vec4 pos;
    highp float viewDist;
    highp vec3 viewDir;
    highp vec3 worldPos;
    highp vec3 _LightCoord;
    highp vec3 _ShadowCoord;
    highp vec3 sphereNormal;
};
#line 526
struct appdata_t {
    highp vec4 vertex;
    highp vec3 normal;
    highp vec4 texcoord;
    highp vec4 texcoord2;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform highp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform samplerCube _ShadowMapTexture;
uniform samplerCube _LightTexture0;
#line 335
uniform highp mat4 _LightMatrix0;
uniform sampler2D _LightTextureB0;
#line 347
uniform lowp vec4 _LightColor0;
uniform lowp vec4 _SpecColor;
#line 360
#line 368
#line 382
uniform highp mat4 _MainRotation;
uniform highp mat4 _DetailRotation;
#line 415
#line 419
#line 428
#line 436
#line 445
#line 453
#line 466
#line 478
#line 494
#line 507
uniform lowp vec4 _SurfaceColor;
#line 515
uniform highp float _Shininess;
uniform sampler2D _MainTex;
uniform sampler2D _DetailTex;
uniform highp float _DetailScale;
#line 519
uniform highp float _DetailDist;
uniform highp float _MinLight;
uniform sampler2D _CameraDepthTexture;
uniform highp mat4 _CameraToWorld;
#line 523
uniform highp float _LightPower;
uniform highp float _PlanetOpacity;
uniform highp vec3 _PlanetOrigin;
#line 545
#line 545
v2f vert( in appdata_t v ) {
    v2f o;
    highp vec4 vertex = v.vertex;
    #line 549
    o.pos = (glstate_matrix_mvp * vertex).xyzw;
    highp vec3 vertexPos = (_Object2World * vertex).xyz;
    o.viewDist = distance( vertexPos, _WorldSpaceCameraPos);
    o.worldPos = vertexPos;
    #line 553
    o.sphereNormal = (-normalize(vec4( v.texcoord.x, v.texcoord.y, v.texcoord2.x, v.texcoord2.y)).xyz);
    o.viewDir = normalize((_WorldSpaceCameraPos.xyz - vertexPos));
    o._LightCoord = (_LightMatrix0 * (_Object2World * v.vertex)).xyz;
    o._ShadowCoord = ((_Object2World * v.vertex).xyz - _LightPositionRange.xyz);
    #line 558
    return o;
}
out highp float xlv_TEXCOORD0;
out highp vec3 xlv_TEXCOORD1;
out highp vec3 xlv_TEXCOORD2;
out highp vec3 xlv_TEXCOORD3;
out highp vec3 xlv_TEXCOORD4;
out highp vec3 xlv_TEXCOORD5;
void main() {
    v2f xl_retval;
    appdata_t xlt_v;
    xlt_v.vertex = vec4(gl_Vertex);
    xlt_v.normal = vec3(gl_Normal);
    xlt_v.texcoord = vec4(gl_MultiTexCoord0);
    xlt_v.texcoord2 = vec4(gl_MultiTexCoord1);
    xl_retval = vert( xlt_v);
    gl_Position = vec4(xl_retval.pos);
    xlv_TEXCOORD0 = float(xl_retval.viewDist);
    xlv_TEXCOORD1 = vec3(xl_retval.viewDir);
    xlv_TEXCOORD2 = vec3(xl_retval.worldPos);
    xlv_TEXCOORD3 = vec3(xl_retval._LightCoord);
    xlv_TEXCOORD4 = vec3(xl_retval._ShadowCoord);
    xlv_TEXCOORD5 = vec3(xl_retval.sphereNormal);
}


#endif
#ifdef FRAGMENT

#define gl_FragData _glesFragData
layout(location = 0) out mediump vec4 _glesFragData[4];
float xll_dFdx_f(float f) {
  return dFdx(f);
}
vec2 xll_dFdx_vf2(vec2 v) {
  return dFdx(v);
}
vec3 xll_dFdx_vf3(vec3 v) {
  return dFdx(v);
}
vec4 xll_dFdx_vf4(vec4 v) {
  return dFdx(v);
}
mat2 xll_dFdx_mf2x2(mat2 m) {
  return mat2( dFdx(m[0]), dFdx(m[1]));
}
mat3 xll_dFdx_mf3x3(mat3 m) {
  return mat3( dFdx(m[0]), dFdx(m[1]), dFdx(m[2]));
}
mat4 xll_dFdx_mf4x4(mat4 m) {
  return mat4( dFdx(m[0]), dFdx(m[1]), dFdx(m[2]), dFdx(m[3]));
}
float xll_dFdy_f(float f) {
  return dFdy(f);
}
vec2 xll_dFdy_vf2(vec2 v) {
  return dFdy(v);
}
vec3 xll_dFdy_vf3(vec3 v) {
  return dFdy(v);
}
vec4 xll_dFdy_vf4(vec4 v) {
  return dFdy(v);
}
mat2 xll_dFdy_mf2x2(mat2 m) {
  return mat2( dFdy(m[0]), dFdy(m[1]));
}
mat3 xll_dFdy_mf3x3(mat3 m) {
  return mat3( dFdy(m[0]), dFdy(m[1]), dFdy(m[2]));
}
mat4 xll_dFdy_mf4x4(mat4 m) {
  return mat4( dFdy(m[0]), dFdy(m[1]), dFdy(m[2]), dFdy(m[3]));
}
vec4 xll_tex2Dgrad(sampler2D s, vec2 coord, vec2 ddx, vec2 ddy) {
   return textureGrad( s, coord, ddx, ddy);
}
float xll_saturate_f( float x) {
  return clamp( x, 0.0, 1.0);
}
vec2 xll_saturate_vf2( vec2 x) {
  return clamp( x, 0.0, 1.0);
}
vec3 xll_saturate_vf3( vec3 x) {
  return clamp( x, 0.0, 1.0);
}
vec4 xll_saturate_vf4( vec4 x) {
  return clamp( x, 0.0, 1.0);
}
mat2 xll_saturate_mf2x2(mat2 m) {
  return mat2( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0));
}
mat3 xll_saturate_mf3x3(mat3 m) {
  return mat3( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0));
}
mat4 xll_saturate_mf4x4(mat4 m) {
  return mat4( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0), clamp(m[3], 0.0, 1.0));
}
vec2 xll_vecTSel_vb2_vf2_vf2 (bvec2 a, vec2 b, vec2 c) {
  return vec2 (a.x ? b.x : c.x, a.y ? b.y : c.y);
}
vec3 xll_vecTSel_vb3_vf3_vf3 (bvec3 a, vec3 b, vec3 c) {
  return vec3 (a.x ? b.x : c.x, a.y ? b.y : c.y, a.z ? b.z : c.z);
}
vec4 xll_vecTSel_vb4_vf4_vf4 (bvec4 a, vec4 b, vec4 c) {
  return vec4 (a.x ? b.x : c.x, a.y ? b.y : c.y, a.z ? b.z : c.z, a.w ? b.w : c.w);
}
#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 337
struct SurfaceOutput {
    lowp vec3 Albedo;
    lowp vec3 Normal;
    lowp vec3 Emission;
    mediump float Specular;
    lowp float Gloss;
    lowp float Alpha;
};
#line 534
struct v2f {
    highp vec4 pos;
    highp float viewDist;
    highp vec3 viewDir;
    highp vec3 worldPos;
    highp vec3 _LightCoord;
    highp vec3 _ShadowCoord;
    highp vec3 sphereNormal;
};
#line 526
struct appdata_t {
    highp vec4 vertex;
    highp vec3 normal;
    highp vec4 texcoord;
    highp vec4 texcoord2;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform highp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform samplerCube _ShadowMapTexture;
uniform samplerCube _LightTexture0;
#line 335
uniform highp mat4 _LightMatrix0;
uniform sampler2D _LightTextureB0;
#line 347
uniform lowp vec4 _LightColor0;
uniform lowp vec4 _SpecColor;
#line 360
#line 368
#line 382
uniform highp mat4 _MainRotation;
uniform highp mat4 _DetailRotation;
#line 415
#line 419
#line 428
#line 436
#line 445
#line 453
#line 466
#line 478
#line 494
#line 507
uniform lowp vec4 _SurfaceColor;
#line 515
uniform highp float _Shininess;
uniform sampler2D _MainTex;
uniform sampler2D _DetailTex;
uniform highp float _DetailScale;
#line 519
uniform highp float _DetailDist;
uniform highp float _MinLight;
uniform sampler2D _CameraDepthTexture;
uniform highp mat4 _CameraToWorld;
#line 523
uniform highp float _LightPower;
uniform highp float _PlanetOpacity;
uniform highp vec3 _PlanetOrigin;
#line 545
#line 419
highp vec4 Derivatives( in highp float lat, in highp float lon, in highp vec3 pos ) {
    highp vec2 latLong = vec2( lat, lon);
    highp float latDdx = (0.159155 * length(xll_dFdx_vf2(pos.xz)));
    #line 423
    highp float latDdy = (0.159155 * length(xll_dFdy_vf2(pos.xz)));
    highp float longDdx = xll_dFdx_f(lon);
    highp float longDdy = xll_dFdy_f(lon);
    return vec4( latDdx, longDdx, latDdy, longDdy);
}
#line 428
highp vec2 GetSphereUV( in highp vec3 sphereVect, in highp vec2 uvOffset ) {
    highp vec2 uv;
    uv.x = (0.5 + (0.159155 * atan( sphereVect.x, sphereVect.z)));
    #line 432
    uv.y = (0.31831 * acos(sphereVect.y));
    uv += uvOffset;
    return uv;
}
#line 466
mediump vec4 GetShereDetailMap( in sampler2D texSampler, in highp vec3 sphereVect, in highp float detailScale ) {
    highp vec3 sphereVectNorm = normalize(sphereVect);
    highp vec2 uv = ((GetSphereUV( sphereVectNorm, vec2( 0.0, 0.0)) * 4.0) * detailScale);
    #line 470
    highp vec4 uvdd = Derivatives( (uv.x - 0.5), uv.y, sphereVectNorm);
    sphereVectNorm = abs(sphereVectNorm);
    mediump float zxlerp = step( sphereVectNorm.x, sphereVectNorm.z);
    mediump float nylerp = step( sphereVectNorm.y, mix( sphereVectNorm.x, sphereVectNorm.z, zxlerp));
    #line 474
    mediump vec3 detailCoords = mix( sphereVectNorm.xyz, sphereVectNorm.zxy, vec3( zxlerp));
    detailCoords = mix( sphereVectNorm.yxz, detailCoords, vec3( nylerp));
    return xll_tex2Dgrad( texSampler, (((0.5 * detailCoords.zy) / abs(detailCoords.x)) * detailScale), uvdd.xy, uvdd.zw);
}
#line 445
mediump vec4 GetSphereMap( in sampler2D texSampler, in highp vec3 sphereVect ) {
    highp vec3 sphereVectNorm = normalize(sphereVect);
    highp vec2 uv = GetSphereUV( sphereVectNorm, vec2( 0.0, 0.0));
    #line 449
    highp vec4 uvdd = Derivatives( (uv.x - 0.5), uv.y, sphereVectNorm);
    mediump vec4 tex = xll_tex2Dgrad( texSampler, uv, uvdd.xy, uvdd.zw);
    return tex;
}
#line 494
mediump vec4 SpecularColorLight( in mediump vec3 lightDir, in mediump vec3 viewDir, in mediump vec3 normal, in mediump vec4 color, in mediump vec4 specColor, in highp float specK, in mediump float atten ) {
    lightDir = normalize(lightDir);
    viewDir = normalize(viewDir);
    #line 498
    mediump vec3 h = normalize((lightDir + viewDir));
    mediump float diffuse = dot( normal, lightDir);
    highp float nh = xll_saturate_f(dot( h, normal));
    highp float spec = (pow( nh, specK) * color.w);
    #line 502
    mediump vec4 c;
    c.xyz = ((((color.xyz * _LightColor0.xyz) * diffuse) + ((_LightColor0.xyz * specColor.xyz) * spec)) * (atten * 4.0));
    c.w = (diffuse * (atten * 4.0));
    return c;
}
#line 215
highp float DecodeFloatRGBA( in highp vec4 enc ) {
    highp vec4 kDecodeDot = vec4( 1.0, 0.00392157, 1.53787e-05, 6.22737e-09);
    return dot( enc, kDecodeDot);
}
#line 316
highp float SampleCubeDistance( in highp vec3 vec ) {
    highp vec4 packDist = texture( _ShadowMapTexture, vec);
    #line 319
    return DecodeFloatRGBA( packDist);
}
#line 321
highp float unityCubeShadow( in highp vec3 vec ) {
    #line 323
    highp float mydist = (length(vec) * _LightPositionRange.w);
    mydist *= 0.97;
    highp float z = 0.0078125;
    highp vec4 shadowVals;
    #line 327
    shadowVals.x = SampleCubeDistance( (vec + vec3( z, z, z)));
    shadowVals.y = SampleCubeDistance( (vec + vec3( (-z), (-z), z)));
    shadowVals.z = SampleCubeDistance( (vec + vec3( (-z), z, (-z))));
    shadowVals.w = SampleCubeDistance( (vec + vec3( z, (-z), (-z))));
    #line 331
    mediump vec4 shadows = xll_vecTSel_vb4_vf4_vf4 (lessThan( shadowVals, vec4( mydist)), vec4( _LightShadowData.xxxx), vec4( 1.0));
    return dot( shadows, vec4( 0.25));
}
#line 560
lowp vec4 frag( in v2f IN ) {
    #line 562
    mediump vec4 color;
    highp vec3 sphereNrm = IN.sphereNormal;
    mediump vec4 main = GetSphereMap( _MainTex, sphereNrm);
    mediump vec4 detail = GetShereDetailMap( _DetailTex, sphereNrm, _DetailScale);
    #line 566
    color = _SurfaceColor;
    mediump float detailLevel = xll_saturate_f(((2.0 * _DetailDist) * IN.viewDist));
    color.xyz += (0.5 * mix( (detail.xyz - 0.5), vec3( 0.0), vec3( detailLevel)));
    mediump float handoff = xll_saturate_f(pow( _PlanetOpacity, 2.0));
    #line 570
    color.xyz = mix( color.xyz, main.xyz, vec3( handoff));
    mediump vec4 specColor = _SpecColor;
    specColor.w = mix( 1.0, main.w, handoff);
    mediump vec4 colorLight = SpecularColorLight( vec3( normalize(_WorldSpaceLightPos0)), IN.viewDir, normalize((IN.worldPos - _PlanetOrigin)), color, specColor, (_Shininess * 128.0), ((texture( _LightTextureB0, vec2( dot( IN._LightCoord, IN._LightCoord))).w * texture( _LightTexture0, IN._LightCoord).w) * unityCubeShadow( IN._ShadowCoord)));
    #line 574
    color.w = mix( 1.0, color.w, xll_saturate_f((colorLight.w * 4.0)));
    color.w = mix( color.w, 1.0, xll_saturate_f((length(colorLight.xyz) - length((2.0 * color.xyz)))));
    color.w = mix( color.w, 1.0, handoff);
    color.xyz = colorLight.xyz;
    #line 578
    return color;
}
in highp float xlv_TEXCOORD0;
in highp vec3 xlv_TEXCOORD1;
in highp vec3 xlv_TEXCOORD2;
in highp vec3 xlv_TEXCOORD3;
in highp vec3 xlv_TEXCOORD4;
in highp vec3 xlv_TEXCOORD5;
void main() {
    lowp vec4 xl_retval;
    v2f xlt_IN;
    xlt_IN.pos = vec4(0.0);
    xlt_IN.viewDist = float(xlv_TEXCOORD0);
    xlt_IN.viewDir = vec3(xlv_TEXCOORD1);
    xlt_IN.worldPos = vec3(xlv_TEXCOORD2);
    xlt_IN._LightCoord = vec3(xlv_TEXCOORD3);
    xlt_IN._ShadowCoord = vec3(xlv_TEXCOORD4);
    xlt_IN.sphereNormal = vec3(xlv_TEXCOORD5);
    xl_retval = frag( xlt_IN);
    gl_FragData[0] = vec4(xl_retval);
}


#endif"
}

}
Program "fp" {
// Fragment combos: 15
//   d3d9 - ALU: 129 to 154, TEX: 6 to 12
SubProgram "opengl " {
Keywords { "POINT" "SHADOWS_OFF" }
"!!GLSL"
}

SubProgram "d3d9 " {
Keywords { "POINT" "SHADOWS_OFF" }
Vector 0 [_WorldSpaceLightPos0]
Vector 1 [_LightColor0]
Vector 2 [_SpecColor]
Vector 3 [_SurfaceColor]
Float 4 [_Shininess]
Float 5 [_DetailScale]
Float 6 [_DetailDist]
Float 7 [_PlanetOpacity]
Vector 8 [_PlanetOrigin]
SetTexture 0 [_MainTex] 2D
SetTexture 1 [_DetailTex] 2D
SetTexture 2 [_LightTexture0] 2D
"ps_3_0
; 133 ALU, 7 TEX
dcl_2d s0
dcl_2d s1
dcl_2d s2
def c9, 128.00000000, 0.00000000, 1.00000000, -0.21211439
def c10, -0.01872930, 0.07426100, 1.57072902, 2.00000000
def c11, 3.14159298, 0.31830987, -0.01348047, 0.05747731
def c12, -0.12123910, 0.19563590, -0.33299461, 0.99999559
def c13, 1.57079601, 0.15915494, 0.50000000, 1.27323949
def c14, -0.50000000, 4.00000000, 16.00000000, -1.00000000
dcl_texcoord0 v0.x
dcl_texcoord1 v1.xyz
dcl_texcoord2 v2.xyz
dcl_texcoord3 v3.xyz
dcl_texcoord5 v4.xyz
dp3 r0.x, v4, v4
rsq r0.x, r0.x
mul r1.xyz, r0.x, v4
abs r2.xyz, r1
add r0.w, r2.z, -r2.x
add r0.xyz, r2.zxyw, -r2
cmp r0.w, r0, c9.z, c9.y
mad r0.xyz, r0.w, r0, r2
add r0.w, -r2.y, r0.x
cmp r2.w, r0, c9.z, c9.y
abs r0.w, r1.z
add r0.xyz, -r2.yxzw, r0
mad r0.xyz, r2.w, r0, r2.yxzw
max r1.w, r2.x, r0
rcp r2.y, r1.w
min r1.w, r2.x, r0
mul r1.w, r1, r2.y
abs_pp r0.x, r0
rcp_pp r2.z, r0.x
mul r2.y, r1.w, r1.w
mul_pp r2.zw, r0.xyzy, r2.z
mad r0.x, r2.y, c11.z, c11.w
mad r0.x, r0, r2.y, c12
mul_pp r2.zw, r2, c13.z
mad r0.z, r0.x, r2.y, c12.y
mul r0.xy, r2.zwzw, c5.x
mad r2.z, r0, r2.y, c12
mad r2.w, r2.z, r2.y, c12
abs r0.z, r1.y
add r2.z, -r0, c9
mad r2.y, r0.z, c10.x, c10
mad r2.y, r2, r0.z, c9.w
rsq r2.z, r2.z
mul r1.w, r2, r1
mad r0.z, r2.y, r0, c10
rcp r2.z, r2.z
mul r2.y, r0.z, r2.z
cmp r0.z, r1.y, c9.y, c9
mul r1.y, r0.z, r2
mad r1.y, -r1, c10.w, r2
mad r1.y, r0.z, c11.x, r1
dsy r2.zw, r1.xyxz
mul r2.zw, r2, r2
add r2.y, -r1.w, c13.x
add r0.z, r2.x, -r0.w
cmp r0.z, -r0, r1.w, r2.y
mul r1.w, r1.y, c5.x
add r0.w, -r0.z, c11.x
cmp r3.x, r1.z, r0.z, r0.w
dsx r0.zw, r1.xyxz
mul r0.zw, r0, r0
add r0.z, r0, r0.w
add r0.w, r2.z, r2
cmp r1.x, r1, r3, -r3
mul r1.w, r1, c13
dsx r2.y, r1.w
rsq r0.z, r0.z
rcp r0.z, r0.z
rsq r0.w, r0.w
rcp r0.w, r0.w
mul r1.z, r0.w, c13.y
mul r0.w, r1.y, c11.y
mul r2.x, r0.z, c13.y
dsy r1.w, r1
texldd r0.xyz, r0, s1, r2, r1.zwzw
mov r1.y, r0.w
dsy r1.w, r0
mad r1.x, r1, c13.y, c13.z
dsx r2.y, r0.w
texldd r2.xyz, r1, s0, r2, r1.zwzw
add_pp r1.xyz, r0, c14.x
mul r0.y, v0.x, c6.x
mul_sat r0.y, r0, c10.w
mad_pp r3.xyz, r0.y, -r1, r1
dp4 r0.x, c0, c0
rsq r0.x, r0.x
mul r0.xyz, r0.x, c0
dp3_pp r0.w, r0, r0
rsq_pp r1.w, r0.w
mov_pp r1.xyz, c3
mad_pp r1.xyz, r3, c13.z, r1
add_pp r3.xyz, r2, -r1
mul_pp r2.xyz, r1.w, r0
dp3_pp r0.w, v1, v1
rsq_pp r0.x, r0.w
mad_pp r0.xyz, r0.x, v1, r2
mul_sat r1.w, c7.x, c7.x
mad_pp r1.xyz, r1.w, r3, r1
dp3_pp r0.w, r0, r0
add r3.xyz, v2, -c8
rsq_pp r0.w, r0.w
mul_pp r4.xyz, r1, c1
dp3 r2.w, r3, r3
mul_pp r0.xyz, r0.w, r0
rsq r0.w, r2.w
mov r2.w, c4.x
mul r3.xyz, r0.w, r3
mul r3.w, c9.x, r2
dp3_pp_sat r2.w, r0, r3
pow r0, r2.w, r3.w
dp3_pp r0.y, r2, r3
mul r0.z, r0.x, c3.w
dp3 r0.x, v3, v3
texld r0.x, r0.x, s2
mul_pp r0.w, r0.x, c14.y
mul_pp r0.x, r0.y, r0
mov_pp r2.xyz, c1
mul_pp r3.xyz, r4, r0.y
mul_pp r2.xyz, c2, r2
mad r2.xyz, r2, r0.z, r3
mul r2.xyz, r2, r0.w
mul_pp r1.xyz, r1, c10.w
dp3_pp r0.w, r1, r1
rsq_pp r1.x, r0.w
dp3_pp r0.z, r2, r2
rsq_pp r0.z, r0.z
rcp_pp r0.w, r0.z
mov_pp r0.z, c3.w
mul_pp_sat r0.x, r0, c14.z
add_pp r0.y, c14.w, r0.z
mul_pp r0.y, r0.x, r0
rcp_pp r1.x, r1.x
add_pp_sat r0.x, r0.w, -r1
mad_pp r0.x, r0, -r0.y, r0.y
add_pp r0.x, r0, c9.z
add_pp r0.y, -r0.x, c9.z
mad_pp r2.w, r1, r0.y, r0.x
mov_pp oC0, r2
"
}

SubProgram "gles " {
Keywords { "POINT" "SHADOWS_OFF" }
"!!GLES"
}

SubProgram "glesdesktop " {
Keywords { "POINT" "SHADOWS_OFF" }
"!!GLES"
}

SubProgram "gles3 " {
Keywords { "POINT" "SHADOWS_OFF" }
"!!GLES3"
}

SubProgram "opengl " {
Keywords { "DIRECTIONAL" "SHADOWS_OFF" }
"!!GLSL"
}

SubProgram "d3d9 " {
Keywords { "DIRECTIONAL" "SHADOWS_OFF" }
Vector 0 [_WorldSpaceLightPos0]
Vector 1 [_LightColor0]
Vector 2 [_SpecColor]
Vector 3 [_SurfaceColor]
Float 4 [_Shininess]
Float 5 [_DetailScale]
Float 6 [_DetailDist]
Float 7 [_PlanetOpacity]
Vector 8 [_PlanetOrigin]
SetTexture 0 [_MainTex] 2D
SetTexture 1 [_DetailTex] 2D
"ps_3_0
; 130 ALU, 6 TEX
dcl_2d s0
dcl_2d s1
def c9, 128.00000000, 0.00000000, 1.00000000, -0.21211439
def c10, -0.01872930, 0.07426100, 1.57072902, 2.00000000
def c11, 3.14159298, 0.31830987, -0.01348047, 0.05747731
def c12, -0.12123910, 0.19563590, -0.33299461, 0.99999559
def c13, 1.57079601, 0.15915494, 0.50000000, 1.27323949
def c14, -0.50000000, 4.00000000, 16.00000000, -1.00000000
dcl_texcoord0 v0.x
dcl_texcoord1 v1.xyz
dcl_texcoord2 v2.xyz
dcl_texcoord5 v3.xyz
dp3 r0.x, v3, v3
rsq r0.x, r0.x
mul r1.xyz, r0.x, v3
abs r2.xyz, r1
add r0.w, r2.z, -r2.x
dsy r4.xy, r1.xzzw
add r0.xyz, r2.zxyw, -r2
cmp r0.w, r0, c9.z, c9.y
mad r0.xyz, r0.w, r0, r2
add r0.w, -r2.y, r0.x
abs r1.w, r1.z
add r0.xyz, -r2.yxzw, r0
cmp r0.w, r0, c9.z, c9.y
mad r0.xyz, r0.w, r0, r2.yxzw
abs_pp r0.x, r0
rcp_pp r0.x, r0.x
mul_pp r0.xy, r0.zyzw, r0.x
max r0.z, r2.x, r1.w
rcp r0.w, r0.z
min r0.z, r2.x, r1.w
mul r2.y, r0.z, r0.w
abs r0.w, r1.y
add r2.w, -r0, c9.z
mad r2.z, r0.w, c10.x, c10.y
mad r2.z, r2, r0.w, c9.w
mul_pp r0.xy, r0, c13.z
rsq r2.w, r2.w
mul r0.z, r2.y, r2.y
mad r0.w, r2.z, r0, c10.z
rcp r2.w, r2.w
mul r2.z, r0.w, r2.w
cmp r0.w, r1.y, c9.y, c9.z
mul r1.y, r0.w, r2.z
mad r1.y, -r1, c10.w, r2.z
mad r2.w, r0.z, c11.z, c11
mad r2.z, r2.w, r0, c12.x
mad r0.w, r0, c11.x, r1.y
mad r1.y, r2.z, r0.z, c12
mul r2.z, r0.w, c5.x
mul r2.z, r2, c13.w
mad r1.y, r1, r0.z, c12.z
mad r1.y, r1, r0.z, c12.w
mul r2.y, r1, r2
add r1.y, r2.x, -r1.w
mul r1.w, v0.x, c6.x
mul r0.w, r0, c11.y
dsx r3.w, r2.z
dsy r3.y, r2.z
dsx r2.zw, r1.xyxz
mul r2.zw, r2, r2
add r0.z, r2, r2.w
mul r4.xy, r4, r4
add r2.z, r4.x, r4.y
rsq r0.z, r0.z
rcp r0.z, r0.z
rsq r2.z, r2.z
rcp r2.z, r2.z
mul r3.x, r2.z, c13.y
add r2.z, -r2.y, c13.x
mul r3.z, r0, c13.y
mul r0.xy, r0, c5.x
texldd r0.xyz, r0, s1, r3.zwzw, r3
cmp r1.y, -r1, r2, r2.z
add_pp r0.xyz, r0, c14.x
mul_sat r1.w, r1, c10
mad_pp r2.xyz, r1.w, -r0, r0
add r1.w, -r1.y, c11.x
cmp r1.y, r1.z, r1, r1.w
cmp r1.x, r1, r1.y, -r1.y
mov_pp r0.xyz, c3
mad_pp r0.xyz, r2, c13.z, r0
dsx r2.y, r0.w
dsy r1.w, r0
mov r1.y, r0.w
mov r2.x, r3.z
mov r1.z, r3.x
mad r1.x, r1, c13.y, c13.z
texldd r1.xyz, r1, s0, r2, r1.zwzw
add_pp r1.xyz, r1, -r0
mul_sat r1.w, c7.x, c7.x
mad_pp r3.xyz, r1.w, r1, r0
dp4_pp r0.w, c0, c0
rsq_pp r0.y, r0.w
dp3_pp r0.x, v1, v1
mul_pp r1.xyz, r0.y, c0
rsq_pp r0.x, r0.x
mad_pp r0.xyz, r0.x, v1, r1
dp3_pp r0.w, r0, r0
rsq_pp r2.w, r0.w
add r2.xyz, v2, -c8
dp3 r0.w, r2, r2
mul_pp r0.xyz, r2.w, r0
rsq r2.w, r0.w
mul r2.xyz, r2.w, r2
mov r0.w, c4.x
dp3_pp_sat r3.w, r0, r2
mul r2.w, c9.x, r0
pow r0, r3.w, r2.w
dp3_pp r0.w, r1, r2
mov r2.x, r0
mul_pp r4.xyz, r3, c1
mul_pp r1.xyz, r4, r0.w
mov_pp r0.xyz, c1
mul r2.x, r2, c3.w
mul_pp r0.xyz, c2, r0
mad r0.xyz, r0, r2.x, r1
mul_pp r1.xyz, r3, c10.w
dp3_pp r1.x, r1, r1
rsq_pp r1.z, r1.x
mul r0.xyz, r0, c14.y
dp3_pp r2.x, r0, r0
rsq_pp r2.x, r2.x
mov_pp r1.x, c3.w
mul_pp_sat r0.w, r0, c14.z
add_pp r1.x, c14.w, r1
mul_pp r1.x, r0.w, r1
rcp_pp r1.y, r2.x
rcp_pp r1.z, r1.z
add_pp_sat r0.w, r1.y, -r1.z
mad_pp r0.w, r0, -r1.x, r1.x
add_pp r0.w, r0, c9.z
add_pp r1.x, -r0.w, c9.z
mad_pp r0.w, r1, r1.x, r0
mov_pp oC0, r0
"
}

SubProgram "gles " {
Keywords { "DIRECTIONAL" "SHADOWS_OFF" }
"!!GLES"
}

SubProgram "glesdesktop " {
Keywords { "DIRECTIONAL" "SHADOWS_OFF" }
"!!GLES"
}

SubProgram "gles3 " {
Keywords { "DIRECTIONAL" "SHADOWS_OFF" }
"!!GLES3"
}

SubProgram "opengl " {
Keywords { "SPOT" "SHADOWS_OFF" }
"!!GLSL"
}

SubProgram "d3d9 " {
Keywords { "SPOT" "SHADOWS_OFF" }
Vector 0 [_WorldSpaceLightPos0]
Vector 1 [_LightColor0]
Vector 2 [_SpecColor]
Vector 3 [_SurfaceColor]
Float 4 [_Shininess]
Float 5 [_DetailScale]
Float 6 [_DetailDist]
Float 7 [_PlanetOpacity]
Vector 8 [_PlanetOrigin]
SetTexture 0 [_MainTex] 2D
SetTexture 1 [_DetailTex] 2D
SetTexture 2 [_LightTexture0] 2D
SetTexture 3 [_LightTextureB0] 2D
"ps_3_0
; 138 ALU, 8 TEX
dcl_2d s0
dcl_2d s1
dcl_2d s2
dcl_2d s3
def c9, 128.00000000, 0.00000000, 1.00000000, -0.21211439
def c10, -0.01872930, 0.07426100, 1.57072902, 2.00000000
def c11, 3.14159298, 0.31830987, -0.01348047, 0.05747731
def c12, -0.12123910, 0.19563590, -0.33299461, 0.99999559
def c13, 1.57079601, 0.15915494, 0.50000000, 1.27323949
def c14, -0.50000000, 4.00000000, 16.00000000, -1.00000000
dcl_texcoord0 v0.x
dcl_texcoord1 v1.xyz
dcl_texcoord2 v2.xyz
dcl_texcoord3 v3
dcl_texcoord5 v4.xyz
dp3 r0.x, v4, v4
rsq r0.x, r0.x
mul r1.xyz, r0.x, v4
abs r2.xyz, r1
add r0.w, r2.z, -r2.x
add r0.xyz, r2.zxyw, -r2
cmp r0.w, r0, c9.z, c9.y
mad r0.xyz, r0.w, r0, r2
add r0.w, -r2.y, r0.x
cmp r2.w, r0, c9.z, c9.y
abs r0.w, r1.z
add r0.xyz, -r2.yxzw, r0
mad r0.xyz, r2.w, r0, r2.yxzw
max r1.w, r2.x, r0
rcp r2.y, r1.w
min r1.w, r2.x, r0
mul r1.w, r1, r2.y
abs_pp r0.x, r0
rcp_pp r2.z, r0.x
mul r2.y, r1.w, r1.w
mul_pp r2.zw, r0.xyzy, r2.z
mad r0.x, r2.y, c11.z, c11.w
mad r0.x, r0, r2.y, c12
mul_pp r2.zw, r2, c13.z
mad r0.z, r0.x, r2.y, c12.y
mul r0.xy, r2.zwzw, c5.x
mad r2.z, r0, r2.y, c12
mad r2.w, r2.z, r2.y, c12
abs r0.z, r1.y
add r2.z, -r0, c9
mad r2.y, r0.z, c10.x, c10
mad r2.y, r2, r0.z, c9.w
rsq r2.z, r2.z
mul r1.w, r2, r1
mad r0.z, r2.y, r0, c10
rcp r2.z, r2.z
mul r2.y, r0.z, r2.z
cmp r0.z, r1.y, c9.y, c9
mul r1.y, r0.z, r2
mad r1.y, -r1, c10.w, r2
mad r1.y, r0.z, c11.x, r1
dsy r2.zw, r1.xyxz
mul r2.zw, r2, r2
add r2.y, -r1.w, c13.x
add r0.z, r2.x, -r0.w
cmp r0.z, -r0, r1.w, r2.y
mul r1.w, r1.y, c5.x
add r0.w, -r0.z, c11.x
cmp r3.x, r1.z, r0.z, r0.w
dsx r0.zw, r1.xyxz
mul r0.zw, r0, r0
add r0.z, r0, r0.w
add r0.w, r2.z, r2
cmp r1.x, r1, r3, -r3
mul r1.w, r1, c13
dsx r2.y, r1.w
rsq r0.z, r0.z
rcp r0.z, r0.z
rsq r0.w, r0.w
rcp r0.w, r0.w
mul r1.z, r0.w, c13.y
mul r0.w, r1.y, c11.y
mul r2.x, r0.z, c13.y
dsy r1.w, r1
texldd r0.xyz, r0, s1, r2, r1.zwzw
mov r1.y, r0.w
dsy r1.w, r0
mad r1.x, r1, c13.y, c13.z
dsx r2.y, r0.w
texldd r2.xyz, r1, s0, r2, r1.zwzw
add_pp r1.xyz, r0, c14.x
mul r0.y, v0.x, c6.x
mul_sat r0.y, r0, c10.w
mad_pp r3.xyz, r0.y, -r1, r1
dp4 r0.x, c0, c0
rsq r0.x, r0.x
mul r0.xyz, r0.x, c0
dp3_pp r0.w, r0, r0
rsq_pp r1.w, r0.w
mov_pp r1.xyz, c3
mad_pp r1.xyz, r3, c13.z, r1
add_pp r3.xyz, r2, -r1
mul_pp r2.xyz, r1.w, r0
dp3_pp r0.w, v1, v1
rsq_pp r0.x, r0.w
mad_pp r0.xyz, r0.x, v1, r2
mul_sat r1.w, c7.x, c7.x
mad_pp r1.xyz, r1.w, r3, r1
mul_pp r4.xyz, r1, c1
mul_pp r1.xyz, r1, c10.w
dp3_pp r1.y, r1, r1
dp3_pp r0.w, r0, r0
add r3.xyz, v2, -c8
rsq_pp r0.w, r0.w
rsq_pp r1.z, r1.y
dp3 r2.w, r3, r3
mul_pp r0.xyz, r0.w, r0
rsq r0.w, r2.w
mov r2.w, c4.x
mul r3.xyz, r0.w, r3
mul r3.w, c9.x, r2
dp3_pp_sat r2.w, r0, r3
pow r0, r2.w, r3.w
dp3_pp r2.w, r2, r3
mul r3.w, r0.x, c3
mul_pp r3.xyz, r4, r2.w
rcp r0.x, v3.w
mad r4.xy, v3, r0.x, c13.z
dp3 r0.x, v3, v3
mov_pp r2.xyz, c1
texld r0.w, r4, s2
cmp r0.y, -v3.z, c9, c9.z
mul_pp r0.y, r0, r0.w
texld r0.x, r0.x, s3
mul_pp r0.w, r0.y, r0.x
mul_pp r0.xyz, c2, r2
mul_pp r2.x, r0.w, c14.y
mad r0.xyz, r0, r3.w, r3
mul r0.xyz, r0, r2.x
dp3_pp r2.x, r0, r0
rsq_pp r1.x, r2.x
rcp_pp r1.y, r1.x
mov_pp r1.x, c3.w
mul_pp r0.w, r2, r0
mul_pp_sat r0.w, r0, c14.z
add_pp r1.x, c14.w, r1
mul_pp r1.x, r0.w, r1
rcp_pp r1.z, r1.z
add_pp_sat r0.w, r1.y, -r1.z
mad_pp r0.w, r0, -r1.x, r1.x
add_pp r0.w, r0, c9.z
add_pp r1.x, -r0.w, c9.z
mad_pp r0.w, r1, r1.x, r0
mov_pp oC0, r0
"
}

SubProgram "gles " {
Keywords { "SPOT" "SHADOWS_OFF" }
"!!GLES"
}

SubProgram "glesdesktop " {
Keywords { "SPOT" "SHADOWS_OFF" }
"!!GLES"
}

SubProgram "gles3 " {
Keywords { "SPOT" "SHADOWS_OFF" }
"!!GLES3"
}

SubProgram "opengl " {
Keywords { "POINT_COOKIE" "SHADOWS_OFF" }
"!!GLSL"
}

SubProgram "d3d9 " {
Keywords { "POINT_COOKIE" "SHADOWS_OFF" }
Vector 0 [_WorldSpaceLightPos0]
Vector 1 [_LightColor0]
Vector 2 [_SpecColor]
Vector 3 [_SurfaceColor]
Float 4 [_Shininess]
Float 5 [_DetailScale]
Float 6 [_DetailDist]
Float 7 [_PlanetOpacity]
Vector 8 [_PlanetOrigin]
SetTexture 0 [_MainTex] 2D
SetTexture 1 [_DetailTex] 2D
SetTexture 2 [_LightTextureB0] 2D
SetTexture 3 [_LightTexture0] CUBE
"ps_3_0
; 134 ALU, 8 TEX
dcl_2d s0
dcl_2d s1
dcl_2d s2
dcl_cube s3
def c9, 128.00000000, 0.00000000, 1.00000000, -0.21211439
def c10, -0.01872930, 0.07426100, 1.57072902, 2.00000000
def c11, 3.14159298, 0.31830987, -0.01348047, 0.05747731
def c12, -0.12123910, 0.19563590, -0.33299461, 0.99999559
def c13, 1.57079601, 0.15915494, 0.50000000, 1.27323949
def c14, -0.50000000, 4.00000000, 16.00000000, -1.00000000
dcl_texcoord0 v0.x
dcl_texcoord1 v1.xyz
dcl_texcoord2 v2.xyz
dcl_texcoord3 v3.xyz
dcl_texcoord5 v4.xyz
dp3 r0.x, v4, v4
rsq r0.x, r0.x
mul r1.xyz, r0.x, v4
abs r2.xyz, r1
add r0.w, r2.z, -r2.x
add r0.xyz, r2.zxyw, -r2
cmp r0.w, r0, c9.z, c9.y
mad r0.xyz, r0.w, r0, r2
add r0.w, -r2.y, r0.x
cmp r2.w, r0, c9.z, c9.y
abs r0.w, r1.z
add r0.xyz, -r2.yxzw, r0
mad r0.xyz, r2.w, r0, r2.yxzw
max r1.w, r2.x, r0
rcp r2.y, r1.w
min r1.w, r2.x, r0
mul r1.w, r1, r2.y
abs_pp r0.x, r0
rcp_pp r2.z, r0.x
mul r2.y, r1.w, r1.w
mul_pp r2.zw, r0.xyzy, r2.z
mad r0.x, r2.y, c11.z, c11.w
mad r0.x, r0, r2.y, c12
mul_pp r2.zw, r2, c13.z
mad r0.z, r0.x, r2.y, c12.y
mul r0.xy, r2.zwzw, c5.x
mad r2.z, r0, r2.y, c12
mad r2.w, r2.z, r2.y, c12
abs r0.z, r1.y
add r2.z, -r0, c9
mad r2.y, r0.z, c10.x, c10
mad r2.y, r2, r0.z, c9.w
rsq r2.z, r2.z
mul r1.w, r2, r1
mad r0.z, r2.y, r0, c10
rcp r2.z, r2.z
mul r2.y, r0.z, r2.z
cmp r0.z, r1.y, c9.y, c9
mul r1.y, r0.z, r2
mad r1.y, -r1, c10.w, r2
mad r1.y, r0.z, c11.x, r1
dsy r2.zw, r1.xyxz
mul r2.zw, r2, r2
add r2.y, -r1.w, c13.x
add r0.z, r2.x, -r0.w
cmp r0.z, -r0, r1.w, r2.y
mul r1.w, r1.y, c5.x
add r0.w, -r0.z, c11.x
cmp r3.x, r1.z, r0.z, r0.w
dsx r0.zw, r1.xyxz
mul r0.zw, r0, r0
add r0.z, r0, r0.w
add r0.w, r2.z, r2
cmp r1.x, r1, r3, -r3
mul r1.w, r1, c13
dsx r2.y, r1.w
rsq r0.z, r0.z
rcp r0.z, r0.z
rsq r0.w, r0.w
rcp r0.w, r0.w
mul r1.z, r0.w, c13.y
mul r0.w, r1.y, c11.y
mul r2.x, r0.z, c13.y
dsy r1.w, r1
texldd r0.xyz, r0, s1, r2, r1.zwzw
mov r1.y, r0.w
dsy r1.w, r0
mad r1.x, r1, c13.y, c13.z
dsx r2.y, r0.w
texldd r2.xyz, r1, s0, r2, r1.zwzw
add_pp r1.xyz, r0, c14.x
mul r0.y, v0.x, c6.x
mul_sat r0.y, r0, c10.w
mad_pp r3.xyz, r0.y, -r1, r1
dp4 r0.x, c0, c0
rsq r0.x, r0.x
mul r0.xyz, r0.x, c0
dp3_pp r0.w, r0, r0
rsq_pp r1.w, r0.w
mov_pp r1.xyz, c3
mad_pp r1.xyz, r3, c13.z, r1
add_pp r3.xyz, r2, -r1
mul_pp r2.xyz, r1.w, r0
dp3_pp r0.w, v1, v1
rsq_pp r0.x, r0.w
mad_pp r0.xyz, r0.x, v1, r2
mul_sat r1.w, c7.x, c7.x
mad_pp r1.xyz, r1.w, r3, r1
dp3_pp r0.w, r0, r0
add r3.xyz, v2, -c8
rsq_pp r0.w, r0.w
mul_pp r4.xyz, r1, c1
mul_pp r1.xyz, r1, c10.w
dp3_pp r1.y, r1, r1
rsq_pp r1.z, r1.y
dp3 r2.w, r3, r3
mul_pp r0.xyz, r0.w, r0
rsq r0.w, r2.w
mov r2.w, c4.x
mul r3.xyz, r0.w, r3
mul r3.w, c9.x, r2
dp3_pp_sat r2.w, r0, r3
pow r0, r2.w, r3.w
dp3_pp r2.w, r2, r3
mul r3.w, r0.x, c3
dp3 r0.x, v3, v3
mov_pp r2.xyz, c1
texld r0.x, r0.x, s2
texld r0.w, v3, s3
mul r0.w, r0.x, r0
mul_pp r0.xyz, c2, r2
mul_pp r2.x, r0.w, c14.y
mul_pp r3.xyz, r4, r2.w
mad r0.xyz, r0, r3.w, r3
mul r0.xyz, r0, r2.x
dp3_pp r2.x, r0, r0
rsq_pp r1.x, r2.x
rcp_pp r1.y, r1.x
mov_pp r1.x, c3.w
mul_pp r0.w, r2, r0
mul_pp_sat r0.w, r0, c14.z
add_pp r1.x, c14.w, r1
mul_pp r1.x, r0.w, r1
rcp_pp r1.z, r1.z
add_pp_sat r0.w, r1.y, -r1.z
mad_pp r0.w, r0, -r1.x, r1.x
add_pp r0.w, r0, c9.z
add_pp r1.x, -r0.w, c9.z
mad_pp r0.w, r1, r1.x, r0
mov_pp oC0, r0
"
}

SubProgram "gles " {
Keywords { "POINT_COOKIE" "SHADOWS_OFF" }
"!!GLES"
}

SubProgram "glesdesktop " {
Keywords { "POINT_COOKIE" "SHADOWS_OFF" }
"!!GLES"
}

SubProgram "gles3 " {
Keywords { "POINT_COOKIE" "SHADOWS_OFF" }
"!!GLES3"
}

SubProgram "opengl " {
Keywords { "DIRECTIONAL_COOKIE" "SHADOWS_OFF" }
"!!GLSL"
}

SubProgram "d3d9 " {
Keywords { "DIRECTIONAL_COOKIE" "SHADOWS_OFF" }
Vector 0 [_WorldSpaceLightPos0]
Vector 1 [_LightColor0]
Vector 2 [_SpecColor]
Vector 3 [_SurfaceColor]
Float 4 [_Shininess]
Float 5 [_DetailScale]
Float 6 [_DetailDist]
Float 7 [_PlanetOpacity]
Vector 8 [_PlanetOrigin]
SetTexture 0 [_MainTex] 2D
SetTexture 1 [_DetailTex] 2D
SetTexture 2 [_LightTexture0] 2D
"ps_3_0
; 129 ALU, 7 TEX
dcl_2d s0
dcl_2d s1
dcl_2d s2
def c9, 128.00000000, 0.00000000, 1.00000000, -0.21211439
def c10, -0.01872930, 0.07426100, 1.57072902, 2.00000000
def c11, 3.14159298, 0.31830987, -0.01348047, 0.05747731
def c12, -0.12123910, 0.19563590, -0.33299461, 0.99999559
def c13, 1.57079601, 0.15915494, 0.50000000, 1.27323949
def c14, -0.50000000, 4.00000000, 16.00000000, -1.00000000
dcl_texcoord0 v0.x
dcl_texcoord1 v1.xyz
dcl_texcoord2 v2.xyz
dcl_texcoord3 v3.xy
dcl_texcoord5 v4.xyz
dp3 r0.x, v4, v4
rsq r0.x, r0.x
mul r0.xyz, r0.x, v4
abs r2.xyz, r0
add r0.w, r2.z, -r2.x
add r1.xyz, r2.zxyw, -r2
cmp r0.w, r0, c9.z, c9.y
mad r1.xyz, r0.w, r1, r2
add r0.w, -r2.y, r1.x
cmp r2.w, r0, c9.z, c9.y
abs r0.w, r0.z
add r1.xyz, -r2.yxzw, r1
mad r1.xyz, r2.w, r1, r2.yxzw
max r1.w, r2.x, r0
rcp r2.y, r1.w
min r1.w, r2.x, r0
mul r1.w, r1, r2.y
abs_pp r1.x, r1
rcp_pp r2.z, r1.x
mul r2.y, r1.w, r1.w
mul_pp r2.zw, r1.xyzy, r2.z
mad r1.x, r2.y, c11.z, c11.w
mad r1.x, r1, r2.y, c12
mul_pp r2.zw, r2, c13.z
mad r1.z, r1.x, r2.y, c12.y
mul r1.xy, r2.zwzw, c5.x
mad r2.z, r1, r2.y, c12
abs r1.z, r0.y
mad r2.w, r2.z, r2.y, c12
add r2.z, -r1, c9
mad r2.y, r1.z, c10.x, c10
mad r2.y, r2, r1.z, c9.w
rsq r2.z, r2.z
mul r1.w, r2, r1
rcp r2.z, r2.z
mad r1.z, r2.y, r1, c10
mul r1.z, r1, r2
dsy r2.zw, r0.xyxz
cmp r0.y, r0, c9, c9.z
mul r2.y, r0, r1.z
mad r1.z, -r2.y, c10.w, r1
mul r2.zw, r2, r2
mad r0.y, r0, c11.x, r1.z
add r2.y, -r1.w, c13.x
add r0.w, r2.x, -r0
cmp r0.w, -r0, r1, r2.y
add r1.z, -r0.w, c11.x
mul r1.w, r0.y, c5.x
mul r1.w, r1, c13
cmp r3.x, r0.z, r0.w, r1.z
dsx r2.y, r1.w
dsy r0.w, r1
dsx r1.zw, r0.xyxz
mul r1.zw, r1, r1
add r0.z, r1, r1.w
add r1.z, r2, r2.w
cmp r0.x, r0, r3, -r3
rsq r0.z, r0.z
rcp r0.z, r0.z
rsq r1.z, r1.z
mul r2.x, r0.z, c13.y
rcp r1.z, r1.z
mul r0.z, r1, c13.y
texldd r1.xyz, r1, s1, r2, r0.zwzw
mul r0.w, r0.y, c11.y
dsx r2.y, r0.w
mov r0.y, r0.w
dsy r0.w, r0
mad r0.x, r0, c13.y, c13.z
texldd r0.xyz, r0, s0, r2, r0.zwzw
add_pp r2.xyz, r1, c14.x
mul r0.w, v0.x, c6.x
mul_sat r0.w, r0, c10
mad_pp r2.xyz, r0.w, -r2, r2
mov_pp r1.xyz, c3
mad_pp r2.xyz, r2, c13.z, r1
add_pp r3.xyz, r0, -r2
dp4_pp r0.w, c0, c0
rsq_pp r0.y, r0.w
mul_sat r1.w, c7.x, c7.x
mad_pp r3.xyz, r1.w, r3, r2
add r2.xyz, v2, -c8
dp3_pp r0.x, v1, v1
mul_pp r1.xyz, r0.y, c0
rsq_pp r0.x, r0.x
mad_pp r0.xyz, r0.x, v1, r1
dp3_pp r0.w, r0, r0
rsq_pp r0.w, r0.w
dp3 r2.w, r2, r2
mul_pp r0.xyz, r0.w, r0
rsq r0.w, r2.w
mov r2.w, c4.x
mul r2.xyz, r0.w, r2
mul r3.w, c9.x, r2
dp3_pp_sat r2.w, r0, r2
pow r0, r2.w, r3.w
dp3_pp r0.w, r1, r2
mul r2.x, r0, c3.w
texld r2.w, v3, s2
mul_pp r4.xyz, r3, c1
mul_pp r1.xyz, r4, r0.w
mov_pp r0.xyz, c1
mul_pp r0.xyz, c2, r0
mad r0.xyz, r0, r2.x, r1
mul_pp r1.xyz, r3, c10.w
dp3_pp r1.y, r1, r1
rsq_pp r1.z, r1.y
mul_pp r2.y, r2.w, c14
mul r0.xyz, r0, r2.y
dp3_pp r2.x, r0, r0
rsq_pp r1.x, r2.x
rcp_pp r1.y, r1.x
mov_pp r1.x, c3.w
mul_pp r0.w, r0, r2
mul_pp_sat r0.w, r0, c14.z
add_pp r1.x, c14.w, r1
mul_pp r1.x, r0.w, r1
rcp_pp r1.z, r1.z
add_pp_sat r0.w, r1.y, -r1.z
mad_pp r0.w, r0, -r1.x, r1.x
add_pp r0.w, r0, c9.z
add_pp r1.x, -r0.w, c9.z
mad_pp r0.w, r1, r1.x, r0
mov_pp oC0, r0
"
}

SubProgram "gles " {
Keywords { "DIRECTIONAL_COOKIE" "SHADOWS_OFF" }
"!!GLES"
}

SubProgram "glesdesktop " {
Keywords { "DIRECTIONAL_COOKIE" "SHADOWS_OFF" }
"!!GLES"
}

SubProgram "gles3 " {
Keywords { "DIRECTIONAL_COOKIE" "SHADOWS_OFF" }
"!!GLES3"
}

SubProgram "opengl " {
Keywords { "SPOT" "SHADOWS_DEPTH" }
"!!GLSL"
}

SubProgram "d3d9 " {
Keywords { "SPOT" "SHADOWS_DEPTH" }
Vector 0 [_WorldSpaceLightPos0]
Vector 1 [_LightShadowData]
Vector 2 [_LightColor0]
Vector 3 [_SpecColor]
Vector 4 [_SurfaceColor]
Float 5 [_Shininess]
Float 6 [_DetailScale]
Float 7 [_DetailDist]
Float 8 [_PlanetOpacity]
Vector 9 [_PlanetOrigin]
SetTexture 0 [_MainTex] 2D
SetTexture 1 [_DetailTex] 2D
SetTexture 2 [_LightTexture0] 2D
SetTexture 3 [_LightTextureB0] 2D
SetTexture 4 [_ShadowMapTexture] 2D
"ps_3_0
; 143 ALU, 9 TEX
dcl_2d s0
dcl_2d s1
dcl_2d s2
dcl_2d s3
dcl_2d s4
def c10, 128.00000000, 0.00000000, 1.00000000, -0.21211439
def c11, -0.01872930, 0.07426100, 1.57072902, 2.00000000
def c12, 3.14159298, 0.31830987, -0.01348047, 0.05747731
def c13, -0.12123910, 0.19563590, -0.33299461, 0.99999559
def c14, 1.57079601, 0.15915494, 0.50000000, 1.27323949
def c15, -0.50000000, 4.00000000, 16.00000000, -1.00000000
dcl_texcoord0 v0.x
dcl_texcoord1 v1.xyz
dcl_texcoord2 v2.xyz
dcl_texcoord3 v3
dcl_texcoord4 v4
dcl_texcoord5 v5.xyz
dp3 r0.x, v5, v5
rsq r0.x, r0.x
mul r1.xyz, r0.x, v5
abs r2.xyz, r1
add r0.w, r2.z, -r2.x
add r0.xyz, r2.zxyw, -r2
cmp r0.w, r0, c10.z, c10.y
mad r0.xyz, r0.w, r0, r2
add r0.w, -r2.y, r0.x
cmp r2.w, r0, c10.z, c10.y
abs r0.w, r1.z
add r0.xyz, -r2.yxzw, r0
mad r0.xyz, r2.w, r0, r2.yxzw
max r1.w, r2.x, r0
rcp r2.y, r1.w
min r1.w, r2.x, r0
mul r1.w, r1, r2.y
abs_pp r0.x, r0
rcp_pp r2.z, r0.x
mul r2.y, r1.w, r1.w
mul_pp r2.zw, r0.xyzy, r2.z
mad r0.x, r2.y, c12.z, c12.w
mad r0.x, r0, r2.y, c13
mul_pp r2.zw, r2, c14.z
mad r0.z, r0.x, r2.y, c13.y
mul r0.xy, r2.zwzw, c6.x
mad r2.z, r0, r2.y, c13
mad r2.w, r2.z, r2.y, c13
abs r0.z, r1.y
add r2.z, -r0, c10
mad r2.y, r0.z, c11.x, c11
mad r2.y, r2, r0.z, c10.w
rsq r2.z, r2.z
mul r1.w, r2, r1
mad r0.z, r2.y, r0, c11
rcp r2.z, r2.z
mul r2.y, r0.z, r2.z
cmp r0.z, r1.y, c10.y, c10
mul r1.y, r0.z, r2
mad r1.y, -r1, c11.w, r2
mad r1.y, r0.z, c12.x, r1
dsy r2.zw, r1.xyxz
mul r2.zw, r2, r2
add r2.y, -r1.w, c14.x
add r0.z, r2.x, -r0.w
cmp r0.z, -r0, r1.w, r2.y
mul r1.w, r1.y, c6.x
add r0.w, -r0.z, c12.x
cmp r3.x, r1.z, r0.z, r0.w
dsx r0.zw, r1.xyxz
mul r0.zw, r0, r0
add r0.z, r0, r0.w
add r0.w, r2.z, r2
cmp r1.x, r1, r3, -r3
mul r1.w, r1, c14
dsx r2.y, r1.w
rsq r0.z, r0.z
rcp r0.z, r0.z
rsq r0.w, r0.w
rcp r0.w, r0.w
mul r1.z, r0.w, c14.y
mul r0.w, r1.y, c12.y
mul r2.x, r0.z, c14.y
dsy r1.w, r1
texldd r0.xyz, r0, s1, r2, r1.zwzw
mov r1.y, r0.w
dsy r1.w, r0
mad r1.x, r1, c14.y, c14.z
dsx r2.y, r0.w
texldd r2.xyz, r1, s0, r2, r1.zwzw
add_pp r1.xyz, r0, c15.x
mul r0.y, v0.x, c7.x
mul_sat r0.y, r0, c11.w
mad_pp r3.xyz, r0.y, -r1, r1
dp4 r0.x, c0, c0
rsq r0.x, r0.x
mul r0.xyz, r0.x, c0
dp3_pp r0.w, r0, r0
rsq_pp r1.w, r0.w
mov_pp r1.xyz, c4
mad_pp r1.xyz, r3, c14.z, r1
add_pp r3.xyz, r2, -r1
mul_pp r2.xyz, r1.w, r0
dp3_pp r0.w, v1, v1
rsq_pp r0.x, r0.w
mad_pp r0.xyz, r0.x, v1, r2
mul_sat r1.w, c8.x, c8.x
mad_pp r1.xyz, r1.w, r3, r1
dp3_pp r0.w, r0, r0
add r3.xyz, v2, -c9
rsq_pp r0.w, r0.w
mul_pp r4.xyz, r1, c2
mul_pp r1.xyz, r1, c11.w
dp3_pp r1.y, r1, r1
rsq_pp r1.z, r1.y
dp3 r2.w, r3, r3
mul_pp r0.xyz, r0.w, r0
rsq r0.w, r2.w
mov r2.w, c5.x
mul r3.xyz, r0.w, r3
mul r3.w, c10.x, r2
dp3_pp_sat r2.w, r0, r3
pow r0, r2.w, r3.w
dp3_pp r2.w, r2, r3
mul r3.z, r0.x, c4.w
mul_pp r2.xyz, r4, r2.w
texldp r0.x, v4, s4
rcp r0.y, v4.w
mad r0.y, -v4.z, r0, r0.x
rcp r0.x, v3.w
mad r3.xy, v3, r0.x, c14.z
mov r0.z, c1.x
cmp r0.z, r0.y, c10, r0
dp3 r0.x, v3, v3
texld r0.w, r3, s2
cmp r0.y, -v3.z, c10, c10.z
mul_pp r0.y, r0, r0.w
texld r0.x, r0.x, s3
mul_pp r0.x, r0.y, r0
mul_pp r0.w, r0.x, r0.z
mul_pp r3.x, r0.w, c15.y
mov_pp r0.xyz, c2
mul_pp r0.xyz, c3, r0
mad r0.xyz, r0, r3.z, r2
mul r0.xyz, r0, r3.x
dp3_pp r2.x, r0, r0
rsq_pp r1.x, r2.x
rcp_pp r1.y, r1.x
mov_pp r1.x, c4.w
mul_pp r0.w, r2, r0
mul_pp_sat r0.w, r0, c15.z
add_pp r1.x, c15.w, r1
mul_pp r1.x, r0.w, r1
rcp_pp r1.z, r1.z
add_pp_sat r0.w, r1.y, -r1.z
mad_pp r0.w, r0, -r1.x, r1.x
add_pp r0.w, r0, c10.z
add_pp r1.x, -r0.w, c10.z
mad_pp r0.w, r1, r1.x, r0
mov_pp oC0, r0
"
}

SubProgram "gles " {
Keywords { "SPOT" "SHADOWS_DEPTH" }
"!!GLES"
}

SubProgram "glesdesktop " {
Keywords { "SPOT" "SHADOWS_DEPTH" }
"!!GLES"
}

SubProgram "gles3 " {
Keywords { "SPOT" "SHADOWS_DEPTH" }
"!!GLES3"
}

SubProgram "opengl " {
Keywords { "SPOT" "SHADOWS_DEPTH" "SHADOWS_NATIVE" }
"!!GLSL"
}

SubProgram "d3d9 " {
Keywords { "SPOT" "SHADOWS_DEPTH" "SHADOWS_NATIVE" }
Vector 0 [_WorldSpaceLightPos0]
Vector 1 [_LightShadowData]
Vector 2 [_LightColor0]
Vector 3 [_SpecColor]
Vector 4 [_SurfaceColor]
Float 5 [_Shininess]
Float 6 [_DetailScale]
Float 7 [_DetailDist]
Float 8 [_PlanetOpacity]
Vector 9 [_PlanetOrigin]
SetTexture 0 [_MainTex] 2D
SetTexture 1 [_DetailTex] 2D
SetTexture 2 [_LightTexture0] 2D
SetTexture 3 [_LightTextureB0] 2D
SetTexture 4 [_ShadowMapTexture] 2D
"ps_3_0
; 142 ALU, 9 TEX
dcl_2d s0
dcl_2d s1
dcl_2d s2
dcl_2d s3
dcl_2d s4
def c10, 128.00000000, 0.00000000, 1.00000000, -0.21211439
def c11, -0.01872930, 0.07426100, 1.57072902, 2.00000000
def c12, 3.14159298, 0.31830987, -0.01348047, 0.05747731
def c13, -0.12123910, 0.19563590, -0.33299461, 0.99999559
def c14, 1.57079601, 0.15915494, 0.50000000, 1.27323949
def c15, -0.50000000, 4.00000000, 16.00000000, -1.00000000
dcl_texcoord0 v0.x
dcl_texcoord1 v1.xyz
dcl_texcoord2 v2.xyz
dcl_texcoord3 v3
dcl_texcoord4 v4
dcl_texcoord5 v5.xyz
dp3 r0.x, v5, v5
rsq r0.x, r0.x
mul r1.xyz, r0.x, v5
abs r2.xyz, r1
add r0.w, r2.z, -r2.x
add r0.xyz, r2.zxyw, -r2
cmp r0.w, r0, c10.z, c10.y
mad r0.xyz, r0.w, r0, r2
add r0.w, -r2.y, r0.x
cmp r2.w, r0, c10.z, c10.y
abs r0.w, r1.z
add r0.xyz, -r2.yxzw, r0
mad r0.xyz, r2.w, r0, r2.yxzw
max r1.w, r2.x, r0
rcp r2.y, r1.w
min r1.w, r2.x, r0
mul r1.w, r1, r2.y
abs_pp r0.x, r0
rcp_pp r2.z, r0.x
mul r2.y, r1.w, r1.w
mul_pp r2.zw, r0.xyzy, r2.z
mad r0.x, r2.y, c12.z, c12.w
mad r0.x, r0, r2.y, c13
mul_pp r2.zw, r2, c14.z
mad r0.z, r0.x, r2.y, c13.y
mul r0.xy, r2.zwzw, c6.x
mad r2.z, r0, r2.y, c13
mad r2.w, r2.z, r2.y, c13
abs r0.z, r1.y
add r2.z, -r0, c10
mad r2.y, r0.z, c11.x, c11
mad r2.y, r2, r0.z, c10.w
rsq r2.z, r2.z
mul r1.w, r2, r1
mad r0.z, r2.y, r0, c11
rcp r2.z, r2.z
mul r2.y, r0.z, r2.z
cmp r0.z, r1.y, c10.y, c10
mul r1.y, r0.z, r2
mad r1.y, -r1, c11.w, r2
mad r1.y, r0.z, c12.x, r1
dsy r2.zw, r1.xyxz
mul r2.zw, r2, r2
add r2.y, -r1.w, c14.x
add r0.z, r2.x, -r0.w
cmp r0.z, -r0, r1.w, r2.y
mul r1.w, r1.y, c6.x
add r0.w, -r0.z, c12.x
cmp r3.x, r1.z, r0.z, r0.w
dsx r0.zw, r1.xyxz
mul r0.zw, r0, r0
add r0.z, r0, r0.w
add r0.w, r2.z, r2
cmp r1.x, r1, r3, -r3
mul r1.w, r1, c14
dsx r2.y, r1.w
rsq r0.z, r0.z
rcp r0.z, r0.z
rsq r0.w, r0.w
rcp r0.w, r0.w
mul r1.z, r0.w, c14.y
mul r0.w, r1.y, c12.y
mul r2.x, r0.z, c14.y
dsy r1.w, r1
texldd r0.xyz, r0, s1, r2, r1.zwzw
mov r1.y, r0.w
dsy r1.w, r0
mad r1.x, r1, c14.y, c14.z
dsx r2.y, r0.w
texldd r2.xyz, r1, s0, r2, r1.zwzw
add_pp r1.xyz, r0, c15.x
mul r0.y, v0.x, c7.x
mul_sat r0.y, r0, c11.w
mad_pp r3.xyz, r0.y, -r1, r1
dp4 r0.x, c0, c0
rsq r0.x, r0.x
mul r0.xyz, r0.x, c0
dp3_pp r0.w, r0, r0
rsq_pp r1.w, r0.w
mov_pp r1.xyz, c4
mad_pp r1.xyz, r3, c14.z, r1
add_pp r3.xyz, r2, -r1
mul_pp r2.xyz, r1.w, r0
dp3_pp r0.w, v1, v1
rsq_pp r0.x, r0.w
mad_pp r0.xyz, r0.x, v1, r2
mul_sat r1.w, c8.x, c8.x
mad_pp r1.xyz, r1.w, r3, r1
dp3_pp r0.w, r0, r0
add r3.xyz, v2, -c9
rsq_pp r0.w, r0.w
mul_pp r4.xyz, r1, c2
mul_pp r1.xyz, r1, c11.w
dp3_pp r1.y, r1, r1
rsq_pp r1.z, r1.y
dp3 r2.w, r3, r3
mul_pp r0.xyz, r0.w, r0
rsq r0.w, r2.w
mov r2.w, c5.x
mul r3.xyz, r0.w, r3
mul r3.w, c10.x, r2
dp3_pp_sat r2.w, r0, r3
pow r0, r2.w, r3.w
dp3_pp r2.w, r2, r3
mul r3.z, r0.x, c4.w
mov r0.x, c1
rcp r0.y, v3.w
mad r3.xy, v3, r0.y, c14.z
add r0.z, c10, -r0.x
texldp r0.x, v4, s4
mad r0.z, r0.x, r0, c1.x
dp3 r0.x, v3, v3
texld r0.w, r3, s2
cmp r0.y, -v3.z, c10, c10.z
mul_pp r0.y, r0, r0.w
texld r0.x, r0.x, s3
mul_pp r0.x, r0.y, r0
mul_pp r0.w, r0.x, r0.z
mul_pp r3.x, r0.w, c15.y
mov_pp r0.xyz, c2
mul_pp r0.w, r2, r0
mul_pp r2.xyz, r4, r2.w
mul_pp r0.xyz, c3, r0
mad r0.xyz, r0, r3.z, r2
mul r0.xyz, r0, r3.x
dp3_pp r2.x, r0, r0
rsq_pp r1.x, r2.x
rcp_pp r1.y, r1.x
mov_pp r1.x, c4.w
mul_pp_sat r0.w, r0, c15.z
add_pp r1.x, c15.w, r1
mul_pp r1.x, r0.w, r1
rcp_pp r1.z, r1.z
add_pp_sat r0.w, r1.y, -r1.z
mad_pp r0.w, r0, -r1.x, r1.x
add_pp r0.w, r0, c10.z
add_pp r1.x, -r0.w, c10.z
mad_pp r0.w, r1, r1.x, r0
mov_pp oC0, r0
"
}

SubProgram "gles " {
Keywords { "SPOT" "SHADOWS_DEPTH" "SHADOWS_NATIVE" }
"!!GLES"
}

SubProgram "gles3 " {
Keywords { "SPOT" "SHADOWS_DEPTH" "SHADOWS_NATIVE" }
"!!GLES3"
}

SubProgram "opengl " {
Keywords { "DIRECTIONAL" "SHADOWS_SCREEN" }
"!!GLSL"
}

SubProgram "d3d9 " {
Keywords { "DIRECTIONAL" "SHADOWS_SCREEN" }
Vector 0 [_WorldSpaceLightPos0]
Vector 1 [_LightColor0]
Vector 2 [_SpecColor]
Vector 3 [_SurfaceColor]
Float 4 [_Shininess]
Float 5 [_DetailScale]
Float 6 [_DetailDist]
Float 7 [_PlanetOpacity]
Vector 8 [_PlanetOrigin]
SetTexture 0 [_MainTex] 2D
SetTexture 1 [_DetailTex] 2D
SetTexture 2 [_ShadowMapTexture] 2D
"ps_3_0
; 129 ALU, 7 TEX
dcl_2d s0
dcl_2d s1
dcl_2d s2
def c9, 128.00000000, 0.00000000, 1.00000000, -0.21211439
def c10, -0.01872930, 0.07426100, 1.57072902, 2.00000000
def c11, 3.14159298, 0.31830987, -0.01348047, 0.05747731
def c12, -0.12123910, 0.19563590, -0.33299461, 0.99999559
def c13, 1.57079601, 0.15915494, 0.50000000, 1.27323949
def c14, -0.50000000, 4.00000000, 16.00000000, -1.00000000
dcl_texcoord0 v0.x
dcl_texcoord1 v1.xyz
dcl_texcoord2 v2.xyz
dcl_texcoord3 v3
dcl_texcoord5 v4.xyz
dp3 r0.x, v4, v4
rsq r0.x, r0.x
mul r0.xyz, r0.x, v4
abs r2.xyz, r0
add r0.w, r2.z, -r2.x
add r1.xyz, r2.zxyw, -r2
cmp r0.w, r0, c9.z, c9.y
mad r1.xyz, r0.w, r1, r2
add r0.w, -r2.y, r1.x
cmp r2.w, r0, c9.z, c9.y
abs r0.w, r0.z
add r1.xyz, -r2.yxzw, r1
mad r1.xyz, r2.w, r1, r2.yxzw
max r1.w, r2.x, r0
rcp r2.y, r1.w
min r1.w, r2.x, r0
mul r1.w, r1, r2.y
abs_pp r1.x, r1
rcp_pp r2.z, r1.x
mul r2.y, r1.w, r1.w
mul_pp r2.zw, r1.xyzy, r2.z
mad r1.x, r2.y, c11.z, c11.w
mad r1.x, r1, r2.y, c12
mul_pp r2.zw, r2, c13.z
mad r1.z, r1.x, r2.y, c12.y
mul r1.xy, r2.zwzw, c5.x
mad r2.z, r1, r2.y, c12
abs r1.z, r0.y
mad r2.w, r2.z, r2.y, c12
add r2.z, -r1, c9
mad r2.y, r1.z, c10.x, c10
mad r2.y, r2, r1.z, c9.w
rsq r2.z, r2.z
mul r1.w, r2, r1
rcp r2.z, r2.z
mad r1.z, r2.y, r1, c10
mul r1.z, r1, r2
dsy r2.zw, r0.xyxz
cmp r0.y, r0, c9, c9.z
mul r2.y, r0, r1.z
mad r1.z, -r2.y, c10.w, r1
mul r2.zw, r2, r2
mad r0.y, r0, c11.x, r1.z
add r2.y, -r1.w, c13.x
add r0.w, r2.x, -r0
cmp r0.w, -r0, r1, r2.y
add r1.z, -r0.w, c11.x
mul r1.w, r0.y, c5.x
mul r1.w, r1, c13
cmp r3.x, r0.z, r0.w, r1.z
dsx r2.y, r1.w
dsy r0.w, r1
dsx r1.zw, r0.xyxz
mul r1.zw, r1, r1
add r0.z, r1, r1.w
add r1.z, r2, r2.w
cmp r0.x, r0, r3, -r3
rsq r0.z, r0.z
rcp r0.z, r0.z
rsq r1.z, r1.z
mul r2.x, r0.z, c13.y
rcp r1.z, r1.z
mul r0.z, r1, c13.y
texldd r1.xyz, r1, s1, r2, r0.zwzw
mul r0.w, r0.y, c11.y
dsx r2.y, r0.w
mov r0.y, r0.w
dsy r0.w, r0
mad r0.x, r0, c13.y, c13.z
texldd r0.xyz, r0, s0, r2, r0.zwzw
add_pp r2.xyz, r1, c14.x
mul r0.w, v0.x, c6.x
mul_sat r0.w, r0, c10
mad_pp r2.xyz, r0.w, -r2, r2
mov_pp r1.xyz, c3
mad_pp r2.xyz, r2, c13.z, r1
add_pp r3.xyz, r0, -r2
dp4_pp r0.w, c0, c0
rsq_pp r0.y, r0.w
mul_sat r1.w, c7.x, c7.x
mad_pp r3.xyz, r1.w, r3, r2
add r2.xyz, v2, -c8
dp3_pp r0.x, v1, v1
mul_pp r1.xyz, r0.y, c0
rsq_pp r0.x, r0.x
mad_pp r0.xyz, r0.x, v1, r1
dp3_pp r0.w, r0, r0
rsq_pp r0.w, r0.w
dp3 r2.w, r2, r2
mul_pp r0.xyz, r0.w, r0
rsq r0.w, r2.w
mov r2.w, c4.x
mul r2.xyz, r0.w, r2
mul r3.w, c9.x, r2
dp3_pp_sat r2.w, r0, r2
pow r0, r2.w, r3.w
dp3_pp r0.w, r1, r2
mul r2.y, r0.x, c3.w
texldp r2.x, v3, s2
mul_pp r4.xyz, r3, c1
mul_pp r1.xyz, r4, r0.w
mov_pp r0.xyz, c1
mul_pp r0.xyz, c2, r0
mad r0.xyz, r0, r2.y, r1
mul_pp r1.xyz, r3, c10.w
dp3_pp r1.y, r1, r1
rsq_pp r1.z, r1.y
mul_pp r2.z, r2.x, c14.y
mul r0.xyz, r0, r2.z
dp3_pp r2.y, r0, r0
rsq_pp r1.x, r2.y
rcp_pp r1.y, r1.x
mov_pp r1.x, c3.w
mul_pp r0.w, r0, r2.x
mul_pp_sat r0.w, r0, c14.z
add_pp r1.x, c14.w, r1
mul_pp r1.x, r0.w, r1
rcp_pp r1.z, r1.z
add_pp_sat r0.w, r1.y, -r1.z
mad_pp r0.w, r0, -r1.x, r1.x
add_pp r0.w, r0, c9.z
add_pp r1.x, -r0.w, c9.z
mad_pp r0.w, r1, r1.x, r0
mov_pp oC0, r0
"
}

SubProgram "gles " {
Keywords { "DIRECTIONAL" "SHADOWS_SCREEN" }
"!!GLES"
}

SubProgram "glesdesktop " {
Keywords { "DIRECTIONAL" "SHADOWS_SCREEN" }
"!!GLES"
}

SubProgram "gles3 " {
Keywords { "DIRECTIONAL" "SHADOWS_SCREEN" }
"!!GLES3"
}

SubProgram "opengl " {
Keywords { "DIRECTIONAL_COOKIE" "SHADOWS_SCREEN" }
"!!GLSL"
}

SubProgram "d3d9 " {
Keywords { "DIRECTIONAL_COOKIE" "SHADOWS_SCREEN" }
Vector 0 [_WorldSpaceLightPos0]
Vector 1 [_LightColor0]
Vector 2 [_SpecColor]
Vector 3 [_SurfaceColor]
Float 4 [_Shininess]
Float 5 [_DetailScale]
Float 6 [_DetailDist]
Float 7 [_PlanetOpacity]
Vector 8 [_PlanetOrigin]
SetTexture 0 [_MainTex] 2D
SetTexture 1 [_DetailTex] 2D
SetTexture 2 [_ShadowMapTexture] 2D
SetTexture 3 [_LightTexture0] 2D
"ps_3_0
; 130 ALU, 8 TEX
dcl_2d s0
dcl_2d s1
dcl_2d s2
dcl_2d s3
def c9, 128.00000000, 0.00000000, 1.00000000, -0.21211439
def c10, -0.01872930, 0.07426100, 1.57072902, 2.00000000
def c11, 3.14159298, 0.31830987, -0.01348047, 0.05747731
def c12, -0.12123910, 0.19563590, -0.33299461, 0.99999559
def c13, 1.57079601, 0.15915494, 0.50000000, 1.27323949
def c14, -0.50000000, 4.00000000, 16.00000000, -1.00000000
dcl_texcoord0 v0.x
dcl_texcoord1 v1.xyz
dcl_texcoord2 v2.xyz
dcl_texcoord3 v3.xy
dcl_texcoord4 v4
dcl_texcoord5 v5.xyz
dp3 r0.x, v5, v5
rsq r0.x, r0.x
mul r0.xyz, r0.x, v5
abs r2.xyz, r0
add r0.w, r2.z, -r2.x
add r1.xyz, r2.zxyw, -r2
cmp r0.w, r0, c9.z, c9.y
mad r1.xyz, r0.w, r1, r2
add r0.w, -r2.y, r1.x
cmp r2.w, r0, c9.z, c9.y
abs r0.w, r0.z
add r1.xyz, -r2.yxzw, r1
mad r1.xyz, r2.w, r1, r2.yxzw
max r1.w, r2.x, r0
rcp r2.y, r1.w
min r1.w, r2.x, r0
mul r1.w, r1, r2.y
abs_pp r1.x, r1
rcp_pp r2.z, r1.x
mul r2.y, r1.w, r1.w
mul_pp r2.zw, r1.xyzy, r2.z
mad r1.x, r2.y, c11.z, c11.w
mad r1.x, r1, r2.y, c12
mul_pp r2.zw, r2, c13.z
mad r1.z, r1.x, r2.y, c12.y
mul r1.xy, r2.zwzw, c5.x
mad r2.z, r1, r2.y, c12
abs r1.z, r0.y
mad r2.w, r2.z, r2.y, c12
add r2.z, -r1, c9
mad r2.y, r1.z, c10.x, c10
mad r2.y, r2, r1.z, c9.w
rsq r2.z, r2.z
mul r1.w, r2, r1
rcp r2.z, r2.z
mad r1.z, r2.y, r1, c10
mul r1.z, r1, r2
dsy r2.zw, r0.xyxz
cmp r0.y, r0, c9, c9.z
mul r2.y, r0, r1.z
mad r1.z, -r2.y, c10.w, r1
mul r2.zw, r2, r2
mad r0.y, r0, c11.x, r1.z
add r2.y, -r1.w, c13.x
add r0.w, r2.x, -r0
cmp r0.w, -r0, r1, r2.y
add r1.z, -r0.w, c11.x
mul r1.w, r0.y, c5.x
mul r1.w, r1, c13
cmp r3.x, r0.z, r0.w, r1.z
dsx r2.y, r1.w
dsy r0.w, r1
dsx r1.zw, r0.xyxz
mul r1.zw, r1, r1
add r0.z, r1, r1.w
add r1.z, r2, r2.w
cmp r0.x, r0, r3, -r3
rsq r0.z, r0.z
rcp r0.z, r0.z
rsq r1.z, r1.z
mul r2.x, r0.z, c13.y
rcp r1.z, r1.z
mul r0.z, r1, c13.y
texldd r1.xyz, r1, s1, r2, r0.zwzw
mul r0.w, r0.y, c11.y
dsx r2.y, r0.w
mov r0.y, r0.w
dsy r0.w, r0
mad r0.x, r0, c13.y, c13.z
texldd r0.xyz, r0, s0, r2, r0.zwzw
add_pp r2.xyz, r1, c14.x
mul r0.w, v0.x, c6.x
mul_sat r0.w, r0, c10
mad_pp r2.xyz, r0.w, -r2, r2
mov_pp r1.xyz, c3
mad_pp r1.xyz, r2, c13.z, r1
add_pp r3.xyz, r0, -r1
dp4_pp r0.w, c0, c0
rsq_pp r0.y, r0.w
mul_sat r1.w, c7.x, c7.x
mad_pp r1.xyz, r1.w, r3, r1
add r3.xyz, v2, -c8
mul_pp r4.xyz, r1, c1
mul_pp r1.xyz, r1, c10.w
dp3_pp r1.y, r1, r1
rsq_pp r1.z, r1.y
dp3_pp r0.x, v1, v1
mul_pp r2.xyz, r0.y, c0
rsq_pp r0.x, r0.x
mad_pp r0.xyz, r0.x, v1, r2
dp3_pp r0.w, r0, r0
rsq_pp r0.w, r0.w
dp3 r2.w, r3, r3
mul_pp r0.xyz, r0.w, r0
rsq r0.w, r2.w
mov r2.w, c4.x
mul r3.xyz, r0.w, r3
mul r3.w, c9.x, r2
dp3_pp_sat r2.w, r0, r3
pow r0, r2.w, r3.w
dp3_pp r2.w, r2, r3
mul r3.w, r0.x, c3
mov_pp r2.xyz, c1
texldp r0.x, v4, s2
texld r0.w, v3, s3
mul r0.w, r0, r0.x
mul_pp r0.xyz, c2, r2
mul_pp r2.x, r0.w, c14.y
mul_pp r3.xyz, r4, r2.w
mad r0.xyz, r0, r3.w, r3
mul r0.xyz, r0, r2.x
dp3_pp r2.x, r0, r0
rsq_pp r1.x, r2.x
rcp_pp r1.y, r1.x
mov_pp r1.x, c3.w
mul_pp r0.w, r2, r0
mul_pp_sat r0.w, r0, c14.z
add_pp r1.x, c14.w, r1
mul_pp r1.x, r0.w, r1
rcp_pp r1.z, r1.z
add_pp_sat r0.w, r1.y, -r1.z
mad_pp r0.w, r0, -r1.x, r1.x
add_pp r0.w, r0, c9.z
add_pp r1.x, -r0.w, c9.z
mad_pp r0.w, r1, r1.x, r0
mov_pp oC0, r0
"
}

SubProgram "gles " {
Keywords { "DIRECTIONAL_COOKIE" "SHADOWS_SCREEN" }
"!!GLES"
}

SubProgram "glesdesktop " {
Keywords { "DIRECTIONAL_COOKIE" "SHADOWS_SCREEN" }
"!!GLES"
}

SubProgram "gles3 " {
Keywords { "DIRECTIONAL_COOKIE" "SHADOWS_SCREEN" }
"!!GLES3"
}

SubProgram "opengl " {
Keywords { "POINT" "SHADOWS_CUBE" }
"!!GLSL"
}

SubProgram "d3d9 " {
Keywords { "POINT" "SHADOWS_CUBE" }
Vector 0 [_WorldSpaceLightPos0]
Vector 1 [_LightPositionRange]
Vector 2 [_LightShadowData]
Vector 3 [_LightColor0]
Vector 4 [_SpecColor]
Vector 5 [_SurfaceColor]
Float 6 [_Shininess]
Float 7 [_DetailScale]
Float 8 [_DetailDist]
Float 9 [_PlanetOpacity]
Vector 10 [_PlanetOrigin]
SetTexture 0 [_MainTex] 2D
SetTexture 1 [_DetailTex] 2D
SetTexture 2 [_ShadowMapTexture] CUBE
SetTexture 3 [_LightTexture0] 2D
"ps_3_0
; 144 ALU, 8 TEX
dcl_2d s0
dcl_2d s1
dcl_cube s2
dcl_2d s3
def c11, 128.00000000, 0.00000000, 1.00000000, -0.21211439
def c12, -0.01872930, 0.07426100, 1.57072902, 2.00000000
def c13, 3.14159298, 0.31830987, -0.01348047, 0.05747731
def c14, -0.12123910, 0.19563590, -0.33299461, 0.99999559
def c15, 1.57079601, 0.15915494, 0.50000000, 1.27323949
def c16, -0.50000000, 0.97000003, 4.00000000, 16.00000000
def c17, 1.00000000, 0.00392157, 0.00001538, 0.00000001
def c18, -1.00000000, 0, 0, 0
dcl_texcoord0 v0.x
dcl_texcoord1 v1.xyz
dcl_texcoord2 v2.xyz
dcl_texcoord3 v3.xyz
dcl_texcoord4 v4.xyz
dcl_texcoord5 v5.xyz
dp3 r0.x, v5, v5
rsq r0.x, r0.x
mul r1.xyz, r0.x, v5
abs r0.xyz, r1
abs r0.w, r1.z
max r1.w, r0.x, r0
rcp r2.x, r1.w
min r1.w, r0.x, r0
mul r1.w, r1, r2.x
add r3.x, r0.z, -r0
dsy r3.zw, r1.xyxz
mul r2.w, r1, r1
add r2.xyz, r0.zxyw, -r0
cmp r3.x, r3, c11.z, c11.y
mad r2.xyz, r3.x, r2, r0
add r3.y, -r0, r2.x
mad r3.x, r2.w, c13.z, c13.w
mad r3.x, r3, r2.w, c14
mad r3.x, r3, r2.w, c14.y
mul r3.zw, r3, r3
add r2.xyz, -r0.yxzw, r2
cmp r3.y, r3, c11.z, c11
mad r2.xyz, r3.y, r2, r0.yxzw
mad r3.x, r3, r2.w, c14.z
mad r0.y, r3.x, r2.w, c14.w
mul r0.z, r0.y, r1.w
add r0.y, r0.x, -r0.w
dsx r3.xy, r1.xzzw
abs_pp r2.x, r2
rcp_pp r1.w, r2.x
add r2.x, -r0.z, c15
cmp r0.w, -r0.y, r0.z, r2.x
abs r0.x, r1.y
add r0.z, -r0.x, c11
mad r0.y, r0.x, c12.x, c12
mad r0.y, r0, r0.x, c11.w
rsq r0.z, r0.z
mul r3.xy, r3, r3
mad r0.x, r0.y, r0, c12.z
rcp r0.z, r0.z
mul r0.y, r0.x, r0.z
cmp r0.x, r1.y, c11.y, c11.z
mul r0.z, r0.x, r0.y
mad r0.y, -r0.z, c12.w, r0
add r1.y, -r0.w, c13.x
cmp r0.z, r1, r0.w, r1.y
mad r2.w, r0.x, c13.x, r0.y
cmp r0.x, r1, r0.z, -r0.z
mul r0.z, r2.w, c13.y
add r1.x, r3.z, r3.w
rsq r1.x, r1.x
rcp r1.x, r1.x
mul r2.x, r1, c15.y
mov r0.y, r0.z
dsy r0.w, r0.z
dsx r1.y, r0.z
add r0.z, r3.x, r3.y
rsq r0.z, r0.z
rcp r0.z, r0.z
mul r3.x, r0.z, c15.y
mov r0.z, r2.x
mad r0.x, r0, c15.y, c15.z
mov r1.x, r3
texldd r1.xyz, r0, s0, r1, r0.zwzw
mul_pp r0.xy, r2.zyzw, r1.w
mul r0.z, r2.w, c7.x
mul r0.z, r0, c15.w
mul_pp r0.xy, r0, c15.z
dsy r2.y, r0.z
dsx r3.y, r0.z
mul r0.xy, r0, c7.x
texldd r0.xyz, r0, s1, r3, r2
add_pp r2.xyz, r0, c16.x
mul r0.w, v0.x, c8.x
mul_sat r0.x, r0.w, c12.w
mad_pp r2.xyz, r0.x, -r2, r2
mov_pp r0.xyz, c5
mad_pp r2.xyz, r2, c15.z, r0
dp4 r0.w, c0, c0
rsq r0.w, r0.w
mul r0.xyz, r0.w, c0
add_pp r1.xyz, r1, -r2
mul_sat r1.w, c9.x, c9.x
mad_pp r3.xyz, r1.w, r1, r2
dp3_pp r0.w, r0, r0
rsq_pp r1.x, r0.w
mul_pp r1.xyz, r1.x, r0
dp3_pp r0.w, v1, v1
rsq_pp r0.x, r0.w
mad_pp r0.xyz, r0.x, v1, r1
dp3_pp r0.w, r0, r0
rsq_pp r2.w, r0.w
add r2.xyz, v2, -c10
dp3 r0.w, r2, r2
mul_pp r0.xyz, r2.w, r0
rsq r2.w, r0.w
mul r2.xyz, r2.w, r2
dp3_pp_sat r3.w, r0, r2
mov r0.w, c6.x
mul r2.w, c11.x, r0
pow r0, r3.w, r2.w
dp3_pp r2.x, r1, r2
dp3 r0.y, v4, v4
rsq r2.z, r0.y
mul r2.y, r0.x, c5.w
texld r0, v4, s2
dp4 r0.y, r0, c17
rcp r2.z, r2.z
mul r0.x, r2.z, c1.w
mad r0.y, -r0.x, c16, r0
mov r0.z, c2.x
mul_pp r4.xyz, r3, c3
dp3 r0.x, v3, v3
mul_pp r1.xyz, r4, r2.x
cmp r0.y, r0, c11.z, r0.z
texld r0.x, r0.x, s3
mul r0.w, r0.x, r0.y
mul_pp r2.z, r0.w, c16
mov_pp r0.xyz, c3
mul_pp r0.xyz, c4, r0
mad r0.xyz, r0, r2.y, r1
mul_pp r1.xyz, r3, c12.w
dp3_pp r1.y, r1, r1
mul r0.xyz, r0, r2.z
rsq_pp r1.z, r1.y
dp3_pp r2.y, r0, r0
rsq_pp r1.x, r2.y
rcp_pp r1.y, r1.x
mov_pp r1.x, c5.w
mul_pp r0.w, r2.x, r0
mul_pp_sat r0.w, r0, c16
add_pp r1.x, c18, r1
mul_pp r1.x, r0.w, r1
rcp_pp r1.z, r1.z
add_pp_sat r0.w, r1.y, -r1.z
mad_pp r0.w, r0, -r1.x, r1.x
add_pp r0.w, r0, c11.z
add_pp r1.x, -r0.w, c11.z
mad_pp r0.w, r1, r1.x, r0
mov_pp oC0, r0
"
}

SubProgram "gles " {
Keywords { "POINT" "SHADOWS_CUBE" }
"!!GLES"
}

SubProgram "glesdesktop " {
Keywords { "POINT" "SHADOWS_CUBE" }
"!!GLES"
}

SubProgram "gles3 " {
Keywords { "POINT" "SHADOWS_CUBE" }
"!!GLES3"
}

SubProgram "opengl " {
Keywords { "POINT_COOKIE" "SHADOWS_CUBE" }
"!!GLSL"
}

SubProgram "d3d9 " {
Keywords { "POINT_COOKIE" "SHADOWS_CUBE" }
Vector 0 [_WorldSpaceLightPos0]
Vector 1 [_LightPositionRange]
Vector 2 [_LightShadowData]
Vector 3 [_LightColor0]
Vector 4 [_SpecColor]
Vector 5 [_SurfaceColor]
Float 6 [_Shininess]
Float 7 [_DetailScale]
Float 8 [_DetailDist]
Float 9 [_PlanetOpacity]
Vector 10 [_PlanetOrigin]
SetTexture 0 [_MainTex] 2D
SetTexture 1 [_DetailTex] 2D
SetTexture 2 [_ShadowMapTexture] CUBE
SetTexture 3 [_LightTextureB0] 2D
SetTexture 4 [_LightTexture0] CUBE
"ps_3_0
; 143 ALU, 9 TEX
dcl_2d s0
dcl_2d s1
dcl_cube s2
dcl_2d s3
dcl_cube s4
def c11, 128.00000000, 0.00000000, 1.00000000, -0.21211439
def c12, -0.01872930, 0.07426100, 1.57072902, 2.00000000
def c13, 3.14159298, 0.31830987, -0.01348047, 0.05747731
def c14, -0.12123910, 0.19563590, -0.33299461, 0.99999559
def c15, 1.57079601, 0.15915494, 0.50000000, 1.27323949
def c16, -0.50000000, 0.97000003, 4.00000000, 16.00000000
def c17, 1.00000000, 0.00392157, 0.00001538, 0.00000001
def c18, -1.00000000, 0, 0, 0
dcl_texcoord0 v0.x
dcl_texcoord1 v1.xyz
dcl_texcoord2 v2.xyz
dcl_texcoord3 v3.xyz
dcl_texcoord4 v4.xyz
dcl_texcoord5 v5.xyz
dp3 r0.x, v5, v5
rsq r0.x, r0.x
mul r1.xyz, r0.x, v5
abs r2.xyz, r1
add r0.w, r2.z, -r2.x
add r0.xyz, r2.zxyw, -r2
cmp r0.w, r0, c11.z, c11.y
mad r0.xyz, r0.w, r0, r2
add r0.w, -r2.y, r0.x
cmp r2.w, r0, c11.z, c11.y
abs r0.w, r1.z
add r0.xyz, -r2.yxzw, r0
mad r0.xyz, r2.w, r0, r2.yxzw
max r1.w, r2.x, r0
rcp r2.y, r1.w
min r1.w, r2.x, r0
mul r1.w, r1, r2.y
abs_pp r0.x, r0
rcp_pp r2.z, r0.x
mul r2.y, r1.w, r1.w
mul_pp r2.zw, r0.xyzy, r2.z
mad r0.x, r2.y, c13.z, c13.w
mad r0.x, r0, r2.y, c14
mul_pp r2.zw, r2, c15.z
mad r0.z, r0.x, r2.y, c14.y
mul r0.xy, r2.zwzw, c7.x
mad r2.z, r0, r2.y, c14
mad r2.w, r2.z, r2.y, c14
abs r0.z, r1.y
add r2.z, -r0, c11
mad r2.y, r0.z, c12.x, c12
mad r2.y, r2, r0.z, c11.w
rsq r2.z, r2.z
mul r1.w, r2, r1
mad r0.z, r2.y, r0, c12
rcp r2.z, r2.z
mul r2.y, r0.z, r2.z
cmp r0.z, r1.y, c11.y, c11
mul r1.y, r0.z, r2
mad r1.y, -r1, c12.w, r2
mad r1.y, r0.z, c13.x, r1
dsy r2.zw, r1.xyxz
mul r2.zw, r2, r2
add r2.y, -r1.w, c15.x
add r0.z, r2.x, -r0.w
cmp r0.z, -r0, r1.w, r2.y
mul r1.w, r1.y, c7.x
add r0.w, -r0.z, c13.x
cmp r3.x, r1.z, r0.z, r0.w
dsx r0.zw, r1.xyxz
mul r0.zw, r0, r0
add r0.z, r0, r0.w
add r0.w, r2.z, r2
cmp r1.x, r1, r3, -r3
mul r1.w, r1, c15
dsx r2.y, r1.w
rsq r0.z, r0.z
rcp r0.z, r0.z
rsq r0.w, r0.w
rcp r0.w, r0.w
mul r1.z, r0.w, c15.y
mul r0.w, r1.y, c13.y
mul r2.x, r0.z, c15.y
dsy r1.w, r1
texldd r0.xyz, r0, s1, r2, r1.zwzw
mov r1.y, r0.w
dsy r1.w, r0
mad r1.x, r1, c15.y, c15.z
dsx r2.y, r0.w
texldd r2.xyz, r1, s0, r2, r1.zwzw
add_pp r1.xyz, r0, c16.x
mul r0.y, v0.x, c8.x
mul_sat r0.y, r0, c12.w
mad_pp r3.xyz, r0.y, -r1, r1
dp4 r0.x, c0, c0
rsq r0.x, r0.x
mul r0.xyz, r0.x, c0
dp3_pp r0.w, r0, r0
rsq_pp r1.w, r0.w
mov_pp r1.xyz, c5
mad_pp r1.xyz, r3, c15.z, r1
add_pp r3.xyz, r2, -r1
mul_pp r2.xyz, r1.w, r0
dp3_pp r0.w, v1, v1
rsq_pp r0.x, r0.w
mad_pp r0.xyz, r0.x, v1, r2
mul_sat r1.w, c9.x, c9.x
mad_pp r1.xyz, r1.w, r3, r1
dp3_pp r0.w, r0, r0
add r3.xyz, v2, -c10
rsq_pp r0.w, r0.w
mul_pp r4.xyz, r1, c3
mul_pp r1.xyz, r1, c12.w
dp3_pp r1.y, r1, r1
rsq_pp r1.z, r1.y
dp3 r2.w, r3, r3
mul_pp r0.xyz, r0.w, r0
rsq r0.w, r2.w
mov r2.w, c6.x
mul r3.xyz, r0.w, r3
mul r3.w, c11.x, r2
dp3_pp_sat r2.w, r0, r3
pow r0, r2.w, r3.w
dp3_pp r2.w, r2, r3
mul r3.x, r0, c5.w
texld r0, v4, s2
dp4 r0.y, r0, c17
dp3 r3.y, v4, v4
rsq r3.y, r3.y
rcp r0.x, r3.y
mul r0.x, r0, c1.w
mad r0.x, -r0, c16.y, r0.y
mov r0.z, c2.x
cmp r0.y, r0.x, c11.z, r0.z
dp3 r0.x, v3, v3
mul_pp r2.xyz, r4, r2.w
texld r0.w, v3, s4
texld r0.x, r0.x, s3
mul r0.x, r0, r0.w
mul r0.w, r0.x, r0.y
mul_pp r3.y, r0.w, c16.z
mov_pp r0.xyz, c3
mul_pp r0.xyz, c4, r0
mad r0.xyz, r0, r3.x, r2
mul r0.xyz, r0, r3.y
dp3_pp r2.x, r0, r0
rsq_pp r1.x, r2.x
rcp_pp r1.y, r1.x
mov_pp r1.x, c5.w
mul_pp r0.w, r2, r0
mul_pp_sat r0.w, r0, c16
add_pp r1.x, c18, r1
mul_pp r1.x, r0.w, r1
rcp_pp r1.z, r1.z
add_pp_sat r0.w, r1.y, -r1.z
mad_pp r0.w, r0, -r1.x, r1.x
add_pp r0.w, r0, c11.z
add_pp r1.x, -r0.w, c11.z
mad_pp r0.w, r1, r1.x, r0
mov_pp oC0, r0
"
}

SubProgram "gles " {
Keywords { "POINT_COOKIE" "SHADOWS_CUBE" }
"!!GLES"
}

SubProgram "glesdesktop " {
Keywords { "POINT_COOKIE" "SHADOWS_CUBE" }
"!!GLES"
}

SubProgram "gles3 " {
Keywords { "POINT_COOKIE" "SHADOWS_CUBE" }
"!!GLES3"
}

SubProgram "opengl " {
Keywords { "SPOT" "SHADOWS_DEPTH" "SHADOWS_SOFT" }
"!!GLSL"
}

SubProgram "d3d9 " {
Keywords { "SPOT" "SHADOWS_DEPTH" "SHADOWS_SOFT" }
Vector 0 [_WorldSpaceLightPos0]
Vector 1 [_LightShadowData]
Vector 2 [_ShadowOffsets0]
Vector 3 [_ShadowOffsets1]
Vector 4 [_ShadowOffsets2]
Vector 5 [_ShadowOffsets3]
Vector 6 [_LightColor0]
Vector 7 [_SpecColor]
Vector 8 [_SurfaceColor]
Float 9 [_Shininess]
Float 10 [_DetailScale]
Float 11 [_DetailDist]
Float 12 [_PlanetOpacity]
Vector 13 [_PlanetOrigin]
SetTexture 0 [_MainTex] 2D
SetTexture 1 [_DetailTex] 2D
SetTexture 2 [_LightTexture0] 2D
SetTexture 3 [_LightTextureB0] 2D
SetTexture 4 [_ShadowMapTexture] 2D
"ps_3_0
; 154 ALU, 12 TEX
dcl_2d s0
dcl_2d s1
dcl_2d s2
dcl_2d s3
dcl_2d s4
def c14, 128.00000000, 0.00000000, 1.00000000, -0.21211439
def c15, -0.01872930, 0.07426100, 1.57072902, 2.00000000
def c16, 3.14159298, 0.31830987, -0.01348047, 0.05747731
def c17, -0.12123910, 0.19563590, -0.33299461, 0.99999559
def c18, 1.57079601, 0.15915494, 0.50000000, 1.27323949
def c19, -0.50000000, 0.25000000, 4.00000000, 16.00000000
def c20, -1.00000000, 0, 0, 0
dcl_texcoord0 v0.x
dcl_texcoord1 v1.xyz
dcl_texcoord2 v2.xyz
dcl_texcoord3 v3
dcl_texcoord4 v4
dcl_texcoord5 v5.xyz
dp3 r0.x, v5, v5
rsq r0.x, r0.x
mul r1.xyz, r0.x, v5
abs r0.xyz, r1
abs r0.w, r1.z
max r1.w, r0.x, r0
rcp r2.x, r1.w
min r1.w, r0.x, r0
mul r1.w, r1, r2.x
add r3.x, r0.z, -r0
dsy r3.zw, r1.xyxz
mul r2.w, r1, r1
add r2.xyz, r0.zxyw, -r0
cmp r3.x, r3, c14.z, c14.y
mad r2.xyz, r3.x, r2, r0
add r3.y, -r0, r2.x
mad r3.x, r2.w, c16.z, c16.w
mad r3.x, r3, r2.w, c17
mad r3.x, r3, r2.w, c17.y
add r2.xyz, -r0.yxzw, r2
cmp r3.y, r3, c14.z, c14
mad r2.xyz, r3.y, r2, r0.yxzw
mad r3.x, r3, r2.w, c17.z
mad r0.y, r3.x, r2.w, c17.w
mul r0.z, r0.y, r1.w
add r0.y, r0.x, -r0.w
dsx r3.xy, r1.xzzw
abs_pp r2.x, r2
rcp_pp r1.w, r2.x
add r2.x, -r0.z, c18
cmp r0.w, -r0.y, r0.z, r2.x
abs r0.x, r1.y
add r0.z, -r0.x, c14
mad r0.y, r0.x, c15.x, c15
mad r0.y, r0, r0.x, c14.w
rsq r0.z, r0.z
mad r0.x, r0.y, r0, c15.z
rcp r0.z, r0.z
mul r0.y, r0.x, r0.z
cmp r0.x, r1.y, c14.y, c14.z
mul r0.z, r0.x, r0.y
mad r0.y, -r0.z, c15.w, r0
add r1.y, -r0.w, c16.x
cmp r0.z, r1, r0.w, r1.y
mad r2.w, r0.x, c16.x, r0.y
cmp r0.x, r1, r0.z, -r0.z
mul r0.z, r2.w, c16.y
mul r3.zw, r3, r3
add r1.x, r3.z, r3.w
rsq r1.x, r1.x
rcp r1.x, r1.x
dsx r1.y, r0.z
dsy r0.w, r0.z
mul r1.z, r1.x, c18.y
mov r0.y, r0.z
mul r3.xy, r3, r3
add r0.z, r3.x, r3.y
rsq r0.z, r0.z
rcp r0.z, r0.z
mul r2.x, r0.z, c18.y
mov r1.x, r2
mov r0.z, r1
mad r0.x, r0, c18.y, c18.z
texldd r0.xyz, r0, s0, r1, r0.zwzw
mul_pp r1.xy, r2.zyzw, r1.w
mul r0.w, r2, c10.x
mul r0.w, r0, c18
mul_pp r1.xy, r1, c18.z
dsy r1.w, r0
dsx r2.y, r0.w
mul r1.xy, r1, c10.x
texldd r1.xyz, r1, s1, r2, r1.zwzw
mul r0.w, v0.x, c11.x
add_pp r1.xyz, r1, c19.x
mul_sat r0.w, r0, c15
mad_pp r2.xyz, r0.w, -r1, r1
mov_pp r1.xyz, c8
mad_pp r1.xyz, r2, c18.z, r1
dp4 r0.w, c0, c0
add_pp r2.xyz, r0, -r1
rsq r0.w, r0.w
mul r0.xyz, r0.w, c0
dp3_pp r0.w, r0, r0
mul_sat r1.w, c12.x, c12.x
mad_pp r1.xyz, r1.w, r2, r1
mul_pp r4.xyz, r1, c6
mul_pp r1.xyz, r1, c15.w
dp3_pp r1.y, r1, r1
rsq_pp r0.w, r0.w
mul_pp r2.xyz, r0.w, r0
add r3.xyz, v2, -c13
dp3 r0.y, r3, r3
rsq r0.w, r0.y
mul r3.xyz, r0.w, r3
rsq_pp r1.z, r1.y
dp3_pp r0.x, v1, v1
rsq_pp r0.x, r0.x
mad_pp r0.xyz, r0.x, v1, r2
dp3_pp r2.w, r2, r3
dp3_pp r0.w, r0, r0
rsq_pp r0.w, r0.w
mov r2.x, c9
mul r2.y, c14.x, r2.x
mul_pp r0.xyz, r0.w, r0
dp3_pp_sat r2.x, r0, r3
pow r0, r2.x, r2.y
mov r0.z, r0.x
rcp r3.y, v4.w
mul_pp r2.xyz, r4, r2.w
mad r0.xy, v4, r3.y, c5
texld r0.x, r0, s4
mad r4.xy, v4, r3.y, c4
mov r0.w, r0.x
texld r0.x, r4, s4
mul r3.x, r0.z, c8.w
mad r4.xy, v4, r3.y, c3
mov r0.z, r0.x
texld r0.x, r4, s4
mad r4.xy, v4, r3.y, c2
mov r0.y, r0.x
texld r0.x, r4, s4
mad r0, -v4.z, r3.y, r0
rcp r3.y, v3.w
mov r3.z, c1.x
cmp r0, r0, c14.z, r3.z
dp4_pp r0.z, r0, c19.y
mad r4.xy, v3, r3.y, c18.z
dp3 r0.x, v3, v3
texld r0.w, r4, s2
cmp r0.y, -v3.z, c14, c14.z
mul_pp r0.y, r0, r0.w
texld r0.x, r0.x, s3
mul_pp r0.x, r0.y, r0
mul_pp r0.w, r0.x, r0.z
mul_pp r3.y, r0.w, c19.z
mov_pp r0.xyz, c6
mul_pp r0.xyz, c7, r0
mad r0.xyz, r0, r3.x, r2
mul r0.xyz, r0, r3.y
dp3_pp r2.x, r0, r0
rsq_pp r1.x, r2.x
rcp_pp r1.y, r1.x
mov_pp r1.x, c8.w
mul_pp r0.w, r2, r0
mul_pp_sat r0.w, r0, c19
add_pp r1.x, c20, r1
mul_pp r1.x, r0.w, r1
rcp_pp r1.z, r1.z
add_pp_sat r0.w, r1.y, -r1.z
mad_pp r0.w, r0, -r1.x, r1.x
add_pp r0.w, r0, c14.z
add_pp r1.x, -r0.w, c14.z
mad_pp r0.w, r1, r1.x, r0
mov_pp oC0, r0
"
}

SubProgram "gles " {
Keywords { "SPOT" "SHADOWS_DEPTH" "SHADOWS_SOFT" }
"!!GLES"
}

SubProgram "glesdesktop " {
Keywords { "SPOT" "SHADOWS_DEPTH" "SHADOWS_SOFT" }
"!!GLES"
}

SubProgram "gles3 " {
Keywords { "SPOT" "SHADOWS_DEPTH" "SHADOWS_SOFT" }
"!!GLES3"
}

SubProgram "opengl " {
Keywords { "SPOT" "SHADOWS_DEPTH" "SHADOWS_SOFT" "SHADOWS_NATIVE" }
"!!GLSL"
}

SubProgram "d3d9 " {
Keywords { "SPOT" "SHADOWS_DEPTH" "SHADOWS_SOFT" "SHADOWS_NATIVE" }
Vector 0 [_WorldSpaceLightPos0]
Vector 1 [_LightShadowData]
Vector 2 [_ShadowOffsets0]
Vector 3 [_ShadowOffsets1]
Vector 4 [_ShadowOffsets2]
Vector 5 [_ShadowOffsets3]
Vector 6 [_LightColor0]
Vector 7 [_SpecColor]
Vector 8 [_SurfaceColor]
Float 9 [_Shininess]
Float 10 [_DetailScale]
Float 11 [_DetailDist]
Float 12 [_PlanetOpacity]
Vector 13 [_PlanetOrigin]
SetTexture 0 [_MainTex] 2D
SetTexture 1 [_DetailTex] 2D
SetTexture 2 [_LightTexture0] 2D
SetTexture 3 [_LightTextureB0] 2D
SetTexture 4 [_ShadowMapTexture] 2D
"ps_3_0
; 154 ALU, 12 TEX
dcl_2d s0
dcl_2d s1
dcl_2d s2
dcl_2d s3
dcl_2d s4
def c14, 128.00000000, 0.00000000, 1.00000000, -0.21211439
def c15, -0.01872930, 0.07426100, 1.57072902, 2.00000000
def c16, 3.14159298, 0.31830987, -0.01348047, 0.05747731
def c17, -0.12123910, 0.19563590, -0.33299461, 0.99999559
def c18, 1.57079601, 0.15915494, 0.50000000, 1.27323949
def c19, -0.50000000, 0.25000000, 4.00000000, 16.00000000
def c20, -1.00000000, 0, 0, 0
dcl_texcoord0 v0.x
dcl_texcoord1 v1.xyz
dcl_texcoord2 v2.xyz
dcl_texcoord3 v3
dcl_texcoord4 v4
dcl_texcoord5 v5.xyz
dp3 r0.x, v5, v5
rsq r0.x, r0.x
mul r1.xyz, r0.x, v5
abs r2.xyz, r1
add r0.w, r2.z, -r2.x
dsy r4.xy, r1.xzzw
add r0.xyz, r2.zxyw, -r2
cmp r0.w, r0, c14.z, c14.y
mad r0.xyz, r0.w, r0, r2
add r0.w, -r2.y, r0.x
abs r1.w, r1.z
add r0.xyz, -r2.yxzw, r0
cmp r0.w, r0, c14.z, c14.y
mad r0.xyz, r0.w, r0, r2.yxzw
abs_pp r0.x, r0
rcp_pp r0.x, r0.x
mul_pp r0.xy, r0.zyzw, r0.x
max r0.z, r2.x, r1.w
rcp r0.w, r0.z
min r0.z, r2.x, r1.w
mul r2.y, r0.z, r0.w
abs r0.w, r1.y
add r2.w, -r0, c14.z
mad r2.z, r0.w, c15.x, c15.y
mad r2.z, r2, r0.w, c14.w
mul_pp r0.xy, r0, c18.z
rsq r2.w, r2.w
mul r0.z, r2.y, r2.y
mad r0.w, r2.z, r0, c15.z
rcp r2.w, r2.w
mul r2.z, r0.w, r2.w
cmp r0.w, r1.y, c14.y, c14.z
mul r1.y, r0.w, r2.z
mad r1.y, -r1, c15.w, r2.z
mad r2.w, r0.z, c16.z, c16
mad r2.z, r2.w, r0, c17.x
mad r0.w, r0, c16.x, r1.y
mad r1.y, r2.z, r0.z, c17
mul r2.z, r0.w, c10.x
mul r2.z, r2, c18.w
mad r1.y, r1, r0.z, c17.z
mad r1.y, r1, r0.z, c17.w
mul r2.y, r1, r2
add r1.y, r2.x, -r1.w
mul r1.w, v0.x, c11.x
mul r0.w, r0, c16.y
dsx r3.w, r2.z
dsy r3.y, r2.z
dsx r2.zw, r1.xyxz
mul r2.zw, r2, r2
add r0.z, r2, r2.w
mul r4.xy, r4, r4
add r2.z, r4.x, r4.y
rsq r0.z, r0.z
rcp r0.z, r0.z
rsq r2.z, r2.z
rcp r2.z, r2.z
mul r3.x, r2.z, c18.y
add r2.z, -r2.y, c18.x
mul r3.z, r0, c18.y
mul r0.xy, r0, c10.x
texldd r0.xyz, r0, s1, r3.zwzw, r3
mov r3.w, c9.x
cmp r1.y, -r1, r2, r2.z
add_pp r0.xyz, r0, c19.x
mul_sat r1.w, r1, c15
mad_pp r2.xyz, r1.w, -r0, r0
add r1.w, -r1.y, c16.x
cmp r1.y, r1.z, r1, r1.w
cmp r1.x, r1, r1.y, -r1.y
mov_pp r0.xyz, c8
mad_pp r0.xyz, r2, c18.z, r0
dsx r2.y, r0.w
dsy r1.w, r0
mov r2.x, r3.z
mov r1.y, r0.w
mov r1.z, r3.x
mad r1.x, r1, c18.y, c18.z
texldd r1.xyz, r1, s0, r2, r1.zwzw
add_pp r1.xyz, r1, -r0
mul_sat r1.w, c12.x, c12.x
mad_pp r2.xyz, r1.w, r1, r0
add r1.xyz, v2, -c13
dp3 r0.w, r1, r1
rsq r2.w, r0.w
dp4 r0.x, c0, c0
rsq r0.x, r0.x
mul r0.xyz, r0.x, c0
dp3_pp r0.w, r0, r0
mul r1.xyz, r2.w, r1
rsq_pp r2.w, r0.w
mul_pp r3.xyz, r2.w, r0
dp3_pp r0.w, v1, v1
rsq_pp r0.x, r0.w
mad_pp r0.xyz, r0.x, v1, r3
dp3_pp r0.w, r0, r0
rsq_pp r0.w, r0.w
dp3_pp r2.w, r3, r1
mul_pp r4.xyz, r2, c6
mul_pp r3.xyz, r4, r2.w
mul_pp r0.xyz, r0.w, r0
rcp r4.x, v4.w
dp3_pp_sat r1.x, r0, r1
mul r3.w, c14.x, r3
pow r0, r1.x, r3.w
mov r0.y, r0.x
mad r1.xyz, v4, r4.x, c5
texld r0.x, r1, s4
mad r1.xyz, v4, r4.x, c3
mul r3.w, r0.y, c8
mov_pp r0.w, r0.x
mad r0.xyz, v4, r4.x, c4
texld r0.x, r0, s4
texld r1.x, r1, s4
mov_pp r0.z, r0.x
mov_pp r0.y, r1.x
mad r1.xyz, v4, r4.x, c2
mov r0.x, c1
add r4.x, c14.z, -r0
texld r0.x, r1, s4
mad r0, r0, r4.x, c1.x
dp4_pp r0.z, r0, c19.y
rcp r1.x, v3.w
mad r1.xy, v3, r1.x, c18.z
dp3 r0.x, v3, v3
texld r0.w, r1, s2
cmp r0.y, -v3.z, c14, c14.z
mul_pp r0.y, r0, r0.w
texld r0.x, r0.x, s3
mul_pp r0.x, r0.y, r0
mul_pp r0.w, r0.x, r0.z
mul_pp r1.x, r0.w, c19.z
mov_pp r0.xyz, c6
mul_pp r0.xyz, c7, r0
mad r0.xyz, r0, r3.w, r3
mul r0.xyz, r0, r1.x
mul_pp r1.xyz, r2, c15.w
dp3_pp r1.y, r1, r1
rsq_pp r1.z, r1.y
dp3_pp r2.x, r0, r0
rsq_pp r1.x, r2.x
rcp_pp r1.y, r1.x
mov_pp r1.x, c8.w
mul_pp r0.w, r2, r0
mul_pp_sat r0.w, r0, c19
add_pp r1.x, c20, r1
mul_pp r1.x, r0.w, r1
rcp_pp r1.z, r1.z
add_pp_sat r0.w, r1.y, -r1.z
mad_pp r0.w, r0, -r1.x, r1.x
add_pp r0.w, r0, c14.z
add_pp r1.x, -r0.w, c14.z
mad_pp r0.w, r1, r1.x, r0
mov_pp oC0, r0
"
}

SubProgram "gles " {
Keywords { "SPOT" "SHADOWS_DEPTH" "SHADOWS_SOFT" "SHADOWS_NATIVE" }
"!!GLES"
}

SubProgram "gles3 " {
Keywords { "SPOT" "SHADOWS_DEPTH" "SHADOWS_SOFT" "SHADOWS_NATIVE" }
"!!GLES3"
}

SubProgram "opengl " {
Keywords { "POINT" "SHADOWS_CUBE" "SHADOWS_SOFT" }
"!!GLSL"
}

SubProgram "d3d9 " {
Keywords { "POINT" "SHADOWS_CUBE" "SHADOWS_SOFT" }
Vector 0 [_WorldSpaceLightPos0]
Vector 1 [_LightPositionRange]
Vector 2 [_LightShadowData]
Vector 3 [_LightColor0]
Vector 4 [_SpecColor]
Vector 5 [_SurfaceColor]
Float 6 [_Shininess]
Float 7 [_DetailScale]
Float 8 [_DetailDist]
Float 9 [_PlanetOpacity]
Vector 10 [_PlanetOrigin]
SetTexture 0 [_MainTex] 2D
SetTexture 1 [_DetailTex] 2D
SetTexture 2 [_ShadowMapTexture] CUBE
SetTexture 3 [_LightTexture0] 2D
"ps_3_0
; 153 ALU, 11 TEX
dcl_2d s0
dcl_2d s1
dcl_cube s2
dcl_2d s3
def c11, 128.00000000, 0.00000000, 1.00000000, -0.21211439
def c12, -0.01872930, 0.07426100, 1.57072902, 2.00000000
def c13, 3.14159298, 0.31830987, -0.01348047, 0.05747731
def c14, -0.12123910, 0.19563590, -0.33299461, 0.99999559
def c15, 1.57079601, 0.15915494, 0.50000000, 1.27323949
def c16, -0.50000000, 0.00781250, -0.00781250, 0.97000003
def c17, 1.00000000, 0.00392157, 0.00001538, 0.00000001
def c18, 0.25000000, 4.00000000, 16.00000000, -1.00000000
dcl_texcoord0 v0.x
dcl_texcoord1 v1.xyz
dcl_texcoord2 v2.xyz
dcl_texcoord3 v3.xyz
dcl_texcoord4 v4.xyz
dcl_texcoord5 v5.xyz
dp3 r0.x, v5, v5
rsq r0.x, r0.x
mul r0.xyz, r0.x, v5
abs r1.xyz, r0
abs r0.w, r0.z
max r1.w, r1.x, r0
rcp r2.x, r1.w
min r1.w, r1.x, r0
mul r2.w, r1, r2.x
add r3.x, r1.z, -r1
mul r1.w, r2, r2
add r2.xyz, r1.zxyw, -r1
cmp r3.x, r3, c11.z, c11.y
mad r2.xyz, r3.x, r2, r1
add r3.y, -r1, r2.x
mad r3.x, r1.w, c13.z, c13.w
mad r3.x, r3, r1.w, c14
mad r3.x, r3, r1.w, c14.y
add r2.xyz, -r1.yxzw, r2
cmp r3.y, r3, c11.z, c11
mad r2.xyz, r3.y, r2, r1.yxzw
mad r3.x, r3, r1.w, c14.z
mad r1.y, r3.x, r1.w, c14.w
add r1.x, r1, -r0.w
abs r0.w, r0.y
abs_pp r1.z, r2.x
dsy r3.xy, r0.xzzw
mul r3.xy, r3, r3
mul r1.y, r1, r2.w
rcp_pp r2.x, r1.z
add r1.z, -r1.y, c15.x
cmp r1.z, -r1.x, r1.y, r1
add r1.y, -r0.w, c11.z
mad r1.x, r0.w, c12, c12.y
mad r1.x, r1, r0.w, c11.w
rsq r1.y, r1.y
cmp r0.y, r0, c11, c11.z
rcp r1.y, r1.y
mad r0.w, r1.x, r0, c12.z
mul r0.w, r0, r1.y
mul r1.x, r0.y, r0.w
mad r0.w, -r1.x, c12, r0
mad r2.w, r0.y, c13.x, r0
add r1.y, -r1.z, c13.x
cmp r1.x, r0.z, r1.z, r1.y
dsx r1.zw, r0.xyxz
cmp r0.w, r0.x, r1.x, -r1.x
mul r1.zw, r1, r1
mul r0.y, r2.w, c13
add r0.x, r1.z, r1.w
add r0.z, r3.x, r3.y
mad r1.x, r0.w, c15.y, c15.z
rsq r0.x, r0.x
rcp r0.x, r0.x
rsq r0.z, r0.z
rcp r0.z, r0.z
mul r3.x, r0, c15.y
mul r3.z, r0, c15.y
dsx r0.w, r0.y
mov r1.y, r0
mov r0.z, r3.x
mov r0.x, r3.z
dsy r0.y, r0
texldd r1.xyz, r1, s0, r0.zwzw, r0
mul r0.z, r2.w, c7.x
mul r0.z, r0, c15.w
mul_pp r0.xy, r2.zyzw, r2.x
mul_pp r0.xy, r0, c15.z
dsy r3.w, r0.z
dsx r3.y, r0.z
mul r0.xy, r0, c7.x
texldd r0.xyz, r0, s1, r3, r3.zwzw
add_pp r2.xyz, r0, c16.x
mul r0.w, v0.x, c8.x
mul_sat r0.x, r0.w, c12.w
mad_pp r2.xyz, r0.x, -r2, r2
mov_pp r0.xyz, c5
mad_pp r2.xyz, r2, c15.z, r0
dp4 r0.w, c0, c0
rsq r0.w, r0.w
mul r0.xyz, r0.w, c0
dp3_pp r0.w, r0, r0
rsq_pp r0.w, r0.w
mul_pp r4.xyz, r0.w, r0
dp3_pp r0.x, v1, v1
rsq_pp r0.x, r0.x
add_pp r1.xyz, r1, -r2
mul_sat r2.w, c9.x, c9.x
mad_pp r2.xyz, r2.w, r1, r2
mul_pp r3.xyz, r2, c3
add r1.xyz, v2, -c10
dp3 r0.w, r1, r1
rsq r1.w, r0.w
mul r1.xyz, r1.w, r1
dp3_pp r3.w, r4, r1
mad_pp r0.xyz, r0.x, v1, r4
dp3_pp r0.w, r0, r0
rsq_pp r0.w, r0.w
mul_pp r0.xyz, r0.w, r0
dp3_pp_sat r1.x, r0, r1
mov r0.w, c6.x
mul r1.y, c11.x, r0.w
pow r4, r1.x, r1.y
add r0.xyz, v4, c16.yzzw
texld r0, r0, s2
dp4 r5.w, r0, c17
add r0.xyz, v4, c16.zyzw
texld r0, r0, s2
dp4 r5.z, r0, c17
add r1.xyz, v4, c16.zzyw
texld r1, r1, s2
dp4 r5.y, r1, c17
add r0.xyz, v4, c16.y
texld r0, r0, s2
dp3 r1.x, v4, v4
rsq r1.x, r1.x
dp4 r5.x, r0, c17
rcp r0.x, r1.x
mul r0.x, r0, c1.w
mad r0, -r0.x, c16.w, r5
mov r1.x, c2
cmp r1, r0, c11.z, r1.x
dp3 r0.x, v3, v3
dp4_pp r0.y, r1, c18.x
texld r0.x, r0.x, s3
mul r0.w, r0.x, r0.y
mul_pp r1.y, r0.w, c18
mov r1.x, r4
mov_pp r0.xyz, c3
mul_pp r0.w, r3, r0
mul r1.x, r1, c5.w
mul_pp_sat r0.w, r0, c18.z
mul_pp r3.xyz, r3, r3.w
mul_pp r0.xyz, c4, r0
mad r0.xyz, r0, r1.x, r3
mul r0.xyz, r0, r1.y
mul_pp r2.xyz, r2, c12.w
dp3_pp r1.y, r2, r2
rsq_pp r1.z, r1.y
dp3_pp r1.x, r0, r0
rsq_pp r1.x, r1.x
rcp_pp r1.y, r1.x
mov_pp r1.x, c5.w
add_pp r1.x, c18.w, r1
mul_pp r1.x, r0.w, r1
rcp_pp r1.z, r1.z
add_pp_sat r0.w, r1.y, -r1.z
mad_pp r0.w, r0, -r1.x, r1.x
add_pp r0.w, r0, c11.z
add_pp r1.x, -r0.w, c11.z
mad_pp r0.w, r2, r1.x, r0
mov_pp oC0, r0
"
}

SubProgram "gles " {
Keywords { "POINT" "SHADOWS_CUBE" "SHADOWS_SOFT" }
"!!GLES"
}

SubProgram "glesdesktop " {
Keywords { "POINT" "SHADOWS_CUBE" "SHADOWS_SOFT" }
"!!GLES"
}

SubProgram "gles3 " {
Keywords { "POINT" "SHADOWS_CUBE" "SHADOWS_SOFT" }
"!!GLES3"
}

SubProgram "opengl " {
Keywords { "POINT_COOKIE" "SHADOWS_CUBE" "SHADOWS_SOFT" }
"!!GLSL"
}

SubProgram "d3d9 " {
Keywords { "POINT_COOKIE" "SHADOWS_CUBE" "SHADOWS_SOFT" }
Vector 0 [_WorldSpaceLightPos0]
Vector 1 [_LightPositionRange]
Vector 2 [_LightShadowData]
Vector 3 [_LightColor0]
Vector 4 [_SpecColor]
Vector 5 [_SurfaceColor]
Float 6 [_Shininess]
Float 7 [_DetailScale]
Float 8 [_DetailDist]
Float 9 [_PlanetOpacity]
Vector 10 [_PlanetOrigin]
SetTexture 0 [_MainTex] 2D
SetTexture 1 [_DetailTex] 2D
SetTexture 2 [_ShadowMapTexture] CUBE
SetTexture 3 [_LightTextureB0] 2D
SetTexture 4 [_LightTexture0] CUBE
"ps_3_0
; 153 ALU, 12 TEX
dcl_2d s0
dcl_2d s1
dcl_cube s2
dcl_2d s3
dcl_cube s4
def c11, 128.00000000, 0.00000000, 1.00000000, -0.21211439
def c12, -0.01872930, 0.07426100, 1.57072902, 2.00000000
def c13, 3.14159298, 0.31830987, -0.01348047, 0.05747731
def c14, -0.12123910, 0.19563590, -0.33299461, 0.99999559
def c15, 1.57079601, 0.15915494, 0.50000000, 1.27323949
def c16, -0.50000000, 0.00781250, -0.00781250, 0.97000003
def c17, 1.00000000, 0.00392157, 0.00001538, 0.00000001
def c18, 0.25000000, 4.00000000, 16.00000000, -1.00000000
dcl_texcoord0 v0.x
dcl_texcoord1 v1.xyz
dcl_texcoord2 v2.xyz
dcl_texcoord3 v3.xyz
dcl_texcoord4 v4.xyz
dcl_texcoord5 v5.xyz
dp3 r0.x, v5, v5
rsq r0.x, r0.x
mul r1.xyz, r0.x, v5
abs r2.xyz, r1
add r0.w, r2.z, -r2.x
dsx r4.xy, r1.xzzw
add r0.xyz, r2.zxyw, -r2
cmp r0.w, r0, c11.z, c11.y
mad r0.xyz, r0.w, r0, r2
add r0.w, -r2.y, r0.x
abs r1.w, r1.z
add r0.xyz, -r2.yxzw, r0
cmp r0.w, r0, c11.z, c11.y
mad r0.xyz, r0.w, r0, r2.yxzw
abs_pp r0.x, r0
rcp_pp r0.x, r0.x
mul_pp r0.xy, r0.zyzw, r0.x
max r0.z, r2.x, r1.w
rcp r0.w, r0.z
min r0.z, r2.x, r1.w
mul r2.y, r0.z, r0.w
abs r0.w, r1.y
add r2.w, -r0, c11.z
mad r2.z, r0.w, c12.x, c12.y
mad r2.z, r2, r0.w, c11.w
mul_pp r0.xy, r0, c15.z
rsq r2.w, r2.w
mul r0.z, r2.y, r2.y
mad r0.w, r2.z, r0, c12.z
rcp r2.w, r2.w
mul r2.z, r0.w, r2.w
cmp r0.w, r1.y, c11.y, c11.z
mul r1.y, r0.w, r2.z
mad r1.y, -r1, c12.w, r2.z
mad r2.w, r0.z, c13.z, c13
mad r0.w, r0, c13.x, r1.y
mad r2.z, r2.w, r0, c14.x
mad r1.y, r2.z, r0.z, c14
mad r1.y, r1, r0.z, c14.z
mad r1.y, r1, r0.z, c14.w
mul r2.y, r1, r2
add r1.y, r2.x, -r1.w
mul r2.z, r0.w, c7.x
mul r2.z, r2, c15.w
mul r4.xy, r4, r4
add r0.z, r4.x, r4.y
rsq r0.z, r0.z
rcp r0.z, r0.z
mul r1.w, v0.x, c8.x
mul r3.z, r0, c15.y
dsx r3.w, r2.z
dsy r3.y, r2.z
dsy r2.zw, r1.xyxz
mul r2.zw, r2, r2
add r2.z, r2, r2.w
rsq r2.z, r2.z
rcp r2.z, r2.z
mul r3.x, r2.z, c15.y
add r2.z, -r2.y, c15.x
mul r0.xy, r0, c7.x
texldd r0.xyz, r0, s1, r3.zwzw, r3
cmp r1.y, -r1, r2, r2.z
add_pp r0.xyz, r0, c16.x
mul_sat r1.w, r1, c12
mad_pp r2.xyz, r1.w, -r0, r0
mov_pp r0.xyz, c5
mad_pp r2.xyz, r2, c15.z, r0
mul r0.x, r0.w, c13.y
add r1.w, -r1.y, c13.x
cmp r1.y, r1.z, r1, r1.w
cmp r0.y, r1.x, r1, -r1
mad r1.x, r0.y, c15.y, c15.z
mov r1.y, r0.x
dsx r0.w, r0.x
dsy r0.y, r0.x
mov r0.z, r3
mov r0.x, r3
texldd r0.xyz, r1, s0, r0.zwzw, r0
add_pp r0.xyz, r0, -r2
mul_sat r2.w, c9.x, c9.x
mad_pp r4.xyz, r2.w, r0, r2
add r2.xyz, v2, -c10
dp3 r1.w, r2, r2
rsq r1.w, r1.w
dp4 r0.x, c0, c0
rsq r0.x, r0.x
mul r0.xyz, r0.x, c0
dp3_pp r0.w, r0, r0
mul r3.xyz, r1.w, r2
rsq_pp r0.w, r0.w
mul_pp r2.xyz, r0.w, r0
add r0.xyz, v4, c16.yzzw
texld r0, r0, s2
dp3_pp r3.w, r2, r3
mul_pp r1.xyz, r4, c3
mul_pp r5.xyz, r1, r3.w
add r1.xyz, v4, c16.zyzw
dp4 r1.w, r0, c17
texld r0, r1, s2
dp4 r1.z, r0, c17
add r6.xyz, v4, c16.zzyw
texld r0, r6, s2
dp4 r1.y, r0, c17
add r6.xyz, v4, c16.y
texld r0, r6, s2
dp4 r1.x, r0, c17
dp3 r4.w, v4, v4
rsq r0.y, r4.w
dp3_pp r0.x, v1, v1
rcp r0.y, r0.y
rsq_pp r4.w, r0.x
mul r0.x, r0.y, c1.w
mad r0, -r0.x, c16.w, r1
mad_pp r1.xyz, r4.w, v1, r2
mov r2.x, c2
cmp r0, r0, c11.z, r2.x
dp4_pp r0.y, r0, c18.x
dp3_pp r1.w, r1, r1
rsq_pp r1.w, r1.w
mov r2.x, c6
dp3 r0.x, v3, v3
mul r2.y, c11.x, r2.x
mul_pp r1.xyz, r1.w, r1
dp3_pp_sat r2.x, r1, r3
pow r1, r2.x, r2.y
texld r0.w, v3, s4
texld r0.x, r0.x, s3
mul r0.x, r0, r0.w
mul r0.w, r0.x, r0.y
mul_pp r1.y, r0.w, c18
mov_pp r0.xyz, c3
mul_pp r0.w, r3, r0
mul r1.x, r1, c5.w
mul_pp r0.xyz, c4, r0
mad r0.xyz, r0, r1.x, r5
mul r0.xyz, r0, r1.y
mul_pp r2.xyz, r4, c12.w
dp3_pp r1.y, r2, r2
rsq_pp r1.z, r1.y
dp3_pp r1.x, r0, r0
rsq_pp r1.x, r1.x
rcp_pp r1.y, r1.x
mov_pp r1.x, c5.w
mul_pp_sat r0.w, r0, c18.z
add_pp r1.x, c18.w, r1
mul_pp r1.x, r0.w, r1
rcp_pp r1.z, r1.z
add_pp_sat r0.w, r1.y, -r1.z
mad_pp r0.w, r0, -r1.x, r1.x
add_pp r0.w, r0, c11.z
add_pp r1.x, -r0.w, c11.z
mad_pp r0.w, r2, r1.x, r0
mov_pp oC0, r0
"
}

SubProgram "gles " {
Keywords { "POINT_COOKIE" "SHADOWS_CUBE" "SHADOWS_SOFT" }
"!!GLES"
}

SubProgram "glesdesktop " {
Keywords { "POINT_COOKIE" "SHADOWS_CUBE" "SHADOWS_SOFT" }
"!!GLES"
}

SubProgram "gles3 " {
Keywords { "POINT_COOKIE" "SHADOWS_CUBE" "SHADOWS_SOFT" }
"!!GLES3"
}

}

#LINE 124

	
		}
		
		// Pass to render object as a shadow collector
		Pass {
			Name "ShadowCollector"
			Tags { "LightMode" = "ShadowCollector" }
			
			Fog {Mode Off}
			ZWrite On ZTest LEqual

			Program "vp" {
// Vertex combos: 4
//   opengl - ALU: 24 to 24
//   d3d9 - ALU: 24 to 24
//   d3d11 - ALU: 29 to 29, TEX: 0 to 0, FLOW: 1 to 1
//   d3d11_9x - ALU: 29 to 29, TEX: 0 to 0, FLOW: 1 to 1
SubProgram "opengl " {
Keywords { "SHADOWS_NONATIVE" }
Bind "vertex" Vertex
Matrix 9 [unity_World2Shadow0]
Matrix 13 [unity_World2Shadow1]
Matrix 17 [unity_World2Shadow2]
Matrix 21 [unity_World2Shadow3]
Matrix 25 [_Object2World]
"!!ARBvp1.0
# 24 ALU
PARAM c[29] = { program.local[0],
		state.matrix.modelview[0],
		state.matrix.mvp,
		program.local[9..28] };
TEMP R0;
TEMP R1;
DP4 R0.w, vertex.position, c[3];
DP4 R1.w, vertex.position, c[28];
DP4 R0.z, vertex.position, c[27];
DP4 R0.x, vertex.position, c[25];
DP4 R0.y, vertex.position, c[26];
MOV R1.xyz, R0;
MOV R0.w, -R0;
DP4 result.texcoord[0].z, R1, c[11];
DP4 result.texcoord[0].y, R1, c[10];
DP4 result.texcoord[0].x, R1, c[9];
DP4 result.texcoord[1].z, R1, c[15];
DP4 result.texcoord[1].y, R1, c[14];
DP4 result.texcoord[1].x, R1, c[13];
DP4 result.texcoord[2].z, R1, c[19];
DP4 result.texcoord[2].y, R1, c[18];
DP4 result.texcoord[2].x, R1, c[17];
DP4 result.texcoord[3].z, R1, c[23];
DP4 result.texcoord[3].y, R1, c[22];
DP4 result.texcoord[3].x, R1, c[21];
MOV result.texcoord[4], R0;
DP4 result.position.w, vertex.position, c[8];
DP4 result.position.z, vertex.position, c[7];
DP4 result.position.y, vertex.position, c[6];
DP4 result.position.x, vertex.position, c[5];
END
# 24 instructions, 2 R-regs
"
}

SubProgram "d3d9 " {
Keywords { "SHADOWS_NONATIVE" }
Bind "vertex" Vertex
Matrix 0 [glstate_matrix_modelview0]
Matrix 4 [glstate_matrix_mvp]
Matrix 8 [unity_World2Shadow0]
Matrix 12 [unity_World2Shadow1]
Matrix 16 [unity_World2Shadow2]
Matrix 20 [unity_World2Shadow3]
Matrix 24 [_Object2World]
"vs_2_0
; 24 ALU
dcl_position0 v0
dp4 r0.w, v0, c2
dp4 r1.w, v0, c27
dp4 r0.z, v0, c26
dp4 r0.x, v0, c24
dp4 r0.y, v0, c25
mov r1.xyz, r0
mov r0.w, -r0
dp4 oT0.z, r1, c10
dp4 oT0.y, r1, c9
dp4 oT0.x, r1, c8
dp4 oT1.z, r1, c14
dp4 oT1.y, r1, c13
dp4 oT1.x, r1, c12
dp4 oT2.z, r1, c18
dp4 oT2.y, r1, c17
dp4 oT2.x, r1, c16
dp4 oT3.z, r1, c22
dp4 oT3.y, r1, c21
dp4 oT3.x, r1, c20
mov oT4, r0
dp4 oPos.w, v0, c7
dp4 oPos.z, v0, c6
dp4 oPos.y, v0, c5
dp4 oPos.x, v0, c4
"
}

SubProgram "gles " {
Keywords { "SHADOWS_NONATIVE" }
"!!GLES


#ifdef VERTEX

varying highp vec4 xlv_TEXCOORD4;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp vec3 xlv_TEXCOORD0;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 unity_World2Shadow[4];
attribute vec4 _glesVertex;
void main ()
{
  highp vec4 tmpvar_1;
  highp vec4 tmpvar_2;
  tmpvar_2 = (_Object2World * _glesVertex);
  tmpvar_1.xyz = tmpvar_2.xyz;
  tmpvar_1.w = -((glstate_matrix_modelview0 * _glesVertex).z);
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = (unity_World2Shadow[0] * tmpvar_2).xyz;
  xlv_TEXCOORD1 = (unity_World2Shadow[1] * tmpvar_2).xyz;
  xlv_TEXCOORD2 = (unity_World2Shadow[2] * tmpvar_2).xyz;
  xlv_TEXCOORD3 = (unity_World2Shadow[3] * tmpvar_2).xyz;
  xlv_TEXCOORD4 = tmpvar_1;
}



#endif
#ifdef FRAGMENT

varying highp vec4 xlv_TEXCOORD4;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp vec3 xlv_TEXCOORD0;
uniform sampler2D _ShadowMapTexture;
uniform highp vec4 _LightShadowData;
uniform highp vec4 _LightSplitsFar;
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _ProjectionParams;
void main ()
{
  lowp vec4 tmpvar_1;
  highp vec4 res_2;
  highp vec4 zFar_3;
  highp vec4 zNear_4;
  bvec4 tmpvar_5;
  tmpvar_5 = greaterThanEqual (xlv_TEXCOORD4.wwww, _LightSplitsNear);
  lowp vec4 tmpvar_6;
  tmpvar_6 = vec4(tmpvar_5);
  zNear_4 = tmpvar_6;
  bvec4 tmpvar_7;
  tmpvar_7 = lessThan (xlv_TEXCOORD4.wwww, _LightSplitsFar);
  lowp vec4 tmpvar_8;
  tmpvar_8 = vec4(tmpvar_7);
  zFar_3 = tmpvar_8;
  highp vec4 tmpvar_9;
  tmpvar_9 = (zNear_4 * zFar_3);
  highp float tmpvar_10;
  tmpvar_10 = clamp (((xlv_TEXCOORD4.w * _LightShadowData.z) + _LightShadowData.w), 0.0, 1.0);
  highp vec4 tmpvar_11;
  tmpvar_11.w = 1.0;
  tmpvar_11.xyz = ((((xlv_TEXCOORD0 * tmpvar_9.x) + (xlv_TEXCOORD1 * tmpvar_9.y)) + (xlv_TEXCOORD2 * tmpvar_9.z)) + (xlv_TEXCOORD3 * tmpvar_9.w));
  lowp vec4 tmpvar_12;
  tmpvar_12 = texture2D (_ShadowMapTexture, tmpvar_11.xy);
  highp float tmpvar_13;
  if ((tmpvar_12.x < tmpvar_11.z)) {
    tmpvar_13 = _LightShadowData.x;
  } else {
    tmpvar_13 = 1.0;
  };
  res_2.x = clamp ((tmpvar_13 + tmpvar_10), 0.0, 1.0);
  res_2.y = 1.0;
  highp vec2 enc_14;
  highp vec2 tmpvar_15;
  tmpvar_15 = fract((vec2(1.0, 255.0) * (1.0 - (xlv_TEXCOORD4.w * _ProjectionParams.w))));
  enc_14.y = tmpvar_15.y;
  enc_14.x = (tmpvar_15.x - (tmpvar_15.y * 0.00392157));
  res_2.zw = enc_14;
  tmpvar_1 = res_2;
  gl_FragData[0] = tmpvar_1;
}



#endif"
}

SubProgram "glesdesktop " {
Keywords { "SHADOWS_NONATIVE" }
"!!GLES


#ifdef VERTEX

varying highp vec4 xlv_TEXCOORD4;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp vec3 xlv_TEXCOORD0;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 unity_World2Shadow[4];
attribute vec4 _glesVertex;
void main ()
{
  highp vec4 tmpvar_1;
  highp vec4 tmpvar_2;
  tmpvar_2 = (_Object2World * _glesVertex);
  tmpvar_1.xyz = tmpvar_2.xyz;
  tmpvar_1.w = -((glstate_matrix_modelview0 * _glesVertex).z);
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = (unity_World2Shadow[0] * tmpvar_2).xyz;
  xlv_TEXCOORD1 = (unity_World2Shadow[1] * tmpvar_2).xyz;
  xlv_TEXCOORD2 = (unity_World2Shadow[2] * tmpvar_2).xyz;
  xlv_TEXCOORD3 = (unity_World2Shadow[3] * tmpvar_2).xyz;
  xlv_TEXCOORD4 = tmpvar_1;
}



#endif
#ifdef FRAGMENT

varying highp vec4 xlv_TEXCOORD4;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp vec3 xlv_TEXCOORD0;
uniform sampler2D _ShadowMapTexture;
uniform highp vec4 _LightShadowData;
uniform highp vec4 _LightSplitsFar;
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _ProjectionParams;
void main ()
{
  lowp vec4 tmpvar_1;
  highp vec4 res_2;
  highp vec4 zFar_3;
  highp vec4 zNear_4;
  bvec4 tmpvar_5;
  tmpvar_5 = greaterThanEqual (xlv_TEXCOORD4.wwww, _LightSplitsNear);
  lowp vec4 tmpvar_6;
  tmpvar_6 = vec4(tmpvar_5);
  zNear_4 = tmpvar_6;
  bvec4 tmpvar_7;
  tmpvar_7 = lessThan (xlv_TEXCOORD4.wwww, _LightSplitsFar);
  lowp vec4 tmpvar_8;
  tmpvar_8 = vec4(tmpvar_7);
  zFar_3 = tmpvar_8;
  highp vec4 tmpvar_9;
  tmpvar_9 = (zNear_4 * zFar_3);
  highp float tmpvar_10;
  tmpvar_10 = clamp (((xlv_TEXCOORD4.w * _LightShadowData.z) + _LightShadowData.w), 0.0, 1.0);
  highp vec4 tmpvar_11;
  tmpvar_11.w = 1.0;
  tmpvar_11.xyz = ((((xlv_TEXCOORD0 * tmpvar_9.x) + (xlv_TEXCOORD1 * tmpvar_9.y)) + (xlv_TEXCOORD2 * tmpvar_9.z)) + (xlv_TEXCOORD3 * tmpvar_9.w));
  lowp vec4 tmpvar_12;
  tmpvar_12 = texture2D (_ShadowMapTexture, tmpvar_11.xy);
  highp float tmpvar_13;
  if ((tmpvar_12.x < tmpvar_11.z)) {
    tmpvar_13 = _LightShadowData.x;
  } else {
    tmpvar_13 = 1.0;
  };
  res_2.x = clamp ((tmpvar_13 + tmpvar_10), 0.0, 1.0);
  res_2.y = 1.0;
  highp vec2 enc_14;
  highp vec2 tmpvar_15;
  tmpvar_15 = fract((vec2(1.0, 255.0) * (1.0 - (xlv_TEXCOORD4.w * _ProjectionParams.w))));
  enc_14.y = tmpvar_15.y;
  enc_14.x = (tmpvar_15.x - (tmpvar_15.y * 0.00392157));
  res_2.zw = enc_14;
  tmpvar_1 = res_2;
  gl_FragData[0] = tmpvar_1;
}



#endif"
}

SubProgram "flash " {
Keywords { "SHADOWS_NONATIVE" }
Bind "vertex" Vertex
Matrix 0 [glstate_matrix_modelview0]
Matrix 4 [glstate_matrix_mvp]
Matrix 8 [unity_World2Shadow0]
Matrix 12 [unity_World2Shadow1]
Matrix 16 [unity_World2Shadow2]
Matrix 20 [unity_World2Shadow3]
Matrix 24 [_Object2World]
"agal_vs
[bc]
bdaaaaaaaaaaaiacaaaaaaoeaaaaaaaaacaaaaoeabaaaaaa dp4 r0.w, a0, c2
bdaaaaaaabaaaiacaaaaaaoeaaaaaaaablaaaaoeabaaaaaa dp4 r1.w, a0, c27
bdaaaaaaaaaaaeacaaaaaaoeaaaaaaaabkaaaaoeabaaaaaa dp4 r0.z, a0, c26
bdaaaaaaaaaaabacaaaaaaoeaaaaaaaabiaaaaoeabaaaaaa dp4 r0.x, a0, c24
bdaaaaaaaaaaacacaaaaaaoeaaaaaaaabjaaaaoeabaaaaaa dp4 r0.y, a0, c25
aaaaaaaaabaaahacaaaaaakeacaaaaaaaaaaaaaaaaaaaaaa mov r1.xyz, r0.xyzz
bfaaaaaaaaaaaiacaaaaaappacaaaaaaaaaaaaaaaaaaaaaa neg r0.w, r0.w
bdaaaaaaaaaaaeaeabaaaaoeacaaaaaaakaaaaoeabaaaaaa dp4 v0.z, r1, c10
bdaaaaaaaaaaacaeabaaaaoeacaaaaaaajaaaaoeabaaaaaa dp4 v0.y, r1, c9
bdaaaaaaaaaaabaeabaaaaoeacaaaaaaaiaaaaoeabaaaaaa dp4 v0.x, r1, c8
bdaaaaaaabaaaeaeabaaaaoeacaaaaaaaoaaaaoeabaaaaaa dp4 v1.z, r1, c14
bdaaaaaaabaaacaeabaaaaoeacaaaaaaanaaaaoeabaaaaaa dp4 v1.y, r1, c13
bdaaaaaaabaaabaeabaaaaoeacaaaaaaamaaaaoeabaaaaaa dp4 v1.x, r1, c12
bdaaaaaaacaaaeaeabaaaaoeacaaaaaabcaaaaoeabaaaaaa dp4 v2.z, r1, c18
bdaaaaaaacaaacaeabaaaaoeacaaaaaabbaaaaoeabaaaaaa dp4 v2.y, r1, c17
bdaaaaaaacaaabaeabaaaaoeacaaaaaabaaaaaoeabaaaaaa dp4 v2.x, r1, c16
bdaaaaaaadaaaeaeabaaaaoeacaaaaaabgaaaaoeabaaaaaa dp4 v3.z, r1, c22
bdaaaaaaadaaacaeabaaaaoeacaaaaaabfaaaaoeabaaaaaa dp4 v3.y, r1, c21
bdaaaaaaadaaabaeabaaaaoeacaaaaaabeaaaaoeabaaaaaa dp4 v3.x, r1, c20
aaaaaaaaaeaaapaeaaaaaaoeacaaaaaaaaaaaaaaaaaaaaaa mov v4, r0
bdaaaaaaaaaaaiadaaaaaaoeaaaaaaaaahaaaaoeabaaaaaa dp4 o0.w, a0, c7
bdaaaaaaaaaaaeadaaaaaaoeaaaaaaaaagaaaaoeabaaaaaa dp4 o0.z, a0, c6
bdaaaaaaaaaaacadaaaaaaoeaaaaaaaaafaaaaoeabaaaaaa dp4 o0.y, a0, c5
bdaaaaaaaaaaabadaaaaaaoeaaaaaaaaaeaaaaoeabaaaaaa dp4 o0.x, a0, c4
aaaaaaaaaaaaaiaeaaaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov v0.w, c0
aaaaaaaaabaaaiaeaaaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov v1.w, c0
aaaaaaaaacaaaiaeaaaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov v2.w, c0
aaaaaaaaadaaaiaeaaaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov v3.w, c0
"
}

SubProgram "opengl " {
Keywords { "SHADOWS_NATIVE" }
Bind "vertex" Vertex
Matrix 9 [unity_World2Shadow0]
Matrix 13 [unity_World2Shadow1]
Matrix 17 [unity_World2Shadow2]
Matrix 21 [unity_World2Shadow3]
Matrix 25 [_Object2World]
"!!ARBvp1.0
# 24 ALU
PARAM c[29] = { program.local[0],
		state.matrix.modelview[0],
		state.matrix.mvp,
		program.local[9..28] };
TEMP R0;
TEMP R1;
DP4 R0.w, vertex.position, c[3];
DP4 R1.w, vertex.position, c[28];
DP4 R0.z, vertex.position, c[27];
DP4 R0.x, vertex.position, c[25];
DP4 R0.y, vertex.position, c[26];
MOV R1.xyz, R0;
MOV R0.w, -R0;
DP4 result.texcoord[0].z, R1, c[11];
DP4 result.texcoord[0].y, R1, c[10];
DP4 result.texcoord[0].x, R1, c[9];
DP4 result.texcoord[1].z, R1, c[15];
DP4 result.texcoord[1].y, R1, c[14];
DP4 result.texcoord[1].x, R1, c[13];
DP4 result.texcoord[2].z, R1, c[19];
DP4 result.texcoord[2].y, R1, c[18];
DP4 result.texcoord[2].x, R1, c[17];
DP4 result.texcoord[3].z, R1, c[23];
DP4 result.texcoord[3].y, R1, c[22];
DP4 result.texcoord[3].x, R1, c[21];
MOV result.texcoord[4], R0;
DP4 result.position.w, vertex.position, c[8];
DP4 result.position.z, vertex.position, c[7];
DP4 result.position.y, vertex.position, c[6];
DP4 result.position.x, vertex.position, c[5];
END
# 24 instructions, 2 R-regs
"
}

SubProgram "d3d9 " {
Keywords { "SHADOWS_NATIVE" }
Bind "vertex" Vertex
Matrix 0 [glstate_matrix_modelview0]
Matrix 4 [glstate_matrix_mvp]
Matrix 8 [unity_World2Shadow0]
Matrix 12 [unity_World2Shadow1]
Matrix 16 [unity_World2Shadow2]
Matrix 20 [unity_World2Shadow3]
Matrix 24 [_Object2World]
"vs_2_0
; 24 ALU
dcl_position0 v0
dp4 r0.w, v0, c2
dp4 r1.w, v0, c27
dp4 r0.z, v0, c26
dp4 r0.x, v0, c24
dp4 r0.y, v0, c25
mov r1.xyz, r0
mov r0.w, -r0
dp4 oT0.z, r1, c10
dp4 oT0.y, r1, c9
dp4 oT0.x, r1, c8
dp4 oT1.z, r1, c14
dp4 oT1.y, r1, c13
dp4 oT1.x, r1, c12
dp4 oT2.z, r1, c18
dp4 oT2.y, r1, c17
dp4 oT2.x, r1, c16
dp4 oT3.z, r1, c22
dp4 oT3.y, r1, c21
dp4 oT3.x, r1, c20
mov oT4, r0
dp4 oPos.w, v0, c7
dp4 oPos.z, v0, c6
dp4 oPos.y, v0, c5
dp4 oPos.x, v0, c4
"
}

SubProgram "d3d11 " {
Keywords { "SHADOWS_NATIVE" }
Bind "vertex" Vertex
ConstBuffer "UnityShadows" 416 // 384 used size, 8 vars
Matrix 128 [unity_World2Shadow0] 4
Matrix 192 [unity_World2Shadow1] 4
Matrix 256 [unity_World2Shadow2] 4
Matrix 320 [unity_World2Shadow3] 4
ConstBuffer "UnityPerDraw" 336 // 256 used size, 6 vars
Matrix 0 [glstate_matrix_mvp] 4
Matrix 64 [glstate_matrix_modelview0] 4
Matrix 192 [_Object2World] 4
BindCB "UnityShadows" 0
BindCB "UnityPerDraw" 1
// 31 instructions, 2 temp regs, 0 temp arrays:
// ALU 29 float, 0 int, 0 uint
// TEX 0 (0 load, 0 comp, 0 bias, 0 grad)
// FLOW 1 static, 0 dynamic
"vs_4_0
eefiecedmnkcbicaflnkacmllblelhfpmpifpejmabaaaaaaeaagaaaaadaaaaaa
cmaaaaaakaaaaaaafiabaaaaejfdeheogmaaaaaaadaaaaaaaiaaaaaafaaaaaaa
aaaaaaaaaaaaaaaaadaaaaaaaaaaaaaaapapaaaafjaaaaaaaaaaaaaaaaaaaaaa
adaaaaaaabaaaaaaahaaaaaagaaaaaaaaaaaaaaaaaaaaaaaadaaaaaaacaaaaaa
apaaaaaafaepfdejfeejepeoaaeoepfcenebemaafeeffiedepepfceeaaklklkl
epfdeheolaaaaaaaagaaaaaaaiaaaaaajiaaaaaaaaaaaaaaabaaaaaaadaaaaaa
aaaaaaaaapaaaaaakeaaaaaaaaaaaaaaaaaaaaaaadaaaaaaabaaaaaaahaiaaaa
keaaaaaaabaaaaaaaaaaaaaaadaaaaaaacaaaaaaahaiaaaakeaaaaaaacaaaaaa
aaaaaaaaadaaaaaaadaaaaaaahaiaaaakeaaaaaaadaaaaaaaaaaaaaaadaaaaaa
aeaaaaaaahaiaaaakeaaaaaaaeaaaaaaaaaaaaaaadaaaaaaafaaaaaaapaaaaaa
fdfgfpfaepfdejfeejepeoaafeeffiedepepfceeaaklklklfdeieefcoaaeaaaa
eaaaabaadiabaaaafjaaaaaeegiocaaaaaaaaaaabiaaaaaafjaaaaaeegiocaaa
abaaaaaabaaaaaaafpaaaaadpcbabaaaaaaaaaaaghaaaaaepccabaaaaaaaaaaa
abaaaaaagfaaaaadhccabaaaabaaaaaagfaaaaadhccabaaaacaaaaaagfaaaaad
hccabaaaadaaaaaagfaaaaadhccabaaaaeaaaaaagfaaaaadpccabaaaafaaaaaa
giaaaaacacaaaaaadiaaaaaipcaabaaaaaaaaaaafgbfbaaaaaaaaaaaegiocaaa
abaaaaaaabaaaaaadcaaaaakpcaabaaaaaaaaaaaegiocaaaabaaaaaaaaaaaaaa
agbabaaaaaaaaaaaegaobaaaaaaaaaaadcaaaaakpcaabaaaaaaaaaaaegiocaaa
abaaaaaaacaaaaaakgbkbaaaaaaaaaaaegaobaaaaaaaaaaadcaaaaakpccabaaa
aaaaaaaaegiocaaaabaaaaaaadaaaaaapgbpbaaaaaaaaaaaegaobaaaaaaaaaaa
diaaaaaipcaabaaaaaaaaaaafgbfbaaaaaaaaaaaegiocaaaabaaaaaaanaaaaaa
dcaaaaakpcaabaaaaaaaaaaaegiocaaaabaaaaaaamaaaaaaagbabaaaaaaaaaaa
egaobaaaaaaaaaaadcaaaaakpcaabaaaaaaaaaaaegiocaaaabaaaaaaaoaaaaaa
kgbkbaaaaaaaaaaaegaobaaaaaaaaaaadcaaaaakpcaabaaaaaaaaaaaegiocaaa
abaaaaaaapaaaaaapgbpbaaaaaaaaaaaegaobaaaaaaaaaaadiaaaaaihcaabaaa
abaaaaaafgafbaaaaaaaaaaaegiccaaaaaaaaaaaajaaaaaadcaaaaakhcaabaaa
abaaaaaaegiccaaaaaaaaaaaaiaaaaaaagaabaaaaaaaaaaaegacbaaaabaaaaaa
dcaaaaakhcaabaaaabaaaaaaegiccaaaaaaaaaaaakaaaaaakgakbaaaaaaaaaaa
egacbaaaabaaaaaadcaaaaakhccabaaaabaaaaaaegiccaaaaaaaaaaaalaaaaaa
pgapbaaaaaaaaaaaegacbaaaabaaaaaadiaaaaaihcaabaaaabaaaaaafgafbaaa
aaaaaaaaegiccaaaaaaaaaaaanaaaaaadcaaaaakhcaabaaaabaaaaaaegiccaaa
aaaaaaaaamaaaaaaagaabaaaaaaaaaaaegacbaaaabaaaaaadcaaaaakhcaabaaa
abaaaaaaegiccaaaaaaaaaaaaoaaaaaakgakbaaaaaaaaaaaegacbaaaabaaaaaa
dcaaaaakhccabaaaacaaaaaaegiccaaaaaaaaaaaapaaaaaapgapbaaaaaaaaaaa
egacbaaaabaaaaaadiaaaaaihcaabaaaabaaaaaafgafbaaaaaaaaaaaegiccaaa
aaaaaaaabbaaaaaadcaaaaakhcaabaaaabaaaaaaegiccaaaaaaaaaaabaaaaaaa
agaabaaaaaaaaaaaegacbaaaabaaaaaadcaaaaakhcaabaaaabaaaaaaegiccaaa
aaaaaaaabcaaaaaakgakbaaaaaaaaaaaegacbaaaabaaaaaadcaaaaakhccabaaa
adaaaaaaegiccaaaaaaaaaaabdaaaaaapgapbaaaaaaaaaaaegacbaaaabaaaaaa
diaaaaaihcaabaaaabaaaaaafgafbaaaaaaaaaaaegiccaaaaaaaaaaabfaaaaaa
dcaaaaakhcaabaaaabaaaaaaegiccaaaaaaaaaaabeaaaaaaagaabaaaaaaaaaaa
egacbaaaabaaaaaadcaaaaakhcaabaaaabaaaaaaegiccaaaaaaaaaaabgaaaaaa
kgakbaaaaaaaaaaaegacbaaaabaaaaaadcaaaaakhccabaaaaeaaaaaaegiccaaa
aaaaaaaabhaaaaaapgapbaaaaaaaaaaaegacbaaaabaaaaaadgaaaaafhccabaaa
afaaaaaaegacbaaaaaaaaaaadiaaaaaibcaabaaaaaaaaaaabkbabaaaaaaaaaaa
ckiacaaaabaaaaaaafaaaaaadcaaaaakbcaabaaaaaaaaaaackiacaaaabaaaaaa
aeaaaaaaakbabaaaaaaaaaaaakaabaaaaaaaaaaadcaaaaakbcaabaaaaaaaaaaa
ckiacaaaabaaaaaaagaaaaaackbabaaaaaaaaaaaakaabaaaaaaaaaaadcaaaaak
bcaabaaaaaaaaaaackiacaaaabaaaaaaahaaaaaadkbabaaaaaaaaaaaakaabaaa
aaaaaaaadgaaaaagiccabaaaafaaaaaaakaabaiaebaaaaaaaaaaaaaadoaaaaab
"
}

SubProgram "gles " {
Keywords { "SHADOWS_NATIVE" }
"!!GLES


#ifdef VERTEX

#extension GL_EXT_shadow_samplers : enable
varying highp vec4 xlv_TEXCOORD4;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp vec3 xlv_TEXCOORD0;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 unity_World2Shadow[4];
attribute vec4 _glesVertex;
void main ()
{
  highp vec4 tmpvar_1;
  highp vec4 tmpvar_2;
  tmpvar_2 = (_Object2World * _glesVertex);
  tmpvar_1.xyz = tmpvar_2.xyz;
  tmpvar_1.w = -((glstate_matrix_modelview0 * _glesVertex).z);
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = (unity_World2Shadow[0] * tmpvar_2).xyz;
  xlv_TEXCOORD1 = (unity_World2Shadow[1] * tmpvar_2).xyz;
  xlv_TEXCOORD2 = (unity_World2Shadow[2] * tmpvar_2).xyz;
  xlv_TEXCOORD3 = (unity_World2Shadow[3] * tmpvar_2).xyz;
  xlv_TEXCOORD4 = tmpvar_1;
}



#endif
#ifdef FRAGMENT

#extension GL_EXT_shadow_samplers : enable
varying highp vec4 xlv_TEXCOORD4;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp vec3 xlv_TEXCOORD0;
uniform lowp sampler2DShadow _ShadowMapTexture;
uniform highp vec4 _LightShadowData;
uniform highp vec4 _LightSplitsFar;
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _ProjectionParams;
void main ()
{
  lowp vec4 tmpvar_1;
  highp vec4 res_2;
  mediump float shadow_3;
  highp vec4 zFar_4;
  highp vec4 zNear_5;
  bvec4 tmpvar_6;
  tmpvar_6 = greaterThanEqual (xlv_TEXCOORD4.wwww, _LightSplitsNear);
  lowp vec4 tmpvar_7;
  tmpvar_7 = vec4(tmpvar_6);
  zNear_5 = tmpvar_7;
  bvec4 tmpvar_8;
  tmpvar_8 = lessThan (xlv_TEXCOORD4.wwww, _LightSplitsFar);
  lowp vec4 tmpvar_9;
  tmpvar_9 = vec4(tmpvar_8);
  zFar_4 = tmpvar_9;
  highp vec4 tmpvar_10;
  tmpvar_10 = (zNear_5 * zFar_4);
  highp vec4 tmpvar_11;
  tmpvar_11.w = 1.0;
  tmpvar_11.xyz = ((((xlv_TEXCOORD0 * tmpvar_10.x) + (xlv_TEXCOORD1 * tmpvar_10.y)) + (xlv_TEXCOORD2 * tmpvar_10.z)) + (xlv_TEXCOORD3 * tmpvar_10.w));
  lowp float tmpvar_12;
  tmpvar_12 = shadow2DEXT (_ShadowMapTexture, tmpvar_11.xyz);
  shadow_3 = tmpvar_12;
  highp float tmpvar_13;
  tmpvar_13 = (_LightShadowData.x + (shadow_3 * (1.0 - _LightShadowData.x)));
  shadow_3 = tmpvar_13;
  res_2.x = clamp ((shadow_3 + clamp (((xlv_TEXCOORD4.w * _LightShadowData.z) + _LightShadowData.w), 0.0, 1.0)), 0.0, 1.0);
  res_2.y = 1.0;
  highp vec2 enc_14;
  highp vec2 tmpvar_15;
  tmpvar_15 = fract((vec2(1.0, 255.0) * (1.0 - (xlv_TEXCOORD4.w * _ProjectionParams.w))));
  enc_14.y = tmpvar_15.y;
  enc_14.x = (tmpvar_15.x - (tmpvar_15.y * 0.00392157));
  res_2.zw = enc_14;
  tmpvar_1 = res_2;
  gl_FragData[0] = tmpvar_1;
}



#endif"
}

SubProgram "d3d11_9x " {
Keywords { "SHADOWS_NATIVE" }
Bind "vertex" Vertex
ConstBuffer "UnityShadows" 416 // 384 used size, 8 vars
Matrix 128 [unity_World2Shadow0] 4
Matrix 192 [unity_World2Shadow1] 4
Matrix 256 [unity_World2Shadow2] 4
Matrix 320 [unity_World2Shadow3] 4
ConstBuffer "UnityPerDraw" 336 // 256 used size, 6 vars
Matrix 0 [glstate_matrix_mvp] 4
Matrix 64 [glstate_matrix_modelview0] 4
Matrix 192 [_Object2World] 4
BindCB "UnityShadows" 0
BindCB "UnityPerDraw" 1
// 31 instructions, 2 temp regs, 0 temp arrays:
// ALU 29 float, 0 int, 0 uint
// TEX 0 (0 load, 0 comp, 0 bias, 0 grad)
// FLOW 1 static, 0 dynamic
"vs_4_0_level_9_1
eefieceddcancklelhchleoiglklmccbijbiodfiabaaaaaapiaiaaaaaeaaaaaa
daaaaaaaoeacaaaammahaaaaeaaiaaaaebgpgodjkmacaaaakmacaaaaaaacpopp
gaacaaaaemaaaaaaadaaceaaaaaaeiaaaaaaeiaaaaaaceaaabaaeiaaaaaaaiaa
baaaabaaaaaaaaaaabaaaaaaaiaabbaaaaaaaaaaabaaamaaaeaabjaaaaaaaaaa
aaaaaaaaaaacpoppbpaaaaacafaaaaiaaaaaapjaafaaaaadaaaaabiaaaaaffja
bgaakkkaaeaaaaaeaaaaabiabfaakkkaaaaaaajaaaaaaaiaaeaaaaaeaaaaabia
bhaakkkaaaaakkjaaaaaaaiaaeaaaaaeaaaaabiabiaakkkaaaaappjaaaaaaaia
abaaaaacaeaaaioaaaaaaaibafaaaaadaaaaapiaaaaaffjabkaaoekaaeaaaaae
aaaaapiabjaaoekaaaaaaajaaaaaoeiaaeaaaaaeaaaaapiablaaoekaaaaakkja
aaaaoeiaaeaaaaaeaaaaapiabmaaoekaaaaappjaaaaaoeiaafaaaaadabaaahia
aaaaffiaacaaoekaaeaaaaaeabaaahiaabaaoekaaaaaaaiaabaaoeiaaeaaaaae
abaaahiaadaaoekaaaaakkiaabaaoeiaaeaaaaaeaaaaahoaaeaaoekaaaaappia
abaaoeiaafaaaaadabaaahiaaaaaffiaagaaoekaaeaaaaaeabaaahiaafaaoeka
aaaaaaiaabaaoeiaaeaaaaaeabaaahiaahaaoekaaaaakkiaabaaoeiaaeaaaaae
abaaahoaaiaaoekaaaaappiaabaaoeiaafaaaaadabaaahiaaaaaffiaakaaoeka
aeaaaaaeabaaahiaajaaoekaaaaaaaiaabaaoeiaaeaaaaaeabaaahiaalaaoeka
aaaakkiaabaaoeiaaeaaaaaeacaaahoaamaaoekaaaaappiaabaaoeiaafaaaaad
abaaahiaaaaaffiaaoaaoekaaeaaaaaeabaaahiaanaaoekaaaaaaaiaabaaoeia
aeaaaaaeabaaahiaapaaoekaaaaakkiaabaaoeiaaeaaaaaeadaaahoabaaaoeka
aaaappiaabaaoeiaabaaaaacaeaaahoaaaaaoeiaafaaaaadaaaaapiaaaaaffja
bcaaoekaaeaaaaaeaaaaapiabbaaoekaaaaaaajaaaaaoeiaaeaaaaaeaaaaapia
bdaaoekaaaaakkjaaaaaoeiaaeaaaaaeaaaaapiabeaaoekaaaaappjaaaaaoeia
aeaaaaaeaaaaadmaaaaappiaaaaaoekaaaaaoeiaabaaaaacaaaaammaaaaaoeia
ppppaaaafdeieefcoaaeaaaaeaaaabaadiabaaaafjaaaaaeegiocaaaaaaaaaaa
biaaaaaafjaaaaaeegiocaaaabaaaaaabaaaaaaafpaaaaadpcbabaaaaaaaaaaa
ghaaaaaepccabaaaaaaaaaaaabaaaaaagfaaaaadhccabaaaabaaaaaagfaaaaad
hccabaaaacaaaaaagfaaaaadhccabaaaadaaaaaagfaaaaadhccabaaaaeaaaaaa
gfaaaaadpccabaaaafaaaaaagiaaaaacacaaaaaadiaaaaaipcaabaaaaaaaaaaa
fgbfbaaaaaaaaaaaegiocaaaabaaaaaaabaaaaaadcaaaaakpcaabaaaaaaaaaaa
egiocaaaabaaaaaaaaaaaaaaagbabaaaaaaaaaaaegaobaaaaaaaaaaadcaaaaak
pcaabaaaaaaaaaaaegiocaaaabaaaaaaacaaaaaakgbkbaaaaaaaaaaaegaobaaa
aaaaaaaadcaaaaakpccabaaaaaaaaaaaegiocaaaabaaaaaaadaaaaaapgbpbaaa
aaaaaaaaegaobaaaaaaaaaaadiaaaaaipcaabaaaaaaaaaaafgbfbaaaaaaaaaaa
egiocaaaabaaaaaaanaaaaaadcaaaaakpcaabaaaaaaaaaaaegiocaaaabaaaaaa
amaaaaaaagbabaaaaaaaaaaaegaobaaaaaaaaaaadcaaaaakpcaabaaaaaaaaaaa
egiocaaaabaaaaaaaoaaaaaakgbkbaaaaaaaaaaaegaobaaaaaaaaaaadcaaaaak
pcaabaaaaaaaaaaaegiocaaaabaaaaaaapaaaaaapgbpbaaaaaaaaaaaegaobaaa
aaaaaaaadiaaaaaihcaabaaaabaaaaaafgafbaaaaaaaaaaaegiccaaaaaaaaaaa
ajaaaaaadcaaaaakhcaabaaaabaaaaaaegiccaaaaaaaaaaaaiaaaaaaagaabaaa
aaaaaaaaegacbaaaabaaaaaadcaaaaakhcaabaaaabaaaaaaegiccaaaaaaaaaaa
akaaaaaakgakbaaaaaaaaaaaegacbaaaabaaaaaadcaaaaakhccabaaaabaaaaaa
egiccaaaaaaaaaaaalaaaaaapgapbaaaaaaaaaaaegacbaaaabaaaaaadiaaaaai
hcaabaaaabaaaaaafgafbaaaaaaaaaaaegiccaaaaaaaaaaaanaaaaaadcaaaaak
hcaabaaaabaaaaaaegiccaaaaaaaaaaaamaaaaaaagaabaaaaaaaaaaaegacbaaa
abaaaaaadcaaaaakhcaabaaaabaaaaaaegiccaaaaaaaaaaaaoaaaaaakgakbaaa
aaaaaaaaegacbaaaabaaaaaadcaaaaakhccabaaaacaaaaaaegiccaaaaaaaaaaa
apaaaaaapgapbaaaaaaaaaaaegacbaaaabaaaaaadiaaaaaihcaabaaaabaaaaaa
fgafbaaaaaaaaaaaegiccaaaaaaaaaaabbaaaaaadcaaaaakhcaabaaaabaaaaaa
egiccaaaaaaaaaaabaaaaaaaagaabaaaaaaaaaaaegacbaaaabaaaaaadcaaaaak
hcaabaaaabaaaaaaegiccaaaaaaaaaaabcaaaaaakgakbaaaaaaaaaaaegacbaaa
abaaaaaadcaaaaakhccabaaaadaaaaaaegiccaaaaaaaaaaabdaaaaaapgapbaaa
aaaaaaaaegacbaaaabaaaaaadiaaaaaihcaabaaaabaaaaaafgafbaaaaaaaaaaa
egiccaaaaaaaaaaabfaaaaaadcaaaaakhcaabaaaabaaaaaaegiccaaaaaaaaaaa
beaaaaaaagaabaaaaaaaaaaaegacbaaaabaaaaaadcaaaaakhcaabaaaabaaaaaa
egiccaaaaaaaaaaabgaaaaaakgakbaaaaaaaaaaaegacbaaaabaaaaaadcaaaaak
hccabaaaaeaaaaaaegiccaaaaaaaaaaabhaaaaaapgapbaaaaaaaaaaaegacbaaa
abaaaaaadgaaaaafhccabaaaafaaaaaaegacbaaaaaaaaaaadiaaaaaibcaabaaa
aaaaaaaabkbabaaaaaaaaaaackiacaaaabaaaaaaafaaaaaadcaaaaakbcaabaaa
aaaaaaaackiacaaaabaaaaaaaeaaaaaaakbabaaaaaaaaaaaakaabaaaaaaaaaaa
dcaaaaakbcaabaaaaaaaaaaackiacaaaabaaaaaaagaaaaaackbabaaaaaaaaaaa
akaabaaaaaaaaaaadcaaaaakbcaabaaaaaaaaaaackiacaaaabaaaaaaahaaaaaa
dkbabaaaaaaaaaaaakaabaaaaaaaaaaadgaaaaagiccabaaaafaaaaaaakaabaia
ebaaaaaaaaaaaaaadoaaaaabejfdeheogmaaaaaaadaaaaaaaiaaaaaafaaaaaaa
aaaaaaaaaaaaaaaaadaaaaaaaaaaaaaaapapaaaafjaaaaaaaaaaaaaaaaaaaaaa
adaaaaaaabaaaaaaahaaaaaagaaaaaaaaaaaaaaaaaaaaaaaadaaaaaaacaaaaaa
apaaaaaafaepfdejfeejepeoaaeoepfcenebemaafeeffiedepepfceeaaklklkl
epfdeheolaaaaaaaagaaaaaaaiaaaaaajiaaaaaaaaaaaaaaabaaaaaaadaaaaaa
aaaaaaaaapaaaaaakeaaaaaaaaaaaaaaaaaaaaaaadaaaaaaabaaaaaaahaiaaaa
keaaaaaaabaaaaaaaaaaaaaaadaaaaaaacaaaaaaahaiaaaakeaaaaaaacaaaaaa
aaaaaaaaadaaaaaaadaaaaaaahaiaaaakeaaaaaaadaaaaaaaaaaaaaaadaaaaaa
aeaaaaaaahaiaaaakeaaaaaaaeaaaaaaaaaaaaaaadaaaaaaafaaaaaaapaaaaaa
fdfgfpfaepfdejfeejepeoaafeeffiedepepfceeaaklklkl"
}

SubProgram "gles3 " {
Keywords { "SHADOWS_NATIVE" }
"!!GLES3#version 300 es


#ifdef VERTEX

#define gl_Vertex _glesVertex
in vec4 _glesVertex;
#define gl_Normal (normalize(_glesNormal))
in vec3 _glesNormal;
#define gl_MultiTexCoord0 _glesMultiTexCoord0
in vec4 _glesMultiTexCoord0;

#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 316
struct v2f {
    highp vec4 pos;
    highp vec3 _ShadowCoord0;
    highp vec3 _ShadowCoord1;
    highp vec3 _ShadowCoord2;
    highp vec3 _ShadowCoord3;
    highp vec4 _WorldPosViewZ;
};
#line 52
struct appdata_base {
    highp vec4 vertex;
    highp vec3 normal;
    highp vec4 texcoord;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform highp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform lowp sampler2DShadow _ShadowMapTexture;
#line 326
#line 339
uniform lowp vec4 _Color;
#line 326
v2f vert( in appdata_base v ) {
    v2f o;
    o.pos = (glstate_matrix_mvp * v.vertex);
    #line 330
    highp vec4 wpos = (_Object2World * v.vertex);
    o._WorldPosViewZ.xyz = vec3( wpos);
    o._WorldPosViewZ.w = (-(glstate_matrix_modelview0 * v.vertex).z);
    o._ShadowCoord0 = (unity_World2Shadow[0] * wpos).xyz;
    #line 334
    o._ShadowCoord1 = (unity_World2Shadow[1] * wpos).xyz;
    o._ShadowCoord2 = (unity_World2Shadow[2] * wpos).xyz;
    o._ShadowCoord3 = (unity_World2Shadow[3] * wpos).xyz;
    return o;
}
out highp vec3 xlv_TEXCOORD0;
out highp vec3 xlv_TEXCOORD1;
out highp vec3 xlv_TEXCOORD2;
out highp vec3 xlv_TEXCOORD3;
out highp vec4 xlv_TEXCOORD4;
void main() {
    v2f xl_retval;
    appdata_base xlt_v;
    xlt_v.vertex = vec4(gl_Vertex);
    xlt_v.normal = vec3(gl_Normal);
    xlt_v.texcoord = vec4(gl_MultiTexCoord0);
    xl_retval = vert( xlt_v);
    gl_Position = vec4(xl_retval.pos);
    xlv_TEXCOORD0 = vec3(xl_retval._ShadowCoord0);
    xlv_TEXCOORD1 = vec3(xl_retval._ShadowCoord1);
    xlv_TEXCOORD2 = vec3(xl_retval._ShadowCoord2);
    xlv_TEXCOORD3 = vec3(xl_retval._ShadowCoord3);
    xlv_TEXCOORD4 = vec4(xl_retval._WorldPosViewZ);
}


#endif
#ifdef FRAGMENT

#define gl_FragData _glesFragData
layout(location = 0) out mediump vec4 _glesFragData[4];
float xll_shadow2D(mediump sampler2DShadow s, vec3 coord) { return texture (s, coord); }
float xll_saturate_f( float x) {
  return clamp( x, 0.0, 1.0);
}
vec2 xll_saturate_vf2( vec2 x) {
  return clamp( x, 0.0, 1.0);
}
vec3 xll_saturate_vf3( vec3 x) {
  return clamp( x, 0.0, 1.0);
}
vec4 xll_saturate_vf4( vec4 x) {
  return clamp( x, 0.0, 1.0);
}
mat2 xll_saturate_mf2x2(mat2 m) {
  return mat2( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0));
}
mat3 xll_saturate_mf3x3(mat3 m) {
  return mat3( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0));
}
mat4 xll_saturate_mf4x4(mat4 m) {
  return mat4( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0), clamp(m[3], 0.0, 1.0));
}
#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 316
struct v2f {
    highp vec4 pos;
    highp vec3 _ShadowCoord0;
    highp vec3 _ShadowCoord1;
    highp vec3 _ShadowCoord2;
    highp vec3 _ShadowCoord3;
    highp vec4 _WorldPosViewZ;
};
#line 52
struct appdata_base {
    highp vec4 vertex;
    highp vec3 normal;
    highp vec4 texcoord;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform highp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform lowp sampler2DShadow _ShadowMapTexture;
#line 326
#line 339
uniform lowp vec4 _Color;
#line 220
highp vec2 EncodeFloatRG( in highp float v ) {
    highp vec2 kEncodeMul = vec2( 1.0, 255.0);
    highp float kEncodeBit = 0.00392157;
    #line 224
    highp vec2 enc = (kEncodeMul * v);
    enc = fract(enc);
    enc.x -= (enc.y * kEncodeBit);
    return enc;
}
#line 340
lowp vec4 frag( in v2f i ) {
    highp vec4 viewZ = vec4( i._WorldPosViewZ.w);
    #line 343
    highp vec4 zNear = vec4(greaterThanEqual( viewZ, _LightSplitsNear));
    highp vec4 zFar = vec4(lessThan( viewZ, _LightSplitsFar));
    highp vec4 cascadeWeights = (zNear * zFar);
    highp float shadowFade = xll_saturate_f(((i._WorldPosViewZ.w * _LightShadowData.z) + _LightShadowData.w));
    #line 347
    highp vec4 coord = vec4( ((((i._ShadowCoord0 * cascadeWeights.x) + (i._ShadowCoord1 * cascadeWeights.y)) + (i._ShadowCoord2 * cascadeWeights.z)) + (i._ShadowCoord3 * cascadeWeights.w)), 1.0);
    mediump float shadow = xll_shadow2D( _ShadowMapTexture, coord.xyz);
    shadow = (_LightShadowData.x + (shadow * (1.0 - _LightShadowData.x)));
    highp vec4 res;
    #line 351
    res.x = xll_saturate_f((shadow + shadowFade));
    res.y = 1.0;
    res.zw = EncodeFloatRG( (1.0 - (i._WorldPosViewZ.w * _ProjectionParams.w)));
    return res;
}
in highp vec3 xlv_TEXCOORD0;
in highp vec3 xlv_TEXCOORD1;
in highp vec3 xlv_TEXCOORD2;
in highp vec3 xlv_TEXCOORD3;
in highp vec4 xlv_TEXCOORD4;
void main() {
    lowp vec4 xl_retval;
    v2f xlt_i;
    xlt_i.pos = vec4(0.0);
    xlt_i._ShadowCoord0 = vec3(xlv_TEXCOORD0);
    xlt_i._ShadowCoord1 = vec3(xlv_TEXCOORD1);
    xlt_i._ShadowCoord2 = vec3(xlv_TEXCOORD2);
    xlt_i._ShadowCoord3 = vec3(xlv_TEXCOORD3);
    xlt_i._WorldPosViewZ = vec4(xlv_TEXCOORD4);
    xl_retval = frag( xlt_i);
    gl_FragData[0] = vec4(xl_retval);
}


#endif"
}

SubProgram "opengl " {
Keywords { "SHADOWS_NONATIVE" "SHADOWS_SPLIT_SPHERES" }
Bind "vertex" Vertex
Matrix 9 [unity_World2Shadow0]
Matrix 13 [unity_World2Shadow1]
Matrix 17 [unity_World2Shadow2]
Matrix 21 [unity_World2Shadow3]
Matrix 25 [_Object2World]
"!!ARBvp1.0
# 24 ALU
PARAM c[29] = { program.local[0],
		state.matrix.modelview[0],
		state.matrix.mvp,
		program.local[9..28] };
TEMP R0;
TEMP R1;
DP4 R0.w, vertex.position, c[3];
DP4 R1.w, vertex.position, c[28];
DP4 R0.z, vertex.position, c[27];
DP4 R0.x, vertex.position, c[25];
DP4 R0.y, vertex.position, c[26];
MOV R1.xyz, R0;
MOV R0.w, -R0;
DP4 result.texcoord[0].z, R1, c[11];
DP4 result.texcoord[0].y, R1, c[10];
DP4 result.texcoord[0].x, R1, c[9];
DP4 result.texcoord[1].z, R1, c[15];
DP4 result.texcoord[1].y, R1, c[14];
DP4 result.texcoord[1].x, R1, c[13];
DP4 result.texcoord[2].z, R1, c[19];
DP4 result.texcoord[2].y, R1, c[18];
DP4 result.texcoord[2].x, R1, c[17];
DP4 result.texcoord[3].z, R1, c[23];
DP4 result.texcoord[3].y, R1, c[22];
DP4 result.texcoord[3].x, R1, c[21];
MOV result.texcoord[4], R0;
DP4 result.position.w, vertex.position, c[8];
DP4 result.position.z, vertex.position, c[7];
DP4 result.position.y, vertex.position, c[6];
DP4 result.position.x, vertex.position, c[5];
END
# 24 instructions, 2 R-regs
"
}

SubProgram "d3d9 " {
Keywords { "SHADOWS_NONATIVE" "SHADOWS_SPLIT_SPHERES" }
Bind "vertex" Vertex
Matrix 0 [glstate_matrix_modelview0]
Matrix 4 [glstate_matrix_mvp]
Matrix 8 [unity_World2Shadow0]
Matrix 12 [unity_World2Shadow1]
Matrix 16 [unity_World2Shadow2]
Matrix 20 [unity_World2Shadow3]
Matrix 24 [_Object2World]
"vs_2_0
; 24 ALU
dcl_position0 v0
dp4 r0.w, v0, c2
dp4 r1.w, v0, c27
dp4 r0.z, v0, c26
dp4 r0.x, v0, c24
dp4 r0.y, v0, c25
mov r1.xyz, r0
mov r0.w, -r0
dp4 oT0.z, r1, c10
dp4 oT0.y, r1, c9
dp4 oT0.x, r1, c8
dp4 oT1.z, r1, c14
dp4 oT1.y, r1, c13
dp4 oT1.x, r1, c12
dp4 oT2.z, r1, c18
dp4 oT2.y, r1, c17
dp4 oT2.x, r1, c16
dp4 oT3.z, r1, c22
dp4 oT3.y, r1, c21
dp4 oT3.x, r1, c20
mov oT4, r0
dp4 oPos.w, v0, c7
dp4 oPos.z, v0, c6
dp4 oPos.y, v0, c5
dp4 oPos.x, v0, c4
"
}

SubProgram "gles " {
Keywords { "SHADOWS_NONATIVE" "SHADOWS_SPLIT_SPHERES" }
"!!GLES


#ifdef VERTEX

varying highp vec4 xlv_TEXCOORD4;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp vec3 xlv_TEXCOORD0;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 unity_World2Shadow[4];
attribute vec4 _glesVertex;
void main ()
{
  highp vec4 tmpvar_1;
  highp vec4 tmpvar_2;
  tmpvar_2 = (_Object2World * _glesVertex);
  tmpvar_1.xyz = tmpvar_2.xyz;
  tmpvar_1.w = -((glstate_matrix_modelview0 * _glesVertex).z);
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = (unity_World2Shadow[0] * tmpvar_2).xyz;
  xlv_TEXCOORD1 = (unity_World2Shadow[1] * tmpvar_2).xyz;
  xlv_TEXCOORD2 = (unity_World2Shadow[2] * tmpvar_2).xyz;
  xlv_TEXCOORD3 = (unity_World2Shadow[3] * tmpvar_2).xyz;
  xlv_TEXCOORD4 = tmpvar_1;
}



#endif
#ifdef FRAGMENT

varying highp vec4 xlv_TEXCOORD4;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp vec3 xlv_TEXCOORD0;
uniform sampler2D _ShadowMapTexture;
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp vec4 _LightShadowData;
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 _ProjectionParams;
void main ()
{
  lowp vec4 tmpvar_1;
  highp vec4 res_2;
  highp vec4 cascadeWeights_3;
  highp vec3 tmpvar_4;
  tmpvar_4 = (xlv_TEXCOORD4.xyz - unity_ShadowSplitSpheres[0].xyz);
  highp vec3 tmpvar_5;
  tmpvar_5 = (xlv_TEXCOORD4.xyz - unity_ShadowSplitSpheres[1].xyz);
  highp vec3 tmpvar_6;
  tmpvar_6 = (xlv_TEXCOORD4.xyz - unity_ShadowSplitSpheres[2].xyz);
  highp vec3 tmpvar_7;
  tmpvar_7 = (xlv_TEXCOORD4.xyz - unity_ShadowSplitSpheres[3].xyz);
  highp vec4 tmpvar_8;
  tmpvar_8.x = dot (tmpvar_4, tmpvar_4);
  tmpvar_8.y = dot (tmpvar_5, tmpvar_5);
  tmpvar_8.z = dot (tmpvar_6, tmpvar_6);
  tmpvar_8.w = dot (tmpvar_7, tmpvar_7);
  bvec4 tmpvar_9;
  tmpvar_9 = lessThan (tmpvar_8, unity_ShadowSplitSqRadii);
  lowp vec4 tmpvar_10;
  tmpvar_10 = vec4(tmpvar_9);
  cascadeWeights_3 = tmpvar_10;
  cascadeWeights_3.yzw = clamp ((cascadeWeights_3.yzw - cascadeWeights_3.xyz), 0.0, 1.0);
  highp vec3 p_11;
  p_11 = (xlv_TEXCOORD4.xyz - unity_ShadowFadeCenterAndType.xyz);
  highp float tmpvar_12;
  tmpvar_12 = clamp (((sqrt(dot (p_11, p_11)) * _LightShadowData.z) + _LightShadowData.w), 0.0, 1.0);
  highp vec4 tmpvar_13;
  tmpvar_13.w = 1.0;
  tmpvar_13.xyz = ((((xlv_TEXCOORD0 * cascadeWeights_3.x) + (xlv_TEXCOORD1 * cascadeWeights_3.y)) + (xlv_TEXCOORD2 * cascadeWeights_3.z)) + (xlv_TEXCOORD3 * cascadeWeights_3.w));
  lowp vec4 tmpvar_14;
  tmpvar_14 = texture2D (_ShadowMapTexture, tmpvar_13.xy);
  highp float tmpvar_15;
  if ((tmpvar_14.x < tmpvar_13.z)) {
    tmpvar_15 = _LightShadowData.x;
  } else {
    tmpvar_15 = 1.0;
  };
  res_2.x = clamp ((tmpvar_15 + tmpvar_12), 0.0, 1.0);
  res_2.y = 1.0;
  highp vec2 enc_16;
  highp vec2 tmpvar_17;
  tmpvar_17 = fract((vec2(1.0, 255.0) * (1.0 - (xlv_TEXCOORD4.w * _ProjectionParams.w))));
  enc_16.y = tmpvar_17.y;
  enc_16.x = (tmpvar_17.x - (tmpvar_17.y * 0.00392157));
  res_2.zw = enc_16;
  tmpvar_1 = res_2;
  gl_FragData[0] = tmpvar_1;
}



#endif"
}

SubProgram "glesdesktop " {
Keywords { "SHADOWS_NONATIVE" "SHADOWS_SPLIT_SPHERES" }
"!!GLES


#ifdef VERTEX

varying highp vec4 xlv_TEXCOORD4;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp vec3 xlv_TEXCOORD0;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 unity_World2Shadow[4];
attribute vec4 _glesVertex;
void main ()
{
  highp vec4 tmpvar_1;
  highp vec4 tmpvar_2;
  tmpvar_2 = (_Object2World * _glesVertex);
  tmpvar_1.xyz = tmpvar_2.xyz;
  tmpvar_1.w = -((glstate_matrix_modelview0 * _glesVertex).z);
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = (unity_World2Shadow[0] * tmpvar_2).xyz;
  xlv_TEXCOORD1 = (unity_World2Shadow[1] * tmpvar_2).xyz;
  xlv_TEXCOORD2 = (unity_World2Shadow[2] * tmpvar_2).xyz;
  xlv_TEXCOORD3 = (unity_World2Shadow[3] * tmpvar_2).xyz;
  xlv_TEXCOORD4 = tmpvar_1;
}



#endif
#ifdef FRAGMENT

varying highp vec4 xlv_TEXCOORD4;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp vec3 xlv_TEXCOORD0;
uniform sampler2D _ShadowMapTexture;
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp vec4 _LightShadowData;
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 _ProjectionParams;
void main ()
{
  lowp vec4 tmpvar_1;
  highp vec4 res_2;
  highp vec4 cascadeWeights_3;
  highp vec3 tmpvar_4;
  tmpvar_4 = (xlv_TEXCOORD4.xyz - unity_ShadowSplitSpheres[0].xyz);
  highp vec3 tmpvar_5;
  tmpvar_5 = (xlv_TEXCOORD4.xyz - unity_ShadowSplitSpheres[1].xyz);
  highp vec3 tmpvar_6;
  tmpvar_6 = (xlv_TEXCOORD4.xyz - unity_ShadowSplitSpheres[2].xyz);
  highp vec3 tmpvar_7;
  tmpvar_7 = (xlv_TEXCOORD4.xyz - unity_ShadowSplitSpheres[3].xyz);
  highp vec4 tmpvar_8;
  tmpvar_8.x = dot (tmpvar_4, tmpvar_4);
  tmpvar_8.y = dot (tmpvar_5, tmpvar_5);
  tmpvar_8.z = dot (tmpvar_6, tmpvar_6);
  tmpvar_8.w = dot (tmpvar_7, tmpvar_7);
  bvec4 tmpvar_9;
  tmpvar_9 = lessThan (tmpvar_8, unity_ShadowSplitSqRadii);
  lowp vec4 tmpvar_10;
  tmpvar_10 = vec4(tmpvar_9);
  cascadeWeights_3 = tmpvar_10;
  cascadeWeights_3.yzw = clamp ((cascadeWeights_3.yzw - cascadeWeights_3.xyz), 0.0, 1.0);
  highp vec3 p_11;
  p_11 = (xlv_TEXCOORD4.xyz - unity_ShadowFadeCenterAndType.xyz);
  highp float tmpvar_12;
  tmpvar_12 = clamp (((sqrt(dot (p_11, p_11)) * _LightShadowData.z) + _LightShadowData.w), 0.0, 1.0);
  highp vec4 tmpvar_13;
  tmpvar_13.w = 1.0;
  tmpvar_13.xyz = ((((xlv_TEXCOORD0 * cascadeWeights_3.x) + (xlv_TEXCOORD1 * cascadeWeights_3.y)) + (xlv_TEXCOORD2 * cascadeWeights_3.z)) + (xlv_TEXCOORD3 * cascadeWeights_3.w));
  lowp vec4 tmpvar_14;
  tmpvar_14 = texture2D (_ShadowMapTexture, tmpvar_13.xy);
  highp float tmpvar_15;
  if ((tmpvar_14.x < tmpvar_13.z)) {
    tmpvar_15 = _LightShadowData.x;
  } else {
    tmpvar_15 = 1.0;
  };
  res_2.x = clamp ((tmpvar_15 + tmpvar_12), 0.0, 1.0);
  res_2.y = 1.0;
  highp vec2 enc_16;
  highp vec2 tmpvar_17;
  tmpvar_17 = fract((vec2(1.0, 255.0) * (1.0 - (xlv_TEXCOORD4.w * _ProjectionParams.w))));
  enc_16.y = tmpvar_17.y;
  enc_16.x = (tmpvar_17.x - (tmpvar_17.y * 0.00392157));
  res_2.zw = enc_16;
  tmpvar_1 = res_2;
  gl_FragData[0] = tmpvar_1;
}



#endif"
}

SubProgram "flash " {
Keywords { "SHADOWS_NONATIVE" "SHADOWS_SPLIT_SPHERES" }
Bind "vertex" Vertex
Matrix 0 [glstate_matrix_modelview0]
Matrix 4 [glstate_matrix_mvp]
Matrix 8 [unity_World2Shadow0]
Matrix 12 [unity_World2Shadow1]
Matrix 16 [unity_World2Shadow2]
Matrix 20 [unity_World2Shadow3]
Matrix 24 [_Object2World]
"agal_vs
[bc]
bdaaaaaaaaaaaiacaaaaaaoeaaaaaaaaacaaaaoeabaaaaaa dp4 r0.w, a0, c2
bdaaaaaaabaaaiacaaaaaaoeaaaaaaaablaaaaoeabaaaaaa dp4 r1.w, a0, c27
bdaaaaaaaaaaaeacaaaaaaoeaaaaaaaabkaaaaoeabaaaaaa dp4 r0.z, a0, c26
bdaaaaaaaaaaabacaaaaaaoeaaaaaaaabiaaaaoeabaaaaaa dp4 r0.x, a0, c24
bdaaaaaaaaaaacacaaaaaaoeaaaaaaaabjaaaaoeabaaaaaa dp4 r0.y, a0, c25
aaaaaaaaabaaahacaaaaaakeacaaaaaaaaaaaaaaaaaaaaaa mov r1.xyz, r0.xyzz
bfaaaaaaaaaaaiacaaaaaappacaaaaaaaaaaaaaaaaaaaaaa neg r0.w, r0.w
bdaaaaaaaaaaaeaeabaaaaoeacaaaaaaakaaaaoeabaaaaaa dp4 v0.z, r1, c10
bdaaaaaaaaaaacaeabaaaaoeacaaaaaaajaaaaoeabaaaaaa dp4 v0.y, r1, c9
bdaaaaaaaaaaabaeabaaaaoeacaaaaaaaiaaaaoeabaaaaaa dp4 v0.x, r1, c8
bdaaaaaaabaaaeaeabaaaaoeacaaaaaaaoaaaaoeabaaaaaa dp4 v1.z, r1, c14
bdaaaaaaabaaacaeabaaaaoeacaaaaaaanaaaaoeabaaaaaa dp4 v1.y, r1, c13
bdaaaaaaabaaabaeabaaaaoeacaaaaaaamaaaaoeabaaaaaa dp4 v1.x, r1, c12
bdaaaaaaacaaaeaeabaaaaoeacaaaaaabcaaaaoeabaaaaaa dp4 v2.z, r1, c18
bdaaaaaaacaaacaeabaaaaoeacaaaaaabbaaaaoeabaaaaaa dp4 v2.y, r1, c17
bdaaaaaaacaaabaeabaaaaoeacaaaaaabaaaaaoeabaaaaaa dp4 v2.x, r1, c16
bdaaaaaaadaaaeaeabaaaaoeacaaaaaabgaaaaoeabaaaaaa dp4 v3.z, r1, c22
bdaaaaaaadaaacaeabaaaaoeacaaaaaabfaaaaoeabaaaaaa dp4 v3.y, r1, c21
bdaaaaaaadaaabaeabaaaaoeacaaaaaabeaaaaoeabaaaaaa dp4 v3.x, r1, c20
aaaaaaaaaeaaapaeaaaaaaoeacaaaaaaaaaaaaaaaaaaaaaa mov v4, r0
bdaaaaaaaaaaaiadaaaaaaoeaaaaaaaaahaaaaoeabaaaaaa dp4 o0.w, a0, c7
bdaaaaaaaaaaaeadaaaaaaoeaaaaaaaaagaaaaoeabaaaaaa dp4 o0.z, a0, c6
bdaaaaaaaaaaacadaaaaaaoeaaaaaaaaafaaaaoeabaaaaaa dp4 o0.y, a0, c5
bdaaaaaaaaaaabadaaaaaaoeaaaaaaaaaeaaaaoeabaaaaaa dp4 o0.x, a0, c4
aaaaaaaaaaaaaiaeaaaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov v0.w, c0
aaaaaaaaabaaaiaeaaaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov v1.w, c0
aaaaaaaaacaaaiaeaaaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov v2.w, c0
aaaaaaaaadaaaiaeaaaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov v3.w, c0
"
}

SubProgram "opengl " {
Keywords { "SHADOWS_NATIVE" "SHADOWS_SPLIT_SPHERES" }
Bind "vertex" Vertex
Matrix 9 [unity_World2Shadow0]
Matrix 13 [unity_World2Shadow1]
Matrix 17 [unity_World2Shadow2]
Matrix 21 [unity_World2Shadow3]
Matrix 25 [_Object2World]
"!!ARBvp1.0
# 24 ALU
PARAM c[29] = { program.local[0],
		state.matrix.modelview[0],
		state.matrix.mvp,
		program.local[9..28] };
TEMP R0;
TEMP R1;
DP4 R0.w, vertex.position, c[3];
DP4 R1.w, vertex.position, c[28];
DP4 R0.z, vertex.position, c[27];
DP4 R0.x, vertex.position, c[25];
DP4 R0.y, vertex.position, c[26];
MOV R1.xyz, R0;
MOV R0.w, -R0;
DP4 result.texcoord[0].z, R1, c[11];
DP4 result.texcoord[0].y, R1, c[10];
DP4 result.texcoord[0].x, R1, c[9];
DP4 result.texcoord[1].z, R1, c[15];
DP4 result.texcoord[1].y, R1, c[14];
DP4 result.texcoord[1].x, R1, c[13];
DP4 result.texcoord[2].z, R1, c[19];
DP4 result.texcoord[2].y, R1, c[18];
DP4 result.texcoord[2].x, R1, c[17];
DP4 result.texcoord[3].z, R1, c[23];
DP4 result.texcoord[3].y, R1, c[22];
DP4 result.texcoord[3].x, R1, c[21];
MOV result.texcoord[4], R0;
DP4 result.position.w, vertex.position, c[8];
DP4 result.position.z, vertex.position, c[7];
DP4 result.position.y, vertex.position, c[6];
DP4 result.position.x, vertex.position, c[5];
END
# 24 instructions, 2 R-regs
"
}

SubProgram "d3d9 " {
Keywords { "SHADOWS_NATIVE" "SHADOWS_SPLIT_SPHERES" }
Bind "vertex" Vertex
Matrix 0 [glstate_matrix_modelview0]
Matrix 4 [glstate_matrix_mvp]
Matrix 8 [unity_World2Shadow0]
Matrix 12 [unity_World2Shadow1]
Matrix 16 [unity_World2Shadow2]
Matrix 20 [unity_World2Shadow3]
Matrix 24 [_Object2World]
"vs_2_0
; 24 ALU
dcl_position0 v0
dp4 r0.w, v0, c2
dp4 r1.w, v0, c27
dp4 r0.z, v0, c26
dp4 r0.x, v0, c24
dp4 r0.y, v0, c25
mov r1.xyz, r0
mov r0.w, -r0
dp4 oT0.z, r1, c10
dp4 oT0.y, r1, c9
dp4 oT0.x, r1, c8
dp4 oT1.z, r1, c14
dp4 oT1.y, r1, c13
dp4 oT1.x, r1, c12
dp4 oT2.z, r1, c18
dp4 oT2.y, r1, c17
dp4 oT2.x, r1, c16
dp4 oT3.z, r1, c22
dp4 oT3.y, r1, c21
dp4 oT3.x, r1, c20
mov oT4, r0
dp4 oPos.w, v0, c7
dp4 oPos.z, v0, c6
dp4 oPos.y, v0, c5
dp4 oPos.x, v0, c4
"
}

SubProgram "d3d11 " {
Keywords { "SHADOWS_NATIVE" "SHADOWS_SPLIT_SPHERES" }
Bind "vertex" Vertex
ConstBuffer "UnityShadows" 416 // 384 used size, 8 vars
Matrix 128 [unity_World2Shadow0] 4
Matrix 192 [unity_World2Shadow1] 4
Matrix 256 [unity_World2Shadow2] 4
Matrix 320 [unity_World2Shadow3] 4
ConstBuffer "UnityPerDraw" 336 // 256 used size, 6 vars
Matrix 0 [glstate_matrix_mvp] 4
Matrix 64 [glstate_matrix_modelview0] 4
Matrix 192 [_Object2World] 4
BindCB "UnityShadows" 0
BindCB "UnityPerDraw" 1
// 31 instructions, 2 temp regs, 0 temp arrays:
// ALU 29 float, 0 int, 0 uint
// TEX 0 (0 load, 0 comp, 0 bias, 0 grad)
// FLOW 1 static, 0 dynamic
"vs_4_0
eefiecedmnkcbicaflnkacmllblelhfpmpifpejmabaaaaaaeaagaaaaadaaaaaa
cmaaaaaakaaaaaaafiabaaaaejfdeheogmaaaaaaadaaaaaaaiaaaaaafaaaaaaa
aaaaaaaaaaaaaaaaadaaaaaaaaaaaaaaapapaaaafjaaaaaaaaaaaaaaaaaaaaaa
adaaaaaaabaaaaaaahaaaaaagaaaaaaaaaaaaaaaaaaaaaaaadaaaaaaacaaaaaa
apaaaaaafaepfdejfeejepeoaaeoepfcenebemaafeeffiedepepfceeaaklklkl
epfdeheolaaaaaaaagaaaaaaaiaaaaaajiaaaaaaaaaaaaaaabaaaaaaadaaaaaa
aaaaaaaaapaaaaaakeaaaaaaaaaaaaaaaaaaaaaaadaaaaaaabaaaaaaahaiaaaa
keaaaaaaabaaaaaaaaaaaaaaadaaaaaaacaaaaaaahaiaaaakeaaaaaaacaaaaaa
aaaaaaaaadaaaaaaadaaaaaaahaiaaaakeaaaaaaadaaaaaaaaaaaaaaadaaaaaa
aeaaaaaaahaiaaaakeaaaaaaaeaaaaaaaaaaaaaaadaaaaaaafaaaaaaapaaaaaa
fdfgfpfaepfdejfeejepeoaafeeffiedepepfceeaaklklklfdeieefcoaaeaaaa
eaaaabaadiabaaaafjaaaaaeegiocaaaaaaaaaaabiaaaaaafjaaaaaeegiocaaa
abaaaaaabaaaaaaafpaaaaadpcbabaaaaaaaaaaaghaaaaaepccabaaaaaaaaaaa
abaaaaaagfaaaaadhccabaaaabaaaaaagfaaaaadhccabaaaacaaaaaagfaaaaad
hccabaaaadaaaaaagfaaaaadhccabaaaaeaaaaaagfaaaaadpccabaaaafaaaaaa
giaaaaacacaaaaaadiaaaaaipcaabaaaaaaaaaaafgbfbaaaaaaaaaaaegiocaaa
abaaaaaaabaaaaaadcaaaaakpcaabaaaaaaaaaaaegiocaaaabaaaaaaaaaaaaaa
agbabaaaaaaaaaaaegaobaaaaaaaaaaadcaaaaakpcaabaaaaaaaaaaaegiocaaa
abaaaaaaacaaaaaakgbkbaaaaaaaaaaaegaobaaaaaaaaaaadcaaaaakpccabaaa
aaaaaaaaegiocaaaabaaaaaaadaaaaaapgbpbaaaaaaaaaaaegaobaaaaaaaaaaa
diaaaaaipcaabaaaaaaaaaaafgbfbaaaaaaaaaaaegiocaaaabaaaaaaanaaaaaa
dcaaaaakpcaabaaaaaaaaaaaegiocaaaabaaaaaaamaaaaaaagbabaaaaaaaaaaa
egaobaaaaaaaaaaadcaaaaakpcaabaaaaaaaaaaaegiocaaaabaaaaaaaoaaaaaa
kgbkbaaaaaaaaaaaegaobaaaaaaaaaaadcaaaaakpcaabaaaaaaaaaaaegiocaaa
abaaaaaaapaaaaaapgbpbaaaaaaaaaaaegaobaaaaaaaaaaadiaaaaaihcaabaaa
abaaaaaafgafbaaaaaaaaaaaegiccaaaaaaaaaaaajaaaaaadcaaaaakhcaabaaa
abaaaaaaegiccaaaaaaaaaaaaiaaaaaaagaabaaaaaaaaaaaegacbaaaabaaaaaa
dcaaaaakhcaabaaaabaaaaaaegiccaaaaaaaaaaaakaaaaaakgakbaaaaaaaaaaa
egacbaaaabaaaaaadcaaaaakhccabaaaabaaaaaaegiccaaaaaaaaaaaalaaaaaa
pgapbaaaaaaaaaaaegacbaaaabaaaaaadiaaaaaihcaabaaaabaaaaaafgafbaaa
aaaaaaaaegiccaaaaaaaaaaaanaaaaaadcaaaaakhcaabaaaabaaaaaaegiccaaa
aaaaaaaaamaaaaaaagaabaaaaaaaaaaaegacbaaaabaaaaaadcaaaaakhcaabaaa
abaaaaaaegiccaaaaaaaaaaaaoaaaaaakgakbaaaaaaaaaaaegacbaaaabaaaaaa
dcaaaaakhccabaaaacaaaaaaegiccaaaaaaaaaaaapaaaaaapgapbaaaaaaaaaaa
egacbaaaabaaaaaadiaaaaaihcaabaaaabaaaaaafgafbaaaaaaaaaaaegiccaaa
aaaaaaaabbaaaaaadcaaaaakhcaabaaaabaaaaaaegiccaaaaaaaaaaabaaaaaaa
agaabaaaaaaaaaaaegacbaaaabaaaaaadcaaaaakhcaabaaaabaaaaaaegiccaaa
aaaaaaaabcaaaaaakgakbaaaaaaaaaaaegacbaaaabaaaaaadcaaaaakhccabaaa
adaaaaaaegiccaaaaaaaaaaabdaaaaaapgapbaaaaaaaaaaaegacbaaaabaaaaaa
diaaaaaihcaabaaaabaaaaaafgafbaaaaaaaaaaaegiccaaaaaaaaaaabfaaaaaa
dcaaaaakhcaabaaaabaaaaaaegiccaaaaaaaaaaabeaaaaaaagaabaaaaaaaaaaa
egacbaaaabaaaaaadcaaaaakhcaabaaaabaaaaaaegiccaaaaaaaaaaabgaaaaaa
kgakbaaaaaaaaaaaegacbaaaabaaaaaadcaaaaakhccabaaaaeaaaaaaegiccaaa
aaaaaaaabhaaaaaapgapbaaaaaaaaaaaegacbaaaabaaaaaadgaaaaafhccabaaa
afaaaaaaegacbaaaaaaaaaaadiaaaaaibcaabaaaaaaaaaaabkbabaaaaaaaaaaa
ckiacaaaabaaaaaaafaaaaaadcaaaaakbcaabaaaaaaaaaaackiacaaaabaaaaaa
aeaaaaaaakbabaaaaaaaaaaaakaabaaaaaaaaaaadcaaaaakbcaabaaaaaaaaaaa
ckiacaaaabaaaaaaagaaaaaackbabaaaaaaaaaaaakaabaaaaaaaaaaadcaaaaak
bcaabaaaaaaaaaaackiacaaaabaaaaaaahaaaaaadkbabaaaaaaaaaaaakaabaaa
aaaaaaaadgaaaaagiccabaaaafaaaaaaakaabaiaebaaaaaaaaaaaaaadoaaaaab
"
}

SubProgram "gles " {
Keywords { "SHADOWS_NATIVE" "SHADOWS_SPLIT_SPHERES" }
"!!GLES


#ifdef VERTEX

#extension GL_EXT_shadow_samplers : enable
varying highp vec4 xlv_TEXCOORD4;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp vec3 xlv_TEXCOORD0;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 unity_World2Shadow[4];
attribute vec4 _glesVertex;
void main ()
{
  highp vec4 tmpvar_1;
  highp vec4 tmpvar_2;
  tmpvar_2 = (_Object2World * _glesVertex);
  tmpvar_1.xyz = tmpvar_2.xyz;
  tmpvar_1.w = -((glstate_matrix_modelview0 * _glesVertex).z);
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = (unity_World2Shadow[0] * tmpvar_2).xyz;
  xlv_TEXCOORD1 = (unity_World2Shadow[1] * tmpvar_2).xyz;
  xlv_TEXCOORD2 = (unity_World2Shadow[2] * tmpvar_2).xyz;
  xlv_TEXCOORD3 = (unity_World2Shadow[3] * tmpvar_2).xyz;
  xlv_TEXCOORD4 = tmpvar_1;
}



#endif
#ifdef FRAGMENT

#extension GL_EXT_shadow_samplers : enable
varying highp vec4 xlv_TEXCOORD4;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec3 xlv_TEXCOORD1;
varying highp vec3 xlv_TEXCOORD0;
uniform lowp sampler2DShadow _ShadowMapTexture;
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp vec4 _LightShadowData;
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 _ProjectionParams;
void main ()
{
  lowp vec4 tmpvar_1;
  highp vec4 res_2;
  mediump float shadow_3;
  highp vec4 cascadeWeights_4;
  highp vec3 tmpvar_5;
  tmpvar_5 = (xlv_TEXCOORD4.xyz - unity_ShadowSplitSpheres[0].xyz);
  highp vec3 tmpvar_6;
  tmpvar_6 = (xlv_TEXCOORD4.xyz - unity_ShadowSplitSpheres[1].xyz);
  highp vec3 tmpvar_7;
  tmpvar_7 = (xlv_TEXCOORD4.xyz - unity_ShadowSplitSpheres[2].xyz);
  highp vec3 tmpvar_8;
  tmpvar_8 = (xlv_TEXCOORD4.xyz - unity_ShadowSplitSpheres[3].xyz);
  highp vec4 tmpvar_9;
  tmpvar_9.x = dot (tmpvar_5, tmpvar_5);
  tmpvar_9.y = dot (tmpvar_6, tmpvar_6);
  tmpvar_9.z = dot (tmpvar_7, tmpvar_7);
  tmpvar_9.w = dot (tmpvar_8, tmpvar_8);
  bvec4 tmpvar_10;
  tmpvar_10 = lessThan (tmpvar_9, unity_ShadowSplitSqRadii);
  lowp vec4 tmpvar_11;
  tmpvar_11 = vec4(tmpvar_10);
  cascadeWeights_4 = tmpvar_11;
  cascadeWeights_4.yzw = clamp ((cascadeWeights_4.yzw - cascadeWeights_4.xyz), 0.0, 1.0);
  highp vec3 p_12;
  p_12 = (xlv_TEXCOORD4.xyz - unity_ShadowFadeCenterAndType.xyz);
  highp vec4 tmpvar_13;
  tmpvar_13.w = 1.0;
  tmpvar_13.xyz = ((((xlv_TEXCOORD0 * cascadeWeights_4.x) + (xlv_TEXCOORD1 * cascadeWeights_4.y)) + (xlv_TEXCOORD2 * cascadeWeights_4.z)) + (xlv_TEXCOORD3 * cascadeWeights_4.w));
  lowp float tmpvar_14;
  tmpvar_14 = shadow2DEXT (_ShadowMapTexture, tmpvar_13.xyz);
  shadow_3 = tmpvar_14;
  highp float tmpvar_15;
  tmpvar_15 = (_LightShadowData.x + (shadow_3 * (1.0 - _LightShadowData.x)));
  shadow_3 = tmpvar_15;
  res_2.x = clamp ((shadow_3 + clamp (((sqrt(dot (p_12, p_12)) * _LightShadowData.z) + _LightShadowData.w), 0.0, 1.0)), 0.0, 1.0);
  res_2.y = 1.0;
  highp vec2 enc_16;
  highp vec2 tmpvar_17;
  tmpvar_17 = fract((vec2(1.0, 255.0) * (1.0 - (xlv_TEXCOORD4.w * _ProjectionParams.w))));
  enc_16.y = tmpvar_17.y;
  enc_16.x = (tmpvar_17.x - (tmpvar_17.y * 0.00392157));
  res_2.zw = enc_16;
  tmpvar_1 = res_2;
  gl_FragData[0] = tmpvar_1;
}



#endif"
}

SubProgram "d3d11_9x " {
Keywords { "SHADOWS_NATIVE" "SHADOWS_SPLIT_SPHERES" }
Bind "vertex" Vertex
ConstBuffer "UnityShadows" 416 // 384 used size, 8 vars
Matrix 128 [unity_World2Shadow0] 4
Matrix 192 [unity_World2Shadow1] 4
Matrix 256 [unity_World2Shadow2] 4
Matrix 320 [unity_World2Shadow3] 4
ConstBuffer "UnityPerDraw" 336 // 256 used size, 6 vars
Matrix 0 [glstate_matrix_mvp] 4
Matrix 64 [glstate_matrix_modelview0] 4
Matrix 192 [_Object2World] 4
BindCB "UnityShadows" 0
BindCB "UnityPerDraw" 1
// 31 instructions, 2 temp regs, 0 temp arrays:
// ALU 29 float, 0 int, 0 uint
// TEX 0 (0 load, 0 comp, 0 bias, 0 grad)
// FLOW 1 static, 0 dynamic
"vs_4_0_level_9_1
eefieceddcancklelhchleoiglklmccbijbiodfiabaaaaaapiaiaaaaaeaaaaaa
daaaaaaaoeacaaaammahaaaaeaaiaaaaebgpgodjkmacaaaakmacaaaaaaacpopp
gaacaaaaemaaaaaaadaaceaaaaaaeiaaaaaaeiaaaaaaceaaabaaeiaaaaaaaiaa
baaaabaaaaaaaaaaabaaaaaaaiaabbaaaaaaaaaaabaaamaaaeaabjaaaaaaaaaa
aaaaaaaaaaacpoppbpaaaaacafaaaaiaaaaaapjaafaaaaadaaaaabiaaaaaffja
bgaakkkaaeaaaaaeaaaaabiabfaakkkaaaaaaajaaaaaaaiaaeaaaaaeaaaaabia
bhaakkkaaaaakkjaaaaaaaiaaeaaaaaeaaaaabiabiaakkkaaaaappjaaaaaaaia
abaaaaacaeaaaioaaaaaaaibafaaaaadaaaaapiaaaaaffjabkaaoekaaeaaaaae
aaaaapiabjaaoekaaaaaaajaaaaaoeiaaeaaaaaeaaaaapiablaaoekaaaaakkja
aaaaoeiaaeaaaaaeaaaaapiabmaaoekaaaaappjaaaaaoeiaafaaaaadabaaahia
aaaaffiaacaaoekaaeaaaaaeabaaahiaabaaoekaaaaaaaiaabaaoeiaaeaaaaae
abaaahiaadaaoekaaaaakkiaabaaoeiaaeaaaaaeaaaaahoaaeaaoekaaaaappia
abaaoeiaafaaaaadabaaahiaaaaaffiaagaaoekaaeaaaaaeabaaahiaafaaoeka
aaaaaaiaabaaoeiaaeaaaaaeabaaahiaahaaoekaaaaakkiaabaaoeiaaeaaaaae
abaaahoaaiaaoekaaaaappiaabaaoeiaafaaaaadabaaahiaaaaaffiaakaaoeka
aeaaaaaeabaaahiaajaaoekaaaaaaaiaabaaoeiaaeaaaaaeabaaahiaalaaoeka
aaaakkiaabaaoeiaaeaaaaaeacaaahoaamaaoekaaaaappiaabaaoeiaafaaaaad
abaaahiaaaaaffiaaoaaoekaaeaaaaaeabaaahiaanaaoekaaaaaaaiaabaaoeia
aeaaaaaeabaaahiaapaaoekaaaaakkiaabaaoeiaaeaaaaaeadaaahoabaaaoeka
aaaappiaabaaoeiaabaaaaacaeaaahoaaaaaoeiaafaaaaadaaaaapiaaaaaffja
bcaaoekaaeaaaaaeaaaaapiabbaaoekaaaaaaajaaaaaoeiaaeaaaaaeaaaaapia
bdaaoekaaaaakkjaaaaaoeiaaeaaaaaeaaaaapiabeaaoekaaaaappjaaaaaoeia
aeaaaaaeaaaaadmaaaaappiaaaaaoekaaaaaoeiaabaaaaacaaaaammaaaaaoeia
ppppaaaafdeieefcoaaeaaaaeaaaabaadiabaaaafjaaaaaeegiocaaaaaaaaaaa
biaaaaaafjaaaaaeegiocaaaabaaaaaabaaaaaaafpaaaaadpcbabaaaaaaaaaaa
ghaaaaaepccabaaaaaaaaaaaabaaaaaagfaaaaadhccabaaaabaaaaaagfaaaaad
hccabaaaacaaaaaagfaaaaadhccabaaaadaaaaaagfaaaaadhccabaaaaeaaaaaa
gfaaaaadpccabaaaafaaaaaagiaaaaacacaaaaaadiaaaaaipcaabaaaaaaaaaaa
fgbfbaaaaaaaaaaaegiocaaaabaaaaaaabaaaaaadcaaaaakpcaabaaaaaaaaaaa
egiocaaaabaaaaaaaaaaaaaaagbabaaaaaaaaaaaegaobaaaaaaaaaaadcaaaaak
pcaabaaaaaaaaaaaegiocaaaabaaaaaaacaaaaaakgbkbaaaaaaaaaaaegaobaaa
aaaaaaaadcaaaaakpccabaaaaaaaaaaaegiocaaaabaaaaaaadaaaaaapgbpbaaa
aaaaaaaaegaobaaaaaaaaaaadiaaaaaipcaabaaaaaaaaaaafgbfbaaaaaaaaaaa
egiocaaaabaaaaaaanaaaaaadcaaaaakpcaabaaaaaaaaaaaegiocaaaabaaaaaa
amaaaaaaagbabaaaaaaaaaaaegaobaaaaaaaaaaadcaaaaakpcaabaaaaaaaaaaa
egiocaaaabaaaaaaaoaaaaaakgbkbaaaaaaaaaaaegaobaaaaaaaaaaadcaaaaak
pcaabaaaaaaaaaaaegiocaaaabaaaaaaapaaaaaapgbpbaaaaaaaaaaaegaobaaa
aaaaaaaadiaaaaaihcaabaaaabaaaaaafgafbaaaaaaaaaaaegiccaaaaaaaaaaa
ajaaaaaadcaaaaakhcaabaaaabaaaaaaegiccaaaaaaaaaaaaiaaaaaaagaabaaa
aaaaaaaaegacbaaaabaaaaaadcaaaaakhcaabaaaabaaaaaaegiccaaaaaaaaaaa
akaaaaaakgakbaaaaaaaaaaaegacbaaaabaaaaaadcaaaaakhccabaaaabaaaaaa
egiccaaaaaaaaaaaalaaaaaapgapbaaaaaaaaaaaegacbaaaabaaaaaadiaaaaai
hcaabaaaabaaaaaafgafbaaaaaaaaaaaegiccaaaaaaaaaaaanaaaaaadcaaaaak
hcaabaaaabaaaaaaegiccaaaaaaaaaaaamaaaaaaagaabaaaaaaaaaaaegacbaaa
abaaaaaadcaaaaakhcaabaaaabaaaaaaegiccaaaaaaaaaaaaoaaaaaakgakbaaa
aaaaaaaaegacbaaaabaaaaaadcaaaaakhccabaaaacaaaaaaegiccaaaaaaaaaaa
apaaaaaapgapbaaaaaaaaaaaegacbaaaabaaaaaadiaaaaaihcaabaaaabaaaaaa
fgafbaaaaaaaaaaaegiccaaaaaaaaaaabbaaaaaadcaaaaakhcaabaaaabaaaaaa
egiccaaaaaaaaaaabaaaaaaaagaabaaaaaaaaaaaegacbaaaabaaaaaadcaaaaak
hcaabaaaabaaaaaaegiccaaaaaaaaaaabcaaaaaakgakbaaaaaaaaaaaegacbaaa
abaaaaaadcaaaaakhccabaaaadaaaaaaegiccaaaaaaaaaaabdaaaaaapgapbaaa
aaaaaaaaegacbaaaabaaaaaadiaaaaaihcaabaaaabaaaaaafgafbaaaaaaaaaaa
egiccaaaaaaaaaaabfaaaaaadcaaaaakhcaabaaaabaaaaaaegiccaaaaaaaaaaa
beaaaaaaagaabaaaaaaaaaaaegacbaaaabaaaaaadcaaaaakhcaabaaaabaaaaaa
egiccaaaaaaaaaaabgaaaaaakgakbaaaaaaaaaaaegacbaaaabaaaaaadcaaaaak
hccabaaaaeaaaaaaegiccaaaaaaaaaaabhaaaaaapgapbaaaaaaaaaaaegacbaaa
abaaaaaadgaaaaafhccabaaaafaaaaaaegacbaaaaaaaaaaadiaaaaaibcaabaaa
aaaaaaaabkbabaaaaaaaaaaackiacaaaabaaaaaaafaaaaaadcaaaaakbcaabaaa
aaaaaaaackiacaaaabaaaaaaaeaaaaaaakbabaaaaaaaaaaaakaabaaaaaaaaaaa
dcaaaaakbcaabaaaaaaaaaaackiacaaaabaaaaaaagaaaaaackbabaaaaaaaaaaa
akaabaaaaaaaaaaadcaaaaakbcaabaaaaaaaaaaackiacaaaabaaaaaaahaaaaaa
dkbabaaaaaaaaaaaakaabaaaaaaaaaaadgaaaaagiccabaaaafaaaaaaakaabaia
ebaaaaaaaaaaaaaadoaaaaabejfdeheogmaaaaaaadaaaaaaaiaaaaaafaaaaaaa
aaaaaaaaaaaaaaaaadaaaaaaaaaaaaaaapapaaaafjaaaaaaaaaaaaaaaaaaaaaa
adaaaaaaabaaaaaaahaaaaaagaaaaaaaaaaaaaaaaaaaaaaaadaaaaaaacaaaaaa
apaaaaaafaepfdejfeejepeoaaeoepfcenebemaafeeffiedepepfceeaaklklkl
epfdeheolaaaaaaaagaaaaaaaiaaaaaajiaaaaaaaaaaaaaaabaaaaaaadaaaaaa
aaaaaaaaapaaaaaakeaaaaaaaaaaaaaaaaaaaaaaadaaaaaaabaaaaaaahaiaaaa
keaaaaaaabaaaaaaaaaaaaaaadaaaaaaacaaaaaaahaiaaaakeaaaaaaacaaaaaa
aaaaaaaaadaaaaaaadaaaaaaahaiaaaakeaaaaaaadaaaaaaaaaaaaaaadaaaaaa
aeaaaaaaahaiaaaakeaaaaaaaeaaaaaaaaaaaaaaadaaaaaaafaaaaaaapaaaaaa
fdfgfpfaepfdejfeejepeoaafeeffiedepepfceeaaklklkl"
}

SubProgram "gles3 " {
Keywords { "SHADOWS_NATIVE" "SHADOWS_SPLIT_SPHERES" }
"!!GLES3#version 300 es


#ifdef VERTEX

#define gl_Vertex _glesVertex
in vec4 _glesVertex;
#define gl_Normal (normalize(_glesNormal))
in vec3 _glesNormal;
#define gl_MultiTexCoord0 _glesMultiTexCoord0
in vec4 _glesMultiTexCoord0;

#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 316
struct v2f {
    highp vec4 pos;
    highp vec3 _ShadowCoord0;
    highp vec3 _ShadowCoord1;
    highp vec3 _ShadowCoord2;
    highp vec3 _ShadowCoord3;
    highp vec4 _WorldPosViewZ;
};
#line 52
struct appdata_base {
    highp vec4 vertex;
    highp vec3 normal;
    highp vec4 texcoord;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform highp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform lowp sampler2DShadow _ShadowMapTexture;
#line 326
#line 339
uniform lowp vec4 _Color;
#line 326
v2f vert( in appdata_base v ) {
    v2f o;
    o.pos = (glstate_matrix_mvp * v.vertex);
    #line 330
    highp vec4 wpos = (_Object2World * v.vertex);
    o._WorldPosViewZ.xyz = vec3( wpos);
    o._WorldPosViewZ.w = (-(glstate_matrix_modelview0 * v.vertex).z);
    o._ShadowCoord0 = (unity_World2Shadow[0] * wpos).xyz;
    #line 334
    o._ShadowCoord1 = (unity_World2Shadow[1] * wpos).xyz;
    o._ShadowCoord2 = (unity_World2Shadow[2] * wpos).xyz;
    o._ShadowCoord3 = (unity_World2Shadow[3] * wpos).xyz;
    return o;
}
out highp vec3 xlv_TEXCOORD0;
out highp vec3 xlv_TEXCOORD1;
out highp vec3 xlv_TEXCOORD2;
out highp vec3 xlv_TEXCOORD3;
out highp vec4 xlv_TEXCOORD4;
void main() {
    v2f xl_retval;
    appdata_base xlt_v;
    xlt_v.vertex = vec4(gl_Vertex);
    xlt_v.normal = vec3(gl_Normal);
    xlt_v.texcoord = vec4(gl_MultiTexCoord0);
    xl_retval = vert( xlt_v);
    gl_Position = vec4(xl_retval.pos);
    xlv_TEXCOORD0 = vec3(xl_retval._ShadowCoord0);
    xlv_TEXCOORD1 = vec3(xl_retval._ShadowCoord1);
    xlv_TEXCOORD2 = vec3(xl_retval._ShadowCoord2);
    xlv_TEXCOORD3 = vec3(xl_retval._ShadowCoord3);
    xlv_TEXCOORD4 = vec4(xl_retval._WorldPosViewZ);
}


#endif
#ifdef FRAGMENT

#define gl_FragData _glesFragData
layout(location = 0) out mediump vec4 _glesFragData[4];
float xll_shadow2D(mediump sampler2DShadow s, vec3 coord) { return texture (s, coord); }
float xll_saturate_f( float x) {
  return clamp( x, 0.0, 1.0);
}
vec2 xll_saturate_vf2( vec2 x) {
  return clamp( x, 0.0, 1.0);
}
vec3 xll_saturate_vf3( vec3 x) {
  return clamp( x, 0.0, 1.0);
}
vec4 xll_saturate_vf4( vec4 x) {
  return clamp( x, 0.0, 1.0);
}
mat2 xll_saturate_mf2x2(mat2 m) {
  return mat2( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0));
}
mat3 xll_saturate_mf3x3(mat3 m) {
  return mat3( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0));
}
mat4 xll_saturate_mf4x4(mat4 m) {
  return mat4( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0), clamp(m[3], 0.0, 1.0));
}
#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 316
struct v2f {
    highp vec4 pos;
    highp vec3 _ShadowCoord0;
    highp vec3 _ShadowCoord1;
    highp vec3 _ShadowCoord2;
    highp vec3 _ShadowCoord3;
    highp vec4 _WorldPosViewZ;
};
#line 52
struct appdata_base {
    highp vec4 vertex;
    highp vec3 normal;
    highp vec4 texcoord;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform highp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform lowp sampler2DShadow _ShadowMapTexture;
#line 326
#line 339
uniform lowp vec4 _Color;
#line 220
highp vec2 EncodeFloatRG( in highp float v ) {
    highp vec2 kEncodeMul = vec2( 1.0, 255.0);
    highp float kEncodeBit = 0.00392157;
    #line 224
    highp vec2 enc = (kEncodeMul * v);
    enc = fract(enc);
    enc.x -= (enc.y * kEncodeBit);
    return enc;
}
#line 340
lowp vec4 frag( in v2f i ) {
    highp vec3 fromCenter0 = (i._WorldPosViewZ.xyz - unity_ShadowSplitSpheres[0].xyz);
    #line 343
    highp vec3 fromCenter1 = (i._WorldPosViewZ.xyz - unity_ShadowSplitSpheres[1].xyz);
    highp vec3 fromCenter2 = (i._WorldPosViewZ.xyz - unity_ShadowSplitSpheres[2].xyz);
    highp vec3 fromCenter3 = (i._WorldPosViewZ.xyz - unity_ShadowSplitSpheres[3].xyz);
    highp vec4 distances2 = vec4( dot( fromCenter0, fromCenter0), dot( fromCenter1, fromCenter1), dot( fromCenter2, fromCenter2), dot( fromCenter3, fromCenter3));
    #line 347
    highp vec4 cascadeWeights = vec4(lessThan( distances2, unity_ShadowSplitSqRadii));
    cascadeWeights.yzw = xll_saturate_vf3((cascadeWeights.yzw - cascadeWeights.xyz));
    highp float sphereDist = distance( i._WorldPosViewZ.xyz, unity_ShadowFadeCenterAndType.xyz);
    highp float shadowFade = xll_saturate_f(((sphereDist * _LightShadowData.z) + _LightShadowData.w));
    #line 351
    highp vec4 coord = vec4( ((((i._ShadowCoord0 * cascadeWeights.x) + (i._ShadowCoord1 * cascadeWeights.y)) + (i._ShadowCoord2 * cascadeWeights.z)) + (i._ShadowCoord3 * cascadeWeights.w)), 1.0);
    mediump float shadow = xll_shadow2D( _ShadowMapTexture, coord.xyz);
    shadow = (_LightShadowData.x + (shadow * (1.0 - _LightShadowData.x)));
    highp vec4 res;
    #line 355
    res.x = xll_saturate_f((shadow + shadowFade));
    res.y = 1.0;
    res.zw = EncodeFloatRG( (1.0 - (i._WorldPosViewZ.w * _ProjectionParams.w)));
    return res;
}
in highp vec3 xlv_TEXCOORD0;
in highp vec3 xlv_TEXCOORD1;
in highp vec3 xlv_TEXCOORD2;
in highp vec3 xlv_TEXCOORD3;
in highp vec4 xlv_TEXCOORD4;
void main() {
    lowp vec4 xl_retval;
    v2f xlt_i;
    xlt_i.pos = vec4(0.0);
    xlt_i._ShadowCoord0 = vec3(xlv_TEXCOORD0);
    xlt_i._ShadowCoord1 = vec3(xlv_TEXCOORD1);
    xlt_i._ShadowCoord2 = vec3(xlv_TEXCOORD2);
    xlt_i._ShadowCoord3 = vec3(xlv_TEXCOORD3);
    xlt_i._WorldPosViewZ = vec4(xlv_TEXCOORD4);
    xl_retval = frag( xlt_i);
    gl_FragData[0] = vec4(xl_retval);
}


#endif"
}

}
Program "fp" {
// Fragment combos: 4
//   opengl - ALU: 21 to 32, TEX: 1 to 1
//   d3d9 - ALU: 24 to 37, TEX: 1 to 1
//   d3d11 - ALU: 17 to 27, TEX: 0 to 0, FLOW: 1 to 1
//   d3d11_9x - ALU: 17 to 27, TEX: 0 to 0, FLOW: 1 to 1
SubProgram "opengl " {
Keywords { "SHADOWS_NONATIVE" }
Vector 0 [_ProjectionParams]
Vector 1 [_LightSplitsNear]
Vector 2 [_LightSplitsFar]
Vector 3 [_LightShadowData]
SetTexture 0 [_ShadowMapTexture] 2D
"!!ARBfp1.0
OPTION ARB_precision_hint_fastest;
# 21 ALU, 1 TEX
PARAM c[5] = { program.local[0..3],
		{ 1, 255, 0.0039215689 } };
TEMP R0;
TEMP R1;
SLT R1, fragment.texcoord[4].w, c[2];
SGE R0, fragment.texcoord[4].w, c[1];
MUL R0, R0, R1;
MUL R1.xyz, R0.y, fragment.texcoord[1];
MAD R1.xyz, R0.x, fragment.texcoord[0], R1;
MAD R0.xyz, R0.z, fragment.texcoord[2], R1;
MAD R0.xyz, fragment.texcoord[3], R0.w, R0;
MAD_SAT R1.y, fragment.texcoord[4].w, c[3].z, c[3].w;
MOV result.color.y, c[4].x;
TEX R0.x, R0, texture[0], 2D;
ADD R0.z, R0.x, -R0;
MOV R0.x, c[4];
CMP R1.x, R0.z, c[3], R0;
MUL R0.y, -fragment.texcoord[4].w, c[0].w;
ADD R0.y, R0, c[4].x;
MUL R0.xy, R0.y, c[4];
FRC R0.zw, R0.xyxy;
MOV R0.y, R0.w;
MAD R0.x, -R0.w, c[4].z, R0.z;
ADD_SAT result.color.x, R1, R1.y;
MOV result.color.zw, R0.xyxy;
END
# 21 instructions, 2 R-regs
"
}

SubProgram "d3d9 " {
Keywords { "SHADOWS_NONATIVE" }
Vector 0 [_ProjectionParams]
Vector 1 [_LightSplitsNear]
Vector 2 [_LightSplitsFar]
Vector 3 [_LightShadowData]
SetTexture 0 [_ShadowMapTexture] 2D
"ps_2_0
; 26 ALU, 1 TEX
dcl_2d s0
def c4, 1.00000000, 0.00000000, 255.00000000, 0.00392157
dcl t0.xyz
dcl t1.xyz
dcl t2.xyz
dcl t3.xyz
dcl t4.xyzw
add r1, t4.w, -c2
add r0, t4.w, -c1
cmp r1, r1, c4.y, c4.x
cmp r0, r0, c4.x, c4.y
mul r0, r0, r1
mul r1.xyz, r0.y, t1
mad r1.xyz, r0.x, t0, r1
mad r0.xyz, r0.z, t2, r1
mad r1.xyz, t3, r0.w, r0
mov r2.x, c3
mov r2.y, c4.z
texld r0, r1, s0
add r0.x, r0, -r1.z
cmp r0.x, r0, c4, r2
mul r1.x, -t4.w, c0.w
add r1.x, r1, c4
mov r2.x, c4
mul r2.xy, r1.x, r2
mad_sat r1.x, t4.w, c3.z, c3.w
frc r2.xy, r2
add_sat r0.x, r0, r1
mov r1.y, r2
mad r1.x, -r2.y, c4.w, r2
mov r0.w, r1.y
mov r0.z, r1.x
mov r0.y, c4.x
mov_pp oC0, r0
"
}

SubProgram "gles " {
Keywords { "SHADOWS_NONATIVE" }
"!!GLES"
}

SubProgram "glesdesktop " {
Keywords { "SHADOWS_NONATIVE" }
"!!GLES"
}

SubProgram "flash " {
Keywords { "SHADOWS_NONATIVE" }
Vector 0 [_ProjectionParams]
Vector 1 [_LightSplitsNear]
Vector 2 [_LightSplitsFar]
Vector 3 [_LightShadowData]
SetTexture 0 [_ShadowMapTexture] 2D
"agal_ps
c4 1.0 0.0 255.0 0.003922
c5 1.0 0.003922 0.000015 0.0
[bc]
acaaaaaaabaaapacaeaaaappaeaaaaaaacaaaaoeabaaaaaa sub r1, v4.w, c2
acaaaaaaaaaaapacaeaaaappaeaaaaaaabaaaaoeabaaaaaa sub r0, v4.w, c1
ckaaaaaaacaaapacabaaaaoeacaaaaaaaeaaaaffabaaaaaa slt r2, r1, c4.y
aaaaaaaaadaaapacaeaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov r3, c4
aaaaaaaaaeaaapacaeaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov r4, c4
acaaaaaaaeaaapacadaaaaaaacaaaaaaaeaaaaffacaaaaaa sub r4, r3.x, r4.y
adaaaaaaabaaapacaeaaaaoeacaaaaaaacaaaaoeacaaaaaa mul r1, r4, r2
abaaaaaaabaaapacabaaaaoeacaaaaaaaeaaaaffabaaaaaa add r1, r1, c4.y
ckaaaaaaaeaaapacaaaaaaoeacaaaaaaaeaaaaffabaaaaaa slt r4, r0, c4.y
aaaaaaaaafaaacacaeaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov r5.y, c4
aaaaaaaaafaaapacaeaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov r5, c4
acaaaaaaadaaapacafaaaaffacaaaaaaafaaaaaaacaaaaaa sub r3, r5.y, r5.x
adaaaaaaaaaaapacadaaaaoeacaaaaaaaeaaaaoeacaaaaaa mul r0, r3, r4
abaaaaaaaaaaapacaaaaaaoeacaaaaaaaeaaaaaaabaaaaaa add r0, r0, c4.x
adaaaaaaaaaaapacaaaaaaoeacaaaaaaabaaaaoeacaaaaaa mul r0, r0, r1
adaaaaaaabaaahacaaaaaaffacaaaaaaabaaaaoeaeaaaaaa mul r1.xyz, r0.y, v1
adaaaaaaaeaaahacaaaaaaaaacaaaaaaaaaaaaoeaeaaaaaa mul r4.xyz, r0.x, v0
abaaaaaaabaaahacaeaaaakeacaaaaaaabaaaakeacaaaaaa add r1.xyz, r4.xyzz, r1.xyzz
adaaaaaaaaaaahacaaaaaakkacaaaaaaacaaaaoeaeaaaaaa mul r0.xyz, r0.z, v2
abaaaaaaaaaaahacaaaaaakeacaaaaaaabaaaakeacaaaaaa add r0.xyz, r0.xyzz, r1.xyzz
adaaaaaaabaaahacadaaaaoeaeaaaaaaaaaaaappacaaaaaa mul r1.xyz, v3, r0.w
abaaaaaaabaaahacabaaaakeacaaaaaaaaaaaakeacaaaaaa add r1.xyz, r1.xyzz, r0.xyzz
aaaaaaaaacaaabacadaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov r2.x, c3
aaaaaaaaacaaacacaeaaaakkabaaaaaaaaaaaaaaaaaaaaaa mov r2.y, c4.z
ciaaaaaaaaaaapacabaaaafeacaaaaaaaaaaaaaaafaababb tex r0, r1.xyyy, s0 <2d wrap linear point>
bdaaaaaaaaaaabacaaaaaaoeacaaaaaaafaaaaoeabaaaaaa dp4 r0.x, r0, c5
acaaaaaaaaaaabacaaaaaaaaacaaaaaaabaaaakkacaaaaaa sub r0.x, r0.x, r1.z
ckaaaaaaadaaabacaaaaaaaaacaaaaaaaeaaaaffabaaaaaa slt r3.x, r0.x, c4.y
acaaaaaaaeaaabacacaaaaaaacaaaaaaaeaaaaoeabaaaaaa sub r4.x, r2.x, c4
adaaaaaaaaaaabacaeaaaaaaacaaaaaaadaaaaaaacaaaaaa mul r0.x, r4.x, r3.x
abaaaaaaaaaaabacaaaaaaaaacaaaaaaaeaaaaoeabaaaaaa add r0.x, r0.x, c4
bfaaaaaaadaaaiacaeaaaappaeaaaaaaaaaaaaaaaaaaaaaa neg r3.w, v4.w
adaaaaaaabaaabacadaaaappacaaaaaaaaaaaappabaaaaaa mul r1.x, r3.w, c0.w
abaaaaaaabaaabacabaaaaaaacaaaaaaaeaaaaoeabaaaaaa add r1.x, r1.x, c4
aaaaaaaaacaaabacaeaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov r2.x, c4
adaaaaaaacaaadacabaaaaaaacaaaaaaacaaaafeacaaaaaa mul r2.xy, r1.x, r2.xyyy
adaaaaaaabaaabacaeaaaappaeaaaaaaadaaaakkabaaaaaa mul r1.x, v4.w, c3.z
abaaaaaaabaaabacabaaaaaaacaaaaaaadaaaappabaaaaaa add r1.x, r1.x, c3.w
bgaaaaaaabaaabacabaaaaaaacaaaaaaaaaaaaaaaaaaaaaa sat r1.x, r1.x
aiaaaaaaacaaadacacaaaafeacaaaaaaaaaaaaaaaaaaaaaa frc r2.xy, r2.xyyy
abaaaaaaaaaaabacaaaaaaaaacaaaaaaabaaaaaaacaaaaaa add r0.x, r0.x, r1.x
bgaaaaaaaaaaabacaaaaaaaaacaaaaaaaaaaaaaaaaaaaaaa sat r0.x, r0.x
aaaaaaaaabaaacacacaaaaffacaaaaaaaaaaaaaaaaaaaaaa mov r1.y, r2.y
bfaaaaaaaeaaacacacaaaaffacaaaaaaaaaaaaaaaaaaaaaa neg r4.y, r2.y
adaaaaaaabaaabacaeaaaaffacaaaaaaaeaaaappabaaaaaa mul r1.x, r4.y, c4.w
abaaaaaaabaaabacabaaaaaaacaaaaaaacaaaaaaacaaaaaa add r1.x, r1.x, r2.x
aaaaaaaaaaaaaiacabaaaaffacaaaaaaaaaaaaaaaaaaaaaa mov r0.w, r1.y
aaaaaaaaaaaaaeacabaaaaaaacaaaaaaaaaaaaaaaaaaaaaa mov r0.z, r1.x
aaaaaaaaaaaaacacaeaaaaaaabaaaaaaaaaaaaaaaaaaaaaa mov r0.y, c4.x
aaaaaaaaaaaaapadaaaaaaoeacaaaaaaaaaaaaaaaaaaaaaa mov o0, r0
"
}

SubProgram "opengl " {
Keywords { "SHADOWS_NATIVE" }
Vector 0 [_ProjectionParams]
Vector 1 [_LightSplitsNear]
Vector 2 [_LightSplitsFar]
Vector 3 [_LightShadowData]
SetTexture 0 [_ShadowMapTexture] 2D
"!!ARBfp1.0
OPTION ARB_precision_hint_fastest;
# 21 ALU, 1 TEX
OPTION ARB_fragment_program_shadow;
PARAM c[5] = { program.local[0..3],
		{ 1, 255, 0.0039215689 } };
TEMP R0;
TEMP R1;
SLT R1, fragment.texcoord[4].w, c[2];
SGE R0, fragment.texcoord[4].w, c[1];
MUL R0, R0, R1;
MUL R1.xyz, R0.y, fragment.texcoord[1];
MAD R1.xyz, R0.x, fragment.texcoord[0], R1;
MAD R0.xyz, R0.z, fragment.texcoord[2], R1;
MAD R0.xyz, fragment.texcoord[3], R0.w, R0;
MAD_SAT R1.y, fragment.texcoord[4].w, c[3].z, c[3].w;
MOV result.color.y, c[4].x;
TEX R0.x, R0, texture[0], SHADOW2D;
MOV R0.y, c[4].x;
ADD R0.w, R0.y, -c[3].x;
MAD R1.x, R0, R0.w, c[3];
MUL R0.z, -fragment.texcoord[4].w, c[0].w;
ADD R0.y, R0.z, c[4].x;
MUL R0.xy, R0.y, c[4];
FRC R0.zw, R0.xyxy;
MOV R0.y, R0.w;
MAD R0.x, -R0.w, c[4].z, R0.z;
ADD_SAT result.color.x, R1, R1.y;
MOV result.color.zw, R0.xyxy;
END
# 21 instructions, 2 R-regs
"
}

SubProgram "d3d9 " {
Keywords { "SHADOWS_NATIVE" }
Vector 0 [_ProjectionParams]
Vector 1 [_LightSplitsNear]
Vector 2 [_LightSplitsFar]
Vector 3 [_LightShadowData]
SetTexture 0 [_ShadowMapTexture] 2D
"ps_2_0
; 24 ALU, 1 TEX
dcl_2d s0
def c4, 0.00000000, 1.00000000, 255.00000000, 0.00392157
dcl t0.xyz
dcl t1.xyz
dcl t2.xyz
dcl t3.xyz
dcl t4.xyzw
add r1, t4.w, -c2
add r0, t4.w, -c1
cmp r1, r1, c4.x, c4.y
cmp r0, r0, c4.y, c4.x
mul r0, r0, r1
mul r1.xyz, r0.y, t1
mad r1.xyz, r0.x, t0, r1
mad r0.xyz, r0.z, t2, r1
mad r0.xyz, t3, r0.w, r0
mul r1.x, -t4.w, c0.w
add r1.x, r1, c4.y
texld r2, r0, s0
mov r0.x, c3
add r0.x, c4.y, -r0
mad r0.x, r2, r0, c3
mul r2.xy, r1.x, c4.yzxw
mad_sat r1.x, t4.w, c3.z, c3.w
frc r2.xy, r2
add_sat r0.x, r0, r1
mov r1.y, r2
mad r1.x, -r2.y, c4.w, r2
mov r0.w, r1.y
mov r0.z, r1.x
mov r0.y, c4
mov_pp oC0, r0
"
}

SubProgram "d3d11 " {
Keywords { "SHADOWS_NATIVE" }
ConstBuffer "UnityPerCamera" 128 // 96 used size, 8 vars
Vector 80 [_ProjectionParams] 4
ConstBuffer "UnityShadows" 416 // 400 used size, 8 vars
Vector 96 [_LightSplitsNear] 4
Vector 112 [_LightSplitsFar] 4
Vector 384 [_LightShadowData] 4
BindCB "UnityPerCamera" 0
BindCB "UnityShadows" 1
SetTexture 0 [_ShadowMapTexture] 2D 0
// 21 instructions, 2 temp regs, 0 temp arrays:
// ALU 15 float, 0 int, 2 uint
// TEX 0 (0 load, 1 comp, 0 bias, 0 grad)
// FLOW 1 static, 0 dynamic
"ps_4_0
eefiecedfoicichoepiaaopfmpilgmkjgoeglgdgabaaaaaageaeaaaaadaaaaaa
cmaaaaaaoeaaaaaabiabaaaaejfdeheolaaaaaaaagaaaaaaaiaaaaaajiaaaaaa
aaaaaaaaabaaaaaaadaaaaaaaaaaaaaaapaaaaaakeaaaaaaaaaaaaaaaaaaaaaa
adaaaaaaabaaaaaaahahaaaakeaaaaaaabaaaaaaaaaaaaaaadaaaaaaacaaaaaa
ahahaaaakeaaaaaaacaaaaaaaaaaaaaaadaaaaaaadaaaaaaahahaaaakeaaaaaa
adaaaaaaaaaaaaaaadaaaaaaaeaaaaaaahahaaaakeaaaaaaaeaaaaaaaaaaaaaa
adaaaaaaafaaaaaaapaiaaaafdfgfpfaepfdejfeejepeoaafeeffiedepepfcee
aaklklklepfdeheocmaaaaaaabaaaaaaaiaaaaaacaaaaaaaaaaaaaaaaaaaaaaa
adaaaaaaaaaaaaaaapaaaaaafdfgfpfegbhcghgfheaaklklfdeieefceeadaaaa
eaaaaaaanbaaaaaafjaaaaaeegiocaaaaaaaaaaaagaaaaaafjaaaaaeegiocaaa
abaaaaaabjaaaaaafkaiaaadaagabaaaaaaaaaaafibiaaaeaahabaaaaaaaaaaa
ffffaaaagcbaaaadhcbabaaaabaaaaaagcbaaaadhcbabaaaacaaaaaagcbaaaad
hcbabaaaadaaaaaagcbaaaadhcbabaaaaeaaaaaagcbaaaadicbabaaaafaaaaaa
gfaaaaadpccabaaaaaaaaaaagiaaaaacacaaaaaabnaaaaaipcaabaaaaaaaaaaa
pgbpbaaaafaaaaaaegiocaaaabaaaaaaagaaaaaaabaaaaakpcaabaaaaaaaaaaa
egaobaaaaaaaaaaaaceaaaaaaaaaiadpaaaaiadpaaaaiadpaaaaiadpdbaaaaai
pcaabaaaabaaaaaapgbpbaaaafaaaaaaegiocaaaabaaaaaaahaaaaaaabaaaaak
pcaabaaaabaaaaaaegaobaaaabaaaaaaaceaaaaaaaaaiadpaaaaiadpaaaaiadp
aaaaiadpdiaaaaahpcaabaaaaaaaaaaaegaobaaaaaaaaaaaegaobaaaabaaaaaa
diaaaaahhcaabaaaabaaaaaafgafbaaaaaaaaaaaegbcbaaaacaaaaaadcaaaaaj
hcaabaaaabaaaaaaegbcbaaaabaaaaaaagaabaaaaaaaaaaaegacbaaaabaaaaaa
dcaaaaajhcaabaaaaaaaaaaaegbcbaaaadaaaaaakgakbaaaaaaaaaaaegacbaaa
abaaaaaadcaaaaajhcaabaaaaaaaaaaaegbcbaaaaeaaaaaapgapbaaaaaaaaaaa
egacbaaaaaaaaaaaehaaaaalbcaabaaaaaaaaaaaegaabaaaaaaaaaaaaghabaaa
aaaaaaaaaagabaaaaaaaaaaackaabaaaaaaaaaaaaaaaaaajccaabaaaaaaaaaaa
akiacaiaebaaaaaaabaaaaaabiaaaaaaabeaaaaaaaaaiadpdcaaaaakbcaabaaa
aaaaaaaaakaabaaaaaaaaaaabkaabaaaaaaaaaaaakiacaaaabaaaaaabiaaaaaa
dccaaaalccaabaaaaaaaaaaadkbabaaaafaaaaaackiacaaaabaaaaaabiaaaaaa
dkiacaaaabaaaaaabiaaaaaaaacaaaahbccabaaaaaaaaaaabkaabaaaaaaaaaaa
akaabaaaaaaaaaaadcaaaaalbcaabaaaaaaaaaaadkbabaiaebaaaaaaafaaaaaa
dkiacaaaaaaaaaaaafaaaaaaabeaaaaaaaaaiadpdiaaaaakdcaabaaaaaaaaaaa
agaabaaaaaaaaaaaaceaaaaaaaaaiadpaaaahpedaaaaaaaaaaaaaaaabkaaaaaf
dcaabaaaaaaaaaaaegaabaaaaaaaaaaadcaaaaakeccabaaaaaaaaaaabkaabaia
ebaaaaaaaaaaaaaaabeaaaaaibiaiadlakaabaaaaaaaaaaadgaaaaaficcabaaa
aaaaaaaabkaabaaaaaaaaaaadgaaaaafcccabaaaaaaaaaaaabeaaaaaaaaaiadp
doaaaaab"
}

SubProgram "gles " {
Keywords { "SHADOWS_NATIVE" }
"!!GLES"
}

SubProgram "d3d11_9x " {
Keywords { "SHADOWS_NATIVE" }
ConstBuffer "UnityPerCamera" 128 // 96 used size, 8 vars
Vector 80 [_ProjectionParams] 4
ConstBuffer "UnityShadows" 416 // 400 used size, 8 vars
Vector 96 [_LightSplitsNear] 4
Vector 112 [_LightSplitsFar] 4
Vector 384 [_LightShadowData] 4
BindCB "UnityPerCamera" 0
BindCB "UnityShadows" 1
SetTexture 0 [_ShadowMapTexture] 2D 0
// 21 instructions, 2 temp regs, 0 temp arrays:
// ALU 15 float, 0 int, 2 uint
// TEX 0 (0 load, 1 comp, 0 bias, 0 grad)
// FLOW 1 static, 0 dynamic
"ps_4_0_level_9_1
eefiecedphcelgomhcehbhmgdplfpphjcngdocfgabaaaaaaiiagaaaaafaaaaaa
deaaaaaaeaacaaaaimafaaaajmafaaaafeagaaaaebgpgodjaeacaaaaaeacaaaa
aaacppppliabaaaaemaaaaaaadaaciaaaaaaemaaaaaaemaaabaaceaaaaaaemaa
aaaaaaaaaaaaafaaabaaaaaaaaaaaaaaabaaagaaacaaabaaaaaaaaaaabaabiaa
abaaadaaaaaaaaaaaaacppppfbaaaaafaeaaapkaaaaaaaaaaaaaiadpaaaahped
ibiaiadlbpaaaaacaaaaaaiaaaaaahlabpaaaaacaaaaaaiaabaaahlabpaaaaac
aaaaaaiaacaaahlabpaaaaacaaaaaaiaadaaahlabpaaaaacaaaaaaiaaeaaapla
bpaaaaacaaaaaajaaaaiapkaacaaaaadaaaaapiaaeaapplaacaaoekbfiaaaaae
aaaaapiaaaaaoeiaaeaaaakaaeaaffkaacaaaaadabaaapiaaeaapplaabaaoekb
fiaaaaaeaaaaapiaabaaoeiaaaaaoeiaaeaaaakaafaaaaadabaaahiaaaaaffia
abaaoelaaeaaaaaeabaaahiaaaaaoelaaaaaaaiaabaaoeiaaeaaaaaeaaaaahia
acaaoelaaaaakkiaabaaoeiaaeaaaaaeaaaaahiaadaaoelaaaaappiaaaaaoeia
ecaaaaadaaaacpiaaaaaoeiaaaaioekaabaaaaacaaaaaciaaeaaffkabcaaaaae
abaacbiaaaaaaaiaaaaaffiaadaaaakaaeaaaaaeaaaabbiaaeaapplaadaakkka
adaappkaacaaaaadabaadbiaaaaaaaiaabaaaaiaaeaaaaaeaaaaabiaaeaappla
aaaappkbaaaaffiaafaaaaadaaaaadiaaaaaaaiaaeaamjkabdaaaaacaaaaadia
aaaaoeiaaeaaaaaeabaaceiaaaaaffiaaeaappkbaaaaaaiaabaaaaacabaaciia
aaaaffiaabaaaaacabaaaciaaeaaffkaabaaaaacaaaicpiaabaaoeiappppaaaa
fdeieefceeadaaaaeaaaaaaanbaaaaaafjaaaaaeegiocaaaaaaaaaaaagaaaaaa
fjaaaaaeegiocaaaabaaaaaabjaaaaaafkaiaaadaagabaaaaaaaaaaafibiaaae
aahabaaaaaaaaaaaffffaaaagcbaaaadhcbabaaaabaaaaaagcbaaaadhcbabaaa
acaaaaaagcbaaaadhcbabaaaadaaaaaagcbaaaadhcbabaaaaeaaaaaagcbaaaad
icbabaaaafaaaaaagfaaaaadpccabaaaaaaaaaaagiaaaaacacaaaaaabnaaaaai
pcaabaaaaaaaaaaapgbpbaaaafaaaaaaegiocaaaabaaaaaaagaaaaaaabaaaaak
pcaabaaaaaaaaaaaegaobaaaaaaaaaaaaceaaaaaaaaaiadpaaaaiadpaaaaiadp
aaaaiadpdbaaaaaipcaabaaaabaaaaaapgbpbaaaafaaaaaaegiocaaaabaaaaaa
ahaaaaaaabaaaaakpcaabaaaabaaaaaaegaobaaaabaaaaaaaceaaaaaaaaaiadp
aaaaiadpaaaaiadpaaaaiadpdiaaaaahpcaabaaaaaaaaaaaegaobaaaaaaaaaaa
egaobaaaabaaaaaadiaaaaahhcaabaaaabaaaaaafgafbaaaaaaaaaaaegbcbaaa
acaaaaaadcaaaaajhcaabaaaabaaaaaaegbcbaaaabaaaaaaagaabaaaaaaaaaaa
egacbaaaabaaaaaadcaaaaajhcaabaaaaaaaaaaaegbcbaaaadaaaaaakgakbaaa
aaaaaaaaegacbaaaabaaaaaadcaaaaajhcaabaaaaaaaaaaaegbcbaaaaeaaaaaa
pgapbaaaaaaaaaaaegacbaaaaaaaaaaaehaaaaalbcaabaaaaaaaaaaaegaabaaa
aaaaaaaaaghabaaaaaaaaaaaaagabaaaaaaaaaaackaabaaaaaaaaaaaaaaaaaaj
ccaabaaaaaaaaaaaakiacaiaebaaaaaaabaaaaaabiaaaaaaabeaaaaaaaaaiadp
dcaaaaakbcaabaaaaaaaaaaaakaabaaaaaaaaaaabkaabaaaaaaaaaaaakiacaaa
abaaaaaabiaaaaaadccaaaalccaabaaaaaaaaaaadkbabaaaafaaaaaackiacaaa
abaaaaaabiaaaaaadkiacaaaabaaaaaabiaaaaaaaacaaaahbccabaaaaaaaaaaa
bkaabaaaaaaaaaaaakaabaaaaaaaaaaadcaaaaalbcaabaaaaaaaaaaadkbabaia
ebaaaaaaafaaaaaadkiacaaaaaaaaaaaafaaaaaaabeaaaaaaaaaiadpdiaaaaak
dcaabaaaaaaaaaaaagaabaaaaaaaaaaaaceaaaaaaaaaiadpaaaahpedaaaaaaaa
aaaaaaaabkaaaaafdcaabaaaaaaaaaaaegaabaaaaaaaaaaadcaaaaakeccabaaa
aaaaaaaabkaabaiaebaaaaaaaaaaaaaaabeaaaaaibiaiadlakaabaaaaaaaaaaa
dgaaaaaficcabaaaaaaaaaaabkaabaaaaaaaaaaadgaaaaafcccabaaaaaaaaaaa
abeaaaaaaaaaiadpdoaaaaabfdegejdaaiaaaaaaiaaaaaaaaaaaaaaaejfdeheo
laaaaaaaagaaaaaaaiaaaaaajiaaaaaaaaaaaaaaabaaaaaaadaaaaaaaaaaaaaa
apaaaaaakeaaaaaaaaaaaaaaaaaaaaaaadaaaaaaabaaaaaaahahaaaakeaaaaaa
abaaaaaaaaaaaaaaadaaaaaaacaaaaaaahahaaaakeaaaaaaacaaaaaaaaaaaaaa
adaaaaaaadaaaaaaahahaaaakeaaaaaaadaaaaaaaaaaaaaaadaaaaaaaeaaaaaa
ahahaaaakeaaaaaaaeaaaaaaaaaaaaaaadaaaaaaafaaaaaaapaiaaaafdfgfpfa
epfdejfeejepeoaafeeffiedepepfceeaaklklklepfdeheocmaaaaaaabaaaaaa
aiaaaaaacaaaaaaaaaaaaaaaaaaaaaaaadaaaaaaaaaaaaaaapaaaaaafdfgfpfe
gbhcghgfheaaklkl"
}

SubProgram "gles3 " {
Keywords { "SHADOWS_NATIVE" }
"!!GLES3"
}

SubProgram "opengl " {
Keywords { "SHADOWS_NONATIVE" "SHADOWS_SPLIT_SPHERES" }
Vector 0 [_ProjectionParams]
Vector 1 [unity_ShadowSplitSpheres0]
Vector 2 [unity_ShadowSplitSpheres1]
Vector 3 [unity_ShadowSplitSpheres2]
Vector 4 [unity_ShadowSplitSpheres3]
Vector 5 [unity_ShadowSplitSqRadii]
Vector 6 [_LightShadowData]
Vector 7 [unity_ShadowFadeCenterAndType]
SetTexture 0 [_ShadowMapTexture] 2D
"!!ARBfp1.0
OPTION ARB_precision_hint_fastest;
# 32 ALU, 1 TEX
PARAM c[9] = { program.local[0..7],
		{ 1, 255, 0.0039215689 } };
TEMP R0;
TEMP R1;
TEMP R2;
ADD R0.xyz, fragment.texcoord[4], -c[1];
ADD R2.xyz, fragment.texcoord[4], -c[4];
DP3 R0.x, R0, R0;
ADD R1.xyz, fragment.texcoord[4], -c[2];
DP3 R0.y, R1, R1;
ADD R1.xyz, fragment.texcoord[4], -c[3];
DP3 R0.w, R2, R2;
DP3 R0.z, R1, R1;
SLT R2, R0, c[5];
ADD_SAT R0.xyz, R2.yzww, -R2;
MUL R1.xyz, R0.x, fragment.texcoord[1];
MAD R1.xyz, R2.x, fragment.texcoord[0], R1;
MAD R1.xyz, R0.y, fragment.texcoord[2], R1;
MAD R0.xyz, fragment.texcoord[3], R0.z, R1;
ADD R1.xyz, -fragment.texcoord[4], c[7];
MOV result.color.y, c[8].x;
TEX R0.x, R0, texture[0], 2D;
ADD R0.y, R0.x, -R0.z;
DP3 R0.z, R1, R1;
RSQ R0.z, R0.z;
MOV R0.x, c[8];
CMP R0.x, R0.y, c[6], R0;
MUL R0.y, -fragment.texcoord[4].w, c[0].w;
ADD R0.y, R0, c[8].x;
RCP R1.x, R0.z;
MUL R0.zw, R0.y, c[8].xyxy;
MAD_SAT R0.y, R1.x, c[6].z, c[6].w;
FRC R0.zw, R0;
ADD_SAT result.color.x, R0, R0.y;
MOV R0.y, R0.w;
MAD R0.x, -R0.w, c[8].z, R0.z;
MOV result.color.zw, R0.xyxy;
END
# 32 instructions, 3 R-regs
"
}

SubProgram "d3d9 " {
Keywords { "SHADOWS_NONATIVE" "SHADOWS_SPLIT_SPHERES" }
Vector 0 [_ProjectionParams]
Vector 1 [unity_ShadowSplitSpheres0]
Vector 2 [unity_ShadowSplitSpheres1]
Vector 3 [unity_ShadowSplitSpheres2]
Vector 4 [unity_ShadowSplitSpheres3]
Vector 5 [unity_ShadowSplitSqRadii]
Vector 6 [_LightShadowData]
Vector 7 [unity_ShadowFadeCenterAndType]
SetTexture 0 [_ShadowMapTexture] 2D
"ps_2_0
; 37 ALU, 1 TEX
dcl_2d s0
def c8, 1.00000000, 255.00000000, 0.00392157, 0.00000000
dcl t0.xyz
dcl t1.xyz
dcl t2.xyz
dcl t3.xyz
dcl t4
add r0.xyz, t4, -c1
add r2.xyz, t4, -c4
dp3 r0.x, r0, r0
add r1.xyz, t4, -c2
dp3 r0.y, r1, r1
add r1.xyz, t4, -c3
dp3 r0.z, r1, r1
dp3 r0.w, r2, r2
add r0, r0, -c5
cmp r0, r0, c8.w, c8.x
mov r1.x, r0.y
mov r1.z, r0.w
mov r1.y, r0.z
add_sat r1.xyz, r1, -r0
mul r2.xyz, r1.x, t1
mad r0.xyz, r0.x, t0, r2
mad r0.xyz, r1.y, t2, r0
mad r1.xyz, t3, r1.z, r0
add r2.xyz, -t4, c7
texld r0, r1, s0
mov r1.x, c6
add r0.x, r0, -r1.z
cmp r0.x, r0, c8, r1
dp3 r1.x, r2, r2
mul r2.x, -t4.w, c0.w
rsq r1.x, r1.x
add r2.x, r2, c8
rcp r1.x, r1.x
mad_sat r1.x, r1, c6.z, c6.w
mul r2.xy, r2.x, c8
frc r2.xy, r2
add_sat r0.x, r0, r1
mov r1.y, r2
mad r1.x, -r2.y, c8.z, r2
mov r0.w, r1.y
mov r0.z, r1.x
mov r0.y, c8.x
mov_pp oC0, r0
"
}

SubProgram "gles " {
Keywords { "SHADOWS_NONATIVE" "SHADOWS_SPLIT_SPHERES" }
"!!GLES"
}

SubProgram "glesdesktop " {
Keywords { "SHADOWS_NONATIVE" "SHADOWS_SPLIT_SPHERES" }
"!!GLES"
}

SubProgram "flash " {
Keywords { "SHADOWS_NONATIVE" "SHADOWS_SPLIT_SPHERES" }
Vector 0 [_ProjectionParams]
Vector 1 [unity_ShadowSplitSpheres0]
Vector 2 [unity_ShadowSplitSpheres1]
Vector 3 [unity_ShadowSplitSpheres2]
Vector 4 [unity_ShadowSplitSpheres3]
Vector 5 [unity_ShadowSplitSqRadii]
Vector 6 [_LightShadowData]
Vector 7 [unity_ShadowFadeCenterAndType]
SetTexture 0 [_ShadowMapTexture] 2D
"agal_ps
c8 1.0 255.0 0.003922 0.0
c9 1.0 0.003922 0.000015 0.0
[bc]
acaaaaaaaaaaahacaeaaaaoeaeaaaaaaabaaaaoeabaaaaaa sub r0.xyz, v4, c1
acaaaaaaacaaahacaeaaaaoeaeaaaaaaaeaaaaoeabaaaaaa sub r2.xyz, v4, c4
bcaaaaaaaaaaabacaaaaaakeacaaaaaaaaaaaakeacaaaaaa dp3 r0.x, r0.xyzz, r0.xyzz
acaaaaaaabaaahacaeaaaaoeaeaaaaaaacaaaaoeabaaaaaa sub r1.xyz, v4, c2
bcaaaaaaaaaaacacabaaaakeacaaaaaaabaaaakeacaaaaaa dp3 r0.y, r1.xyzz, r1.xyzz
acaaaaaaabaaahacaeaaaaoeaeaaaaaaadaaaaoeabaaaaaa sub r1.xyz, v4, c3
bcaaaaaaaaaaaeacabaaaakeacaaaaaaabaaaakeacaaaaaa dp3 r0.z, r1.xyzz, r1.xyzz
bcaaaaaaaaaaaiacacaaaakeacaaaaaaacaaaakeacaaaaaa dp3 r0.w, r2.xyzz, r2.xyzz
acaaaaaaaaaaapacaaaaaaoeacaaaaaaafaaaaoeabaaaaaa sub r0, r0, c5
ckaaaaaaadaaapacaaaaaaoeacaaaaaaaiaaaappabaaaaaa slt r3, r0, c8.w
aaaaaaaaaeaaapacaiaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov r4, c8
aaaaaaaaabaaaiacaiaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov r1.w, c8
acaaaaaaaeaaapacaeaaaaaaacaaaaaaabaaaappacaaaaaa sub r4, r4.x, r1.w
adaaaaaaaaaaapacaeaaaaoeacaaaaaaadaaaaoeacaaaaaa mul r0, r4, r3
abaaaaaaaaaaapacaaaaaaoeacaaaaaaaiaaaappabaaaaaa add r0, r0, c8.w
aaaaaaaaabaaabacaaaaaaffacaaaaaaaaaaaaaaaaaaaaaa mov r1.x, r0.y
aaaaaaaaabaaaeacaaaaaappacaaaaaaaaaaaaaaaaaaaaaa mov r1.z, r0.w
aaaaaaaaabaaacacaaaaaakkacaaaaaaaaaaaaaaaaaaaaaa mov r1.y, r0.z
acaaaaaaabaaahacabaaaakeacaaaaaaaaaaaakeacaaaaaa sub r1.xyz, r1.xyzz, r0.xyzz
bgaaaaaaabaaahacabaaaakeacaaaaaaaaaaaaaaaaaaaaaa sat r1.xyz, r1.xyzz
adaaaaaaacaaahacabaaaaaaacaaaaaaabaaaaoeaeaaaaaa mul r2.xyz, r1.x, v1
adaaaaaaaaaaahacaaaaaaaaacaaaaaaaaaaaaoeaeaaaaaa mul r0.xyz, r0.x, v0
abaaaaaaaaaaahacaaaaaakeacaaaaaaacaaaakeacaaaaaa add r0.xyz, r0.xyzz, r2.xyzz
adaaaaaaadaaahacabaaaaffacaaaaaaacaaaaoeaeaaaaaa mul r3.xyz, r1.y, v2
abaaaaaaaaaaahacadaaaakeacaaaaaaaaaaaakeacaaaaaa add r0.xyz, r3.xyzz, r0.xyzz
adaaaaaaabaaahacadaaaaoeaeaaaaaaabaaaakkacaaaaaa mul r1.xyz, v3, r1.z
abaaaaaaabaaahacabaaaakeacaaaaaaaaaaaakeacaaaaaa add r1.xyz, r1.xyzz, r0.xyzz
bfaaaaaaacaaahacaeaaaaoeaeaaaaaaaaaaaaaaaaaaaaaa neg r2.xyz, v4
abaaaaaaacaaahacacaaaakeacaaaaaaahaaaaoeabaaaaaa add r2.xyz, r2.xyzz, c7
ciaaaaaaaaaaapacabaaaafeacaaaaaaaaaaaaaaafaababb tex r0, r1.xyyy, s0 <2d wrap linear point>
bdaaaaaaaaaaabacaaaaaaoeacaaaaaaajaaaaoeabaaaaaa dp4 r0.x, r0, c9
aaaaaaaaabaaabacagaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov r1.x, c6
acaaaaaaaaaaabacaaaaaaaaacaaaaaaabaaaakkacaaaaaa sub r0.x, r0.x, r1.z
ckaaaaaaaeaaabacaaaaaaaaacaaaaaaaiaaaappabaaaaaa slt r4.x, r0.x, c8.w
acaaaaaaadaaabacabaaaaaaacaaaaaaaiaaaaoeabaaaaaa sub r3.x, r1.x, c8
adaaaaaaaaaaabacadaaaaaaacaaaaaaaeaaaaaaacaaaaaa mul r0.x, r3.x, r4.x
abaaaaaaaaaaabacaaaaaaaaacaaaaaaaiaaaaoeabaaaaaa add r0.x, r0.x, c8
bcaaaaaaabaaabacacaaaakeacaaaaaaacaaaakeacaaaaaa dp3 r1.x, r2.xyzz, r2.xyzz
bfaaaaaaaeaaaiacaeaaaappaeaaaaaaaaaaaaaaaaaaaaaa neg r4.w, v4.w
adaaaaaaacaaabacaeaaaappacaaaaaaaaaaaappabaaaaaa mul r2.x, r4.w, c0.w
akaaaaaaabaaabacabaaaaaaacaaaaaaaaaaaaaaaaaaaaaa rsq r1.x, r1.x
abaaaaaaacaaabacacaaaaaaacaaaaaaaiaaaaoeabaaaaaa add r2.x, r2.x, c8
afaaaaaaabaaabacabaaaaaaacaaaaaaaaaaaaaaaaaaaaaa rcp r1.x, r1.x
adaaaaaaabaaabacabaaaaaaacaaaaaaagaaaakkabaaaaaa mul r1.x, r1.x, c6.z
abaaaaaaabaaabacabaaaaaaacaaaaaaagaaaappabaaaaaa add r1.x, r1.x, c6.w
bgaaaaaaabaaabacabaaaaaaacaaaaaaaaaaaaaaaaaaaaaa sat r1.x, r1.x
adaaaaaaacaaadacacaaaaaaacaaaaaaaiaaaaoeabaaaaaa mul r2.xy, r2.x, c8
aiaaaaaaacaaadacacaaaafeacaaaaaaaaaaaaaaaaaaaaaa frc r2.xy, r2.xyyy
abaaaaaaaaaaabacaaaaaaaaacaaaaaaabaaaaaaacaaaaaa add r0.x, r0.x, r1.x
bgaaaaaaaaaaabacaaaaaaaaacaaaaaaaaaaaaaaaaaaaaaa sat r0.x, r0.x
aaaaaaaaabaaacacacaaaaffacaaaaaaaaaaaaaaaaaaaaaa mov r1.y, r2.y
bfaaaaaaadaaacacacaaaaffacaaaaaaaaaaaaaaaaaaaaaa neg r3.y, r2.y
adaaaaaaabaaabacadaaaaffacaaaaaaaiaaaakkabaaaaaa mul r1.x, r3.y, c8.z
abaaaaaaabaaabacabaaaaaaacaaaaaaacaaaaaaacaaaaaa add r1.x, r1.x, r2.x
aaaaaaaaaaaaaiacabaaaaffacaaaaaaaaaaaaaaaaaaaaaa mov r0.w, r1.y
aaaaaaaaaaaaaeacabaaaaaaacaaaaaaaaaaaaaaaaaaaaaa mov r0.z, r1.x
aaaaaaaaaaaaacacaiaaaaaaabaaaaaaaaaaaaaaaaaaaaaa mov r0.y, c8.x
aaaaaaaaaaaaapadaaaaaaoeacaaaaaaaaaaaaaaaaaaaaaa mov o0, r0
"
}

SubProgram "opengl " {
Keywords { "SHADOWS_NATIVE" "SHADOWS_SPLIT_SPHERES" }
Vector 0 [_ProjectionParams]
Vector 1 [unity_ShadowSplitSpheres0]
Vector 2 [unity_ShadowSplitSpheres1]
Vector 3 [unity_ShadowSplitSpheres2]
Vector 4 [unity_ShadowSplitSpheres3]
Vector 5 [unity_ShadowSplitSqRadii]
Vector 6 [_LightShadowData]
Vector 7 [unity_ShadowFadeCenterAndType]
SetTexture 0 [_ShadowMapTexture] 2D
"!!ARBfp1.0
OPTION ARB_precision_hint_fastest;
# 32 ALU, 1 TEX
OPTION ARB_fragment_program_shadow;
PARAM c[9] = { program.local[0..7],
		{ 1, 255, 0.0039215689 } };
TEMP R0;
TEMP R1;
TEMP R2;
ADD R0.xyz, fragment.texcoord[4], -c[1];
ADD R2.xyz, fragment.texcoord[4], -c[4];
DP3 R0.x, R0, R0;
ADD R1.xyz, fragment.texcoord[4], -c[2];
DP3 R0.y, R1, R1;
ADD R1.xyz, fragment.texcoord[4], -c[3];
DP3 R0.w, R2, R2;
DP3 R0.z, R1, R1;
SLT R2, R0, c[5];
ADD_SAT R0.xyz, R2.yzww, -R2;
MUL R1.xyz, R0.x, fragment.texcoord[1];
MAD R1.xyz, R2.x, fragment.texcoord[0], R1;
MAD R1.xyz, R0.y, fragment.texcoord[2], R1;
MAD R0.xyz, fragment.texcoord[3], R0.z, R1;
ADD R1.xyz, -fragment.texcoord[4], c[7];
MOV result.color.y, c[8].x;
TEX R0.x, R0, texture[0], SHADOW2D;
DP3 R0.z, R1, R1;
RSQ R0.z, R0.z;
MOV R0.y, c[8].x;
ADD R0.y, R0, -c[6].x;
MAD R0.x, R0, R0.y, c[6];
MUL R0.y, -fragment.texcoord[4].w, c[0].w;
ADD R0.y, R0, c[8].x;
RCP R1.x, R0.z;
MUL R0.zw, R0.y, c[8].xyxy;
MAD_SAT R0.y, R1.x, c[6].z, c[6].w;
FRC R0.zw, R0;
ADD_SAT result.color.x, R0, R0.y;
MOV R0.y, R0.w;
MAD R0.x, -R0.w, c[8].z, R0.z;
MOV result.color.zw, R0.xyxy;
END
# 32 instructions, 3 R-regs
"
}

SubProgram "d3d9 " {
Keywords { "SHADOWS_NATIVE" "SHADOWS_SPLIT_SPHERES" }
Vector 0 [_ProjectionParams]
Vector 1 [unity_ShadowSplitSpheres0]
Vector 2 [unity_ShadowSplitSpheres1]
Vector 3 [unity_ShadowSplitSpheres2]
Vector 4 [unity_ShadowSplitSpheres3]
Vector 5 [unity_ShadowSplitSqRadii]
Vector 6 [_LightShadowData]
Vector 7 [unity_ShadowFadeCenterAndType]
SetTexture 0 [_ShadowMapTexture] 2D
"ps_2_0
; 37 ALU, 1 TEX
dcl_2d s0
def c8, 0.00000000, 1.00000000, 255.00000000, 0.00392157
dcl t0.xyz
dcl t1.xyz
dcl t2.xyz
dcl t3.xyz
dcl t4
add r0.xyz, t4, -c1
add r2.xyz, t4, -c4
dp3 r0.x, r0, r0
add r1.xyz, t4, -c2
dp3 r0.y, r1, r1
add r1.xyz, t4, -c3
dp3 r0.z, r1, r1
dp3 r0.w, r2, r2
add r0, r0, -c5
cmp r0, r0, c8.x, c8.y
mov r1.x, r0.y
mov r1.z, r0.w
mov r1.y, r0.z
add_sat r1.xyz, r1, -r0
mul r2.xyz, r1.x, t1
mad r0.xyz, r0.x, t0, r2
mad r0.xyz, r1.y, t2, r0
mad r0.xyz, t3, r1.z, r0
add r1.xyz, -t4, c7
dp3 r1.x, r1, r1
rsq r1.x, r1.x
rcp r1.x, r1.x
mad_sat r1.x, r1, c6.z, c6.w
texld r2, r0, s0
mov r0.x, c6
add r0.x, c8.y, -r0
mad r0.x, r2, r0, c6
mul r2.x, -t4.w, c0.w
add r2.x, r2, c8.y
mul r2.xy, r2.x, c8.yzxw
frc r2.xy, r2
add_sat r0.x, r0, r1
mov r1.y, r2
mad r1.x, -r2.y, c8.w, r2
mov r0.w, r1.y
mov r0.z, r1.x
mov r0.y, c8
mov_pp oC0, r0
"
}

SubProgram "d3d11 " {
Keywords { "SHADOWS_NATIVE" "SHADOWS_SPLIT_SPHERES" }
ConstBuffer "UnityPerCamera" 128 // 96 used size, 8 vars
Vector 80 [_ProjectionParams] 4
ConstBuffer "UnityShadows" 416 // 416 used size, 8 vars
Vector 0 [unity_ShadowSplitSpheres0] 4
Vector 16 [unity_ShadowSplitSpheres1] 4
Vector 32 [unity_ShadowSplitSpheres2] 4
Vector 48 [unity_ShadowSplitSpheres3] 4
Vector 64 [unity_ShadowSplitSqRadii] 4
Vector 384 [_LightShadowData] 4
Vector 400 [unity_ShadowFadeCenterAndType] 4
BindCB "UnityPerCamera" 0
BindCB "UnityShadows" 1
SetTexture 0 [_ShadowMapTexture] 2D 0
// 32 instructions, 2 temp regs, 0 temp arrays:
// ALU 26 float, 0 int, 1 uint
// TEX 0 (0 load, 1 comp, 0 bias, 0 grad)
// FLOW 1 static, 0 dynamic
"ps_4_0
eefiecedehfdffddekigboeafomdgidfgeolncnbabaaaaaaneafaaaaadaaaaaa
cmaaaaaaoeaaaaaabiabaaaaejfdeheolaaaaaaaagaaaaaaaiaaaaaajiaaaaaa
aaaaaaaaabaaaaaaadaaaaaaaaaaaaaaapaaaaaakeaaaaaaaaaaaaaaaaaaaaaa
adaaaaaaabaaaaaaahahaaaakeaaaaaaabaaaaaaaaaaaaaaadaaaaaaacaaaaaa
ahahaaaakeaaaaaaacaaaaaaaaaaaaaaadaaaaaaadaaaaaaahahaaaakeaaaaaa
adaaaaaaaaaaaaaaadaaaaaaaeaaaaaaahahaaaakeaaaaaaaeaaaaaaaaaaaaaa
adaaaaaaafaaaaaaapapaaaafdfgfpfaepfdejfeejepeoaafeeffiedepepfcee
aaklklklepfdeheocmaaaaaaabaaaaaaaiaaaaaacaaaaaaaaaaaaaaaaaaaaaaa
adaaaaaaaaaaaaaaapaaaaaafdfgfpfegbhcghgfheaaklklfdeieefcleaeaaaa
eaaaaaaacnabaaaafjaaaaaeegiocaaaaaaaaaaaagaaaaaafjaaaaaeegiocaaa
abaaaaaabkaaaaaafkaiaaadaagabaaaaaaaaaaafibiaaaeaahabaaaaaaaaaaa
ffffaaaagcbaaaadhcbabaaaabaaaaaagcbaaaadhcbabaaaacaaaaaagcbaaaad
hcbabaaaadaaaaaagcbaaaadhcbabaaaaeaaaaaagcbaaaadpcbabaaaafaaaaaa
gfaaaaadpccabaaaaaaaaaaagiaaaaacacaaaaaaaaaaaaajhcaabaaaaaaaaaaa
egbcbaaaafaaaaaaegiccaiaebaaaaaaabaaaaaaaaaaaaaabaaaaaahbcaabaaa
aaaaaaaaegacbaaaaaaaaaaaegacbaaaaaaaaaaaaaaaaaajhcaabaaaabaaaaaa
egbcbaaaafaaaaaaegiccaiaebaaaaaaabaaaaaaabaaaaaabaaaaaahccaabaaa
aaaaaaaaegacbaaaabaaaaaaegacbaaaabaaaaaaaaaaaaajhcaabaaaabaaaaaa
egbcbaaaafaaaaaaegiccaiaebaaaaaaabaaaaaaacaaaaaabaaaaaahecaabaaa
aaaaaaaaegacbaaaabaaaaaaegacbaaaabaaaaaaaaaaaaajhcaabaaaabaaaaaa
egbcbaaaafaaaaaaegiccaiaebaaaaaaabaaaaaaadaaaaaabaaaaaahicaabaaa
aaaaaaaaegacbaaaabaaaaaaegacbaaaabaaaaaadbaaaaaipcaabaaaaaaaaaaa
egaobaaaaaaaaaaaegiocaaaabaaaaaaaeaaaaaadhaaaaaphcaabaaaabaaaaaa
egacbaaaaaaaaaaaaceaaaaaaaaaialpaaaaialpaaaaialpaaaaaaaaaceaaaaa
aaaaaaiaaaaaaaiaaaaaaaiaaaaaaaaaabaaaaakpcaabaaaaaaaaaaaegaobaaa
aaaaaaaaaceaaaaaaaaaiadpaaaaiadpaaaaiadpaaaaiadpaaaaaaahocaabaaa
aaaaaaaaagajbaaaabaaaaaafgaobaaaaaaaaaaadeaaaaakocaabaaaaaaaaaaa
fgaobaaaaaaaaaaaaceaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaadiaaaaah
hcaabaaaabaaaaaafgafbaaaaaaaaaaaegbcbaaaacaaaaaadcaaaaajhcaabaaa
abaaaaaaegbcbaaaabaaaaaaagaabaaaaaaaaaaaegacbaaaabaaaaaadcaaaaaj
hcaabaaaaaaaaaaaegbcbaaaadaaaaaakgakbaaaaaaaaaaaegacbaaaabaaaaaa
dcaaaaajhcaabaaaaaaaaaaaegbcbaaaaeaaaaaapgapbaaaaaaaaaaaegacbaaa
aaaaaaaaehaaaaalbcaabaaaaaaaaaaaegaabaaaaaaaaaaaaghabaaaaaaaaaaa
aagabaaaaaaaaaaackaabaaaaaaaaaaaaaaaaaajccaabaaaaaaaaaaaakiacaia
ebaaaaaaabaaaaaabiaaaaaaabeaaaaaaaaaiadpdcaaaaakbcaabaaaaaaaaaaa
akaabaaaaaaaaaaabkaabaaaaaaaaaaaakiacaaaabaaaaaabiaaaaaaaaaaaaaj
ocaabaaaaaaaaaaaagbjbaaaafaaaaaaagijcaiaebaaaaaaabaaaaaabjaaaaaa
baaaaaahccaabaaaaaaaaaaajgahbaaaaaaaaaaajgahbaaaaaaaaaaaelaaaaaf
ccaabaaaaaaaaaaabkaabaaaaaaaaaaadccaaaalccaabaaaaaaaaaaabkaabaaa
aaaaaaaackiacaaaabaaaaaabiaaaaaadkiacaaaabaaaaaabiaaaaaaaacaaaah
bccabaaaaaaaaaaabkaabaaaaaaaaaaaakaabaaaaaaaaaaadcaaaaalbcaabaaa
aaaaaaaadkbabaiaebaaaaaaafaaaaaadkiacaaaaaaaaaaaafaaaaaaabeaaaaa
aaaaiadpdiaaaaakdcaabaaaaaaaaaaaagaabaaaaaaaaaaaaceaaaaaaaaaiadp
aaaahpedaaaaaaaaaaaaaaaabkaaaaafdcaabaaaaaaaaaaaegaabaaaaaaaaaaa
dcaaaaakeccabaaaaaaaaaaabkaabaiaebaaaaaaaaaaaaaaabeaaaaaibiaiadl
akaabaaaaaaaaaaadgaaaaaficcabaaaaaaaaaaabkaabaaaaaaaaaaadgaaaaaf
cccabaaaaaaaaaaaabeaaaaaaaaaiadpdoaaaaab"
}

SubProgram "gles " {
Keywords { "SHADOWS_NATIVE" "SHADOWS_SPLIT_SPHERES" }
"!!GLES"
}

SubProgram "d3d11_9x " {
Keywords { "SHADOWS_NATIVE" "SHADOWS_SPLIT_SPHERES" }
ConstBuffer "UnityPerCamera" 128 // 96 used size, 8 vars
Vector 80 [_ProjectionParams] 4
ConstBuffer "UnityShadows" 416 // 416 used size, 8 vars
Vector 0 [unity_ShadowSplitSpheres0] 4
Vector 16 [unity_ShadowSplitSpheres1] 4
Vector 32 [unity_ShadowSplitSpheres2] 4
Vector 48 [unity_ShadowSplitSpheres3] 4
Vector 64 [unity_ShadowSplitSqRadii] 4
Vector 384 [_LightShadowData] 4
Vector 400 [unity_ShadowFadeCenterAndType] 4
BindCB "UnityPerCamera" 0
BindCB "UnityShadows" 1
SetTexture 0 [_ShadowMapTexture] 2D 0
// 32 instructions, 2 temp regs, 0 temp arrays:
// ALU 26 float, 0 int, 1 uint
// TEX 0 (0 load, 1 comp, 0 bias, 0 grad)
// FLOW 1 static, 0 dynamic
"ps_4_0_level_9_1
eefiecednjimmkpkglhenecngjmdodgjnmhighkaabaaaaaaoiaiaaaaafaaaaaa
deaaaaaadaadaaaaomahaaaapmahaaaaleaiaaaaebgpgodjpeacaaaapeacaaaa
aaacppppkiacaaaaemaaaaaaadaaciaaaaaaemaaaaaaemaaabaaceaaaaaaemaa
aaaaaaaaaaaaafaaabaaaaaaaaaaaaaaabaaaaaaafaaabaaaaaaaaaaabaabiaa
acaaagaaaaaaaaaaaaacppppfbaaaaafaiaaapkaaaaaiadpaaaahpedibiaiadl
aaaaaaaafbaaaaafajaaapkaaaaaaaaaaaaaiadpaaaaaaiaaaaaialpbpaaaaac
aaaaaaiaaaaaahlabpaaaaacaaaaaaiaabaaahlabpaaaaacaaaaaaiaacaaahla
bpaaaaacaaaaaaiaadaaahlabpaaaaacaaaaaaiaaeaaaplabpaaaaacaaaaaaja
aaaiapkaacaaaaadaaaaahiaaeaaoelaabaaoekbaiaaaaadaaaaabiaaaaaoeia
aaaaoeiaacaaaaadabaaahiaaeaaoelaacaaoekbaiaaaaadaaaaaciaabaaoeia
abaaoeiaacaaaaadabaaahiaaeaaoelaadaaoekbaiaaaaadaaaaaeiaabaaoeia
abaaoeiaacaaaaadabaaahiaaeaaoelaaeaaoekbaiaaaaadaaaaaiiaabaaoeia
abaaoeiaacaaaaadaaaaapiaaaaaoeiaafaaoekbfiaaaaaeabaaahiaaaaaoeia
ajaakkkaajaappkafiaaaaaeaaaaapiaaaaaoeiaajaaaakaajaaffkaacaaaaad
acaaadiaabaaoeiaaaaamjiaacaaaaadacaaaeiaabaakkiaaaaappiaalaaaaad
aaaaaoiaacaabliaajaaaakaafaaaaadabaaahiaaaaappiaabaaoelaaeaaaaae
abaaahiaaaaaoelaaaaaaaiaabaaoeiaaeaaaaaeabaaahiaacaaoelaaaaakkia
abaaoeiaaeaaaaaeaaaaahiaadaaoelaaaaaffiaabaaoeiaecaaaaadaaaacpia
aaaaoeiaaaaioekaabaaaaacaaaaaciaajaaffkabcaaaaaeabaacbiaaaaaaaia
aaaaffiaagaaaakaacaaaaadacaaahiaaeaaoelaahaaoekbaiaaaaadaaaaabia
acaaoeiaacaaoeiaahaaaaacaaaaabiaaaaaaaiaagaaaaacaaaaabiaaaaaaaia
aeaaaaaeaaaabbiaaaaaaaiaagaakkkaagaappkaacaaaaadabaadbiaaaaaaaia
abaaaaiaaeaaaaaeaaaaabiaaeaapplaaaaappkbaaaaffiaafaaaaadaaaaadia
aaaaaaiaaiaaoekabdaaaaacaaaaadiaaaaaoeiaaeaaaaaeabaaceiaaaaaffia
aiaakkkbaaaaaaiaabaaaaacabaaciiaaaaaffiaabaaaaacabaacciaajaaffka
abaaaaacaaaicpiaabaaoeiappppaaaafdeieefcleaeaaaaeaaaaaaacnabaaaa
fjaaaaaeegiocaaaaaaaaaaaagaaaaaafjaaaaaeegiocaaaabaaaaaabkaaaaaa
fkaiaaadaagabaaaaaaaaaaafibiaaaeaahabaaaaaaaaaaaffffaaaagcbaaaad
hcbabaaaabaaaaaagcbaaaadhcbabaaaacaaaaaagcbaaaadhcbabaaaadaaaaaa
gcbaaaadhcbabaaaaeaaaaaagcbaaaadpcbabaaaafaaaaaagfaaaaadpccabaaa
aaaaaaaagiaaaaacacaaaaaaaaaaaaajhcaabaaaaaaaaaaaegbcbaaaafaaaaaa
egiccaiaebaaaaaaabaaaaaaaaaaaaaabaaaaaahbcaabaaaaaaaaaaaegacbaaa
aaaaaaaaegacbaaaaaaaaaaaaaaaaaajhcaabaaaabaaaaaaegbcbaaaafaaaaaa
egiccaiaebaaaaaaabaaaaaaabaaaaaabaaaaaahccaabaaaaaaaaaaaegacbaaa
abaaaaaaegacbaaaabaaaaaaaaaaaaajhcaabaaaabaaaaaaegbcbaaaafaaaaaa
egiccaiaebaaaaaaabaaaaaaacaaaaaabaaaaaahecaabaaaaaaaaaaaegacbaaa
abaaaaaaegacbaaaabaaaaaaaaaaaaajhcaabaaaabaaaaaaegbcbaaaafaaaaaa
egiccaiaebaaaaaaabaaaaaaadaaaaaabaaaaaahicaabaaaaaaaaaaaegacbaaa
abaaaaaaegacbaaaabaaaaaadbaaaaaipcaabaaaaaaaaaaaegaobaaaaaaaaaaa
egiocaaaabaaaaaaaeaaaaaadhaaaaaphcaabaaaabaaaaaaegacbaaaaaaaaaaa
aceaaaaaaaaaialpaaaaialpaaaaialpaaaaaaaaaceaaaaaaaaaaaiaaaaaaaia
aaaaaaiaaaaaaaaaabaaaaakpcaabaaaaaaaaaaaegaobaaaaaaaaaaaaceaaaaa
aaaaiadpaaaaiadpaaaaiadpaaaaiadpaaaaaaahocaabaaaaaaaaaaaagajbaaa
abaaaaaafgaobaaaaaaaaaaadeaaaaakocaabaaaaaaaaaaafgaobaaaaaaaaaaa
aceaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaadiaaaaahhcaabaaaabaaaaaa
fgafbaaaaaaaaaaaegbcbaaaacaaaaaadcaaaaajhcaabaaaabaaaaaaegbcbaaa
abaaaaaaagaabaaaaaaaaaaaegacbaaaabaaaaaadcaaaaajhcaabaaaaaaaaaaa
egbcbaaaadaaaaaakgakbaaaaaaaaaaaegacbaaaabaaaaaadcaaaaajhcaabaaa
aaaaaaaaegbcbaaaaeaaaaaapgapbaaaaaaaaaaaegacbaaaaaaaaaaaehaaaaal
bcaabaaaaaaaaaaaegaabaaaaaaaaaaaaghabaaaaaaaaaaaaagabaaaaaaaaaaa
ckaabaaaaaaaaaaaaaaaaaajccaabaaaaaaaaaaaakiacaiaebaaaaaaabaaaaaa
biaaaaaaabeaaaaaaaaaiadpdcaaaaakbcaabaaaaaaaaaaaakaabaaaaaaaaaaa
bkaabaaaaaaaaaaaakiacaaaabaaaaaabiaaaaaaaaaaaaajocaabaaaaaaaaaaa
agbjbaaaafaaaaaaagijcaiaebaaaaaaabaaaaaabjaaaaaabaaaaaahccaabaaa
aaaaaaaajgahbaaaaaaaaaaajgahbaaaaaaaaaaaelaaaaafccaabaaaaaaaaaaa
bkaabaaaaaaaaaaadccaaaalccaabaaaaaaaaaaabkaabaaaaaaaaaaackiacaaa
abaaaaaabiaaaaaadkiacaaaabaaaaaabiaaaaaaaacaaaahbccabaaaaaaaaaaa
bkaabaaaaaaaaaaaakaabaaaaaaaaaaadcaaaaalbcaabaaaaaaaaaaadkbabaia
ebaaaaaaafaaaaaadkiacaaaaaaaaaaaafaaaaaaabeaaaaaaaaaiadpdiaaaaak
dcaabaaaaaaaaaaaagaabaaaaaaaaaaaaceaaaaaaaaaiadpaaaahpedaaaaaaaa
aaaaaaaabkaaaaafdcaabaaaaaaaaaaaegaabaaaaaaaaaaadcaaaaakeccabaaa
aaaaaaaabkaabaiaebaaaaaaaaaaaaaaabeaaaaaibiaiadlakaabaaaaaaaaaaa
dgaaaaaficcabaaaaaaaaaaabkaabaaaaaaaaaaadgaaaaafcccabaaaaaaaaaaa
abeaaaaaaaaaiadpdoaaaaabfdegejdaaiaaaaaaiaaaaaaaaaaaaaaaejfdeheo
laaaaaaaagaaaaaaaiaaaaaajiaaaaaaaaaaaaaaabaaaaaaadaaaaaaaaaaaaaa
apaaaaaakeaaaaaaaaaaaaaaaaaaaaaaadaaaaaaabaaaaaaahahaaaakeaaaaaa
abaaaaaaaaaaaaaaadaaaaaaacaaaaaaahahaaaakeaaaaaaacaaaaaaaaaaaaaa
adaaaaaaadaaaaaaahahaaaakeaaaaaaadaaaaaaaaaaaaaaadaaaaaaaeaaaaaa
ahahaaaakeaaaaaaaeaaaaaaaaaaaaaaadaaaaaaafaaaaaaapapaaaafdfgfpfa
epfdejfeejepeoaafeeffiedepepfceeaaklklklepfdeheocmaaaaaaabaaaaaa
aiaaaaaacaaaaaaaaaaaaaaaaaaaaaaaadaaaaaaaaaaaaaaapaaaaaafdfgfpfe
gbhcghgfheaaklkl"
}

SubProgram "gles3 " {
Keywords { "SHADOWS_NATIVE" "SHADOWS_SPLIT_SPHERES" }
"!!GLES3"
}

}

#LINE 163


		}
		
		Pass {
            Tags {"LightMode" = "ForwardAdd"} 
            Blend One One                                      
            Program "vp" {
// Vertex combos: 5
//   opengl - ALU: 10 to 19
//   d3d9 - ALU: 12 to 21
//   d3d11 - ALU: 8 to 17, TEX: 0 to 0, FLOW: 1 to 1
//   d3d11_9x - ALU: 8 to 17, TEX: 0 to 0, FLOW: 1 to 1
SubProgram "opengl " {
Keywords { "POINT" }
Bind "vertex" Vertex
Bind "color" Color
Bind "normal" Normal
Vector 17 [_WorldSpaceLightPos0]
Matrix 5 [_Object2World]
Matrix 9 [_World2Object]
Vector 18 [unity_Scale]
Matrix 13 [_LightMatrix0]
"!!ARBvp1.0
# 18 ALU
PARAM c[19] = { program.local[0],
		state.matrix.mvp,
		program.local[5..18] };
TEMP R0;
TEMP R1;
MOV R1, c[17];
DP4 R0.w, vertex.position, c[8];
DP4 R0.z, R1, c[11];
DP4 R0.x, R1, c[9];
DP4 R0.y, R1, c[10];
MAD result.texcoord[2].xyz, R0, c[18].w, -vertex.position;
DP4 R0.z, vertex.position, c[7];
DP4 R0.x, vertex.position, c[5];
DP4 R0.y, vertex.position, c[6];
DP4 result.texcoord[3].z, R0, c[15];
DP4 result.texcoord[3].y, R0, c[14];
DP4 result.texcoord[3].x, R0, c[13];
MOV result.texcoord[5], vertex.color;
MOV result.texcoord[1].xyz, vertex.normal;
DP4 result.position.w, vertex.position, c[4];
DP4 result.position.z, vertex.position, c[3];
DP4 result.position.y, vertex.position, c[2];
DP4 result.position.x, vertex.position, c[1];
END
# 18 instructions, 2 R-regs
"
}

SubProgram "d3d9 " {
Keywords { "POINT" }
Bind "vertex" Vertex
Bind "color" Color
Bind "normal" Normal
Matrix 0 [glstate_matrix_mvp]
Vector 16 [_WorldSpaceLightPos0]
Matrix 4 [_Object2World]
Matrix 8 [_World2Object]
Vector 17 [unity_Scale]
Matrix 12 [_LightMatrix0]
"vs_2_0
; 20 ALU
dcl_position0 v0
dcl_color0 v1
dcl_normal0 v2
mov r0, c10
dp4 r2.z, c16, r0
mov r0, c9
dp4 r2.y, c16, r0
mov r1, c8
dp4 r2.x, c16, r1
dp4 r0.w, v0, c7
dp4 r0.z, v0, c6
dp4 r0.x, v0, c4
dp4 r0.y, v0, c5
mad oT2.xyz, r2, c17.w, -v0
dp4 oT3.z, r0, c14
dp4 oT3.y, r0, c13
dp4 oT3.x, r0, c12
mov oT5, v1
mov oT1.xyz, v2
dp4 oPos.w, v0, c3
dp4 oPos.z, v0, c2
dp4 oPos.y, v0, c1
dp4 oPos.x, v0, c0
"
}

SubProgram "d3d11 " {
Keywords { "POINT" }
Bind "vertex" Vertex
Bind "color" Color
Bind "normal" Normal
ConstBuffer "$Globals" 112 // 80 used size, 4 vars
Matrix 16 [_LightMatrix0] 4
ConstBuffer "UnityLighting" 720 // 16 used size, 17 vars
Vector 0 [_WorldSpaceLightPos0] 4
ConstBuffer "UnityPerDraw" 336 // 336 used size, 6 vars
Matrix 0 [glstate_matrix_mvp] 4
Matrix 192 [_Object2World] 4
Matrix 256 [_World2Object] 4
Vector 320 [unity_Scale] 4
BindCB "$Globals" 0
BindCB "UnityLighting" 1
BindCB "UnityPerDraw" 2
// 20 instructions, 2 temp regs, 0 temp arrays:
// ALU 17 float, 0 int, 0 uint
// TEX 0 (0 load, 0 comp, 0 bias, 0 grad)
// FLOW 1 static, 0 dynamic
"vs_4_0
eefiecedmjjpegplcgemohadockdciemelndpjpbabaaaaaaoiaeaaaaadaaaaaa
cmaaaaaalmaaaaaaheabaaaaejfdeheoiiaaaaaaaeaaaaaaaiaaaaaagiaaaaaa
aaaaaaaaaaaaaaaaadaaaaaaaaaaaaaaapapaaaahbaaaaaaaaaaaaaaaaaaaaaa
adaaaaaaabaaaaaaapapaaaahhaaaaaaaaaaaaaaaaaaaaaaadaaaaaaacaaaaaa
ahahaaaahoaaaaaaaaaaaaaaaaaaaaaaadaaaaaaadaaaaaaahaaaaaafaepfdej
feejepeoaaedepemepfcaaeoepfcenebemaafeebeoehefeofeaaklklepfdeheo
laaaaaaaagaaaaaaaiaaaaaajiaaaaaaaaaaaaaaabaaaaaaadaaaaaaaaaaaaaa
apaaaaaakeaaaaaaaaaaaaaaaaaaaaaaadaaaaaaabaaaaaaadapaaaakeaaaaaa
acaaaaaaaaaaaaaaadaaaaaaacaaaaaaahaiaaaakeaaaaaaabaaaaaaaaaaaaaa
adaaaaaaadaaaaaaahaiaaaakeaaaaaaadaaaaaaaaaaaaaaadaaaaaaaeaaaaaa
ahaiaaaakeaaaaaaafaaaaaaaaaaaaaaadaaaaaaafaaaaaaapaaaaaafdfgfpfa
epfdejfeejepeoaafeeffiedepepfceeaaklklklfdeieefcgmadaaaaeaaaabaa
nlaaaaaafjaaaaaeegiocaaaaaaaaaaaafaaaaaafjaaaaaeegiocaaaabaaaaaa
abaaaaaafjaaaaaeegiocaaaacaaaaaabfaaaaaafpaaaaadpcbabaaaaaaaaaaa
fpaaaaadpcbabaaaabaaaaaafpaaaaadhcbabaaaacaaaaaaghaaaaaepccabaaa
aaaaaaaaabaaaaaagfaaaaadhccabaaaacaaaaaagfaaaaadhccabaaaadaaaaaa
gfaaaaadhccabaaaaeaaaaaagfaaaaadpccabaaaafaaaaaagiaaaaacacaaaaaa
diaaaaaipcaabaaaaaaaaaaafgbfbaaaaaaaaaaaegiocaaaacaaaaaaabaaaaaa
dcaaaaakpcaabaaaaaaaaaaaegiocaaaacaaaaaaaaaaaaaaagbabaaaaaaaaaaa
egaobaaaaaaaaaaadcaaaaakpcaabaaaaaaaaaaaegiocaaaacaaaaaaacaaaaaa
kgbkbaaaaaaaaaaaegaobaaaaaaaaaaadcaaaaakpccabaaaaaaaaaaaegiocaaa
acaaaaaaadaaaaaapgbpbaaaaaaaaaaaegaobaaaaaaaaaaadiaaaaajhcaabaaa
aaaaaaaafgifcaaaabaaaaaaaaaaaaaaegiccaaaacaaaaaabbaaaaaadcaaaaal
hcaabaaaaaaaaaaaegiccaaaacaaaaaabaaaaaaaagiacaaaabaaaaaaaaaaaaaa
egacbaaaaaaaaaaadcaaaaalhcaabaaaaaaaaaaaegiccaaaacaaaaaabcaaaaaa
kgikcaaaabaaaaaaaaaaaaaaegacbaaaaaaaaaaadcaaaaalhcaabaaaaaaaaaaa
egiccaaaacaaaaaabdaaaaaapgipcaaaabaaaaaaaaaaaaaaegacbaaaaaaaaaaa
dcaaaaalhccabaaaacaaaaaaegacbaaaaaaaaaaapgipcaaaacaaaaaabeaaaaaa
egbcbaiaebaaaaaaaaaaaaaadgaaaaafhccabaaaadaaaaaaegbcbaaaacaaaaaa
diaaaaaipcaabaaaaaaaaaaafgbfbaaaaaaaaaaaegiocaaaacaaaaaaanaaaaaa
dcaaaaakpcaabaaaaaaaaaaaegiocaaaacaaaaaaamaaaaaaagbabaaaaaaaaaaa
egaobaaaaaaaaaaadcaaaaakpcaabaaaaaaaaaaaegiocaaaacaaaaaaaoaaaaaa
kgbkbaaaaaaaaaaaegaobaaaaaaaaaaadcaaaaakpcaabaaaaaaaaaaaegiocaaa
acaaaaaaapaaaaaapgbpbaaaaaaaaaaaegaobaaaaaaaaaaadiaaaaaihcaabaaa
abaaaaaafgafbaaaaaaaaaaaegiccaaaaaaaaaaaacaaaaaadcaaaaakhcaabaaa
abaaaaaaegiccaaaaaaaaaaaabaaaaaaagaabaaaaaaaaaaaegacbaaaabaaaaaa
dcaaaaakhcaabaaaaaaaaaaaegiccaaaaaaaaaaaadaaaaaakgakbaaaaaaaaaaa
egacbaaaabaaaaaadcaaaaakhccabaaaaeaaaaaaegiccaaaaaaaaaaaaeaaaaaa
pgapbaaaaaaaaaaaegacbaaaaaaaaaaadgaaaaafpccabaaaafaaaaaaegbobaaa
abaaaaaadoaaaaab"
}

SubProgram "gles " {
Keywords { "POINT" }
"!!GLES


#ifdef VERTEX

varying highp vec4 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD1;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec2 xlv_TEXCOORD0;
uniform highp mat4 _LightMatrix0;
uniform highp vec4 unity_Scale;
uniform highp mat4 _World2Object;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_mvp;
uniform highp vec4 _WorldSpaceLightPos0;
attribute vec3 _glesNormal;
attribute vec4 _glesColor;
attribute vec4 _glesVertex;
void main ()
{
  highp vec2 tmpvar_1;
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = tmpvar_1;
  xlv_TEXCOORD2 = (((_World2Object * _WorldSpaceLightPos0).xyz * unity_Scale.w) - _glesVertex.xyz);
  xlv_TEXCOORD1 = normalize(_glesNormal);
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * _glesVertex)).xyz;
  xlv_TEXCOORD5 = _glesColor;
}



#endif
#ifdef FRAGMENT

varying highp vec4 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD1;
varying highp vec3 xlv_TEXCOORD2;
uniform lowp vec4 _LightColor0;
uniform sampler2D _LightTexture0;
void main ()
{
  lowp vec4 c_1;
  lowp float diff_2;
  lowp vec3 normal_3;
  highp float tmpvar_4;
  tmpvar_4 = dot (xlv_TEXCOORD3, xlv_TEXCOORD3);
  lowp float tmpvar_5;
  tmpvar_5 = texture2D (_LightTexture0, vec2(tmpvar_4)).w;
  normal_3 = xlv_TEXCOORD1;
  highp float tmpvar_6;
  tmpvar_6 = clamp (dot (normal_3, normalize(xlv_TEXCOORD2)), 0.0, 1.0);
  diff_2 = tmpvar_6;
  highp vec3 tmpvar_7;
  tmpvar_7 = (((xlv_TEXCOORD5.xyz * _LightColor0.xyz) * diff_2) * (tmpvar_5 * 2.0));
  c_1.xyz = tmpvar_7;
  highp float tmpvar_8;
  tmpvar_8 = xlv_TEXCOORD5.w;
  c_1.w = tmpvar_8;
  gl_FragData[0] = c_1;
}



#endif"
}

SubProgram "glesdesktop " {
Keywords { "POINT" }
"!!GLES


#ifdef VERTEX

varying highp vec4 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD1;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec2 xlv_TEXCOORD0;
uniform highp mat4 _LightMatrix0;
uniform highp vec4 unity_Scale;
uniform highp mat4 _World2Object;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_mvp;
uniform highp vec4 _WorldSpaceLightPos0;
attribute vec3 _glesNormal;
attribute vec4 _glesColor;
attribute vec4 _glesVertex;
void main ()
{
  highp vec2 tmpvar_1;
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = tmpvar_1;
  xlv_TEXCOORD2 = (((_World2Object * _WorldSpaceLightPos0).xyz * unity_Scale.w) - _glesVertex.xyz);
  xlv_TEXCOORD1 = normalize(_glesNormal);
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * _glesVertex)).xyz;
  xlv_TEXCOORD5 = _glesColor;
}



#endif
#ifdef FRAGMENT

varying highp vec4 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD1;
varying highp vec3 xlv_TEXCOORD2;
uniform lowp vec4 _LightColor0;
uniform sampler2D _LightTexture0;
void main ()
{
  lowp vec4 c_1;
  lowp float diff_2;
  lowp vec3 normal_3;
  highp float tmpvar_4;
  tmpvar_4 = dot (xlv_TEXCOORD3, xlv_TEXCOORD3);
  lowp float tmpvar_5;
  tmpvar_5 = texture2D (_LightTexture0, vec2(tmpvar_4)).w;
  normal_3 = xlv_TEXCOORD1;
  highp float tmpvar_6;
  tmpvar_6 = clamp (dot (normal_3, normalize(xlv_TEXCOORD2)), 0.0, 1.0);
  diff_2 = tmpvar_6;
  highp vec3 tmpvar_7;
  tmpvar_7 = (((xlv_TEXCOORD5.xyz * _LightColor0.xyz) * diff_2) * (tmpvar_5 * 2.0));
  c_1.xyz = tmpvar_7;
  highp float tmpvar_8;
  tmpvar_8 = xlv_TEXCOORD5.w;
  c_1.w = tmpvar_8;
  gl_FragData[0] = c_1;
}



#endif"
}

SubProgram "flash " {
Keywords { "POINT" }
Bind "vertex" Vertex
Bind "color" Color
Bind "normal" Normal
Matrix 0 [glstate_matrix_mvp]
Vector 16 [_WorldSpaceLightPos0]
Matrix 4 [_Object2World]
Matrix 8 [_World2Object]
Vector 17 [unity_Scale]
Matrix 12 [_LightMatrix0]
"agal_vs
[bc]
aaaaaaaaaaaaapacakaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov r0, c10
bdaaaaaaacaaaeacbaaaaaoeabaaaaaaaaaaaaoeacaaaaaa dp4 r2.z, c16, r0
aaaaaaaaaaaaapacajaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov r0, c9
bdaaaaaaacaaacacbaaaaaoeabaaaaaaaaaaaaoeacaaaaaa dp4 r2.y, c16, r0
aaaaaaaaabaaapacaiaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov r1, c8
bdaaaaaaacaaabacbaaaaaoeabaaaaaaabaaaaoeacaaaaaa dp4 r2.x, c16, r1
bdaaaaaaaaaaaiacaaaaaaoeaaaaaaaaahaaaaoeabaaaaaa dp4 r0.w, a0, c7
bdaaaaaaaaaaaeacaaaaaaoeaaaaaaaaagaaaaoeabaaaaaa dp4 r0.z, a0, c6
bdaaaaaaaaaaabacaaaaaaoeaaaaaaaaaeaaaaoeabaaaaaa dp4 r0.x, a0, c4
bdaaaaaaaaaaacacaaaaaaoeaaaaaaaaafaaaaoeabaaaaaa dp4 r0.y, a0, c5
adaaaaaaabaaahacacaaaakeacaaaaaabbaaaappabaaaaaa mul r1.xyz, r2.xyzz, c17.w
acaaaaaaacaaahaeabaaaakeacaaaaaaaaaaaaoeaaaaaaaa sub v2.xyz, r1.xyzz, a0
bdaaaaaaadaaaeaeaaaaaaoeacaaaaaaaoaaaaoeabaaaaaa dp4 v3.z, r0, c14
bdaaaaaaadaaacaeaaaaaaoeacaaaaaaanaaaaoeabaaaaaa dp4 v3.y, r0, c13
bdaaaaaaadaaabaeaaaaaaoeacaaaaaaamaaaaoeabaaaaaa dp4 v3.x, r0, c12
aaaaaaaaafaaapaeacaaaaoeaaaaaaaaaaaaaaaaaaaaaaaa mov v5, a2
aaaaaaaaabaaahaeabaaaaoeaaaaaaaaaaaaaaaaaaaaaaaa mov v1.xyz, a1
bdaaaaaaaaaaaiadaaaaaaoeaaaaaaaaadaaaaoeabaaaaaa dp4 o0.w, a0, c3
bdaaaaaaaaaaaeadaaaaaaoeaaaaaaaaacaaaaoeabaaaaaa dp4 o0.z, a0, c2
bdaaaaaaaaaaacadaaaaaaoeaaaaaaaaabaaaaoeabaaaaaa dp4 o0.y, a0, c1
bdaaaaaaaaaaabadaaaaaaoeaaaaaaaaaaaaaaoeabaaaaaa dp4 o0.x, a0, c0
aaaaaaaaabaaaiaeaaaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov v1.w, c0
aaaaaaaaacaaaiaeaaaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov v2.w, c0
aaaaaaaaadaaaiaeaaaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov v3.w, c0
"
}

SubProgram "d3d11_9x " {
Keywords { "POINT" }
Bind "vertex" Vertex
Bind "color" Color
Bind "normal" Normal
ConstBuffer "$Globals" 112 // 80 used size, 4 vars
Matrix 16 [_LightMatrix0] 4
ConstBuffer "UnityLighting" 720 // 16 used size, 17 vars
Vector 0 [_WorldSpaceLightPos0] 4
ConstBuffer "UnityPerDraw" 336 // 336 used size, 6 vars
Matrix 0 [glstate_matrix_mvp] 4
Matrix 192 [_Object2World] 4
Matrix 256 [_World2Object] 4
Vector 320 [unity_Scale] 4
BindCB "$Globals" 0
BindCB "UnityLighting" 1
BindCB "UnityPerDraw" 2
// 20 instructions, 2 temp regs, 0 temp arrays:
// ALU 17 float, 0 int, 0 uint
// TEX 0 (0 load, 0 comp, 0 bias, 0 grad)
// FLOW 1 static, 0 dynamic
"vs_4_0_level_9_1
eefiecedakhailhlejdgcnafjjmlpemddlfdopddabaaaaaaaaahaaaaaeaaaaaa
daaaaaaaeeacaaaaliafaaaaeiagaaaaebgpgodjamacaaaaamacaaaaaaacpopp
leabaaaafiaaaaaaaeaaceaaaaaafeaaaaaafeaaaaaaceaaabaafeaaaaaaabaa
aeaaabaaaaaaaaaaabaaaaaaabaaafaaaaaaaaaaacaaaaaaaeaaagaaaaaaaaaa
acaaamaaajaaakaaaaaaaaaaaaaaaaaaaaacpoppbpaaaaacafaaaaiaaaaaapja
bpaaaaacafaaabiaabaaapjabpaaaaacafaaaciaacaaapjaabaaaaacaaaaapia
afaaoekaafaaaaadabaaahiaaaaaffiaapaaoekaaeaaaaaeabaaahiaaoaaoeka
aaaaaaiaabaaoeiaaeaaaaaeaaaaahiabaaaoekaaaaakkiaabaaoeiaaeaaaaae
aaaaahiabbaaoekaaaaappiaaaaaoeiaaeaaaaaeabaaahoaaaaaoeiabcaappka
aaaaoejbafaaaaadaaaaapiaaaaaffjaalaaoekaaeaaaaaeaaaaapiaakaaoeka
aaaaaajaaaaaoeiaaeaaaaaeaaaaapiaamaaoekaaaaakkjaaaaaoeiaaeaaaaae
aaaaapiaanaaoekaaaaappjaaaaaoeiaafaaaaadabaaahiaaaaaffiaacaaoeka
aeaaaaaeabaaahiaabaaoekaaaaaaaiaabaaoeiaaeaaaaaeaaaaahiaadaaoeka
aaaakkiaabaaoeiaaeaaaaaeadaaahoaaeaaoekaaaaappiaaaaaoeiaafaaaaad
aaaaapiaaaaaffjaahaaoekaaeaaaaaeaaaaapiaagaaoekaaaaaaajaaaaaoeia
aeaaaaaeaaaaapiaaiaaoekaaaaakkjaaaaaoeiaaeaaaaaeaaaaapiaajaaoeka
aaaappjaaaaaoeiaaeaaaaaeaaaaadmaaaaappiaaaaaoekaaaaaoeiaabaaaaac
aaaaammaaaaaoeiaabaaaaacacaaahoaacaaoejaabaaaaacaeaaapoaabaaoeja
ppppaaaafdeieefcgmadaaaaeaaaabaanlaaaaaafjaaaaaeegiocaaaaaaaaaaa
afaaaaaafjaaaaaeegiocaaaabaaaaaaabaaaaaafjaaaaaeegiocaaaacaaaaaa
bfaaaaaafpaaaaadpcbabaaaaaaaaaaafpaaaaadpcbabaaaabaaaaaafpaaaaad
hcbabaaaacaaaaaaghaaaaaepccabaaaaaaaaaaaabaaaaaagfaaaaadhccabaaa
acaaaaaagfaaaaadhccabaaaadaaaaaagfaaaaadhccabaaaaeaaaaaagfaaaaad
pccabaaaafaaaaaagiaaaaacacaaaaaadiaaaaaipcaabaaaaaaaaaaafgbfbaaa
aaaaaaaaegiocaaaacaaaaaaabaaaaaadcaaaaakpcaabaaaaaaaaaaaegiocaaa
acaaaaaaaaaaaaaaagbabaaaaaaaaaaaegaobaaaaaaaaaaadcaaaaakpcaabaaa
aaaaaaaaegiocaaaacaaaaaaacaaaaaakgbkbaaaaaaaaaaaegaobaaaaaaaaaaa
dcaaaaakpccabaaaaaaaaaaaegiocaaaacaaaaaaadaaaaaapgbpbaaaaaaaaaaa
egaobaaaaaaaaaaadiaaaaajhcaabaaaaaaaaaaafgifcaaaabaaaaaaaaaaaaaa
egiccaaaacaaaaaabbaaaaaadcaaaaalhcaabaaaaaaaaaaaegiccaaaacaaaaaa
baaaaaaaagiacaaaabaaaaaaaaaaaaaaegacbaaaaaaaaaaadcaaaaalhcaabaaa
aaaaaaaaegiccaaaacaaaaaabcaaaaaakgikcaaaabaaaaaaaaaaaaaaegacbaaa
aaaaaaaadcaaaaalhcaabaaaaaaaaaaaegiccaaaacaaaaaabdaaaaaapgipcaaa
abaaaaaaaaaaaaaaegacbaaaaaaaaaaadcaaaaalhccabaaaacaaaaaaegacbaaa
aaaaaaaapgipcaaaacaaaaaabeaaaaaaegbcbaiaebaaaaaaaaaaaaaadgaaaaaf
hccabaaaadaaaaaaegbcbaaaacaaaaaadiaaaaaipcaabaaaaaaaaaaafgbfbaaa
aaaaaaaaegiocaaaacaaaaaaanaaaaaadcaaaaakpcaabaaaaaaaaaaaegiocaaa
acaaaaaaamaaaaaaagbabaaaaaaaaaaaegaobaaaaaaaaaaadcaaaaakpcaabaaa
aaaaaaaaegiocaaaacaaaaaaaoaaaaaakgbkbaaaaaaaaaaaegaobaaaaaaaaaaa
dcaaaaakpcaabaaaaaaaaaaaegiocaaaacaaaaaaapaaaaaapgbpbaaaaaaaaaaa
egaobaaaaaaaaaaadiaaaaaihcaabaaaabaaaaaafgafbaaaaaaaaaaaegiccaaa
aaaaaaaaacaaaaaadcaaaaakhcaabaaaabaaaaaaegiccaaaaaaaaaaaabaaaaaa
agaabaaaaaaaaaaaegacbaaaabaaaaaadcaaaaakhcaabaaaaaaaaaaaegiccaaa
aaaaaaaaadaaaaaakgakbaaaaaaaaaaaegacbaaaabaaaaaadcaaaaakhccabaaa
aeaaaaaaegiccaaaaaaaaaaaaeaaaaaapgapbaaaaaaaaaaaegacbaaaaaaaaaaa
dgaaaaafpccabaaaafaaaaaaegbobaaaabaaaaaadoaaaaabejfdeheoiiaaaaaa
aeaaaaaaaiaaaaaagiaaaaaaaaaaaaaaaaaaaaaaadaaaaaaaaaaaaaaapapaaaa
hbaaaaaaaaaaaaaaaaaaaaaaadaaaaaaabaaaaaaapapaaaahhaaaaaaaaaaaaaa
aaaaaaaaadaaaaaaacaaaaaaahahaaaahoaaaaaaaaaaaaaaaaaaaaaaadaaaaaa
adaaaaaaahaaaaaafaepfdejfeejepeoaaedepemepfcaaeoepfcenebemaafeeb
eoehefeofeaaklklepfdeheolaaaaaaaagaaaaaaaiaaaaaajiaaaaaaaaaaaaaa
abaaaaaaadaaaaaaaaaaaaaaapaaaaaakeaaaaaaaaaaaaaaaaaaaaaaadaaaaaa
abaaaaaaadapaaaakeaaaaaaacaaaaaaaaaaaaaaadaaaaaaacaaaaaaahaiaaaa
keaaaaaaabaaaaaaaaaaaaaaadaaaaaaadaaaaaaahaiaaaakeaaaaaaadaaaaaa
aaaaaaaaadaaaaaaaeaaaaaaahaiaaaakeaaaaaaafaaaaaaaaaaaaaaadaaaaaa
afaaaaaaapaaaaaafdfgfpfaepfdejfeejepeoaafeeffiedepepfceeaaklklkl
"
}

SubProgram "gles3 " {
Keywords { "POINT" }
"!!GLES3#version 300 es


#ifdef VERTEX

#define gl_Vertex _glesVertex
in vec4 _glesVertex;
#define gl_Color _glesColor
in vec4 _glesColor;
#define gl_Normal (normalize(_glesNormal))
in vec3 _glesNormal;
#define TANGENT vec4(normalize(_glesTANGENT.xyz), _glesTANGENT.w)
in vec4 _glesTANGENT;

#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 325
struct v2f {
    highp vec4 pos;
    highp vec2 uv;
    highp vec3 lightDir;
    highp vec3 normal;
    highp vec3 _LightCoord;
    highp vec4 color;
};
#line 317
struct appdata_t {
    highp vec4 vertex;
    lowp vec4 color;
    highp vec3 normal;
    highp vec3 tangent;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform highp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform sampler2D _LightTexture0;
uniform highp mat4 _LightMatrix0;
#line 335
uniform lowp vec4 _Color;
uniform lowp vec4 _LightColor0;
#line 348
#line 82
highp vec3 ObjSpaceLightDir( in highp vec4 v ) {
    highp vec3 objSpaceLightPos = (_World2Object * _WorldSpaceLightPos0).xyz;
    return ((objSpaceLightPos.xyz * unity_Scale.w) - v.xyz);
}
#line 335
v2f vert( in appdata_t v ) {
    v2f o;
    o.pos = (glstate_matrix_mvp * v.vertex);
    #line 339
    o.lightDir = ObjSpaceLightDir( v.vertex).xyz;
    o.color = v.color;
    o.normal = v.normal;
    o._LightCoord = (_LightMatrix0 * (_Object2World * v.vertex)).xyz;
    #line 344
    return o;
}

out highp vec2 xlv_TEXCOORD0;
out highp vec3 xlv_TEXCOORD2;
out highp vec3 xlv_TEXCOORD1;
out highp vec3 xlv_TEXCOORD3;
out highp vec4 xlv_TEXCOORD5;
void main() {
    v2f xl_retval;
    appdata_t xlt_v;
    xlt_v.vertex = vec4(gl_Vertex);
    xlt_v.color = vec4(gl_Color);
    xlt_v.normal = vec3(gl_Normal);
    xlt_v.tangent = vec3(TANGENT);
    xl_retval = vert( xlt_v);
    gl_Position = vec4(xl_retval.pos);
    xlv_TEXCOORD0 = vec2(xl_retval.uv);
    xlv_TEXCOORD2 = vec3(xl_retval.lightDir);
    xlv_TEXCOORD1 = vec3(xl_retval.normal);
    xlv_TEXCOORD3 = vec3(xl_retval._LightCoord);
    xlv_TEXCOORD5 = vec4(xl_retval.color);
}


#endif
#ifdef FRAGMENT

#define gl_FragData _glesFragData
layout(location = 0) out mediump vec4 _glesFragData[4];
float xll_saturate_f( float x) {
  return clamp( x, 0.0, 1.0);
}
vec2 xll_saturate_vf2( vec2 x) {
  return clamp( x, 0.0, 1.0);
}
vec3 xll_saturate_vf3( vec3 x) {
  return clamp( x, 0.0, 1.0);
}
vec4 xll_saturate_vf4( vec4 x) {
  return clamp( x, 0.0, 1.0);
}
mat2 xll_saturate_mf2x2(mat2 m) {
  return mat2( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0));
}
mat3 xll_saturate_mf3x3(mat3 m) {
  return mat3( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0));
}
mat4 xll_saturate_mf4x4(mat4 m) {
  return mat4( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0), clamp(m[3], 0.0, 1.0));
}
#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 325
struct v2f {
    highp vec4 pos;
    highp vec2 uv;
    highp vec3 lightDir;
    highp vec3 normal;
    highp vec3 _LightCoord;
    highp vec4 color;
};
#line 317
struct appdata_t {
    highp vec4 vertex;
    lowp vec4 color;
    highp vec3 normal;
    highp vec3 tangent;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform highp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform sampler2D _LightTexture0;
uniform highp mat4 _LightMatrix0;
#line 335
uniform lowp vec4 _Color;
uniform lowp vec4 _LightColor0;
#line 348
#line 348
lowp vec4 frag( in v2f IN ) {
    IN.lightDir = normalize(IN.lightDir);
    lowp float atten = (texture( _LightTexture0, vec2( dot( IN._LightCoord, IN._LightCoord))).w * 1.0);
    #line 352
    lowp vec3 normal = IN.normal;
    lowp float diff = xll_saturate_f(dot( normal, IN.lightDir));
    lowp vec4 c;
    c.xyz = (((IN.color.xyz * _LightColor0.xyz) * diff) * (atten * 2.0));
    #line 356
    c.w = IN.color.w;
    return c;
}
in highp vec2 xlv_TEXCOORD0;
in highp vec3 xlv_TEXCOORD2;
in highp vec3 xlv_TEXCOORD1;
in highp vec3 xlv_TEXCOORD3;
in highp vec4 xlv_TEXCOORD5;
void main() {
    lowp vec4 xl_retval;
    v2f xlt_IN;
    xlt_IN.pos = vec4(0.0);
    xlt_IN.uv = vec2(xlv_TEXCOORD0);
    xlt_IN.lightDir = vec3(xlv_TEXCOORD2);
    xlt_IN.normal = vec3(xlv_TEXCOORD1);
    xlt_IN._LightCoord = vec3(xlv_TEXCOORD3);
    xlt_IN.color = vec4(xlv_TEXCOORD5);
    xl_retval = frag( xlt_IN);
    gl_FragData[0] = vec4(xl_retval);
}


#endif"
}

SubProgram "opengl " {
Keywords { "DIRECTIONAL" }
Bind "vertex" Vertex
Bind "color" Color
Bind "normal" Normal
Vector 9 [_WorldSpaceLightPos0]
Matrix 5 [_World2Object]
"!!ARBvp1.0
# 10 ALU
PARAM c[10] = { program.local[0],
		state.matrix.mvp,
		program.local[5..9] };
TEMP R0;
MOV R0, c[9];
DP4 result.texcoord[2].z, R0, c[7];
DP4 result.texcoord[2].y, R0, c[6];
DP4 result.texcoord[2].x, R0, c[5];
MOV result.texcoord[5], vertex.color;
MOV result.texcoord[1].xyz, vertex.normal;
DP4 result.position.w, vertex.position, c[4];
DP4 result.position.z, vertex.position, c[3];
DP4 result.position.y, vertex.position, c[2];
DP4 result.position.x, vertex.position, c[1];
END
# 10 instructions, 1 R-regs
"
}

SubProgram "d3d9 " {
Keywords { "DIRECTIONAL" }
Bind "vertex" Vertex
Bind "color" Color
Bind "normal" Normal
Matrix 0 [glstate_matrix_mvp]
Vector 8 [_WorldSpaceLightPos0]
Matrix 4 [_World2Object]
"vs_2_0
; 12 ALU
dcl_position0 v0
dcl_color0 v1
dcl_normal0 v2
mov r0, c6
dp4 oT2.z, c8, r0
mov r0, c5
mov r1, c4
dp4 oT2.y, c8, r0
dp4 oT2.x, c8, r1
mov oT5, v1
mov oT1.xyz, v2
dp4 oPos.w, v0, c3
dp4 oPos.z, v0, c2
dp4 oPos.y, v0, c1
dp4 oPos.x, v0, c0
"
}

SubProgram "d3d11 " {
Keywords { "DIRECTIONAL" }
Bind "vertex" Vertex
Bind "color" Color
Bind "normal" Normal
ConstBuffer "UnityLighting" 720 // 16 used size, 17 vars
Vector 0 [_WorldSpaceLightPos0] 4
ConstBuffer "UnityPerDraw" 336 // 320 used size, 6 vars
Matrix 0 [glstate_matrix_mvp] 4
Matrix 256 [_World2Object] 4
BindCB "UnityLighting" 0
BindCB "UnityPerDraw" 1
// 11 instructions, 1 temp regs, 0 temp arrays:
// ALU 8 float, 0 int, 0 uint
// TEX 0 (0 load, 0 comp, 0 bias, 0 grad)
// FLOW 1 static, 0 dynamic
"vs_4_0
eefiecedhlffamgibkghgdhcndobnoaidcnlmladabaaaaaafiadaaaaadaaaaaa
cmaaaaaalmaaaaaafmabaaaaejfdeheoiiaaaaaaaeaaaaaaaiaaaaaagiaaaaaa
aaaaaaaaaaaaaaaaadaaaaaaaaaaaaaaapapaaaahbaaaaaaaaaaaaaaaaaaaaaa
adaaaaaaabaaaaaaapapaaaahhaaaaaaaaaaaaaaaaaaaaaaadaaaaaaacaaaaaa
ahahaaaahoaaaaaaaaaaaaaaaaaaaaaaadaaaaaaadaaaaaaahaaaaaafaepfdej
feejepeoaaedepemepfcaaeoepfcenebemaafeebeoehefeofeaaklklepfdeheo
jiaaaaaaafaaaaaaaiaaaaaaiaaaaaaaaaaaaaaaabaaaaaaadaaaaaaaaaaaaaa
apaaaaaaimaaaaaaaaaaaaaaaaaaaaaaadaaaaaaabaaaaaaadapaaaaimaaaaaa
acaaaaaaaaaaaaaaadaaaaaaacaaaaaaahaiaaaaimaaaaaaabaaaaaaaaaaaaaa
adaaaaaaadaaaaaaahaiaaaaimaaaaaaafaaaaaaaaaaaaaaadaaaaaaaeaaaaaa
apaaaaaafdfgfpfaepfdejfeejepeoaafeeffiedepepfceeaaklklklfdeieefc
peabaaaaeaaaabaahnaaaaaafjaaaaaeegiocaaaaaaaaaaaabaaaaaafjaaaaae
egiocaaaabaaaaaabeaaaaaafpaaaaadpcbabaaaaaaaaaaafpaaaaadpcbabaaa
abaaaaaafpaaaaadhcbabaaaacaaaaaaghaaaaaepccabaaaaaaaaaaaabaaaaaa
gfaaaaadhccabaaaacaaaaaagfaaaaadhccabaaaadaaaaaagfaaaaadpccabaaa
aeaaaaaagiaaaaacabaaaaaadiaaaaaipcaabaaaaaaaaaaafgbfbaaaaaaaaaaa
egiocaaaabaaaaaaabaaaaaadcaaaaakpcaabaaaaaaaaaaaegiocaaaabaaaaaa
aaaaaaaaagbabaaaaaaaaaaaegaobaaaaaaaaaaadcaaaaakpcaabaaaaaaaaaaa
egiocaaaabaaaaaaacaaaaaakgbkbaaaaaaaaaaaegaobaaaaaaaaaaadcaaaaak
pccabaaaaaaaaaaaegiocaaaabaaaaaaadaaaaaapgbpbaaaaaaaaaaaegaobaaa
aaaaaaaadiaaaaajhcaabaaaaaaaaaaafgifcaaaaaaaaaaaaaaaaaaaegiccaaa
abaaaaaabbaaaaaadcaaaaalhcaabaaaaaaaaaaaegiccaaaabaaaaaabaaaaaaa
agiacaaaaaaaaaaaaaaaaaaaegacbaaaaaaaaaaadcaaaaalhcaabaaaaaaaaaaa
egiccaaaabaaaaaabcaaaaaakgikcaaaaaaaaaaaaaaaaaaaegacbaaaaaaaaaaa
dcaaaaalhccabaaaacaaaaaaegiccaaaabaaaaaabdaaaaaapgipcaaaaaaaaaaa
aaaaaaaaegacbaaaaaaaaaaadgaaaaafhccabaaaadaaaaaaegbcbaaaacaaaaaa
dgaaaaafpccabaaaaeaaaaaaegbobaaaabaaaaaadoaaaaab"
}

SubProgram "gles " {
Keywords { "DIRECTIONAL" }
"!!GLES


#ifdef VERTEX

varying highp vec4 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD1;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec2 xlv_TEXCOORD0;
uniform highp mat4 _World2Object;
uniform highp mat4 glstate_matrix_mvp;
uniform lowp vec4 _WorldSpaceLightPos0;
attribute vec3 _glesNormal;
attribute vec4 _glesColor;
attribute vec4 _glesVertex;
void main ()
{
  highp vec2 tmpvar_1;
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = tmpvar_1;
  xlv_TEXCOORD2 = (_World2Object * _WorldSpaceLightPos0).xyz;
  xlv_TEXCOORD1 = normalize(_glesNormal);
  xlv_TEXCOORD5 = _glesColor;
}



#endif
#ifdef FRAGMENT

varying highp vec4 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD1;
varying highp vec3 xlv_TEXCOORD2;
uniform lowp vec4 _LightColor0;
void main ()
{
  lowp vec4 c_1;
  lowp float diff_2;
  lowp vec3 normal_3;
  normal_3 = xlv_TEXCOORD1;
  highp float tmpvar_4;
  tmpvar_4 = clamp (dot (normal_3, normalize(xlv_TEXCOORD2)), 0.0, 1.0);
  diff_2 = tmpvar_4;
  highp vec3 tmpvar_5;
  tmpvar_5 = (((xlv_TEXCOORD5.xyz * _LightColor0.xyz) * diff_2) * 2.0);
  c_1.xyz = tmpvar_5;
  highp float tmpvar_6;
  tmpvar_6 = xlv_TEXCOORD5.w;
  c_1.w = tmpvar_6;
  gl_FragData[0] = c_1;
}



#endif"
}

SubProgram "glesdesktop " {
Keywords { "DIRECTIONAL" }
"!!GLES


#ifdef VERTEX

varying highp vec4 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD1;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec2 xlv_TEXCOORD0;
uniform highp mat4 _World2Object;
uniform highp mat4 glstate_matrix_mvp;
uniform lowp vec4 _WorldSpaceLightPos0;
attribute vec3 _glesNormal;
attribute vec4 _glesColor;
attribute vec4 _glesVertex;
void main ()
{
  highp vec2 tmpvar_1;
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = tmpvar_1;
  xlv_TEXCOORD2 = (_World2Object * _WorldSpaceLightPos0).xyz;
  xlv_TEXCOORD1 = normalize(_glesNormal);
  xlv_TEXCOORD5 = _glesColor;
}



#endif
#ifdef FRAGMENT

varying highp vec4 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD1;
varying highp vec3 xlv_TEXCOORD2;
uniform lowp vec4 _LightColor0;
void main ()
{
  lowp vec4 c_1;
  lowp float diff_2;
  lowp vec3 normal_3;
  normal_3 = xlv_TEXCOORD1;
  highp float tmpvar_4;
  tmpvar_4 = clamp (dot (normal_3, normalize(xlv_TEXCOORD2)), 0.0, 1.0);
  diff_2 = tmpvar_4;
  highp vec3 tmpvar_5;
  tmpvar_5 = (((xlv_TEXCOORD5.xyz * _LightColor0.xyz) * diff_2) * 2.0);
  c_1.xyz = tmpvar_5;
  highp float tmpvar_6;
  tmpvar_6 = xlv_TEXCOORD5.w;
  c_1.w = tmpvar_6;
  gl_FragData[0] = c_1;
}



#endif"
}

SubProgram "flash " {
Keywords { "DIRECTIONAL" }
Bind "vertex" Vertex
Bind "color" Color
Bind "normal" Normal
Matrix 0 [glstate_matrix_mvp]
Vector 8 [_WorldSpaceLightPos0]
Matrix 4 [_World2Object]
"agal_vs
[bc]
aaaaaaaaaaaaapacagaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov r0, c6
bdaaaaaaacaaaeaeaiaaaaoeabaaaaaaaaaaaaoeacaaaaaa dp4 v2.z, c8, r0
aaaaaaaaaaaaapacafaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov r0, c5
aaaaaaaaabaaapacaeaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov r1, c4
bdaaaaaaacaaacaeaiaaaaoeabaaaaaaaaaaaaoeacaaaaaa dp4 v2.y, c8, r0
bdaaaaaaacaaabaeaiaaaaoeabaaaaaaabaaaaoeacaaaaaa dp4 v2.x, c8, r1
aaaaaaaaafaaapaeacaaaaoeaaaaaaaaaaaaaaaaaaaaaaaa mov v5, a2
aaaaaaaaabaaahaeabaaaaoeaaaaaaaaaaaaaaaaaaaaaaaa mov v1.xyz, a1
bdaaaaaaaaaaaiadaaaaaaoeaaaaaaaaadaaaaoeabaaaaaa dp4 o0.w, a0, c3
bdaaaaaaaaaaaeadaaaaaaoeaaaaaaaaacaaaaoeabaaaaaa dp4 o0.z, a0, c2
bdaaaaaaaaaaacadaaaaaaoeaaaaaaaaabaaaaoeabaaaaaa dp4 o0.y, a0, c1
bdaaaaaaaaaaabadaaaaaaoeaaaaaaaaaaaaaaoeabaaaaaa dp4 o0.x, a0, c0
aaaaaaaaabaaaiaeaaaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov v1.w, c0
aaaaaaaaacaaaiaeaaaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov v2.w, c0
"
}

SubProgram "d3d11_9x " {
Keywords { "DIRECTIONAL" }
Bind "vertex" Vertex
Bind "color" Color
Bind "normal" Normal
ConstBuffer "UnityLighting" 720 // 16 used size, 17 vars
Vector 0 [_WorldSpaceLightPos0] 4
ConstBuffer "UnityPerDraw" 336 // 320 used size, 6 vars
Matrix 0 [glstate_matrix_mvp] 4
Matrix 256 [_World2Object] 4
BindCB "UnityLighting" 0
BindCB "UnityPerDraw" 1
// 11 instructions, 1 temp regs, 0 temp arrays:
// ALU 8 float, 0 int, 0 uint
// TEX 0 (0 load, 0 comp, 0 bias, 0 grad)
// FLOW 1 static, 0 dynamic
"vs_4_0_level_9_1
eefiecedjnmaggkionlfmiffnkeilonkceebjlmlabaaaaaaliaeaaaaaeaaaaaa
daaaaaaaimabaaaaiiadaaaabiaeaaaaebgpgodjfeabaaaafeabaaaaaaacpopp
aiabaaaaemaaaaaaadaaceaaaaaaeiaaaaaaeiaaaaaaceaaabaaeiaaaaaaaaaa
abaaabaaaaaaaaaaabaaaaaaaeaaacaaaaaaaaaaabaabaaaaeaaagaaaaaaaaaa
aaaaaaaaaaacpoppbpaaaaacafaaaaiaaaaaapjabpaaaaacafaaabiaabaaapja
bpaaaaacafaaaciaacaaapjaabaaaaacaaaaapiaabaaoekaafaaaaadabaaahia
aaaaffiaahaaoekaaeaaaaaeabaaahiaagaaoekaaaaaaaiaabaaoeiaaeaaaaae
aaaaahiaaiaaoekaaaaakkiaabaaoeiaaeaaaaaeabaaahoaajaaoekaaaaappia
aaaaoeiaafaaaaadaaaaapiaaaaaffjaadaaoekaaeaaaaaeaaaaapiaacaaoeka
aaaaaajaaaaaoeiaaeaaaaaeaaaaapiaaeaaoekaaaaakkjaaaaaoeiaaeaaaaae
aaaaapiaafaaoekaaaaappjaaaaaoeiaaeaaaaaeaaaaadmaaaaappiaaaaaoeka
aaaaoeiaabaaaaacaaaaammaaaaaoeiaabaaaaacacaaahoaacaaoejaabaaaaac
adaaapoaabaaoejappppaaaafdeieefcpeabaaaaeaaaabaahnaaaaaafjaaaaae
egiocaaaaaaaaaaaabaaaaaafjaaaaaeegiocaaaabaaaaaabeaaaaaafpaaaaad
pcbabaaaaaaaaaaafpaaaaadpcbabaaaabaaaaaafpaaaaadhcbabaaaacaaaaaa
ghaaaaaepccabaaaaaaaaaaaabaaaaaagfaaaaadhccabaaaacaaaaaagfaaaaad
hccabaaaadaaaaaagfaaaaadpccabaaaaeaaaaaagiaaaaacabaaaaaadiaaaaai
pcaabaaaaaaaaaaafgbfbaaaaaaaaaaaegiocaaaabaaaaaaabaaaaaadcaaaaak
pcaabaaaaaaaaaaaegiocaaaabaaaaaaaaaaaaaaagbabaaaaaaaaaaaegaobaaa
aaaaaaaadcaaaaakpcaabaaaaaaaaaaaegiocaaaabaaaaaaacaaaaaakgbkbaaa
aaaaaaaaegaobaaaaaaaaaaadcaaaaakpccabaaaaaaaaaaaegiocaaaabaaaaaa
adaaaaaapgbpbaaaaaaaaaaaegaobaaaaaaaaaaadiaaaaajhcaabaaaaaaaaaaa
fgifcaaaaaaaaaaaaaaaaaaaegiccaaaabaaaaaabbaaaaaadcaaaaalhcaabaaa
aaaaaaaaegiccaaaabaaaaaabaaaaaaaagiacaaaaaaaaaaaaaaaaaaaegacbaaa
aaaaaaaadcaaaaalhcaabaaaaaaaaaaaegiccaaaabaaaaaabcaaaaaakgikcaaa
aaaaaaaaaaaaaaaaegacbaaaaaaaaaaadcaaaaalhccabaaaacaaaaaaegiccaaa
abaaaaaabdaaaaaapgipcaaaaaaaaaaaaaaaaaaaegacbaaaaaaaaaaadgaaaaaf
hccabaaaadaaaaaaegbcbaaaacaaaaaadgaaaaafpccabaaaaeaaaaaaegbobaaa
abaaaaaadoaaaaabejfdeheoiiaaaaaaaeaaaaaaaiaaaaaagiaaaaaaaaaaaaaa
aaaaaaaaadaaaaaaaaaaaaaaapapaaaahbaaaaaaaaaaaaaaaaaaaaaaadaaaaaa
abaaaaaaapapaaaahhaaaaaaaaaaaaaaaaaaaaaaadaaaaaaacaaaaaaahahaaaa
hoaaaaaaaaaaaaaaaaaaaaaaadaaaaaaadaaaaaaahaaaaaafaepfdejfeejepeo
aaedepemepfcaaeoepfcenebemaafeebeoehefeofeaaklklepfdeheojiaaaaaa
afaaaaaaaiaaaaaaiaaaaaaaaaaaaaaaabaaaaaaadaaaaaaaaaaaaaaapaaaaaa
imaaaaaaaaaaaaaaaaaaaaaaadaaaaaaabaaaaaaadapaaaaimaaaaaaacaaaaaa
aaaaaaaaadaaaaaaacaaaaaaahaiaaaaimaaaaaaabaaaaaaaaaaaaaaadaaaaaa
adaaaaaaahaiaaaaimaaaaaaafaaaaaaaaaaaaaaadaaaaaaaeaaaaaaapaaaaaa
fdfgfpfaepfdejfeejepeoaafeeffiedepepfceeaaklklkl"
}

SubProgram "gles3 " {
Keywords { "DIRECTIONAL" }
"!!GLES3#version 300 es


#ifdef VERTEX

#define gl_Vertex _glesVertex
in vec4 _glesVertex;
#define gl_Color _glesColor
in vec4 _glesColor;
#define gl_Normal (normalize(_glesNormal))
in vec3 _glesNormal;
#define TANGENT vec4(normalize(_glesTANGENT.xyz), _glesTANGENT.w)
in vec4 _glesTANGENT;

#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 323
struct v2f {
    highp vec4 pos;
    highp vec2 uv;
    highp vec3 lightDir;
    highp vec3 normal;
    highp vec4 color;
};
#line 315
struct appdata_t {
    highp vec4 vertex;
    lowp vec4 color;
    highp vec3 normal;
    highp vec3 tangent;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform lowp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 332
uniform lowp vec4 _Color;
uniform lowp vec4 _LightColor0;
#line 344
#line 82
highp vec3 ObjSpaceLightDir( in highp vec4 v ) {
    highp vec3 objSpaceLightPos = (_World2Object * _WorldSpaceLightPos0).xyz;
    return objSpaceLightPos.xyz;
}
#line 332
v2f vert( in appdata_t v ) {
    v2f o;
    o.pos = (glstate_matrix_mvp * v.vertex);
    #line 336
    o.lightDir = ObjSpaceLightDir( v.vertex).xyz;
    o.color = v.color;
    o.normal = v.normal;
    #line 340
    return o;
}

out highp vec2 xlv_TEXCOORD0;
out highp vec3 xlv_TEXCOORD2;
out highp vec3 xlv_TEXCOORD1;
out highp vec4 xlv_TEXCOORD5;
void main() {
    v2f xl_retval;
    appdata_t xlt_v;
    xlt_v.vertex = vec4(gl_Vertex);
    xlt_v.color = vec4(gl_Color);
    xlt_v.normal = vec3(gl_Normal);
    xlt_v.tangent = vec3(TANGENT);
    xl_retval = vert( xlt_v);
    gl_Position = vec4(xl_retval.pos);
    xlv_TEXCOORD0 = vec2(xl_retval.uv);
    xlv_TEXCOORD2 = vec3(xl_retval.lightDir);
    xlv_TEXCOORD1 = vec3(xl_retval.normal);
    xlv_TEXCOORD5 = vec4(xl_retval.color);
}


#endif
#ifdef FRAGMENT

#define gl_FragData _glesFragData
layout(location = 0) out mediump vec4 _glesFragData[4];
float xll_saturate_f( float x) {
  return clamp( x, 0.0, 1.0);
}
vec2 xll_saturate_vf2( vec2 x) {
  return clamp( x, 0.0, 1.0);
}
vec3 xll_saturate_vf3( vec3 x) {
  return clamp( x, 0.0, 1.0);
}
vec4 xll_saturate_vf4( vec4 x) {
  return clamp( x, 0.0, 1.0);
}
mat2 xll_saturate_mf2x2(mat2 m) {
  return mat2( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0));
}
mat3 xll_saturate_mf3x3(mat3 m) {
  return mat3( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0));
}
mat4 xll_saturate_mf4x4(mat4 m) {
  return mat4( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0), clamp(m[3], 0.0, 1.0));
}
#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 323
struct v2f {
    highp vec4 pos;
    highp vec2 uv;
    highp vec3 lightDir;
    highp vec3 normal;
    highp vec4 color;
};
#line 315
struct appdata_t {
    highp vec4 vertex;
    lowp vec4 color;
    highp vec3 normal;
    highp vec3 tangent;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform lowp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 332
uniform lowp vec4 _Color;
uniform lowp vec4 _LightColor0;
#line 344
#line 344
lowp vec4 frag( in v2f IN ) {
    IN.lightDir = normalize(IN.lightDir);
    lowp float atten = 1.0;
    #line 348
    lowp vec3 normal = IN.normal;
    lowp float diff = xll_saturate_f(dot( normal, IN.lightDir));
    lowp vec4 c;
    c.xyz = (((IN.color.xyz * _LightColor0.xyz) * diff) * (atten * 2.0));
    #line 352
    c.w = IN.color.w;
    return c;
}
in highp vec2 xlv_TEXCOORD0;
in highp vec3 xlv_TEXCOORD2;
in highp vec3 xlv_TEXCOORD1;
in highp vec4 xlv_TEXCOORD5;
void main() {
    lowp vec4 xl_retval;
    v2f xlt_IN;
    xlt_IN.pos = vec4(0.0);
    xlt_IN.uv = vec2(xlv_TEXCOORD0);
    xlt_IN.lightDir = vec3(xlv_TEXCOORD2);
    xlt_IN.normal = vec3(xlv_TEXCOORD1);
    xlt_IN.color = vec4(xlv_TEXCOORD5);
    xl_retval = frag( xlt_IN);
    gl_FragData[0] = vec4(xl_retval);
}


#endif"
}

SubProgram "opengl " {
Keywords { "SPOT" }
Bind "vertex" Vertex
Bind "color" Color
Bind "normal" Normal
Vector 17 [_WorldSpaceLightPos0]
Matrix 5 [_Object2World]
Matrix 9 [_World2Object]
Vector 18 [unity_Scale]
Matrix 13 [_LightMatrix0]
"!!ARBvp1.0
# 19 ALU
PARAM c[19] = { program.local[0],
		state.matrix.mvp,
		program.local[5..18] };
TEMP R0;
TEMP R1;
MOV R1, c[17];
DP4 R0.w, vertex.position, c[8];
DP4 R0.z, R1, c[11];
DP4 R0.x, R1, c[9];
DP4 R0.y, R1, c[10];
MAD result.texcoord[2].xyz, R0, c[18].w, -vertex.position;
DP4 R0.z, vertex.position, c[7];
DP4 R0.x, vertex.position, c[5];
DP4 R0.y, vertex.position, c[6];
DP4 result.texcoord[3].w, R0, c[16];
DP4 result.texcoord[3].z, R0, c[15];
DP4 result.texcoord[3].y, R0, c[14];
DP4 result.texcoord[3].x, R0, c[13];
MOV result.texcoord[5], vertex.color;
MOV result.texcoord[1].xyz, vertex.normal;
DP4 result.position.w, vertex.position, c[4];
DP4 result.position.z, vertex.position, c[3];
DP4 result.position.y, vertex.position, c[2];
DP4 result.position.x, vertex.position, c[1];
END
# 19 instructions, 2 R-regs
"
}

SubProgram "d3d9 " {
Keywords { "SPOT" }
Bind "vertex" Vertex
Bind "color" Color
Bind "normal" Normal
Matrix 0 [glstate_matrix_mvp]
Vector 16 [_WorldSpaceLightPos0]
Matrix 4 [_Object2World]
Matrix 8 [_World2Object]
Vector 17 [unity_Scale]
Matrix 12 [_LightMatrix0]
"vs_2_0
; 21 ALU
dcl_position0 v0
dcl_color0 v1
dcl_normal0 v2
mov r0, c10
dp4 r2.z, c16, r0
mov r0, c9
dp4 r2.y, c16, r0
mov r1, c8
dp4 r2.x, c16, r1
dp4 r0.w, v0, c7
dp4 r0.z, v0, c6
dp4 r0.x, v0, c4
dp4 r0.y, v0, c5
mad oT2.xyz, r2, c17.w, -v0
dp4 oT3.w, r0, c15
dp4 oT3.z, r0, c14
dp4 oT3.y, r0, c13
dp4 oT3.x, r0, c12
mov oT5, v1
mov oT1.xyz, v2
dp4 oPos.w, v0, c3
dp4 oPos.z, v0, c2
dp4 oPos.y, v0, c1
dp4 oPos.x, v0, c0
"
}

SubProgram "d3d11 " {
Keywords { "SPOT" }
Bind "vertex" Vertex
Bind "color" Color
Bind "normal" Normal
ConstBuffer "$Globals" 112 // 80 used size, 4 vars
Matrix 16 [_LightMatrix0] 4
ConstBuffer "UnityLighting" 720 // 16 used size, 17 vars
Vector 0 [_WorldSpaceLightPos0] 4
ConstBuffer "UnityPerDraw" 336 // 336 used size, 6 vars
Matrix 0 [glstate_matrix_mvp] 4
Matrix 192 [_Object2World] 4
Matrix 256 [_World2Object] 4
Vector 320 [unity_Scale] 4
BindCB "$Globals" 0
BindCB "UnityLighting" 1
BindCB "UnityPerDraw" 2
// 20 instructions, 2 temp regs, 0 temp arrays:
// ALU 17 float, 0 int, 0 uint
// TEX 0 (0 load, 0 comp, 0 bias, 0 grad)
// FLOW 1 static, 0 dynamic
"vs_4_0
eefieceddiemkimndippbbnjeipihbehkfmhcbkpabaaaaaaoiaeaaaaadaaaaaa
cmaaaaaalmaaaaaaheabaaaaejfdeheoiiaaaaaaaeaaaaaaaiaaaaaagiaaaaaa
aaaaaaaaaaaaaaaaadaaaaaaaaaaaaaaapapaaaahbaaaaaaaaaaaaaaaaaaaaaa
adaaaaaaabaaaaaaapapaaaahhaaaaaaaaaaaaaaaaaaaaaaadaaaaaaacaaaaaa
ahahaaaahoaaaaaaaaaaaaaaaaaaaaaaadaaaaaaadaaaaaaahaaaaaafaepfdej
feejepeoaaedepemepfcaaeoepfcenebemaafeebeoehefeofeaaklklepfdeheo
laaaaaaaagaaaaaaaiaaaaaajiaaaaaaaaaaaaaaabaaaaaaadaaaaaaaaaaaaaa
apaaaaaakeaaaaaaaaaaaaaaaaaaaaaaadaaaaaaabaaaaaaadapaaaakeaaaaaa
acaaaaaaaaaaaaaaadaaaaaaacaaaaaaahaiaaaakeaaaaaaabaaaaaaaaaaaaaa
adaaaaaaadaaaaaaahaiaaaakeaaaaaaadaaaaaaaaaaaaaaadaaaaaaaeaaaaaa
apaaaaaakeaaaaaaafaaaaaaaaaaaaaaadaaaaaaafaaaaaaapaaaaaafdfgfpfa
epfdejfeejepeoaafeeffiedepepfceeaaklklklfdeieefcgmadaaaaeaaaabaa
nlaaaaaafjaaaaaeegiocaaaaaaaaaaaafaaaaaafjaaaaaeegiocaaaabaaaaaa
abaaaaaafjaaaaaeegiocaaaacaaaaaabfaaaaaafpaaaaadpcbabaaaaaaaaaaa
fpaaaaadpcbabaaaabaaaaaafpaaaaadhcbabaaaacaaaaaaghaaaaaepccabaaa
aaaaaaaaabaaaaaagfaaaaadhccabaaaacaaaaaagfaaaaadhccabaaaadaaaaaa
gfaaaaadpccabaaaaeaaaaaagfaaaaadpccabaaaafaaaaaagiaaaaacacaaaaaa
diaaaaaipcaabaaaaaaaaaaafgbfbaaaaaaaaaaaegiocaaaacaaaaaaabaaaaaa
dcaaaaakpcaabaaaaaaaaaaaegiocaaaacaaaaaaaaaaaaaaagbabaaaaaaaaaaa
egaobaaaaaaaaaaadcaaaaakpcaabaaaaaaaaaaaegiocaaaacaaaaaaacaaaaaa
kgbkbaaaaaaaaaaaegaobaaaaaaaaaaadcaaaaakpccabaaaaaaaaaaaegiocaaa
acaaaaaaadaaaaaapgbpbaaaaaaaaaaaegaobaaaaaaaaaaadiaaaaajhcaabaaa
aaaaaaaafgifcaaaabaaaaaaaaaaaaaaegiccaaaacaaaaaabbaaaaaadcaaaaal
hcaabaaaaaaaaaaaegiccaaaacaaaaaabaaaaaaaagiacaaaabaaaaaaaaaaaaaa
egacbaaaaaaaaaaadcaaaaalhcaabaaaaaaaaaaaegiccaaaacaaaaaabcaaaaaa
kgikcaaaabaaaaaaaaaaaaaaegacbaaaaaaaaaaadcaaaaalhcaabaaaaaaaaaaa
egiccaaaacaaaaaabdaaaaaapgipcaaaabaaaaaaaaaaaaaaegacbaaaaaaaaaaa
dcaaaaalhccabaaaacaaaaaaegacbaaaaaaaaaaapgipcaaaacaaaaaabeaaaaaa
egbcbaiaebaaaaaaaaaaaaaadgaaaaafhccabaaaadaaaaaaegbcbaaaacaaaaaa
diaaaaaipcaabaaaaaaaaaaafgbfbaaaaaaaaaaaegiocaaaacaaaaaaanaaaaaa
dcaaaaakpcaabaaaaaaaaaaaegiocaaaacaaaaaaamaaaaaaagbabaaaaaaaaaaa
egaobaaaaaaaaaaadcaaaaakpcaabaaaaaaaaaaaegiocaaaacaaaaaaaoaaaaaa
kgbkbaaaaaaaaaaaegaobaaaaaaaaaaadcaaaaakpcaabaaaaaaaaaaaegiocaaa
acaaaaaaapaaaaaapgbpbaaaaaaaaaaaegaobaaaaaaaaaaadiaaaaaipcaabaaa
abaaaaaafgafbaaaaaaaaaaaegiocaaaaaaaaaaaacaaaaaadcaaaaakpcaabaaa
abaaaaaaegiocaaaaaaaaaaaabaaaaaaagaabaaaaaaaaaaaegaobaaaabaaaaaa
dcaaaaakpcaabaaaabaaaaaaegiocaaaaaaaaaaaadaaaaaakgakbaaaaaaaaaaa
egaobaaaabaaaaaadcaaaaakpccabaaaaeaaaaaaegiocaaaaaaaaaaaaeaaaaaa
pgapbaaaaaaaaaaaegaobaaaabaaaaaadgaaaaafpccabaaaafaaaaaaegbobaaa
abaaaaaadoaaaaab"
}

SubProgram "gles " {
Keywords { "SPOT" }
"!!GLES


#ifdef VERTEX

varying highp vec4 xlv_TEXCOORD5;
varying highp vec4 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD1;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec2 xlv_TEXCOORD0;
uniform highp mat4 _LightMatrix0;
uniform highp vec4 unity_Scale;
uniform highp mat4 _World2Object;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_mvp;
uniform highp vec4 _WorldSpaceLightPos0;
attribute vec3 _glesNormal;
attribute vec4 _glesColor;
attribute vec4 _glesVertex;
void main ()
{
  highp vec2 tmpvar_1;
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = tmpvar_1;
  xlv_TEXCOORD2 = (((_World2Object * _WorldSpaceLightPos0).xyz * unity_Scale.w) - _glesVertex.xyz);
  xlv_TEXCOORD1 = normalize(_glesNormal);
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * _glesVertex));
  xlv_TEXCOORD5 = _glesColor;
}



#endif
#ifdef FRAGMENT

varying highp vec4 xlv_TEXCOORD5;
varying highp vec4 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD1;
varying highp vec3 xlv_TEXCOORD2;
uniform lowp vec4 _LightColor0;
uniform sampler2D _LightTextureB0;
uniform sampler2D _LightTexture0;
void main ()
{
  lowp vec4 c_1;
  lowp float diff_2;
  lowp vec3 normal_3;
  lowp float atten_4;
  lowp vec4 tmpvar_5;
  highp vec2 P_6;
  P_6 = ((xlv_TEXCOORD3.xy / xlv_TEXCOORD3.w) + 0.5);
  tmpvar_5 = texture2D (_LightTexture0, P_6);
  highp float tmpvar_7;
  tmpvar_7 = dot (xlv_TEXCOORD3.xyz, xlv_TEXCOORD3.xyz);
  lowp vec4 tmpvar_8;
  tmpvar_8 = texture2D (_LightTextureB0, vec2(tmpvar_7));
  highp float tmpvar_9;
  tmpvar_9 = ((float((xlv_TEXCOORD3.z > 0.0)) * tmpvar_5.w) * tmpvar_8.w);
  atten_4 = tmpvar_9;
  normal_3 = xlv_TEXCOORD1;
  highp float tmpvar_10;
  tmpvar_10 = clamp (dot (normal_3, normalize(xlv_TEXCOORD2)), 0.0, 1.0);
  diff_2 = tmpvar_10;
  highp vec3 tmpvar_11;
  tmpvar_11 = (((xlv_TEXCOORD5.xyz * _LightColor0.xyz) * diff_2) * (atten_4 * 2.0));
  c_1.xyz = tmpvar_11;
  highp float tmpvar_12;
  tmpvar_12 = xlv_TEXCOORD5.w;
  c_1.w = tmpvar_12;
  gl_FragData[0] = c_1;
}



#endif"
}

SubProgram "glesdesktop " {
Keywords { "SPOT" }
"!!GLES


#ifdef VERTEX

varying highp vec4 xlv_TEXCOORD5;
varying highp vec4 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD1;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec2 xlv_TEXCOORD0;
uniform highp mat4 _LightMatrix0;
uniform highp vec4 unity_Scale;
uniform highp mat4 _World2Object;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_mvp;
uniform highp vec4 _WorldSpaceLightPos0;
attribute vec3 _glesNormal;
attribute vec4 _glesColor;
attribute vec4 _glesVertex;
void main ()
{
  highp vec2 tmpvar_1;
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = tmpvar_1;
  xlv_TEXCOORD2 = (((_World2Object * _WorldSpaceLightPos0).xyz * unity_Scale.w) - _glesVertex.xyz);
  xlv_TEXCOORD1 = normalize(_glesNormal);
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * _glesVertex));
  xlv_TEXCOORD5 = _glesColor;
}



#endif
#ifdef FRAGMENT

varying highp vec4 xlv_TEXCOORD5;
varying highp vec4 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD1;
varying highp vec3 xlv_TEXCOORD2;
uniform lowp vec4 _LightColor0;
uniform sampler2D _LightTextureB0;
uniform sampler2D _LightTexture0;
void main ()
{
  lowp vec4 c_1;
  lowp float diff_2;
  lowp vec3 normal_3;
  lowp float atten_4;
  lowp vec4 tmpvar_5;
  highp vec2 P_6;
  P_6 = ((xlv_TEXCOORD3.xy / xlv_TEXCOORD3.w) + 0.5);
  tmpvar_5 = texture2D (_LightTexture0, P_6);
  highp float tmpvar_7;
  tmpvar_7 = dot (xlv_TEXCOORD3.xyz, xlv_TEXCOORD3.xyz);
  lowp vec4 tmpvar_8;
  tmpvar_8 = texture2D (_LightTextureB0, vec2(tmpvar_7));
  highp float tmpvar_9;
  tmpvar_9 = ((float((xlv_TEXCOORD3.z > 0.0)) * tmpvar_5.w) * tmpvar_8.w);
  atten_4 = tmpvar_9;
  normal_3 = xlv_TEXCOORD1;
  highp float tmpvar_10;
  tmpvar_10 = clamp (dot (normal_3, normalize(xlv_TEXCOORD2)), 0.0, 1.0);
  diff_2 = tmpvar_10;
  highp vec3 tmpvar_11;
  tmpvar_11 = (((xlv_TEXCOORD5.xyz * _LightColor0.xyz) * diff_2) * (atten_4 * 2.0));
  c_1.xyz = tmpvar_11;
  highp float tmpvar_12;
  tmpvar_12 = xlv_TEXCOORD5.w;
  c_1.w = tmpvar_12;
  gl_FragData[0] = c_1;
}



#endif"
}

SubProgram "flash " {
Keywords { "SPOT" }
Bind "vertex" Vertex
Bind "color" Color
Bind "normal" Normal
Matrix 0 [glstate_matrix_mvp]
Vector 16 [_WorldSpaceLightPos0]
Matrix 4 [_Object2World]
Matrix 8 [_World2Object]
Vector 17 [unity_Scale]
Matrix 12 [_LightMatrix0]
"agal_vs
[bc]
aaaaaaaaaaaaapacakaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov r0, c10
bdaaaaaaacaaaeacbaaaaaoeabaaaaaaaaaaaaoeacaaaaaa dp4 r2.z, c16, r0
aaaaaaaaaaaaapacajaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov r0, c9
bdaaaaaaacaaacacbaaaaaoeabaaaaaaaaaaaaoeacaaaaaa dp4 r2.y, c16, r0
aaaaaaaaabaaapacaiaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov r1, c8
bdaaaaaaacaaabacbaaaaaoeabaaaaaaabaaaaoeacaaaaaa dp4 r2.x, c16, r1
bdaaaaaaaaaaaiacaaaaaaoeaaaaaaaaahaaaaoeabaaaaaa dp4 r0.w, a0, c7
bdaaaaaaaaaaaeacaaaaaaoeaaaaaaaaagaaaaoeabaaaaaa dp4 r0.z, a0, c6
bdaaaaaaaaaaabacaaaaaaoeaaaaaaaaaeaaaaoeabaaaaaa dp4 r0.x, a0, c4
bdaaaaaaaaaaacacaaaaaaoeaaaaaaaaafaaaaoeabaaaaaa dp4 r0.y, a0, c5
adaaaaaaabaaahacacaaaakeacaaaaaabbaaaappabaaaaaa mul r1.xyz, r2.xyzz, c17.w
acaaaaaaacaaahaeabaaaakeacaaaaaaaaaaaaoeaaaaaaaa sub v2.xyz, r1.xyzz, a0
bdaaaaaaadaaaiaeaaaaaaoeacaaaaaaapaaaaoeabaaaaaa dp4 v3.w, r0, c15
bdaaaaaaadaaaeaeaaaaaaoeacaaaaaaaoaaaaoeabaaaaaa dp4 v3.z, r0, c14
bdaaaaaaadaaacaeaaaaaaoeacaaaaaaanaaaaoeabaaaaaa dp4 v3.y, r0, c13
bdaaaaaaadaaabaeaaaaaaoeacaaaaaaamaaaaoeabaaaaaa dp4 v3.x, r0, c12
aaaaaaaaafaaapaeacaaaaoeaaaaaaaaaaaaaaaaaaaaaaaa mov v5, a2
aaaaaaaaabaaahaeabaaaaoeaaaaaaaaaaaaaaaaaaaaaaaa mov v1.xyz, a1
bdaaaaaaaaaaaiadaaaaaaoeaaaaaaaaadaaaaoeabaaaaaa dp4 o0.w, a0, c3
bdaaaaaaaaaaaeadaaaaaaoeaaaaaaaaacaaaaoeabaaaaaa dp4 o0.z, a0, c2
bdaaaaaaaaaaacadaaaaaaoeaaaaaaaaabaaaaoeabaaaaaa dp4 o0.y, a0, c1
bdaaaaaaaaaaabadaaaaaaoeaaaaaaaaaaaaaaoeabaaaaaa dp4 o0.x, a0, c0
aaaaaaaaabaaaiaeaaaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov v1.w, c0
aaaaaaaaacaaaiaeaaaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov v2.w, c0
"
}

SubProgram "d3d11_9x " {
Keywords { "SPOT" }
Bind "vertex" Vertex
Bind "color" Color
Bind "normal" Normal
ConstBuffer "$Globals" 112 // 80 used size, 4 vars
Matrix 16 [_LightMatrix0] 4
ConstBuffer "UnityLighting" 720 // 16 used size, 17 vars
Vector 0 [_WorldSpaceLightPos0] 4
ConstBuffer "UnityPerDraw" 336 // 336 used size, 6 vars
Matrix 0 [glstate_matrix_mvp] 4
Matrix 192 [_Object2World] 4
Matrix 256 [_World2Object] 4
Vector 320 [unity_Scale] 4
BindCB "$Globals" 0
BindCB "UnityLighting" 1
BindCB "UnityPerDraw" 2
// 20 instructions, 2 temp regs, 0 temp arrays:
// ALU 17 float, 0 int, 0 uint
// TEX 0 (0 load, 0 comp, 0 bias, 0 grad)
// FLOW 1 static, 0 dynamic
"vs_4_0_level_9_1
eefiecedeikidmidnabnlgbjbikkomfoibegjdckabaaaaaaaaahaaaaaeaaaaaa
daaaaaaaeeacaaaaliafaaaaeiagaaaaebgpgodjamacaaaaamacaaaaaaacpopp
leabaaaafiaaaaaaaeaaceaaaaaafeaaaaaafeaaaaaaceaaabaafeaaaaaaabaa
aeaaabaaaaaaaaaaabaaaaaaabaaafaaaaaaaaaaacaaaaaaaeaaagaaaaaaaaaa
acaaamaaajaaakaaaaaaaaaaaaaaaaaaaaacpoppbpaaaaacafaaaaiaaaaaapja
bpaaaaacafaaabiaabaaapjabpaaaaacafaaaciaacaaapjaabaaaaacaaaaapia
afaaoekaafaaaaadabaaahiaaaaaffiaapaaoekaaeaaaaaeabaaahiaaoaaoeka
aaaaaaiaabaaoeiaaeaaaaaeaaaaahiabaaaoekaaaaakkiaabaaoeiaaeaaaaae
aaaaahiabbaaoekaaaaappiaaaaaoeiaaeaaaaaeabaaahoaaaaaoeiabcaappka
aaaaoejbafaaaaadaaaaapiaaaaaffjaalaaoekaaeaaaaaeaaaaapiaakaaoeka
aaaaaajaaaaaoeiaaeaaaaaeaaaaapiaamaaoekaaaaakkjaaaaaoeiaaeaaaaae
aaaaapiaanaaoekaaaaappjaaaaaoeiaafaaaaadabaaapiaaaaaffiaacaaoeka
aeaaaaaeabaaapiaabaaoekaaaaaaaiaabaaoeiaaeaaaaaeabaaapiaadaaoeka
aaaakkiaabaaoeiaaeaaaaaeadaaapoaaeaaoekaaaaappiaabaaoeiaafaaaaad
aaaaapiaaaaaffjaahaaoekaaeaaaaaeaaaaapiaagaaoekaaaaaaajaaaaaoeia
aeaaaaaeaaaaapiaaiaaoekaaaaakkjaaaaaoeiaaeaaaaaeaaaaapiaajaaoeka
aaaappjaaaaaoeiaaeaaaaaeaaaaadmaaaaappiaaaaaoekaaaaaoeiaabaaaaac
aaaaammaaaaaoeiaabaaaaacacaaahoaacaaoejaabaaaaacaeaaapoaabaaoeja
ppppaaaafdeieefcgmadaaaaeaaaabaanlaaaaaafjaaaaaeegiocaaaaaaaaaaa
afaaaaaafjaaaaaeegiocaaaabaaaaaaabaaaaaafjaaaaaeegiocaaaacaaaaaa
bfaaaaaafpaaaaadpcbabaaaaaaaaaaafpaaaaadpcbabaaaabaaaaaafpaaaaad
hcbabaaaacaaaaaaghaaaaaepccabaaaaaaaaaaaabaaaaaagfaaaaadhccabaaa
acaaaaaagfaaaaadhccabaaaadaaaaaagfaaaaadpccabaaaaeaaaaaagfaaaaad
pccabaaaafaaaaaagiaaaaacacaaaaaadiaaaaaipcaabaaaaaaaaaaafgbfbaaa
aaaaaaaaegiocaaaacaaaaaaabaaaaaadcaaaaakpcaabaaaaaaaaaaaegiocaaa
acaaaaaaaaaaaaaaagbabaaaaaaaaaaaegaobaaaaaaaaaaadcaaaaakpcaabaaa
aaaaaaaaegiocaaaacaaaaaaacaaaaaakgbkbaaaaaaaaaaaegaobaaaaaaaaaaa
dcaaaaakpccabaaaaaaaaaaaegiocaaaacaaaaaaadaaaaaapgbpbaaaaaaaaaaa
egaobaaaaaaaaaaadiaaaaajhcaabaaaaaaaaaaafgifcaaaabaaaaaaaaaaaaaa
egiccaaaacaaaaaabbaaaaaadcaaaaalhcaabaaaaaaaaaaaegiccaaaacaaaaaa
baaaaaaaagiacaaaabaaaaaaaaaaaaaaegacbaaaaaaaaaaadcaaaaalhcaabaaa
aaaaaaaaegiccaaaacaaaaaabcaaaaaakgikcaaaabaaaaaaaaaaaaaaegacbaaa
aaaaaaaadcaaaaalhcaabaaaaaaaaaaaegiccaaaacaaaaaabdaaaaaapgipcaaa
abaaaaaaaaaaaaaaegacbaaaaaaaaaaadcaaaaalhccabaaaacaaaaaaegacbaaa
aaaaaaaapgipcaaaacaaaaaabeaaaaaaegbcbaiaebaaaaaaaaaaaaaadgaaaaaf
hccabaaaadaaaaaaegbcbaaaacaaaaaadiaaaaaipcaabaaaaaaaaaaafgbfbaaa
aaaaaaaaegiocaaaacaaaaaaanaaaaaadcaaaaakpcaabaaaaaaaaaaaegiocaaa
acaaaaaaamaaaaaaagbabaaaaaaaaaaaegaobaaaaaaaaaaadcaaaaakpcaabaaa
aaaaaaaaegiocaaaacaaaaaaaoaaaaaakgbkbaaaaaaaaaaaegaobaaaaaaaaaaa
dcaaaaakpcaabaaaaaaaaaaaegiocaaaacaaaaaaapaaaaaapgbpbaaaaaaaaaaa
egaobaaaaaaaaaaadiaaaaaipcaabaaaabaaaaaafgafbaaaaaaaaaaaegiocaaa
aaaaaaaaacaaaaaadcaaaaakpcaabaaaabaaaaaaegiocaaaaaaaaaaaabaaaaaa
agaabaaaaaaaaaaaegaobaaaabaaaaaadcaaaaakpcaabaaaabaaaaaaegiocaaa
aaaaaaaaadaaaaaakgakbaaaaaaaaaaaegaobaaaabaaaaaadcaaaaakpccabaaa
aeaaaaaaegiocaaaaaaaaaaaaeaaaaaapgapbaaaaaaaaaaaegaobaaaabaaaaaa
dgaaaaafpccabaaaafaaaaaaegbobaaaabaaaaaadoaaaaabejfdeheoiiaaaaaa
aeaaaaaaaiaaaaaagiaaaaaaaaaaaaaaaaaaaaaaadaaaaaaaaaaaaaaapapaaaa
hbaaaaaaaaaaaaaaaaaaaaaaadaaaaaaabaaaaaaapapaaaahhaaaaaaaaaaaaaa
aaaaaaaaadaaaaaaacaaaaaaahahaaaahoaaaaaaaaaaaaaaaaaaaaaaadaaaaaa
adaaaaaaahaaaaaafaepfdejfeejepeoaaedepemepfcaaeoepfcenebemaafeeb
eoehefeofeaaklklepfdeheolaaaaaaaagaaaaaaaiaaaaaajiaaaaaaaaaaaaaa
abaaaaaaadaaaaaaaaaaaaaaapaaaaaakeaaaaaaaaaaaaaaaaaaaaaaadaaaaaa
abaaaaaaadapaaaakeaaaaaaacaaaaaaaaaaaaaaadaaaaaaacaaaaaaahaiaaaa
keaaaaaaabaaaaaaaaaaaaaaadaaaaaaadaaaaaaahaiaaaakeaaaaaaadaaaaaa
aaaaaaaaadaaaaaaaeaaaaaaapaaaaaakeaaaaaaafaaaaaaaaaaaaaaadaaaaaa
afaaaaaaapaaaaaafdfgfpfaepfdejfeejepeoaafeeffiedepepfceeaaklklkl
"
}

SubProgram "gles3 " {
Keywords { "SPOT" }
"!!GLES3#version 300 es


#ifdef VERTEX

#define gl_Vertex _glesVertex
in vec4 _glesVertex;
#define gl_Color _glesColor
in vec4 _glesColor;
#define gl_Normal (normalize(_glesNormal))
in vec3 _glesNormal;
#define TANGENT vec4(normalize(_glesTANGENT.xyz), _glesTANGENT.w)
in vec4 _glesTANGENT;

#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 334
struct v2f {
    highp vec4 pos;
    highp vec2 uv;
    highp vec3 lightDir;
    highp vec3 normal;
    highp vec4 _LightCoord;
    highp vec4 color;
};
#line 326
struct appdata_t {
    highp vec4 vertex;
    lowp vec4 color;
    highp vec3 normal;
    highp vec3 tangent;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform highp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform sampler2D _LightTexture0;
uniform highp mat4 _LightMatrix0;
uniform sampler2D _LightTextureB0;
#line 344
uniform lowp vec4 _Color;
uniform lowp vec4 _LightColor0;
#line 357
#line 82
highp vec3 ObjSpaceLightDir( in highp vec4 v ) {
    highp vec3 objSpaceLightPos = (_World2Object * _WorldSpaceLightPos0).xyz;
    return ((objSpaceLightPos.xyz * unity_Scale.w) - v.xyz);
}
#line 344
v2f vert( in appdata_t v ) {
    v2f o;
    o.pos = (glstate_matrix_mvp * v.vertex);
    #line 348
    o.lightDir = ObjSpaceLightDir( v.vertex).xyz;
    o.color = v.color;
    o.normal = v.normal;
    o._LightCoord = (_LightMatrix0 * (_Object2World * v.vertex));
    #line 353
    return o;
}

out highp vec2 xlv_TEXCOORD0;
out highp vec3 xlv_TEXCOORD2;
out highp vec3 xlv_TEXCOORD1;
out highp vec4 xlv_TEXCOORD3;
out highp vec4 xlv_TEXCOORD5;
void main() {
    v2f xl_retval;
    appdata_t xlt_v;
    xlt_v.vertex = vec4(gl_Vertex);
    xlt_v.color = vec4(gl_Color);
    xlt_v.normal = vec3(gl_Normal);
    xlt_v.tangent = vec3(TANGENT);
    xl_retval = vert( xlt_v);
    gl_Position = vec4(xl_retval.pos);
    xlv_TEXCOORD0 = vec2(xl_retval.uv);
    xlv_TEXCOORD2 = vec3(xl_retval.lightDir);
    xlv_TEXCOORD1 = vec3(xl_retval.normal);
    xlv_TEXCOORD3 = vec4(xl_retval._LightCoord);
    xlv_TEXCOORD5 = vec4(xl_retval.color);
}


#endif
#ifdef FRAGMENT

#define gl_FragData _glesFragData
layout(location = 0) out mediump vec4 _glesFragData[4];
float xll_saturate_f( float x) {
  return clamp( x, 0.0, 1.0);
}
vec2 xll_saturate_vf2( vec2 x) {
  return clamp( x, 0.0, 1.0);
}
vec3 xll_saturate_vf3( vec3 x) {
  return clamp( x, 0.0, 1.0);
}
vec4 xll_saturate_vf4( vec4 x) {
  return clamp( x, 0.0, 1.0);
}
mat2 xll_saturate_mf2x2(mat2 m) {
  return mat2( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0));
}
mat3 xll_saturate_mf3x3(mat3 m) {
  return mat3( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0));
}
mat4 xll_saturate_mf4x4(mat4 m) {
  return mat4( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0), clamp(m[3], 0.0, 1.0));
}
#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 334
struct v2f {
    highp vec4 pos;
    highp vec2 uv;
    highp vec3 lightDir;
    highp vec3 normal;
    highp vec4 _LightCoord;
    highp vec4 color;
};
#line 326
struct appdata_t {
    highp vec4 vertex;
    lowp vec4 color;
    highp vec3 normal;
    highp vec3 tangent;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform highp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform sampler2D _LightTexture0;
uniform highp mat4 _LightMatrix0;
uniform sampler2D _LightTextureB0;
#line 344
uniform lowp vec4 _Color;
uniform lowp vec4 _LightColor0;
#line 357
#line 322
lowp float UnitySpotAttenuate( in highp vec3 LightCoord ) {
    #line 324
    return texture( _LightTextureB0, vec2( dot( LightCoord, LightCoord))).w;
}
#line 318
lowp float UnitySpotCookie( in highp vec4 LightCoord ) {
    #line 320
    return texture( _LightTexture0, ((LightCoord.xy / LightCoord.w) + 0.5)).w;
}
#line 357
lowp vec4 frag( in v2f IN ) {
    IN.lightDir = normalize(IN.lightDir);
    lowp float atten = (((float((IN._LightCoord.z > 0.0)) * UnitySpotCookie( IN._LightCoord)) * UnitySpotAttenuate( IN._LightCoord.xyz)) * 1.0);
    #line 361
    lowp vec3 normal = IN.normal;
    lowp float diff = xll_saturate_f(dot( normal, IN.lightDir));
    lowp vec4 c;
    c.xyz = (((IN.color.xyz * _LightColor0.xyz) * diff) * (atten * 2.0));
    #line 365
    c.w = IN.color.w;
    return c;
}
in highp vec2 xlv_TEXCOORD0;
in highp vec3 xlv_TEXCOORD2;
in highp vec3 xlv_TEXCOORD1;
in highp vec4 xlv_TEXCOORD3;
in highp vec4 xlv_TEXCOORD5;
void main() {
    lowp vec4 xl_retval;
    v2f xlt_IN;
    xlt_IN.pos = vec4(0.0);
    xlt_IN.uv = vec2(xlv_TEXCOORD0);
    xlt_IN.lightDir = vec3(xlv_TEXCOORD2);
    xlt_IN.normal = vec3(xlv_TEXCOORD1);
    xlt_IN._LightCoord = vec4(xlv_TEXCOORD3);
    xlt_IN.color = vec4(xlv_TEXCOORD5);
    xl_retval = frag( xlt_IN);
    gl_FragData[0] = vec4(xl_retval);
}


#endif"
}

SubProgram "opengl " {
Keywords { "POINT_COOKIE" }
Bind "vertex" Vertex
Bind "color" Color
Bind "normal" Normal
Vector 17 [_WorldSpaceLightPos0]
Matrix 5 [_Object2World]
Matrix 9 [_World2Object]
Vector 18 [unity_Scale]
Matrix 13 [_LightMatrix0]
"!!ARBvp1.0
# 18 ALU
PARAM c[19] = { program.local[0],
		state.matrix.mvp,
		program.local[5..18] };
TEMP R0;
TEMP R1;
MOV R1, c[17];
DP4 R0.w, vertex.position, c[8];
DP4 R0.z, R1, c[11];
DP4 R0.x, R1, c[9];
DP4 R0.y, R1, c[10];
MAD result.texcoord[2].xyz, R0, c[18].w, -vertex.position;
DP4 R0.z, vertex.position, c[7];
DP4 R0.x, vertex.position, c[5];
DP4 R0.y, vertex.position, c[6];
DP4 result.texcoord[3].z, R0, c[15];
DP4 result.texcoord[3].y, R0, c[14];
DP4 result.texcoord[3].x, R0, c[13];
MOV result.texcoord[5], vertex.color;
MOV result.texcoord[1].xyz, vertex.normal;
DP4 result.position.w, vertex.position, c[4];
DP4 result.position.z, vertex.position, c[3];
DP4 result.position.y, vertex.position, c[2];
DP4 result.position.x, vertex.position, c[1];
END
# 18 instructions, 2 R-regs
"
}

SubProgram "d3d9 " {
Keywords { "POINT_COOKIE" }
Bind "vertex" Vertex
Bind "color" Color
Bind "normal" Normal
Matrix 0 [glstate_matrix_mvp]
Vector 16 [_WorldSpaceLightPos0]
Matrix 4 [_Object2World]
Matrix 8 [_World2Object]
Vector 17 [unity_Scale]
Matrix 12 [_LightMatrix0]
"vs_2_0
; 20 ALU
dcl_position0 v0
dcl_color0 v1
dcl_normal0 v2
mov r0, c10
dp4 r2.z, c16, r0
mov r0, c9
dp4 r2.y, c16, r0
mov r1, c8
dp4 r2.x, c16, r1
dp4 r0.w, v0, c7
dp4 r0.z, v0, c6
dp4 r0.x, v0, c4
dp4 r0.y, v0, c5
mad oT2.xyz, r2, c17.w, -v0
dp4 oT3.z, r0, c14
dp4 oT3.y, r0, c13
dp4 oT3.x, r0, c12
mov oT5, v1
mov oT1.xyz, v2
dp4 oPos.w, v0, c3
dp4 oPos.z, v0, c2
dp4 oPos.y, v0, c1
dp4 oPos.x, v0, c0
"
}

SubProgram "d3d11 " {
Keywords { "POINT_COOKIE" }
Bind "vertex" Vertex
Bind "color" Color
Bind "normal" Normal
ConstBuffer "$Globals" 112 // 80 used size, 4 vars
Matrix 16 [_LightMatrix0] 4
ConstBuffer "UnityLighting" 720 // 16 used size, 17 vars
Vector 0 [_WorldSpaceLightPos0] 4
ConstBuffer "UnityPerDraw" 336 // 336 used size, 6 vars
Matrix 0 [glstate_matrix_mvp] 4
Matrix 192 [_Object2World] 4
Matrix 256 [_World2Object] 4
Vector 320 [unity_Scale] 4
BindCB "$Globals" 0
BindCB "UnityLighting" 1
BindCB "UnityPerDraw" 2
// 20 instructions, 2 temp regs, 0 temp arrays:
// ALU 17 float, 0 int, 0 uint
// TEX 0 (0 load, 0 comp, 0 bias, 0 grad)
// FLOW 1 static, 0 dynamic
"vs_4_0
eefiecedmjjpegplcgemohadockdciemelndpjpbabaaaaaaoiaeaaaaadaaaaaa
cmaaaaaalmaaaaaaheabaaaaejfdeheoiiaaaaaaaeaaaaaaaiaaaaaagiaaaaaa
aaaaaaaaaaaaaaaaadaaaaaaaaaaaaaaapapaaaahbaaaaaaaaaaaaaaaaaaaaaa
adaaaaaaabaaaaaaapapaaaahhaaaaaaaaaaaaaaaaaaaaaaadaaaaaaacaaaaaa
ahahaaaahoaaaaaaaaaaaaaaaaaaaaaaadaaaaaaadaaaaaaahaaaaaafaepfdej
feejepeoaaedepemepfcaaeoepfcenebemaafeebeoehefeofeaaklklepfdeheo
laaaaaaaagaaaaaaaiaaaaaajiaaaaaaaaaaaaaaabaaaaaaadaaaaaaaaaaaaaa
apaaaaaakeaaaaaaaaaaaaaaaaaaaaaaadaaaaaaabaaaaaaadapaaaakeaaaaaa
acaaaaaaaaaaaaaaadaaaaaaacaaaaaaahaiaaaakeaaaaaaabaaaaaaaaaaaaaa
adaaaaaaadaaaaaaahaiaaaakeaaaaaaadaaaaaaaaaaaaaaadaaaaaaaeaaaaaa
ahaiaaaakeaaaaaaafaaaaaaaaaaaaaaadaaaaaaafaaaaaaapaaaaaafdfgfpfa
epfdejfeejepeoaafeeffiedepepfceeaaklklklfdeieefcgmadaaaaeaaaabaa
nlaaaaaafjaaaaaeegiocaaaaaaaaaaaafaaaaaafjaaaaaeegiocaaaabaaaaaa
abaaaaaafjaaaaaeegiocaaaacaaaaaabfaaaaaafpaaaaadpcbabaaaaaaaaaaa
fpaaaaadpcbabaaaabaaaaaafpaaaaadhcbabaaaacaaaaaaghaaaaaepccabaaa
aaaaaaaaabaaaaaagfaaaaadhccabaaaacaaaaaagfaaaaadhccabaaaadaaaaaa
gfaaaaadhccabaaaaeaaaaaagfaaaaadpccabaaaafaaaaaagiaaaaacacaaaaaa
diaaaaaipcaabaaaaaaaaaaafgbfbaaaaaaaaaaaegiocaaaacaaaaaaabaaaaaa
dcaaaaakpcaabaaaaaaaaaaaegiocaaaacaaaaaaaaaaaaaaagbabaaaaaaaaaaa
egaobaaaaaaaaaaadcaaaaakpcaabaaaaaaaaaaaegiocaaaacaaaaaaacaaaaaa
kgbkbaaaaaaaaaaaegaobaaaaaaaaaaadcaaaaakpccabaaaaaaaaaaaegiocaaa
acaaaaaaadaaaaaapgbpbaaaaaaaaaaaegaobaaaaaaaaaaadiaaaaajhcaabaaa
aaaaaaaafgifcaaaabaaaaaaaaaaaaaaegiccaaaacaaaaaabbaaaaaadcaaaaal
hcaabaaaaaaaaaaaegiccaaaacaaaaaabaaaaaaaagiacaaaabaaaaaaaaaaaaaa
egacbaaaaaaaaaaadcaaaaalhcaabaaaaaaaaaaaegiccaaaacaaaaaabcaaaaaa
kgikcaaaabaaaaaaaaaaaaaaegacbaaaaaaaaaaadcaaaaalhcaabaaaaaaaaaaa
egiccaaaacaaaaaabdaaaaaapgipcaaaabaaaaaaaaaaaaaaegacbaaaaaaaaaaa
dcaaaaalhccabaaaacaaaaaaegacbaaaaaaaaaaapgipcaaaacaaaaaabeaaaaaa
egbcbaiaebaaaaaaaaaaaaaadgaaaaafhccabaaaadaaaaaaegbcbaaaacaaaaaa
diaaaaaipcaabaaaaaaaaaaafgbfbaaaaaaaaaaaegiocaaaacaaaaaaanaaaaaa
dcaaaaakpcaabaaaaaaaaaaaegiocaaaacaaaaaaamaaaaaaagbabaaaaaaaaaaa
egaobaaaaaaaaaaadcaaaaakpcaabaaaaaaaaaaaegiocaaaacaaaaaaaoaaaaaa
kgbkbaaaaaaaaaaaegaobaaaaaaaaaaadcaaaaakpcaabaaaaaaaaaaaegiocaaa
acaaaaaaapaaaaaapgbpbaaaaaaaaaaaegaobaaaaaaaaaaadiaaaaaihcaabaaa
abaaaaaafgafbaaaaaaaaaaaegiccaaaaaaaaaaaacaaaaaadcaaaaakhcaabaaa
abaaaaaaegiccaaaaaaaaaaaabaaaaaaagaabaaaaaaaaaaaegacbaaaabaaaaaa
dcaaaaakhcaabaaaaaaaaaaaegiccaaaaaaaaaaaadaaaaaakgakbaaaaaaaaaaa
egacbaaaabaaaaaadcaaaaakhccabaaaaeaaaaaaegiccaaaaaaaaaaaaeaaaaaa
pgapbaaaaaaaaaaaegacbaaaaaaaaaaadgaaaaafpccabaaaafaaaaaaegbobaaa
abaaaaaadoaaaaab"
}

SubProgram "gles " {
Keywords { "POINT_COOKIE" }
"!!GLES


#ifdef VERTEX

varying highp vec4 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD1;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec2 xlv_TEXCOORD0;
uniform highp mat4 _LightMatrix0;
uniform highp vec4 unity_Scale;
uniform highp mat4 _World2Object;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_mvp;
uniform highp vec4 _WorldSpaceLightPos0;
attribute vec3 _glesNormal;
attribute vec4 _glesColor;
attribute vec4 _glesVertex;
void main ()
{
  highp vec2 tmpvar_1;
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = tmpvar_1;
  xlv_TEXCOORD2 = (((_World2Object * _WorldSpaceLightPos0).xyz * unity_Scale.w) - _glesVertex.xyz);
  xlv_TEXCOORD1 = normalize(_glesNormal);
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * _glesVertex)).xyz;
  xlv_TEXCOORD5 = _glesColor;
}



#endif
#ifdef FRAGMENT

varying highp vec4 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD1;
varying highp vec3 xlv_TEXCOORD2;
uniform lowp vec4 _LightColor0;
uniform sampler2D _LightTextureB0;
uniform samplerCube _LightTexture0;
void main ()
{
  lowp vec4 c_1;
  lowp float diff_2;
  lowp vec3 normal_3;
  highp float tmpvar_4;
  tmpvar_4 = dot (xlv_TEXCOORD3, xlv_TEXCOORD3);
  lowp float tmpvar_5;
  tmpvar_5 = (texture2D (_LightTextureB0, vec2(tmpvar_4)).w * textureCube (_LightTexture0, xlv_TEXCOORD3).w);
  normal_3 = xlv_TEXCOORD1;
  highp float tmpvar_6;
  tmpvar_6 = clamp (dot (normal_3, normalize(xlv_TEXCOORD2)), 0.0, 1.0);
  diff_2 = tmpvar_6;
  highp vec3 tmpvar_7;
  tmpvar_7 = (((xlv_TEXCOORD5.xyz * _LightColor0.xyz) * diff_2) * (tmpvar_5 * 2.0));
  c_1.xyz = tmpvar_7;
  highp float tmpvar_8;
  tmpvar_8 = xlv_TEXCOORD5.w;
  c_1.w = tmpvar_8;
  gl_FragData[0] = c_1;
}



#endif"
}

SubProgram "glesdesktop " {
Keywords { "POINT_COOKIE" }
"!!GLES


#ifdef VERTEX

varying highp vec4 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD1;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec2 xlv_TEXCOORD0;
uniform highp mat4 _LightMatrix0;
uniform highp vec4 unity_Scale;
uniform highp mat4 _World2Object;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_mvp;
uniform highp vec4 _WorldSpaceLightPos0;
attribute vec3 _glesNormal;
attribute vec4 _glesColor;
attribute vec4 _glesVertex;
void main ()
{
  highp vec2 tmpvar_1;
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = tmpvar_1;
  xlv_TEXCOORD2 = (((_World2Object * _WorldSpaceLightPos0).xyz * unity_Scale.w) - _glesVertex.xyz);
  xlv_TEXCOORD1 = normalize(_glesNormal);
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * _glesVertex)).xyz;
  xlv_TEXCOORD5 = _glesColor;
}



#endif
#ifdef FRAGMENT

varying highp vec4 xlv_TEXCOORD5;
varying highp vec3 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD1;
varying highp vec3 xlv_TEXCOORD2;
uniform lowp vec4 _LightColor0;
uniform sampler2D _LightTextureB0;
uniform samplerCube _LightTexture0;
void main ()
{
  lowp vec4 c_1;
  lowp float diff_2;
  lowp vec3 normal_3;
  highp float tmpvar_4;
  tmpvar_4 = dot (xlv_TEXCOORD3, xlv_TEXCOORD3);
  lowp float tmpvar_5;
  tmpvar_5 = (texture2D (_LightTextureB0, vec2(tmpvar_4)).w * textureCube (_LightTexture0, xlv_TEXCOORD3).w);
  normal_3 = xlv_TEXCOORD1;
  highp float tmpvar_6;
  tmpvar_6 = clamp (dot (normal_3, normalize(xlv_TEXCOORD2)), 0.0, 1.0);
  diff_2 = tmpvar_6;
  highp vec3 tmpvar_7;
  tmpvar_7 = (((xlv_TEXCOORD5.xyz * _LightColor0.xyz) * diff_2) * (tmpvar_5 * 2.0));
  c_1.xyz = tmpvar_7;
  highp float tmpvar_8;
  tmpvar_8 = xlv_TEXCOORD5.w;
  c_1.w = tmpvar_8;
  gl_FragData[0] = c_1;
}



#endif"
}

SubProgram "flash " {
Keywords { "POINT_COOKIE" }
Bind "vertex" Vertex
Bind "color" Color
Bind "normal" Normal
Matrix 0 [glstate_matrix_mvp]
Vector 16 [_WorldSpaceLightPos0]
Matrix 4 [_Object2World]
Matrix 8 [_World2Object]
Vector 17 [unity_Scale]
Matrix 12 [_LightMatrix0]
"agal_vs
[bc]
aaaaaaaaaaaaapacakaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov r0, c10
bdaaaaaaacaaaeacbaaaaaoeabaaaaaaaaaaaaoeacaaaaaa dp4 r2.z, c16, r0
aaaaaaaaaaaaapacajaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov r0, c9
bdaaaaaaacaaacacbaaaaaoeabaaaaaaaaaaaaoeacaaaaaa dp4 r2.y, c16, r0
aaaaaaaaabaaapacaiaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov r1, c8
bdaaaaaaacaaabacbaaaaaoeabaaaaaaabaaaaoeacaaaaaa dp4 r2.x, c16, r1
bdaaaaaaaaaaaiacaaaaaaoeaaaaaaaaahaaaaoeabaaaaaa dp4 r0.w, a0, c7
bdaaaaaaaaaaaeacaaaaaaoeaaaaaaaaagaaaaoeabaaaaaa dp4 r0.z, a0, c6
bdaaaaaaaaaaabacaaaaaaoeaaaaaaaaaeaaaaoeabaaaaaa dp4 r0.x, a0, c4
bdaaaaaaaaaaacacaaaaaaoeaaaaaaaaafaaaaoeabaaaaaa dp4 r0.y, a0, c5
adaaaaaaabaaahacacaaaakeacaaaaaabbaaaappabaaaaaa mul r1.xyz, r2.xyzz, c17.w
acaaaaaaacaaahaeabaaaakeacaaaaaaaaaaaaoeaaaaaaaa sub v2.xyz, r1.xyzz, a0
bdaaaaaaadaaaeaeaaaaaaoeacaaaaaaaoaaaaoeabaaaaaa dp4 v3.z, r0, c14
bdaaaaaaadaaacaeaaaaaaoeacaaaaaaanaaaaoeabaaaaaa dp4 v3.y, r0, c13
bdaaaaaaadaaabaeaaaaaaoeacaaaaaaamaaaaoeabaaaaaa dp4 v3.x, r0, c12
aaaaaaaaafaaapaeacaaaaoeaaaaaaaaaaaaaaaaaaaaaaaa mov v5, a2
aaaaaaaaabaaahaeabaaaaoeaaaaaaaaaaaaaaaaaaaaaaaa mov v1.xyz, a1
bdaaaaaaaaaaaiadaaaaaaoeaaaaaaaaadaaaaoeabaaaaaa dp4 o0.w, a0, c3
bdaaaaaaaaaaaeadaaaaaaoeaaaaaaaaacaaaaoeabaaaaaa dp4 o0.z, a0, c2
bdaaaaaaaaaaacadaaaaaaoeaaaaaaaaabaaaaoeabaaaaaa dp4 o0.y, a0, c1
bdaaaaaaaaaaabadaaaaaaoeaaaaaaaaaaaaaaoeabaaaaaa dp4 o0.x, a0, c0
aaaaaaaaabaaaiaeaaaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov v1.w, c0
aaaaaaaaacaaaiaeaaaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov v2.w, c0
aaaaaaaaadaaaiaeaaaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov v3.w, c0
"
}

SubProgram "d3d11_9x " {
Keywords { "POINT_COOKIE" }
Bind "vertex" Vertex
Bind "color" Color
Bind "normal" Normal
ConstBuffer "$Globals" 112 // 80 used size, 4 vars
Matrix 16 [_LightMatrix0] 4
ConstBuffer "UnityLighting" 720 // 16 used size, 17 vars
Vector 0 [_WorldSpaceLightPos0] 4
ConstBuffer "UnityPerDraw" 336 // 336 used size, 6 vars
Matrix 0 [glstate_matrix_mvp] 4
Matrix 192 [_Object2World] 4
Matrix 256 [_World2Object] 4
Vector 320 [unity_Scale] 4
BindCB "$Globals" 0
BindCB "UnityLighting" 1
BindCB "UnityPerDraw" 2
// 20 instructions, 2 temp regs, 0 temp arrays:
// ALU 17 float, 0 int, 0 uint
// TEX 0 (0 load, 0 comp, 0 bias, 0 grad)
// FLOW 1 static, 0 dynamic
"vs_4_0_level_9_1
eefiecedakhailhlejdgcnafjjmlpemddlfdopddabaaaaaaaaahaaaaaeaaaaaa
daaaaaaaeeacaaaaliafaaaaeiagaaaaebgpgodjamacaaaaamacaaaaaaacpopp
leabaaaafiaaaaaaaeaaceaaaaaafeaaaaaafeaaaaaaceaaabaafeaaaaaaabaa
aeaaabaaaaaaaaaaabaaaaaaabaaafaaaaaaaaaaacaaaaaaaeaaagaaaaaaaaaa
acaaamaaajaaakaaaaaaaaaaaaaaaaaaaaacpoppbpaaaaacafaaaaiaaaaaapja
bpaaaaacafaaabiaabaaapjabpaaaaacafaaaciaacaaapjaabaaaaacaaaaapia
afaaoekaafaaaaadabaaahiaaaaaffiaapaaoekaaeaaaaaeabaaahiaaoaaoeka
aaaaaaiaabaaoeiaaeaaaaaeaaaaahiabaaaoekaaaaakkiaabaaoeiaaeaaaaae
aaaaahiabbaaoekaaaaappiaaaaaoeiaaeaaaaaeabaaahoaaaaaoeiabcaappka
aaaaoejbafaaaaadaaaaapiaaaaaffjaalaaoekaaeaaaaaeaaaaapiaakaaoeka
aaaaaajaaaaaoeiaaeaaaaaeaaaaapiaamaaoekaaaaakkjaaaaaoeiaaeaaaaae
aaaaapiaanaaoekaaaaappjaaaaaoeiaafaaaaadabaaahiaaaaaffiaacaaoeka
aeaaaaaeabaaahiaabaaoekaaaaaaaiaabaaoeiaaeaaaaaeaaaaahiaadaaoeka
aaaakkiaabaaoeiaaeaaaaaeadaaahoaaeaaoekaaaaappiaaaaaoeiaafaaaaad
aaaaapiaaaaaffjaahaaoekaaeaaaaaeaaaaapiaagaaoekaaaaaaajaaaaaoeia
aeaaaaaeaaaaapiaaiaaoekaaaaakkjaaaaaoeiaaeaaaaaeaaaaapiaajaaoeka
aaaappjaaaaaoeiaaeaaaaaeaaaaadmaaaaappiaaaaaoekaaaaaoeiaabaaaaac
aaaaammaaaaaoeiaabaaaaacacaaahoaacaaoejaabaaaaacaeaaapoaabaaoeja
ppppaaaafdeieefcgmadaaaaeaaaabaanlaaaaaafjaaaaaeegiocaaaaaaaaaaa
afaaaaaafjaaaaaeegiocaaaabaaaaaaabaaaaaafjaaaaaeegiocaaaacaaaaaa
bfaaaaaafpaaaaadpcbabaaaaaaaaaaafpaaaaadpcbabaaaabaaaaaafpaaaaad
hcbabaaaacaaaaaaghaaaaaepccabaaaaaaaaaaaabaaaaaagfaaaaadhccabaaa
acaaaaaagfaaaaadhccabaaaadaaaaaagfaaaaadhccabaaaaeaaaaaagfaaaaad
pccabaaaafaaaaaagiaaaaacacaaaaaadiaaaaaipcaabaaaaaaaaaaafgbfbaaa
aaaaaaaaegiocaaaacaaaaaaabaaaaaadcaaaaakpcaabaaaaaaaaaaaegiocaaa
acaaaaaaaaaaaaaaagbabaaaaaaaaaaaegaobaaaaaaaaaaadcaaaaakpcaabaaa
aaaaaaaaegiocaaaacaaaaaaacaaaaaakgbkbaaaaaaaaaaaegaobaaaaaaaaaaa
dcaaaaakpccabaaaaaaaaaaaegiocaaaacaaaaaaadaaaaaapgbpbaaaaaaaaaaa
egaobaaaaaaaaaaadiaaaaajhcaabaaaaaaaaaaafgifcaaaabaaaaaaaaaaaaaa
egiccaaaacaaaaaabbaaaaaadcaaaaalhcaabaaaaaaaaaaaegiccaaaacaaaaaa
baaaaaaaagiacaaaabaaaaaaaaaaaaaaegacbaaaaaaaaaaadcaaaaalhcaabaaa
aaaaaaaaegiccaaaacaaaaaabcaaaaaakgikcaaaabaaaaaaaaaaaaaaegacbaaa
aaaaaaaadcaaaaalhcaabaaaaaaaaaaaegiccaaaacaaaaaabdaaaaaapgipcaaa
abaaaaaaaaaaaaaaegacbaaaaaaaaaaadcaaaaalhccabaaaacaaaaaaegacbaaa
aaaaaaaapgipcaaaacaaaaaabeaaaaaaegbcbaiaebaaaaaaaaaaaaaadgaaaaaf
hccabaaaadaaaaaaegbcbaaaacaaaaaadiaaaaaipcaabaaaaaaaaaaafgbfbaaa
aaaaaaaaegiocaaaacaaaaaaanaaaaaadcaaaaakpcaabaaaaaaaaaaaegiocaaa
acaaaaaaamaaaaaaagbabaaaaaaaaaaaegaobaaaaaaaaaaadcaaaaakpcaabaaa
aaaaaaaaegiocaaaacaaaaaaaoaaaaaakgbkbaaaaaaaaaaaegaobaaaaaaaaaaa
dcaaaaakpcaabaaaaaaaaaaaegiocaaaacaaaaaaapaaaaaapgbpbaaaaaaaaaaa
egaobaaaaaaaaaaadiaaaaaihcaabaaaabaaaaaafgafbaaaaaaaaaaaegiccaaa
aaaaaaaaacaaaaaadcaaaaakhcaabaaaabaaaaaaegiccaaaaaaaaaaaabaaaaaa
agaabaaaaaaaaaaaegacbaaaabaaaaaadcaaaaakhcaabaaaaaaaaaaaegiccaaa
aaaaaaaaadaaaaaakgakbaaaaaaaaaaaegacbaaaabaaaaaadcaaaaakhccabaaa
aeaaaaaaegiccaaaaaaaaaaaaeaaaaaapgapbaaaaaaaaaaaegacbaaaaaaaaaaa
dgaaaaafpccabaaaafaaaaaaegbobaaaabaaaaaadoaaaaabejfdeheoiiaaaaaa
aeaaaaaaaiaaaaaagiaaaaaaaaaaaaaaaaaaaaaaadaaaaaaaaaaaaaaapapaaaa
hbaaaaaaaaaaaaaaaaaaaaaaadaaaaaaabaaaaaaapapaaaahhaaaaaaaaaaaaaa
aaaaaaaaadaaaaaaacaaaaaaahahaaaahoaaaaaaaaaaaaaaaaaaaaaaadaaaaaa
adaaaaaaahaaaaaafaepfdejfeejepeoaaedepemepfcaaeoepfcenebemaafeeb
eoehefeofeaaklklepfdeheolaaaaaaaagaaaaaaaiaaaaaajiaaaaaaaaaaaaaa
abaaaaaaadaaaaaaaaaaaaaaapaaaaaakeaaaaaaaaaaaaaaaaaaaaaaadaaaaaa
abaaaaaaadapaaaakeaaaaaaacaaaaaaaaaaaaaaadaaaaaaacaaaaaaahaiaaaa
keaaaaaaabaaaaaaaaaaaaaaadaaaaaaadaaaaaaahaiaaaakeaaaaaaadaaaaaa
aaaaaaaaadaaaaaaaeaaaaaaahaiaaaakeaaaaaaafaaaaaaaaaaaaaaadaaaaaa
afaaaaaaapaaaaaafdfgfpfaepfdejfeejepeoaafeeffiedepepfceeaaklklkl
"
}

SubProgram "gles3 " {
Keywords { "POINT_COOKIE" }
"!!GLES3#version 300 es


#ifdef VERTEX

#define gl_Vertex _glesVertex
in vec4 _glesVertex;
#define gl_Color _glesColor
in vec4 _glesColor;
#define gl_Normal (normalize(_glesNormal))
in vec3 _glesNormal;
#define TANGENT vec4(normalize(_glesTANGENT.xyz), _glesTANGENT.w)
in vec4 _glesTANGENT;

#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 326
struct v2f {
    highp vec4 pos;
    highp vec2 uv;
    highp vec3 lightDir;
    highp vec3 normal;
    highp vec3 _LightCoord;
    highp vec4 color;
};
#line 318
struct appdata_t {
    highp vec4 vertex;
    lowp vec4 color;
    highp vec3 normal;
    highp vec3 tangent;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform highp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform samplerCube _LightTexture0;
uniform highp mat4 _LightMatrix0;
uniform sampler2D _LightTextureB0;
#line 336
uniform lowp vec4 _Color;
uniform lowp vec4 _LightColor0;
#line 349
#line 82
highp vec3 ObjSpaceLightDir( in highp vec4 v ) {
    highp vec3 objSpaceLightPos = (_World2Object * _WorldSpaceLightPos0).xyz;
    return ((objSpaceLightPos.xyz * unity_Scale.w) - v.xyz);
}
#line 336
v2f vert( in appdata_t v ) {
    v2f o;
    o.pos = (glstate_matrix_mvp * v.vertex);
    #line 340
    o.lightDir = ObjSpaceLightDir( v.vertex).xyz;
    o.color = v.color;
    o.normal = v.normal;
    o._LightCoord = (_LightMatrix0 * (_Object2World * v.vertex)).xyz;
    #line 345
    return o;
}

out highp vec2 xlv_TEXCOORD0;
out highp vec3 xlv_TEXCOORD2;
out highp vec3 xlv_TEXCOORD1;
out highp vec3 xlv_TEXCOORD3;
out highp vec4 xlv_TEXCOORD5;
void main() {
    v2f xl_retval;
    appdata_t xlt_v;
    xlt_v.vertex = vec4(gl_Vertex);
    xlt_v.color = vec4(gl_Color);
    xlt_v.normal = vec3(gl_Normal);
    xlt_v.tangent = vec3(TANGENT);
    xl_retval = vert( xlt_v);
    gl_Position = vec4(xl_retval.pos);
    xlv_TEXCOORD0 = vec2(xl_retval.uv);
    xlv_TEXCOORD2 = vec3(xl_retval.lightDir);
    xlv_TEXCOORD1 = vec3(xl_retval.normal);
    xlv_TEXCOORD3 = vec3(xl_retval._LightCoord);
    xlv_TEXCOORD5 = vec4(xl_retval.color);
}


#endif
#ifdef FRAGMENT

#define gl_FragData _glesFragData
layout(location = 0) out mediump vec4 _glesFragData[4];
float xll_saturate_f( float x) {
  return clamp( x, 0.0, 1.0);
}
vec2 xll_saturate_vf2( vec2 x) {
  return clamp( x, 0.0, 1.0);
}
vec3 xll_saturate_vf3( vec3 x) {
  return clamp( x, 0.0, 1.0);
}
vec4 xll_saturate_vf4( vec4 x) {
  return clamp( x, 0.0, 1.0);
}
mat2 xll_saturate_mf2x2(mat2 m) {
  return mat2( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0));
}
mat3 xll_saturate_mf3x3(mat3 m) {
  return mat3( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0));
}
mat4 xll_saturate_mf4x4(mat4 m) {
  return mat4( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0), clamp(m[3], 0.0, 1.0));
}
#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 326
struct v2f {
    highp vec4 pos;
    highp vec2 uv;
    highp vec3 lightDir;
    highp vec3 normal;
    highp vec3 _LightCoord;
    highp vec4 color;
};
#line 318
struct appdata_t {
    highp vec4 vertex;
    lowp vec4 color;
    highp vec3 normal;
    highp vec3 tangent;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform highp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform samplerCube _LightTexture0;
uniform highp mat4 _LightMatrix0;
uniform sampler2D _LightTextureB0;
#line 336
uniform lowp vec4 _Color;
uniform lowp vec4 _LightColor0;
#line 349
#line 349
lowp vec4 frag( in v2f IN ) {
    IN.lightDir = normalize(IN.lightDir);
    lowp float atten = ((texture( _LightTextureB0, vec2( dot( IN._LightCoord, IN._LightCoord))).w * texture( _LightTexture0, IN._LightCoord).w) * 1.0);
    #line 353
    lowp vec3 normal = IN.normal;
    lowp float diff = xll_saturate_f(dot( normal, IN.lightDir));
    lowp vec4 c;
    c.xyz = (((IN.color.xyz * _LightColor0.xyz) * diff) * (atten * 2.0));
    #line 357
    c.w = IN.color.w;
    return c;
}
in highp vec2 xlv_TEXCOORD0;
in highp vec3 xlv_TEXCOORD2;
in highp vec3 xlv_TEXCOORD1;
in highp vec3 xlv_TEXCOORD3;
in highp vec4 xlv_TEXCOORD5;
void main() {
    lowp vec4 xl_retval;
    v2f xlt_IN;
    xlt_IN.pos = vec4(0.0);
    xlt_IN.uv = vec2(xlv_TEXCOORD0);
    xlt_IN.lightDir = vec3(xlv_TEXCOORD2);
    xlt_IN.normal = vec3(xlv_TEXCOORD1);
    xlt_IN._LightCoord = vec3(xlv_TEXCOORD3);
    xlt_IN.color = vec4(xlv_TEXCOORD5);
    xl_retval = frag( xlt_IN);
    gl_FragData[0] = vec4(xl_retval);
}


#endif"
}

SubProgram "opengl " {
Keywords { "DIRECTIONAL_COOKIE" }
Bind "vertex" Vertex
Bind "color" Color
Bind "normal" Normal
Vector 17 [_WorldSpaceLightPos0]
Matrix 5 [_Object2World]
Matrix 9 [_World2Object]
Matrix 13 [_LightMatrix0]
"!!ARBvp1.0
# 16 ALU
PARAM c[18] = { program.local[0],
		state.matrix.mvp,
		program.local[5..17] };
TEMP R0;
MOV R0, c[17];
DP4 result.texcoord[2].z, R0, c[11];
DP4 result.texcoord[2].y, R0, c[10];
DP4 result.texcoord[2].x, R0, c[9];
DP4 R0.w, vertex.position, c[8];
DP4 R0.z, vertex.position, c[7];
DP4 R0.x, vertex.position, c[5];
DP4 R0.y, vertex.position, c[6];
DP4 result.texcoord[3].y, R0, c[14];
DP4 result.texcoord[3].x, R0, c[13];
MOV result.texcoord[5], vertex.color;
MOV result.texcoord[1].xyz, vertex.normal;
DP4 result.position.w, vertex.position, c[4];
DP4 result.position.z, vertex.position, c[3];
DP4 result.position.y, vertex.position, c[2];
DP4 result.position.x, vertex.position, c[1];
END
# 16 instructions, 1 R-regs
"
}

SubProgram "d3d9 " {
Keywords { "DIRECTIONAL_COOKIE" }
Bind "vertex" Vertex
Bind "color" Color
Bind "normal" Normal
Matrix 0 [glstate_matrix_mvp]
Vector 16 [_WorldSpaceLightPos0]
Matrix 4 [_Object2World]
Matrix 8 [_World2Object]
Matrix 12 [_LightMatrix0]
"vs_2_0
; 18 ALU
dcl_position0 v0
dcl_color0 v1
dcl_normal0 v2
mov r0, c10
dp4 oT2.z, c16, r0
mov r0, c9
dp4 oT2.y, c16, r0
mov r1, c8
dp4 r0.w, v0, c7
dp4 r0.z, v0, c6
dp4 r0.x, v0, c4
dp4 r0.y, v0, c5
dp4 oT2.x, c16, r1
dp4 oT3.y, r0, c13
dp4 oT3.x, r0, c12
mov oT5, v1
mov oT1.xyz, v2
dp4 oPos.w, v0, c3
dp4 oPos.z, v0, c2
dp4 oPos.y, v0, c1
dp4 oPos.x, v0, c0
"
}

SubProgram "d3d11 " {
Keywords { "DIRECTIONAL_COOKIE" }
Bind "vertex" Vertex
Bind "color" Color
Bind "normal" Normal
ConstBuffer "$Globals" 112 // 80 used size, 4 vars
Matrix 16 [_LightMatrix0] 4
ConstBuffer "UnityLighting" 720 // 16 used size, 17 vars
Vector 0 [_WorldSpaceLightPos0] 4
ConstBuffer "UnityPerDraw" 336 // 320 used size, 6 vars
Matrix 0 [glstate_matrix_mvp] 4
Matrix 192 [_Object2World] 4
Matrix 256 [_World2Object] 4
BindCB "$Globals" 0
BindCB "UnityLighting" 1
BindCB "UnityPerDraw" 2
// 19 instructions, 2 temp regs, 0 temp arrays:
// ALU 16 float, 0 int, 0 uint
// TEX 0 (0 load, 0 comp, 0 bias, 0 grad)
// FLOW 1 static, 0 dynamic
"vs_4_0
eefieceddmhacdconjpjameeinopjabeejblfbnhabaaaaaalmaeaaaaadaaaaaa
cmaaaaaalmaaaaaaheabaaaaejfdeheoiiaaaaaaaeaaaaaaaiaaaaaagiaaaaaa
aaaaaaaaaaaaaaaaadaaaaaaaaaaaaaaapapaaaahbaaaaaaaaaaaaaaaaaaaaaa
adaaaaaaabaaaaaaapapaaaahhaaaaaaaaaaaaaaaaaaaaaaadaaaaaaacaaaaaa
ahahaaaahoaaaaaaaaaaaaaaaaaaaaaaadaaaaaaadaaaaaaahaaaaaafaepfdej
feejepeoaaedepemepfcaaeoepfcenebemaafeebeoehefeofeaaklklepfdeheo
laaaaaaaagaaaaaaaiaaaaaajiaaaaaaaaaaaaaaabaaaaaaadaaaaaaaaaaaaaa
apaaaaaakeaaaaaaaaaaaaaaaaaaaaaaadaaaaaaabaaaaaaadapaaaakeaaaaaa
adaaaaaaaaaaaaaaadaaaaaaabaaaaaaamadaaaakeaaaaaaacaaaaaaaaaaaaaa
adaaaaaaacaaaaaaahaiaaaakeaaaaaaabaaaaaaaaaaaaaaadaaaaaaadaaaaaa
ahaiaaaakeaaaaaaafaaaaaaaaaaaaaaadaaaaaaaeaaaaaaapaaaaaafdfgfpfa
epfdejfeejepeoaafeeffiedepepfceeaaklklklfdeieefceaadaaaaeaaaabaa
naaaaaaafjaaaaaeegiocaaaaaaaaaaaafaaaaaafjaaaaaeegiocaaaabaaaaaa
abaaaaaafjaaaaaeegiocaaaacaaaaaabeaaaaaafpaaaaadpcbabaaaaaaaaaaa
fpaaaaadpcbabaaaabaaaaaafpaaaaadhcbabaaaacaaaaaaghaaaaaepccabaaa
aaaaaaaaabaaaaaagfaaaaadmccabaaaabaaaaaagfaaaaadhccabaaaacaaaaaa
gfaaaaadhccabaaaadaaaaaagfaaaaadpccabaaaaeaaaaaagiaaaaacacaaaaaa
diaaaaaipcaabaaaaaaaaaaafgbfbaaaaaaaaaaaegiocaaaacaaaaaaabaaaaaa
dcaaaaakpcaabaaaaaaaaaaaegiocaaaacaaaaaaaaaaaaaaagbabaaaaaaaaaaa
egaobaaaaaaaaaaadcaaaaakpcaabaaaaaaaaaaaegiocaaaacaaaaaaacaaaaaa
kgbkbaaaaaaaaaaaegaobaaaaaaaaaaadcaaaaakpccabaaaaaaaaaaaegiocaaa
acaaaaaaadaaaaaapgbpbaaaaaaaaaaaegaobaaaaaaaaaaadiaaaaajhcaabaaa
aaaaaaaafgifcaaaabaaaaaaaaaaaaaaegiccaaaacaaaaaabbaaaaaadcaaaaal
hcaabaaaaaaaaaaaegiccaaaacaaaaaabaaaaaaaagiacaaaabaaaaaaaaaaaaaa
egacbaaaaaaaaaaadcaaaaalhcaabaaaaaaaaaaaegiccaaaacaaaaaabcaaaaaa
kgikcaaaabaaaaaaaaaaaaaaegacbaaaaaaaaaaadcaaaaalhccabaaaacaaaaaa
egiccaaaacaaaaaabdaaaaaapgipcaaaabaaaaaaaaaaaaaaegacbaaaaaaaaaaa
dgaaaaafhccabaaaadaaaaaaegbcbaaaacaaaaaadiaaaaaipcaabaaaaaaaaaaa
fgbfbaaaaaaaaaaaegiocaaaacaaaaaaanaaaaaadcaaaaakpcaabaaaaaaaaaaa
egiocaaaacaaaaaaamaaaaaaagbabaaaaaaaaaaaegaobaaaaaaaaaaadcaaaaak
pcaabaaaaaaaaaaaegiocaaaacaaaaaaaoaaaaaakgbkbaaaaaaaaaaaegaobaaa
aaaaaaaadcaaaaakpcaabaaaaaaaaaaaegiocaaaacaaaaaaapaaaaaapgbpbaaa
aaaaaaaaegaobaaaaaaaaaaadiaaaaaidcaabaaaabaaaaaafgafbaaaaaaaaaaa
egiacaaaaaaaaaaaacaaaaaadcaaaaakdcaabaaaaaaaaaaaegiacaaaaaaaaaaa
abaaaaaaagaabaaaaaaaaaaaegaabaaaabaaaaaadcaaaaakdcaabaaaaaaaaaaa
egiacaaaaaaaaaaaadaaaaaakgakbaaaaaaaaaaaegaabaaaaaaaaaaadcaaaaak
mccabaaaabaaaaaaagiecaaaaaaaaaaaaeaaaaaapgapbaaaaaaaaaaaagaebaaa
aaaaaaaadgaaaaafpccabaaaaeaaaaaaegbobaaaabaaaaaadoaaaaab"
}

SubProgram "gles " {
Keywords { "DIRECTIONAL_COOKIE" }
"!!GLES


#ifdef VERTEX

varying highp vec4 xlv_TEXCOORD5;
varying highp vec2 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD1;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec2 xlv_TEXCOORD0;
uniform highp mat4 _LightMatrix0;
uniform highp mat4 _World2Object;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_mvp;
uniform lowp vec4 _WorldSpaceLightPos0;
attribute vec3 _glesNormal;
attribute vec4 _glesColor;
attribute vec4 _glesVertex;
void main ()
{
  highp vec2 tmpvar_1;
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = tmpvar_1;
  xlv_TEXCOORD2 = (_World2Object * _WorldSpaceLightPos0).xyz;
  xlv_TEXCOORD1 = normalize(_glesNormal);
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * _glesVertex)).xy;
  xlv_TEXCOORD5 = _glesColor;
}



#endif
#ifdef FRAGMENT

varying highp vec4 xlv_TEXCOORD5;
varying highp vec2 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD1;
varying highp vec3 xlv_TEXCOORD2;
uniform lowp vec4 _LightColor0;
uniform sampler2D _LightTexture0;
void main ()
{
  lowp vec4 c_1;
  lowp float diff_2;
  lowp vec3 normal_3;
  lowp float tmpvar_4;
  tmpvar_4 = texture2D (_LightTexture0, xlv_TEXCOORD3).w;
  normal_3 = xlv_TEXCOORD1;
  highp float tmpvar_5;
  tmpvar_5 = clamp (dot (normal_3, normalize(xlv_TEXCOORD2)), 0.0, 1.0);
  diff_2 = tmpvar_5;
  highp vec3 tmpvar_6;
  tmpvar_6 = (((xlv_TEXCOORD5.xyz * _LightColor0.xyz) * diff_2) * (tmpvar_4 * 2.0));
  c_1.xyz = tmpvar_6;
  highp float tmpvar_7;
  tmpvar_7 = xlv_TEXCOORD5.w;
  c_1.w = tmpvar_7;
  gl_FragData[0] = c_1;
}



#endif"
}

SubProgram "glesdesktop " {
Keywords { "DIRECTIONAL_COOKIE" }
"!!GLES


#ifdef VERTEX

varying highp vec4 xlv_TEXCOORD5;
varying highp vec2 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD1;
varying highp vec3 xlv_TEXCOORD2;
varying highp vec2 xlv_TEXCOORD0;
uniform highp mat4 _LightMatrix0;
uniform highp mat4 _World2Object;
uniform highp mat4 _Object2World;
uniform highp mat4 glstate_matrix_mvp;
uniform lowp vec4 _WorldSpaceLightPos0;
attribute vec3 _glesNormal;
attribute vec4 _glesColor;
attribute vec4 _glesVertex;
void main ()
{
  highp vec2 tmpvar_1;
  gl_Position = (glstate_matrix_mvp * _glesVertex);
  xlv_TEXCOORD0 = tmpvar_1;
  xlv_TEXCOORD2 = (_World2Object * _WorldSpaceLightPos0).xyz;
  xlv_TEXCOORD1 = normalize(_glesNormal);
  xlv_TEXCOORD3 = (_LightMatrix0 * (_Object2World * _glesVertex)).xy;
  xlv_TEXCOORD5 = _glesColor;
}



#endif
#ifdef FRAGMENT

varying highp vec4 xlv_TEXCOORD5;
varying highp vec2 xlv_TEXCOORD3;
varying highp vec3 xlv_TEXCOORD1;
varying highp vec3 xlv_TEXCOORD2;
uniform lowp vec4 _LightColor0;
uniform sampler2D _LightTexture0;
void main ()
{
  lowp vec4 c_1;
  lowp float diff_2;
  lowp vec3 normal_3;
  lowp float tmpvar_4;
  tmpvar_4 = texture2D (_LightTexture0, xlv_TEXCOORD3).w;
  normal_3 = xlv_TEXCOORD1;
  highp float tmpvar_5;
  tmpvar_5 = clamp (dot (normal_3, normalize(xlv_TEXCOORD2)), 0.0, 1.0);
  diff_2 = tmpvar_5;
  highp vec3 tmpvar_6;
  tmpvar_6 = (((xlv_TEXCOORD5.xyz * _LightColor0.xyz) * diff_2) * (tmpvar_4 * 2.0));
  c_1.xyz = tmpvar_6;
  highp float tmpvar_7;
  tmpvar_7 = xlv_TEXCOORD5.w;
  c_1.w = tmpvar_7;
  gl_FragData[0] = c_1;
}



#endif"
}

SubProgram "flash " {
Keywords { "DIRECTIONAL_COOKIE" }
Bind "vertex" Vertex
Bind "color" Color
Bind "normal" Normal
Matrix 0 [glstate_matrix_mvp]
Vector 16 [_WorldSpaceLightPos0]
Matrix 4 [_Object2World]
Matrix 8 [_World2Object]
Matrix 12 [_LightMatrix0]
"agal_vs
[bc]
aaaaaaaaaaaaapacakaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov r0, c10
bdaaaaaaacaaaeaebaaaaaoeabaaaaaaaaaaaaoeacaaaaaa dp4 v2.z, c16, r0
aaaaaaaaaaaaapacajaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov r0, c9
bdaaaaaaacaaacaebaaaaaoeabaaaaaaaaaaaaoeacaaaaaa dp4 v2.y, c16, r0
aaaaaaaaabaaapacaiaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov r1, c8
bdaaaaaaaaaaaiacaaaaaaoeaaaaaaaaahaaaaoeabaaaaaa dp4 r0.w, a0, c7
bdaaaaaaaaaaaeacaaaaaaoeaaaaaaaaagaaaaoeabaaaaaa dp4 r0.z, a0, c6
bdaaaaaaaaaaabacaaaaaaoeaaaaaaaaaeaaaaoeabaaaaaa dp4 r0.x, a0, c4
bdaaaaaaaaaaacacaaaaaaoeaaaaaaaaafaaaaoeabaaaaaa dp4 r0.y, a0, c5
bdaaaaaaacaaabaebaaaaaoeabaaaaaaabaaaaoeacaaaaaa dp4 v2.x, c16, r1
bdaaaaaaadaaacaeaaaaaaoeacaaaaaaanaaaaoeabaaaaaa dp4 v3.y, r0, c13
bdaaaaaaadaaabaeaaaaaaoeacaaaaaaamaaaaoeabaaaaaa dp4 v3.x, r0, c12
aaaaaaaaafaaapaeacaaaaoeaaaaaaaaaaaaaaaaaaaaaaaa mov v5, a2
aaaaaaaaabaaahaeabaaaaoeaaaaaaaaaaaaaaaaaaaaaaaa mov v1.xyz, a1
bdaaaaaaaaaaaiadaaaaaaoeaaaaaaaaadaaaaoeabaaaaaa dp4 o0.w, a0, c3
bdaaaaaaaaaaaeadaaaaaaoeaaaaaaaaacaaaaoeabaaaaaa dp4 o0.z, a0, c2
bdaaaaaaaaaaacadaaaaaaoeaaaaaaaaabaaaaoeabaaaaaa dp4 o0.y, a0, c1
bdaaaaaaaaaaabadaaaaaaoeaaaaaaaaaaaaaaoeabaaaaaa dp4 o0.x, a0, c0
aaaaaaaaabaaaiaeaaaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov v1.w, c0
aaaaaaaaacaaaiaeaaaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov v2.w, c0
aaaaaaaaadaaamaeaaaaaaoeabaaaaaaaaaaaaaaaaaaaaaa mov v3.zw, c0
"
}

SubProgram "d3d11_9x " {
Keywords { "DIRECTIONAL_COOKIE" }
Bind "vertex" Vertex
Bind "color" Color
Bind "normal" Normal
ConstBuffer "$Globals" 112 // 80 used size, 4 vars
Matrix 16 [_LightMatrix0] 4
ConstBuffer "UnityLighting" 720 // 16 used size, 17 vars
Vector 0 [_WorldSpaceLightPos0] 4
ConstBuffer "UnityPerDraw" 336 // 320 used size, 6 vars
Matrix 0 [glstate_matrix_mvp] 4
Matrix 192 [_Object2World] 4
Matrix 256 [_World2Object] 4
BindCB "$Globals" 0
BindCB "UnityLighting" 1
BindCB "UnityPerDraw" 2
// 19 instructions, 2 temp regs, 0 temp arrays:
// ALU 16 float, 0 int, 0 uint
// TEX 0 (0 load, 0 comp, 0 bias, 0 grad)
// FLOW 1 static, 0 dynamic
"vs_4_0_level_9_1
eefiecedfdghapkdldpokkagfeafamaifeehnmmfabaaaaaamaagaaaaaeaaaaaa
daaaaaaadaacaaaahiafaaaaaiagaaaaebgpgodjpiabaaaapiabaaaaaaacpopp
kaabaaaafiaaaaaaaeaaceaaaaaafeaaaaaafeaaaaaaceaaabaafeaaaaaaabaa
aeaaabaaaaaaaaaaabaaaaaaabaaafaaaaaaaaaaacaaaaaaaeaaagaaaaaaaaaa
acaaamaaaiaaakaaaaaaaaaaaaaaaaaaaaacpoppbpaaaaacafaaaaiaaaaaapja
bpaaaaacafaaabiaabaaapjabpaaaaacafaaaciaacaaapjaabaaaaacaaaaapia
afaaoekaafaaaaadabaaahiaaaaaffiaapaaoekaaeaaaaaeabaaahiaaoaaoeka
aaaaaaiaabaaoeiaaeaaaaaeaaaaahiabaaaoekaaaaakkiaabaaoeiaaeaaaaae
abaaahoabbaaoekaaaaappiaaaaaoeiaafaaaaadaaaaapiaaaaaffjaalaaoeka
aeaaaaaeaaaaapiaakaaoekaaaaaaajaaaaaoeiaaeaaaaaeaaaaapiaamaaoeka
aaaakkjaaaaaoeiaaeaaaaaeaaaaapiaanaaoekaaaaappjaaaaaoeiaafaaaaad
abaaadiaaaaaffiaacaaobkaaeaaaaaeaaaaadiaabaaobkaaaaaaaiaabaaoeia
aeaaaaaeaaaaadiaadaaobkaaaaakkiaaaaaoeiaaeaaaaaeaaaaamoaaeaabeka
aaaappiaaaaaeeiaafaaaaadaaaaapiaaaaaffjaahaaoekaaeaaaaaeaaaaapia
agaaoekaaaaaaajaaaaaoeiaaeaaaaaeaaaaapiaaiaaoekaaaaakkjaaaaaoeia
aeaaaaaeaaaaapiaajaaoekaaaaappjaaaaaoeiaaeaaaaaeaaaaadmaaaaappia
aaaaoekaaaaaoeiaabaaaaacaaaaammaaaaaoeiaabaaaaacacaaahoaacaaoeja
abaaaaacadaaapoaabaaoejappppaaaafdeieefceaadaaaaeaaaabaanaaaaaaa
fjaaaaaeegiocaaaaaaaaaaaafaaaaaafjaaaaaeegiocaaaabaaaaaaabaaaaaa
fjaaaaaeegiocaaaacaaaaaabeaaaaaafpaaaaadpcbabaaaaaaaaaaafpaaaaad
pcbabaaaabaaaaaafpaaaaadhcbabaaaacaaaaaaghaaaaaepccabaaaaaaaaaaa
abaaaaaagfaaaaadmccabaaaabaaaaaagfaaaaadhccabaaaacaaaaaagfaaaaad
hccabaaaadaaaaaagfaaaaadpccabaaaaeaaaaaagiaaaaacacaaaaaadiaaaaai
pcaabaaaaaaaaaaafgbfbaaaaaaaaaaaegiocaaaacaaaaaaabaaaaaadcaaaaak
pcaabaaaaaaaaaaaegiocaaaacaaaaaaaaaaaaaaagbabaaaaaaaaaaaegaobaaa
aaaaaaaadcaaaaakpcaabaaaaaaaaaaaegiocaaaacaaaaaaacaaaaaakgbkbaaa
aaaaaaaaegaobaaaaaaaaaaadcaaaaakpccabaaaaaaaaaaaegiocaaaacaaaaaa
adaaaaaapgbpbaaaaaaaaaaaegaobaaaaaaaaaaadiaaaaajhcaabaaaaaaaaaaa
fgifcaaaabaaaaaaaaaaaaaaegiccaaaacaaaaaabbaaaaaadcaaaaalhcaabaaa
aaaaaaaaegiccaaaacaaaaaabaaaaaaaagiacaaaabaaaaaaaaaaaaaaegacbaaa
aaaaaaaadcaaaaalhcaabaaaaaaaaaaaegiccaaaacaaaaaabcaaaaaakgikcaaa
abaaaaaaaaaaaaaaegacbaaaaaaaaaaadcaaaaalhccabaaaacaaaaaaegiccaaa
acaaaaaabdaaaaaapgipcaaaabaaaaaaaaaaaaaaegacbaaaaaaaaaaadgaaaaaf
hccabaaaadaaaaaaegbcbaaaacaaaaaadiaaaaaipcaabaaaaaaaaaaafgbfbaaa
aaaaaaaaegiocaaaacaaaaaaanaaaaaadcaaaaakpcaabaaaaaaaaaaaegiocaaa
acaaaaaaamaaaaaaagbabaaaaaaaaaaaegaobaaaaaaaaaaadcaaaaakpcaabaaa
aaaaaaaaegiocaaaacaaaaaaaoaaaaaakgbkbaaaaaaaaaaaegaobaaaaaaaaaaa
dcaaaaakpcaabaaaaaaaaaaaegiocaaaacaaaaaaapaaaaaapgbpbaaaaaaaaaaa
egaobaaaaaaaaaaadiaaaaaidcaabaaaabaaaaaafgafbaaaaaaaaaaaegiacaaa
aaaaaaaaacaaaaaadcaaaaakdcaabaaaaaaaaaaaegiacaaaaaaaaaaaabaaaaaa
agaabaaaaaaaaaaaegaabaaaabaaaaaadcaaaaakdcaabaaaaaaaaaaaegiacaaa
aaaaaaaaadaaaaaakgakbaaaaaaaaaaaegaabaaaaaaaaaaadcaaaaakmccabaaa
abaaaaaaagiecaaaaaaaaaaaaeaaaaaapgapbaaaaaaaaaaaagaebaaaaaaaaaaa
dgaaaaafpccabaaaaeaaaaaaegbobaaaabaaaaaadoaaaaabejfdeheoiiaaaaaa
aeaaaaaaaiaaaaaagiaaaaaaaaaaaaaaaaaaaaaaadaaaaaaaaaaaaaaapapaaaa
hbaaaaaaaaaaaaaaaaaaaaaaadaaaaaaabaaaaaaapapaaaahhaaaaaaaaaaaaaa
aaaaaaaaadaaaaaaacaaaaaaahahaaaahoaaaaaaaaaaaaaaaaaaaaaaadaaaaaa
adaaaaaaahaaaaaafaepfdejfeejepeoaaedepemepfcaaeoepfcenebemaafeeb
eoehefeofeaaklklepfdeheolaaaaaaaagaaaaaaaiaaaaaajiaaaaaaaaaaaaaa
abaaaaaaadaaaaaaaaaaaaaaapaaaaaakeaaaaaaaaaaaaaaaaaaaaaaadaaaaaa
abaaaaaaadapaaaakeaaaaaaadaaaaaaaaaaaaaaadaaaaaaabaaaaaaamadaaaa
keaaaaaaacaaaaaaaaaaaaaaadaaaaaaacaaaaaaahaiaaaakeaaaaaaabaaaaaa
aaaaaaaaadaaaaaaadaaaaaaahaiaaaakeaaaaaaafaaaaaaaaaaaaaaadaaaaaa
aeaaaaaaapaaaaaafdfgfpfaepfdejfeejepeoaafeeffiedepepfceeaaklklkl
"
}

SubProgram "gles3 " {
Keywords { "DIRECTIONAL_COOKIE" }
"!!GLES3#version 300 es


#ifdef VERTEX

#define gl_Vertex _glesVertex
in vec4 _glesVertex;
#define gl_Color _glesColor
in vec4 _glesColor;
#define gl_Normal (normalize(_glesNormal))
in vec3 _glesNormal;
#define TANGENT vec4(normalize(_glesTANGENT.xyz), _glesTANGENT.w)
in vec4 _glesTANGENT;

#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 325
struct v2f {
    highp vec4 pos;
    highp vec2 uv;
    highp vec3 lightDir;
    highp vec3 normal;
    highp vec2 _LightCoord;
    highp vec4 color;
};
#line 317
struct appdata_t {
    highp vec4 vertex;
    lowp vec4 color;
    highp vec3 normal;
    highp vec3 tangent;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform lowp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform sampler2D _LightTexture0;
uniform highp mat4 _LightMatrix0;
#line 335
uniform lowp vec4 _Color;
uniform lowp vec4 _LightColor0;
#line 348
#line 82
highp vec3 ObjSpaceLightDir( in highp vec4 v ) {
    highp vec3 objSpaceLightPos = (_World2Object * _WorldSpaceLightPos0).xyz;
    return objSpaceLightPos.xyz;
}
#line 335
v2f vert( in appdata_t v ) {
    v2f o;
    o.pos = (glstate_matrix_mvp * v.vertex);
    #line 339
    o.lightDir = ObjSpaceLightDir( v.vertex).xyz;
    o.color = v.color;
    o.normal = v.normal;
    o._LightCoord = (_LightMatrix0 * (_Object2World * v.vertex)).xy;
    #line 344
    return o;
}

out highp vec2 xlv_TEXCOORD0;
out highp vec3 xlv_TEXCOORD2;
out highp vec3 xlv_TEXCOORD1;
out highp vec2 xlv_TEXCOORD3;
out highp vec4 xlv_TEXCOORD5;
void main() {
    v2f xl_retval;
    appdata_t xlt_v;
    xlt_v.vertex = vec4(gl_Vertex);
    xlt_v.color = vec4(gl_Color);
    xlt_v.normal = vec3(gl_Normal);
    xlt_v.tangent = vec3(TANGENT);
    xl_retval = vert( xlt_v);
    gl_Position = vec4(xl_retval.pos);
    xlv_TEXCOORD0 = vec2(xl_retval.uv);
    xlv_TEXCOORD2 = vec3(xl_retval.lightDir);
    xlv_TEXCOORD1 = vec3(xl_retval.normal);
    xlv_TEXCOORD3 = vec2(xl_retval._LightCoord);
    xlv_TEXCOORD5 = vec4(xl_retval.color);
}


#endif
#ifdef FRAGMENT

#define gl_FragData _glesFragData
layout(location = 0) out mediump vec4 _glesFragData[4];
float xll_saturate_f( float x) {
  return clamp( x, 0.0, 1.0);
}
vec2 xll_saturate_vf2( vec2 x) {
  return clamp( x, 0.0, 1.0);
}
vec3 xll_saturate_vf3( vec3 x) {
  return clamp( x, 0.0, 1.0);
}
vec4 xll_saturate_vf4( vec4 x) {
  return clamp( x, 0.0, 1.0);
}
mat2 xll_saturate_mf2x2(mat2 m) {
  return mat2( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0));
}
mat3 xll_saturate_mf3x3(mat3 m) {
  return mat3( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0));
}
mat4 xll_saturate_mf4x4(mat4 m) {
  return mat4( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0), clamp(m[3], 0.0, 1.0));
}
#line 151
struct v2f_vertex_lit {
    highp vec2 uv;
    lowp vec4 diff;
    lowp vec4 spec;
};
#line 187
struct v2f_img {
    highp vec4 pos;
    mediump vec2 uv;
};
#line 181
struct appdata_img {
    highp vec4 vertex;
    mediump vec2 texcoord;
};
#line 325
struct v2f {
    highp vec4 pos;
    highp vec2 uv;
    highp vec3 lightDir;
    highp vec3 normal;
    highp vec2 _LightCoord;
    highp vec4 color;
};
#line 317
struct appdata_t {
    highp vec4 vertex;
    lowp vec4 color;
    highp vec3 normal;
    highp vec3 tangent;
};
uniform highp vec4 _Time;
uniform highp vec4 _SinTime;
#line 3
uniform highp vec4 _CosTime;
uniform highp vec4 unity_DeltaTime;
uniform highp vec3 _WorldSpaceCameraPos;
uniform highp vec4 _ProjectionParams;
#line 7
uniform highp vec4 _ScreenParams;
uniform highp vec4 _ZBufferParams;
uniform highp vec4 unity_CameraWorldClipPlanes[6];
uniform lowp vec4 _WorldSpaceLightPos0;
#line 11
uniform highp vec4 _LightPositionRange;
uniform highp vec4 unity_4LightPosX0;
uniform highp vec4 unity_4LightPosY0;
uniform highp vec4 unity_4LightPosZ0;
#line 15
uniform highp vec4 unity_4LightAtten0;
uniform highp vec4 unity_LightColor[8];
uniform highp vec4 unity_LightPosition[8];
uniform highp vec4 unity_LightAtten[8];
#line 19
uniform highp vec4 unity_SpotDirection[8];
uniform highp vec4 unity_SHAr;
uniform highp vec4 unity_SHAg;
uniform highp vec4 unity_SHAb;
#line 23
uniform highp vec4 unity_SHBr;
uniform highp vec4 unity_SHBg;
uniform highp vec4 unity_SHBb;
uniform highp vec4 unity_SHC;
#line 27
uniform highp vec3 unity_LightColor0;
uniform highp vec3 unity_LightColor1;
uniform highp vec3 unity_LightColor2;
uniform highp vec3 unity_LightColor3;
uniform highp vec4 unity_ShadowSplitSpheres[4];
uniform highp vec4 unity_ShadowSplitSqRadii;
uniform highp vec4 unity_LightShadowBias;
#line 31
uniform highp vec4 _LightSplitsNear;
uniform highp vec4 _LightSplitsFar;
uniform highp mat4 unity_World2Shadow[4];
uniform highp vec4 _LightShadowData;
#line 35
uniform highp vec4 unity_ShadowFadeCenterAndType;
uniform highp mat4 glstate_matrix_mvp;
uniform highp mat4 glstate_matrix_modelview0;
uniform highp mat4 glstate_matrix_invtrans_modelview0;
#line 39
uniform highp mat4 _Object2World;
uniform highp mat4 _World2Object;
uniform highp vec4 unity_Scale;
uniform highp mat4 glstate_matrix_transpose_modelview0;
#line 43
uniform highp mat4 glstate_matrix_texture0;
uniform highp mat4 glstate_matrix_texture1;
uniform highp mat4 glstate_matrix_texture2;
uniform highp mat4 glstate_matrix_texture3;
#line 47
uniform highp mat4 glstate_matrix_projection;
uniform highp vec4 glstate_lightmodel_ambient;
uniform highp mat4 unity_MatrixV;
uniform highp mat4 unity_MatrixVP;
#line 51
uniform lowp vec4 unity_ColorSpaceGrey;
#line 77
#line 82
#line 87
#line 91
#line 96
#line 120
#line 137
#line 158
#line 166
#line 193
#line 206
#line 215
#line 220
#line 229
#line 234
#line 243
#line 260
#line 265
#line 291
#line 299
#line 307
#line 311
#line 315
uniform sampler2D _LightTexture0;
uniform highp mat4 _LightMatrix0;
#line 335
uniform lowp vec4 _Color;
uniform lowp vec4 _LightColor0;
#line 348
#line 348
lowp vec4 frag( in v2f IN ) {
    IN.lightDir = normalize(IN.lightDir);
    lowp float atten = (texture( _LightTexture0, IN._LightCoord).w * 1.0);
    #line 352
    lowp vec3 normal = IN.normal;
    lowp float diff = xll_saturate_f(dot( normal, IN.lightDir));
    lowp vec4 c;
    c.xyz = (((IN.color.xyz * _LightColor0.xyz) * diff) * (atten * 2.0));
    #line 356
    c.w = IN.color.w;
    return c;
}
in highp vec2 xlv_TEXCOORD0;
in highp vec3 xlv_TEXCOORD2;
in highp vec3 xlv_TEXCOORD1;
in highp vec2 xlv_TEXCOORD3;
in highp vec4 xlv_TEXCOORD5;
void main() {
    lowp vec4 xl_retval;
    v2f xlt_IN;
    xlt_IN.pos = vec4(0.0);
    xlt_IN.uv = vec2(xlv_TEXCOORD0);
    xlt_IN.lightDir = vec3(xlv_TEXCOORD2);
    xlt_IN.normal = vec3(xlv_TEXCOORD1);
    xlt_IN._LightCoord = vec2(xlv_TEXCOORD3);
    xlt_IN.color = vec4(xlv_TEXCOORD5);
    xl_retval = frag( xlt_IN);
    gl_FragData[0] = vec4(xl_retval);
}


#endif"
}

}
Program "fp" {
// Fragment combos: 5
//   opengl - ALU: 8 to 17, TEX: 0 to 2
//   d3d9 - ALU: 9 to 17, TEX: 1 to 2
//   d3d11 - ALU: 7 to 14, TEX: 0 to 2, FLOW: 1 to 1
//   d3d11_9x - ALU: 7 to 14, TEX: 0 to 2, FLOW: 1 to 1
SubProgram "opengl " {
Keywords { "POINT" }
Vector 0 [_LightColor0]
SetTexture 0 [_LightTexture0] 2D
"!!ARBfp1.0
# 11 ALU, 1 TEX
PARAM c[2] = { program.local[0],
		{ 2 } };
TEMP R0;
TEMP R1;
DP3 R0.x, fragment.texcoord[3], fragment.texcoord[3];
MOV result.color.w, fragment.texcoord[5];
TEX R0.w, R0.x, texture[0], 2D;
DP3 R0.x, fragment.texcoord[2], fragment.texcoord[2];
RSQ R0.x, R0.x;
MUL R1.xyz, R0.x, fragment.texcoord[2];
MUL R0.xyz, fragment.texcoord[5], c[0];
DP3_SAT R1.x, fragment.texcoord[1], R1;
MUL R0.w, R0, c[1].x;
MUL R0.xyz, R0, R1.x;
MUL result.color.xyz, R0, R0.w;
END
# 11 instructions, 2 R-regs
"
}

SubProgram "d3d9 " {
Keywords { "POINT" }
Vector 0 [_LightColor0]
SetTexture 0 [_LightTexture0] 2D
"ps_2_0
; 12 ALU, 1 TEX
dcl_2d s0
def c1, 2.00000000, 0, 0, 0
dcl t2.xyz
dcl t1.xyz
dcl t3.xyz
dcl t5
dp3 r0.x, t3, t3
mov r0.xy, r0.x
dp3 r1.x, t2, t2
rsq r1.x, r1.x
mul r1.xyz, r1.x, t2
dp3_pp_sat r1.x, t1, r1
mul r2.xyz, t5, c0
mul r1.xyz, r2, r1.x
texld r0, r0, s0
mul_pp r0.x, r0, c1
mul r0.xyz, r1, r0.x
mov_pp r0.w, t5
mov_pp oC0, r0
"
}

SubProgram "d3d11 " {
Keywords { "POINT" }
ConstBuffer "$Globals" 112 // 112 used size, 4 vars
Vector 96 [_LightColor0] 4
BindCB "$Globals" 0
SetTexture 0 [_LightTexture0] 2D 0
// 12 instructions, 2 temp regs, 0 temp arrays:
// ALU 9 float, 0 int, 0 uint
// TEX 1 (0 load, 0 comp, 0 bias, 0 grad)
// FLOW 1 static, 0 dynamic
"ps_4_0
eefiecedbioionpndiclbpbkjhaodjppefcaogpfabaaaaaammacaaaaadaaaaaa
cmaaaaaaoeaaaaaabiabaaaaejfdeheolaaaaaaaagaaaaaaaiaaaaaajiaaaaaa
aaaaaaaaabaaaaaaadaaaaaaaaaaaaaaapaaaaaakeaaaaaaaaaaaaaaaaaaaaaa
adaaaaaaabaaaaaaadaaaaaakeaaaaaaacaaaaaaaaaaaaaaadaaaaaaacaaaaaa
ahahaaaakeaaaaaaabaaaaaaaaaaaaaaadaaaaaaadaaaaaaahahaaaakeaaaaaa
adaaaaaaaaaaaaaaadaaaaaaaeaaaaaaahahaaaakeaaaaaaafaaaaaaaaaaaaaa
adaaaaaaafaaaaaaapapaaaafdfgfpfaepfdejfeejepeoaafeeffiedepepfcee
aaklklklepfdeheocmaaaaaaabaaaaaaaiaaaaaacaaaaaaaaaaaaaaaaaaaaaaa
adaaaaaaaaaaaaaaapaaaaaafdfgfpfegbhcghgfheaaklklfdeieefckmabaaaa
eaaaaaaaglaaaaaafjaaaaaeegiocaaaaaaaaaaaahaaaaaafkaaaaadaagabaaa
aaaaaaaafibiaaaeaahabaaaaaaaaaaaffffaaaagcbaaaadhcbabaaaacaaaaaa
gcbaaaadhcbabaaaadaaaaaagcbaaaadhcbabaaaaeaaaaaagcbaaaadpcbabaaa
afaaaaaagfaaaaadpccabaaaaaaaaaaagiaaaaacacaaaaaabaaaaaahbcaabaaa
aaaaaaaaegbcbaaaacaaaaaaegbcbaaaacaaaaaaeeaaaaafbcaabaaaaaaaaaaa
akaabaaaaaaaaaaadiaaaaahhcaabaaaaaaaaaaaagaabaaaaaaaaaaaegbcbaaa
acaaaaaabacaaaahbcaabaaaaaaaaaaaegbcbaaaadaaaaaaegacbaaaaaaaaaaa
diaaaaaiocaabaaaaaaaaaaaagbjbaaaafaaaaaaagijcaaaaaaaaaaaagaaaaaa
diaaaaahhcaabaaaaaaaaaaaagaabaaaaaaaaaaajgahbaaaaaaaaaaabaaaaaah
icaabaaaaaaaaaaaegbcbaaaaeaaaaaaegbcbaaaaeaaaaaaefaaaaajpcaabaaa
abaaaaaapgapbaaaaaaaaaaaeghobaaaaaaaaaaaaagabaaaaaaaaaaaaaaaaaah
icaabaaaaaaaaaaaakaabaaaabaaaaaaakaabaaaabaaaaaadiaaaaahhccabaaa
aaaaaaaapgapbaaaaaaaaaaaegacbaaaaaaaaaaadgaaaaaficcabaaaaaaaaaaa
dkbabaaaafaaaaaadoaaaaab"
}

SubProgram "gles " {
Keywords { "POINT" }
"!!GLES"
}

SubProgram "glesdesktop " {
Keywords { "POINT" }
"!!GLES"
}

SubProgram "flash " {
Keywords { "POINT" }
Vector 0 [_LightColor0]
SetTexture 0 [_LightTexture0] 2D
"agal_ps
c1 2.0 0.0 0.0 0.0
[bc]
bcaaaaaaaaaaabacadaaaaoeaeaaaaaaadaaaaoeaeaaaaaa dp3 r0.x, v3, v3
aaaaaaaaaaaaadacaaaaaaaaacaaaaaaaaaaaaaaaaaaaaaa mov r0.xy, r0.x
adaaaaaaacaaahacafaaaaoeaeaaaaaaaaaaaaoeabaaaaaa mul r2.xyz, v5, c0
ciaaaaaaaaaaapacaaaaaafeacaaaaaaaaaaaaaaafaababb tex r0, r0.xyyy, s0 <2d wrap linear point>
bcaaaaaaaaaaabacacaaaaoeaeaaaaaaacaaaaoeaeaaaaaa dp3 r0.x, v2, v2
akaaaaaaaaaaabacaaaaaaaaacaaaaaaaaaaaaaaaaaaaaaa rsq r0.x, r0.x
adaaaaaaabaaahacaaaaaaaaacaaaaaaacaaaaoeaeaaaaaa mul r1.xyz, r0.x, v2
adaaaaaaaaaaabacaaaaaappacaaaaaaabaaaaoeabaaaaaa mul r0.x, r0.w, c1
bcaaaaaaabaaabacabaaaaoeaeaaaaaaabaaaakeacaaaaaa dp3 r1.x, v1, r1.xyzz
bgaaaaaaabaaabacabaaaaaaacaaaaaaaaaaaaaaaaaaaaaa sat r1.x, r1.x
adaaaaaaabaaahacacaaaakeacaaaaaaabaaaaaaacaaaaaa mul r1.xyz, r2.xyzz, r1.x
adaaaaaaaaaaahacabaaaakeacaaaaaaaaaaaaaaacaaaaaa mul r0.xyz, r1.xyzz, r0.x
aaaaaaaaaaaaaiacafaaaaoeaeaaaaaaaaaaaaaaaaaaaaaa mov r0.w, v5
aaaaaaaaaaaaapadaaaaaaoeacaaaaaaaaaaaaaaaaaaaaaa mov o0, r0
"
}

SubProgram "d3d11_9x " {
Keywords { "POINT" }
ConstBuffer "$Globals" 112 // 112 used size, 4 vars
Vector 96 [_LightColor0] 4
BindCB "$Globals" 0
SetTexture 0 [_LightTexture0] 2D 0
// 12 instructions, 2 temp regs, 0 temp arrays:
// ALU 9 float, 0 int, 0 uint
// TEX 1 (0 load, 0 comp, 0 bias, 0 grad)
// FLOW 1 static, 0 dynamic
"ps_4_0_level_9_1
eefiecedalemgnichmemlepajpfbeadidmiehekdabaaaaaapaadaaaaaeaaaaaa
daaaaaaafaabaaaaaeadaaaalmadaaaaebgpgodjbiabaaaabiabaaaaaaacpppp
oeaaaaaadeaaaaaaabaaciaaaaaadeaaaaaadeaaabaaceaaaaaadeaaaaaaaaaa
aaaaagaaabaaaaaaaaaaaaaaaaacppppbpaaaaacaaaaaaiaabaaahlabpaaaaac
aaaaaaiaacaachlabpaaaaacaaaaaaiaadaaahlabpaaaaacaaaaaaiaaeaacpla
bpaaaaacaaaaaajaaaaiapkaceaaaaacaaaaahiaabaaoelaaiaaaaadaaaadbia
acaaoelaaaaaoeiaafaaaaadaaaaaoiaaeaabllaaaaablkaafaaaaadaaaaahia
aaaaaaiaaaaabliaaiaaaaadaaaaaiiaadaaoelaadaaoelaabaaaaacabaaadia
aaaappiaecaaaaadabaacpiaabaaoeiaaaaioekaacaaaaadaaaaaiiaabaaaaia
abaaaaiaafaaaaadaaaachiaaaaappiaaaaaoeiaabaaaaacaaaaciiaaeaappla
abaaaaacaaaicpiaaaaaoeiappppaaaafdeieefckmabaaaaeaaaaaaaglaaaaaa
fjaaaaaeegiocaaaaaaaaaaaahaaaaaafkaaaaadaagabaaaaaaaaaaafibiaaae
aahabaaaaaaaaaaaffffaaaagcbaaaadhcbabaaaacaaaaaagcbaaaadhcbabaaa
adaaaaaagcbaaaadhcbabaaaaeaaaaaagcbaaaadpcbabaaaafaaaaaagfaaaaad
pccabaaaaaaaaaaagiaaaaacacaaaaaabaaaaaahbcaabaaaaaaaaaaaegbcbaaa
acaaaaaaegbcbaaaacaaaaaaeeaaaaafbcaabaaaaaaaaaaaakaabaaaaaaaaaaa
diaaaaahhcaabaaaaaaaaaaaagaabaaaaaaaaaaaegbcbaaaacaaaaaabacaaaah
bcaabaaaaaaaaaaaegbcbaaaadaaaaaaegacbaaaaaaaaaaadiaaaaaiocaabaaa
aaaaaaaaagbjbaaaafaaaaaaagijcaaaaaaaaaaaagaaaaaadiaaaaahhcaabaaa
aaaaaaaaagaabaaaaaaaaaaajgahbaaaaaaaaaaabaaaaaahicaabaaaaaaaaaaa
egbcbaaaaeaaaaaaegbcbaaaaeaaaaaaefaaaaajpcaabaaaabaaaaaapgapbaaa
aaaaaaaaeghobaaaaaaaaaaaaagabaaaaaaaaaaaaaaaaaahicaabaaaaaaaaaaa
akaabaaaabaaaaaaakaabaaaabaaaaaadiaaaaahhccabaaaaaaaaaaapgapbaaa
aaaaaaaaegacbaaaaaaaaaaadgaaaaaficcabaaaaaaaaaaadkbabaaaafaaaaaa
doaaaaabejfdeheolaaaaaaaagaaaaaaaiaaaaaajiaaaaaaaaaaaaaaabaaaaaa
adaaaaaaaaaaaaaaapaaaaaakeaaaaaaaaaaaaaaaaaaaaaaadaaaaaaabaaaaaa
adaaaaaakeaaaaaaacaaaaaaaaaaaaaaadaaaaaaacaaaaaaahahaaaakeaaaaaa
abaaaaaaaaaaaaaaadaaaaaaadaaaaaaahahaaaakeaaaaaaadaaaaaaaaaaaaaa
adaaaaaaaeaaaaaaahahaaaakeaaaaaaafaaaaaaaaaaaaaaadaaaaaaafaaaaaa
apapaaaafdfgfpfaepfdejfeejepeoaafeeffiedepepfceeaaklklklepfdeheo
cmaaaaaaabaaaaaaaiaaaaaacaaaaaaaaaaaaaaaaaaaaaaaadaaaaaaaaaaaaaa
apaaaaaafdfgfpfegbhcghgfheaaklkl"
}

SubProgram "gles3 " {
Keywords { "POINT" }
"!!GLES3"
}

SubProgram "opengl " {
Keywords { "DIRECTIONAL" }
Vector 0 [_LightColor0]
"!!ARBfp1.0
# 8 ALU, 0 TEX
PARAM c[2] = { program.local[0],
		{ 2 } };
TEMP R0;
DP3 R0.x, fragment.texcoord[2], fragment.texcoord[2];
RSQ R0.x, R0.x;
MUL R0.xyz, R0.x, fragment.texcoord[2];
DP3_SAT R0.w, fragment.texcoord[1], R0;
MUL R0.xyz, fragment.texcoord[5], c[0];
MUL R0.xyz, R0, R0.w;
MUL result.color.xyz, R0, c[1].x;
MOV result.color.w, fragment.texcoord[5];
END
# 8 instructions, 1 R-regs
"
}

SubProgram "d3d9 " {
Keywords { "DIRECTIONAL" }
Vector 0 [_LightColor0]
"ps_2_0
; 9 ALU
def c1, 2.00000000, 0, 0, 0
dcl t2.xyz
dcl t1.xyz
dcl t5
dp3 r0.x, t2, t2
rsq r0.x, r0.x
mul r0.xyz, r0.x, t2
dp3_pp_sat r0.x, t1, r0
mul r1.xyz, t5, c0
mul r0.xyz, r1, r0.x
mul r0.xyz, r0, c1.x
mov_pp r0.w, t5
mov_pp oC0, r0
"
}

SubProgram "d3d11 " {
Keywords { "DIRECTIONAL" }
ConstBuffer "$Globals" 48 // 48 used size, 3 vars
Vector 32 [_LightColor0] 4
BindCB "$Globals" 0
// 9 instructions, 1 temp regs, 0 temp arrays:
// ALU 7 float, 0 int, 0 uint
// TEX 0 (0 load, 0 comp, 0 bias, 0 grad)
// FLOW 1 static, 0 dynamic
"ps_4_0
eefiecedloieipnbkbffnjnmagdbeekmebefinkdabaaaaaadaacaaaaadaaaaaa
cmaaaaaammaaaaaaaaabaaaaejfdeheojiaaaaaaafaaaaaaaiaaaaaaiaaaaaaa
aaaaaaaaabaaaaaaadaaaaaaaaaaaaaaapaaaaaaimaaaaaaaaaaaaaaaaaaaaaa
adaaaaaaabaaaaaaadaaaaaaimaaaaaaacaaaaaaaaaaaaaaadaaaaaaacaaaaaa
ahahaaaaimaaaaaaabaaaaaaaaaaaaaaadaaaaaaadaaaaaaahahaaaaimaaaaaa
afaaaaaaaaaaaaaaadaaaaaaaeaaaaaaapapaaaafdfgfpfaepfdejfeejepeoaa
feeffiedepepfceeaaklklklepfdeheocmaaaaaaabaaaaaaaiaaaaaacaaaaaaa
aaaaaaaaaaaaaaaaadaaaaaaaaaaaaaaapaaaaaafdfgfpfegbhcghgfheaaklkl
fdeieefcciabaaaaeaaaaaaaekaaaaaafjaaaaaeegiocaaaaaaaaaaaadaaaaaa
gcbaaaadhcbabaaaacaaaaaagcbaaaadhcbabaaaadaaaaaagcbaaaadpcbabaaa
aeaaaaaagfaaaaadpccabaaaaaaaaaaagiaaaaacabaaaaaabaaaaaahbcaabaaa
aaaaaaaaegbcbaaaacaaaaaaegbcbaaaacaaaaaaeeaaaaafbcaabaaaaaaaaaaa
akaabaaaaaaaaaaadiaaaaahhcaabaaaaaaaaaaaagaabaaaaaaaaaaaegbcbaaa
acaaaaaabacaaaahbcaabaaaaaaaaaaaegbcbaaaadaaaaaaegacbaaaaaaaaaaa
diaaaaaiocaabaaaaaaaaaaaagbjbaaaaeaaaaaaagijcaaaaaaaaaaaacaaaaaa
diaaaaahhcaabaaaaaaaaaaaagaabaaaaaaaaaaajgahbaaaaaaaaaaaaaaaaaah
hccabaaaaaaaaaaaegacbaaaaaaaaaaaegacbaaaaaaaaaaadgaaaaaficcabaaa
aaaaaaaadkbabaaaaeaaaaaadoaaaaab"
}

SubProgram "gles " {
Keywords { "DIRECTIONAL" }
"!!GLES"
}

SubProgram "glesdesktop " {
Keywords { "DIRECTIONAL" }
"!!GLES"
}

SubProgram "flash " {
Keywords { "DIRECTIONAL" }
Vector 0 [_LightColor0]
"agal_ps
c1 2.0 0.0 0.0 0.0
[bc]
bcaaaaaaaaaaabacacaaaaoeaeaaaaaaacaaaaoeaeaaaaaa dp3 r0.x, v2, v2
akaaaaaaaaaaabacaaaaaaaaacaaaaaaaaaaaaaaaaaaaaaa rsq r0.x, r0.x
adaaaaaaaaaaahacaaaaaaaaacaaaaaaacaaaaoeaeaaaaaa mul r0.xyz, r0.x, v2
bcaaaaaaaaaaabacabaaaaoeaeaaaaaaaaaaaakeacaaaaaa dp3 r0.x, v1, r0.xyzz
bgaaaaaaaaaaabacaaaaaaaaacaaaaaaaaaaaaaaaaaaaaaa sat r0.x, r0.x
adaaaaaaabaaahacafaaaaoeaeaaaaaaaaaaaaoeabaaaaaa mul r1.xyz, v5, c0
adaaaaaaaaaaahacabaaaakeacaaaaaaaaaaaaaaacaaaaaa mul r0.xyz, r1.xyzz, r0.x
adaaaaaaaaaaahacaaaaaakeacaaaaaaabaaaaaaabaaaaaa mul r0.xyz, r0.xyzz, c1.x
aaaaaaaaaaaaaiacafaaaaoeaeaaaaaaaaaaaaaaaaaaaaaa mov r0.w, v5
aaaaaaaaaaaaapadaaaaaaoeacaaaaaaaaaaaaaaaaaaaaaa mov o0, r0
"
}

SubProgram "d3d11_9x " {
Keywords { "DIRECTIONAL" }
ConstBuffer "$Globals" 48 // 48 used size, 3 vars
Vector 32 [_LightColor0] 4
BindCB "$Globals" 0
// 9 instructions, 1 temp regs, 0 temp arrays:
// ALU 7 float, 0 int, 0 uint
// TEX 0 (0 load, 0 comp, 0 bias, 0 grad)
// FLOW 1 static, 0 dynamic
"ps_4_0_level_9_1
eefiecedhmbgndkhekjafmbnlllfoeplpaliaonaabaaaaaapmacaaaaaeaaaaaa
daaaaaaapiaaaaaaciacaaaamiacaaaaebgpgodjmaaaaaaamaaaaaaaaaacpppp
jaaaaaaadaaaaaaaabaaceaaaaaadaaaaaaadaaaaaaaceaaaaaadaaaaaaaacaa
abaaaaaaaaaaaaaaaaacppppbpaaaaacaaaaaaiaabaaahlabpaaaaacaaaaaaia
acaachlabpaaaaacaaaaaaiaadaacplaceaaaaacaaaaahiaabaaoelaaiaaaaad
aaaadbiaacaaoelaaaaaoeiaafaaaaadaaaaaoiaadaabllaaaaablkaafaaaaad
aaaaahiaaaaaaaiaaaaabliaacaaaaadaaaachiaaaaaoeiaaaaaoeiaabaaaaac
aaaaciiaadaapplaabaaaaacaaaicpiaaaaaoeiappppaaaafdeieefcciabaaaa
eaaaaaaaekaaaaaafjaaaaaeegiocaaaaaaaaaaaadaaaaaagcbaaaadhcbabaaa
acaaaaaagcbaaaadhcbabaaaadaaaaaagcbaaaadpcbabaaaaeaaaaaagfaaaaad
pccabaaaaaaaaaaagiaaaaacabaaaaaabaaaaaahbcaabaaaaaaaaaaaegbcbaaa
acaaaaaaegbcbaaaacaaaaaaeeaaaaafbcaabaaaaaaaaaaaakaabaaaaaaaaaaa
diaaaaahhcaabaaaaaaaaaaaagaabaaaaaaaaaaaegbcbaaaacaaaaaabacaaaah
bcaabaaaaaaaaaaaegbcbaaaadaaaaaaegacbaaaaaaaaaaadiaaaaaiocaabaaa
aaaaaaaaagbjbaaaaeaaaaaaagijcaaaaaaaaaaaacaaaaaadiaaaaahhcaabaaa
aaaaaaaaagaabaaaaaaaaaaajgahbaaaaaaaaaaaaaaaaaahhccabaaaaaaaaaaa
egacbaaaaaaaaaaaegacbaaaaaaaaaaadgaaaaaficcabaaaaaaaaaaadkbabaaa
aeaaaaaadoaaaaabejfdeheojiaaaaaaafaaaaaaaiaaaaaaiaaaaaaaaaaaaaaa
abaaaaaaadaaaaaaaaaaaaaaapaaaaaaimaaaaaaaaaaaaaaaaaaaaaaadaaaaaa
abaaaaaaadaaaaaaimaaaaaaacaaaaaaaaaaaaaaadaaaaaaacaaaaaaahahaaaa
imaaaaaaabaaaaaaaaaaaaaaadaaaaaaadaaaaaaahahaaaaimaaaaaaafaaaaaa
aaaaaaaaadaaaaaaaeaaaaaaapapaaaafdfgfpfaepfdejfeejepeoaafeeffied
epepfceeaaklklklepfdeheocmaaaaaaabaaaaaaaiaaaaaacaaaaaaaaaaaaaaa
aaaaaaaaadaaaaaaaaaaaaaaapaaaaaafdfgfpfegbhcghgfheaaklkl"
}

SubProgram "gles3 " {
Keywords { "DIRECTIONAL" }
"!!GLES3"
}

SubProgram "opengl " {
Keywords { "SPOT" }
Vector 0 [_LightColor0]
SetTexture 0 [_LightTexture0] 2D
SetTexture 1 [_LightTextureB0] 2D
"!!ARBfp1.0
# 17 ALU, 2 TEX
PARAM c[2] = { program.local[0],
		{ 0, 0.5, 2 } };
TEMP R0;
TEMP R1;
TEMP R2;
DP3 R0.z, fragment.texcoord[3], fragment.texcoord[3];
RCP R0.x, fragment.texcoord[3].w;
MAD R0.xy, fragment.texcoord[3], R0.x, c[1].y;
SLT R2.x, c[1], fragment.texcoord[3].z;
MOV result.color.w, fragment.texcoord[5];
TEX R0.w, R0, texture[0], 2D;
TEX R1.w, R0.z, texture[1], 2D;
DP3 R0.x, fragment.texcoord[2], fragment.texcoord[2];
RSQ R1.x, R0.x;
MUL R0.w, R2.x, R0;
MUL R1.xyz, R1.x, fragment.texcoord[2];
MUL R1.w, R0, R1;
DP3_SAT R0.w, fragment.texcoord[1], R1;
MUL R0.xyz, fragment.texcoord[5], c[0];
MUL R1.x, R1.w, c[1].z;
MUL R0.xyz, R0, R0.w;
MUL result.color.xyz, R0, R1.x;
END
# 17 instructions, 3 R-regs
"
}

SubProgram "d3d9 " {
Keywords { "SPOT" }
Vector 0 [_LightColor0]
SetTexture 0 [_LightTexture0] 2D
SetTexture 1 [_LightTextureB0] 2D
"ps_2_0
; 17 ALU, 2 TEX
dcl_2d s0
dcl_2d s1
def c1, 0.50000000, 0.00000000, 1.00000000, 2.00000000
dcl t2.xyz
dcl t1.xyz
dcl t3
dcl t5
rcp r1.x, t3.w
mad r2.xy, t3, r1.x, c1.x
dp3 r0.x, t3, t3
mov r1.xy, r0.x
texld r0, r2, s0
texld r2, r1, s1
cmp r0.x, -t3.z, c1.y, c1.z
mul_pp r0.x, r0, r0.w
mul_pp r0.x, r0, r2
dp3 r1.x, t2, t2
rsq r1.x, r1.x
mul r1.xyz, r1.x, t2
mul_pp r0.x, r0, c1.w
dp3_pp_sat r1.x, t1, r1
mul r2.xyz, t5, c0
mul r1.xyz, r2, r1.x
mul r0.xyz, r1, r0.x
mov_pp r0.w, t5
mov_pp oC0, r0
"
}

SubProgram "d3d11 " {
Keywords { "SPOT" }
ConstBuffer "$Globals" 112 // 112 used size, 4 vars
Vector 96 [_LightColor0] 4
BindCB "$Globals" 0
SetTexture 0 [_LightTexture0] 2D 0
SetTexture 1 [_LightTextureB0] 2D 1
// 18 instructions, 2 temp regs, 0 temp arrays:
// ALU 13 float, 0 int, 1 uint
// TEX 2 (0 load, 0 comp, 0 bias, 0 grad)
// FLOW 1 static, 0 dynamic
"ps_4_0
eefiecednbeijpebpeecdfmohlgldkeeefgcibieabaaaaaakeadaaaaadaaaaaa
cmaaaaaaoeaaaaaabiabaaaaejfdeheolaaaaaaaagaaaaaaaiaaaaaajiaaaaaa
aaaaaaaaabaaaaaaadaaaaaaaaaaaaaaapaaaaaakeaaaaaaaaaaaaaaaaaaaaaa
adaaaaaaabaaaaaaadaaaaaakeaaaaaaacaaaaaaaaaaaaaaadaaaaaaacaaaaaa
ahahaaaakeaaaaaaabaaaaaaaaaaaaaaadaaaaaaadaaaaaaahahaaaakeaaaaaa
adaaaaaaaaaaaaaaadaaaaaaaeaaaaaaapapaaaakeaaaaaaafaaaaaaaaaaaaaa
adaaaaaaafaaaaaaapapaaaafdfgfpfaepfdejfeejepeoaafeeffiedepepfcee
aaklklklepfdeheocmaaaaaaabaaaaaaaiaaaaaacaaaaaaaaaaaaaaaaaaaaaaa
adaaaaaaaaaaaaaaapaaaaaafdfgfpfegbhcghgfheaaklklfdeieefcieacaaaa
eaaaaaaakbaaaaaafjaaaaaeegiocaaaaaaaaaaaahaaaaaafkaaaaadaagabaaa
aaaaaaaafkaaaaadaagabaaaabaaaaaafibiaaaeaahabaaaaaaaaaaaffffaaaa
fibiaaaeaahabaaaabaaaaaaffffaaaagcbaaaadhcbabaaaacaaaaaagcbaaaad
hcbabaaaadaaaaaagcbaaaadpcbabaaaaeaaaaaagcbaaaadpcbabaaaafaaaaaa
gfaaaaadpccabaaaaaaaaaaagiaaaaacacaaaaaaaoaaaaahdcaabaaaaaaaaaaa
egbabaaaaeaaaaaapgbpbaaaaeaaaaaaaaaaaaakdcaabaaaaaaaaaaaegaabaaa
aaaaaaaaaceaaaaaaaaaaadpaaaaaadpaaaaaaaaaaaaaaaaefaaaaajpcaabaaa
aaaaaaaaegaabaaaaaaaaaaaeghobaaaaaaaaaaaaagabaaaaaaaaaaadbaaaaah
bcaabaaaaaaaaaaaabeaaaaaaaaaaaaackbabaaaaeaaaaaaabaaaaahbcaabaaa
aaaaaaaaakaabaaaaaaaaaaaabeaaaaaaaaaiadpdiaaaaahbcaabaaaaaaaaaaa
dkaabaaaaaaaaaaaakaabaaaaaaaaaaabaaaaaahccaabaaaaaaaaaaaegbcbaaa
aeaaaaaaegbcbaaaaeaaaaaaefaaaaajpcaabaaaabaaaaaafgafbaaaaaaaaaaa
eghobaaaabaaaaaaaagabaaaabaaaaaaapaaaaahbcaabaaaaaaaaaaaagaabaaa
aaaaaaaaagaabaaaabaaaaaabaaaaaahccaabaaaaaaaaaaaegbcbaaaacaaaaaa
egbcbaaaacaaaaaaeeaaaaafccaabaaaaaaaaaaabkaabaaaaaaaaaaadiaaaaah
ocaabaaaaaaaaaaafgafbaaaaaaaaaaaagbjbaaaacaaaaaabacaaaahccaabaaa
aaaaaaaaegbcbaaaadaaaaaajgahbaaaaaaaaaaadiaaaaaihcaabaaaabaaaaaa
egbcbaaaafaaaaaaegiccaaaaaaaaaaaagaaaaaadiaaaaahocaabaaaaaaaaaaa
fgafbaaaaaaaaaaaagajbaaaabaaaaaadiaaaaahhccabaaaaaaaaaaaagaabaaa
aaaaaaaajgahbaaaaaaaaaaadgaaaaaficcabaaaaaaaaaaadkbabaaaafaaaaaa
doaaaaab"
}

SubProgram "gles " {
Keywords { "SPOT" }
"!!GLES"
}

SubProgram "glesdesktop " {
Keywords { "SPOT" }
"!!GLES"
}

SubProgram "flash " {
Keywords { "SPOT" }
Vector 0 [_LightColor0]
SetTexture 0 [_LightTexture0] 2D
SetTexture 1 [_LightTextureB0] 2D
"agal_ps
c1 0.5 0.0 1.0 2.0
[bc]
afaaaaaaabaaabacadaaaappaeaaaaaaaaaaaaaaaaaaaaaa rcp r1.x, v3.w
bcaaaaaaaaaaabacadaaaaoeaeaaaaaaadaaaaoeaeaaaaaa dp3 r0.x, v3, v3
adaaaaaaabaaadacadaaaaoeaeaaaaaaabaaaaaaacaaaaaa mul r1.xy, v3, r1.x
abaaaaaaabaaadacabaaaafeacaaaaaaabaaaaaaabaaaaaa add r1.xy, r1.xyyy, c1.x
aaaaaaaaaaaaadacaaaaaaaaacaaaaaaaaaaaaaaaaaaaaaa mov r0.xy, r0.x
adaaaaaaacaaahacafaaaaoeaeaaaaaaaaaaaaoeabaaaaaa mul r2.xyz, v5, c0
ciaaaaaaabaaapacabaaaafeacaaaaaaaaaaaaaaafaababb tex r1, r1.xyyy, s0 <2d wrap linear point>
ciaaaaaaaaaaapacaaaaaafeacaaaaaaabaaaaaaafaababb tex r0, r0.xyyy, s1 <2d wrap linear point>
bfaaaaaaacaaaiacadaaaakkaeaaaaaaaaaaaaaaaaaaaaaa neg r2.w, v3.z
ckaaaaaaaaaaabacacaaaappacaaaaaaabaaaaffabaaaaaa slt r0.x, r2.w, c1.y
adaaaaaaaaaaabacaaaaaaaaacaaaaaaabaaaappacaaaaaa mul r0.x, r0.x, r1.w
adaaaaaaaaaaabacaaaaaaaaacaaaaaaaaaaaappacaaaaaa mul r0.x, r0.x, r0.w
bcaaaaaaabaaabacacaaaaoeaeaaaaaaacaaaaoeaeaaaaaa dp3 r1.x, v2, v2
akaaaaaaabaaabacabaaaaaaacaaaaaaaaaaaaaaaaaaaaaa rsq r1.x, r1.x
adaaaaaaabaaahacabaaaaaaacaaaaaaacaaaaoeaeaaaaaa mul r1.xyz, r1.x, v2
bcaaaaaaabaaabacabaaaaoeaeaaaaaaabaaaakeacaaaaaa dp3 r1.x, v1, r1.xyzz
bgaaaaaaabaaabacabaaaaaaacaaaaaaaaaaaaaaaaaaaaaa sat r1.x, r1.x
adaaaaaaaaaaabacaaaaaaaaacaaaaaaabaaaappabaaaaaa mul r0.x, r0.x, c1.w
adaaaaaaabaaahacacaaaakeacaaaaaaabaaaaaaacaaaaaa mul r1.xyz, r2.xyzz, r1.x
adaaaaaaaaaaahacabaaaakeacaaaaaaaaaaaaaaacaaaaaa mul r0.xyz, r1.xyzz, r0.x
aaaaaaaaaaaaaiacafaaaaoeaeaaaaaaaaaaaaaaaaaaaaaa mov r0.w, v5
aaaaaaaaaaaaapadaaaaaaoeacaaaaaaaaaaaaaaaaaaaaaa mov o0, r0
"
}

SubProgram "d3d11_9x " {
Keywords { "SPOT" }
ConstBuffer "$Globals" 112 // 112 used size, 4 vars
Vector 96 [_LightColor0] 4
BindCB "$Globals" 0
SetTexture 0 [_LightTexture0] 2D 0
SetTexture 1 [_LightTextureB0] 2D 1
// 18 instructions, 2 temp regs, 0 temp arrays:
// ALU 13 float, 0 int, 1 uint
// TEX 2 (0 load, 0 comp, 0 bias, 0 grad)
// FLOW 1 static, 0 dynamic
"ps_4_0_level_9_1
eefiecediebbibeaffknnoffjkdbkppjakhalgobabaaaaaaeeafaaaaaeaaaaaa
daaaaaaammabaaaafiaeaaaabaafaaaaebgpgodjjeabaaaajeabaaaaaaacpppp
fmabaaaadiaaaaaaabaacmaaaaaadiaaaaaadiaaacaaceaaaaaadiaaaaaaaaaa
abababaaaaaaagaaabaaaaaaaaaaaaaaaaacppppfbaaaaafabaaapkaaaaaaadp
aaaaaaaaaaaaaaaaaaaaaaaabpaaaaacaaaaaaiaabaaahlabpaaaaacaaaaaaia
acaachlabpaaaaacaaaaaaiaadaaaplabpaaaaacaaaaaaiaaeaacplabpaaaaac
aaaaaajaaaaiapkabpaaaaacaaaaaajaabaiapkaagaaaaacaaaaaiiaadaappla
aeaaaaaeaaaaadiaadaaoelaaaaappiaabaaaakaaiaaaaadabaaaiiaadaaoela
adaaoelaabaaaaacabaaadiaabaappiaecaaaaadaaaacpiaaaaaoeiaaaaioeka
ecaaaaadabaacpiaabaaoeiaabaioekaafaaaaadaaaacbiaaaaappiaabaaaaia
fiaaaaaeaaaacbiaadaakklbabaaffkaaaaaaaiaacaaaaadaaaaabiaaaaaaaia
aaaaaaiaceaaaaacabaaahiaabaaoelaaiaaaaadaaaadciaacaaoelaabaaoeia
afaaaaadabaaahiaaeaaoelaaaaaoekaafaaaaadaaaaaoiaaaaaffiaabaablia
afaaaaadaaaachiaaaaaaaiaaaaabliaabaaaaacaaaaciiaaeaapplaabaaaaac
aaaicpiaaaaaoeiappppaaaafdeieefcieacaaaaeaaaaaaakbaaaaaafjaaaaae
egiocaaaaaaaaaaaahaaaaaafkaaaaadaagabaaaaaaaaaaafkaaaaadaagabaaa
abaaaaaafibiaaaeaahabaaaaaaaaaaaffffaaaafibiaaaeaahabaaaabaaaaaa
ffffaaaagcbaaaadhcbabaaaacaaaaaagcbaaaadhcbabaaaadaaaaaagcbaaaad
pcbabaaaaeaaaaaagcbaaaadpcbabaaaafaaaaaagfaaaaadpccabaaaaaaaaaaa
giaaaaacacaaaaaaaoaaaaahdcaabaaaaaaaaaaaegbabaaaaeaaaaaapgbpbaaa
aeaaaaaaaaaaaaakdcaabaaaaaaaaaaaegaabaaaaaaaaaaaaceaaaaaaaaaaadp
aaaaaadpaaaaaaaaaaaaaaaaefaaaaajpcaabaaaaaaaaaaaegaabaaaaaaaaaaa
eghobaaaaaaaaaaaaagabaaaaaaaaaaadbaaaaahbcaabaaaaaaaaaaaabeaaaaa
aaaaaaaackbabaaaaeaaaaaaabaaaaahbcaabaaaaaaaaaaaakaabaaaaaaaaaaa
abeaaaaaaaaaiadpdiaaaaahbcaabaaaaaaaaaaadkaabaaaaaaaaaaaakaabaaa
aaaaaaaabaaaaaahccaabaaaaaaaaaaaegbcbaaaaeaaaaaaegbcbaaaaeaaaaaa
efaaaaajpcaabaaaabaaaaaafgafbaaaaaaaaaaaeghobaaaabaaaaaaaagabaaa
abaaaaaaapaaaaahbcaabaaaaaaaaaaaagaabaaaaaaaaaaaagaabaaaabaaaaaa
baaaaaahccaabaaaaaaaaaaaegbcbaaaacaaaaaaegbcbaaaacaaaaaaeeaaaaaf
ccaabaaaaaaaaaaabkaabaaaaaaaaaaadiaaaaahocaabaaaaaaaaaaafgafbaaa
aaaaaaaaagbjbaaaacaaaaaabacaaaahccaabaaaaaaaaaaaegbcbaaaadaaaaaa
jgahbaaaaaaaaaaadiaaaaaihcaabaaaabaaaaaaegbcbaaaafaaaaaaegiccaaa
aaaaaaaaagaaaaaadiaaaaahocaabaaaaaaaaaaafgafbaaaaaaaaaaaagajbaaa
abaaaaaadiaaaaahhccabaaaaaaaaaaaagaabaaaaaaaaaaajgahbaaaaaaaaaaa
dgaaaaaficcabaaaaaaaaaaadkbabaaaafaaaaaadoaaaaabejfdeheolaaaaaaa
agaaaaaaaiaaaaaajiaaaaaaaaaaaaaaabaaaaaaadaaaaaaaaaaaaaaapaaaaaa
keaaaaaaaaaaaaaaaaaaaaaaadaaaaaaabaaaaaaadaaaaaakeaaaaaaacaaaaaa
aaaaaaaaadaaaaaaacaaaaaaahahaaaakeaaaaaaabaaaaaaaaaaaaaaadaaaaaa
adaaaaaaahahaaaakeaaaaaaadaaaaaaaaaaaaaaadaaaaaaaeaaaaaaapapaaaa
keaaaaaaafaaaaaaaaaaaaaaadaaaaaaafaaaaaaapapaaaafdfgfpfaepfdejfe
ejepeoaafeeffiedepepfceeaaklklklepfdeheocmaaaaaaabaaaaaaaiaaaaaa
caaaaaaaaaaaaaaaaaaaaaaaadaaaaaaaaaaaaaaapaaaaaafdfgfpfegbhcghgf
heaaklkl"
}

SubProgram "gles3 " {
Keywords { "SPOT" }
"!!GLES3"
}

SubProgram "opengl " {
Keywords { "POINT_COOKIE" }
Vector 0 [_LightColor0]
SetTexture 0 [_LightTextureB0] 2D
SetTexture 1 [_LightTexture0] CUBE
"!!ARBfp1.0
# 13 ALU, 2 TEX
PARAM c[2] = { program.local[0],
		{ 2 } };
TEMP R0;
TEMP R1;
TEX R1.w, fragment.texcoord[3], texture[1], CUBE;
DP3 R0.x, fragment.texcoord[3], fragment.texcoord[3];
MOV result.color.w, fragment.texcoord[5];
TEX R0.w, R0.x, texture[0], 2D;
DP3 R0.x, fragment.texcoord[2], fragment.texcoord[2];
RSQ R1.x, R0.x;
MUL R1.xyz, R1.x, fragment.texcoord[2];
MUL R1.w, R0, R1;
DP3_SAT R0.w, fragment.texcoord[1], R1;
MUL R0.xyz, fragment.texcoord[5], c[0];
MUL R1.x, R1.w, c[1];
MUL R0.xyz, R0, R0.w;
MUL result.color.xyz, R0, R1.x;
END
# 13 instructions, 2 R-regs
"
}

SubProgram "d3d9 " {
Keywords { "POINT_COOKIE" }
Vector 0 [_LightColor0]
SetTexture 0 [_LightTextureB0] 2D
SetTexture 1 [_LightTexture0] CUBE
"ps_2_0
; 13 ALU, 2 TEX
dcl_2d s0
dcl_cube s1
def c1, 2.00000000, 0, 0, 0
dcl t2.xyz
dcl t1.xyz
dcl t3.xyz
dcl t5
dp3 r0.x, t3, t3
mov r0.xy, r0.x
texld r2, r0, s0
texld r0, t3, s1
dp3 r0.x, t2, t2
rsq r1.x, r0.x
mul r1.xyz, r1.x, t2
mul r0.x, r2, r0.w
mul_pp r0.x, r0, c1
dp3_pp_sat r1.x, t1, r1
mul r2.xyz, t5, c0
mul r1.xyz, r2, r1.x
mul r0.xyz, r1, r0.x
mov_pp r0.w, t5
mov_pp oC0, r0
"
}

SubProgram "d3d11 " {
Keywords { "POINT_COOKIE" }
ConstBuffer "$Globals" 112 // 112 used size, 4 vars
Vector 96 [_LightColor0] 4
BindCB "$Globals" 0
SetTexture 0 [_LightTextureB0] 2D 1
SetTexture 1 [_LightTexture0] CUBE 0
// 13 instructions, 3 temp regs, 0 temp arrays:
// ALU 9 float, 0 int, 0 uint
// TEX 2 (0 load, 0 comp, 0 bias, 0 grad)
// FLOW 1 static, 0 dynamic
"ps_4_0
eefiecedmibmaanhegfhgebjgfckekinpiclngbeabaaaaaaamadaaaaadaaaaaa
cmaaaaaaoeaaaaaabiabaaaaejfdeheolaaaaaaaagaaaaaaaiaaaaaajiaaaaaa
aaaaaaaaabaaaaaaadaaaaaaaaaaaaaaapaaaaaakeaaaaaaaaaaaaaaaaaaaaaa
adaaaaaaabaaaaaaadaaaaaakeaaaaaaacaaaaaaaaaaaaaaadaaaaaaacaaaaaa
ahahaaaakeaaaaaaabaaaaaaaaaaaaaaadaaaaaaadaaaaaaahahaaaakeaaaaaa
adaaaaaaaaaaaaaaadaaaaaaaeaaaaaaahahaaaakeaaaaaaafaaaaaaaaaaaaaa
adaaaaaaafaaaaaaapapaaaafdfgfpfaepfdejfeejepeoaafeeffiedepepfcee
aaklklklepfdeheocmaaaaaaabaaaaaaaiaaaaaacaaaaaaaaaaaaaaaaaaaaaaa
adaaaaaaaaaaaaaaapaaaaaafdfgfpfegbhcghgfheaaklklfdeieefcomabaaaa
eaaaaaaahlaaaaaafjaaaaaeegiocaaaaaaaaaaaahaaaaaafkaaaaadaagabaaa
aaaaaaaafkaaaaadaagabaaaabaaaaaafibiaaaeaahabaaaaaaaaaaaffffaaaa
fidaaaaeaahabaaaabaaaaaaffffaaaagcbaaaadhcbabaaaacaaaaaagcbaaaad
hcbabaaaadaaaaaagcbaaaadhcbabaaaaeaaaaaagcbaaaadpcbabaaaafaaaaaa
gfaaaaadpccabaaaaaaaaaaagiaaaaacadaaaaaabaaaaaahbcaabaaaaaaaaaaa
egbcbaaaacaaaaaaegbcbaaaacaaaaaaeeaaaaafbcaabaaaaaaaaaaaakaabaaa
aaaaaaaadiaaaaahhcaabaaaaaaaaaaaagaabaaaaaaaaaaaegbcbaaaacaaaaaa
bacaaaahbcaabaaaaaaaaaaaegbcbaaaadaaaaaaegacbaaaaaaaaaaadiaaaaai
ocaabaaaaaaaaaaaagbjbaaaafaaaaaaagijcaaaaaaaaaaaagaaaaaadiaaaaah
hcaabaaaaaaaaaaaagaabaaaaaaaaaaajgahbaaaaaaaaaaabaaaaaahicaabaaa
aaaaaaaaegbcbaaaaeaaaaaaegbcbaaaaeaaaaaaefaaaaajpcaabaaaabaaaaaa
pgapbaaaaaaaaaaaeghobaaaaaaaaaaaaagabaaaabaaaaaaefaaaaajpcaabaaa
acaaaaaaegbcbaaaaeaaaaaaeghobaaaabaaaaaaaagabaaaaaaaaaaaapaaaaah
icaabaaaaaaaaaaaagaabaaaabaaaaaapgapbaaaacaaaaaadiaaaaahhccabaaa
aaaaaaaapgapbaaaaaaaaaaaegacbaaaaaaaaaaadgaaaaaficcabaaaaaaaaaaa
dkbabaaaafaaaaaadoaaaaab"
}

SubProgram "gles " {
Keywords { "POINT_COOKIE" }
"!!GLES"
}

SubProgram "glesdesktop " {
Keywords { "POINT_COOKIE" }
"!!GLES"
}

SubProgram "flash " {
Keywords { "POINT_COOKIE" }
Vector 0 [_LightColor0]
SetTexture 0 [_LightTextureB0] 2D
SetTexture 1 [_LightTexture0] CUBE
"agal_ps
c1 2.0 0.0 0.0 0.0
[bc]
bcaaaaaaaaaaabacadaaaaoeaeaaaaaaadaaaaoeaeaaaaaa dp3 r0.x, v3, v3
aaaaaaaaaaaaadacaaaaaaaaacaaaaaaaaaaaaaaaaaaaaaa mov r0.xy, r0.x
adaaaaaaacaaahacafaaaaoeaeaaaaaaaaaaaaoeabaaaaaa mul r2.xyz, v5, c0
ciaaaaaaabaaapacaaaaaafeacaaaaaaaaaaaaaaafaababb tex r1, r0.xyyy, s0 <2d wrap linear point>
ciaaaaaaaaaaapacadaaaaoeaeaaaaaaabaaaaaaafbababb tex r0, v3, s1 <cube wrap linear point>
bcaaaaaaaaaaabacacaaaaoeaeaaaaaaacaaaaoeaeaaaaaa dp3 r0.x, v2, v2
akaaaaaaabaaabacaaaaaaaaacaaaaaaaaaaaaaaaaaaaaaa rsq r1.x, r0.x
adaaaaaaaaaaabacabaaaappacaaaaaaaaaaaappacaaaaaa mul r0.x, r1.w, r0.w
adaaaaaaabaaahacabaaaaaaacaaaaaaacaaaaoeaeaaaaaa mul r1.xyz, r1.x, v2
bcaaaaaaabaaabacabaaaaoeaeaaaaaaabaaaakeacaaaaaa dp3 r1.x, v1, r1.xyzz
bgaaaaaaabaaabacabaaaaaaacaaaaaaaaaaaaaaaaaaaaaa sat r1.x, r1.x
adaaaaaaaaaaabacaaaaaaaaacaaaaaaabaaaaoeabaaaaaa mul r0.x, r0.x, c1
adaaaaaaabaaahacacaaaakeacaaaaaaabaaaaaaacaaaaaa mul r1.xyz, r2.xyzz, r1.x
adaaaaaaaaaaahacabaaaakeacaaaaaaaaaaaaaaacaaaaaa mul r0.xyz, r1.xyzz, r0.x
aaaaaaaaaaaaaiacafaaaaoeaeaaaaaaaaaaaaaaaaaaaaaa mov r0.w, v5
aaaaaaaaaaaaapadaaaaaaoeacaaaaaaaaaaaaaaaaaaaaaa mov o0, r0
"
}

SubProgram "d3d11_9x " {
Keywords { "POINT_COOKIE" }
ConstBuffer "$Globals" 112 // 112 used size, 4 vars
Vector 96 [_LightColor0] 4
BindCB "$Globals" 0
SetTexture 0 [_LightTextureB0] 2D 1
SetTexture 1 [_LightTexture0] CUBE 0
// 13 instructions, 3 temp regs, 0 temp arrays:
// ALU 9 float, 0 int, 0 uint
// TEX 2 (0 load, 0 comp, 0 bias, 0 grad)
// FLOW 1 static, 0 dynamic
"ps_4_0_level_9_1
eefiecedllanjeideokngnjhhgonjfkkfphknfmoabaaaaaagaaeaaaaaeaaaaaa
daaaaaaaiaabaaaaheadaaaacmaeaaaaebgpgodjeiabaaaaeiabaaaaaaacpppp
baabaaaadiaaaaaaabaacmaaaaaadiaaaaaadiaaacaaceaaaaaadiaaabaaaaaa
aaababaaaaaaagaaabaaaaaaaaaaaaaaaaacppppbpaaaaacaaaaaaiaabaaahla
bpaaaaacaaaaaaiaacaachlabpaaaaacaaaaaaiaadaaahlabpaaaaacaaaaaaia
aeaacplabpaaaaacaaaaaajiaaaiapkabpaaaaacaaaaaajaabaiapkaaiaaaaad
aaaaaiiaadaaoelaadaaoelaabaaaaacaaaaadiaaaaappiaecaaaaadaaaaapia
aaaaoeiaabaioekaecaaaaadabaaapiaadaaoelaaaaioekaafaaaaadaaaacbia
aaaaaaiaabaappiaacaaaaadaaaaabiaaaaaaaiaaaaaaaiaceaaaaacabaaahia
abaaoelaaiaaaaadaaaadciaacaaoelaabaaoeiaafaaaaadabaaahiaaeaaoela
aaaaoekaafaaaaadaaaaaoiaaaaaffiaabaabliaafaaaaadaaaachiaaaaaaaia
aaaabliaabaaaaacaaaaciiaaeaapplaabaaaaacaaaicpiaaaaaoeiappppaaaa
fdeieefcomabaaaaeaaaaaaahlaaaaaafjaaaaaeegiocaaaaaaaaaaaahaaaaaa
fkaaaaadaagabaaaaaaaaaaafkaaaaadaagabaaaabaaaaaafibiaaaeaahabaaa
aaaaaaaaffffaaaafidaaaaeaahabaaaabaaaaaaffffaaaagcbaaaadhcbabaaa
acaaaaaagcbaaaadhcbabaaaadaaaaaagcbaaaadhcbabaaaaeaaaaaagcbaaaad
pcbabaaaafaaaaaagfaaaaadpccabaaaaaaaaaaagiaaaaacadaaaaaabaaaaaah
bcaabaaaaaaaaaaaegbcbaaaacaaaaaaegbcbaaaacaaaaaaeeaaaaafbcaabaaa
aaaaaaaaakaabaaaaaaaaaaadiaaaaahhcaabaaaaaaaaaaaagaabaaaaaaaaaaa
egbcbaaaacaaaaaabacaaaahbcaabaaaaaaaaaaaegbcbaaaadaaaaaaegacbaaa
aaaaaaaadiaaaaaiocaabaaaaaaaaaaaagbjbaaaafaaaaaaagijcaaaaaaaaaaa
agaaaaaadiaaaaahhcaabaaaaaaaaaaaagaabaaaaaaaaaaajgahbaaaaaaaaaaa
baaaaaahicaabaaaaaaaaaaaegbcbaaaaeaaaaaaegbcbaaaaeaaaaaaefaaaaaj
pcaabaaaabaaaaaapgapbaaaaaaaaaaaeghobaaaaaaaaaaaaagabaaaabaaaaaa
efaaaaajpcaabaaaacaaaaaaegbcbaaaaeaaaaaaeghobaaaabaaaaaaaagabaaa
aaaaaaaaapaaaaahicaabaaaaaaaaaaaagaabaaaabaaaaaapgapbaaaacaaaaaa
diaaaaahhccabaaaaaaaaaaapgapbaaaaaaaaaaaegacbaaaaaaaaaaadgaaaaaf
iccabaaaaaaaaaaadkbabaaaafaaaaaadoaaaaabejfdeheolaaaaaaaagaaaaaa
aiaaaaaajiaaaaaaaaaaaaaaabaaaaaaadaaaaaaaaaaaaaaapaaaaaakeaaaaaa
aaaaaaaaaaaaaaaaadaaaaaaabaaaaaaadaaaaaakeaaaaaaacaaaaaaaaaaaaaa
adaaaaaaacaaaaaaahahaaaakeaaaaaaabaaaaaaaaaaaaaaadaaaaaaadaaaaaa
ahahaaaakeaaaaaaadaaaaaaaaaaaaaaadaaaaaaaeaaaaaaahahaaaakeaaaaaa
afaaaaaaaaaaaaaaadaaaaaaafaaaaaaapapaaaafdfgfpfaepfdejfeejepeoaa
feeffiedepepfceeaaklklklepfdeheocmaaaaaaabaaaaaaaiaaaaaacaaaaaaa
aaaaaaaaaaaaaaaaadaaaaaaaaaaaaaaapaaaaaafdfgfpfegbhcghgfheaaklkl
"
}

SubProgram "gles3 " {
Keywords { "POINT_COOKIE" }
"!!GLES3"
}

SubProgram "opengl " {
Keywords { "DIRECTIONAL_COOKIE" }
Vector 0 [_LightColor0]
SetTexture 0 [_LightTexture0] 2D
"!!ARBfp1.0
# 10 ALU, 1 TEX
PARAM c[2] = { program.local[0],
		{ 2 } };
TEMP R0;
TEMP R1;
TEX R0.w, fragment.texcoord[3], texture[0], 2D;
DP3 R0.x, fragment.texcoord[2], fragment.texcoord[2];
RSQ R0.x, R0.x;
MUL R1.xyz, R0.x, fragment.texcoord[2];
MUL R0.xyz, fragment.texcoord[5], c[0];
DP3_SAT R1.x, fragment.texcoord[1], R1;
MUL R0.w, R0, c[1].x;
MUL R0.xyz, R0, R1.x;
MUL result.color.xyz, R0, R0.w;
MOV result.color.w, fragment.texcoord[5];
END
# 10 instructions, 2 R-regs
"
}

SubProgram "d3d9 " {
Keywords { "DIRECTIONAL_COOKIE" }
Vector 0 [_LightColor0]
SetTexture 0 [_LightTexture0] 2D
"ps_2_0
; 10 ALU, 1 TEX
dcl_2d s0
def c1, 2.00000000, 0, 0, 0
dcl t2.xyz
dcl t1.xyz
dcl t3.xy
dcl t5
texld r0, t3, s0
dp3 r0.x, t2, t2
rsq r0.x, r0.x
mul r1.xyz, r0.x, t2
mul_pp r0.x, r0.w, c1
dp3_pp_sat r1.x, t1, r1
mul r2.xyz, t5, c0
mul r1.xyz, r2, r1.x
mul r0.xyz, r1, r0.x
mov_pp r0.w, t5
mov_pp oC0, r0
"
}

SubProgram "d3d11 " {
Keywords { "DIRECTIONAL_COOKIE" }
ConstBuffer "$Globals" 112 // 112 used size, 4 vars
Vector 96 [_LightColor0] 4
BindCB "$Globals" 0
SetTexture 0 [_LightTexture0] 2D 0
// 11 instructions, 2 temp regs, 0 temp arrays:
// ALU 8 float, 0 int, 0 uint
// TEX 1 (0 load, 0 comp, 0 bias, 0 grad)
// FLOW 1 static, 0 dynamic
"ps_4_0
eefieceddlagaeffgggjojnblaiknbdlaooljhknabaaaaaalaacaaaaadaaaaaa
cmaaaaaaoeaaaaaabiabaaaaejfdeheolaaaaaaaagaaaaaaaiaaaaaajiaaaaaa
aaaaaaaaabaaaaaaadaaaaaaaaaaaaaaapaaaaaakeaaaaaaaaaaaaaaaaaaaaaa
adaaaaaaabaaaaaaadaaaaaakeaaaaaaadaaaaaaaaaaaaaaadaaaaaaabaaaaaa
amamaaaakeaaaaaaacaaaaaaaaaaaaaaadaaaaaaacaaaaaaahahaaaakeaaaaaa
abaaaaaaaaaaaaaaadaaaaaaadaaaaaaahahaaaakeaaaaaaafaaaaaaaaaaaaaa
adaaaaaaaeaaaaaaapapaaaafdfgfpfaepfdejfeejepeoaafeeffiedepepfcee
aaklklklepfdeheocmaaaaaaabaaaaaaaiaaaaaacaaaaaaaaaaaaaaaaaaaaaaa
adaaaaaaaaaaaaaaapaaaaaafdfgfpfegbhcghgfheaaklklfdeieefcjaabaaaa
eaaaaaaageaaaaaafjaaaaaeegiocaaaaaaaaaaaahaaaaaafkaaaaadaagabaaa
aaaaaaaafibiaaaeaahabaaaaaaaaaaaffffaaaagcbaaaadmcbabaaaabaaaaaa
gcbaaaadhcbabaaaacaaaaaagcbaaaadhcbabaaaadaaaaaagcbaaaadpcbabaaa
aeaaaaaagfaaaaadpccabaaaaaaaaaaagiaaaaacacaaaaaabaaaaaahbcaabaaa
aaaaaaaaegbcbaaaacaaaaaaegbcbaaaacaaaaaaeeaaaaafbcaabaaaaaaaaaaa
akaabaaaaaaaaaaadiaaaaahhcaabaaaaaaaaaaaagaabaaaaaaaaaaaegbcbaaa
acaaaaaabacaaaahbcaabaaaaaaaaaaaegbcbaaaadaaaaaaegacbaaaaaaaaaaa
diaaaaaiocaabaaaaaaaaaaaagbjbaaaaeaaaaaaagijcaaaaaaaaaaaagaaaaaa
diaaaaahhcaabaaaaaaaaaaaagaabaaaaaaaaaaajgahbaaaaaaaaaaaefaaaaaj
pcaabaaaabaaaaaaogbkbaaaabaaaaaaeghobaaaaaaaaaaaaagabaaaaaaaaaaa
aaaaaaahicaabaaaaaaaaaaadkaabaaaabaaaaaadkaabaaaabaaaaaadiaaaaah
hccabaaaaaaaaaaapgapbaaaaaaaaaaaegacbaaaaaaaaaaadgaaaaaficcabaaa
aaaaaaaadkbabaaaaeaaaaaadoaaaaab"
}

SubProgram "gles " {
Keywords { "DIRECTIONAL_COOKIE" }
"!!GLES"
}

SubProgram "glesdesktop " {
Keywords { "DIRECTIONAL_COOKIE" }
"!!GLES"
}

SubProgram "flash " {
Keywords { "DIRECTIONAL_COOKIE" }
Vector 0 [_LightColor0]
SetTexture 0 [_LightTexture0] 2D
"agal_ps
c1 2.0 0.0 0.0 0.0
[bc]
ciaaaaaaaaaaapacadaaaaoeaeaaaaaaaaaaaaaaafaababb tex r0, v3, s0 <2d wrap linear point>
bcaaaaaaaaaaabacacaaaaoeaeaaaaaaacaaaaoeaeaaaaaa dp3 r0.x, v2, v2
akaaaaaaaaaaabacaaaaaaaaacaaaaaaaaaaaaaaaaaaaaaa rsq r0.x, r0.x
adaaaaaaabaaahacaaaaaaaaacaaaaaaacaaaaoeaeaaaaaa mul r1.xyz, r0.x, v2
adaaaaaaaaaaabacaaaaaappacaaaaaaabaaaaoeabaaaaaa mul r0.x, r0.w, c1
bcaaaaaaabaaabacabaaaaoeaeaaaaaaabaaaakeacaaaaaa dp3 r1.x, v1, r1.xyzz
bgaaaaaaabaaabacabaaaaaaacaaaaaaaaaaaaaaaaaaaaaa sat r1.x, r1.x
adaaaaaaacaaahacafaaaaoeaeaaaaaaaaaaaaoeabaaaaaa mul r2.xyz, v5, c0
adaaaaaaabaaahacacaaaakeacaaaaaaabaaaaaaacaaaaaa mul r1.xyz, r2.xyzz, r1.x
adaaaaaaaaaaahacabaaaakeacaaaaaaaaaaaaaaacaaaaaa mul r0.xyz, r1.xyzz, r0.x
aaaaaaaaaaaaaiacafaaaaoeaeaaaaaaaaaaaaaaaaaaaaaa mov r0.w, v5
aaaaaaaaaaaaapadaaaaaaoeacaaaaaaaaaaaaaaaaaaaaaa mov o0, r0
"
}

SubProgram "d3d11_9x " {
Keywords { "DIRECTIONAL_COOKIE" }
ConstBuffer "$Globals" 112 // 112 used size, 4 vars
Vector 96 [_LightColor0] 4
BindCB "$Globals" 0
SetTexture 0 [_LightTexture0] 2D 0
// 11 instructions, 2 temp regs, 0 temp arrays:
// ALU 8 float, 0 int, 0 uint
// TEX 1 (0 load, 0 comp, 0 bias, 0 grad)
// FLOW 1 static, 0 dynamic
"ps_4_0_level_9_1
eefieceddjfbacnndndbchhbkadbfkdckhdefnbcabaaaaaameadaaaaaeaaaaaa
daaaaaaaeaabaaaaniacaaaajaadaaaaebgpgodjaiabaaaaaiabaaaaaaacpppp
neaaaaaadeaaaaaaabaaciaaaaaadeaaaaaadeaaabaaceaaaaaadeaaaaaaaaaa
aaaaagaaabaaaaaaaaaaaaaaaaacppppbpaaaaacaaaaaaiaaaaaaplabpaaaaac
aaaaaaiaabaaahlabpaaaaacaaaaaaiaacaachlabpaaaaacaaaaaaiaadaacpla
bpaaaaacaaaaaajaaaaiapkaceaaaaacaaaaahiaabaaoelaaiaaaaadaaaadbia
acaaoelaaaaaoeiaafaaaaadaaaaaoiaadaabllaaaaablkaafaaaaadaaaaahia
aaaaaaiaaaaabliaabaaaaacabaaadiaaaaabllaecaaaaadabaacpiaabaaoeia
aaaioekaacaaaaadaaaaaiiaabaappiaabaappiaafaaaaadaaaachiaaaaappia
aaaaoeiaabaaaaacaaaaciiaadaapplaabaaaaacaaaicpiaaaaaoeiappppaaaa
fdeieefcjaabaaaaeaaaaaaageaaaaaafjaaaaaeegiocaaaaaaaaaaaahaaaaaa
fkaaaaadaagabaaaaaaaaaaafibiaaaeaahabaaaaaaaaaaaffffaaaagcbaaaad
mcbabaaaabaaaaaagcbaaaadhcbabaaaacaaaaaagcbaaaadhcbabaaaadaaaaaa
gcbaaaadpcbabaaaaeaaaaaagfaaaaadpccabaaaaaaaaaaagiaaaaacacaaaaaa
baaaaaahbcaabaaaaaaaaaaaegbcbaaaacaaaaaaegbcbaaaacaaaaaaeeaaaaaf
bcaabaaaaaaaaaaaakaabaaaaaaaaaaadiaaaaahhcaabaaaaaaaaaaaagaabaaa
aaaaaaaaegbcbaaaacaaaaaabacaaaahbcaabaaaaaaaaaaaegbcbaaaadaaaaaa
egacbaaaaaaaaaaadiaaaaaiocaabaaaaaaaaaaaagbjbaaaaeaaaaaaagijcaaa
aaaaaaaaagaaaaaadiaaaaahhcaabaaaaaaaaaaaagaabaaaaaaaaaaajgahbaaa
aaaaaaaaefaaaaajpcaabaaaabaaaaaaogbkbaaaabaaaaaaeghobaaaaaaaaaaa
aagabaaaaaaaaaaaaaaaaaahicaabaaaaaaaaaaadkaabaaaabaaaaaadkaabaaa
abaaaaaadiaaaaahhccabaaaaaaaaaaapgapbaaaaaaaaaaaegacbaaaaaaaaaaa
dgaaaaaficcabaaaaaaaaaaadkbabaaaaeaaaaaadoaaaaabejfdeheolaaaaaaa
agaaaaaaaiaaaaaajiaaaaaaaaaaaaaaabaaaaaaadaaaaaaaaaaaaaaapaaaaaa
keaaaaaaaaaaaaaaaaaaaaaaadaaaaaaabaaaaaaadaaaaaakeaaaaaaadaaaaaa
aaaaaaaaadaaaaaaabaaaaaaamamaaaakeaaaaaaacaaaaaaaaaaaaaaadaaaaaa
acaaaaaaahahaaaakeaaaaaaabaaaaaaaaaaaaaaadaaaaaaadaaaaaaahahaaaa
keaaaaaaafaaaaaaaaaaaaaaadaaaaaaaeaaaaaaapapaaaafdfgfpfaepfdejfe
ejepeoaafeeffiedepepfceeaaklklklepfdeheocmaaaaaaabaaaaaaaiaaaaaa
caaaaaaaaaaaaaaaaaaaaaaaadaaaaaaaaaaaaaaapaaaaaafdfgfpfegbhcghgf
heaaklkl"
}

SubProgram "gles3 " {
Keywords { "DIRECTIONAL_COOKIE" }
"!!GLES3"
}

}

#LINE 224

        }
		
	} 

}