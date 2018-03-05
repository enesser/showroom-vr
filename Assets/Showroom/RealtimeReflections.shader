// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "MyMobile/Realtime" 
{
	Properties
	{
		_Color("Color", Color) = (0.8,0.8,0.8,1)
		_Color2(" Spec Color", Color) = (0.8,0.8,0.8,1)
		_Color3(" detail Color", Color) = (0.8,0.8,0.8,1)
		_Color4(" reflection Color", Color) = (0.8,0.8,0.8,1)
		_Diffuse_Tex("Diffuse_Tex", 2D) = "white" {}
		_Detail_Tex("Detail (RGB)", 2D) = "gray" {}		
		
		_Blending("Blend amount", Range(0, 1)) = 1
		_Reflection("Reflection Amount", Range(0, 1)) = 1			
		_DetailAmount("detail amount", Range(0, 1)) = 1	
		_Spd("Spec amount", Range(0,1)) = 1	
	    _Shininess("Shininess", Float) = 10
			
	}

		SubShader{ Tags{ "LightMode" = "ForwardBase" }
		Pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
#pragma multi_compile_fwdbase
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"

			uniform float4 _Color;
			uniform float4 _Color2;
			uniform float4 _Color3;
			uniform float4 _Color4;
		
			uniform sampler2D _Diffuse_Tex; uniform float4 _Diffuse_Tex_ST;
			uniform sampler2D _Detail_Tex; uniform float4 _Detail_Tex_ST;
			uniform float _Shininess;
			uniform float _Reflection;
			uniform float _Blending;
			uniform float _DetailAmount;
			uniform float _Spd;
			struct VertexInput {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 texcoord0 : TEXCOORD0;
				float2 texcoord1 : TEXCOORD1;
			};
			struct VertexOutput {
				float4 pos : SV_POSITION;
				float2 uv0 : TEXCOORD0;
				float2 uv1 : TEXCOORD1;
				float4 posWorld : TEXCOORD2;
				float3 normalDir : TEXCOORD3;
				LIGHTING_COORDS(4, 5)

			};
			VertexOutput vert(VertexInput v) {
				VertexOutput o;
				o.uv0 = v.texcoord0;
				o.uv1 = TRANSFORM_TEX(v.texcoord1, _Detail_Tex);
				o.normalDir = mul(float4(v.normal,0), unity_WorldToObject).xyz;
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				o.pos = UnityObjectToClipPos(v.vertex);
				TRANSFER_VERTEX_TO_FRAGMENT(o);
				return o;
			}
			fixed4 frag(VertexOutput i) : COLOR
			{ 
				
				float3 normalDirection = normalize(i.normalDir);
				
				float3 viewDirection = normalize(
					_WorldSpaceCameraPos - i.posWorld.xyz);
				float3 lightDirectionx;
				float attenuation = LIGHT_ATTENUATION(i);
				if (0.0 == _WorldSpaceLightPos0.w) // directional light?
				{
					//attenuation = 1.0; // no attenuation
					lightDirectionx = normalize(_WorldSpaceLightPos0.xyz);
				}
				else // point or spot light
				{
					float3 vertexToLightSource =
						_WorldSpaceLightPos0.xyz - i.posWorld.xyz;
					float distance = length(vertexToLightSource);
					attenuation = attenuation / distance; // linear attenuation 
					lightDirectionx = normalize(vertexToLightSource);
				}

				float3 ambientLighting =
					UNITY_LIGHTMODEL_AMBIENT.rgb * _Color.rgb;

				float3 diffuseReflection =
					attenuation * _Color2.rgb * _Color.rgb
					* max(0.0, dot(normalDirection, lightDirectionx));

					float3 specularReflection = _Color2.rgb *_Spd* pow(max(0.0, dot(	reflect(-lightDirectionx, normalDirection),
							viewDirection)), _Shininess) + diffuseReflection;
			

				
				float4 ambientLight = UNITY_LIGHTMODEL_AMBIENT;

				float4 lightDirection = normalize(_WorldSpaceLightPos0);

				float4 diffuseTerm = tex2D(_Diffuse_Tex, i.uv0) *_Blending* saturate(dot(lightDirection, i.normalDir));
				float4 diffuseLight = diffuseTerm * _Color;

				float4 cameraPosition = normalize(float4(_WorldSpaceCameraPos,1) - i.pos);

				// Blinn-Phong
				float4 halfVector = normalize(lightDirection + cameraPosition);
				float4 specularTerm = pow(saturate(dot(i.normalDir, halfVector)), 25)*_Spd;
				//specularTerm *= _Color2 ;

				// Phong
				//float4 reflectionVector = reflect(-lightDirection, float4(i.normalDir, 1))*_spamount;
				//float4 specularTerm = pow(saturate(dot(reflectionVector, cameraPosition)),15)*_spamount;

				
				//float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
				//float3 lightDirection= normalize(_WorldSpaceLightPos0.xyz);
				//float3 normalDirection = normalize(i.normalDir);
				float3 viewReflectDirection = reflect(-viewDirection, normalDirection);
			
				attenuation = LIGHT_ATTENUATION(i);
				float3 forwardLight = max(float3(0.0, 0.0, 0.0), attenuation);
				float3 finalColor = 0;
				//float3 ambientLighting = UNITY_LIGHTMODEL_AMBIENT.rgb ;
				float3 diffuse = tex2D(_Diffuse_Tex, i.uv0);
				diffuse *= 1.0 + (_Color-_Blending);
				// tex2D(_Diffuse_Tex,TRANSFORM_TEX(i.uv0, _Diffuse_Tex)).rgb)/2 ;
				fixed3 ddetail = (_DetailAmount * tex2D(_Detail_Tex, i.uv1).rgb) * _Color3 ;
				float4 val = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, viewReflectDirection);
				float3 reflection = DecodeHDR(val, unity_SpecCube0_HDR);
				//float3 reflection = texCUBE(_Reflect, viewReflectDirection).rgb;
				reflection = (reflection  * (1.0 * _Reflection))*_Color4;
				specularReflection *= attenuation;
				 finalColor = diffuse + ddetail + reflection +  specularReflection;

				return float4(finalColor ,1.0);
				//return float4(ambientLighting + diffuseReflection
					//+ specularReflection, 1.0);
			}
			ENDCG
		}
		}
			FallBack "VertexLit"
}



