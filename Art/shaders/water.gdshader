shader_type canvas_item;

uniform float waterSpeed = 0.75f;
uniform vec2 textureScale = vec2(0.7f, 0.5f);
uniform float tileResolution : hint_range(1, 128, 1) = 32.0f;
uniform float colorDepth : hint_range(0, 64, 1) = 12.0f;
uniform float framesPerSecond : hint_range(15, 60, 15) = 30.0f;
uniform float translucency : hint_range(0, 1) = 0.3f;

// random function for voronoi from https://godotshaders.com/snippet/voronoi/
vec2 random(vec2 uv) {
	return vec2(fract(sin(dot(uv.xy,
		vec2(12.9898,78.233))) * 43758.5453123));
}

// worley function for voronoi from https://godotshaders.com/snippet/voronoi/
float worley(vec2 uv, float columns, float rows, float time) {

	vec2 index_uv = floor(vec2(uv.x * columns, uv.y * rows));
	vec2 fract_uv = fract(vec2(uv.x * columns, uv.y * rows));

	float minimum_dist = 1.0;

	for (int y= -1; y <= 1; y++) {
		for (int x= -1; x <= 1; x++) {
			vec2 neighbor = vec2(float(x),float(y));
			vec2 point = random(index_uv + neighbor);
			float speed = 4.5;
			point = vec2( cos(time * point.x * speed), sin(time * point.y * speed) ) * 0.5 + 0.5;

			vec2 diff = neighbor + point - fract_uv;
			float dist = length(diff);
			minimum_dist = min(minimum_dist, dist);
		}
	}

	return minimum_dist;
}

// grab the position from the vertex shader
// (the "vertex shader" runs once for each vertex)
varying vec2 world_position;
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy  / (128.0f*textureScale);
}

// draw every single pixel
// (the "fragment shader" runs once for each screen pixel)
void fragment() {
	float tileResolutionX = tileResolution * textureScale.x;
	float tileResolutionY = tileResolution * textureScale.y;

	float speed1 = waterSpeed;
	float speed2 = waterSpeed * -1.5f;

	// pixelate by snap the UV coordinates
	// vec2 snappedUV = UV / textureScale;    // replacing the following line with this one will make the tiles repeat a small texture
	vec2 snappedUV = world_position;
	snappedUV = vec2(floor(snappedUV.x*tileResolutionX)/tileResolutionX, floor(snappedUV.y*tileResolutionY)/tileResolutionY);

	float snappedTime = floor(TIME*framesPerSecond)/framesPerSecond;

	// generate noise
	float noise = worley(snappedUV, 3.0, 5.0, snappedTime*speed1)*worley(snappedUV+vec2(2.0f,0.1f), 3.0, 5.0, snappedTime*speed2);

	// posterize the texture (limit the number of colors)
	noise = round(noise*colorDepth)/colorDepth;

	// exaggerate the colors by squaring the brightness
	// (all colors are between 0 and 1, so multiplying by itself darkens anything darker than white)
	noise *= noise;

	// add the highlights to the texture, set the texture translucency to "translucency" shader parameter
	COLOR = vec4(texture(TEXTURE, UV).rgb + vec3(noise), translucency+noise);
}
