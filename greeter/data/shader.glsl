uniform sampler2D tex;
uniform int width;
uniform int height;
uniform int dir;
uniform float radius;
uniform float brightness;

float radius_band = 5;
int band = 1; // int(radius/radius_band);
int elements = 2;
float[31] weights;

void main(void) {
    //initWeights();

    vec2 pos = cogl_tex_coord_in[0].xy;

    //cogl_color_out = texture2D(tex, pos) * weights[0];
    for(int t = 1; t < elements; t++) {
        cogl_color_out += texture2D(tex, pos + t * step_size * direction) * 0.0293172877821358;
        cogl_color_out += texture2D(tex, pos - t * step_size * direction) * 0.0293172877821358;
    }

    cogl_color_out.a = 1.0;
    cogl_color_out.rgb *= brightness;
}