/*
Pass
{ Name "ForwardAdd" Tags { "LightMode"="ForwardAdd" } Blend One One ZWrite On

Fog{ Color(0,0,0,0) }
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#define UNITY_PASS_FORWARDADD
#include "UnityCG.cginc"
#include "AutoLight.cginc"
#pragma multi_compile_fwdadd
#pragma exclude_renderers xbox360 ps3 flash d3d11_9x
#pragma target 3.0
uniform float4 _LightColor0;
uniform float4 _Color;
uniform samplerCUBE _Reflect;
uniform sampler2D _Diffuse_Tex; uniform float4 _Diffuse_Tex_ST;
uniform float _Alpha;
struct VertexInput {
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float2 texcoord0 : TEXCOORD0;
};
struct VertexOutput {
	float4 pos : SV_POSITION;
	float2 uv0 : TEXCOORD0;
	float4 posWorld : TEXCOORD1;
	float3 normalDir : TEXCOORD2;
	LIGHTING_COORDS(3,4)
};
VertexOutput vert(VertexInput v) {
	VertexOutput o;
	o.uv0 = v.texcoord0;
	o.normalDir = mul(float4(v.normal,0), unity_WorldToObject).xyz;
	o.posWorld = mul(unity_ObjectToWorld, v.vertex);
	o.pos = UnityObjectToClipPos(v.vertex);
	TRANSFER_VERTEX_TO_FRAGMENT(o)
		return o;
}
fixed4 frag(VertexOutput i) : COLOR{
	i.normalDir = normalize(i.normalDir);
float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);

/////// Normals:
float3 normalDirection = i.normalDir; float3 viewReflectDirection = reflect( -viewDirection, normalDirection ); float3 lightDirection = normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - i.posWorld.xyz,_WorldSpaceLightPos0.w));
////// Lighting:
float attenuation = LIGHT_ATTENUATION(i);
float3 attenColor = attenuation  / _LightColor0.xyz;
/////// Diffuse:
float NdotL = dot( normalDirection, lightDirection );
float3 w = texCUBE(_Reflect,viewReflectDirection).rgb*0.5;
// Light wrapping
float3 NdotLWrap = NdotL  * ( 1.0 - w );
float3 forwardLight = max(float3(0.0,0.0,0.0), NdotLWrap + w );
float3 diffuse = forwardLight + attenColor;
float3 finalColor = 0;
float3 diffuseLight = diffuse;
float2 node_59 = i.uv0;
finalColor += diffuseLight/(tex2D(_Diffuse_Tex,TRANSFORM_TEX(node_59.rg, _Diffuse_Tex)).rgb*_Color.rgb);
/// Final Color:
return fixed4(finalColor , _Alpha);
}

ENDCG
} */