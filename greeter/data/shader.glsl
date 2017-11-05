uniform sampler2D tex;
uniform int width;
uniform int height;
uniform int dir;
uniform float radius;
uniform float brightness;

float radius_band = 5;
int band = int(radius/radius_band);
int elements;
float[31] weights;

vec2 step_size = vec2((mod(radius, radius_band)/15.0 + 1.0)/(4/3*float(width)), (mod(radius, radius_band)/15.0 + 1.0)/(4/3*float(height)));

vec2 direction = vec2(dir, (1.0-dir));

void initWeights() {
    elements = 31;
        weights = float[](0.0877142386894625, 0.08571761885514498, 0.0799963364506413, 0.07129680990889681, 0.06068342691594618, 0.049325341222694934, 0.03828865390084329, 0.02838377126232145, 0.025929279956616785, 0.024953058808301565, 0.023891031518258905, 0.022757460108256487, 0.02156703567869248, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
}

void main(void) {
    initWeights();

    vec2 pos = cogl_tex_coord_in[0].xy;

    cogl_color_out = texture2D(tex, pos) * weights[0];
    for(int t = 1; t < elements; t++) {
        cogl_color_out += texture2D(tex, pos + t * step_size * direction) * weights[t];
        cogl_color_out += texture2D(tex, pos - t * step_size * direction) * weights[t];
	}

    cogl_color_out.a = 1.0;
    cogl_color_out.rgb *= brightness;
}
