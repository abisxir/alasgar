import alasgar

# Creates a window named Hello
window("Hello", 640, 360)
   
# Creates a new scene
var scene = newScene()
var env = newEnvironmentComponent()
# Sets background color to black
setBackground(env, parseHtmlName("DimGray"))
# Adds environment to our scene
addComponent(scene, env)

# Creates camera entity
var cameraEntity = newEntity(scene, "Camera")
# Sets camera position
cameraEntity.transform.position = vec3(0, 0, 10)
# Creates camera component
var camera = newPerspectiveCamera(
        75, 
        runtime.engine.ratio, 
        0.1, 
        100.0, 
        vec3(0) - cameraEntity.transform.position
    )

# Adds a perspective camera component to entity
addComponent(
    cameraEntity, 
    camera
)
# Split is just for debugging, it will apply it on the second half 
# of the screen when it is 0.5
addEffect(camera, "FXAA", newFxaaEffect(split=0.5))
# Makes the camera entity child of scene
addChild(scene, cameraEntity)

# Creates light entity
var lightEntity = newEntity(scene, "Light")
# Sets light position
lightEntity.transform.position = cameraEntity.transform.position
# Adds a point light component to entity
addComponent(
    lightEntity, 
    newPointLightComponent()
)
# Makes the light entity child of the scene
addChild(scene, lightEntity)

# Creates cube entity, by default position is 0, 0, 0
var cubeEntity = newEntity(scene, "Cube")
# Set scale to 2
cubeEntity.transform.scale = vec3(2)
# Add a cube mesh component to entity
addComponent(cubeEntity, newCubeMesh())
# Adds a material to cube
addComponent(cubeEntity, newMaterialComponent(
    diffuseColor=parseHtmlName("white"),
    albedoMap=newTexture("res://stone-texture.png")
))
# Adds a script component to cube entity
addScript(cubeEntity, proc(script: ScriptComponent, input: Input, delta: float32) =
    # We can rotate an object using euler also we can directly set rotation property that is a quaternion.
    script.transform.euler = vec3(
        sin(runtime.engine.age) * sin(runtime.engine.age), 
        cos(runtime.engine.age), 
        sin(runtime.engine.age)
    )
)
# Makes the cube enity child of scene
addChild(scene, cubeEntity)

# Creates cube entity, by default position is 0, 0, 0
var gridEntity = newEntity(scene, "Grid")
# Set scale to 2
gridEntity.transform.scale = 10 * vec3(runtime.engine.ratio, 1.0, 1.0)
gridEntity.transform.position = vec3(0, 0, -3)
# Add a cube mesh component to entity
addComponent(gridEntity, newPlaneMesh(1, 1))
# Adds a material to cube
addComponent(gridEntity, newMaterialComponent(
    diffuseColor=parseHtmlName("white"),
))
# Adds a shader to cube
addComponent(gridEntity, newFragmentShaderComponent("""
float time;
vec3 pln;

float terrain(vec3 p)
{
	float nx=floor(p.x)*10.0+floor(p.z)*100.0,center=0.0,scale=2.0;
	vec4 heights=vec4(0.0,0.0,0.0,0.0);
	
	for(int i=0;i<5;i+=1)
	{
		vec2 spxz=step(vec2(0.0),p.xz);
		float corner_height = mix(mix(heights.x, heights.y, spxz.x),
								  mix(heights.w, heights.z, spxz.x),spxz.y);
		
		vec4 mid_heights=(heights+heights.yzwx)*0.5;
		
		heights =mix(mix(vec4(heights.x,mid_heights.x,center,mid_heights.w),
					     vec4(mid_heights.x,heights.y,mid_heights.y,center), spxz.x),
					 mix(vec4(mid_heights.w,center,mid_heights.z,heights.w), 
						 vec4(center,mid_heights.y,heights.z,mid_heights.z), spxz.x), spxz.y);
		
		nx=nx*4.0+spxz.x+2.0*spxz.y;
		
		center=(center+corner_height)*0.5+cos(nx*20.0)/scale*30.0;
		p.xz=fract(p.xz)-vec2(0.5);
		p*=2.0;
		scale*=2.0;
	}
	
		
	float d0=p.x+p.z;
	
	vec2 plh=mix( mix(heights.xw,heights.zw,step(0.0,d0)),
				  mix(heights.xy,heights.zy,step(0.0,d0)), step(p.z,p.x));
	
	pln=normalize(vec3(plh.x-plh.y,2.0,(plh.x-center)+(plh.y-center)));

	if(p.x+p.z>0.0)
		pln.xz=-pln.zx;
	
	if(p.x<p.z)
		pln.xz=pln.zx;
	
	p.y-=center;	
	return dot(p,pln)/scale;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	time=frame.time*0.4;
	vec2 uv=(fragCoord.xy / frame.resolution.xy)*2.0-vec2(1.0);
	uv.x*=frame.resolution.x/frame.resolution.y;
	
	float sc=(time+sin(time*0.2)*4.0)*0.8;
	vec3 camo=vec3(sc+cos(time*0.2)*0.5,0.7+sin(time*0.3)*0.4,0.3+sin(time*0.4)*0.8);
	vec3 camt=vec3(sc+cos(time*0.04)*1.5,-1.5,0.0);
	vec3 camd=normalize(camt-camo);
	
	vec3 camu=normalize(cross(camd,vec3(0.5,1.0,0.0))),camv=normalize(cross(camu,camd));
	camu=normalize(cross(camd,camv));
	
	mat3 m=mat3(camu,camv,camd);
	
	vec3 rd=m*normalize(vec3(uv,1.8)),rp;
	
	float t=0.0;
	
	for(int i=0;i<100;i+=1)
	{
		rp=camo+rd*t;
		float d=terrain(rp);
		if(d<4e-3)
			break;
		t+=d;
	}

	vec3 ld=normalize(vec3(1.0,0.6,2.0));
	fragColor.rgb=mix(vec3(0.1,0.1,0.5)*0.4,vec3(1.0,1.0,0.8),pow(0.5+0.5*dot(pln,ld),0.7));
	fragColor.rgb=mix(vec3(0.5,0.6,1.0),fragColor.rgb,exp(-t*0.02));
	
}


void fragment() {
    mainImage(COLOR, surface.uv.xy * frame.resolution.xy);
}
"""))
# Makes the cube enity child of scene
addChild(scene, gridEntity)


# Creats spot point light entity
var spotLightEntity = newEntity(scene, "SpotLight")
# Sets position to (-6, 6, 6)
spotLightEntity.transform.position = vec3(-6, 6, 6)
# Adds a spot point light component
addComponent(spotLightEntity, newSpotPointLightComponent(
    vec3(0) - spotLightEntity.transform.position, # Light direction
    color=parseHtmlName("aqua"),                  # Light color
    luminance=10.0,                                # Light luminance
    shadow=false,                                 # Casts shadow or not
    innerCutoff=10,                               # Inner circle of light
    outerCutoff=30                                # Outer circle of light
))
# Adds a script component to spot point light entity
addComponent(spotLightEntity, newScriptComponent(proc(script: ScriptComponent, input: Input, delta: float32) =
    # Access to point light component, if it returns nil then there is no such a component on this entity.
    let light = getComponent[SpotPointLightComponent](script)
    # Changes light color
    light.color = color(
        abs(sin(runtime.engine.age)), 
        abs(cos(runtime.engine.age)), 
        abs(sin(runtime.engine.age) * sin(runtime.engine.age))
    )
))
# Makes the new light child of the scene
addChild(scene, spotLightEntity)

# Renders an empty sceene
render(scene)
# Runs game main loop
loop()

