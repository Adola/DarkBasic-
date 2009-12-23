string Description = "This shader creates a cell shading outline around cartoon objects";
string Thumbnail = "Cartoon Outline.png";

float2 ViewSize : ViewSize;

float2 PixelOffsets[9] =
{
    { -1,  -1 },
    {  0,  -1  },
    {  1,  -1  },
    { -1,   0  },
    {  0,   0  },
    {  1,   0  },
    { -1,   1 },
    {  0,   1 },
    {  1,   1  },
};

float EdgeDetectH[9] =
{
   -1, -2, -1,
    0,  0,  0,
    1,  2,  1
};

float EdgeDetectV[9] =
{
   -1,  0,  1,
   -2,  0,  2,
   -1,  0,  1
};

float edgeSize
<
	string UIWidget = "slider";
	float UIMax = 3.0;
	float UIMin = 0.01;
	float UIStep = 0.01;
> = 0.940000;

//scene image
texture frame : RENDERCOLORTARGET
< 
	string ResourceName = "";
	float2 ViewportRatio = { 1.0, 1.0 };
>;

sampler2D frameSamp = sampler_state {
    Texture = < frame >;
    MinFilter = Linear; MagFilter = Linear; MipFilter = Linear;
    AddressU = Clamp; AddressV = Clamp;
};

struct input 
{
	float4 pos : POSITION;
	float2 uv : TEXCOORD0;
};
 
struct output {

	float4 pos: POSITION;
	float2 uv: TEXCOORD0;

};

output VS( input IN ) 
{
	output OUT;

	//quad needs to be shifted by half a pixel.
    //Go here for more info: http://www.sjbrown.co.uk/?article=directx_texels
    
	float4 oPos = float4( IN.pos.xy + float2( -1.0f/ViewSize.x, 1.0f/ViewSize.y ),0.0,1.0 );
	OUT.pos = oPos;

	float2 uv = (IN.pos.xy + 1.0) / 2.0;
	uv.y = 1 - uv.y; 
	OUT.uv = uv;
	
	return OUT;	
}

float4 PSOutline( output IN, uniform sampler2D srcTex ) : COLOR
{
    float4 color = 0;
    float edgeH = 0;
    float edgeV = 0;
    
    float2 scale = edgeSize/ViewSize;
    
    color = tex2D( srcTex, IN.uv );
    
    //Sobel filter to detect edges we want to highlight
    for (int i = 0; i < 9; i++)
    {
        //convert pixel offsets into texel offsets via the inverse view values.
        float pixel = tex2D( srcTex, IN.uv + PixelOffsets[i].xy*scale ).a;
        edgeH += pixel*EdgeDetectH[i];
        edgeV += pixel*EdgeDetectV[i];
    }
    
    float edge = edgeH*edgeH + edgeV*edgeV;
    edge = edge > 0.0049; //clamp
    
    return lerp(color,(1-edge),edge);
}

technique Outline
<
	//specify where we want the original scene to be put
	string RenderColorTarget = "frame";
>
{
	//single pass to highlight the edges in the scene
	pass Outline
	<
		string RenderColorTarget = "";
	>
	{
		ZEnable = False;
		VertexShader = compile vs_2_0 VS();
		PixelShader = compile ps_2_0 PSOutline( frameSamp );
	}
}
